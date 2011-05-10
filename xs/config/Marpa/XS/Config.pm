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

package Marpa::XS;

# This file is editable.  It is used during the
# configuration process to set up version information.

use strict;
use warnings;

%Marpa::XS::VERSION_FOR_CONFIG = (
    'Scalar::Util'        => 1.21,
    'List::Util'          => 1.21,
    'Carp'                => 1.08,
    'Data::Dumper'        => '2.125',
    'Storable'            => 2.21,
    'PPI'                 => '1.206',
    'Test::Weaken'        => '3.004000',
    'Task::Weaken'        => '0',
    'ExtUtils::PkgConfig' => 1.12,
    'Module::Build'       => 0.3601,
    'ExtUtils::CBuilder'  => 0.27,
    'Test::More'          => 0.94,
    'Glib'                => 1.223,
);

