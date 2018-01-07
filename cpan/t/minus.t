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

use 5.010;

use strict;
use warnings;

use Test::More tests => 10;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

# The inefficiency (at least some of it) is deliberate.
# Passing up a duples of [ string, value ] and then
# assembling a final string at the top would be better
# than assembling the string then taking it
# apart at each step.  But I wanted to test having
# a start symbol that appears repeatedly on the RHS.

## no critic (Subroutines::RequireArgUnpacking)

sub subtraction {
    shift;
    my ( $right_string, $right_value ) = ( $_[2] =~ /^(.*)==(.*)$/xms );
    my ( $left_string,  $left_value )  = ( $_[0] =~ /^(.*)==(.*)$/xms );
    my $value = $left_value - $right_value;
    return '(' . $left_string . q{-} . $right_string . ')==' . $value;
} ## end sub subtraction

sub postfix_decr {
    shift;
    my ( $string, $value ) = ( $_[0] =~ /^(.*)==(.*)$/xms );
    return '(' . $string . q{--} . ')==' . $value--;
}

sub prefix_decr {
    shift;
    my ( $string, $value ) = ( $_[1] =~ /^(.*)==(.*)$/xms );
    return '(' . q{--} . $string . ')==' . --$value;
}

sub negation {
    shift;
    my ( $string, $value ) = ( $_[1] =~ /^(.*)==(.*)$/xms );
    return '(' . q{-} . $string . ')==' . -$value;
}

sub number {
    shift;
    my $value = $_[0];
    return "$value==$value";
}

sub default_action {
    shift;
    return q{} if scalar @_ <= 0;
    return $_[0] if scalar @_ == 1;
    return '(' . join( q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start   => 'E',
        actions => 'main',
        rules   => [
            {   lhs    => 'E',
                rhs    => [qw/E Minus E/],
                action => 'subtraction',
            },
            {   lhs    => 'E',
                rhs    => [qw/E MinusMinus/],
                action => 'postfix_decr',
            },
            {   lhs    => 'E',
                rhs    => [qw/MinusMinus E/],
                action => 'prefix_decr',
            },
            {   lhs    => 'E',
                rhs    => [qw/Minus E/],
                action => 'negation'
            },
            {   lhs    => 'E',
                rhs    => [qw/Number/],
                action => 'number'
            },
        ],

# Marpa::R2::Display
# name: Symbol descriptor example

        symbols => {
            MinusMinus => { terminal => 1 },
            Minus      => { terminal => 1 },
            Number     => { terminal => 1 },
        },

# Marpa::R2::Display::End

        default_action => 'default_action',
    },
);
$grammar->precompute();

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

Marpa::R2::Test::is( $grammar->show_rules,
    <<'END_RULES', 'Minuses Equation Rules' );
0: E -> E Minus E
1: E -> E MinusMinus
2: E -> MinusMinus E
3: E -> Minus E
4: E -> Number
END_RULES

Marpa::R2::Test::is( $grammar->show_ahms,
    <<'END_AHMS', 'Minuses Equation AHMs' );
AHM 0: postdot = "E"
    E ::= . E Minus E
AHM 1: postdot = "Minus"
    E ::= E . Minus E
AHM 2: postdot = "E"
    E ::= E Minus . E
AHM 3: completion
    E ::= E Minus E .
AHM 4: postdot = "E"
    E ::= . E MinusMinus
AHM 5: postdot = "MinusMinus"
    E ::= E . MinusMinus
AHM 6: completion
    E ::= E MinusMinus .
AHM 7: postdot = "MinusMinus"
    E ::= . MinusMinus E
AHM 8: postdot = "E"
    E ::= MinusMinus . E
AHM 9: completion
    E ::= MinusMinus E .
AHM 10: postdot = "Minus"
    E ::= . Minus E
AHM 11: postdot = "E"
    E ::= Minus . E
AHM 12: completion
    E ::= Minus E .
AHM 13: postdot = "Number"
    E ::= . Number
AHM 14: completion
    E ::= Number .
AHM 15: postdot = "E"
    E['] ::= . E
AHM 16: completion
    E['] ::= E .
END_AHMS

my %expected = map { ( $_ => 1 ) } (
    #<<< no perltidy
    '(((6--)--)-1)==5',
    '((6--)-(--1))==6',
    '((6--)-(-(-1)))==5',
    '(6-(--(--1)))==7',
    '(6-(--(-(-1))))==6',
    '(6-(-(--(-1))))==4',
    '(6-(-(-(--1))))==6',
    '(6-(-(-(-(-1)))))==5',
    #>>>
);

$recce->read( 'Number', '6' );
for ( 1 .. 4 ) {
    $recce->alternative( 'MinusMinus', \q{--}, 2 );
    $recce->alternative( 'Minus', \q{-} );
    $recce->earleme_complete();
}
$recce->read( 'Minus',  q{-}, );
$recce->read( 'Number', '1' );

# Set max_parses to 20 in case there's an infinite loop.
# This is for debugging, after all
$recce->set( { max_parses => 20 } );

while ( my $value_ref = $recce->value() ) {
    my $value = $value_ref ? ${$value_ref} : 'No parse';
    if ( defined $expected{$value} ) {
        delete $expected{$value};
        Test::More::pass("Expected Value $value");
    }
    else {
        Test::More::fail("Unexpected Value $value");
    }
} ## end while ( my $value_ref = $recce->value() )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
