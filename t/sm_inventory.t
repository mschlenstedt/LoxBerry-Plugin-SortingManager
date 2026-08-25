#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
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
    }
  }
}
GENERALJSON
close($gfh);

use lib File::Spec->catdir( $FindBin::Bin, '..', 'bin' );
use SortingManager;

# --- Fake-Antworten --------------------------------------------------------
# getuserlist2 liefert die Liste als JSON-STRING im LL-value
my $userlist = '[{"name":"chef","uniqueUserId":"","uuid":"11111111-1111-1111-111111111111",'
             . '"isAdmin":true,"userState":0},'
             . '{"name":"gast","uniqueUserId":"","uuid":"22222222-2222-2222-222222222222",'
             . '"isAdmin":false,"userState":0},'
             . '{"name":"technik","uniqueUserId":"","uuid":"33333333-3333-3333-333333333333",'
             . '"isAdmin":false,"userState":1}]';

my $pairing = '[{"uuid":"aaaaaaaa-aaaa-aaaa-aaaaaaaaaaaa","name":"Flur",'
            . '"room":"99999999-9999-9999-999999999999","inst":"",'
            . '"user":"bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb","deviceId":"dev1","model":"SM-X210"}]';

$SortingManager::userlist_hook = sub { return ( $userlist, undef ); };
$SortingManager::pairing_hook  = sub { return ( $pairing,  undef ); };

# --- Gutfall ---------------------------------------------------------------
my $inv = SortingManager::users_and_tablets(1);
is( $inv->{ok}, 1, 'users_and_tablets ok' );
is( scalar( @{ $inv->{users} } ),   3, 'drei Benutzer' );
is( scalar( @{ $inv->{tablets} } ), 1, 'ein Tablet' );

my ($chef)    = grep { $_->{name} eq 'chef' }    @{ $inv->{users} };
my ($gast)    = grep { $_->{name} eq 'gast' }    @{ $inv->{users} };
my ($technik) = grep { $_->{name} eq 'technik' } @{ $inv->{users} };

is( $chef->{uuid},     '11111111-1111-1111-111111111111', 'uuid des Admins' );
is( $chef->{is_admin}, 1,       'isAdmin wird uebernommen' );
is( $chef->{type},     'admin', 'Admin bekommt den Typ admin' );
is( $gast->{is_admin}, 0,       'normaler Benutzer' );
is( $gast->{type},     'user',  'normaler Benutzer bekommt den Typ user' );
is( $technik->{state}, 1,       'userState wird uebernommen' );

my $tab = $inv->{tablets}[0];
is( $tab->{name},        'Flur',                            'Name des Tablets' );
is( $tab->{type},        'tablet',                          'Typ tablet' );
is( $tab->{device_uuid}, 'aaaaaaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Geraete-UUID' );
is( $tab->{uuid},        'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb', 'uuid ist die BENUTZER-UUID' );
is( $tab->{model},       'SM-X210',                         'Modell' );

# --- Fehlerfaelle ----------------------------------------------------------
$SortingManager::userlist_hook = sub { return ( undef, 'unreachable' ); };
is( SortingManager::users_and_tablets(1)->{error}, 'unreachable',
    'Fehler der Benutzerliste wird durchgereicht' );

$SortingManager::userlist_hook = sub { return ( 'kein json', undef ); };
is( SortingManager::users_and_tablets(1)->{error}, 'parseerror', 'kaputte Benutzerliste' );

# Ein Miniserver ohne verwaltete Tablets ist normal, kein Fehler
$SortingManager::userlist_hook = sub { return ( $userlist, undef ); };
$SortingManager::pairing_hook  = sub { return ( '[]', undef ); };
my $notab = SortingManager::users_and_tablets(1);
is( $notab->{ok}, 1, 'ohne Tablets weiterhin ok' );
is( scalar( @{ $notab->{tablets} } ), 0, 'leere Tabletliste' );

# Auch ein Fehler beim Pairing-Endpunkt darf die Benutzerliste nicht kippen
$SortingManager::pairing_hook = sub { return ( undef, 'unreachable' ); };
my $degraded = SortingManager::users_and_tablets(1);
is( $degraded->{ok}, 1, 'Benutzer bleiben nutzbar, wenn nur die Tablets fehlen' );
is( scalar( @{ $degraded->{users} } ), 3, 'drei Benutzer trotzdem da' );
is( $degraded->{tablets_error}, 'unreachable', 'der Tablet-Fehler wird vermerkt' );


# --- Die beiden Endpunkte antworten UNTERSCHIEDLICH ------------------------
# Am Geraet gemessen (17.1.7.3): getuserlist2 verpackt die Liste als STRING in
# der LL-Huelle, apppairing/list liefert ein nacktes Array ohne Huelle.
$SortingManager::userlist_hook = sub {
	return ( '{"LL": { "control": "dev/sps/getuserlist2", "value": ' . JSON::to_json($userlist) . ', "Code": "200"}}', undef );
};
$SortingManager::pairing_hook = sub { return ( $pairing, undef ); };
my $shapes = SortingManager::users_and_tablets(1);
is( $shapes->{ok}, 1, 'beide Antwortformen werden verstanden' );
is( scalar( @{ $shapes->{users} } ),   3, 'Benutzer aus der LL-Huelle mit String' );
is( scalar( @{ $shapes->{tablets} } ), 1, 'Tablets aus dem nackten Array' );
is( $shapes->{tablets_error}, undef, 'kein Fehler bei der nackten Antwort' );

# und die dritte Form: Huelle mit bereits entpacktem Array
$SortingManager::pairing_hook = sub {
	return ( '{"LL": { "value": ' . $pairing . ', "Code": "200"}}', undef );
};
my $third = SortingManager::users_and_tablets(1);
is( scalar( @{ $third->{tablets} } ), 1, 'Huelle mit Array als value' );

$SortingManager::userlist_hook = sub { return ( $userlist, undef ); };
$SortingManager::pairing_hook  = sub { return ( $pairing,  undef ); };


# ==========================================================================
# FTP-Schicht und vollstaendiges Inventar
# ==========================================================================

# Ein Fake-FTP: kennt genau die Methoden, die das Modul benutzt.
{
	package FakeFTP;
	sub new    { my ($c, %f) = @_; return bless { files => $f{files}, log => [] }, $c; }
	sub login  { push @{ $_[0]{log} }, "login:$_[1]"; return 1; }
	sub binary { return 1; }
	sub quit   { push @{ $_[0]{log} }, 'quit'; return 1; }
	sub message { return 'fake'; }
	sub ls {
		my ($self, $dir) = @_;
		return map { "$dir/$_" } sort keys %{ $self->{files} };
	}
	sub size {
		my ($self, $path) = @_;
		my $n = $path; $n =~ s{.*/}{};
		return length( $self->{files}{$n} // '' );
	}
	sub get {
		my ($self, $path, $fh) = @_;
		my $n = $path; $n =~ s{.*/}{};
		return 0 if (!exists $self->{files}{$n});
		print $fh $self->{files}{$n};
		return 1;
	}
	sub put {
		my ($self, $fh, $path) = @_;
		my $n = $path; $n =~ s{.*/}{};
		local $/;
		$self->{files}{$n} = <$fh>;
		push @{ $self->{log} }, "put:$n";
		return 1;
	}
}

my $chef_json = '{"userDefaultStructure":{"x":{},"y":{}},"ts":556000001,"audioZoneCustomization":{}}';
my $tab_json  = '{"userDefaultStructure":{"x":{}},"ts":556000002,"audioZoneCustomization":{}}';

my $fake;
$SortingManager::ftp_factory = sub {
	$fake = FakeFTP->new( files => {
		'11111111-1111-1111-111111111111.json' => '556000001/' . $chef_json,
		'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb.json' => '556000002/' . $tab_json,
		# eine verwaiste Datei ohne zugehoerigen Benutzer
		'cccccccc-cccc-cccc-cccccccccccc.json' => '556000003/{"userDefaultStructure":{},"ts":556000003}',
		'altes_zeug_2.xml'                     => '<xml/>',
	} );
	return $fake;
};

# --- Dateiliste ------------------------------------------------------------
my $files = SortingManager::list_sortings(1);
is( $files->{ok}, 1, 'list_sortings ok' );
is( scalar( keys %{ $files->{files} } ), 3, 'nur die drei .json-Dateien, keine .xml' );
ok( exists $files->{files}{'11111111-1111-1111-111111111111'}, 'Schluessel ist die UUID ohne Endung' );
cmp_ok( $files->{files}{'11111111-1111-1111-111111111111'}, '>', 0, 'Groesse wird geliefert' );

# --- Lesen -----------------------------------------------------------------
my $r = SortingManager::read_sorting(1, '11111111-1111-1111-111111111111');
is( $r->{ok}, 1,          'read_sorting ok' );
is( $r->{ts}, 556000001,  'Zeitstempel' );
is( SortingManager::control_count($r->{data}), 2, 'zwei Bausteine' );

my $missing = SortingManager::read_sorting(1, 'gibtesnicht');
is( $missing->{ok},    0,         'fehlende Datei' );
is( $missing->{error}, 'notfound','Fehlercode notfound' );

# --- Schreiben -------------------------------------------------------------
my $w = SortingManager::write_sorting_ftp(1, '22222222-2222-2222-222222222222',
                                          '556000009/{"userDefaultStructure":{},"ts":556000009}');
is( $w->{ok}, 1, 'write_sorting_ftp ok' );
ok( ( grep { $_ eq 'put:22222222-2222-2222-222222222222.json' } @{ $fake->{log} } ),
    'die Datei wurde unter der UUID abgelegt' );

# --- Vollstaendiges Inventar -----------------------------------------------
$SortingManager::userlist_hook = sub { return ( $userlist, undef ); };
$SortingManager::pairing_hook  = sub { return ( $pairing,  undef ); };

my $full = SortingManager::inventory(1);
is( $full->{ok}, 1, 'inventory ok' );

my ($ichef) = grep { $_->{name} eq 'chef' }   @{ $full->{entries} };
my ($igast) = grep { $_->{name} eq 'gast' }   @{ $full->{entries} };
my ($itab)  = grep { $_->{type} eq 'tablet' } @{ $full->{entries} };

is( scalar( @{ $full->{entries} } ), 4, 'drei Benutzer plus ein Tablet in einer Liste' );
is( $ichef->{has_sorting}, 1,         'chef hat eine Sortierung' );
is( $ichef->{ts},          556000001, 'mit Zeitstempel' );
is( $igast->{has_sorting}, 0,         'gast hat keine' );
is( $igast->{ts},          undef,     'ohne Zeitstempel' );
is( $itab->{has_sorting},  1,         'das Tablet hat eine' );

# Die verwaiste Datei gehoert zu keinem Eintrag - sie wird separat ausgewiesen
is( scalar( @{ $full->{orphans} } ), 1, 'eine verwaiste Sortierdatei' );
is( $full->{orphans}[0], 'cccccccc-cccc-cccc-cccccccccccc', 'die richtige' );

done_testing();
