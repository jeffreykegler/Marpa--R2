#!/usr/bin/perl
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

# Regression tests for several bugs found by Jean-Damien

use 5.010;
use strict;
use warnings;

use Test::More tests => 11;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $dsl;
my $grammar;
my $recce;
my $input;
my $length;
my $expected_output;
my $actual_output;
my $pos = 0;

# This first problem was with ambiguous SLIF parses when
# used together with values from an external scanner

$dsl = <<'END_OF_SOURCE';
:start ::= Expression
Expression ::= Number
    | Expression Add Expression action => do_add
    | Expression Multiply Expression action => do_multiply
      Add ~ '+'
      Multiply ~ '*'
      Number ~ digits
      digits ~ [\d]+
      :discard ~ whitespace
      whitespace ~ [\s]+
END_OF_SOURCE

$grammar = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Nodes',
        default_action => 'first_arg',
        source         => \$dsl,
    }
);

$recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
$input = '2*1+3*4+5';
$pos   = 0;
$recce->read( \$input, 0, 0 );
for my $input_token (qw(2 * 1 + 3 * 4 + 5)) {
    my $token_type =
          $input_token eq '+' ? 'Add'
        : $input_token eq '*' ? 'Multiply'
        :                       'Number';
    my $return_value = $recce->lexeme_read( $token_type, $pos, 1, $input_token );
    $pos++;
    Test::More::is( $return_value, $pos, "Return value of lexeme_read() is $pos" );
} ## end for my $input_token (qw(2 * 1 + 3 * 4 + 5))

my @values = ();
while ( my $value_ref = $recce->value() ) {
    push @values, ${$value_ref};
}

$expected_output = '19 19 25 29 31 36 36 37 37 42 45 56 72 72';
$actual_output = join " ", sort @values;
Test::More::is( $actual_output, $expected_output, 'Values for Durand test' );

package My_Nodes;

sub new { return {}; }

sub do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}

sub first_arg { shift; return shift; }

# Second problem -- Location 0 events

$dsl = <<GRAMMAR_SOURCE;
:start ::= Script
Script ::= null1 null2 digits1 null3 null4 digits2 null5
digits1 ::= DIGITS
digits2 ::= DIGITS
null1   ::=
null2   ::=
null3   ::=
null4   ::=
null5   ::=
DIGITS ~ [\\d]+
WS ~ [\\s]
:discard ~ WS
GRAMMAR_SOURCE

foreach (
    qw/Script/,
    ( map {"digits$_"} ( 1 .. 2 ) ),
    ( map {"null$_"}   ( 1 .. 5 ) )
    )
{
    $dsl .= <<EVENTS;
event '${_}\$' = completed <$_>
event '^${_}' = predicted <$_>
event '${_}[]' = nulled <$_>
EVENTS
} ## end foreach ( qw/Script/, ( map {"digits$_"} ( 1 .. 2 ) ), ( ...))

$input = '    1 2';

$grammar = Marpa::R2::Scanless::G->new( { source  => \$dsl } );
$recce   = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
$length  = length $input;
$actual_output   = q{};
$expected_output = q{};
for (
    my $pos = $recce->read( \$input );
    $pos < $length;
    $pos = $recce->resume()
    )
{
    $actual_output .= record_events($recce);
} ## end for ( my $pos = $recce->read( \$input ); $pos < $length...)
$actual_output   .= record_events($recce);
$expected_output .= <<'END_OF_EXPECTED_OUTPUT';
^Script ^digits1 null1[] null2[]
^digits2 digits1$ null3[] null4[]
Script$ digits2$ null5[]
END_OF_EXPECTED_OUTPUT

sub record_events {
    my ( $recce, $pos ) = @_;
    my $text = q{};
    my @events;
    for (
        my $event_ix = 0;
        my $event    = $recce->event($event_ix);
        $event_ix++
        )
    {
        my ( $event_name, @event_data ) = @{$event};
        push @events, $event_name;
    } ## end for ( my $event_ix = 0; my $event = $recce->event($event_ix...))
    return ( join q{ }, sort @events ) . "\n";
} ## end sub record_events
Test::More::is( $actual_output, $expected_output,
    'Events for Durand event test 1' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
