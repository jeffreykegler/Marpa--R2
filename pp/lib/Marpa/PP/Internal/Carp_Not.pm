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

package Marpa::PP::Internal::Carp_Not;

use 5.010;
use strict;
use warnings;
use integer;

our @CARP_NOT = (__PACKAGE__);

sub import {
    my $calling_package = ( caller 0 );
    push @CARP_NOT, $calling_package;
    no strict 'refs';
    *{ $calling_package . q{::CARP_NOT} } =
        \@Marpa::PP::Internal::Carp_Not::CARP_NOT;
    return 1;
} ## end sub import

1;
