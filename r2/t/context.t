#!/usr/bin/perl
# Copyright 2012 Jeffrey Kegler
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

# Debug Sequence Example

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $trace_rules = q{};

sub do_S {
    my ($action_object) = @_;
    my $rule_id         = $Marpa::R2::Context::rule;
    my $grammar         = $Marpa::R2::Context::grammar;

# Marpa::R2::Display
# name: rule() Synopsis

    my ( $lhs, @rhs ) = $grammar->rule($rule_id);

# Marpa::R2::Display::End

    $action_object->{text}
        .= "rule $rule_id: $lhs ::= " . ( join q{ }, @rhs ) . "\n";
    return $action_object;
} ## end sub do_S

my @terminals = qw/A B C D/;
my $grammar   = Marpa::R2::Grammar->new(
    {   start => 'S',
        rules =>
            [ { lhs => 'S', rhs => \@terminals, action => 'main::do_S' }, ],
        symbols => { map { ( $_ => { terminal => 1 } ) } @terminals }
    }
);

$grammar->precompute();

# Marpa::R2::Display
# name: rule_ids() Synopsis

my @rule_ids = $grammar->rule_ids();

# Marpa::R2::Display::End

Test::More::is( (join q{ }, @rule_ids), '0', '$g->rule_ids() ok?' );

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

for my $terminal (@terminals) {
    $recce->read( $terminal, $terminal );
}

my $value_ref = $recce->value;
VALUE_TEST: {
    if ( ref $value_ref ne 'REF' ) {
        my $ref_type = ref $value_ref;
        Test::More::fail(
            qq{Parse result ref type is "$ref_type"; it needs to be "REF"});
        last VALUE_TEST;
    } ## end if ( ref $value_ref ne 'REF' )
    my $value = ${$value_ref};
    if ( ref $value ne 'HASH' ) {
        my $ref_type = ref $value;
        Test::More::fail(
            qq{Parse value ref type is "$ref_type"; it needs to be "HASH"});
        last VALUE_TEST;
    } ## end if ( ref $value ne 'HASH' )
    my $expected_text = qq{rule 0: S ::= A B C D\n};
    Test::More::is( $value->{text}, $expected_text, 'Parse ok?' );
} ## end VALUE_TEST:

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
