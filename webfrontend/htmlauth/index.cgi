#!/usr/bin/perl

# Sorting Manager web interface.
#
# Uses the LoxBerry Design System (lb-* classes), not jQuery Mobile: the fourth
# argument to lbheader() is "nojqm". The page is a set of tabs, one template per
# tab, selected through the ?form= parameter. All data is fetched from ajax.cgi,
# so switching tabs never loses state on the device.

use strict;
use warnings;
use CGI;
use HTML::Template;
use LoxBerry::System;
use LoxBerry::Web;
use LoxBerry::Log;

my $cgi = CGI->new;
my $q   = $cgi->Vars;

my $version = LoxBerry::System::pluginversion();

my $WIKI = 'https://wiki.loxberry.de/plugins/sortingmanager/start';

$q->{form} = 'overview' if ( !$q->{form} );
# Keeps the chosen Miniserver when switching tabs
my $ms = ( defined $q->{msnr} and $q->{msnr} =~ /^\d+$/ ) ? "&msnr=$q->{msnr}" : '';

my $template;
my $templateout;
my %L;

if ( $q->{form} eq 'watch' ) {
	$template = LoxBerry::System::read_file("$lbptemplatedir/tab_watch.html");
	&preparetemplate();
}
elsif ( $q->{form} eq 'backup' ) {
	$template = LoxBerry::System::read_file("$lbptemplatedir/tab_backup.html");
	&preparetemplate();
}
elsif ( $q->{form} eq 'logfiles' ) {
	$template = LoxBerry::System::read_file("$lbptemplatedir/tab_logfiles.html");
	&preparetemplate();
	$templateout->param( 'LOGLIST', LoxBerry::Web::loglist_html() );
}
else {
	$q->{form} = 'overview';
	$template = LoxBerry::System::read_file("$lbptemplatedir/tab_overview.html");
	&preparetemplate();
}

&printtemplate();
exit;

##########################################################################
# Template and navbar
##########################################################################

sub preparetemplate
{
	# The shared JavaScript is appended to every tab. It runs through
	# HTML::Template too, so it can use <TMPL_VAR> for localized strings, and
	# fetches its data from ajax.cgi.
	$template .= LoxBerry::System::read_file("$lbptemplatedir/javascript.js");

	$templateout = HTML::Template->new_scalar_ref(
		\$template,
		global_vars       => 1,
		loop_context_vars => 1,
		die_on_bad_params => 0,
	);
	%L = LoxBerry::System::readlanguage( $templateout, 'language.ini' );
	$templateout->param( WIKI_URL => $WIKI );

	# Navbar entries. Numeric keys control the display order.
	our %navbar;

	$navbar{10}{Name}   = $L{'COMMON.TAB_OVERVIEW'};
	$navbar{10}{URL}    = "index.cgi?form=overview$ms";
	$navbar{10}{active} = 1 if ( $q->{form} eq 'overview' );

	$navbar{20}{Name}   = $L{'COMMON.TAB_WATCH'};
	$navbar{20}{URL}    = "index.cgi?form=watch$ms";
	$navbar{20}{active} = 1 if ( $q->{form} eq 'watch' );

	$navbar{30}{Name}   = $L{'COMMON.TAB_BACKUP'};
	$navbar{30}{URL}    = "index.cgi?form=backup$ms";
	$navbar{30}{active} = 1 if ( $q->{form} eq 'backup' );


	$navbar{50}{Name}   = $L{'COMMON.TAB_LOGFILES'};
	$navbar{50}{URL}    = "index.cgi?form=logfiles$ms";
	$navbar{50}{active} = 1 if ( $q->{form} eq 'logfiles' );

	return ();
}


sub printtemplate
{
	# "nojqm" selects the LoxBerry Design System instead of jQuery Mobile.
	LoxBerry::Web::lbheader(
		$L{'COMMON.PLUGIN_TITLE'} . " V$version",
		$WIKI,
		'', 'nojqm'
	);
	print LoxBerry::Log::get_notifications_html($lbpplugindir);
	# Own styles on top of the Design System, tokens only
	print "<style>\n" . LoxBerry::System::read_file("$lbptemplatedir/style.css") . "</style>\n";
	print $templateout->output();
	LoxBerry::Web::lbfooter();
	return ();
}
