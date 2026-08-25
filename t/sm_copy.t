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
make_path("$home/data/system");
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
use LoxBerry::Auth;

$LoxBerry::Auth::store_file = "$home/data/system/tokens.json";

# --- Fake-FTP mit einer Quellsortierung ------------------------------------
{
	package FakeFTP2;
	sub new    { my ($c, %f) = @_; return bless { files => $f{files}, log => [] }, $c; }
	sub login  { return 1; }
	sub binary { return 1; }
	sub quit   { return 1; }
	sub message{ return 'fake'; }
	sub ls     { my ($s, $d) = @_; return map { "$d/$_" } sort keys %{ $s->{files} }; }
	sub size   { my ($s, $p) = @_; my $n = $p; $n =~ s{.*/}{}; return length( $s->{files}{$n} // '' ); }
	sub get    { my ($s, $p, $fh) = @_; my $n = $p; $n =~ s{.*/}{};
	             return 0 if (!exists $s->{files}{$n}); print $fh $s->{files}{$n}; return 1; }
	sub put    { my ($s, $fh, $p) = @_; my $n = $p; $n =~ s{.*/}{};
	             local $/; $s->{files}{$n} = <$fh>; push @{ $s->{log} }, "put:$n"; return 1; }
}

my $SRC     = '11111111-1111-1111-111111111111';
my $srcjson = '{"userDefaultStructure":{"a":{},"b":{},"c":{}},"ts":556000001,"audioZoneCustomization":{}}';
my $ftpfake;
$SortingManager::ftp_factory = sub {
	$ftpfake = FakeFTP2->new( files => { "$SRC.json" => '556000001/' . $srcjson } )
		if (!$ftpfake);
	return $ftpfake;
};

# --- Fake-Miniserver fuer die Auth-Lib -------------------------------------
my $KEY = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
my @posts;
my %behave = ( gettoken => 'ok', setusersettings => 'ok' );

$LoxBerry::Auth::transport = sub {
	my ($url, %o) = @_;
	if ($url =~ m{/jdev/cfg/api$}) {
		return (200, '{"LL": { "control": "dev/cfg/api", "value": '
		           . '"{\'snr\': \'AB:CD:EF:01:02:03\', \'version\':\'17.1.7.3\'}", "Code": "200"}}', '200 OK');
	}
	if ($url =~ m{/jdev/sys/getkey2/}) {
		return (200, '{"LL":{"control":"getkey2","code":"200","value":{"key":"' . $KEY
		           . '","salt":"41B0A8F1","hashAlg":"SHA256"}}}', '200 OK');
	}
	if ($url =~ m{/jdev/sys/gettoken/}) {
		return (401, '<html>401</html>', '401 Unauthorized') if ($behave{gettoken} eq '401');
		return (200, '{"LL":{"control":"gettoken","code":"200","value":{"token":"TOK123","key":"'
		           . $KEY . '","validUntil":999999999,"tokenRights":1924,"unsecurePass":false}}}', '200 OK');
	}
	if ($url =~ m{/jdev/sps/setusersettings}) {
		push @posts, { url => $url, method => $o{method}, content => $o{content} };
		return (200, '{"LL":{"control":"setusersettings","value":"","Code":"200"}}', '200 OK')
			if ($behave{setusersettings} eq 'ok');
		return (401, '<html>401</html>', '401 Unauthorized');
	}
	if ($url =~ m{/jdev/sps/getusersettings}) {
		# Gegenprobe: liefert zurueck, was zuletzt geschrieben wurde
		my $last = @posts ? $posts[-1]{content} : '';
		return (200, '{"LL":{"control":"getusersettings","code":"200","value":'
		           . JSON->new->encode($last) . '}}', '200 OK');
	}
	if ($url =~ m{/jdev/sys/killtoken/}) {
		return (200, '{"LL":{"control":"killtoken","code":"200","value":"1"}}', '200 OK');
	}
	if ($url =~ m{/jdev/sys/reboot}) {
		return (200, '{"LL":{"control":"reboot","code":"200","value":"1"}}', '200 OK');
	}
	return (404, 'not found', '404 Not Found');
};

# --- Gutfall ---------------------------------------------------------------
@posts = ();
my $before = SortingManager::lox_now();
my $r = SortingManager::copy_to_user(1, $SRC, 'gast', password => 'geheim');
is( $r->{ok},       1, 'copy_to_user ok' );
is( $r->{controls}, 3, 'drei Bausteine uebertragen' );
cmp_ok( $r->{ts}, '>=', $before, 'der Zeitstempel ist frisch, nicht der der Quelle' );
isnt( $r->{ts}, 556000001, 'auf keinen Fall der Zeitstempel der Quelle' );

is( scalar(@posts), 1, 'genau ein Schreibvorgang' );
is( $posts[0]{method}, 'POST', 'als POST geschrieben' );
like( $posts[0]{url}, qr{user=gast}, 'fuer den Zielbenutzer angemeldet' );

# Der Rumpf muss aussen und innen denselben frischen Zeitstempel tragen
my $p = SortingManager::parse_sorting( $posts[0]{content} );
is( $p->{ok},       1,        'der geschriebene Rumpf ist wohlgeformt' );
is( $p->{ts},       $r->{ts}, 'Praefix traegt den gemeldeten Zeitstempel' );
is( $p->{data}{ts}, $r->{ts}, 'und innen steht derselbe' );
is( SortingManager::control_count($p->{data}), 3, 'Inhalt der Quelle unveraendert' );

# --- Fehlerfaelle ----------------------------------------------------------
my $noone = SortingManager::copy_to_user(1, 'gibtesnicht', 'gast', password => 'geheim');
is( $noone->{ok},    0,         'fehlende Quelle' );
is( $noone->{error}, 'notfound','Fehlercode der Quelle wird durchgereicht' );

$behave{gettoken} = '401';
LoxBerry::Auth::_cache_clear();
unlink "$home/data/system/tokens.json";
my $badpw = SortingManager::copy_to_user(1, $SRC, 'anderer', password => 'falsch');
is( $badpw->{ok},    0,               'falsches Passwort' );
is( $badpw->{error}, 'badcredentials','Fehlercode der Auth-Lib' );
$behave{gettoken} = 'ok';

# Ohne Passwort und ohne hinterlegten Token: die Oberflaeche muss fragen
LoxBerry::Auth::_cache_clear();
unlink "$home/data/system/tokens.json";
my $nopw = SortingManager::copy_to_user(1, $SRC, 'niemand');
is( $nopw->{ok},    0,               'ohne Passwort kein Kopiervorgang' );
is( $nopw->{error}, 'nocredentials', 'Fehlercode nocredentials' );

# ==========================================================================
# Tablet-Weg und Reboot
# ==========================================================================

my $TAB = 'bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb';
@posts = ();
my $tr = SortingManager::copy_to_tablet(1, $SRC, $TAB);
is( $tr->{ok},           1, 'copy_to_tablet ok' );
is( $tr->{controls},     3, 'drei Bausteine' );
is( $tr->{needs_reboot}, 1, 'meldet, dass ein Reboot noetig ist' );
is( scalar(@posts),      0, 'ein Tablet wird NICHT ueber setusersettings geschrieben' );

# per FTP unter der Benutzer-UUID des Tablets abgelegt
ok( ( grep { $_ eq "put:$TAB.json" } @{ $ftpfake->{log} } ),
    'die Datei liegt unter der Benutzer-UUID des Tablets' );

my $written = SortingManager::parse_sorting( $ftpfake->{files}{"$TAB.json"} );
is( $written->{ok},       1,          'die geschriebene Datei ist wohlgeformt' );
is( $written->{ts},       $tr->{ts},  'mit dem gemeldeten Zeitstempel' );
is( $written->{data}{ts}, $tr->{ts},  'innen derselbe' );
cmp_ok( $written->{ts}, '>', 556000001, 'neuer als die Quelle' );
is( SortingManager::control_count($written->{data}), 3, 'Inhalt der Quelle' );

# --- Reboot ist ein eigener Schritt ----------------------------------------
my $rb = SortingManager::reboot_miniserver(1);
is( $rb->{ok}, 1, 'reboot_miniserver ok' );

# --- Fehlende Quelle -------------------------------------------------------
my $tnone = SortingManager::copy_to_tablet(1, 'gibtesnicht', $TAB);
is( $tnone->{ok},    0,          'fehlende Quelle' );
is( $tnone->{error}, 'notfound', 'Fehlercode' );

# --- Vorlage statt Quelle (das macht der Restore) --------------------------
my $tpl = '556000500/{"userDefaultStructure":{"z":{}},"ts":556000500}';
@posts = ();
LoxBerry::Auth::_cache_clear();
my $fromraw = SortingManager::copy_to_user(1, undef, 'gast', raw => $tpl, password => 'geheim');
is( $fromraw->{ok},       1, 'copy_to_user mit fertiger Vorlage' );
is( $fromraw->{controls}, 1, 'Inhalt der Vorlage' );
my $rawp = SortingManager::parse_sorting( $posts[0]{content} );
cmp_ok( $rawp->{ts}, '>', 556000500, 'auch die Vorlage bekommt einen frischen Zeitstempel' );

# --- Der Miniserver-Administrator braucht kein zweites Passwort -------------
# Sein Passwort steht in general.json. Die Auth-Lib nimmt es nur, wenn gar kein
# Benutzer genannt wird - hier wird er aber genannt, also muss das Plugin es
# selbst beisteuern, statt die Oberflaeche danach fragen zu lassen.
@posts = ();
LoxBerry::Auth::_cache_clear();
unlink "$home/data/system/tokens.json";
my $asadmin = SortingManager::copy_to_user(1, $SRC, 'lbuser');
is( $asadmin->{ok}, 1, 'Kopie auf den Miniserver-Administrator ohne Passwortangabe' );
like( $posts[0]{url}, qr{user=lbuser}, 'als er selbst angemeldet' );

# Ein anderer Benutzer bekommt dieses Passwort nicht untergeschoben
LoxBerry::Auth::_cache_clear();
unlink "$home/data/system/tokens.json";
is( SortingManager::copy_to_user(1, $SRC, 'fremder')->{error}, 'nocredentials',
    'fuer einen anderen Benutzer gilt das nicht' );

done_testing();
