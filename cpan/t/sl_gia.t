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

# Tests which require only grammar, input, and an output with no
# semantics -- usually just an AST

use 5.010;
use strict;
use warnings;

use Test::More tests => 34;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my @tests_data = ();

our $DEBUG = 0;

# In crediting test, JDD = Jean-Damien Durand
if (1) {
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

    push @tests_data,
        [
        $glenn_grammar,
        'child::book',
        [ 'child', q{::}, 'book' ],
        'Parse OK',
        'Nate Glenn bug regression'
        ];
} ## end if (0)

# Marpa::R2::Display
# name: Case-insensitive characters examples
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

if (1) {
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
        [
        $ic_grammar,
        'ChilD::BooK',
        [ 'ChilD', q{::}, 'BooK' ],
        'Parse OK',
        'Case insensitivity test'
        ];
} ## end if (0)

if (1) {
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
        ["## Allowed in the input\n"],
        'Parse OK',
        'JDD test of discard versus accepted'
    ];
} ## end if (0)

# ===============

if (1) {
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
} ## end if (1)

# ===============

if (1) {
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
        [qw(= / dumb)],
        'Parse OK',
        'Regression test of perl_pos bug found by JDD'
    ];
} ## end if (1)


# ===============

# Regression test of grammar without lexers --
# based on one from Jean-Damien
if (1) {
    my $grammar = Marpa::R2::Scanless::G->new(
        {   source => \(<<'END_OF_SOURCE'),
:start ::= null
null ::=
END_OF_SOURCE
        }
    );

    push @tests_data, [
        $grammar, q{},
        undef,
        'Parse OK',
        'Regression test of lexerless grammar, bug found by JDD'
    ];

} ## end if (1)

# Test of forgiving token from Peter Stuifzand
if (1) {

# Marpa::R2::Display
# name: forgiving adverb example
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
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

END_OF_SOURCE

# Marpa::R2::Display::END

    my $input = <<'INPUT';
130.12312
Descriptive line
1,10 1,10 1,30
INPUT

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $grammar, $input,
        [ '130.12312', 'Descriptive line', '1,10', '1,10', '1,30' ],
        'Parse OK', 'Test of forgiving token from Peter Stuifzand'
        ];
}

# Test of LATM token from Ruslan Zakirov
if (1) {

# Marpa::R2::Display
# name: latm adverb example
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
:default ::= action => ::array
:start ::= content
content ::= name ':' value
name ~ [A-Za-z0-9-]+
value ~ [A-Za-z0-9:-]+
:lexeme ~ value latm => 1
END_OF_SOURCE

# Marpa::R2::Display

    my $input = 'UID:urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1';
    my $expected_output =
        [ 'UID', ':', 'urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1' ];

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $grammar, $input, $expected_output,
        'Parse OK', 'Test of LATM token from Ruslan Zakirov'
        ];
}

# Test of LATM token from Ruslan Zakirov
# This time using the lexeme default statement
if (1) {

    my $source = <<'END_OF_SOURCE';
lexeme default = latm => 1
:default ::= action => ::array
:start ::= content
content ::= name ':' value
name ~ [A-Za-z0-9-]+
value ~ [A-Za-z0-9:-]+
END_OF_SOURCE

    my $input = 'UID:urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1';
    my $expected_output =
        [ 'UID', ':', 'urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1' ];

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $grammar, $input, $expected_output,
        'Parse OK', 'Test of LATM token using lexeme default statement'
        ];
}

# Test of rank adverb
if (1) {

# Marpa::R2::Display
# name: rank adverb example
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
lexeme default = latm => 1
:default ::= action => [name,values]
:start ::= externals
externals ::= external* action => [values]
external ::= special action => ::first
   | unspecial action => ::first
unspecial ::= ('I' 'am' 'special') words ('--' 'NOT!' ';') rank => 1
special ::= words (';') rank => -1
words ::= word* action => [values]

:discard ~ whitespace
whitespace ~ [\s]+
word ~ [\w!-]+
END_OF_SOURCE

    my $input = <<'END_OF_INPUT';
I am special so very special -- NOT!;
I am special and nothing is going to change that;
END_OF_INPUT

# Marpa::R2::Display

    my $expected_output = [
        [ 'unspecial', [qw(so very special)] ],
        [   'special',
            [qw(I am special and nothing is going to change that)],
        ]
    ];

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $grammar, $input, $expected_output,
        'Parse OK', 'Test of rank adverb for display'
        ];
}

# Test of rule array item descriptor for action adverb
# todo: test by converting rule and lhs ID's to names
# based on $grammar->symbol_is_lexeme(symbol_id) -- to be written
if (1) {
    my $source = <<'END_OF_SOURCE';

    :default ::= action => [lhs, rule, values]
    lexeme default = action => [lhs, rule, value]
    start ::= number1 number2
    number1 ::= <forty two>
    number2 ::= <forty three>
    <forty two> ~ '42'
    <forty three> ~ '43'
END_OF_SOURCE

    my $input = '4243';
    my $expected_output =
        [ 1, 0, [ 2, 1, [ 4, undef, '42' ] ], [ 3, 2, [ 5, undef, '43' ] ] ];

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $grammar, $input, $expected_output,
        'Parse OK', 'Test of rule array item descriptor for action adverb'
        ];
}

# Test of 'symbol', 'name' array item descriptors
if (1) {

# Marpa::R2::Display
# name: symbol, name array descriptor example
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';

    :default ::= action => [symbol, name, values]
    lexeme default = action => [symbol, name, value]
    start ::= number1 number2 name => top
    number1 ::= <forty two> name => 'number 1'
    number2 ::= <forty three> name => 'number 2'
    <forty two> ~ '42'
    <forty three> ~ '43'
END_OF_SOURCE

# Marpa::R2::Display::End

    my $input           = '4243';
    my $expected_output = [
        'start',
        'top',
        [ 'number1', 'number 1', [ 'forty two',   'forty two',   '42' ] ],
        [ 'number2', 'number 2', [ 'forty three', 'forty three', '43' ] ]
    ];

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $grammar, $input, $expected_output,
        'Parse OK', 'Test of rule array item descriptor for action adverb'
        ];
}

### Test of 'inaccessible is ok'
if (1) {

# Marpa::R2::Display
# name: inaccessible is ok statement
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';

    inaccessible is ok by default

    :default ::= action => [values]
    start ::= stuff*
    stuff ::= a | b
    a ::= x action => ::first
    b ::= x action => ::first
    c ::= x action => ::first
    x ::= 'x'
END_OF_SOURCE

# Marpa::R2::Display::End

    my $input           = 'xx';
    my $expected_output = [
        [ [ 'x' ] ],
        [ [ 'x' ] ]
    ];

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );
    push @tests_data,
        [
        $grammar, $input, $expected_output,
        'Parse OK', qq{Test of "Inaccessible is ok"}
        ];
}

if (1) {
    my $source = <<'END_OF_SOURCE';
 
    inaccessible is ok by default
    :default ::= action => ::first
    
    start ::= !START!
    start1 ::= X
    start2 ::= Y
 
    X ~ 'X'
    Y ~ 'X'
 
END_OF_SOURCE

    my $input           = 'X';
    my $expected_output = 'X';

    for my $this_start (qw/start1 start2/) {

        my $this_source = $source;
        $this_source =~ s/!START!/$this_start/;
        my $grammar = Marpa::R2::Scanless::G->new( { source => \$this_source } );
        push @tests_data,
            [
            $grammar, $input, $expected_output,
            'Parse OK', qq{Test of changing start symbols: <$this_start>}
            ];

    } ## end for my $this_start (qw/start1 start2/)
}

if (1) {
    my $source = <<'END_OF_SOURCE';
 
    :default ::= action => ::first
    
    dual_start ::= start1 name => 'first start rule'
    dual_start ::= start2 name => 'second start rule'
    start1 ::= X
    start2 ::= Y
 
    X ~ 'X'
    Y ~ 'Y'
 
END_OF_SOURCE

    my $input           = 'X';
    my $expected_output = 'X';

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );

# Marpa::R2::Display
# name: $grammar->start_symbol_id() example

    my $start_id = $grammar->start_symbol_id();

# Marpa::R2::Display::End

    Test::More::is( $start_id, 0, q{Test of $grammar->start_symbol_id()} );

    my @rule_names = ();

# Marpa::R2::Display
# name: $grammar->rule_name() example

    push @rule_names, $grammar->rule_name($_) for $grammar->rule_ids();

# Marpa::R2::Display::End

    my $rule_names = join q{:}, @rule_names;
    Test::More::is(
        $rule_names,
        'first start rule:second start rule:start1:start2:[:start]',
        q{Test of $grammar->rule_name()}
    );

    push @tests_data,
        [
        $grammar, $input, $expected_output,
        'Parse OK', qq{Test of alternative as start rule}
        ];

} ## end if (0)

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
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $recce->read( \$string ); 1 ...})
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        return 'No parse', 'Input read to end but no parse';
    }
    return [ return ${$value_ref}, 'Parse OK' ];
} ## end sub my_parser

# vim: expandtab shiftwidth=4:
