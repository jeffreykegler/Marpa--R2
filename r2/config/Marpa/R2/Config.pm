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

# This file is editable.  It is used during the
# configuration process to set up version information.

package Marpa::R2;

use 5.010;

use strict;
use warnings;

%Marpa::R2::VERSION_FOR_CONFIG = (
    'Carp'                => 1.08,
    'Data::Dumper'        => '2.125',
    'ExtUtils::CBuilder'  => 0.27,
    'ExtUtils::PkgConfig' => 1.12,
    'Glib'                => 1.223,
    'HTML::Parser'        => '3.64',
    'HTML::PullParser'    => '3.57',
    'HTML::Entities'    => '3.68',
    'List::Util'          => 1.21,
    'Module::Build'       => 0.3601,
    'PPI'                 => '1.206',
    'Scalar::Util'        => 1.21,
    'Storable'            => 2.21,
    'Task::Weaken'        => '0',
    'Test::More'          => 0.94,
    'Test::Weaken'        => '3.004000',
);

1;
