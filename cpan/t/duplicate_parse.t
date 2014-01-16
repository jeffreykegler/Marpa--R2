#!/usr/bin/perl
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

# Test of deletion of duplicate parses.

use 5.010;
use strict;
use warnings;

use Test::More tests => 5;

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
    <<'END_OF_STRING', 'duplicate parse Rules' );
0: S -> p p p n
1: p -> a
2: p -> /* empty !used */
3: n -> a
END_OF_STRING

Marpa::R2::Test::is( $grammar->show_AHFA,
    <<'END_OF_STRING', 'duplicate parse AHFA' );
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

use constant SPACE => 0x60;

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );
my $input_length = 3;
for my $input_ix ( 1 .. $input_length ) {
    $recce->read( 'a', chr( SPACE + $input_ix ) );
}

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
