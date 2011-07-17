#!/usr/bin/perl
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

use Fatal qw(open close);
use Test::More tests => 9;

use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::PP');
}

# Marpa::PP::Display
# name: Implementation Example

my $grammar = Marpa::Grammar->new(
    {   start          => 'Expression',
        actions        => 'My_Actions',
        default_action => 'first_arg',
        strip          => 0,
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

my $recce = Marpa::Recognizer->new( { grammar => $grammar } );

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

# Marpa::PP::Display::End

Marpa::Test::is( 49, $value, 'Implementation Example Value 1' );

$recce->reset_evaluation();

my $show_symbols_output = $grammar->show_symbols();

# Marpa::PP::Display
# name: Implementation Example show_symbols Output
# start-after-line: END_SYMBOLS
# end-before-line: '^END_SYMBOLS$'

Marpa::Test::is( $show_symbols_output,
    <<'END_SYMBOLS', 'Implementation Example Symbols' );
0: Expression, lhs=[0] rhs=[5] terminal
1: Term, lhs=[1 3] rhs=[0 3] terminal
2: Factor, lhs=[2 4] rhs=[1 4] terminal
3: Number, lhs=[] rhs=[2] terminal
4: Add, lhs=[] rhs=[3] terminal
5: Multiply, lhs=[] rhs=[4] terminal
6: Expression['], lhs=[5] rhs=[]
END_SYMBOLS

# Marpa::PP::Display::End

my $show_rules_output = $grammar->show_rules();

# Marpa::PP::Display
# name: Implementation Example show_rules Output
# start-after-line: END_RULES
# end-before-line: '^END_RULES$'

Marpa::Test::is( $show_rules_output,
    <<'END_RULES', 'Implementation Example Rules' );
0: Expression -> Term
1: Term -> Factor
2: Factor -> Number
3: Term -> Term Add Term
4: Factor -> Factor Multiply Factor
5: Expression['] -> Expression /* vlhs real=1 */
END_RULES

# Marpa::PP::Display::End

my $show_AHFA_output = $grammar->show_AHFA();

# Marpa::PP::Display
# name: Implementation Example show_AHFA Output
# start-after-line: END_AHFA
# end-before-line: '^END_AHFA$'

Marpa::Test::is( $show_AHFA_output,
    <<'END_AHFA', 'Implementation Example AHFA' );
* S0:
Expression['] -> . Expression
 <Expression> => S2; leo(Expression['])
* S1: predict
Expression -> . Term
Term -> . Factor
Factor -> . Number
Term -> . Term Add Term
Factor -> . Factor Multiply Factor
 <Factor> => S4
 <Number> => S5
 <Term> => S3
* S2: leo-c
Expression['] -> Expression .
* S3:
Expression -> Term .
Term -> Term . Add Term
 <Add> => S6; S7
* S4:
Term -> Factor .
Factor -> Factor . Multiply Factor
 <Multiply> => S8; S9
* S5:
Factor -> Number .
* S6:
Term -> Term Add . Term
 <Term> => S10; leo(Term)
* S7: predict
Term -> . Factor
Factor -> . Number
Term -> . Term Add Term
Factor -> . Factor Multiply Factor
 <Factor> => S4
 <Number> => S5
 <Term> => S11
* S8:
Factor -> Factor Multiply . Factor
 <Factor> => S12; leo(Factor)
* S9: predict
Factor -> . Number
Factor -> . Factor Multiply Factor
 <Factor> => S13
 <Number> => S5
* S10: leo-c
Term -> Term Add Term .
* S11:
Term -> Term . Add Term
 <Add> => S6; S7
* S12: leo-c
Factor -> Factor Multiply Factor .
* S13:
Factor -> Factor . Multiply Factor
 <Multiply> => S8; S9
END_AHFA

# Marpa::PP::Display::End

my $show_earley_sets_output = $recce->show_earley_sets();

# Marpa::PP::Display
# name: Implementation Example show_earley_sets Output
# start-after-line: END_EARLEY_SETS
# end-before-line: '^END_EARLEY_SETS$'

my $expected_earley_sets = <<'END_EARLEY_SETS';
Last Completed: 5; Furthest: 5
Earley Set 0
S0@0-0
S1@0-0
Earley Set 1
S2@0-1 [p=S0@0-0; c=S3@0-1]
S3@0-1 [p=S1@0-0; c=S4@0-1]
S4@0-1 [p=S1@0-0; c=S5@0-1]
S5@0-1 [p=S1@0-0; s=Number; t=\42]
Earley Set 2
S8@0-2 [p=S4@0-1; s=Multiply; t=\'*']
S9@2-2
Earley Set 3
S2@0-3 [p=S0@0-0; c=S3@0-3]
S3@0-3 [p=S1@0-0; c=S4@0-3]
S4@0-3 [p=S1@0-0; c=S12@0-3]
S12@0-3 [p=S8@0-2; c=S5@2-3]
S5@2-3 [p=S9@2-2; s=Number; t=\1]
S13@2-3 [p=S9@2-2; c=S5@2-3]
Earley Set 4
S6@0-4 [p=S3@0-3; s=Add; t=\'+']
S7@4-4
Earley Set 5
S2@0-5 [p=S0@0-0; c=S3@0-5]
S3@0-5 [p=S1@0-0; c=S10@0-5]
S10@0-5 [p=S6@0-4; c=S4@4-5]
S4@4-5 [p=S7@4-4; c=S5@4-5]
S5@4-5 [p=S7@4-4; s=Number; t=\7]
S11@4-5 [p=S7@4-4; c=S4@4-5]
END_EARLEY_SETS

# Marpa::PP::Display::End

Marpa::Test::is( $show_earley_sets_output,
    $expected_earley_sets, 'Implementation Example Earley Sets' );

my $trace_output;
open my $trace_fh, q{>}, \$trace_output;
$value_ref = $recce->value( { trace_fh => $trace_fh, trace_values => 1 } );
$recce->set( { trace_fh => \*STDOUT, trace_values => 0 } );
close $trace_fh;

$value = $value_ref ? ${$value_ref} : 'No Parse';
Marpa::Test::is( 49, $value, 'Implementation Example Value 2' );

# Marpa::PP::Display
# name: Implementation Example trace_values Output
# start-after-line: END_TRACE_OUTPUT
# end-before-line: '^END_TRACE_OUTPUT$'

my $expected_trace_output = <<'END_TRACE_OUTPUT';
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
Symbol count is 1, now 1 rules
END_TRACE_OUTPUT

# Marpa::PP::Display::End

Marpa::Test::is( $trace_output,
    $expected_trace_output, 'Implementation Example Trace Output' );

$recce->reset_evaluation();

$value_ref = $recce->value();
$value = $value_ref ? ${$value_ref} : 'No Parse';
Marpa::Test::is( 49, $value, 'Implementation Example Value 3' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
