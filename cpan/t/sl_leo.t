#!perl
# Copyright 2014 Jeffrey Kegler
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

use Test::More tests => 2;

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
event A = completed <A>
event C = completed <C>
event S = completed <S>

# Marpa::R2::Display
# name: SLIF nulled event statement synopsis

event 'A[]' = nulled <A>

# Marpa::R2::Display::End

event 'C[]' = nulled <C>
event 'S[]' = nulled <S>
END_OF_DSL
    }
);

my $recce         = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
my $input         = 'aaa';
my $event_history = q{};
my $pos           = $recce->read( \$input );
READ: while (1) {
    my @event_names;
    for ( my $ix = 0; my $event = $recce->event($ix); $ix++ ) {
        push @event_names, @{$event};
    }
    $event_history .= join q{ }, $pos, sort @event_names;
    $event_history .= "\n";
    last READ if $pos >= length $input;
    $pos = $recce->resume();
} ## end READ: while (1)
my $value_ref = $recce->value();
my $value = $value_ref ? ${$value_ref} : 'No parse';
Marpa::R2::Test::is( $value,         'aaa',           'Leo SLIF parse' );
Marpa::R2::Test::is( $event_history, <<'END_OF_TEXT', 'Event history' );
1 A[] C[] S S[]
2 A A[] C C[] S S[]
3 A A[] C C[] S S[]
END_OF_TEXT

# vim: expandtab shiftwidth=4:
