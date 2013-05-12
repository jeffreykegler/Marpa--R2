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

use Test::More tests => 6;

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
:start ::= <expression>
<expression> ::= 'x' | <assignment>
<assignment> ::= <divide assignment>
<assignment> ::= <multiply assignment>
<assignment> ::= <add assignment>
<assignment> ::= <subtract assignment>
<assignment> ::= <plain assignment>
<divide assignment> ::= 'x' '/=' <expression>
<multiply assignment> ::= 'x' '*=' <expression>
<add assignment> ::= 'x' '+=' <expression>
<subtract assignment> ::= 'x' '-=' <expression>
<plain assignment> ::= 'x' '=' <expression>
event divide = completed <divide assignment>
event multiply = completed <multiply assignment>
event subtract = completed <subtract assignment>
event add = completed <add assignment>
event plain = completed <plain assignment>
:discard ~ whitespace
whitespace ~ [\s]*
END_OF_DSL
    }
);

# Reaches closure
do_test($grammar, 'x = x += x -= x *= x /= x',
<<'END_OF_HISTORY'
plain
add plain
add plain subtract
add multiply plain subtract
add divide multiply plain subtract
END_OF_HISTORY
);

# Reaches closure and continues
do_test($grammar, 'x = x += x -= x *= x /= x = x += x -= x *= x /= x',
<<'END_OF_HISTORY'
plain
add plain
add plain subtract
add multiply plain subtract
add divide multiply plain subtract
add divide multiply plain subtract
add divide multiply plain subtract
add divide multiply plain subtract
add divide multiply plain subtract
add divide multiply plain subtract
END_OF_HISTORY
);

# Never reaches closure
do_test($grammar, 'x = x += x -= x = x += x -= x',
<<'END_OF_HISTORY'
plain
add plain
add plain subtract
add plain subtract
add plain subtract
add plain subtract
END_OF_HISTORY
);

sub do_test {
    my ( $grammar, $input, $expected_history ) = @_;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $event_history;
    my $pos = $recce->read( \$input );
    READ: while (1) {
        my @event_names;
        for ( my $ix = 0; my $event = $recce->event($ix); $ix++ ) {
            push @event_names, @{$event};
        }
        $event_history .= join q{ }, sort @event_names;
        $event_history .= "\n";
        last READ if $pos >= length $input;
        $pos = $recce->resume();
    } ## end READ: while (1)
    my $value_ref = $recce->value();
    my $value = $value_ref ? ${$value_ref} : 'No parse';
    ( my $expected = $input ) =~ s/\s//gxms;
    Marpa::R2::Test::is( $value, $expected, "Leo SLIF parse of $expected" );
    Marpa::R2::Test::is( $event_history, $expected_history, "Event history of $expected" );
} ## end sub do_test

# vim: expandtab shiftwidth=4:
