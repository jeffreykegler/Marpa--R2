#!/usr/bin/perl
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

# Synopsis for Scannerless interface

use 5.010;
use strict;
use warnings;
use Test::More tests => 4;
use English qw( -no_match_vars );
use Scalar::Util qw(blessed);

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'My_Nodes',
        source        => \(<<'END_OF_SOURCE'),
:default ::= action => ::array bless => ::lhs
:start ::= Script
Script ::= Expression+ separator => comma bless => script
comma ~ [,]
Expression ::=
    Number bless => primary
    | ('(') Expression (')') assoc => group bless => parens
   || Expression ('**') Expression assoc => right bless => power
   || Expression ('*') Expression bless => multiply
    | Expression ('/') Expression bless => divide
   || Expression ('+') Expression bless => add
    | Expression ('-') Expression bless => subtract
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

# Marpa::R2::Display
# name: SLR show_rules() synopsis

my $show_rules_output = $grammar->show_rules();

# Marpa::R2::Display::End

$show_rules_output .= $grammar->show_rules(1, 'G0');

Marpa::R2::Test::is( $show_rules_output,
    <<'END_OF_SHOW_RULES_OUTPUT', 'Scanless show_rules()' );
G1 R0 :start ::= <Script>
G1 R1 <Script> ::= <Expression> +
G1 R2 <Expression> ::= <Expression>
G1 R3 <Expression> ::= <Expression>
G1 R4 <Expression> ::= <Expression>
G1 R5 <Expression> ::= <Expression>
G1 R6 <Expression> ::= <Number>
G1 R7 <Expression> ::= '(' <Expression> ')'
G1 R8 <Expression> ::= <Expression> '**' <Expression>
G1 R9 <Expression> ::= <Expression> '*' <Expression>
G1 R10 <Expression> ::= <Expression> '/' <Expression>
G1 R11 <Expression> ::= <Expression> '+' <Expression>
G1 R12 <Expression> ::= <Expression> '-' <Expression>
G0 R0 <comma> ::= [,]
G0 R1 '(' ::= [\(]
G0 R2 ')' ::= [\)]
G0 R3 '**' ::= [\*] [\*]
G0 R4 '*' ::= [\*]
G0 R5 '/' ::= [\/]
G0 R6 '+' ::= [\+]
G0 R7 '-' ::= [\-]
G0 R8 <Number> ::= [\d] +
G0 R9 :discard ::= <whitespace>
G0 R10 <whitespace> ::= [\s] +
G0 R11 :discard ::= <hash comment>
G0 R12 <hash comment> ::= <terminated hash comment>
G0 R13 <hash comment> ::= <unterminated final hash comment>
G0 R14 <terminated hash comment> ::= [\#] <hash comment body> <vertical space char>
G0 R15 <unterminated final hash comment> ::= [\#] <hash comment body>
G0 R16 <hash comment body> ::= <hash comment char> *
G0 R17 <vertical space char> ::= [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
G0 R18 <hash comment char> ::= [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
G0 R19 :start_lex ::= <Number>
G0 R20 :start_lex ::= :discard
G0 R21 :start_lex ::= '('
G0 R22 :start_lex ::= ')'
G0 R23 :start_lex ::= '**'
G0 R24 :start_lex ::= '*'
G0 R25 :start_lex ::= '/'
G0 R26 :start_lex ::= '+'
G0 R27 :start_lex ::= '-'
G0 R28 :start_lex ::= <comma>
END_OF_SHOW_RULES_OUTPUT

sub my_parser {
    my ( $grammar, $p_input_string ) = @_;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

    $recce->read($p_input_string);
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse was found, after reading the entire input\n";
    }
    return ${$value_ref}->doit();

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
    my $result = my_parser( $grammar, \$input );
    Test::More::like( $result, $output_re, 'Value of scannerless parse' );
}

sub My_Nodes::script::doit {
    my ($self) = @_;
    return join q{ }, map { $_->doit() } @{$self};
}

sub My_Nodes::add::doit {
    my ($self) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit() + $b->doit();
}

sub My_Nodes::subtract::doit {
    my ($self) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit() - $b->doit();
}

sub My_Nodes::multiply::doit {
    my ($self) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit() * $b->doit();
}

sub My_Nodes::divide::doit {
    my ($self) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit() / $b->doit();
}

sub My_Nodes::primary::doit { return $_[0]->[0]; }
sub My_Nodes::parens::doit  { return $_[0]->[0]->doit(); }

sub My_Nodes::power::doit {
    my ($self) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit()**$b->doit();
}

# vim: expandtab shiftwidth=4:
