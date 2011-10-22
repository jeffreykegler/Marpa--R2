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

package Marpa::PP;

# This file is editable.  It is used during the
# configuration process to set up version information.

use strict;
use warnings;

%Marpa::PP::VERSION_FOR_CONFIG = (
    'Scalar::Util'        => 1.21,
    'List::Util'          => 1.21,
    'Carp'                => 1.08,
    'Data::Dumper'        => '2.125',
    'Storable'            => 2.21,
    'PPI'                 => '1.206',
    'Test::Weaken'        => '3.004000',
    'Task::Weaken'        => '0',
    'Module::Build'       => 0.3601,
    'Test::More'          => 0.94,
);

