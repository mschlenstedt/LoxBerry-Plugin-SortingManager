#!/usr/bin/perl

# Backup and restore of the Loxone app sortings.
#
#   sm_backup.pl create  --msnr <n> [--keep <k>]
#   sm_backup.pl list    --msnr <n>
#   sm_backup.pl check   --file <archive>
#   sm_backup.pl restore --msnr <n> --file <archive> [--reboot]
#   sm_backup.pl delete  --file <archive>
#
# "check" answers as JSON and changes nothing - the web interface uses it to
# find out beforehand what a restore would do.

use strict;
use warnings;
use Getopt::Long;
use JSON;
use LoxBerry::System;
use LoxBerry::Log;
use FindBin;
use File::Basename;
use lib $FindBin::RealBin;   # the plugin bin directory - its name is dynamic
use SortingManager;

my $command = shift @ARGV // '';
my ( $msnr, $file, $keep, $reboot, $json_only );
GetOptions(
	'msnr=i' => \$msnr,
	'file=s' => \$file,
	'keep=i' => \$keep,
	'reboot' => \$reboot,
	'json'   => \$json_only,
);

sub out_json { print JSON->new->pretty->canonical(1)->encode( $_[0] ); }

# LoxBerry::Log finds the plugin on its own only when it is called from a CGI.
# Out of bin/ it has to be told - and the folder name is already in our own
# path, which is the one place it is guaranteed to be right.
sub open_log
{
	my ($title) = @_;
	my $plugin = $lbpplugindir || basename($FindBin::RealBin);
	my $log = LoxBerry::Log->new(
		name    => 'backup',
		package => $plugin,
		logdir  => ( $lbplogdir || "$lbhomedir/log/plugins/$plugin" ),
		addtime => 1,
	);
	$log->LOGSTART($title);
	return $log;
}

if ( $command eq 'create' ) {
	die "--msnr required\n" if (!$msnr);
	my $log = open_log("Backup of Miniserver $msnr");

	my $cfg   = SortingManager::plugin_config();
	my $s     = SortingManager::ms_serial($msnr);
	my $keepn = $keep;
	if ( !defined $keepn and $s->{ok} ) {
		my $e = SortingManager::ms_entry( $cfg, $s->{serial} );
		$keepn = $e->{backup}{keep};
	}

	my $r = SortingManager::create_backup( $msnr, ( defined $keepn ? ( keep => $keepn ) : () ) );
	if ( $r->{ok} ) {
		$log->OK( sprintf( "%s - %d entries, %d bytes", $r->{file}, $r->{entries}, $r->{bytes} ) );
		$log->LOGEND("done");
		out_json($r) if ($json_only);
		exit 0;
	}
	$log->ERR( "Backup failed: " . ( $r->{error} // '?' ) );
	$log->LOGEND("failed");
	out_json($r) if ($json_only);
	exit 1;
}

if ( $command eq 'list' ) {
	die "--msnr required\n" if (!$msnr);
	my $s = SortingManager::ms_serial($msnr);
	die "Miniserver not reachable\n" if (! $s->{ok});
	my $list = SortingManager::list_backups( $s->{serial} );
	if ($json_only) { out_json($list); exit 0; }
	printf "%-46s %10s %8s\n", 'archive', 'bytes', 'entries';
	printf "%-46s %10d %8s\n", $_->{name}, $_->{bytes}, ( $_->{entries} // '?' ) foreach (@$list);
	exit 0;
}

if ( $command eq 'check' ) {
	die "--file required\n" if (!$file);
	out_json( SortingManager::check_restore($file) );
	exit 0;
}

if ( $command eq 'restore' ) {
	die "--msnr and --file required\n" if ( !$msnr or !$file );
	my $log = open_log("Restore from $file");

	my $r = SortingManager::restore_backup( $msnr, $file, auto_reboot => ( $reboot ? 1 : 0 ) );
	if (! $r->{ok}) {
		$log->ERR( "Restore failed: " . ( $r->{error} // '?' ) );
		$log->LOGEND("failed");
		out_json($r) if ($json_only);
		exit 1;
	}
	foreach my $e ( @{ $r->{results} } ) {
		$e->{ok} ? $log->OK("$e->{name}: restored")
		         : $log->ERR("$e->{name}: " . ( $e->{error} // '?' ));
	}
	$log->WARN("$_->{name} no longer exists - skipped") foreach ( @{ $r->{missing} } );
	$log->INF("Reboot required - not triggered") if ( $r->{reboot_pending} );
	$log->LOGEND("done");
	out_json($r) if ($json_only);
	exit 0;
}

if ( $command eq 'delete' ) {
	die "--file required\n" if (!$file);
	my $r = SortingManager::delete_backup($file);
	out_json($r) if ($json_only);
	exit( $r->{ok} ? 0 : 1 );
}

print STDERR "usage: sm_backup.pl create|list|check|restore|delete [options]\n";
exit 1;
