#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
use strict;
use warnings;

use Test::More skip_all => 'Cycle logic is not yet settled';
# use Test::More tests => 9;
use English qw( -no_match_vars );
use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

## no critic (Subroutines::RequireArgUnpacking)

# Ranks are less than zero
# to make sure
# that the ranks are floating point --
# that integer rounding
# is not happening anywhere.

our $CYCLE_RANK = 1;

# If we are counting up, the lowest number
# has to have the highest numerical rank.
# sub rank_cycle { return \($main::CYCLE_RANK*(Marpa::location()+1)) }
sub rank_cycle {
    return \( $main::CYCLE_RANK * ( 9 - Marpa::location() ) );
}

sub rule_action  { return 'direct' }
sub cycle_action { return 'cycle' }

sub default_rule_action {
    shift;
    return join q{;}, @_;
}

## use critic

my $grammar = Marpa::Grammar->new(
    {   start                => 'S',
        strip                => 0,
        infinite_action      => 'quiet',
        cycle_ranking_action => 'main::rank_cycle',
        rules                => [
            {   lhs    => 'S',
                rhs    => [qw/item item/],
                action => 'main::default_rule_action'
            },
            {   lhs    => 'item',
                rhs    => ['direct'],
                action => 'main::rule_action',

                # ranking_action => 'main::rank_rule'
            },
            {   lhs    => 'item',
                rhs    => ['cycle'],
                action => 'main::cycle_action'
            },
            {   lhs => 'cycle',
                rhs => ['cycle2'],
            },
            {   lhs => 'cycle2',
                rhs => ['cycle'],
            },
            {   lhs => 'direct',
                rhs => ['t'],
            },
            {   lhs => 'cycle2',
                rhs => ['t'],
            },
        ],
        terminals => [qw(t)],
    }
);

$grammar->precompute();

my $recce = Marpa::Recognizer->new(
    { grammar => $grammar, ranking_method => 'constant' } );

my $input_length = 2;
$recce->tokens( [ ( ['t'] ) x $input_length ] );

my @expected1 = qw(
    direct;direct
    direct;cycle
    cycle;direct
    cycle;cycle
);
my @expected = ( @expected1, ( reverse @expected1 ) );

my $i = 0;
for my $cycle_rank ( -1, 1 ) {
    $main::CYCLE_RANK = $cycle_rank;
    $recce->reset_evaluation();
    while ( my $result = $recce->value() ) {
        Test::More::is( ${$result}, $expected[$i], "cycle_rank=$cycle_rank" );
        $i++;
    }
} ## end for my $cycle_rank ( -1, 1 )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
