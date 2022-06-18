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

my $basic_pascal_rules = parse_rules(<<"RULES");
     A ::= a
     A ::= E
     E ::= Null
RULES

sub do_pascal {
    my ( $g, $n ) = @_;
    my $parse_count = 0;
    my $recce = Marpa::R2::Recognizer->new( { grammar => $g } );

    # Just in case
    $recce->set( { max_parses => 999, end => $n } );
    for my $token_ix ( 0 .. $n - 1 ) {
        defined $recce->read('a') or die "Cannot read char $token_ix";
    }
    $parse_count++ while $recce->value();
    return $parse_count;
} ## end sub do_pascal

my @pascal_numbers = (
    '1',
    '1 1',
    '1 2 1',
    '1 3 3 1',
    '1 4 6 4 1',
    '1 5 10 10 5 1',
    '1 6 15 20 15 6 1',
    '1 7 21 35 35 21 7 1',
    '1 8 28 56 70 56 28 8 1',
    '1 9 36 84 126 126 84 36 9 1',
    '1 10 45 120 210 252 210 120 45 10 1',
    '1 11 55 165 330 462 462 330 165 55 11 1',
    '1 12 66 220 495 792 924 792 495 220 66 12 1'
);

for my $n ( 0 .. 12 ) {

    my $variable_rule = [ S => [ ('A') x $n ] ];
    my $grammar = Marpa::R2::Grammar->new(
        {   start => 'S',
            rules => [ $variable_rule, @{$basic_pascal_rules} ],
            warnings      => ( $n ? 1 : 0 ),
        }
    );

    $grammar->precompute();

    my $expected = join q{ }, $pascal_numbers[$n];
    my $actual = join q{ }, map { do_pascal( $grammar, $_ ) } 0 .. $n;
    say "$actual" or die "say failed: $ERRNO";
    if ( $actual ne $expected ) {
        say "  MISMATCH, above should have been $expected"
            or die "say failed: $ERRNO";
    }

} ## end for my $n ( 0 .. 10 )
