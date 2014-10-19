#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Marpa::R2 2.097_002;
use Data::Dumper;

# This example searches for recursively nested braces --
# curly, square and round -- in a "salad" of other things.
# It's to show general BNF search -- sort of a grep or an ack,
# but for general BNF, instead of regexes.  The term
# "salad" I picked up from Michael Roberts, to suggest
# that the targets occur in a sort of "lexeme salad".
# In the literature, this is called a supersequence
# search.

# New (as yet undocumented) features:
# 
# 1.) The $recce->last_completed_span($symbol) method
# returns the location of the most recent completion
# of $symbol.  Locations are in input stream terms.
# It works similarly to the documented method,
# $recce->last_completed($symbol).
#
# 2.) A scanless recognizer setting: 'exhaustion'
# If its value is "fatal",
# when the SLIF tries to continue
# reading input after exhaustion, it throws an
# exception.  If "event", it returns an event
# named "'exhausted".  Note the initial single quote,
# which marks it as a reserved event.
#
# The 'exhaustion event only occurs when needed to
# make the $recce->read() or $recce->resume() method
# return.  Applications which want to check for exhaustion
# should ignore the event and
# use the $recce->exhausted() method.
#
# 3.) A new scanless recognizer setting: 'rejection'
# It determines what happens when
# all alternatives at a location are rejected.
# If its value is 'fatal', an exception is thrown.
# If its value is 'event', a "'rejection" event
# occurs.  Note the initial single quote,
# which marks it as a reserved event.
#
# 4.) Lexeme priorities can now be changed on the
# fly, using the
# $recce->lexeme_priority_set( $lexeme_name, $priority )
# call.

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

# Test strings go here
#             012345678901234567890
my @strings = ( 'z}ab)({[]})))(([]))zz',
'9\090]{[][][9]89]8[][]90]{[]\{}{}09[]}[',
'([]([])([]([]',
);

for my $string (@strings) {
    my $finds = test($g, $string);
    say "Input: $string";
    for ( my $i = 0; $i < scalar @{$finds}; $i++ ) {
        say join " ", "Find", ( $i + 1 . ":" ), $finds->[$i];
    }
} ## end for my $string (@strings)

sub test {
    my ($g, $string) = @_;
    my @found = ();
    # say STDERR "Input: $string";
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
                # say STDERR "Preliminary target at $pos: ",
                    # $recce->literal(@shortest_span);
                next EVENT;
            } ## end if ( $name eq 'target' )
                # Not all exhaustion has an exhaustion event,
                # so we look for exhaustion explicitly below.
            next EVENT if $name eq q('exhausted);
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

        last TARGET if not scalar @shortest_span;

        # We now have found the longest allowed prefix.
        # Our "longest match" will begin at the end of this prefix,
        # or before it.

        # We just run until exhausted, the  look for the last
        # completed <target>.  This will be our longest match.

        # say STDERR join q{ }, @shortest_span;
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
        $recce->lexeme_priority_set( 'prefix lexeme', -1 );
        $pos = $recce->resume($prefix_end);

        my @longest_span = $recce->last_completed_span('target');
        # say STDERR "Actual target at $pos: ", $recce->literal(@longest_span);

        last TARGET if not scalar @longest_span;
        push @found, $recce->literal(@longest_span);
        # say "Found target at $pos: ", $recce->literal(@longest_span);

        # Move the search location forward,
        # in preparation for looking for the next target

        $target_start = $longest_span[0] + $longest_span[1];

    } ## end TARGET: while ( $target_start < $input_length )
    return \@found;
} ## end sub test

# vim: expandtab shiftwidth=4:
