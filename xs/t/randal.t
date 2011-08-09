#!/usr/bin/perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Test::More tests => 5;
use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

package Test_Grammar;

# This grammar is from Data::Dumper,
# which disagrees with Perl::Critic about proper
# use of quotes and with perltidy about
# formatting

#<<< no perltidy
##no critic (ValuesAndExpressions::ProhibitNoisyQuotes)

$Test_Grammar::MARPA_OPTIONS = [
    {
      'rules' => [
        {
          'action' => 'comment',
          'lhs' => 'comment:optional',
          'rhs' => [
            'comment'
          ]
        },
        {
          'lhs' => 'comment:optional',
          'rhs' => []
        },
        {
          'action' => 'show_perl_line',
          'lhs' => 'perl-line',
          'rhs' => [
            'perl-statements',
            'comment:optional'
          ]
        },
        {
          'action' => 'show_statement_sequence',
          'lhs' => 'perl-statements',
          'min' => 1,
          'rhs' => [
            'perl-statement'
          ],
          'separator' => 'semicolon'
        },
        {
          'action' => 'show_division',
          'lhs' => 'perl-statement',
          'rhs' => [
            'division'
          ]
        },
        {
          'action' => 'show_function_call',
          'lhs' => 'perl-statement',
          'rhs' => [
            'function-call'
          ]
        },
        {
          'action' => 'show_die',
          'lhs' => 'perl-statement',
          'rhs' => [
            'die:k0',
            'string-literal'
          ]
        },
        {
          'lhs' => 'division',
          'rhs' => [
            'expr',
            'division-sign',
            'expr'
          ]
        },
        {
          'lhs' => 'expr',
          'rhs' => [
            'function-call'
          ]
        },
        {
          'lhs' => 'expr',
          'rhs' => [
            'number'
          ]
        },
        {
          'action' => 'show_unary',
          'lhs' => 'function-call',
          'rhs' => [
            'unary-function-name',
            'argument'
          ]
        },
        {
          'action' => 'show_nullary',
          'lhs' => 'function-call',
          'rhs' => [
            'nullary-function-name'
          ]
        },
        {
          'lhs' => 'argument',
          'rhs' => [
            'pattern-match'
          ]
        }
      ],
      'start' => 'perl-line',
      'terminals' => [
        'die:k0',
        'unary-function-name',
        'nullary-function-name',
        'number',
        'semicolon',
        'division-sign',
        'pattern-match',
        'comment',
        'string-literal'
      ],
    }
  ];

my %regexes = (
    'die:k0'                => 'die',
    'unary-function-name'   => '(caller|eof|sin|localtime)',
    'nullary-function-name' => '(caller|eof|sin|time|localtime)',
    'number'                => '\\d+',
    'semicolon'             => ';',
    'division-sign'         => '[/]',
    'pattern-match'         => '[/][^/]*/',
    'comment'               => '[#].*',
    'string-literal'        => '"[^"]*"',
);

## use critic
#>>>
#

package main;

my @test_data = (
    [   'sin',
        q{sin  / 25 ; # / ; die "this dies!"},
        [ 'sin function call, die statement', 'division, comment' ]
    ],
    [ 'time', q{time  / 25 ; # / ; die "this dies!"}, ['division, comment'] ]
);

my $g = Marpa::Grammar->new(
    {   warnings => 1,
        actions  => 'main',
    },
    @{$Test_Grammar::MARPA_OPTIONS}
);

$g->precompute();

TEST: for my $test_data (@test_data) {

    my ( $test_name, $test_input, $test_results ) = @{$test_data};
    my $recce =
        Marpa::Recognizer->new( { grammar => $g, mode => 'stream' } );

    my $input_length = length $test_input;
    pos $test_input = 0;

# Marpa::XS::Display
# name: Recognizer terminals_expected Synopsis

    my $terminals_expected = $recce->terminals_expected();

# Marpa::XS::Display::End

    for ( my $pos = 0; $pos < $input_length; $pos++ ) {
        my @tokens = ();
        TOKEN_TYPE: while ( my ( $token, $regex ) = each %regexes ) {
            next TOKEN_TYPE if not $token ~~ $terminals_expected;
            pos $test_input = $pos;
            next TOKEN_TYPE
                if not $test_input =~ m{ \G \s* (?<match>$regex) }xgms;

## no critic (Variables::ProhibitPunctuationVars)
            push @tokens,
                [ $token, $+{match}, ( ( pos $test_input ) - $pos ), 0 ];

        } ## end while ( my ( $token, $regex ) = each %regexes )
        ( undef, $terminals_expected ) =
            $recce->tokens( \@tokens );
    } ## end for ( my $pos = 0; $pos < $input_length; $pos++ )
    $recce->end_input();

    my @parses;
    while ( defined( my $value_ref = $recce->value() ) ) {
        my $value = $value_ref ? ${$value_ref} : 'No parse';
        push @parses, $value;
    }
    my $expected_parse_count = scalar @{$test_results};
    my $parse_count          = scalar @parses;
    Marpa::Test::is( $parse_count, $expected_parse_count,
        "$test_name: Parse count" );

    my $expected = join "\n", sort @{$test_results};
    my $actual   = join "\n", sort @parses;
    Marpa::Test::is( $actual, $expected, "$test_name: Parse match" );
} ## end for my $test_data (@test_data)

## no critic (Subroutines::RequireArgUnpacking)

sub show_perl_line {
    shift;
    return join ', ', grep {defined} @_;
}

sub comment                 { return 'comment' }
sub show_statement_sequence { shift; return join q{, }, @_ }
sub show_division           { return 'division' }
sub show_function_call      { return $_[1] }
sub show_die                { return 'die statement' }
sub show_unary              { return $_[1] . ' function call' }
sub show_nullary            { return $_[1] . ' function call' }

## use critic

1;    # In case used as "do" file

