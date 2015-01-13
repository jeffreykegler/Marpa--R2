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
# A CHAF rule which starts with nullables, and cycle.

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

our $dash = q{-};

sub rule_n {
    shift;
    return 'n(' . ( join q{;}, map { $_ // q{-} } @_ ) . ')';
}

sub start_rule {
    shift;
    return 'S(' . ( join q{;}, ( map { $_ // q{-} } @_ ) ) . ')';
}

sub rule_f {
    shift;
    return 'f(' . ( join q{;}, ( map { $_ // q{-} } @_ ) ) . ')';
}

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start           => 'S',
        infinite_action => 'quiet',
        rules           => [
            {   lhs    => 'S',
                rhs    => [qw/n n n f/],
                action => 'main::start_rule'
            },
            { lhs => 'n', rhs => ['a'], action => 'main::rule_n' },
            { lhs => 'n', rhs => [], action => 'main::dash' },
            { lhs => 'f', rhs => ['a'], action => 'main::rule_f' },
            { lhs => 'f', rhs => [], action => 'main::dash' },
            { lhs => 'f', rhs => ['S'], action => 'main::rule_f' },
        ],
        terminals => [qw(a)],
    }
);

$grammar->precompute();

my @expected = qw{
    S(-;-;-;f(A))
    S(-;-;-;f(S(n(A);-;-;-)))
    S(-;-;n(A);-)
    S(-;n(A);-;-)
    S(n(A);-;-;-)
};

my $input_length = 1;
my $recce =
    Marpa::R2::Recognizer->new( { grammar => $grammar, max_parses => 99 } );
for my $token_ix ( 1 .. $input_length ) {
    $recce->read( 'a', 'A' );
}
my $expected = $expected[$input_length];
my @values   = ();
while ( my $value_ref = $recce->value() ) {
    push @values, ${$value_ref};
}
Marpa::R2::Test::is(
    ( join "\n", sort @values ),
    ( join "\n", @expected ),
    "value for input length $input_length"
);

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
