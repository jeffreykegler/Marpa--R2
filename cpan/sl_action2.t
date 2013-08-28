#!/usr/bin/perl
# Copyright 2013 Jeffrey Kegler
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

use 5.010;
use strict;
use warnings;

use Test::More tests => 6;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

no warnings 'once';
$My_Actions::hash_ref = {'a hash ref' => 1};
$My_Actions::array_ref = ['an array ref'];
$My_Actions::scalar_ref = \8675309;
$My_Actions::code_ref = sub { return 'code ref' };
use warnings;

my $grammar   = Marpa::R2::Scanless::G->new(
    {
    source => \<<'END_OF_SOURCE',
:default ::= action => ::array
:start ::= S
S ::= <array ref>  <hash ref>  <ref ref>  <code ref> 
<array ref> ::= 'a' action => array_ref
<hash ref> ::= 'a' action => hash_ref
<ref ref>  ::= 'a' action => scalar_ref
<code ref>  ::= 'a' action => code_ref
END_OF_SOURCE
});

sub do_parse {
    my $slr = Marpa::R2::Scanless::R->new(
        { grammar => $grammar, semantics_package => 'My_Actions', } );
    $slr->read( \'aaaa' );
    return $slr->value();
} ## end sub do_parse

my $value_ref;
$value_ref = do_parse();
say Data::Dumper::Dumper($value_ref);

# vim: expandtab shiftwidth=4:
