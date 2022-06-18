#!perl
# Copyright 2022 Jeffrey Kegler
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

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Marpa::R2;
use MarpaX::Simple::Rules '0.2.6', 'parse_rules';

my $catalan_rules = parse_rules(<<"RULES");
     pair ::= a a
     pair ::= pair a
     pair ::= a pair
     pair ::= pair pair
RULES

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'pair',
        rules => $catalan_rules,
    }
);
$grammar->precompute();

sub do_catalan {
    my $n           = shift;
    my $parse_count = 0;
    my $recce       = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    # Just in case
    $recce->set( { max_parses => 9999, } );
    for my $token_ix ( 0 .. $n - 1 ) {
        defined $recce->read('a') or die "Cannot read char $token_ix";
    }
    $parse_count++ while $recce->value();
    return $parse_count;
} ## end sub do_catalan

my @catalan_numbers = ( 0, 1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862 );

my $expected = join q{ }, @catalan_numbers;
my $actual = join q{ }, 0, 1, map { do_catalan($_) } 2 .. 10;

say "Expected: $expected" or die "say failed: $ERRNO";
say "  Actual: $actual"   or die "say failed: $ERRNO";
say $actual eq $expected ? 'OK' : 'MISMATCH' or die "say failed: $ERRNO";

