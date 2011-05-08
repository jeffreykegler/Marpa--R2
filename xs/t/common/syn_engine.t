#!/usr/bin/perl
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

# Engine Synopsis

use 5.010;
use strict;
use warnings;

use Test::More tests => 3;

use Marpa::XS::Test;

## no critic (ErrorHandling::RequireCarping);

# Marpa::XS::Display
# name: Engine Synopsis Unambiguous Parse

use Marpa::XS;

my $grammar = Marpa::XS::Grammar->new(
    {   start          => 'Expression',
        actions        => 'My_Actions',
        default_action => 'first_arg',
        rules          => [
            { lhs => 'Expression', rhs => [qw/Term/] },
            { lhs => 'Term',       rhs => [qw/Factor/] },
            { lhs => 'Factor',     rhs => [qw/Number/] },
            { lhs => 'Term', rhs => [qw/Term Add Term/], action => 'do_add' },
            {   lhs    => 'Factor',
                rhs    => [qw/Factor Multiply Factor/],
                action => 'do_multiply'
            },
        ],
    }
);

$grammar->precompute();

my $recce = Marpa::XS::Recognizer->new( { grammar => $grammar } );

$recce->read( 'Number', 42 );
$recce->read( 'Multiply', );
$recce->read( 'Number', 1 );
$recce->read( 'Add', );
$recce->read( 'Number', 7 );

sub My_Actions::do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub My_Actions::do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}

sub My_Actions::first_arg { shift; return shift; }

my $value_ref = $recce->value;
my $value = $value_ref ? ${$value_ref} : 'No Parse';

# Marpa::XS::Display::End

# Ambiguous, Array Form Rules

# Marpa::XS::Display
# name: Engine Synopsis Ambiguous Parse

use Marpa::XS;

my $ambiguous_grammar = Marpa::XS::Grammar->new(
    {   start   => 'E',
        actions => 'My_Actions',
        rules   => [
            [ 'E', [qw/E Add E/],      'do_add' ],
            [ 'E', [qw/E Multiply E/], 'do_multiply' ],
            [ 'E', [qw/Number/], ],
        ],
        default_action => 'first_arg',
    }
);

$ambiguous_grammar->precompute();

my $ambiguous_recce =
    Marpa::XS::Recognizer->new( { grammar => $ambiguous_grammar } );

$ambiguous_recce->read( 'Number', 42 );
$ambiguous_recce->read( 'Multiply', );
$ambiguous_recce->read( 'Number', 1 );
$ambiguous_recce->read( 'Add', );
$ambiguous_recce->read( 'Number', 7 );

my @values = ();
while ( defined( my $ambiguous_value_ref = $ambiguous_recce->value() ) ) {
    push @values, ${$ambiguous_value_ref};
}

# Marpa::XS::Display::End

Test::More::is( $value, 49, 'Unambiguous Value' );
Test::More::is_deeply( [ sort @values ], [ 336, 49 ], 'Ambiguous Values' );

# An example of "Ruby Slippers" lexing, using
# the unambiguous grammar.

sub fix_things {
    die q{Don't know how to fix things};
}

# Marpa::XS::Display
# name: Engine Synopsis Interactive Parse

$recce =
    Marpa::XS::Recognizer->new( { grammar => $grammar } );

my @tokens = (
    [ 'Number', 42 ],
    ['Multiply'], [ 'Number', 1 ],
    ['Add'],      [ 'Number', 7 ],
);

TOKEN: for ( my $token_ix = 0; $token_ix <= $#tokens; $token_ix++ ) {
    defined $recce->read( @{ $tokens[$token_ix] } )
        or fix_things( $recce, \@tokens )
        or die q{Don't know how to fix things};
}

# Marpa::XS::Display::End

$value_ref = $recce->value;
$value = $value_ref ? ${$value_ref} : 'No Parse';
Test::More::is( $value, 49, 'Interactive Value' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
