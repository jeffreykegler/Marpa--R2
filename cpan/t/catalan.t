#!perl
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

use 5.010001;

# Count the ways of parenthesizing N symbols in pairs
# This generates the Catalan numbers

use strict;
use warnings;

use Test::More tests => 7;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $g = Marpa::R2::Grammar->new(
    {   start => 'pair',
        rules => [
            [ pair => [qw(a a)],       '::whatever' ],
            [ pair => [qw(pair a)],    '::whatever' ],
            [ pair => [qw(a pair)],    '::whatever' ],
            [ pair => [qw(pair pair)], '::whatever' ],
        ],
        terminals => ['a'],

    }
);
$g->precompute();

sub do_pairings {
    my $n           = shift;
    my $parse_count = 0;

    my $recce = Marpa::R2::Recognizer->new( { grammar => $g } );

    # An arbitrary maximum is put on the number of parses -- this is for
    # debugging, and infinite loops happen.
    $recce->set( { max_parses => 999, } );

    for my $token_ix ( 0 .. $n - 1 ) {
        $recce->read('a');
    }

    while ( my $value_ref = $recce->value() ) {
        $parse_count++;
    }
    return $parse_count;
} ## end sub do_pairings

my @catalan_numbers = ( 0, 1, 1, 2, 5, 14, 42, 132, 429 );

for my $a ( ( 2 .. 8 ) ) {

    my $actual_parse_count = do_pairings($a);
    Marpa::R2::Test::is( $actual_parse_count, $catalan_numbers[$a],
        "Catalan number $a matches parse count ($actual_parse_count)" );

} ## end for my $a ( ( 2 .. 8 ) )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
