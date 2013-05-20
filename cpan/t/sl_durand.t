#!/usr/bin/perl
# Copyright 2013 Jeffrey Kegler
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

# Regression test for bug found by Jean-Damien
# The problem was with ambiguous SLIF parses when
# used together with values from an external scanner

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Nodes',
        default_action => 'first_arg',
        source         => \(<<'END_OF_SOURCE'),
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
    }
);

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
my $input = '2*1+3*4+5';
my $pos = 0;
$recce->read( \$input, 0, 0 );
for my $input_token (qw(2 * 1 + 3 * 4 + 5)) {
    my $token_type = $input_token eq '+' ? 'Add' : $input_token eq '*' ? 'Multiply' : 'Number';
    $recce->lexeme_read( $token_type, $pos, 1, $input_token );
    $pos++;
}

my @values = ();
while (my $value_ref = $recce->value()) {
   push @values, ${$value_ref};
}
my $expected_values = '19 19 25 29 31 36 36 37 37 42 45 56 72 72';
my $actual_values = join " ", sort @values;
Test::More::is( $actual_values, $expected_values, 'Values for Durand test' );

package My_Nodes;

sub new { return {}; }

sub do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}

sub first_arg { shift; return shift; }


1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
