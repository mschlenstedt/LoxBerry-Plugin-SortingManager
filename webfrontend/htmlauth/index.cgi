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

$q->{form} = 'overview' if ( !$q->{form} );

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

	# Navbar entries. Numeric keys control the display order.
	our %navbar;

	$navbar{10}{Name}   = $L{'COMMON.TAB_OVERVIEW'};
	$navbar{10}{URL}    = 'index.cgi?form=overview';
	$navbar{10}{active} = 1 if ( $q->{form} eq 'overview' );

	$navbar{20}{Name}   = $L{'COMMON.TAB_WATCH'};
	$navbar{20}{URL}    = 'index.cgi?form=watch';
	$navbar{20}{active} = 1 if ( $q->{form} eq 'watch' );

	$navbar{30}{Name}   = $L{'COMMON.TAB_BACKUP'};
	$navbar{30}{URL}    = 'index.cgi?form=backup';
	$navbar{30}{active} = 1 if ( $q->{form} eq 'backup' );

	# Not a tab of ours: a link to the Miniserver, opened in a new window.
	# Which one is a guess - the first configured, or the one the interface was
	# last pointed at.
	my $msurl = &miniserver_url();
	if ($msurl) {
		$navbar{40}{Name}   = $L{'COMMON.TAB_MINISERVER'};
		$navbar{40}{URL}    = $msurl;
		$navbar{40}{target} = '_blank';
	}

	$navbar{50}{Name}   = $L{'COMMON.TAB_LOGFILES'};
	$navbar{50}{URL}    = 'index.cgi?form=logfiles';
	$navbar{50}{active} = 1 if ( $q->{form} eq 'logfiles' );

	return ();
}

sub miniserver_url
{
	my %ms = LoxBerry::System::get_miniservers();
	return undef if ( !%ms );

	my $msnr = ( $q->{msnr} and $ms{ $q->{msnr} } )
		? $q->{msnr}
		: ( sort { $a <=> $b } keys %ms )[0];

	my $m = $ms{$msnr};
	my $scheme = $m->{Preferhttps} ? 'https' : 'http';
	my $port   = $m->{Preferhttps} ? $m->{Porthttps} : $m->{Port};
	my $host   = $m->{Ipaddress};
	return undef if ( !$host );
	return ( $port and $port != 80 and $port != 443 )
		? "$scheme://$host:$port/"
		: "$scheme://$host/";
}

sub printtemplate
{
	# "nojqm" selects the LoxBerry Design System instead of jQuery Mobile.
	LoxBerry::Web::lbheader(
		$L{'COMMON.PLUGIN_TITLE'} . " V$version",
		'https://wiki.loxberry.de/plugins/sortingmanager/start',
		'', 'nojqm'
	);
	print LoxBerry::Log::get_notifications_html($lbpplugindir);
	print $templateout->output();
	LoxBerry::Web::lbfooter();
	return ();
}
