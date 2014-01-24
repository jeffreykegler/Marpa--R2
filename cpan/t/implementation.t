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

use Fatal qw(open close);
use Test::More tests => 8;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $grammar = Marpa::R2::Grammar->new(
    {   start          => 'Expression',
        actions        => 'My_Actions',
        default_action => 'first_arg',
        rules          => [
            { lhs => 'Expression', rhs => [qw/Term/] },
            { lhs => 'Term',       rhs => [qw/Factor/] },
            { lhs => 'Factor',     rhs => [qw/Number/] },
            { lhs => 'Term', rhs => [qw/Term Add Term/], action => 'do_add' },
            {   lhs    => 'Factor',
                rhs    => [qw/Factor Multiply Factor/],
                action => 'do_multiply'
            },
        ],
    }
);

$grammar->precompute();

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

my @tokens = (
    [ 'Number',   42 ],
    [ 'Multiply', q{*} ],
    [ 'Number',   1 ],
    [ 'Add',      q{+} ],
    [ 'Number',   7 ],
);

for my $token_and_value (@tokens) {
    $recce->read( @{$token_and_value} );
}

sub My_Actions::do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub My_Actions::do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}

sub My_Actions::first_arg { shift; return shift; }

my $value_ref = $recce->value();
my $value = $value_ref ? ${$value_ref} : 'No Parse';

Marpa::R2::Test::is( 49, $value, 'Implementation Example Value 1' );

$recce->reset_evaluation();

my $show_symbols_output = $grammar->show_symbols();

Marpa::R2::Test::is( $show_symbols_output,
    <<'END_SYMBOLS', 'Implementation Example Symbols' );
0: Expression
1: Term
2: Factor
3: Number, terminal
4: Add, terminal
5: Multiply, terminal
END_SYMBOLS

my $show_rules_output = $grammar->show_rules();

Marpa::R2::Test::is( $show_rules_output,
    <<'END_RULES', 'Implementation Example Rules' );
0: Expression -> Term
1: Term -> Factor
2: Factor -> Number
3: Term -> Term Add Term
4: Factor -> Factor Multiply Factor
END_RULES

my $show_ahms_output = $grammar->show_ahms();

Marpa::R2::Test::is( $show_ahms_output,
    <<'END_AHM', 'Implementation Example AHMs' );
AHM 0: postdot = "Term"
    Expression ::= . Term
AHM 1: completion
    Expression ::= Term .
AHM 2: postdot = "Factor"
    Term ::= . Factor
AHM 3: completion
    Term ::= Factor .
AHM 4: postdot = "Number"
    Factor ::= . Number
AHM 5: completion
    Factor ::= Number .
AHM 6: postdot = "Term"
    Term ::= . Term Add Term
AHM 7: postdot = "Add"
    Term ::= Term . Add Term
AHM 8: postdot = "Term"
    Term ::= Term Add . Term
AHM 9: completion
    Term ::= Term Add Term .
AHM 10: postdot = "Factor"
    Factor ::= . Factor Multiply Factor
AHM 11: postdot = "Multiply"
    Factor ::= Factor . Multiply Factor
AHM 12: postdot = "Factor"
    Factor ::= Factor Multiply . Factor
AHM 13: completion
    Factor ::= Factor Multiply Factor .
AHM 14: postdot = "Expression"
    Expression['] ::= . Expression
AHM 15: completion
    Expression['] ::= Expression .
END_AHM

my $show_earley_sets_output = $recce->show_earley_sets();

my $expected_earley_sets = <<'END_EARLEY_SETS';
Last Completed: 5; Furthest: 5
Earley Set 0
ahm14: R5:0@0-0
  R5:0: Expression['] ::= . Expression
ahm0: R0:0@0-0
  R0:0: Expression ::= . Term
ahm2: R1:0@0-0
  R1:0: Term ::= . Factor
ahm4: R2:0@0-0
  R2:0: Factor ::= . Number
ahm6: R3:0@0-0
  R3:0: Term ::= . Term Add Term
ahm10: R4:0@0-0
  R4:0: Factor ::= . Factor Multiply Factor
Earley Set 1
ahm5: R2$@0-1
  R2$: Factor ::= Number .
  [c=R2:0@0-0; s=Number; t=\42]
ahm11: R4:1@0-1
  R4:1: Factor ::= Factor . Multiply Factor
  [p=R4:0@0-0; c=R2$@0-1]
ahm3: R1$@0-1
  R1$: Term ::= Factor .
  [p=R1:0@0-0; c=R2$@0-1]
ahm7: R3:1@0-1
  R3:1: Term ::= Term . Add Term
  [p=R3:0@0-0; c=R1$@0-1]
ahm1: R0$@0-1
  R0$: Expression ::= Term .
  [p=R0:0@0-0; c=R1$@0-1]
ahm15: R5$@0-1
  R5$: Expression['] ::= Expression .
  [p=R5:0@0-0; c=R0$@0-1]
Earley Set 2
ahm12: R4:2@0-2
  R4:2: Factor ::= Factor Multiply . Factor
  [c=R4:1@0-1; s=Multiply; t=\'*']
ahm4: R2:0@2-2
  R2:0: Factor ::= . Number
ahm10: R4:0@2-2
  R4:0: Factor ::= . Factor Multiply Factor
Earley Set 3
ahm5: R2$@2-3
  R2$: Factor ::= Number .
  [c=R2:0@2-2; s=Number; t=\1]
ahm11: R4:1@2-3
  R4:1: Factor ::= Factor . Multiply Factor
  [p=R4:0@2-2; c=R2$@2-3]
ahm13: R4$@0-3
  R4$: Factor ::= Factor Multiply Factor .
  [p=R4:2@0-2; c=R2$@2-3]
ahm11: R4:1@0-3
  R4:1: Factor ::= Factor . Multiply Factor
  [p=R4:0@0-0; c=R4$@0-3]
ahm3: R1$@0-3
  R1$: Term ::= Factor .
  [p=R1:0@0-0; c=R4$@0-3]
ahm7: R3:1@0-3
  R3:1: Term ::= Term . Add Term
  [p=R3:0@0-0; c=R1$@0-3]
ahm1: R0$@0-3
  R0$: Expression ::= Term .
  [p=R0:0@0-0; c=R1$@0-3]
ahm15: R5$@0-3
  R5$: Expression['] ::= Expression .
  [p=R5:0@0-0; c=R0$@0-3]
Earley Set 4
ahm8: R3:2@0-4
  R3:2: Term ::= Term Add . Term
  [c=R3:1@0-3; s=Add; t=\'+']
ahm2: R1:0@4-4
  R1:0: Term ::= . Factor
ahm4: R2:0@4-4
  R2:0: Factor ::= . Number
ahm6: R3:0@4-4
  R3:0: Term ::= . Term Add Term
ahm10: R4:0@4-4
  R4:0: Factor ::= . Factor Multiply Factor
Earley Set 5
ahm5: R2$@4-5
  R2$: Factor ::= Number .
  [c=R2:0@4-4; s=Number; t=\7]
ahm11: R4:1@4-5
  R4:1: Factor ::= Factor . Multiply Factor
  [p=R4:0@4-4; c=R2$@4-5]
ahm3: R1$@4-5
  R1$: Term ::= Factor .
  [p=R1:0@4-4; c=R2$@4-5]
ahm7: R3:1@4-5
  R3:1: Term ::= Term . Add Term
  [p=R3:0@4-4; c=R1$@4-5]
ahm9: R3$@0-5
  R3$: Term ::= Term Add Term .
  [p=R3:2@0-4; c=R1$@4-5]
ahm7: R3:1@0-5
  R3:1: Term ::= Term . Add Term
  [p=R3:0@0-0; c=R3$@0-5]
ahm1: R0$@0-5
  R0$: Expression ::= Term .
  [p=R0:0@0-0; c=R3$@0-5]
ahm15: R5$@0-5
  R5$: Expression['] ::= Expression .
  [p=R5:0@0-0; c=R0$@0-5]
END_EARLEY_SETS

Marpa::R2::Test::is( $show_earley_sets_output, $expected_earley_sets,
    'Implementation Example Earley Sets' );

my $trace_output;
open my $trace_fh, q{>}, \$trace_output;
$recce->set( { trace_fh => $trace_fh, trace_values => 2 } );
$value_ref = $recce->value();
$recce->set( { trace_fh => \*STDOUT, trace_values => 0 } );
close $trace_fh;

$value = $value_ref ? ${$value_ref} : 'No Parse';
Marpa::R2::Test::is( 49, $value, 'Implementation Example Value 2' );

my $expected_trace_output = <<'END_TRACE_OUTPUT';
Setting trace_values option
Pushed value from R2:1@0-1S3@0: Number = \42
Popping 1 values to evaluate R2:1@0-1S3@0, rule: 2: Factor -> Number
Calculated and pushed value: 42
Pushed value from R4:2@0-2S5@1: Multiply = \'*'
Pushed value from R2:1@2-3S3@2: Number = \1
Popping 1 values to evaluate R2:1@2-3S3@2, rule: 2: Factor -> Number
Calculated and pushed value: 1
Popping 3 values to evaluate R4:3@0-3C2@2, rule: 4: Factor -> Factor Multiply Factor
Calculated and pushed value: 42
Popping 1 values to evaluate R1:1@0-3C4@0, rule: 1: Term -> Factor
Calculated and pushed value: 42
Pushed value from R3:2@0-4S4@3: Add = \'+'
Pushed value from R2:1@4-5S3@4: Number = \7
Popping 1 values to evaluate R2:1@4-5S3@4, rule: 2: Factor -> Number
Calculated and pushed value: 7
Popping 1 values to evaluate R1:1@4-5C2@4, rule: 1: Term -> Factor
Calculated and pushed value: 7
Popping 3 values to evaluate R3:3@0-5C1@4, rule: 3: Term -> Term Add Term
Calculated and pushed value: 49
Popping 1 values to evaluate R0:1@0-5C3@0, rule: 0: Expression -> Term
Calculated and pushed value: 49
New Virtual Rule: R5:1@0-5C0@0, rule: 5: Expression['] -> Expression
Real symbol count is 1
END_TRACE_OUTPUT

Marpa::R2::Test::is( $trace_output, $expected_trace_output,
    'Implementation Example Trace Output' );

$recce->reset_evaluation();

$value_ref = $recce->value();
$value = $value_ref ? ${$value_ref} : 'No Parse';
Marpa::R2::Test::is( 49, $value, 'Implementation Example Value 3' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
