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

package Marpa::XS::Internal::Callback;

use 5.010;
use warnings;
use strict;
use integer;

use English qw( -no_match_vars );

sub Marpa::XS::location {
    Marpa::XS::exception('No context for location callback')
        if not my $context = $Marpa::XS::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        return $and_node->[Marpa::XS::Internal::And_Node::START_EARLEME];
    }
    Marpa::XS::exception('LOCATION called outside and-node context');
} ## end sub Marpa::XS::location

sub Marpa::XS::cause_location {
    Marpa::XS::exception('No context for cause_location callback')
        if not my $context = $Marpa::XS::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        return $and_node->[Marpa::XS::Internal::And_Node::CAUSE_EARLEME];
    }
    Marpa::XS::exception('cause_location() called outside and-node context');
} ## end sub Marpa::XS::cause_location

no strict 'refs';
*{'Marpa::XS::token_location'} = \&Marpa::XS::cause_location;
use strict;

sub Marpa::XS::length {
    Marpa::XS::exception('No context for LENGTH tie')
        if not my $context = $Marpa::XS::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        return $and_node->[Marpa::XS::Internal::And_Node::END_EARLEME]
            - $and_node->[Marpa::XS::Internal::And_Node::START_EARLEME];
    }
    Marpa::XS::exception('LENGTH called outside and-node context');
} ## end sub Marpa::XS::length

1;
