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

# Synopsis for Scannerless version of Stuizand interface

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
    {   
        action_object  => 'My_Actions',
        bless_package => 'My_Nodes',
        default_action => '::dwim',
        source          => \(<<'END_OF_SOURCE'),
:start ::= Script
Script ::= Expression+ separator => comma bless => script
comma ~ [,]
Expression ::=
    Number
    | ('(') Expression (')') assoc => group
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

my $show_rules_output = $grammar->show_rules();

Marpa::R2::Test::is( $show_rules_output,
    <<'END_OF_SHOW_RULES_OUTPUT', 'Scanless show_rules()' );
Lex (G0) Rules:
0: comma -> [[,]]
1: [Lex-0] -> [[\(]]
2: [Lex-1] -> [[\)]]
3: [Lex-2] -> [[\*]] [[\*]]
4: [Lex-3] -> [[\*]]
5: [Lex-4] -> [[\/]]
6: [Lex-5] -> [[\+]]
7: [Lex-6] -> [[\-]]
8: Number -> [[\d]]+
9: [:discard] -> whitespace
10: whitespace -> [[\s]]+
11: [:discard] -> hash comment
12: hash comment -> terminated hash comment
13: hash comment -> unterminated final hash comment
14: terminated hash comment -> [[\#]] hash comment body vertical space char
15: unterminated final hash comment -> [[\#]] hash comment body
16: hash comment body -> hash comment char*
17: vertical space char -> [[\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]]
18: hash comment char -> [[^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]]
19: [:start_lex] -> Number
20: [:start_lex] -> [:discard]
21: [:start_lex] -> [Lex-0]
22: [:start_lex] -> [Lex-1]
23: [:start_lex] -> [Lex-2]
24: [:start_lex] -> [Lex-3]
25: [:start_lex] -> [Lex-4]
26: [:start_lex] -> [Lex-5]
27: [:start_lex] -> [Lex-6]
28: [:start_lex] -> comma
G1 Rules:
0: [:start] -> Script
1: Script -> Expression+ /* discard_sep */
2: Expression -> Expression
3: Expression -> Expression
4: Expression -> Expression
5: Expression -> Expression
6: Expression -> Number
7: Expression -> [Lex-0] Expression [Lex-1]
8: Expression -> Expression [Lex-2] Expression
9: Expression -> Expression [Lex-3] Expression
10: Expression -> Expression [Lex-4] Expression
11: Expression -> Expression [Lex-5] Expression
12: Expression -> Expression [Lex-6] Expression
END_OF_SHOW_RULES_OUTPUT

sub my_parser {
    my ( $grammar, $p_input_string ) = @_;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $self = bless { grammar => $grammar }, 'My_Actions';
    $self->{recce} = $recce;
    local $My_Actions::SELF = $self;

    if ( not defined eval { $recce->read($p_input_string); 1 }
        )
    {
        ## Add last expression found, and rethrow
        my $eval_error = $EVAL_ERROR;
        chomp $eval_error;
        die $self->show_last_expression(), "\n", $eval_error, "\n";
    } ## end if ( not defined eval { $event_count = $recce->read...})

    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die $self->show_last_expression(), "\n",
            "No parse was found, after reading the entire input\n";
    }

    return ${$value_ref};

} ## end sub my_parser

sub doit {
    my ($value) = @_;
    my $ref_type = ref $value;
    my $is_my_node = substr( $ref_type, 0, 10 ) eq 'My_Nodes::';
    if ($is_my_node) {
        my $method = $value->can('doit');
        if ( defined $method ) {
            my @children = map { doit($_); } @{$value};
            return $method->(@children);
        }
    } ## end if ($is_my_node)
    return [ map { doit($_) } @{$value} ]
        if $is_my_node
            or $ref_type eq 'ARRAY';
    return $value;
} ## end sub doit

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
    my $result = doit($value);
    Test::More::like( $result, $output_re, 'Value of scannerless parse' );
}

package My_Nodes::script;

sub doit { return join q{ },  @_; }

package My_Nodes::add;

sub doit { my ($a, $b) = @_; return $a+$b; }

package My_Nodes::subtract;

sub doit { my ($a, $b) = @_; return $a-$b; }

package My_Nodes::multiply;

sub doit { my ($a, $b) = @_; return $a*$b; }

package My_Nodes::divide;

sub doit { my ($a, $b) = @_; return $a/$b; }

package My_Nodes::power;

sub doit { my ($a, $b) = @_; return $a**$b; }

package My_Actions;

our $SELF;
sub new { return $SELF }

sub show_last_expression {
    my ($self) = @_;
    my $recce = $self->{recce};
    my ( $start, $end ) = $recce->last_completed_range('Expression');
    return 'No expression was successfully parsed' if not defined $start;
    my $last_expression = $recce->range_to_string( $start, $end );
    return "Last expression successfully parsed was: $last_expression";
} ## end sub show_last_expression

# vim: expandtab shiftwidth=4:
