#!/usr/bin/perl
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

# Test of the actions, focusing on the various types --
# CODE, ref to scalar/hash/array, etc.

use 5.010001;
use strict;
use warnings;

use Test::More tests => 2;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $side_effect = 0;

no warnings 'once';
$My_Actions::hash_ref = {'a hash ref' => 1};
$My_Actions::array_ref = ['an array ref'];
$My_Actions::array_ref2 = ['array ref 2'];
$My_Actions::scalar_ref = \8675309;
$My_Actions::scalar = 42;
$My_Actions::scalar2 = 'scalar2';
$My_Actions::code_ref = sub { return 'code ref' };
$My_Actions::code_ref2 = sub { return 'code ref 2' };
$My_Actions::code_ref_ref = \(sub { return 'code ref ref' });
sub My_Actions::scalar2 { return ( 'should not see me', 'shadow of scalar 2' ) };
sub My_Actions::array_ref2 { return 'shadow of array_ref2' };
sub My_Actions::code_ref2 { return 'shadow of code_ref2' };
use warnings;
sub My_Actions::code { return 'code' };
sub My_Actions::new { $side_effect = 42; }

my $grammar   = Marpa::R2::Scanless::G->new(
    {
    source => \<<'END_OF_SOURCE',
:default ::= action => ::array
:start ::= S
S ::= <array ref>  <hash ref>  <ref ref>  <code ref>
    <code ref ref> <code> <scalar> 
    <scalar2> <array ref 2> <code ref 2>
<array ref> ::= 'a' action => array_ref
<hash ref> ::= 'a' action => hash_ref
<ref ref>  ::= 'a' action => scalar_ref
<code ref>  ::= 'a' action => code_ref
<code ref ref>  ::= 'a' action => code_ref_ref
<code>  ::= 'a' action => code
<scalar>  ::= 'a' action => scalar
<scalar2>  ::= 'a' action => scalar2
<array ref 2>  ::= 'a' action => array_ref2
<code ref 2>  ::= 'a' action => code_ref2
END_OF_SOURCE
});

sub do_parse {
    my $slr = Marpa::R2::Scanless::R->new(
        { grammar => $grammar, semantics_package => 'My_Actions', } );
    $slr->read( \'aaaaaaaaaa' );
    return $slr->value();
} ## end sub do_parse

my $value_ref;
$value_ref = do_parse();
my $expected = \[
    [ 'an array ref' ],
    { 'a hash ref' => 1 },
    \8675309,
    $My_Actions::code_ref,
    $My_Actions::code_ref_ref,
    'code',
    42,
    'shadow of scalar 2',
    'shadow of array_ref2',
    'shadow of code_ref2'
];
Test::More::is_deeply($value_ref, $expected, 'Constant actions');
Test::More::is($side_effect, 42, 'semantics_package constructor');

# vim: expandtab shiftwidth=4:
