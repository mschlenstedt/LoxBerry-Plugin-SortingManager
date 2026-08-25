#!/usr/bin/perl

# Command line for the Sorting Manager. Everything the web interface does is
# reachable here too - that is what makes the plugin testable without a browser.
#
#   sm_cli.pl inventory  --msnr <n>
#   sm_cli.pl show       --msnr <n> --uuid <uuid>
#   sm_cli.pl copy       --msnr <n> --source <uuid> --target <name> [--password <pw>]
#   sm_cli.pl copy       --msnr <n> --source <uuid> --tablet <uuid> [--reboot]
#   sm_cli.pl revoke-all
#
# revoke-all is called by uninstall/uninstall: tokens stay in the Miniserver's
# token list until they expire, and revoking them needs the password, which is
# only available while the configuration still exists.

use strict;
use warnings;
use Getopt::Long;
use JSON;
use LoxBerry::System;
use LoxBerry::Auth;
use FindBin;
use lib $FindBin::RealBin;   # the plugin bin directory - its name is dynamic
use SortingManager;

my $command = shift @ARGV // '';
my ( $msnr, $uuid, $source, $target, $tablet, $password, $reboot, $json_only );
GetOptions(
	'msnr=i'     => \$msnr,
	'uuid=s'     => \$uuid,
	'source=s'   => \$source,
	'target=s'   => \$target,
	'tablet=s'   => \$tablet,
	'password=s' => \$password,
	'reboot'     => \$reboot,
	'json'       => \$json_only,
);

sub out_json { print JSON->new->pretty->canonical(1)->encode( $_[0] ); }

if ( $command eq 'inventory' ) {
	die "--msnr required\n" if (!$msnr);
	my $inv = SortingManager::inventory($msnr);
	if (! $inv->{ok}) { out_json($inv); exit 1; }
	if ($json_only)   { out_json($inv); exit 0; }

	printf "%-24s %-8s %-10s %-12s %s\n", 'name', 'type', 'sorting', 'timestamp', 'uuid';
	foreach my $e ( @{ $inv->{entries} } ) {
		printf "%-24s %-8s %-10s %-12s %s\n",
			( $e->{name} // '?' ), $e->{type},
			( $e->{has_sorting} ? 'yes' : 'no' ),
			( $e->{ts} // '-' ), $e->{uuid};
	}
	printf "\n%d orphaned sorting files without an owner\n", scalar( @{ $inv->{orphans} } )
		if ( @{ $inv->{orphans} } );
	print "WARNING: the tablet list could not be read ($inv->{tablets_error})\n"
		if ( $inv->{tablets_error} );
	exit 0;
}

if ( $command eq 'show' ) {
	die "--msnr and --uuid required\n" if ( !$msnr or !$uuid );
	my $r = SortingManager::read_sorting( $msnr, $uuid );
	if (! $r->{ok}) { out_json($r); exit 1; }
	printf "timestamp: %s\ncontrols : %d\nbytes    : %d\n",
		$r->{ts}, SortingManager::control_count( $r->{data} ), length( $r->{raw} );
	exit 0;
}

if ( $command eq 'copy' ) {
	die "--msnr and --source required\n" if ( !$msnr or !$source );
	my $r;
	if ($tablet) {
		$r = SortingManager::copy_to_tablet( $msnr, $source, $tablet );
		if ( $r->{ok} and $reboot ) {
			my $rb = SortingManager::reboot_miniserver($msnr);
			$r->{reboot} = $rb->{ok} ? 'triggered' : ( $rb->{error} // 'failed' );
		}
	}
	elsif ($target) {
		my %o;
		$o{password} = $password if ( defined $password );
		$r = SortingManager::copy_to_user( $msnr, $source, $target, %o );
	}
	else {
		die "--target or --tablet required\n";
	}
	out_json($r);
	exit( $r->{ok} ? 0 : 1 );
}

if ( $command eq 'revoke-all' ) {
	my $cfg = SortingManager::plugin_config();
	my $failed = 0;
	foreach my $serial ( keys %{ $cfg->{miniservers} } ) {
		my $e = $cfg->{miniservers}{$serial};
		next if ( !$e->{msnr} );
		foreach my $t ( @{ $e->{targets} || [] } ) {
			next if ( !$t->{name} );
			my $k = LoxBerry::Auth::kill_token( $e->{msnr}, user => $t->{name} );
			$failed++ if (! $k->{ok});
		}
	}
	exit( $failed ? 1 : 0 );
}

print STDERR "usage: sm_cli.pl inventory|show|copy|revoke-all [options]\n";
exit 1;
