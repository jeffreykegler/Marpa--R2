#!perl
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

use 5.010;
use warnings;
use strict;

use Test::More tests => 5;
use lib 'lib';
use lib 'blib/arch';
use lib 'inc';
use lib 'pperl';

BEGIN {
    Test::More::use_ok('Devel::SawAmpersand');
    Test::More::use_ok('Marpa::R2');
    Test::More::use_ok('Marpa::R2::Perl');
    Test::More::use_ok('Marpa::R2::Test');
} ## end BEGIN

Test::More::ok( !Devel::SawAmpersand::sawampersand(), 'PL_sawampersand set' );
