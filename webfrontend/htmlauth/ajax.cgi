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
use SortingManager;

my $cgi    = CGI->new;
my $q      = $cgi->Vars;
my $action = $q->{action} // '';

print "Content-Type: application/json; charset=utf-8\n\n";

sub out { print JSON->new->canonical(1)->encode( $_[0] ); exit 0; }
sub err { out( { ok => 0, error => $_[0] } ); }

sub is_post { return ( ( $ENV{REQUEST_METHOD} // '' ) eq 'POST' ); }

# A log session for actions carried out right here instead of in a job
sub weblog
{
	my ($name, $title) = @_;
	require LoxBerry::Log;
	my $l = LoxBerry::Log->new(
		name    => $name,
		package => $lbpplugindir,
		logdir  => $lbplogdir,
		addtime => 1,
	);
	$l->LOGSTART($title);
	SortingManager::set_logger($l);
	return $l;
}
sub debug_level { return ( LoxBerry::System::pluginloglevel() || 0 ) >= 7; }

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
		localtime( SortingManager::lox2unix($lox) ) );
}

# The configuration is keyed by serial number, the interface speaks Miniserver
# numbers - this is where the two meet.
sub entry_for {
	my ($msnr) = @_;
	return ( undef, undef, 'nomsnr' ) if ( !defined $msnr or $msnr eq '' );
	# Works from the configuration while the Miniserver is down - settings and
	# archives stay visible, only what needs the Miniserver fails later on.
	my $s = SortingManager::serial_for($msnr);
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

# Light check whether the Miniserver answers - the interface asks this every
# few seconds while one is down, e.g. during a reboot.
if ( $action eq 'reach' ) {
	my $s = SortingManager::ms_serial( $q->{msnr} );
	out( { ok => ( $s->{ok} ? 1 : 0 ), serial => $s->{serial}, firmware => $s->{firmware}, error => $s->{error} } );
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

# Everything the watch tab shows: settings, what is watched, the next check and
# the last runs.
if ( $action eq 'watchstatus' ) {
	my ( $cfg, $entry, $e ) = entry_for( $q->{msnr} );
	err($e) if ($e);
	my $s    = SortingManager::serial_for( $q->{msnr} );
	my $hist = SortingManager::watch_history( $s->{serial} );
	$_->{ts_local} = local_time( $_->{ts} ) foreach (@$hist);
	my $next = SortingManager::next_watch( $entry, SortingManager::lox_now() );
	out( {
		ok             => 1,
		watch          => $entry->{watch},
		source         => $entry->{source},
		targets        => $entry->{targets},
		history        => $hist,
		next_run       => $next,
		next_run_local => local_time($next),
		last_run_local => local_time( $entry->{watch}{last_run} ),
	} );
}

if ( $action eq 'jobstatus' ) {
	out( { ok => 1, job => ( SortingManager::job_status() || {} ) } );
}

if ( $action eq 'backups' ) {
	my $s = SortingManager::serial_for( $q->{msnr} );
	err( $s->{error} || 'notreachable' ) if (! $s->{ok});
	my $list = SortingManager::list_backups( $s->{serial} );
	$_->{created_local} = local_time( $_->{created} ) foreach (@$list);
	out( { ok => 1, backups => $list,
	       free_bytes => SortingManager::free_bytes( SortingManager::backup_dir() ) } );
}

if ( $action eq 'checkrestore' ) {
	my $file = SortingManager::safe_backup_file( $q->{file} );
	err('badpath') if (!$file);
	# Which archived users still exist, and how their sorting looks now
	my $c = SortingManager::restore_preview( $q->{msnr}, $file );
	err( $c->{error} ) if (! $c->{ok});
	foreach my $e ( @{ $c->{manifest}{entries} || [] } ) {
		$e->{ts_local}         = local_time( $e->{ts} );
		$e->{current_ts_local} = local_time( $e->{current_ts} );
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

	my $l;
	if ( debug_level() ) {
		$l = weblog( 'webui', 'Settings saved' );
		$l->DEB( "saveconfig for Miniserver $q->{msnr}: " . JSON->new->canonical(1)->encode($data) );
	}
	my $saved = SortingManager::save_config($cfg);
	$l->LOGEND( defined $saved ? 'saved' : 'failed' ) if ($l);
	err('savefailed') if ( !defined $saved );
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
	my $l = weblog( 'webui', 'Delete archive' );
	my $r = SortingManager::delete_backup($file);
	$l->LOGEND( $r->{ok} ? 'done' : 'failed' );
	out($r);
}

if ( $action eq 'watchnow' ) {
	my ( $cfg, $entry, $e ) = entry_for( $q->{msnr} );
	err($e) if ($e);
	# A check, not a forced copy: an unchanged source copies nothing.
	my $l = weblog( 'watch', "Check by hand, Miniserver $q->{msnr}" );
	my $r = SortingManager::run_watch( $q->{msnr}, manual => 1 );
	if    ( $r->{skipped} ) { $l->INF('nothing to watch yet'); }
	elsif ( !$r->{ok} )     { $l->ERR( 'check failed - ' . ( $r->{error} // '?' ) ); }
	elsif ( $r->{changed} ) { $l->OK('source had changed and was copied'); }
	else                    { $l->OK('source unchanged'); }
	$l->LOGEND('done');
	out($r);
}

err('unknownaction');
