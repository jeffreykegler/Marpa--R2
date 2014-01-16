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

my $show_AHFA_output = $grammar->show_AHFA();

Marpa::R2::Test::is( $show_AHFA_output,
    <<'END_AHFA', 'Implementation Example AHFA' );
* S0:
Expression['] -> . Expression
* S1: predict
Expression -> . Term
Term -> . Factor
Factor -> . Number
Term -> . Term Add Term
Factor -> . Factor Multiply Factor
* S2:
Expression -> Term .
* S3:
Term -> Factor .
* S4:
Factor -> Number .
* S5:
Term -> Term . Add Term
* S6:
Term -> Term Add . Term
* S7: predict
Term -> . Factor
Factor -> . Number
Term -> . Term Add Term
Factor -> . Factor Multiply Factor
* S8: leo-c
Term -> Term Add Term .
* S9:
Factor -> Factor . Multiply Factor
* S10:
Factor -> Factor Multiply . Factor
* S11: predict
Factor -> . Number
Factor -> . Factor Multiply Factor
* S12: leo-c
Factor -> Factor Multiply Factor .
* S13:
Expression['] -> Expression .
END_AHFA

my $show_earley_sets_output = $recce->show_earley_sets();

my $expected_earley_sets = <<'END_EARLEY_SETS';
Last Completed: 5; Furthest: 5
Earley Set 0
S0@0-0
S1@0-0
Earley Set 1
S2@0-1 [p=S1@0-0; c=S3@0-1]
S3@0-1 [p=S1@0-0; c=S4@0-1]
S4@0-1 [p=S1@0-0; s=Number; t=\42]
S5@0-1 [p=S1@0-0; c=S3@0-1]
S9@0-1 [p=S1@0-0; c=S4@0-1]
S13@0-1 [p=S0@0-0; c=S2@0-1]
Earley Set 2
S10@0-2 [p=S9@0-1; s=Multiply; t=\'*']
S11@2-2
Earley Set 3
S2@0-3 [p=S1@0-0; c=S3@0-3]
S3@0-3 [p=S1@0-0; c=S12@0-3]
S5@0-3 [p=S1@0-0; c=S3@0-3]
S9@0-3 [p=S1@0-0; c=S12@0-3]
S12@0-3 [p=S10@0-2; c=S4@2-3]
S13@0-3 [p=S0@0-0; c=S2@0-3]
S4@2-3 [p=S11@2-2; s=Number; t=\1]
S9@2-3 [p=S11@2-2; c=S4@2-3]
Earley Set 4
S6@0-4 [p=S5@0-3; s=Add; t=\'+']
S7@4-4
Earley Set 5
S2@0-5 [p=S1@0-0; c=S8@0-5]
S5@0-5 [p=S1@0-0; c=S8@0-5]
S8@0-5 [p=S6@0-4; c=S3@4-5]
S13@0-5 [p=S0@0-0; c=S2@0-5]
S3@4-5 [p=S7@4-4; c=S4@4-5]
S4@4-5 [p=S7@4-4; s=Number; t=\7]
S5@4-5 [p=S7@4-4; c=S3@4-5]
S9@4-5 [p=S7@4-4; c=S4@4-5]
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
