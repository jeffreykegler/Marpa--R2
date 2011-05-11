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

use 5.010;
use warnings;
use strict;

use Test::More tests => 2;

use Carp;
use Data::Dumper;
use lib "tool/lib";

BEGIN {
    Test::More::use_ok('Marpa::PP');
}

defined $INC{'Marpa/PP.pm'}
    or Test::More::BAIL_OUT('Could not load Marpa::PP');

Test::More::ok( defined $Marpa::PP::VERSION, 'Marpa::version defined' );

1;    # In case used as "do" file

