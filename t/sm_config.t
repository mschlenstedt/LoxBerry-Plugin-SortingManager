#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw( tempdir );
use File::Path qw( make_path );
use JSON;

my $home;
BEGIN {
	require File::Temp;
	$home = File::Temp::tempdir( CLEANUP => 1 );
	$ENV{LBHOMEDIR} = $home;
}

make_path("$home/config/system");
open( my $gfh, '>', "$home/config/system/general.json" ) or die $!;
print $gfh <<'GENERALJSON';
{
  "Base": { "Lang": "de", "Version": "4.0.1" },
  "Miniserver": {
    "1": {
      "Name": "Haupthaus", "Ipaddress": "192.0.2.10",
      "Admin": "lbuser", "Pass": "TestPass%2123",
      "Admin_raw": "lbuser", "Pass_raw": "TestPass!23",
      "Credentials_raw": "lbuser:TestPass!23",
      "Port": 80, "Porthttps": 443, "Preferhttps": 0
    },
    "2": {
      "Name": "Nebengebaeude", "Ipaddress": "192.0.2.11",
      "Admin": "lbuser", "Pass": "TestPass%2123",
      "Admin_raw": "lbuser", "Pass_raw": "TestPass!23",
      "Credentials_raw": "lbuser:TestPass!23",
      "Port": 80, "Porthttps": 443, "Preferhttps": 0
    }
  }
}
GENERALJSON
close($gfh);

use lib File::Spec->catdir( $FindBin::Bin, '..', 'bin' );
use SortingManager;

my $dir = tempdir( CLEANUP => 1 );
$SortingManager::config_file = "$dir/pluginconfig.json";

# --- Leere Konfiguration ---------------------------------------------------
my $cfg = SortingManager::plugin_config();
is( ref($cfg),                'HASH', 'plugin_config liefert einen Hashref' );
is( ref($cfg->{miniservers}), 'HASH', 'miniservers ist angelegt' );
ok( ! -e "$dir/pluginconfig.json", 'Lesen legt die Datei nicht an' );

# --- Eintrag je Seriennummer -----------------------------------------------
my $e = SortingManager::ms_entry( $cfg, 'AB:CD:EF:01:02:03' );
is( ref($e),                   'HASH', 'ms_entry liefert einen Hashref' );
is( $e->{watch}{enabled},      0,      'Ueberwachung ist per Vorgabe aus' );
is( $e->{watch}{interval_min}, 15,     'Vorgabe-Intervall 15 Minuten' );
is( $e->{watch}{auto_reboot},  0,      'automatischer Reboot ist per Vorgabe aus' );
is( $e->{backup}{keep},        10,     'Vorgabe: 10 Archive' );
is( $e->{backup}{compression}, 'gzip', 'Vorgabe-Komprimierung' );
is( ref($e->{targets}),        'ARRAY','targets ist eine Liste' );

# derselbe Aufruf liefert denselben Eintrag, keine Neuanlage
$e->{source} = 'uuid-der-quelle';
my $again = SortingManager::ms_entry( $cfg, 'AB:CD:EF:01:02:03' );
is( $again->{source}, 'uuid-der-quelle', 'bestehender Eintrag bleibt erhalten' );

# --- Schreiben nur bei Aenderung -------------------------------------------
is( SortingManager::save_config($cfg), 1, 'erstes Speichern schreibt' );
ok( -e "$dir/pluginconfig.json", 'Datei wurde angelegt' );
my $mode = (stat("$dir/pluginconfig.json"))[2] & 07777;
is( $mode, 0600, 'Konfiguration ist 0600 - sie kann Zugangsdaten enthalten' );

my $mtime = (stat("$dir/pluginconfig.json"))[9];
sleep 1;
is( SortingManager::save_config($cfg), 0, 'unveraendert wird nicht geschrieben' );
is( (stat("$dir/pluginconfig.json"))[9], $mtime, 'mtime unveraendert' );

$cfg->{miniservers}{'AB:CD:EF:01:02:03'}{source} = 'andere-uuid';
is( SortingManager::save_config($cfg), 1, 'Aenderung wird geschrieben' );

my $reloaded = SortingManager::plugin_config();
is( $reloaded->{miniservers}{'AB:CD:EF:01:02:03'}{source}, 'andere-uuid', 'zurueckgelesen' );

# --- Seriennummer ermitteln ------------------------------------------------
my %api_answers = (
	1 => "{'snr': 'AB:CD:EF:01:02:03', 'version':'17.1.7.3'}",
	2 => "{'snr': 'AB:CD:EF:01:02:04', 'version':'15.2.0.1'}",
);
$SortingManager::api_hook = sub {
	my ($msnr) = @_;
	return ( undef, 'unreachable' ) if (!exists $api_answers{$msnr});
	return ( $api_answers{$msnr}, undef );
};

my $s = SortingManager::ms_serial(1);
is( $s->{ok},       1,                   'ms_serial ok' );
is( $s->{serial},   'AB:CD:EF:01:02:03', 'Seriennummer' );
is( $s->{firmware}, '17.1.7.3',          'Firmware' );

my $bad = SortingManager::ms_serial(9);
is( $bad->{ok},    0,             'unbekannter Miniserver' );
is( $bad->{error}, 'unreachable', 'Fehlercode durchgereicht' );

# --- Alle konfigurierten Miniserver ----------------------------------------
my $all = SortingManager::known_miniservers();
is( ref($all),         'ARRAY', 'known_miniservers liefert eine Liste' );
is( scalar(@$all),     2,       'beide Miniserver aus general.json' );
is( $all->[0]{msnr},   1,                   'erster: Nummer' );
is( $all->[0]{name},   'Haupthaus',         'erster: Name' );
is( $all->[0]{serial}, 'AB:CD:EF:01:02:03', 'erster: Seriennummer' );
is( $all->[1]{serial}, 'AB:CD:EF:01:02:04', 'zweiter: Seriennummer' );

# --- Ohne Pluginkontext keine Datei am Wurzelverzeichnis --------------------
{
	local $SortingManager::config_file = undef;
	is( SortingManager::config_file(), undef, 'ohne $lbpconfigdir keine Datei' );
	is_deeply( SortingManager::plugin_config(), SortingManager::_empty_config(),
	           'gelesen wird eine leere Konfiguration' );
	is( SortingManager::save_config( SortingManager::_empty_config() ), undef,
	    'und geschrieben wird gar nicht' );
	ok( ! -e '/pluginconfig.json', 'nichts im Wurzelverzeichnis angelegt' );
}

done_testing();
