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

# This example searches for mismatched braces --
# curly, square and round.

use 5.010;
use strict;
use warnings;
use Marpa::R2 2.097_002;
use Data::Dumper;
use English qw( -no_match_vars );
use Test::More tests => 3;
use Getopt::Long ();

my $verbose;
my $testing;
die if not Getopt::Long::GetOptions( verbose => \$verbose, test => \$testing );

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

my %matching = ();
my %literal_match = ();
for my $pair (qw% () [] {} %) {
    my ( $left, $right ) = split //xms, $pair;
    $matching{$left}  = $tokens{$right};
    $literal_match{$left}  = $right;
    $matching{$right} = $tokens{$left};
    $literal_match{$right}  = $left;
}
my %token_by_name = (
    rcurly  => $tokens{'}'},
    rsquare => $tokens{']'},
    rparen  => $tokens{')'},
);

my $g = Marpa::R2::Scanless::G->new( { source => \($grammar) } );

my @tests = ();

if ( defined $testing ) {
    @tests = (
        [ 'z}ab)({[]})))(([]))zz',                   q{} ],
        [ '9\090]{[][][9]89]8[][]90]{[]\{}{}09[]}[', q{} ],
        [ '([]([])([]([]',                           q{}, ],
        [ '([([([([',                                q{}, ],
        [ '({]-[(}-[{)',                             q{}, ],
    );
} ## end if ( defined $testing )
else {
    local $RS = undef;
    my $input = <>;
    @tests = ( [ $input, q{} ] );
} ## end else [ if ( defined $testing ) ]

sub diagnostic {
   my ($testing, @args) = @_;
   if ($testing) {
       Test::More::diag(@args);
   } else {
       say {*STDERR} @args;
   }
}

for my $test (@tests) {
    my ( $string, $expected_result ) = @{$test};
    my $actual_result = test( $g, $string );
    diagnostic("Input: $string") if $verbose;
    my $description = qq{Result of "} . ( substr $string, 0, 60 );
    Test::More::is( $actual_result, $expected_result, $description );
} ## end for my $test (@tests)

sub marked_line {
    my ($string, $column1, $column2) = @_;
    my $max_line_length = 60;
    $max_line_length = $column1 if $column1 > $max_line_length;
    $max_line_length = $column2 if defined $column2 and $column2 > $max_line_length;
    # $pos_column is always the last of the two columns
    my $output_line = substr $string, 0, $max_line_length;
    my $nl_pos = index $output_line, "\n";
    $output_line = substr $output_line, 0, $nl_pos;
    my $pointer_line = (q{ } x $column1) . q{^};
    if (defined $column2)
    {
       my $further_offset = $column2 - $column1;
        $pointer_line .= (q{ } x ($further_offset-1)) . q{^};
    }
    return join "\n", $output_line, $pointer_line;
}

sub test {
    my ( $g, $string ) = @_;
    my @problems = ();
    diagnostic("Input: $string") if $verbose;

    diagnostic($testing, "Input: $string");

    my $input_length = length $string;
    my $pos          = 0;

    $string .= $suffix;

    # state $recce_debug_args = { trace_terminals => 1, trace_values => 1 };
    state $recce_debug_args = {};

    my $recce = Marpa::R2::Scanless::R->new(
        {   grammar   => $g,
            rejection => 'event',
        },
        $recce_debug_args
    );
    $pos = $recce->read( \$string, $pos, $input_length );

    READ: while ( $pos < $input_length ) {

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

        if ( not $rejection ) {
            $pos = $recce->resume( $pos, $input_length - $pos );
            next READ;

        } ## end if ( not $rejection )
        my @expected = @{ $recce->terminals_expected() };

        my ($token) =
            grep {defined}
            map  { $token_by_name{$_} } @{ $recce->terminals_expected() };

        my $opening = not defined $token;
        if ($opening) {
            my $nextchar = substr $string, $pos, 1;
            $token = $matching{$nextchar};
        }
        die "Rejection at pos $pos: ", substr( $string, $pos, 10 )
            if not defined $token;

        my ( $token_start, $token_length ) = @{$token};
        $token_start += $input_length;
        my $token_literal = substr $string, $token_start, $token_length;
        my $result = $recce->resume( $token_start, $token_length );
        die "Read of Ruby slippers token failed"
            if $result != $token_start + $token_length;

        my ( $pos_line, $pos_column ) = $recce->line_column($pos);
        my $problem;
        if ($opening) {
            $problem = join "\n",
                "Line $pos_line, column $pos_column: Missing open $token_literal",
                marked_line(
                (   substr $string,
                    $pos - ( $pos_column - 1 ),
                    -( length $suffix ) + 1
                ),
                $pos_column - 1
                );
            push @problems, [ $pos_line, $pos_column, $problem ];
            diagnostic( $testing,
                "Line $pos_line, column $pos_column: Missing open $token_literal"
            ) if $verbose;
            next READ;
        } ## end if ($opening)

        my ($opening_bracket) = $recce->last_completed_span('balanced');
        my ( $line, $column ) = $recce->line_column($opening_bracket);
        my $opening_column0 = $opening_bracket - ( $column - 1 );
        if ( $line == $pos_line ) {
            $problem = join "\n",
                "Line $line, column $column: Missing close $token_literal, "
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
        else
        {
            $problem = join "\n",
                "===",
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
        push @problems, [ $line, $column, $problem ];
        diagnostic($testing,
            "Line $line, column $column: Missing close $token_literal, ",
            "problem detected at line $pos_line, column $pos_column") if $verbose;

    } ## end READ: while ( $pos < $input_length )

    TRAILER: while ( 1 ) {

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

        die "Rejection at end of string" if  $rejection ;

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

        my ($opening_bracket) = $recce->last_completed_span('balanced');
        my ( $line, $column ) = $recce->line_column($opening_bracket);
        my $opening_column0 = $opening_bracket - ( $column - 1 );
        my $problem = join "\n",
              "Line $line, column $column: Opening "
            . q{'} . $literal_match{$token_literal}
            . q{' never closed, problem detected at end of string},
            marked_line( substr($string, $opening_column0, -(length $suffix)+1), $column - 1 );
        push @problems, [ $line, $column, $problem ];

    } ## end READ: while ( $pos < $input_length )

    my @sorted_problems = sort { $a->[0] <=> $b->[0] or $a->[1] <=> $b->[1] } @problems;
    my $result = join "\n", (map { $_->[-1] } @sorted_problems), q{};
    return $result;

} ## end sub test

# vim: expandtab shiftwidth=4:
