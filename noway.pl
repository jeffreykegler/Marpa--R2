#!/bin/env perl

use 5.010;
use strict;
use warnings;
use Marpa::R2 2.086000;
use Data::Dumper;

my $dsl = <<'EO_DSL';
:default ::= action => [name,values]
lexeme default = latm => 1

exp ::= [a-z]
   || '(' exp ')' assoc => group
   | '[' exp ']' assoc => group
   | '<' exp '>' assoc => group
   | '{' exp '}' assoc => group
   | [({[<] exp [>\x{5D}})] assoc => group rank => -1
EO_DSL

my $g = Marpa::R2::Scanless::G->new( { source => \$dsl } );

my @input = (
'(<(({a>>>>>',
# '(>((<{a>>>>',
);

for my $input (@input) {
  my $r = Marpa::R2::Scanless::R->new( { grammar => $g
    , trace_terminals => 1
  } );
  $r->read(\$input);
  my $value_ref = $r->value();
  die "No parse" unless defined $value_ref;
  say Data::Dumper::Dumper( $value_ref );
}

exit 0;
