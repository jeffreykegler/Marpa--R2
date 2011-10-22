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

package Marpa::XS::Test;

use 5.010;
use strict;
use warnings;

use Data::Dumper;

Marpa::exception('Test::More not loaded')
    if not defined &Test::More::is;

BEGIN {
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval 'use Test::Differences';
}

sub Marpa::Test::is {
    goto &Test::Differences::eq_or_diff
        if defined &Test::Differences::eq_or_diff && @_ > 1;
    @_ = map { ref $_ ? Data::Dumper::Dumper(@_) : $_ } @_;
    goto &Test::More::is;
} ## end sub Marpa::Test::is

1;

