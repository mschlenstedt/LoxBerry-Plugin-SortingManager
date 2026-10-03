#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw( tempdir );
use JSON;

use lib File::Spec->catdir( $FindBin::Bin, '..', 'bin' );
use SortingManager;
use lib $FindBin::Bin;
use FakeLog;

my $dir = tempdir( CLEANUP => 1 );
$SortingManager::job_file = "$dir/job.json";

# --- Keine Datei, kein Status ----------------------------------------------
is( SortingManager::job_status(), undef, 'ohne Datei kein Status' );

# --- Kopierfunktionen durch Attrappen ersetzen -----------------------------
my @calls;
my %result = (
	'chef' => { ok => 1, ts => 556000010, controls => 3 },
	'gast' => { ok => 0, error => 'nocredentials', message => 'kein Passwort' },
);
{
	no warnings 'redefine';
	*SortingManager::copy_to_user = sub {
		my ($msnr, $src, $name, %o) = @_;
		push @calls, "user:$name";
		return $result{$name} || { ok => 1, ts => 1, controls => 1 };
	};
	*SortingManager::copy_to_tablet = sub {
		my ($msnr, $src, $uuid, %o) = @_;
		push @calls, "tablet:$uuid";
		return { ok => 1, ts => 556000011, controls => 3, needs_reboot => 1 };
	};
	*SortingManager::reboot_miniserver = sub {
		push @calls, 'reboot';
		return { ok => 1 };
	};
}

# --- Lauf mit drei Zielen, davon eines fehlerhaft --------------------------
my $spec = {
	source  => 'quelle-uuid',
	targets => [
		{ name => 'chef', type => 'user',   method => 'token' },
		{ name => 'gast', type => 'user',   method => 'token' },
		{ uuid => 'tab-uuid', name => 'Flur', type => 'tablet', method => 'reboot' },
	],
	auto_reboot => 1,
};

my $end = SortingManager::run_copy_job(1, $spec);
is( $end->{state},  'done', 'Job ist am Ende fertig' );
is( $end->{total},  3,      'drei Ziele' );
is( $end->{done},   3,      'alle drei abgearbeitet' );
is( $end->{failed}, 1,      'eines davon fehlgeschlagen' );

is_deeply( \@calls, [ 'user:chef', 'user:gast', 'tablet:tab-uuid', 'reboot' ],
           'Reihenfolge stimmt, und der Reboot kommt EINMAL am Schluss' );

my ($rchef) = grep { $_->{name} eq 'chef' } @{ $end->{results} };
my ($rgast) = grep { $_->{name} eq 'gast' } @{ $end->{results} };
is( $rchef->{ok},    1,               'chef erfolgreich' );
is( $rchef->{ts},    556000010,       'mit Zeitstempel' );
is( $rgast->{ok},    0,               'gast fehlgeschlagen' );
is( $rgast->{error}, 'nocredentials', 'mit Fehlercode' );

# --- Der Status liegt auf der Platte und ist lesbar ------------------------
my $st = SortingManager::job_status();
is( $st->{state}, 'done', 'Status aus der Datei' );
is( $st->{done},  3,      'Fortschritt gespeichert' );
is( ref($st->{results}), 'ARRAY', 'Einzelergebnisse gespeichert' );

# --- Ohne Tablet-Ziel wird nicht rebootet ----------------------------------
@calls = ();
SortingManager::run_copy_job(1, {
	source      => 'quelle-uuid',
	targets     => [ { name => 'chef', type => 'user', method => 'token' } ],
	auto_reboot => 1,
});
is_deeply( \@calls, [ 'user:chef' ], 'kein Reboot ohne Tablet-Ziel' );

# --- auto_reboot aus: Tablet wird geschrieben, aber nicht rebootet ---------
@calls = ();
my $noreboot = SortingManager::run_copy_job(1, {
	source      => 'quelle-uuid',
	targets     => [ { uuid => 'tab-uuid', name => 'Flur', type => 'tablet', method => 'reboot' } ],
	auto_reboot => 0,
});
is_deeply( \@calls, [ 'tablet:tab-uuid' ], 'ohne auto_reboot kein Reboot' );
is( $noreboot->{reboot_pending}, 1, 'aber der Job meldet, dass einer noetig waere' );

# ==========================================================================
# spawn_job - ein Lauf zur Zeit
# ==========================================================================

my @spawned;
$SortingManager::spawn_hook = sub { push @spawned, $_[1]; return 4711; };

sub set_status {
	my (%st) = @_;
	open( my $fh, '>', $SortingManager::job_file ) or die $!;
	print $fh JSON->new->encode( \%st );
	close($fh);
}

# Eine PID, die es sicher nicht gibt
my $DEAD = 999999;
$DEAD-- while ( $DEAD > 2 and kill( 0, $DEAD ) );

# --- Abgeschlossener Lauf blockiert nicht ----------------------------------
@spawned = ();
set_status( state => 'done', pid => $$ );
my $sp = SortingManager::spawn_job( { kind => 'backup', msnr => 1 } );
is( $sp->{ok},  1,    'nach einem abgeschlossenen Lauf wird gestartet' );
is( $sp->{pid}, 4711, 'die gemeldete PID kommt zurueck' );
is( scalar(@spawned), 1, 'der Runner wurde einmal gestartet' );
is( SortingManager::job_status()->{msnr}, 1, 'der Startzustand nennt den Miniserver' );

# Der Auftrag liegt als Datei bereit
my $specfile = $spawned[0];
ok( -e $specfile, 'die Auftragsdatei existiert' );
my $spec;
{ local $/; open( my $fh, '<', $specfile ); $spec = JSON::from_json(<$fh>); close($fh); }
is( $spec->{kind}, 'backup', 'mit der Art des Auftrags' );
is( ( stat($specfile) )[2] & 07777, 0600,
    'und 0600 - sie kann Passwoerter enthalten' );

# --- Laufender Prozess blockiert -------------------------------------------
@spawned = ();
set_status( state => 'running', pid => $$ );
my $busy = SortingManager::spawn_job( { kind => 'copy' } );
is( $busy->{ok},    0,            'ein laufender Job blockiert' );
is( $busy->{error}, 'jobrunning', 'mit eindeutigem Fehlercode' );
is( scalar(@spawned), 0, 'und es wird nichts gestartet' );

# --- Tote PID blockiert nicht ----------------------------------------------
@spawned = ();
set_status( state => 'running', pid => $DEAD );
is( SortingManager::spawn_job( { kind => 'copy' } )->{ok}, 1,
    'ein abgestuerzter Job blockiert nicht ewig' );

# --- Start ohne gemeldete PID ----------------------------------------------
# Zwischen spawn_job und dem ersten Lebenszeichen des Kindes steht noch keine
# PID im Status. Kurz danach gilt der Start als laufend, spaeter nicht mehr.
@spawned = ();
set_status( state => 'starting', pid => 0, started => SortingManager::lox_now() );
is( SortingManager::spawn_job( { kind => 'copy' } )->{error}, 'jobrunning',
    'ein gerade angelaufener Start blockiert' );

set_status( state => 'starting', pid => 0, started => SortingManager::lox_now() - 60 );
is( SortingManager::spawn_job( { kind => 'copy' } )->{ok}, 1,
    'ein haengengebliebener Start blockiert nicht ewig' );

# --- Fortschritt: das gerade bearbeitete Ziel steht im Jobstatus ----------
{
	my @snaps;
	no warnings 'redefine';
	local *SortingManager::_write_job = sub { my %c = %{ $_[0] }; push @snaps, \%c; return 1; };
	SortingManager::run_copy_job(1, {
		source  => 'quelle-uuid',
		targets => [ { uuid => 'uuid-a', name => 'chef', type => 'user' },
		             { uuid => 'uuid-b', name => 'Flur', type => 'tablet' } ],
		auto_reboot => 0,
	});
	my @cur = grep { defined $_->{current} } @snaps;
	ok( ( grep { $_->{current} eq 'uuid-a' and $_->{done} == 0 } @cur ), 'Ziel 1 wird als laufend gemeldet' );
	ok( ( grep { $_->{current} eq 'uuid-b' and $_->{done} == 1 } @cur ), 'Ziel 2 nach Ziel 1' );
	is( $snaps[-1]{state}, 'done', 'letzter Stand ist fertig' );
	ok( !exists $snaps[-1]{current}, 'und ohne laufendes Ziel' );
}

# --- Debug-Protokoll des Kopierjobs ---------------------------------------
{
	my $fl = FakeLog->new;
	SortingManager::set_logger($fl);
	SortingManager::run_copy_job(1, {
		source  => 'quelle-uuid',
		targets => [ { uuid => 'u1', name => 'chef', type => 'user' },
		             { uuid => 'u2', name => 'gast', type => 'user' } ],
		passwords => { gast => 'streng-geheim' },
	});
	my $all = $fl->all;
	SortingManager::set_logger(undef);
	like( $all, qr/^DEB .*1\/2.*chef/m, 'Ziel 1 von 2 mit Namen' );
	like( $all, qr/^DEB .*2\/2.*gast/m, 'Ziel 2 von 2 mit Namen' );
	like( $all, qr/^OK .*chef/m,        'Erfolg je Ziel' );
	like( $all, qr/^ERR .*gast.*nocredentials/m, 'Fehler je Ziel mit Schluessel' );
	unlike( $all, qr/streng-geheim/,    'kein Passwort im Log' );
}

# Ein Restore nennt sein Archiv, damit ein zweiter Tab den Fortschritt zuordnen kann
set_status( state => 'done', pid => $$ );
SortingManager::spawn_job( { kind => 'restore', msnr => 1, file => '/x/sorting_A_1.tar.gz' } );
is( SortingManager::job_status()->{file}, '/x/sorting_A_1.tar.gz', 'der Startzustand eines Restores nennt das Archiv' );

done_testing();

