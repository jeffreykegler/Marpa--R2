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

# Synopsis for DSL pod of SLIF

use 5.010;
use strict;
use warnings;
use Test::More tests => 4;
use English qw( -no_match_vars );
use Scalar::Util;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

# Marpa::R2::Display
# name: SLIF DSL synopsis

use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {   
        bless_package => 'My_Nodes',
        source          => \(<<'END_OF_SOURCE'),
:default ::= action => [values] bless => ::lhs
lexeme default = action => [range,value] bless => ::name

:start ::= Script
Script ::= Expression+ separator => comma
comma ~ [,]
Expression ::=
    Number
    | '(' Expression ')' assoc => group
   || Expression '**' Expression assoc => right
   || Expression '*' Expression
    | Expression '/' Expression
   || Expression '+' Expression
    | Expression '-' Expression

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

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: Scanless show_rules() synopsis

my $show_rules_output = $grammar->show_rules();

# Marpa::R2::Display::End

sub my_parser {
    my ( $grammar, $p_input_string ) = @_;

# Marpa::R2::Display
# name: Scanless recognizer synopsis

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $self = bless { grammar => $grammar }, 'My_Actions';
    $self->{recce} = $recce;

 $recce->read($p_input_string);

    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse was found, after reading the entire input\n";
    }
    say STDERR Data::Dumper::Dumper(traverse(${$value_ref}));
    die Data::Dumper::Dumper($value_ref);

# Marpa::R2::Display::End

    return ${$value_ref};

} ## end sub my_parser

sub traverse 
{
    my ($node) = @_;
    return if not defined $node;
    if ( Scalar::Util::blessed($node) and $node->can('doit') ) {
        return $node->doit();
    }
    my $reftype = Scalar::Util::reftype($node);
    return $node if not $reftype;
    if ( $reftype eq 'ARRAY' ) {
        return [ map { traverse($_) } @{$node} ];
    }
    return $node;
}

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

package My_Nodes;

our $SELF;
sub new { return $SELF }

sub My_Nodes::Number::doit { return $_[2] }
sub My_Nodes::parens    { shift; return $_[1] }
sub My_Nodes::add       { shift; return $_[0] + $_[2] }
sub My_Nodes::subtract  { shift; return $_[0] - $_[2] }
sub My_Nodes::multiply  { shift; return $_[0] * $_[2] }
sub My_Nodes::divide    { shift; return $_[0] / $_[2] }
sub My_Nodes::pow       { shift; return $_[0]**$_[2] }
sub My_Nodes::first_arg { shift; return shift; }
sub My_Nodes::script    { shift; return join q{ }, @_ }

# vim: expandtab shiftwidth=4:
