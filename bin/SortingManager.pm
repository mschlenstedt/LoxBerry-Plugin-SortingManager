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
use Fcntl qw( :flock O_RDWR O_CREAT );
use LoxBerry::System;
use LoxBerry::IO;
use Net::FTP;
use File::Path qw( make_path );
use Archive::Tar;
use POSIX ();
use LoxBerry::Auth;

use base 'Exporter';
our @EXPORT_OK = qw(
	lox_now
	parse_sorting
	restamp
	parse_api_value
	control_count
);

our $VERSION = "0.1";
our $DEBUG = 0;

sub _dbg { print STDERR "SortingManager: $_[0]\n" if ($DEBUG); }

##################################################################
# Pure helpers - no I/O, no state
##################################################################

# Seconds since 2009-01-01 00:00:00 UTC, the epoch Loxone uses everywhere.
# Deliberately delegated instead of reimplemented: a second implementation
# would be one timezone bug waiting to happen.
sub lox_now
{
	return LoxBerry::System::epoch2lox();
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
		_dbg("pluginconfig.json is not readable JSON - starting empty");
		return _empty_config();
	}
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
		return 0 if ( defined $old and $old eq $new );
	}

	my $fh;
	if ( ! sysopen($fh, $file, O_RDWR | O_CREAT, 0600) ) {
		_dbg("cannot write $file: $!");
		return undef;
	}
	flock($fh, LOCK_EX);
	seek($fh, 0, 0);
	print $fh $new;
	truncate($fh, tell($fh));
	close($fh);
	chmod 0600, $file;
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

	my ($content, $info) = LoxBerry::IO::mshttp_call2($msnr, '/jdev/cfg/api');
	return ( undef, 'unreachable' ) if (!defined $content);

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

	return { ok => 1, serial => uc($api->{snr}), firmware => $api->{version} };
}

# Every Miniserver from general.json, with its serial number. Entries whose
# serial cannot be determined are still listed, with serial => undef, so the
# web interface can show them as unreachable instead of hiding them.
sub known_miniservers
{
	my %miniservers = LoxBerry::System::get_miniservers();
	my @out;
	foreach my $msnr ( sort { $a <=> $b } keys %miniservers ) {
		my $s = ms_serial($msnr);
		push @out, {
			msnr     => $msnr,
			name     => $miniservers{$msnr}{Name},
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
	my ($content) = LoxBerry::IO::mshttp_call2($msnr, '/jdev/sps/getuserlist2');
	return ( undef, 'unreachable' ) if (!defined $content);
	return ( $content, undef );
}

sub _fetch_pairing
{
	my ($msnr) = @_;
	return $pairing_hook->($msnr) if ($pairing_hook);
	my ($content) = LoxBerry::IO::mshttp_call2($msnr, '/jdev/sps/apppairing/list');
	return ( undef, 'unreachable' ) if (!defined $content);
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

# Two sources, because getuserlist2 does not know the managed tablets. In
# apppairing/list the field "user" is the UUID the sorting file belongs to;
# "uuid" is the device.
sub users_and_tablets
{
	my ($msnr) = @_;

	my ($rawusers, $uerr) = _fetch_userlist($msnr);
	return { ok => 0, error => $uerr || 'unreachable' } if (!defined $rawusers);

	my $ulist = _decode_list($rawusers);
	return { ok => 0, error => 'parseerror' } if (!$ulist);

	my @users;
	foreach my $u (@$ulist) {
		next if (!$u->{uuid});
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
	my $ftp = Net::FTP->new( $msc->{IPAddress},
		Port    => ( $port ? $port : 21 ),
		Timeout => 15,
		Passive => 1,
	);
	if (!$ftp) {
		_dbg("FTP connect to $msc->{IPAddress} failed");
		return undef;
	}
	if ( ! $ftp->login( $msc->{Admin_RAW}, $msc->{Pass_RAW} ) ) {
		_dbg("FTP login failed: " . $ftp->message);
		$ftp->quit;
		return undef;
	}
	$ftp->binary();
	return $ftp;
}

# Which sortings exist, keyed by user UUID. Only .json files count - the
# directory also holds older .xml leftovers that are none of our business.
sub list_sortings
{
	my ($msnr) = @_;
	my $ftp = ftp_connect($msnr);
	return { ok => 0, error => 'ftpfailed' } if (!$ftp);

	my %files;
	foreach my $path ( $ftp->ls($SORTING_DIR) ) {
		my $name = $path;
		$name =~ s{.*/}{};
		next if ($name !~ /^(.+)\.json$/);
		my $uuid = $1;
		my $size = $ftp->size($path);
		$files{$uuid} = defined $size ? $size : 0;
	}
	$ftp->quit;
	return { ok => 1, files => \%files };
}

sub read_sorting
{
	my ($msnr, $uuid) = @_;
	return { ok => 0, error => 'nouuid' } if (!$uuid);

	my $ftp = ftp_connect($msnr);
	return { ok => 0, error => 'ftpfailed' } if (!$ftp);

	my $raw = '';
	CORE::open( my $fh, '>', \$raw ) or do { $ftp->quit; return { ok => 0, error => 'ioerror' }; };
	my $got = $ftp->get( "$SORTING_DIR/$uuid.json", $fh );
	close($fh);
	$ftp->quit;
	return { ok => 0, error => 'notfound' } if (!$got);

	my $p = parse_sorting($raw);
	return { ok => 0, error => $p->{error} } if (!$p->{ok});
	return { ok => 1, ts => $p->{ts}, data => $p->{data}, raw => $raw };
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
	CORE::open( my $fh, '<', \$copy ) or do { $ftp->quit; return { ok => 0, error => 'ioerror' }; };
	my $put = $ftp->put( $fh, "$SORTING_DIR/$uuid.json" );
	close($fh);
	$ftp->quit;
	return { ok => 0, error => 'writefailed' } if (!$put);
	return { ok => 1 };
}

##################################################################
# The full picture: who exists, and who has a sorting
##################################################################

sub inventory
{
	my ($msnr) = @_;

	my $ut = users_and_tablets($msnr);
	return $ut if (! $ut->{ok});

	my $files = list_sortings($msnr);
	my %have  = $files->{ok} ? %{ $files->{files} } : ();

	my @entries;
	foreach my $e ( @{ $ut->{users} }, @{ $ut->{tablets} } ) {
		my %row = %$e;
		if ( exists $have{ $row{uuid} } ) {
			$row{has_sorting} = 1;
			$row{bytes}       = $have{ $row{uuid} };
			my $r = read_sorting( $msnr, $row{uuid} );
			$row{ts} = $r->{ok} ? $r->{ts} : undef;
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
	my @orphans = sort keys %have;

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
		my $p = parse_sorting($raw);
		return ( undef, $p->{error} ) if (! $p->{ok});
		return ( $p->{data}, undef );
	}
	return ( undef, 'nosource' ) if (!$src_uuid);

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

	my %authopts = ( user => $target_name, method => 'POST', content => $body );
	$authopts{password} = $password if ( defined $password );

	my ($resp, $info) = LoxBerry::Auth::request( $msnr, '/jdev/sps/setusersettings', %authopts );
	if ( $info->{error} ) {
		return {
			ok      => 0,
			error   => ( $info->{errcode} || 'httperror' ),
			message => $info->{message},
		};
	}

	# Read it back unless the caller opted out. A 200 only says the Miniserver
	# accepted the request, not that it stored what we sent.
	if ( !defined $opts{verify} or $opts{verify} ) {
		my %vopts = ( user => $target_name );
		$vopts{password} = $password if ( defined $password );
		my ($back) = LoxBerry::Auth::request( $msnr, '/jdev/sps/getusersettings', %vopts );
		if ( defined $back and index($back, "$ts") < 0 ) {
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
	my ($resp, $info) = LoxBerry::Auth::request( $msnr, '/jdev/sys/reboot' );
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

	foreach my $t (@targets) {
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
		_write_job( \%state );
	}

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

	my $inv = inventory($msnr);
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

	foreach my $e ( @{ $inv->{entries} } ) {
		next if (! $e->{has_sorting});
		my $r = read_sorting( $msnr, $e->{uuid} );
		next if (! $r->{ok});

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
		                                   localtime( LoxBerry::System::lox2epoch($now) ) ),
		miniserver     => { serial => $s->{serial}, firmware => $s->{firmware}, msnr => $msnr },
		plugin_version => $VERSION,
		entries        => \@manifest_entries,
	};
	$tar->add_data( 'manifest.json',
		JSON->new->pretty->canonical(1)->encode($manifest) );

	my $stamp = POSIX::strftime( '%Y%m%d_%H%M%S',
	                             localtime( LoxBerry::System::lox2epoch($now) ) );
	my $file  = sprintf( '%s/sorting_%s_%s.tar.gz', $dir, _serial_slug($s->{serial}), $stamp );

	if ( ! $tar->write( $file, Archive::Tar::COMPRESS_GZIP() ) ) {
		return { ok => 0, error => 'writefailed' };
	}
	chmod 0600, $file;

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
		my $tar = Archive::Tar->new();
		if ( eval { $tar->read($file) } ) {
			my $man;
			eval { $man = JSON::from_json( $tar->get_content('manifest.json') ); };
			if ( ref($man) eq 'HASH' ) {
				$entries = scalar( @{ $man->{entries} || [] } );
				$created = $man->{created};
			}
		}
		push @out, {
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
	return if ( scalar(@$list) <= $keep );
	foreach my $old ( @{$list}[ $keep .. $#$list ] ) {
		unlink $old->{file};
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
	return { ok => 0, error => $c->{error} } if (! $c->{ok});

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

	foreach my $e ( @{ $c->{manifest}{entries} || [] } ) {
		next if ( %wanted and ! $wanted{ $e->{uuid} } );

		my $current = $known{ $e->{uuid} };
		if ( !$current ) {
			push @missing, { uuid => $e->{uuid}, name => $e->{name}, type => $e->{type} };
			next;
		}

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

sub delete_backup
{
	my ($file) = @_;
	return { ok => 0, error => 'notfound' } if ( !$file or ! -e $file );
	return { ok => 0, error => 'deletefailed' } if ( ! unlink($file) );
	return { ok => 1 };
}

#####################################################
# Finally 1; ########################################
#####################################################
1;
