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

done_testing();
