package FakeLog;

# Stands in for a LoxBerry::Log object: collects every message with its level.
use strict;
use warnings;

sub new { return bless { m => [] }, shift; }
foreach my $lvl (qw( DEB INF OK WARN ERR )) {
	no strict 'refs';
	*{$lvl} = sub { push @{ $_[0]{m} }, [ $lvl, $_[1] ]; return; };
}
sub all   { return join( "\n", map { "$_->[0] $_->[1]" } @{ $_[0]{m} } ); }
sub clear { $_[0]{m} = []; return; }

1;
