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
# Catch the case of a final non-nulling symbol at the end of a rule
# which has more than 2 proper nullables
# This is to test an untested branch of the CHAF logic.

use 5.010001;
use strict;
use warnings;

use Test::More tests => 10;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{-} if $v_count <= 0;
    my @vals = map { $_ // q{-} } @_;
    return $vals[0] if $v_count == 1;
    return '(' . join( q{;}, @vals ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'S',

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

Marpa::R2::Test::is( $grammar->show_rules,
    <<'END_OF_STRING', 'final nonnulling Rules' );
0: S -> p p p n
1: p -> a
2: p -> /* empty !used */
3: n -> a
END_OF_STRING

Marpa::R2::Test::is( $grammar->show_ahms,
    <<'END_OF_STRING', 'final nonnulling AHFA' );
AHM 0: postdot = "p"
    S ::= . p p S[R0:2]
AHM 1: postdot = "p"
    S ::= p . p S[R0:2]
AHM 2: postdot = "S[R0:2]"
    S ::= p p . S[R0:2]
AHM 3: completion
    S ::= p p S[R0:2] .
AHM 4: postdot = "p"
    S ::= . p p[] S[R0:2]
AHM 5: postdot = "S[R0:2]"
    S ::= p p[] . S[R0:2]
AHM 6: completion
    S ::= p p[] S[R0:2] .
AHM 7: postdot = "p"
    S ::= p[] . p S[R0:2]
AHM 8: postdot = "S[R0:2]"
    S ::= p[] p . S[R0:2]
AHM 9: completion
    S ::= p[] p S[R0:2] .
AHM 10: postdot = "S[R0:2]"
    S ::= p[] p[] . S[R0:2]
AHM 11: completion
    S ::= p[] p[] S[R0:2] .
AHM 12: postdot = "p"
    S[R0:2] ::= . p n
AHM 13: postdot = "n"
    S[R0:2] ::= p . n
AHM 14: completion
    S[R0:2] ::= p n .
AHM 15: postdot = "n"
    S[R0:2] ::= p[] . n
AHM 16: completion
    S[R0:2] ::= p[] n .
AHM 17: postdot = "a"
    p ::= . a
AHM 18: completion
    p ::= a .
AHM 19: postdot = "a"
    n ::= . a
AHM 20: completion
    n ::= a .
AHM 21: postdot = "S"
    S['] ::= . S
AHM 22: completion
    S['] ::= S .
END_OF_STRING

my @expected = map {
    +{ map { ( $_ => 1 ) } @{$_} }
    }
    [q{}],
    [qw( (-;-;-;a) )],
    [qw( (a;-;-;a) (-;-;a;a) (-;a;-;a) )],
    [qw( (a;a;-;a) (-;a;a;a) (a;-;a;a))],
    [qw( (a;a;a;a) )];

for my $input_length ( 1 .. 4 ) {

    # Set max at 10 just in case there's an infinite loop.
    # This is for debugging, after all
    my $recce = Marpa::R2::Recognizer->new(
        { grammar => $grammar, max_parses => 10 } );
    for ( 1 .. $input_length ) {
        $recce->read( 'a', 'a' );
    }
    while ( my $value_ref = $recce->value() ) {
        my $value = $value_ref ? ${$value_ref} : 'No parse';
        my $expected = $expected[$input_length];
        if ( defined $expected->{$value} ) {
            delete $expected->{$value};
            Test::More::pass(qq{Expected value: "$value"});
        }
        else {
            Test::More::fail(qq{Unexpected value: "$value"});
        }
    } ## end while ( my $value_ref = $recce->value() )
} ## end for my $input_length ( 1 .. 4 )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
