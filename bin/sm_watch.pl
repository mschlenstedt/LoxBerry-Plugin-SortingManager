#!/usr/bin/perl

# The periodic run, hooked into cron.05min.
#
#   sm_watch.pl [--force] [--dry]
#
# Walks the Miniservers configured in the plugin and asks the module whether
# the watch or a scheduled backup is due. Deciding here rather than in the
# crontab means a changed interval takes effect without rewriting cron.
#
# Stays silent when there is nothing to do: no log session is opened at all.
# The plugin log lives on a RAM disk, and a run every five minutes would fill
# it with nothing.

use strict;
use warnings;
use Getopt::Long;
use FindBin;
use File::Basename;
use File::Path qw( make_path );
use Fcntl qw( :flock );
use LoxBerry::System;
use LoxBerry::Log;
use lib $FindBin::RealBin;
use SortingManager;

my ( $force, $dry );
GetOptions( 'force' => \$force, 'dry' => \$dry );

my $plugin = $lbpplugindir || basename($FindBin::RealBin);

# One run at a time. A copy across several targets can outlast five minutes,
# and two of them would fight over the same configuration file.
my $rundir = "/var/run/shm/$plugin";
eval { make_path($rundir) } if ( ! -d $rundir );
exit 0 if ( ! CORE::open( my $lock, '>', "$rundir/watch.lock" ) );
exit 0 if ( ! flock( $lock, LOCK_EX | LOCK_NB ) );

my $cfg = SortingManager::plugin_config();
my $now = SortingManager::lox_now();
my $log;

# At level Debug every run is logged, with every decision. Below that the log
# opens on the first real event only, so an idle run every five minutes does
# not leave a file behind.
my $verbose = ( LoxBerry::System::pluginloglevel() || 0 ) >= 7;
{
	package SmWatchLog;
	sub new  { return bless {}, shift; }
	sub DEB  { return if (!$verbose); main::logger()->DEB( $_[1] ); }
	sub INF  { main::logger()->INF( $_[1] ); }
	sub OK   { main::logger()->OK( $_[1] ); }
	sub WARN { main::logger()->WARN( $_[1] ); }
	sub ERR  { main::logger()->ERR( $_[1] ); }
}
SortingManager::set_logger( SmWatchLog->new );

# Opened on first use only - see the note above.
sub logger
{
	return $log if ($log);
	$log = LoxBerry::Log->new(
		name    => 'watch',
		package => $plugin,
		logdir  => ( $lbplogdir || "$lbhomedir/log/plugins/$plugin" ),
		addtime => 1,
	);
	$log->LOGSTART('Watch run');
	return $log;
}

foreach my $serial ( sort keys %{ $cfg->{miniservers} } ) {
	my $entry = $cfg->{miniservers}{$serial};
	next if ( ref($entry) ne 'HASH' or !$entry->{msnr} );
	my $msnr = $entry->{msnr};

	my $watch_due  = $force ? 1 : SortingManager::watch_due( $entry, $now );
	my $backup_due = $force ? 1 : SortingManager::backup_due( $entry, $now );
	if ($verbose) {
		my $w = $entry->{watch} || {};
		my $b = ( $entry->{backup} || {} )->{schedule} || {};
		logger()->DEB( sprintf( '%s (Miniserver %s): watch %s, every %d min, last run %s -> %s',
			$serial, $msnr, ( $w->{enabled} ? 'on' : 'off' ), $w->{interval_min} || 15,
			( $w->{last_run} ? scalar localtime( SortingManager::lox2unix( $w->{last_run} ) ) : 'never' ),
			( $watch_due ? 'due' : 'not due' ) ) );
		logger()->DEB( sprintf( '%s: backup schedule %s, days [%s] at %02d:%02d, every %d week(s), last run %s -> %s',
			$serial, ( $b->{enabled} ? 'on' : 'off' ), join( ',', @{ $b->{days} || [] } ), $b->{hour} || 0, $b->{minute} || 0,
			$b->{every_weeks} || 1,
			( $b->{last_run} ? scalar localtime( SortingManager::lox2unix( $b->{last_run} ) ) : 'never' ),
			( $backup_due ? 'due' : 'not due' ) ) );
	}

	if ($dry) {
		printf "%s watch=%d backup=%d\n", $serial, $watch_due, $backup_due
			if ( $watch_due or $backup_due );
		next;
	}

	if ($watch_due) {
		my $r = SortingManager::run_watch( $msnr, ( $force ? ( force => 1 ) : () ) );
		if ( $r->{skipped} ) {
			# Not set up yet - not an event worth a log line every five minutes.
		}
		elsif (! $r->{ok}) {
			logger()->ERR( "$serial: watch failed - " . ( $r->{error} // '?' ) );
		}
		elsif ( $r->{changed} ) {
			my @copied = @{ $r->{copied} || [] };
			my $ok     = scalar( grep { $_->{ok} } @copied );
			logger()->OK( sprintf( '%s: source changed, copied to %d of %d targets',
			                       $serial, $ok, scalar(@copied) ) );
			foreach my $c ( grep { !$_->{ok} } @copied ) {
				logger()->ERR( "  $c->{name}: " . ( $c->{error} // '?' ) );
			}
			if ( $r->{notify} ) {
				logger()->WARN("$serial: the Miniserver has to be rebooted for the tablets");
				LoxBerry::Log::notify( $plugin, 'watch',
					"Sorting copied to a managed tablet. Reboot the Miniserver to make it appear.", 0 );
			}
		}
	}

	if ($backup_due) {
		my $r = SortingManager::create_backup( $msnr, keep => ( $entry->{backup}{keep} || 10 ),
		                                       trigger => 'schedule' );
		if ( $r->{ok} ) {
			logger()->OK( sprintf( '%s: backup written - %d entries, %d bytes',
			                       $serial, $r->{entries}, $r->{bytes} ) );

			# Read the configuration afresh: run_watch above has written to it,
			# and the copy held here is stale.
			my $c = SortingManager::plugin_config();
			SortingManager::ms_entry( $c, $serial )->{backup}{schedule}{last_run} = $now;
			SortingManager::save_config($c);
		}
		else {
			logger()->ERR( "$serial: backup failed - " . ( $r->{error} // '?' ) );
			LoxBerry::Log::notify( $plugin, 'watch', 'The scheduled backup failed.', 1 );
		}
	}
}

$log->LOGEND('done') if ($log);
exit 0;
