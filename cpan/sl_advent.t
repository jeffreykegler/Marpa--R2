#!/usr/bin/perl
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

# This example is an example from a Perl 6 advent blog post
# (Day 18 2103) by Dwarring, adapted to Marpa by Jean-Damien
# Durand.

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use utf8;

# This next line is so that Test::More works with utf8
use open ':std', ':encoding(utf8)';

use Test::More tests => 18;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

# Guess why
# ---------
binmode STDOUT, ':utf8';                                
binmode STDERR, ':utf8';                                

# Grammar and test suite are in __DATA__
# --------------------------------------
my $base_dsl = <<'END_OF_BASE_DSL';
:start ::= deal
deal ::= hands
hands ::= hand | hands ';' hand
hand ::= card card card card card
card ~ face suit
face ~ [2-9jqka] | '10'
suit ~ [\x{2665}\x{2666}\x{2663}\x{2660}]
WS ~ [\s]
:discard ~ WS

:lexeme ~ <card>  pause => after event => 'card'
END_OF_BASE_DSL

my @tests = ();
push @tests, [ '2♥ 5♥ 7♦ 8♣ 9♠',
'Parse OK',
'Parse OK'
 ];
push @tests, [ '2♥ a♥ 7♦ 8♣ j♥',
'Parse OK',
'Parse OK'
 ];
push @tests, [ 'a♥ a♥ 7♦ 8♣ j♥',
'Parse stopped by application',
'Duplicate card a♥'
 ];
push @tests, [ 'a♥ 7♥ 7♦ 8♣ j♥; 10♥ j♥ q♥ k♥ a♥',
'Parse stopped by application',
'Duplicate card j♥'
 ];
push @tests, [ '2♥ 7♥ 2♦ 3♣ 3♦',
'Parse OK',
'Parse OK'
 ];
push @tests, [ '2♥ 7♥ 2♦ 3♣',
'No parse',
'No parse'
 ];
push @tests, [ '2♥ 7♥ 2♦ 3♣ 3♦ 1♦',
'No parse',
<<'END_OF_MESSAGE'
'Error in SLIF parse: No lexeme found at line 1, column 16
* String before error: 2\x{2665} 7\x{2665} 2\x{2666} 3\x{2663} 3\x{2666}\s
* The error was at line 1, column 16, and at character 0x0031 '1', ...
* here: 1\x{2666}
END_OF_MESSAGE
 ];
push @tests, [ '2♥ 7♥ 2♦ 3♣',
'No parse',
'No parse'
 ];
push @tests, [ 'a♥ 7♥ 7♦ 8♣ j♥; 10♥ j♣ q♥ k♥',
'Parse failed after finding hand(s)',
'Last hand successfully parsed was: a♥ 7♥ 7♦ 8♣ j♥'
 ];

for my $test_data (@tests) {
    my ( $input, $expected_result, $expected_value ) = @{$test_data};
    my ( $actual_result, $actual_value );

    PROCESSING: {

        # Note: in production, no need to recompute G each time
        my $grammar = Marpa::R2::Scanless::G->new( { source => \$base_dsl } );
        my $re = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
        my $length = length $input;

        my %played = ();
        my $pos = eval { $re->read( \$input ) };
        return $@ if $@;
        do {
            # In our example there is a single event: no need to ask Marpa what it is
            my ( $start, $length ) =
                $re->g1_location_to_span( $re->current_g1_location() );
            my $card = $re->literal( $start, $length );
            if ( ++$played{$card} > 1 ) {
                $actual_result = 'Parse stopped by application';
                $actual_value  = "Duplicate card " . $card;
                last PROCESSING;
            }
            eval { $pos = $re->resume() };
            if ($EVAL_ERROR) {
                $actual_result = "No parse";
                $actual_value  = $EVAL_ERROR;
                last PROCESSING;
            }
        } while ( $pos < $length );

        my $value_ref = $re->value();
        if ( $value_ref ) {
            $actual_result = 'Parse OK';
            $actual_value  = ${$value_ref};
            last PROCESSING;
        }
        my ( $start, $end ) = $re->last_completed_range('hand');
        if ( not defined $start ) {
            $actual_result = 'No parse';
            $actual_value  = 'No parse';
            last PROCESSING;
        }
        my $lastHand = $re->range_to_string( $start, $end );
        $actual_result = 'Parse failed after finding hand(s)';
        $actual_value  = "Last hand successfully parsed was: $lastHand";
    } ## end PROCESSING:

    printf STDERR ( "%-40s : %s\n", $input, $actual_value || "OK" );
    my $test_name = "Test of $input";
    
    Marpa::R2::Test::is($actual_result, $expected_result, $test_name);
    Marpa::R2::Test::is($actual_value, $expected_value, $test_name);
} ## end for my $test_data (@tests)

