#!perl
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

# This test uses the thin interface.  It tests the behavior of
# ambiguous nulls.  These occur if two nullable rules have the same
# LHS.

use 5.010001;
use strict;
use warnings;

use Test::More tests => 2;

use lib 'inc';
use Marpa::R2::Test;
use English qw( -no_match_vars );
use Fatal qw( close open );
use Data::Dumper;
use Marpa::R2;

my $grammar = Marpa::R2::Thin::G->new( { if => 1 } );
$grammar->force_valued();
my @symbol = ();
my $symbol_S = $grammar->symbol_new();
$symbol[$symbol_S] = "S";
$grammar->start_symbol_set($symbol_S);
my $symbol_amb = $grammar->symbol_new();
$symbol[$symbol_amb] = "AMB";
my $symbol_a = $grammar->symbol_new();
$symbol[$symbol_a] = "A";
my $symbol_b = $grammar->symbol_new();
$symbol[$symbol_b] = "B";
my $symbol_x = $grammar->symbol_new();
$symbol[$symbol_x] = "X";
my $symbol_y = $grammar->symbol_new();
$symbol[$symbol_y] = "Y";

my @rule = ();
my $start_rule_id  = $grammar->rule_new( $symbol_S, [$symbol_x, $symbol_amb, $symbol_y] );
$rule[$start_rule_id] = 'start';
my $amb1_rule_id = $grammar->rule_new( $symbol_amb, [$symbol_a, $symbol_b] );
$rule[$amb1_rule_id] = 'amb1';
my $amb2_rule_id = $grammar->rule_new( $symbol_amb, [$symbol_b, $symbol_a] );
$rule[$amb2_rule_id] = 'amb1';
my $a_rule_id = $grammar->rule_new( $symbol_a, [] );
$rule[$a_rule_id] = 'a';
my $b_rule_id = $grammar->rule_new( $symbol_b, [] );
$rule[$b_rule_id] = 'b';

$grammar->precompute();

my $recce = Marpa::R2::Thin::R->new($grammar);
$recce->start_input();

# The numbers from 1 to 3 are themselves --
# that is, they index their own token value.
# Important: zero cannot be itself!

my @token_values  = ( 0 .. 3 );
my $x_token_value = -1 + push @token_values, "x";
my $y_token_value = -1 + push @token_values, "y";

$recce->alternative( $symbol_x, $x_token_value, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_y, $x_token_value, 1 );
$recce->earleme_complete();

my %expected_value = ( q{\['X:', 'AMB:', 'Y:']} => 1, );

my $actual_values = evalIt($recce);
my $i             = 0;
for my $actual_value (@$actual_values) {
    my $dumped_value =
      Data::Dumper->new( [ \$actual_value ] )->Indent(0)->Terse(1)->Dump;
    if ( defined $expected_value{$dumped_value} ) {
        delete $expected_value{$dumped_value};
        Test::More::pass("Expected Value $i: $dumped_value");
    }
    else {
        Test::More::fail("Unexpected Value $i: $dumped_value");
    }
    $i++;
}
my @not_found = keys %expected_value;
my $not_found_count = scalar @not_found;
if ($not_found_count) {
        Test::More::fail("$not_found_count expected value(s) not found");
        for my $value (@not_found) {
            Test::More::diag("$value");
        }
} else {
        Test::More::ok("All expected values found");
}

my @rule_data = (
  [ 'AMB1', $amb1_rule_id ],
  [ 'AMB2', $amb2_rule_id ],
  [ 'A', $a_rule_id ],
  [ 'B', $b_rule_id ],
);

sub evalIt {
    my ($recce)              = @_;
    my $latest_earley_set_ID = $recce->latest_earley_set();
    my $bocage = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
    my $metric = $bocage->ambiguity_metric();
    Test::More::is($metric, 1, "Ambiguity metric");
    my $order  = Marpa::R2::Thin::O->new($bocage);
    my $tree   = Marpa::R2::Thin::T->new($order);
    my @actual_values = ();
    while ( $tree->next() ) {
        my $valuator = Marpa::R2::Thin::V->new($tree);
        my @stack    = ();
      STEP: while (1) {
            my ( $type, @step_data ) = $valuator->step();
            last STEP if not defined $type;
            if ( $type eq 'MARPA_STEP_TOKEN' ) {
                say STDERR "TOKEN: ", join " ", @step_data;
                my ( $sym_id, $token_value_ix, $arg_n ) = @step_data;
                my $tag = $symbol[$sym_id] . ':';
                $stack[$arg_n] = [ $tag, $token_values[$token_value_ix] ];
                next STEP;
            }
            if ( $type eq 'MARPA_STEP_NULLING_SYMBOL' ) {

                say STDERR "NULLING: ", join " ", @step_data;
                my ( $sym_id, $arg_n ) = @step_data;
                $stack[$arg_n] = [ $symbol[$sym_id] . ':' ];
                next STEP;
            }
            if ( $type eq 'MARPA_STEP_RULE' ) {

                say STDERR "RULE: ", join " ", @step_data;
                my ( $rule_id, $arg_0, $arg_n ) = @step_data;
                if ( $rule_id == $start_rule_id ) {

                    # just leave value at stack 0 where it is
                    next STEP;
                }
                    my $elements = [$rule[$rule_id] . ':'];
                    for my $i ( $arg_0 ... $arg_n ) {
                        push @$elements, $stack[$i];
                    }
                    $stack[$arg_0] = $elements;
                    next STEP;
                die "Unknown rule $rule_id";
            } ## end if ( $type eq 'MARPA_STEP_RULE' )
            die "Unexpected step type: $type";
        } ## end STEP: while (1)
        push @actual_values, $stack[0];
    } ## end while ( $tree->next() )
    return \@actual_values;
}

# vim: expandtab shiftwidth=4:
