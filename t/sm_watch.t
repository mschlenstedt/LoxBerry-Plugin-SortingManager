#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw( tempdir );
use Time::Local qw( timelocal );
use JSON;

use lib File::Spec->catdir( $FindBin::Bin, '..', 'bin' );
use SortingManager;
use lib $FindBin::Bin;
use FakeLog;
use LoxBerry::System;

my $dir = tempdir( CLEANUP => 1 );
$SortingManager::config_file = "$dir/pluginconfig.json";
$SortingManager::history_dir = "$dir/hist";

my $SERIAL = 'AB:CD:EF:01:02:03';
my $SRC    = '11111111-1111-1111-111111111111';

# --- Hilfsmittel -----------------------------------------------------------
sub lox { return LoxBerry::System::epoch2lox( $_[0] ); }

sub fresh_entry {
	unlink $SortingManager::config_file;
	my $cfg = SortingManager::plugin_config();
	my $e   = SortingManager::ms_entry( $cfg, $SERIAL );
	$e->{msnr}   = 1;
	$e->{source} = $SRC;
	$e->{targets} = [ { uuid => '22222222-2222-2222-222222222222', name => 'gast',
	                    type => 'user', method => 'token' } ];
	return ( $cfg, $e );
}

# ==========================================================================
# watch_due
# ==========================================================================
my ( $cfg, $e ) = fresh_entry();
my $NOW = SortingManager::lox_now();

$e->{watch}{enabled}      = 0;
$e->{watch}{interval_min} = 15;
$e->{watch}{last_run}     = 0;
is( SortingManager::watch_due( $e, $NOW ), 0, 'abgeschaltet ist nie faellig' );

$e->{watch}{enabled} = 1;
is( SortingManager::watch_due( $e, $NOW ), 1, 'noch nie gelaufen ist sofort faellig' );

$e->{watch}{last_run} = $NOW - 14 * 60;
is( SortingManager::watch_due( $e, $NOW ), 0, '14 von 15 Minuten reichen nicht' );

$e->{watch}{last_run} = $NOW - 15 * 60;
is( SortingManager::watch_due( $e, $NOW ), 1, '15 Minuten sind faellig' );

# ==========================================================================
# backup_due
# ==========================================================================
# Fester Bezugspunkt, damit der Wochentag nicht vom Testtag abhaengt:
# 26.08.2026, 04:00 Uhr Ortszeit.
my $unix = timelocal( 0, 0, 4, 26, 7, 2026 );
my $wday = ( localtime($unix) )[6];
my $T    = lox($unix);

my ( $c2, $b ) = fresh_entry();
my $s = $b->{backup}{schedule};
$s->{enabled}     = 1;
$s->{days}        = [ ( $wday + 1 ) % 7 ];
$s->{hour}        = 3;
$s->{minute}      = 0;
$s->{every_weeks} = 1;
$s->{last_run}    = 0;
is( SortingManager::backup_due( $b, $T ), 0, 'falscher Wochentag' );

$s->{days} = [$wday];
$s->{hour} = 5;
is( SortingManager::backup_due( $b, $T ), 0, 'richtiger Tag, aber die Uhrzeit ist noch nicht erreicht' );

$s->{hour} = 3;
is( SortingManager::backup_due( $b, $T ), 1, 'richtiger Tag nach der eingestellten Zeit' );

$s->{last_run} = lox( $unix - 1800 );    # heute um 03:30
is( SortingManager::backup_due( $b, $T ), 0, 'heute schon gelaufen' );

$s->{last_run} = lox( $unix - 86400 );   # gestern
is( SortingManager::backup_due( $b, $T ), 1, 'woechentlich laeuft an jedem gewaehlten Tag' );

$s->{every_weeks} = 2;
$s->{last_run}    = lox( $unix - 8 * 86400 );
is( SortingManager::backup_due( $b, $T ), 1, 'alle zwei Wochen: nach acht Tagen faellig' );

$s->{last_run} = lox( $unix - 6 * 86400 );
is( SortingManager::backup_due( $b, $T ), 0, 'alle zwei Wochen: nach sechs Tagen nicht' );

# ==========================================================================
# run_watch
# ==========================================================================
my $source_ts = 556000001;
my @jobs;
{
	no warnings 'redefine';
	*SortingManager::ms_serial = sub { return { ok => 1, serial => $SERIAL, firmware => '17.1' }; };
	*SortingManager::read_sorting = sub {
		return { ok => 1, ts => $source_ts, raw => "$source_ts/{}", data => {} };
	};
	*SortingManager::run_copy_job = sub {
		my ( $msnr, $spec ) = @_;
		push @jobs, $spec;
		my $pending = ( grep { ( $_->{type} // '' ) eq 'tablet' } @{ $spec->{targets} } )
		              && !$spec->{auto_reboot};
		return {
			state          => 'done',
			results        => [ map { { name => $_->{name}, ok => 1 } } @{ $spec->{targets} } ],
			reboot_pending => ( $pending ? 1 : 0 ),
		};
	};
}

sub stored_entry {
	my $c = SortingManager::plugin_config();
	return SortingManager::ms_entry( $c, $SERIAL );
}

# --- Quelle unveraendert ---------------------------------------------------
@jobs = ();
( $cfg, $e ) = fresh_entry();
$e->{watch}{last_source_ts} = $source_ts;
SortingManager::save_config($cfg);

my $r = SortingManager::run_watch(1);
is( $r->{ok},      1, 'run_watch ok' );
is( $r->{changed}, 0, 'unveraenderte Quelle wird nicht kopiert' );
is( scalar(@jobs), 0, 'run_copy_job nicht gerufen' );
ok( stored_entry()->{watch}{last_run} > 0, 'der Lauf wird trotzdem vermerkt' );

# --- Quelle veraendert -----------------------------------------------------
@jobs = ();
( $cfg, $e ) = fresh_entry();
$e->{watch}{last_source_ts} = 555000000;
SortingManager::save_config($cfg);

$r = SortingManager::run_watch(1);
is( $r->{changed}, 1, 'veraenderte Quelle wird kopiert' );
is( scalar(@jobs), 1, 'genau ein Kopierlauf' );
is( $jobs[0]{source}, $SRC, 'mit der konfigurierten Quelle' );
is( scalar( @{ $jobs[0]{targets} } ), 1, 'und den konfigurierten Zielen' );
is( $jobs[0]{targets}[0]{name}, 'gast', 'Ziel namentlich' );

my $after = stored_entry();
is( $after->{watch}{last_source_ts}, $source_ts, 'der Zeitstempel der Quelle ist vermerkt' );
ok( $after->{watch}{last_run} > 0, 'und der Zeitpunkt des Laufs' );

# Ein zweiter Lauf kopiert nicht noch einmal
@jobs = ();
$r = SortingManager::run_watch(1);
is( $r->{changed}, 0, 'der zweite Lauf sieht keine Aenderung mehr' );
is( scalar(@jobs), 0, 'und kopiert nicht' );

# --- force kopiert trotzdem ------------------------------------------------
@jobs = ();
$r = SortingManager::run_watch( 1, force => 1 );
is( $r->{changed}, 1, 'force kopiert auch ohne Aenderung' );
is( scalar(@jobs), 1, 'ein Kopierlauf' );

# --- Nicht eingerichtet ----------------------------------------------------
@jobs = ();
( $cfg, $e ) = fresh_entry();
$e->{source} = undef;
SortingManager::save_config($cfg);

$r = SortingManager::run_watch(1);
is( $r->{ok},      0,               'ohne Quelle kein Lauf' );
is( $r->{skipped}, 1,               'sondern uebersprungen' );
is( $r->{reason},  'notconfigured', 'mit Begruendung' );
is( stored_entry()->{watch}{last_run}, 0,
    'und OHNE last_run - sonst greift eine spaetere Einrichtung erst nach dem Intervall' );

# --- Tablet ohne automatischen Reboot --------------------------------------
@jobs = ();
( $cfg, $e ) = fresh_entry();
$e->{targets} = [ { uuid => 'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb', name => 'Flur',
                    type => 'tablet', method => 'reboot' } ];
$e->{watch}{auto_reboot}    = 0;
$e->{watch}{last_source_ts} = 555000000;
SortingManager::save_config($cfg);

$r = SortingManager::run_watch(1);
is( $r->{changed}, 1,                'Tablet wird geschrieben' );
is( $r->{notify},  'rebootrequired', 'und der noetige Reboot gemeldet' );

# ==========================================================================
# Verlauf
# ==========================================================================
my $H = 'CD:EF:00:11:22:33';
is_deeply( SortingManager::watch_history($H), [], 'ohne Datei ist der Verlauf leer' );
SortingManager::push_history( $H, { ts => $_, result => 'unchanged' } ) foreach ( 1 .. 12 );
my $hist = SortingManager::watch_history($H);
is( scalar(@$hist), 10, 'der Verlauf haelt hoechstens zehn Eintraege' );
is( $hist->[0]{ts}, 12, 'neueste zuerst' );
is( $hist->[9]{ts}, 3,  'die aeltesten fallen heraus' );

open( my $bad, '>', SortingManager::history_file($H) ) or die; print $bad '{kaputt'; close($bad);
is_deeply( SortingManager::watch_history($H), [], 'kaputte Datei gilt als leer' );
SortingManager::push_history( $H, { ts => 99, result => 'unchanged' } );
is( SortingManager::watch_history($H)->[0]{ts}, 99, 'und wird beim naechsten Eintrag sauber ersetzt' );
{
	local $SortingManager::history_dir = undef;
	local $LoxBerry::System::lbpdatadir = '';
	is( SortingManager::history_file($H), undef, 'ohne Ablage kein Dateiname' );
}

# --- run_watch schreibt in den Verlauf -------------------------------------
@jobs = ();
( $cfg, $e ) = fresh_entry();
$e->{watch}{last_source_ts} = $source_ts;
SortingManager::save_config($cfg);
$r = SortingManager::run_watch(1);
my $h0 = SortingManager::watch_history($SERIAL)->[0];
is( $h0->{result}, 'unchanged', 'unveraenderte Quelle: Eintrag unchanged' );
ok( !$h0->{manual}, 'ohne manual nicht als von Hand markiert' );
ok( $h0->{ts} > 0, 'mit Zeitpunkt' );

# "Jetzt pruefen" darf bei unveraenderter Quelle nichts kopieren
@jobs = ();
$r = SortingManager::run_watch( 1, manual => 1 );
is( $r->{changed}, 0, 'manual kopiert unveraenderte Quelle nicht' );
is( scalar(@jobs), 0, 'kein Kopierlauf' );
is( SortingManager::watch_history($SERIAL)->[0]{manual}, 1, 'Eintrag als von Hand markiert' );

@jobs = ();
( $cfg, $e ) = fresh_entry();
$e->{targets} = [ { uuid => '22222222-2222-2222-222222222222', name => 'gast', type => 'user' },
                  { uuid => 'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb', name => 'Flur', type => 'tablet' } ];
$e->{watch}{last_source_ts} = 555000000;
SortingManager::save_config($cfg);
$r = SortingManager::run_watch(1);
$h0 = SortingManager::watch_history($SERIAL)->[0];
is( $h0->{result}, 'changed', 'geaenderte Quelle: Eintrag changed' );
is( $h0->{copied}, 2, 'mit Anzahl der erfolgreichen Ziele' );
is( $h0->{failed}, 0, 'und der fehlgeschlagenen' );
is( $h0->{reboot}, 'pending', 'gemeldeter Neustart' );

{
	no warnings 'redefine';
	local *SortingManager::read_sorting = sub { return { ok => 0, error => 'ftpfailed' }; };
	$r = SortingManager::run_watch(1);
}
$h0 = SortingManager::watch_history($SERIAL)->[0];
is( $h0->{result}, 'error',     'fehlgeschlagenes Lesen: Eintrag error' );
is( $h0->{error},  'ftpfailed', 'mit Fehlerschluessel' );

# --- next_watch ------------------------------------------------------------
my $nw = { watch => { enabled => 0, interval_min => 15, last_run => 0 } };
is( SortingManager::next_watch( $nw, 1000 ), undef, 'aus: kein naechster Lauf' );
$nw->{watch}{enabled} = 1;
is( SortingManager::next_watch( $nw, 1000 ), 1000, 'noch nie gelaufen: jetzt' );
$nw->{watch}{last_run} = 5000;
is( SortingManager::next_watch( $nw, 6000 ), 5900, 'sonst letzter Lauf plus Intervall' );

# --- Debug-Protokoll der Ueberwachung --------------------------------------
{
	my $fl = FakeLog->new;
	SortingManager::set_logger($fl);
	( $cfg, $e ) = fresh_entry();
	$e->{watch}{last_source_ts} = $source_ts;
	SortingManager::save_config($cfg);
	SortingManager::run_watch(1);
	my $all = $fl->all;
	SortingManager::set_logger(undef);
	like( $all, qr/^DEB .*$source_ts/m, 'der gelesene Stand der Quelle steht im Log' );
	like( $all, qr/unchanged/i,          'und die Entscheidung' );
}

done_testing();
