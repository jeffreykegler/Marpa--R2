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
    Marpa::exception('No context for location callback')
        if not my $context = $Marpa::XS::Internal::CONTEXT;
    my ( $context_type, $and_node_id, $recce ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
        my $parent_or_node_id = $recce_c->and_node_parent($and_node_id);
        my $parent_origin = $recce_c->or_node_origin($parent_or_node_id);
        return $parent_origin;
    } ## end if ( $context_type eq 'and-node' )
    Marpa::exception('LOCATION called outside and-node context');
} ## end sub Marpa::XS::location

sub Marpa::XS::cause_location {
    Marpa::exception('No context for cause_location callback')
        if not my $context = $Marpa::XS::Internal::CONTEXT;
    my ( $context_type, $and_node_id, $recce ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
        my $parent_or_node_id = $recce_c->and_node_parent($and_node_id);
        my $predecessor_or_node_id =
            $recce_c->and_node_predecessor($and_node_id);
        if ( defined $predecessor_or_node_id ) {
            my $predecessor_set =
                $recce_c->or_node_set($predecessor_or_node_id);
            return $predecessor_set;
        }
        else {
            my $parent_origin = $recce_c->or_node_origin($parent_or_node_id);
            return $parent_origin;
        }
    } ## end if ( $context_type eq 'and-node' )
    Marpa::exception('cause_location() called outside and-node context');
} ## end sub Marpa::XS::cause_location

no strict 'refs';
*{'Marpa::XS::token_location'} = \&Marpa::XS::cause_location;
use strict;

sub Marpa::XS::length {
    Marpa::exception('No context for LENGTH tie')
        if not my $context = $Marpa::XS::Internal::CONTEXT;
    my ( $context_type, $and_node_id, $recce ) = @{$context};
    if ( $context_type eq 'and-node' ) {
        my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
        my $parent_or_node_id = $recce_c->and_node_parent($and_node_id);
        my $predecessor_or_node_id =
            $recce_c->and_node_predecessor($and_node_id);
	my $parent_origin = $recce_c->or_node_origin($parent_or_node_id);
	my $parent_set = $recce_c->or_node_set($parent_or_node_id);
        return $parent_set - $parent_origin;
    } ## end if ( $context_type eq 'and-node' )
    Marpa::exception('LENGTH called outside and-node context');
} ## end sub Marpa::XS::length

1;
