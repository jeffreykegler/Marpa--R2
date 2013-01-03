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

# Tests of scannerless parsing -- some corner cases,
# including exhaustion at G1 level

use 5.010;
use strict;
use warnings;

use Test::More tests => 30;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $source_template = <<'END_OF_SOURCE';
:start       ::= Number
Number       ::= number   # If I add '+' or '*' it will work...
%QUANTIFIER%
number       ~ [\d]+
:discard     ~ whitespace
whitespace   ~ [\s]+
END_OF_SOURCE

(my $source_bare = $source_template) =~ s/ %QUANTIFIER% / /xms;

my $grammar_bare = Marpa::R2::Scanless::G->new(
    {
        action_object        => 'My_Actions',
        default_action => 'do_arg0',
        source          => \$source_bare
    }
);

package My_Actions;
our $SELF;
sub new { return $SELF }
sub do_arg0 { shift; return shift; }

sub show_last_expression {
    my ($self) = @_;
    my $recce = $self->{recce};
    my ( $start, $end ) = $recce->last_completed_range('Number');
    return if not defined $start;
    my $last_expression = $recce->range_to_string( $start, $end );
    return $last_expression;
} ## end sub show_last_expression

package main;

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $self = bless { grammar => $grammar }, 'My_Actions';
    local $My_Actions::SELF = $self;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    $self->{recce} = $recce;
    my ( $parse_value, $parse_status, $last_expression );

    if ( not defined eval { $recce->read(\$string); 1 } ) {
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        return 'No parse', $abbreviated_error, $self->show_last_expression();
    }
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        return
            'No parse', 'Input read to end but no parse',
            $self->show_last_expression();
    } ## end if ( not defined $value_ref )
    return [ return ${$value_ref}, 'Parse OK', 'entire input' ];
} ## end sub my_parser

my @tests_data = (
    [ $grammar_bare, '1 2 3',     '1 results: 13', 'Parse OK', 'entire input' ],
);

TEST:
for my $test_data (@tests_data) {
    my ($grammar, $test_string,     $expected_value,
        $expected_result, $expected_last_expression
    ) = @{$test_data};
    my ($actual_value,
        $actual_result, $actual_last_expression
    ) = my_parser( $grammar, $test_string );
    $actual_last_expression //= 'none';
    Test::More::is( $actual_value, $expected_value, qq{Value of "$test_string"} );
    Test::More::is( $actual_result, $expected_result, qq{Result of "$test_string"} );
    Test::More::is( $actual_last_expression, $expected_last_expression, qq{Last expression found in "$test_string"} );
} ## end TEST: for my $test_string (@test_strings)

# vim: expandtab shiftwidth=4:
