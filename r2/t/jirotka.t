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
# An ambiguous equation

use 5.010;
use strict;
use warnings;

use Test::More tests => 9;

use lib 'tool/lib';
use Marpa::R2::Test;

use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw( close open );

BEGIN {
    Test::More::use_ok('Marpa::R2');
}

# Regression test for bug originally found and documented
# by Tomas Jirotka

## INPUT DATA
my $tokens = [
    [ 'CREATE',    'Create' ],
    [ 'METRIC',    'Metric' ],
    [ 'ID_METRIC', 'm' ],
    [ 'AS',        'As' ],
    [ 'SELECT',    'Select' ],
    [ 'NUMBER',    1 ],
    [ 'WHERE',     'Where' ],
    [ 'TRUE',      'True' ],
];

my @terminals =
    qw/AS BY CREATE FALSE FOR METRIC PF SELECT TRUE WHERE WITH ID_METRIC SEPARATOR NUMBER/;
my $grammar = Marpa::R2::Grammar->new(
    {   start          => 'Input',
        action_object  => 'Maql_Actions',
        default_action => 'tisk',
        terminals      => \@terminals,
        rules          => [
            {   lhs       => 'Input',
                rhs       => ['Statement'],
                min       => 1,
                separator => 'SEPARATOR'
            },
            {   lhs => 'Statement',
                rhs => [qw/CREATE TypeDef/],
            },
            {   lhs => 'TypeDef',
                rhs => [qw/METRIC ID_METRIC AS MetricSelect/],
            },
            {   lhs => 'MetricSelect',
                rhs => [qw/SELECT MetricExpr ByClause Match Filter WithPf/],
            },
            {   lhs => 'MetricExpr',
                rhs => [qw/NUMBER/],
            },
##############################################################################
            {   lhs => 'ByClause',
                rhs => [],
            },
            {   lhs => 'ByClause',
                rhs => [qw/BY/],
            },
##############################################################################
            {   lhs => 'Match',
                rhs => [],
            },
            {   lhs => 'Match',
                rhs => [qw/FOR/],
            },
#############################################################################
            {   lhs => 'Filter',
                rhs => [],
            },
            {   lhs => 'Filter',
                rhs => [qw/WHERE FilterExpr/],
            },
            {   lhs => 'FilterExpr',
                rhs => [qw/TRUE/],
            },
            {   lhs => 'FilterExpr',
                rhs => [qw/FALSE/],
            },
###############################################################################
            {   lhs => 'WithPf',
                rhs => [],
            },
            {   lhs => 'WithPf',
                rhs => [qw/WITH PF/],
            },
###############################################################################
        ],
    }
);

$grammar->precompute();

Marpa::R2::Test::is(
    <<'END_OF_SYMBOLS', $grammar->show_symbols(), 'Symbols' );
0: AS, lhs=[] rhs=[6] terminal
1: BY, lhs=[] rhs=[10] terminal
2: CREATE, lhs=[] rhs=[5] terminal
3: FALSE, lhs=[] rhs=[16] terminal
4: FOR, lhs=[] rhs=[12] terminal
5: METRIC, lhs=[] rhs=[6] terminal
6: PF, lhs=[] rhs=[18] terminal
7: SELECT, lhs=[] rhs=[7 19 20 21 22] terminal
8: TRUE, lhs=[] rhs=[15] terminal
9: WHERE, lhs=[] rhs=[14] terminal
10: WITH, lhs=[] rhs=[18] terminal
11: ID_METRIC, lhs=[] rhs=[6] terminal
12: SEPARATOR, lhs=[] rhs=[2 4] terminal
13: NUMBER, lhs=[] rhs=[8] terminal
14: Input, lhs=[0 1 2] rhs=[29]
15: Statement, lhs=[5] rhs=[0 3 4]
16: Input[Statement+], lhs=[3 4] rhs=[1 2 4]
17: TypeDef, lhs=[6] rhs=[5]
18: MetricSelect, lhs=[7 19 20 21 22] rhs=[6]
19: MetricExpr, lhs=[8] rhs=[7 19 20 21 22]
20: ByClause, lhs=[9 10] rhs=[7 19 20]
21: Match, lhs=[11 12] rhs=[7 23 24]
22: Filter, lhs=[13 14] rhs=[7 26 27]
23: WithPf, lhs=[17 18] rhs=[7 26 28]
24: FilterExpr, lhs=[15 16] rhs=[14]
25: ByClause[], lhs=[] rhs=[21 22] nullable nulling
26: Match[], lhs=[] rhs=[20 22 25] nullable nulling
27: Filter[], lhs=[] rhs=[20 22 24 28] nullable nulling
28: WithPf[], lhs=[] rhs=[20 22 24 27] nullable nulling
29: MetricSelect[R7:3], lhs=[23 24 25] rhs=[19 21]
30: MetricSelect[R7:4], lhs=[26 27 28] rhs=[23 25]
31: Input['], lhs=[29] rhs=[]
END_OF_SYMBOLS

Marpa::R2::Test::is( <<'END_OF_RULES', $grammar->show_rules(), 'Rules' );
0: Input -> Statement /* !used discard_sep */
1: Input -> Input[Statement+] /* vrhs real=0 */
2: Input -> Input[Statement+] SEPARATOR /* vrhs real=1 */
3: Input[Statement+] -> Statement /* vlhs real=1 */
4: Input[Statement+] -> Input[Statement+] SEPARATOR Statement /* vlhs vrhs real=2 */
5: Statement -> CREATE TypeDef
6: TypeDef -> METRIC ID_METRIC AS MetricSelect
7: MetricSelect -> SELECT MetricExpr ByClause Match Filter WithPf /* !used */
8: MetricExpr -> NUMBER
9: ByClause -> /* empty !used */
10: ByClause -> BY
11: Match -> /* empty !used */
12: Match -> FOR
13: Filter -> /* empty !used */
14: Filter -> WHERE FilterExpr
15: FilterExpr -> TRUE
16: FilterExpr -> FALSE
17: WithPf -> /* empty !used */
18: WithPf -> WITH PF
19: MetricSelect -> SELECT MetricExpr ByClause MetricSelect[R7:3] /* vrhs real=3 */
20: MetricSelect -> SELECT MetricExpr ByClause Match[] Filter[] WithPf[]
21: MetricSelect -> SELECT MetricExpr ByClause[] MetricSelect[R7:3] /* vrhs real=3 */
22: MetricSelect -> SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[]
23: MetricSelect[R7:3] -> Match MetricSelect[R7:4] /* vlhs vrhs real=1 */
24: MetricSelect[R7:3] -> Match Filter[] WithPf[] /* vlhs real=3 */
25: MetricSelect[R7:3] -> Match[] MetricSelect[R7:4] /* vlhs vrhs real=1 */
26: MetricSelect[R7:4] -> Filter WithPf /* vlhs real=2 */
27: MetricSelect[R7:4] -> Filter WithPf[] /* vlhs real=2 */
28: MetricSelect[R7:4] -> Filter[] WithPf /* vlhs real=2 */
29: Input['] -> Input /* vlhs real=1 */
END_OF_RULES

Marpa::R2::Test::is( <<'END_OF_AHFA', $grammar->show_AHFA(), 'AHFA' );
* S0:
Input['] -> . Input
 <Input> => S2; leo(Input['])
* S1: predict
Input -> . Input[Statement+]
Input -> . Input[Statement+] SEPARATOR
Input[Statement+] -> . Statement
Input[Statement+] -> . Input[Statement+] SEPARATOR Statement
Statement -> . CREATE TypeDef
 <CREATE> => S3; S4
 <Input[Statement+]> => S6
 <Statement> => S5; leo(Input[Statement+])
* S2: leo-c
Input['] -> Input .
* S3:
Statement -> CREATE . TypeDef
 <TypeDef> => S7; leo(Statement)
* S4: predict
TypeDef -> . METRIC ID_METRIC AS MetricSelect
 <METRIC> => S8
* S5: leo-c
Input[Statement+] -> Statement .
* S6:
Input -> Input[Statement+] .
Input -> Input[Statement+] . SEPARATOR
Input[Statement+] -> Input[Statement+] . SEPARATOR Statement
 <SEPARATOR> => S10; S9
* S7: leo-c
Statement -> CREATE TypeDef .
* S8:
TypeDef -> METRIC . ID_METRIC AS MetricSelect
 <ID_METRIC> => S11
* S9:
Input -> Input[Statement+] SEPARATOR .
Input[Statement+] -> Input[Statement+] SEPARATOR . Statement
 <Statement> => S12; leo(Input[Statement+])
* S10: predict
Statement -> . CREATE TypeDef
 <CREATE> => S3; S4
* S11:
TypeDef -> METRIC ID_METRIC . AS MetricSelect
 <AS> => S13; S14
* S12: leo-c
Input[Statement+] -> Input[Statement+] SEPARATOR Statement .
* S13:
TypeDef -> METRIC ID_METRIC AS . MetricSelect
 <MetricSelect> => S15; leo(TypeDef)
* S14: predict
MetricSelect -> . SELECT MetricExpr ByClause MetricSelect[R7:3]
MetricSelect -> . SELECT MetricExpr ByClause Match[] Filter[] WithPf[]
MetricSelect -> . SELECT MetricExpr ByClause[] MetricSelect[R7:3]
MetricSelect -> . SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[]
 <SELECT> => S16; S17
* S15: leo-c
TypeDef -> METRIC ID_METRIC AS MetricSelect .
* S16:
MetricSelect -> SELECT . MetricExpr ByClause MetricSelect[R7:3]
MetricSelect -> SELECT . MetricExpr ByClause Match[] Filter[] WithPf[]
MetricSelect -> SELECT . MetricExpr ByClause[] MetricSelect[R7:3]
MetricSelect -> SELECT . MetricExpr ByClause[] Match[] Filter[] WithPf[]
 <MetricExpr> => S18; S19
* S17: predict
MetricExpr -> . NUMBER
 <NUMBER> => S20
* S18:
MetricSelect -> SELECT MetricExpr . ByClause MetricSelect[R7:3]
MetricSelect -> SELECT MetricExpr . ByClause Match[] Filter[] WithPf[]
MetricSelect -> SELECT MetricExpr ByClause[] . MetricSelect[R7:3]
MetricSelect -> SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[] .
 <ByClause> => S21; S22
 <MetricSelect[R7:3]> => S23; leo(MetricSelect)
* S19: predict
ByClause -> . BY
Match -> . FOR
Filter -> . WHERE FilterExpr
WithPf -> . WITH PF
MetricSelect[R7:3] -> . Match MetricSelect[R7:4]
MetricSelect[R7:3] -> . Match Filter[] WithPf[]
MetricSelect[R7:3] -> Match[] . MetricSelect[R7:4]
MetricSelect[R7:4] -> . Filter WithPf
MetricSelect[R7:4] -> . Filter WithPf[]
MetricSelect[R7:4] -> Filter[] . WithPf
 <BY> => S24
 <FOR> => S25
 <Filter> => S31; S32
 <Match> => S29; S30
 <MetricSelect[R7:4]> => S34; leo(MetricSelect[R7:3])
 <WHERE> => S26; S27
 <WITH> => S28
 <WithPf> => S33; leo(MetricSelect[R7:4])
* S20:
MetricExpr -> NUMBER .
* S21:
MetricSelect -> SELECT MetricExpr ByClause . MetricSelect[R7:3]
MetricSelect -> SELECT MetricExpr ByClause Match[] Filter[] WithPf[] .
 <MetricSelect[R7:3]> => S35; leo(MetricSelect)
* S22: predict
Match -> . FOR
Filter -> . WHERE FilterExpr
WithPf -> . WITH PF
MetricSelect[R7:3] -> . Match MetricSelect[R7:4]
MetricSelect[R7:3] -> . Match Filter[] WithPf[]
MetricSelect[R7:3] -> Match[] . MetricSelect[R7:4]
MetricSelect[R7:4] -> . Filter WithPf
MetricSelect[R7:4] -> . Filter WithPf[]
MetricSelect[R7:4] -> Filter[] . WithPf
 <FOR> => S25
 <Filter> => S31; S32
 <Match> => S29; S30
 <MetricSelect[R7:4]> => S34; leo(MetricSelect[R7:3])
 <WHERE> => S26; S27
 <WITH> => S28
 <WithPf> => S33; leo(MetricSelect[R7:4])
* S23: leo-c
MetricSelect -> SELECT MetricExpr ByClause[] MetricSelect[R7:3] .
* S24:
ByClause -> BY .
* S25:
Match -> FOR .
* S26:
Filter -> WHERE . FilterExpr
 <FilterExpr> => S36; leo(Filter)
* S27: predict
FilterExpr -> . TRUE
FilterExpr -> . FALSE
 <FALSE> => S37
 <TRUE> => S38
* S28:
WithPf -> WITH . PF
 <PF> => S39
* S29:
MetricSelect[R7:3] -> Match . MetricSelect[R7:4]
MetricSelect[R7:3] -> Match Filter[] WithPf[] .
 <MetricSelect[R7:4]> => S40; leo(MetricSelect[R7:3])
* S30: predict
Filter -> . WHERE FilterExpr
WithPf -> . WITH PF
MetricSelect[R7:4] -> . Filter WithPf
MetricSelect[R7:4] -> . Filter WithPf[]
MetricSelect[R7:4] -> Filter[] . WithPf
 <Filter> => S31; S32
 <WHERE> => S26; S27
 <WITH> => S28
 <WithPf> => S33; leo(MetricSelect[R7:4])
* S31:
MetricSelect[R7:4] -> Filter . WithPf
MetricSelect[R7:4] -> Filter WithPf[] .
 <WithPf> => S41; leo(MetricSelect[R7:4])
* S32: predict
WithPf -> . WITH PF
 <WITH> => S28
* S33: leo-c
MetricSelect[R7:4] -> Filter[] WithPf .
* S34: leo-c
MetricSelect[R7:3] -> Match[] MetricSelect[R7:4] .
* S35: leo-c
MetricSelect -> SELECT MetricExpr ByClause MetricSelect[R7:3] .
* S36: leo-c
Filter -> WHERE FilterExpr .
* S37:
FilterExpr -> FALSE .
* S38:
FilterExpr -> TRUE .
* S39:
WithPf -> WITH PF .
* S40: leo-c
MetricSelect[R7:3] -> Match MetricSelect[R7:4] .
* S41: leo-c
MetricSelect[R7:4] -> Filter WithPf .
END_OF_AHFA

Marpa::R2::Test::is(
    <<'END_OF_AHFA_ITEMS', $grammar->show_AHFA_items(), 'AHFA Items' );
AHFA item 0: sort = 21; postdot = "Input[Statement+]"
    Input -> . Input[Statement+]
AHFA item 1: sort = 43; completion
    Input -> Input[Statement+] .
AHFA item 2: sort = 22; postdot = "Input[Statement+]"
    Input -> . Input[Statement+] SEPARATOR
AHFA item 3: sort = 15; postdot = "SEPARATOR"
    Input -> Input[Statement+] . SEPARATOR
AHFA item 4: sort = 44; completion
    Input -> Input[Statement+] SEPARATOR .
AHFA item 5: sort = 19; postdot = "Statement"
    Input[Statement+] -> . Statement
AHFA item 6: sort = 45; completion
    Input[Statement+] -> Statement .
AHFA item 7: sort = 23; postdot = "Input[Statement+]"
    Input[Statement+] -> . Input[Statement+] SEPARATOR Statement
AHFA item 8: sort = 16; postdot = "SEPARATOR"
    Input[Statement+] -> Input[Statement+] . SEPARATOR Statement
AHFA item 9: sort = 20; postdot = "Statement"
    Input[Statement+] -> Input[Statement+] SEPARATOR . Statement
AHFA item 10: sort = 46; completion
    Input[Statement+] -> Input[Statement+] SEPARATOR Statement .
AHFA item 11: sort = 2; postdot = "CREATE"
    Statement -> . CREATE TypeDef
AHFA item 12: sort = 24; postdot = "TypeDef"
    Statement -> CREATE . TypeDef
AHFA item 13: sort = 47; completion
    Statement -> CREATE TypeDef .
AHFA item 14: sort = 5; postdot = "METRIC"
    TypeDef -> . METRIC ID_METRIC AS MetricSelect
AHFA item 15: sort = 14; postdot = "ID_METRIC"
    TypeDef -> METRIC . ID_METRIC AS MetricSelect
AHFA item 16: sort = 0; postdot = "AS"
    TypeDef -> METRIC ID_METRIC . AS MetricSelect
AHFA item 17: sort = 25; postdot = "MetricSelect"
    TypeDef -> METRIC ID_METRIC AS . MetricSelect
AHFA item 18: sort = 48; completion
    TypeDef -> METRIC ID_METRIC AS MetricSelect .
AHFA item 19: sort = 17; postdot = "NUMBER"
    MetricExpr -> . NUMBER
AHFA item 20: sort = 49; completion
    MetricExpr -> NUMBER .
AHFA item 21: sort = 1; postdot = "BY"
    ByClause -> . BY
AHFA item 22: sort = 50; completion
    ByClause -> BY .
AHFA item 23: sort = 4; postdot = "FOR"
    Match -> . FOR
AHFA item 24: sort = 51; completion
    Match -> FOR .
AHFA item 25: sort = 12; postdot = "WHERE"
    Filter -> . WHERE FilterExpr
AHFA item 26: sort = 38; postdot = "FilterExpr"
    Filter -> WHERE . FilterExpr
AHFA item 27: sort = 52; completion
    Filter -> WHERE FilterExpr .
AHFA item 28: sort = 11; postdot = "TRUE"
    FilterExpr -> . TRUE
AHFA item 29: sort = 53; completion
    FilterExpr -> TRUE .
AHFA item 30: sort = 3; postdot = "FALSE"
    FilterExpr -> . FALSE
AHFA item 31: sort = 54; completion
    FilterExpr -> FALSE .
AHFA item 32: sort = 13; postdot = "WITH"
    WithPf -> . WITH PF
AHFA item 33: sort = 6; postdot = "PF"
    WithPf -> WITH . PF
AHFA item 34: sort = 55; completion
    WithPf -> WITH PF .
AHFA item 35: sort = 7; postdot = "SELECT"
    MetricSelect -> . SELECT MetricExpr ByClause MetricSelect[R7:3]
AHFA item 36: sort = 26; postdot = "MetricExpr"
    MetricSelect -> SELECT . MetricExpr ByClause MetricSelect[R7:3]
AHFA item 37: sort = 30; postdot = "ByClause"
    MetricSelect -> SELECT MetricExpr . ByClause MetricSelect[R7:3]
AHFA item 38: sort = 39; postdot = "MetricSelect[R7:3]"
    MetricSelect -> SELECT MetricExpr ByClause . MetricSelect[R7:3]
AHFA item 39: sort = 56; completion
    MetricSelect -> SELECT MetricExpr ByClause MetricSelect[R7:3] .
AHFA item 40: sort = 8; postdot = "SELECT"
    MetricSelect -> . SELECT MetricExpr ByClause Match[] Filter[] WithPf[]
AHFA item 41: sort = 27; postdot = "MetricExpr"
    MetricSelect -> SELECT . MetricExpr ByClause Match[] Filter[] WithPf[]
AHFA item 42: sort = 31; postdot = "ByClause"
    MetricSelect -> SELECT MetricExpr . ByClause Match[] Filter[] WithPf[]
AHFA item 43: sort = 57; completion
    MetricSelect -> SELECT MetricExpr ByClause Match[] Filter[] WithPf[] .
AHFA item 44: sort = 9; postdot = "SELECT"
    MetricSelect -> . SELECT MetricExpr ByClause[] MetricSelect[R7:3]
AHFA item 45: sort = 28; postdot = "MetricExpr"
    MetricSelect -> SELECT . MetricExpr ByClause[] MetricSelect[R7:3]
AHFA item 46: sort = 40; postdot = "MetricSelect[R7:3]"
    MetricSelect -> SELECT MetricExpr ByClause[] . MetricSelect[R7:3]
AHFA item 47: sort = 58; completion
    MetricSelect -> SELECT MetricExpr ByClause[] MetricSelect[R7:3] .
AHFA item 48: sort = 10; postdot = "SELECT"
    MetricSelect -> . SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[]
AHFA item 49: sort = 29; postdot = "MetricExpr"
    MetricSelect -> SELECT . MetricExpr ByClause[] Match[] Filter[] WithPf[]
AHFA item 50: sort = 59; completion
    MetricSelect -> SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[] .
AHFA item 51: sort = 32; postdot = "Match"
    MetricSelect[R7:3] -> . Match MetricSelect[R7:4]
AHFA item 52: sort = 41; postdot = "MetricSelect[R7:4]"
    MetricSelect[R7:3] -> Match . MetricSelect[R7:4]
AHFA item 53: sort = 60; completion
    MetricSelect[R7:3] -> Match MetricSelect[R7:4] .
AHFA item 54: sort = 33; postdot = "Match"
    MetricSelect[R7:3] -> . Match Filter[] WithPf[]
AHFA item 55: sort = 61; completion
    MetricSelect[R7:3] -> Match Filter[] WithPf[] .
AHFA item 56: sort = 42; postdot = "MetricSelect[R7:4]"
    MetricSelect[R7:3] -> Match[] . MetricSelect[R7:4]
AHFA item 57: sort = 62; completion
    MetricSelect[R7:3] -> Match[] MetricSelect[R7:4] .
AHFA item 58: sort = 34; postdot = "Filter"
    MetricSelect[R7:4] -> . Filter WithPf
AHFA item 59: sort = 36; postdot = "WithPf"
    MetricSelect[R7:4] -> Filter . WithPf
AHFA item 60: sort = 63; completion
    MetricSelect[R7:4] -> Filter WithPf .
AHFA item 61: sort = 35; postdot = "Filter"
    MetricSelect[R7:4] -> . Filter WithPf[]
AHFA item 62: sort = 64; completion
    MetricSelect[R7:4] -> Filter WithPf[] .
AHFA item 63: sort = 37; postdot = "WithPf"
    MetricSelect[R7:4] -> Filter[] . WithPf
AHFA item 64: sort = 65; completion
    MetricSelect[R7:4] -> Filter[] WithPf .
AHFA item 65: sort = 18; postdot = "Input"
    Input['] -> . Input
AHFA item 66: sort = 66; completion
    Input['] -> Input .
END_OF_AHFA_ITEMS

my $recog = Marpa::R2::Recognizer->new( { grammar => $grammar } );
for my $token ( @{$tokens} ) { $recog->read( @{$token} ); }
my @result = $recog->value();

Marpa::R2::Test::is(
    <<'END_OF_EARLEY_SETS', $recog->show_earley_sets(), 'Earley Sets' );
Last Completed: 8; Furthest: 8
Earley Set 0
S0@0-0
S1@0-0
Earley Set 1
S3@0-1 [p=S1@0-0; s=CREATE; t=\'Create']
S4@1-1
L17@1 ["TypeDef"; S3@0-1]
Earley Set 2
S8@1-2 [p=S4@1-1; s=METRIC; t=\'Metric']
Earley Set 3
S11@1-3 [p=S8@1-2; s=ID_METRIC; t=\'m']
Earley Set 4
S13@1-4 [p=S11@1-3; s=AS; t=\'As']
S14@4-4
L18@4 ["MetricSelect"; L17@1; S13@1-4]
Earley Set 5
S16@4-5 [p=S14@4-4; s=SELECT; t=\'Select']
S17@5-5
Earley Set 6
S2@0-6 [p=S0@0-0; c=S6@0-6]
S5@0-6 [p=S1@0-0; c=S7@0-6]
S6@0-6 [p=S1@0-0; c=S5@0-6]
S7@0-6 [l=L18@4; c=S18@4-6]
S18@4-6 [p=S16@4-5; c=S20@5-6]
S20@5-6 [p=S17@5-5; s=NUMBER; t=\1]
S19@6-6
L23@6 ["WithPf"; L30@6; S19@6-6]
L29@6 ["MetricSelect[R7:3]"; L18@4; S18@4-6]
L30@6 ["MetricSelect[R7:4]"; L29@6; S19@6-6]
Earley Set 7
S26@6-7 [p=S19@6-6; s=WHERE; t=\'Where']
S27@7-7
L24@7 ["FilterExpr"; S26@6-7]
Earley Set 8
S2@0-8 [p=S0@0-0; c=S6@0-8]
S5@0-8 [p=S1@0-0; c=S7@0-8]
S6@0-8 [p=S1@0-0; c=S5@0-8]
S7@0-8 [l=L30@6; c=S31@6-8]
S31@6-8 [p=S19@6-6; c=S36@6-8]
S36@6-8 [l=L24@7; c=S38@7-8]
S38@7-8 [p=S27@7-7; s=TRUE; t=\'True']
S32@8-8
L23@8 ["WithPf"; L30@6; S31@6-8]
END_OF_EARLEY_SETS

Marpa::R2::Test::is(
    <<'END_OF_AND_NODES', $recog->show_and_nodes(), 'And Nodes' );
R5:1@0-1S2@0
R1:1@0-8C3@0
R3:1@0-8C5@0
R5:2@0-8C6@1
R29:1@0-8C1@0
R6:1@1-2S5@1
R6:2@1-3S11@2
R6:3@1-4S0@3
R6:4@1-8C21@4
R21:1@4-5S7@4
R21:2@4-6C8@5
R21:3@4-6S25@6
R21:4@4-8C25@6
R8:1@5-6S13@5
R25:1@6-6S26@6
R14:1@6-7S9@6
R14:2@6-8C15@7
R25:2@6-8C27@6
R27:1@6-8C14@6
R27:2@6-8S28@8
R15:1@7-8S8@7
END_OF_AND_NODES

Marpa::R2::Test::is(
    <<'END_OF_OR_NODES', $recog->show_or_nodes(), 'Or Nodes' );
R5:1@0-1
R1:1@0-8
R3:1@0-8
R5:2@0-8
R29:1@0-8
R6:1@1-2
R6:2@1-3
R6:3@1-4
R6:4@1-8
R21:1@4-5
R21:2@4-6
R21:3@4-6
R21:4@4-8
R8:1@5-6
R25:1@6-6
R14:1@6-7
R14:2@6-8
R25:2@6-8
R27:1@6-8
R27:2@6-8
R15:1@7-8
END_OF_OR_NODES

Marpa::R2::Test::is( Dumper( \@result ), <<'END_OF_STRING', 'Result' );
$VAR1 = [
          \[
              [
                'Create',
                [
                  'Metric',
                  'm',
                  'As',
                  [
                    'Select',
                    [
                      1
                    ],
                    undef,
                    undef,
                    [
                      'Where',
                      [
                        'True'
                      ]
                    ],
                    undef
                  ]
                ]
              ]
            ]
        ];
END_OF_STRING

#############################################################################
package Maql_Actions;

sub new { }

sub tisk { shift; return \@_; }

