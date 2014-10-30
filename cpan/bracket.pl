#!/usr/bin/env perl
# Copyright 2014 Jeffrey Kegler
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

# This utility searches for mismatched braces --
# curly, square and round.

use 5.010;
use strict;
use warnings;
use Marpa::R2 2.098000;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long ();
use Test::More;

sub usage {
    die "Usage: $PROGRAM_NAME < file\n",
        "For testing: $PROGRAM_NAME --test\n";
}

my $testing = 0;
my $verbose = 0;
usage()
    if
    not Getopt::Long::GetOptions( verbose => \$verbose, test => \$testing );
usage() if @ARGV;

Test::More::plan tests => 5 if $testing;
our $TESTING = $testing;

my $grammar = << '=== GRAMMAR ===';
:default ::= action => [ name, value ]
lexeme default = action => [ name, value ] latm => 1 # to add token names to ast

text ::= pieces
pieces ::= piece*
piece ::= filler | balanced

balanced ::= 
    lparen pieces rparen
  | lcurly pieces rcurly
  | lsquare pieces rsquare

# x5b is left square bracket
# x5d is right square bracket
filler ~ [^(){}\x5B\x5D]+

lparen ~ '('
rparen ~ ')'
lcurly ~ '{'
rcurly ~ '}'
lsquare ~ '['
rsquare ~ ']'

=== GRAMMAR ===

my $suffix = '(){}[]';
my %tokens = ();
for my $ix ( 0 .. ( length $suffix ) - 1 ) {
    my $char = substr $suffix, $ix, 1;
    $tokens{$char} = [ $ix, 1 ];
}

my %matching      = ();
my %literal_match = ();
for my $pair (qw% () [] {} %) {
    my ( $left, $right ) = split //xms, $pair;
    $matching{$left}       = $tokens{$right};
    $literal_match{$left}  = $right;
    $matching{$right}      = $tokens{$left};
    $literal_match{$right} = $left;
} ## end for my $pair (qw% () [] {} %)
my %token_by_name = (
    rcurly  => $tokens{'}'},
    rsquare => $tokens{']'},
    rparen  => $tokens{')'},
);

my $g = Marpa::R2::Scanless::G->new( { source => \($grammar) } );

my @tests = ();

if ($TESTING) {
    @tests = (
        [ 'z}ab)({[]})))(([]))zz',                   '1{ 4( 11( 12(' ],
        [ '9\090]{[][][9]89]8[][]90]{[]\{}{}09[]}[', '5[ 16} 16[ 24[ 39]' ],
        [ '([]([])([]([]',                           '13) 13) 13)' ],
        [ '([([([([',    '8] 8) 8] 8) 8] 8) 8] 8)' ],
        [ '({]-[(}-[{)', '2} 2) 2[ 6) 6] 6{ 10} 10] 10(' ],
    );
    for my $test (@tests) {
        my ( $string, $expected_result ) = @{$test};
        my $fixes = q{};
        test( $g, $string, \$fixes );
        diagnostic( "Input: ", substr( $string, 0, 60 ) ) if $verbose;
        my $description = qq{Result of "} . ( substr $string, 0, 60 );
        Test::More::is( $fixes, $expected_result, $description );
    } ## end for my $test (@tests)
} ## end if ($TESTING)
else {
    local $RS = undef;
    my $input = <>;
    my $actual_result = test( $g, $input );
    if ( not scalar @{$actual_result} ) {
        say '=== All brackets balanced ===';
    }
    else {
        my $divider = "\n" . ( '=' x 20 ) . "\n";
        say join $divider, @{$actual_result};
    }
} ## end else [ if ($TESTING) ]

sub diagnostic {
    if ($TESTING) {
        Test::More::diag(@_);
    }
    else {
        say {*STDERR} @_;
    }
} ## end sub diagnostic

sub marked_line {
    my ( $string, $column1, $column2 ) = @_;
    my $max_line_length = 60;
    $max_line_length = $column1 if $column1 > $max_line_length;
    $max_line_length = $column2
        if defined $column2 and $column2 > $max_line_length;

    # $pos_column is always the last of the two columns
    my $output_line = substr $string, 0, $max_line_length;
    my $nl_pos = index $output_line, "\n";
    $output_line = substr $output_line, 0, $nl_pos;
    my $pointer_line = ( q{ } x $column1 ) . q{^};
    if ( defined $column2 ) {
        my $further_offset = $column2 - $column1;
        $pointer_line .= ( q{ } x ( $further_offset - 1 ) ) . q{^};
    }
    return join "\n", $output_line, $pointer_line;
} ## end sub marked_line

sub test {
    my ( $g, $string, $fixes ) = @_;
    my @problems = ();
    my @fixes    = ();
    diagnostic( "Input: ", substr( $string, 0, 60 ) ) if $verbose or $TESTING;

    # Record the length of the "real input"
    my $input_length = length $string;
    my $pos          = 0;

    # For Ruby Slippers, put a set of matching brackets into a suffix
    # of the input.
    # We wil carefully set our lengths when reading,
    # so that we don't treat to accidentally read this, while reading
    # the "real input".
    $string .= $suffix;

    # state $recce_debug_args = { trace_terminals => 1, trace_values => 1 };
    state $recce_debug_args = {};

    my $recce = Marpa::R2::Scanless::R->new(
        {   grammar => $g,
            ## Ask Marpa to generate an event on rejection
            rejection => 'event',
        },
        $recce_debug_args
    );

    # Note that we make sure only to read the "real input"
    $pos = $recce->read( \$string, $pos, $input_length );

    # For the entire input string ...
    READ: while ( $pos < $input_length ) {

        # Check if we stopped due to a rejection event.
        # Any other event is an error.
        my $rejection = 0;
        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            if ( $name eq q{'rejected} ) {
                $rejection = 1;
                next EVENT;
            }
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

        # No rejection event?
        # Then just start up again
        if ( not $rejection ) {

            # Note that we make sure we don't try to read the suffix
            $pos = $recce->resume( $pos, $input_length - $pos );
            next READ;

        } ## end if ( not $rejection )

        # If here, we rejected the next input token

        # What terminals do we expect?
        my @expected = @{ $recce->terminals_expected() };

        # Find, at random, one of these tokens that is a closing bracket.
        my ($token) =
            grep {defined}
            map  { $token_by_name{$_} } @{ $recce->terminals_expected() };

        # If there is no expected closing bracket, then what we need A
        # a new opening bracket in order to continue.  Find out which one.
        my $opening = not defined $token;
        if ($opening) {
            my $nextchar = substr $string, $pos, 1;
            $token = $matching{$nextchar};
        }

        # If it the case that we do we not expect a closing bracket,
        # and an opening bracket won't fix the problem either?
        # That should not happen.  All we can do is abend.
        die "Rejection at pos $pos: ", substr( $string, $pos, 10 )
            if not defined $token;

        # Concoct a "Ruby Slippers token" and read it from the
        # suffix
        my ( $token_start, $token_length ) = @{$token};
        $token_start += $input_length;
        my $token_literal = substr $string, $token_start, $token_length;
        my $result = $recce->resume( $token_start, $token_length );
        die "Read of Ruby slippers token failed"
            if $result != $token_start + $token_length;

        # Used for testing
        push @fixes, "$pos$token_literal" if $fixes;

        # We've done the Ruby Slippers thing, and are ready to
        # continue reading.
        # But first we want to report the error.

        my ( $pos_line, $pos_column ) = $recce->line_column($pos);
        my $problem;

        # Report the error if it was a case of a missing open bracket.
        if ($opening) {
            $problem = join "\n",
                "* Line $pos_line, column $pos_column: Missing open $token_literal",
                marked_line(
                (   substr $string,
                    $pos - ( $pos_column - 1 ),
                    -( length $suffix ) + 1
                ),
                $pos_column - 1
                );
            push @problems, [ $pos_line, $pos_column, $problem ];
            diagnostic(
                "* Line $pos_line, column $pos_column: Missing open $token_literal"
            ) if $verbose;
            next READ;
        } ## end if ($opening)

        # Report the error if it was a case of a missing close bracket.

        # We've created a properly bracketed span of the input, using
        # the Ruby Slippers token.  Use Marpa's tables to find its
        # beginning.
        my ($opening_bracket) = $recce->last_completed_span('balanced');
        my ( $line, $column ) = $recce->line_column($opening_bracket);
        my $opening_column0 = $opening_bracket - ( $column - 1 );

        if ( $line == $pos_line ) {

            # Report a missing close bracket for cases contained in
            # a single text line
            $problem = join "\n",
                "* Line $line, column $column: Missing close $token_literal, "
                . "problem detected at line $pos_line, column $pos_column",
                marked_line(
                substr(
                    $string,
                    $pos - ( $pos_column - 1 ),
                    -( length $suffix ) + 1
                ),
                $column - 1,
                $pos_column - 1
                );
        } ## end if ( $line == $pos_line )
        else {
            # Report a missing close bracket for cases that span
            # two or more text lines
            $problem = join "\n",
                  "* Line $line, column $column: No matching bracket for "
                . q{'}
                . $literal_match{$token_literal} . q{', },
                marked_line(
                substr( $string, $opening_column0, -( length $suffix ) + 1 ),
                $column - 1
                ),
                , "*   Problem detected at line $pos_line, column $pos_column:",
                marked_line(
                substr(
                    $string,
                    $pos - ( $pos_column - 1 ),
                    -( length $suffix ) + 1
                ),
                $pos_column - 1
                );
        } ## end else [ if ( $line == $pos_line ) ]

        # Add our report to the list of problems.
        push @problems, [ $line, $column, $problem ];
        diagnostic(
            "* Line $line, column $column: Missing close $token_literal, ",
            "problem detected at line $pos_line, column $pos_column"
        ) if $verbose;

    } ## end READ: while ( $pos < $input_length )

    # At this point we have finished the input.
    # Now we must deal with opening brackets which
    # were never closed.
    # The logic here is a simplified version of that of the main
    # reading loop.

    TRAILER: while (1) {

        # Programming note: this is so similar to the code of the
        # main reading loop, it is tempting to combine them and use
        # a flag.
        # But there are quite a few small differences,
        # so that would be much less readable.
        # And for efficiency purposes, this is a kind of "hand-unrolling"
        # of a loop, with optimization of the code.

        my $rejection = 0;
        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            if ( $name eq q{'rejected} ) {
                $rejection = 1;
                next EVENT;
            }
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

        die "Rejection at end of string" if $rejection;

        my @expected = @{ $recce->terminals_expected() };

        # say STDERR join " ", "terminals expected:", @expected;

        my ($token) =
            grep {defined}
            map  { $token_by_name{$_} } @{ $recce->terminals_expected() };

        last TRAILER if not defined $token;

        my ( $token_start, $token_length ) = @{$token};
        $token_start += $input_length;
        my $token_literal = substr $string, $token_start, $token_length;
        my $result = $recce->resume( $token_start, $token_length );
        die "Read of Ruby slippers token failed"
            if $result != $token_start + $token_length;

        # Used for testing
        push @fixes, "$pos$token_literal" if $fixes;

        my ($opening_bracket) = $recce->last_completed_span('balanced');
        my ( $line, $column ) = $recce->line_column($opening_bracket);
        my $opening_column0 = $opening_bracket - ( $column - 1 );
        my $problem = join "\n",
              "* Line $line, column $column: Opening " . q{'}
            . $literal_match{$token_literal}
            . q{' never closed, problem detected at end of string},
            marked_line(
            substr( $string, $opening_column0, -( length $suffix ) + 1 ),
            $column - 1 );
        push @problems, [ $line, $column, $problem ];

    } ## end TRAILER: while (1)

    # For testing
    if ( ref $fixes ) {
        ${$fixes} = join " ", @fixes;
    }

    # The problems do not necessarily occur in lexical order.
    # Sort them so that they can be reported that way.
    my @sorted_problems =
        sort { $a->[0] <=> $b->[0] or $a->[1] <=> $b->[1] } @problems;
    my @result = map { $_->[-1] } @sorted_problems;
    return \@result;

} ## end sub test

# vim: expandtab shiftwidth=4:
