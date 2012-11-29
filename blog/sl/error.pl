#!/usr/bin/perl
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

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa::R2 2.023008;

my $prefix_grammar = Marpa::R2::Grammar->new(
    {
        action_object        => 'My_Actions',
        default_action => 'do_arg0',
        scannerless => 1,
        rules          => [ <<'END_OF_RULES' ]
:start ::= Script
Script ::=
     Expression
   | 'say' Expression
Expression ::=
     Number
   | '+' Expression Expression action => do_add
Number ~ [\d] + action => do_number
END_OF_RULES
    }
);

package My_Actions;
our $SELF;
sub new { return $SELF }
sub do_number {
    my $self = shift;
    my $recce = $self->{recce};
    my ( $start, $end ) = Marpa::R2::Context::location();
    return $recce->sl_range_to_string($start, $end);
} ## end sub do_number

sub do_add  { shift;
# say +(scalar @_), " args: ", join "; ", @_;
return $_[0] + $_[1] }
sub do_arg0 { shift; return shift; }
sub do_arg1 { shift; return $_[1]; }

package main;

$prefix_grammar->precompute();

sub My_Error::last_completed_range {
    my ( $self, $symbol_name ) = @_;
    my $grammar      = $self->{grammar};
    my $recce        = $self->{recce};
    my @sought_rules = ();
    for my $rule_id ( $grammar->rule_ids() ) {
        my ($lhs) = $grammar->bnf_rule($rule_id);
        push @sought_rules, $rule_id if $lhs eq $symbol_name;
    }
    die "Looking for completion of non-existent rule lhs: $symbol_name"
        if not scalar @sought_rules;
    my $latest_earley_set = $recce->latest_earley_set();
    my $earley_set        = $latest_earley_set;

    # Initialize to one past the end, so we can tell if there were no hits
    my $first_origin = $latest_earley_set + 1;
    EARLEY_SET: while ( $earley_set >= 0 ) {
        my $report_items = $recce->progress($earley_set);
        ITEM: for my $report_item ( @{$report_items} ) {
            my ( $rule_id, $dot_position, $origin ) = @{$report_item};
            next ITEM if $dot_position != -1;
            next ITEM if not scalar grep { $_ == $rule_id } @sought_rules;
            next ITEM if $origin >= $first_origin;
            $first_origin = $origin;
        } ## end ITEM: for my $report_item ( @{$report_items} )
        last EARLEY_SET if $first_origin <= $latest_earley_set;
        $earley_set--;
    } ## end EARLEY_SET: while ( $earley_set >= 0 )
    return if $earley_set < 0;
    return ( $first_origin, $earley_set );
} ## end sub My_Error::last_completed_range

sub My_Error::show_last_expression {
    my ($self) = @_;
    my ( $start, $end ) = $self->last_completed_range('Expression');
    return 'No expression was successfully parsed' if not defined $start;
    my $last_expression = $self->{recce}->sl_range_to_string( $start, $end );
    return "Last expression successfully parsed was: $last_expression";
} ## end sub My_Error::show_last_expression

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $self = bless { grammar => $grammar, input => \$string, }, 'My_Error';
    local $My_Actions::SELF = $self;

    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );
    $self->{recce} = $recce;
    my $event_count;

    if ( not defined eval { $event_count = $recce->sl_read($string); 1 } ) {

        # Add last expression found, and rethrow
        my $eval_error = $EVAL_ERROR;
        chomp $eval_error;
        die $self->show_last_expression(), "\n", $eval_error, "\n";
    } ## end if ( not defined eval { $recce->sl_read($string)...})
    if (not defined $event_count) {
        die $self->show_last_expression(), "\n", $recce->sl_error();
    }
    my $value_ref = $recce->value;
    if ( not defined $value_ref ) {
        die $self->show_last_expression(), "\n",
            "No parse was found, after reading the entire input\n";
    }
    return ${$value_ref};
} ## end sub my_parser

TEST:
for my $test_string (
    '+++ 1 2 3 + + 1 2 4',
    'say + 1 2',
    '+ 1 say 2',
    '+ 1 2 3 + + 1 2 4',
    '+++',
    '++1 2++',
    '++1 2++3 4++',
    '1 + 2 +3  4 + 5 + 6 + 7',
    '+12',
    '+1234'
    )
{
    my $output;
    my $eval_ok =
        eval { $output = my_parser( $prefix_grammar, $test_string ); 1 };
    my $eval_error = $EVAL_ERROR;
    if ( not defined $eval_ok ) {
        chomp $eval_error;
        say q{=} x 30;
        print qq{Input was "$test_string"\n},
            qq{Parse failed, with this diagnostic:\n},
            $eval_error, "\n";
        next TEST;
    } ## end if ( not defined $eval_ok )
    say q{=} x 30;
    print qq{Input was "$test_string"\n},
        qq{Parse was successful, output was "$output"\n};
} ## end TEST: for my $test_string ( '+++ 1 2 3 + + 1 2 4', 'say + 1 2'...)

# vim: expandtab shiftwidth=4:
