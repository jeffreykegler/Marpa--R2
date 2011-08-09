#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;

use strict;
use warnings;

use Test::More tests => 11;

use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

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
    given ( scalar @_ ) {
        when ( $_ <= 0 ) { return q{} }
        when (1)         { return $_[0] }
    };
    return '(' . join( q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::Grammar->new(
    {   start => 'E',
        strip => 0,

        actions => 'main',
        rules   => [
            {   lhs      => 'E',
                rhs      => [qw/E Minus E/],
                action   => 'subtraction',
            },
            {   lhs      => 'E',
                rhs      => [qw/E MinusMinus/],
                action   => 'postfix_decr',
            },
            {   lhs      => 'E',
                rhs      => [qw/MinusMinus E/],
                action   => 'prefix_decr',
            },
            {   lhs      => 'E',
                rhs      => [qw/Minus E/],
                action   => 'negation'
            },
            {   lhs    => 'E',
                rhs    => [qw/Number/],
                action => 'number'
            },
        ],
        terminals      => [qw( Number Minus MinusMinus )],
        default_action => 'default_action',
    }
);
$grammar->precompute();

my $recce = Marpa::Recognizer->new( { grammar => $grammar } );

Marpa::Test::is( $grammar->show_rules,
    <<'END_RULES', 'Minuses Equation Rules' );
0: E -> E Minus E
1: E -> E MinusMinus
2: E -> MinusMinus E
3: E -> Minus E
4: E -> Number
5: E['] -> E /* vlhs real=1 */
END_RULES

Marpa::Test::is( $grammar->show_AHFA,
    <<'END_AHFA', 'Minuses Equation AHFA' );
* S0:
E['] -> . E
 <E> => S2; leo(E['])
* S1: predict
E -> . E Minus E
E -> . E MinusMinus
E -> . MinusMinus E
E -> . Minus E
E -> . Number
 <E> => S6
 <Minus> => S1; S4
 <MinusMinus> => S1; S5
 <Number> => S3
* S2: leo-c
E['] -> E .
* S3:
E -> Number .
* S4:
E -> Minus . E
 <E> => S7; leo(E)
* S5:
E -> MinusMinus . E
 <E> => S8; leo(E)
* S6:
E -> E . Minus E
E -> E . MinusMinus
 <Minus> => S1; S9
 <MinusMinus> => S10
* S7: leo-c
E -> Minus E .
* S8: leo-c
E -> MinusMinus E .
* S9:
E -> E Minus . E
 <E> => S11; leo(E)
* S10:
E -> E MinusMinus .
* S11: leo-c
E -> E Minus E .
END_AHFA

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

my @input = ();
push @input, [ 'Number', '6' ];
push @input, ( [ 'MinusMinus', q{--}, 2, 0 ], [ 'Minus', q{-} ] ) x 4;
push @input, [ 'Minus',  q{-}, ];
push @input, [ 'Number', '1' ];

$recce->tokens( \@input );

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
