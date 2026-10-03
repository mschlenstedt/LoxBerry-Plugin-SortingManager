package SortingManager;

# Core of the Sorting Manager plugin: reads the plugin configuration, takes
# inventory of Miniserver users and tablets, and copies the app sorting from one
# user to another.
#
# Used by bin/sm_cli.pl, bin/sm_job.pl, bin/sm_watch.pl, bin/sm_backup.pl and
# the web interface. Everything with I/O hangs on a replaceable hook so the
# flows can be tested without a Miniserver.

use strict;
use warnings;
use JSON;
use Fcntl qw( :flock O_RDWR O_WRONLY O_CREAT O_TRUNC );
use LoxBerry::System;
use LoxBerry::IO;
use Net::FTP;
use File::Path qw( make_path );
use Archive::Tar;
use POSIX ();
use File::Basename ();
use File::Spec ();
use version ();

##################################################################
# LoxBerry::Auth - from the core or bundled with the plugin
##################################################################

# The plugin ships its own copy in bin/lib/LoxBerry/Auth.pm, so new lib
# features can be used before the core releases them. The core's copy wins as
# soon as it is at least as new as the bundled one. The decision reads $VERSION
# from the files without loading either - a loaded module cannot be swapped.
#
# Everything else in the plugin gets the lib through this module and must not
# "use LoxBerry::Auth" before it, or the core's copy is loaded unconditionally.

# Version string from "our $VERSION = '...'" of a module file; undef if the
# file is missing or has no version.
sub lib_version
{
	my ($file) = @_;
	return undef if ( !defined $file or !-r $file );
	open( my $fh, '<', $file ) or return undef;
	while ( my $line = <$fh> ) {
		if ( $line =~ /^\s*(?:our\s+)?\$VERSION\s*=\s*["']([^"']+)["']/ ) {
			close($fh);
			return $1;
		}
	}
	close($fh);
	return undef;
}

# { source => 'core' | 'plugin', file => <path>, version => <string> }
# An unreadable core version counts as older than the bundled one.
sub auth_lib_choice
{
	my ($core_file, $bundled_file) = @_;
	my $bundled = { source => 'plugin', file => $bundled_file, version => lib_version($bundled_file) };
	my $core_version = lib_version($core_file);
	return $bundled if ( !defined $core_version );
	my $newer = eval { version->parse($core_version) >= version->parse( $bundled->{version} ) };
	return $bundled if ( !$newer );
	return { source => 'core', file => $core_file, version => $core_version };
}

# The choice that was made when this module was loaded
our $auth_lib;

BEGIN {
	my $libdir = File::Spec->catdir( File::Basename::dirname( File::Spec->rel2abs(__FILE__) ), 'lib' );
	# The core lib lives next to LoxBerry::System, which is loaded above
	my $core = defined $INC{'LoxBerry/System.pm'}
		? File::Spec->catfile( File::Basename::dirname( $INC{'LoxBerry/System.pm'} ), 'Auth.pm' )
		: undef;
	$auth_lib = auth_lib_choice( $core, File::Spec->catfile( $libdir, 'LoxBerry', 'Auth.pm' ) );
	# local: the bundled directory must not stay in @INC for other modules
	local @INC = $auth_lib->{source} eq 'plugin' ? ( $libdir, @INC ) : @INC;
	require LoxBerry::Auth;
}

use base 'Exporter';
our @EXPORT_OK = qw(
	lox_now
	lox2unix
	unix2lox
	parse_sorting
	restamp
	parse_api_value
	control_count
);

our $VERSION = "0.9.0";
our $DEBUG = 0;

# Logging. The entry scripts (job, watch, backup, CLI) hand over their
# LoxBerry::Log object; its level - set in the plugin management - decides what
# lands in the file. Without one (tests, plain CGI reads) messages only go to
# STDERR, and only with $DEBUG. Passwords and tokens are never logged.
our $log;
sub set_logger { $log = $_[0]; return; }

my %LOGFN = ( DEB => 'DEB', INF => 'INF', OK => 'OK', WARN => 'WARN', ERR => 'ERR' );
sub _log
{
	my ($lvl, $msg) = @_;
	if ($log) {
		my $fn = $LOGFN{$lvl} || 'INF';
		eval { $log->$fn($msg); };
		return;
	}
	print STDERR "SortingManager: [$lvl] $msg\n" if ($DEBUG);
	return;
}
sub _dbg { _log( 'DEB', $_[0] ); }

##################################################################
# Pure helpers - no I/O, no state
##################################################################

# Seconds since 2009-01-01 00:00:00 UTC - the base the Loxone App stamps the
# sorting files with (measured: a change at 13:11:49 CEST carried 560257909).
# NOT LoxBerry::System::epoch2lox: that one counts in local time, the
# Miniserver's convention, and would put every copy one or two hours into the
# future from the app's point of view. Every timestamp of this plugin uses the
# app's base, so all conversions go through these three functions.
my $LOX_EPOCH = 1230768000;

sub lox_now
{
	return unix2lox( time() );
}

sub unix2lox
{
	my ($unix) = @_;
	return int($unix) - $LOX_EPOCH;
}

sub lox2unix
{
	my ($lox) = @_;
	return undef if ( !$lox );
	return int($lox) + $LOX_EPOCH;
}

# A sorting file is "<ts>/<json>", and the same timestamp appears again inside
# the JSON. Both must match - that is how the app writes it, and a file where
# they differ is not trustworthy.
sub parse_sorting
{
	my ($raw) = @_;
	return { ok => 0, error => 'empty' } if (!defined $raw or $raw !~ /\S/);

	my ($ts, $json) = $raw =~ m{^(\d+)/(.*)$}s;
	return { ok => 0, error => 'badformat' } if (!defined $ts);

	my $data;
	eval { $data = JSON::from_json($json); };
	return { ok => 0, error => 'badjson' } if ($@ or ref($data) ne 'HASH');

	if ( !defined $data->{ts} or "$data->{ts}" ne "$ts" ) {
		return { ok => 0, error => 'tsmismatch' };
	}

	return { ok => 1, ts => int($ts), data => $data };
}

# Builds the string to write back, with a fresh timestamp inside and outside.
# The timestamp has to stay numeric: "ts":"556999999" makes the Miniserver
# discard the file.
sub restamp
{
	my ($data, $ts) = @_;
	$ts = lox_now() if (!defined $ts);
	$ts = int($ts);

	my %copy = %$data;
	$copy{ts} = $ts + 0;

	return $ts . '/' . JSON->new->canonical(0)->encode( \%copy );
}

sub control_count
{
	my ($data) = @_;
	return 0 if (ref($data) ne 'HASH' or ref($data->{userDefaultStructure}) ne 'HASH');
	return scalar( keys %{ $data->{userDefaultStructure} } );
}

# jdev/cfg/api returns its value as a STRING using single quotes - not valid
# JSON, so it must not be handed to a JSON parser.
sub parse_api_value
{
	my ($value) = @_;
	return undef if (!defined $value or $value eq '');
	my %out;
	while ( $value =~ /'([^']+)'\s*:\s*(?:'([^']*)'|([^,}\s]+))/g ) {
		$out{$1} = defined $2 ? $2 : $3;
	}
	return undef if (! %out);
	return \%out;
}

##################################################################
# Configuration
##################################################################

# Test hook: point this at a temp file to decouple tests from the installation.
our $config_file;

sub config_file
{
	return $config_file if ($config_file);
	# Same reasoning as in backup_dir(): without a plugin context the path would
	# point at the root of the filesystem.
	return undef if ( !$LoxBerry::System::lbpconfigdir );
	return "$LoxBerry::System::lbpconfigdir/pluginconfig.json";
}

sub _empty_config { return { MAIN => { loglevel_watch => 6 }, miniservers => {} }; }

sub _slurp
{
	my ($file) = @_;
	my $content = '';
	if ( CORE::open( my $fh, '<', $file ) ) {
		flock($fh, LOCK_SH);
		local $/;
		$content = <$fh>;
		close($fh);
	}
	return $content;
}

sub plugin_config
{
	my $file = config_file();
	return _empty_config() if (!$file or ! -e $file);

	my $cfg;
	eval { $cfg = JSON::from_json( _slurp($file) ); };
	if ($@ or ref($cfg) ne 'HASH') {
		_log( 'WARN', "config: $file is not readable JSON - starting empty" );
		return _empty_config();
	}
	_dbg("config: read $file");
	$cfg->{MAIN}        = {} if (ref($cfg->{MAIN}) ne 'HASH');
	$cfg->{miniservers} = {} if (ref($cfg->{miniservers}) ne 'HASH');
	return $cfg;
}

sub _encode_config { return JSON->new->pretty->canonical(1)->encode( $_[0] ); }

# Written only when something really changed - the config lives on the SD card.
# 0600 because it may hold credentials the user entered for a target account.
sub save_config
{
	my ($cfg) = @_;
	my $file = config_file();
	return undef if (!$file);

	my $new = _encode_config($cfg);
	if ( -e $file ) {
		my $old = _slurp($file);
		if ( defined $old and $old eq $new ) {
			_dbg("config: unchanged, not written");
			return 0;
		}
	}

	my $fh;
	if ( ! sysopen($fh, $file, O_RDWR | O_CREAT, 0600) ) {
		_log( 'ERR', "config: cannot write $file: $!" );
		return undef;
	}
	flock($fh, LOCK_EX);
	seek($fh, 0, 0);
	print $fh $new;
	truncate($fh, tell($fh));
	close($fh);
	chmod 0600, $file;
	_dbg( "config: written $file (" . length($new) . " bytes)" );
	return 1;
}

# Returns the entry of one Miniserver, creating it with the defaults when it is
# not there yet. Keyed by serial number: the Miniserver number in general.json
# moves as soon as somebody adds or removes a Miniserver.
sub ms_entry
{
	my ($cfg, $serial) = @_;
	return undef if (!$cfg or !$serial);
	$cfg->{miniservers} = {} if (ref($cfg->{miniservers}) ne 'HASH');

	if ( ref($cfg->{miniservers}{$serial}) ne 'HASH' ) {
		$cfg->{miniservers}{$serial} = {
			msnr    => undef,
			source  => undef,
			targets => [],
			watch   => {
				enabled        => 0,
				interval_min   => 15,
				auto_reboot    => 0,
				last_run       => 0,
				last_source_ts => 0,
			},
			backup  => {
				keep        => 10,
				compression => 'gzip',
				schedule    => {
					enabled     => 0,
					days        => [],
					hour        => 3,
					minute      => 0,
					every_weeks => 1,
				},
			},
		};
	}
	return $cfg->{miniservers}{$serial};
}

##################################################################
# Miniserver identity
##################################################################

# Test hook: sub ($msnr) -> ($api_value_string, $error)
our $api_hook;

sub _fetch_api
{
	my ($msnr) = @_;
	return $api_hook->($msnr) if ($api_hook);

	_dbg("Miniserver $msnr: GET /jdev/cfg/api");
	my ($content, $info) = LoxBerry::IO::mshttp_call2($msnr, '/jdev/cfg/api');
	if (!defined $content) {
		_log( 'WARN', "Miniserver $msnr: /jdev/cfg/api did not answer" );
		return ( undef, 'unreachable' );
	}

	my $ll;
	eval { $ll = JSON::from_json($content); };
	return ( undef, 'parseerror' ) if ($@ or ref($ll) ne 'HASH');
	return ( $ll->{LL}{value}, undef );
}

sub ms_serial
{
	my ($msnr) = @_;
	my ($value, $err) = _fetch_api($msnr);
	return { ok => 0, error => $err || 'parseerror' } if (!defined $value);

	my $api = parse_api_value($value);
	return { ok => 0, error => 'parseerror' } if (!$api or !$api->{snr});

	_dbg( "Miniserver $msnr: serial " . uc($api->{snr}) . ", firmware " . ( $api->{version} // '?' ) );
	return { ok => 1, serial => uc($api->{snr}), firmware => $api->{version} };
}

# Every Miniserver from general.json, with its serial number. Entries whose
# serial cannot be determined are still listed, with serial => undef, so the
# web interface can show them as unreachable instead of hiding them.
# The serial of a Miniserver even while it is down: from the Miniserver when it
# answers, otherwise from the plugin configuration, which stores every entry
# under its serial. Keeps archives and settings visible during a reboot.
sub serial_for
{
	my ($msnr) = @_;
	my $s = ms_serial($msnr);
	return { ok => 1, serial => $s->{serial}, firmware => $s->{firmware}, from => 'miniserver', reachable => 1 }
		if ( $s->{ok} );
	my $cfg = plugin_config();
	foreach my $serial ( sort keys %{ $cfg->{miniservers} } ) {
		my $e = $cfg->{miniservers}{$serial};
		next if ( ref($e) ne 'HASH' or !defined $e->{msnr} or "$e->{msnr}" ne "$msnr" );
		_dbg("Miniserver $msnr: not reachable, serial $serial taken from the configuration");
		return { ok => 1, serial => $serial, from => 'config', reachable => 0 };
	}
	return { ok => 0, error => ( $s->{error} || 'unreachable' ) };
}

sub known_miniservers
{
	my %miniservers = LoxBerry::System::get_miniservers();
	my @out;
	foreach my $msnr ( sort { $a <=> $b } keys %miniservers ) {
		my $s = ms_serial($msnr);
		push @out, {
			msnr     => $msnr,
			name     => $miniservers{$msnr}{Name},
			host     => $miniservers{$msnr}{IPAddress},
			serial   => ( $s->{ok} ? $s->{serial}   : undef ),
			firmware => ( $s->{ok} ? $s->{firmware} : undef ),
			error    => ( $s->{ok} ? undef          : $s->{error} ),
		};
	}
	return \@out;
}
##################################################################
# Inventory: users and managed tablets
##################################################################

# Test hooks: sub ($msnr) -> ($ll_value_string, $error)
our $userlist_hook;
our $pairing_hook;

# getuserlist2 refuses token authentication - it answers 403 even for a token
# with admin permission. Basic auth via LoxBerry::IO is the only way in.
sub _fetch_userlist
{
	my ($msnr) = @_;
	return $userlist_hook->($msnr) if ($userlist_hook);
	_dbg("Miniserver $msnr: GET /jdev/sps/getuserlist2 (basic auth, LoxBerry credentials)");
	my ($content) = LoxBerry::IO::mshttp_call2($msnr, '/jdev/sps/getuserlist2');
	if (!defined $content) {
		_log( 'WARN', "Miniserver $msnr: user list did not answer" );
		return ( undef, 'unreachable' );
	}
	_dbg( "Miniserver $msnr: user list " . length($content) . " bytes" );
	return ( $content, undef );
}

sub _fetch_pairing
{
	my ($msnr) = @_;
	return $pairing_hook->($msnr) if ($pairing_hook);
	_dbg("Miniserver $msnr: GET /jdev/sps/apppairing/list");
	my ($content) = LoxBerry::IO::mshttp_call2($msnr, '/jdev/sps/apppairing/list');
	if (!defined $content) {
		_log( 'WARN', "Miniserver $msnr: tablet list did not answer" );
		return ( undef, 'unreachable' );
	}
	return ( $content, undef );
}

# The two endpoints do NOT answer the same way, measured on firmware 17.1.7.3:
#
#   getuserlist2      {"LL": { "value": "[{...}]" }}   - list as a STRING in the envelope
#   apppairing/list   [{...}]                          - bare array, no envelope at all
#
# So the decoder has to cope with three shapes: a bare array, an envelope whose
# value is a string, and an envelope whose value is already an array.
sub _decode_list
{
	my ($raw) = @_;
	return undef if (!defined $raw);
	return $raw if (ref($raw) eq 'ARRAY');

	my $parsed;
	eval { $parsed = JSON::from_json($raw); };
	return undef if ($@);

	return $parsed if (ref($parsed) eq 'ARRAY');

	if ( ref($parsed) eq 'HASH' and ref($parsed->{LL}) eq 'HASH' ) {
		my $value = $parsed->{LL}{value};
		return $value if (ref($value) eq 'ARRAY');
		return undef  if (!defined $value or ref($value));

		my $inner;
		eval { $inner = JSON::from_json($value); };
		return undef if ($@ or ref($inner) ne 'ARRAY');
		return $inner;
	}
	return undef;
}

# Two sources. In apppairing/list the field "user" is the UUID the sorting file
# belongs to; "uuid" is the device. Newer firmware also lists that tablet user
# in getuserlist2, marked representsControl with pairedControl = the device.
# Such a user is a tablet, never a normal user: it has no known password, so a
# token copy can not work. If apppairing/list fails, getuserlist2 alone still
# keeps it a tablet.
sub users_and_tablets
{
	my ($msnr) = @_;

	my ($rawusers, $uerr) = _fetch_userlist($msnr);
	return { ok => 0, error => $uerr || 'unreachable' } if (!defined $rawusers);

	my $ulist = _decode_list($rawusers);
	return { ok => 0, error => 'parseerror' } if (!$ulist);

	my @users;
	my @control_users;
	foreach my $u (@$ulist) {
		next if (!$u->{uuid});
		if ( $u->{representsControl} and $u->{representsControl} ne 'false' ) {
			push @control_users, $u;
			next;
		}
		my $admin = ( $u->{isAdmin} and $u->{isAdmin} ne 'false' ) ? 1 : 0;
		push @users, {
			uuid     => $u->{uuid},
			name     => $u->{name},
			is_admin => $admin,
			state    => ( defined $u->{userState} ? $u->{userState} : 0 ),
			type     => ( $admin ? 'admin' : 'user' ),
		};
	}

	# A Miniserver without tablets is normal, and a failing pairing endpoint
	# must not take the user list down with it.
	my @tablets;
	my $terr;
	my ($rawpair, $perr) = _fetch_pairing($msnr);
	if (!defined $rawpair) {
		$terr = $perr || 'unreachable';
	}
	else {
		my $plist = _decode_list($rawpair);
		if (!$plist) {
			$terr = 'parseerror';
		}
		else {
			foreach my $d (@$plist) {
				next if (!$d->{user});
				push @tablets, {
					uuid        => $d->{user},
					device_uuid => $d->{uuid},
					name        => $d->{name},
					room        => $d->{room},
					model       => $d->{model},
					type        => 'tablet',
				};
			}
		}
	}

	my %listed = map { $_->{uuid} => 1 } @tablets;
	foreach my $u (@control_users) {
		next if ( $listed{ $u->{uuid} } );
		push @tablets, {
			uuid        => $u->{uuid},
			device_uuid => $u->{pairedControl},
			name        => $u->{name},
			type        => 'tablet',
		};
	}

	_dbg( "users: " . join( ', ', map { "$_->{name} ($_->{type})" } @users ) );
	_dbg( "tablets: " . ( @tablets ? join( ', ', map { $_->{name} // $_->{uuid} } @tablets ) : 'none' ) );
	_log( 'WARN', "tablet list unusable: $terr" ) if ($terr);
	return {
		ok            => 1,
		users         => \@users,
		tablets       => \@tablets,
		tablets_error => $terr,
	};
}

##################################################################
# FTP: the only way to see and read foreign sortings
#
# getusersettings always answers for the LOGGED-IN user, so it cannot tell us
# who has a sorting at all, nor read somebody else's as a source.
##################################################################

our $SORTING_DIR = '/user/custom';

# Test hook: sub ($msnr) -> FTP object
our $ftp_factory;

sub ftp_connect
{
	my ($msnr) = @_;
	return $ftp_factory->($msnr) if ($ftp_factory);

	my %miniservers = LoxBerry::System::get_miniservers();
	my $msc = $miniservers{$msnr};
	return undef if (!$msc);

	my $port = LoxBerry::System::get_ftpport($msnr);
	_dbg( "FTP: connecting to $msc->{IPAddress}:" . ( $port ? $port : 21 ) . " as $msc->{Admin_RAW}" );
	my $ftp = Net::FTP->new( $msc->{IPAddress},
		Port    => ( $port ? $port : 21 ),
		Timeout => 15,
		Passive => 1,
	);
	if (!$ftp) {
		_log( 'ERR', "FTP: connect to $msc->{IPAddress} failed: $@" );
		return undef;
	}
	if ( ! $ftp->login( $msc->{Admin_RAW}, $msc->{Pass_RAW} ) ) {
		_log( 'ERR', "FTP: login as $msc->{Admin_RAW} failed: " . $ftp->message );
		$ftp->quit;
		return undef;
	}
	$ftp->binary();
	_dbg("FTP: logged in");
	return $ftp;
}

# Which sortings exist, keyed by user UUID. Only .json files count - the
# directory also holds older .xml leftovers that are none of our business.
# Listing and reading work on an open connection, so the inventory can do all
# of it over one login instead of one per file.
sub _ftp_list
{
	my ($ftp) = @_;
	my %files;
	foreach my $path ( $ftp->ls($SORTING_DIR) ) {
		my $name = $path;
		$name =~ s{.*/}{};
		next if ($name !~ /^(.+)\.json$/);
		my $uuid = $1;
		my $size = $ftp->size($path);
		$files{$uuid} = defined $size ? $size : 0;
	}
	_dbg( "FTP: " . scalar( keys %files ) . " sorting files in $SORTING_DIR" );
	return \%files;
}

sub _ftp_read
{
	my ($ftp, $uuid) = @_;
	my $raw = '';
	CORE::open( my $fh, '>', \$raw ) or return { ok => 0, error => 'ioerror' };
	my $got = $ftp->get( "$SORTING_DIR/$uuid.json", $fh );
	close($fh);
	if (!$got) {
		_log( 'WARN', "read $uuid.json: not found" );
		return { ok => 0, error => 'notfound' };
	}
	my $p = parse_sorting($raw);
	return { ok => 0, error => $p->{error} } if (!$p->{ok});
	_dbg( "read $uuid.json: " . length($raw) . " bytes, ts $p->{ts}" );
	return { ok => 1, ts => $p->{ts}, data => $p->{data}, raw => $raw };
}

sub list_sortings
{
	my ($msnr) = @_;
	my $ftp = ftp_connect($msnr);
	return { ok => 0, error => 'ftpfailed' } if (!$ftp);
	my $files = _ftp_list($ftp);
	$ftp->quit;
	return { ok => 1, files => $files };
}

sub read_sorting
{
	my ($msnr, $uuid) = @_;
	return { ok => 0, error => 'nouuid' } if (!$uuid);

	my $ftp = ftp_connect($msnr);
	return { ok => 0, error => 'ftpfailed' } if (!$ftp);
	my $r = _ftp_read( $ftp, $uuid );
	$ftp->quit;
	return $r;
}

# Only used for managed tablets. Normal users are written through
# setusersettings, because the Miniserver keeps their settings in RAM and never
# re-reads the file while running.
sub write_sorting_ftp
{
	my ($msnr, $uuid, $raw) = @_;
	return { ok => 0, error => 'nouuid' } if (!$uuid);

	my $ftp = ftp_connect($msnr);
	return { ok => 0, error => 'ftpfailed' } if (!$ftp);

	my $copy = $raw;
	_dbg( "FTP: writing $SORTING_DIR/$uuid.json (" . length($raw) . " bytes)" );
	CORE::open( my $fh, '<', \$copy ) or do { $ftp->quit; return { ok => 0, error => 'ioerror' }; };
	my $put = $ftp->put( $fh, "$SORTING_DIR/$uuid.json" );
	close($fh);
	$ftp->quit;
	if (!$put) {
		_log( 'ERR', "FTP: writing $uuid.json failed" );
		return { ok => 0, error => 'writefailed' };
	}
	_dbg("FTP: $uuid.json written");
	return { ok => 1 };
}

##################################################################
# The full picture: who exists, and who has a sorting
##################################################################

sub inventory
{
	my ($msnr, %opts) = @_;

	my $ut = users_and_tablets($msnr);
	return $ut if (! $ut->{ok});

	# One FTP login for the listing and every file. keep_raw hands the contents
	# on, so a backup does not read every file a second time.
	my $ftp   = ftp_connect($msnr);
	my $files = $ftp ? { ok => 1, files => _ftp_list($ftp) } : { ok => 0, error => 'ftpfailed' };
	my %have  = $files->{ok} ? %{ $files->{files} } : ();

	my @entries;
	foreach my $e ( @{ $ut->{users} }, @{ $ut->{tablets} } ) {
		my %row = %$e;
		if ( exists $have{ $row{uuid} } ) {
			$row{has_sorting} = 1;
			$row{bytes}       = $have{ $row{uuid} };
			my $r = _ftp_read( $ftp, $row{uuid} );
			$row{ts}  = $r->{ok} ? $r->{ts} : undef;
			$row{raw} = $r->{raw} if ( $opts{keep_raw} and $r->{ok} );
			delete $have{ $row{uuid} };
		}
		else {
			$row{has_sorting} = 0;
			$row{ts}          = undef;
		}
		push @entries, \%row;
	}

	# Whatever is left belongs to no user: device UUIDs, control UUIDs, or
	# accounts that were deleted. Reported, never written to.
	$ftp->quit if ($ftp);
	my @orphans = sort keys %have;
	_log( 'INF', sprintf( 'inventory: %d entries, %d with sorting, %d orphaned files',
	                      scalar(@entries), scalar( grep { $_->{has_sorting} } @entries ), scalar(@orphans) ) );
	_dbg( "inventory: " . join( ', ', map { "$_->{name}=" . ( $_->{has_sorting} ? "ts " . ( $_->{ts} // '?' ) : 'none' ) } @entries ) );
	_log( 'WARN', "inventory: FTP listing failed ($files->{error})" ) if (! $files->{ok});

	return {
		ok            => 1,
		entries       => \@entries,
		orphans       => \@orphans,
		ftp_error     => ( $files->{ok} ? undef : $files->{error} ),
		tablets_error => $ut->{tablets_error},
	};
}

##################################################################
# Copying
#
# Normal user  -> setusersettings with a token. Takes effect immediately.
# Managed tablet -> FTP plus a reboot, because a tablet has no known password:
#   it rotates to a random value when the device is paired and only lives in
#   the device's secure storage.
##################################################################

# Either copy from a source user, or write a body the caller brings along -
# that is what a restore does.
sub _source_data
{
	my ($msnr, $src_uuid, $raw) = @_;

	if ( defined $raw ) {
		_dbg( "source: template from the archive (" . length($raw) . " bytes)" );
		my $p = parse_sorting($raw);
		return ( undef, $p->{error} ) if (! $p->{ok});
		return ( $p->{data}, undef );
	}
	return ( undef, 'nosource' ) if (!$src_uuid);
	_dbg("source: reading $src_uuid");

	my $src = read_sorting($msnr, $src_uuid);
	return ( undef, $src->{error} ) if (! $src->{ok});
	return ( $src->{data}, undef );
}

# The source is addressed by UUID (that is how the files are named), the target
# by NAME: setusersettings writes for the logged-in user, and the token is
# issued for that name.
# The Miniserver's own administrator is the one user whose password LoxBerry
# already knows. LoxBerry::Auth deliberately ignores the stored password as soon
# as a user is named - which is right for a foreign user, but would make the
# interface ask for a password it already has.
sub _known_password
{
	my ($msnr, $name) = @_;
	return undef if ( !$msnr or !$name );
	my %ms = LoxBerry::System::get_miniservers();
	my $e  = $ms{$msnr};
	return undef if ( !$e or ( $e->{Admin_RAW} // '' ) ne $name );
	return $e->{Pass_RAW};
}

sub copy_to_user
{
	my ($msnr, $src_uuid, $target_name, %opts) = @_;
	return { ok => 0, error => 'notarget' } if (!$target_name);

	my ($data, $err) = _source_data( $msnr, $src_uuid, $opts{raw} );
	return { ok => 0, error => $err, message => 'source unreadable' } if (!$data);

	my $ts   = lox_now();
	my $body = restamp( $data, $ts );

	my $password = defined $opts{password} ? $opts{password}
	                                      : _known_password( $msnr, $target_name );

	_dbg( "user $target_name: restamped to ts $ts, " . length($body) . " bytes" );
	_dbg( "user $target_name: password supplied: " . ( defined $opts{password} ? 'yes (entered)'
	      : defined $password ? 'yes (LoxBerry Miniserver credentials)' : 'no - a stored token is needed' ) );
	# Only the app right: writing one's own sorting needs nothing more, and a
	# normal user does not have SysWS - asking for the default 0x104 makes the
	# Miniserver refuse the token with 412.
	my %authopts = ( user => $target_name, method => 'POST', content => $body,
	                 perm => $LoxBerry::Auth::PERM_APP );
	$authopts{password} = $password if ( defined $password );

	_dbg("user $target_name: POST /jdev/sps/setusersettings");
	my ($resp, $info) = LoxBerry::Auth::request( $msnr, '/jdev/sps/setusersettings', %authopts );
	if ( $info->{error} ) {
		_log( 'ERR', "user $target_name: setusersettings failed - " . ( $info->{errcode} || 'httperror' )
		             . ( $info->{message} ? " ($info->{message})" : '' ) );
		return {
			ok      => 0,
			error   => ( $info->{errcode} || 'httperror' ),
			message => $info->{message},
		};
	}

	# Read it back unless the caller opted out. A 200 only says the Miniserver
	# accepted the request, not that it stored what we sent.
	if ( !defined $opts{verify} or $opts{verify} ) {
		my %vopts = ( user => $target_name, perm => $LoxBerry::Auth::PERM_APP );
		$vopts{password} = $password if ( defined $password );
		_dbg("user $target_name: verifying via GET /jdev/sps/getusersettings");
		my ($back) = LoxBerry::Auth::request( $msnr, '/jdev/sps/getusersettings', %vopts );
		_log( 'WARN', "user $target_name: verify read gave no answer - write is assumed to be done" ) if ( !defined $back );
		_dbg("user $target_name: verified, Miniserver reports ts $ts") if ( defined $back and index($back, "$ts") >= 0 );
		if ( defined $back and index($back, "$ts") < 0 ) {
			_log( 'ERR', "user $target_name: verify failed - the Miniserver did not report ts $ts back" );
			return { ok => 0, error => 'verifyfailed',
			         message => 'the Miniserver did not report the new timestamp back' };
		}
	}

	return { ok => 1, ts => $ts, controls => control_count($data), target => $target_name };
}

sub copy_to_tablet
{
	my ($msnr, $src_uuid, $tablet_uuid, %opts) = @_;
	return { ok => 0, error => 'notarget' } if (!$tablet_uuid);

	my ($data, $err) = _source_data( $msnr, $src_uuid, $opts{raw} );
	return { ok => 0, error => $err, message => 'source unreadable' } if (!$data);

	my $ts   = lox_now();
	my $body = restamp( $data, $ts );

	_dbg( "tablet $tablet_uuid: restamped to ts $ts, " . length($body) . " bytes" );
	my $w = write_sorting_ftp( $msnr, $tablet_uuid, $body );
	return { ok => 0, error => $w->{error} } if (! $w->{ok});

	# The reboot is deliberately NOT done here: writing three tablets should
	# reboot once, not three times. The caller decides.
	return {
		ok           => 1,
		ts           => $ts,
		controls     => control_count($data),
		target       => $tablet_uuid,
		needs_reboot => 1,
	};
}

# Needs the Sys-WS right, which the default permission 0x104 of LoxBerry::Auth
# includes.
sub reboot_miniserver
{
	my ($msnr) = @_;
	_log( 'WARN', "Miniserver $msnr: requesting a reboot (GET /jdev/sys/reboot)" );
	my ($resp, $info) = LoxBerry::Auth::request( $msnr, '/jdev/sys/reboot' );
	_log( $info->{error} ? 'ERR' : 'OK', "Miniserver $msnr: reboot " . ( $info->{error}
	      ? 'failed - ' . ( $info->{errcode} || 'httperror' ) . ( $info->{message} ? " ($info->{message})" : '' ) : 'accepted' ) );
	return { ok => 0, error => ( $info->{errcode} || 'httperror' ), message => $info->{message} }
		if ( $info->{error} );
	return { ok => 1 };
}

##################################################################
# Job runner
#
# A copy over several targets - a reboot in particular - does not fit into a CGI
# timeout. The job therefore runs detached and writes its progress after every
# target, so the web interface can follow along.
##################################################################

our $job_file;

sub job_file
{
	return $job_file if ($job_file);
	my $dir = "/var/run/shm/" . ( $LoxBerry::System::lbpplugindir || 'sortingmanager' );
	return "$dir/job.json";
}

sub _write_job
{
	my ($state) = @_;
	# Whoever writes the state is the job - that is how a later caller finds
	# out whether the process is still alive.
	$state->{pid} = $$ if ( !defined $state->{pid} );
	my $file = job_file();
	return if (!$file);
	my $dir = $file;
	$dir =~ s{/[^/]+$}{};
	if ( ! -d $dir ) {
		eval { File::Path::make_path($dir) };
	}
	if ( CORE::open( my $fh, '>', $file ) ) {
		flock($fh, LOCK_EX);
		print $fh JSON->new->pretty->canonical(1)->encode($state);
		close($fh);
	}
}

# The job runner is a separate process, so the caller - a CGI with a timeout of
# its own - is free the moment it has been started. Which process that is can be
# replaced for the tests.
our $spawn_hook;
our $job_runner;

sub job_spec_file
{
	my $file = job_file();
	return undef if (!$file);
	$file =~ s{/[^/]+$}{/job.spec};
	return $file;
}

# "Is one still running?" cannot be answered from the state alone: a crashed job
# leaves its last state behind for good. The PID decides - and in the moment
# between the start and the child's first sign of life there is none yet, so a
# short grace period stands in for it.
sub _job_running
{
	my $st = job_status();
	return 0 if ( !$st or ( $st->{state} // '' ) eq 'done' );

	my $pid = $st->{pid} || 0;
	return ( kill( 0, $pid ) ? 1 : 0 ) if ( $pid > 1 );
	return ( ( _now() - ( $st->{started} || 0 ) ) < 30 ) ? 1 : 0;
}

sub spawn_job
{
	my ($spec) = @_;
	return { ok => 0, error => 'nospec' } if ( ref($spec) ne 'HASH' );
	return { ok => 0, error => 'jobrunning' } if ( _job_running() );

	my $file = job_spec_file();
	return { ok => 0, error => 'nojobdir' } if (!$file);
	my $dir = $file;
	$dir =~ s{/[^/]+$}{};
	if ( ! -d $dir ) {
		eval { make_path($dir) };
		return { ok => 0, error => 'nojobdir' } if ( ! -d $dir );
	}

	# The spec can carry passwords for the target users - it lives in RAM and
	# nobody but us may read it.
	return { ok => 0, error => 'nojobdir' } if ( ! sysopen( my $fh, $file, O_WRONLY | O_CREAT | O_TRUNC, 0600 ) );
	print $fh JSON->new->canonical(1)->encode($spec);
	close($fh);
	chmod 0600, $file;

	_write_job( {
		state   => 'starting',
		pid     => 0,
		kind    => $spec->{kind},
		msnr    => $spec->{msnr},
		# A restore names its archive, so a second tab can show its progress
		( $spec->{file} ? ( file => $spec->{file} ) : () ),
		started => _now(),
		total   => scalar( @{ $spec->{targets} || [] } ),
		done    => 0,
		results => [],
	} );

	my $runner = $job_runner || "$LoxBerry::System::lbpbindir/sm_job.pl";
	_dbg( "job: starting $spec->{kind} for Miniserver " . ( $spec->{msnr} // '?' ) );
	my $pid;
	if ($spawn_hook) {
		$pid = $spawn_hook->( $runner, $file );
	}
	else {
		$pid = _double_fork($runner);
		return { ok => 0, error => 'forkfailed' } if (!$pid);
	}

	return { ok => 1, pid => $pid };
}

# Two forks with setsid in between: the middle process dies right away, so the
# runner is orphaned and adopted by init instead of hanging off the web server.
# Its PID travels back through a pipe - without it nobody could tell later
# whether the job is still alive.
sub _double_fork
{
	my ($runner) = @_;
	return undef if ( ! pipe( my $rd, my $wr ) );

	my $mid = fork();
	return undef if (!defined $mid);

	if ( $mid == 0 ) {
		close($rd);
		POSIX::setsid();
		my $child = fork();
		if ( !defined $child ) { POSIX::_exit(1); }
		if ( $child != 0 ) {
			print $wr "$child\n";
			close($wr);
			POSIX::_exit(0);
		}
		close($wr);
		CORE::open( STDIN,  '<', '/dev/null' );
		CORE::open( STDOUT, '>', '/dev/null' );
		CORE::open( STDERR, '>', '/dev/null' );
		# Hand our own search path on: on a normal installation PERL5LIB carries
		# the LoxBerry libraries anyway, but a caller started with -I (a working
		# copy, a test) would otherwise leave the runner unable to load them.
		exec( $^X, ( map { "-I$_" } grep { !ref($_) and -d $_ } @INC ), $runner )
			or POSIX::_exit(1);
	}

	close($wr);
	my $pid = <$rd>;
	close($rd);
	waitpid( $mid, 0 );
	chomp($pid) if ( defined $pid );
	return ( $pid && $pid =~ /^\d+$/ ) ? $pid : undef;
}

sub job_status
{
	my $file = job_file();
	return undef if (!$file or ! -e $file);
	my $st;
	eval { $st = JSON::from_json( _slurp($file) ); };
	return undef if ($@ or ref($st) ne 'HASH');
	return $st;
}

# One failure does not stop the others - the result is a list "target -> ok or
# reason". The reboot happens once, at the end, and only if a tablet was
# actually written.
sub run_copy_job
{
	my ($msnr, $spec) = @_;

	my @targets = @{ $spec->{targets} || [] };
	my %state = (
		state          => 'running',
		kind           => 'copy',
		msnr           => $msnr,
		source         => $spec->{source},
		total          => scalar(@targets),
		done           => 0,
		failed         => 0,
		started        => lox_now(),
		results        => [],
		reboot_pending => 0,
	);
	_write_job( \%state );

	my $tablet_written = 0;
	_log( 'INF', "copy: source $spec->{source} to " . scalar(@targets) . " targets"
	             . ( $spec->{auto_reboot} ? ', reboot afterwards if a tablet was written' : '' ) );
	if ( ref( $spec->{passwords} ) eq 'HASH' and %{ $spec->{passwords} } ) {
		_dbg( "copy: passwords entered for " . join( ', ', sort keys %{ $spec->{passwords} } ) );
	}
	my $n = 0;

	foreach my $t (@targets) {
		$n++;
		_dbg( sprintf( 'copy: target %d/%d: %s (%s, %s)', $n, scalar(@targets), $t->{name} // '?',
		               $t->{type} // '?', ( ( $t->{type} // '' ) eq 'tablet' ? 'FTP + reboot' : 'token' ) ) );
		# The interface marks the target being worked on
		$state{current} = defined $t->{uuid} ? $t->{uuid} : $t->{name};
		_write_job( \%state );

		my $res;
		if ( ($t->{type} || '') eq 'tablet' ) {
			$res = copy_to_tablet( $msnr, $spec->{source}, $t->{uuid} );
			$tablet_written = 1 if ( $res->{ok} );
		}
		else {
			my %o;
			$o{password} = $spec->{passwords}{ $t->{name} }
				if ( ref($spec->{passwords}) eq 'HASH' and defined $spec->{passwords}{ $t->{name} } );
			$res = copy_to_user( $msnr, $spec->{source}, $t->{name}, %o );
		}

		push @{ $state{results} }, {
			name     => $t->{name},
			uuid     => $t->{uuid},
			type     => $t->{type},
			ok       => ( $res->{ok} ? 1 : 0 ),
			ts       => $res->{ts},
			controls => $res->{controls},
			error    => $res->{error},
			message  => $res->{message},
		};
		$state{done}++;
		$state{failed}++ if (! $res->{ok});
		$res->{ok}
			? _log( 'OK', "copy: $t->{name}: copied, ts $res->{ts}" . ( defined $res->{controls} ? ", $res->{controls} controls" : '' ) )
			: _log( 'ERR', "copy: $t->{name}: " . ( $res->{error} // '?' ) . ( $res->{message} ? " ($res->{message})" : '' ) );
		_write_job( \%state );
	}
	delete $state{current};
	_log( 'INF', sprintf( 'copy: %d of %d targets copied', $state{done} - $state{failed}, $state{done} ) );
	_log( 'INF', 'copy: a tablet was written - reboot ' . ( $spec->{auto_reboot} ? 'follows' : 'required, not triggered' ) )
		if ($tablet_written);

	if ( $tablet_written ) {
		if ( $spec->{auto_reboot} ) {
			$state{state} = 'rebooting';
			_write_job( \%state );
			my $rb = reboot_miniserver($msnr);
			$state{reboot_ok}    = $rb->{ok} ? 1 : 0;
			$state{reboot_error} = $rb->{error};
		}
		else {
			$state{reboot_pending} = 1;
		}
	}

	$state{state}    = 'done';
	$state{finished} = lox_now();
	_write_job( \%state );
	return \%state;
}


##################################################################
# Backup
#
# An archive holds the sorting files of everyone who still exists - filtered
# against the user list and the tablet list. Orphaned device and control files
# stay out: an archive where every file has an owner is self-explanatory when
# it is restored.
##################################################################

our $backup_dir;

sub backup_dir
{
	return $backup_dir if ($backup_dir);
	# Outside a plugin context $lbpdatadir is empty - the path would degenerate
	# to "/backups". Better no directory at all than one at the root.
	return undef if ( !$LoxBerry::System::lbpdatadir );
	return "$LoxBerry::System::lbpdatadir/backups";
}

# The serial number carries colons, which have no business in a file name.
sub _serial_slug
{
	my ($serial) = @_;
	my $slug = uc( $serial || 'unknown' );
	$slug =~ s/[^A-Z0-9]//g;
	return $slug;
}

sub create_backup
{
	my ($msnr, %opts) = @_;

	my $s = ms_serial($msnr);
	return { ok => 0, error => $s->{error} } if (! $s->{ok});

	my $inv = inventory( $msnr, keep_raw => 1 );
	return { ok => 0, error => ( $inv->{error} || 'inventoryfailed' ) } if (! $inv->{ok});

	my $dir = backup_dir();
	return { ok => 0, error => 'nobackupdir' } if (!$dir);
	if ( ! -d $dir ) {
		eval { make_path($dir) };
		return { ok => 0, error => 'nobackupdir', message => $@ } if ( ! -d $dir );
	}

	my $now = lox_now();
	my $tar = Archive::Tar->new();
	my @manifest_entries;
	_log( 'INF', "backup: Miniserver $msnr ($s->{serial}), " . scalar( @{ $inv->{entries} } ) . " users and tablets"
	             . ( $opts{trigger} ? ", trigger $opts{trigger}" : '' ) );

	foreach my $e ( @{ $inv->{entries} } ) {
		if (! $e->{has_sorting}) {
			_dbg("backup: $e->{name} has no sorting - skipped");
			next;
		}
		# The inventory has read it already; only fall back to reading again
		my $r = defined $e->{raw} ? { ok => 1, raw => $e->{raw}, ts => $e->{ts} } : read_sorting( $msnr, $e->{uuid} );
		if (! $r->{ok}) {
			_log( 'WARN', "backup: $e->{name} could not be read ($r->{error}) - skipped" );
			next;
		}
		_dbg( "backup: added $e->{name} ($e->{type}, $e->{uuid}): " . length( $r->{raw} ) . " bytes, ts $r->{ts}" );

		$tar->add_data( "sortings/$e->{uuid}.json", $r->{raw} );
		push @manifest_entries, {
			uuid  => $e->{uuid},
			name  => $e->{name},
			type  => $e->{type},
			ts    => $r->{ts},
			bytes => length( $r->{raw} ),
		};
	}

	my $manifest = {
		created        => $now,
		created_iso    => POSIX::strftime( '%Y-%m-%dT%H:%M:%S%z',
		                                   localtime( lox2unix($now) ) ),
		miniserver     => { serial => $s->{serial}, firmware => $s->{firmware}, msnr => $msnr },
		plugin_version => $VERSION,
		trigger        => ( ( $opts{trigger} // '' ) eq 'schedule' ? 'schedule' : 'manual' ),
		entries        => \@manifest_entries,
	};
	$tar->add_data( 'manifest.json',
		JSON->new->pretty->canonical(1)->encode($manifest) );

	my $stamp = POSIX::strftime( '%Y%m%d_%H%M%S',
	                             localtime( lox2unix($now) ) );
	my $file  = sprintf( '%s/sorting_%s_%s.tar.gz', $dir, _serial_slug($s->{serial}), $stamp );

	if ( ! $tar->write( $file, Archive::Tar::COMPRESS_GZIP() ) ) {
		return { ok => 0, error => 'writefailed' };
	}
	chmod 0600, $file;
	_log( 'OK', "backup: written $file - " . scalar(@manifest_entries) . " entries, " . ( -s $file ) . " bytes" );

	_prune_backups( $s->{serial}, $opts{keep} ) if ( defined $opts{keep} );

	return {
		ok      => 1,
		file    => $file,
		entries => scalar(@manifest_entries),
		bytes   => ( -s $file ),
		serial  => $s->{serial},
	};
}

# Reads the manifest of every archive so the list can be shown without
# unpacking anything.
sub list_backups
{
	my ($serial) = @_;
	my $dir  = backup_dir();
	my $slug = _serial_slug($serial);
	return [] if ( !$dir or ! -d $dir );

	my @out;
	opendir( my $dh, $dir ) or return [];
	foreach my $name ( readdir($dh) ) {
		next if ( $name !~ /^sorting_\Q$slug\E_.*\.tar\.gz$/ );
		my $file = "$dir/$name";

		my $entries;
		my $created;
		my $firmware;
		# Archives from before the trigger field were all written by the schedule
		# or by hand - "schedule" is the more likely one.
		my $trigger = 'schedule';
		my $tar = Archive::Tar->new();
		if ( eval { $tar->read($file) } ) {
			my $man;
			eval { $man = JSON::from_json( $tar->get_content('manifest.json') ); };
			if ( ref($man) eq 'HASH' ) {
				$entries  = scalar( @{ $man->{entries} || [] } );
				$created  = $man->{created};
				$firmware = $man->{miniserver}{firmware} if ( ref( $man->{miniserver} ) eq 'HASH' );
				$trigger  = $man->{trigger} if ( $man->{trigger} );
			}
		}
		push @out, {
			trigger  => $trigger,
			firmware => $firmware,
			file    => $file,
			name    => $name,
			bytes   => ( -s $file ),
			mtime   => ( stat($file) )[9],
			entries => $entries,
			created => $created,
		};
	}
	closedir($dh);

	@out = sort { ( $b->{created} || $b->{mtime} ) <=> ( $a->{created} || $a->{mtime} ) } @out;
	return \@out;
}

sub _prune_backups
{
	my ($serial, $keep) = @_;
	return if ( !defined $keep or $keep <= 0 );
	my $list = list_backups($serial);
	_dbg( "prune: " . scalar(@$list) . " archives, keeping $keep" );
	return if ( scalar(@$list) <= $keep );
	foreach my $old ( @{$list}[ $keep .. $#$list ] ) {
		unlink( $old->{file} )
			? _log( 'INF', "prune: removed $old->{name}" )
			: _log( 'WARN', "prune: could not remove $old->{name}: $!" );
	}
}

# Answers what a restore would do, and changes nothing. The web interface asks
# this before showing the confirmation dialog.
sub check_restore
{
	my ($file) = @_;
	return { ok => 0, error => 'notfound' } if ( !$file or ! -e $file );

	my $tar = Archive::Tar->new();
	return { ok => 0, error => 'unreadable' } if ( ! eval { $tar->read($file) } );

	my $man;
	eval { $man = JSON::from_json( $tar->get_content('manifest.json') ); };
	return { ok => 0, error => 'nomanifest' } if ( $@ or ref($man) ne 'HASH' );

	return { ok => 1, manifest => $man, missing => [], file => $file };
}

# check_restore plus, per entry, whether the user still exists and the state of
# their sorting right now - the restore view compares both before anything is
# overwritten.
sub restore_preview
{
	my ($msnr, $file) = @_;
	my $c = check_restore($file);
	return $c if (! $c->{ok});
	my %now;
	my $inv = inventory($msnr);
	if ( $inv->{ok} ) {
		$now{ $_->{uuid} } = $_ foreach ( @{ $inv->{entries} } );
	}
	foreach my $e ( @{ $c->{manifest}{entries} || [] } ) {
		my $n = $now{ $e->{uuid} };
		$e->{alive}      = $n ? 1 : 0;
		$e->{current_ts} = $n ? $n->{ts} : undef;
		$e->{type_now}   = $n ? $n->{type} : undef;
	}
	return $c;
}

# Free bytes on the file system holding $dir, undef if that cannot be told.
sub free_bytes
{
	my ($dir) = @_;
	return undef if ( !$dir or ! -d $dir );
	open( my $df, '-|', 'df', '-Pk', '--', $dir ) or return undef;
	my @lines = <$df>;
	close($df);
	return undef if ( @lines < 2 );
	my @f = split( /\s+/, $lines[-1] );
	return ( defined $f[3] and $f[3] =~ /^\d+$/ ) ? $f[3] * 1024 : undef;
}

##################################################################
# Restore
#
# Goes the same way as a copy - normal users through a token, tablets through
# FTP and a reboot - and always with a FRESH timestamp. A restore carrying the
# archive's own timestamp would never reach the apps: they only load a state
# that is newer than their own, and would push theirs instead.
##################################################################

sub restore_backup
{
	my ($msnr, $file, %opts) = @_;

	my $c = check_restore($file);
	if (! $c->{ok}) {
		_log( 'ERR', "restore: $file unusable ($c->{error})" );
		return { ok => 0, error => $c->{error} };
	}
	_log( 'INF', "restore: $file, " . scalar( @{ $c->{manifest}{entries} || [] } ) . " entries in the archive"
	             . ( ref( $opts{only} ) eq 'ARRAY' ? ', ' . scalar( @{ $opts{only} } ) . ' selected' : ', all' ) );

	my $tar = Archive::Tar->new();
	return { ok => 0, error => 'unreadable' } if ( ! eval { $tar->read($file) } );

	# Who exists right now? The archive may be older than the user list.
	my $inv = inventory($msnr);
	my %known;
	if ( $inv->{ok} ) {
		$known{ $_->{uuid} } = $_ foreach ( @{ $inv->{entries} } );
	}

	my %wanted;
	if ( ref($opts{only}) eq 'ARRAY' ) {
		$wanted{$_} = 1 foreach ( @{ $opts{only} } );
	}

	my @results;
	my @missing;
	my $tablet_written = 0;

	# progress: called before every entry and once at the end, so the job can
	# show which entry is being written.
	my @todo = grep { ( !%wanted or $wanted{ $_->{uuid} } ) and $known{ $_->{uuid} } }
	           @{ $c->{manifest}{entries} || [] };
	my $report = sub {
		my ($cur) = @_;
		return if ( ref($opts{progress}) ne 'CODE' );
		$opts{progress}->( {
			total   => scalar(@todo),
			done    => scalar(@results),
			failed  => scalar( grep { !$_->{ok} } @results ),
			results => [ @results ],
			missing => [ @missing ],
			( defined $cur ? ( current => $cur ) : () ),
		} );
	};

	foreach my $e ( @{ $c->{manifest}{entries} || [] } ) {
		if ( %wanted and ! $wanted{ $e->{uuid} } ) {
			_dbg("restore: $e->{name} not selected - skipped");
			next;
		}

		my $current = $known{ $e->{uuid} };
		if ( !$current ) {
			_log( 'WARN', "restore: $e->{name} ($e->{uuid}) no longer exists - skipped" );
			push @missing, { uuid => $e->{uuid}, name => $e->{name}, type => $e->{type} };
			next;
		}
		$report->( $e->{uuid} );
		_dbg( "restore: $current->{name} ($current->{type}), archived ts " . ( $e->{ts} // '?' ) );

		my $raw = $tar->get_content("sortings/$e->{uuid}.json");
		if ( !defined $raw ) {
			push @results, { uuid => $e->{uuid}, name => $e->{name}, ok => 0,
			                 error => 'missinginarchive' };
			next;
		}

		my $res;
		if ( ( $current->{type} || '' ) eq 'tablet' ) {
			$res = copy_to_tablet( $msnr, undef, $e->{uuid}, raw => $raw );
			$tablet_written = 1 if ( $res->{ok} );
		}
		else {
			my %o = ( raw => $raw );
			$o{password} = $opts{passwords}{ $current->{name} }
				if ( ref($opts{passwords}) eq 'HASH'
				     and defined $opts{passwords}{ $current->{name} } );
			$res = copy_to_user( $msnr, undef, $current->{name}, %o );
		}

		$res->{ok}
			? _log( 'OK', "restore: $current->{name}: restored, ts $res->{ts}" )
			: _log( 'ERR', "restore: $current->{name}: " . ( $res->{error} // '?' ) . ( $res->{message} ? " ($res->{message})" : '' ) );
		push @results, {
			uuid     => $e->{uuid},
			name     => $current->{name},
			type     => $current->{type},
			ok       => ( $res->{ok} ? 1 : 0 ),
			ts       => $res->{ts},
			controls => $res->{controls},
			error    => $res->{error},
			message  => $res->{message},
		};
	}

	$report->(undef);

	my $reboot_pending = 0;
	if ( $tablet_written ) {
		if ( $opts{auto_reboot} ) {
			reboot_miniserver($msnr);
		}
		else {
			$reboot_pending = 1;
		}
	}

	return {
		ok             => 1,
		results        => \@results,
		missing        => \@missing,
		reboot_pending => $reboot_pending,
	};
}

# A file name coming from a browser must never reach the filesystem unchecked.
# Only a plain archive name directly inside the backup directory passes.
sub safe_backup_file
{
	my ($file) = @_;
	return undef if ( !$file or $file =~ m{\.\.} );
	my $dir = backup_dir();
	return undef if (!$dir);
	return ( $file =~ m{^\Q$dir\E/[^/]+\.tar\.gz$} ) ? $file : undef;
}

sub delete_backup
{
	my ($file) = @_;
	return { ok => 0, error => 'notfound' } if ( !$file or ! -e $file );
	if ( ! unlink($file) ) {
		_log( 'ERR', "delete: $file could not be removed: $!" );
		return { ok => 0, error => 'deletefailed' };
	}
	_log( 'INF', "delete: $file removed" );
	return { ok => 1 };
}

##################################################################
# Watch
#
# The cron entry point runs every five minutes and asks here whether anything
# is due. Keeping the decision in the module - and out of the cron script -
# means it can be tested without a clock and without a Miniserver.
##################################################################

our $now_hook;

sub _now { return $now_hook ? $now_hook->() : lox_now(); }

sub watch_due
{
	my ($entry, $now) = @_;
	return 0 if ( ref($entry) ne 'HASH' );
	my $w = $entry->{watch};
	return 0 if ( ref($w) ne 'HASH' or !$w->{enabled} );

	$now = _now() if (!defined $now);
	return 1 if ( !$w->{last_run} );
	return ( ( $now - $w->{last_run} ) >= ( $w->{interval_min} || 15 ) * 60 ) ? 1 : 0;
}

# Weekday, time of day and the week interval - all three have to agree. The
# week interval is counted as full weeks BETWEEN two runs: with every_weeks 1
# every selected weekday runs, which is what a plan like "Monday and Thursday"
# means; only from 2 upwards does a waiting period apply.
sub backup_due
{
	my ($entry, $now) = @_;
	return 0 if ( ref($entry) ne 'HASH' );
	my $s = $entry->{backup}{schedule};
	return 0 if ( ref($s) ne 'HASH' or !$s->{enabled} );

	$now = _now() if (!defined $now);
	my $unix = lox2unix($now);
	my ( $min, $hour, $mday, $mon, $year, $wday ) = ( localtime($unix) )[ 1, 2, 3, 4, 5, 6 ];

	return 0 if ( !grep { $_ == $wday } @{ $s->{days} || [] } );
	return 0 if ( $hour * 60 + $min < ( $s->{hour} || 0 ) * 60 + ( $s->{minute} || 0 ) );

	my $last = $s->{last_run} || 0;
	return 1 if (!$last);

	my $last_unix = lox2unix($last);
	my @lt = localtime($last_unix);
	return 0 if ( $lt[3] == $mday and $lt[4] == $mon and $lt[5] == $year );

	my $min_days = ( ( $s->{every_weeks} || 1 ) - 1 ) * 7;
	return 0 if ( ( $unix - $last_unix ) < $min_days * 86400 );
	return 1;
}

# Detection runs on the timestamp of the source file: if it moved, the user
# rearranged their app and the targets get the new state.
# The watch keeps its last runs for the web interface. Kept out of
# pluginconfig.json: one file per Miniserver, written once per run anyway.
our $history_dir;
our $HISTORY_MAX = 10;

sub history_file
{
	my ($serial) = @_;
	my $dir = $history_dir ? $history_dir : $LoxBerry::System::lbpdatadir;
	return undef if ( !$dir );
	return "$dir/watch_" . _serial_slug($serial) . ".json";
}

# Newest first; a missing or broken file is an empty history.
sub watch_history
{
	my ($serial) = @_;
	my $file = history_file($serial);
	return [] if ( !$file or ! -e $file );
	my $h;
	eval { $h = JSON::from_json( _slurp($file) ); };
	return ( !$@ and ref($h) eq 'ARRAY' ) ? $h : [];
}

sub push_history
{
	my ($serial, $item) = @_;
	my $file = history_file($serial);
	return 0 if (!$file);
	my $dir = $file;
	$dir =~ s{/[^/]+$}{};
	eval { make_path($dir) } if ( ! -d $dir );
	my @h = ( $item, @{ watch_history($serial) } );
	splice( @h, $HISTORY_MAX ) if ( @h > $HISTORY_MAX );
	open( my $fh, '>', "$file.tmp" ) or return 0;
	print $fh JSON->new->canonical(1)->encode( \@h );
	close($fh);
	return rename( "$file.tmp", $file ) ? 1 : 0;
}

# Lox time of the next check, undef while the watch is off.
sub next_watch
{
	my ($entry, $now) = @_;
	my $w = $entry->{watch} || {};
	return undef if ( !$w->{enabled} );
	return $now if ( !$w->{last_run} );
	return $w->{last_run} + ( $w->{interval_min} || 15 ) * 60;
}

sub run_watch
{
	my ($msnr, %opts) = @_;
	my $manual = $opts{manual} ? 1 : 0;

	my $s = ms_serial($msnr);
	return { ok => 0, error => ( $s->{error} || 'notreachable' ) } if (! $s->{ok});

	my $cfg   = plugin_config();
	my $entry = ms_entry( $cfg, $s->{serial} );
	my @targets = @{ $entry->{targets} || [] };

	# Not set up yet: leave last_run alone, otherwise the first real run after
	# the configuration is saved would wait out a whole interval.
	if ( !$entry->{source} or !@targets ) {
		_dbg("watch $s->{serial}: no source or no targets saved - nothing to watch");
		return { ok => 0, skipped => 1, reason => 'notconfigured' };
	}
	_dbg( "watch $s->{serial}: source $entry->{source}, " . scalar(@targets) . " targets"
	      . ( $manual ? ', checked by hand' : '' ) . ( $opts{force} ? ', forced' : '' ) );

	my $now = _now();
	my $r   = read_sorting( $msnr, $entry->{source} );
	if (! $r->{ok}) {
		my $err = $r->{error} || 'notfound';
		push_history( $s->{serial}, { ts => $now, result => 'error', error => $err, manual => $manual } );
		return { ok => 0, error => $err };
	}

	my $seen = $entry->{watch}{last_source_ts} || 0;
	_dbg("watch $s->{serial}: source ts now $r->{ts}, last seen $seen");

	if ( !$opts{force} and "$r->{ts}" eq "$seen" ) {
		$entry->{watch}{last_run} = $now;
		save_config($cfg);
		push_history( $s->{serial}, { ts => $now, result => 'unchanged', manual => $manual } );
		_dbg("watch $s->{serial}: source unchanged - nothing copied");
		return { ok => 1, changed => 0, source_ts => $r->{ts} };
	}

	_log( 'INF', "watch $s->{serial}: source " . ( $opts{force} ? 'copied by force' : 'changed' ) . " - copying" );
	my $job = run_copy_job( $msnr, {
		source      => $entry->{source},
		targets     => \@targets,
		auto_reboot => ( $entry->{watch}{auto_reboot} ? 1 : 0 ),
		passwords   => $opts{passwords},
	} );

	$entry->{watch}{last_source_ts} = $r->{ts};
	$entry->{watch}{last_run}       = $now;
	save_config($cfg);

	my %out = (
		ok        => 1,
		changed   => 1,
		source_ts => $r->{ts},
		copied    => ( $job->{results} || [] ),
	);
	$out{notify} = 'rebootrequired' if ( $job->{reboot_pending} );

	my @res = @{ $job->{results} || [] };
	push_history( $s->{serial}, {
		ts     => $now,
		result => 'changed',
		manual => $manual,
		copied => scalar( grep { $_->{ok} } @res ),
		failed => scalar( grep { !$_->{ok} } @res ),
		reboot => ( $job->{reboot_pending} ? 'pending' : defined $job->{reboot_ok} ? 'done' : undef ),
	} );
	return \%out;
}

#####################################################
# Finally 1; ########################################
#####################################################
1;
