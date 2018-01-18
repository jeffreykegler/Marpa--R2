#!/usr/bin/env perl
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

# This example searches for recursively nested braces --
# curly, square and round -- in a "salad" of other things.
# It's to show general BNF search -- sort of a grep or an ack,
# but for general BNF, instead of regexes.  The term
# "salad" I picked up from Michael Roberts, to suggest
# that the targets occur in a sort of "lexeme salad".
# In the literature, this is called a supersequence
# search.

use 5.010001;
use strict;
use warnings;
use Marpa::R2 2.097_002;
use Data::Dumper;
use Test::More tests => 3;
use Getopt::Long ();

my $verbose;
die if not Getopt::Long::GetOptions( verbose => \$verbose );

my $grammar = << '=== GRAMMAR ===';
:default ::= action => [ name, value ]
lexeme default = action => [ name, value ] latm => 1 # to add token names to ast

<prefixed target> ::= prefix target
prefix ::= <prefix lexeme>*

target ::= balanced
event target = completed target

balanced ::= 
    lparen contents rparen
  | lcurly contents rcurly
  | lsquare contents rsquare

contents ::= <content item>*
<content item> ::= balanced | filler

<prefix lexeme> ~ <deep filler>
filler ~ <deep filler>
# x5b is left square bracket
# x5d is right square bracket
<deep filler> ~ [^(){}\x5B\x5D]+

<prefix lexeme> ~ <deep lparen>
lparen ~ <deep lparen>
<deep lparen> ~ '('

<prefix lexeme> ~ <deep rparen>
rparen ~ <deep rparen>
<deep rparen> ~ ')'

<prefix lexeme> ~ <deep lcurly>
lcurly ~ <deep lcurly>
<deep lcurly> ~ '{'

<prefix lexeme> ~ <deep rcurly>
rcurly ~ <deep rcurly>
<deep rcurly> ~ '}'

<prefix lexeme> ~ <deep lsquare>
lsquare ~ <deep lsquare>
<deep lsquare> ~ '['

<prefix lexeme> ~ <deep rsquare>
rsquare ~ <deep rsquare>
<deep rsquare> ~ ']'

=== GRAMMAR ===

my $g = Marpa::R2::Scanless::G->new( { source => \($grammar) } );

my @tests = (
    [ 'z}ab)({[]})))(([]))zz', ( join "\n", '({[]})', '(([]))', '' ) ],
    [   '9\090]{[][][9]89]8[][]90]{[]\{}{}09[]}[',
        join "\n", '[]', '[]', '[9]', '[]', '[]', '{[]\{}{}09[]}', ''
    ],
    [ '([]([])([]([]', join "\n", '[]', '([])', '[]', '[]', '' ],
);

for my $test (@tests) {
    my ( $string, $expected_result ) = @{$test};
    my $actual_result = test( $g, $string );
    diag("Input: $string") if $verbose;
    Test::More::is( $actual_result, $expected_result,
        qq{Result of "$string"} );
} ## end for my $test (@tests)

sub test {
    my ($g, $string) = @_;
    my @found = ();
    diag( "Input: $string" ) if $verbose;
    my $input_length = length $string;
    my $target_start = 0;

    # my $recce_debug_args = { trace_terminals => 1, trace_values => 1 };
    state $recce_debug_args = {};

    # One pass through this loop for every target found,
    # until we reach end of string without finding a target

    TARGET: while ( $target_start < $input_length ) {

        # First we find the "shortest span" -- the one which ends earliest.
        # This tells us where the prefix should end.
        # No prefix should go beyond the first location of the shortest span.

# Marpa::R2::Display
# name: SLIF exhaustion recognizer setting synopsis

        my @shortest_span = ();
        my $recce         = Marpa::R2::Scanless::R->new(
            {   grammar    => $g,
                exhaustion => 'event',
            },
            $recce_debug_args
        );
        my $pos = $recce->read( \$string, $target_start );

        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            if ( $name eq 'target' ) {
                @shortest_span = $recce->last_completed_span('target');
                diag(
                    "Preliminary target at $pos: ",
                    $recce->literal(@shortest_span)
                ) if $verbose;
                next EVENT;
            } ## end if ( $name eq 'target' )
                # Not all exhaustion has an exhaustion event,
                # so we look for exhaustion explicitly below.
            next EVENT if $name eq q('exhausted);
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

# Marpa::R2::Display::End

        last TARGET if not scalar @shortest_span;

        # We now have found the longest allowed prefix.
        # Our "longest match" will begin at the end of this prefix,
        # or before it.

        # We just run until exhausted, the  look for the last
        # completed <target>.  This will be our longest match.

        diag( join q{ }, @shortest_span ) if $verbose;
        my $prefix_end = $shortest_span[0];
        $recce = Marpa::R2::Scanless::R->new(
            {   grammar    => $g,
                exhaustion => 'event',
                rejection => 'event',
            },
            $recce_debug_args
        );
        $recce->activate( 'target', 0 );
        $recce->read( \$string, $target_start, $prefix_end - $target_start );

# Marpa::R2::Display
# name: SLIF recognizer lexeme_priority_set() synopsis

        $recce->lexeme_priority_set( 'prefix lexeme', -1 );

# Marpa::R2::Display::End

        $pos = $recce->resume($prefix_end);

# Marpa::R2::Display
# name: SLIF recognizer last_completed_span() synopsis

        my @longest_span = $recce->last_completed_span('target');
        diag( "Actual target at $pos: ", $recce->literal(@longest_span) ) if $verbose;

# Marpa::R2::Display::End

        last TARGET if not scalar @longest_span;
        push @found, $recce->literal(@longest_span);
        diag( "Found target at $pos: ", $recce->literal(@longest_span) ) if $verbose;

        # Move the search location forward,
        # in preparation for looking for the next target

        $target_start = $longest_span[0] + $longest_span[1];

    } ## end TARGET: while ( $target_start < $input_length )
    return join "\n", @found, q{};
} ## end sub test

# vim: expandtab shiftwidth=4:
