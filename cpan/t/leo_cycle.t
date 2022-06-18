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

# This is based on the
# example from p. 166 of Leo's paper,
# augmented to test Leo prediction items,
# as well as a long cycle of Leo items

use 5.010001;
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

my $expected_ahms_output = <<'END_OF_STRING';
AHM 0: postdot = "a"
    S ::= . a A
AHM 1: postdot = "A"
    S ::= a . A
AHM 2: completion
    S ::= a A .
AHM 3: postdot = "a"
    S ::= . a A[]
AHM 4: completion
    S ::= a A[] .
AHM 5: postdot = "S"
    H ::= . S
AHM 6: completion
    H ::= S .
AHM 7: postdot = "C"
    B ::= . C
AHM 8: completion
    B ::= C .
AHM 9: postdot = "E"
    D ::= . E
AHM 10: completion
    D ::= E .
AHM 11: postdot = "F"
    E ::= . F
AHM 12: completion
    E ::= F .
AHM 13: postdot = "G"
    F ::= . G
AHM 14: completion
    F ::= G .
AHM 15: postdot = "D"
    C ::= . D
AHM 16: completion
    C ::= D .
AHM 17: postdot = "H"
    G ::= . H
AHM 18: completion
    G ::= H .
AHM 19: postdot = "B"
    A ::= . B
AHM 20: completion
    A ::= B .
AHM 21: postdot = "S"
    S['] ::= . S
AHM 22: completion
    S['] ::= S .
END_OF_STRING

Marpa::R2::Test::is( $grammar->show_ahms(), $expected_ahms_output,
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
my $expected_size = 14;
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
ahm21: R10:0@0-0
  R10:0: S['] ::= . S
ahm0: R0:0@0-0
  R0:0: S ::= . a A
ahm3: R1:0@0-0
  R1:0: S ::= . a A[]
Earley Set 1
ahm4: R1$@0-1
  R1$: S ::= a A[] .
  [c=R1:0@0-0; s=a; t=\'a']
ahm1: R0:1@0-1
  R0:1: S ::= a . A
  [c=R0:0@0-0; s=a; t=\'a']
ahm22: R10$@0-1
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R1$@0-1]
ahm0: R0:0@1-1
  R0:0: S ::= . a A
ahm3: R1:0@1-1
  R1:0: S ::= . a A[]
ahm5: R2:0@1-1
  R2:0: H ::= . S
ahm7: R3:0@1-1
  R3:0: B ::= . C
ahm9: R4:0@1-1
  R4:0: D ::= . E
ahm11: R5:0@1-1
  R5:0: E ::= . F
ahm13: R6:0@1-1
  R6:0: F ::= . G
ahm15: R7:0@1-1
  R7:0: C ::= . D
ahm17: R8:0@1-1
  R8:0: G ::= . H
ahm19: R9:0@1-1
  R9:0: A ::= . B
L1@1 ["S"; L5@1; S5@1-1]
L3@1 ["A"; S1@0-1]
L5@1 ["H"; L17@1; S17@1-1]
L7@1 ["B"; L3@1; S19@1-1]
L9@1 ["C"; L7@1; S7@1-1]
L11@1 ["D"; L9@1; S15@1-1]
L13@1 ["E"; L11@1; S9@1-1]
L15@1 ["F"; L13@1; S11@1-1]
L17@1 ["G"; L15@1; S13@1-1]
Earley Set 2
ahm4: R1$@1-2
  R1$: S ::= a A[] .
  [c=R1:0@1-1; s=a; t=\'a']
ahm1: R0:1@1-2
  R0:1: S ::= a . A
  [c=R0:0@1-1; s=a; t=\'a']
ahm2: R0$@0-2
  R0$: S ::= a A .
  [l=L1@1; c=R1$@1-2]
ahm22: R10$@0-2
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-2]
ahm0: R0:0@2-2
  R0:0: S ::= . a A
ahm3: R1:0@2-2
  R1:0: S ::= . a A[]
ahm5: R2:0@2-2
  R2:0: H ::= . S
ahm7: R3:0@2-2
  R3:0: B ::= . C
ahm9: R4:0@2-2
  R4:0: D ::= . E
ahm11: R5:0@2-2
  R5:0: E ::= . F
ahm13: R6:0@2-2
  R6:0: F ::= . G
ahm15: R7:0@2-2
  R7:0: C ::= . D
ahm17: R8:0@2-2
  R8:0: G ::= . H
ahm19: R9:0@2-2
  R9:0: A ::= . B
L1@2 ["S"; L5@2; S5@2-2]
L3@2 ["A"; L1@1; S1@1-2]
L5@2 ["H"; L17@2; S17@2-2]
L7@2 ["B"; L3@2; S19@2-2]
L9@2 ["C"; L7@2; S7@2-2]
L11@2 ["D"; L9@2; S15@2-2]
L13@2 ["E"; L11@2; S9@2-2]
L15@2 ["F"; L13@2; S11@2-2]
L17@2 ["G"; L15@2; S13@2-2]
Earley Set 3
ahm4: R1$@2-3
  R1$: S ::= a A[] .
  [c=R1:0@2-2; s=a; t=\'a']
ahm1: R0:1@2-3
  R0:1: S ::= a . A
  [c=R0:0@2-2; s=a; t=\'a']
ahm2: R0$@0-3
  R0$: S ::= a A .
  [l=L1@2; c=R1$@2-3]
ahm22: R10$@0-3
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-3]
ahm0: R0:0@3-3
  R0:0: S ::= . a A
ahm3: R1:0@3-3
  R1:0: S ::= . a A[]
ahm5: R2:0@3-3
  R2:0: H ::= . S
ahm7: R3:0@3-3
  R3:0: B ::= . C
ahm9: R4:0@3-3
  R4:0: D ::= . E
ahm11: R5:0@3-3
  R5:0: E ::= . F
ahm13: R6:0@3-3
  R6:0: F ::= . G
ahm15: R7:0@3-3
  R7:0: C ::= . D
ahm17: R8:0@3-3
  R8:0: G ::= . H
ahm19: R9:0@3-3
  R9:0: A ::= . B
L1@3 ["S"; L5@3; S5@3-3]
L3@3 ["A"; L1@2; S1@2-3]
L5@3 ["H"; L17@3; S17@3-3]
L7@3 ["B"; L3@3; S19@3-3]
L9@3 ["C"; L7@3; S7@3-3]
L11@3 ["D"; L9@3; S15@3-3]
L13@3 ["E"; L11@3; S9@3-3]
L15@3 ["F"; L13@3; S11@3-3]
L17@3 ["G"; L15@3; S13@3-3]
Earley Set 4
ahm4: R1$@3-4
  R1$: S ::= a A[] .
  [c=R1:0@3-3; s=a; t=\'a']
ahm1: R0:1@3-4
  R0:1: S ::= a . A
  [c=R0:0@3-3; s=a; t=\'a']
ahm2: R0$@0-4
  R0$: S ::= a A .
  [l=L1@3; c=R1$@3-4]
ahm22: R10$@0-4
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-4]
ahm0: R0:0@4-4
  R0:0: S ::= . a A
ahm3: R1:0@4-4
  R1:0: S ::= . a A[]
ahm5: R2:0@4-4
  R2:0: H ::= . S
ahm7: R3:0@4-4
  R3:0: B ::= . C
ahm9: R4:0@4-4
  R4:0: D ::= . E
ahm11: R5:0@4-4
  R5:0: E ::= . F
ahm13: R6:0@4-4
  R6:0: F ::= . G
ahm15: R7:0@4-4
  R7:0: C ::= . D
ahm17: R8:0@4-4
  R8:0: G ::= . H
ahm19: R9:0@4-4
  R9:0: A ::= . B
L1@4 ["S"; L5@4; S5@4-4]
L3@4 ["A"; L1@3; S1@3-4]
L5@4 ["H"; L17@4; S17@4-4]
L7@4 ["B"; L3@4; S19@4-4]
L9@4 ["C"; L7@4; S7@4-4]
L11@4 ["D"; L9@4; S15@4-4]
L13@4 ["E"; L11@4; S9@4-4]
L15@4 ["F"; L13@4; S11@4-4]
L17@4 ["G"; L15@4; S13@4-4]
Earley Set 5
ahm4: R1$@4-5
  R1$: S ::= a A[] .
  [c=R1:0@4-4; s=a; t=\'a']
ahm1: R0:1@4-5
  R0:1: S ::= a . A
  [c=R0:0@4-4; s=a; t=\'a']
ahm2: R0$@0-5
  R0$: S ::= a A .
  [l=L1@4; c=R1$@4-5]
ahm22: R10$@0-5
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-5]
ahm0: R0:0@5-5
  R0:0: S ::= . a A
ahm3: R1:0@5-5
  R1:0: S ::= . a A[]
ahm5: R2:0@5-5
  R2:0: H ::= . S
ahm7: R3:0@5-5
  R3:0: B ::= . C
ahm9: R4:0@5-5
  R4:0: D ::= . E
ahm11: R5:0@5-5
  R5:0: E ::= . F
ahm13: R6:0@5-5
  R6:0: F ::= . G
ahm15: R7:0@5-5
  R7:0: C ::= . D
ahm17: R8:0@5-5
  R8:0: G ::= . H
ahm19: R9:0@5-5
  R9:0: A ::= . B
L1@5 ["S"; L5@5; S5@5-5]
L3@5 ["A"; L1@4; S1@4-5]
L5@5 ["H"; L17@5; S17@5-5]
L7@5 ["B"; L3@5; S19@5-5]
L9@5 ["C"; L7@5; S7@5-5]
L11@5 ["D"; L9@5; S15@5-5]
L13@5 ["E"; L11@5; S9@5-5]
L15@5 ["F"; L13@5; S11@5-5]
L17@5 ["G"; L15@5; S13@5-5]
Earley Set 6
ahm4: R1$@5-6
  R1$: S ::= a A[] .
  [c=R1:0@5-5; s=a; t=\'a']
ahm1: R0:1@5-6
  R0:1: S ::= a . A
  [c=R0:0@5-5; s=a; t=\'a']
ahm2: R0$@0-6
  R0$: S ::= a A .
  [l=L1@5; c=R1$@5-6]
ahm22: R10$@0-6
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-6]
ahm0: R0:0@6-6
  R0:0: S ::= . a A
ahm3: R1:0@6-6
  R1:0: S ::= . a A[]
ahm5: R2:0@6-6
  R2:0: H ::= . S
ahm7: R3:0@6-6
  R3:0: B ::= . C
ahm9: R4:0@6-6
  R4:0: D ::= . E
ahm11: R5:0@6-6
  R5:0: E ::= . F
ahm13: R6:0@6-6
  R6:0: F ::= . G
ahm15: R7:0@6-6
  R7:0: C ::= . D
ahm17: R8:0@6-6
  R8:0: G ::= . H
ahm19: R9:0@6-6
  R9:0: A ::= . B
L1@6 ["S"; L5@6; S5@6-6]
L3@6 ["A"; L1@5; S1@5-6]
L5@6 ["H"; L17@6; S17@6-6]
L7@6 ["B"; L3@6; S19@6-6]
L9@6 ["C"; L7@6; S7@6-6]
L11@6 ["D"; L9@6; S15@6-6]
L13@6 ["E"; L11@6; S9@6-6]
L15@6 ["F"; L13@6; S11@6-6]
L17@6 ["G"; L15@6; S13@6-6]
Earley Set 7
ahm4: R1$@6-7
  R1$: S ::= a A[] .
  [c=R1:0@6-6; s=a; t=\'a']
ahm1: R0:1@6-7
  R0:1: S ::= a . A
  [c=R0:0@6-6; s=a; t=\'a']
ahm2: R0$@0-7
  R0$: S ::= a A .
  [l=L1@6; c=R1$@6-7]
ahm22: R10$@0-7
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-7]
ahm0: R0:0@7-7
  R0:0: S ::= . a A
ahm3: R1:0@7-7
  R1:0: S ::= . a A[]
ahm5: R2:0@7-7
  R2:0: H ::= . S
ahm7: R3:0@7-7
  R3:0: B ::= . C
ahm9: R4:0@7-7
  R4:0: D ::= . E
ahm11: R5:0@7-7
  R5:0: E ::= . F
ahm13: R6:0@7-7
  R6:0: F ::= . G
ahm15: R7:0@7-7
  R7:0: C ::= . D
ahm17: R8:0@7-7
  R8:0: G ::= . H
ahm19: R9:0@7-7
  R9:0: A ::= . B
L1@7 ["S"; L5@7; S5@7-7]
L3@7 ["A"; L1@6; S1@6-7]
L5@7 ["H"; L17@7; S17@7-7]
L7@7 ["B"; L3@7; S19@7-7]
L9@7 ["C"; L7@7; S7@7-7]
L11@7 ["D"; L9@7; S15@7-7]
L13@7 ["E"; L11@7; S9@7-7]
L15@7 ["F"; L13@7; S11@7-7]
L17@7 ["G"; L15@7; S13@7-7]
Earley Set 8
ahm4: R1$@7-8
  R1$: S ::= a A[] .
  [c=R1:0@7-7; s=a; t=\'a']
ahm1: R0:1@7-8
  R0:1: S ::= a . A
  [c=R0:0@7-7; s=a; t=\'a']
ahm2: R0$@0-8
  R0$: S ::= a A .
  [l=L1@7; c=R1$@7-8]
ahm22: R10$@0-8
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-8]
ahm0: R0:0@8-8
  R0:0: S ::= . a A
ahm3: R1:0@8-8
  R1:0: S ::= . a A[]
ahm5: R2:0@8-8
  R2:0: H ::= . S
ahm7: R3:0@8-8
  R3:0: B ::= . C
ahm9: R4:0@8-8
  R4:0: D ::= . E
ahm11: R5:0@8-8
  R5:0: E ::= . F
ahm13: R6:0@8-8
  R6:0: F ::= . G
ahm15: R7:0@8-8
  R7:0: C ::= . D
ahm17: R8:0@8-8
  R8:0: G ::= . H
ahm19: R9:0@8-8
  R9:0: A ::= . B
L1@8 ["S"; L5@8; S5@8-8]
L3@8 ["A"; L1@7; S1@7-8]
L5@8 ["H"; L17@8; S17@8-8]
L7@8 ["B"; L3@8; S19@8-8]
L9@8 ["C"; L7@8; S7@8-8]
L11@8 ["D"; L9@8; S15@8-8]
L13@8 ["E"; L11@8; S9@8-8]
L15@8 ["F"; L13@8; S11@8-8]
L17@8 ["G"; L15@8; S13@8-8]
Earley Set 9
ahm4: R1$@8-9
  R1$: S ::= a A[] .
  [c=R1:0@8-8; s=a; t=\'a']
ahm1: R0:1@8-9
  R0:1: S ::= a . A
  [c=R0:0@8-8; s=a; t=\'a']
ahm2: R0$@0-9
  R0$: S ::= a A .
  [l=L1@8; c=R1$@8-9]
ahm22: R10$@0-9
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-9]
ahm0: R0:0@9-9
  R0:0: S ::= . a A
ahm3: R1:0@9-9
  R1:0: S ::= . a A[]
ahm5: R2:0@9-9
  R2:0: H ::= . S
ahm7: R3:0@9-9
  R3:0: B ::= . C
ahm9: R4:0@9-9
  R4:0: D ::= . E
ahm11: R5:0@9-9
  R5:0: E ::= . F
ahm13: R6:0@9-9
  R6:0: F ::= . G
ahm15: R7:0@9-9
  R7:0: C ::= . D
ahm17: R8:0@9-9
  R8:0: G ::= . H
ahm19: R9:0@9-9
  R9:0: A ::= . B
L1@9 ["S"; L5@9; S5@9-9]
L3@9 ["A"; L1@8; S1@8-9]
L5@9 ["H"; L17@9; S17@9-9]
L7@9 ["B"; L3@9; S19@9-9]
L9@9 ["C"; L7@9; S7@9-9]
L11@9 ["D"; L9@9; S15@9-9]
L13@9 ["E"; L11@9; S9@9-9]
L15@9 ["F"; L13@9; S11@9-9]
L17@9 ["G"; L15@9; S13@9-9]
Earley Set 10
ahm4: R1$@9-10
  R1$: S ::= a A[] .
  [c=R1:0@9-9; s=a; t=\'a']
ahm1: R0:1@9-10
  R0:1: S ::= a . A
  [c=R0:0@9-9; s=a; t=\'a']
ahm2: R0$@0-10
  R0$: S ::= a A .
  [l=L1@9; c=R1$@9-10]
ahm22: R10$@0-10
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-10]
ahm0: R0:0@10-10
  R0:0: S ::= . a A
ahm3: R1:0@10-10
  R1:0: S ::= . a A[]
ahm5: R2:0@10-10
  R2:0: H ::= . S
ahm7: R3:0@10-10
  R3:0: B ::= . C
ahm9: R4:0@10-10
  R4:0: D ::= . E
ahm11: R5:0@10-10
  R5:0: E ::= . F
ahm13: R6:0@10-10
  R6:0: F ::= . G
ahm15: R7:0@10-10
  R7:0: C ::= . D
ahm17: R8:0@10-10
  R8:0: G ::= . H
ahm19: R9:0@10-10
  R9:0: A ::= . B
L1@10 ["S"; L5@10; S5@10-10]
L3@10 ["A"; L1@9; S1@9-10]
L5@10 ["H"; L17@10; S17@10-10]
L7@10 ["B"; L3@10; S19@10-10]
L9@10 ["C"; L7@10; S7@10-10]
L11@10 ["D"; L9@10; S15@10-10]
L13@10 ["E"; L11@10; S9@10-10]
L15@10 ["F"; L13@10; S11@10-10]
L17@10 ["G"; L15@10; S13@10-10]
Earley Set 11
ahm4: R1$@10-11
  R1$: S ::= a A[] .
  [c=R1:0@10-10; s=a; t=\'a']
ahm1: R0:1@10-11
  R0:1: S ::= a . A
  [c=R0:0@10-10; s=a; t=\'a']
ahm2: R0$@0-11
  R0$: S ::= a A .
  [l=L1@10; c=R1$@10-11]
ahm22: R10$@0-11
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-11]
ahm0: R0:0@11-11
  R0:0: S ::= . a A
ahm3: R1:0@11-11
  R1:0: S ::= . a A[]
ahm5: R2:0@11-11
  R2:0: H ::= . S
ahm7: R3:0@11-11
  R3:0: B ::= . C
ahm9: R4:0@11-11
  R4:0: D ::= . E
ahm11: R5:0@11-11
  R5:0: E ::= . F
ahm13: R6:0@11-11
  R6:0: F ::= . G
ahm15: R7:0@11-11
  R7:0: C ::= . D
ahm17: R8:0@11-11
  R8:0: G ::= . H
ahm19: R9:0@11-11
  R9:0: A ::= . B
L1@11 ["S"; L5@11; S5@11-11]
L3@11 ["A"; L1@10; S1@10-11]
L5@11 ["H"; L17@11; S17@11-11]
L7@11 ["B"; L3@11; S19@11-11]
L9@11 ["C"; L7@11; S7@11-11]
L11@11 ["D"; L9@11; S15@11-11]
L13@11 ["E"; L11@11; S9@11-11]
L15@11 ["F"; L13@11; S11@11-11]
L17@11 ["G"; L15@11; S13@11-11]
Earley Set 12
ahm4: R1$@11-12
  R1$: S ::= a A[] .
  [c=R1:0@11-11; s=a; t=\'a']
ahm1: R0:1@11-12
  R0:1: S ::= a . A
  [c=R0:0@11-11; s=a; t=\'a']
ahm2: R0$@0-12
  R0$: S ::= a A .
  [l=L1@11; c=R1$@11-12]
ahm22: R10$@0-12
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-12]
ahm0: R0:0@12-12
  R0:0: S ::= . a A
ahm3: R1:0@12-12
  R1:0: S ::= . a A[]
ahm5: R2:0@12-12
  R2:0: H ::= . S
ahm7: R3:0@12-12
  R3:0: B ::= . C
ahm9: R4:0@12-12
  R4:0: D ::= . E
ahm11: R5:0@12-12
  R5:0: E ::= . F
ahm13: R6:0@12-12
  R6:0: F ::= . G
ahm15: R7:0@12-12
  R7:0: C ::= . D
ahm17: R8:0@12-12
  R8:0: G ::= . H
ahm19: R9:0@12-12
  R9:0: A ::= . B
L1@12 ["S"; L5@12; S5@12-12]
L3@12 ["A"; L1@11; S1@11-12]
L5@12 ["H"; L17@12; S17@12-12]
L7@12 ["B"; L3@12; S19@12-12]
L9@12 ["C"; L7@12; S7@12-12]
L11@12 ["D"; L9@12; S15@12-12]
L13@12 ["E"; L11@12; S9@12-12]
L15@12 ["F"; L13@12; S11@12-12]
L17@12 ["G"; L15@12; S13@12-12]
Earley Set 13
ahm4: R1$@12-13
  R1$: S ::= a A[] .
  [c=R1:0@12-12; s=a; t=\'a']
ahm1: R0:1@12-13
  R0:1: S ::= a . A
  [c=R0:0@12-12; s=a; t=\'a']
ahm2: R0$@0-13
  R0$: S ::= a A .
  [l=L1@12; c=R1$@12-13]
ahm22: R10$@0-13
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-13]
ahm0: R0:0@13-13
  R0:0: S ::= . a A
ahm3: R1:0@13-13
  R1:0: S ::= . a A[]
ahm5: R2:0@13-13
  R2:0: H ::= . S
ahm7: R3:0@13-13
  R3:0: B ::= . C
ahm9: R4:0@13-13
  R4:0: D ::= . E
ahm11: R5:0@13-13
  R5:0: E ::= . F
ahm13: R6:0@13-13
  R6:0: F ::= . G
ahm15: R7:0@13-13
  R7:0: C ::= . D
ahm17: R8:0@13-13
  R8:0: G ::= . H
ahm19: R9:0@13-13
  R9:0: A ::= . B
L1@13 ["S"; L5@13; S5@13-13]
L3@13 ["A"; L1@12; S1@12-13]
L5@13 ["H"; L17@13; S17@13-13]
L7@13 ["B"; L3@13; S19@13-13]
L9@13 ["C"; L7@13; S7@13-13]
L11@13 ["D"; L9@13; S15@13-13]
L13@13 ["E"; L11@13; S9@13-13]
L15@13 ["F"; L13@13; S11@13-13]
L17@13 ["G"; L15@13; S13@13-13]
Earley Set 14
ahm4: R1$@13-14
  R1$: S ::= a A[] .
  [c=R1:0@13-13; s=a; t=\'a']
ahm1: R0:1@13-14
  R0:1: S ::= a . A
  [c=R0:0@13-13; s=a; t=\'a']
ahm2: R0$@0-14
  R0$: S ::= a A .
  [l=L1@13; c=R1$@13-14]
ahm22: R10$@0-14
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-14]
ahm0: R0:0@14-14
  R0:0: S ::= . a A
ahm3: R1:0@14-14
  R1:0: S ::= . a A[]
ahm5: R2:0@14-14
  R2:0: H ::= . S
ahm7: R3:0@14-14
  R3:0: B ::= . C
ahm9: R4:0@14-14
  R4:0: D ::= . E
ahm11: R5:0@14-14
  R5:0: E ::= . F
ahm13: R6:0@14-14
  R6:0: F ::= . G
ahm15: R7:0@14-14
  R7:0: C ::= . D
ahm17: R8:0@14-14
  R8:0: G ::= . H
ahm19: R9:0@14-14
  R9:0: A ::= . B
L1@14 ["S"; L5@14; S5@14-14]
L3@14 ["A"; L1@13; S1@13-14]
L5@14 ["H"; L17@14; S17@14-14]
L7@14 ["B"; L3@14; S19@14-14]
L9@14 ["C"; L7@14; S7@14-14]
L11@14 ["D"; L9@14; S15@14-14]
L13@14 ["E"; L11@14; S9@14-14]
L15@14 ["F"; L13@14; S11@14-14]
L17@14 ["G"; L15@14; S13@14-14]
Earley Set 15
ahm4: R1$@14-15
  R1$: S ::= a A[] .
  [c=R1:0@14-14; s=a; t=\'a']
ahm1: R0:1@14-15
  R0:1: S ::= a . A
  [c=R0:0@14-14; s=a; t=\'a']
ahm2: R0$@0-15
  R0$: S ::= a A .
  [l=L1@14; c=R1$@14-15]
ahm22: R10$@0-15
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-15]
ahm0: R0:0@15-15
  R0:0: S ::= . a A
ahm3: R1:0@15-15
  R1:0: S ::= . a A[]
ahm5: R2:0@15-15
  R2:0: H ::= . S
ahm7: R3:0@15-15
  R3:0: B ::= . C
ahm9: R4:0@15-15
  R4:0: D ::= . E
ahm11: R5:0@15-15
  R5:0: E ::= . F
ahm13: R6:0@15-15
  R6:0: F ::= . G
ahm15: R7:0@15-15
  R7:0: C ::= . D
ahm17: R8:0@15-15
  R8:0: G ::= . H
ahm19: R9:0@15-15
  R9:0: A ::= . B
L1@15 ["S"; L5@15; S5@15-15]
L3@15 ["A"; L1@14; S1@14-15]
L5@15 ["H"; L17@15; S17@15-15]
L7@15 ["B"; L3@15; S19@15-15]
L9@15 ["C"; L7@15; S7@15-15]
L11@15 ["D"; L9@15; S15@15-15]
L13@15 ["E"; L11@15; S9@15-15]
L15@15 ["F"; L13@15; S11@15-15]
L17@15 ["G"; L15@15; S13@15-15]
Earley Set 16
ahm4: R1$@15-16
  R1$: S ::= a A[] .
  [c=R1:0@15-15; s=a; t=\'a']
ahm1: R0:1@15-16
  R0:1: S ::= a . A
  [c=R0:0@15-15; s=a; t=\'a']
ahm2: R0$@0-16
  R0$: S ::= a A .
  [l=L1@15; c=R1$@15-16]
ahm22: R10$@0-16
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-16]
ahm0: R0:0@16-16
  R0:0: S ::= . a A
ahm3: R1:0@16-16
  R1:0: S ::= . a A[]
ahm5: R2:0@16-16
  R2:0: H ::= . S
ahm7: R3:0@16-16
  R3:0: B ::= . C
ahm9: R4:0@16-16
  R4:0: D ::= . E
ahm11: R5:0@16-16
  R5:0: E ::= . F
ahm13: R6:0@16-16
  R6:0: F ::= . G
ahm15: R7:0@16-16
  R7:0: C ::= . D
ahm17: R8:0@16-16
  R8:0: G ::= . H
ahm19: R9:0@16-16
  R9:0: A ::= . B
L1@16 ["S"; L5@16; S5@16-16]
L3@16 ["A"; L1@15; S1@15-16]
L5@16 ["H"; L17@16; S17@16-16]
L7@16 ["B"; L3@16; S19@16-16]
L9@16 ["C"; L7@16; S7@16-16]
L11@16 ["D"; L9@16; S15@16-16]
L13@16 ["E"; L11@16; S9@16-16]
L15@16 ["F"; L13@16; S11@16-16]
L17@16 ["G"; L15@16; S13@16-16]
Earley Set 17
ahm4: R1$@16-17
  R1$: S ::= a A[] .
  [c=R1:0@16-16; s=a; t=\'a']
ahm1: R0:1@16-17
  R0:1: S ::= a . A
  [c=R0:0@16-16; s=a; t=\'a']
ahm2: R0$@0-17
  R0$: S ::= a A .
  [l=L1@16; c=R1$@16-17]
ahm22: R10$@0-17
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-17]
ahm0: R0:0@17-17
  R0:0: S ::= . a A
ahm3: R1:0@17-17
  R1:0: S ::= . a A[]
ahm5: R2:0@17-17
  R2:0: H ::= . S
ahm7: R3:0@17-17
  R3:0: B ::= . C
ahm9: R4:0@17-17
  R4:0: D ::= . E
ahm11: R5:0@17-17
  R5:0: E ::= . F
ahm13: R6:0@17-17
  R6:0: F ::= . G
ahm15: R7:0@17-17
  R7:0: C ::= . D
ahm17: R8:0@17-17
  R8:0: G ::= . H
ahm19: R9:0@17-17
  R9:0: A ::= . B
L1@17 ["S"; L5@17; S5@17-17]
L3@17 ["A"; L1@16; S1@16-17]
L5@17 ["H"; L17@17; S17@17-17]
L7@17 ["B"; L3@17; S19@17-17]
L9@17 ["C"; L7@17; S7@17-17]
L11@17 ["D"; L9@17; S15@17-17]
L13@17 ["E"; L11@17; S9@17-17]
L15@17 ["F"; L13@17; S11@17-17]
L17@17 ["G"; L15@17; S13@17-17]
Earley Set 18
ahm4: R1$@17-18
  R1$: S ::= a A[] .
  [c=R1:0@17-17; s=a; t=\'a']
ahm1: R0:1@17-18
  R0:1: S ::= a . A
  [c=R0:0@17-17; s=a; t=\'a']
ahm2: R0$@0-18
  R0$: S ::= a A .
  [l=L1@17; c=R1$@17-18]
ahm22: R10$@0-18
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-18]
ahm0: R0:0@18-18
  R0:0: S ::= . a A
ahm3: R1:0@18-18
  R1:0: S ::= . a A[]
ahm5: R2:0@18-18
  R2:0: H ::= . S
ahm7: R3:0@18-18
  R3:0: B ::= . C
ahm9: R4:0@18-18
  R4:0: D ::= . E
ahm11: R5:0@18-18
  R5:0: E ::= . F
ahm13: R6:0@18-18
  R6:0: F ::= . G
ahm15: R7:0@18-18
  R7:0: C ::= . D
ahm17: R8:0@18-18
  R8:0: G ::= . H
ahm19: R9:0@18-18
  R9:0: A ::= . B
L1@18 ["S"; L5@18; S5@18-18]
L3@18 ["A"; L1@17; S1@17-18]
L5@18 ["H"; L17@18; S17@18-18]
L7@18 ["B"; L3@18; S19@18-18]
L9@18 ["C"; L7@18; S7@18-18]
L11@18 ["D"; L9@18; S15@18-18]
L13@18 ["E"; L11@18; S9@18-18]
L15@18 ["F"; L13@18; S11@18-18]
L17@18 ["G"; L15@18; S13@18-18]
Earley Set 19
ahm4: R1$@18-19
  R1$: S ::= a A[] .
  [c=R1:0@18-18; s=a; t=\'a']
ahm1: R0:1@18-19
  R0:1: S ::= a . A
  [c=R0:0@18-18; s=a; t=\'a']
ahm2: R0$@0-19
  R0$: S ::= a A .
  [l=L1@18; c=R1$@18-19]
ahm22: R10$@0-19
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-19]
ahm0: R0:0@19-19
  R0:0: S ::= . a A
ahm3: R1:0@19-19
  R1:0: S ::= . a A[]
ahm5: R2:0@19-19
  R2:0: H ::= . S
ahm7: R3:0@19-19
  R3:0: B ::= . C
ahm9: R4:0@19-19
  R4:0: D ::= . E
ahm11: R5:0@19-19
  R5:0: E ::= . F
ahm13: R6:0@19-19
  R6:0: F ::= . G
ahm15: R7:0@19-19
  R7:0: C ::= . D
ahm17: R8:0@19-19
  R8:0: G ::= . H
ahm19: R9:0@19-19
  R9:0: A ::= . B
L1@19 ["S"; L5@19; S5@19-19]
L3@19 ["A"; L1@18; S1@18-19]
L5@19 ["H"; L17@19; S17@19-19]
L7@19 ["B"; L3@19; S19@19-19]
L9@19 ["C"; L7@19; S7@19-19]
L11@19 ["D"; L9@19; S15@19-19]
L13@19 ["E"; L11@19; S9@19-19]
L15@19 ["F"; L13@19; S11@19-19]
L17@19 ["G"; L15@19; S13@19-19]
Earley Set 20
ahm4: R1$@19-20
  R1$: S ::= a A[] .
  [c=R1:0@19-19; s=a; t=\'a']
ahm1: R0:1@19-20
  R0:1: S ::= a . A
  [c=R0:0@19-19; s=a; t=\'a']
ahm2: R0$@0-20
  R0$: S ::= a A .
  [l=L1@19; c=R1$@19-20]
ahm22: R10$@0-20
  R10$: S['] ::= S .
  [p=R10:0@0-0; c=R0$@0-20]
ahm0: R0:0@20-20
  R0:0: S ::= . a A
ahm3: R1:0@20-20
  R1:0: S ::= . a A[]
ahm5: R2:0@20-20
  R2:0: H ::= . S
ahm7: R3:0@20-20
  R3:0: B ::= . C
ahm9: R4:0@20-20
  R4:0: D ::= . E
ahm11: R5:0@20-20
  R5:0: E ::= . F
ahm13: R6:0@20-20
  R6:0: F ::= . G
ahm15: R7:0@20-20
  R7:0: C ::= . D
ahm17: R8:0@20-20
  R8:0: G ::= . H
ahm19: R9:0@20-20
  R9:0: A ::= . B
L1@20 ["S"; L5@20; S5@20-20]
L3@20 ["A"; L1@19; S1@19-20]
L5@20 ["H"; L17@20; S17@20-20]
L7@20 ["B"; L3@20; S19@20-20]
L9@20 ["C"; L7@20; S7@20-20]
L11@20 ["D"; L9@20; S15@20-20]
L13@20 ["E"; L11@20; S9@20-20]
L15@20 ["F"; L13@20; S11@20-20]
L17@20 ["G"; L15@20; S13@20-20]
