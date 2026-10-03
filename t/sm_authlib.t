#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw( tempdir );

use lib File::Spec->catdir( $FindBin::Bin, '..', 'bin' );
use SortingManager;

my $tmp = tempdir( CLEANUP => 1 );

sub lib_file
{
	my ($name, $version_line) = @_;
	my $f = "$tmp/$name.pm";
	open( my $fh, '>', $f ) or die "$f: $!";
	print $fh "package LoxBerry::Auth;\nuse strict;\n$version_line\n1;\n";
	close($fh);
	return $f;
}

# --- lib_version -----------------------------------------------------------
is( SortingManager::lib_version( lib_file( 'dq', 'our $VERSION = "4.0.0.1";' ) ),
    '4.0.0.1', 'lib_version liest $VERSION in doppelten Anfuehrungszeichen' );
is( SortingManager::lib_version( lib_file( 'sq', "our \$VERSION = '4.0.2';" ) ),
    '4.0.2', 'lib_version liest $VERSION in einfachen Anfuehrungszeichen' );
is( SortingManager::lib_version( lib_file( 'none', '# no version' ) ),
    undef, 'lib_version ohne $VERSION ist undef' );
is( SortingManager::lib_version("$tmp/missing.pm"), undef,
    'lib_version einer fehlenden Datei ist undef' );

# --- auth_lib_choice -------------------------------------------------------
my $bundled = lib_file( 'bundled', 'our $VERSION = "4.0.0.2";' );

my $c = SortingManager::auth_lib_choice( "$tmp/missing.pm", $bundled );
is( $c->{source}, 'plugin', 'Core ohne Lib: mitgelieferte Lib' );
is( $c->{file}, $bundled, 'Core ohne Lib: Datei ist die mitgelieferte' );
is( $c->{version}, '4.0.0.2', 'Core ohne Lib: Version der mitgelieferten Lib' );

$c = SortingManager::auth_lib_choice( undef, $bundled );
is( $c->{source}, 'plugin', 'Core-Pfad unbekannt: mitgelieferte Lib' );

$c = SortingManager::auth_lib_choice( lib_file( 'older', 'our $VERSION = "4.0.0.1";' ), $bundled );
is( $c->{source}, 'plugin', 'Core-Lib aelter: mitgelieferte Lib' );

my $same = lib_file( 'same', 'our $VERSION = "4.0.0.2";' );
$c = SortingManager::auth_lib_choice( $same, $bundled );
is( $c->{source}, 'core', 'Core-Lib gleich alt: Core-Lib' );
is( $c->{file}, $same, 'Core-Lib gleich alt: Datei ist die des Cores' );

$c = SortingManager::auth_lib_choice( lib_file( 'newer', 'our $VERSION = "4.1.0.0";' ), $bundled );
is( $c->{source}, 'core', 'Core-Lib neuer: Core-Lib' );
is( $c->{version}, '4.1.0.0', 'Core-Lib neuer: Version des Cores' );

# Dotted-decimal, nicht Dezimalzahl: 4.0.0.10 ist neuer als 4.0.0.2
$c = SortingManager::auth_lib_choice( lib_file( 'ten', 'our $VERSION = "4.0.0.10";' ), $bundled );
is( $c->{source}, 'core', '4.0.0.10 gilt als neuer als 4.0.0.2' );

$c = SortingManager::auth_lib_choice( lib_file( 'nover', '# no version' ), $bundled );
is( $c->{source}, 'plugin', 'Core-Lib ohne $VERSION: mitgelieferte Lib' );

$c = SortingManager::auth_lib_choice( lib_file( 'junk', 'our $VERSION = "kaputt";' ), $bundled );
is( $c->{source}, 'plugin', 'Core-Lib mit unlesbarer Version: mitgelieferte Lib' );

# --- tatsaechlich geladene Lib ---------------------------------------------
my $own = File::Spec->catfile( $FindBin::Bin, '..', 'bin', 'lib', 'LoxBerry', 'Auth.pm' );
ok( -e $own, 'Plugin liefert bin/lib/LoxBerry/Auth.pm mit' );
like( SortingManager::lib_version($own) // '', qr/^\d+(\.\d+)+$/,
      'mitgelieferte Lib hat eine lesbare Version' );

my $info = $SortingManager::auth_lib;
like( $info->{source}, qr/^(core|plugin)$/, 'Auswahl ist festgehalten' );
is( File::Spec->rel2abs( $INC{'LoxBerry/Auth.pm'} ), File::Spec->rel2abs( $info->{file} ),
    'geladen wurde genau die ausgewaehlte Datei' );
is( $LoxBerry::Auth::VERSION, $info->{version}, 'geladene Version entspricht der Auswahl' );
ok( defined &LoxBerry::Auth::request, 'LoxBerry::Auth::request ist verfuegbar' );
ok( !grep( { $_ eq File::Spec->catdir( $FindBin::Bin, '..', 'bin', 'lib' ) } @INC ),
    'Verzeichnis der mitgelieferten Lib bleibt nicht in @INC' );

done_testing();
