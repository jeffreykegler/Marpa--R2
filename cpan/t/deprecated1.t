#!perl
# Copyright 2014 Jeffrey Kegler
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

# !!! WARNING !!!
# The code in this test uses deprecated methods, techniques, etc.
# Please DO NOT USE IT AS AN EXAMPLE
# Thanks

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;

use lib 'inc';
use Marpa::R2::Test;
use English qw( -no_match_vars );
use Fatal qw( close open );
use Marpa::R2;

# Test the deprecated, zero-argument form
# of the thin grammar constructor.
my $grammar = Marpa::R2::Thin::G->new();

# Carry on with it a little ways,
# just to show that the recognizer starts out
# sane

my $symbol_S = $grammar->symbol_new();
my $symbol_a = $grammar->symbol_new();
$grammar->start_symbol_set($symbol_S);

$grammar->rule_new( $symbol_S, [ $symbol_a, $symbol_a ] );

$grammar->precompute();

my $recce = Marpa::R2::Thin::R->new($grammar);
$recce->start_input();
$recce->alternative( $symbol_a, 1, 1 );
$recce->earleme_complete();
my @terminals = $recce->terminals_expected();

Test::More::is( ( scalar @terminals ), 1, 'count of terminals expected' );
Test::More::is( $terminals[0], $symbol_a, 'expected terminal' );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
