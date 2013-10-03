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

our %choicepoint_seen;

# Terms
#
# Symchset -- A set of symches, all with the same start and end locations.
#
# Choicepoint -- A symchset which is reachable from the top choicepoint.
# Choicepoints can be internal or external.
#
# Factoring -- one possible factoring of an external choicepoint.  It is a sequence
# of factors.
#
# Factor -- A list of choicepoints.
#
# Symch (Symbolic choice) -- An or-node or a terminal
#

# This is more complicated that it needs to be for the current implementation.
# It allows for LHS terminals (implemented in Libmarpa but not allowed by the SLIF).
# It also assumes that every or-node which can be constructed from preceding or-nodes
# and the input will be present.  This is currently the case, but in the future
# rules and/or symbols may have extra-syntactic conditions attached making this
# assumption false.

sub Marpa::R2::Symchset::obtain {
    my ($class, $asf, @symch_ids) = @_;
    my @sorted_symchset = sort { $a <=> $b } @symch_ids;
    my $key = join q{ }, @sorted_symchset;
    say STDERR "Obtaining symchset for key $key";
    my $symchset_by_key =
        $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_KEY];
    my $symchset = $symchset_by_key->{$key};
    return $symchset if defined $symchset;
    $symchset = bless [], $class;
    my $id = $asf->[Marpa::R2::Internal::Scanless::ASF::NEXT_SYMCHSET_ID]++;
    $symchset->[Marpa::R2::Internal::Symchset::ID] = $id;
    $symchset->[Marpa::R2::Internal::Symchset::SYMCHES] = \@sorted_symchset;
    $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_KEY]->{$key} = $symchset;
    $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_ID]->[$id] = $symchset;
    return $symchset;
}

sub Marpa::R2::Symchset::symch_ids {
    my ($symchset) = @_;
    return $symchset->[Marpa::R2::Internal::Symchset::SYMCHES];
}

sub Marpa::R2::Symchset::symch {
    my ($symchset, $ix) = @_;
    return $symchset->[Marpa::R2::Internal::Symchset::SYMCHES]->[$ix];
}

sub Marpa::R2::Symchset::count {
    my ($symchset) = @_;
    return scalar @{$symchset->[Marpa::R2::Internal::Symchset::SYMCHES]};
}

sub Marpa::R2::Symchset::id {
    my ($symchset) = @_;
    return $symchset->[Marpa::R2::Internal::Symchset::ID];
}

sub Marpa::R2::Symchset::show {
    my ($symchset) = @_;
    my $id = $symchset->id();
    my $symch_ids = $symchset->symch_ids();
    return "Symchset #$id: " . join q{ }, @{$symch_ids};
}

sub Marpa::R2::Powerset::obtain {
    my ($class, $asf, @symchset_ids) = @_;
    my @sorted_symchset_ids = sort { $a <=> $b } @symchset_ids;
    my $key = join q{ }, @sorted_symchset_ids;
    my $powerset_by_key =
        $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_KEY];
    my $powerset = $powerset_by_key->{$key};
    return $powerset if defined $powerset;
    $powerset = bless [], $class;
    my $id = $asf->[Marpa::R2::Internal::Scanless::ASF::NEXT_POWERSET_ID]++;
    $powerset->[Marpa::R2::Internal::Powerset::ID] = $id;
    $powerset->[Marpa::R2::Internal::Powerset::SYMCHSET_IDS] = \@sorted_symchset_ids;
    $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_KEY]->{$key} = $powerset;
    $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID]->[$id] = $powerset;
    return $powerset;
}

sub Marpa::R2::Powerset::symchset_ids {
    my ($powerset) = @_;
    return $powerset->[Marpa::R2::Internal::Powerset::SYMCHSET_IDS];
}

sub Marpa::R2::Powerset::count {
    my ($powerset) = @_;
    return scalar @{$powerset->[Marpa::R2::Internal::Powerset::SYMCHSET_IDS]};
}

sub Marpa::R2::Powerset::symchset_id {
    my ($powerset, $ix) = @_;
    my $symchset_ids = $powerset->[Marpa::R2::Internal::Powerset::SYMCHSET_IDS];
    return if $ix > $#{$symchset_ids};
    return $powerset->[Marpa::R2::Internal::Powerset::SYMCHSET_IDS]->[$ix];
}

sub Marpa::R2::Powerset::id {
    my ($powerset) = @_;
    return $powerset->[Marpa::R2::Internal::Powerset::ID];
}

sub Marpa::R2::Powerset::show {
    my ($powerset) = @_;
    my $id = $powerset->id();
    my $symchset_ids = $powerset->symchset_ids();
    return "Powerset #$id: " . join q{ }, @{$symchset_ids};
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
    die "No Bocage" if not $bocage;
    my $augment_or_node_id = $bocage->_marpa_b_top_or_node();
    my $augment_and_node_id =
        $bocage->_marpa_b_or_node_first_and($augment_or_node_id);
    my $augment2_or_node_id =
        $bocage->_marpa_b_and_node_cause($augment_and_node_id);
    my @symch_set;
    AND_NODE:
    for my $augment2_and_node_id (
        $bocage->_marpa_b_or_node_first_and($augment2_or_node_id)
        .. $bocage->_marpa_b_or_node_last_and($augment2_or_node_id) )
    {
        my $cause_id =
            $bocage->_marpa_b_and_node_cause($augment2_and_node_id);
        if ( defined $cause_id ) {
            push @symch_set, $cause_id;
            next AND_NODE;
        }
        push @symch_set, and_node_to_token_symch($augment2_and_node_id);
    } ## end AND_NODE: for my $augment2_and_node_id ( $bocage...)
    my $top_symchset = Marpa::R2::Symchset->obtain( $asf, @symch_set );
    $top = $asf->new_choicepoint($top_symchset);
    $asf->[Marpa::R2::Internal::Scanless::ASF::TOP] = $top;
    return $top;
} ## end sub Marpa::R2::Scanless::ASF::top

sub make_token_cp { return -($_[0] + 43); }
sub unmake_token_cp { return -$_[0] - 43; }

# Range from -1 to -42 reserved for special values
sub and_node_to_token_symch { return -$_[0] - 43; }
sub token_symch_to_and_node { return -$_[0] - 43; }

sub normalize_asf_blessing {
    my ($name) = @_;
    $name =~ s/\A \s * //xms;
    $name =~ s/ \s * \z//xms;
    $name =~ s/ \s+ / /gxms;
    $name =~ s/ [^\w] /_/gxms;
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
        if ( '::' ne substr $blessing, 0, 2 ) {
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
        if ( '::' ne substr $blessing, 0, 2 ) {
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

    my $choice_blessing = 'My_ASF::choice';
    my $force;
    my $default_blessing;
    my $slr;

    for my $args (@arg_hashes) {
        if ( defined( my $value = $args->{slr} ) ) {
            $asf->[Marpa::R2::Internal::Scanless::ASF::SLR] = $slr = $value;
        }
        if ( defined( my $value = $args->{choice} ) ) {
    $asf->[Marpa::R2::Internal::Scanless::ASF::CHOICE_BLESSING] =
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

    if ( not defined $force and not defined $default_blessing ) {
        Marpa::R2::exception(
            q{The "force" or "default" named argument must be specified },
            q{ with the Marpa::R2::Scanless::ASF::new method }
        );
    } ## end if ( not defined $force and not defined $default_blessing)

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

    $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_ID] = [];
    $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_KEY] = {};
    $asf->[Marpa::R2::Internal::Scanless::ASF::NEXT_SYMCHSET_ID] = 0;
    $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID] = [];
    $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_KEY] = {};
    $asf->[Marpa::R2::Internal::Scanless::ASF::NEXT_POWERSET_ID] = 0;

    my $slg       = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr  = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];

    $recce->ordering_create()
        if not $recce->[Marpa::R2::Internal::Recognizer::O_C];

    blessings_set($asf, $default_blessing, $force);

    return $asf;

} ## end sub Marpa::R2::Scanless::ASF::new

sub Marpa::R2::Scanless::ASF::new_choicepoint {
    my ( $asf, $symchset ) = @_;
    my $cpi = bless [], 'Marpa::R2::Choicepoint';
    $cpi->[Marpa::R2::Internal::Choicepoint::ASF] = $asf;
    $cpi->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] = undef;
    $cpi->[Marpa::R2::Internal::Choicepoint::SYMCHSET] = $symchset;
    $cpi->[Marpa::R2::Internal::Choicepoint::SYMCH_IX] = 0;
    return $cpi;
}

sub Marpa::R2::Choicepoint::show {
    my ( $cp ) = @_;
    my $id = $cp->id();
    return join q{ }, "Choicepoint #$id:", 
        @{$cp->[Marpa::R2::Internal::Choicepoint::SYMCHSET]->symch_ids()};
}

sub Marpa::R2::Choicepoint::id {
    my ( $cp ) = @_;
    return $cp->[Marpa::R2::Internal::Choicepoint::SYMCHSET]->id();
}

sub Marpa::R2::Choicepoint::symch_count {
    my ( $cp ) = @_;
    return $cp->[Marpa::R2::Internal::Choicepoint::SYMCHSET]->count();
}

sub Marpa::R2::Choicepoint::symch {
    my ( $cp, $ix ) = @_;
    my $symch_ix = $ix // $cp->[Marpa::R2::Internal::Choicepoint::SYMCH_IX];
    say STDERR "symch_ix=$symch_ix ", $cp->show();
    return $cp->[Marpa::R2::Internal::Choicepoint::SYMCHSET]->symch_ids()->[$symch_ix];
}

sub Marpa::R2::Choicepoint::symch_set {
    my ( $cp, $ix ) = @_;
    my $max_symch_ix = $cp->symch_count() - 1;
    Marpa::R2::exception("Symch index must in range from 0 to $max_symch_ix")
       if $ix < 0 or $ix > $max_symch_ix;
    $cp->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] = undef;
    return $cp->[Marpa::R2::Internal::Choicepoint::SYMCH_IX] = $ix;
}

sub Marpa::R2::Choicepoint::rule_id {
    my ($cp)      = @_;
    my $asf       = $cp->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage     = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $or_node_id = $cp->symch() // -1;
    say STDERR "or_node_id=$or_node_id ", $cp->show();
    return if $or_node_id < 0;
    my $irl_id = $bocage->_marpa_b_or_node_irl($or_node_id);
    my $xrl_id = $grammar_c->_marpa_g_source_xrl($irl_id);
    return $xrl_id;
} ## end sub Marpa::R2::Choicepoint::rule_id

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
    my $symch = $cp->symch();
    my $asf     = $cp->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr     = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    if ( $symch < 0 ) {
        my $and_node_id = token_symch_to_and_node($symch);
        my ( $start, $length ) = token_es_span( $asf, $and_node_id );
        return '' if $length == 0;
        return $slr->substring( $start, $length );
    } ## end if ( $symch < 0 )
    return $slr->substring( or_node_es_span( $asf, $symch ) );
} ## end sub Marpa::R2::Choicepoint::literal

sub Marpa::R2::Choicepoint::symbol_id {
    my ($cp)      = @_;
    my $symch_0   = $cp->symch(0);
    my $asf       = $cp->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( $symch_0 < 0 ) {
        my $and_node_id  = token_symch_to_and_node($symch_0);
        my $token_isy_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
        my $token_id     = $grammar_c->_marpa_g_source_xsy($token_isy_id);
        return $token_id;
    } ## end if ( $symch_0 < 0 )
    my $irl_id = $bocage->_marpa_b_or_node_irl($symch_0);
    my $xrl_id = $grammar_c->_marpa_g_source_xrl($irl_id);
    my $lhs_id = $grammar_c->rule_lhs($xrl_id);
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

sub Marpa::R2::Choicepoint::first_factoring {
    my ( $choicepoint ) = @_;
    my $asf = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    say STDERR join q{ }, __FILE__, __LINE__, "first_factoring()", $choicepoint->show();
    my $symch = $choicepoint->symch();

    my $symchset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_ID];

    # return undef if we were passed a symch which is not
    # an or-node
    return if $symch < 0;

    my $slr = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $ordering  = $recce->[Marpa::R2::Internal::Recognizer::O_C];

    my %predecessors = ();

    # Find symch of "finals" -- symches which can be last in the external
    # rule.
    my @finals;
    my @stack = ( $symch );
    my %or_node_seen = ( $symch => 1 );
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
                push @finals, and_node_to_token_symch($and_node_id);
                say STDERR "Adding ", and_node_to_token_symch($and_node_id), " to final symches";
		next AND_NODE;
            }
	    next STACK_ELEMENT if $or_node_seen{$cause_id};
	    $or_node_seen{$cause_id} = 1;
            if ( $bocage->_marpa_b_or_node_is_semantic($cause_id) ) {
                push @finals, $cause_id;
                say STDERR "Adding $cause_id to final symches";
		next AND_NODE;
            }
	    push @stack, $cause_id;
        } ## end for my $and_node_id ( $ordering...)
    } ## end STACK_ELEMENT: while ( defined( my $stack_element = pop @stack ) )
    my $final_symchset = Marpa::R2::Symchset->obtain( $asf, @finals );

    # Find the direct predecessors of each cause or-node,
    # and the "internal completions" -- or-nodes for internal rules
    # completed in the current checkpoint
    @stack     = ($symch);
    my @internal_completions = ();
    %or_node_seen = ($symch => 1);
    STACK_ELEMENT: while ( defined( my $or_node = pop @stack ) ) {

        AND_NODE: for my $and_node_id (
            $ordering->_marpa_o_or_node_and_node_ids($or_node) )
        {
            my $predecessor_id =
                $bocage->_marpa_b_and_node_predecessor($and_node_id);
            my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
            if ( not defined $cause_id ) {
                $cause_id = and_node_to_token_symch($and_node_id);
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
        my @stack            = ($complete_or_node_id);
        OR_NODE_ID: while ( defined( my $or_node_id = pop @stack ) ) {
            for my $and_node_id (
                $ordering->_marpa_o_or_node_and_node_ids($or_node_id) )
            {
                my $predecessor_id =
                    $bocage->_marpa_b_and_node_predecessor($and_node_id);
                if ( defined $predecessor_id ) {

                    # If a predecessor, and it has not been stacked, stack
                    # it to be followed looking for initial causes
                    if ( not $predecessor_seen{$predecessor_id} ) {
                        push @stack, $predecessor_id;
                        $predecessor_seen{$predecessor_id} = 1;
                    }
                    next OR_NODE_ID;
                } ## end if ( defined $predecessor_id )

                # If here, no predecessor, and the cause will be an initial cause
                # for this $complete_or_node_id
                my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
                if ( not defined $cause_id ) {
                    $cause_id = and_node_to_token_symch($and_node_id);
                }
                if ( not $initial_seen{$cause_id} ) {
                    push @initials, $cause_id;
                    $initial_seen{$cause_id}++;
                }
            } ## end for my $and_node_id ( $ordering...)

        } ## end OR_NODE_ID: while ( defined( my $or_node_id = pop @stack ) )

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
                    { and_node_to_token_symch($and_node_id) } = 1;
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

    my %symch_to_prior_symchset = ();
    for my $successor_cause_id ( sort keys %prior_cause ) {
        my @predecessors = keys %{ $prior_cause{$successor_cause_id} };
        my $prior_symchset = Marpa::R2::Symchset->obtain( $asf, @predecessors );
        $symch_to_prior_symchset{$successor_cause_id} = $prior_symchset;
    }

    say STDERR '%symch_to_prior_symchset = ', Data::Dumper::Dumper( \%symch_to_prior_symchset);

    my %symchset_to_powerset = ();
    my %symchset_ids_to_do = map { $_->id() => 1 } ($final_symchset, values %symch_to_prior_symchset );
    SYMCHSET: for my $symchset_id ( sort keys %symchset_ids_to_do ) {
        my @sorted_symch_ids =
            map  { $_->[-1] }
            sort { $a->[0] <=> $b->[0] }
            map  { ; [ ( $symch_to_prior_symchset{$_} // -1 ), $_ ] }
            @{ $symchset_by_id->[$symchset_id]->symch_ids() };
        my $symch_ix            = 0;
        my $this_symch          = $sorted_symch_ids[ $symch_ix++ ];
        my $prior_of_this_symch = $symch_to_prior_symchset{$this_symch} // -1;
        my @symch_ids_with_current_prior = ();
        my $current_prior                = $prior_of_this_symch;
        my @choicepoints                 = ();
        SYMCH: while (1) {

            CHECK_FOR_BREAK: {
                if ( defined $this_symch
                    and $prior_of_this_symch == $current_prior )
                {
                    push @symch_ids_with_current_prior, $this_symch;
                    last CHECK_FOR_BREAK;
                } ## end if ( defined $this_symch and $prior_of_this_symch ==...)

                # perform break on prior
                my $choicepoint = Marpa::R2::Symchset->obtain( $asf,
                    @symch_ids_with_current_prior );
                push @choicepoints, $choicepoint->id();
                last SYMCH if not defined $this_symch;
                @symch_ids_with_current_prior = ($this_symch);
                $current_prior                = $prior_of_this_symch;
            } ## end CHECK_FOR_BREAK:
            $this_symch = $sorted_symch_ids[ $symch_ix++ ];
            next SYMCH if not defined $this_symch;
            $prior_of_this_symch = $symch_to_prior_symchset{$this_symch}
                // -1;
        } ## end SYMCH: while (1)
        my $powerset = Marpa::R2::Powerset->obtain( $asf, @choicepoints );
        $symchset_to_powerset{$symchset_id} = $powerset;
    } ## end SYMCHSET: for my $symchset_id ( sort keys %symchset_ids_to_do )

    my %symch_set_to_prior_powerset = ();
    for my $powerset ( sort values %symchset_to_powerset ) {
        CHOICEPOINT: for my $symchset_id ( @{$powerset->symchset_ids()} ) {
            next CHOICEPOINT if $symch_set_to_prior_powerset{$symchset_id};
            my $symchset = $symchset_by_id->[$symchset_id];
            my $symch_id          = $symchset->symch_ids()->[0];
            my $prior_symchset    = $symch_to_prior_symchset{$symch_id};
            next CHOICEPOINT if not defined $prior_symchset;
            my $prior_symchset_id = $prior_symchset->id();
            $symch_set_to_prior_powerset{$symchset_id} =
                $symchset_to_powerset{$prior_symchset_id};
        }
    }

    my $final_powerset = $symchset_to_powerset{ $final_symchset->id() };
    my @factoring_stack = ( [ $final_powerset, 0 ] );

    $choicepoint->[Marpa::R2::Internal::Choicepoint::SYMCHSET_TO_PRIOR_POWERSET] =
        \%symch_set_to_prior_powerset;
    $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] =
        \@factoring_stack;
    return finish_stack($choicepoint);
}

sub finish_stack {
    my ($choicepoint) = @_;
    my $asf = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $symchset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_ID];
    my $symch_set_to_prior_powerset = $choicepoint
        ->[Marpa::R2::Internal::Choicepoint::SYMCHSET_TO_PRIOR_POWERSET];
    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];

    my ( $top_powerset, $top_symchset_ix ) = @{ $factoring_stack->[-1] };
    my $current_symchset_id = $top_powerset->symchset_id($top_symchset_ix);
    FACTOR: while ( defined $current_symchset_id ) {
        my $prior_powerset = $symch_set_to_prior_powerset->{$current_symchset_id};
        last FACTOR if not defined $prior_powerset;
        push @{$factoring_stack}, [ $prior_powerset, 0 ];
        $current_symchset_id = $prior_powerset->symchset_id(0);
    }

    say STDERR '%symch_set_to_prior_powerset = ', Data::Dumper::Dumper( $symch_set_to_prior_powerset);

    my @return_value = ();
    for my $stack_element ( reverse @{$factoring_stack} ) {
        my ( $powerset, $ix ) = @{$stack_element};
        my $symchset_id = $powerset->symchset_id($ix);
        my $symchset = $symchset_by_id->[$symchset_id];
        push @return_value, $asf->new_choicepoint($symchset);
    }
    return \@return_value;

} ## end sub finish_stack

sub Marpa::R2::Choicepoint::next_factoring {
    my ($choicepoint) = @_;
    say STDERR join q{ }, __FILE__, __LINE__, "next_factoring()", $choicepoint->show();
    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];
    Marpa::R2::exception("ASF choicepoint is not initialized for factoring")
        if not defined $factoring_stack;
    my $symch_set_to_prior_powerset =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::SYMCHSET_TO_PRIOR_POWERSET];

    # pop stack until we can increment an element
    STACK_ELEMENT:
    while ( defined( my $stack_element = pop @{$factoring_stack} ) )
    {
        my ( $powerset, $symchset_ix ) = @{$stack_element};
        $symchset_ix++;
        if ( defined $powerset->symchset_id($symchset_ix) ) {
            push @{$factoring_stack}, [ $powerset, $symchset_ix ];
            return finish_stack($choicepoint);
        }
    } ## end STACK_ELEMENT: while ( defined( my $stack_element = pop @{...}))

    # if we could not increment any stack element, clear the factoring data
    # and return undef
    $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK] = undef;
    $choicepoint->[Marpa::R2::Internal::Choicepoint::SYMCHSET_TO_PRIOR_POWERSET] =
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
    my $symchset_by_id = $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_ID];
    my $factoring_stack =
        $choicepoint->[Marpa::R2::Internal::Choicepoint::FACTORING_STACK];
    Marpa::R2::exception("ASF choicepoint is not initialized for factoring")
        if not defined $factoring_stack;
    my $stack_pos = $#{$factoring_stack};
    STACK_POS: while ( $stack_pos >= 0 ) {
        my ( $powerset, $symchset_ix ) = @{ $factoring_stack->[$stack_pos] };
        last STACK_POS if $powerset->count() > 1;
        my $symchset_id = $powerset->symchset_id($symchset_ix);
        my $symchset = $symchset_by_id->[$symchset_id];
        last STACK_POS if $symchset->count() > 1;
        $stack_pos--;
    } ## end STACK_POS: while ( $stack_pos >= 0 )
    return $stack_pos + 1;
} ## end sub Marpa::R2::Choicepoint::ambiguous_prefix

sub Marpa::R2::Scanless::ASF::show_symchsets {
    my ($asf) = @_;
    my $text = q{};
    my $symchsets = $asf->[Marpa::R2::Internal::Scanless::ASF::SYMCHSET_BY_ID];
    for my $symchset (@{$symchsets}) {
        $text .= $symchset->show() . "\n";
    }
    return $text;
}

sub Marpa::R2::Scanless::ASF::show_powersets {
    my ($asf) = @_;
    my $text = q{};
    my $powersets = $asf->[Marpa::R2::Internal::Scanless::ASF::POWERSET_BY_ID];
    for my $powerset (@{$powersets}) {
        $text .= $powerset->show() . "\n";
    }
    return $text;
}

sub Marpa::R2::Choicepoint::show_symches {
    my ( $choicepoint, $parent_choice ) = @_;
    my $id = $choicepoint->id();
    say STDERR join q{ }, __FILE__, __LINE__, "show_symches(choicepoint=#$id)";
    say STDERR join q{ }, __FILE__, __LINE__, $choicepoint->show();
    if ($choicepoint_seen{$id}) {
        $parent_choice = '"Top"' if not defined $parent_choice;
        say STDERR join q{ }, __FILE__, __LINE__, "SEEN:", $choicepoint->show();
        return ["Choicepoint $parent_choice already displayed"];
    }
    $choicepoint_seen{$id} = 1;
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
        say STDERR join q{ }, __FILE__, __LINE__, '$symch_ix =', $symch_ix;
        my $current_choice = "$parent_choice$symch_ix";
        push @lines, "Symch #$current_choice: " if $symch_count > 1;
        my $rule_id = $choicepoint->rule_id();
        say STDERR join q{ }, __FILE__, __LINE__, '$rule_id =', ($rule_id // 'undef');
        if ( defined $rule_id ) {
            push @lines,
            ( 'Rule ' . $grammar->brief_rule($rule_id) ),
                map { q{  } . $_ }
                @{ $choicepoint->show_factorings( $current_choice ) };
        }
        else {
            my $symbol_id = $choicepoint->symbol_id();
            my $literal = $choicepoint->literal();
            my $symbol_name = $grammar->symbol_name($symbol_id);
            push @lines, qq{Symbol: $symbol_name "$literal"};
        }
    } ## end for ( my $symch_ix = 0; $symch_ix < $symch_count; $symch_ix...)
    return \@lines;
} ## end sub Marpa::R2::Choicepoint::show_symches

sub Marpa::R2::Choicepoint::show_factorings {
    my ( $choicepoint, $parent_choice ) = @_;
    say STDERR join q{ }, __FILE__, __LINE__, "show_factorings()", $choicepoint->show();
    $parent_choice .= q{.} if defined $parent_choice;
    $parent_choice //= q{};

    # Check if choicepoint already seen?
    my $asf       = $choicepoint->[Marpa::R2::Internal::Choicepoint::ASF];
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my @lines;

    my $factoring = $choicepoint->first_factoring();

    my $ambiguous_prefix = $choicepoint->ambiguous_prefix();
    say STDERR join q{ }, __FILE__, __LINE__, "ambiguous_prefix=$ambiguous_prefix", $choicepoint->show();
    FACTOR: for ( my $factor_ix = 0; defined $factoring; $factor_ix++ ) {
        my $current_choice = "$parent_choice$factor_ix";
        my $indent = q{};
        if ($ambiguous_prefix) {
            push @lines, "Factoring #$current_choice";
            $indent = q{  };
        }
        for my $choicepoint ( @{$factoring} ) {
            say STDERR join q{ }, __FILE__, __LINE__, $choicepoint->show();
            push @lines, map { $indent . $_ } @{$choicepoint->show_symches( $current_choice )};
        }
        $factoring = $choicepoint->next_factoring();
    } ## end FACTOR: for ( my $factor_ix = 0; defined $factoring; $factor_ix...)
    return \@lines;
} ## end sub Marpa::R2::Choicepoint::show_factorings

sub Marpa::R2::Scanless::ASF::show {
    my ($asf) = @_;
    my $top = $asf->top();
    local %choicepoint_seen = ();
    my $lines = $top->show_symches ();
    return join "\n", @{$lines}, q{};
}

1;

# vim: expandtab shiftwidth=4:
