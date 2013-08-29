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

use Test::More tests => 10;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $rules = <<'END_OF_GRAMMAR';
:start ::= text
text ::= <text segment>* action => OK
<text segment> ::= subtext
<text segment> ::= <word>
subtext ::= '(' text ')'
# Marpa::R2::Display
# name: SLIF completed event statement synopsis

event subtext = completed <subtext>

# Marpa::R2::Display::End

word ~ [\w]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new( { source => \$rules } );


do_test($grammar, q{42 ( hi 42 hi ) 7 11}, [ '( hi 42 hi )' ]);
do_test($grammar, q{42 ( hi) 42 (hi ) 7 11}, [ '( hi)', '(hi )' ] );
do_test($grammar, q{(hi 42 hi)}, ['(hi 42 hi)']);
do_test($grammar, q{1(2(3(4)))}, [ qw{ (4) (3(4)) (2(3(4))) } ]);
do_test($grammar, q{(((1)2)3)4}, [ qw{(1) ((1)2) (((1)2)3)} ]);

sub show_last_subtext {
    my ($slr) = @_;
    my ( $start, $end ) = $slr->last_completed_range('subtext');
    return 'No expression was successfully parsed' if not defined $start;
    return $slr->range_to_string( $start, $end );
}

sub do_test {
    my ( $slg, $string, $expected_events ) = @_;
    my @actual_events;
    my $slr = Marpa::R2::Scanless::R->new(
        { grammar => $grammar, semantics_package => 'My_Actions' } );
    my $length = length $string;
    my $pos    = $slr->read( \$string );
    READ: while (1) {

# Marpa::R2::Display
# name: SLR event() method synopsis

        EVENT: for (
            my $event_ix = 0;
            my $event    = $slr->event($event_ix);
            $event_ix++
            )
        {
            my ($name) = @{$event};
            if ( $name eq 'subtext' ) {
                push @actual_events, show_last_subtext($slr);
                next EVENT;
            }
        } ## end for ( my $event_ix = 0; my $event = $slr->event($event_ix...))

# Marpa::R2::Display::End

        last READ if $pos >= $length;
        $pos = $slr->resume($pos);
    } ## end READ: while (1)
    my $value_ref = $slr->value();
    if ( not defined $value_ref ) {
        die "No parse\n";
    }
    my $actual_value = ${$value_ref};
    Test::More::is( $actual_value, q{1792}, qq{Value for "$string"} );
    Test::More::is_deeply( \@actual_events, $expected_events, qq{Events for "$string"} );
} ## end sub do_test

sub My_Actions::OK { return 1792 };

# vim: expandtab shiftwidth=4:
