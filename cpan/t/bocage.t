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

# This test dumps the contents of the bocage and its iterator.
# The example grammar is Aycock/Horspool's
# "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use Test::More tests => 19;
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

Marpa::R2::Test::is( $grammar->show_AHFA_items(),
    <<'EOS', 'Aycock/Horspool AHFA Items' );
AHFA item 0: sort = 1; postdot = "A"
    S -> . A S[R0:1]
AHFA item 1: sort = 10; postdot = "S[R0:1]"
    S -> A . S[R0:1]
AHFA item 2: sort = 14; completion
    S -> A S[R0:1] .
AHFA item 3: sort = 2; postdot = "A"
    S -> . A A[] A[] A[]
AHFA item 4: sort = 15; completion
    S -> A A[] A[] A[] .
AHFA item 5: sort = 11; postdot = "S[R0:1]"
    S -> A[] . S[R0:1]
AHFA item 6: sort = 16; completion
    S -> A[] S[R0:1] .
AHFA item 7: sort = 3; postdot = "A"
    S[R0:1] -> . A S[R0:2]
AHFA item 8: sort = 12; postdot = "S[R0:2]"
    S[R0:1] -> A . S[R0:2]
AHFA item 9: sort = 17; completion
    S[R0:1] -> A S[R0:2] .
AHFA item 10: sort = 4; postdot = "A"
    S[R0:1] -> . A A[] A[]
AHFA item 11: sort = 18; completion
    S[R0:1] -> A A[] A[] .
AHFA item 12: sort = 13; postdot = "S[R0:2]"
    S[R0:1] -> A[] . S[R0:2]
AHFA item 13: sort = 19; completion
    S[R0:1] -> A[] S[R0:2] .
AHFA item 14: sort = 5; postdot = "A"
    S[R0:2] -> . A A
AHFA item 15: sort = 6; postdot = "A"
    S[R0:2] -> A . A
AHFA item 16: sort = 20; completion
    S[R0:2] -> A A .
AHFA item 17: sort = 7; postdot = "A"
    S[R0:2] -> . A A[]
AHFA item 18: sort = 21; completion
    S[R0:2] -> A A[] .
AHFA item 19: sort = 8; postdot = "A"
    S[R0:2] -> A[] . A
AHFA item 20: sort = 22; completion
    S[R0:2] -> A[] A .
AHFA item 21: sort = 9; postdot = "a"
    A -> . a
AHFA item 22: sort = 23; completion
    A -> a .
AHFA item 23: sort = 0; postdot = "S"
    S['] -> . S
AHFA item 24: sort = 24; completion
    S['] -> S .
EOS

Marpa::R2::Test::is( $grammar->show_AHFA, <<'EOS', 'Aycock/Horspool AHFA' );
* S0:
S['] -> . S
 <S> => S2
* S1: predict
S -> . A S[R0:1]
S -> . A A[] A[] A[]
S -> A[] . S[R0:1]
S[R0:1] -> . A S[R0:2]
S[R0:1] -> . A A[] A[]
S[R0:1] -> A[] . S[R0:2]
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
A -> . a
 <A> => S3; S4
 <S[R0:1]> => S6
 <S[R0:2]> => S7
 <a> => S5
* S2:
S['] -> S .
* S3:
S -> A . S[R0:1]
S -> A A[] A[] A[] .
S[R0:1] -> A . S[R0:2]
S[R0:1] -> A A[] A[] .
S[R0:2] -> A . A
S[R0:2] -> A A[] .
S[R0:2] -> A[] A .
 <A> => S8
 <S[R0:1]> => S9
 <S[R0:2]> => S10
* S4: predict
S[R0:1] -> . A S[R0:2]
S[R0:1] -> . A A[] A[]
S[R0:1] -> A[] . S[R0:2]
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
A -> . a
 <A> => S11; S12
 <S[R0:2]> => S7
 <a> => S5
* S5:
A -> a .
* S6:
S -> A[] S[R0:1] .
* S7:
S[R0:1] -> A[] S[R0:2] .
* S8:
S[R0:2] -> A A .
* S9:
S -> A S[R0:1] .
* S10:
S[R0:1] -> A S[R0:2] .
* S11:
S[R0:1] -> A . S[R0:2]
S[R0:1] -> A A[] A[] .
S[R0:2] -> A . A
S[R0:2] -> A A[] .
S[R0:2] -> A[] A .
 <A> => S8
 <S[R0:2]> => S10
* S12: predict
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
A -> . a
 <A> => S13; S14
 <a> => S5
* S13:
S[R0:2] -> A . A
S[R0:2] -> A A[] .
S[R0:2] -> A[] A .
 <A> => S8
* S14: predict
A -> . a
 <a> => S5
EOS

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

my @set =
    ( <<'END_OF_SET0', <<'END_OF_SET1', <<'END_OF_SET2', <<'END_OF_SET3', );
Earley Set 0
S0@0-0
S1@0-0
END_OF_SET0
Earley Set 1
S2@0-1 [p=S0@0-0; c=S3@0-1] [p=S0@0-0; c=S6@0-1]
S3@0-1 [p=S1@0-0; c=S5@0-1]
S5@0-1 [p=S1@0-0; s=a; t=\'a']
S6@0-1 [p=S1@0-0; c=S3@0-1] [p=S1@0-0; c=S7@0-1]
S7@0-1 [p=S1@0-0; c=S3@0-1]
S4@1-1
END_OF_SET1
Earley Set 2
S2@0-2 [p=S0@0-0; c=S6@0-2] [p=S0@0-0; c=S9@0-2]
S6@0-2 [p=S1@0-0; c=S7@0-2] [p=S1@0-0; c=S10@0-2]
S7@0-2 [p=S1@0-0; c=S8@0-2]
S8@0-2 [p=S3@0-1; c=S5@1-2]
S9@0-2 [p=S3@0-1; c=S7@1-2] [p=S3@0-1; c=S11@1-2]
S10@0-2 [p=S3@0-1; c=S11@1-2]
S5@1-2 [p=S4@1-1; s=a; t=\'a']
S7@1-2 [p=S4@1-1; c=S11@1-2]
S11@1-2 [p=S4@1-1; c=S5@1-2]
S12@2-2
END_OF_SET2
Earley Set 3
S2@0-3 [p=S0@0-0; c=S6@0-3] [p=S0@0-0; c=S9@0-3]
S6@0-3 [p=S1@0-0; c=S10@0-3]
S9@0-3 [p=S3@0-1; c=S7@1-3] [p=S3@0-1; c=S10@1-3]
S10@0-3 [p=S3@0-1; c=S8@1-3]
S7@1-3 [p=S4@1-1; c=S8@1-3]
S8@1-3 [p=S11@1-2; c=S5@2-3]
S10@1-3 [p=S11@1-2; c=S13@2-3]
S5@2-3 [p=S12@2-2; s=a; t=\'a']
S13@2-3 [p=S12@2-2; c=S5@2-3]
S14@3-3
END_OF_SET3

my %tree_expected = ();

$tree_expected{'(;a;a;a)'} = <<'END_OF_TEXT';
0: o17[-] R10:1@0-3 p=ok c=ok
 o17[0]* ::= a17 R10:1@0-3C2@0
 o17[1] ::= a18 R10:1@0-3C0@0
1: o16[c0] R2:2@0-3 p=ok c=ok
 o16[0]* ::= a16 R2:2@0-3C3@0
2: o15[c1] R3:2@0-3 p=ok c=ok
 o15[0]* ::= a15 R3:2@0-3C6@1
3: o13[c2] R6:2@1-3 p=ok c=ok
 o13[0]* ::= a13 R6:2@1-3C9@2
4: o9[c3] R9:1@2-3 p=ok c=ok
 o9[0]* ::= a9 R9:1@2-3S4@2
5: o7[p3] R6:1@1-2 p=ok c=ok
 o7[0]* ::= a7 R6:1@1-2C9@1
6: o5[c5] R9:1@1-2 p=ok c=ok
 o5[0]* ::= a5 R9:1@1-2S4@1
7: o3[p2] R3:1@0-1 p=ok c=ok
 o3[0]* ::= a3 R3:1@0-1C9@0
8: o1[c7] R9:1@0-1 p=ok c=ok
 o1[0]* ::= a1 R9:1@0-1S4@0
9: o0[p1] R2:1@0-0 p=ok c=ok
 o0[0]* ::= a0 R2:1@0-0S3@0
END_OF_TEXT

$tree_expected{'(a;;a;a)'} = <<'END_OF_TEXT';
0: o17[-] R10:1@0-3 p=ok c=ok
 o17[0] ::= a17 R10:1@0-3C2@0
 o17[1]* ::= a18 R10:1@0-3C0@0
1: o18[c0] R0:2@0-3 p=ok c=ok
 o18[0]* ::= a19 R0:2@0-3C5@1
 o18[1] ::= a20 R0:2@0-3C3@1
2: o14[c1] R5:2@1-3 p=ok c=ok
 o14[0]* ::= a14 R5:2@1-3C6@1
3: o13[c2] R6:2@1-3 p=ok c=ok
 o13[0]* ::= a13 R6:2@1-3C9@2
4: o9[c3] R9:1@2-3 p=ok c=ok
 o9[0]* ::= a9 R9:1@2-3S4@2
5: o7[p3] R6:1@1-2 p=ok c=ok
 o7[0]* ::= a7 R6:1@1-2C9@1
6: o5[c5] R9:1@1-2 p=ok c=ok
 o5[0]* ::= a5 R9:1@1-2S4@1
7: o4[p2] R5:1@1-1 p=ok c=ok
 o4[0]* ::= a4 R5:1@1-1S3@1
8: o2[p1] R0:1@0-1 p=ok c=ok
 o2[0]* ::= a2 R0:1@0-1C9@0
9: o1[c8] R9:1@0-1 p=ok c=ok
 o1[0]* ::= a1 R9:1@0-1S4@0
END_OF_TEXT

$tree_expected{'(a;a;;a)'} = <<'END_OF_TEXT';
0: o17[-] R10:1@0-3 p=ok c=ok
 o17[0] ::= a17 R10:1@0-3C2@0
 o17[1]* ::= a18 R10:1@0-3C0@0
1: o18[c0] R0:2@0-3 p=ok c=ok
 o18[0] ::= a19 R0:2@0-3C5@1
 o18[1]* ::= a20 R0:2@0-3C3@1
2: o19[c1] R3:2@1-3 p=ok c=ok
 o19[0]* ::= a21 R3:2@1-3C8@2
 o19[1] ::= a22 R3:2@1-3C7@2
3: o12[c2] R8:2@2-3 p=ok c=ok
 o12[0]* ::= a12 R8:2@2-3C9@2
4: o9[c3] R9:1@2-3 p=ok c=ok
 o9[0]* ::= a9 R9:1@2-3S4@2
5: o8[p3] R8:1@2-2 p=ok c=ok
 o8[0]* ::= a8 R8:1@2-2S3@2
6: o6[p2] R3:1@1-2 p=ok c=ok
 o6[0]* ::= a6 R3:1@1-2C9@1
7: o5[c6] R9:1@1-2 p=ok c=ok
 o5[0]* ::= a5 R9:1@1-2S4@1
8: o2[p1] R0:1@0-1 p=ok c=ok
 o2[0]* ::= a2 R0:1@0-1C9@0
9: o1[c8] R9:1@0-1 p=ok c=ok
 o1[0]* ::= a1 R9:1@0-1S4@0
END_OF_TEXT

$tree_expected{'(a;a;a;)'} = <<'END_OF_TEXT';
0: o17[-] R10:1@0-3 p=ok c=ok
 o17[0] ::= a17 R10:1@0-3C2@0
 o17[1]* ::= a18 R10:1@0-3C0@0
1: o18[c0] R0:2@0-3 p=ok c=ok
 o18[0] ::= a19 R0:2@0-3C5@1
 o18[1]* ::= a20 R0:2@0-3C3@1
2: o19[c1] R3:2@1-3 p=ok c=ok
 o19[0] ::= a21 R3:2@1-3C8@2
 o19[1]* ::= a22 R3:2@1-3C7@2
3: o11[c2] R7:2@2-3 p=ok c=ok
 o11[0]* ::= a11 R7:2@2-3S3@3
4: o10[p3] R7:1@2-3 p=ok c=ok
 o10[0]* ::= a10 R7:1@2-3C9@2
5: o9[c4] R9:1@2-3 p=ok c=ok
 o9[0]* ::= a9 R9:1@2-3S4@2
6: o6[p2] R3:1@1-2 p=ok c=ok
 o6[0]* ::= a6 R3:1@1-2C9@1
7: o5[c6] R9:1@1-2 p=ok c=ok
 o5[0]* ::= a5 R9:1@1-2S4@1
8: o2[p1] R0:1@0-1 p=ok c=ok
 o2[0]* ::= a2 R0:1@0-1C9@0
9: o1[c8] R9:1@0-1 p=ok c=ok
 o1[0]* ::= a1 R9:1@0-1S4@0
END_OF_TEXT

$recce->read( 'a', 'a' );
$recce->read( 'a', 'a' );
$recce->read( 'a', 'a' );

Marpa::R2::Test::is(
    $recce->show_earley_sets(1),
    "Last Completed: 3; Furthest: 3\n" . ( join q{}, @set[ 0 .. 3 ] ),
    'Aycock/Horspool Parse Status'
);

my %expected =
    map { ( $_ => 1 ) } qw( (a;a;a;) (a;a;;a) (a;;a;a) (;a;a;a) );

$recce->set( { max_parses => 20 } );

while ( my $value_ref = $recce->value() ) {

    my $tree_output = q{};

    my $value = 'No parse';
    if ($value_ref) {
        $value = ${$value_ref};
        Marpa::R2::Test::is( $recce->show_tree(), $tree_expected{$value},
            qq{Tree, "$value"} );
    }
    else {
        Test::More::fail('Tree');
    }

    if ( defined $expected{$value} ) {
        delete $expected{$value};
        Test::More::pass(qq{Expected result, "$value"});
    }
    else {
        Test::More::fail(qq{Unexpected result, "$value"});
    }
} ## end while ( my $value_ref = $recce->value() )

for my $value ( keys %expected ) {
    Test::More::fail(qq{Missing result, "$value"});
}

my $or_node_output = <<'END_OF_TEXT';
R2:1@0-0
R0:1@0-1
R3:1@0-1
R9:1@0-1
R0:2@0-3
R2:2@0-3
R3:2@0-3
R10:1@0-3
R5:1@1-1
R3:1@1-2
R6:1@1-2
R9:1@1-2
R3:2@1-3
R5:2@1-3
R6:2@1-3
R8:1@2-2
R7:1@2-3
R7:2@2-3
R8:2@2-3
R9:1@2-3
END_OF_TEXT

Marpa::R2::Test::is( $recce->show_or_nodes(), $or_node_output,
    'XS Or nodes' );

my $and_node_output = <<'END_OF_TEXT';
And-node #0: R2:1@0-0S3@0
And-node #2: R0:1@0-1C9@0
And-node #3: R3:1@0-1C9@0
And-node #1: R9:1@0-1S4@0
And-node #19: R0:2@0-3C5@1
And-node #20: R0:2@0-3C3@1
And-node #16: R2:2@0-3C3@0
And-node #15: R3:2@0-3C6@1
And-node #17: R10:1@0-3C2@0
And-node #18: R10:1@0-3C0@0
And-node #4: R5:1@1-1S3@1
And-node #6: R3:1@1-2C9@1
And-node #7: R6:1@1-2C9@1
And-node #5: R9:1@1-2S4@1
And-node #21: R3:2@1-3C8@2
And-node #22: R3:2@1-3C7@2
And-node #14: R5:2@1-3C6@1
And-node #13: R6:2@1-3C9@2
And-node #8: R8:1@2-2S3@2
And-node #10: R7:1@2-3C9@2
And-node #11: R7:2@2-3S3@3
And-node #12: R8:2@2-3C9@2
And-node #9: R9:1@2-3S4@2
END_OF_TEXT

Marpa::R2::Test::is( $recce->show_and_nodes(),
    $and_node_output, 'XS And nodes' );

my $bocage_output = <<'END_OF_TEXT';
R2:1@0-0 - S3
R0:1@0-1 - R9:1@0-1
R3:1@0-1 - R9:1@0-1
R9:1@0-1 - S4
R0:2@0-3 R0:1@0-1 R3:2@1-3
R0:2@0-3 R0:1@0-1 R5:2@1-3
R2:2@0-3 R2:1@0-0 R3:2@0-3
R3:2@0-3 R3:1@0-1 R6:2@1-3
R10:1@0-3 - R0:2@0-3
R10:1@0-3 - R2:2@0-3
R5:1@1-1 - S3
R3:1@1-2 - R9:1@1-2
R6:1@1-2 - R9:1@1-2
R9:1@1-2 - S4
R3:2@1-3 R3:1@1-2 R7:2@2-3
R3:2@1-3 R3:1@1-2 R8:2@2-3
R5:2@1-3 R5:1@1-1 R6:2@1-3
R6:2@1-3 R6:1@1-2 R9:1@2-3
R8:1@2-2 - S3
R7:1@2-3 - R9:1@2-3
R7:2@2-3 R7:1@2-3 S3
R8:2@2-3 R8:1@2-2 R9:1@2-3
R9:1@2-3 - S4
END_OF_TEXT

Marpa::R2::Test::is( $recce->show_bocage(), $bocage_output, 'XS Bocage' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
