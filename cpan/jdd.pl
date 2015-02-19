#!env perl
use strict;
use diagnostics;
use Marpa::R2;
use Data::Dumper;

print "\$Marpa::R2::VERSION=$Marpa::R2::VERSION\n";

my $s = do { local $/; <DATA>; };
my $g = Marpa::R2::Scanless::G->new({source => \$s});
print Dumper($g->parse(\'', {trace_terminals => 999, trace_values => 999}));

sub nullAction {
  return 'not null';
}

__DATA__
:default ::= action => [values]
lexeme default = action => [start,length,value,name]

:start ::= fake

fake ::=          action => main::nullAction
fake ::= 'unused'
