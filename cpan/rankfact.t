#!perl
# Copyright 2022 Jeffrey Kegler
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

# Test ranking in the presence of both a factoring and
# a symbolic choice.

use 5.010001;

use strict;
use warnings;

use Test::More tests => 8;
use Data::Dumper;
use English qw( -no_match_vars );
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale( LC_ALL, "C" );

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my @tests_data = ();
my @results    = ();

my @tests = (
    [ 'aaa', 1, 2, '' ],
    [ 'aaa', 2, 1, '' ],
);

for my $test (@tests) {
    my ( $input, $rank1, $rank2, $output ) = @{$test};

my $source = <<"END_OF_SOURCE";
    :default ::= action => main::dwim

    S ::= L R
    L ::= A
    L ::= A A
    R ::= R1
    R ::= R2
    R1 ::= A rank => $rank1
    R1 ::= A A rank => $rank1
    R2 ::= A rank => $rank2
    R2 ::= A A rank => $rank2
    A  ::= 'a'

END_OF_SOURCE

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );

    my $recce = Marpa::R2::Scanless::R->new(
        {
            grammar        => $grammar,
            ranking_method => 'rule'
        }
    );
    $recce->read( \$input );
    my $parse_no = 0;
    VALUE: for (;;) {
        my $value_ref = $recce->value();
        last VALUE if not defined $value_ref;
        local $Data::Dumper::Deepcopy = 1;
        local $Data::Dumper::Terse    = 1;
        say STDERR sprintf( 'Ranking synopsis test #%d %d: "%s"', $parse_no, $rank1, $input );
        say STDERR Data::Dumper::Dumper($value_ref);
        # Test::More::is( $value_ref, $output,
            # sprintf( 'Ranking synopsis test #%d: "%s"', $parse_no, $input ) );
        $parse_no++;
    }
}

sub main::dwim {
    my @result = ();
    shift;
    ARG: for my $v ( @_ ) {
        next ARG if not $v;
        my $type = Scalar::Util::reftype $v;
        if (not $type or $type ne 'ARRAY') {
           push @result, $v;
           next ARG;
        }
        my $size = scalar @{$v};
        next ARG if $size == 0;
        if ($size == 1) {
           push @result, ${$v}[0];
           next ARG;
        }
        push @result, $v;
    }
    return [@result];
}

# vim: expandtab shiftwidth=4:
