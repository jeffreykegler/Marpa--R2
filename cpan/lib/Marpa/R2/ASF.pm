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
$VERSION        = '2.073_001';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

# The code in this file, for now, breaks "the rules".  It makes use
# of internal methods not documented as part of Libmarpa.
# It is intended to create documented Libmarpa methods to underlie
# this interface, and rewrite it to use them

package Marpa::R2::Internal::ASF;

# This is more complicated that it needs to be for the current implementation.
# It allows for LHS terminals (implemented in Libmarpa but not allowed by the SLIF).
# It also assumes that every or-node which can be constructed from preceding or-nodes
# and the input will be present.  This is currently the case, but in the future
# rules and/or symbols may have extra-syntactic conditions attached making this
# assumption false.

# Terms:

# NID (Node ID): Encoded ID of either an or-node or an and-node.
#
# Extensions:
# Set "powers":  A set of power 0 is an "atom" -- a single NID.
# A set of power 1 is a set of NID's -- a nidset.
# A set of power 2 is a set of sets of NID's, also called a powerset.
# A set of power 3 is a set of powersets, etc.
#
# The whole ID of NID is the external rule id of an or-node, or -1
# if the NID is for a token and-node.
#
# Intensions:
# A Symch is a nidset, where all the NID's share the same "whole ID"
# and the same span.  NID's in a symch may differ in their internal rule,
# or have different causes.  If the symch contains and-node NID's they
# will all have the same symbol.
#
# A choicepoint is a powerset -- a set of symches all of which share
# the same set of predecessors.  (This set of predecessors is a power 3 set of
# choicepoints.)  All symches in a choicepoint also share the same span,
# and the same symch-symbol.  A symch's symbol is the LHS of the rule,
# or the symbol of the token in the token and-nodes.

sub intset_id {
    my ($asf, @ids) = @_;
    my $key = join q{ }, sort { $a <=> $b } @ids;
    my $intset_by_key = $asf->[Marpa::R2::Internal::Scanless::ASF::INTSET_BY_KEY];
    my $intset_id = $intset_by_key->{$key};
    return $intset_id if defined $intset_id;
    $intset_id = $asf->[Marpa::R2::Internal::Scanless::ASF::NEXT_INTSET_ID]++;
    $intset_by_key->{$key} = $intset_id;
    return $intset_id;
}

sub Marpa::R2::Nidset::obtain {
    my ($class, $asf, @nids) = @_;
    my $id = intset_id($asf, @nids);
    my $nidset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::NIDSET_BY_ID];
    my $nidset = $nidset_by_id->[$id];
    return $nidset if defined $nidset;
    $nidset = bless [], $class;
    $nidset->[Marpa::R2::Internal::Nidset::ID] = $id;
    $nidset->[Marpa::R2::Internal::Nidset::NIDS] = [sort { $a <=> $b } @nids];
    $nidset_by_id->[$id] = $nidset;
    return $nidset;
}

sub Marpa::R2::Nidset::nids {
    my ($nidset) = @_;
    return $nidset->[Marpa::R2::Internal::Nidset::NIDS];
}

sub Marpa::R2::Nidset::nid {
    my ($nidset, $ix) = @_;
    return $nidset->[Marpa::R2::Internal::Nidset::NIDS]->[$ix];
}

sub Marpa::R2::Nidset::count {
    my ($nidset) = @_;
    return scalar @{$nidset->[Marpa::R2::Internal::Nidset::NIDS]};
}

sub Marpa::R2::Nidset::id {
    my ($nidset) = @_;
    return $nidset->[Marpa::R2::Internal::Nidset::ID];
}

sub Marpa::R2::Nidset::show {
    my ($nidset) = @_;
    my $id = $nidset->id();
    my $nids = $nidset->nids();
    return "Nidset #$id: " . join q{ }, @{$nids};
}

sub Marpa::R2::Powerset::obtain {
    my ($class, $asf, @nidset_ids) = @_;
    my $id = intset_id($asf, @nidset_ids);
    my $powerset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID];
    my $powerset = $powerset_by_id->[$id];
    return $powerset if defined $powerset;
    $powerset = bless [], $class;
    $powerset->[Marpa::R2::Internal::Powerset::ID] = $id;
    $powerset->[Marpa::R2::Internal::Powerset::NIDSET_IDS] = [ sort { $a <=> $b } @nidset_ids ];
    $powerset_by_id->[$id] = $powerset;
    return $powerset;
}

sub Marpa::R2::Powerset::nidset_ids {
    my ($powerset) = @_;
    return $powerset->[Marpa::R2::Internal::Powerset::NIDSET_IDS];
}

sub Marpa::R2::Powerset::count {
    my ($powerset) = @_;
    return scalar @{$powerset->[Marpa::R2::Internal::Powerset::NIDSET_IDS]};
}

sub Marpa::R2::Powerset::nidset_id {
    my ($powerset, $ix) = @_;
    my $nidset_ids = $powerset->[Marpa::R2::Internal::Powerset::NIDSET_IDS];
    return if $ix > $#{$nidset_ids};
    return $powerset->[Marpa::R2::Internal::Powerset::NIDSET_IDS]->[$ix];
}

sub Marpa::R2::Powerset::id {
    my ($powerset) = @_;
    return $powerset->[Marpa::R2::Internal::Powerset::ID];
}

sub Marpa::R2::Powerset::show {
    my ($powerset) = @_;
    my $id = $powerset->id();
    my $nidset_ids = $powerset->nidset_ids();
    return "Powerset #$id: " . join q{ }, @{$nidset_ids};
}

sub set_last_choice {
    my ( $asf, $nook ) = @_;
    my $or_nodes  = $asf->[Marpa::R2::Internal::Scanless::ASF::OR_NODES];
    my $or_node_id = $nook->[Marpa::R2::Internal::Nook::OR_NODE];
    my $and_nodes = $or_nodes->[$or_node_id];
    my $choice     = $nook->[Marpa::R2::Internal::Nook::FIRST_CHOICE];
    return if $choice > $#{ $and_nodes };
    if ( nook_has_semantic_cause( $asf, $nook ) ) {
        my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
        my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
        my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
        my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
        my $and_node_id = $and_nodes->[$choice];
        my $current_predecessor = $bocage->_marpa_b_and_node_predecessor($and_node_id);
        AND_NODE: while (1) {
            $choice++;
            $and_node_id = $and_nodes->[$choice];
            last AND_NODE if not defined $and_node_id;
            last AND_NODE
                if $current_predecessor
                    != $bocage->_marpa_b_and_node_predecessor($and_node_id);
        } ## end AND_NODE: while (1)
        $choice--;
    } ## end if ( nook_has_semantic_cause( $asf, $nook ) )
    $nook->[Marpa::R2::Internal::Nook::LAST_CHOICE] = $choice;
    return $choice;
} ## end sub set_last_choice

sub nook_new {
    my ( $asf, $or_node_id, $parent_or_node_id ) = @_;
    my $nook = [];
    $nook->[Marpa::R2::Internal::Nook::OR_NODE] = $or_node_id;
    $nook->[Marpa::R2::Internal::Nook::PARENT] = $parent_or_node_id // -1;
    $nook->[Marpa::R2::Internal::Nook::FIRST_CHOICE] = 0;
    set_last_choice($asf, $nook);
    return $nook;
} ## end sub nook_new

sub nook_increment {
    my ( $asf, $nook ) = @_;
    $nook->[Marpa::R2::Internal::Nook::LAST_CHOICE] //= 0;
    $nook->[Marpa::R2::Internal::Nook::FIRST_CHOICE] =
        $nook->[Marpa::R2::Internal::Nook::LAST_CHOICE] + 1;
    return if not defined set_last_choice( $asf, $nook );
    return 1;
} ## end sub nook_increment

sub nook_has_semantic_cause {
    my ( $asf, $nook ) = @_;
    my $or_node = $nook->[Marpa::R2::Internal::Nook::OR_NODE];
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];

    my $irl_id          = $bocage->_marpa_b_or_node_irl($or_node);
    my $predot_position = $bocage->_marpa_b_or_node_position($or_node) - 1;
    my $predot_isyid =
        $grammar_c->_marpa_g_irl_rhs( $irl_id, $predot_position );
    return $grammar_c->_marpa_g_isy_is_semantic($predot_isyid);
} ## end sub nook_has_semantic_cause

# No check for conflicting usage -- value(), asf(), etc.
# at this point
sub Marpa::R2::Scanless::ASF::top {
    my ($asf) = @_;
    my $top = $asf->[Marpa::R2::Internal::Scanless::ASF::TOP];
    return $top if defined $top;
    my $or_nodes = $asf->[Marpa::R2::Internal::Scanless::ASF::OR_NODES];
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    die 'No Bocage' if not $bocage;
    my $augment_or_node_id = $bocage->_marpa_b_top_or_node();
    my $augment_and_node_id = $or_nodes->[$augment_or_node_id]->[0];

    my $augment2_or_node_id =
        $bocage->_marpa_b_and_node_cause($augment_and_node_id);
    my $augment2_and_node_id = $or_nodes->[$augment2_or_node_id]->[0];

    my $start_or_node_id =
        $bocage->_marpa_b_and_node_cause($augment2_and_node_id);
    my $top_nidset = Marpa::R2::Nidset->obtain( $asf, $start_or_node_id );
    my $top_choicepoint_base = nidset_to_choicepoint_base( $asf, $top_nidset );
    $top = $asf->new_choicepoint($top_choicepoint_base);

    $asf->[Marpa::R2::Internal::Scanless::ASF::TOP] = $top;
    return $top;
} ## end sub Marpa::R2::Scanless::ASF::top

# Range from -1 to -42 reserved for special values
sub and_node_to_nid { return -$_[0] - 43; }
sub nid_to_and_node { return -$_[0] - 43; }

sub normalize_asf_blessing {
    my ($name) = @_;
    $name =~ s/\A \s * //xms;
    $name =~ s/ \s * \z//xms;
    $name =~ s/ \s+ / /gxms;
    $name =~ s/ \W /_/gxms;
    return $name;
} ## end sub normalize_asf_blessing

sub Marpa::R2::Internal::ASF::blessings_set {
    my ( $asf, $default_blessing, $force ) = @_;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];

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
        my $blessing =
            Marpa::R2::Internal::Recognizer::rule_blessing_find( $recce,
            $rule_id );
        if ( q{::} ne substr $blessing, 0, 2 ) {
            $rule_blessing[$rule_id] = $blessing;
            next RULE;
        }
        $rule_blessing[$rule_id] = join q{::}, $default_blessing,
            normalize_asf_blessing($name);
    } ## end RULE: for ( my $rule_id = 0; $rule_id <= $highest_rule_id; ...)

    my @symbol_blessing   = ();
    my $highest_symbol_id = $grammar_c->highest_symbol_id();
    SYMBOL:
    for ( my $symbol_id = 0; $symbol_id <= $highest_symbol_id; $symbol_id++ )
    {
        my $name = $grammar->symbol_name($symbol_id);
        if ( defined $force ) {
            $symbol_blessing[$symbol_id] = join q{::}, $force,
                normalize_asf_blessing($name);
            next SYMBOL;
        }
        my $blessing =
            Marpa::R2::Internal::Recognizer::lexeme_blessing_find( $recce,
            $symbol_id );
        if ( q{::} ne substr $blessing, 0, 2 ) {
            $symbol_blessing[$symbol_id] = $blessing;
            next SYMBOL;
        }
        $symbol_blessing[$symbol_id] = join q{::}, $default_blessing,
            normalize_asf_blessing($name);
    } ## end SYMBOL: for ( my $symbol_id = 0; $symbol_id <= $highest_symbol_id...)
    $asf->[Marpa::R2::Internal::Scanless::ASF::RULE_BLESSING] =
        \@rule_blessing;
    $asf->[Marpa::R2::Internal::Scanless::ASF::SYMBOL_BLESSING] =
        \@symbol_blessing;
    return $asf;
} ## end sub Marpa::R2::Internal::ASF::blessings_set

# Returns undef if no parse
sub Marpa::R2::Scanless::ASF::new {
    my ( $class, @arg_hashes ) = @_;
    my $asf       = bless [], $class;

    my $slr;

    for my $arg_hash (@arg_hashes) {
        ARG: for my $arg ( keys %{$arg_hash} ) {
            if ( $arg eq 'slr' ) {
                $asf->[Marpa::R2::Internal::Scanless::ASF::SLR] = $slr =
                    $arg_hash->{$arg};
                next ARG;
            }
            Marpa::R2::exception(
                qq{Unknown named arg to $asf->new(): "$arg"});
        } ## end ARG: for my $arg ( keys %{$arg_hash} )
    } ## end for my $arg_hash (@arg_hashes)

    Marpa::R2::exception(
        q{The "slr" named argument must be specified with the Marpa::R2::Scanless::ASF::new method}
    ) if not defined $slr;
    $asf->[Marpa::R2::Internal::Scanless::ASF::SLR] = $slr;

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

    $asf->[Marpa::R2::Internal::Scanless::ASF::NEXT_INTSET_ID] = 0;
    $asf->[Marpa::R2::Internal::Scanless::ASF::INTSET_BY_KEY] = {};

    $asf->[Marpa::R2::Internal::Scanless::ASF::NIDSET_BY_ID] = [];
    $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID] = [];


    my $slg       = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr  = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];

    $recce->ordering_create()
        if not $recce->[Marpa::R2::Internal::Recognizer::O_C];

    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $ordering = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $or_nodes = $asf->[Marpa::R2::Internal::Scanless::ASF::OR_NODES] = [];
    use sort 'stable';
    OR_NODE: for ( my $or_node_id = 0;; $or_node_id++ ) {
        my @and_node_ids = $ordering->_marpa_o_or_node_and_node_ids($or_node_id);
        last OR_NODE if not scalar @and_node_ids;
        my @sorted_and_node_ids = map { $_->[-1] } sort { $a <=> $b } map {
            [ ( $bocage->_marpa_b_and_node_predecessor($_) // -1 ), $_ ]
        } @and_node_ids;
        $or_nodes->[$or_node_id] = \@and_node_ids;
    } ## end OR_NODE: for ( my $or_node_id = 0;; $or_node_id++ )

    return $asf;

} ## end sub Marpa::R2::Scanless::ASF::new

sub Marpa::R2::Scanless::ASF::new_choicepoint {
    my ( $asf, $powerset ) = @_;
    my $cp = bless [], 'Marpa::R2::Choicepoint';
    $cp->[Marpa::R2::Internal::Choicepoint::ASF] = $asf;
    $cp->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] = undef;
    $cp->[Marpa::R2::Internal::Choicepoint::POWERSET] = $powerset;
    $cp->[Marpa::R2::Internal::Choicepoint::SYMCH_IX] = 0;
    $cp->[Marpa::R2::Internal::Choicepoint::NID_IX] = 0;
    $cp->[Marpa::R2::Internal::Choicepoint::FACTORING_COUNT] = 0;
    return $cp;
}

sub nidset_to_choicepoint_base {
    my ( $asf, $nidset ) = @_;

    # Memoize this method?

    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];

    my @source_data = ();
    for my $source_nid ( @{ $nidset->nids() } ) {
        my $sort_ix;
        if ( $source_nid >= 0 ) {
            my $irl_id = $bocage->_marpa_b_or_node_irl($source_nid);
            $sort_ix = $grammar_c->_marpa_g_source_xrl($irl_id);
        }
        else {
            my $and_node_id = nid_to_and_node($source_nid);
            my $token_isy_id =
                $bocage->_marpa_b_and_node_symbol($and_node_id);
            my $token_id = $grammar_c->_marpa_g_source_xsy($token_isy_id);
            $sort_ix = -$token_id - 1;
        } ## end else [ if ( $source_nid >= 0 ) ]
        push @source_data, [ $sort_ix, $source_nid ];
    } ## end for my $source_nid ( @{ $nidset->nids() } )
    my @sorted_source_data = sort { $a->[0] <=> $b->[0] } @source_data;
    my $nid_ix = 0;
    my ( $sort_ix_of_this_nid, $this_nid ) =
        @{ $sorted_source_data[ $nid_ix++ ] };
    my @nids_with_current_sort_ix = ();
    my $current_sort_ix           = $sort_ix_of_this_nid;
    my @symch_ids                 = ();
    NID: while (1) {

        if ( $sort_ix_of_this_nid != $current_sort_ix ) {

            # Currently only whole id break logic
            my $nidset_for_sort_ix =
                Marpa::R2::Nidset->obtain( $asf, @nids_with_current_sort_ix );
            push @symch_ids, $nidset_for_sort_ix->id();
            @nids_with_current_sort_ix = ();
            $current_sort_ix           = $sort_ix_of_this_nid;
        } ## end if ( $sort_ix_of_this_nid != $current_sort_ix )
        last NID if not defined $this_nid;
        push @nids_with_current_sort_ix, $this_nid;
        my $sorted_entry = $sorted_source_data[ $nid_ix++ ];
        if ( defined $sorted_entry ) {
            ( $sort_ix_of_this_nid, $this_nid ) = @{$sorted_entry};
            next NID;
        }
        $this_nid            = undef;
        $sort_ix_of_this_nid = -2;
    } ## end NID: while (1)
    return Marpa::R2::Powerset->obtain( $asf, @symch_ids );
} ## end sub nidset_to_choicepoint_base

sub Marpa::R2::Choicepoint::show {
    my ( $cp ) = @_;
    my $id = $cp->base_id();
    return join q{ }, "Choicepoint based on powerset #$id: ",
        $cp->[Marpa::R2::Internal::Choicepoint::POWERSET]->show();
}

# ID of the set on which the choicepoint is based.  Two or more choicepoints
# may share the same base ID.
sub Marpa::R2::Choicepoint::base_id {
    my ( $cp ) = @_;
    return $cp->[Marpa::R2::Internal::Choicepoint::POWERSET]->id();
}

sub Marpa::R2::Choicepoint::symch_count {
    my ( $cp ) = @_;
    return $cp->[Marpa::R2::Internal::Choicepoint::POWERSET]->count();
}

sub Marpa::R2::Choicepoint::symch {
    my ( $cp, $symch_ix ) = @_;
    $symch_ix //= $cp->[Marpa::R2::Internal::Choicepoint::SYMCH_IX];
    my $asf = $cp->[Marpa::R2::Internal::Choicepoint::ASF];
    my $nidset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::NIDSET_BY_ID];
    my $symch_id = $cp->[Marpa::R2::Internal::Choicepoint::POWERSET]->nidset_id($symch_ix);
    return $nidset_by_id->[$symch_id];
}

sub Marpa::R2::Choicepoint::nid {
    my ( $cp, $symch_ix, $nid_ix ) = @_;
    $symch_ix //= $cp->[Marpa::R2::Internal::Choicepoint::SYMCH_IX];
    $nid_ix //= $cp->[Marpa::R2::Internal::Choicepoint::NID_IX];
    my $symch = $cp->symch($symch_ix);
    return if not defined $symch;
    return $symch->nid($nid_ix);
} ## end sub Marpa::R2::Choicepoint::nid

sub Marpa::R2::Choicepoint::symch_set {
    my ( $cp, $ix ) = @_;
    my $max_symch_ix = $cp->symch_count() - 1;
    Marpa::R2::exception("SYMCH index must be in range from 0 to $max_symch_ix")
       if $ix < 0 or $ix > $max_symch_ix;
    $cp->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] = undef;
    $cp->[Marpa::R2::Internal::Choicepoint::FACTORING_COUNT] = 0;
    $cp->[Marpa::R2::Internal::Choicepoint::NID_IX] = 0;
    return $cp->[Marpa::R2::Internal::Choicepoint::SYMCH_IX] = $ix;
}

sub Marpa::R2::Choicepoint::rule_id {
    my ($cp)      = @_;
    my $asf     = $cp->[Marpa::R2::Internal::Choicepoint::ASF];
    my $or_node_id = $cp->nid() // -1;
    return nid_to_whole_id($asf, $or_node_id);
} ## end sub Marpa::R2::Choicepoint::rule_id

# The "whole id" is the external rule ID, if there is one,
# otherwise -1.  In particular, it is -1 is the NID is for
# token
sub nid_to_whole_id {
    my ($asf, $nid) = @_;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage     = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    return -1 if $nid < 0;
    my $irl_id = $bocage->_marpa_b_or_node_irl($nid);
    my $xrl_id = $grammar_c->_marpa_g_source_xrl($irl_id);
    return $xrl_id;
}

sub or_node_es_span {
    my ( $asf, $choicepoint ) = @_;
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce      = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage     = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $origin_es  = $bocage->_marpa_b_or_node_origin($choicepoint);
    my $current_es = $bocage->_marpa_b_or_node_set($choicepoint);
    return $origin_es, $current_es - $origin_es;
} ## end sub or_node_es_span

sub token_es_span {
    my ( $asf, $and_node_id ) = @_;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $predecessor_id = $bocage->_marpa_b_and_node_predecessor($and_node_id);
    my $parent_or_node_id = $bocage->_marpa_b_and_node_parent($and_node_id);

    if (defined $predecessor_id) {
        my $origin_es  = $bocage->_marpa_b_or_node_set($predecessor_id);
        my $current_es = $bocage->_marpa_b_or_node_set($parent_or_node_id);
        return ( $origin_es, $current_es - $origin_es );
    } ## end if ($predecessor_id)
    return or_node_es_span( $asf, $parent_or_node_id );
} ## end sub token_es_span

sub Marpa::R2::Choicepoint::literal {
    my ($cp)    = @_;
    my $nid = $cp->nid();
    my $asf     = $cp->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr     = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    if ( $nid < 0 ) {
        my $and_node_id = nid_to_and_node($nid);
        my ( $start, $length ) = token_es_span( $asf, $and_node_id );
        return q{} if $length == 0;
        return $slr->substring( $start, $length );
    } ## end if ( $nid < 0 )
    return $slr->substring( or_node_es_span( $asf, $nid ) );
} ## end sub Marpa::R2::Choicepoint::literal

sub Marpa::R2::Choicepoint::symbol_id {
    my ($cp)      = @_;
    my $nid_0   = $cp->nid(0);
    my $asf       = $cp->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( $nid_0 < 0 ) {
        my $and_node_id  = nid_to_and_node($nid_0);
        my $token_isy_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
        my $token_id     = $grammar_c->_marpa_g_source_xsy($token_isy_id);
        return $token_id;
    } ## end if ( $nid_0 < 0 )
    my $irl_id = $bocage->_marpa_b_or_node_irl($nid_0);
    my $xrl_id = $grammar_c->_marpa_g_source_xrl($irl_id);
    my $lhs_id = $grammar_c->rule_lhs($xrl_id);
    return $lhs_id;
} ## end sub Marpa::R2::Choicepoint::symbol_id

# Memoization is heavily used -- it needs to be to keep the worst cases from
# going exponential.  The need to memoize is the reason for the very heavy use of
# hashes.  For example, quite often an HOH (hash of hashes) is used where
# an HoL (hash of lists) would usually be preferred.  But the HOL would leave me
# with the problem of having duplicates, which if followed up upon, would make
# the algorithm go exponential.

# For the "seen" hashes, the intent, in C, is to use a bit vector.  Since typically
# choicepoints will only use a tiny fraction of the or- and and-node space, I'll create
# a per-choicepoint index in the bit vector for each or- and and-node.  The index will
# per-ASF, and to avoid the overhead of clearing it, it will track, or each node, the
# current CP indexing it.  It is assumed that the indexes need only remain valid within
# the method call that constructs the CPI (choicepoint iterator).

# Not external -- first_symch() will be the external method.
sub next_factoring {
    my ($choicepoint) = @_;
    say STDERR join q{ }, __FILE__, __LINE__, "next_factoring()",
        $choicepoint->show();
    say STDERR "next_factoring: id=", $choicepoint->base_id(),
        "; symch IX = ",
        $choicepoint->[Marpa::R2::Internal::Choicepoint::SYMCH_IX],
        "; nid IX = ",
        $choicepoint->[Marpa::R2::Internal::Choicepoint::NID_IX];
    my $asf = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $or_nodes = $asf->[Marpa::R2::Internal::Scanless::ASF::OR_NODES];
    $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] //= [];
    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];
    my $factoring_count =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_COUNT];
    my $is_first_factoring_attempt = ( $factoring_count <= 0 );

    $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_COUNT]++;

    # Current NID of current SYMCH
    my $nid_of_choicepoint = $choicepoint->nid();
    say STDERR "next_factoring NID of choicepoint = ", $nid_of_choicepoint;

    my $nidset_by_id =
        $asf->[Marpa::R2::Internal::Scanless::ASF::NIDSET_BY_ID];
    my $powerset_by_id =
        $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID];

    # The caller should ensure that we are never called unless the current
    # NID is for a rule.
    Marpa::exception(
        "Internal error: next_factoring() called for negative NID: $nid_of_choicepoint"
    ) if $nid_of_choicepoint < 0;

    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];

    FACTORING_ATTEMPT: while (1) {
        if ($is_first_factoring_attempt) {

            # Due to skipping, even the top or-node can have no valid choices
            if (not scalar @{$or_nodes->[ $nid_of_choicepoint ]})
            {
                $choicepoint
                    ->[Marpa::R2::Internal::Choicepoint::IS_EXHAUSTED] = 1;
                $choicepoint
                    ->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] =
                    undef;
                return;
            }

            $is_first_factoring_attempt = 0;
            $choicepoint->[Marpa::R2::Internal::Choicepoint::OR_NODE_IN_USE]
                ->{$nid_of_choicepoint} = 1;
            my $nook = nook_new($asf, $nid_of_choicepoint);
            push @{$factoring_stack}, $nook;
        } ## end if ($is_first_factoring_attempt)
        else {
            FIND_NODE_TO_ITERATE: while (1) {
                if ( not scalar @{$factoring_stack} ) {
                    $choicepoint
                        ->[Marpa::R2::Internal::Choicepoint::IS_EXHAUSTED] = 1;
                    $choicepoint
                        ->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK]
                        = undef;
                    return;
                } ## end if ( not scalar @{$factoring_stack} )
                my $top_nook = $factoring_stack->[-1];
                if ( nook_increment($asf, $top_nook) ) {
                    $top_nook->[Marpa::R2::Internal::Nook::CAUSE_IS_EXPANDED]
                        = 1;
                    $top_nook
                        ->[Marpa::R2::Internal::Nook::PREDECESSOR_IS_EXPANDED]
                        = 1;
                    last FIND_NODE_TO_ITERATE;  # in C, a "break" will do this
                } ## end if ( defined $work_and_node_id )

                # Could not iterate
                # "Dirty" the corresponding bits in the parent and pop this nook
                my $stack_ix_of_parent_nook =
                    $top_nook->[Marpa::R2::Internal::Nook::PARENT];
                if ( $stack_ix_of_parent_nook >= 0 ) {
                    my $parent_nook =
                        $factoring_stack->[$stack_ix_of_parent_nook];
                    $parent_nook
                        ->[Marpa::R2::Internal::Nook::CAUSE_IS_EXPANDED] = 0
                        if $top_nook->[Marpa::R2::Internal::Nook::IS_CAUSE];
                    $parent_nook
                        ->[Marpa::R2::Internal::Nook::PREDECESSOR_IS_EXPANDED]
                        = 0
                        if $top_nook
                            ->[Marpa::R2::Internal::Nook::IS_PREDECESSOR];
                } ## end if ( $stack_ix_of_parent_nook >= 0 )

                my $top_or_node =
                    $top_nook->[Marpa::R2::Internal::Nook::OR_NODE];
                $choicepoint
                    ->[Marpa::R2::Internal::Choicepoint::OR_NODE_IN_USE]
                    ->{$top_or_node} = undef;
                pop @{$factoring_stack};
            } ## end FIND_NODE_TO_ITERATE: while (1)
        } ## end else [ if ($is_first_factoring_attempt) ]

        my @worklist = ( 0 .. $#{$factoring_stack} );

        DO_WORKLIST: while ( scalar @worklist ) {
            my $stack_ix_of_work_nook = $worklist[-1];
            my $work_nook = $factoring_stack->[$stack_ix_of_work_nook];
            my $work_or_node =
                $work_nook->[Marpa::R2::Internal::Nook::OR_NODE];
            my $working_choice =
                $work_nook->[Marpa::R2::Internal::Nook::FIRST_CHOICE];
            my $work_and_node_id = $or_nodes->[$work_or_node]->[$working_choice];
            my $child_or_node;
            my $child_is_cause;
            my $child_is_predecessor;
            FIND_CHILD_OR_NODE: {

                if ( !$work_nook
                    ->[Marpa::R2::Internal::Nook::CAUSE_IS_EXPANDED] )
                {
                    if ( not nook_has_semantic_cause( $asf, $work_nook ) ) {
                        $child_or_node =
                            $bocage->_marpa_b_and_node_cause(
                            $work_and_node_id);
                        $child_is_cause = 1;
                        last FIND_CHILD_OR_NODE;
                    } ## end if ( not nook_has_semantic_cause( $asf, $work_nook ...))
                } ## end if ( !$work_nook->[...])
                $work_nook->[Marpa::R2::Internal::Nook::CAUSE_IS_EXPANDED] =
                    1;
                if ( !$work_nook
                    ->[Marpa::R2::Internal::Nook::PREDECESSOR_IS_EXPANDED] )
                {
                    $child_or_node =
                        $bocage->_marpa_b_and_node_predecessor(
                        $work_and_node_id);
                    if ( defined $child_or_node ) {
                        $child_is_predecessor = 1;
                        last FIND_CHILD_OR_NODE;
                    }
                } ## end if ( !$work_nook->[...])
                $work_nook
                    ->[Marpa::R2::Internal::Nook::PREDECESSOR_IS_EXPANDED] =
                    1;
                pop @worklist;
                next DO_WORKLIST;
            } ## end FIND_CHILD_OR_NODE:

            next FACTORING_ATTEMPT
                if $choicepoint
                    ->[Marpa::R2::Internal::Choicepoint::OR_NODE_IN_USE]
                    ->{$child_or_node};

            next FACTORING_ATTEMPT
                if not scalar @{ $or_nodes->[ $work_or_node ] };

            my $new_nook = nook_new( $asf, $child_or_node , $stack_ix_of_work_nook);
            if ($child_is_cause) {
                $new_nook->[Marpa::R2::Internal::Nook::IS_CAUSE] = 1;
                $work_nook->[Marpa::R2::Internal::Nook::CAUSE_IS_EXPANDED] =
                    1;
            }
            if ($child_is_predecessor) {
                $new_nook->[Marpa::R2::Internal::Nook::IS_PREDECESSOR] = 1;
                $work_nook
                    ->[Marpa::R2::Internal::Nook::PREDECESSOR_IS_EXPANDED] =
                    1;
            } ## end if ($child_is_predecessor)
            push @{$factoring_stack}, $new_nook;
            push @worklist, $#{$factoring_stack};

        } ## end DO_WORKLIST: while ( scalar @worklist )

        return 1;

    } ## end FACTORING_ATTEMPT: while (1)
} ## end sub next_factoring

sub factors {
    my ($choicepoint) = @_;
    my $asf           = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr           = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce         = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar       = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c     = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage        = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $or_nodes = $asf->[Marpa::R2::Internal::Scanless::ASF::OR_NODES];

    my @result;
    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];
    return if not $factoring_stack;
    FACTOR:
    for (
        my $factor_ix = 0;
        $factor_ix <= $#{$factoring_stack};
        $factor_ix++
        )
    {
        my $nook = $factoring_stack->[$factor_ix];
        next FACTOR if not nook_has_semantic_cause( $asf, $nook );
        my %causes    = ();
        my $or_node   = $nook->[Marpa::R2::Internal::Nook::OR_NODE];
        my $and_nodes = $or_nodes->[$or_node];
        for my $and_node_ix ( $nook->[Marpa::R2::Internal::Nook::FIRST_CHOICE]
            .. $nook->[Marpa::R2::Internal::Nook::LAST_CHOICE] )
        {
            my $and_node_id = $and_nodes->[$and_node_ix];
            my $cause_nid   = $bocage->_marpa_b_and_node_cause($and_node_id)
                // and_node_to_nid($and_node_id);
            $causes{$cause_nid} = 1;
        } ## end for my $and_node_ix ( $nook->[...])
        my $choicepoint_nidset =
            Marpa::R2::Nidset->obtain( $asf, keys %causes );
        my $choicepoint_base =
            nidset_to_choicepoint_base( $asf, $choicepoint_nidset );
        my $new_choicepoint = $asf->new_choicepoint($choicepoint_base);
        push @result, $new_choicepoint;
    } ## end for ( my $factor_ix = 0; $factor_ix <= $#{$factoring_stack...})
    return \@result;
} ## end sub factors

# Internal?
# Return the size of the choicepoint ambiguous prefix.
# This is the last point in the factoring stack with an ambiguity.
# if the choicepoint is ambiguous, it is greater than 0.
# If the choicepoint is unambiguous, it is always 0.
# The concept of "point in the factoring stack" is internal.
sub Marpa::R2::Choicepoint::ambiguous_prefix {
    my ($choicepoint) = @_;
    my $asf = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $or_nodes = $asf->[Marpa::R2::Internal::Scanless::ASF::OR_NODES];
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];
    Marpa::R2::exception('ASF choicepoint factoring was never initialized')
        if not defined $factoring_stack;
    my $stack_pos = $#{$factoring_stack};
    STACK_POS: while ( $stack_pos >= 0 ) {
        my $nook =  $factoring_stack->[$stack_pos];
        my $or_node = $nook->[Marpa::R2::Internal::Nook::OR_NODE];
        last STACK_POS if scalar @{ $or_nodes->[$or_node] } > 1;
        $stack_pos--;
    } ## end STACK_POS: while ( $stack_pos >= 0 )
    return $stack_pos + 1;
} ## end sub Marpa::R2::Choicepoint::ambiguous_prefix

sub Marpa::R2::Scanless::ASF::show_nidsets {
    my ($asf) = @_;
    my $text = q{};
    my $nidsets = $asf->[Marpa::R2::Internal::Scanless::ASF::NIDSET_BY_ID];
    for my $nidset (grep { defined } @{$nidsets}) {
        $text .= $nidset->show() . "\n";
    }
    return $text;
}

sub Marpa::R2::Scanless::ASF::show_powersets {
    my ($asf) = @_;
    my $text = q{};
    my $powersets = $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID];
    for my $powerset (grep { defined } @{$powersets}) {
        $text .= $powerset->show() . "\n";
    }
    return $text;
}

# CHOICEPOINT_SEEN is a local -- this is to silence warnings
our %CHOICEPOINT_SEEN;

sub Marpa::R2::Choicepoint::show_nids {
    my ( $choicepoint, $parent_choice ) = @_;
    my $id = $choicepoint->base_id();
    if ($CHOICEPOINT_SEEN{$id}) {
        return ["CP$id already displayed"];
    }
    $CHOICEPOINT_SEEN{$id} = 1;
    say STDERR join q{ }, __FILE__, __LINE__, ("show_nids($id, " . ($parent_choice // 'top') . ')'), $choicepoint->show();
    $parent_choice .= q{.} if defined $parent_choice;
    $parent_choice //= q{};

    # Check if choicepoint already seen?
    my $asf         = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr         = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce       = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar     = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my @lines = ();

    my $symch_count = $choicepoint->symch_count();
    for ( my $symch_ix = 0; $symch_ix < $symch_count; $symch_ix++ ) {
        $choicepoint->symch_set($symch_ix);
        my $current_choice = "$parent_choice$symch_ix";
        push @lines, "CP$id SYMCH #$current_choice: " if $symch_count > 1;
        my $rule_id = $choicepoint->rule_id();
        if ( $rule_id >= 0 ) {
            say STDERR "LINE: ", ( "CP$id Rule " . $grammar->brief_rule($rule_id) );
            push @lines,
            ( "CP$id Rule " . $grammar->brief_rule($rule_id) ),
                map { q{  } . $_ }
                @{ $choicepoint->show_factorings( $current_choice ) };
        }
        else {
            push @lines,
                @{ $choicepoint->show_symch_tokens( $current_choice ) };
        }
    }
    return \@lines;
} ## end sub Marpa::R2::Choicepoint::show_nids

# Show all the factorings of a SYMCH
sub Marpa::R2::Choicepoint::show_factorings {
    my ( $choicepoint, $parent_choice ) = @_;
    say STDERR join q{ }, __FILE__, __LINE__, "show_factorings()",
        $choicepoint->show();
    $parent_choice .= q{.} if defined $parent_choice;
    $parent_choice //= q{};

    # Check if choicepoint already seen?
    my $asf     = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr     = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce   = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my @lines;

    my $symch     = $choicepoint->symch();
    my $nid_count = $symch->count();
    my $factor_ix = 0;
    for ( my $nid_ix = 0; $nid_ix < $nid_count; $nid_ix++ ) {
        $choicepoint->[Marpa::R2::Internal::Choicepoint::NID_IX] = $nid_ix;

        next_factoring($choicepoint);
        my $factoring = factors($choicepoint);

        my $factoring_is_ambiguous = ($nid_count > 1) || $choicepoint->ambiguous_prefix();
        FACTOR: while (defined $factoring ) {
            my $current_choice = "$parent_choice$factor_ix";
            my $indent         = q{};
            if ($factoring_is_ambiguous) {
                say STDERR "LINE: ", "Factoring #$current_choice";
                push @lines, "Factoring #$current_choice";
                $indent = q{  };
            }
            for my $choicepoint ( @{$factoring} ) {
                push @lines,
                    map { $indent . $_ }
                    @{ $choicepoint->show_nids($current_choice) };
            } ## end for my $choicepoint ( @{$factoring} )
            next_factoring($choicepoint);
            $factoring = factors($choicepoint);
            $factor_ix++;
        } ## end FACTOR: for ( my $factor_ix = 0; defined $factoring; ...)
    } ## end for ( my $nid_ix = 0; $nid_ix < $nid_count; $nid_ix++)
    return \@lines;
} ## end sub Marpa::R2::Choicepoint::show_factorings

# Show all the tokens of a SYMCH
sub Marpa::R2::Choicepoint::show_symch_tokens {
    my ( $choicepoint, $parent_choice ) = @_;
    say STDERR join q{ }, __FILE__, __LINE__, "show_symch_tokens()",
        $choicepoint->show();
    my $id = $choicepoint->base_id();
    $parent_choice .= q{.} if defined $parent_choice;
    $parent_choice //= q{};

    # Check if choicepoint already seen?
    my $asf     = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr     = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce   = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my @lines;

    my $symch     = $choicepoint->symch();
    my $nid_count = $symch->count();
    for ( my $nid_ix = 0; $nid_ix < $nid_count; $nid_ix++ ) {
        $choicepoint->[Marpa::R2::Internal::Choicepoint::NID_IX] = $nid_ix;
        my $symbol_id   = $choicepoint->symbol_id();
        my $literal     = $choicepoint->literal();
        my $symbol_name = $grammar->symbol_name($symbol_id);
        say STDERR "LINE: ", qq{CP$id Symbol: $symbol_name "$literal"};
        push @lines, qq{CP$id Symbol: $symbol_name "$literal"};
    } ## end for ( my $nid_ix = 0; $nid_ix < $nid_count; $nid_ix++)
    return \@lines;
} ## end sub Marpa::R2::Choicepoint::show_symch_tokens

sub Marpa::R2::Scanless::ASF::show {
    my ($asf) = @_;
    my $top = $asf->top();
    local %CHOICEPOINT_SEEN = (); ## no critic (Variables::ProhibitLocalVars)
    my $lines = $top->show_nids ();
    return join "\n", @{$lines}, q{};
}

1;

# vim: expandtab shiftwidth=4:
