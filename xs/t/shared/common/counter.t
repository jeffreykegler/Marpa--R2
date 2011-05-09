#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::PP.  Marpa::PP is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::PP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::PP.  If not, see
# http://www.gnu.org/licenses/.

# This uses an ambiguous grammar to implement a binary
# counter.  A very expensive way to do it, but a
# good test of the ranking logic.

use 5.010;
use strict;
use warnings;

use Test::More tests => 33;
use English qw( -no_match_vars );
use Marpa::PP::Test;
use Carp;

BEGIN {
    Test::More::use_ok('Marpa::Any');
}

## no critic (Subroutines::RequireArgUnpacking)

# Ranks are less than 1
# to make sure
# that integer rounding
# is not happening anywhere.

# If we are counting up, the lowest number
# has to have the highest numerical rank.
sub rank_one {
    return \( ( $MyTest::UP ? -1 : 1 ) / ( 2 << Marpa::location() ) );
}
sub rank_zero { return \0 }
sub zero      { return '0' }
sub one       { return '1' }

sub start_rule_action {
    shift;
    return join q{}, @_;
}

## use critic

my $grammar = Marpa::Grammar->new(
    {   start => 'S',
        strip => 0,
        rules => [
            {   lhs    => 'S',
                rhs    => [qw/digit digit digit digit/],
                action => 'main::start_rule_action'
            },
            {   lhs            => 'digit',
                rhs            => ['zero'],
                ranking_action => 'main::rank_zero',
                action         => 'main::zero'
            },
            {   lhs            => 'digit',
                rhs            => ['one'],
                ranking_action => 'main::rank_one',
                action         => 'main::one'
            },
            {   lhs => 'one',
                rhs => ['t'],
            },
            {   lhs => 'zero',
                rhs => ['t'],
            },
        ],
        terminals => [qw(t)],
    }
);

$grammar->precompute();

my $recce = Marpa::Recognizer->new(
    { grammar => $grammar, ranking_method => 'constant' } );

my $input_length = 4;
$recce->tokens( [ ( ['t'] ) x $input_length ] );

my @counting_up =
    qw{ 0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111 };
my @counting_down = reverse @counting_up;

for my $up ( 1, 0 ) {
    local $MyTest::UP = $up;
    my $count = $up ? ( \@counting_up ) : ( \@counting_down );
    my $direction = $up ? 'up' : 'down';
    $recce->reset_evaluation();
    my $i = 0;
    while ( my $result = $recce->value() ) {
        my $got      = ${$result};
        my $expected = $count->[$i];
        say ${$result} or Carp::croak("Could not print to STDOUT: $ERRNO");
        Test::More::is( $got, $expected, "counting $direction $i" );
        $i++;
    } ## end while ( my $result = $recce->value() )
} ## end for my $up ( 1, 0 )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
