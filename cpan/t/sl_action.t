#!/usr/bin/perl
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

# SLIF semantics examples

use 5.010001;
use strict;
use warnings;

use Test::More tests => 6;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $trace_rules = q{};

# Marpa::R2::Display
# name: SLIF action context synopsis

sub do_S {
    my ($action_object) = @_;
    my $rule_id         = $Marpa::R2::Context::rule;
    my $slg             = $Marpa::R2::Context::slg;
    my ( $lhs, @rhs ) =
        map { $slg->symbol_display_form($_) } $slg->rule_expand($rule_id);
    $action_object->{text} =
          "rule $rule_id: $lhs ::= "
        . ( join q{ }, @rhs ) . "\n"
        . "locations: "
        . ( join q{-}, Marpa::R2::Context::location() ) . "\n";
    return $action_object;
} ## end sub do_S

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF bail synopsis

my $bail_message = "This is a bail out message!";

sub do_bail_with_message_if_A {
    my ($action_object, $terminal) = @_;
    Marpa::R2::Context::bail($bail_message) if $terminal eq 'A';
}

sub do_bail_with_object_if_A {
    my ($action_object, $terminal) = @_;
    Marpa::R2::Context::bail([$bail_message]) if $terminal eq 'A';
}

# Marpa::R2::Display::End

my @terminals = qw/A B C D/;
my $grammar   = Marpa::R2::Scanless::G->new(
    {   source => \<<'END_OF_SOURCE',
:start ::= S
S ::= A B C D action => main::do_S
A ~ 'A'
B ~ 'B'
C ~ 'C'
D ~ 'D'
END_OF_SOURCE
});

sub do_parse {
    my $slr = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    $slr->read( \'ABCD' );
    return $slr->value();
} ## end sub do_parse

my $value_ref;
$value_ref = do_parse();
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
    my $expected_text = qq{rule 0: S ::= A B C D\nlocations: 0-4\n};
    Test::More::is( $value->{text}, $expected_text, 'Parse ok?' );
} ## end VALUE_TEST:

my $eval_ok;
{
    local *do_S = *do_bail_with_message_if_A;
    $eval_ok = eval { $value_ref = do_parse(); 1 };
}
my $actual_eval_error = $EVAL_ERROR
    // 'no eval error';    # grab it now to be safe
Test::More::ok( ( not defined $eval_ok ),
    "bail with string argument happened" );
$actual_eval_error
    =~ s/\A User \s+ bailed \s+ at \s+ line \s+ \d+ [^\n]* \n/<LOCATION LINE>/xms;
Test::More::is(
    $actual_eval_error,
    '<LOCATION LINE>' . $bail_message . "\n",
    "bail with string argument"
);

{
    local *do_S = *do_bail_with_object_if_A;
    $eval_ok = eval { $value_ref = do_parse(); 1 };
}
$actual_eval_error = $EVAL_ERROR;
my $eval_error_ref_type = ref $actual_eval_error;
my $exception_value_desc =
      $eval_error_ref_type eq 'ARRAY'
    ? $actual_eval_error->[0]
    : "ref type of exception is $eval_error_ref_type";
Test::More::ok( ( not defined $eval_ok ),
    "bail with object argument happened" );
Test::More::is( $eval_error_ref_type, 'ARRAY',
    "bail with object argument ref type" );
Test::More::is( $exception_value_desc, $bail_message,
    "bail with object argument value" );

# vim: expandtab shiftwidth=4:
