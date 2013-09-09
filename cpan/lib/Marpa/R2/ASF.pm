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
$VERSION        = '2.071_000';
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

    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    if ( defined $recce->[Marpa::R2::Internal::Recognizer::TREE_MODE] ) {
        # If we already in ASF mode, or are in valuation mode, we cannot create an ASF
        Marpa::R2::exception(
            "An attempt was made to create an ASF for a SLIF recognizer already in use\n",
            "   The recognizer must be reset first\n",
            '  The current SLIF recognizer mode is "',
            $recce->[Marpa::R2::Internal::Recognizer::TREE_MODE],
            qq{"\n}
        );
    }
    $recce->[Marpa::R2::Internal::Recognizer::TREE_MODE] = 'forest';

    my $slg       = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr  = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];

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

    my $rule_resolutions = Marpa::R2::Internal::Recognizer::semantics_set( $recce);

    my $default_blessing_by_rule_id   = $rule_resolutions->{blessing};
    my $default_blessing_by_lexeme_id = $rule_resolutions->{blessing_by_lexeme};

    my @rule_blessing   = ();
    my $highest_rule_id = $grammar_c->highest_rule_id();
    RULE: for ( my $rule_id = 0; $rule_id <= $highest_rule_id; $rule_id++ ) {
        my $lhs_id = $grammar_c->rule_lhs($rule_id);
        my $name   = $grammar->symbol_name($lhs_id);
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
        my $name = $grammar->symbol_name($symbol_id);
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

1;

# vim: expandtab shiftwidth=4:
