#!perl
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

# Test of Leo logic for unit rule.

use 5.010;
use strict;
use warnings;

use List::Util;
use Test::More tests => 7;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub main::default_action {
    shift;
    return ( join q{}, grep {defined} @_ );
}

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'A',
        rules => [
            [ 'A', [qw/a B/] ],
            [ 'B', [qw/C/] ],
            [ 'C', [qw/c A/] ],
            [ 'C', [qw/c/] ],
        ],
        terminals      => [qw(a c)],
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

Marpa::R2::Test::is( $grammar->show_symbols(),
    <<'END_OF_STRING', 'Leo166 Symbols' );
0: a, terminal
1: c, terminal
2: A
3: B
4: C
END_OF_STRING

Marpa::R2::Test::is( $grammar->show_rules,
    <<'END_OF_STRING', 'Leo166 Rules' );
0: A -> a B
1: B -> C
2: C -> c A
3: C -> c
END_OF_STRING


Marpa::R2::Test::is( $grammar->show_ahms, <<'END_OF_STRING', 'Leo166 AHFA' );
* S0:
A['] -> . A
* S1: predict
A -> . a B
* S2:
A -> a . B
* S3: predict
B -> . C
C -> . c A
C -> . c
* S4:
A -> a B .
* S5:
B -> C .
* S6:
C -> c . A
* S7:
C -> c A .
* S8:
C -> c .
* S9:
A['] -> A .
END_OF_STRING

my $input = 'acacac';
my $length_of_input = length $input;

LEO_FLAG: for my $leo_flag ( 0, 1 ) {
    my $recce = Marpa::R2::Recognizer->new(
        { grammar => $grammar, leo => $leo_flag } );

    my $i                 = 0;
    my $latest_earley_set = $recce->latest_earley_set();
    my @sizes = ($recce->earley_set_size($latest_earley_set));
    TOKEN: for ( my $i = 0; $i < $length_of_input; $i++ ) {
        my $token_name = substr( $input, $i, 1 );

        # token name and value are the same
        $recce->read( $token_name, $token_name );
        $latest_earley_set = $recce->latest_earley_set();
        push @sizes, $recce->earley_set_size($latest_earley_set);

    } ## end TOKEN: for ( my $i = 0; $i < $length_of_input; $i++ )

    my $max_size = List::Util::max(@sizes);
    my $expected_size = $leo_flag ? 5 : ( $length_of_input / 2 ) * 3 + 3;
    Marpa::R2::Test::is( $max_size, $expected_size,
        "Leo flag $leo_flag, size was $max_size but $expected_size was expected" );

    my $value_ref = $recce->value();
    my $value = $value_ref ? ${$value_ref} : 'No parse';
    Marpa::R2::Test::is( $value, 'acacac', 'Leo unit rule parse' );

} ## end LEO_FLAG: for my $leo_flag ( 0, 1 )

# vim: expandtab shiftwidth=4:
