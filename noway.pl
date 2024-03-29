#!/bin/env perl
# Copyright 2022 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
use strict;
use warnings;
use Marpa::R2 2.086000;
use Data::Dumper;

my $dsl = <<'EO_DSL';
:default ::= action => My_Action::asis
lexeme default = latm => 1

exps ::= exp+
exp ::= [a-z]
   || '(' exp ')' assoc => group
   | '[' exp ']' assoc => group
   | '<' exp '>' assoc => group
   | '{' exp '}' assoc => group
   | [({[<] exp [>\x{5D}})] assoc => group rank => -1
      action => My_Action::correct
   || exp '<' exp action => My_Action::lt
   | exp '>' exp action => My_Action::gt
:discard ~ ws
ws ~ [\s]+
EO_DSL

my $g = Marpa::R2::Scanless::G->new( { source => \$dsl } );

my @input = (
'(a>b)((<{b>>>>',
'(a>b)((<{b<c<d>>>>',
'(a>b)((<{b<<<c>)<d>>>>',
'(a>b)((<{ b < << i>j >> > d >>>>',
);

for my $input (@input) {
  my $r = Marpa::R2::Scanless::R->new( { grammar => $g
    , ranking_method => 'high_rule_only'
    # , trace_terminals => 1
  } );
  $r->read(\$input);
  my $pp_val = { warnings => [] };
  my $value_ref = $r->value($pp_val);
  say join "\n", @{$pp_val->{warnings}};
  # say Data::Dumper::Dumper($pp_val);
  die "No parse" unless defined $value_ref;
  say qq{Input: $input};
  say 'Output: ', ${$value_ref};
}

package My_Action;

sub gt {
   my ($pp_val, $left, $gt, $right) = @_;
   return join q{}, $left, ' gt ', $right;
}

sub lt {
   my ($pp_val, $left, $lt, $right) = @_;
   return join q{}, $left, ' lt ', $right;
}

sub asis
{ 
   my ($pp_val, @args) = @_;
   return join q{}, @args;
}

sub correct
{
   my ($pp_val, $left, $exp, $right) = @_;
   state $brackets = '(){}[]<>';
   my $left_ix = index $brackets, $left;
   my $new_right = substr $brackets, $left_ix+1, 1;
   push @{$pp_val->{warnings}}, qq{Mismatched brackets: "$left$right" corrected to "$left$new_right"};
   return join q{}, $left, $exp, $new_right;
}

exit 0;
