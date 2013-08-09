# Copyright 2013 Jeffrey Kegler
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

package Marpa::R2::ASF;

use 5.010;
use strict;
use warnings;
no warnings qw(recursion);

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.067_001';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

# The code in this file, for now, breaks "the rules".  It makes use
# of internal methods not documented as part of Libmarpa.
# It is intended to create documented Libmarpa methods to underlie
# this interface, and rewrite it to use them

package Marpa::R2::Internal::ASF;

# Terms
#
# Choicepoint -- a rule instance, which may be factored.  It is
# a set of factorings.
#
# Full choicepoint expansion -- expansion of a choicepoint into sequences
# of choicepoints, each an alternative for that choicepoint.
#
# Factoring -- one possible factoring of a choicepoint.  It is a sequence
# of factors.
#
# Factor -- In a BNF rule, factor each factor corresponds to one of
# the RHS symbols.  In a sequence rule, each factor corresponds to one item.
# A factor is a set of symches.
#
# Symch (Symbolic choice) -- A set of one or more cartesians --
#
# Cartesian -- A pair of sets of choicepoints,
# so called because every
# pairing of choicepoints in the Cartesian product of the two
# sets is allowed.  The first set contains the predecessor
# choicepoints, and the second set contains the component choicepoints.
# Predecessor choicepoints may be 'nil', but are never token instances.
# Component choicepoint may be token instances, but are never 'nil'.
# (The term "component" comes from Irons 1961 paper.)

# This is more complicated that it needs to be for the current implementation.
# It allows for LHS terminals (implemented in Libmarpa but not allowed by the SLIF).
# It also assumes that every or-node which can be constructed from preceding or-nodes
# and the input will be present.  This is currently the case, but in the future
# rules and/or symbols may have extra-syntactic conditions attached making this
# assumption false.

# Given the or-node IDs and token IDs, return the choicepoint,
# creating one if necessary.  Default is internal.
sub ensure_cp {
    my ( $asf, $or_node_ids, $token_ids ) = @_;
    my $choicepoints_by_token_id =
        $asf->[Marpa::R2::Internal::Scanless::ASF::CHOICEPOINTS_BY_TOKEN_ID];
    my $choicepoints_by_or_node_id = $asf
        ->[Marpa::R2::Internal::Scanless::ASF::CHOICEPOINTS_BY_OR_NODE_ID];
    my $token_id_count = scalar @{$token_ids};
    FIND_CP: {
        my $cp_candidates =
              $token_id_count
            ? $choicepoints_by_token_id->[ $token_ids->[0] ]
            : $choicepoints_by_or_node_id->[ $or_node_ids->[0] ];
        last FIND_CP if not defined $cp_candidates;
        for my $cp_candidate ( @{$cp_candidates} ) {
            my $candidate_token_ids = $cp_candidate
                ->[Marpa::R2::Internal::Scanless::Choicepoint::TOKEN_IDS];
            next CP_CANDIDATE
                if scalar @{$token_ids} != scalar @{$candidate_token_ids};
            for my $token_id ( @{$token_ids} ) {
                next CP_CANDIDATE
                    if not grep { $token_id == $_ } @{$candidate_token_ids};
            }
            my $candidate_or_node_ids = $cp_candidate
                ->[Marpa::R2::Internal::Scanless::Choicepoint::OR_NODE_IDS];
            next CP_CANDIDATE
                if scalar @{$or_node_ids} != scalar @{$candidate_or_node_ids};
            for my $or_node_id ( @{$or_node_ids} ) {
                next CP_CANDIDATE
                    if not grep { $or_node_id == $_ }
                        @{$candidate_or_node_ids};
            }
            return $cp_candidate;
        } ## end for my $cp_candidate ( @{$cp_candidates} )
    } ## end FIND_CP:
    return new_cp( $asf, $or_node_ids, $token_ids );
} ## end sub ensure_cp

# Sort with decreasing length as the major key
sub cmp_cp_length_major {
    my ($a, $b) = @_;
}

sub new_cp {
    my ( $asf, $or_node_ids, $token_ids ) = @_;
    my $cp;
    $cp->[Marpa::R2::Internal::Scanless::Choicepoint::OR_NODE_IDS] =
        $or_node_ids // [];
    $cp->[Marpa::R2::Internal::Scanless::Choicepoint::TOKEN_IDS] = $token_ids
        // [];

    ## In C use an insertion sort by decreasing length, and changes searches to
    # that they give up once past the last possible choicepoint
    for my $token_id ( @{$token_ids} ) {
        push @{
            $asf->[
                Marpa::R2::Internal::Scanless::ASF::CHOICEPOINTS_BY_TOKEN_ID]
            },
            $token_id;
    } ## end for my $token_id ( @{$token_ids} )
    for my $or_node_id ( @{$or_node_ids} ) {
        push @{
            $asf->[
                Marpa::R2::Internal::Scanless::ASF::CHOICEPOINTS_BY_OR_NODE_ID
            ]
            },
            $or_node_id;
    } ## end for my $or_node_id ( @{$or_node_ids} )
    return $cp;
} ## end sub new_cp

# No check for conflicting usage -- value(), asf(), etc.
# at this point
sub Marpa::R2::Scanless::ASF::top {
    my ($asf) = @_;
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( not $bocage ) {
        my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
        my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
        my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
        $grammar_c->throw_set(0);
        $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C] =
            Marpa::R2::Thin::B->new( $recce_c, -1 );
        $grammar_c->throw_set(1);
        die "No parse" if not defined $bocage;
    } ## end if ( not $bocage )
    my $augment_or_node_id = $bocage->_marpa_b_top_or_node();
    my $augment_and_node_id =
        $bocage->_marpa_b_or_node_first_and($augment_or_node_id);
    my $augment2_or_node_id =
        $bocage->_marpa_b_and_node_cause($augment_and_node_id);
    my @token_ids;
    my @or_node_ids;
    AND_NODE: for my $augment2_and_node_id (
        $bocage->_marpa_b_or_node_first_and($augment2_or_node_id)
        .. $bocage->_marpa_b_or_node_last_and($augment2_or_node_id)) {
      my $cause_id = $bocage->_marpa_b_and_node_cause($augment2_and_node_id);
      if (defined $cause_id) {
          push @or_node_ids, $cause_id;
	  next AND_NODE;
      }
      my $token_id = $bocage->_marpa_b_and_node_symbol($augment2_and_node_id);
      push @token_ids, $token_id;
    }
    my $new_cp = ensure_cp($asf, \@or_node_ids, \@token_ids);
    $new_cp->[Marpa::R2::Internal::Scanless::Choicepoint::EXTERNAL] = 1;
    return $new_cp;
} ## end sub Marpa::R2::Scanless::ASF::top_choicepoint

sub make_token_cp { return -($_[0] + 43); }
sub unmake_token_cp { return -$_[0] - 43; }

sub cmp_symches_by_predecessors {
    my ( $symch_a, $symch_b, $sorted_pairings, $chaf_predecessors ) = @_;
    my ( $a_first_pairing, $a_last_pairing ) = @{$symch_a};
    my ( $b_first_pairing, $b_last_pairing ) = @{$symch_b};
    my $a_diff = $a_last_pairing - $a_first_pairing;
    my $b_diff = $b_last_pairing - $b_first_pairing;
    my $cmp    = $a_diff <=> $b_diff;
    return $cmp if $cmp;
    for ( my $node_ix = 0; $node_ix <= $a_diff; $node_ix++ ) {
        my $a_predecessor_cp =
            $sorted_pairings->[ $a_first_pairing + $node_ix ]->[0];
        my $b_predecessor_cp =
            $sorted_pairings->[ $b_first_pairing + $node_ix ]->[0];
        my $cmp = $a_predecessor_cp cmp $b_predecessor_cp;
        return $cmp if $cmp;
        $a_predecessor_cp =
            $sorted_pairings->[ $a_first_pairing + $node_ix ]->[1];
        $b_predecessor_cp =
            $sorted_pairings->[ $b_first_pairing + $node_ix ]->[1];
        $cmp = $a_predecessor_cp <=> $b_predecessor_cp;
        return $cmp if $cmp;
    } ## end for ( my $node_ix = 0; $node_ix <= $a_diff; $node_ix++)
    my $a_parent_id = $sorted_pairings->[ $a_first_pairing ] ->[3];
    my $b_parent_id = $sorted_pairings->[ $b_first_pairing ] ->[3];
    my $a_chaf_predecessors = [];
    $a_chaf_predecessors = $chaf_predecessors->[$a_parent_id] if $a_parent_id >= 0;
    my $b_chaf_predecessors = [];
    $b_chaf_predecessors = $chaf_predecessors->[$b_parent_id] if $b_parent_id >= 0;
    my $a_last_chaf_predecessor = $#{$a_chaf_predecessors};
    my $b_last_chaf_predecessor = $#{$b_chaf_predecessors};
    $cmp = $a_last_chaf_predecessor <=> $b_last_chaf_predecessor;
    return $cmp if $cmp;
    for my $predecessor_ix (0 .. $a_last_chaf_predecessor) {
         my $a_predecessor_id = $a_chaf_predecessors->[$predecessor_ix];
         my $b_predecessor_id = $b_chaf_predecessors->[$predecessor_ix];
         $cmp = $a_predecessor_id <=> $b_predecessor_id;
         return $cmp if $cmp;
    }
    return 0;
} ## end sub cmp_symches_by_predecessors

# Given a set of or-nodes, convert them to a factor
sub or_nodes_to_factor {
    $DB::single = 1;
    my ( $asf, $or_node_list, $chaf_predecessors ) = @_;
    my $slr    = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce  = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my @pairings = ();
    for my $parent_or_node_id ( @{$or_node_list} ) {
        for my $and_node_id (
            $bocage->_marpa_b_or_node_first_and($parent_or_node_id)
            .. $bocage->_marpa_b_or_node_last_and($parent_or_node_id) )
        {
            ## -1 if no predecessor
            my $predecessor_cp =
                $bocage->_marpa_b_and_node_predecessor($and_node_id);
            my $cause_cp = $bocage->_marpa_b_and_node_cause($and_node_id);
            if ( not defined $cause_cp ) {
                my $token_id =
                    $bocage->_marpa_b_and_node_symbol($and_node_id);
                say STDERR "cause is token $token_id";
                $cause_cp = make_token_cp($and_node_id);
            }
            say STDERR "and-node $and_node_id = [ ", ( $predecessor_cp // 'undef' ), "; $cause_cp ]";
            if ( not defined $predecessor_cp ) {
                push @pairings, [ 'nil', -1, $cause_cp, $parent_or_node_id ];
            }
            else {
                push @pairings,
                    [ 'pred', $predecessor_cp, $cause_cp,
                    $parent_or_node_id ];
            }
        } ## end for my $and_node_id ( $bocage->_marpa_b_or_node_first_and...)
    } ## end for my $parent_or_node_id ( @{$or_node_list} )
    my @sorted_pairings =
        sort {
        $a->[2] <=> $b->[2] || $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1];
        } @pairings;

    say STDERR "sorted_pairings = ", Data::Dumper::Dumper(\@sorted_pairings);

    # A symch is a set of and-nodes sharing the same component
    my @symches                = ();
    my $start_of_current_symch = 0;
    my $current_component      = $sorted_pairings[0]->[2];
    AND_NODE_IX:
    for (
        my $and_node_ix = $start_of_current_symch + 1;
        $and_node_ix <= $#sorted_pairings;
        $and_node_ix++
        )
    {
        my $this_component = $sorted_pairings[$and_node_ix]->[2];
        next AND_NODE_IX if $current_component == $this_component;
        push @symches, [ $start_of_current_symch, $and_node_ix - 1 ];
        $start_of_current_symch = $and_node_ix;
        $current_component = $sorted_pairings[$start_of_current_symch]->[2];
    } ## end AND_NODE_IX: for ( my $and_node_ix = $start_of_current_symch + 1;...)
    push @symches, [ $start_of_current_symch, $#sorted_pairings ];

    # Sort the cause choices by their predecessor sets
    my @sorted_symches =
        sort { cmp_symches_by_predecessors( $a, $b, \@sorted_pairings, $chaf_predecessors ); }
        @symches;

    my @cartesians        = ();
    my $current_cartesian;
    {
        my $first_pairing = $sorted_pairings[ $sorted_symches[0]->[0] ];
        my $first_cause_id = $first_pairing->[2];
        my $first_parent_id = $first_pairing->[3];
            say "cause=$first_cause_id, parent=$first_parent_id, ", Data::Dumper::Dumper( $chaf_predecessors->[$first_parent_id]);
        my $chaf_predecessors = $chaf_predecessors->[$first_parent_id] // [];
        $current_cartesian =  [
            $chaf_predecessors,
            [   map { $sorted_pairings[$_]->[1] }
                    grep { $sorted_pairings[$_]->[0] eq 'pred' }
                    ( $sorted_symches[0]->[0] .. $sorted_symches[0]->[1] )
            ],
            [$first_cause_id]
        ];
    }
    my $current_symch = $sorted_symches[0];
    SYMCH_IX:
    for ( my $symch_ix = 1; $symch_ix <= $#sorted_symches; $symch_ix++ ) {
        my $this_symch = $sorted_symches[$symch_ix];
        if (cmp_symches_by_predecessors(
                $current_symch,    $this_symch,
                \@sorted_pairings, $chaf_predecessors
            )
            )
        {
            push @cartesians, $current_cartesian;
            say STDERR "Pushing cartesian: ",
                Data::Dumper::Dumper($current_cartesian);
            my $first_pairing = $sorted_pairings[ $sorted_symches[0]->[0] ];
        my $first_cause_id = $first_pairing->[2];
        my $first_parent_id = $first_pairing->[3];
            say "cause=$first_cause_id, parent=$first_parent_id, ", Data::Dumper::Dumper( $chaf_predecessors->[$first_parent_id]);
            my $chaf_predecessors = $chaf_predecessors->[$first_parent_id]
                // [];
            $current_cartesian = [
                $chaf_predecessors,
                [   map { $sorted_pairings[$_]->[1] }
                        grep { $sorted_pairings[$_]->[0] eq 'pred' } (
                        $sorted_symches[$symch_ix]->[0]
                            .. $sorted_symches[$symch_ix]->[1]
                        )
                ],
                [$first_cause_id]
            ];
            $current_symch = $this_symch;
            next SYMCH_IX;
        } ## end if ( cmp_symches_by_predecessors( $current_symch, ...))
        push @{ $current_cartesian->[2] },
            $sorted_pairings[ $sorted_symches[$symch_ix]->[0] ]->[2];
    } ## end for ( my $symch_ix = 1; $symch_ix <= $#sorted_symches...)
    say STDERR "Pushing cartesian: ", Data::Dumper::Dumper($current_cartesian);
    push @cartesians, $current_cartesian;
    return [ \@cartesians, 0 ];
} ## end sub or_nodes_to_factor

sub Marpa::R2::Scanless::ASF::first_factored_rhs {
    my ( $asf, $arg_cp ) = @_;
    Marpa::R2::exception("Cannot factor token") if $arg_cp < 0;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my @or_node_worklist  = @{$arg_cp->[Marpa::R2::Internal::Scanless::Choicepoint::OR_NODE_IDS]};
    my @final_or_nodes;
    my $chaf_predecessors =
        $asf
        ->[Marpa::R2::Internal::Scanless::ASF::FAC_CHAF_PREDECESSOR_BY_CAUSE]
        = [];

    my @chaf_links = ();
    WORK_ITEM: while ( defined( my $or_node_id = pop @or_node_worklist ) ) {
        my $irl_id = $bocage->_marpa_b_or_node_irl($or_node_id);

        # The first one may be undefined, because that ID comes from the
        # user.  Otherwise this should never fail.
        Marpa::R2::exception("Bad or-node ID: $or_node_id")
            if not defined $irl_id;
        if ( not $grammar_c->_marpa_g_irl_is_virtual_rhs($irl_id) ) {
            push @final_or_nodes, $or_node_id;
            say STDERR "Final or-node: $or_node_id";
            next WORK_ITEM;
        } ## end if ( not $grammar_c->_marpa_g_irl_is_virtual_rhs($irl_id...))
        for my $and_node_id ( $bocage->_marpa_b_or_node_first_and($or_node_id)
            .. $bocage->_marpa_b_or_node_last_and($or_node_id) )
        {

            my $predecessor_id =
                $bocage->_marpa_b_and_node_predecessor($and_node_id);
            ## This is the last and-node of a virtual RHS rule,
            ## so the cause cannot be a token
            my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
            say STDERR "Chaf link $or_node_id -> $cause_id";
            $chaf_links[$cause_id][$predecessor_id] = 1;
            ## In C, use a bitmap to track active cause ID's?
            ## Virtual RHS, so we do not have to worry about tokens
            push @or_node_worklist, $cause_id;
        } ## end for my $and_node_id ( $bocage->_marpa_b_or_node_first_and...)
    } ## end WORK_ITEM: while ( defined( my $or_node_id = pop @or_node_worklist ) )
    # In the C code, do track CHAF cause/predecessor with linked lists?
    for my $cause_id ( 0 .. $#chaf_links ) {
        my $predecessors = $chaf_links[$cause_id];
        if ( defined $predecessors ) {
            $chaf_predecessors->[$cause_id] = [ grep { $predecessors->[$_] } (0 .. $#$predecessors) ];
        }
    } ## end for my $cause_id ( 0 .. $#$chaf_predecessors )
    say STDERR "about to call or_nodes_to_factor with final or-nodes, chaf predecessors:\n",
        Data::Dumper::Dumper($chaf_predecessors);
    my @factoring = ( or_nodes_to_factor( $asf, \@final_or_nodes, $chaf_predecessors ) );
    my $current_chaf_predecessor_or_nodes = [];
    FACTOR: while (1) {
        my $current_factor = $factoring[$#factoring];
        my ( $cartesians, $current_cartesian_ix ) = @{$current_factor};
        my $current_cartesian    = $cartesians->[$current_cartesian_ix];
        my $predecessor_or_nodes = $current_cartesian->[1];
        $current_chaf_predecessor_or_nodes = $current_cartesian->[0]
            if $#{$current_chaf_predecessor_or_nodes} < 0;
        if ( $#{$predecessor_or_nodes} < 0 ) {
            $predecessor_or_nodes = $current_chaf_predecessor_or_nodes;
            last FACTOR if $#{$predecessor_or_nodes} < 0;
            $current_chaf_predecessor_or_nodes = [];
        }
        say STDERR "about to call or_nodes_to_factor with or-nodes ",
            Data::Dumper::Dumper($predecessor_or_nodes);
        push @factoring,
            or_nodes_to_factor( $asf, $predecessor_or_nodes,
            $chaf_predecessors );
    } ## end FACTOR: while (1)
    return \@factoring;
} ## end sub Marpa::R2::Scanless::ASF::first_factored_rhs

sub irl_extend {
    my ( $recce, $or_node_id ) = @_;
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $irl_id    = $bocage->_marpa_b_or_node_irl($or_node_id);
    return or_node_flatten( $recce, $or_node_id )
        if not $grammar_c->_marpa_g_irl_is_virtual_rhs($irl_id);
    my @choices;
    for my $and_node_id ( $bocage->_marpa_b_or_node_first_and($or_node_id)
        .. $bocage->_marpa_b_or_node_last_and($or_node_id) )
    {
        my $predecessor_id =
            $bocage->_marpa_b_and_node_predecessor($and_node_id);

        # If not defined, one choice, an empty series of node ID's
        my $left_choices =
            defined $predecessor_id
            ? or_node_flatten( $recce, $predecessor_id )
            : [ [] ];
    my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
        my $right_choices = irl_extend( $recce, $cause_id );
        for my $left_choice ( @{$left_choices} ) {
            for my $right_choice ( @{$right_choices} ) {
                push @choices, [ @{$left_choice}, @{$right_choice} ];
            }
        }
    } ## end for my $and_node_id ( $bocage->_marpa_b_or_node_first_and...)
    return \@choices;
} ## end sub irl_extend

sub or_node_flatten {
    my ( $recce, $or_node_id ) = @_;
    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my @choices;
    for my $and_node_id ( $bocage->_marpa_b_or_node_first_and($or_node_id)
        .. $bocage->_marpa_b_or_node_last_and($or_node_id) )
    {
        my @choice = ();
        my $proto_choices =
            [ [] ];    # a single empty list of or-node IDs is the default
        my $predecessor_id =
            $bocage->_marpa_b_and_node_predecessor($and_node_id);
        if ( defined $predecessor_id ) {
            $proto_choices = or_node_flatten( $recce, $predecessor_id );
        }
        my $next_choice;
        if (defined(
                my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id)
            )
            )
        {
            $next_choice = $cause_id;
        } ## end if ( defined( my $cause_id = $bocage...))
        else {
            my $token_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
            $next_choice = make_token_cp( $and_node_id );
        }
        for my $proto_choice ( @{$proto_choices} ) {
            push @choices, [ @{$proto_choice}, $next_choice ];
        }
    } ## end for my $and_node_id ( $bocage->_marpa_b_or_node_first_and...)
    return \@choices;
} ## end sub or_node_flatten

# Return choices in XRL terms
# The memoization is vital for efficiency -- without it the
# algorithm quickly and easily goes very non-linear
sub choices {
    my ( $recce, $or_node_id ) = @_;
    my $memoized_or_nodes =
        $recce->[Marpa::R2::Internal::Recognizer::ASF_OR_NODES];
    my $choices = $memoized_or_nodes->[$or_node_id];
    return $choices if defined $choices;
    $choices = $memoized_or_nodes->[$or_node_id] =
            irl_extend( $recce, $or_node_id );
    return $choices;
}

sub or_node_expand {
    my ( $recce, $or_node_id, $memoized_expansions ) = @_;
    my $memoized_or_nodes =
        $recce->[Marpa::R2::Internal::Recognizer::ASF_OR_NODES];
    my $choices   = choices( $recce, $or_node_id );
    my @children = ();

    $memoized_expansions //= [];
    my $expansion = $memoized_expansions->[$or_node_id];
    return $expansion if defined $expansion;
    for my $choice ( @{$choices} ) {
        push @children, [
            map {
                $_ < 0
                    ? $_
                    : or_node_expand( $recce, $_, $memoized_expansions )
            } @{$choice}
        ];
    } ## end for my $choice ( @{$choices} )
    my $choice_count = scalar @children;
    if ( $choice_count == 1 ) {
        $expansion = [ $or_node_id, @{$children[0]} ];
    }
    else {
        $expansion = [ -2, $or_node_id, @children ];
    }
    return $memoized_expansions->[$or_node_id] = $expansion;
} ## end sub or_node_expand

sub normalize_asf_blessing {
    my ($name) = @_;
    $name =~ s/\A \s * //xms;
    $name =~ s/ \s * \z//xms;
    $name =~ s/ \s+ / /gxms;
    $name =~ s/ [^\w] /_/gxms;
    return $name;
} ## end sub normalize_asf_blessing

# Returns undef if no parse
sub Marpa::R2::Scanless::ASF::new {
    my ( $class, @arg_hashes ) = @_;
    my $asf       = bless [], $class;

    my $choice_blessing = 'My_ASF::choice';
    my $force;
    my $default_blessing;
    my $slr;

    for my $args (@arg_hashes) {
        if ( defined( my $value = $args->{slr} ) ) {
            $asf->[Marpa::R2::Internal::Scanless::ASF::SLR] = $slr = $value;
        }
        if ( defined( my $value = $args->{choice} ) ) {
            $choice_blessing = $value;
        }
        if ( defined( my $value = $args->{force} ) ) {
            $force = $value;
        }
        if ( defined( my $value = $args->{default} ) ) {
            $default_blessing = $value;
        }
    } ## end for my $args (@arg_hashes)

    Marpa::R2::exception(
        q{The "slr" named argument must be specified with the Marpa::R2::Scanless::ASF::new method}
    ) if not defined $slr;
    $asf->[Marpa::R2::Internal::Scanless::ASF::SLR] = $slr;

    Marpa::R2::exception(
        q{The "force" or "default" named argument must be specified },
        {with the Marpa::R2::Scanless::ASF::new method}
    ) if not defined $force and not defined $default_blessing;

    my $slg       = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr  = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];

    if ( $recce->[Marpa::R2::Internal::Recognizer::T_C] ) {

        # If there is a tree we are in valuation mode, and cannot create an ASF
        Marpa::R2::exception(
            'An attempt was made to create an ASF for a SLIF recognizer in value mode',
            '   The recognizer must be reset first'
        );
    } ## end if ( $recce->[Marpa::R2::Internal::Recognizer::T_C] )

    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( not $bocage ) {
        my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
        my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
        my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
        $grammar_c->throw_set(0);
        $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C] =
            Marpa::R2::Thin::B->new( $recce_c, -1 );
        $grammar_c->throw_set(1);
        return if not defined $bocage;
    } ## end if ( not $bocage )

    my $rule_resolutions =
        $recce->[Marpa::R2::Internal::Recognizer::RULE_RESOLUTIONS]
        // Marpa::R2::Internal::Recognizer::semantics_set( $recce,
        Marpa::R2::Internal::Recognizer::default_semantics($recce) );

    my $default_blessing_by_rule_id   = $rule_resolutions->{blessing};
    my $default_blessing_by_lexeme_id = $rule_resolutions->{blessing_by_lexeme};

    my @rule_blessing   = ();
    my $highest_rule_id = $grammar_c->highest_rule_id();
    RULE: for ( my $rule_id = 0; $rule_id <= $highest_rule_id; $rule_id++ ) {
        my $lhs_id = $grammar_c->rule_lhs($rule_id);
        my $name   = Marpa::R2::Grammar::original_symbol_name(
            $grammar->symbol_name($lhs_id) );
        if ( defined $force ) {
            $rule_blessing[$rule_id] = join q{::}, $force,
                normalize_asf_blessing($name);
            next RULE;
        }
        if (defined(
                my $blessing = $default_blessing_by_rule_id->[$rule_id]
            )
            )
        {
            $rule_blessing[$rule_id] = $blessing;
            next RULE;
        } ## end if ( defined( my $blessing = $default_blessing_by_rule_id...))
        $rule_blessing[$rule_id] = join q{::}, $default_blessing,
            normalize_asf_blessing($name);
    } ## end RULE: for ( my $rule_id = 0; $rule_id <= $highest_rule_id; ...)
    my @symbol_blessing   = ();
    my $highest_symbol_id = $grammar_c->highest_symbol_id();
    SYMBOL: for ( my $symbol_id = 0; $symbol_id <= $highest_symbol_id; $symbol_id++ )
    {
        my $name = Marpa::R2::Grammar::original_symbol_name(
            $grammar->symbol_name($symbol_id) );
        if ( defined $force ) {
            $symbol_blessing[$symbol_id] = join q{::}, $force,
                normalize_asf_blessing($name);
            next SYMBOL;
        }
        if (defined(
                my $blessing = $default_blessing_by_lexeme_id->[$symbol_id]
            )
            )
        {
            $symbol_blessing[$symbol_id] = $blessing;
            next SYMBOL;
        } ## end if ( defined( my $blessing = $default_blessing_by_lexeme_id...))
        $symbol_blessing[$symbol_id] = join q{::}, $default_blessing,
            normalize_asf_blessing($name);
    } ## end for ( my $symbol_id = 0; $symbol_id <= $highest_symbol_id...)
    $asf->[Marpa::R2::Internal::Scanless::ASF::RULE_BLESSING] =
        \@rule_blessing;
    $asf->[Marpa::R2::Internal::Scanless::ASF::SYMBOL_BLESSING] =
        \@symbol_blessing;
    $asf->[Marpa::R2::Internal::Scanless::ASF::CHOICE_BLESSING] =
        $choice_blessing;

    return $asf;

} ## end sub Marpa::R2::Scanless::ASF::new

sub Marpa::R2::Scanless::ASF::raw {
    my ($asf, $start_rcp) = @_;
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    $start_rcp //= $asf->top_choicepoint();
    return or_node_expand( $recce, $start_rcp );
} ## end sub Marpa::R2::Scanless::ASF::raw_asf

sub bless_asf {
    my ( $asf, $tree, $data ) = @_;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $tag       = ref $tree ? $tree->[0] : $tree;
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( $tag >= 0 ) {
        my ( $checkpoint_id, @children ) = @{$tree};
        my $blessed_node = $data->{blessed_nodes}->[$checkpoint_id];
        return $blessed_node if defined $blessed_node;
        my $irl_id = $bocage->_marpa_b_or_node_irl($checkpoint_id);
        my $xrl_id = $grammar_c->_marpa_g_source_xrl($irl_id);
        my $desc   = 'Rule ' . $grammar->brief_rule($xrl_id);
        my $rule_blessing =
            $asf->[Marpa::R2::Internal::Scanless::ASF::RULE_BLESSING]
            ->[$xrl_id];
        $blessed_node = bless [
            $checkpoint_id, $desc,
            map { bless_asf( $asf, $_, $data ) } @children
            ],
            $rule_blessing;
        $data->{blessed_nodes}->[$checkpoint_id] = $blessed_node;
        return $blessed_node;
    } ## end if ( $tag >= 0 )
    if ( $tag == -2 ) {
        my ( $tag, $checkpoint_id, @choices ) = @{$tree};
        my $blessed_node = $data->{blessed_nodes}->[$checkpoint_id];
        return $blessed_node if defined $blessed_node;
        my $irl_id = $bocage->_marpa_b_or_node_irl($checkpoint_id);
        my $xrl_id = $grammar_c->_marpa_g_source_xrl($irl_id);
        my $desc   = 'Rule ' . $grammar->brief_rule($xrl_id);
        my $rule_blessing =
            $asf->[Marpa::R2::Internal::Scanless::ASF::RULE_BLESSING]
            ->[$xrl_id];
        my @blessed_choices = ();

        for my $choice (@choices) {
            push @blessed_choices,
                bless [ map { bless_asf( $asf, $_, $data ) } @{$choice} ],
                $rule_blessing;
        }
        $blessed_node = bless [ -2, $checkpoint_id, $desc, @blessed_choices ],
            $asf->[Marpa::R2::Internal::Scanless::ASF::CHOICE_BLESSING];
        $data->{blessed_nodes}->[$checkpoint_id] = $blessed_node;
        return $blessed_node;
    } ## end if ( $tag == -2 )
    {
        my $and_node_id = unmake_token_cp( $tag );
        my $token_isy_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
        my $token_id     = $grammar_c->_marpa_g_source_xsy($token_isy_id);
        my $symbol_blessing =
            $asf->[Marpa::R2::Internal::Scanless::ASF::SYMBOL_BLESSING]
            ->[$token_id];
        return bless [
            -1, ( 'Token: ' . $asf->cp_token_name($tag) ),
            $and_node_id, $asf->cp_literal($tag)
        ], $symbol_blessing;
    }
    die "Unknown tag in bless_asf: $tag";
} ## end sub bless_asf

sub Marpa::R2::Scanless::ASF::bless {
    my ( $asf, $tree ) = @_;
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my %data  = ();
    $data{blessed_nodes} = [];
    bless_asf( $asf, $tree, \%data );
} ## end sub Marpa::R2::Scanless::ASF::bless

# No check for conflicting usage -- value(), asf(), etc.
# at this point
sub Marpa::R2::Scanless::ASF::top_choicepoint {
    my ($asf) = @_;
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( not $bocage ) {
        my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
        my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
        my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
        $grammar_c->throw_set(0);
        $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C] =
            Marpa::R2::Thin::B->new( $recce_c, -1 );
        $grammar_c->throw_set(1);
        die "No parse" if not defined $bocage;
    } ## end if ( not $bocage )
    my $augment_or_node_id = $bocage->_marpa_b_top_or_node();
    # say STDERR "augment or-node = $augment_or_node_id";
    my $augment_and_node_id =
        $bocage->_marpa_b_or_node_first_and($augment_or_node_id);
    my $augment2_or_node_id =
        $bocage->_marpa_b_and_node_cause($augment_and_node_id);
    # say STDERR "augment 2 or-node = $augment2_or_node_id";
    my $augment2_and_node_id =
        $bocage->_marpa_b_or_node_first_and($augment2_or_node_id);
    return $bocage->_marpa_b_and_node_cause($augment2_and_node_id);
} ## end sub Marpa::R2::Scanless::ASF::top_choicepoint

sub Marpa::R2::Scanless::ASF::choices {
    my ( $asf, $choicepoint ) = @_;
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    return choices( $recce, $choicepoint );
}

sub token_es_span {
    my ( $asf, $and_node_id ) = @_;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $predecessor_id = $bocage->_marpa_b_and_node_predecessor($and_node_id);
    my $parent_or_node_id = $bocage->_marpa_b_and_node_parent($and_node_id);

    if ($predecessor_id) {
        my $origin_es  = $bocage->_marpa_b_or_node_set($predecessor_id);
        my $current_es = $bocage->_marpa_b_or_node_set($parent_or_node_id);
        return ( $origin_es, $current_es - $origin_es );
    } ## end if ($predecessor_id)
    return or_node_es_span( $asf, $parent_or_node_id );
} ## end sub token_es_span

sub or_child_current_set {
    my ( $asf, $or_child ) = @_;
    my $slr    = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce  = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( $or_child < 0 ) {

        # switch the parent in for the or-node
        my $and_node_id = unmake_token_cp($or_child);
        $or_child = $bocage->_marpa_b_and_node_parent($and_node_id);
    } ## end if ( $or_child < 0 )
    return $bocage->_marpa_b_or_node_set($or_child);
} ## end sub or_child_current_set

sub Marpa::R2::Scanless::ASF::is_factored {
    my ( $asf, $choicepoint_id ) = @_;

    my $is_factored_by_choicepoint =
        $asf->[Marpa::R2::Internal::Scanless::ASF::CHOICEPOINT_IS_FACTORED];
    if (defined(
            my $is_factored = $is_factored_by_choicepoint->[$choicepoint_id]
        )
        )
    {
        return $is_factored;
    } ## end if ( defined( my $is_factored = $is_factored_by_choicepoint...))

    my $choices = $asf->choices($choicepoint_id);
    return $is_factored_by_choicepoint->[$choicepoint_id] = 0
        if scalar @{$choices} <= 1;

    my $choice_0               = $choices->[0];
    my $choice_0_last_child_ix = $#{$choice_0};

    # At this point, default to factored
    $is_factored_by_choicepoint->[$choicepoint_id] = 1;
    for my $choice_ix ( 1 .. $#{$choices} ) {
        my $choice                 = $choices->[$choice_ix];
        my $choice_n_last_child_ix = $#{$choice};
        return 1 if $choice_0_last_child_ix != $choice_n_last_child_ix;
    }

    # If here, all choices have the same child count
    # For every medial location (that is, current child location,
    # except for # the last child).
    for my $child_ix ( 1 .. $choice_0_last_child_ix ) {
        my $choice_0_medial =
            or_child_current_set( $asf, $choice_0->[$child_ix] );
        for my $choice_ix ( 1 .. $#{$choices} ) {
            my $child = $choices->[$choice_ix]->[$child_ix];
            return 1
                if $choice_0_medial != or_child_current_set( $asf, $child );
        }
    } ## end for my $child_ix ( 1 .. $choice_0_last_child_ix )

    # No factoring found, so reverse the default
    return $is_factored_by_choicepoint->[$choicepoint_id] = 0;
} ## end sub is_factored

sub Marpa::R2::Scanless::ASF::choices_by_rhs {
    my ( $asf, $choicepoint_id ) = @_;
    my @choices_by_rhs = ();
    # Get choices first to ensure is-factored boolean is set
    my $choices = $asf->choices($choicepoint_id);
    Marpa::R2::exception(
        "Choices by RHS requested for factored choicepoint $choicepoint_id")
        if $asf->is_factored($choicepoint_id);
    my $choice_0 = $choices->[0];

    CHILD: for my $child_ix ( 0 .. $#{$choice_0} ) {
        my @tags = ();
        CHOICE: for my $choice_ix ( 0 .. $#{$choices} ) {
            my $child = $choices->[$choice_ix]->[$child_ix];
            my $tag;
            if ( $child < 0 ) {
                my $and_node_id = unmake_token_cp( $child );
                push @tags, "A$and_node_id";
                next CHOICE;
            }
            push @tags, $child;
        } ## end CHOICE: for my $choice_ix ( 0 .. ${$choices} )
        my %seen = ();
        TAG: for my $tag ( grep { !$seen{$_}++ } @tags ) {
            if ( ( substr $tag, 0, 1 ) eq 'A' ) {
                push @{ $choices_by_rhs[$child_ix] },
                    make_token_cp( substr $tag, 1 );
                next TAG;
            }
            push @{ $choices_by_rhs[$child_ix] }, $tag + 0;
        } ## end for my $tag ( grep { !$seen{$_}++ } @tags )
    } ## end CHILD: for my $child_ix ( 0 .. $#{$choice_0} )
    return \@choices_by_rhs;

} ## end sub choices_by_rhs

sub ambiguities {
    my ( $asf, $choicepoint_id, $data ) = @_;
    my $slr              = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $was_node_seen    = $data->{was_node_seen};
    return if $was_node_seen->[$choicepoint_id];
    $was_node_seen->[$choicepoint_id] = 1;
    my $recce   = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $choices = $asf->choices($choicepoint_id);
    my $is_node_ambiguous = $data->{is_node_ambiguous};
    my $last_choice_ix    = $#{$choices};

    if ( $last_choice_ix > 0 ) {
        $is_node_ambiguous->[$choicepoint_id] = 1;
        return if $asf->is_factored( $choicepoint_id );
        my $choice_0 = $choices->[0];

        # Initially, guess that node is factored

        # If here, we are ambiguous but
        # not factored
        # Recurse through any children identical in all factors
        CHILD: for my $child_ix ( 1 .. $#{$choice_0} ) {
            my $choice_0_child = $choice_0->[$child_ix];

            # If it's a token, don't recurse for this child --
            # either these children are all tokens, or else they
            # are not identical in all factors
            next CHILD if $choice_0_child < 0;
            for my $choice_ix ( 1 .. $last_choice_ix ) {
                my $child = $choices->[$choice_ix]->[$child_ix];

                # Not identical in all factors
                next CHILD if $child != $choice_0_child;
            } ## end for my $choice_ix ( 1 .. $last_choice_ix )

            # For this choice, the child is the same in all factors --
            # recurse through it
            ambiguities( $asf, $choice_0_child, $data );
        } ## end CHILD: for my $child_ix ( 1 .. $choice_0_last_child_ix )

        return;
    } ## end if ( $last_choice_ix > 0 )

    for my $choice ( @{$choices} ) {
        CHILD: for my $child ( @{$choice} ) {
            next CHILD if $child < 0;
            ambiguities( $asf, $child, $data );
        }
    } ## end for my $choice ( @{$choices} )
    return;
} ## end sub ambiguities

# Return a list of ambiguous checkpoint ID's.
# Once an ambiguity is found, its subtree is not explored further.
sub Marpa::R2::Scanless::ASF::ambiguities {
    my ( $asf, $tree, @arg_hashes ) = @_;
    my $slr               = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my %data              = ();
    my $is_node_ambiguous = $data{is_node_ambiguous} = [];
    $data{was_node_seen} = [];
    ambiguities( $asf, $asf->top_choicepoint(), \%data );
    my $recce      = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage     = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my @sorted_ambiguities =
        map  { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
        map  { [ $bocage->_marpa_b_or_node_origin($_), $_ ] }
        grep { $is_node_ambiguous->[$_] } 0 .. $#{$is_node_ambiguous};
    return \@sorted_ambiguities;
} ## end sub Marpa::R2::Scanless::ASF::ambiguities

sub or_node_es_span {
    my ( $asf, $choicepoint ) = @_;
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce      = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage     = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $origin_es  = $bocage->_marpa_b_or_node_origin($choicepoint);
    my $current_es = $bocage->_marpa_b_or_node_set($choicepoint);
    return $origin_es, $current_es - $origin_es;
} ## end sub or_node_es_span

sub Marpa::R2::Scanless::ASF::cp_literal {
    my ( $asf, $cp ) = @_;
    if ($cp < 0) {
        my $and_node_id = unmake_token_cp( $cp );
        my $slr = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
        my ( $start, $length ) = token_es_span( $asf, $and_node_id );
        return '' if $length == 0;
        return $slr->substring( $start, $length );
    }
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    return $slr->substring(or_node_es_span($asf, $cp));
} ## end sub Marpa::R2::Scanless::R::choicepoint_literal

sub Marpa::R2::Scanless::ASF::cp_span {
    my ( $asf, $cp ) = @_;
    return or_node_es_span($asf, $cp) if $cp >= 0;
    my $and_node_id = unmake_token_cp( $cp );
    return token_es_span( $asf, $and_node_id );
}

sub Marpa::R2::Scanless::ASF::cp_rule_id {
    my ( $asf, $choicepoint ) = @_;
    return undef if $choicepoint < 0;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $irl_id    = $bocage->_marpa_b_or_node_irl($choicepoint);
    return $grammar_c->_marpa_g_source_xrl($irl_id);
} ## end sub Marpa::R2::Scanless::ASF::cp_rule

sub Marpa::R2::Scanless::ASF::cp_rule {
    my ( $asf, $choicepoint ) = @_;
    return undef if $choicepoint < 0;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $irl_id    = $bocage->_marpa_b_or_node_irl($choicepoint);
    my $rule_id   = $grammar_c->_marpa_g_source_xrl($irl_id);
    return $grammar->rule($rule_id);
} ## end sub Marpa::R2::Scanless::ASF::cp_rule_id

sub Marpa::R2::Scanless::ASF::cp_is_token {
    my ( $asf, $cp ) = @_;
    return $cp < 0 ? 1 : undef;
}

sub Marpa::R2::Scanless::ASF::cp_token_name {
    my ( $asf, $cp ) = @_;
    return undef if $cp >= 0;
    my $and_node_id  = unmake_token_cp($cp);
    my $slr          = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce        = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar      = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c    = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage       = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $token_isy_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
    my $token_id     = $grammar_c->_marpa_g_source_xsy($token_isy_id);
    return $grammar->symbol_name($token_id);
} ## end sub Marpa::R2::Scanless::ASF::cp_token_name

sub Marpa::R2::Scanless::ASF::cp_brief {
    my ( $asf, $cp ) = @_;
    return $asf->cp_token_name($cp) if $cp < 0;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $irl_id  = $bocage->_marpa_b_or_node_irl($cp);
    my $rule_id = $grammar_c->_marpa_g_source_xrl($irl_id);
    return $grammar->brief_rule($rule_id);
} ## end sub Marpa::R2::Scanless::ASF::cp_brief

sub Marpa::R2::Scanless::ASF::cp_blessing {
    my ( $asf, $cp ) = @_;
    if ( $cp < 0 ) {
        my $and_node_id = unmake_token_cp($cp);
        my $slr         = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
        my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
        my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
        my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
        my $token_isy_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
        my $token_id     = $grammar_c->_marpa_g_source_xsy($token_isy_id);
        return $asf->[Marpa::R2::Internal::Scanless::ASF::SYMBOL_BLESSING]
            ->[$token_id];
    } ## end if ( $cp < 0 )
    my $rule_id = $asf->cp_rule_id($cp);
    return $asf->[Marpa::R2::Internal::Scanless::ASF::RULE_BLESSING]
        ->[$rule_id];
} ## end sub Marpa::R2::Scanless::ASF::cp_blessing

1;

# vim: expandtab shiftwidth=4:
