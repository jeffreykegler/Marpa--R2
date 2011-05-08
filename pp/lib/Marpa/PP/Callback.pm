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

package Marpa::PP::Internal::Callback;

use 5.010;
use warnings;
use strict;
use integer;

use English qw( -no_match_vars );

sub Marpa::PP::location {
    Marpa::exception('No context for location callback')
        if not my $context = $Marpa::PP::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        return $and_node->[Marpa::PP::Internal::And_Node::START_EARLEME];
    }
    Marpa::exception('LOCATION called outside and-node context');
} ## end sub Marpa::PP::location

sub Marpa::PP::cause_location {
    Marpa::exception('No context for cause_location callback')
        if not my $context = $Marpa::PP::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        return $and_node->[Marpa::PP::Internal::And_Node::CAUSE_EARLEME];
    }
    Marpa::exception('cause_location() called outside and-node context');
} ## end sub Marpa::PP::cause_location

no strict 'refs';
*{'Marpa::PP::token_location'} = \&Marpa::PP::cause_location;
use strict;

sub Marpa::PP::length {
    Marpa::exception('No context for LENGTH tie')
        if not my $context = $Marpa::PP::Internal::CONTEXT;
    my ( $context_type, $and_node ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        return $and_node->[Marpa::PP::Internal::And_Node::END_EARLEME]
            - $and_node->[Marpa::PP::Internal::And_Node::START_EARLEME];
    }
    Marpa::exception('LENGTH called outside and-node context');
} ## end sub Marpa::PP::length

1;
