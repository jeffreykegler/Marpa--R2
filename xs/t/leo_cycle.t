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

# This is based on the
# example from p. 166 of Leo's paper,
# augmented to test Leo prediction items,
# as well as a long cycle of Leo items

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Test::More tests => 7;

use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

## no critic (Subroutines::RequireArgUnpacking)

sub main::default_action {
    shift;
    return ( join q{}, grep {defined} @_ );
}

## use critic

my $grammar = Marpa::Grammar->new(
    {   start => 'S',
        strip => 0,
        rules => [
            [ 'S', [qw/a A/] ],
            [ 'H', [qw/S/] ],
            [ 'B', [qw/C/] ],
            [ 'D', [qw/E/] ],
            [ 'E', [qw/F/] ],
            [ 'F', [qw/G/] ],
            [ 'C', [qw/D/] ],
            [ 'G', [qw/H/] ],
            [ 'A', [qw/B/] ],
            [ 'S', [], ],
        ],
        terminals      => [qw(a)],
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

Marpa::Test::is( $grammar->show_symbols(),
    <<'END_OF_STRING', 'Leo166 Symbols' );
0: a, lhs=[] rhs=[0 10 11] terminal
1: S, lhs=[0 9 10 11] rhs=[1 12 20]
2: A, lhs=[8 19] rhs=[0 10]
3: H, lhs=[1 12] rhs=[7 18]
4: B, lhs=[2 13] rhs=[8 19]
5: C, lhs=[6 17] rhs=[2 13]
6: D, lhs=[3 14] rhs=[6 17]
7: E, lhs=[4 15] rhs=[3 14]
8: F, lhs=[5 16] rhs=[4 15]
9: G, lhs=[7 18] rhs=[5 16]
10: S[], lhs=[] rhs=[] nullable nulling
11: A[], lhs=[] rhs=[11] nullable nulling
12: H[], lhs=[] rhs=[] nullable nulling
13: B[], lhs=[] rhs=[] nullable nulling
14: C[], lhs=[] rhs=[] nullable nulling
15: D[], lhs=[] rhs=[] nullable nulling
16: E[], lhs=[] rhs=[] nullable nulling
17: F[], lhs=[] rhs=[] nullable nulling
18: G[], lhs=[] rhs=[] nullable nulling
19: S['], lhs=[20] rhs=[]
20: S['][], lhs=[21] rhs=[] nullable nulling
END_OF_STRING

Marpa::Test::is( $grammar->show_rules,
    <<'END_OF_STRING', 'Leo166 Rules' );
0: S -> a A /* !used */
1: H -> S /* !used */
2: B -> C /* !used */
3: D -> E /* !used */
4: E -> F /* !used */
5: F -> G /* !used */
6: C -> D /* !used */
7: G -> H /* !used */
8: A -> B /* !used */
9: S -> /* empty !used */
10: S -> a A
11: S -> a A[]
12: H -> S
13: B -> C
14: D -> E
15: E -> F
16: F -> G
17: C -> D
18: G -> H
19: A -> B
20: S['] -> S /* vlhs real=1 */
21: S['][] -> /* empty vlhs real=1 */
END_OF_STRING

my $expected_ahfa_output = <<'END_OF_STRING';
* S0:
S['] -> . S
S['][] -> .
 <S> => S2; leo(S['])
* S1: predict
S -> . a A
S -> . a A[]
 <a> => S3; S4
* S2: leo-c
S['] -> S .
* S3:
S -> a . A
S -> a A[] .
 <A> => S5; leo(S)
* S4: predict
S -> . a A
S -> . a A[]
H -> . S
B -> . C
D -> . E
E -> . F
F -> . G
C -> . D
G -> . H
A -> . B
 <B> => S8; leo(A)
 <C> => S9; leo(B)
 <D> => S10; leo(C)
 <E> => S11; leo(D)
 <F> => S12; leo(E)
 <G> => S13; leo(F)
 <H> => S7; leo(G)
 <S> => S6; leo(H)
 <a> => S3; S4
* S5: leo-c
S -> a A .
* S6: leo-c
H -> S .
* S7: leo-c
G -> H .
* S8: leo-c
A -> B .
* S9: leo-c
B -> C .
* S10: leo-c
C -> D .
* S11: leo-c
D -> E .
* S12: leo-c
E -> F .
* S13: leo-c
F -> G .
END_OF_STRING

Marpa::Test::is( $grammar->show_AHFA(), $expected_ahfa_output,
    'Leo166 AHFA' );

my $a_token = [ 'a', 'a' ];
my $length = 20;

my $recce = Marpa::Recognizer->new(
    { grammar => $grammar, mode => 'stream'  } );

my $i        = 0;
my $latest_earley_set = $recce->latest_earley_set();
my $max_size = $recce->earley_set_size($latest_earley_set);
TOKEN: while ( $i++ < $length ) {
    $recce->tokens( [$a_token] );
    $latest_earley_set = $recce->latest_earley_set();
    my $size = $recce->earley_set_size($latest_earley_set);

    $max_size = $size > $max_size ? $size : $max_size;
} ## end while ( $i++ < $length )

# Note that the length formula only works
# beginning with Earley set c, for some small
# constant c
my $expected_size = 4;
Marpa::Test::is( $max_size, $expected_size,
    "size $max_size" );

my $show_earley_sets_output = do { local $RS = undef; readline(*DATA); };

Marpa::Test::is( $recce->show_earley_sets(1),
    $show_earley_sets_output, 'Leo cycle Earley sets' );

my $value_ref = $recce->value( {} );
my $value = $value_ref ? ${$value_ref} : 'No parse';
Marpa::Test::is( $value, 'a' x $length, 'Leo cycle parse' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

__DATA__
Last Completed: 20; Furthest: 20
Earley Set 0
S0@0-0
S1@0-0
Earley Set 1
S2@0-1 [p=S0@0-0; c=S3@0-1]
S3@0-1 [p=S1@0-0; s=a; t=\'a']
S4@1-1
L1@1 ["S"; L3@1; S4@1-1]
L2@1 ["A"; S3@0-1]
L3@1 ["H"; L9@1; S4@1-1]
L4@1 ["B"; L2@1; S4@1-1]
L5@1 ["C"; L4@1; S4@1-1]
L6@1 ["D"; L5@1; S4@1-1]
L7@1 ["E"; L6@1; S4@1-1]
L8@1 ["F"; L7@1; S4@1-1]
L9@1 ["G"; L8@1; S4@1-1]
Earley Set 2
S2@0-2 [p=S0@0-0; c=S5@0-2]
S5@0-2 [l=L1@1; c=S3@1-2]
S3@1-2 [p=S4@1-1; s=a; t=\'a']
S4@2-2
L1@2 ["S"; L3@2; S4@2-2]
L2@2 ["A"; L1@1; S3@1-2]
L3@2 ["H"; L9@2; S4@2-2]
L4@2 ["B"; L2@2; S4@2-2]
L5@2 ["C"; L4@2; S4@2-2]
L6@2 ["D"; L5@2; S4@2-2]
L7@2 ["E"; L6@2; S4@2-2]
L8@2 ["F"; L7@2; S4@2-2]
L9@2 ["G"; L8@2; S4@2-2]
Earley Set 3
S2@0-3 [p=S0@0-0; c=S5@0-3]
S5@0-3 [l=L1@2; c=S3@2-3]
S3@2-3 [p=S4@2-2; s=a; t=\'a']
S4@3-3
L1@3 ["S"; L3@3; S4@3-3]
L2@3 ["A"; L1@2; S3@2-3]
L3@3 ["H"; L9@3; S4@3-3]
L4@3 ["B"; L2@3; S4@3-3]
L5@3 ["C"; L4@3; S4@3-3]
L6@3 ["D"; L5@3; S4@3-3]
L7@3 ["E"; L6@3; S4@3-3]
L8@3 ["F"; L7@3; S4@3-3]
L9@3 ["G"; L8@3; S4@3-3]
Earley Set 4
S2@0-4 [p=S0@0-0; c=S5@0-4]
S5@0-4 [l=L1@3; c=S3@3-4]
S3@3-4 [p=S4@3-3; s=a; t=\'a']
S4@4-4
L1@4 ["S"; L3@4; S4@4-4]
L2@4 ["A"; L1@3; S3@3-4]
L3@4 ["H"; L9@4; S4@4-4]
L4@4 ["B"; L2@4; S4@4-4]
L5@4 ["C"; L4@4; S4@4-4]
L6@4 ["D"; L5@4; S4@4-4]
L7@4 ["E"; L6@4; S4@4-4]
L8@4 ["F"; L7@4; S4@4-4]
L9@4 ["G"; L8@4; S4@4-4]
Earley Set 5
S2@0-5 [p=S0@0-0; c=S5@0-5]
S5@0-5 [l=L1@4; c=S3@4-5]
S3@4-5 [p=S4@4-4; s=a; t=\'a']
S4@5-5
L1@5 ["S"; L3@5; S4@5-5]
L2@5 ["A"; L1@4; S3@4-5]
L3@5 ["H"; L9@5; S4@5-5]
L4@5 ["B"; L2@5; S4@5-5]
L5@5 ["C"; L4@5; S4@5-5]
L6@5 ["D"; L5@5; S4@5-5]
L7@5 ["E"; L6@5; S4@5-5]
L8@5 ["F"; L7@5; S4@5-5]
L9@5 ["G"; L8@5; S4@5-5]
Earley Set 6
S2@0-6 [p=S0@0-0; c=S5@0-6]
S5@0-6 [l=L1@5; c=S3@5-6]
S3@5-6 [p=S4@5-5; s=a; t=\'a']
S4@6-6
L1@6 ["S"; L3@6; S4@6-6]
L2@6 ["A"; L1@5; S3@5-6]
L3@6 ["H"; L9@6; S4@6-6]
L4@6 ["B"; L2@6; S4@6-6]
L5@6 ["C"; L4@6; S4@6-6]
L6@6 ["D"; L5@6; S4@6-6]
L7@6 ["E"; L6@6; S4@6-6]
L8@6 ["F"; L7@6; S4@6-6]
L9@6 ["G"; L8@6; S4@6-6]
Earley Set 7
S2@0-7 [p=S0@0-0; c=S5@0-7]
S5@0-7 [l=L1@6; c=S3@6-7]
S3@6-7 [p=S4@6-6; s=a; t=\'a']
S4@7-7
L1@7 ["S"; L3@7; S4@7-7]
L2@7 ["A"; L1@6; S3@6-7]
L3@7 ["H"; L9@7; S4@7-7]
L4@7 ["B"; L2@7; S4@7-7]
L5@7 ["C"; L4@7; S4@7-7]
L6@7 ["D"; L5@7; S4@7-7]
L7@7 ["E"; L6@7; S4@7-7]
L8@7 ["F"; L7@7; S4@7-7]
L9@7 ["G"; L8@7; S4@7-7]
Earley Set 8
S2@0-8 [p=S0@0-0; c=S5@0-8]
S5@0-8 [l=L1@7; c=S3@7-8]
S3@7-8 [p=S4@7-7; s=a; t=\'a']
S4@8-8
L1@8 ["S"; L3@8; S4@8-8]
L2@8 ["A"; L1@7; S3@7-8]
L3@8 ["H"; L9@8; S4@8-8]
L4@8 ["B"; L2@8; S4@8-8]
L5@8 ["C"; L4@8; S4@8-8]
L6@8 ["D"; L5@8; S4@8-8]
L7@8 ["E"; L6@8; S4@8-8]
L8@8 ["F"; L7@8; S4@8-8]
L9@8 ["G"; L8@8; S4@8-8]
Earley Set 9
S2@0-9 [p=S0@0-0; c=S5@0-9]
S5@0-9 [l=L1@8; c=S3@8-9]
S3@8-9 [p=S4@8-8; s=a; t=\'a']
S4@9-9
L1@9 ["S"; L3@9; S4@9-9]
L2@9 ["A"; L1@8; S3@8-9]
L3@9 ["H"; L9@9; S4@9-9]
L4@9 ["B"; L2@9; S4@9-9]
L5@9 ["C"; L4@9; S4@9-9]
L6@9 ["D"; L5@9; S4@9-9]
L7@9 ["E"; L6@9; S4@9-9]
L8@9 ["F"; L7@9; S4@9-9]
L9@9 ["G"; L8@9; S4@9-9]
Earley Set 10
S2@0-10 [p=S0@0-0; c=S5@0-10]
S5@0-10 [l=L1@9; c=S3@9-10]
S3@9-10 [p=S4@9-9; s=a; t=\'a']
S4@10-10
L1@10 ["S"; L3@10; S4@10-10]
L2@10 ["A"; L1@9; S3@9-10]
L3@10 ["H"; L9@10; S4@10-10]
L4@10 ["B"; L2@10; S4@10-10]
L5@10 ["C"; L4@10; S4@10-10]
L6@10 ["D"; L5@10; S4@10-10]
L7@10 ["E"; L6@10; S4@10-10]
L8@10 ["F"; L7@10; S4@10-10]
L9@10 ["G"; L8@10; S4@10-10]
Earley Set 11
S2@0-11 [p=S0@0-0; c=S5@0-11]
S5@0-11 [l=L1@10; c=S3@10-11]
S3@10-11 [p=S4@10-10; s=a; t=\'a']
S4@11-11
L1@11 ["S"; L3@11; S4@11-11]
L2@11 ["A"; L1@10; S3@10-11]
L3@11 ["H"; L9@11; S4@11-11]
L4@11 ["B"; L2@11; S4@11-11]
L5@11 ["C"; L4@11; S4@11-11]
L6@11 ["D"; L5@11; S4@11-11]
L7@11 ["E"; L6@11; S4@11-11]
L8@11 ["F"; L7@11; S4@11-11]
L9@11 ["G"; L8@11; S4@11-11]
Earley Set 12
S2@0-12 [p=S0@0-0; c=S5@0-12]
S5@0-12 [l=L1@11; c=S3@11-12]
S3@11-12 [p=S4@11-11; s=a; t=\'a']
S4@12-12
L1@12 ["S"; L3@12; S4@12-12]
L2@12 ["A"; L1@11; S3@11-12]
L3@12 ["H"; L9@12; S4@12-12]
L4@12 ["B"; L2@12; S4@12-12]
L5@12 ["C"; L4@12; S4@12-12]
L6@12 ["D"; L5@12; S4@12-12]
L7@12 ["E"; L6@12; S4@12-12]
L8@12 ["F"; L7@12; S4@12-12]
L9@12 ["G"; L8@12; S4@12-12]
Earley Set 13
S2@0-13 [p=S0@0-0; c=S5@0-13]
S5@0-13 [l=L1@12; c=S3@12-13]
S3@12-13 [p=S4@12-12; s=a; t=\'a']
S4@13-13
L1@13 ["S"; L3@13; S4@13-13]
L2@13 ["A"; L1@12; S3@12-13]
L3@13 ["H"; L9@13; S4@13-13]
L4@13 ["B"; L2@13; S4@13-13]
L5@13 ["C"; L4@13; S4@13-13]
L6@13 ["D"; L5@13; S4@13-13]
L7@13 ["E"; L6@13; S4@13-13]
L8@13 ["F"; L7@13; S4@13-13]
L9@13 ["G"; L8@13; S4@13-13]
Earley Set 14
S2@0-14 [p=S0@0-0; c=S5@0-14]
S5@0-14 [l=L1@13; c=S3@13-14]
S3@13-14 [p=S4@13-13; s=a; t=\'a']
S4@14-14
L1@14 ["S"; L3@14; S4@14-14]
L2@14 ["A"; L1@13; S3@13-14]
L3@14 ["H"; L9@14; S4@14-14]
L4@14 ["B"; L2@14; S4@14-14]
L5@14 ["C"; L4@14; S4@14-14]
L6@14 ["D"; L5@14; S4@14-14]
L7@14 ["E"; L6@14; S4@14-14]
L8@14 ["F"; L7@14; S4@14-14]
L9@14 ["G"; L8@14; S4@14-14]
Earley Set 15
S2@0-15 [p=S0@0-0; c=S5@0-15]
S5@0-15 [l=L1@14; c=S3@14-15]
S3@14-15 [p=S4@14-14; s=a; t=\'a']
S4@15-15
L1@15 ["S"; L3@15; S4@15-15]
L2@15 ["A"; L1@14; S3@14-15]
L3@15 ["H"; L9@15; S4@15-15]
L4@15 ["B"; L2@15; S4@15-15]
L5@15 ["C"; L4@15; S4@15-15]
L6@15 ["D"; L5@15; S4@15-15]
L7@15 ["E"; L6@15; S4@15-15]
L8@15 ["F"; L7@15; S4@15-15]
L9@15 ["G"; L8@15; S4@15-15]
Earley Set 16
S2@0-16 [p=S0@0-0; c=S5@0-16]
S5@0-16 [l=L1@15; c=S3@15-16]
S3@15-16 [p=S4@15-15; s=a; t=\'a']
S4@16-16
L1@16 ["S"; L3@16; S4@16-16]
L2@16 ["A"; L1@15; S3@15-16]
L3@16 ["H"; L9@16; S4@16-16]
L4@16 ["B"; L2@16; S4@16-16]
L5@16 ["C"; L4@16; S4@16-16]
L6@16 ["D"; L5@16; S4@16-16]
L7@16 ["E"; L6@16; S4@16-16]
L8@16 ["F"; L7@16; S4@16-16]
L9@16 ["G"; L8@16; S4@16-16]
Earley Set 17
S2@0-17 [p=S0@0-0; c=S5@0-17]
S5@0-17 [l=L1@16; c=S3@16-17]
S3@16-17 [p=S4@16-16; s=a; t=\'a']
S4@17-17
L1@17 ["S"; L3@17; S4@17-17]
L2@17 ["A"; L1@16; S3@16-17]
L3@17 ["H"; L9@17; S4@17-17]
L4@17 ["B"; L2@17; S4@17-17]
L5@17 ["C"; L4@17; S4@17-17]
L6@17 ["D"; L5@17; S4@17-17]
L7@17 ["E"; L6@17; S4@17-17]
L8@17 ["F"; L7@17; S4@17-17]
L9@17 ["G"; L8@17; S4@17-17]
Earley Set 18
S2@0-18 [p=S0@0-0; c=S5@0-18]
S5@0-18 [l=L1@17; c=S3@17-18]
S3@17-18 [p=S4@17-17; s=a; t=\'a']
S4@18-18
L1@18 ["S"; L3@18; S4@18-18]
L2@18 ["A"; L1@17; S3@17-18]
L3@18 ["H"; L9@18; S4@18-18]
L4@18 ["B"; L2@18; S4@18-18]
L5@18 ["C"; L4@18; S4@18-18]
L6@18 ["D"; L5@18; S4@18-18]
L7@18 ["E"; L6@18; S4@18-18]
L8@18 ["F"; L7@18; S4@18-18]
L9@18 ["G"; L8@18; S4@18-18]
Earley Set 19
S2@0-19 [p=S0@0-0; c=S5@0-19]
S5@0-19 [l=L1@18; c=S3@18-19]
S3@18-19 [p=S4@18-18; s=a; t=\'a']
S4@19-19
L1@19 ["S"; L3@19; S4@19-19]
L2@19 ["A"; L1@18; S3@18-19]
L3@19 ["H"; L9@19; S4@19-19]
L4@19 ["B"; L2@19; S4@19-19]
L5@19 ["C"; L4@19; S4@19-19]
L6@19 ["D"; L5@19; S4@19-19]
L7@19 ["E"; L6@19; S4@19-19]
L8@19 ["F"; L7@19; S4@19-19]
L9@19 ["G"; L8@19; S4@19-19]
Earley Set 20
S2@0-20 [p=S0@0-0; c=S5@0-20]
S5@0-20 [l=L1@19; c=S3@19-20]
S3@19-20 [p=S4@19-19; s=a; t=\'a']
S4@20-20
L1@20 ["S"; L3@20; S4@20-20]
L2@20 ["A"; L1@19; S3@19-20]
L3@20 ["H"; L9@20; S4@20-20]
L4@20 ["B"; L2@20; S4@20-20]
L5@20 ["C"; L4@20; S4@20-20]
L6@20 ["D"; L5@20; S4@20-20]
L7@20 ["E"; L6@20; S4@20-20]
L8@20 ["F"; L7@20; S4@20-20]
L9@20 ["G"; L8@20; S4@20-20]
