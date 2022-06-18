#!/usr/bin/perl
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

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa::R2 2.023008;
use Getopt::Long;

my $do_demo = 0;
my $getopt_result = GetOptions( "demo!" => \$do_demo, );

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
$PROGRAM_NAME --demo
$PROGRAM_NAME 'exp' [...]

Run $PROGRAM_NAME with either the "--demo" argument
or a series of calculator expressions.
END_OF_USAGE_MESSAGE
} ## end sub usage

if ( not $getopt_result ) {
    usage();
}
if ($do_demo) {
    if ( scalar @ARGV > 0 ) { say join q{ }, @ARGV; usage(); }
}
elsif ( scalar @ARGV <= 0 ) { usage(); }

my $prefix_grammar = Marpa::R2::Scanless::G->new(
    {
        action_object        => 'My_Actions',
        default_action => 'do_arg0',
        source          => \(<<'END_OF_RULES'),
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

package My_Actions;
our $SELF;
sub new { return $SELF }
sub do_list {
    my ($self, @results) = @_;
    return +(scalar @results) . ' results: ' . join q{ }, @results;
}

sub do_add  { shift; return $_[0] + $_[1] }
sub do_arg0 { shift; return shift; }

sub show_last_expression {
    my ($self) = @_;
    my $recce = $self->{recce};
    my ( $start, $end ) = $recce->last_completed_range('Expression');
    return 'No expression was successfully parsed' if not defined $start;
    my $last_expression = $recce->range_to_string( $start, $end );
    return "Last expression successfully parsed was: $last_expression";
} ## end sub show_last_expression

package main;

sub my_parser {
    my ( $grammar, $p_string ) = @_;

    my $self = bless { grammar => $grammar  }, 'My_Actions';
    local $My_Actions::SELF = $self;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    $self->{recce} = $recce;

    if ( not defined eval { $recce->read($p_string); 1 } ) {

        # Add last expression found, and rethrow
        my $eval_error = $EVAL_ERROR;
        chomp $eval_error;
        die $self->show_last_expression(), "\n", $eval_error, "\n";
    } ## end if ( not defined eval { $recce->read($string)...})
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die $self->show_last_expression(), "\n",
            "No parse was found, after reading the entire input\n";
    }
    return ${$value_ref};
} ## end sub my_parser

my @test_strings;
if ($do_demo) {
    push @test_strings,
    '+++ 1 2 3 + + 1 2 4',
    'say + 1 2',
    '+ 1 say 2',
    '+ 1 2 3 + + 1 2 4',
    '+++',
    '++1 2++',
    '++1 2++3 4++',
    '1 + 2 +3  4 + 5 + 6 + 7',
    '+12',
    '+1234'
    ;
} else {
    push @test_strings, shift;
}

TEST:
for my $test_string (@test_strings) {
    my $output;
    my $eval_ok =
        eval { $output = my_parser( $prefix_grammar, \$test_string ); 1 };
    my $eval_error = $EVAL_ERROR;
    if ( not defined $eval_ok ) {
        chomp $eval_error;
        say q{=} x 30;
        print qq{Input was "$test_string"\n},
            qq{Parse failed, with this diagnostic:\n},
            $eval_error, "\n";
        next TEST;
    } ## end if ( not defined $eval_ok )
    say q{=} x 30;
    print qq{Input was "$test_string"\n},
        qq{Parse was successful, output was "$output"\n};
} ## end TEST: for my $test_string (@test_strings)

# vim: expandtab shiftwidth=4:
