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
use Carp;
use English qw( -no_match_vars );

use Marpa::PP::Version;

# Sensible defaults if not defined
$Marpa::PP::USE_PP //= 0;
$Marpa::PP::USE_XS //= ! $Marpa::PP::USE_PP;

# Die if both PP and XS were chosen
if ( $Marpa::PP::USE_PP and $Marpa::PP::USE_XS ) {
    Carp::croak('Cannot specify both USE_XS and USE_PP');
}
# Die if both PP and XS were unset
if ( ! $Marpa::PP::USE_PP and ! $Marpa::PP::USE_XS ) {
    Carp::croak('Cannot unset both USE_XS and USE_PP');
}

if ( $Marpa::PP::USE_XS ) {

    require Marpa::PP::Internal;
    require Marpa::PP::Internal::Carp_Not;
    Marpa::PP::Internal::Carp_Not->import();

    return 1;
}

$Marpa::PP::USING_XS = 0;
$Marpa::PP::USING_PP = 1;

require Marpa::PP::Internal;
require Marpa::PP::Internal::Carp_Not;
Marpa::PP::Internal::Carp_Not->import();
require Marpa::PP::Grammar;
require Marpa::PP::Recognizer;
require Marpa::PP::Value;
require Marpa::PP::Callback;

1;

__END__
