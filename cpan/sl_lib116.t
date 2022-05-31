#!/usr/bin/perl
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

# Dave Abrahams Libmarpa issue 116

use 5.010001;
use strict;
use warnings;
use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $source = <<'END_OF_SOURCE';
:default ::= action => ::array
:start ::= Script
END_OF_SOURCE

my $grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'My_Nodes',
        source          => \$source,
    }
);

my @terminals = (
#    [ Number   => qr/\d+/xms,    "Number" ],
#    [ 'op pow' => qr/[\^]/xms,   'Exponentiation operator' ],
#    [ 'op pow' => qr/[*][*]/xms, 'Exponentiation' ],          # order matters!
#    [ 'op times' => qr/[*]/xms, 'Multiplication operator' ],  # order matters!
#    [ 'op divide'   => qr/[\/]/xms, 'Division operator' ],
#    [ 'op add'      => qr/[+]/xms,  'Addition operator' ],
#    [ 'op subtract' => qr/[-]/xms,  'Subtraction operator' ],
#    [ 'op lparen'   => qr/[(]/xms,  'Left parenthesis' ],
#    [ 'op rparen'   => qr/[)]/xms,  'Right parenthesis' ],
#    [ 'op comma'    => qr/[,]/xms,  'Comma operator' ],
);

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

my $string = q{};
$recce->read( \$string, 0, 0 );

my $length = length $string;
pos $string = 0;
TOKEN: while (1) {
    my $start_of_lexeme = pos $string;
    last TOKEN if $start_of_lexeme >= $length;
    next TOKEN if $string =~ m/\G\s+/gcxms;    # skip whitespace
    TOKEN_TYPE: for my $t (@terminals) {
        my ( $token_name, $regex, $long_name ) = @{$t};
        next TOKEN_TYPE if not $string =~ m/\G($regex)/gcxms;
        my $lexeme = $1;

        if ( not defined $recce->lexeme_alternative($token_name) ) {
            die
                qq{Parser rejected token "$long_name" at position $start_of_lexeme, before "},
                substr( $string, $start_of_lexeme, 40 ), q{"};
        }
        next TOKEN
            if $recce->lexeme_complete( $start_of_lexeme,
                    ( length $lexeme ) );

    } ## end TOKEN_TYPE: for my $t (@terminals)
    die qq{No token found at position $start_of_lexeme, before "},
        substr( $string, pos $string, 40 ), q{"};
} ## end TOKEN: while (1)

my $value_ref = $recce->value();
if ( not defined $value_ref ) {
    die "No parse was found, after reading the entire input\n";
}

Test::More::is( ${$value_ref}, '', 'Value of parse' );

# vim: expandtab shiftwidth=4:
