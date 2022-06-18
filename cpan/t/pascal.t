#!perl
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

use 5.010001;

# variations on
# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,

use strict;
use warnings;

use Test::More tests => 7;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

sub ah_extended {
    my $n = shift;

    my $g = Marpa::R2::Grammar->new(
        {   start => 'S',

            rules => [
                [ 'S', [ ('A') x $n ] ],
                [ 'A', [qw/a/] ],
                [ 'A', [qw/E/] ],
                ['E'],
            ],
            terminals => ['a'],

            # no warnings for $n equals zero
            warnings => ( $n ? 1 : 0 ),
        }
    );
    $g->precompute();

    my $recce = Marpa::R2::Recognizer->new( { grammar => $g } );

    for my $token_ix ( 1 .. $n ) {
        $recce->read( 'a' );
    }

    my @parse_counts;
    for my $loc ( 0 .. $n ) {
        my $parse_number = 0;

        # An arbitrary maximum is put on the number of parses -- this is for
        # debugging, and infinite loops happen.

# Marpa::R2::Display
# name: reset_evaluation Synopsis

        $recce->reset_evaluation();
        $recce->set( { end => $loc, max_parses => 999, } );

# Marpa::R2::Display::End

        while ( $recce->value() ) { $parse_counts[$loc]++ }
    } ## end for my $loc ( 0 .. $n )
    return join q{ }, @parse_counts;
} ## end sub ah_extended

my @answers = (
    '1',
    '1 1',
    '1 2 1',
    '1 3 3 1',
    '1 4 6 4 1',
    '1 5 10 10 5 1',
    '1 6 15 20 15 6 1',
    '1 7 21 35 35 21 7 1',
    '1 8 28 56 70 56 28 8 1',
    '1 9 36 84 126 126 84 36 9 1',
    '1 10 45 120 210 252 210 120 45 10 1',
);

## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
for my $a ( ( 0 .. 5 ), 10 ) {
## use critic

    Marpa::R2::Test::is( ah_extended($a), $answers[$a],
        "Row $a of Pascal's triangle matches parse counts" );

} ## end for my $a ( ( 0 .. 5 ), 10 )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
