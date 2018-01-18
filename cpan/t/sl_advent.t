#!/usr/bin/perl
# Copyright 2018 Jeffrey Kegler
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

# This example is from a Perl 6 advent blog post
# (Day 18 2013) by Dwarring, adapted to Marpa by Jean-Damien
# Durand.

use 5.010001;
use strict;
use warnings;
use English qw( -no_match_vars );
use utf8;
use open ':std', ':encoding(utf8)';

use Test::More tests => 54;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $base_dsl = <<'END_OF_BASE_DSL';
:start ::= deal
deal ::= hands
hands ::= hand | hands ';' hand
hand ::= card card card card card
card ~ face suit
face ~ [2-9jqka] | '10'
WS ~ [\s]
:discard ~ WS

:lexeme ~ <card>  pause => after event => 'card'
END_OF_BASE_DSL

my @tests = ();
push @tests,
    [
    '2♥ 5♥ 7♦ 8♣ 9♠',
    'Parse OK',
    'Hand was 2♥ 5♥ 7♦ 8♣ 9♠',
    ];
push @tests,
    [
    '2♥ a♥ 7♦ 8♣ j♥',
    'Parse OK',
    'Hand was 2♥ a♥ 7♦ 8♣ j♥',
    ];
push @tests,
    [
    'a♥ a♥ 7♦ 8♣ j♥',
    'Parse stopped by application',
    'Duplicate card a♥'
    ];
push @tests,
    [
    'a♥ 7♥ 7♦ 8♣ j♥; 10♥ j♥ q♥ k♥ a♥',
    'Parse stopped by application',
    'Duplicate card j♥'
    ];
push @tests,
    [
    '2♥ 7♥ 2♦ 3♣ 3♦',
    'Parse OK',
    'Hand was 2♥ 7♥ 2♦ 3♣ 3♦',
    ];
push @tests,
    [
    '2♥ 7♥ 2♦ 3♣',
    'Parse reached end of input, but failed',
    'No hands were found'
    ];
push @tests, [
    '2♥ 7♥ 2♦ 3♣ 3♦ 1♦',
    'Parse failed before end',
    <<'END_OF_MESSAGE'
Error in SLIF parse: No lexeme found at line 1, column 16
* String before error: 2\x{2665} 7\x{2665} 2\x{2666} 3\x{2663} 3\x{2666}\s
* The error was at line 1, column 16, and at character 0x0031 '1', ...
* here: 1\x{2666}
END_OF_MESSAGE
];
push @tests,
    [
    '2♥ 7♥ 2♦ 3♣',
    'Parse reached end of input, but failed',
    'No hands were found'
    ];
push @tests,
    [
    'a♥ 7♥ 7♦ 8♣ j♥; 10♥ j♣ q♥ k♥',
    'Parse failed after finding hand(s)',
    'Last hand successfully parsed was a♥ 7♥ 7♦ 8♣ j♥'
    ];

my @suit_line = (
    [ 'suit ~ [\x{2665}\x{2666}\x{2663}\x{2660}]', 'hex' ],
    [ 'suit ~ [♥♦♣♠]',                     'char class' ],
    [ q{suit ~ '♥' | '♦' | '♣'| '♠'},      'strings' ],
);

for my $test_data (@tests) {
    my ( $input, $expected_result, $expected_value ) = @{$test_data};
    my ( $actual_result, $actual_value );

    for my $suit_line_data (@suit_line) {
        my ( $suit_line, $suit_line_type ) = @{$suit_line_data};
        PROCESSING: {

            # Note: in production, you would compute the three grammar variants
            # ahead of time.
            my $full_dsl = $base_dsl . $suit_line;
            my $grammar =
                Marpa::R2::Scanless::G->new( { source => \$full_dsl } );
            my $re = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
            my $length = length $input;

            my %played = ();
            my $pos;
            my $eval_ok = eval { $pos = $re->read( \$input ); 1 };
            while ( $eval_ok and $pos < $length ) {

                # In our example there is a single event: no need to ask Marpa what it is
                my ( $start, $length ) =
                    $re->g1_location_to_span( $re->current_g1_location() );
                my $card = $re->literal( $start, $length );
                if ( ++$played{$card} > 1 ) {
                    $actual_result = 'Parse stopped by application';
                    $actual_value  = "Duplicate card " . $card;
                    last PROCESSING;
                }
                $eval_ok = eval { $pos = $re->resume(); 1 };
            } ## end while ( $eval_ok and $pos < $length )
            if ( not $eval_ok ) {
                $actual_result = "Parse failed before end";
                $actual_value  = $EVAL_ERROR;
                $actual_value
                    =~ s/ ^ Marpa::R2 \s+ exception \s+ at \s .* \z//xms;
                last PROCESSING;
            } ## end if ( not $eval_ok )

            my $value_ref = $re->value();
            my $last_hand;
            my ( $start, $end ) = $re->last_completed_range('hand');
            if ( defined $start ) {
                $last_hand = $re->range_to_string( $start, $end );
            }
            if ($value_ref) {
                $actual_result = 'Parse OK';
                $actual_value  = "Hand was $last_hand";
                last PROCESSING;
            }
            if ( defined $last_hand ) {
                $actual_result = 'Parse failed after finding hand(s)';
                $actual_value =
                    "Last hand successfully parsed was $last_hand";
                last PROCESSING;
            } ## end if ( defined $last_hand )
            $actual_result = 'Parse reached end of input, but failed';
            $actual_value  = 'No hands were found';
        } ## end PROCESSING:

        Marpa::R2::Test::is( $actual_result, $expected_result,
            "Result of $input using $suit_line_type" );
        Marpa::R2::Test::is( $actual_value, $expected_value,
            "Value of $input using $suit_line_type" );
    } ## end for my $suit_line_data (@suit_line)
} ## end for my $test_data (@tests)

# vim: expandtab shiftwidth=4:
