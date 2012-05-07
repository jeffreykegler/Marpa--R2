#!perl
# Copyright 2012 Jeffrey Kegler
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

use Test::More tests => 3;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $trace_output;
open my $trace_fh, q{>}, \$trace_output;

my $grammar = Marpa::R2::Grammar->new(
    {   trace_file_handle => $trace_fh,
        trace_rules       => 1,
        start             => 'S',
        rules             => [
            [ S      => [qw/Seq0 Seq1/] ],
            [ S      => [qw/Proper Proper Proper Proper/] ],
            [ S      => [qw/X Y Z/] ],
            { lhs    => 'Seq0', rhs => [qw/a/], min => 0 },
            { lhs    => 'Seq1', rhs => [qw/A/], min => 1 },
            [ X      => [qw/x/] ],
            [ Y      => [qw/y/] ],
            [ Z      => [qw/z/] ],
            [ A      => [qw/y/] ],
            [ Proper => [] ],
            [ Proper => [qw(p)] ],
        ],
    }
);

$grammar->set( { terminals => [qw(x y z a p)] } );

$grammar->precompute();

Marpa::R2::Test::is( $trace_output, <<'EOS', 'Trace Output' );
Setting trace_rules
Added rule #0: S -> Seq0 Seq1
Added rule #1: S -> Proper Proper Proper Proper
Added rule #2: S -> X Y Z
Added rule #3: Seq0 -> a
Added rule #4: Seq1 -> A
Added rule #5: X -> x
Added rule #6: Y -> y
Added rule #7: Z -> z
Added rule #8: A -> y
Added rule #9: Proper ->
Added rule #10: Proper -> p
Added rule #11: S -> Seq0 Seq1
Added rule #12: S -> Seq0[] Seq1
Added rule #13: S -> Proper S[R1:1]
Added rule #14: S -> Proper Proper[] Proper[] Proper[]
Added rule #15: S -> Proper[] S[R1:1]
Added rule #16: S[R1:1] -> Proper S[R1:2]
Added rule #17: S[R1:1] -> Proper Proper[] Proper[]
Added rule #18: S[R1:1] -> Proper[] S[R1:2]
Added rule #19: S[R1:2] -> Proper Proper
Added rule #20: S[R1:2] -> Proper Proper[]
Added rule #21: S[R1:2] -> Proper[] Proper
Added rule #22: Seq0 -> Seq0[Seq]
Added rule #23: Seq0[Seq] -> a
Added rule #24: Seq0[Seq] -> Seq0[Seq] a
Added rule #25: Seq1 -> Seq1[Seq]
Added rule #26: Seq1[Seq] -> A
Added rule #27: Seq1[Seq] -> Seq1[Seq] A
Added rule #28: S['] -> S
EOS

Marpa::R2::Test::is( $grammar->show_symbols,
    <<'EOS', 'Symbols' );
0: S
1: Seq0
2: Seq1
3: Proper
4: X
5: Y
6: Z
7: a, terminal
8: A
9: x, terminal
10: y, terminal
11: z, terminal
12: p, terminal
13: S[], nulling
14: Seq0[], nulling
15: Proper[], nulling
16: S[R1:1]
17: S[R1:2]
18: Seq0[Seq], unproductive inaccessible
19: Seq1[Seq], unproductive inaccessible
20: S[']
EOS

Marpa::R2::Test::is( $grammar->show_rules, <<'EOS', 'Rules' );
0: S -> Seq0 Seq1
1: S -> Proper Proper Proper Proper
2: S -> X Y Z
3: Seq0 -> a
4: Seq1 -> A
5: X -> x
6: Y -> y
7: Z -> z
8: A -> y
9: Proper -> /* empty !used */
10: Proper -> p
11: S -> Seq0 Seq1
12: S -> Seq0[] Seq1
13: S -> Proper S[R1:1]
14: S -> Proper Proper[] Proper[] Proper[]
15: S -> Proper[] S[R1:1]
16: S[R1:1] -> Proper S[R1:2]
17: S[R1:1] -> Proper Proper[] Proper[]
18: S[R1:1] -> Proper[] S[R1:2]
19: S[R1:2] -> Proper Proper
20: S[R1:2] -> Proper Proper[]
21: S[R1:2] -> Proper[] Proper
22: Seq0 -> Seq0[Seq]
23: Seq0[Seq] -> a
24: Seq0[Seq] -> Seq0[Seq] a
25: Seq1 -> Seq1[Seq]
26: Seq1[Seq] -> A
27: Seq1[Seq] -> Seq1[Seq] A
28: S['] -> S
EOS

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
