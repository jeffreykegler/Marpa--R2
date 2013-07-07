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

sub Marpa::R2::Scanless::R::asf_init {

    my ( $slr, @arg_hashes ) = @_;
    my $slg       = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr  = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $choice_blessing = 'My_ASF::choice';
    my $force;

    for my $args (@arg_hashes) {
        if ( defined( my $value = $args->{choice} ) ) {
                $choice_blessing = $value;
        }
        if ( defined( my $value = $args->{force} ) ) {
            $force = $value;
        }
    } ## end for my $args (@arg_hashes)

    Marpa::R2::exception(
        q{The "force" named argument must be specified with the $slr->asf() method}
    ) if not defined $force;

    my @rule_blessing   = ();
    my $highest_rule_id = $grammar_c->highest_rule_id();
    for ( my $rule_id = 0; $rule_id <= $highest_rule_id; $rule_id++ ) {
        my $lhs_id = $grammar_c->rule_lhs($rule_id);
        my $name   = Marpa::R2::Grammar::original_symbol_name(
            $grammar->symbol_name($lhs_id) );
        $rule_blessing[$rule_id] = join q{::}, $force,
            normalize_asf_blessing($name);
    } ## end for ( my $rule_id = 0; $rule_id <= $highest_rule_id; ...)
    my @symbol_blessing   = ();
    my $highest_symbol_id = $grammar_c->highest_symbol_id();
    for ( my $symbol_id = 0; $symbol_id <= $highest_symbol_id; $symbol_id++ )
    {
        my $name = Marpa::R2::Grammar::original_symbol_name(
            $grammar->symbol_name($symbol_id) );
        $symbol_blessing[$symbol_id] = join q{::}, $force,
            normalize_asf_blessing($name);
    } ## end for ( my $symbol_id = 0; $symbol_id <= $highest_symbol_id...)
    return (\@rule_blessing, \@symbol_blessing, $choice_blessing);

} ## end sub Marpa::R2::Scanless::R::asf_init

sub Marpa::R2::Scanless::R::raw_asf {
    my ( $slr ) = @_;
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $start_or_node_id = $slr->top_choicepoint();
    return \or_node_expand( $recce, $start_or_node_id );
} ## end sub Marpa::R2::Scanless::R::asf

sub bless_asf {
    my ( $slr, $asf, $data ) = @_;
    my $tag = $asf->[0];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( $tag == -1 ) {
        my ( undef, $and_node_id ) = @{$asf};
        my $token_isy_id    = $bocage->_marpa_b_and_node_symbol($and_node_id);
        my $token_id        = $grammar_c->_marpa_g_source_xsy($token_isy_id);
        my $token_name      = $grammar->symbol_name($token_id);
        my $symbol_blessing = $data->{symbol_blessings}->[$token_id];
        return bless [
            -1,           "Token: $token_name",
            $and_node_id, $slr->token_literal($and_node_id)
        ], $symbol_blessing;
    } ## end if ( $tag == -1 )
    if ( $tag >= 0 ) {
        my ( $checkpoint_id, @children ) = @{$asf};
        my $blessed_node = $data->{blessed_nodes}->[$checkpoint_id];
        return $blessed_node if defined $blessed_node;
        my $irl_id        = $bocage->_marpa_b_or_node_irl($checkpoint_id);
        my $xrl_id        = $grammar_c->_marpa_g_source_xrl($irl_id);
        my $desc = 'Rule ' . $grammar->brief_rule($xrl_id);
        my $rule_blessing = $data->{rule_blessings}->[$xrl_id];
        $blessed_node =
            bless [ $checkpoint_id, $desc,
            map { bless_asf( $slr, $_, $data ) } @children ],
            $rule_blessing;
        $data->{blessed_nodes}->[$checkpoint_id] = $blessed_node;
        return $blessed_node;
    } ## end if ( $tag >= 0 )
    if ( $tag == -2 ) {
        my ( $tag, $checkpoint_id, @choices ) = @{$asf};
        my $blessed_node = $data->{blessed_nodes}->[$checkpoint_id];
        return $blessed_node if defined $blessed_node;
        my $irl_id          = $bocage->_marpa_b_or_node_irl($checkpoint_id);
        my $xrl_id          = $grammar_c->_marpa_g_source_xrl($irl_id);
        my $desc = 'Rule ' . $grammar->brief_rule($xrl_id);
        my $rule_blessing   = $data->{rule_blessings}->[$xrl_id];
        my @blessed_choices = ();
        for my $choice (@choices) {
            push @blessed_choices,
                bless [ map { bless_asf( $slr, $_, $data ) } @{$choice} ],
                $rule_blessing;
        }
        $blessed_node = bless [ -2, $checkpoint_id, $desc, @blessed_choices ],
            $data->{choice_blessing};
        $data->{blessed_nodes}->[$checkpoint_id] = $blessed_node;
        return $blessed_node;
    } ## end if ( $tag == -1 )
    die "Unknown tag in bless_asf: $tag";
} ## end sub bless_asf

sub Marpa::R2::Scanless::R::bless_asf {
    my ( $slr, $asf, @arg_hashes ) = @_;
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my %data = ();
    ($data{rule_blessings}, $data{symbol_blessings}, $data{choice_blessing}) = $slr->asf_init(@arg_hashes);
    $data{blessed_nodes} = [];
    bless_asf($slr, $asf, \%data);
}

# No check for conflicting usage -- value(), asf(), etc.
# at this point
sub Marpa::R2::Scanless::R::top_choicepoint {
    my ($slr)   = @_;
    my $recce   = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if ( not $bocage ) {
        my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
        my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
        my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
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
} ## end sub Marpa::R2::Scanless::R::top_choicepoint

sub Marpa::R2::Scanless::R::choices {
    my ( $slr, $choicepoint ) = @_;
    my $recce = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    return choices( $recce, $choicepoint );
}

sub token_es_span {
    my ( $slr, $and_node_id ) = @_;
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
    return or_node_es_span( $slr, $parent_or_node_id );
} ## end sub token_es_span

sub or_child_current_set {
    my ( $slr, $or_child, $data ) = @_;
    my $recce   = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    if (ref $or_child) {
        # switch the parent in for the or-node
        my (undef, $and_node_id) = @{$or_child};
        $or_child = $bocage->_marpa_b_and_node_parent($and_node_id);
    }
    return $bocage->_marpa_b_or_node_set($or_child);
}

sub asf_ambiguities {
    my ( $slr, $choicepoint_id, $data ) = @_;
    my $was_node_seen = $data->{was_node_seen};
    return if $was_node_seen->[$choicepoint_id];
    $was_node_seen->[$choicepoint_id] = 1;
    my $recce   = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $choices = $slr->choices($choicepoint_id);
    my $is_node_ambiguous = $data->{is_node_ambiguous};
    my $last_choice_ix    = $#{$choices};

    if ( $last_choice_ix > 0 ) {
        my $choice_0 = $choices->[0];
        $is_node_ambiguous->[$choicepoint_id] = 1;
        my $choice_0_last_child_ix = $#{$choice_0};
        for my $choice_ix ( 1 .. $last_choice_ix ) {
            my $choice                 = $choices->[$choice_ix];
            my $choice_n_last_child_ix = $#{$choice};
            return if $choice_0_last_child_ix != $choice_n_last_child_ix;
        }

        # If here, all choices have the same child count
        # For every medial location (that is, current child location,
        # except for # the last child).
        for my $child_ix ( 1 .. $choice_0_last_child_ix ) {
            die("Not yet implemented");
            my $choice_0_medial =
                or_child_current_set( $choice_0->[$child_ix] );
            for my $choice_ix ( 1 .. $last_choice_ix ) {
                my $child = $choices->[$choice_ix]->[$child_ix];
                return if $choice_0_medial != or_child_current_set($child);
            }
        } ## end for my $child_ix ( 1 .. $choice_0_last_child_ix )
    } ## end if ( $last_choice_ix > 0 )

    for my $choice ( @{$choices} ) {
        CHILD: for my $child ( @{$choice} ) {
            next CHILD if ref $child;
            asf_ambiguities( $slr, $child, $data );
        }
    } ## end for my $choice ( @{$choices} )
} ## end sub asf_ambiguities

# Return a list of ambiguous checkpoint ID's.
# Once an ambiguity is found, its subtree is not explored further.
sub Marpa::R2::Scanless::R::asf_ambiguities {
    my ( $slr, $asf, @arg_hashes ) = @_;
    my %data = ();
    my $is_node_ambiguous = $data{is_node_ambiguous} = [];
    $data{was_node_seen} = [];
    asf_ambiguities($slr, $asf, \%data);
    return [ grep { $is_node_ambiguous->[$_] } 0 .. $#{$is_node_ambiguous} ];
}

sub or_node_es_span {
    my ( $slr, $choicepoint ) = @_;
    my $recce      = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $bocage     = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $origin_es  = $bocage->_marpa_b_or_node_origin($choicepoint);
    my $current_es = $bocage->_marpa_b_or_node_set($choicepoint);
    return $origin_es, $current_es - $origin_es;
} ## end sub or_node_es_span

sub Marpa::R2::Scanless::R::choicepoint_literal {
    my ( $slr, $choicepoint ) = @_;
    return $slr->substring(or_node_es_span($slr, $choicepoint));
} ## end sub Marpa::R2::Scanless::R::choicepoint_literal

sub Marpa::R2::Scanless::R::token_literal {
    my ( $slr, $token_id ) = @_;
    my ($start, $length) = token_es_span($slr, $token_id);
    return '' if $length == 0;
    return $slr->substring($start, $length);
} ## end sub Marpa::R2::Scanless::R::choicepoint_literal

sub Marpa::R2::Scanless::R::choicepoint_rule {
    my ( $slr, $choicepoint ) = @_;
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $irl_id    = $bocage->_marpa_b_or_node_irl($choicepoint);
    return $grammar_c->_marpa_g_source_xrl($irl_id);
} ## end sub Marpa::R2::Scanless::R::choicepoint_rule

sub Marpa::R2::Scanless::R::brief_rule {
    my ( $slr, $rule_id ) = @_;
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    return $grammar->brief_rule($rule_id);
}

1;

# vim: expandtab shiftwidth=4:
