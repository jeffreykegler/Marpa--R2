#!/usr/bin/perl
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

# Dave Abrahams marpabook repo issue 3
# Attempt at Minimal Work Example
# "Bad ambiguity report"

use 5.010001;
use strict;
use warnings;
use Scalar::Util;
use Data::Dumper;
use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

say 'Libmarpa tag: ' . Marpa::R2::Thin::tag();

my $bnf = <<'END_OF_BNF';
:default ::= action => [values]
lexeme default = latm => 1
A ::= 'w' 'x' B | 'w'
B ::= C
C ::= 'y' 'z' A

:discard ~ whitespace
whitespace ~ [\s]+
END_OF_BNF

sub My_Actions::do_rule {
    my ( undef, $t1, undef, $t2 ) = @_;
    return [$t1, @{$t2}];
}

my $grammar = Marpa::R2::Scanless::G->new(
    {  
        source          => \$bnf,
    }
);

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar,
   # trace_earley_sets => 1,
   trace_terminals => 1
   } );

my $string = 'w x y z w x y z w';

read_input();

say "Ambiguity Metric: ", $recce->ambiguity_metric();
say "Ambiguity: ", $recce->ambiguous();

# Start a new recognizer, because we cannot call
# $r->ambiguous() and $r->value() on the same recognizer
$recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
read_input();
say "Ambiguity Metric: ", $recce->ambiguity_metric();
say $grammar->show_rules();
# say "=== ISYs ===\n", $grammar->show_isys();
# say $grammar->show_irls();
# say "=== And nodes ===\n", $recce->show_and_nodes(1);
# say "=== Or nodes ===\n", $recce->verbose_or_nodes();
# say "=== Bocage ===\n", $recce->show_bocage();
say "=== Earley sets ===\n", $recce->show_earley_sets();

Marpa::R2::Thin::debug_level_set(1);
my $value_ref = $recce->value();
if ( not defined $value_ref ) {
    die "No parse was found, after reading the entire input\n";
}

my $expected_value = \[ ];

Test::More::is(
    Data::Dumper::Dumper($value_ref),
    Data::Dumper::Dumper($expected_value),
    'Value of parse'
);

sub read_input {
    $recce->read( \$string );

}

sub main::dwim {
    my @result = ();
    shift;
    ARG: for my $v ( @_ ) {
        next ARG if not $v;
        my $type = Scalar::Util::reftype $v;
        if (not $type or $type ne 'ARRAY') {
           push @result, $v;
           next ARG;
        }
        my $size = scalar @{$v};
        next ARG if $size == 0;
        if ($size == 1) {
           push @result, ${$v}[0];
           next ARG;
        }
        push @result, $v;
    }
    return [@result];
}

# vim: expandtab shiftwidth=4:
