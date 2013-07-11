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
$VERSION        = '2.063_002';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

# The code in this file, for now, breaks "the rules".  It makes use
# of internal methods not documented as part of Libmarpa.
# It is intended to create documented Libmarpa methods to underlie
# this interface, and rewrite it to use them

package Marpa::R2::Internal::ASF;

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::R2::Internal::Scanless::ASF

    SLR { The underlying SLR }
    CHOICE_BLESSING
    RULE_BLESSING
    SYMBOL_BLESSING
    CHOICEPOINT_IS_FACTORED

END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN

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
            $next_choice = [ -1, $and_node_id ];
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
                ref $_
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
        die "No parse" if not defined $bocage;
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
    return \or_node_expand( $recce, $start_rcp );
} ## end sub Marpa::R2::Scanless::ASF::raw_asf

sub bless_asf {
    my ( $asf, $tree, $data ) = @_;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $tag       = $tree->[0];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( $tag == -1 ) {
        my ( undef, $and_node_id ) = @{$tree};
        my $token_isy_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
        my $token_id     = $grammar_c->_marpa_g_source_xsy($token_isy_id);
        my $symbol_blessing =
            $asf->[Marpa::R2::Internal::Scanless::ASF::SYMBOL_BLESSING]
            ->[$token_id];
        return bless [
            -1, ( 'Token: ' . $asf->cp_token_name($tree) ),
            $and_node_id, $asf->cp_literal($tree)
        ], $symbol_blessing;
    } ## end if ( $tag == -1 )
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
    my $augment_and_node_id =
        $bocage->_marpa_b_or_node_first_and($augment_or_node_id);
    my $augment2_or_node_id =
        $bocage->_marpa_b_and_node_cause($augment_and_node_id);
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
    if ( ref $or_child ) {

        # switch the parent in for the or-node
        my ( undef, $and_node_id ) = @{$or_child};
        $or_child = $bocage->_marpa_b_and_node_parent($and_node_id);
    } ## end if ( ref $or_child )
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
            if ( ref $child ) {
                my ( undef, $and_node_id ) = @{$child};
                push @tags, "A$and_node_id";
                next CHOICE;
            }
            push @tags, $child;
        } ## end CHOICE: for my $choice_ix ( 0 .. ${$choices} )
        my %seen = ();
        TAG: for my $tag ( grep { !$seen{$_}++ } @tags ) {
            if ( ( substr $tag, 0, 1 ) eq 'A' ) {
                push @{ $choices_by_rhs[$child_ix] },
                    [ -1, 0 + ( substr $tag, 1 ) ];
                next TAG;
            }
            push @{ $choices_by_rhs[$child_ix] }, $tag + 0;
        } ## end for my $tag ( grep { !$seen{$_} } @tags )
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
            next CHILD if ref $choice_0_child;
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
            next CHILD if ref $child;
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
    if (ref $cp) {
        my (undef, $and_node_id) = @{$cp};
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
    return or_node_es_span($asf, $cp) if not ref $cp;
    my ( undef, $and_node_id ) = @{$cp};
    return token_es_span( $asf, $and_node_id );
}

sub Marpa::R2::Scanless::ASF::cp_rule_id {
    my ( $asf, $choicepoint ) = @_;
    return undef if ref $choicepoint;
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
    return undef if ref $choicepoint;
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $irl_id    = $bocage->_marpa_b_or_node_irl($choicepoint);
    my $rule_id   = $grammar_c->_marpa_g_source_xrl($irl_id);
    return $grammar->rule($rule_id);
} ## end sub Marpa::R2::Scanless::ASF::cp_rule_id

sub Marpa::R2::Scanless::ASF::cp_token_name {
    my ( $asf, $cp ) = @_;
    return undef if not ref $cp;
    my ( undef, $and_node_id ) = @{$cp};
    my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $token_isy_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
    my $token_id     = $grammar_c->_marpa_g_source_xsy($token_isy_id);
    return $grammar->symbol_name($token_id);
}

sub Marpa::R2::Scanless::ASF::cp_brief {
    my ( $asf, $cp ) = @_;
    return $asf->cp_token_name($cp) if ref $cp;
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
    if ( ref $cp ) {
        my ( undef, $and_node_id ) = @{$cp};
        my $slr       = $asf->[Marpa::R2::Internal::Scanless::ASF::SLR];
        my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
        my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
        my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
        my $token_isy_id = $bocage->_marpa_b_and_node_symbol($and_node_id);
        my $token_id     = $grammar_c->_marpa_g_source_xsy($token_isy_id);
        return $asf->[Marpa::R2::Internal::Scanless::ASF::SYMBOL_BLESSING]
            ->[$token_id];
    } ## end if ( ref $cp )
    my $rule_id = $asf->cp_rule_id($cp);
    return $asf->[Marpa::R2::Internal::Scanless::ASF::RULE_BLESSING]
        ->[$rule_id];
} ## end sub Marpa::R2::Scanless::ASF::cp_blessing

1;

# vim: expandtab shiftwidth=4:
