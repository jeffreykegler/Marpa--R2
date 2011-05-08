#!/usr/bin/perl
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

# Test of deletion of duplicate parses.

use 5.010;
use strict;
use warnings;

use Test::More tests => 6;

use Marpa::XS::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{} if $v_count <= 0;
    my @vals = map { $_ // q{-} } @_;
    return $vals[0] if $v_count == 1;
    return '(' . join( q{;}, @vals ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::XS::Grammar->new(
    {   start => 'S',
        strip => 0,

        rules => [
            [ 'S', [qw/p p p n/], ],
            [ 'p', ['a'], ],
            [ 'p', [], ],
            [ 'n', ['a'], ],
        ],
        terminals      => ['a'],
        default_action => 'main::default_action',

    }
);

$grammar->precompute();

Marpa::XS::Test::is( $grammar->show_rules,
    <<'END_OF_STRING', 'duplicate parse Rules' );
0: S -> p p p n /* !used */
1: p -> a
2: p -> /* empty !used */
3: n -> a
4: S -> p p S[R0:2] /* vrhs real=2 */
5: S -> p p[] S[R0:2] /* vrhs real=2 */
6: S -> p[] p S[R0:2] /* vrhs real=2 */
7: S -> p[] p[] S[R0:2] /* vrhs real=2 */
8: S[R0:2] -> p n /* vlhs real=2 */
9: S[R0:2] -> p[] n /* vlhs real=2 */
10: S['] -> S /* vlhs real=1 */
END_OF_STRING

Marpa::XS::Test::is( $grammar->show_AHFA,
    <<'END_OF_STRING', 'duplicate parse AHFA' );
* S0:
S['] -> . S
 <S> => S2; leo(S['])
* S1: predict
p -> . a
n -> . a
S -> . p p S[R0:2]
S -> . p p[] S[R0:2]
S -> p[] . p S[R0:2]
S -> p[] p[] . S[R0:2]
S[R0:2] -> . p n
S[R0:2] -> p[] . n
 <S[R0:2]> => S7; leo(S)
 <a> => S3
 <n> => S6; leo(S[R0:2])
 <p> => S4; S5
* S2: leo-c
S['] -> S .
* S3:
p -> a .
n -> a .
* S4:
S -> p . p S[R0:2]
S -> p p[] . S[R0:2]
S -> p[] p . S[R0:2]
S[R0:2] -> p . n
 <S[R0:2]> => S10
 <n> => S9; leo(S[R0:2])
 <p> => S5; S8
* S5: predict
p -> . a
n -> . a
S[R0:2] -> . p n
S[R0:2] -> p[] . n
 <a> => S3
 <n> => S6; leo(S[R0:2])
 <p> => S11; S12
* S6: leo-c
S[R0:2] -> p[] n .
* S7: leo-c
S -> p[] p[] S[R0:2] .
* S8:
S -> p p . S[R0:2]
 <S[R0:2]> => S13; leo(S)
* S9: leo-c
S[R0:2] -> p n .
* S10:
S -> p p[] S[R0:2] .
S -> p[] p S[R0:2] .
* S11:
S[R0:2] -> p . n
 <n> => S9; leo(S[R0:2])
* S12: predict
n -> . a
 <a> => S14
* S13: leo-c
S -> p p S[R0:2] .
* S14:
n -> a .
END_OF_STRING

use constant SPACE => 0x60;

my $input_length = 3;
my $recce = Marpa::XS::Recognizer->new( { grammar => $grammar } );
$recce->tokens(
    [ map { [ 'a', chr( SPACE + $_ ), 1 ] } ( 1 .. $input_length ) ] );

# Set max at 10 just in case there's an infinite loop.
# This is for debugging, after all
$recce->set( { max_parses => 10 } );

my %expected = map { ( $_ => 1 ) } qw( (-;a;b;c) (a;-;b;c) (a;b;-;c) );

while ( my $value_ref = $recce->value() ) {
    my $value = $value_ref ? ${$value_ref} : 'No parse';
    if ( defined $expected{$value} ) {
        delete $expected{$value};
        Test::More::pass("Expected value: $value");
    }
    else {
        Test::More::fail("Unexpected value: $value");
    }
} ## end while ( my $value_ref = $recce->value() )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
