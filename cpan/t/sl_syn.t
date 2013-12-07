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

# Synopsis for scannerless parsing, main POD page

use 5.010;
use strict;
use warnings;

use Test::More tests => 21;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {

# Marpa::R2::Display
# name: Scanless concept example

        source => \(<<'END_OF_SOURCE'),
:start ::= <number sequence>
<number sequence> ::= <number>+ action => add_sequence
number ~ digit+
digit ~ [0-9]
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_SOURCE

# Marpa::R2::Display::End

    }
);

package My_Actions;
sub add_sequence {
    my ($self, @numbers) = @_;
    return List::Util::sum @numbers, 0;
}

sub show_sequence_so_far {
    my ($self) = @_;
    my $recce = $self->{recce};
    my ( $start, $end ) = $recce->last_completed_range('number sequence');
    return if not defined $start;
    my $sequence_so_far = $recce->range_to_string( $start, $end );
    return $sequence_so_far;
} ## end sub show_sequence_so_far

package main;

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $parse_arg = bless { grammar => $grammar }, 'My_Actions';

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    $parse_arg->{recce} = $recce;
    my ( $parse_value, $parse_status, $sequence_so_far );

    if ( not defined eval { $recce->read( \$string ); 1 } ) {
        return 'No parse', $EVAL_ERROR, $parse_arg->show_sequence_so_far();
    }
    my $value_ref = $recce->value( $parse_arg);
    if ( not defined $value_ref ) {
        return 'No parse', 'Input read to end but no parse',
            $parse_arg->show_sequence_so_far();
    }
    return [ return ${$value_ref}, 'Parse OK', ];
} ## end sub my_parser

my @tests_data = (
    [ ' 1 2 3   1 2 4', 13,      qr/\AParse \s+ OK\z/xms ],
    [ ' 8675311',       8675311, qr/\AParse \s+ OK\z/xms ],
    [ '867 5311',       6178,    qr/\AParse \s+ OK\z/xms ],
    [ ' 8 6 7 5 3 1 1', 31,      qr/\AParse \s+ OK\z/xms ],
    [ '1234',           1234,    qr/\AParse \s+ OK\z/xms ],
    [   '2 x 1234', 'No parse',
        qr/ No \s+ lexeme \s+ found \s+ at \s /xms,
        2
    ],
    [   '', 'No parse',
        qr/\A Input \s+ read \s+ to \s+ end \s+ but \s+ no \s+ parse \z/xms,
    ],
);

TEST:
for my $test_data (@tests_data) {
    my ($test_string,     $expected_value,
        $expected_result, $expected_sequence_so_far
    ) = @{$test_data};
    $expected_sequence_so_far //= 'none';
    my ($actual_value,
        $actual_result, $actual_sequence_so_far
    ) = my_parser( $grammar, $test_string );
    $actual_sequence_so_far //= 'none';
    Test::More::is( $actual_value, $expected_value, qq{Value of "$test_string"} );
    Test::More::like( $actual_result, $expected_result, qq{Result of "$test_string"} );
    Test::More::is( $actual_sequence_so_far, $expected_sequence_so_far, qq{Sequence so far from "$test_string"} );
} ## end TEST: for my $test_string (@test_strings)
# vim: expandtab shiftwidth=4:
