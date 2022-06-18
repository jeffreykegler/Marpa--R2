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

# Regressions tests involving the Stuizand interface

use 5.010001;
use strict;
use warnings;
use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

# Regression test of bug found by Andrew Rodland

my $g = Marpa::R2::Grammar->new(
    {   actions => "main",
        start   => "start",
        source   => \"start ::= action => act"
    }
);
$g->precompute;
my $r         = Marpa::R2::Recognizer->new( { grammar => $g } );
my $value_ref = $r->value;
my $value     = defined $value_ref ? ${$value_ref} : 'No parse';
sub act {123};

Test::More::is( $value, '123', 'Rodland regression test' );

# vim: expandtab shiftwidth=4:
