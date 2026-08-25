#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw( tempdir );
use JSON;
use Archive::Tar;

use lib File::Spec->catdir( $FindBin::Bin, '..', 'bin' );
use SortingManager;

my $dir = tempdir( CLEANUP => 1 );
$SortingManager::backup_dir = $dir;

# --- Inventar und Leseweg durch Attrappen ersetzen -------------------------
my %sortings = (
	'11111111-1111-1111-111111111111' => '556000001/{"userDefaultStructure":{"a":{},"b":{}},"ts":556000001}',
	'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb' => '556000002/{"userDefaultStructure":{"a":{}},"ts":556000002}',
);
{
	no warnings 'redefine';
	*SortingManager::ms_serial = sub {
		return { ok => 1, serial => 'AB:CD:EF:01:02:03', firmware => '17.1.7.3' };
	};
	*SortingManager::inventory = sub {
		return {
			ok      => 1,
			entries => [
				{ uuid => '11111111-1111-1111-111111111111', name => 'chef', type => 'admin',
				  has_sorting => 1, ts => 556000001, bytes => 60 },
				{ uuid => '22222222-2222-2222-222222222222', name => 'gast', type => 'user',
				  has_sorting => 0 },
				{ uuid => 'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb', name => 'Flur', type => 'tablet',
				  has_sorting => 1, ts => 556000002, bytes => 50 },
			],
			orphans => [ 'cccccccc-cccc-cccc-cccccccccccc' ],
		};
	};
	*SortingManager::read_sorting = sub {
		my ($msnr, $uuid) = @_;
		return { ok => 0, error => 'notfound' } if (!exists $sortings{$uuid});
		my $p = SortingManager::parse_sorting( $sortings{$uuid} );
		return { ok => 1, ts => $p->{ts}, data => $p->{data}, raw => $sortings{$uuid} };
	};
}

# --- Anlegen ---------------------------------------------------------------
my $b = SortingManager::create_backup(1);
is( $b->{ok},      1, 'create_backup ok' );
is( $b->{entries}, 2, 'zwei Sortierungen gesichert - der Benutzer ohne wird uebersprungen' );
ok( -e $b->{file}, 'die Archivdatei existiert' );
like( $b->{file}, qr{\.tar\.gz$}, 'gzip-Archiv' );
like( $b->{file}, qr{ABCDEF010203}, 'der Dateiname traegt die Seriennummer' );

my $mode = (stat($b->{file}))[2] & 07777;
is( $mode, 0600, 'Archiv ist 0600 - es enthaelt die Sortierungen aller Benutzer' );

# --- Inhalt des Archivs ----------------------------------------------------
my $tar = Archive::Tar->new();
$tar->read( $b->{file} );
my @names = sort $tar->list_files();
is( scalar(@names), 3, 'zwei Sortierungen plus Manifest' );
ok( ( grep { $_ eq 'manifest.json' } @names ), 'manifest.json liegt bei' );
ok( ( grep { $_ eq 'sortings/11111111-1111-1111-111111111111.json' } @names ), 'Sortierung des Admins' );
ok( ( grep { $_ eq 'sortings/bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb.json' } @names ), 'Sortierung des Tablets' );
ok( ! ( grep { /cccccccc/ } @names ), 'die verwaiste Datei ist NICHT im Archiv' );

my $man = JSON::from_json( $tar->get_content('manifest.json') );
is( $man->{miniserver}{serial},   'AB:CD:EF:01:02:03', 'Seriennummer im Manifest' );
is( $man->{miniserver}{firmware}, '17.1.7.3',          'Firmware im Manifest' );
is( scalar( @{ $man->{entries} } ), 2, 'zwei Eintraege im Manifest' );

my ($me) = grep { $_->{name} eq 'chef' } @{ $man->{entries} };
is( $me->{uuid}, '11111111-1111-1111-111111111111', 'UUID im Manifest' );
is( $me->{type}, 'admin',   'Typ im Manifest' );
is( $me->{ts},   556000001, 'Zeitstempel im Manifest' );
ok( $man->{created} > 550_000_000, 'Erstellungszeitpunkt in Loxone-Epoche' );

# --- Auflisten -------------------------------------------------------------
my $list = SortingManager::list_backups('AB:CD:EF:01:02:03');
is( ref($list),     'ARRAY', 'list_backups liefert eine Liste' );
is( scalar(@$list), 1,       'ein Archiv' );
is( $list->[0]{entries}, 2,  'Anzahl der Eintraege ohne Entpacken' );
ok( $list->[0]{bytes} > 0,   'Groesse' );

# Ein Archiv eines anderen Miniservers taucht hier nicht auf
is( scalar( @{ SortingManager::list_backups('AB:CD:EF:99:99:99') } ), 0,
    'nach Seriennummer getrennt' );

# --- Aufbewahrung ----------------------------------------------------------
sleep 1; SortingManager::create_backup(1, keep => 2);
sleep 1; SortingManager::create_backup(1, keep => 2);
sleep 1; SortingManager::create_backup(1, keep => 2);
is( scalar( @{ SortingManager::list_backups('AB:CD:EF:01:02:03') } ), 2,
    'keep begrenzt die Anzahl der Archive' );

# --- Pruefen vor dem Restore, ohne etwas zu aendern -------------------------
my $newest = SortingManager::list_backups('AB:CD:EF:01:02:03')->[0];
my $c = SortingManager::check_restore( $newest->{file} );
is( $c->{ok}, 1, 'check_restore ok' );
is( scalar( @{ $c->{manifest}{entries} } ), 2, 'Manifest gelesen' );

my $broken = SortingManager::check_restore("$dir/gibtesnicht.tar.gz");
is( $broken->{ok},    0,          'fehlende Datei' );
is( $broken->{error}, 'notfound', 'Fehlercode' );

# ==========================================================================
# Restore
# ==========================================================================

my @restored;
{
	no warnings 'redefine';
	*SortingManager::copy_to_user = sub {
		my ($msnr, $src, $name, %o) = @_;
		push @restored, { kind => 'user', name => $name, raw => $o{raw} };
		return { ok => 1, ts => SortingManager::lox_now(), controls => 2 };
	};
	*SortingManager::copy_to_tablet = sub {
		my ($msnr, $src, $uuid, %o) = @_;
		push @restored, { kind => 'tablet', uuid => $uuid, raw => $o{raw} };
		return { ok => 1, ts => SortingManager::lox_now(), controls => 1, needs_reboot => 1 };
	};
	*SortingManager::reboot_miniserver = sub { push @restored, { kind => 'reboot' }; return { ok => 1 }; };
}

my $arch = SortingManager::list_backups('AB:CD:EF:01:02:03')->[0]{file};

# --- Restore auf alle enthaltenen Eintraege --------------------------------
@restored = ();
my $res = SortingManager::restore_backup(1, $arch, auto_reboot => 1);
is( $res->{ok}, 1, 'restore_backup ok' );
is( scalar( @{ $res->{results} } ), 2, 'zwei Eintraege zurueckgespielt' );

my ($ru) = grep { $_->{kind} eq 'user' }   @restored;
my ($rt) = grep { $_->{kind} eq 'tablet' } @restored;
is( $ru->{name}, 'chef',                            'der Benutzer ueber seinen Namen' );
is( $rt->{uuid}, 'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb', 'das Tablet ueber seine UUID' );
ok( ( grep { $_->{kind} eq 'reboot' } @restored ), 'einmal rebootet' );

# --- Der Inhalt kommt aus dem Archiv, der Zeitstempel wird spaeter frisch ---
foreach my $r ( grep { defined $_->{raw} } @restored ) {
	my $p = SortingManager::parse_sorting( $r->{raw} );
	is( $p->{ok}, 1, 'zurueckgespielter Rumpf ist wohlgeformt' );
}
ok( scalar( grep { defined $_->{raw} } @restored ) == 2,
    'beide Eintraege wurden als fertige Vorlage uebergeben' );

# --- Nicht mehr existierende Benutzer werden uebersprungen -----------------
{
	no warnings 'redefine';
	*SortingManager::inventory = sub {
		return {
			ok      => 1,
			entries => [
				{ uuid => 'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb', name => 'Flur', type => 'tablet',
				  has_sorting => 1 },
			],
			orphans => [],
		};
	};
}
@restored = ();
my $partial = SortingManager::restore_backup(1, $arch, auto_reboot => 0);
is( $partial->{ok}, 1, 'Restore laeuft trotzdem' );
is( scalar( @{ $partial->{missing} } ), 1, 'ein Benutzer existiert nicht mehr' );
is( $partial->{missing}[0]{name}, 'chef', 'und wird benannt' );
ok( ! ( grep { $_->{kind} eq 'user' } @restored ), 'er wird nicht geschrieben' );
is( $partial->{reboot_pending}, 1, 'ohne auto_reboot wird der Reboot nur gemeldet' );

# --- Auswahl einzelner Eintraege -------------------------------------------
@restored = ();
my $only = SortingManager::restore_backup(1, $arch,
	only => [ 'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb' ], auto_reboot => 0);
is( scalar( @{ $only->{results} } ), 1, 'nur der gewaehlte Eintrag' );

# --- Loeschen --------------------------------------------------------------
my $before_count = scalar( @{ SortingManager::list_backups('AB:CD:EF:01:02:03') } );
my $d = SortingManager::delete_backup($arch);
is( $d->{ok}, 1, 'delete_backup ok' );
ok( ! -e $arch, 'die Datei ist weg' );
is( scalar( @{ SortingManager::list_backups('AB:CD:EF:01:02:03') } ), $before_count - 1,
    'eines weniger in der Liste' );

is( SortingManager::delete_backup("$dir/gibtesnicht.tar.gz")->{error}, 'notfound',
    'fehlende Datei wird gemeldet' );
# --- Kein brauchbares Ablageverzeichnis ------------------------------------
# Ohne Pluginkontext ist $lbpdatadir leer. Frueher wurde daraus der Pfad
# "/backups", und make_path starb - mitten im Job oder im CGI.
{
	local $SortingManager::backup_dir = undef;
	is( SortingManager::backup_dir(), undef, 'ohne Pluginkontext kein Verzeichnis' );
	my $r = SortingManager::create_backup(1);
	is( $r->{ok},    0,             'create_backup bricht sauber ab' );
	is( $r->{error}, 'nobackupdir', 'mit einem Fehlercode statt einem die' );
	is_deeply( SortingManager::list_backups('AB:CD:EF:01:02:03'), [],
	           'list_backups liefert eine leere Liste statt zu warnen' );
}

# Ein Verzeichnis, das nicht angelegt werden kann, ebenso
{
	local $SortingManager::backup_dir = "/proc/gibtesnicht/backups";
	my $r = SortingManager::create_backup(1);
	is( $r->{ok},    0,             'nicht anlegbares Verzeichnis' );
	is( $r->{error}, 'nobackupdir', 'wird gemeldet, nicht geworfen' );
}

# --- Pfadpruefung fuer Dateinamen aus dem Browser ---------------------------
{
	local $SortingManager::backup_dir = $dir;
	my $good = "$dir/sorting_ABCDEF010203_20260101_000000.tar.gz";
	is( SortingManager::safe_backup_file($good), $good, 'ein Archiv im Ablageordner' );
	is( SortingManager::safe_backup_file('/etc/passwd'), undef, 'Datei ausserhalb' );
	is( SortingManager::safe_backup_file("$dir/../etc/passwd.tar.gz"), undef, 'Ausbruch per ..' );
	is( SortingManager::safe_backup_file("$dir/unter/ordner.tar.gz"), undef, 'Unterordner' );
	is( SortingManager::safe_backup_file("$dir/archiv.zip"), undef, 'falsche Endung' );
	is( SortingManager::safe_backup_file(''), undef, 'leerer Name' );
	is( SortingManager::safe_backup_file(undef), undef, 'kein Name' );
}

done_testing();
