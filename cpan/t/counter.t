#!perl
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

# This uses an ambiguous grammar to implement a binary
# counter.  A very expensive way to do it, but a
# good test of the ranking logic.

use 5.010;
use strict;
use warnings;

use Test::More tests => 32;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

sub zero { return '0' }
sub one  { return '1' }

sub start_rule_action {
    shift;
    return join q{}, @_;
}

## use critic

sub gen_grammar {
    my ($is_count_up) = @_;
    my $grammar = Marpa::R2::Grammar->new(
        {   start => 'S',
            rules => [
                {   lhs    => 'S',
                    rhs    => [qw/digit digit digit digit/],
                    action => 'main::start_rule_action'
                },
                {   lhs    => 'digit',
                    rhs    => ['zero'],
                    rank   => $is_count_up ? 1 : 0,
                    action => 'main::zero'
                },
                {   lhs    => 'digit',
                    rhs    => ['one'],
                    rank   => $is_count_up ? 0 : 1,
                    action => 'main::one'
                },
                {   lhs => 'one',
                    rhs => ['t'],
                },
                {   lhs => 'zero',
                    rhs => ['t'],
                },
            ],
            terminals => [qw(t)],
        }
    );
    return $grammar->precompute();
} ## end sub gen_grammar

my @counting_up =
    qw{ 0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111 };
my @counting_down = reverse @counting_up;

for my $is_count_up ( 1, 0 ) {
    my $count = $is_count_up ? ( \@counting_up ) : ( \@counting_down );
    my $direction_desc = $is_count_up ? 'up' : 'down';
    my $recce = Marpa::R2::Recognizer->new(
        { grammar => gen_grammar($is_count_up), ranking_method => 'rule' } );

    my $input_length = 4;
    for ( 1 .. $input_length ) { $recce->read('t'); }

    my $i = 0;
    while ( my $result = $recce->value() ) {
        my $got      = ${$result};
        my $expected = reverse $count->[$i];
        Test::More::is( $got, $expected, "counting $direction_desc $i" );
        $i++;
    } ## end while ( my $result = $recce->value() )
} ## end for my $is_count_up ( 1, 0 )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
