#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::PP.  Marpa::PP is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::PP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::PP.  If not, see
# http://www.gnu.org/licenses/.

# Test loading of the PP version explicitly

use 5.010;
use warnings;
use strict;

use Test::More tests => 4;

use Carp;
use Data::Dumper;

package Marpa::PP;
our $USE_PP;

package main;

BEGIN {

    # force perl-only version to be tested
    $Marpa::PP::USE_PP = 1;
    Test::More::use_ok('Marpa::PP');
} ## end BEGIN

defined $INC{'Marpa/PP.pm'}
    or Test::More::BAIL_OUT('Could not load Marpa::PP');

Test::More::ok( ( defined $Marpa::PP::VERSION ),
    'PP version not defined' );
Test::More::ok( ( defined $Marpa::PP::STRING_VERSION ),
    'PP string version not defined' );

Test::More::ok( ( not defined $Marpa::PP::Internal::{check_version}{CODE} ),
    'Pure Perl mode' );

