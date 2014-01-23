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
# Catch the case of a final non-nulling symbol at the end of a rule
# which has more than 2 proper nullables
# This is to test an untested branch of the CHAF logic.

use 5.010;
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
* S0:
S['] -> . S
* S1: predict
S -> . p p S[R0:2]
S -> . p p[] S[R0:2]
S -> p[] . p S[R0:2]
S -> p[] p[] . S[R0:2]
S[R0:2] -> . p n
S[R0:2] -> p[] . n
p -> . a
n -> . a
* S2:
S -> p . p S[R0:2]
* S3: predict
p -> . a
* S4:
S -> p p . S[R0:2]
* S5: predict
S[R0:2] -> . p n
S[R0:2] -> p[] . n
p -> . a
n -> . a
* S6:
S -> p p S[R0:2] .
* S7:
S -> p p[] . S[R0:2]
* S8:
S -> p p[] S[R0:2] .
* S9:
S -> p[] p . S[R0:2]
* S10:
S -> p[] p S[R0:2] .
* S11:
S -> p[] p[] S[R0:2] .
* S12:
S[R0:2] -> p . n
* S13: predict
n -> . a
* S14:
S[R0:2] -> p n .
* S15:
S[R0:2] -> p[] n .
* S16:
p -> a .
* S17:
n -> a .
* S18:
S['] -> S .
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
