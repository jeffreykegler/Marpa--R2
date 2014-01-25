#!perl
# Copyright 2014 Jeffrey Kegler
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

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use Test::More tests => 25;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . ( join q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'S',
        rules => [
            [ 'S', [qw/A A A A/] ],
            [ 'A', [qw/a/] ],
            [ 'A', [qw/E/] ],
            ['E'],
        ],
        default_action     => 'main::default_action',
    }
);

$grammar->set( { terminals => ['a'], } );

$grammar->precompute();

Marpa::R2::Test::is( $grammar->show_rules, <<'EOS', 'Aycock/Horspool Rules' );
0: S -> A A A A
1: A -> a
2: A -> E /* !used */
3: E -> /* empty !used */
EOS

Marpa::R2::Test::is( $grammar->show_symbols,
    <<'EOS', 'Aycock/Horspool Symbols' );
0: S
1: A
2: a, terminal
3: E, nulling
EOS

Marpa::R2::Test::is( $grammar->show_isys,
    <<'EOS', 'Aycock/Horspool ISYs' );
0: S
1: S[], nulling
2: A
3: A[], nulling
4: a
5: E[], nulling
6: S[R0:1]
7: S[R0:2]
8: S[']
EOS

Marpa::R2::Test::is( $grammar->show_irls,
    <<'EOS', 'Aycock/Horspool IRLs' );
0: S -> A S[R0:1]
1: S -> A A[] A[] A[]
2: S -> A[] S[R0:1]
3: S[R0:1] -> A S[R0:2]
4: S[R0:1] -> A A[] A[]
5: S[R0:1] -> A[] S[R0:2]
6: S[R0:2] -> A A
7: S[R0:2] -> A A[]
8: S[R0:2] -> A[] A
9: A -> a
10: S['] -> S
EOS

Marpa::R2::Test::is(
    $grammar->show_nulling_symbols,
    q{E},
    'Aycock/Horspool Nulling Symbols'
);
Marpa::R2::Test::is(
    $grammar->show_productive_symbols,
    q{A E S a},
    'Aycock/Horspool Productive Symbols'
);
Marpa::R2::Test::is(
    $grammar->show_accessible_symbols,
    q{A E S a},
    'Aycock/Horspool Accessible Symbols'
);

Marpa::R2::Test::is( $grammar->show_ahms(),
    <<'EOS', 'Aycock/Horspool AHMs' );
AHM 0: postdot = "A"
    S ::= . A S[R0:1]
AHM 1: postdot = "S[R0:1]"
    S ::= A . S[R0:1]
AHM 2: completion
    S ::= A S[R0:1] .
AHM 3: postdot = "A"
    S ::= . A A[] A[] A[]
AHM 4: completion
    S ::= A A[] A[] A[] .
AHM 5: postdot = "S[R0:1]"
    S ::= A[] . S[R0:1]
AHM 6: completion
    S ::= A[] S[R0:1] .
AHM 7: postdot = "A"
    S[R0:1] ::= . A S[R0:2]
AHM 8: postdot = "S[R0:2]"
    S[R0:1] ::= A . S[R0:2]
AHM 9: completion
    S[R0:1] ::= A S[R0:2] .
AHM 10: postdot = "A"
    S[R0:1] ::= . A A[] A[]
AHM 11: completion
    S[R0:1] ::= A A[] A[] .
AHM 12: postdot = "S[R0:2]"
    S[R0:1] ::= A[] . S[R0:2]
AHM 13: completion
    S[R0:1] ::= A[] S[R0:2] .
AHM 14: postdot = "A"
    S[R0:2] ::= . A A
AHM 15: postdot = "A"
    S[R0:2] ::= A . A
AHM 16: completion
    S[R0:2] ::= A A .
AHM 17: postdot = "A"
    S[R0:2] ::= . A A[]
AHM 18: completion
    S[R0:2] ::= A A[] .
AHM 19: postdot = "A"
    S[R0:2] ::= A[] . A
AHM 20: completion
    S[R0:2] ::= A[] A .
AHM 21: postdot = "a"
    A ::= . a
AHM 22: completion
    A ::= a .
AHM 23: postdot = "S"
    S['] ::= . S
AHM 24: completion
    S['] ::= S .
EOS

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

my $expected_earley_sets = <<'END_OF_SETS';
Last Completed: 4; Furthest: 4
Earley Set 0
ahm23: R10:0@0-0
  R10:0: S['] ::= . S
ahm0: R0:0@0-0
  R0:0: S ::= . A S[R0:1]
ahm3: R1:0@0-0
  R1:0: S ::= . A A[] A[] A[]
ahm5: R2:1@0-0
  R2:1: S ::= A[] . S[R0:1]
ahm7: R3:0@0-0
  R3:0: S[R0:1] ::= . A S[R0:2]
ahm10: R4:0@0-0
  R4:0: S[R0:1] ::= . A A[] A[]
ahm12: R5:1@0-0
  R5:1: S[R0:1] ::= A[] . S[R0:2]
ahm14: R6:0@0-0
  R6:0: S[R0:2] ::= . A A
ahm17: R7:0@0-0
  R7:0: S[R0:2] ::= . A A[]
ahm19: R8:1@0-0
  R8:1: S[R0:2] ::= A[] . A
ahm21: R9:0@0-0
  R9:0: A ::= . a
Earley Set 1
ahm22: R9$@0-1
  R9$: A ::= a .
  [c=R9:0@0-0; s=a; t=\'a']
ahm20: R8$@0-1
  R8$: S[R0:2] ::= A[] A .
  [p=R8:1@0-0; c=R9$@0-1]
ahm18: R7$@0-1
  R7$: S[R0:2] ::= A A[] .
  [p=R7:0@0-0; c=R9$@0-1]
ahm15: R6:1@0-1
  R6:1: S[R0:2] ::= A . A
  [p=R6:0@0-0; c=R9$@0-1]
ahm11: R4$@0-1
  R4$: S[R0:1] ::= A A[] A[] .
  [p=R4:0@0-0; c=R9$@0-1]
ahm8: R3:1@0-1
  R3:1: S[R0:1] ::= A . S[R0:2]
  [p=R3:0@0-0; c=R9$@0-1]
ahm4: R1$@0-1
  R1$: S ::= A A[] A[] A[] .
  [p=R1:0@0-0; c=R9$@0-1]
ahm1: R0:1@0-1
  R0:1: S ::= A . S[R0:1]
  [p=R0:0@0-0; c=R9$@0-1]
ahm24: R10$@0-1
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R1$@0-1] [p=R10:0@0-0; c=R2$@0-1]
ahm6: R2$@0-1
  R2$: S ::= A[] S[R0:1] .
  [p=R2:1@0-0; c=R4$@0-1] [p=R2:1@0-0; c=R5$@0-1]
ahm13: R5$@0-1
  R5$: S[R0:1] ::= A[] S[R0:2] .
  [p=R5:1@0-0; c=R7$@0-1] [p=R5:1@0-0; c=R8$@0-1]
ahm21: R9:0@1-1
  R9:0: A ::= . a
ahm14: R6:0@1-1
  R6:0: S[R0:2] ::= . A A
ahm17: R7:0@1-1
  R7:0: S[R0:2] ::= . A A[]
ahm19: R8:1@1-1
  R8:1: S[R0:2] ::= A[] . A
ahm7: R3:0@1-1
  R3:0: S[R0:1] ::= . A S[R0:2]
ahm10: R4:0@1-1
  R4:0: S[R0:1] ::= . A A[] A[]
ahm12: R5:1@1-1
  R5:1: S[R0:1] ::= A[] . S[R0:2]
Earley Set 2
ahm22: R9$@1-2
  R9$: A ::= a .
  [c=R9:0@1-1; s=a; t=\'a']
ahm11: R4$@1-2
  R4$: S[R0:1] ::= A A[] A[] .
  [p=R4:0@1-1; c=R9$@1-2]
ahm8: R3:1@1-2
  R3:1: S[R0:1] ::= A . S[R0:2]
  [p=R3:0@1-1; c=R9$@1-2]
ahm20: R8$@1-2
  R8$: S[R0:2] ::= A[] A .
  [p=R8:1@1-1; c=R9$@1-2]
ahm18: R7$@1-2
  R7$: S[R0:2] ::= A A[] .
  [p=R7:0@1-1; c=R9$@1-2]
ahm15: R6:1@1-2
  R6:1: S[R0:2] ::= A . A
  [p=R6:0@1-1; c=R9$@1-2]
ahm16: R6$@0-2
  R6$: S[R0:2] ::= A A .
  [p=R6:1@0-1; c=R9$@1-2]
ahm13: R5$@0-2
  R5$: S[R0:1] ::= A[] S[R0:2] .
  [p=R5:1@0-0; c=R6$@0-2]
ahm6: R2$@0-2
  R2$: S ::= A[] S[R0:1] .
  [p=R2:1@0-0; c=R3$@0-2] [p=R2:1@0-0; c=R5$@0-2]
ahm24: R10$@0-2
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-2] [p=R10:0@0-0; c=R2$@0-2]
ahm13: R5$@1-2
  R5$: S[R0:1] ::= A[] S[R0:2] .
  [p=R5:1@1-1; c=R7$@1-2] [p=R5:1@1-1; c=R8$@1-2]
ahm9: R3$@0-2
  R3$: S[R0:1] ::= A S[R0:2] .
  [p=R3:1@0-1; c=R7$@1-2] [p=R3:1@0-1; c=R8$@1-2]
ahm2: R0$@0-2
  R0$: S ::= A S[R0:1] .
  [p=R0:1@0-1; c=R4$@1-2] [p=R0:1@0-1; c=R5$@1-2]
ahm14: R6:0@2-2
  R6:0: S[R0:2] ::= . A A
ahm17: R7:0@2-2
  R7:0: S[R0:2] ::= . A A[]
ahm19: R8:1@2-2
  R8:1: S[R0:2] ::= A[] . A
ahm21: R9:0@2-2
  R9:0: A ::= . a
Earley Set 3
ahm22: R9$@2-3
  R9$: A ::= a .
  [c=R9:0@2-2; s=a; t=\'a']
ahm20: R8$@2-3
  R8$: S[R0:2] ::= A[] A .
  [p=R8:1@2-2; c=R9$@2-3]
ahm18: R7$@2-3
  R7$: S[R0:2] ::= A A[] .
  [p=R7:0@2-2; c=R9$@2-3]
ahm15: R6:1@2-3
  R6:1: S[R0:2] ::= A . A
  [p=R6:0@2-2; c=R9$@2-3]
ahm16: R6$@1-3
  R6$: S[R0:2] ::= A A .
  [p=R6:1@1-2; c=R9$@2-3]
ahm13: R5$@1-3
  R5$: S[R0:1] ::= A[] S[R0:2] .
  [p=R5:1@1-1; c=R6$@1-3]
ahm9: R3$@0-3
  R3$: S[R0:1] ::= A S[R0:2] .
  [p=R3:1@0-1; c=R6$@1-3]
ahm6: R2$@0-3
  R2$: S ::= A[] S[R0:1] .
  [p=R2:1@0-0; c=R3$@0-3]
ahm24: R10$@0-3
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-3] [p=R10:0@0-0; c=R2$@0-3]
ahm2: R0$@0-3
  R0$: S ::= A S[R0:1] .
  [p=R0:1@0-1; c=R3$@1-3] [p=R0:1@0-1; c=R5$@1-3]
ahm9: R3$@1-3
  R3$: S[R0:1] ::= A S[R0:2] .
  [p=R3:1@1-2; c=R7$@2-3] [p=R3:1@1-2; c=R8$@2-3]
ahm21: R9:0@3-3
  R9:0: A ::= . a
Earley Set 4
ahm22: R9$@3-4
  R9$: A ::= a .
  [c=R9:0@3-3; s=a; t=\'a']
ahm16: R6$@2-4
  R6$: S[R0:2] ::= A A .
  [p=R6:1@2-3; c=R9$@3-4]
ahm9: R3$@1-4
  R3$: S[R0:1] ::= A S[R0:2] .
  [p=R3:1@1-2; c=R6$@2-4]
ahm2: R0$@0-4
  R0$: S ::= A S[R0:1] .
  [p=R0:1@0-1; c=R3$@1-4]
ahm24: R10$@0-4
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-4]
END_OF_SETS

my $input_length = 4;
for (my $i = 0; $i < $input_length; $i++) {
    $recce->read( 'a', 'a' );
}

Marpa::R2::Test::is(
    $recce->show_earley_sets(2),
    $expected_earley_sets,
    'Aycock/Horspool Earley sets'
);

my @expected = map {
    +{ map { ( $_ => 1 ) } @{$_} }
    }
    [q{}],
    [qw( (a;;;) (;a;;) (;;a;) (;;;a) )],
    [qw( (a;a;;) (a;;a;) (a;;;a) (;a;a;) (;a;;a) (;;a;a) )],
    [qw( (a;a;a;) (a;a;;a) (a;;a;a) (;a;a;a) )],
    ['(a;a;a;a)'];

$recce->set( { max_parses => 20 } );

for my $i ( 0 .. $input_length ) {

    $recce->reset_evaluation();
    $recce->set( { end => $i } );
    my $expected = $expected[$i];

    while ( my $value_ref = $recce->value() ) {

        my $value = $value_ref ? ${$value_ref} : 'No parse';
        if ( defined $expected->{$value} ) {
            delete $expected->{$value};
            Test::More::pass(qq{Expected result for length=$i, "$value"});
        }
        else {
            Test::More::fail(qq{Unexpected result for length=$i, "$value"});
        }
    } ## end while ( my $value_ref = $recce->value() )

    for my $value ( keys %{$expected} ) {
        Test::More::fail(qq{Missing result for length=$i, "$value"});
    }
} ## end for my $i ( 0 .. $input_length )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
