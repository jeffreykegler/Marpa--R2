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
# An ambiguous equation

use 5.010;
use strict;
use warnings;

use Test::More tests => 8;

use lib 'inc';
use Marpa::R2::Test;

use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw( close open );
use Marpa::R2;

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
        default_empty_action => '::undef',
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
    $grammar->show_symbols(),
    <<'END_OF_SYMBOLS', 'Symbols' );
0: AS, terminal
1: BY, terminal
2: CREATE, terminal
3: FALSE, terminal
4: FOR, terminal
5: METRIC, terminal
6: PF, terminal
7: SELECT, terminal
8: TRUE, terminal
9: WHERE, terminal
10: WITH, terminal
11: ID_METRIC, terminal
12: SEPARATOR, terminal
13: NUMBER, terminal
14: Input
15: Statement
16: TypeDef
17: MetricSelect
18: MetricExpr
19: ByClause
20: Match
21: Filter
22: WithPf
23: FilterExpr
END_OF_SYMBOLS

Marpa::R2::Test::is( $grammar->show_rules(),
<<'END_OF_RULES', 'Rules' );
0: Input -> Statement+ /* discard_sep */
1: Statement -> CREATE TypeDef
2: TypeDef -> METRIC ID_METRIC AS MetricSelect
3: MetricSelect -> SELECT MetricExpr ByClause Match Filter WithPf
4: MetricExpr -> NUMBER
5: ByClause -> /* empty !used */
6: ByClause -> BY
7: Match -> /* empty !used */
8: Match -> FOR
9: Filter -> /* empty !used */
10: Filter -> WHERE FilterExpr
11: FilterExpr -> TRUE
12: FilterExpr -> FALSE
13: WithPf -> /* empty !used */
14: WithPf -> WITH PF
END_OF_RULES

Marpa::R2::Test::is( $grammar->show_AHFA(),
<<'END_OF_AHFA', 'AHFA' );
* S0:
Input['] -> . Input
* S1: predict
Input -> . Input[Seq]
Input -> . Input[Seq] SEPARATOR
Input[Seq] -> . Statement
Input[Seq] -> . Input[Seq] SEPARATOR Statement
Statement -> . CREATE TypeDef
* S2:
Input -> Input[Seq] .
* S3:
Input -> Input[Seq] . SEPARATOR
* S4:
Input -> Input[Seq] SEPARATOR .
* S5:
Input[Seq] -> Statement .
* S6:
Input[Seq] -> Input[Seq] . SEPARATOR Statement
* S7:
Input[Seq] -> Input[Seq] SEPARATOR . Statement
* S8: predict
Statement -> . CREATE TypeDef
* S9:
Input[Seq] -> Input[Seq] SEPARATOR Statement .
* S10:
Statement -> CREATE . TypeDef
* S11: predict
TypeDef -> . METRIC ID_METRIC AS MetricSelect
* S12:
Statement -> CREATE TypeDef .
* S13:
TypeDef -> METRIC . ID_METRIC AS MetricSelect
* S14:
TypeDef -> METRIC ID_METRIC . AS MetricSelect
* S15:
TypeDef -> METRIC ID_METRIC AS . MetricSelect
* S16: predict
MetricSelect -> . SELECT MetricExpr ByClause MetricSelect[R3:3]
MetricSelect -> . SELECT MetricExpr ByClause Match[] Filter[] WithPf[]
MetricSelect -> . SELECT MetricExpr ByClause[] MetricSelect[R3:3]
MetricSelect -> . SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[]
* S17:
TypeDef -> METRIC ID_METRIC AS MetricSelect .
* S18:
MetricSelect -> SELECT . MetricExpr ByClause MetricSelect[R3:3]
* S19: predict
MetricExpr -> . NUMBER
* S20:
MetricSelect -> SELECT MetricExpr . ByClause MetricSelect[R3:3]
* S21: predict
ByClause -> . BY
* S22:
MetricSelect -> SELECT MetricExpr ByClause . MetricSelect[R3:3]
* S23: predict
MetricSelect[R3:3] -> . Match MetricSelect[R3:4]
MetricSelect[R3:3] -> . Match Filter[] WithPf[]
MetricSelect[R3:3] -> Match[] . MetricSelect[R3:4]
MetricSelect[R3:4] -> . Filter WithPf
MetricSelect[R3:4] -> . Filter WithPf[]
MetricSelect[R3:4] -> Filter[] . WithPf
Match -> . FOR
Filter -> . WHERE FilterExpr
WithPf -> . WITH PF
* S24:
MetricSelect -> SELECT MetricExpr ByClause MetricSelect[R3:3] .
* S25:
MetricSelect -> SELECT . MetricExpr ByClause Match[] Filter[] WithPf[]
* S26:
MetricSelect -> SELECT MetricExpr . ByClause Match[] Filter[] WithPf[]
* S27:
MetricSelect -> SELECT MetricExpr ByClause Match[] Filter[] WithPf[] .
* S28:
MetricSelect -> SELECT . MetricExpr ByClause[] MetricSelect[R3:3]
* S29:
MetricSelect -> SELECT MetricExpr ByClause[] . MetricSelect[R3:3]
* S30:
MetricSelect -> SELECT MetricExpr ByClause[] MetricSelect[R3:3] .
* S31:
MetricSelect -> SELECT . MetricExpr ByClause[] Match[] Filter[] WithPf[]
* S32:
MetricSelect -> SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[] .
* S33:
MetricSelect[R3:3] -> Match . MetricSelect[R3:4]
* S34: predict
MetricSelect[R3:4] -> . Filter WithPf
MetricSelect[R3:4] -> . Filter WithPf[]
MetricSelect[R3:4] -> Filter[] . WithPf
Filter -> . WHERE FilterExpr
WithPf -> . WITH PF
* S35:
MetricSelect[R3:3] -> Match MetricSelect[R3:4] .
* S36:
MetricSelect[R3:3] -> Match Filter[] WithPf[] .
* S37:
MetricSelect[R3:3] -> Match[] MetricSelect[R3:4] .
* S38:
MetricSelect[R3:4] -> Filter . WithPf
* S39: predict
WithPf -> . WITH PF
* S40:
MetricSelect[R3:4] -> Filter WithPf .
* S41:
MetricSelect[R3:4] -> Filter WithPf[] .
* S42:
MetricSelect[R3:4] -> Filter[] WithPf .
* S43:
MetricExpr -> NUMBER .
* S44:
ByClause -> BY .
* S45:
Match -> FOR .
* S46:
Filter -> WHERE . FilterExpr
* S47: predict
FilterExpr -> . TRUE
FilterExpr -> . FALSE
* S48:
Filter -> WHERE FilterExpr .
* S49:
FilterExpr -> TRUE .
* S50:
FilterExpr -> FALSE .
* S51:
WithPf -> WITH . PF
* S52:
WithPf -> WITH PF .
* S53:
Input['] -> Input .
END_OF_AHFA

Marpa::R2::Test::is( $grammar->show_ahms(),
    <<'END_OF_AHFA_ITEMS', 'AHFA Items' );
AHFA item 0: sort = 36; postdot = "Input[Seq]"
    Input -> . Input[Seq]
AHFA item 1: sort = 43; completion
    Input -> Input[Seq] .
AHFA item 2: sort = 37; postdot = "Input[Seq]"
    Input -> . Input[Seq] SEPARATOR
AHFA item 3: sort = 15; postdot = "SEPARATOR"
    Input -> Input[Seq] . SEPARATOR
AHFA item 4: sort = 44; completion
    Input -> Input[Seq] SEPARATOR .
AHFA item 5: sort = 19; postdot = "Statement"
    Input[Seq] -> . Statement
AHFA item 6: sort = 45; completion
    Input[Seq] -> Statement .
AHFA item 7: sort = 38; postdot = "Input[Seq]"
    Input[Seq] -> . Input[Seq] SEPARATOR Statement
AHFA item 8: sort = 16; postdot = "SEPARATOR"
    Input[Seq] -> Input[Seq] . SEPARATOR Statement
AHFA item 9: sort = 20; postdot = "Statement"
    Input[Seq] -> Input[Seq] SEPARATOR . Statement
AHFA item 10: sort = 46; completion
    Input[Seq] -> Input[Seq] SEPARATOR Statement .
AHFA item 11: sort = 2; postdot = "CREATE"
    Statement -> . CREATE TypeDef
AHFA item 12: sort = 21; postdot = "TypeDef"
    Statement -> CREATE . TypeDef
AHFA item 13: sort = 47; completion
    Statement -> CREATE TypeDef .
AHFA item 14: sort = 5; postdot = "METRIC"
    TypeDef -> . METRIC ID_METRIC AS MetricSelect
AHFA item 15: sort = 14; postdot = "ID_METRIC"
    TypeDef -> METRIC . ID_METRIC AS MetricSelect
AHFA item 16: sort = 0; postdot = "AS"
    TypeDef -> METRIC ID_METRIC . AS MetricSelect
AHFA item 17: sort = 22; postdot = "MetricSelect"
    TypeDef -> METRIC ID_METRIC AS . MetricSelect
AHFA item 18: sort = 48; completion
    TypeDef -> METRIC ID_METRIC AS MetricSelect .
AHFA item 19: sort = 7; postdot = "SELECT"
    MetricSelect -> . SELECT MetricExpr ByClause MetricSelect[R3:3]
AHFA item 20: sort = 23; postdot = "MetricExpr"
    MetricSelect -> SELECT . MetricExpr ByClause MetricSelect[R3:3]
AHFA item 21: sort = 27; postdot = "ByClause"
    MetricSelect -> SELECT MetricExpr . ByClause MetricSelect[R3:3]
AHFA item 22: sort = 39; postdot = "MetricSelect[R3:3]"
    MetricSelect -> SELECT MetricExpr ByClause . MetricSelect[R3:3]
AHFA item 23: sort = 49; completion
    MetricSelect -> SELECT MetricExpr ByClause MetricSelect[R3:3] .
AHFA item 24: sort = 8; postdot = "SELECT"
    MetricSelect -> . SELECT MetricExpr ByClause Match[] Filter[] WithPf[]
AHFA item 25: sort = 24; postdot = "MetricExpr"
    MetricSelect -> SELECT . MetricExpr ByClause Match[] Filter[] WithPf[]
AHFA item 26: sort = 28; postdot = "ByClause"
    MetricSelect -> SELECT MetricExpr . ByClause Match[] Filter[] WithPf[]
AHFA item 27: sort = 50; completion
    MetricSelect -> SELECT MetricExpr ByClause Match[] Filter[] WithPf[] .
AHFA item 28: sort = 9; postdot = "SELECT"
    MetricSelect -> . SELECT MetricExpr ByClause[] MetricSelect[R3:3]
AHFA item 29: sort = 25; postdot = "MetricExpr"
    MetricSelect -> SELECT . MetricExpr ByClause[] MetricSelect[R3:3]
AHFA item 30: sort = 40; postdot = "MetricSelect[R3:3]"
    MetricSelect -> SELECT MetricExpr ByClause[] . MetricSelect[R3:3]
AHFA item 31: sort = 51; completion
    MetricSelect -> SELECT MetricExpr ByClause[] MetricSelect[R3:3] .
AHFA item 32: sort = 10; postdot = "SELECT"
    MetricSelect -> . SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[]
AHFA item 33: sort = 26; postdot = "MetricExpr"
    MetricSelect -> SELECT . MetricExpr ByClause[] Match[] Filter[] WithPf[]
AHFA item 34: sort = 52; completion
    MetricSelect -> SELECT MetricExpr ByClause[] Match[] Filter[] WithPf[] .
AHFA item 35: sort = 29; postdot = "Match"
    MetricSelect[R3:3] -> . Match MetricSelect[R3:4]
AHFA item 36: sort = 41; postdot = "MetricSelect[R3:4]"
    MetricSelect[R3:3] -> Match . MetricSelect[R3:4]
AHFA item 37: sort = 53; completion
    MetricSelect[R3:3] -> Match MetricSelect[R3:4] .
AHFA item 38: sort = 30; postdot = "Match"
    MetricSelect[R3:3] -> . Match Filter[] WithPf[]
AHFA item 39: sort = 54; completion
    MetricSelect[R3:3] -> Match Filter[] WithPf[] .
AHFA item 40: sort = 42; postdot = "MetricSelect[R3:4]"
    MetricSelect[R3:3] -> Match[] . MetricSelect[R3:4]
AHFA item 41: sort = 55; completion
    MetricSelect[R3:3] -> Match[] MetricSelect[R3:4] .
AHFA item 42: sort = 31; postdot = "Filter"
    MetricSelect[R3:4] -> . Filter WithPf
AHFA item 43: sort = 33; postdot = "WithPf"
    MetricSelect[R3:4] -> Filter . WithPf
AHFA item 44: sort = 56; completion
    MetricSelect[R3:4] -> Filter WithPf .
AHFA item 45: sort = 32; postdot = "Filter"
    MetricSelect[R3:4] -> . Filter WithPf[]
AHFA item 46: sort = 57; completion
    MetricSelect[R3:4] -> Filter WithPf[] .
AHFA item 47: sort = 34; postdot = "WithPf"
    MetricSelect[R3:4] -> Filter[] . WithPf
AHFA item 48: sort = 58; completion
    MetricSelect[R3:4] -> Filter[] WithPf .
AHFA item 49: sort = 17; postdot = "NUMBER"
    MetricExpr -> . NUMBER
AHFA item 50: sort = 59; completion
    MetricExpr -> NUMBER .
AHFA item 51: sort = 1; postdot = "BY"
    ByClause -> . BY
AHFA item 52: sort = 60; completion
    ByClause -> BY .
AHFA item 53: sort = 4; postdot = "FOR"
    Match -> . FOR
AHFA item 54: sort = 61; completion
    Match -> FOR .
AHFA item 55: sort = 12; postdot = "WHERE"
    Filter -> . WHERE FilterExpr
AHFA item 56: sort = 35; postdot = "FilterExpr"
    Filter -> WHERE . FilterExpr
AHFA item 57: sort = 62; completion
    Filter -> WHERE FilterExpr .
AHFA item 58: sort = 11; postdot = "TRUE"
    FilterExpr -> . TRUE
AHFA item 59: sort = 63; completion
    FilterExpr -> TRUE .
AHFA item 60: sort = 3; postdot = "FALSE"
    FilterExpr -> . FALSE
AHFA item 61: sort = 64; completion
    FilterExpr -> FALSE .
AHFA item 62: sort = 13; postdot = "WITH"
    WithPf -> . WITH PF
AHFA item 63: sort = 6; postdot = "PF"
    WithPf -> WITH . PF
AHFA item 64: sort = 65; completion
    WithPf -> WITH PF .
AHFA item 65: sort = 18; postdot = "Input"
    Input['] -> . Input
AHFA item 66: sort = 66; completion
    Input['] -> Input .
END_OF_AHFA_ITEMS

my $recog = Marpa::R2::Recognizer->new( { grammar => $grammar } );
for my $token ( @{$tokens} ) { $recog->read( @{$token} ); }
my @result = $recog->value();

Marpa::R2::Test::is( $recog->show_earley_sets(),
    <<'END_OF_EARLEY_SETS', 'Earley Sets' );
Last Completed: 8; Furthest: 8
Earley Set 0
S0@0-0
S1@0-0
Earley Set 1
S10@0-1 [p=S1@0-0; s=CREATE; t=\'Create']
S11@1-1
Earley Set 2
S13@1-2 [p=S11@1-1; s=METRIC; t=\'Metric']
Earley Set 3
S14@1-3 [p=S13@1-2; s=ID_METRIC; t=\'m']
Earley Set 4
S15@1-4 [p=S14@1-3; s=AS; t=\'As']
S16@4-4
Earley Set 5
S18@4-5 [p=S16@4-4; s=SELECT; t=\'Select']
S25@4-5 [p=S16@4-4; s=SELECT; t=\'Select']
S28@4-5 [p=S16@4-4; s=SELECT; t=\'Select']
S31@4-5 [p=S16@4-4; s=SELECT; t=\'Select']
S19@5-5
Earley Set 6
S2@0-6 [p=S1@0-0; c=S5@0-6]
S3@0-6 [p=S1@0-0; c=S5@0-6]
S5@0-6 [p=S1@0-0; c=S12@0-6]
S6@0-6 [p=S1@0-0; c=S5@0-6]
S12@0-6 [p=S10@0-1; c=S17@1-6]
S53@0-6 [p=S0@0-0; c=S2@0-6]
S17@1-6 [p=S15@1-4; c=S32@4-6]
S20@4-6 [p=S18@4-5; c=S43@5-6]
S26@4-6 [p=S25@4-5; c=S43@5-6]
S29@4-6 [p=S28@4-5; c=S43@5-6]
S32@4-6 [p=S31@4-5; c=S43@5-6]
S43@5-6 [p=S19@5-5; s=NUMBER; t=\1]
S21@6-6
S23@6-6
Earley Set 7
S46@6-7 [p=S23@6-6; s=WHERE; t=\'Where']
S47@7-7
Earley Set 8
S2@0-8 [p=S1@0-0; c=S5@0-8]
S3@0-8 [p=S1@0-0; c=S5@0-8]
S5@0-8 [p=S1@0-0; c=S12@0-8]
S6@0-8 [p=S1@0-0; c=S5@0-8]
S12@0-8 [p=S10@0-1; c=S17@1-8]
S53@0-8 [p=S0@0-0; c=S2@0-8]
S17@1-8 [p=S15@1-4; c=S30@4-8]
S30@4-8 [p=S29@4-6; c=S37@6-8]
S37@6-8 [p=S23@6-6; c=S41@6-8]
S38@6-8 [p=S23@6-6; c=S48@6-8]
S41@6-8 [p=S23@6-6; c=S48@6-8]
S48@6-8 [p=S46@6-7; c=S49@7-8]
S49@7-8 [p=S47@7-7; s=TRUE; t=\'True']
S39@8-8
END_OF_EARLEY_SETS

Marpa::R2::Test::is( $recog->show_and_nodes(),
    <<'END_OF_AND_NODES', 'And Nodes' );
And-node #0: R4:1@0-1S2@0
And-node #19: R0:1@0-8C2@0
And-node #18: R2:1@0-8C4@0
And-node #17: R4:2@0-8C5@1
And-node #20: R23:1@0-8C0@0
And-node #1: R5:1@1-2S5@1
And-node #2: R5:2@1-3S11@2
And-node #3: R5:3@1-4S0@3
And-node #16: R5:4@1-8C8@4
And-node #4: R8:1@4-5S7@4
And-node #6: R8:2@4-6C16@5
And-node #7: R8:3@4-6S20@6
And-node #15: R8:4@4-8C12@6
And-node #5: R16:1@5-6S13@5
And-node #8: R12:1@6-6S22@6
And-node #9: R19:1@6-7S9@6
And-node #14: R12:2@6-8C14@6
And-node #12: R14:1@6-8C19@6
And-node #13: R14:2@6-8S26@8
And-node #11: R19:2@6-8C20@7
And-node #10: R20:1@7-8S8@7
END_OF_AND_NODES

Marpa::R2::Test::is( $recog->show_or_nodes(),
    <<'END_OF_OR_NODES', 'Or Nodes' );
R4:1@0-1
R0:1@0-8
R2:1@0-8
R4:2@0-8
R23:1@0-8
R5:1@1-2
R5:2@1-3
R5:3@1-4
R5:4@1-8
R8:1@4-5
R8:2@4-6
R8:3@4-6
R8:4@4-8
R16:1@5-6
R12:1@6-6
R19:1@6-7
R12:2@6-8
R14:1@6-8
R14:2@6-8
R19:2@6-8
R20:1@7-8
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

