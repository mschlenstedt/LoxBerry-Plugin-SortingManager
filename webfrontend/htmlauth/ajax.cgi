#!/usr/bin/perl

# AJAX endpoint for the web interface. Answers JSON, always.
#
# Errors come back as KEYS, not as sentences: the browser owns the language.
# Anything that changes something needs POST - a GET must never rewrite a
# configuration or start a job.

use strict;
use warnings;
use CGI;
use JSON;
use POSIX ();
use LoxBerry::System;
# LoxBerry::System fills $lbpbindir at compile time from our own path
# (webfrontend/htmlauth/plugins/<folder>), so the following "use lib" finds the
# plugin modules without knowing the folder name.
use lib $lbpbindir;
use LoxBerry::Auth;
use SortingManager;

my $cgi    = CGI->new;
my $q      = $cgi->Vars;
my $action = $q->{action} // '';

print "Content-Type: application/json; charset=utf-8\n\n";

sub out { print JSON->new->canonical(1)->encode( $_[0] ); exit 0; }
sub err { out( { ok => 0, error => $_[0] } ); }

sub is_post { return ( ( $ENV{REQUEST_METHOD} // '' ) eq 'POST' ); }

sub want_json {
	my ($raw) = @_;
	return undef if ( !defined $raw or $raw eq '' );
	my $d;
	eval { $d = JSON::from_json($raw); };
	return $@ ? undef : $d;
}

# Local time for display. The Miniserver counts from 2009, JavaScript does not.
sub local_time {
	my ($lox) = @_;
	return undef if ( !$lox );
	return POSIX::strftime( '%Y-%m-%d %H:%M',
		localtime( LoxBerry::System::lox2epoch($lox) ) );
}

# The configuration is keyed by serial number, the interface speaks Miniserver
# numbers - this is where the two meet.
sub entry_for {
	my ($msnr) = @_;
	return ( undef, undef, 'nomsnr' ) if ( !defined $msnr or $msnr eq '' );
	my $s = SortingManager::ms_serial($msnr);
	return ( undef, undef, ( $s->{error} || 'notreachable' ) ) if (! $s->{ok});
	my $cfg = SortingManager::plugin_config();
	my $e   = SortingManager::ms_entry( $cfg, $s->{serial} );
	$e->{msnr} = $msnr;
	return ( $cfg, $e, undef );
}

##########################################################################
# Reading
##########################################################################

if ( $action eq 'miniservers' ) {
	my $cfg  = SortingManager::plugin_config();
	my $list = SortingManager::known_miniservers();
	foreach my $m (@$list) {
		$m->{configured} = ( $m->{serial}
			and ref( $cfg->{miniservers}{ $m->{serial} } ) eq 'HASH'
			and $cfg->{miniservers}{ $m->{serial} }{source} ) ? 1 : 0;
	}
	out( { ok => 1, miniservers => $list } );
}

if ( $action eq 'inventory' ) {
	my $inv = SortingManager::inventory( $q->{msnr} );
	err( $inv->{error} || 'notreachable' ) if (! $inv->{ok});
	$_->{ts_local} = local_time( $_->{ts} ) foreach ( @{ $inv->{entries} } );
	out($inv);
}

# Kept apart from the inventory on purpose: token_info asks the Miniserver, and
# doing that for a dozen users would make the table slow to appear.
if ( $action eq 'tokenstatus' ) {
	my $inv = SortingManager::inventory( $q->{msnr} );
	err( $inv->{error} || 'notreachable' ) if (! $inv->{ok});
	my %state;
	foreach my $e ( @{ $inv->{entries} } ) {
		next if ( ( $e->{type} // '' ) eq 'tablet' or !$e->{name} );
		my $t = LoxBerry::Auth::token_info( $q->{msnr}, user => $e->{name} );
		$state{ $e->{uuid} } = !$t->{ok}                        ? 'none'
		                     : ( ( $t->{expires_in} // 0 ) > 0 ) ? 'ok'
		                     :                                     'expired';
	}
	out( { ok => 1, token => \%state } );
}

if ( $action eq 'config' ) {
	my ( $cfg, $entry, $e ) = entry_for( $q->{msnr} );
	err($e) if ($e);
	out( { ok => 1, config => $entry } );
}

if ( $action eq 'jobstatus' ) {
	out( { ok => 1, job => ( SortingManager::job_status() || {} ) } );
}

if ( $action eq 'backups' ) {
	my $s = SortingManager::ms_serial( $q->{msnr} );
	err( $s->{error} || 'notreachable' ) if (! $s->{ok});
	my $list = SortingManager::list_backups( $s->{serial} );
	$_->{created_local} = local_time( $_->{created} ) foreach (@$list);
	out( { ok => 1, backups => $list } );
}

if ( $action eq 'checkrestore' ) {
	my $file = SortingManager::safe_backup_file( $q->{file} );
	err('badpath') if (!$file);
	my $c = SortingManager::check_restore($file);
	err( $c->{error} ) if (! $c->{ok});

	# Which of the archived users still exist? That decides what the restore
	# dialog may offer.
	my %alive;
	my $inv = SortingManager::inventory( $q->{msnr} );
	if ( $inv->{ok} ) {
		$alive{ $_->{uuid} } = 1 foreach ( @{ $inv->{entries} } );
	}
	foreach my $e ( @{ $c->{manifest}{entries} || [] } ) {
		$e->{alive}    = $alive{ $e->{uuid} } ? 1 : 0;
		$e->{ts_local} = local_time( $e->{ts} );
	}
	$c->{manifest}{created_local} = local_time( $c->{manifest}{created} );
	out($c);
}

##########################################################################
# Writing
##########################################################################

err('postrequired') if ( !is_post() );

if ( $action eq 'saveconfig' ) {
	my ( $cfg, $entry, $e ) = entry_for( $q->{msnr} );
	err($e) if ($e);
	my $data = want_json( $q->{data} );
	err('baddata') if ( ref($data) ne 'HASH' );

	# Only these four branches belong to the interface. The rest of the entry -
	# last_run, last_source_ts - belongs to the watch.
	$entry->{source}  = $data->{source} if ( exists $data->{source} );
	$entry->{targets} = $data->{targets} if ( ref( $data->{targets} ) eq 'ARRAY' );

	if ( ref( $data->{watch} ) eq 'HASH' ) {
		foreach my $k (qw( enabled interval_min auto_reboot )) {
			$entry->{watch}{$k} = $data->{watch}{$k} + 0
				if ( defined $data->{watch}{$k} );
		}
		# The cron runs every five minutes; anything below that is a promise
		# the plugin cannot keep.
		$entry->{watch}{interval_min} = 5 if ( ( $entry->{watch}{interval_min} || 0 ) < 5 );
	}
	if ( ref( $data->{backup} ) eq 'HASH' ) {
		$entry->{backup}{keep} = $data->{backup}{keep} + 0
			if ( defined $data->{backup}{keep} );
		if ( ref( $data->{backup}{schedule} ) eq 'HASH' ) {
			my $s = $data->{backup}{schedule};
			foreach my $k (qw( enabled hour minute every_weeks )) {
				$entry->{backup}{schedule}{$k} = $s->{$k} + 0 if ( defined $s->{$k} );
			}
			$entry->{backup}{schedule}{days} = [ map { $_ + 0 } @{ $s->{days} } ]
				if ( ref( $s->{days} ) eq 'ARRAY' );
		}
	}

	err('savefailed') if ( !defined SortingManager::save_config($cfg) );
	out( { ok => 1 } );
}

if ( $action eq 'copy' ) {
	my ( $cfg, $entry, $e ) = entry_for( $q->{msnr} );
	err($e) if ($e);
	my $targets = want_json( $q->{targets} );
	err('notargets') if ( ref($targets) ne 'ARRAY' or !@$targets );
	err('nosource')  if ( !$q->{source} );

	out( SortingManager::spawn_job( {
		kind        => 'copy',
		msnr        => $q->{msnr},
		source      => $q->{source},
		targets     => $targets,
		auto_reboot => ( $q->{auto_reboot} ? 1 : 0 ),
		passwords   => ( want_json( $q->{passwords} ) || {} ),
	} ) );
}

if ( $action eq 'backupnow' ) {
	my ( $cfg, $entry, $e ) = entry_for( $q->{msnr} );
	err($e) if ($e);
	out( SortingManager::spawn_job( {
		kind => 'backup',
		msnr => $q->{msnr},
		keep => ( $entry->{backup}{keep} || 10 ),
	} ) );
}

if ( $action eq 'restore' ) {
	my $file = SortingManager::safe_backup_file( $q->{file} );
	err('badpath') if (!$file);
	my ( $cfg, $entry, $e ) = entry_for( $q->{msnr} );
	err($e) if ($e);

	my $only = want_json( $q->{only} );
	out( SortingManager::spawn_job( {
		kind        => 'restore',
		msnr        => $q->{msnr},
		file        => $file,
		only        => ( ref($only) eq 'ARRAY' ? $only : undef ),
		auto_reboot => ( $q->{auto_reboot} ? 1 : 0 ),
		passwords   => ( want_json( $q->{passwords} ) || {} ),
	} ) );
}

if ( $action eq 'deletebackup' ) {
	my $file = SortingManager::safe_backup_file( $q->{file} );
	err('badpath') if (!$file);
	out( SortingManager::delete_backup($file) );
}

if ( $action eq 'watchnow' ) {
	my ( $cfg, $entry, $e ) = entry_for( $q->{msnr} );
	err($e) if ($e);
	out( SortingManager::run_watch( $q->{msnr}, force => 1 ) );
}

err('unknownaction');
