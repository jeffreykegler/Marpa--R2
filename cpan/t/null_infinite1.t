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
# Two rules which start with nullables, and cycle.

use 5.010;
use strict;
use warnings;

use Test::More tests => 3;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{-} if $v_count <= 0;
    my @vals = map { $_ // q{-} } @_;
    return '(' . join( q{;}, @vals ) . ')';
} ## end sub default_action

sub rule_na {
    shift;
    return 'na(' . ( join q{;}, map { $_ // q{-} } @_ ) . ')';
}

sub rule_Snf {
    shift;
    return 'Snf(' . ( join q{;}, ( map { $_ // q{-} } @_ ) ) . ')';
}

sub rule_fa {
    shift;
    return 'fa(' . ( join q{;}, ( map { $_ // q{-} } @_ ) ) . ')';
}

sub rule_fS {
    shift;
    return 'fS(' . ( join q{;}, ( map { $_ // q{-} } @_ ) ) . ')';
}

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start           => 'S',
        infinite_action => 'quiet',
        rules           => [
            { lhs => 'S', rhs => [qw/n f/], action => 'main::rule_Snf' },
            { lhs => 'n', rhs => ['a'],     action => 'main::rule_na' },
            { lhs => 'n', rhs => [] },
            { lhs => 'f', rhs => ['a'],     action => 'main::rule_fa' },
            { lhs => 'f', rhs => [] },
            { lhs => 'f', rhs => ['S'],     action => 'main::rule_fS' },
        ],
        terminals => [qw(a)],
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

my @expected2 = qw{
    Snf(-;fS(Snf(na(A);fS(Snf(-;fa(A))))))
    Snf(-;fS(Snf(na(A);fS(Snf(na(A);-)))))
    Snf(-;fS(Snf(na(A);fa(A))))
    Snf(na(A);fS(Snf(-;fa(A))))
    Snf(na(A);fS(Snf(na(A);-)))
    Snf(na(A);fa(A))
};

my @expected3 = qw{
    Snf(-;fS(Snf(na(A);fS(Snf(na(A);fS(Snf(-;fa(A))))))))
    Snf(-;fS(Snf(na(A);fS(Snf(na(A);fS(Snf(na(A);-)))))))
    Snf(-;fS(Snf(na(A);fS(Snf(na(A);fa(A))))))
    Snf(na(A);fS(Snf(na(A);fS(Snf(-;fa(A))))))
    Snf(na(A);fS(Snf(na(A);fS(Snf(na(A);-)))))
    Snf(na(A);fS(Snf(na(A);fa(A))))
};

my @expected = (
    [q{}],
    [   qw{
            Snf(-;fa(A))
            Snf(-;fS(Snf(na(A);-)))
            Snf(na(A);-)
            }
    ],
    \@expected2,
    \@expected3,
);

for my $input_length ( 1 .. 3 ) {
    my $recce = Marpa::R2::Recognizer->new(
        { grammar => $grammar, max_parses => 99 } );
    for my $token_ix ( 1 .. $input_length ) {
        $recce->read( 'a', 'A' );
    }
    my $expected = $expected[$input_length];
    my @values   = ();
    while ( my $value_ref = $recce->value() ) {
        push @values, ${$value_ref};
    }
    my $values          = join "\n", sort @values;
    my $expected_values = join "\n", sort @{$expected};

    # die if $values ne $expected_values;
    Marpa::R2::Test::is( $values, $expected_values,
        "value for input length $input_length" );
} ## end for my $input_length ( 1 .. 3 )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
