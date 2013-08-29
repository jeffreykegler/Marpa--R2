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

# Test of scannerless parsing -- prefix addition

use 5.010;
use strict;
use warnings;

use Test::More tests => 30;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $prefix_grammar = Marpa::R2::Scanless::G->new(
    {
        source          => \(<<'END_OF_RULES'),
:default ::= action => do_arg0
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

sub My_Actions::do_list {
    my ( $self, @results ) = @_;
    return +( scalar @results ) . ' results: ' . join q{ }, @results;
}

sub My_Actions::do_add  { shift; return $_[0] + $_[1] }
sub My_Actions::do_arg0 { shift; return shift; }

sub My_Actions::show_last_expression {
    my ($self) = @_;
    my $recce = $self->{recce};
    my ( $start, $end ) = $recce->last_completed_range('Expression');
    return if not defined $start;
    my $last_expression = $recce->range_to_string( $start, $end );
    return $last_expression;
} ## end sub My_Actions::show_last_expression

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $self = bless { grammar => $grammar, recce => $recce }, 'My_Actions';
    my ( $parse_value, $parse_status, $last_expression );

    if ( not defined eval { $recce->read( \$string ); 1 } ) {
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        return 'No parse', $abbreviated_error, $self->show_last_expression();
    } ## end if ( not defined eval { $recce->read( \$string ); 1 ...})
    my $value_ref = $recce->value($self);
    if ( not defined $value_ref ) {
        return 'No parse', 'Input read to end but no parse',
            $self->show_last_expression();
    }
    return [ return ${$value_ref}, 'Parse OK', 'entire input' ];
} ## end sub my_parser

my @tests_data = (
    [ '+++ 1 2 3 + + 1 2 4',     '1 results: 13', 'Parse OK', 'entire input' ],
    [ 'say + 1 2',               '1 results: 3', 'Parse OK', 'entire input' ],
    [ '+ 1 say 2',               'No parse', 'Error in SLIF parse: No lexemes accepted at line 1, column 5', '1' ],
    [ '+ 1 2 3 + + 1 2 4',       '3 results: 3 3 7', 'Parse OK', 'entire input' ],
    [ '+++',                     'No parse', 'Input read to end but no parse', 'none' ],
    [ '++1 2++',                 'No parse', 'Input read to end but no parse', '+1 2' ],
    [ '++1 2++3 4++',            'No parse', 'Input read to end but no parse', '+3 4' ],
    [ '1 + 2 +3  4 + 5 + 6 + 7', 'No parse', 'Input read to end but no parse', '7' ],
    [ '+12',                     'No parse', 'Input read to end but no parse', '12' ],
    [ '+1234',                   'No parse', 'Input read to end but no parse', '1234' ],
);

TEST:
for my $test_data (@tests_data) {
    my ($test_string,     $expected_value,
        $expected_result, $expected_last_expression
    ) = @{$test_data};
    my ($actual_value,
        $actual_result, $actual_last_expression
    ) = my_parser( $prefix_grammar, $test_string );
    $actual_last_expression //= 'none';
    Test::More::is( $actual_value, $expected_value, qq{Value of "$test_string"} );
    Test::More::is( $actual_result, $expected_result, qq{Result of "$test_string"} );
    Test::More::is( $actual_last_expression, $expected_last_expression, qq{Last expression found in "$test_string"} );
} ## end TEST: for my $test_string (@test_strings)

# vim: expandtab shiftwidth=4:
