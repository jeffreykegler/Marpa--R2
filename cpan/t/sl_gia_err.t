#!perl
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

# Tests that include a grammar, an input, and an error message
# or an AST, but no semantics.
#
# Uses include tests of parsing of the SLIF DSL itself.

use 5.010;
use strict;
use warnings;

use Test::More tests => 38;
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
Parse of BNF/Scanless source failed:
Length of symbol "statement" at line 2, column 13 is ambiguous
  Choices start with: quartet  ::= a a a a
  Choice 1, length=20, ends at line 2, column 32
  Choice 1: quartet  ::= a a a a
  Choice 2, length=52, ends at line 3, column 31
  Choice 2: quartet  ::= a a a a\n        start symbol is quarte
END_OF_MESSAGE
    'English start statement second'
];

my $invalid_syntax_grammar = \(<<'END_OF_SOURCE');
    quartet$ ::= a b c d e f
END_OF_SOURCE

push @tests_data, [
    $invalid_syntax_grammar, 'n/a',
    'SLIF grammar failed',
    <<'END_OF_MESSAGE',
Parse of BNF/Scanless source failed
Error in SLIF parse: No lexeme found at line 1, column 12
* String before error:     quartet
* The error was at line 1, column 12, and at character 0x0024 '$', ...
* here: $ ::= a b c d e f\n
END_OF_MESSAGE
    'Grammar with syntax error'
];

# test <>-wrapping of SLIF symbol names containing spaces

my $non_unique_sequence_grammar = \(<<'END_OF_SOURCE');
    <sequence of items> ::= item* proper => 1
    <sequence of items> ::= <forty two>
END_OF_SOURCE

push @tests_data, [
    $non_unique_sequence_grammar, 'n/a',
    'SLIF grammar failed',
    <<'END_OF_MESSAGE',
LHS of sequence rule would not be unique: <sequence of items> -> <forty two>
END_OF_MESSAGE
    'Grammar with non-unique LHS sequence symbols'
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

{

# Marpa::R2::Display
# name: statements separted by semicolon
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

my $source = \(<<'END_OF_SOURCE');
          :default ::= action => ::array
          quartet  ::= a a a a;
        inaccessible is warn by default
        a ~ 'a'
END_OF_SOURCE

# Marpa::R2::Display::End

push @tests_data,
    [
    $source, 'aaaa',
    [qw(a a a a)],     'Parse OK',
    'Explicit inaccessible is warn statement second, using semi-colon'
    ];
}

###

{

# Marpa::R2::Display
# name: statements grouped in curly braces
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

my $source = \(<<'END_OF_SOURCE');
      {
          :default ::= action => ::array
          quartet  ::= a a a a
      }
      inaccessible is warn by default
      a ~ 'a'
END_OF_SOURCE

# Marpa::R2::Display::End

push @tests_data,
    [
    $source, 'aaaa',
    [qw(a a a a)],     'Parse OK',
    'Explicit inaccessible is warn statement second, using grouping'
    ];
}

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
# test null adverbs

{
    my $grammar = \(<<'END_OF_SOURCE');
    :default ::= ,action => ::array,
    quartet ::= a b c d e f
        { a ~ 'a' { b ~ 'b' { c~'c' {; d~'d' {e~'e'}} }}  f ~ 'f' }
END_OF_SOURCE

    push @tests_data,
        [
        $grammar,      'abcdef',
        [qw(a b c d e f)], 'Parse OK',
        'Grammar with nested statement groups'
        ];
}

#####
# test discarding of spaces in array descriptor actions

{
    my $grammar = \(<<'END_OF_SOURCE');
    :default ::= action => [lhs, value]
    lexeme default = action => [ lhs, value ]
    s ::= a
    a ~ '42'
END_OF_SOURCE

    push @tests_data,
        [
        $grammar,      '42',
        [ 1, [ 2, '42' ] ], 'Parse OK',
        'Grammar with spaces in array descriptor actions'
        ];
}

#####

if (1) {
    my $grammar = \(<<'END_OF_SOURCE');
    :default ::= action => [ lhs, value]
    lexeme default = action => [lhs, value ]
    s ::= a
    a ~ '42'
END_OF_SOURCE

    push @tests_data,
        [
        $grammar,      '42',
        [ 1, [ 2, '42' ] ], 'Parse OK',
        'Grammar with spaces in array descriptor actions'
        ];
}

if (1) {
    my $grammar = \(<<'END_OF_SOURCE');
:default ::= action => [ name, value]
lexeme default = action => [name, value ]
:start ::= start
start ~ 'X'
:discard ~ [^[:print:]]
END_OF_SOURCE

    push @tests_data,
        [
        $grammar,      'X',
        [ qw(start X) ], 'Parse OK',
        'Bug found by Jean-Damien Durand'
        ];
}

if (1) {
    use utf8;
    my $grammar = \(<<'END_OF_SOURCE');
:default ::= action => [name,values]
<Š> ::= <Á> <Č>
<Á> ::= a+
<Č> ::= c
a ~ 'a'
c ~ 'c'
END_OF_SOURCE

    push @tests_data,
      [
        $grammar, 'aac', [ 'Š', [qw(Á a a)], [qw(Č c)] ],
        'Parse OK', 'Bug in Unicode found by choroba'
      ];
}

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

    Marpa::R2::Test::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Marpa::R2::Test::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end for my $test_data (@tests_data)

# vim: expandtab shiftwidth=4:
