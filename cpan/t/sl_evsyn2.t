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

# Synopsis tests

# Test SLIF -- predicted, nulled and completed events with 
# deactivation and reactivation, initialization at DSL time,
# initialization override at recce creation time

use 5.010;
use strict;
use warnings;

use Test::More tests => 4;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $rules = <<'END_OF_GRAMMAR';
:start ::= sequence
sequence ::= A B C D
    action => OK
A ::= 'a'
A ::= # empty
B ::= 'b'
B ::= # empty
C ::= 'c'
C ::= # empty
D ::= 'd'
D ::= # empty

# Marpa::R2::Display
# name: SLIF predicted event statement synopsis

event '^a' = predicted A
event '^b'=off = predicted B
event '^c'=on = predicted C
event '^d' = predicted D

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF completed event statement synopsis

event 'a' = completed A
event 'b'=off = completed B
event 'c'=on = completed C
event 'd' = completed D

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF nulled event statement synopsis

event '!a' = nulled A
event '!b'=off = nulled B
event '!c'=on = nulled C
event '!d' = nulled D

# Marpa::R2::Display::End

END_OF_GRAMMAR

# This test the order of events
# No more than one of each event type per line
# so that order is non-arbitrary
my $location_0_events = qq{0 !a !c !d ^a ^c ^d\n};
my $after_0_events = <<'END_OF_EVENTS';
1 a !c !d ^c ^d
2 !c !d ^c ^d
3 c !d ^d
4 d
END_OF_EVENTS

my $grammar = Marpa::R2::Scanless::G->new( { source => \$rules } );

my @events = map { ( '!' . $_, '^' . $_, $_ ) } qw(a c d);

# Test of all events
my $all_events_expected = $location_0_events . $after_0_events ;
do_test( "all events", $grammar, q{abcd}, $all_events_expected );

my $loc0_events_expected = $location_0_events .  join "\n", (1 .. 4), q{};
do_test( "all events deactivated", $grammar, q{abcd}, $loc0_events_expected, [] );

sub show_last_subtext {
    my ($recce) = @_;
    my ( $start, $end ) = $recce->last_completed_range('subtext');
    return 'No expression was successfully parsed' if not defined $start;
    return $recce->range_to_string( $start, $end );
}

sub do_test {
    my ( $test, $slg, $string, $expected_events, $reactivate_events ) = @_;
    my $recce = Marpa::R2::Scanless::R->new(
        { grammar => $grammar, semantics_package => 'My_Actions' } );
    if (defined $reactivate_events) {

# Marpa::R2::Display
# name: SLIF activate() method synopsis

        $recce->activate($_, 0) for @events;

# Marpa::R2::Display::End

        $recce->activate($_) for @{$reactivate_events};

    }

# Marpa::R2::Display
# name: SLIF events() method synopsis

    my @actual_events = ();
    my $length = length $string;
    my $pos    = $recce->read( \$string );
    READ: while (1) {

        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            push @{$actual_events[$pos]}, $name;
        }

        last READ if $pos >= $length;
        $pos = $recce->resume($pos);
    } ## end READ: while (1)

# Marpa::R2::Display::End

    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse\n";
    }
    my $actual_value = ${$value_ref};
    my $actual_events = q{};
    for (my $i = 0; $i <= $length; $i++) {
        my $events = $actual_events[$i] // [];
        $actual_events .= join " ", $i, @{$events};
        $actual_events .= "\n";
    }
    Test::More::is( $actual_value, q{1792}, qq{Value for $test} );
    Marpa::R2::Test::is( $actual_events, $expected_events,
        qq{Events for $test} );
} ## end sub do_test

sub My_Actions::OK { return 1792 };

# vim: expandtab shiftwidth=4:
