#!perl
# Copyright 2011 Jeffrey Kegler
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

use Test::More tests => 4;
use lib 'tool/lib';
use Marpa::R2::Test;

BEGIN {
    Test::More::use_ok('Marpa::R2');
}

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
Added rule #4: Seq0 ->
Added rule #5: Seq0 -> Seq0[a*]
Added rule #6: Seq0[a*] -> a
Added rule #7: Seq0[a*] -> Seq0[a*] a
Added rule #8: Seq1 -> A
Added rule #9: Seq1 -> Seq1[A+]
Added rule #10: Seq1[A+] -> A
Added rule #11: Seq1[A+] -> Seq1[A+] A
Added rule #12: X -> x
Added rule #13: Y -> y
Added rule #14: Z -> z
Added rule #15: A -> y
Added rule #16: Proper ->
Added rule #17: Proper -> p
Added rule #18: S -> Seq0 Seq1
Added rule #19: S -> Seq0[] Seq1
Added rule #20: S -> Proper S[R1:1]
Added rule #21: S -> Proper Proper[] Proper[] Proper[]
Added rule #22: S -> Proper[] S[R1:1]
Added rule #23: S[R1:1] -> Proper S[R1:2]
Added rule #24: S[R1:1] -> Proper Proper[] Proper[]
Added rule #25: S[R1:1] -> Proper[] S[R1:2]
Added rule #26: S[R1:2] -> Proper Proper
Added rule #27: S[R1:2] -> Proper Proper[]
Added rule #28: S[R1:2] -> Proper[] Proper
Added rule #29: S['] -> S
Added rule #30: S['][] ->
EOS

Marpa::R2::Test::is( $grammar->show_rules, <<'EOS', 'Rules' );
0: S -> Seq0 Seq1 /* !used */
1: S -> Proper Proper Proper Proper /* !used */
2: S -> X Y Z
3: Seq0 -> a /* !used */
4: Seq0 -> /* empty !used */
5: Seq0 -> Seq0[a*] /* vrhs real=0 */
6: Seq0[a*] -> a /* vlhs real=1 */
7: Seq0[a*] -> Seq0[a*] a /* vlhs vrhs real=1 */
8: Seq1 -> A /* !used */
9: Seq1 -> Seq1[A+] /* vrhs real=0 */
10: Seq1[A+] -> A /* vlhs real=1 */
11: Seq1[A+] -> Seq1[A+] A /* vlhs vrhs real=1 */
12: X -> x
13: Y -> y
14: Z -> z
15: A -> y
16: Proper -> /* empty !used */
17: Proper -> p
18: S -> Seq0 Seq1
19: S -> Seq0[] Seq1
20: S -> Proper S[R1:1] /* vrhs real=1 */
21: S -> Proper Proper[] Proper[] Proper[]
22: S -> Proper[] S[R1:1] /* vrhs real=1 */
23: S[R1:1] -> Proper S[R1:2] /* vlhs vrhs real=1 */
24: S[R1:1] -> Proper Proper[] Proper[] /* vlhs real=3 */
25: S[R1:1] -> Proper[] S[R1:2] /* vlhs vrhs real=1 */
26: S[R1:2] -> Proper Proper /* vlhs real=2 */
27: S[R1:2] -> Proper Proper[] /* vlhs real=2 */
28: S[R1:2] -> Proper[] Proper /* vlhs real=2 */
29: S['] -> S /* vlhs real=1 */
30: S['][] -> /* empty !used vlhs real=1 */
EOS

Marpa::R2::Test::is( $grammar->show_symbols,
    <<'EOS', 'Symbols' );
0: S, lhs=[0 1 2 18 19 20 21 22] rhs=[29]
1: Seq0, lhs=[3 4 5] rhs=[0 18]
2: Seq1, lhs=[8 9] rhs=[0 18 19]
3: Proper, lhs=[16 17] rhs=[1 20 21 23 24 26 27 28]
4: X, lhs=[12] rhs=[2]
5: Y, lhs=[13] rhs=[2]
6: Z, lhs=[14] rhs=[2]
7: a, lhs=[] rhs=[3 6 7] terminal
8: Seq0[a*], lhs=[6 7] rhs=[5 7]
9: A, lhs=[15] rhs=[8 10 11]
10: Seq1[A+], lhs=[10 11] rhs=[9 11]
11: x, lhs=[] rhs=[12] terminal
12: y, lhs=[] rhs=[13 15] terminal
13: z, lhs=[] rhs=[14] terminal
14: p, lhs=[] rhs=[17] terminal
15: S[], lhs=[] rhs=[] nullable nulling
16: Seq0[], lhs=[] rhs=[19] nullable nulling
17: Proper[], lhs=[] rhs=[21 22 24 25 27 28] nullable nulling
18: S[R1:1], lhs=[23 24 25] rhs=[20 22]
19: S[R1:2], lhs=[26 27 28] rhs=[23 25]
20: S['], lhs=[29] rhs=[]
21: S['][], lhs=[30] rhs=[] nullable nulling
EOS

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
