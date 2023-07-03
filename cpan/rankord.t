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

# Test order of ranking

use 5.010001;

use strict;
use warnings;

use Test::More tests => 2;
use Data::Dumper;
use English qw( -no_match_vars );
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale( LC_ALL, "C" );

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $input = 'aaaa';

my $source = <<"END_OF_SOURCE";
    :default ::= action => main::dwim

    S ::= A A action => main::flatten
    A ::= A1 rank => 2
    A ::= A2 rank => 1
    A1 ::= B B action => main::dwimB
    A2 ::= B B action => main::dwimB
    B ::= B1 rank => 2
    B ::= B2 rank => 1
    B1  ::= ('a') action => main::dwimB
    B2  ::= ('a') action => main::dwimB

END_OF_SOURCE

my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );

my $recce = Marpa::R2::Scanless::R->new(
    {
        grammar        => $grammar,
        ranking_method => 'rule'
    }
);
$recce->read( \$input );
my @rawGot = ();
VALUE: for ( ; ; ) {
    my $value_ref = $recce->value();
    last VALUE if not defined $value_ref;
    push @rawGot, $$value_ref;
    # local $Data::Dumper::Deepcopy = 1;
    # local $Data::Dumper::Terse    = 1;
    # say STDERR Data::Dumper::Dumper($value_ref);
}

my $output = <<'EOS';
B1 B1 A1 B1 B1 A1
B2 B1 A1 B1 B1 A1
B1 B2 A1 B1 B1 A1
B2 B2 A1 B1 B1 A1
B1 B1 A2 B1 B1 A1
B2 B1 A2 B1 B1 A1
B1 B2 A2 B1 B1 A1
B2 B2 A2 B1 B1 A1
B1 B1 A1 B2 B1 A1
B2 B1 A1 B2 B1 A1
B1 B2 A1 B2 B1 A1
B2 B2 A1 B2 B1 A1
B1 B1 A2 B2 B1 A1
B2 B1 A2 B2 B1 A1
B1 B2 A2 B2 B1 A1
B2 B2 A2 B2 B1 A1
B1 B1 A1 B1 B2 A1
B2 B1 A1 B1 B2 A1
B1 B2 A1 B1 B2 A1
B2 B2 A1 B1 B2 A1
B1 B1 A2 B1 B2 A1
B2 B1 A2 B1 B2 A1
B1 B2 A2 B1 B2 A1
B2 B2 A2 B1 B2 A1
B1 B1 A1 B2 B2 A1
B2 B1 A1 B2 B2 A1
B1 B2 A1 B2 B2 A1
B2 B2 A1 B2 B2 A1
B1 B1 A2 B2 B2 A1
B2 B1 A2 B2 B2 A1
B1 B2 A2 B2 B2 A1
B2 B2 A2 B2 B2 A1
B1 B1 A1 B1 B1 A2
B2 B1 A1 B1 B1 A2
B1 B2 A1 B1 B1 A2
B2 B2 A1 B1 B1 A2
B1 B1 A2 B1 B1 A2
B2 B1 A2 B1 B1 A2
B1 B2 A2 B1 B1 A2
B2 B2 A2 B1 B1 A2
B1 B1 A1 B2 B1 A2
B2 B1 A1 B2 B1 A2
B1 B2 A1 B2 B1 A2
B2 B2 A1 B2 B1 A2
B1 B1 A2 B2 B1 A2
B2 B1 A2 B2 B1 A2
B1 B2 A2 B2 B1 A2
B2 B2 A2 B2 B1 A2
B1 B1 A1 B1 B2 A2
B2 B1 A1 B1 B2 A2
B1 B2 A1 B1 B2 A2
B2 B2 A1 B1 B2 A2
B1 B1 A2 B1 B2 A2
B2 B1 A2 B1 B2 A2
B1 B2 A2 B1 B2 A2
B2 B2 A2 B1 B2 A2
B1 B1 A1 B2 B2 A2
B2 B1 A1 B2 B2 A2
B1 B2 A1 B2 B2 A2
B2 B2 A1 B2 B2 A2
B1 B1 A2 B2 B2 A2
B2 B1 A2 B2 B2 A2
B1 B2 A2 B2 B2 A2
B2 B2 A2 B2 B2 A2
EOS

my @got = ();
my @revGot = ();
for my $gotArr (@rawGot) {
    my $gotLine = join " ", @{$gotArr};
    my $revGotLine = join " ", reverse @{$gotArr};
    push @got, $gotLine;
    push @revGot, $revGotLine;
}
my $got = join "\n", @got, '';
my @sortedGot = sort { $a cmp $b } @revGot;
Test::More::is( $got, $output, 'Ranking order vs expected');
Test::More::is_deeply( \@revGot, \@sortedGot, 'Ranking order vs sort');

sub main::dwim {
    my @result = ();
    shift;
  ARG: for my $v (@_) {
        next ARG if not $v;
        my $type = Scalar::Util::reftype $v;
        if ( not $type or $type ne 'ARRAY' ) {
            push @result, $v;
            next ARG;
        }
        my $size = scalar @{$v};
        next ARG if $size == 0;
        if ( $size == 1 ) {
            push @result, ${$v}[0];
            next ARG;
        }
        push @result, $v;
    }
    return [@result];
}

sub main::dwimB {
    my @result = ();
    shift;
  ARG: for my $v (@_) {
        next ARG if not $v;
        my $type = Scalar::Util::reftype $v;
        if ( not $type or $type ne 'ARRAY' ) {
            push @result, $v;
            next ARG;
        }
        my $size = scalar @{$v};
        next ARG if $size == 0;
        if ( $size == 1 ) {
            push @result, ${$v}[0];
            next ARG;
        }
        push @result, $v;
    }
    my $rule_id = $Marpa::R2::Context::rule;
    my $grammar = $Marpa::R2::Context::grammar;
    my ($lhs)   = $grammar->rule($rule_id);
    return [ @result, $lhs ];
}

sub flatten {
    my ( $parseValue, @values ) = @_;
    my $arrRef = flattenArrayRef( \@values );
    return $arrRef;
}

sub flattenArrayRef {
    my ($array) = @_;
    return [] if not defined $array;
    my $ref = ref $array;
    return [$array] if $ref ne 'ARRAY';
    my @flat = ();
  ELEMENT: for my $element ( @{$array} ) {
        my $ref = ref $element;
        if ( $ref ne 'ARRAY' ) {
            push @flat, $element;
            next ELEMENT;
        }
        my $flat_piece = flattenArrayRef($element);
        push @flat, @{$flat_piece};
    }
    return \@flat;
}

# vim: expandtab shiftwidth=4:
