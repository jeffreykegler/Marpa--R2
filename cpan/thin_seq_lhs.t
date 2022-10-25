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

# Testing using deprecated methods of
# the thin interface

use 5.010001;
use strict;
use warnings;

use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;
use English qw( -no_match_vars );
use Fatal qw( close open );
use Data::Dumper;
use Marpa::R2;

my $grammar = Marpa::R2::Thin::G->new( { if => 1 } );
$grammar->force_valued();
my $symbol_S = $grammar->symbol_new();
$grammar->start_symbol_set($symbol_S);
my $symbol_seq = $grammar->symbol_new();
my $symbol_element     = $grammar->symbol_new();
my $start_rule_id = $grammar->rule_new( $symbol_S, [$symbol_seq] );
my $seq_rule_id = $grammar->sequence_new( $symbol_seq, $symbol_element, { min => 0});
$grammar->symbol_is_terminal_set($symbol_seq, 1);

$grammar->precompute();

my $recce = Marpa::R2::Thin::R->new($grammar);
$recce->start_input();

# The numbers from 1 to 3 are themselves --
# that is, they index their own token value.
# Important: zero cannot be itself!

my @token_values         = ( 0 .. 3 );
my $x_token_value                 = -1 + push @token_values, "x";

$recce->alternative( $symbol_element, $x_token_value, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_element, $x_token_value, 1 );
$recce->earleme_complete();

sub evalIt {
    my ($recce) = @_;
my $latest_earley_set_ID = $recce->latest_earley_set();
my $bocage        = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
my $order         = Marpa::R2::Thin::O->new($bocage);
my $tree          = Marpa::R2::Thin::T->new($order);
my @actual_values = ();
while ( $tree->next() ) {
    my $valuator = Marpa::R2::Thin::V->new($tree);
    my @stack    = ();
    STEP: while (1) {
        my ( $type, @step_data ) = $valuator->step();
        last STEP if not defined $type;
        if ( $type eq 'MARPA_STEP_TOKEN' ) {
            # say STDERR "TOKEN: ", join " ", @step_data;
            my ( undef, $token_value_ix, $arg_n ) = @step_data;
            $stack[$arg_n] = [ "TOKEN:", $token_values[$token_value_ix] ];
            next STEP;
        }
        if ( $type eq 'MARPA_STEP_RULE' ) {
            # say STDERR "RULE: ", join " ", @step_data;
            my ( $rule_id, $arg_0, $arg_n ) = @step_data;
            if ( $rule_id == $start_rule_id ) {
                # just leave value at stack 0 where it is
                next STEP;
            }
            if ( $rule_id == $seq_rule_id ) {
                my $elements = ["SEQ:"];
                for my $i ($arg_0 ... $arg_n) {
                    push @$elements, $stack[$i];
                }
                $stack[$arg_0] = $elements;
                next STEP;
            }
            die "Unknown rule $rule_id";
        } ## end if ( $type eq 'MARPA_STEP_RULE' )
        die "Unexpected step type: $type";
    } ## end STEP: while (1)
    push @actual_values, $stack[0];
} ## end while ( $tree->next() )
return \@actual_values;
}

my %expected_value = (
 q{\['SEQ:',['TOKEN:','x'],['TOKEN:','x']]} => 1,
);

my $actual_values = evalIt($recce);
my $i = 0;
for my $actual_value (@$actual_values) {
    my $dumped_value = Data::Dumper->new( [ \$actual_value ] )->Indent(0)->Terse(1)->Dump;
    if ( defined $expected_value{$dumped_value} ) {
        delete $expected_value{$dumped_value};
        Test::More::pass("Expected Value $i: $dumped_value");
    }
    else {
        Test::More::fail("Unexpected Value $i: $dumped_value");
    }
    $i++;
}

# vim: expandtab shiftwidth=4:
