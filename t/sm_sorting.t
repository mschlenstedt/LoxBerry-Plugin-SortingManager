#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use JSON;

use lib File::Spec->catdir( $FindBin::Bin, '..', 'bin' );
use SortingManager;

# --- lox_now ---------------------------------------------------------------
my $now = SortingManager::lox_now();
like( $now, qr/^\d+$/, 'lox_now liefert eine Zahl' );
cmp_ok( $now, '>', 550_000_000, 'lox_now liegt nach Mitte 2026' );
cmp_ok( $now, '<', 900_000_000, 'lox_now liegt vor dem Jahr 2037' );

# Gegenprobe gegen die Core-Funktion - beide muessen dieselbe Epoche nutzen
is( abs( $now - LoxBerry::System::epoch2lox() ) <= 1, 1,
    'lox_now stimmt mit LoxBerry::System::epoch2lox ueberein' );

# --- parse_sorting ---------------------------------------------------------
my $json = '{"userDefaultStructure":{"a":{"room":{"position":0}},"b":{}},'
         . '"ts":556542088,"audioZoneCustomization":{}}';
my $raw  = '556542088/' . $json;

my $p = SortingManager::parse_sorting($raw);
is( $p->{ok},  1,          'parse_sorting ok' );
is( $p->{ts},  556542088,  'Zeitstempel aus dem Praefix' );
is( ref($p->{data}), 'HASH', 'data ist ein Hashref' );
is( $p->{data}{ts}, 556542088, 'Zeitstempel innen' );

# Praefix und innerer Wert muessen uebereinstimmen - sonst ist die Datei kaputt
my $mismatch = SortingManager::parse_sorting('556542099/' . $json);
is( $mismatch->{ok},    0,          'abweichender Zeitstempel wird erkannt' );
is( $mismatch->{error}, 'tsmismatch', 'Fehlercode tsmismatch' );

is( SortingManager::parse_sorting('')->{error},            'empty',      'leer' );
is( SortingManager::parse_sorting(undef)->{error},         'empty',      'undef' );
is( SortingManager::parse_sorting('kein-praefix')->{error},'badformat',  'ohne Praefix' );
is( SortingManager::parse_sorting('123/{kaputt')->{error}, 'badjson',    'kaputtes JSON' );

# --- control_count ---------------------------------------------------------
is( SortingManager::control_count($p->{data}), 2, 'zwei Bausteine gezaehlt' );
is( SortingManager::control_count({}),         0, 'leere Struktur zaehlt 0' );

# --- restamp ---------------------------------------------------------------
my $out = SortingManager::restamp( $p->{data}, 556999999 );
like( $out, qr{^556999999/}, 'Praefix traegt den neuen Zeitstempel' );

my $reparsed = SortingManager::parse_sorting($out);
is( $reparsed->{ok},        1,         'das Ergebnis ist wieder lesbar' );
is( $reparsed->{ts},        556999999, 'neuer Zeitstempel aussen' );
is( $reparsed->{data}{ts},  556999999, 'neuer Zeitstempel innen' );
is( SortingManager::control_count($reparsed->{data}), 2, 'Inhalt unveraendert' );

# Der Zeitstempel muss eine ZAHL sein, kein String - sonst schreibt JSON
# "ts":"556999999" und der Miniserver verwirft die Datei
my $decoded = JSON::from_json( (split(m{/}, $out, 2))[1] );
ok( $decoded->{ts} =~ /^\d+$/ && "$decoded->{ts}" eq '556999999', 'ts bleibt numerisch' );
unlike( $out, qr/"ts":"/, 'ts steht nicht in Anfuehrungszeichen' );

# --- parse_api_value -------------------------------------------------------
# jdev/cfg/api antwortet mit einem STRING in einfachen Anfuehrungszeichen -
# das ist kein gueltiges JSON.
my $apival = "{'snr': 'AB:CD:EF:01:02:03', 'version':'17.1.7.3', 'hasEventSlots':true, "
           . "'isInTrust':false, 'local':true,'certTLD':'com'}";
my $api = SortingManager::parse_api_value($apival);
is( $api->{snr},     'AB:CD:EF:01:02:03', 'Seriennummer' );
is( $api->{version}, '17.1.7.3',          'Firmware' );
is( $api->{local},   'true',              'unquotierter Wert' );
is( SortingManager::parse_api_value(''),    undef, 'leer ist undef' );
is( SortingManager::parse_api_value(undef), undef, 'undef ist undef' );

done_testing();
