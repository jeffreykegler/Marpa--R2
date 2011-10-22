#!perl
# Copyright 2011 Jeffrey Kegler
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

use Test::More tests => 5;

use Carp;
use Data::Dumper;

BEGIN {
    Test::More::use_ok('Marpa::R2');
}

defined $INC{'Marpa/R2.pm'}
    or Test::More::BAIL_OUT('Could not load Marpa::R2');

Test::More::ok( defined &Marpa::R2::version, 'Marpa::R2::version defined' );

my @version = Marpa::R2::version();
Test::More::is( $version[0], 0, 'Marpa::R2 major version' );
Test::More::is( $version[1], 1, 'Marpa::R2 minor version' );
Test::More::is( $version[2], 0, 'Marpa::R2 micro version' );

Test::More::diag( 'Using Marpa::R2 ',
    $Marpa::R2::VERSION, q{ }, $Marpa::R2::TIMESTAMP );

1;    # In case used as "do" file

