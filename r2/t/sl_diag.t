#!perl
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

# Test of scannerless parsing -- diagnostics

use 5.010;
use strict;
use warnings;

use Test::More tests => 3;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $prefix_grammar = Marpa::R2::Scanless::G->new(
    {
        action_object        => 'My_Actions',
        default_action => 'do_arg0',
        source          => \(<<'END_OF_RULES'),
:start ::= Script
Script ::= Calculation* action => do_list
Calculation ::= Expression | ('say') Expression
Expression ::=
     Number
   | ('+') Expression Expression action => do_add
Number ~ [\d] +
:discard ~ whitespace
whitespace ~ [\s]+
# allow comments
:discard ~ <hash comment>
<hash comment> ~ <terminated hash comment> | <unterminated
   final hash comment>
<terminated hash comment> ~ '#' <hash comment body> <vertical space char>
<unterminated final hash comment> ~ '#' <hash comment body>
<hash comment body> ~ <hash comment char>*
<vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
<hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_OF_RULES
    }
);

package My_Actions;
our $SELF;
sub new { return $SELF }
sub do_list {
    my ($self, @results) = @_;
    return +(scalar @results) . ' results: ' . join q{ }, @results;
}

sub do_add  { shift; return $_[0] + $_[1] }
sub do_arg0 { shift; return shift; }

sub show_last_expression {
    my ($self) = @_;
    my $slr = $self->{slr};
    my ( $start, $end ) = $slr->last_completed_range('Expression');
    return if not defined $start;
    my $last_expression = $slr->range_to_string( $start, $end );
    return $last_expression;
} ## end sub show_last_expression

package main;

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $self = bless { grammar => $grammar }, 'My_Actions';
    local $My_Actions::SELF = $self;

    my $trace_output = q{};
    open my $trace_fh, q{>}, \$trace_output;
    my $recce = Marpa::R2::Scanless::R->new(
        {   grammar           => $grammar,
            trace_terminals   => 1,
            trace_file_handle => $trace_fh
        }
    );
    $self->{recce} = $recce;
    my ( $parse_value, $parse_status, $last_expression );

    my $eval_ok = eval { $recce->read( \$string ); 1 };
    close $trace_fh;

    if ( not defined $eval_ok ) {
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        die $self->show_last_expression(), $EVAL_ERROR;
    } ## end if ( not defined $eval_ok )
    my $value_ref = $recce->value;
    if ( not defined $value_ref ) {
        die join q{ },
            'Input read to end but no parse',
            $self->show_last_expression();
    }
    return $recce, ${$value_ref}, $trace_output;
} ## end sub my_parser

my @tests_data = (
    [ '+++ 1 2 3 + + 1 2 4',     '1 results: 13', 'Parse OK', 'entire input' ],
);

TEST:
for my $test_data (@tests_data) {
    my ($test_string,     $expected_value,
        $expected_result, $expected_last_expression
    ) = @{$test_data};
    my ( $recce, $actual_value, $trace_output ) =
        my_parser( $prefix_grammar, $test_string );

# Marpa::R2::Display
# name: Scanless show_progress() synopsis

    my $show_progress_output = $recce->show_progress();

# Marpa::R2::Display::End

    Marpa::R2::Test::is( $show_progress_output,
        <<'END_OF_EXPECTED_OUTPUT', qq{Scanless show_progess()} );
F0 @0-11 [:start] -> Script .
P1 @0-11 Script -> . Calculation*
F1 @0-11 Script -> Calculation* .
P2 @11-11 Calculation -> . Expression
F2 @0-11 Calculation -> Expression .
P3 @11-11 Calculation -> . [Lex-0] Expression
P4 @11-11 Expression -> . Number
F4 @10-11 Expression -> Number .
P5 @11-11 Expression -> . [Lex-1] Expression Expression
F5 x3 @0,6,10-11 Expression -> [Lex-1] Expression Expression .
END_OF_EXPECTED_OUTPUT

    Test::More::is( $actual_value, $expected_value,
        qq{Value of "$test_string"} );
    Test::More::is( $trace_output, <<'END_OF_OUTPUT', qq{Trace output} );
Found lexemes @0-1: [Lex-1]; value="+"
Found lexemes @1-2: [Lex-1]; value="+"
Found lexemes @2-3: [Lex-1]; value="+"
Found lexemes @4-5: Number; value="1"
Found lexemes @6-7: Number; value="2"
Found lexemes @8-9: Number; value="3"
Found lexemes @10-11: [Lex-1]; value="+"
Found lexemes @12-13: [Lex-1]; value="+"
Found lexemes @14-15: Number; value="1"
Found lexemes @16-17: Number; value="2"
Found lexemes @18-19: Number; value="4"
END_OF_OUTPUT
} ## end for my $test_data (@tests_data)

# vim: expandtab shiftwidth=4:
