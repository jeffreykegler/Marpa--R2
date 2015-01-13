#!perl
# Copyright 2015 Jeffrey Kegler
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
# Two rules which start with nullables, and cycle.

use 5.010;
use strict;
use warnings;

use Test::More tests => 9;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{-} if $v_count <= 0;
    my @vals = map { $_ // q{-} } @_;
    return $_[0] if scalar @vals == 1;
    return '(' . join( q{;}, @vals ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'S',

        rules => [
            [ 'S',  [qw/p p p n/], ],
            [ 'p',  ['t'], ],
            [ 'p',  [], ],
            [ 'n',  ['t'], ],
            [ 'n',  ['r2'], ],
            [ 'r2', [qw/a b c d e x/], ],
            [ 'a',  [] ],
            [ 'b',  [] ],
            [ 'c',  [] ],
            [ 'd',  [] ],
            [ 'e',  [] ],
            [ 'a',  ['t'] ],
            [ 'b',  ['t'] ],
            [ 'c',  ['t'] ],
            [ 'd',  ['t'] ],
            [ 'e',  ['t'] ],
            [ 'x',  ['t'], ],
        ],
        terminals      => ['t'],
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

# The count of results without an r2 production, the count
# is C(n-1,3), when n>=4, 0 otherwise.
# The count of results with an r2 productions is C(n-1,8).
# Total results is the sum of the results with an
# r2 production and those without.
my @expected_count;
$expected_count[1] = 2;     # 1 w/o r2; 1 with an r2
$expected_count[2] = 11;    # 3 w/o r2; 8 with an r2
$expected_count[3] = 31;    # 3 w/o r2; 28 with an r2
$expected_count[4] = 57;    # 1 w/o r2; 56 with an r2
$expected_count[5] = 70;    # 0 w/o r2; 70 with an r2
$expected_count[6] = 56;    # 0 w/o r2; 70 with an r2
$expected_count[7] = 28;    # 0 w/o r2; 28 with an r2
$expected_count[8] = 8;     # 0 w/o r2; 8 with an r2
$expected_count[9] = 1;     # 0 w/o r2; 1 with an r2

for my $input_length ( 1 .. 9 ) {
    my $recce = Marpa::R2::Recognizer->new(
        { grammar => $grammar, max_parses => 100 } );
    for ( 1 .. $input_length ) { $recce->read( 't', 't' ); }
    my $expected = 1;
    my $parse_count = 0;
    while ( $expected and my $value_ref = $recce->value() ) {
        $expected = 0;
        $parse_count++;
        my $value = ${$value_ref};
        if ($value =~ m{
            \A
            [(]
                ((t|[-])[;]){3}
                (t|[-])
            [)]
            \z
            }xms
            )
        {
            $expected = 1;
        } ## end if ( $value =~ m{ ) (})
        elsif (
            $value =~ m{
            \A
            [(]
            ((t|[-])[;]){3}
                [(]
                    ((t|[-])[;]){5}
                    (t|[-])
                [)]
            [)]
            \z
            }xms
            )
        {
            $expected = 1;
        } ## end elsif ( $value =~ m{ ) (})
        $expected &&= $input_length == ( $value =~ tr/t/t/ );
        if ( not $expected ) {
            Test::More::fail(
                qq{Unexpected value, length=$input_length, "$value"});
        }
    } ## end while ( $expected and my $value_ref = $recce->value() )
    if ($expected) {
        my $expected_count = $expected_count[$input_length];
        if ( $parse_count == $expected_count ) {
            Test::More::pass(
                qq{Good parse count $parse_count; input length=$input_length}
            );
        }
        else {
            Test::More::fail(
                qq{Bad parse count $parse_count, expected $expected_count; input length=$input_length}
            );
        }
    } ## end if ($expected)
} ## end for my $input_length ( 1 .. 9 )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
