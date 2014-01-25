#!perl
# Copyright 2014 Jeffrey Kegler
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

# Tests negative ranks, SLIF ranks and
# external SLIF scanning

# This uses an ambiguous grammar to implement a binary
# counter.  A very expensive way to do it, but a
# good test of the ranking logic.

use 5.010;
use strict;
use warnings;

use Test::More tests => 16;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

sub My_Actions::zero { return '0' }
sub My_Actions::one  { return '1' }

sub My_Actions::start_rule_action {
    shift;
    return join q{}, @_;
}

## use critic

    my $grammar = Marpa::R2::Scanless::G->new(
    {
    source => \(<<'END_OF_GRAMMAR'),
:start ::= S
S ::= digit digit digit digit action => start_rule_action
digit ::=
      zero rank => 1 action => zero
    | one  rank => -1 action => one
zero ~ 't'
one ~ 't'
END_OF_GRAMMAR
}
    );

my @counting_up =
    qw{ 0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111 };

my $recce = Marpa::R2::Scanless::R->new(
    {   grammar           => $grammar,
        semantics_package => 'My_Actions',
        ranking_method    => 'rule'
    }
);

$recce->read(\'tttt');

my $i = 0;
while ( my $result = $recce->value() ) {
    my $got      = ${$result};
    my $expected = reverse $counting_up[$i];
    Test::More::is( $got, $expected, "counting up $i" );
    $i++;
} ## end while ( my $result = $recce->value() )

1;    # In case used as "do" file

# vim: expandtab shiftwidth=4:
