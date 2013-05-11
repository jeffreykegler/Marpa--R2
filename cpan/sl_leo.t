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
# The example from p. 166 of Leo's paper,
# augmented to test Leo prediction items.
#

use 5.010;
use strict;
use warnings;

use Test::More tests => 7;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub main::default_action {
    shift;
    return ( join q{}, grep {defined} @_ );
}

## use critic

my $grammar = Marpa::R2::Scanless::G->new(
    { 
        default_action => 'main::default_action',
        source => \(<<'END_OF_DSL'),
:start ::= S
S ::= 'a' A
A ::= B
B ::= C
C ::= S
S ::=
event have_A = completed <A>
event have_B = completed <B>
event have_C = completed <C>
event have_S = completed <S>
END_OF_DSL
    }
);

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
my $input = 'aaa';
my $pos = $recce->read(\$input);
READ: while (1) {
    for (my $ix = 0; my $event = $recce->event($ix); $ix++) {
        my ($event_name) = @{$event};
        say "$pos $event_name";
    }
    last READ if $pos >= length $input;
    $pos = $recce->resume();
}
my $value_ref = $recce->value();
my $value = $value_ref ? ${$value_ref} : 'No parse';
Marpa::R2::Test::is( $value, 'aaa', 'Leo SLIF parse' );

# vim: expandtab shiftwidth=4:
