#!perl
# Copyright 2012 Jeffrey Kegler
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

# Testing an ambiguous equation
# using the thin interface

use 5.010;
use strict;
use warnings;

use Test::More tests => 11;

use lib 'inc';
use Marpa::R2::Test;
use English qw( -no_match_vars );
use Fatal qw( close open );
use Marpa::R2;

# Marpa::R2::Display
# name: Thin example

my $grammar  = Marpa::R2::Thin::G->new();
my $symbol_S = $grammar->symbol_new();
my $symbol_E = $grammar->symbol_new();
$grammar->start_symbol_set($symbol_S);
my $symbol_op     = $grammar->symbol_new();
my $symbol_number = $grammar->symbol_new();
my $start_rule_id = $grammar->rule_new( $symbol_S, [$symbol_E] );
my $op_rule_id =
    $grammar->rule_new( $symbol_E, [ $symbol_E, $symbol_op, $symbol_E ] );
my $number_rule_id = $grammar->rule_new( $symbol_E, [$symbol_number] );
$grammar->precompute();

my $recce = Marpa::R2::Thin::R->new($grammar);
$recce->start_input();

# The numbers from 1 to 3 are themselves --
# that is, they index their own token value.
# Important: zero cannot be itself!

my @token_values         = ( 0 .. 3 );
my $zero                 = -1 + +push @token_values, 0;
my $minus_token_value    = -1 + push @token_values, q{-};
my $plus_token_value     = -1 + push @token_values, q{+};
my $multiply_token_value = -1 + push @token_values, q{*};

$recce->alternative( $symbol_number, 2, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_op, $minus_token_value, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_number, $zero, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_op, $multiply_token_value, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_number, 3, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_op, $plus_token_value, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_number, 1, 1 );
$recce->earleme_complete();

my $latest_earley_set_ID = $recce->latest_earley_set();
my $bocage        = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
my $order         = Marpa::R2::Thin::O->new($bocage);
my $tree          = Marpa::R2::Thin::T->new($order);
my @actual_values = ();
while ( $tree->next() ) {
    my $valuator = Marpa::R2::Thin::V->new($tree);
    $valuator->rule_is_valued_set( $op_rule_id,     1 );
    $valuator->rule_is_valued_set( $start_rule_id,  1 );
    $valuator->rule_is_valued_set( $number_rule_id, 1 );
    my @stack = ();
    STEP: while ( my ( $type, @step_data ) = $valuator->step() ) {
        last STEP if not defined $type;
        if ( $type eq 'MARPA_STEP_TOKEN' ) {
            my ( undef, $token_value_ix, $arg_n ) = @step_data;
            $stack[$arg_n] = $token_values[$token_value_ix];
            next STEP;
        }
        if ( $type eq 'MARPA_STEP_RULE' ) {
            my ( $rule_id, $arg_0, $arg_n ) = @step_data;
            if ( $rule_id == $start_rule_id ) {
                my ( $string, $value ) = @{ $stack[$arg_n] };
                $stack[$arg_0] = "$string == $value";
                next STEP;
            }
            if ( $rule_id == $number_rule_id ) {
                my $number = $stack[$arg_0];
                $stack[$arg_0] = [ $number, $number ];
                next STEP;
            }
            if ( $rule_id == $op_rule_id ) {
                my $op = $stack[ $arg_0 + 1 ];
                my ( $right_string, $right_value ) = @{ $stack[$arg_n] };
                my ( $left_string,  $left_value )  = @{ $stack[$arg_0] };
                my $value;
                my $text = '(' . $left_string . $op . $right_string . ')';
                if ( $op eq q{+} ) {
                    $stack[$arg_0] = [ $text, $left_value + $right_value ];
                    next STEP;
                }
                if ( $op eq q{-} ) {
                    $stack[$arg_0] = [ $text, $left_value - $right_value ];
                    next STEP;
                }
                if ( $op eq q{*} ) {
                    $stack[$arg_0] = [ $text, $left_value * $right_value ];
                    next STEP;
                }
                die "Unknown op: $op";
            } ## end if ( $rule_id == $op_rule_id )
            die "Unknown rule $rule_id";
        } ## end if ( $type eq 'MARPA_STEP_RULE' )
        die "Unexpected step type: $type";
    } ## end while ( my ( $type, @step_data ) = $valuator->step() )
    push @actual_values, $stack[0];
} ## end while ( $tree->next() )

# Marpa::R2::Display::End

my %expected_value = (
    '(2-(0*(3+1))) == 2' => 1,
    '(((2-0)*3)+1) == 7' => 1,
    '((2-(0*3))+1) == 3' => 1,
    '((2-0)*(3+1)) == 8' => 1,
    '(2-((0*3)+1)) == 1' => 1,
);

my $i = 0;
for my $actual_value (@actual_values) {
    if ( defined $expected_value{$actual_value} ) {
        delete $expected_value{$actual_value};
        Test::More::pass("Expected Value $i: $actual_value");
    }
    else {
        Test::More::fail("Unexpected Value $i: $actual_value");
    }
    $i++;
} ## end for my $actual_value (@actual_values)

# For the error methods, start clean,
# with a new, trivial grammar
$grammar = Marpa::R2::Thin::G->new();

# Marpa::R2::Display
# name: Thin grammar error methods

my @error_names       = Marpa::R2::Thin::error_names();
my $error_code        = $grammar->error_code();
my $error_name        = $error_names[$error_code];
my $error_description = $grammar->error();

# Marpa::R2::Display::End

Test::More::is( $error_code, 0, 'Grammar error code' );
Test::More::is( $error_name, 'MARPA_ERR_NONE', 'Grammar error name' );
Test::More::is( $error_description, 'No error', 'Grammar error description' );

$symbol_S = $grammar->symbol_new();
my $symbol_a = $grammar->symbol_new();
my $symbol_sep = $grammar->symbol_new();
$grammar->start_symbol_set($symbol_S);

# Marpa::R2::Display
# name: Thin sequence_new() example

my $sequence_rule_id = $grammar->sequence_new(
        $symbol_S,
        $symbol_a,
        {   separator => $symbol_sep,
            proper    => 0,
            min       => 1
        }
    );

# Marpa::R2::Display::End

$grammar->precompute();
my $event_ix = 0;

# Marpa::R2::Display
# name: Thin event() example

my ( $event_type, $value ) = $grammar->event( $event_ix++ ) ;

# Marpa::R2::Display::End

$recce = Marpa::R2::Thin::R->new($grammar);

# Marpa::R2::Display
# name: Thin recognizer error methods

$error_code        = $recce->error_code();
$error_name        = $error_names[$error_code];
$error_description = $recce->error();

# Marpa::R2::Display::End

Test::More::is( $error_code, 0, 'Recognizer error code' );
Test::More::is( $error_name, 'MARPA_ERR_NONE', 'Recognizer error name' );
Test::More::is( $error_description, 'No error',
    'Recognizer error description' );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
