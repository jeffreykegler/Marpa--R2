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

# This is based on the
# example from p. 166 of Leo's paper,
# augmented to test Leo prediction items,
# as well as a long cycle of Leo items

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Test::More tests => 6;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

sub main::default_action {
    shift;
    return ( join q{}, grep {defined} @_ );
}

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'S',
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

Marpa::R2::Test::is( $grammar->show_symbols(),
    <<'END_OF_STRING', 'Leo166 Symbols' );
0: a, terminal
1: S
2: A
3: H
4: B
5: C
6: D
7: E
8: F
9: G
END_OF_STRING

Marpa::R2::Test::is( $grammar->show_rules,
    <<'END_OF_STRING', 'Leo166 Rules' );
0: S -> a A
1: H -> S
2: B -> C
3: D -> E
4: E -> F
5: F -> G
6: C -> D
7: G -> H
8: A -> B
9: S -> /* empty !used */
END_OF_STRING

my $expected_ahfa_output = <<'END_OF_STRING';
* S0:
S['] -> . S
* S1: predict
S -> . a A
S -> . a A[]
* S2:
S -> a . A
* S3: predict
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
* S4:
S -> a A .
* S5:
S -> a A[] .
* S6:
H -> S .
* S7:
B -> C .
* S8:
D -> E .
* S9:
E -> F .
* S10:
F -> G .
* S11:
C -> D .
* S12:
G -> H .
* S13:
A -> B .
* S14:
S['] -> S .
END_OF_STRING

Marpa::R2::Test::is( $grammar->show_ahms(), $expected_ahfa_output,
    'Leo166 AHFA' );

my $length = 20;

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

my $i                 = 0;
my $latest_earley_set = $recce->latest_earley_set();
my $max_size          = $recce->earley_set_size($latest_earley_set);
TOKEN: while ( $i++ < $length ) {
    $recce->read( 'a', 'a' );
    $latest_earley_set = $recce->latest_earley_set();
    my $size = $recce->earley_set_size($latest_earley_set);

    $max_size = $size > $max_size ? $size : $max_size;
} ## end while ( $i++ < $length )

# Note that the length formula only works
# beginning with Earley set c, for some small
# constant c
my $expected_size = 5;
Marpa::R2::Test::is( $max_size, $expected_size, "size $max_size" );

my $show_earley_sets_output = do {
    local $RS = undef;
## no critic(Subroutines::ProhibitCallsToUndeclaredSubs)
    <DATA>;
};

Marpa::R2::Test::is( $recce->show_earley_sets(1),
    $show_earley_sets_output, 'Leo cycle Earley sets' );

my $value_ref = $recce->value();
my $value = $value_ref ? ${$value_ref} : 'No parse';
Marpa::R2::Test::is( $value, 'a' x $length, 'Leo cycle parse' );

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
S2@0-1 [p=S1@0-0; s=a; t=\'a']
S5@0-1 [p=S1@0-0; s=a; t=\'a']
S14@0-1 [p=S0@0-0; c=S5@0-1]
S3@1-1
L1@1 ["S"; L5@1; S3@1-1]
L3@1 ["A"; S2@0-1]
L5@1 ["H"; L17@1; S3@1-1]
L7@1 ["B"; L3@1; S3@1-1]
L9@1 ["C"; L7@1; S3@1-1]
L11@1 ["D"; L9@1; S3@1-1]
L13@1 ["E"; L11@1; S3@1-1]
L15@1 ["F"; L13@1; S3@1-1]
L17@1 ["G"; L15@1; S3@1-1]
Earley Set 2
S4@0-2 [l=L1@1; c=S5@1-2]
S14@0-2 [p=S0@0-0; c=S4@0-2]
S2@1-2 [p=S3@1-1; s=a; t=\'a']
S5@1-2 [p=S3@1-1; s=a; t=\'a']
S3@2-2
L1@2 ["S"; L5@2; S3@2-2]
L3@2 ["A"; L1@1; S2@1-2]
L5@2 ["H"; L17@2; S3@2-2]
L7@2 ["B"; L3@2; S3@2-2]
L9@2 ["C"; L7@2; S3@2-2]
L11@2 ["D"; L9@2; S3@2-2]
L13@2 ["E"; L11@2; S3@2-2]
L15@2 ["F"; L13@2; S3@2-2]
L17@2 ["G"; L15@2; S3@2-2]
Earley Set 3
S4@0-3 [l=L1@2; c=S5@2-3]
S14@0-3 [p=S0@0-0; c=S4@0-3]
S2@2-3 [p=S3@2-2; s=a; t=\'a']
S5@2-3 [p=S3@2-2; s=a; t=\'a']
S3@3-3
L1@3 ["S"; L5@3; S3@3-3]
L3@3 ["A"; L1@2; S2@2-3]
L5@3 ["H"; L17@3; S3@3-3]
L7@3 ["B"; L3@3; S3@3-3]
L9@3 ["C"; L7@3; S3@3-3]
L11@3 ["D"; L9@3; S3@3-3]
L13@3 ["E"; L11@3; S3@3-3]
L15@3 ["F"; L13@3; S3@3-3]
L17@3 ["G"; L15@3; S3@3-3]
Earley Set 4
S4@0-4 [l=L1@3; c=S5@3-4]
S14@0-4 [p=S0@0-0; c=S4@0-4]
S2@3-4 [p=S3@3-3; s=a; t=\'a']
S5@3-4 [p=S3@3-3; s=a; t=\'a']
S3@4-4
L1@4 ["S"; L5@4; S3@4-4]
L3@4 ["A"; L1@3; S2@3-4]
L5@4 ["H"; L17@4; S3@4-4]
L7@4 ["B"; L3@4; S3@4-4]
L9@4 ["C"; L7@4; S3@4-4]
L11@4 ["D"; L9@4; S3@4-4]
L13@4 ["E"; L11@4; S3@4-4]
L15@4 ["F"; L13@4; S3@4-4]
L17@4 ["G"; L15@4; S3@4-4]
Earley Set 5
S4@0-5 [l=L1@4; c=S5@4-5]
S14@0-5 [p=S0@0-0; c=S4@0-5]
S2@4-5 [p=S3@4-4; s=a; t=\'a']
S5@4-5 [p=S3@4-4; s=a; t=\'a']
S3@5-5
L1@5 ["S"; L5@5; S3@5-5]
L3@5 ["A"; L1@4; S2@4-5]
L5@5 ["H"; L17@5; S3@5-5]
L7@5 ["B"; L3@5; S3@5-5]
L9@5 ["C"; L7@5; S3@5-5]
L11@5 ["D"; L9@5; S3@5-5]
L13@5 ["E"; L11@5; S3@5-5]
L15@5 ["F"; L13@5; S3@5-5]
L17@5 ["G"; L15@5; S3@5-5]
Earley Set 6
S4@0-6 [l=L1@5; c=S5@5-6]
S14@0-6 [p=S0@0-0; c=S4@0-6]
S2@5-6 [p=S3@5-5; s=a; t=\'a']
S5@5-6 [p=S3@5-5; s=a; t=\'a']
S3@6-6
L1@6 ["S"; L5@6; S3@6-6]
L3@6 ["A"; L1@5; S2@5-6]
L5@6 ["H"; L17@6; S3@6-6]
L7@6 ["B"; L3@6; S3@6-6]
L9@6 ["C"; L7@6; S3@6-6]
L11@6 ["D"; L9@6; S3@6-6]
L13@6 ["E"; L11@6; S3@6-6]
L15@6 ["F"; L13@6; S3@6-6]
L17@6 ["G"; L15@6; S3@6-6]
Earley Set 7
S4@0-7 [l=L1@6; c=S5@6-7]
S14@0-7 [p=S0@0-0; c=S4@0-7]
S2@6-7 [p=S3@6-6; s=a; t=\'a']
S5@6-7 [p=S3@6-6; s=a; t=\'a']
S3@7-7
L1@7 ["S"; L5@7; S3@7-7]
L3@7 ["A"; L1@6; S2@6-7]
L5@7 ["H"; L17@7; S3@7-7]
L7@7 ["B"; L3@7; S3@7-7]
L9@7 ["C"; L7@7; S3@7-7]
L11@7 ["D"; L9@7; S3@7-7]
L13@7 ["E"; L11@7; S3@7-7]
L15@7 ["F"; L13@7; S3@7-7]
L17@7 ["G"; L15@7; S3@7-7]
Earley Set 8
S4@0-8 [l=L1@7; c=S5@7-8]
S14@0-8 [p=S0@0-0; c=S4@0-8]
S2@7-8 [p=S3@7-7; s=a; t=\'a']
S5@7-8 [p=S3@7-7; s=a; t=\'a']
S3@8-8
L1@8 ["S"; L5@8; S3@8-8]
L3@8 ["A"; L1@7; S2@7-8]
L5@8 ["H"; L17@8; S3@8-8]
L7@8 ["B"; L3@8; S3@8-8]
L9@8 ["C"; L7@8; S3@8-8]
L11@8 ["D"; L9@8; S3@8-8]
L13@8 ["E"; L11@8; S3@8-8]
L15@8 ["F"; L13@8; S3@8-8]
L17@8 ["G"; L15@8; S3@8-8]
Earley Set 9
S4@0-9 [l=L1@8; c=S5@8-9]
S14@0-9 [p=S0@0-0; c=S4@0-9]
S2@8-9 [p=S3@8-8; s=a; t=\'a']
S5@8-9 [p=S3@8-8; s=a; t=\'a']
S3@9-9
L1@9 ["S"; L5@9; S3@9-9]
L3@9 ["A"; L1@8; S2@8-9]
L5@9 ["H"; L17@9; S3@9-9]
L7@9 ["B"; L3@9; S3@9-9]
L9@9 ["C"; L7@9; S3@9-9]
L11@9 ["D"; L9@9; S3@9-9]
L13@9 ["E"; L11@9; S3@9-9]
L15@9 ["F"; L13@9; S3@9-9]
L17@9 ["G"; L15@9; S3@9-9]
Earley Set 10
S4@0-10 [l=L1@9; c=S5@9-10]
S14@0-10 [p=S0@0-0; c=S4@0-10]
S2@9-10 [p=S3@9-9; s=a; t=\'a']
S5@9-10 [p=S3@9-9; s=a; t=\'a']
S3@10-10
L1@10 ["S"; L5@10; S3@10-10]
L3@10 ["A"; L1@9; S2@9-10]
L5@10 ["H"; L17@10; S3@10-10]
L7@10 ["B"; L3@10; S3@10-10]
L9@10 ["C"; L7@10; S3@10-10]
L11@10 ["D"; L9@10; S3@10-10]
L13@10 ["E"; L11@10; S3@10-10]
L15@10 ["F"; L13@10; S3@10-10]
L17@10 ["G"; L15@10; S3@10-10]
Earley Set 11
S4@0-11 [l=L1@10; c=S5@10-11]
S14@0-11 [p=S0@0-0; c=S4@0-11]
S2@10-11 [p=S3@10-10; s=a; t=\'a']
S5@10-11 [p=S3@10-10; s=a; t=\'a']
S3@11-11
L1@11 ["S"; L5@11; S3@11-11]
L3@11 ["A"; L1@10; S2@10-11]
L5@11 ["H"; L17@11; S3@11-11]
L7@11 ["B"; L3@11; S3@11-11]
L9@11 ["C"; L7@11; S3@11-11]
L11@11 ["D"; L9@11; S3@11-11]
L13@11 ["E"; L11@11; S3@11-11]
L15@11 ["F"; L13@11; S3@11-11]
L17@11 ["G"; L15@11; S3@11-11]
Earley Set 12
S4@0-12 [l=L1@11; c=S5@11-12]
S14@0-12 [p=S0@0-0; c=S4@0-12]
S2@11-12 [p=S3@11-11; s=a; t=\'a']
S5@11-12 [p=S3@11-11; s=a; t=\'a']
S3@12-12
L1@12 ["S"; L5@12; S3@12-12]
L3@12 ["A"; L1@11; S2@11-12]
L5@12 ["H"; L17@12; S3@12-12]
L7@12 ["B"; L3@12; S3@12-12]
L9@12 ["C"; L7@12; S3@12-12]
L11@12 ["D"; L9@12; S3@12-12]
L13@12 ["E"; L11@12; S3@12-12]
L15@12 ["F"; L13@12; S3@12-12]
L17@12 ["G"; L15@12; S3@12-12]
Earley Set 13
S4@0-13 [l=L1@12; c=S5@12-13]
S14@0-13 [p=S0@0-0; c=S4@0-13]
S2@12-13 [p=S3@12-12; s=a; t=\'a']
S5@12-13 [p=S3@12-12; s=a; t=\'a']
S3@13-13
L1@13 ["S"; L5@13; S3@13-13]
L3@13 ["A"; L1@12; S2@12-13]
L5@13 ["H"; L17@13; S3@13-13]
L7@13 ["B"; L3@13; S3@13-13]
L9@13 ["C"; L7@13; S3@13-13]
L11@13 ["D"; L9@13; S3@13-13]
L13@13 ["E"; L11@13; S3@13-13]
L15@13 ["F"; L13@13; S3@13-13]
L17@13 ["G"; L15@13; S3@13-13]
Earley Set 14
S4@0-14 [l=L1@13; c=S5@13-14]
S14@0-14 [p=S0@0-0; c=S4@0-14]
S2@13-14 [p=S3@13-13; s=a; t=\'a']
S5@13-14 [p=S3@13-13; s=a; t=\'a']
S3@14-14
L1@14 ["S"; L5@14; S3@14-14]
L3@14 ["A"; L1@13; S2@13-14]
L5@14 ["H"; L17@14; S3@14-14]
L7@14 ["B"; L3@14; S3@14-14]
L9@14 ["C"; L7@14; S3@14-14]
L11@14 ["D"; L9@14; S3@14-14]
L13@14 ["E"; L11@14; S3@14-14]
L15@14 ["F"; L13@14; S3@14-14]
L17@14 ["G"; L15@14; S3@14-14]
Earley Set 15
S4@0-15 [l=L1@14; c=S5@14-15]
S14@0-15 [p=S0@0-0; c=S4@0-15]
S2@14-15 [p=S3@14-14; s=a; t=\'a']
S5@14-15 [p=S3@14-14; s=a; t=\'a']
S3@15-15
L1@15 ["S"; L5@15; S3@15-15]
L3@15 ["A"; L1@14; S2@14-15]
L5@15 ["H"; L17@15; S3@15-15]
L7@15 ["B"; L3@15; S3@15-15]
L9@15 ["C"; L7@15; S3@15-15]
L11@15 ["D"; L9@15; S3@15-15]
L13@15 ["E"; L11@15; S3@15-15]
L15@15 ["F"; L13@15; S3@15-15]
L17@15 ["G"; L15@15; S3@15-15]
Earley Set 16
S4@0-16 [l=L1@15; c=S5@15-16]
S14@0-16 [p=S0@0-0; c=S4@0-16]
S2@15-16 [p=S3@15-15; s=a; t=\'a']
S5@15-16 [p=S3@15-15; s=a; t=\'a']
S3@16-16
L1@16 ["S"; L5@16; S3@16-16]
L3@16 ["A"; L1@15; S2@15-16]
L5@16 ["H"; L17@16; S3@16-16]
L7@16 ["B"; L3@16; S3@16-16]
L9@16 ["C"; L7@16; S3@16-16]
L11@16 ["D"; L9@16; S3@16-16]
L13@16 ["E"; L11@16; S3@16-16]
L15@16 ["F"; L13@16; S3@16-16]
L17@16 ["G"; L15@16; S3@16-16]
Earley Set 17
S4@0-17 [l=L1@16; c=S5@16-17]
S14@0-17 [p=S0@0-0; c=S4@0-17]
S2@16-17 [p=S3@16-16; s=a; t=\'a']
S5@16-17 [p=S3@16-16; s=a; t=\'a']
S3@17-17
L1@17 ["S"; L5@17; S3@17-17]
L3@17 ["A"; L1@16; S2@16-17]
L5@17 ["H"; L17@17; S3@17-17]
L7@17 ["B"; L3@17; S3@17-17]
L9@17 ["C"; L7@17; S3@17-17]
L11@17 ["D"; L9@17; S3@17-17]
L13@17 ["E"; L11@17; S3@17-17]
L15@17 ["F"; L13@17; S3@17-17]
L17@17 ["G"; L15@17; S3@17-17]
Earley Set 18
S4@0-18 [l=L1@17; c=S5@17-18]
S14@0-18 [p=S0@0-0; c=S4@0-18]
S2@17-18 [p=S3@17-17; s=a; t=\'a']
S5@17-18 [p=S3@17-17; s=a; t=\'a']
S3@18-18
L1@18 ["S"; L5@18; S3@18-18]
L3@18 ["A"; L1@17; S2@17-18]
L5@18 ["H"; L17@18; S3@18-18]
L7@18 ["B"; L3@18; S3@18-18]
L9@18 ["C"; L7@18; S3@18-18]
L11@18 ["D"; L9@18; S3@18-18]
L13@18 ["E"; L11@18; S3@18-18]
L15@18 ["F"; L13@18; S3@18-18]
L17@18 ["G"; L15@18; S3@18-18]
Earley Set 19
S4@0-19 [l=L1@18; c=S5@18-19]
S14@0-19 [p=S0@0-0; c=S4@0-19]
S2@18-19 [p=S3@18-18; s=a; t=\'a']
S5@18-19 [p=S3@18-18; s=a; t=\'a']
S3@19-19
L1@19 ["S"; L5@19; S3@19-19]
L3@19 ["A"; L1@18; S2@18-19]
L5@19 ["H"; L17@19; S3@19-19]
L7@19 ["B"; L3@19; S3@19-19]
L9@19 ["C"; L7@19; S3@19-19]
L11@19 ["D"; L9@19; S3@19-19]
L13@19 ["E"; L11@19; S3@19-19]
L15@19 ["F"; L13@19; S3@19-19]
L17@19 ["G"; L15@19; S3@19-19]
Earley Set 20
S4@0-20 [l=L1@19; c=S5@19-20]
S14@0-20 [p=S0@0-0; c=S4@0-20]
S2@19-20 [p=S3@19-19; s=a; t=\'a']
S5@19-20 [p=S3@19-19; s=a; t=\'a']
S3@20-20
L1@20 ["S"; L5@20; S3@20-20]
L3@20 ["A"; L1@19; S2@19-20]
L5@20 ["H"; L17@20; S3@20-20]
L7@20 ["B"; L3@20; S3@20-20]
L9@20 ["C"; L7@20; S3@20-20]
L11@20 ["D"; L9@20; S3@20-20]
L13@20 ["E"; L11@20; S3@20-20]
L15@20 ["F"; L13@20; S3@20-20]
L17@20 ["G"; L15@20; S3@20-20]
