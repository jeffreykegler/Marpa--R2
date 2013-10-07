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
    my $key = join q{ }, sort @ids;
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

sub Marpa::R2::Pow3set::obtain {
    my ($class, $asf, @powerset_ids) = @_;
    my $id = intset_id($asf, @powerset_ids);
    my $pow3set_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::POW3SET_BY_ID];
    my $pow3set = $pow3set_by_id->[$id];
    return $pow3set if defined $pow3set;
    $pow3set = bless [], $class;
    $pow3set->[Marpa::R2::Internal::Pow3set::ID] = $id;
    $pow3set->[Marpa::R2::Internal::Pow3set::POWERSET_IDS] = [ sort { $a <=> $b } @powerset_ids ];
    $pow3set_by_id->[$id] = $pow3set;
    return $pow3set;
}

sub Marpa::R2::Pow3set::powerset_ids {
    my ($pow3set) = @_;
    return $pow3set->[Marpa::R2::Internal::Pow3set::POWERSET_IDS];
}

sub Marpa::R2::Pow3set::count {
    my ($pow3set) = @_;
    return scalar @{$pow3set->[Marpa::R2::Internal::Pow3set::POWERSET_IDS]};
}

sub Marpa::R2::Pow3set::powerset_id {
    my ($pow3set, $ix) = @_;
    my $powerset_ids = $pow3set->[Marpa::R2::Internal::Pow3set::POWERSET_IDS];
    return if $ix > $#{$powerset_ids};
    return $pow3set->[Marpa::R2::Internal::Pow3set::POWERSET_IDS]->[$ix];
}

sub Marpa::R2::Pow3set::id {
    my ($pow3set) = @_;
    return $pow3set->[Marpa::R2::Internal::Pow3set::ID];
}

sub Marpa::R2::Pow3set::show {
    my ($pow3set) = @_;
    my $id = $pow3set->id();
    my $powerset_ids = $pow3set->powerset_ids();
    return "Pow3set #$id: " . join q{ }, @{$powerset_ids};
}

# No check for conflicting usage -- value(), asf(), etc.
# at this point
sub Marpa::R2::Scanless::ASF::top {
    my ($asf) = @_;
    my $top = $asf->[Marpa::R2::Internal::Scanless::ASF::TOP];
    return $top if defined $top;
    my $slr   = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    die 'No Bocage' if not $bocage;
    my $augment_or_node_id = $bocage->_marpa_b_top_or_node();
    my $augment_and_node_id =
        $bocage->_marpa_b_or_node_first_and($augment_or_node_id);
    my $augment2_or_node_id =
        $bocage->_marpa_b_and_node_cause($augment_and_node_id);
    my @nid_set;
    AND_NODE:

    for my $augment2_and_node_id (
        $bocage->_marpa_b_or_node_first_and($augment2_or_node_id)
        .. $bocage->_marpa_b_or_node_last_and($augment2_or_node_id) )
    {
        my $cause_id =
            $bocage->_marpa_b_and_node_cause($augment2_and_node_id);
        if ( defined $cause_id ) {
            push @nid_set, $cause_id;
            next AND_NODE;
        }
        push @nid_set, and_node_to_nid($augment2_and_node_id);
    } ## end AND_NODE: for my $augment2_and_node_id ( $bocage...)
    my $flat_nidset = Marpa::R2::Nidset->obtain( $asf, @nid_set );
    my $top_factorset = nidset_to_factorset( $asf, $flat_nidset, {} );
    my $top_powerset_id = $top_factorset->powerset_id(0);
    my $top_powerset = $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID]->[$top_powerset_id];
    $top = $asf->new_choicepoint($top_powerset);
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
    $asf->[Marpa::R2::Internal::Scanless::ASF::POW3SET_BY_ID] = [];

    my $slg       = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr  = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];

    $recce->ordering_create()
        if not $recce->[Marpa::R2::Internal::Recognizer::O_C];

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
    return $cp;
}

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

sub nidset_to_factorset {
    my ( $asf, $nidset, $nid_to_prior_nidset ) = @_;
    my $nidset_id = $nidset->id();
    my @sorted_nids =
        map { $_->[-1] }
        sort { $a->[0] <=> $b->[0] or $a->[1] <=> $b->[1] } map {
        ;
        [ ( $nid_to_prior_nidset->{$_} // -1 ), nid_to_whole_id($asf, $_), $_ ]
        } @{ $nidset->nids() };
    my $nid_ix                 = 0;
    my $this_nid               = $sorted_nids[ $nid_ix++ ];
    my $prior_of_this_nid      = $nid_to_prior_nidset->{$this_nid} // -1;
    my $whole_id_of_this_nid   = nid_to_whole_id( $asf, $this_nid );
    my @nids_with_current_whole_id = ();
    my @symches_with_current_priors = ();
    my $current_prior          = $prior_of_this_nid;
    my $current_whole_id       = $whole_id_of_this_nid;
    my @choicepoint_ids           = ();
    NID: while (1) {

        my $prior_nidset_break;
        $prior_nidset_break = 1 if not defined $this_nid;
        $prior_nidset_break = 1 if $prior_of_this_nid != $current_prior;
        my $whole_id_break;
        $whole_id_break = 1 if $whole_id_of_this_nid != $current_whole_id;
        $whole_id_break = 1 if $prior_nidset_break;
        if ($whole_id_break) {

            # Currently only whole id break logic
            my $nidset_for_whole_id = Marpa::R2::Nidset->obtain( $asf,
                @nids_with_current_whole_id );
            push @symches_with_current_priors, $nidset_for_whole_id->id();
            @nids_with_current_whole_id = ();
            $current_whole_id           = $whole_id_of_this_nid;
        } ## end if ($whole_id_break)
        if ($prior_nidset_break) {

            # Currently only whole id break logic
            my $choicepoint = Marpa::R2::Powerset->obtain( $asf,
                @symches_with_current_priors );
            push @choicepoint_ids, $choicepoint->id();
            last NID if not defined $this_nid;
            @symches_with_current_priors = ();
            $current_prior               = $prior_of_this_nid;
        } ## end if ($prior_nidset_break)
        push @nids_with_current_whole_id, $this_nid;
        $this_nid = $sorted_nids[ $nid_ix++ ];
        if ( defined $this_nid ) {
            $prior_of_this_nid = $nid_to_prior_nidset->{$this_nid} // -1;
            $whole_id_of_this_nid = nid_to_whole_id( $asf, $this_nid );
            next NID;
        }

        # -2 indicates 'end of data'
        $prior_of_this_nid    = -2;
        $whole_id_of_this_nid = -2;
    } ## end NID: while (1)
    my $pow3set = Marpa::R2::Pow3set->obtain( $asf, @choicepoint_ids );
    return $pow3set;
} ## end sub nidset_to_factorset

# Not external -- first_symch will be.
sub first_factoring {
    my ( $choicepoint ) = @_;
    my $asf = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];

    # Current NID of current SYMCH
    my $nid_of_choicepoint = $choicepoint->nid();

    my $nidset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::NIDSET_BY_ID];
    my $powerset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID];

    # The caller should ensure that we are never called unless the current
    # NID is for a rule.
    Marpa::exception(
        "Internal error: first_factoring() called for negative NID: $nid_of_choicepoint")
        if $nid_of_choicepoint < 0;

    my $slr = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $ordering  = $recce->[Marpa::R2::Internal::Recognizer::O_C];

    my %predecessors = ();

    # Find nid of "finals" -- nids which can be last in the external
    # rule.
    my @finals;
    my @stack = ( $nid_of_choicepoint );
    my %or_node_seen = ( $nid_of_choicepoint => 1 );
    STACK_ELEMENT: while ( defined( my $or_node = pop @stack ) ) {
        say STDERR "Popped or-node $or_node";
        say STDERR "Count of and-nodes for or-node $or_node: ", $ordering->_marpa_o_or_node_and_node_count($or_node);
        say STDERR "And-nodes for or-node $or_node: ", join " ", $ordering->_marpa_o_or_node_and_node_ids($or_node);

        AND_NODE: for my $and_node_id (
            $ordering->_marpa_o_or_node_and_node_ids($or_node) )
        {
            say STDERR "Looking for finals in and-node $and_node_id";
            my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
            if ( not defined $cause_id ) {
                push @finals, and_node_to_nid($and_node_id);
		next AND_NODE;
            }
	    next STACK_ELEMENT if $or_node_seen{$cause_id};
	    $or_node_seen{$cause_id} = 1;
            if ( $bocage->_marpa_b_or_node_is_semantic($cause_id) ) {
                push @finals, $cause_id;
		next AND_NODE;
            }
	    push @stack, $cause_id;
        } ## end for my $and_node_id ( $ordering...)
    } ## end STACK_ELEMENT: while ( defined( my $stack_element = pop @stack ) )
    my $final_nidset = Marpa::R2::Nidset->obtain( $asf, @finals );

    # Find the direct predecessors of each cause or-node,
    # and the "internal completions" -- or-nodes for internal rules
    # completed in the current checkpoint
    @stack     = ($nid_of_choicepoint);
    my @internal_completions = ();
    %or_node_seen = ($nid_of_choicepoint => 1);
    STACK_ELEMENT: while ( defined( my $or_node = pop @stack ) ) {

        AND_NODE: for my $and_node_id (
            $ordering->_marpa_o_or_node_and_node_ids($or_node) )
        {
            my $predecessor_id =
                $bocage->_marpa_b_and_node_predecessor($and_node_id);
            my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
            if ( not defined $cause_id ) {
                $cause_id = and_node_to_nid($and_node_id);
            }
            if ( defined $predecessor_id ) {
                say STDERR "predecessor of $cause_id is $predecessor_id";
                $predecessors{$cause_id}{$predecessor_id} = 1;
                if ( not $or_node_seen{$predecessor_id} ) {
                    push @stack, $predecessor_id;
                    $or_node_seen{$predecessor_id} = 1;
                }
            }
            next AND_NODE if $cause_id < 0;
            next AND_NODE if $bocage->_marpa_b_or_node_is_semantic($cause_id);
            next AND_NODE if $or_node_seen{$cause_id};
            $or_node_seen{$cause_id} = 1;
            push @stack,     $cause_id;
            push @internal_completions, $cause_id;
        } ## end for my $and_node_id ( $ordering...)
    } ## end STACK_ELEMENT: while ( defined( my $or_node = pop @stack ) )

    say STDERR '%predecessors = ', Data::Dumper::Dumper( \%predecessors);

    # Find the predecessors which cross internal rule boundaries,
    # but that connect cause and predecessor for an external rule.
    # This is a separate pass, to save the overhead of tracking the whole or-node ID
    # for each predecessor -- a single predecessor can be in the predecessor chain
    # of more than one complete ("whole") or-node.
    # In this pass we deal with one "whole" at a time, and do not have to track
    # them on a stack.
    @stack = ();
    for my $complete_or_node_id (@internal_completions) {
        my @initials = ();

        # We do not have to mark the whole id's as "seen", because dups were
        # prevented above, and only predecessors are stacked below.  No predecessor
        # is ever identical to a whole id.
        my %predecessor_seen = ();
        my %initial_seen     = ();
        my @inner_stack            = ($complete_or_node_id);
        OR_NODE_ID: while ( defined( my $or_node_id = pop @inner_stack ) ) {
            for my $and_node_id (
                $ordering->_marpa_o_or_node_and_node_ids($or_node_id) )
            {
                my $predecessor_id =
                    $bocage->_marpa_b_and_node_predecessor($and_node_id);
                if ( defined $predecessor_id ) {

                    # If a predecessor, and it has not been stacked, stack
                    # it to be followed looking for initial causes
                    if ( not $predecessor_seen{$predecessor_id} ) {
                        push @inner_stack, $predecessor_id;
                        $predecessor_seen{$predecessor_id} = 1;
                    }
                    next OR_NODE_ID;
                } ## end if ( defined $predecessor_id )

                # If here, no predecessor, and the cause will be an initial cause
                # for this $complete_or_node_id
                my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
                if ( not defined $cause_id ) {
                    $cause_id = and_node_to_nid($and_node_id);
                }
                if ( not $initial_seen{$cause_id} ) {
                    push @initials, $cause_id;
                    $initial_seen{$cause_id}++;
                }
            } ## end for my $and_node_id ( $ordering...)

        } ## end OR_NODE_ID: while ( defined( my $or_node_id = pop @inner_stack ) )

        my @predecessors_of_completion = keys %{ $predecessors{$complete_or_node_id} };
        for my $initial_cause (@initials) {
            $predecessors{$initial_cause}{$_} = 1 for @predecessors_of_completion;
        }

    } ## end for my $complete_or_node_id (@internal_completions)

    # Find the semantics causes for each predecessor
    my %semantic_cause = ();
    my %and_node_seen = ();

    # This re-initializes a stack to a list of or-nodes whose cause's should be examined,
    # recursively, until a semantic or-node or a terminal is found.
    my %predecessors_to_do = ();
    $predecessors_to_do{$_} = 1 for map { ; keys %{$_} } values %predecessors;
    for my $predecessor_id ( sort keys %predecessors_to_do ) {

        # Not the most efficient Perl implementation -- intended for conversion to C
        # Outer seen, for predecessors, can be bit vector
        # Inner seen, for and_nodes, must be array to track current predecessor,
        #   because and-node is "seen" only if seen FOR THIS PREDECESSOR
        my @and_node_stack = ();
        my %inner_seen     = ();
        for my $and_node_id (
            $ordering->_marpa_o_or_node_and_node_ids($predecessor_id) )
        {
            next AND_NODE
                if ( $inner_seen{$and_node_id} // -1 ) == $predecessor_id;
            $inner_seen{$and_node_id} = $predecessor_id;
            push @and_node_stack, $and_node_id;
        } ## end for my $and_node_id ( $ordering...)
        AND_NODE: while ( defined( my $and_node_id = pop @and_node_stack ) ) {
            my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
            if ( not defined $cause_id ) {
                $semantic_cause{$predecessor_id}
                    { and_node_to_nid($and_node_id) } = 1;
                next AND_NODE;
            }
            if ( $bocage->_marpa_b_or_node_is_semantic($cause_id) ) {
                $semantic_cause{$predecessor_id}{$cause_id} = 1;
                next AND_NODE;
            }
            INNER_AND_NODE:
            for my $inner_and_node_id (
                $ordering->_marpa_o_or_node_and_node_ids($cause_id) )
            {
                next INNER_AND_NODE
                    if ( $inner_seen{$inner_and_node_id} // -1 )
                    == $predecessor_id;
                $inner_seen{$inner_and_node_id} = $predecessor_id;
                push @and_node_stack, $inner_and_node_id;
            } ## end INNER_AND_NODE: for my $inner_and_node_id ( $ordering...)
        } ## end AND_NODE: while ( defined( my $and_node_id = pop @and_node_stack...))
    } ## end for my $predecessor_id ( keys %predecessors_to_do )

    my %prior_cause = ();
    for my $cause_id ( keys %predecessors ) {
        for my $predecessor_id ( keys %{ $predecessors{$cause_id} } )
        {
            for my $prior_cause_id (
                keys %{ $semantic_cause{$predecessor_id} } )
            {
                $prior_cause{$cause_id}{$prior_cause_id} = 1;
            }
        } ## end for my $predecessor_id ( keys %{ $predecessors...})
    } ## end for my $cause_id ( keys %predecessors )

    my %nid_to_prior_nidset = ();
    for my $successor_cause_id ( sort keys %prior_cause ) {
        my @predecessors = keys %{ $prior_cause{$successor_cause_id} };
        my $prior_nidset = Marpa::R2::Nidset->obtain( $asf, @predecessors );
        $nid_to_prior_nidset{$successor_cause_id} = $prior_nidset;
    }

    my %nidset_to_factorset = ();
    my %nidset_ids_to_do = map { $_->id() => 1 } ($final_nidset, values %nid_to_prior_nidset );
    my @nidset_ids_to_do = sort { $a <=> $b } keys %nidset_ids_to_do;
    $nidset_to_factorset{$_} = nidset_to_factorset($asf, $nidset_by_id->[$_], \%nid_to_prior_nidset)
        for @nidset_ids_to_do;

    my %powerset_to_prior_factorset = ();
    for my $nidset_id (@nidset_ids_to_do) {
        my $factorset = $nidset_to_factorset{$nidset_id};
        CHOICEPOINT: for my $powerset_id ( @{ $factorset->powerset_ids() } ) {
            next CHOICEPOINT if $powerset_to_prior_factorset{$powerset_id};
            my $powerset     = $powerset_by_id->[$powerset_id];
            my $nidset_id    = $powerset->nidset_id(0);
            my $nidset       = $nidset_by_id->[$nidset_id];
            my $nid          = $nidset->nid(0);
            my $prior_nidset = $nid_to_prior_nidset{$nid};
            next CHOICEPOINT if not defined $prior_nidset;
            my $prior_nidset_id = $prior_nidset->id();
            $powerset_to_prior_factorset{$powerset_id} =
                $nidset_to_factorset{$prior_nidset_id};
        } ## end CHOICEPOINT: for my $powerset_id ( @{ $factorset->powerset_ids() ...})
    } ## end for my $nidset_id (@nidset_ids_to_do)

    my $final_factorset = $nidset_to_factorset{ $final_nidset->id() };
    my @factoring_stack = ( [ $final_factorset, 0 ] );

    say STDERR '%powerset_to_prior_factorset = ', Data::Dumper::Dumper( \%powerset_to_prior_factorset);
    say STDERR '%final_factorset = ', Data::Dumper::Dumper( $final_factorset);
    $choicepoint->[Marpa::R2::Internal::Choicepoint::POWERSET_TO_PRIOR_FACTORSET] =
        \%powerset_to_prior_factorset;
    $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] =
        \@factoring_stack;
    return finish_stack($choicepoint);
}

sub finish_stack {
    my ($choicepoint) = @_;
    my $asf = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $powerset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID];
    my $powerset_to_prior_factorset = $choicepoint
        ->[Marpa::R2::Internal::Choicepoint::POWERSET_TO_PRIOR_FACTORSET];
    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];

    my ( $top_factorset, $top_powerset_ix ) = @{ $factoring_stack->[-1] };
    my $current_powerset_id = $top_factorset->powerset_id($top_powerset_ix);
    POS: while ( defined $current_powerset_id ) {
        my $prior_factorset = $powerset_to_prior_factorset->{$current_powerset_id};
        last POS if not defined $prior_factorset;
        push @{$factoring_stack}, [ $prior_factorset, 0 ];
        $current_powerset_id = $prior_factorset->powerset_id(0);
    }

    my @return_value = ();
    for my $stack_element ( reverse @{$factoring_stack} ) {
        my ( $factorset, $powerset_ix ) = @{$stack_element};
        my $powerset_id = $factorset->powerset_id($powerset_ix);
        my $powerset = $powerset_by_id->[$powerset_id];
        push @return_value, $asf->new_choicepoint($powerset);
    }
    return \@return_value;

} ## end sub finish_stack

sub Marpa::R2::Choicepoint::next_factoring {
    my ($choicepoint) = @_;
    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];
    Marpa::R2::exception('ASF choicepoint is not initialized for factoring')
        if not defined $factoring_stack;
    my $powerset_to_prior_factorset =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::POWERSET_TO_PRIOR_FACTORSET];

    # pop stack until we can increment an element
    STACK_ELEMENT:
    while ( defined( my $stack_element = pop @{$factoring_stack} ) )
    {
        my ( $factorset, $powerset_ix ) = @{$stack_element};
        $powerset_ix++;
        if ( defined $factorset->powerset_id($powerset_ix) ) {
            push @{$factoring_stack}, [ $factorset, $powerset_ix ];
            return finish_stack($choicepoint);
        }
    } ## end STACK_ELEMENT: while ( defined( my $stack_element = pop @{...}))

    # if we could not increment any stack element, clear the factoring data
    # and return undef
    $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] = undef;
    $choicepoint->[Marpa::R2::Internal::Choicepoint::POWERSET_TO_PRIOR_FACTORSET] =
        undef;
    return;
} ## end sub Marpa::R2::Choicepoint::next_factoring

# Return the size of the choicepoint ambiguous prefix.
# This ranges from 1 to the length of the rule,
# if the choicepoint is ambiguous.
# If the choicepoint is unambiguous, it is always 0.
sub Marpa::R2::Choicepoint::ambiguous_prefix {
    my ($choicepoint) = @_;
    my $asf = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $nidset_by_id =
        $asf->[Marpa::R2::Internal::Scanless::ASF::NIDSET_BY_ID];
    my $powerset_by_id =
        $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID];
    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];
    Marpa::R2::exception('ASF choicepoint is not initialized for factoring')
        if not defined $factoring_stack;
    my $stack_pos = $#{$factoring_stack};
    STACK_POS: while ( $stack_pos >= 0 ) {
        my ( $factorset, $powerset_ix ) = @{ $factoring_stack->[$stack_pos] };
        last STACK_POS if $factorset->count() > 1;
        my $powerset_id = $factorset->powerset_id(0);
        my $powerset = $powerset_by_id->[$powerset_id];
        last STACK_POS if $powerset->count() > 1;
        my $nidset_id = $powerset->nidset_id(0);
        my $nidset = $nidset_by_id->[$nidset_id];
        last STACK_POS if $nidset->count() > 1;
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

sub Marpa::R2::Scanless::ASF::show_pow3sets {
    my ($asf) = @_;
    my $text = q{};
    my $pow3sets = $asf->[Marpa::R2::Internal::Scanless::ASF::POW3SET_BY_ID];
    for my $pow3set (grep { defined } @{$pow3sets}) {
        $text .= $pow3set->show() . "\n";
    }
    return $text;
}

# CHOICEPOINT_SEEN is a local -- this is to silence warnings
our %CHOICEPOINT_SEEN;

sub Marpa::R2::Choicepoint::show_nids {
    my ( $choicepoint, $parent_choice ) = @_;
    my $id = $choicepoint->base_id();
    if ($CHOICEPOINT_SEEN{$id}) {
        $parent_choice = '"Top"' if not defined $parent_choice;
        return ["CP$id already displayed"];
    }
    $CHOICEPOINT_SEEN{$id} = 1;
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
        say STDERR join q{ }, __FILE__, __LINE__, '$rule_id =', ($rule_id // 'undef');
        if ( $rule_id >= 0 ) {
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
    for ( my $nid_ix = 0; $nid_ix < $nid_count; $nid_ix++ ) {
        $choicepoint->[Marpa::R2::Internal::Choicepoint::NID_IX] = $nid_ix;

        my $factoring = first_factoring($choicepoint);

        my $ambiguous_prefix = $choicepoint->ambiguous_prefix();
        say STDERR join q{ }, __FILE__, __LINE__,
            "ambiguous_prefix=$ambiguous_prefix", $choicepoint->show();
        FACTOR: for ( my $factor_ix = 0; defined $factoring; $factor_ix++ ) {
            my $current_choice = "$parent_choice$factor_ix";
            my $indent         = q{};
            if ($ambiguous_prefix) {
                push @lines, "Factoring #$current_choice";
                $indent = q{  };
            }
            for my $choicepoint ( @{$factoring} ) {
                say STDERR join q{ }, __FILE__, __LINE__,
                    $choicepoint->show();
                push @lines,
                    map { $indent . $_ }
                    @{ $choicepoint->show_nids($current_choice) };
            } ## end for my $choicepoint ( @{$factoring} )
            $factoring = $choicepoint->next_factoring();
        } ## end FACTOR: for ( my $factor_ix = 0; defined $factoring; ...)
    } ## end for ( my $nid_ix = 0; $nid_ix < $nid_count; $nid_ix++)
    return \@lines;
} ## end sub Marpa::R2::Choicepoint::show_factorings

# Show all the tokens of a SYMCH
sub Marpa::R2::Choicepoint::show_symch_tokens {
    my ( $choicepoint, $parent_choice ) = @_;
    my $id = $choicepoint->base_id();
    say STDERR join q{ }, __FILE__, __LINE__, "show_symch_tokens()",
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
    for ( my $nid_ix = 0; $nid_ix < $nid_count; $nid_ix++ ) {
        $choicepoint->[Marpa::R2::Internal::Choicepoint::NID_IX] = $nid_ix;
        my $symbol_id   = $choicepoint->symbol_id();
        my $literal     = $choicepoint->literal();
        my $symbol_name = $grammar->symbol_name($symbol_id);
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
