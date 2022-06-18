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

# Regression tests for several bugs found by Jean-Damien

use 5.010001;
use strict;
use warnings;

use Test::More tests => 10;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $dsl;
my $grammar;
my $recce;
my $input;
my $length;
my $expected_output;
my $actual_output;
my $pos = 0;

# This first problem was with ambiguous SLIF parses when
# used together with values from an external scanner

$dsl = <<'END_OF_SOURCE';
:default ::= action => ::first
:start ::= Expression
Expression ::= Number
    | Expression Add Expression action => do_add
    | Expression Multiply Expression action => do_multiply
      Add ~ '+'
      Multiply ~ '*'
      Number ~ digits
      digits ~ [\d]+
      :discard ~ whitespace
      whitespace ~ [\s]+
END_OF_SOURCE

$grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
$recce = Marpa::R2::Scanless::R->new(
    { grammar => $grammar, semantics_package => 'My_Actions' } );
$input = '2*1+3*4+5';
$pos   = 0;
$recce->read( \$input, 0, 0 );
for my $input_token (qw(2 * 1 + 3 * 4 + 5)) {
    my $token_type =
          $input_token eq '+' ? 'Add'
        : $input_token eq '*' ? 'Multiply'
        :                       'Number';
    my $return_value = $recce->lexeme_read( $token_type, $pos, 1, $input_token );
    $pos++;
    Test::More::is( $return_value, $pos, "Return value of lexeme_read() is $pos" );
} ## end for my $input_token (qw(2 * 1 + 3 * 4 + 5))

my @values = ();
while ( my $value_ref = $recce->value() ) {
    push @values, ${$value_ref};
}

$expected_output = '19 19 25 29 31 36 36 37 37 42 45 56 72 72';
$actual_output = join " ", sort @values;
Test::More::is( $actual_output, $expected_output, 'Values for Durand test' );

sub My_Actions::do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub My_Actions::do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}
1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
