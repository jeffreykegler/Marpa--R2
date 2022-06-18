#!/usr/bin/perl
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

use 5.010001;
use strict;
use warnings;

# This test case was originally developed as an example
# for the debugging of grammars with Leo items.  Fortunately,
# I found how to create
# much more user-friendly tools for debugging these grammars,
# so now these are simply Leo-oriented regression tests.

use Fatal qw(open close);
use Test::More tests => 6;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

my $grammar = Marpa::R2::Grammar->new(
    {   start          => 'Statement',
        actions        => 'My_Actions',
        default_action => 'first_arg',
        rules          => [
            {   lhs    => 'Statement',
                rhs    => [qw/Expression/],
                action => 'do_Statement'
            },
            {   lhs    => 'Expression',
                rhs    => [qw/Lvalue AssignOp Expression/],
                action => 'do_Expression'
            },
            {   lhs    => 'Expression',
                rhs    => [qw/Lvalue AddAssignOp Expression/],
                action => 'do_Expression'
            },
            {   lhs    => 'Expression',
                rhs    => [qw/Lvalue MinusAssignOp Expression/],
                action => 'do_Expression'
            },
            {   lhs    => 'Expression',
                rhs    => [qw/Lvalue MultiplyAssignOp Expression/],
                action => 'do_Expression'
            },
            {   lhs    => 'Expression',
                rhs    => [qw/Variable/],
                action => 'do_Expression'
            },
            { lhs => 'Lvalue', rhs => [qw/Variable/] },
        ],
    }
);

$grammar->precompute();

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

$recce->read( 'Variable',         'a' );
$recce->read( 'AssignOp',         q{=} );
$recce->read( 'Variable',         'b' );
$recce->read( 'AddAssignOp',      q{+=} );
$recce->read( 'Variable',         'c' );
$recce->read( 'MinusAssignOp',    q{-=} );
$recce->read( 'Variable',         'd' );
$recce->read( 'MultiplyAssignOp', q{*=} );
$recce->read( 'Variable',         'e' );

%My_Actions::VALUES = ( a => 711, b => 47, c => 1, d => 2, e => 3 );

sub My_Actions::do_Statement {
    return join q{ }, map { $_ . q{=} . $My_Actions::VALUES{$_} }
        sort keys %My_Actions::VALUES;
}

sub My_Actions::do_Expression {
    my ( undef, $lvariable, $op, $rvalue ) = @_;
    my $original_value = $My_Actions::VALUES{$lvariable};
    return $original_value if not defined $rvalue;
    return
        $My_Actions::VALUES{$lvariable} =
          $op eq q{*=} ? ( $original_value * $rvalue )
        : $op eq q{+=} ? ( $original_value + $rvalue )
        : $op eq q{-=} ? ( $original_value - $rvalue )
        : $rvalue

} ## end sub My_Actions::do_Expression

sub My_Actions::first_arg { return $_[1] }

## use critic

my $show_symbols_output = $grammar->show_symbols();

Marpa::R2::Test::is( $show_symbols_output,
    <<'END_SYMBOLS', 'Leo Example Symbols' );
0: Statement
1: Expression
2: Lvalue
3: AssignOp, terminal
4: AddAssignOp, terminal
5: MinusAssignOp, terminal
6: MultiplyAssignOp, terminal
7: Variable, terminal
END_SYMBOLS

my $show_rules_output = $grammar->show_rules();

Marpa::R2::Test::is( $show_rules_output, <<'END_RULES', 'Leo Example Rules' );
0: Statement -> Expression
1: Expression -> Lvalue AssignOp Expression
2: Expression -> Lvalue AddAssignOp Expression
3: Expression -> Lvalue MinusAssignOp Expression
4: Expression -> Lvalue MultiplyAssignOp Expression
5: Expression -> Variable
6: Lvalue -> Variable
END_RULES

my $show_ahms_output = $grammar->show_ahms();

Marpa::R2::Test::is( $show_ahms_output, <<'END_AHMS', 'Leo Example AHMs' );
AHM 0: postdot = "Expression"
    Statement ::= . Expression
AHM 1: completion
    Statement ::= Expression .
AHM 2: postdot = "Lvalue"
    Expression ::= . Lvalue AssignOp Expression
AHM 3: postdot = "AssignOp"
    Expression ::= Lvalue . AssignOp Expression
AHM 4: postdot = "Expression"
    Expression ::= Lvalue AssignOp . Expression
AHM 5: completion
    Expression ::= Lvalue AssignOp Expression .
AHM 6: postdot = "Lvalue"
    Expression ::= . Lvalue AddAssignOp Expression
AHM 7: postdot = "AddAssignOp"
    Expression ::= Lvalue . AddAssignOp Expression
AHM 8: postdot = "Expression"
    Expression ::= Lvalue AddAssignOp . Expression
AHM 9: completion
    Expression ::= Lvalue AddAssignOp Expression .
AHM 10: postdot = "Lvalue"
    Expression ::= . Lvalue MinusAssignOp Expression
AHM 11: postdot = "MinusAssignOp"
    Expression ::= Lvalue . MinusAssignOp Expression
AHM 12: postdot = "Expression"
    Expression ::= Lvalue MinusAssignOp . Expression
AHM 13: completion
    Expression ::= Lvalue MinusAssignOp Expression .
AHM 14: postdot = "Lvalue"
    Expression ::= . Lvalue MultiplyAssignOp Expression
AHM 15: postdot = "MultiplyAssignOp"
    Expression ::= Lvalue . MultiplyAssignOp Expression
AHM 16: postdot = "Expression"
    Expression ::= Lvalue MultiplyAssignOp . Expression
AHM 17: completion
    Expression ::= Lvalue MultiplyAssignOp Expression .
AHM 18: postdot = "Variable"
    Expression ::= . Variable
AHM 19: completion
    Expression ::= Variable .
AHM 20: postdot = "Variable"
    Lvalue ::= . Variable
AHM 21: completion
    Lvalue ::= Variable .
AHM 22: postdot = "Statement"
    Statement['] ::= . Statement
AHM 23: completion
    Statement['] ::= Statement .
END_AHMS

my $show_earley_sets_output_before = $recce->show_earley_sets();

Marpa::R2::Test::is( $show_earley_sets_output_before,
    <<'END_EARLEY_SETS', 'Leo Example Earley Sets "Before"' );
Last Completed: 9; Furthest: 9
Earley Set 0
ahm22: R7:0@0-0
  R7:0: Statement['] ::= . Statement
ahm0: R0:0@0-0
  R0:0: Statement ::= . Expression
ahm2: R1:0@0-0
  R1:0: Expression ::= . Lvalue AssignOp Expression
ahm6: R2:0@0-0
  R2:0: Expression ::= . Lvalue AddAssignOp Expression
ahm10: R3:0@0-0
  R3:0: Expression ::= . Lvalue MinusAssignOp Expression
ahm14: R4:0@0-0
  R4:0: Expression ::= . Lvalue MultiplyAssignOp Expression
ahm18: R5:0@0-0
  R5:0: Expression ::= . Variable
ahm20: R6:0@0-0
  R6:0: Lvalue ::= . Variable
Earley Set 1
ahm21: R6$@0-1
  R6$: Lvalue ::= Variable .
  [c=R6:0@0-0; s=Variable; t=\'a']
ahm19: R5$@0-1
  R5$: Expression ::= Variable .
  [c=R5:0@0-0; s=Variable; t=\'a']
ahm1: R0$@0-1
  R0$: Statement ::= Expression .
  [p=R0:0@0-0; c=R5$@0-1]
ahm23: R7$@0-1
  R7$: Statement['] ::= Statement .
  [p=R7:0@0-0; c=R0$@0-1]
ahm15: R4:1@0-1
  R4:1: Expression ::= Lvalue . MultiplyAssignOp Expression
  [p=R4:0@0-0; c=R6$@0-1]
ahm11: R3:1@0-1
  R3:1: Expression ::= Lvalue . MinusAssignOp Expression
  [p=R3:0@0-0; c=R6$@0-1]
ahm7: R2:1@0-1
  R2:1: Expression ::= Lvalue . AddAssignOp Expression
  [p=R2:0@0-0; c=R6$@0-1]
ahm3: R1:1@0-1
  R1:1: Expression ::= Lvalue . AssignOp Expression
  [p=R1:0@0-0; c=R6$@0-1]
Earley Set 2
ahm4: R1:2@0-2
  R1:2: Expression ::= Lvalue AssignOp . Expression
  [c=R1:1@0-1; s=AssignOp; t=\'=']
ahm2: R1:0@2-2
  R1:0: Expression ::= . Lvalue AssignOp Expression
ahm6: R2:0@2-2
  R2:0: Expression ::= . Lvalue AddAssignOp Expression
ahm10: R3:0@2-2
  R3:0: Expression ::= . Lvalue MinusAssignOp Expression
ahm14: R4:0@2-2
  R4:0: Expression ::= . Lvalue MultiplyAssignOp Expression
ahm18: R5:0@2-2
  R5:0: Expression ::= . Variable
ahm20: R6:0@2-2
  R6:0: Lvalue ::= . Variable
L1@2 ["Expression"; S4@0-2]
Earley Set 3
ahm21: R6$@2-3
  R6$: Lvalue ::= Variable .
  [c=R6:0@2-2; s=Variable; t=\'b']
ahm19: R5$@2-3
  R5$: Expression ::= Variable .
  [c=R5:0@2-2; s=Variable; t=\'b']
ahm5: R1$@0-3
  R1$: Expression ::= Lvalue AssignOp Expression .
  [l=L1@2; c=R5$@2-3]
ahm1: R0$@0-3
  R0$: Statement ::= Expression .
  [p=R0:0@0-0; c=R1$@0-3]
ahm23: R7$@0-3
  R7$: Statement['] ::= Statement .
  [p=R7:0@0-0; c=R0$@0-3]
ahm15: R4:1@2-3
  R4:1: Expression ::= Lvalue . MultiplyAssignOp Expression
  [p=R4:0@2-2; c=R6$@2-3]
ahm11: R3:1@2-3
  R3:1: Expression ::= Lvalue . MinusAssignOp Expression
  [p=R3:0@2-2; c=R6$@2-3]
ahm7: R2:1@2-3
  R2:1: Expression ::= Lvalue . AddAssignOp Expression
  [p=R2:0@2-2; c=R6$@2-3]
ahm3: R1:1@2-3
  R1:1: Expression ::= Lvalue . AssignOp Expression
  [p=R1:0@2-2; c=R6$@2-3]
Earley Set 4
ahm8: R2:2@2-4
  R2:2: Expression ::= Lvalue AddAssignOp . Expression
  [c=R2:1@2-3; s=AddAssignOp; t=\'+=']
ahm2: R1:0@4-4
  R1:0: Expression ::= . Lvalue AssignOp Expression
ahm6: R2:0@4-4
  R2:0: Expression ::= . Lvalue AddAssignOp Expression
ahm10: R3:0@4-4
  R3:0: Expression ::= . Lvalue MinusAssignOp Expression
ahm14: R4:0@4-4
  R4:0: Expression ::= . Lvalue MultiplyAssignOp Expression
ahm18: R5:0@4-4
  R5:0: Expression ::= . Variable
ahm20: R6:0@4-4
  R6:0: Lvalue ::= . Variable
L1@4 ["Expression"; L1@2; S8@2-4]
Earley Set 5
ahm21: R6$@4-5
  R6$: Lvalue ::= Variable .
  [c=R6:0@4-4; s=Variable; t=\'c']
ahm19: R5$@4-5
  R5$: Expression ::= Variable .
  [c=R5:0@4-4; s=Variable; t=\'c']
ahm5: R1$@0-5
  R1$: Expression ::= Lvalue AssignOp Expression .
  [l=L1@4; c=R5$@4-5]
ahm1: R0$@0-5
  R0$: Statement ::= Expression .
  [p=R0:0@0-0; c=R1$@0-5]
ahm23: R7$@0-5
  R7$: Statement['] ::= Statement .
  [p=R7:0@0-0; c=R0$@0-5]
ahm15: R4:1@4-5
  R4:1: Expression ::= Lvalue . MultiplyAssignOp Expression
  [p=R4:0@4-4; c=R6$@4-5]
ahm11: R3:1@4-5
  R3:1: Expression ::= Lvalue . MinusAssignOp Expression
  [p=R3:0@4-4; c=R6$@4-5]
ahm7: R2:1@4-5
  R2:1: Expression ::= Lvalue . AddAssignOp Expression
  [p=R2:0@4-4; c=R6$@4-5]
ahm3: R1:1@4-5
  R1:1: Expression ::= Lvalue . AssignOp Expression
  [p=R1:0@4-4; c=R6$@4-5]
Earley Set 6
ahm12: R3:2@4-6
  R3:2: Expression ::= Lvalue MinusAssignOp . Expression
  [c=R3:1@4-5; s=MinusAssignOp; t=\'-=']
ahm2: R1:0@6-6
  R1:0: Expression ::= . Lvalue AssignOp Expression
ahm6: R2:0@6-6
  R2:0: Expression ::= . Lvalue AddAssignOp Expression
ahm10: R3:0@6-6
  R3:0: Expression ::= . Lvalue MinusAssignOp Expression
ahm14: R4:0@6-6
  R4:0: Expression ::= . Lvalue MultiplyAssignOp Expression
ahm18: R5:0@6-6
  R5:0: Expression ::= . Variable
ahm20: R6:0@6-6
  R6:0: Lvalue ::= . Variable
L1@6 ["Expression"; L1@4; S12@4-6]
Earley Set 7
ahm21: R6$@6-7
  R6$: Lvalue ::= Variable .
  [c=R6:0@6-6; s=Variable; t=\'d']
ahm19: R5$@6-7
  R5$: Expression ::= Variable .
  [c=R5:0@6-6; s=Variable; t=\'d']
ahm5: R1$@0-7
  R1$: Expression ::= Lvalue AssignOp Expression .
  [l=L1@6; c=R5$@6-7]
ahm1: R0$@0-7
  R0$: Statement ::= Expression .
  [p=R0:0@0-0; c=R1$@0-7]
ahm23: R7$@0-7
  R7$: Statement['] ::= Statement .
  [p=R7:0@0-0; c=R0$@0-7]
ahm15: R4:1@6-7
  R4:1: Expression ::= Lvalue . MultiplyAssignOp Expression
  [p=R4:0@6-6; c=R6$@6-7]
ahm11: R3:1@6-7
  R3:1: Expression ::= Lvalue . MinusAssignOp Expression
  [p=R3:0@6-6; c=R6$@6-7]
ahm7: R2:1@6-7
  R2:1: Expression ::= Lvalue . AddAssignOp Expression
  [p=R2:0@6-6; c=R6$@6-7]
ahm3: R1:1@6-7
  R1:1: Expression ::= Lvalue . AssignOp Expression
  [p=R1:0@6-6; c=R6$@6-7]
Earley Set 8
ahm16: R4:2@6-8
  R4:2: Expression ::= Lvalue MultiplyAssignOp . Expression
  [c=R4:1@6-7; s=MultiplyAssignOp; t=\'*=']
ahm2: R1:0@8-8
  R1:0: Expression ::= . Lvalue AssignOp Expression
ahm6: R2:0@8-8
  R2:0: Expression ::= . Lvalue AddAssignOp Expression
ahm10: R3:0@8-8
  R3:0: Expression ::= . Lvalue MinusAssignOp Expression
ahm14: R4:0@8-8
  R4:0: Expression ::= . Lvalue MultiplyAssignOp Expression
ahm18: R5:0@8-8
  R5:0: Expression ::= . Variable
ahm20: R6:0@8-8
  R6:0: Lvalue ::= . Variable
L1@8 ["Expression"; L1@6; S16@6-8]
Earley Set 9
ahm21: R6$@8-9
  R6$: Lvalue ::= Variable .
  [c=R6:0@8-8; s=Variable; t=\'e']
ahm19: R5$@8-9
  R5$: Expression ::= Variable .
  [c=R5:0@8-8; s=Variable; t=\'e']
ahm5: R1$@0-9
  R1$: Expression ::= Lvalue AssignOp Expression .
  [l=L1@8; c=R5$@8-9]
ahm1: R0$@0-9
  R0$: Statement ::= Expression .
  [p=R0:0@0-0; c=R1$@0-9]
ahm23: R7$@0-9
  R7$: Statement['] ::= Statement .
  [p=R7:0@0-0; c=R0$@0-9]
ahm15: R4:1@8-9
  R4:1: Expression ::= Lvalue . MultiplyAssignOp Expression
  [p=R4:0@8-8; c=R6$@8-9]
ahm11: R3:1@8-9
  R3:1: Expression ::= Lvalue . MinusAssignOp Expression
  [p=R3:0@8-8; c=R6$@8-9]
ahm7: R2:1@8-9
  R2:1: Expression ::= Lvalue . AddAssignOp Expression
  [p=R2:0@8-8; c=R6$@8-9]
ahm3: R1:1@8-9
  R1:1: Expression ::= Lvalue . AssignOp Expression
  [p=R1:0@8-8; c=R6$@8-9]
END_EARLEY_SETS

my $trace_output;
open my $trace_fh, q{>}, \$trace_output;
$recce->set( { trace_fh => $trace_fh, trace_values => 2 } );
my $value_ref = $recce->value();
close $trace_fh;

my $value = ref $value_ref ? ${$value_ref} : 'No Parse';
Marpa::R2::Test::is( $value, 'a=42 b=42 c=-5 d=6 e=3', 'Leo Example Value' );

my $show_earley_sets_output_after = $recce->show_earley_sets();

my $expected_trace_output = <<'END_TRACE_OUTPUT';
Setting trace_values option
Pushed value from R6:1@0-1S7@0: Variable = \'a'
Popping 1 values to evaluate R6:1@0-1S7@0, rule: 6: Lvalue -> Variable
Calculated and pushed value: 'a'
Pushed value from R1:2@0-2S3@1: AssignOp = \'='
Pushed value from R6:1@2-3S7@2: Variable = \'b'
Popping 1 values to evaluate R6:1@2-3S7@2, rule: 6: Lvalue -> Variable
Calculated and pushed value: 'b'
Pushed value from R2:2@2-4S4@3: AddAssignOp = \'+='
Pushed value from R6:1@4-5S7@4: Variable = \'c'
Popping 1 values to evaluate R6:1@4-5S7@4, rule: 6: Lvalue -> Variable
Calculated and pushed value: 'c'
Pushed value from R3:2@4-6S5@5: MinusAssignOp = \'-='
Pushed value from R6:1@6-7S7@6: Variable = \'d'
Popping 1 values to evaluate R6:1@6-7S7@6, rule: 6: Lvalue -> Variable
Calculated and pushed value: 'd'
Pushed value from R4:2@6-8S6@7: MultiplyAssignOp = \'*='
Pushed value from R5:1@8-9S7@8: Variable = \'e'
Popping 1 values to evaluate R5:1@8-9S7@8, rule: 5: Expression -> Variable
Calculated and pushed value: 3
Popping 3 values to evaluate R4:3@6-9C5@8, rule: 4: Expression -> Lvalue MultiplyAssignOp Expression
Calculated and pushed value: 6
Popping 3 values to evaluate R3:3@4-9C4@6, rule: 3: Expression -> Lvalue MinusAssignOp Expression
Calculated and pushed value: -5
Popping 3 values to evaluate R2:3@2-9C3@4, rule: 2: Expression -> Lvalue AddAssignOp Expression
Calculated and pushed value: 42
Popping 3 values to evaluate R1:3@0-9C2@2, rule: 1: Expression -> Lvalue AssignOp Expression
Calculated and pushed value: 42
Popping 1 values to evaluate R0:1@0-9C1@0, rule: 0: Statement -> Expression
Calculated and pushed value: 'a=42 b=42 c=-5 d=6 e=3'
New Virtual Rule: R7:1@0-9C0@0, rule: 7: Statement['] -> Statement
Real symbol count is 1
END_TRACE_OUTPUT

Marpa::R2::Test::is( $trace_output, $expected_trace_output,
    'Leo Example Trace Output' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
