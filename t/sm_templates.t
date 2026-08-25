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
	$used{$1} = 1 while ( $raw =~ /<TMPL_VAR\s+([A-Za-z0-9_.]+)\s*>/g );
	delete $used{LOGLIST};

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
		$t->param( %DE, LOGLIST => '' );
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
	tab_overview => [ qw( ms-select inv-body inv-orphans auto-reboot
	                      btn-save-selection btn-copy job-box job-title job-list
	                      pw-dialog pw-fields btn-pw-ok btn-pw-cancel inv-message ) ],
	tab_watch    => [ qw( ms-select watch-form watch-notconfigured watch-enabled
	                      watch-interval watch-reboot watch-last watch-lastts
	                      btn-watch-now btn-watch-save watch-message ) ],
	tab_backup   => [ qw( ms-select btn-backup-now backup-keep sched-enabled
	                      sched-days sched-hour sched-minute sched-weeks
	                      btn-backup-save backup-list restore-dialog
	                      restore-entries restore-info restore-reboot
	                      btn-restore-confirm btn-restore-cancel backup-message ) ],
);

foreach my $tab ( sort keys %ids ) {
	my $html = slurp("$tpldir/$tab.html");
	my @gone = grep { $html !~ /id="\Q$_\E"/ } @{ $ids{$tab} };
	is_deeply( \@gone, [], "$tab: alle vom JavaScript erwarteten IDs sind da" );
}

done_testing();
