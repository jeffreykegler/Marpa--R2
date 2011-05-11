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

package Marpa::PP;

use 5.010;
use strict;
use warnings;
use vars qw($VERSION $STRING_VERSION);
$VERSION = '0.005_005';
$STRING_VERSION = $VERSION;
$VERSION = eval $VERSION;

use Carp;
use English qw( -no_match_vars );

use Marpa::PP::Version;

# Die if both PP and XS were chosen
if ( defined $Marpa::VERSION ) {
    Carp::croak('Cannot load both Marpa::PP and Marpa');
}
if ( defined $Marpa::XS::VERSION ) {
    Carp::croak('Cannot load both Marpa::PP and Marpa::XS');
}

require Marpa::PP::Internal;
require Marpa::PP::Internal::Carp_Not;
Marpa::PP::Internal::Carp_Not->import();
require Marpa::PP::Grammar;
require Marpa::PP::Recognizer;
require Marpa::PP::Value;
require Marpa::PP::Callback;

1;

__END__
