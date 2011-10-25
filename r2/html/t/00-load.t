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
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;
use warnings;
use strict;

use Test::More tests => 2;

use Carp;
use Data::Dumper;

Test::More::use_ok('Marpa::R2::HTML');

Test::More::diag( 'Using Marpa::R2::HTML ', $Marpa::R2::HTML::VERSION );

Test::More::ok( defined $Marpa::R2::TIMESTAMP,
    'Marpa::XS Timestamp defined' );
Test::More::diag( 'Using Marpa::R2 ',
    $Marpa::R2::VERSION, q{ }, $Marpa::R2::TIMESTAMP );

1;    # In case used as "do" file

