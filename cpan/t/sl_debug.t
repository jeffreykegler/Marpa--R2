#!/usr/bin/perl
# Copyright 2015 Jeffrey Kegler
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

use Test::More tests => 26;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my $progress_report = q{};

# Marpa::R2::Display
# name: SLIF debug example, part 1

my $slif_debug_source = <<'END_OF_SOURCE';
:default ::= action => ::array bless => ::lhs
:start ::= statements
statements ::= statement *
statement ::= assignment | <numeric assignment>
assignment ::= 'set' variable 'to' expression

# This is a deliberate error in the grammar
# The next line should be:
# <numeric assignment> ::= variable '=' <numeric expression>
# I have changed the <numeric expression>  to <expression> which
# will cause problems.
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

my $grammar = Marpa::R2::Scanless::G->new(
    {
    bless_package => 'My_Nodes',
    source => \$slif_debug_source,
});

# Marpa::R2::Display::End

## no critic (InputOutput::RequireBriefOpen)
open my $trace_fh, q{>}, \( my $trace_output = q{} );
## use critic

# Marpa::R2::Display
# name: SLIF grammar set() synopsis

$grammar->set( { trace_file_handle => $trace_fh } );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF debug example, part 2

my $recce = Marpa::R2::Scanless::R->new(
    { grammar => $grammar,
    trace_terminals => 1,
    trace_values => 1,
    } );

my $test_input = 'a = 8675309 + 42 * 711';
my $eval_error = $EVAL_ERROR if not eval { $recce->read( \$test_input ); 1 };

$progress_report = $recce->show_progress( 0, -1 );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF debug example error message
# start-after-line: END_OF_TEXT
# end-before-line: '^END_OF_TEXT$'

$eval_error =~ s/^(Marpa::R2 \s+ exception \s+ at) .*/$1\n/xms;
Marpa::R2::Test::is($eval_error, <<'END_OF_TEXT', 'Error message before fix');
Error in SLIF parse: No lexemes accepted at line 1, column 18
  Rejected lexeme #0: '*'; value="*"; length = 1
* String before error: a = 8675309 + 42\s
* The error was at line 1, column 18, and at character 0x002a '*', ...
* here: * 711
Marpa::R2 exception at
END_OF_TEXT

# Marpa::R2::Display::End


# Marpa::R2::Display
# name: SLIF debug example dump of value

my $value_ref = $recce->value();
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

# Marpa::R2::Display::End

Test::More::is_deeply( $value_ref, $expected_output, 'Value before fix' );

# Marpa::R2::Display
# name: SLIF debug example progress report
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

Marpa::R2::Test::is( $progress_report,
    <<'END_PROGRESS_REPORT', 'progress report' );
P0 @0-0 L0c0 statements -> . statement *
P1 @0-0 L0c0 statement -> . assignment
P2 @0-0 L0c0 statement -> . <numeric assignment>
P3 @0-0 L0c0 assignment -> . 'set' variable 'to' expression
P4 @0-0 L0c0 <numeric assignment> -> . variable '=' expression
P19 @0-0 L0c0 :start -> . statements
R4:1 @0-1 L1c1 <numeric assignment> -> variable . '=' expression
R4:2 @0-2 L1c1-3 <numeric assignment> -> variable '=' . expression
P5 @2-2 L1c3 expression -> . expression
P6 @2-2 L1c3 expression -> . expression
P7 @2-2 L1c3 expression -> . expression
P8 @2-2 L1c3 expression -> . variable
P9 @2-2 L1c3 expression -> . string
P10 @2-2 L1c3 expression -> . 'string' '(' <numeric expression> ')'
P11 @2-2 L1c3 expression -> . expression '+' expression
P0 @0-3 L1c1-11 statements -> . statement *
F0 @0-3 L1c1-11 statements -> statement * .
P1 @3-3 L1c5-11 statement -> . assignment
P2 @3-3 L1c5-11 statement -> . <numeric assignment>
F2 @0-3 L1c1-11 statement -> <numeric assignment> .
P3 @3-3 L1c5-11 assignment -> . 'set' variable 'to' expression
P4 @3-3 L1c5-11 <numeric assignment> -> . variable '=' expression
F4 @0-3 L1c1-11 <numeric assignment> -> variable '=' expression .
F5 @2-3 L1c3-11 expression -> expression .
F6 @2-3 L1c3-11 expression -> expression .
F7 @2-3 L1c3-11 expression -> expression .
F8 @2-3 L1c3-11 expression -> variable .
R11:1 @2-3 L1c3-11 expression -> expression . '+' expression
F19 @0-3 L1c1-11 :start -> statements .
P7 @4-4 L1c13 expression -> . expression
P8 @4-4 L1c13 expression -> . variable
P9 @4-4 L1c13 expression -> . string
P10 @4-4 L1c13 expression -> . 'string' '(' <numeric expression> ')'
R11:2 @2-4 L1c3-13 expression -> expression '+' . expression
P0 @0-5 L1c1-16 statements -> . statement *
F0 @0-5 L1c1-16 statements -> statement * .
P1 @5-5 L1c15-16 statement -> . assignment
P2 @5-5 L1c15-16 statement -> . <numeric assignment>
F2 @0-5 L1c1-16 statement -> <numeric assignment> .
P3 @5-5 L1c15-16 assignment -> . 'set' variable 'to' expression
P4 @5-5 L1c15-16 <numeric assignment> -> . variable '=' expression
F4 @0-5 L1c1-16 <numeric assignment> -> variable '=' expression .
F5 @2-5 L1c3-16 expression -> expression .
F7 @4-5 L1c13-16 expression -> expression .
F8 @4-5 L1c13-16 expression -> variable .
R11:1 @2-5 L1c3-16 expression -> expression . '+' expression
F11 @2-5 L1c3-16 expression -> expression '+' expression .
F19 @0-5 L1c1-16 :start -> statements .
END_PROGRESS_REPORT

# Marpa::R2::Display::End

$Data::Dumper::Indent = 0;
$Data::Dumper::Terse  = 1;

# Marpa::R2::Display
# name: SLIF progress(0) example

my $report0 = $recce->progress(0);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF progress() output at location 0
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

chomp( my $expected_report0 = <<'END_PROGRESS_REPORT');
[[0,0,0],[1,0,0],[2,0,0],[3,0,0],[4,0,0],[19,0,0]]
END_PROGRESS_REPORT
Marpa::R2::Test::is( Data::Dumper::Dumper($report0),
    $expected_report0, 'progress report at location 0' );

# Marpa::R2::Display::End

# Try again with negative index
$report0 = $recce->progress(-6);
Marpa::R2::Test::is( Data::Dumper::Dumper($report0),
    $expected_report0, 'progress report at location -6' );

my $report1 = $recce->progress(1);

# Marpa::R2::Display
# name: SLIF progress() output at location 1
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

chomp( my $expected_report1 = <<'END_PROGRESS_REPORT');
[[4,1,0]]
END_PROGRESS_REPORT
Marpa::R2::Test::is( Data::Dumper::Dumper($report1),
    $expected_report1, 'progress report at location 1' );

# Marpa::R2::Display::End

# Try again with negative index
$report1 = $recce->progress(-5);
Marpa::R2::Test::is( Data::Dumper::Dumper($report1),
    $expected_report1, 'progress report at location -5' );

my $report2 = $recce->progress(2);

# Marpa::R2::Display
# name: SLIF progress() output at location 2
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

chomp( my $expected_report2 = <<'END_PROGRESS_REPORT');
[[5,0,2],[6,0,2],[7,0,2],[8,0,2],[9,0,2],[10,0,2],[11,0,2],[4,2,0]]
END_PROGRESS_REPORT
Marpa::R2::Test::is( Data::Dumper::Dumper($report2),
    $expected_report2, 'progress report at location 2' );

# Marpa::R2::Display::End

# Try again with negative index
$report2 = $recce->progress(-4);
Marpa::R2::Test::is( Data::Dumper::Dumper($report2),
    $expected_report2, 'progress report at location -4' );

# Marpa::R2::Display
# name: SLIF progress() example

my $latest_report = $recce->progress();

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF progress() output at default location
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

chomp( my $expected_default_report = <<'END_PROGRESS_REPORT');
[[0,-1,0],[2,-1,0],[4,-1,0],[5,-1,2],[7,-1,4],[8,-1,4],[11,-1,2],[19,-1,0],[0,0,0],[1,0,5],[2,0,5],[3,0,5],[4,0,5],[11,1,2]]
END_PROGRESS_REPORT
Marpa::R2::Test::is( Data::Dumper::Dumper($latest_report),
    $expected_default_report, 'progress report at default location' );

# Marpa::R2::Display::End

chomp( my $expected_report3 = <<'END_PROGRESS_REPORT');
[[0,-1,0],[2,-1,0],[4,-1,0],[5,-1,2],[6,-1,2],[7,-1,2],[8,-1,2],[19,-1,0],[0,0,0],[1,0,3],[2,0,3],[3,0,3],[4,0,3],[11,1,2]]
END_PROGRESS_REPORT

# Try latest report again with explicit index
my $report3 = $recce->progress(3);
Marpa::R2::Test::is( Data::Dumper::Dumper($report3),
    $expected_report3, 'progress report at location 3' );

# Try latest report again with negative index
$latest_report = $recce->progress(-3);
Marpa::R2::Test::is( Data::Dumper::Dumper($latest_report),
    $expected_report3, 'progress report at location -3' );

# Marpa::R2::Display
# name: SLIF debug example trace output
# start-after-line: END_TRACE_OUTPUT
# end-before-line: '^END_TRACE_OUTPUT$'

Marpa::R2::Test::is( $trace_output, <<'END_TRACE_OUTPUT', 'trace output' );
Setting trace_terminals option
Setting trace_values option
Accepted lexeme L1c1 e1: variable; value="a"
Discarded lexeme L1c2: whitespace
Accepted lexeme L1c3 e2: '='; value="="
Discarded lexeme L1c4: whitespace
Rejected lexeme L1c5-11: number; value="8675309"
Accepted lexeme L1c5-11 e3: variable; value="8675309"
Discarded lexeme L1c12: whitespace
Rejected lexeme L1c13: '+'; value="+"
Accepted lexeme L1c13 e4: '+'; value="+"
Discarded lexeme L1c14: whitespace
Rejected lexeme L1c15-16: number; value="42"
Accepted lexeme L1c15-16 e5: variable; value="42"
Discarded lexeme L1c17: whitespace
Rejected lexeme L1c18: '*'; value="*"
END_TRACE_OUTPUT

# Marpa::R2::Display::End

$slif_debug_source =~
    s{^ [<] numeric \s+ assignment [>] \s+ [:][:][=] \s+ variable \s+ ['][=]['] \s+ expression $}
    {<numeric assignment> ::= variable '=' <numeric expression>}xms;

$grammar = Marpa::R2::Scanless::G->new(
    {
    bless_package => 'My_Nodes',
    source => \$slif_debug_source,
});

$recce = Marpa::R2::Scanless::R->new(
    { grammar => $grammar } );

die if not defined $recce->read( \$test_input );
$value_ref = $recce->value();
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

my $show_rules_output;
$show_rules_output .= "G1 Rules:\n";
$show_rules_output .= $grammar->show_rules(3);
$show_rules_output .= "Lex (L0) Rules:\n";

# Marpa::R2::Display
# name: SLG show_rules() synopsis with 2 args

$show_rules_output .= $grammar->show_rules(3, 'L0');

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF debug example show_rules() output
# start-after-line: END_OF_SHOW_RULES_OUTPUT
# end-before-line: '^END_OF_SHOW_RULES_OUTPUT$'

Marpa::R2::Test::is( $show_rules_output,
    <<'END_OF_SHOW_RULES_OUTPUT', 'SLIF show_rules()' );
G1 Rules:
G1 R0 statements ::= statement *
  Symbol IDs: <16> ::= <17>
  Internal symbols: <statements> ::= <statement>
G1 R1 statement ::= assignment
  Symbol IDs: <17> ::= <18>
  Internal symbols: <statement> ::= <assignment>
G1 R2 statement ::= <numeric assignment>
  Symbol IDs: <17> ::= <19>
  Internal symbols: <statement> ::= <numeric assignment>
G1 R3 assignment ::= 'set' variable 'to' expression
  Symbol IDs: <18> ::= <1> <20> <2> <21>
  Internal symbols: <assignment> ::= <[Lex-0]> <variable> <[Lex-1]> <expression>
G1 R4 <numeric assignment> ::= variable '=' <numeric expression>
  Symbol IDs: <19> ::= <20> <3> <22>
  Internal symbols: <numeric assignment> ::= <variable> <[Lex-2]> <numeric expression>
G1 R5 expression ::= expression
  Internal rule top priority rule for <expression>
  Symbol IDs: <21> ::= <10>
  Internal symbols: <expression> ::= <expression[0]>
G1 R6 expression ::= expression
  Internal rule for symbol <expression> priority transition from 0 to 1
  Symbol IDs: <10> ::= <11>
  Internal symbols: <expression[0]> ::= <expression[1]>
G1 R7 expression ::= expression
  Internal rule for symbol <expression> priority transition from 1 to 2
  Symbol IDs: <11> ::= <12>
  Internal symbols: <expression[1]> ::= <expression[2]>
G1 R8 expression ::= variable
  Symbol IDs: <12> ::= <20>
  Internal symbols: <expression[2]> ::= <variable>
G1 R9 expression ::= string
  Symbol IDs: <12> ::= <23>
  Internal symbols: <expression[2]> ::= <string>
G1 R10 expression ::= 'string' '(' <numeric expression> ')'
  Symbol IDs: <11> ::= <4> <5> <22> <6>
  Internal symbols: <expression[1]> ::= <[Lex-3]> <[Lex-4]> <numeric expression> <[Lex-5]>
G1 R11 expression ::= expression '+' expression
  Symbol IDs: <10> ::= <10> <7> <11>
  Internal symbols: <expression[0]> ::= <expression[0]> <[Lex-6]> <expression[1]>
G1 R12 <numeric expression> ::= <numeric expression>
  Internal rule top priority rule for <numeric expression>
  Symbol IDs: <22> ::= <13>
  Internal symbols: <numeric expression> ::= <numeric expression[0]>
G1 R13 <numeric expression> ::= <numeric expression>
  Internal rule for symbol <numeric expression> priority transition from 0 to 1
  Symbol IDs: <13> ::= <14>
  Internal symbols: <numeric expression[0]> ::= <numeric expression[1]>
G1 R14 <numeric expression> ::= <numeric expression>
  Internal rule for symbol <numeric expression> priority transition from 1 to 2
  Symbol IDs: <14> ::= <15>
  Internal symbols: <numeric expression[1]> ::= <numeric expression[2]>
G1 R15 <numeric expression> ::= variable
  Symbol IDs: <15> ::= <20>
  Internal symbols: <numeric expression[2]> ::= <variable>
G1 R16 <numeric expression> ::= number
  Symbol IDs: <15> ::= <24>
  Internal symbols: <numeric expression[2]> ::= <number>
G1 R17 <numeric expression> ::= <numeric expression> '+' <numeric expression>
  Symbol IDs: <14> ::= <14> <8> <15>
  Internal symbols: <numeric expression[1]> ::= <numeric expression[1]> <[Lex-7]> <numeric expression[2]>
G1 R18 <numeric expression> ::= <numeric expression> '*' <numeric expression>
  Symbol IDs: <13> ::= <13> <9> <14>
  Internal symbols: <numeric expression[0]> ::= <numeric expression[0]> <[Lex-8]> <numeric expression[1]>
G1 R19 :start ::= statements
  Symbol IDs: <0> ::= <16>
  Internal symbols: <[:start]> ::= <statements>
Lex (L0) Rules:
L0 R0 'set' ::= [s] [e] [t]
  Internal rule for single-quoted string 'set'
  Symbol IDs: <2> ::= <27> <21> <28>
  Internal symbols: <[Lex-0]> ::= <[[s]]> <[[e]]> <[[t]]>
L0 R1 'to' ::= [t] [o]
  Internal rule for single-quoted string 'to'
  Symbol IDs: <3> ::= <28> <25>
  Internal symbols: <[Lex-1]> ::= <[[t]]> <[[o]]>
L0 R2 '=' ::= [\=]
  Internal rule for single-quoted string '='
  Symbol IDs: <4> ::= <16>
  Internal symbols: <[Lex-2]> ::= <[[\=]]>
L0 R3 'string' ::= [s] [t] [r] [i] [n] [g]
  Internal rule for single-quoted string 'string'
  Symbol IDs: <5> ::= <27> <28> <26> <23> <24> <22>
  Internal symbols: <[Lex-3]> ::= <[[s]]> <[[t]]> <[[r]]> <[[i]]> <[[n]]> <[[g]]>
L0 R4 '(' ::= [\(]
  Internal rule for single-quoted string '('
  Symbol IDs: <6> ::= <12>
  Internal symbols: <[Lex-4]> ::= <[[\(]]>
L0 R5 ')' ::= [\)]
  Internal rule for single-quoted string ')'
  Symbol IDs: <7> ::= <13>
  Internal symbols: <[Lex-5]> ::= <[[\)]]>
L0 R6 '+' ::= [\+]
  Internal rule for single-quoted string '+'
  Symbol IDs: <8> ::= <15>
  Internal symbols: <[Lex-6]> ::= <[[\+]]>
L0 R7 '+' ::= [\+]
  Internal rule for single-quoted string '+'
  Symbol IDs: <9> ::= <15>
  Internal symbols: <[Lex-7]> ::= <[[\+]]>
L0 R8 '*' ::= [\*]
  Internal rule for single-quoted string '*'
  Symbol IDs: <10> ::= <14>
  Internal symbols: <[Lex-8]> ::= <[[\*]]>
L0 R9 variable ::= [\w] +
  Symbol IDs: <29> ::= <19>
  Internal symbols: <variable> ::= <[[\w]]>
L0 R10 number ::= [\d] +
  Symbol IDs: <30> ::= <17>
  Internal symbols: <number> ::= <[[\d]]>
L0 R11 string ::= ['] <string contents> [']
  Symbol IDs: <31> ::= <11> <32> <11>
  Internal symbols: <string> ::= <[[']]> <string contents> <[[']]>
L0 R12 <string contents> ::= [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}] +
  Symbol IDs: <32> ::= <20>
  Internal symbols: <string contents> ::= <[[^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]]>
L0 R13 :discard ::= whitespace
  Discard rule for <whitespace>
  Symbol IDs: <0> ::= <33>
  Internal symbols: <[:discard]> ::= <whitespace>
L0 R14 whitespace ::= [\s] +
  Symbol IDs: <33> ::= <18>
  Internal symbols: <whitespace> ::= <[[\s]]>
L0 R15 :start_lex ::= :discard
  Internal lexical start rule for <[:discard]>
  Symbol IDs: <1> ::= <0>
  Internal symbols: <[:start_lex]> ::= <[:discard]>
L0 R16 :start_lex ::= 'set'
  Internal lexical start rule for <[Lex-0]>
  Symbol IDs: <1> ::= <2>
  Internal symbols: <[:start_lex]> ::= <[Lex-0]>
L0 R17 :start_lex ::= 'to'
  Internal lexical start rule for <[Lex-1]>
  Symbol IDs: <1> ::= <3>
  Internal symbols: <[:start_lex]> ::= <[Lex-1]>
L0 R18 :start_lex ::= '='
  Internal lexical start rule for <[Lex-2]>
  Symbol IDs: <1> ::= <4>
  Internal symbols: <[:start_lex]> ::= <[Lex-2]>
L0 R19 :start_lex ::= 'string'
  Internal lexical start rule for <[Lex-3]>
  Symbol IDs: <1> ::= <5>
  Internal symbols: <[:start_lex]> ::= <[Lex-3]>
L0 R20 :start_lex ::= '('
  Internal lexical start rule for <[Lex-4]>
  Symbol IDs: <1> ::= <6>
  Internal symbols: <[:start_lex]> ::= <[Lex-4]>
L0 R21 :start_lex ::= ')'
  Internal lexical start rule for <[Lex-5]>
  Symbol IDs: <1> ::= <7>
  Internal symbols: <[:start_lex]> ::= <[Lex-5]>
L0 R22 :start_lex ::= '+'
  Internal lexical start rule for <[Lex-6]>
  Symbol IDs: <1> ::= <8>
  Internal symbols: <[:start_lex]> ::= <[Lex-6]>
L0 R23 :start_lex ::= '+'
  Internal lexical start rule for <[Lex-7]>
  Symbol IDs: <1> ::= <9>
  Internal symbols: <[:start_lex]> ::= <[Lex-7]>
L0 R24 :start_lex ::= '*'
  Internal lexical start rule for <[Lex-8]>
  Symbol IDs: <1> ::= <10>
  Internal symbols: <[:start_lex]> ::= <[Lex-8]>
L0 R25 :start_lex ::= number
  Internal lexical start rule for <number>
  Symbol IDs: <1> ::= <30>
  Internal symbols: <[:start_lex]> ::= <number>
L0 R26 :start_lex ::= string
  Internal lexical start rule for <string>
  Symbol IDs: <1> ::= <31>
  Internal symbols: <[:start_lex]> ::= <string>
L0 R27 :start_lex ::= variable
  Internal lexical start rule for <variable>
  Symbol IDs: <1> ::= <29>
  Internal symbols: <[:start_lex]> ::= <variable>
END_OF_SHOW_RULES_OUTPUT

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF show_symbols() synopsis

my $show_symbols_output;
$show_symbols_output .= "G1 Symbols:\n";
$show_symbols_output .= $grammar->show_symbols(3);
$show_symbols_output .= "Lex (L0) Symbols:\n";
$show_symbols_output .= $grammar->show_symbols(3, 'L0');

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF debug example show_symbols() output
# start-after-line: END_OF_SHOW_SYMBOLS_OUTPUT
# end-before-line: '^END_OF_SHOW_SYMBOLS_OUTPUT$'

Marpa::R2::Test::is( $show_symbols_output,
    <<'END_OF_SHOW_SYMBOLS_OUTPUT', 'SLIF show_symbols()' );
G1 Symbols:
G1 S0 :start -- Internal G1 start symbol
  Internal name: <[:start]>
G1 S1 'set' -- Internal lexical symbol for "'set'"
  /* terminal */
  Internal name: <[Lex-0]>
  SLIF name: 'set'
G1 S2 'to' -- Internal lexical symbol for "'to'"
  /* terminal */
  Internal name: <[Lex-1]>
  SLIF name: 'to'
G1 S3 '=' -- Internal lexical symbol for "'='"
  /* terminal */
  Internal name: <[Lex-2]>
  SLIF name: '='
G1 S4 'string' -- Internal lexical symbol for "'string'"
  /* terminal */
  Internal name: <[Lex-3]>
  SLIF name: 'string'
G1 S5 '(' -- Internal lexical symbol for "'('"
  /* terminal */
  Internal name: <[Lex-4]>
  SLIF name: '('
G1 S6 ')' -- Internal lexical symbol for "')'"
  /* terminal */
  Internal name: <[Lex-5]>
  SLIF name: ')'
G1 S7 '+' -- Internal lexical symbol for "'+'"
  /* terminal */
  Internal name: <[Lex-6]>
  SLIF name: '+'
G1 S8 '+' -- Internal lexical symbol for "'+'"
  /* terminal */
  Internal name: <[Lex-7]>
  SLIF name: '+'
G1 S9 '*' -- Internal lexical symbol for "'*'"
  /* terminal */
  Internal name: <[Lex-8]>
  SLIF name: '*'
G1 S10 expression -- <expression> at priority 0
  Internal name: <expression[0]>
  SLIF name: expression
G1 S11 expression -- <expression> at priority 1
  Internal name: <expression[1]>
  SLIF name: expression
G1 S12 expression -- <expression> at priority 2
  Internal name: <expression[2]>
  SLIF name: expression
G1 S13 <numeric expression> -- <numeric expression> at priority 0
  Internal name: <numeric expression[0]>
  SLIF name: numeric expression
G1 S14 <numeric expression> -- <numeric expression> at priority 1
  Internal name: <numeric expression[1]>
  SLIF name: numeric expression
G1 S15 <numeric expression> -- <numeric expression> at priority 2
  Internal name: <numeric expression[2]>
  SLIF name: numeric expression
G1 S16 statements
  Internal name: <statements>
G1 S17 statement
  Internal name: <statement>
G1 S18 assignment
  Internal name: <assignment>
G1 S19 <numeric assignment>
  Internal name: <numeric assignment>
G1 S20 variable
  /* terminal */
  Internal name: <variable>
G1 S21 expression
  Internal name: <expression>
G1 S22 <numeric expression>
  Internal name: <numeric expression>
G1 S23 string
  /* terminal */
  Internal name: <string>
G1 S24 number
  /* terminal */
  Internal name: <number>
Lex (L0) Symbols:
L0 S0 :discard -- Internal LHS for lexer "L0" discard
  Internal name: <[:discard]>
L0 S1 :start_lex -- Internal L0 (lexical) start symbol
  Internal name: <[:start_lex]>
L0 S2 'set' -- Internal lexical symbol for "'set'"
  Internal name: <[Lex-0]>
  SLIF name: 'set'
L0 S3 'to' -- Internal lexical symbol for "'to'"
  Internal name: <[Lex-1]>
  SLIF name: 'to'
L0 S4 '=' -- Internal lexical symbol for "'='"
  Internal name: <[Lex-2]>
  SLIF name: '='
L0 S5 'string' -- Internal lexical symbol for "'string'"
  Internal name: <[Lex-3]>
  SLIF name: 'string'
L0 S6 '(' -- Internal lexical symbol for "'('"
  Internal name: <[Lex-4]>
  SLIF name: '('
L0 S7 ')' -- Internal lexical symbol for "')'"
  Internal name: <[Lex-5]>
  SLIF name: ')'
L0 S8 '+' -- Internal lexical symbol for "'+'"
  Internal name: <[Lex-6]>
  SLIF name: '+'
L0 S9 '+' -- Internal lexical symbol for "'+'"
  Internal name: <[Lex-7]>
  SLIF name: '+'
L0 S10 '*' -- Internal lexical symbol for "'*'"
  Internal name: <[Lex-8]>
  SLIF name: '*'
L0 S11 ['] -- Character class: [']
  /* terminal */
  Internal name: <[[']]>
  SLIF name: [']
L0 S12 [\(] -- Character class: [\(]
  /* terminal */
  Internal name: <[[\(]]>
  SLIF name: [\(]
L0 S13 [\)] -- Character class: [\)]
  /* terminal */
  Internal name: <[[\)]]>
  SLIF name: [\)]
L0 S14 [\*] -- Character class: [\*]
  /* terminal */
  Internal name: <[[\*]]>
  SLIF name: [\*]
L0 S15 [\+] -- Character class: [\+]
  /* terminal */
  Internal name: <[[\+]]>
  SLIF name: [\+]
L0 S16 [\=] -- Character class: [\=]
  /* terminal */
  Internal name: <[[\=]]>
  SLIF name: [\=]
L0 S17 [\d] -- Character class: [\d]
  /* terminal */
  Internal name: <[[\d]]>
  SLIF name: [\d]
L0 S18 [\s] -- Character class: [\s]
  /* terminal */
  Internal name: <[[\s]]>
  SLIF name: [\s]
L0 S19 [\w] -- Character class: [\w]
  /* terminal */
  Internal name: <[[\w]]>
  SLIF name: [\w]
L0 S20 [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}] -- Character class: [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]
  /* terminal */
  Internal name: <[[^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]]>
  SLIF name: [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]
L0 S21 [e] -- Character class: [e]
  /* terminal */
  Internal name: <[[e]]>
  SLIF name: [e]
L0 S22 [g] -- Character class: [g]
  /* terminal */
  Internal name: <[[g]]>
  SLIF name: [g]
L0 S23 [i] -- Character class: [i]
  /* terminal */
  Internal name: <[[i]]>
  SLIF name: [i]
L0 S24 [n] -- Character class: [n]
  /* terminal */
  Internal name: <[[n]]>
  SLIF name: [n]
L0 S25 [o] -- Character class: [o]
  /* terminal */
  Internal name: <[[o]]>
  SLIF name: [o]
L0 S26 [r] -- Character class: [r]
  /* terminal */
  Internal name: <[[r]]>
  SLIF name: [r]
L0 S27 [s] -- Character class: [s]
  /* terminal */
  Internal name: <[[s]]>
  SLIF name: [s]
L0 S28 [t] -- Character class: [t]
  /* terminal */
  Internal name: <[[t]]>
  SLIF name: [t]
L0 S29 variable
  Internal name: <variable>
L0 S30 number
  Internal name: <number>
L0 S31 string
  Internal name: <string>
L0 S32 <string contents>
  Internal name: <string contents>
L0 S33 whitespace
  Internal name: <whitespace>
END_OF_SHOW_SYMBOLS_OUTPUT

# Marpa::R2::Display::End

our @TEST_ARRAY;
sub do_something { push @TEST_ARRAY, $_[0] }

@TEST_ARRAY = ();

# Marpa::R2::Display
# name: SLG symbol_ids() 2 arg synopsis

do_something($_) for $grammar->symbol_ids('L0');

# Marpa::R2::Display::End

Marpa::R2::Test::is(
    ( join "\n", @TEST_ARRAY ),
    ( join "\n", 0 .. 33 ),
    'L0 symbol ids'
);

@TEST_ARRAY = ();

# Marpa::R2::Display
# name: SLG symbol_ids() synopsis

do_something($_) for $grammar->symbol_ids();

# Marpa::R2::Display::End

Marpa::R2::Test::is(
    ( join "\n", @TEST_ARRAY ),
    ( join "\n", 0 .. 24 ),
    'G1 symbol ids'
);

@TEST_ARRAY = ();

# Marpa::R2::Display
# name: SLG rule_ids() synopsis

do_something($_) for $grammar->rule_ids();

# Marpa::R2::Display::End

Marpa::R2::Test::is(
    ( join "\n", @TEST_ARRAY, '' ),
    ( join "\n", 0 .. 19, '' ),
    'G1 rule ids'
);

@TEST_ARRAY = ();

# Marpa::R2::Display
# name: SLG rule_ids() 2 arg synopsis

do_something($_) for $grammar->rule_ids('L0');

# Marpa::R2::Display::End

Marpa::R2::Test::is(
    ( join "\n", @TEST_ARRAY, ''),
    ( join "\n", 0 .. 27, '' ),
    'L0 rule ids'
);

my $text;

$text = q{};

for my $rule_id ( $grammar->rule_ids() ) {

# Marpa::R2::Display
# name: SLG rule_expand() synopsis

    my ($lhs_id, @rhs_ids) = $grammar->rule_expand($rule_id);
    $text .= "Rule #$rule_id: $lhs_id ::= " . (join q{ }, @rhs_ids) . "\n";

# Marpa::R2::Display::End

}

Marpa::R2::Test::is( $text, <<'END_OF_TEXT', 'G1 symbol ids by rule id');
Rule #0: 16 ::= 17
Rule #1: 17 ::= 18
Rule #2: 17 ::= 19
Rule #3: 18 ::= 1 20 2 21
Rule #4: 19 ::= 20 3 22
Rule #5: 21 ::= 10
Rule #6: 10 ::= 11
Rule #7: 11 ::= 12
Rule #8: 12 ::= 20
Rule #9: 12 ::= 23
Rule #10: 11 ::= 4 5 22 6
Rule #11: 10 ::= 10 7 11
Rule #12: 22 ::= 13
Rule #13: 13 ::= 14
Rule #14: 14 ::= 15
Rule #15: 15 ::= 20
Rule #16: 15 ::= 24
Rule #17: 14 ::= 14 8 15
Rule #18: 13 ::= 13 9 14
Rule #19: 0 ::= 16
END_OF_TEXT

$text = q{};

for my $rule_id ( $grammar->rule_ids('L0') ) {

# Marpa::R2::Display
# name: SLG rule_expand() 2 args synopsis

    my ($lhs_id, @rhs_ids) = $grammar->rule_expand($rule_id, 'L0');
    $text .= "L0 Rule #$rule_id: $lhs_id ::= " . (join q{ }, @rhs_ids) . "\n";

# Marpa::R2::Display::End

}

Marpa::R2::Test::is( $text, <<'END_OF_TEXT', 'L0 symbol ids by rule id');
L0 Rule #0: 2 ::= 27 21 28
L0 Rule #1: 3 ::= 28 25
L0 Rule #2: 4 ::= 16
L0 Rule #3: 5 ::= 27 28 26 23 24 22
L0 Rule #4: 6 ::= 12
L0 Rule #5: 7 ::= 13
L0 Rule #6: 8 ::= 15
L0 Rule #7: 9 ::= 15
L0 Rule #8: 10 ::= 14
L0 Rule #9: 29 ::= 19
L0 Rule #10: 30 ::= 17
L0 Rule #11: 31 ::= 11 32 11
L0 Rule #12: 32 ::= 20
L0 Rule #13: 0 ::= 33
L0 Rule #14: 33 ::= 18
L0 Rule #15: 1 ::= 0
L0 Rule #16: 1 ::= 2
L0 Rule #17: 1 ::= 3
L0 Rule #18: 1 ::= 4
L0 Rule #19: 1 ::= 5
L0 Rule #20: 1 ::= 6
L0 Rule #21: 1 ::= 7
L0 Rule #22: 1 ::= 8
L0 Rule #23: 1 ::= 9
L0 Rule #24: 1 ::= 10
L0 Rule #25: 1 ::= 30
L0 Rule #26: 1 ::= 31
L0 Rule #27: 1 ::= 29
END_OF_TEXT

$text = q{};

for my $symbol_id ( $grammar->symbol_ids() ) {

# Marpa::R2::Display
# name: SLG symbol_name() synopsis

    my $name = $grammar->symbol_name($symbol_id);
    $text .= "symbol number: $symbol_id  name: $name\n";

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLG symbol_description() synopsis

    my $description = $grammar->symbol_description($symbol_id)
        // '[No description]';
    $text .= "symbol number: $symbol_id  description $description\n";

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLG symbol_display_form() synopsis

    my $display_form = $grammar->symbol_display_form($symbol_id);
    $text
        .= "symbol number: $symbol_id  name in display form: $display_form\n";

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLG symbol_dsl_form() synopsis

    my $dsl_form = $grammar->symbol_dsl_form($symbol_id)
        // '[No name in DSL form]';
    $text .= "symbol number: $symbol_id  DSL form: $dsl_form\n";

# Marpa::R2::Display::End

} ## end for my $symbol_id ( $grammar->symbol_ids() )

Marpa::R2::Test::is( $text, <<'END_OF_TEXT', 'G1 symbol names and description');
symbol number: 0  name: [:start]
symbol number: 0  description Internal G1 start symbol
symbol number: 0  name in display form: :start
symbol number: 0  DSL form: [No name in DSL form]
symbol number: 1  name: [Lex-0]
symbol number: 1  description Internal lexical symbol for "'set'"
symbol number: 1  name in display form: 'set'
symbol number: 1  DSL form: 'set'
symbol number: 2  name: [Lex-1]
symbol number: 2  description Internal lexical symbol for "'to'"
symbol number: 2  name in display form: 'to'
symbol number: 2  DSL form: 'to'
symbol number: 3  name: [Lex-2]
symbol number: 3  description Internal lexical symbol for "'='"
symbol number: 3  name in display form: '='
symbol number: 3  DSL form: '='
symbol number: 4  name: [Lex-3]
symbol number: 4  description Internal lexical symbol for "'string'"
symbol number: 4  name in display form: 'string'
symbol number: 4  DSL form: 'string'
symbol number: 5  name: [Lex-4]
symbol number: 5  description Internal lexical symbol for "'('"
symbol number: 5  name in display form: '('
symbol number: 5  DSL form: '('
symbol number: 6  name: [Lex-5]
symbol number: 6  description Internal lexical symbol for "')'"
symbol number: 6  name in display form: ')'
symbol number: 6  DSL form: ')'
symbol number: 7  name: [Lex-6]
symbol number: 7  description Internal lexical symbol for "'+'"
symbol number: 7  name in display form: '+'
symbol number: 7  DSL form: '+'
symbol number: 8  name: [Lex-7]
symbol number: 8  description Internal lexical symbol for "'+'"
symbol number: 8  name in display form: '+'
symbol number: 8  DSL form: '+'
symbol number: 9  name: [Lex-8]
symbol number: 9  description Internal lexical symbol for "'*'"
symbol number: 9  name in display form: '*'
symbol number: 9  DSL form: '*'
symbol number: 10  name: expression[0]
symbol number: 10  description <expression> at priority 0
symbol number: 10  name in display form: expression
symbol number: 10  DSL form: expression
symbol number: 11  name: expression[1]
symbol number: 11  description <expression> at priority 1
symbol number: 11  name in display form: expression
symbol number: 11  DSL form: expression
symbol number: 12  name: expression[2]
symbol number: 12  description <expression> at priority 2
symbol number: 12  name in display form: expression
symbol number: 12  DSL form: expression
symbol number: 13  name: numeric expression[0]
symbol number: 13  description <numeric expression> at priority 0
symbol number: 13  name in display form: <numeric expression>
symbol number: 13  DSL form: numeric expression
symbol number: 14  name: numeric expression[1]
symbol number: 14  description <numeric expression> at priority 1
symbol number: 14  name in display form: <numeric expression>
symbol number: 14  DSL form: numeric expression
symbol number: 15  name: numeric expression[2]
symbol number: 15  description <numeric expression> at priority 2
symbol number: 15  name in display form: <numeric expression>
symbol number: 15  DSL form: numeric expression
symbol number: 16  name: statements
symbol number: 16  description [No description]
symbol number: 16  name in display form: statements
symbol number: 16  DSL form: [No name in DSL form]
symbol number: 17  name: statement
symbol number: 17  description [No description]
symbol number: 17  name in display form: statement
symbol number: 17  DSL form: [No name in DSL form]
symbol number: 18  name: assignment
symbol number: 18  description [No description]
symbol number: 18  name in display form: assignment
symbol number: 18  DSL form: [No name in DSL form]
symbol number: 19  name: numeric assignment
symbol number: 19  description [No description]
symbol number: 19  name in display form: <numeric assignment>
symbol number: 19  DSL form: [No name in DSL form]
symbol number: 20  name: variable
symbol number: 20  description [No description]
symbol number: 20  name in display form: variable
symbol number: 20  DSL form: [No name in DSL form]
symbol number: 21  name: expression
symbol number: 21  description [No description]
symbol number: 21  name in display form: expression
symbol number: 21  DSL form: [No name in DSL form]
symbol number: 22  name: numeric expression
symbol number: 22  description [No description]
symbol number: 22  name in display form: <numeric expression>
symbol number: 22  DSL form: [No name in DSL form]
symbol number: 23  name: string
symbol number: 23  description [No description]
symbol number: 23  name in display form: string
symbol number: 23  DSL form: [No name in DSL form]
symbol number: 24  name: number
symbol number: 24  description [No description]
symbol number: 24  name in display form: number
symbol number: 24  DSL form: [No name in DSL form]
END_OF_TEXT

$text = q{};

for my $rule_id ( $grammar->rule_ids() ) {

# Marpa::R2::Display
# name: SLG rule_show() synopsis

    my $rule_description = $grammar->rule_show($rule_id);

# Marpa::R2::Display::End

    $text .= "$rule_description\n";

}

Marpa::R2::Test::is( $text, <<'END_OF_TEXT', 'G1 rule_show() by rule id');
statements ::= statement *
statement ::= assignment
statement ::= <numeric assignment>
assignment ::= 'set' variable 'to' expression
<numeric assignment> ::= variable '=' <numeric expression>
expression ::= expression
expression ::= expression
expression ::= expression
expression ::= variable
expression ::= string
expression ::= 'string' '(' <numeric expression> ')'
expression ::= expression '+' expression
<numeric expression> ::= <numeric expression>
<numeric expression> ::= <numeric expression>
<numeric expression> ::= <numeric expression>
<numeric expression> ::= variable
<numeric expression> ::= number
<numeric expression> ::= <numeric expression> '+' <numeric expression>
<numeric expression> ::= <numeric expression> '*' <numeric expression>
:start ::= statements
END_OF_TEXT

$text = q{};

for my $rule_id ( $grammar->rule_ids('L0') ) {

# Marpa::R2::Display
# name: SLG rule_show() 2 args synopsis

    my $rule_description = $grammar->rule_show($rule_id, 'L0');

# Marpa::R2::Display::End
    $text .= "$rule_description\n";

}

Marpa::R2::Test::is( $text, <<'END_OF_TEXT', 'L0 rule_show() by rule id');
'set' ::= [s] [e] [t]
'to' ::= [t] [o]
'=' ::= [\=]
'string' ::= [s] [t] [r] [i] [n] [g]
'(' ::= [\(]
')' ::= [\)]
'+' ::= [\+]
'+' ::= [\+]
'*' ::= [\*]
variable ::= [\w] +
number ::= [\d] +
string ::= ['] <string contents> [']
<string contents> ::= [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}] +
:discard ::= whitespace
whitespace ::= [\s] +
:start_lex ::= :discard
:start_lex ::= 'set'
:start_lex ::= 'to'
:start_lex ::= '='
:start_lex ::= 'string'
:start_lex ::= '('
:start_lex ::= ')'
:start_lex ::= '+'
:start_lex ::= '+'
:start_lex ::= '*'
:start_lex ::= number
:start_lex ::= string
:start_lex ::= variable
END_OF_TEXT

$text = '';

for my $symbol_id ( $grammar->symbol_ids('L0') ) {

# Marpa::R2::Display
# name: SLG symbol_name() 2 arg synopsis

    my $name = $grammar->symbol_name( $symbol_id, 'L0' );
    $text .= "L0 symbol number: $symbol_id  name: $name\n";

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLG symbol_description() 2 arg synopsis

    my $description = $grammar->symbol_description( $symbol_id, 'L0' )
        // '[No description]';
    $text .= "L0 symbol number: $symbol_id  description $description\n";

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLG symbol_display_form() 2 arg synopsis

    my $display_form = $grammar->symbol_display_form( $symbol_id, 'L0' );
    $text
        .= "L0 symbol number: $symbol_id  name in display form: $display_form\n";

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLG symbol_dsl_form() 2 arg synopsis

    my $dsl_form = $grammar->symbol_dsl_form( $symbol_id, 'L0' )
        // '[No name in DSL form]';
    $text .= "L0 symbol number: $symbol_id  DSL form: $dsl_form\n";

# Marpa::R2::Display::End

} ## end for my $symbol_id ( $grammar->symbol_ids('L0') )

Marpa::R2::Test::is( $text, <<'END_OF_TEXT', 'L0 symbol names and description');
L0 symbol number: 0  name: [:discard]
L0 symbol number: 0  description Internal LHS for lexer "L0" discard
L0 symbol number: 0  name in display form: :discard
L0 symbol number: 0  DSL form: [No name in DSL form]
L0 symbol number: 1  name: [:start_lex]
L0 symbol number: 1  description Internal L0 (lexical) start symbol
L0 symbol number: 1  name in display form: :start_lex
L0 symbol number: 1  DSL form: [No name in DSL form]
L0 symbol number: 2  name: [Lex-0]
L0 symbol number: 2  description Internal lexical symbol for "'set'"
L0 symbol number: 2  name in display form: 'set'
L0 symbol number: 2  DSL form: 'set'
L0 symbol number: 3  name: [Lex-1]
L0 symbol number: 3  description Internal lexical symbol for "'to'"
L0 symbol number: 3  name in display form: 'to'
L0 symbol number: 3  DSL form: 'to'
L0 symbol number: 4  name: [Lex-2]
L0 symbol number: 4  description Internal lexical symbol for "'='"
L0 symbol number: 4  name in display form: '='
L0 symbol number: 4  DSL form: '='
L0 symbol number: 5  name: [Lex-3]
L0 symbol number: 5  description Internal lexical symbol for "'string'"
L0 symbol number: 5  name in display form: 'string'
L0 symbol number: 5  DSL form: 'string'
L0 symbol number: 6  name: [Lex-4]
L0 symbol number: 6  description Internal lexical symbol for "'('"
L0 symbol number: 6  name in display form: '('
L0 symbol number: 6  DSL form: '('
L0 symbol number: 7  name: [Lex-5]
L0 symbol number: 7  description Internal lexical symbol for "')'"
L0 symbol number: 7  name in display form: ')'
L0 symbol number: 7  DSL form: ')'
L0 symbol number: 8  name: [Lex-6]
L0 symbol number: 8  description Internal lexical symbol for "'+'"
L0 symbol number: 8  name in display form: '+'
L0 symbol number: 8  DSL form: '+'
L0 symbol number: 9  name: [Lex-7]
L0 symbol number: 9  description Internal lexical symbol for "'+'"
L0 symbol number: 9  name in display form: '+'
L0 symbol number: 9  DSL form: '+'
L0 symbol number: 10  name: [Lex-8]
L0 symbol number: 10  description Internal lexical symbol for "'*'"
L0 symbol number: 10  name in display form: '*'
L0 symbol number: 10  DSL form: '*'
L0 symbol number: 11  name: [[']]
L0 symbol number: 11  description Character class: [']
L0 symbol number: 11  name in display form: [']
L0 symbol number: 11  DSL form: [']
L0 symbol number: 12  name: [[\(]]
L0 symbol number: 12  description Character class: [\(]
L0 symbol number: 12  name in display form: [\(]
L0 symbol number: 12  DSL form: [\(]
L0 symbol number: 13  name: [[\)]]
L0 symbol number: 13  description Character class: [\)]
L0 symbol number: 13  name in display form: [\)]
L0 symbol number: 13  DSL form: [\)]
L0 symbol number: 14  name: [[\*]]
L0 symbol number: 14  description Character class: [\*]
L0 symbol number: 14  name in display form: [\*]
L0 symbol number: 14  DSL form: [\*]
L0 symbol number: 15  name: [[\+]]
L0 symbol number: 15  description Character class: [\+]
L0 symbol number: 15  name in display form: [\+]
L0 symbol number: 15  DSL form: [\+]
L0 symbol number: 16  name: [[\=]]
L0 symbol number: 16  description Character class: [\=]
L0 symbol number: 16  name in display form: [\=]
L0 symbol number: 16  DSL form: [\=]
L0 symbol number: 17  name: [[\d]]
L0 symbol number: 17  description Character class: [\d]
L0 symbol number: 17  name in display form: [\d]
L0 symbol number: 17  DSL form: [\d]
L0 symbol number: 18  name: [[\s]]
L0 symbol number: 18  description Character class: [\s]
L0 symbol number: 18  name in display form: [\s]
L0 symbol number: 18  DSL form: [\s]
L0 symbol number: 19  name: [[\w]]
L0 symbol number: 19  description Character class: [\w]
L0 symbol number: 19  name in display form: [\w]
L0 symbol number: 19  DSL form: [\w]
L0 symbol number: 20  name: [[^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]]
L0 symbol number: 20  description Character class: [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]
L0 symbol number: 20  name in display form: [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]
L0 symbol number: 20  DSL form: [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]
L0 symbol number: 21  name: [[e]]
L0 symbol number: 21  description Character class: [e]
L0 symbol number: 21  name in display form: [e]
L0 symbol number: 21  DSL form: [e]
L0 symbol number: 22  name: [[g]]
L0 symbol number: 22  description Character class: [g]
L0 symbol number: 22  name in display form: [g]
L0 symbol number: 22  DSL form: [g]
L0 symbol number: 23  name: [[i]]
L0 symbol number: 23  description Character class: [i]
L0 symbol number: 23  name in display form: [i]
L0 symbol number: 23  DSL form: [i]
L0 symbol number: 24  name: [[n]]
L0 symbol number: 24  description Character class: [n]
L0 symbol number: 24  name in display form: [n]
L0 symbol number: 24  DSL form: [n]
L0 symbol number: 25  name: [[o]]
L0 symbol number: 25  description Character class: [o]
L0 symbol number: 25  name in display form: [o]
L0 symbol number: 25  DSL form: [o]
L0 symbol number: 26  name: [[r]]
L0 symbol number: 26  description Character class: [r]
L0 symbol number: 26  name in display form: [r]
L0 symbol number: 26  DSL form: [r]
L0 symbol number: 27  name: [[s]]
L0 symbol number: 27  description Character class: [s]
L0 symbol number: 27  name in display form: [s]
L0 symbol number: 27  DSL form: [s]
L0 symbol number: 28  name: [[t]]
L0 symbol number: 28  description Character class: [t]
L0 symbol number: 28  name in display form: [t]
L0 symbol number: 28  DSL form: [t]
L0 symbol number: 29  name: variable
L0 symbol number: 29  description [No description]
L0 symbol number: 29  name in display form: variable
L0 symbol number: 29  DSL form: [No name in DSL form]
L0 symbol number: 30  name: number
L0 symbol number: 30  description [No description]
L0 symbol number: 30  name in display form: number
L0 symbol number: 30  DSL form: [No name in DSL form]
L0 symbol number: 31  name: string
L0 symbol number: 31  description [No description]
L0 symbol number: 31  name in display form: string
L0 symbol number: 31  DSL form: [No name in DSL form]
L0 symbol number: 32  name: string contents
L0 symbol number: 32  description [No description]
L0 symbol number: 32  name in display form: <string contents>
L0 symbol number: 32  DSL form: [No name in DSL form]
L0 symbol number: 33  name: whitespace
L0 symbol number: 33  description [No description]
L0 symbol number: 33  name in display form: whitespace
L0 symbol number: 33  DSL form: [No name in DSL form]
END_OF_TEXT

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
