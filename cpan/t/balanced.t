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

use 5.010001;
use strict;
use warnings;
use English qw( -no_match_vars );

use List::Util qw(min);
use Test::More tests => 7;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

sub find_match {
    my ($s) = @_;

    my $grammar_args = {
        start => 'S',
        rules => [
            [ S => [qw(prefix first_balanced endmark )] ],
            {   lhs => 'S',
                rhs => [qw(prefix first_balanced )]
            },
            { lhs => 'prefix',      rhs => [qw(prefix_char)], min => 0 },
            { lhs => 'prefix_char', rhs => [qw(xlparen)] },
            { lhs => 'prefix_char', rhs => [qw(rparen)] },
            { lhs => 'lparen',      rhs => [qw(xlparen)] },
            { lhs => 'lparen',      rhs => [qw(ilparen)] },
            {   lhs => 'first_balanced',
                rhs => [qw(xlparen balanced_sequence rparen)],
            },
            {   lhs => 'balanced',
                rhs => [qw(lparen balanced_sequence rparen)],
            },
            {   lhs => 'balanced_sequence',
                rhs => [qw(balanced)],
                min => 0,
            },
        ],
    };

    my $grammar = Marpa::R2::Grammar->new($grammar_args);

    $grammar->precompute();

    my ($first_balanced_rule) =
        grep { ( $grammar->rule($_) )[0] eq 'first_balanced' }
        $grammar->rule_ids();

    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

# Marpa::R2::Display
# name: Recognizer expected_symbol_event_set() Synopsis

    $recce->expected_symbol_event_set( 'endmark', 1 );

# Marpa::R2::Display::End

    my $location      = 0;
    my $string_length = length $s;
    my $end_of_match;

    # find the match which ends first -- the one which starts
    # first must start at or before it does
    CHAR: while ( $location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $event_count;
        if ( $value eq '(' ) {

            # say "Adding xlparen at $location";
            $event_count = $recce->read('xlparen');
        }
        else {
            # say "Adding rparen at $location";
            $event_count = $recce->read('rparen');
        }
        if ( $event_count
            and grep { $_->[0] eq 'SYMBOL_EXPECTED' } @{ $recce->events() } )
        {
            $end_of_match = $location + 1;
            last CHAR;
        } ## end if ( $event_count and grep { $_->[0] eq 'SYMBOL_EXPECTED'...})
        $location++;
    } ## end CHAR: while ( $location < $string_length )

    if ( not defined $end_of_match ) {
        say "No balanced parens";
        return 0;
    }

    CHAR: while ( ++$location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $token = $value eq '(' ? 'ilparen' : 'rparen';

        # say "Adding $token at $location";
        my $event_count = $recce->read($token);
        last CHAR if not defined $event_count;
        if ( $event_count
            and grep { $_->[0] eq 'SYMBOL_EXPECTED' } @{ $recce->events() } )
        {
            $end_of_match = $location + 1;
        }
    } ## end CHAR: while ( ++$location < $string_length )

    my $report = $recce->progress($end_of_match);

    # say Dumper($report);
    my $start_of_match = List::Util::min map { $_->[2] }
        grep { $_->[1] < 0 && $_->[0] == $first_balanced_rule } @{$report};
    return "$start_of_match-$end_of_match";

} ## end sub find_match

my $base_string = '(' x 40;
my $target      = '(()())';
for my $pos (
    0, 1, 2,
    -( 2 + length $target ),
    -( 1 + length $target ),
    -( length $target )
    )
{
    my $test_string = $base_string;
    substr $test_string, $pos, ( length $target ), $target;
    my ( $expected_start, $expected_end );
    if ( $pos >= 0 ) {
        $expected_start = $pos;
        $expected_end   = $pos + length $target;
    }
    else {
        $expected_start = $pos + 40;
        $expected_end   = $pos + 40 + length $target;
    }
    my $expected = $expected_start . q{-} . $expected_end;
    Marpa::R2::Test::is( find_match($test_string),
        $expected, "target at pos $pos" );
} ## end for my $pos ( 0, 1, 2, -( 2 + length $target ), -( 1 ...))
my $test_string = '(' x 20 . ')' x 20;
Marpa::R2::Test::is( find_match($test_string), '0-40', 'Middle target' );
