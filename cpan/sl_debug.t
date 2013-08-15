#!/usr/bin/perl
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

# Displays for SLIF Progress.pod

use 5.010;
use strict;
use warnings;

use Test::More tests => 12;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my $progress_report = q{};

# Marpa::R2::Display
# name: SLIF Debug Example Part 1

my $slif_debug_source = <<'END_OF_SOURCE';
:default ::= action => ::array bless => ::lhs
:start ::= statements
statements ::= statement*
statement ::= assignment | <numeric assignment>
assignment ::= 'set' variable 'to' expression
<numeric assignment> ::= variable '=' expression
expression ::=
       variable | string
    || 'string' '(' <numeric expression> ')'
    || expression '+' expression
<numeric expression> ::=
       variable | number
    || <numeric expression> '+' <numeric expression>
    || <numeric expression> '*' <numeric expression>
variable ~ [\w]+
number ~ [\d]+
string ~ ['] <string contents> [']
<string contents> ~ [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_SOURCE

my $slg = Marpa::R2::Scanless::G->new(
    {
    bless_package => 'My_Nodes',
    source => \$slif_debug_source,
});

# Marpa::R2::Display::End

## no critic (InputOutput::RequireBriefOpen)
open my $trace_fh, q{>}, \( my $trace_output = q{} );
## use critic

# Marpa::R2::Display
# name: SLIF Grammar set() Synopsis

$slg->set( { trace_file_handle => $trace_fh } );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF Debug Example Part 2

my $slr = Marpa::R2::Scanless::R->new(
    { grammar => $slg } );

my $test_input = 'a = 8675309 + 42 * 711' ;
eval { $slr->read( \$test_input ) };

$progress_report = $slr->show_progress( 0, -1 );

# Marpa::R2::Display::End

my $eval_error = $EVAL_ERROR;
$eval_error =~ s/^(Marpa::R2 \s+ exception \s+ at) .*/$1\n/xms;
Marpa::R2::Test::is($eval_error, <<'END_OF_TEXT', 'Error message before fix');
Error in SLIF parse: No lexemes accepted at line 1, column 18
* String before error: a = 8675309 + 42\s
* The error was at line 1, column 18, and at character 0x002a '*', ...
* here: * 711
Marpa::R2 exception at
END_OF_TEXT

my $value_ref = $slr->value();
my $expected_output = \bless( [
                 bless( [
                          bless( [
                                   'a',
                                   '=',
                                   bless( [
                                            bless( [
                                                     '8675309'
                                                   ], 'My_Nodes::expression' ),
                                            '+',
                                            bless( [
                                                     '42'
                                                   ], 'My_Nodes::expression' )
                                          ], 'My_Nodes::expression' )
                                 ], 'My_Nodes::numeric_assignment' )
                        ], 'My_Nodes::statement' )
               ], 'My_Nodes::statements' );
Test::More::is_deeply( $value_ref, $expected_output, 'Value before fix' );

# Marpa::R2::Display
# name: SLIF Debug Example Progress Report
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

Marpa::R2::Test::is( $progress_report,
    <<'END_PROGRESS_REPORT', 'progress report' );
P0 @0-0 :start -> . <statements>
P1 @0-0 <statements> -> . <statement>*
P2 @0-0 <statement> -> . <assignment>
P3 @0-0 <statement> -> . <numeric assignment>
P4 @0-0 <assignment> -> . 'set' <variable> 'to' <expression>
P5 @0-0 <numeric assignment> -> . <variable> '=' <expression>
R5:1 @0-1 <numeric assignment> -> <variable> . '=' <expression>
R5:2 @0-2 <numeric assignment> -> <variable> '=' . <expression>
P6 @2-2 <expression> -> . <expression>
P7 @2-2 <expression> -> . <expression>
P8 @2-2 <expression> -> . <expression>
P9 @2-2 <expression> -> . <variable>
P10 @2-2 <expression> -> . <string>
P11 @2-2 <expression> -> . 'string' '(' <numeric expression> ')'
P12 @2-2 <expression> -> . <expression> '+' <expression>
F0 @0-3 :start -> <statements> .
P1 @0-3 <statements> -> . <statement>*
F1 @0-3 <statements> -> <statement>* .
P2 @3-3 <statement> -> . <assignment>
P3 @3-3 <statement> -> . <numeric assignment>
F3 @0-3 <statement> -> <numeric assignment> .
P4 @3-3 <assignment> -> . 'set' <variable> 'to' <expression>
P5 @3-3 <numeric assignment> -> . <variable> '=' <expression>
F5 @0-3 <numeric assignment> -> <variable> '=' <expression> .
F6 @2-3 <expression> -> <expression> .
F7 @2-3 <expression> -> <expression> .
F8 @2-3 <expression> -> <expression> .
F9 @2-3 <expression> -> <variable> .
R12:1 @2-3 <expression> -> <expression> . '+' <expression>
P8 @4-4 <expression> -> . <expression>
P9 @4-4 <expression> -> . <variable>
P10 @4-4 <expression> -> . <string>
P11 @4-4 <expression> -> . 'string' '(' <numeric expression> ')'
R12:2 @2-4 <expression> -> <expression> '+' . <expression>
F0 @0-5 :start -> <statements> .
P1 @0-5 <statements> -> . <statement>*
F1 @0-5 <statements> -> <statement>* .
P2 @5-5 <statement> -> . <assignment>
P3 @5-5 <statement> -> . <numeric assignment>
F3 @0-5 <statement> -> <numeric assignment> .
P4 @5-5 <assignment> -> . 'set' <variable> 'to' <expression>
P5 @5-5 <numeric assignment> -> . <variable> '=' <expression>
F5 @0-5 <numeric assignment> -> <variable> '=' <expression> .
F6 @2-5 <expression> -> <expression> .
F8 @4-5 <expression> -> <expression> .
F9 @4-5 <expression> -> <variable> .
R12:1 @2-5 <expression> -> <expression> . '+' <expression>
F12 @2-5 <expression> -> <expression> '+' <expression> .
END_PROGRESS_REPORT

# Marpa::R2::Display::End

$Data::Dumper::Indent = 0;
$Data::Dumper::Terse  = 1;

# Marpa::R2::Display
# name: SLIF progress(0) example

my $report0 = $slr->progress(0);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF progress() output at location 0
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

chomp( my $expected_report0 = <<'END_PROGRESS_REPORT');
[[0,0,0],[1,0,0],[2,0,0],[3,0,0],[4,0,0],[5,0,0]]
END_PROGRESS_REPORT
Marpa::R2::Test::is( Data::Dumper::Dumper($report0),
    $expected_report0, 'progress report at location 0' );

# Marpa::R2::Display::End

# Try again with negative index
$report0 = $slr->progress(-6);
Marpa::R2::Test::is( Data::Dumper::Dumper($report0),
    $expected_report0, 'progress report at location -6' );

my $report1 = $slr->progress(1);

# Marpa::R2::Display
# name: SLIF progress() output at location 1
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

chomp( my $expected_report1 = <<'END_PROGRESS_REPORT');
[[5,1,0]]
END_PROGRESS_REPORT
Marpa::R2::Test::is( Data::Dumper::Dumper($report1),
    $expected_report1, 'progress report at location 1' );

# Marpa::R2::Display::End

# Try again with negative index
$report1 = $slr->progress(-5);
Marpa::R2::Test::is( Data::Dumper::Dumper($report1),
    $expected_report1, 'progress report at location -5' );

my $report2 = $slr->progress(2);

# Marpa::R2::Display
# name: SLIF progress() output at location 2
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

chomp( my $expected_report2 = <<'END_PROGRESS_REPORT');
[[6,0,2],[7,0,2],[8,0,2],[9,0,2],[10,0,2],[11,0,2],[12,0,2],[5,2,0]]
END_PROGRESS_REPORT
Marpa::R2::Test::is( Data::Dumper::Dumper($report2),
    $expected_report2, 'progress report at location 2' );

# Marpa::R2::Display::End

# Try again with negative index
$report2 = $slr->progress(-4);
Marpa::R2::Test::is( Data::Dumper::Dumper($report2),
    $expected_report2, 'progress report at location -4' );

# Marpa::R2::Display
# name: SLIF progress() example

my $latest_report = $slr->progress();

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF progress() output at default location
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

chomp( my $expected_default_report = <<'END_PROGRESS_REPORT');
[[0,-1,0],[1,-1,0],[3,-1,0],[5,-1,0],[6,-1,2],[8,-1,4],[9,-1,4],[12,-1,2],[1,0,0],[2,0,5],[3,0,5],[4,0,5],[5,0,5],[12,1,2]]
END_PROGRESS_REPORT
Marpa::R2::Test::is( Data::Dumper::Dumper($latest_report),
    $expected_default_report, 'progress report at default location' );

# Marpa::R2::Display::End

chomp( my $expected_report3 = <<'END_PROGRESS_REPORT');
[[0,-1,0],[1,-1,0],[3,-1,0],[5,-1,0],[6,-1,2],[7,-1,2],[8,-1,2],[9,-1,2],[1,0,0],[2,0,3],[3,0,3],[4,0,3],[5,0,3],[12,1,2]]
END_PROGRESS_REPORT

# Try latest report again with explicit index
my $report3 = $slr->progress(3);
Marpa::R2::Test::is( Data::Dumper::Dumper($report3),
    $expected_report3, 'progress report at location 3' );

# Try latest report again with negative index
$latest_report = $slr->progress(-3);
Marpa::R2::Test::is( Data::Dumper::Dumper($latest_report),
    $expected_report3, 'progress report at location -3' );

# Marpa::R2::Display
# name: SLIF Debug Example Trace Output
# start-after-line: END_TRACE_OUTPUT
# end-before-line: '^END_TRACE_OUTPUT$'

Marpa::R2::Test::is( $trace_output, <<'END_TRACE_OUTPUT', 'trace output' );
Inaccessible symbol: Add
Inaccessible symbol: Term
Setting trace_terminals option
Expecting "Number" at earleme 0
Accepted "Number" at 0-1
Expecting "Multiply" at 1
Accepted "Multiply" at 1-2
Expecting "Number" at 2
Accepted "Number" at 2-3
Expecting "Multiply" at 3
Rejected "Add" at 3-4
END_TRACE_OUTPUT

# Marpa::R2::Display::End

$slif_debug_source =~
    s{^ [<] numeric \s+ assignment [>] \s+ [:][:][=] \s+ variable \s+ ['][=]['] \s+ expression $}
    {<numeric assignment> ::= variable '=' <numeric expression>}xms;

$slg = Marpa::R2::Scanless::G->new(
    {
    bless_package => 'My_Nodes',
    source => \$slif_debug_source,
});

$slr = Marpa::R2::Scanless::R->new(
    { grammar => $slg } );

die if not defined $slr->read( \$test_input );
$value_ref = $slr->value();
my $expected_value_after_fix = \bless(
    [   bless(
            [   bless(
                    [   'a', '=',
                        bless(
                            [   bless(
                                    [   bless(
                                            ['8675309'],
                                            'My_Nodes::numeric_expression'
                                        ),
                                        '+',
                                        bless(
                                            ['42'],
                                            'My_Nodes::numeric_expression'
                                        )
                                    ],
                                    'My_Nodes::numeric_expression'
                                ),
                                '*',
                                bless(
                                    ['711'], 'My_Nodes::numeric_expression'
                                )
                            ],
                            'My_Nodes::numeric_expression'
                        )
                    ],
                    'My_Nodes::numeric_assignment'
                )
            ],
            'My_Nodes::statement'
        )
    ],
    'My_Nodes::statements'
);
Test::More::is_deeply($value_ref, $expected_value_after_fix, 'Value after fix');

my $show_rules_output = $slg->show_rules(3);
Marpa::R2::Test::is( $show_rules_output,
    <<'END_OF_SHOW_RULES_OUTPUT', 'SLIF show_rules()' );
G1 Rules:
G1 R0 :start ::= <statements>
G1 R1 <statements> ::= <statement> *
G1 R2 <statement> ::= <assignment>
G1 R3 <statement> ::= <numeric assignment>
G1 R4 <assignment> ::= 'set' <variable> 'to' <expression>
G1 R5 <numeric assignment> ::= <variable> '=' <numeric expression>
G1 R6 <expression> ::= <expression>
G1 R7 <expression> ::= <expression>
G1 R8 <expression> ::= <expression>
G1 R9 <expression> ::= <variable>
G1 R10 <expression> ::= <string>
G1 R11 <expression> ::= 'string' '(' <numeric expression> ')'
G1 R12 <expression> ::= <expression> '+' <expression>
G1 R13 <numeric expression> ::= <numeric expression>
G1 R14 <numeric expression> ::= <numeric expression>
G1 R15 <numeric expression> ::= <numeric expression>
G1 R16 <numeric expression> ::= <variable>
G1 R17 <numeric expression> ::= <number>
G1 R18 <numeric expression> ::= <numeric expression> '+' <numeric expression>
G1 R19 <numeric expression> ::= <numeric expression> '*' <numeric expression>
Lex (G0) Rules:
G0 R0 'set' ::= [s] [e] [t]
G0 R1 'to' ::= [t] [o]
G0 R2 '=' ::= [\=]
G0 R3 'string' ::= [s] [t] [r] [i] [n] [g]
G0 R4 '(' ::= [\(]
G0 R5 ')' ::= [\)]
G0 R6 '+' ::= [\+]
G0 R7 '+' ::= [\+]
G0 R8 '*' ::= [\*]
G0 R9 <variable> ::= [\w] +
G0 R10 <number> ::= [\d] +
G0 R11 <string> ::= ['] <string contents> [']
G0 R12 <string contents> ::= [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}] +
G0 R13 :discard ::= <whitespace>
G0 R14 <whitespace> ::= [\s] +
G0 R15 :start_lex ::= :discard
G0 R16 :start_lex ::= 'set'
G0 R17 :start_lex ::= 'to'
G0 R18 :start_lex ::= '='
G0 R19 :start_lex ::= 'string'
G0 R20 :start_lex ::= '('
G0 R21 :start_lex ::= ')'
G0 R22 :start_lex ::= '+'
G0 R23 :start_lex ::= '+'
G0 R24 :start_lex ::= '*'
G0 R25 :start_lex ::= <number>
G0 R26 :start_lex ::= <string>
G0 R27 :start_lex ::= <variable>
END_OF_SHOW_RULES_OUTPUT

my $show_symbols_output = $slg->show_symbols();
Marpa::R2::Test::is( $show_symbols_output,
    <<'END_OF_SHOW_SYMBOLS_OUTPUT', 'SLIF show_symbols()' );
END_OF_SHOW_SYMBOLS_OUTPUT

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
