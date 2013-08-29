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

# A test using the Dyck-Hollerith language

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my $dsl = <<'END_OF_DSL';
# The BNF
:default ::= action => ::first
:start ::= sentence
sentence ::= element
array ::= 'A' <array count> '(' elements ')'
    action => check_array
string ::= ( 'S' <string length> '(' ) text ( ')' )
elements ::= element+
  action => ::array
element ::= string | array

# Declare the places where we pause before
# and after lexemes
:lexeme ~ <string length> pause => after event => 'string length'
event 'expecting text' = predicted <text>

# Declare the lexemes themselves
<array count> ~ [\d]+
<string length> ~ [\d]+
# define <text> as one character of anything, as a stub
# the external scanner determines its actual size and value
text ~ [\d\D]
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
my $recce = Marpa::R2::Scanless::R->new(
    { grammar => $grammar, semantics_package => 'My_Actions' } );

my $input = 'A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))';

my $last_string_length;
my $input_length = length $input;
INPUT:
for (
    my $pos = $recce->read( \$input );
    $pos < $input_length;
    $pos = $recce->resume($pos)
    )
{
    EVENT: for my $event ( @{ $recce->events() } ) {
        my ($name) = @{$event};
        if ( $name eq 'expecting text' ) {
            my $text_length = $last_string_length;
            $recce->lexeme_read( 'text', $pos, $text_length );
            $pos += $text_length;
            next EVENT;
        } ## end if ( $name eq 'expecting text' )
        if ( $name eq 'string length' ) {
            my ( $start_pos, $length ) = $recce->pause_span();
            $last_string_length = $recce->literal( $start_pos, $length ) + 0;
            $pos = $start_pos + $length;
            next EVENT;
        } ## end if ( $name eq 'string length' )
        die "Unexpected event: ", join q{ }, @{$event};
    } ## end EVENT: for my $event ( @{ $recce->events() } )
} ## end INPUT: for ( my $pos = $recce->read( \$input ); $pos < $input_length...)

my $result = $recce->value();
die 'No parse' if not defined $result;
my $received = Data::Dumper::Dumper( ${$result} );

my $expected = <<'EXPECTED_OUTPUT';
$VAR1 = [
          [
            'Hey',
            'Hello, World!'
          ],
          'Ciao!'
        ];
EXPECTED_OUTPUT
Test::More::is( $received, $expected , 'Dyck-Hollerith value');

sub My_Actions::check_array {
    my ( undef, undef, $declared_size, undef, $array ) = @_;
    my $actual_size = @{$array};
    warn
        "Array size ($actual_size) does not match that specified ($declared_size)"
        if $declared_size != $actual_size;
    return $array;
} ## end sub check_array

