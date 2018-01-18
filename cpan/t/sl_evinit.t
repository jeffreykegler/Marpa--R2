#!perl
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

# Test of scannerless parsing -- predicted, nulled and completed events
# which are initialized off in the DSL, and selectively reactivated

use 5.010001;
use strict;
use warnings;

use Test::More tests => 46;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $rules = <<'END_OF_GRAMMAR';
:start ::= sequence
sequence ::= A B C D E F G  H I J K L
    action => OK
A ::= 'a'
B ::= 'b'
C ::= 'c'
D ::= 'd'
E ::=
F ::= 'f'
G ::=
H ::= 'h'
I ::= 'i'
J ::= 'j'
K ::=
L ::= 'l'

event '^a'=off = predicted A
event '^b'=off = predicted B
event '^c'=off = predicted C
event '^d'=off = predicted D
event '^e'=off = predicted E
event '^f'=off = predicted F
event '^g'=off = predicted G
event '^h'=off = predicted H
event '^i'=off = predicted I
event '^j'=off = predicted J
event '^k'=off = predicted K
event '^l'=off = predicted L
event 'a'=off = completed A
event 'b'=off = completed B
event 'c'=off = completed C
event 'd'=off = completed D
event 'e'=off = completed E
event 'f'=off = completed F
event 'g'=off = completed G
event 'h'=off = completed H
event 'i'=off = completed I
event 'j'=off = completed J
event 'k'=off = completed K
event 'l'=off = completed L
event 'a[]'=off = nulled A
event 'b[]'=off = nulled B
event 'c[]'=off = nulled C
event 'd[]'=off = nulled D
event 'e[]'=off = nulled E
event 'f[]'=off = nulled F
event 'g[]'=off = nulled G
event 'h[]'=off = nulled H
event 'i[]'=off = nulled I
event 'j[]'=off = nulled J
event 'k[]'=off = nulled K
event 'l[]'=off = nulled L
END_OF_GRAMMAR

# This test the order of events
# No more than one of each event type per line
# so that order is non-arbitrary
my $all_events_expected = <<'END_OF_EVENTS';
0 ^a
1 a ^b
2 b ^c
3 c ^d
4 d e[] ^f
5 f g[] ^h
6 h ^i
7 i ^j
8 j k[] ^l
9 l
END_OF_EVENTS

my %pos_by_event = ();
my @events;
for my $event_line  (split /\n/xms, $all_events_expected)
{
    my ($pos, @pos_events) = split " ", $event_line;
    $pos_by_event{$_} = $pos for @pos_events;
    push @events, @pos_events;
}

my $grammar = Marpa::R2::Scanless::G->new( { source => \$rules } );

# Test of all events
my %active_events = map { ( $_, 1 ) } @events;
do_test( "all events activated", $grammar, q{abcdfhijl}, $all_events_expected, \%active_events );

# Now deactivate all events
do_test( "no events activated", $grammar, q{abcdfhijl}, q{}, );

# Now deactivate all events, and turn them back on, one at a time
EVENT: for my $event (@events) {
    my $expected_events = $pos_by_event{$event} . " $event\n";
    do_test( qq{event "$event" reactivated},
        $grammar, q{abcdfhijl}, $expected_events,
        { $event => 1 } );
} ## end EVENT: for my $event (@events)

sub show_last_subtext {
    my ($recce) = @_;
    my ( $start, $end ) = $recce->last_completed_range('subtext');
    return 'No expression was successfully parsed' if not defined $start;
    return $recce->range_to_string( $start, $end );
}

sub do_test {
    my ( $test, $slg, $string, $expected_events, $active_events ) = @_;
    my $actual_events = q{};
    my $extra_recce_args = {};
    $extra_recce_args = { event_is_active => $active_events }
        if defined $active_events;

    my $recce = Marpa::R2::Scanless::R->new(
        { grammar => $grammar, semantics_package => 'My_Actions' },
        $extra_recce_args
        );

    my $length = length $string;
    my $pos    = $recce->read( \$string );
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
    if ( not defined $value_ref ) {
        die "No parse\n";
    }
    my $actual_value = ${$value_ref};
    Test::More::is( $actual_value, q{1792}, qq{Value for $test} );

    Marpa::R2::Test::is( $actual_events, $expected_events,
        qq{Events for $test} );
} ## end sub do_test

sub My_Actions::OK { return 1792 };

# vim: expandtab shiftwidth=4:
