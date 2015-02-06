#!/usr/bin/perl
# Copyright 2015 Jeffrey Kegler
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

# A "full" Synopsis for the intro doc to the SLIF

use 5.010;
use strict;
use warnings;
use Test::More tests => 1;
use English qw( -no_match_vars );
use Scalar::Util;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'My_Nodes',
        source        => \(<<'END_OF_SOURCE'),
:default ::= action => [g1start,g1length,name,values]
discard default = event => :symbol=off
lexeme default = action => [ g1start, g1length, start, length, value ]
    latm => 1

:start ::= Script
Script ::= Expression+ separator => comma
comma ~ [,]
Expression ::=
    Number bless => primary
    | '(' Expression ')' bless => paren assoc => group
   || Expression '**' Expression bless => exponentiate assoc => right
   || Expression '*' Expression bless => multiply
    | Expression '/' Expression bless => divide
   || Expression '+' Expression bless => add
    | Expression '-' Expression bless => subtract

Number ~ [\d]+
:discard ~ whitespace event => ws=on
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


my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

my $input = '42*2+7/3, 42*(2+7)/3, 2**7-3, 2**(7-3)';
my $length = length $input;
my $pos = $recce->read(\$input);

my $actual_events = q{};
READ: while (1) {

    my @actual_events = ();

    EVENT:
    for my $event ( @{ $recce->events() } ) {
        my ($name) = @{$event};
        push @actual_events, $name;
    }

    if (@actual_events) {
        $actual_events .= join q{ }, $pos, @actual_events;
        $actual_events .= "\n";
    }
    last READ if $pos >= $length;
    $pos = $recce->resume($pos);
} ## end READ: while (1)

my $value_ref = $recce->value();
die "No parse was found\n" if not defined $value_ref;

# Result will be something like "86.33... 126 125 16"
# depending on the floating point precision
my $result = ${$value_ref};
say Data::Dumper::Dumper($result);

# vim: expandtab shiftwidth=4:
