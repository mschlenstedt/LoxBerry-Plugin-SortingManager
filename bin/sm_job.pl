#!/usr/bin/perl

# The detached job runner. Started by spawn_job(), never called by hand.
#
# Reads the order from job.spec and carries it out: copying, a backup or a
# restore. The progress goes into job.json, which the web interface polls -
# a copy across several targets, with a reboot at the end, outlasts any CGI.

use strict;
use warnings;
use FindBin;
use File::Basename;
use JSON;
use LoxBerry::System;
use LoxBerry::Log;
use lib $FindBin::RealBin;
use SortingManager;

my $specfile = SortingManager::job_spec_file();
exit 1 if ( !$specfile or ! -e $specfile );

my $spec;
{
	local $/;
	CORE::open( my $fh, '<', $specfile ) or exit 1;
	my $raw = <$fh>;
	close($fh);
	eval { $spec = JSON::from_json($raw); };
}
# The order may carry passwords for the target users. It has served its
# purpose the moment it is read.
unlink $specfile;
exit 1 if ( ref($spec) ne 'HASH' );

my $plugin = $lbpplugindir || basename($FindBin::RealBin);
my $log    = LoxBerry::Log->new(
	name    => 'job',
	package => $plugin,
	logdir  => ( $lbplogdir || "$lbhomedir/log/plugins/$plugin" ),
	addtime => 1,
);
my $kind = $spec->{kind} // '';
my $msnr = $spec->{msnr};
$log->LOGSTART("Job: $kind");

# run_copy_job writes its own progress after every target. Backup and restore
# are single steps, so the beginning and the end are written here - the web
# interface polls one file for all three.
sub report
{
	my (%st) = @_;
	SortingManager::_write_job( { kind => $kind, pid => $$, %st } );
}

if ( $kind eq 'copy' ) {
	SortingManager::run_copy_job( $msnr, $spec );
	$log->OK('copy finished');
}
elsif ( $kind eq 'backup' ) {
	report( state => 'running', started => SortingManager::lox_now(),
	        total => 1, done => 0, failed => 0, results => [] );
	my $r = SortingManager::create_backup( $msnr,
		( defined $spec->{keep} ? ( keep => $spec->{keep} ) : () ) );
	report(
		state    => 'done',
		finished => SortingManager::lox_now(),
		total    => 1,
		done     => 1,
		failed   => ( $r->{ok} ? 0 : 1 ),
		results  => [ {
			name    => 'backup',
			ok      => ( $r->{ok} ? 1 : 0 ),
			error   => $r->{error},
			file    => $r->{file},
			entries => $r->{entries},
			bytes   => $r->{bytes},
		} ],
	);
	$r->{ok}
		? $log->OK( sprintf( 'backup written - %d entries, %d bytes', $r->{entries}, $r->{bytes} ) )
		: $log->ERR( 'backup failed - ' . ( $r->{error} // '?' ) );
}
elsif ( $kind eq 'restore' ) {
	report( state => 'running', started => SortingManager::lox_now(),
	        total => 0, done => 0, failed => 0, results => [] );
	my $r = SortingManager::restore_backup( $msnr, $spec->{file},
		only        => $spec->{only},
		auto_reboot => ( $spec->{auto_reboot} ? 1 : 0 ),
		passwords   => $spec->{passwords},
	);

	if (! $r->{ok}) {
		report( state => 'done', finished => SortingManager::lox_now(),
		        total => 1, done => 1, failed => 1,
		        results => [ { name => 'restore', ok => 0, error => $r->{error} } ] );
		$log->ERR( 'restore failed - ' . ( $r->{error} // '?' ) );
	}
	else {
		my @res = @{ $r->{results} || [] };
		report(
			state          => 'done',
			finished       => SortingManager::lox_now(),
			total          => scalar(@res),
			done           => scalar(@res),
			failed         => scalar( grep { !$_->{ok} } @res ),
			results        => \@res,
			missing        => $r->{missing},
			reboot_pending => $r->{reboot_pending},
		);
		$_->{ok} ? $log->OK("$_->{name}: restored")
		         : $log->ERR( "$_->{name}: " . ( $_->{error} // '?' ) ) foreach (@res);
		$log->WARN("$_->{name} no longer exists - skipped") foreach ( @{ $r->{missing} || [] } );
		$log->INF('a reboot is required for the tablets') if ( $r->{reboot_pending} );
	}
}
else {
	$log->ERR("unknown job kind '$kind'");
	report( state => 'done', finished => SortingManager::lox_now(),
	        total => 0, done => 0, failed => 1,
	        results => [ { name => 'job', ok => 0, error => 'unknownkind' } ] );
}

$log->LOGEND('done');
exit 0;
