#!perl
# Copyright 2010 Jeffrey Kegler
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

use Test::More tests => 3;

use Carp;
use Data::Dumper;

Test::More::use_ok('Marpa::HTML');

SKIP: {
   skip "Not Using PP", 1 if $Marpa::USING_XS;
   Test::More::ok( $Marpa::USING_PP, 'Using PP' );
}

SKIP: {
   skip "Not Using XS", 1 if $Marpa::USING_PP;
   Test::More::ok( $Marpa::USING_XS, 'Using XS' );
}

1;    # In case used as "do" file

