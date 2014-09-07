#!/usr/bin/perl
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

# Synopsis for Scannerless version of Stuizand interface

use 5.010;
use strict;
use warnings;
use Test::More tests => 6;
use English qw( -no_match_vars );

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

# Marpa::R2::Display
# name: Scanless grammar synopsis

use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {   
        source          => \(<<'END_OF_SOURCE'),
:default ::= action => do_first_arg
:start ::= Script
Script ::= Expression+ separator => comma action => do_script
comma ~ [,]
Expression ::=
    Number
    | '(' Expression ')' action => do_parens assoc => group
   || Expression '**' Expression action => do_pow assoc => right
   || Expression '*' Expression action => do_multiply
    | Expression '/' Expression action => do_divide
   || Expression '+' Expression action => do_add
    | Expression '-' Expression action => do_subtract
Number ~ [\d]+

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
END_OF_SOURCE
    }
);

my $input = '42 * 1 + 7';

# test with wrong arguments
my $err_msg_expected = q{$slr->parse(): Arguments to $slr->parse must be ref to HASH
  Argument 0 is a ref to SCALAR
};

eval { $grammar->parse( \$input ) };
my $err_msg = $@;
like( $err_msg, qr/^\Q$err_msg_expected\E/m, "ref to SCALAR arg caught" );

# test with proper arguments
my $value_ref =
    $grammar->parse( { input => \$input, semantics_package => 'My_Actions' } );

# Marpa::R2::Display::End

Marpa::R2::Test::is( ${$value_ref}, 49, 'Synopsis value test');

my $show_rules_output = $grammar->show_rules();
$show_rules_output .= $grammar->show_rules(1, 'L0');

Marpa::R2::Test::is( $show_rules_output,
    <<'END_OF_SHOW_RULES_OUTPUT', 'Scanless show_rules()' );
G1 R0 Script ::= Expression +
G1 R1 Expression ::= Expression
G1 R2 Expression ::= Expression
G1 R3 Expression ::= Expression
G1 R4 Expression ::= Expression
G1 R5 Expression ::= Number
G1 R6 Expression ::= '(' Expression ')'
G1 R7 Expression ::= Expression '**' Expression
G1 R8 Expression ::= Expression '*' Expression
G1 R9 Expression ::= Expression '/' Expression
G1 R10 Expression ::= Expression '+' Expression
G1 R11 Expression ::= Expression '-' Expression
G1 R12 :start ::= Script
L0 R0 comma ::= [,]
L0 R1 '(' ::= [\(]
L0 R2 ')' ::= [\)]
L0 R3 '**' ::= [\*] [\*]
L0 R4 '*' ::= [\*]
L0 R5 '/' ::= [\/]
L0 R6 '+' ::= [\+]
L0 R7 '-' ::= [\-]
L0 R8 Number ::= [\d] +
L0 R9 :discard ::= whitespace
L0 R10 whitespace ::= [\s] +
L0 R11 :discard ::= <hash comment>
L0 R12 <hash comment> ::= <terminated hash comment>
L0 R13 <hash comment> ::= <unterminated final hash comment>
L0 R14 <terminated hash comment> ::= [\#] <hash comment body> <vertical space char>
L0 R15 <unterminated final hash comment> ::= [\#] <hash comment body>
L0 R16 <hash comment body> ::= <hash comment char> *
L0 R17 <vertical space char> ::= [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
L0 R18 <hash comment char> ::= [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
L0 R19 :start_lex ::= Number
L0 R20 :start_lex ::= :discard
L0 R21 :start_lex ::= '('
L0 R22 :start_lex ::= ')'
L0 R23 :start_lex ::= '**'
L0 R24 :start_lex ::= '*'
L0 R25 :start_lex ::= '/'
L0 R26 :start_lex ::= '+'
L0 R27 :start_lex ::= '-'
L0 R28 :start_lex ::= comma
END_OF_SHOW_RULES_OUTPUT

sub my_parser {
    my ( $grammar, $p_input_string ) = @_;

# Marpa::R2::Display
# name: Scanless recognizer synopsis

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $self = bless { grammar => $grammar }, 'My_Actions';
    $self->{recce} = $recce;

    if ( not defined eval { $recce->read($p_input_string); 1 }
        )
    {
        ## Add last expression found, and rethrow
        my $eval_error = $EVAL_ERROR;
        chomp $eval_error;
        die $self->show_last_expression(), "\n", $eval_error, "\n";
    } ## end if ( not defined eval { $event_count = $recce->read...})

    my $value_ref = $recce->value( $self );
    if ( not defined $value_ref ) {
        die $self->show_last_expression(), "\n",
            "No parse was found, after reading the entire input\n";
    }

# Marpa::R2::Display::End

    return ${$value_ref};

} ## end sub my_parser

my @tests = (
    [   '42*2+7/3, 42*(2+7)/3, 2**7-3, 2**(7-3)' =>
            qr/\A 86[.]3\d+ \s+ 126 \s+ 125 \s+ 16\z/xms
    ],
    [   '42*3+7, 42 * 3 + 7, 42 * 3+7' => qr/ \s* 133 \s+ 133 \s+ 133 \s* /xms
    ],
    [   '15329 + 42 * 290 * 711, 42*3+7, 3*3+4* 4' =>
            qr/ \s* 8675309 \s+ 133 \s+ 25 \s* /xms
    ],
);

for my $test (@tests) {
    my ( $input, $output_re ) = @{$test};
    my $value = my_parser( $grammar, \$input );
    Test::More::like( $value, $output_re, 'Value of scannerless parse' );
}

# Marpa::R2::Display
# name: Scanless recognizer semantics

package My_Actions;

sub do_parens    { shift; return $_[1] }
sub do_add       { shift; return $_[0] + $_[2] }
sub do_subtract  { shift; return $_[0] - $_[2] }
sub do_multiply  { shift; return $_[0] * $_[2] }
sub do_divide    { shift; return $_[0] / $_[2] }
sub do_pow       { shift; return $_[0]**$_[2] }
sub do_first_arg { shift; return shift; }
sub do_script    { shift; return join q{ }, @_ }

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: Scanless recognizer diagnostics

sub show_last_expression {
    my ($self) = @_;
    my $recce = $self->{recce};
    my ( $g1_start, $g1_length ) = $recce->last_completed('Expression');
    return 'No expression was successfully parsed' if not defined $g1_start;
    my $last_expression = $recce->substring( $g1_start, $g1_length );
    return "Last expression successfully parsed was: $last_expression";
} ## end sub show_last_expression

# Marpa::R2::Display::End

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
