#!/usr/bin/perl
# Copyright 2018 Jeffrey Kegler
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

# This test is mainly a place to record his "dwim" function,
# which Jeffrey keeps losing track of.
# The DWIM (Do What I Mean) action is intended to be used as
# a default action.  It looks at the values
# of each rule and gives you a compact first cut,
# which is reasonably likely to turn out to be
# what you want to do with the rule.

# The example is based on the smaller minimal working example
# for Libmarpa issue 115 (Dave Abrahams).

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

my $bnf = <<'END_OF_BNF';
:default ::= action => main::dwim
lexeme default = latm => 1
:start ::= prefixExpr
prefixExpr ::= null prefixExpr Arg2
prefixExpr ::= Arg1
null ::= 

:discard ~ whitespace
unicorn ~ [^\d\D]
whitespace ~ [\s]+
Arg1 ~ unicorn
Arg2 ~ unicorn
END_OF_BNF

my $grammar = Marpa::R2::Scanless::G->new(
    {
        source => \$bnf,
    }
);

my $string = <<'EOS';
    type A {
      var a: Int
      fun foo(a: Int) { a.copy() }
      fun foo(b: Int) -> Int {
        let   { a + b }
        inout { b += a }
      }
    }
EOS

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

$recce->read( \$string, 0, 0 );

if ( not defined $recce->lexeme_read( 'Arg1', undef, 1, 'Arg1' ) ) {
    die qq{Parser rejected token "Arg1"};
}
if ( not defined $recce->lexeme_read( 'Arg2', undef, 1, 'Arg2' ) ) {
    die qq{Parser rejected token "Arg2"};
}
if ( not defined $recce->lexeme_read( 'Arg2', undef, 1, 'Arg2' ) ) {
    die qq{Parser rejected token "Arg2"};
}

my $value_ref = $recce->value();
if ( not defined $value_ref ) {
    die "No parse was found, after reading the entire input\n";
}

my $expected_value = \[ [ 'Arg1', 'Arg2' ], 'Arg2' ];

Test::More::is_deeply(
    Data::Dumper::Dumper($value_ref),
    Data::Dumper::Dumper($expected_value),
    'Value of parse'
);

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
