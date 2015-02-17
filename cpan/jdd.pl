#!env perl
use strict;
use warnings;
use Marpa::R2;

my $s = do { local $/; <DATA>; };
my $g = Marpa::R2::Scanless::G->new({source => \$s});
# my $r = Marpa::R2::Scanless::R->new({grammar => $g, trace_terminals => 999, trace_values => 999});
$g->parse(\'');

__DATA__
# :default ::= action => ::first
:start ::= null

null ::=
