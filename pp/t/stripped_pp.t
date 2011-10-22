#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::PP.  Marpa::PP is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::PP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::PP.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
use strict;
use warnings;
use Test::More tests => 8;
use lib 'tool/lib';
use Marpa::Test;

BEGIN {

    # Only Pure perl version to be tested
    Test::More::use_ok('Marpa::PP');
}

# The example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630
# This time testing the stripped output

my $g = Marpa::PP::Grammar->new(
    {   start => 'S',
        rules => [
            [ 'S',   [qw/A A A A/] ],
            [ 'A',   [qw/a/] ],
            [ 'A',   [qw/E/] ],
            ['E'],
        ],
    }
);

$g->set( { terminals => ['a'] } );

$g->precompute();

Marpa::Test::is( $g->show_rules, <<'EOS', 'Aycock/Horspool Rules' );
0: S -> A A A A /* stripped !used */
1: A -> a /* stripped */
2: A -> E /* stripped !used */
3: E -> /* empty stripped !used */
4: S -> A S[R0:1] /* stripped vrhs real=1 */
5: S -> A A[] A[] A[] /* stripped */
6: S -> A[] S[R0:1] /* stripped vrhs real=1 */
7: S[R0:1] -> A S[R0:2] /* stripped vlhs vrhs real=1 */
8: S[R0:1] -> A A[] A[] /* stripped vlhs real=3 */
9: S[R0:1] -> A[] S[R0:2] /* stripped vlhs vrhs real=1 */
10: S[R0:2] -> A A /* stripped vlhs real=2 */
11: S[R0:2] -> A A[] /* stripped vlhs real=2 */
12: S[R0:2] -> A[] A /* stripped vlhs real=2 */
13: S['] -> S /* stripped vlhs real=1 */
14: S['][] -> /* empty stripped vlhs real=1 */
EOS

Marpa::Test::is( $g->show_symbols, <<'EOS', 'Aycock/Horspool Symbols' );
0: S, stripped
1: A, stripped
2: a, stripped terminal
3: E, stripped nullable nulling
4: S[], stripped nullable nulling
5: A[], stripped nullable nulling
6: S[R0:1], stripped
7: S[R0:2], stripped
8: S['], stripped
9: S['][], stripped nullable nulling
EOS

Marpa::Test::is( $g->show_nullable_symbols, 'stripped_',
    'Aycock/Horspool Nullable Symbols' );
Marpa::Test::is( $g->show_nulling_symbols, 'stripped_',
    'Aycock/Horspool Nulling Symbols' );
Marpa::Test::is( $g->show_productive_symbols, 'stripped_',
    'Aycock/Horspool Productive Symbols' );
Marpa::Test::is( $g->show_accessible_symbols, 'stripped_',
    'Aycock/Horspool Accessible Symbols' );

Marpa::Test::is( $g->show_NFA, <<'EOS', 'Aycock/Horspool NFA' );
stripped
EOS

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
