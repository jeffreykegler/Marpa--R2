#!perl
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

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use Test::More tests => 31;
use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . ( join q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::Grammar->new(
    {   start => 'S',
        strip => 0,
        rules => [
            [ 'S', [qw/A A A A/] ],
            [ 'A', [qw/a/] ],
            [ 'A', [qw/E/] ],
            ['E'],
        ],
        default_null_value => q{},
        default_action     => 'main::default_action',
    }
);

$grammar->set( { terminals => ['a'], } );

$grammar->precompute();

Marpa::Test::is( $grammar->show_rules, <<'EOS', 'Aycock/Horspool Rules' );
0: S -> A A A A /* !used */
1: A -> a
2: A -> E /* !used */
3: E -> /* empty !used */
4: S -> A S[R0:1] /* vrhs real=1 */
5: S -> A A[] A[] A[]
6: S -> A[] S[R0:1] /* vrhs real=1 */
7: S[R0:1] -> A S[R0:2] /* vlhs vrhs real=1 */
8: S[R0:1] -> A A[] A[] /* vlhs real=3 */
9: S[R0:1] -> A[] S[R0:2] /* vlhs vrhs real=1 */
10: S[R0:2] -> A A /* vlhs real=2 */
11: S[R0:2] -> A A[] /* vlhs real=2 */
12: S[R0:2] -> A[] A /* vlhs real=2 */
13: S['] -> S /* vlhs real=1 */
14: S['][] -> /* empty vlhs real=1 */
EOS

Marpa::Test::is( $grammar->show_symbols, <<'EOS', 'Aycock/Horspool Symbols' );
0: S, lhs=[0 4 5 6] rhs=[13]
1: A, lhs=[1 2] rhs=[0 4 5 7 8 10 11 12]
2: a, lhs=[] rhs=[1] terminal
3: E, lhs=[3] rhs=[2] nullable nulling
4: S[], lhs=[] rhs=[] nullable nulling
5: A[], lhs=[] rhs=[5 6 8 9 11 12] nullable nulling
6: S[R0:1], lhs=[7 8 9] rhs=[4 6]
7: S[R0:2], lhs=[10 11 12] rhs=[7 9]
8: S['], lhs=[13] rhs=[]
9: S['][], lhs=[14] rhs=[] nullable nulling
EOS

Marpa::Test::is(
    $grammar->show_nullable_symbols,
    q{A[] E S['][] S[]},
    'Aycock/Horspool Nullable Symbols'
);
Marpa::Test::is(
    $grammar->show_nulling_symbols,
    q{A[] E S['][] S[]},
    'Aycock/Horspool Nulling Symbols'
);
Marpa::Test::is(
    $grammar->show_productive_symbols,
    q{A A[] E S S['] S['][] S[R0:1] S[R0:2] S[] a},
    'Aycock/Horspool Productive Symbols'
);
Marpa::Test::is(
    $grammar->show_accessible_symbols,
    q{A A[] E S S['] S['][] S[R0:1] S[R0:2] S[] a},
    'Aycock/Horspool Accessible Symbols'
);

if ($Marpa::USING_XS) {
    Marpa::Test::is( $grammar->show_AHFA_items(),
        <<'EOS', 'Aycock/Horspool AHFA Items' );
AHFA item 0: sort = 9; postdot = "a"
    A -> . a
AHFA item 1: sort = 14; completion
    A -> a .
AHFA item 2: sort = 1; postdot = "A"
    S -> . A S[R0:1]
AHFA item 3: sort = 10; postdot = "S[R0:1]"
    S -> A . S[R0:1]
AHFA item 4: sort = 15; completion
    S -> A S[R0:1] .
AHFA item 5: sort = 2; postdot = "A"
    S -> . A A[] A[] A[]
AHFA item 6: sort = 16; completion
    S -> A A[] A[] A[] .
AHFA item 7: sort = 11; postdot = "S[R0:1]"
    S -> A[] . S[R0:1]
AHFA item 8: sort = 17; completion
    S -> A[] S[R0:1] .
AHFA item 9: sort = 3; postdot = "A"
    S[R0:1] -> . A S[R0:2]
AHFA item 10: sort = 12; postdot = "S[R0:2]"
    S[R0:1] -> A . S[R0:2]
AHFA item 11: sort = 18; completion
    S[R0:1] -> A S[R0:2] .
AHFA item 12: sort = 4; postdot = "A"
    S[R0:1] -> . A A[] A[]
AHFA item 13: sort = 19; completion
    S[R0:1] -> A A[] A[] .
AHFA item 14: sort = 13; postdot = "S[R0:2]"
    S[R0:1] -> A[] . S[R0:2]
AHFA item 15: sort = 20; completion
    S[R0:1] -> A[] S[R0:2] .
AHFA item 16: sort = 5; postdot = "A"
    S[R0:2] -> . A A
AHFA item 17: sort = 6; postdot = "A"
    S[R0:2] -> A . A
AHFA item 18: sort = 21; completion
    S[R0:2] -> A A .
AHFA item 19: sort = 7; postdot = "A"
    S[R0:2] -> . A A[]
AHFA item 20: sort = 22; completion
    S[R0:2] -> A A[] .
AHFA item 21: sort = 8; postdot = "A"
    S[R0:2] -> A[] . A
AHFA item 22: sort = 23; completion
    S[R0:2] -> A[] A .
AHFA item 23: sort = 0; postdot = "S"
    S['] -> . S
AHFA item 24: sort = 24; completion
    S['] -> S .
AHFA item 25: sort = 25; completion
    S['][] -> .
EOS
} ## end if ($Marpa::USING_XS)

if ($Marpa::USING_PP) {
    Marpa::Test::is( $grammar->show_NFA, <<'EOS', 'Aycock/Horspool NFA' );
S0: /* empty */
 empty => S33 S35
S1: A -> . a
 <a> => S2
S2: A -> a .
S3: S -> . A S[R0:1]
 empty => S1
 <A> => S4
S4: S -> A . S[R0:1]
 empty => S14 S17 S21
 <S[R0:1]> => S5
S5: S -> A S[R0:1] .
S6: S -> . A A[] A[] A[]
 empty => S1
 <A> => S7
S7: S -> A . A[] A[] A[]
at_nulling
 <A[]> => S8
S8: S -> A A[] . A[] A[]
at_nulling
 <A[]> => S9
S9: S -> A A[] A[] . A[]
at_nulling
 <A[]> => S10
S10: S -> A A[] A[] A[] .
S11: S -> . A[] S[R0:1]
at_nulling
 <A[]> => S12
S12: S -> A[] . S[R0:1]
 empty => S14 S17 S21
 <S[R0:1]> => S13
S13: S -> A[] S[R0:1] .
S14: S[R0:1] -> . A S[R0:2]
 empty => S1
 <A> => S15
S15: S[R0:1] -> A . S[R0:2]
 empty => S24 S27 S30
 <S[R0:2]> => S16
S16: S[R0:1] -> A S[R0:2] .
S17: S[R0:1] -> . A A[] A[]
 empty => S1
 <A> => S18
S18: S[R0:1] -> A . A[] A[]
at_nulling
 <A[]> => S19
S19: S[R0:1] -> A A[] . A[]
at_nulling
 <A[]> => S20
S20: S[R0:1] -> A A[] A[] .
S21: S[R0:1] -> . A[] S[R0:2]
at_nulling
 <A[]> => S22
S22: S[R0:1] -> A[] . S[R0:2]
 empty => S24 S27 S30
 <S[R0:2]> => S23
S23: S[R0:1] -> A[] S[R0:2] .
S24: S[R0:2] -> . A A
 empty => S1
 <A> => S25
S25: S[R0:2] -> A . A
 empty => S1
 <A> => S26
S26: S[R0:2] -> A A .
S27: S[R0:2] -> . A A[]
 empty => S1
 <A> => S28
S28: S[R0:2] -> A . A[]
at_nulling
 <A[]> => S29
S29: S[R0:2] -> A A[] .
S30: S[R0:2] -> . A[] A
at_nulling
 <A[]> => S31
S31: S[R0:2] -> A[] . A
 empty => S1
 <A> => S32
S32: S[R0:2] -> A[] A .
S33: S['] -> . S
 empty => S3 S6 S11
 <S> => S34
S34: S['] -> S .
S35: S['][] -> .
EOS
} ## end if ($Marpa::USING_PP)

Marpa::Test::is( $grammar->show_AHFA, <<'EOS', 'Aycock/Horspool AHFA' );
* S0:
S['] -> . S
S['][] -> .
 <S> => S2; leo(S['])
* S1: predict
A -> . a
S -> . A S[R0:1]
S -> . A A[] A[] A[]
S -> A[] . S[R0:1]
S[R0:1] -> . A S[R0:2]
S[R0:1] -> . A A[] A[]
S[R0:1] -> A[] . S[R0:2]
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
 <A> => S3; S4
 <S[R0:1]> => S6; leo(S)
 <S[R0:2]> => S7; leo(S[R0:1])
 <a> => S5
* S2: leo-c
S['] -> S .
* S3:
S -> A . S[R0:1]
S -> A A[] A[] A[] .
S[R0:1] -> A . S[R0:2]
S[R0:1] -> A A[] A[] .
S[R0:2] -> A . A
S[R0:2] -> A A[] .
S[R0:2] -> A[] A .
 <A> => S8; leo(S[R0:2])
 <S[R0:1]> => S9; leo(S)
 <S[R0:2]> => S10; leo(S[R0:1])
* S4: predict
A -> . a
S[R0:1] -> . A S[R0:2]
S[R0:1] -> . A A[] A[]
S[R0:1] -> A[] . S[R0:2]
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
 <A> => S11; S12
 <S[R0:2]> => S7; leo(S[R0:1])
 <a> => S5
* S5:
A -> a .
* S6: leo-c
S -> A[] S[R0:1] .
* S7: leo-c
S[R0:1] -> A[] S[R0:2] .
* S8: leo-c
S[R0:2] -> A A .
* S9: leo-c
S -> A S[R0:1] .
* S10: leo-c
S[R0:1] -> A S[R0:2] .
* S11:
S[R0:1] -> A . S[R0:2]
S[R0:1] -> A A[] A[] .
S[R0:2] -> A . A
S[R0:2] -> A A[] .
S[R0:2] -> A[] A .
 <A> => S8; leo(S[R0:2])
 <S[R0:2]> => S10; leo(S[R0:1])
* S12: predict
A -> . a
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
 <A> => S13; S14
 <a> => S5
* S13:
S[R0:2] -> A . A
S[R0:2] -> A A[] .
S[R0:2] -> A[] A .
 <A> => S8; leo(S[R0:2])
* S14: predict
A -> . a
 <a> => S5
EOS

my $recce =
    Marpa::Recognizer->new( { grammar => $grammar, mode => 'stream' } );

my @set = (
    <<'END_OF_SET0', <<'END_OF_SET1', <<'END_OF_SET2', <<'END_OF_SET3', <<'END_OF_SET4', );
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
L6@1 ["S[R0:1]"; S3@0-1]
END_OF_SET1
Earley Set 2
S2@0-2 [p=S0@0-0; c=S6@0-2] [p=S0@0-0; c=S9@0-2]
S6@0-2 [p=S1@0-0; c=S7@0-2] [p=S1@0-0; c=S10@0-2]
S7@0-2 [p=S1@0-0; c=S8@0-2]
S8@0-2 [p=S3@0-1; c=S5@1-2]
S9@0-2 [l=L6@1; c=S7@1-2] [l=L6@1; c=S11@1-2]
S10@0-2 [p=S3@0-1; c=S11@1-2]
S5@1-2 [p=S4@1-1; s=a; t=\'a']
S7@1-2 [p=S4@1-1; c=S11@1-2]
S11@1-2 [p=S4@1-1; c=S5@1-2]
S12@2-2
L7@2 ["S[R0:2]"; L6@1; S11@1-2]
END_OF_SET2
Earley Set 3
S2@0-3 [p=S0@0-0; c=S6@0-3] [p=S0@0-0; c=S9@0-3]
S6@0-3 [p=S1@0-0; c=S10@0-3]
S9@0-3 [l=L6@1; c=S7@1-3] [l=L7@2; c=S13@2-3]
S10@0-3 [p=S3@0-1; c=S8@1-3]
S7@1-3 [p=S4@1-1; c=S8@1-3]
S8@1-3 [p=S11@1-2; c=S5@2-3]
S5@2-3 [p=S12@2-2; s=a; t=\'a']
S13@2-3 [p=S12@2-2; c=S5@2-3]
S14@3-3
L1@3 ["A"; L7@2; S13@2-3]
END_OF_SET3
Earley Set 4
S2@0-4 [p=S0@0-0; c=S9@0-4]
S9@0-4 [l=L1@3; c=S5@3-4]
S5@3-4 [p=S14@3-3; s=a; t=\'a']
END_OF_SET4

my $input_length = 4;
EARLEME: for my $earleme ( 0 .. $input_length + 1 ) {
    my $furthest = my $last_completed =
        List::Util::min( $earleme, $input_length );
    Marpa::Test::is(
        $recce->show_earley_sets(1),
        "Last Completed: $last_completed; Furthest: $furthest\n"
            . ( join q{}, @set[ 0 .. $furthest ] ),
        "Aycock/Horspool Parse Status at earleme $earleme"
    );
    next EARLEME if $earleme == $input_length;
    last EARLEME if $earleme > $input_length;
    $recce->read( 'a', 'a' );
} ## end for my $earleme ( 0 .. $input_length + 1 )

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
