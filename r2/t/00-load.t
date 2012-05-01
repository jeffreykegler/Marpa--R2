#!perl
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

use 5.010;
use warnings;
use strict;

use Test::More tests => 2;

use Marpa::R2;

defined $INC{'Marpa/R2.pm'}
    or Test::More::BAIL_OUT('Could not load Marpa::R2');

Test::More::ok( ( defined $Marpa::R2::VERSION ),
    'Marpa::R2 version is ' . $Marpa::R2::VERSION );
Test::More::ok( ( defined $Marpa::R2::STRING_VERSION ),
    'Marpa::R2 string version is ' . $Marpa::R2::STRING_VERSION );

