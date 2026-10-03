#!/usr/bin/env perl

# Prueft die Vorlagen so, wie index.cgi sie zusammensetzt: Tab-Template plus
# javascript.js durch HTML::Template, gefuellt aus der Sprachdatei. Faengt
# kaputte Tags und - vor allem - jeden Platzhalter, fuer den es keine
# Uebersetzung gibt. Ohne diesen Test faellt so etwas erst im Browser auf,
# als leere Stelle in der Oberflaeche.

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use HTML::Template;

my $tpldir = File::Spec->catdir( $FindBin::Bin, '..', 'templates' );

# --- Sprachdateien einlesen ------------------------------------------------
sub read_lang {
	my ($file) = @_;
	my %L;
	my $section = '';
	open( my $fh, '<:encoding(UTF-8)', $file ) or die "$file: $!";
	while ( my $line = <$fh> ) {
		chomp $line;
		next if ( $line =~ /^\s*(#|;|$)/ );
		if ( $line =~ /^\[(.+)\]\s*$/ ) { $section = $1; next; }
		next if ( $line !~ /^([A-Za-z0-9_]+)\s*=\s*(.*)$/ );
		my ( $key, $value ) = ( $1, $2 );
		$value =~ s/^"//;
		$value =~ s/"$//;
		$L{"$section.$key"} = $value;
	}
	close($fh);
	return %L;
}

my %DE = read_lang("$tpldir/lang/language_de.ini");
my %EN = read_lang("$tpldir/lang/language_en.ini");

ok( scalar( keys %DE ) > 50, 'die deutsche Sprachdatei hat Inhalt' );
is_deeply( [ sort keys %EN ], [ sort keys %DE ],
           'beide Sprachdateien fuehren dieselben Schluessel' );

# --- Jede Vorlage rendern --------------------------------------------------
sub slurp {
	my ($file) = @_;
	local $/;
	open( my $fh, '<:encoding(UTF-8)', $file ) or die "$file: $!";
	my $c = <$fh>;
	close($fh);
	return $c;
}

my $js = slurp("$tpldir/javascript.js");

foreach my $tab (qw( tab_overview tab_watch tab_backup tab_logfiles )) {
	my $raw = slurp("$tpldir/$tab.html") . $js;

	# Welche Platzhalter kommen vor? LOGLIST fuellt index.cgi selbst.
	my %used;
	$used{$1} = 1 while ( $raw =~ /<TMPL_VAR\s+([A-Za-z0-9_.]+)(?:\s+ESCAPE=\w+)?\s*>/g );
	# Filled by index.cgi itself
	delete @used{qw( LOGLIST WIKI_URL )};

	my @missing = grep { !exists $DE{$_} } sort keys %used;
	is_deeply( \@missing, [], "$tab: jeder Platzhalter hat eine Uebersetzung" );

	my $out;
	my $ok = eval {
		my $t = HTML::Template->new_scalar_ref(
			\$raw,
			global_vars       => 1,
			loop_context_vars => 1,
			die_on_bad_params => 0,
		);
		$t->param( %DE, LOGLIST => '', WIKI_URL => 'https://example.org/' );
		$out = $t->output();
		1;
	};
	ok( $ok, "$tab: laesst sich fehlerfrei rendern" ) or diag($@);
	next if (!$ok);

	unlike( $out, qr/<TMPL_VAR/, "$tab: kein Platzhalter bleibt stehen" );
	like( $out, qr/<script>/,    "$tab: das gemeinsame JavaScript haengt daran" );
}

# --- Die Bausteine, auf die das JavaScript zugreift, muessen existieren ----
# Ein Tippfehler in einer ID faellt sonst erst im Browser auf, und dort nur
# als "der Knopf tut nichts".
my %ids = (
	tab_overview => [ qw( sm-page ov-switch ov-card ov-error ov-src ov-src-off ov-tgt ov-quick
	                      ov-orphans ov-bar ov-notes ) ],
	tab_watch    => [ qw( sm-page ctx w-error w-notconf w-card w-on w-dot w-state w-sub w-toast
	                      w-now w-what w-hist w-set w-int w-rb ) ],
	tab_backup   => [ qw( sm-page ctx b-error b-card b-on b-next b-next-sub b-keepinfo b-keepsub
	                      b-space b-free b-now b-runline b-sched b-toast b-dep b-days b-time
	                      b-nodays b-rep b-keep b-count b-list ) ],
);

foreach my $tab ( sort keys %ids ) {
	my $html = slurp("$tpldir/$tab.html");
	my @gone = grep { $html !~ /id="\Q$_\E"/ } @{ $ids{$tab} };
	is_deeply( \@gone, [], "$tab: alle vom JavaScript erwarteten IDs sind da" );
}

# --- Gestaltung nur ueber Design-System-Variablen --------------------------
my $css = slurp("$tpldir/style.css");
unlike( $css, qr/#[0-9a-f]{3,8}\b/i, 'style.css: keine feste Farbe' );
unlike( $css, qr/\brgba?\(/,        'style.css: kein rgb()' );
unlike( $js,  qr/\b(confirm|alert|prompt)\s*\(/, 'javascript.js: keine Browser-Dialoge' );
# Das Auge schaltet ein Passwortfeld auf type=text - wer ueber den Typ sucht,
# verliert das Passwort, sobald jemand es sich angesehen hat.
unlike( $js, qr/input\[type=password\]/, 'javascript.js: Passwortfelder nicht ueber ihren Typ suchen' );
like( $js, qr/function errorBox[^\n]*\n(?:[^\n]*\n){0,4}?[^\n]*data-close/, 'javascript.js: Fehlermeldungen lassen sich schliessen' );
# Deeplink in die Loxone App (Aufbau wie bei exo.loxone.com: loxone://ms?mac=<12 Hex>)
# Jeder Fehlerschluessel, den Modul, Auth-Lib oder ajax.cgi liefern, hat einen Text -
# sonst steht in der Oberflaeche "Unbekannter Fehler (unreachable)".
my @errkeys = qw( unreachable notreachable parseerror ftpfailed httperror badcredentials
                  nocredentials nopassword notoken revoked missingright msnotfound fwtooold
                  verifyfailed notfound jobrunning nobackupdir nojobdir writefailed deletefailed
                  unreadable nomanifest missinginarchive inventoryfailed forkfailed badpath
                  baddata savefailed postrequired unknownaction notconfigured nosource
                  notargets nomsnr nominiserver connection );
my @untranslated = grep { !exists $DE{ 'ERR.' . uc($_) } } @errkeys;
is_deeply( \@untranslated, [], 'jeder Fehlerschluessel hat einen Text' );

# Nicht erreichbar: Knopf zum erneuten Pruefen und selbststaendige Pruefung
like( $js, qr/function loadError[\s\S]{0,1500}"reach"/, 'javascript.js: Ladefehler pruefen die Erreichbarkeit selbst nach' );
like( $js, qr/function loadError[\s\S]{0,1500}data-retry/, 'javascript.js: Ladefehler haben einen Knopf zum erneuten Pruefen' );
my $ajax = slurp( File::Spec->catfile( $FindBin::Bin, '..', 'webfrontend', 'htmlauth', 'ajax.cgi' ) );
like( $ajax, qr/\$action eq 'reach'/, "ajax.cgi: Aktion 'reach'" );

like( $js, qr{loxone://ms\?mac=}, 'javascript.js: Knopf "In Loxone App oeffnen"' );
like( $js, qr/function appButton[\s\S]{0,600}COMMON\.OPEN_APP_SHORT/, 'javascript.js: App-Knopf mit kurzer Beschriftung' );
my $cgi = slurp( File::Spec->catfile( $FindBin::Bin, '..', 'webfrontend', 'htmlauth', 'index.cgi' ) );
unlike( $cgi, qr/TAB_MINISERVER/, 'index.cgi: kein Reiter Miniserver mehr' );

done_testing();
