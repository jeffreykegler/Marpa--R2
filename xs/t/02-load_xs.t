#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
use warnings;
use strict;

use Test::More tests => 5;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

defined $INC{'Marpa/XS.pm'}
    or Test::More::BAIL_OUT('Could not load Marpa::XS');

Test::More::ok(
    ( defined $Marpa::XS::VERSION ),
    'XS version is ' . $Marpa::XS::VERSION
);
Test::More::ok( ( defined $Marpa::XS::STRING_VERSION ),
    'XS string version is ' . $Marpa::XS::STRING_VERSION );

Test::More::ok( ( defined &Marpa::XS::version ),
    'Marpa::XS::version defined' );

Test::More::ok( ( not defined $Marpa::XS::Internal::{check_version}{CODE} ),
    'Pure Perl mode' );

