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

# Tests that include a grammar, an input, and an error message
# or an AST, but no semantics.
#
# Uses include tests of parsing of the SLIF DSL itself.

use 5.010;
use strict;
use warnings;

use Test::More tests => 20;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

our $DEBUG = 0;
my @tests_data = ();

my $zero_grammar = \(<<'END_OF_SOURCE');
            :default ::= action => ::array
            quartet  ::= a a a a
        a ~ 'a'
END_OF_SOURCE

push @tests_data,
    [ $zero_grammar, 'aaaa', [qw(a a a a)], 'Parse OK',
    'No start statement' ];

my $colon1_grammar = \(<<'END_OF_SOURCE');
            :default ::= action => ::array
        :start ::= quartet
            quartet  ::= a a a a
        a ~ 'a'
END_OF_SOURCE

push @tests_data,
    [
    $colon1_grammar, 'aaaa',
    [qw(a a a a)],   'Parse OK',
    'Colon start statement first'
    ];

my $colon2_grammar = \(<<'END_OF_SOURCE');
            :default ::= action => ::array
            quartet  ::= a a a a
        :start ::= quartet
        a ~ 'a'
END_OF_SOURCE

push @tests_data,
    [
    $colon2_grammar, 'aaaa',
    [qw(a a a a)],   'Parse OK',
    'Colon start statement second'
    ];

my $english1_grammar = \(<<'END_OF_SOURCE');
            :default ::= action => ::array
        start symbol is quartet
            quartet  ::= a a a a
        a ~ 'a'
END_OF_SOURCE

push @tests_data,
    [
    $english1_grammar, 'aaaa',
    [qw(a a a a)],     'Parse OK',
    'English start statement first'
    ];

my $english2_grammar = \(<<'END_OF_SOURCE');
            :default ::= action => ::array
            quartet  ::= a a a a
        start symbol is quartet
        a ~ 'a'
END_OF_SOURCE

push @tests_data, [
    $english2_grammar, 'aaaa',
    'SLIF grammar failed',
    <<'END_OF_MESSAGE',
Parse of BNF/Scanless source is ambiguous
Length of symbol "statement" at line 2, column 13 is ambiguous
  Choices start with: quartet  ::= a a a a
  Choice 1 ends at line 2, column 32
  Choice 1 ending: quartet  ::= a a a a
  Choice 2: Symbol ends at line 3, column 31
  Choice 2 ending: uartet  ::= a a a a\n        start symbol is quartet
END_OF_MESSAGE
    'English start statement second'
];

#####

my $explicit_grammar1 = \(<<'END_OF_SOURCE');
	      :default ::= action => ::array
	      quartet  ::= a a a a;
        start symbol is quartet
        a ~ 'a'
END_OF_SOURCE

push @tests_data,
    [
    $explicit_grammar1, 'aaaa',
    [qw(a a a a)],     'Parse OK',
    'Explicit English start statement second'
    ];

#####

my $explicit_grammar2 = \(<<'END_OF_SOURCE');
	:default ::= action => ::array
	octet  ::= a a a a
        start symbol <is> octet
        a ~ 'a'
        start ~ 'a'
        symbol ~ 'a'
        is ~ 'a'
        octet ::= a
END_OF_SOURCE

push @tests_data,
    [
    $explicit_grammar2, 'aaaaaaaa',
    [qw(a a a a a a a), ['a']],     'Parse OK',
    'Long quartet; no start statement'
    ];

#####
# test null statements

my $disambig_grammar = \(<<'END_OF_SOURCE');
	;:default ::= action => ::array
	octet  ::= a a a a
        ;a ~ 'a';;;;;
END_OF_SOURCE

push @tests_data,
    [
    $disambig_grammar, 'aaaa',
    [qw(a a a a)],     'Parse OK',
    'Grammar with null statements'
    ];

#####
# test grouped statements

my $grouping_grammar = \(<<'END_OF_SOURCE');
	;:default ::= action => ::array
	{quartet ::= a b c d };
        a ~ 'a' { b ~ 'b' c~'c' } { d ~ 'd'; };
	{ {;} }
END_OF_SOURCE

push @tests_data,
    [
    $grouping_grammar, 'abcd',
    [qw(a b c d)],     'Parse OK',
    'Grammar with grouped statements'
    ];

#####
# test null adverbs

{
    my $grammar = \(<<'END_OF_SOURCE');
	:default ::= ,action => ::array,
	quartet ::= a b c d ,
        a ~ 'a' { b ~ 'b' c~'c' }  d ~ 'd',
END_OF_SOURCE

    push @tests_data,
        [
        $grammar,      'abcd',
        [qw(a b c d)], 'Parse OK',
        'Grammar with null adverbs'
        ];
}

#####

TEST:
for my $test_data (@tests_data) {
    my ( $source, $input, $expected_value, $expected_result, $test_name ) =
        @{$test_data};
    my ( $actual_value, $actual_result );
    PROCESSING: {
        my $grammar;
        if (not defined eval {
                $grammar =
                    Marpa::R2::Scanless::G->new( { source => $source } );
                1;
            }
            )
        {
            say $EVAL_ERROR if $DEBUG;
            my $abbreviated_error = $EVAL_ERROR;

            chomp $abbreviated_error;
            $abbreviated_error =~ s/^ Marpa[:][:]R2 \s+ exception \s+ at \s+ .* \z//xms;
            $actual_value  = 'SLIF grammar failed';
            $actual_result = $abbreviated_error;
            last PROCESSING;
        } ## end if ( not defined eval { $grammar = Marpa::R2::Scanless::G...})
        my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

        if ( not defined eval { $recce->read( \$input ); 1 } ) {
            say $EVAL_ERROR if $DEBUG;
            my $abbreviated_error = $EVAL_ERROR;
            chomp $abbreviated_error;
            $abbreviated_error =~ s/\n.*//xms;
            $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
            $actual_value  = 'No parse';
            $actual_result = $abbreviated_error;
            last PROCESSING;
        } ## end if ( not defined eval { $recce->read( \$input ); 1 })
        my $value_ref = $recce->value();
        if ( not defined $value_ref ) {
            $actual_value  = 'No parse';
            $actual_result = 'Input read to end but no parse';
            last PROCESSING;
        }
        $actual_value  = ${$value_ref};
        $actual_result = 'Parse OK';
        last PROCESSING;
    } ## end PROCESSING:

    Test::More::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Test::More::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end for my $test_data (@tests_data)

# vim: expandtab shiftwidth=4:
