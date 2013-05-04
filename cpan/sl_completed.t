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

# Test of scannerless parsing -- completion events

use 5.010;
use strict;
use warnings;

use Test::More tests => 7;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $rules = <<'END_OF_GRAMMAR';
:default ::= action => ::array
:start ::= text
text ::= <text segment>*
<text segment> ::= <parenthesized text>
<text segment> ::= <word>
<parenthesized text> ::= '(' text ')'
event subtext = completed <parenthesized text>

word ~ [\w]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new(
    {   source          => \$rules }
);

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

my $input = q{42 ( hi 42 hi ) 7 11};
my $length  = length $input;
my $pos = $recce->read(\$input);
READ: for ( ; $pos < $length; $pos = $recce->resume() ) {
    for my $event ( @{ $recce->events() } ) {
        my ($name) = @{$event};
        say "Event: $name";
    } ## end for my $event ( @{ $recce->event() } )
} ## end READ: for ( ; $pos < $length; $recce->resume() )
my $value_ref = $recce->value();
if ( not defined $value_ref ) {
    die "No parse\n";
}
my $actual_value = ${$value_ref};
say Data::Dumper::Dumper($actual_value);
Test::More::is( $actual_value, q{}, qq{Value for "$input"} );

# vim: expandtab shiftwidth=4:
