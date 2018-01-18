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

# Test of scannerless parsing -- named lexeme events
# deactivation and reactivation

use 5.010001;
use strict;
use warnings;

use Test::More tests => 12;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $base_rules = <<'END_OF_GRAMMAR';
:start ::= sequence
sequence ::= char* action => OK
char ::= a | b | c | d
a ~ 'a'
b ~ 'b'
c ~ 'c'
d ~ 'd'

# Marpa::R2::Display
# name: SLIF named lexeme event synopsis

:lexeme ~ <a> pause => before event => 'before a'
:lexeme ~ <b> pause => after event => 'after b'=on
:lexeme ~ <c> pause => before event => 'before c'=off
:lexeme ~ <d> pause => after event => 'after d'

# Marpa::R2::Display::End

END_OF_GRAMMAR

my $rules = $base_rules;
$rules =~ s/=off$//gxms;

# This test the order of events
# No more than one of each event type per line
# so that order is non-arbitrary
my $events_expected = <<'END_OF_EVENTS';
END_OF_EVENTS

my $grammar = Marpa::R2::Scanless::G->new( { source => \$rules } );

my %base_expected_events;
$base_expected_events{'all'} = <<'END_OF_EVENTS';
0 before a
1 before a
3 after b
4 after b
5 after b
5 before c
6 before c
7 before c
9 after d
9 before a
10 before a
11 before a
13 after b
13 before c
14 before c
16 after d
17 after d
18 after d
19 after d
19 before a
21 after b
21 before c
23 after d
END_OF_EVENTS
$base_expected_events{'once'} = <<'END_OF_EVENTS';
0 before a
3 after b
5 before c
9 after d
END_OF_EVENTS
$base_expected_events{'seq'} = <<'END_OF_EVENTS';
0 before a
3 after b
5 before c
9 after d
9 before a
13 after b
13 before c
16 after d
19 before a
21 after b
21 before c
23 after d
END_OF_EVENTS

my %expected_events = %base_expected_events;

sub do_test {
    my ($slr, $test) = @_;
    state $string = q{aabbbcccdaaabccddddabcd};
    state $length = length $string;
    my $pos = $slr->read( \$string );
    my $actual_events = q{};
    my $deactivated_event_name;
    READ: while (1) {
        my @actual_events = ();
        my $event_name;
        EVENT:
        for my $event ( @{ $slr->events() } ) {
            my ($event_name) = @{$event};
            die "event name is undef" if not defined $event_name;
            die "Unexpected event: $event_name"
                if not $event_name =~ m/\A (before|after) \s [abcd] \z/xms;
            ACTIVATION_LOGIC: {
                last ACTIVATION_LOGIC if $test eq 'all';
                if ( $test eq 'once' ) {
                    $slr->activate( $event_name, 0 );
                }
                if ( $test eq 'seq' ) {
                    $slr->activate( $deactivated_event_name, 1 )
                        if defined $deactivated_event_name;
                    $slr->activate( $event_name, 0 );
                    $deactivated_event_name = $event_name;
                } ## end if ( $test eq 'seq' )
            } ## end ACTIVATION_LOGIC:
            push @actual_events, $event_name;
        } ## end for my $event ( @{ $slr->events() } )
        if (@actual_events) {
            $actual_events .= join q{ }, $pos, @actual_events;
            $actual_events .= "\n";
            my ( $start_of_lexeme, $length_of_lexeme ) = $slr->pause_span();
            $pos = $start_of_lexeme + $length_of_lexeme;
        } elsif (my $pause_lexeme = $slr->pause_lexeme()) {
            $actual_events .= "unnamed\n";
            my ( $start_of_lexeme, $length_of_lexeme ) = $slr->pause_span();
            $pos = $start_of_lexeme + $length_of_lexeme;
        }
        last READ if $pos >= $length;
        $pos = $slr->resume($pos);
    } ## end READ: while (1)
    my $value_ref = $slr->value();
    if ( not defined $value_ref ) {
        die "No parse\n";
    }
    my $actual_value = ${$value_ref};
    Test::More::is( $actual_value, q{1792}, qq{Value for test "$test"} );
    my $expected_events = q{};
    Marpa::R2::Test::is( $actual_events, $expected_events{$test},
        qq{Events for test "$test"} );
} ## end sub do_test

my $slr = Marpa::R2::Scanless::R->new( { grammar => $grammar, semantics_package => 'My_Actions' } );
do_test($slr, 'all');
$slr = Marpa::R2::Scanless::R->new( { grammar => $grammar, semantics_package => 'My_Actions' } );
do_test($slr, 'once');
$slr = Marpa::R2::Scanless::R->new( { grammar => $grammar, semantics_package => 'My_Actions' } );
do_test($slr, 'seq');

# Once again, but with unnamed events
$expected_events{'all'} =~ s/^ [^\n]+ $/unnamed/gxms;
$rules =~ s/^ ([:] lexeme \s [^\n]* ) \s+ event \s* [=][>] [^\n]* $/$1/gxms;
$grammar = Marpa::R2::Scanless::G->new( { source => \$rules } );
$slr = Marpa::R2::Scanless::R->new( { grammar => $grammar, semantics_package => 'My_Actions' } );
do_test($slr, 'all');

# Yet another time, with initializers
%expected_events = %base_expected_events;
$expected_events{'all'} =~ s/^\d+ \s before \s c \n//gxms;
$rules = $base_rules;
$grammar = Marpa::R2::Scanless::G->new( { source => \$rules } );
$slr = Marpa::R2::Scanless::R->new( { grammar => $grammar, semantics_package => 'My_Actions' } );
do_test($slr, 'all');

# Yet another time, with initializers
%expected_events = %base_expected_events;
$expected_events{'all'} =~ s/^\d+ \s after \s b \n//gxms;
$rules = $base_rules;
$grammar = Marpa::R2::Scanless::G->new( { source => \$rules } );

# Marpa::R2::Display
# name: SLIF recce event_is_active named arg example

$slr = Marpa::R2::Scanless::R->new(
    {   grammar           => $grammar,
        semantics_package => 'My_Actions',
        event_is_active   => { 'before c' => 1, 'after b' => 0 }
    }
);

# Marpa::R2::Display::End

do_test($slr, 'all');

sub My_Actions::OK { return 1792 }

# vim: expandtab shiftwidth=4:
