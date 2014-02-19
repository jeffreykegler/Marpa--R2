#!perl
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

# Tests which require only grammar, input, and an output with no
# semantics -- usually just an AST

use 5.010;
use strict;
use warnings;

use Test::More tests => 16;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

our $DEBUG = 0;

# In crediting test, JDD = Jean-Damien Durand

my $glenn_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
            :default ::= action => ::array

            Start  ::= Child DoubleColon Token

            DoubleColon ~ '::'
            Child ~ 'child'
            Token ~
                word
                | word ':' word
            word ~ [\w]+

END_OF_SOURCE
    }
);

my $input = 'child::book';

my @tests_data = (
    [   $glenn_grammar,
        'child::book',
        [ 'child', q{::}, 'book' ],
        'Parse OK',
        'Nate Glenn bug regression'
    ],
);

# Marpa::R2::Display
# name: Case-insensitive characters examples
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

my $ic_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
            :default ::= action => ::array

            Start  ::= Child DoubleColon Token

            DoubleColon ~ '::'
            Child ~ 'cHILd':i
            Token ~
                word
                | word ':' word
            word ~ [\w]:ic +

END_OF_SOURCE
    }
);

# Marpa::R2::Display::End

push @tests_data,
    [   $ic_grammar,
        'ChilD::BooK',
        [ 'ChilD', q{::}, 'BooK' ],
        'Parse OK',
        'Case insensitivity test'
    ];

my $durand_grammar1 = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:default ::= action => ::array
start symbol is test
test ::= TEST
:lexeme ~ TEST
TEST                  ~ '## Allowed in the input' NEWLINE
WS                    ~ [ \t]
WS_any                ~ WS*
POUND                 ~ '#'
_NEWLINE              ~ [\n]
NOT_NEWLINE_any       ~ [^\n]*
NEWLINE              ~ _NEWLINE
COMMENT               ~ WS_any POUND NOT_NEWLINE_any _NEWLINE
:discard              ~ COMMENT
BLANKLINE             ~ WS_any _NEWLINE
:discard              ~ BLANKLINE
END_OF_SOURCE
    }
);

push @tests_data, [
    $durand_grammar1, <<INPUT,
## Allowed in the input

# Another comment
INPUT
    [ "## Allowed in the input\n" ],
    'Parse OK',
    'JDD test of discard versus accepted'
];

my $durand_grammar2 = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:default ::= action => ::array
test ::= 'test input' NEWLINE
WS                    ~ [ \t]
WS_any                ~ WS*
POUND                 ~ '#'
_NEWLINE              ~ [\n]
NOT_NEWLINE_any       ~ [^\n]*
NEWLINE              ~ _NEWLINE
COMMENT               ~ WS_any POUND NOT_NEWLINE_any _NEWLINE
:discard              ~ COMMENT
BLANKLINE             ~ WS_any _NEWLINE
:discard              ~ BLANKLINE
END_OF_SOURCE
    }
);

push @tests_data, [
    $durand_grammar2, <<INPUT,
# Comment followed by a newline

# Another comment
test input
INPUT
    [ 'test input', "\n" ],
    'Parse OK',
    'Regression test of bug found by JDD'
];

# ===============

my $durand_grammar3 = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:default ::= action => ::array

Script ::= '=' '/' 'dumb'

_WhiteSpace                            ~ ' '
_LineTerminator                        ~ [\n]
_SingleLineComment                     ~ '//' _SingleLineCommentCharsopt
_SingleLineCommentChars                ~ _SingleLineCommentChar _SingleLineCommentCharsopt
_SingleLineCommentCharsopt             ~ _SingleLineCommentChars
_SingleLineCommentCharsopt             ~
_SingleLineCommentChar                 ~ [^\n]

_S ~
    _WhiteSpace
  | _LineTerminator
  | _SingleLineComment

S_MANY ~ _S+
:discard ~ S_MANY

END_OF_SOURCE
    }
);

push @tests_data, [
    $durand_grammar3, <<INPUT,
 = / dumb
INPUT
    [ qw(= / dumb) ],
    'Parse OK',
    'Regression test of perl_pos bug found by JDD'
];

# Test of forgiving token from Peter Stuifzand
{
    my $source = <<'SOURCE';
:default ::= action => ::array
product ::= sku (nl) name (nl) price price price (nl)

sku       ~ sku_0 '.' sku_0
sku_0     ~ [\d]+

price     ~ price_0 ',' price_0
price_0   ~ [\d]+
nl        ~ [\n]

sp        ~ [ ]+
:discard  ~ sp

:lexeme ~ <name> forgiving => 1
name      ~ [^\n]+

SOURCE

    my $input = <<'INPUT';
130.12312
Descriptive line
1,10 1,10 1,30
INPUT

    my $slg = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $slg, $input,
        [ '130.12312', 'Descriptive line', '1,10', '1,10', '1,30' ],
        'Parse OK', 'Test of forgiving token from Peter Stuifzand'
        ];
}

# Test of forgiving token from Ruslan Zakirov
{

# Marpa::R2::Display
# name: forgiving adverb example
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
:default ::= action => ::array
:start ::= content
content ::= name ':' value
name ~ [A-Za-z0-9-]+
value ~ [A-Za-z0-9:-]+
:lexeme ~ value forgiving => 1
END_OF_SOURCE

# Marpa::R2::Display

    my $input = 'UID:urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1';
    my $expected_output =
        [ 'UID', ':', 'urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1' ];

    my $slg = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $slg, $input, $expected_output,
        'Parse OK', 'Test of forgiving token from Ruslan Zakirov'
        ];
}

# Test of forgiving token from Ruslan Zakirov
# This time using the lexeme default statement
{

    my $source = <<'END_OF_SOURCE';
lexeme default = forgiving => 1
:default ::= action => ::array
:start ::= content
content ::= name ':' value
name ~ [A-Za-z0-9-]+
value ~ [A-Za-z0-9:-]+
END_OF_SOURCE

    my $input = 'UID:urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1';
    my $expected_output =
        [ 'UID', ':', 'urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1' ];

    my $slg = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $slg, $input, $expected_output,
        'Parse OK', 'Test of forgiving token using lexeme default statement'
        ];
}

TEST:
for my $test_data (@tests_data) {
    my ( $grammar, $test_string, $expected_value, $expected_result,
        $test_name )
        = @{$test_data};
    my ( $actual_value, $actual_result ) =
        my_parser( $grammar, $test_string );
    Test::More::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Test::More::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end TEST: for my $test_data (@tests_data)

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

    if ( not defined eval { $recce->read( \$string ); 1 } ) {
        say $EVAL_ERROR if $DEBUG;
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $recce->read( \$string ); 1 ...})
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        return 'No parse', 'Input read to end but no parse';
    }
    return [ return ${$value_ref}, 'Parse OK' ];
} ## end sub my_parser

# vim: expandtab shiftwidth=4:
