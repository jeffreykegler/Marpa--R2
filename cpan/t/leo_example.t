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

use 5.010;
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

Marpa::R2::Test::is( $show_ahms_output, <<'END_AHFA', 'Leo Example AHFA' );
* S0:
Statement['] -> . Statement
* S1: predict
Statement -> . Expression
Expression -> . Lvalue AssignOp Expression
Expression -> . Lvalue AddAssignOp Expression
Expression -> . Lvalue MinusAssignOp Expression
Expression -> . Lvalue MultiplyAssignOp Expression
Expression -> . Variable
Lvalue -> . Variable
* S2:
Statement -> Expression .
* S3:
Expression -> Lvalue . AssignOp Expression
* S4:
Expression -> Lvalue AssignOp . Expression
* S5: predict
Expression -> . Lvalue AssignOp Expression
Expression -> . Lvalue AddAssignOp Expression
Expression -> . Lvalue MinusAssignOp Expression
Expression -> . Lvalue MultiplyAssignOp Expression
Expression -> . Variable
Lvalue -> . Variable
* S6:
Expression -> Lvalue AssignOp Expression .
* S7:
Expression -> Lvalue . AddAssignOp Expression
* S8:
Expression -> Lvalue AddAssignOp . Expression
* S9:
Expression -> Lvalue AddAssignOp Expression .
* S10:
Expression -> Lvalue . MinusAssignOp Expression
* S11:
Expression -> Lvalue MinusAssignOp . Expression
* S12:
Expression -> Lvalue MinusAssignOp Expression .
* S13:
Expression -> Lvalue . MultiplyAssignOp Expression
* S14:
Expression -> Lvalue MultiplyAssignOp . Expression
* S15:
Expression -> Lvalue MultiplyAssignOp Expression .
* S16:
Expression -> Variable .
* S17:
Lvalue -> Variable .
* S18:
Statement['] -> Statement .
END_AHFA

my $show_earley_sets_output_before = $recce->show_earley_sets();

Marpa::R2::Test::is( $show_earley_sets_output_before,
    <<'END_EARLEY_SETS', 'Leo Example Earley Sets "Before"' );
Last Completed: 9; Furthest: 9
Earley Set 0
S0@0-0
S1@0-0
Earley Set 1
S2@0-1 [p=S1@0-0; c=S16@0-1]
S3@0-1 [p=S1@0-0; c=S17@0-1]
S7@0-1 [p=S1@0-0; c=S17@0-1]
S10@0-1 [p=S1@0-0; c=S17@0-1]
S13@0-1 [p=S1@0-0; c=S17@0-1]
S16@0-1 [p=S1@0-0; s=Variable; t=\'a']
S17@0-1 [p=S1@0-0; s=Variable; t=\'a']
S18@0-1 [p=S0@0-0; c=S2@0-1]
Earley Set 2
S4@0-2 [p=S3@0-1; s=AssignOp; t=\'=']
S5@2-2
L1@2 ["Expression"; S4@0-2]
Earley Set 3
S2@0-3 [p=S1@0-0; c=S6@0-3]
S6@0-3 [l=L1@2; c=S16@2-3]
S18@0-3 [p=S0@0-0; c=S2@0-3]
S3@2-3 [p=S5@2-2; c=S17@2-3]
S7@2-3 [p=S5@2-2; c=S17@2-3]
S10@2-3 [p=S5@2-2; c=S17@2-3]
S13@2-3 [p=S5@2-2; c=S17@2-3]
S16@2-3 [p=S5@2-2; s=Variable; t=\'b']
S17@2-3 [p=S5@2-2; s=Variable; t=\'b']
Earley Set 4
S8@2-4 [p=S7@2-3; s=AddAssignOp; t=\'+=']
S5@4-4
L1@4 ["Expression"; L1@2; S8@2-4]
Earley Set 5
S2@0-5 [p=S1@0-0; c=S6@0-5]
S6@0-5 [l=L1@4; c=S16@4-5]
S18@0-5 [p=S0@0-0; c=S2@0-5]
S3@4-5 [p=S5@4-4; c=S17@4-5]
S7@4-5 [p=S5@4-4; c=S17@4-5]
S10@4-5 [p=S5@4-4; c=S17@4-5]
S13@4-5 [p=S5@4-4; c=S17@4-5]
S16@4-5 [p=S5@4-4; s=Variable; t=\'c']
S17@4-5 [p=S5@4-4; s=Variable; t=\'c']
Earley Set 6
S11@4-6 [p=S10@4-5; s=MinusAssignOp; t=\'-=']
S5@6-6
L1@6 ["Expression"; L1@4; S11@4-6]
Earley Set 7
S2@0-7 [p=S1@0-0; c=S6@0-7]
S6@0-7 [l=L1@6; c=S16@6-7]
S18@0-7 [p=S0@0-0; c=S2@0-7]
S3@6-7 [p=S5@6-6; c=S17@6-7]
S7@6-7 [p=S5@6-6; c=S17@6-7]
S10@6-7 [p=S5@6-6; c=S17@6-7]
S13@6-7 [p=S5@6-6; c=S17@6-7]
S16@6-7 [p=S5@6-6; s=Variable; t=\'d']
S17@6-7 [p=S5@6-6; s=Variable; t=\'d']
Earley Set 8
S14@6-8 [p=S13@6-7; s=MultiplyAssignOp; t=\'*=']
S5@8-8
L1@8 ["Expression"; L1@6; S14@6-8]
Earley Set 9
S2@0-9 [p=S1@0-0; c=S6@0-9]
S6@0-9 [l=L1@8; c=S16@8-9]
S18@0-9 [p=S0@0-0; c=S2@0-9]
S3@8-9 [p=S5@8-8; c=S17@8-9]
S7@8-9 [p=S5@8-8; c=S17@8-9]
S10@8-9 [p=S5@8-8; c=S17@8-9]
S13@8-9 [p=S5@8-8; c=S17@8-9]
S16@8-9 [p=S5@8-8; s=Variable; t=\'e']
S17@8-9 [p=S5@8-8; s=Variable; t=\'e']
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
