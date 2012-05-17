# Copyright 2012 Jeffrey Kegler
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

package Marpa::R2::Value;

use 5.010;
use warnings;
use strict;
use integer;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '0.001_045';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::Value;

use English qw( -no_match_vars );

use constant SKIP => -1;

sub Marpa::R2::Recognizer::show_bocage {
    my ($recce) = @_;
    my $text;
    my @data        = ();
    my $id          = 0;
    my $recce_c     = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage      = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $grammar     = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $symbol_hash = $grammar->[Marpa::R2::Internal::Grammar::SYMBOL_HASH];
    OR_NODE: for ( my $or_node_id = 0;; $or_node_id++ ) {
        my $irl_id = $bocage->_marpa_b_or_node_irl($or_node_id);
        last OR_NODE if not defined $irl_id;
        my $position        = $bocage->_marpa_b_or_node_position($or_node_id);
        my $or_origin       = $bocage->_marpa_b_or_node_origin($or_node_id);
        my $origin_earleme  = $recce_c->earleme($or_origin);
        my $or_set          = $bocage->_marpa_b_or_node_set($or_node_id);
        my $current_earleme = $recce_c->earleme($or_set);
        my @and_node_ids =
            ( $bocage->_marpa_b_or_node_first_and($or_node_id)
                .. $bocage->_marpa_b_or_node_last_and($or_node_id) );
        AND_NODE:

        for my $and_node_id (@and_node_ids) {
            my $symbol = $bocage->_marpa_b_and_node_symbol($and_node_id);
            my $cause_tag;

            if ( defined $symbol ) {
                $cause_tag = "S$symbol";
            }
            my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
            my $cause_irl_id;
            if ( defined $cause_id ) {
                $cause_irl_id = $bocage->_marpa_b_or_node_irl($cause_id);
                $cause_tag =
                    Marpa::R2::Recognizer::or_node_tag( $recce, $cause_id );
            }
            my $parent_tag =
                Marpa::R2::Recognizer::or_node_tag( $recce, $or_node_id );
            my $predecessor_id =
                $bocage->_marpa_b_and_node_predecessor($and_node_id);
            my $predecessor_tag = q{-};
            if ( defined $predecessor_id ) {
                $predecessor_tag = Marpa::R2::Recognizer::or_node_tag( $recce,
                    $predecessor_id );
            }
            my $tag = join q{ }, $parent_tag, $predecessor_tag, $cause_tag;
            my $middle_earleme = $origin_earleme;
            if ( defined $predecessor_id ) {
                my $predecessor_set =
                    $bocage->_marpa_b_or_node_set($predecessor_id);
                $middle_earleme = $recce_c->earleme($predecessor_set);
            }

            push @data,
                [
                $origin_earleme, $current_earleme,
                $irl_id,         $position,
                $middle_earleme,
		( defined $symbol ? 0 : 1),
                ( $symbol // $cause_irl_id ), $tag
                ];
        } ## end for my $and_node_id (@and_node_ids)
    } ## end for ( my $or_node_id = 0;; $or_node_id++ )
    my @sorted_data = map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            or $a->[1] <=> $b->[1]
            or $a->[2] <=> $b->[2]
            or $a->[3] <=> $b->[3]
            or $a->[4] <=> $b->[4]
            or $a->[5] <=> $b->[5]
            or $a->[6] <=> $b->[6]
    } @data;
    return ( join "\n", @sorted_data ) . "\n";
} ## end sub Marpa::R2::Recognizer::show_bocage

sub Marpa::R2::Recognizer::and_node_tag {
    my ( $recce, $and_node_id ) = @_;
    my $bocage             = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $recce_c            = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $parent_or_node_id  = $bocage->_marpa_b_and_node_parent($and_node_id);
    my $origin             = $bocage->_marpa_b_or_node_origin($parent_or_node_id);
    my $origin_earleme     = $recce_c->earleme($origin);
    my $current_earley_set = $bocage->_marpa_b_or_node_set($parent_or_node_id);
    my $current_earleme    = $recce_c->earleme($current_earley_set);
    my $cause_id           = $bocage->_marpa_b_and_node_cause($and_node_id);
    my $predecessor_id     = $bocage->_marpa_b_and_node_predecessor($and_node_id);
    my $middle_earleme     = $origin_earleme;
    if ( defined $predecessor_id ) {
        my $middle_set = $bocage->_marpa_b_or_node_set($predecessor_id);
        $middle_earleme = $recce_c->earleme($middle_set);
    }
    my $position = $bocage->_marpa_b_or_node_position($parent_or_node_id);
    my $irl_id     = $bocage->_marpa_b_or_node_irl($parent_or_node_id);

#<<<  perltidy introduces trailing space on this
    my $tag =
          'R'
        . $irl_id . q{:}
        . $position . q{@}
        . $origin_earleme . q{-}
        . $current_earleme;
#>>>
    if ( defined $cause_id ) {
        my $cause_irl_id = $bocage->_marpa_b_or_node_irl($cause_id);
        $tag .= 'C' . $cause_irl_id;
    }
    else {
        my $symbol = $bocage->_marpa_b_and_node_symbol($and_node_id);
        $tag .= 'S' . $symbol;
    }
    $tag .= q{@} . $middle_earleme;
    return $tag;
} ## end sub Marpa::R2::Recognizer::and_node_tag

sub Marpa::R2::Recognizer::show_and_nodes {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $text;
    my @data = ();
    AND_NODE: for ( my $id = 0;; $id++ ) {
        my $parent      = $bocage->_marpa_b_and_node_parent($id);
        my $predecessor = $bocage->_marpa_b_and_node_predecessor($id);
        my $cause       = $bocage->_marpa_b_and_node_cause($id);
        my $symbol      = $bocage->_marpa_b_and_node_symbol($id);
        last AND_NODE if not defined $parent;
        my $origin          = $bocage->_marpa_b_or_node_origin($parent);
        my $set             = $bocage->_marpa_b_or_node_set($parent);
        my $irl_id            = $bocage->_marpa_b_or_node_irl($parent);
        my $position        = $bocage->_marpa_b_or_node_position($parent);
        my $origin_earleme  = $recce_c->earleme($origin);
        my $current_earleme = $recce_c->earleme($set);
        my $middle_earleme  = $origin_earleme;

        if ( defined $predecessor ) {
            my $predecessor_set = $bocage->_marpa_b_or_node_set($predecessor);
            $middle_earleme = $recce_c->earleme($predecessor_set);
        }

#<<<  perltidy introduces trailing space on this
        my $desc =
              'R'
            . $irl_id . q{:}
            . $position . q{@}
            . $origin_earleme . q{-}
            . $current_earleme;
#>>>
        my $cause_rule = -1;
        if ( defined $cause ) {
            my $cause_irl_id = $bocage->_marpa_b_or_node_irl($cause);
            $desc .= 'C' . $cause_irl_id;
        }
        else {
            $desc .= 'S' . $symbol;
        }
        $desc .= q{@} . $middle_earleme;
        push @data,
            [
            $origin_earleme, $current_earleme, $irl_id,
            $position,       $middle_earleme,  $cause_rule,
            ( $symbol // -1 ), $desc
            ];
    } ## end for ( my $id = 0;; $id++ )
    my @sorted_data = map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            or $a->[1] <=> $b->[1]
            or $a->[2] <=> $b->[2]
            or $a->[3] <=> $b->[3]
            or $a->[4] <=> $b->[4]
            or $a->[5] <=> $b->[5]
            or $a->[6] <=> $b->[6]
    } @data;
    return ( join "\n", @sorted_data ) . "\n";
} ## end sub Marpa::R2::Recognizer::show_and_nodes

sub Marpa::R2::Recognizer::or_node_tag {
    my ( $recce, $or_node_id ) = @_;
    my $bocage   = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $set      = $bocage->_marpa_b_or_node_set($or_node_id);
    my $irl_id     = $bocage->_marpa_b_or_node_irl($or_node_id);
    my $origin   = $bocage->_marpa_b_or_node_origin($or_node_id);
    my $position = $bocage->_marpa_b_or_node_position($or_node_id);
    return 'R' . $irl_id . q{:} . $position . q{@} . $origin . q{-} . $set;
} ## end sub Marpa::R2::Recognizer::or_node_tag

sub Marpa::R2::Recognizer::show_or_nodes {
    my ( $recce, $verbose ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $text;
    my @data = ();
    my $id   = 0;
    OR_NODE: for ( ;; ) {
        my $origin   = $bocage->_marpa_b_or_node_origin($id);
        my $set      = $bocage->_marpa_b_or_node_set($id);
        my $irl_id   = $bocage->_marpa_b_or_node_irl($id);
        my $position = $bocage->_marpa_b_or_node_position($id);
        $id++;
        last OR_NODE if not defined $origin;
        my $origin_earleme  = $recce_c->earleme($origin);
        my $current_earleme = $recce_c->earleme($set);

#<<<  perltidy introduces trailing space on this
        my $desc =
              'R'
            . $irl_id . q{:}
            . $position . q{@}
            . $origin_earleme . q{-}
            . $current_earleme;
#>>>
        push @data,
            [ $origin_earleme, $current_earleme, $irl_id, $position, $desc ];
    } ## end for ( ;; )
    my @sorted_data = map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            or $a->[1] <=> $b->[1]
            or $a->[2] <=> $b->[2]
            or $a->[3] <=> $b->[3]
    } @data;
    return ( join "\n", @sorted_data ) . "\n";
} ## end sub Marpa::R2::Recognizer::show_or_nodes

sub Marpa::R2::show_rank_ref {
    my ($rank_ref) = @_;
    return 'undef' if not defined $rank_ref;
    return 'SKIP'  if $rank_ref == Marpa::R2::Internal::Value::SKIP;
    return ${$rank_ref};
} ## end sub Marpa::R2::show_rank_ref

sub Marpa::R2::Recognizer::show_nook {
    my ( $recce, $nook_id, $verbose ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $order = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree = $recce->[Marpa::R2::Internal::Recognizer::T_C];

    my $or_node_id = $tree->_marpa_t_nook_or_node($nook_id);
    return if not defined $or_node_id;

    my $text = "o$or_node_id";
    my $parent = $tree->_marpa_t_nook_parent($nook_id) // q{-};
    CHILD_TYPE: {
        if ( $tree->_marpa_t_nook_is_cause($nook_id) ) {
            $text .= "[c$parent]";
            last CHILD_TYPE;
        }
        if ( $tree->_marpa_t_nook_is_predecessor($nook_id) ) {
            $text .= "[p$parent]";
            last CHILD_TYPE;
        }
        $text .= '[-]';
    } ## end CHILD_TYPE:
    my $or_node_tag =
        Marpa::R2::Recognizer::or_node_tag( $recce, $or_node_id );
    $text .= " $or_node_tag";

    $text .= ' p';
    $text .= $tree->_marpa_t_nook_predecessor_is_ready($nook_id) ? q{=ok} : q{-};
    $text .= ' c';
    $text .= $tree->_marpa_t_nook_cause_is_ready($nook_id) ? q{=ok} : q{-};
    $text .= "\n";

    DESCRIBE_CHOICES: {
        my $this_choice = $tree->_marpa_t_nook_choice($nook_id);
        CHOICE: for ( my $choice_ix = 0;; $choice_ix++ ) {
            my $and_node_id =
                $order->_marpa_o_and_node_order_get( $or_node_id, $choice_ix );
            last CHOICE if not defined $and_node_id;
            $text .= " o$or_node_id" . '[' . $choice_ix . ']';
            if ( defined $this_choice and $this_choice == $choice_ix ) {
                $text .= q{*};
            }
            my $and_node_tag =
                Marpa::R2::Recognizer::and_node_tag( $recce, $and_node_id );
            $text .= " ::= a$and_node_id $and_node_tag";
            $text .= "\n";
        } ## end for ( my $choice_ix = 0;; $choice_ix++ )
    } ## end DESCRIBE_CHOICES:
    return $text;
} ## end sub Marpa::R2::Recognizer::show_nook

sub Marpa::R2::Recognizer::show_tree {
    my ( $recce, $verbose ) = @_;
    my $text = q{};
    NOOK: for ( my $nook_id = 0; 1; $nook_id++ ) {
        my $nook_text = $recce->show_nook( $nook_id, $verbose );
        last NOOK if not defined $nook_text;
        $text .= "$nook_id: $nook_text";
    }
    return $text;
} ## end sub Marpa::R2::Recognizer::show_tree

package Marpa::R2::Internal::Value;

sub Marpa::R2::Internal::Recognizer::set_null_values {
    my ($recce)   = @_;
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $trace_values =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_VALUES];

    my $rules   = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $symbols = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $default_null_value =
        $grammar->[Marpa::R2::Internal::Grammar::DEFAULT_NULL_VALUE];

    my $null_values;
    $#{$null_values} = $#{$symbols};

    SYMBOL: for my $symbol ( @{$symbols} ) {

        my $symbol_id = $symbol->[Marpa::R2::Internal::Symbol::ID];

        next SYMBOL if not $grammar_c->symbol_is_nullable($symbol_id);

        my $null_value = undef;
        if ( $symbol->[Marpa::R2::Internal::Symbol::NULL_VALUE] ) {
            $null_value =
                $symbol->[Marpa::R2::Internal::Symbol::NULL_VALUE];
        }
        else {
            $null_value = $default_null_value;
        }
        next SYMBOL if not defined $null_value;

        $null_values->[$symbol_id] = $null_value;

        if ($trace_values) {
            print {$Marpa::R2::Internal::TRACE_FH}
                'Setting null value for symbol ',
                $grammar->symbol_name($symbol_id),
                ' to ', Data::Dumper->new( [ \$null_value ] )->Terse(1)->Dump
                or Marpa::R2::exception('Could not print to trace file');
        } ## end if ($trace_values)

    } ## end for my $symbol ( @{$symbols} )

    return $null_values;

}    # set_null_values

# Given the grammar and an action name, resolve it to a closure,
# or return undef
sub Marpa::R2::Internal::Recognizer::resolve_semantics {
    my ( $recce, $closure_name ) = @_;
    my $grammar  = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $closures = $recce->[Marpa::R2::Internal::Recognizer::CLOSURES];
    my $trace_actions =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_ACTIONS];

    Marpa::R2::exception(q{Trying to resolve 'undef' as closure name})
        if not defined $closure_name;

    if ( my $closure = $closures->{$closure_name} ) {
        if ($trace_actions) {
            print {$Marpa::R2::Internal::TRACE_FH}
                qq{Resolved "$closure_name" to explicit closure\n}
                or Marpa::R2::exception('Could not print to trace file');
        }

        return $closure;
    } ## end if ( my $closure = $closures->{$closure_name} )

    my $fully_qualified_name;
    DETERMINE_FULLY_QUALIFIED_NAME: {
        if ( $closure_name =~ /([:][:])|[']/xms ) {
            $fully_qualified_name = $closure_name;
            last DETERMINE_FULLY_QUALIFIED_NAME;
        }
        if (defined(
                my $actions_package =
                    $grammar->[Marpa::R2::Internal::Grammar::ACTIONS]
            )
            )
        {
            $fully_qualified_name = $actions_package . q{::} . $closure_name;
            last DETERMINE_FULLY_QUALIFIED_NAME;
        } ## end if ( defined( my $actions_package = $grammar->[...]))

        if (defined(
                my $action_object_class =
                    $grammar->[Marpa::R2::Internal::Grammar::ACTION_OBJECT]
            )
            )
        {
            $fully_qualified_name =
                $action_object_class . q{::} . $closure_name;
        } ## end if ( defined( my $action_object_class = $grammar->[...]))
    } ## end DETERMINE_FULLY_QUALIFIED_NAME:

    return if not defined $fully_qualified_name;

    no strict 'refs';
    my $closure = *{$fully_qualified_name}{'CODE'};
    use strict 'refs';

    if ($trace_actions) {
        print {$Marpa::R2::Internal::TRACE_FH}
            ( $closure ? 'Successful' : 'Failed' )
            . qq{ resolution of "$closure_name" },
            'to ', $fully_qualified_name, "\n"
            or Marpa::R2::exception('Could not print to trace file');
    } ## end if ($trace_actions)

    return $closure;

} ## end sub Marpa::R2::Internal::Recognizer::resolve_semantics

sub Marpa::R2::Internal::Recognizer::set_actions {
    my ($recce)   = @_;
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $rules     = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $symbols   = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $default_action =
        $grammar->[Marpa::R2::Internal::Grammar::DEFAULT_ACTION];

    my $rule_closures  = [];

    my $default_action_closure;
    if ( defined $default_action ) {
        $default_action_closure =
            Marpa::R2::Internal::Recognizer::resolve_semantics( $recce,
            $default_action );
        Marpa::R2::exception(
            "Could not resolve default action named '$default_action'")
            if not $default_action_closure;
    } ## end if ( defined $default_action )

    RULE: for my $rule ( @{$rules} ) {

        my $rule_id = $rule->[Marpa::R2::Internal::Rule::ID];

        if ( my $action = $rule->[Marpa::R2::Internal::Rule::ACTION] ) {
            my $closure =
                Marpa::R2::Internal::Recognizer::resolve_semantics( $recce,
                $action );

            Marpa::R2::exception(qq{Could not resolve action name: "$action"})
                if not defined $closure;
            $rule_closures->[$rule_id] = $closure;
            next RULE;
        } ## end if ( my $action = $rule->[Marpa::R2::Internal::Rule::ACTION...])

        # Try to resolve the LHS as a closure name,
        # if it is not internal.
        # If we can't resolve
        # the LHS as a closure name, it's not
        # a fatal error.
        FIND_CLOSURE_BY_LHS: {
            my $lhs_id = $grammar_c->rule_lhs($rule_id);
            my $action = $grammar->symbol_name($lhs_id);
            last FIND_CLOSURE_BY_LHS if substr( $action, -1 ) eq ']';
            my $closure =
                Marpa::R2::Internal::Recognizer::resolve_semantics( $recce,
                $action );
            last FIND_CLOSURE_BY_LHS if not defined $closure;
            $rule_closures->[$rule_id] = $closure;
            next RULE;
        } ## end FIND_CLOSURE_BY_LHS:

        if ( defined $default_action_closure ) {
            $rule_closures->[$rule_id] = $default_action_closure;
            next RULE;
        }

    } ## end for my $rule ( @{$rules} )

    $recce->[Marpa::R2::Internal::Recognizer::RULE_CLOSURES] = $rule_closures;
    for my $rule_id (grep { defined } 0 .. $#{$rule_closures}) {
         $grammar_c->rule_ask_me_set($rule_id);
    }

    return 1;
}    # set_actions

#
# Set ranks for chaf rules
#
sub rank_chaf_rules {

    my ($grammar) = @_;
    my $rules     = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my @chaf_ranks;

    RULE: for my $irl_id ( 0 .. $grammar_c->_marpa_g_irl_count() - 1 ) {

        my $original_rule_id = $grammar_c->_marpa_g_source_xrl($irl_id);
        my $original_rule =
            defined $original_rule_id ? $rules->[$original_rule_id] : undef;
        my $null_ranking =
            defined $original_rule
            ? $original_rule->[Marpa::R2::Internal::Rule::NULL_RANKING]
            : undef;

        # If not null ranked, default to highest CHAF rank
        if ( not $null_ranking ) {
            $chaf_ranks[$irl_id] = 99;
            next RULE;
        }

        # If this rule is marked as null ranked,
        # but it is not actually a CHAF rule, rank it below
        # all non-null-ranked rules, but above all rules with CHAF
        # ranks actually computed from the proper nullables
        my $virtual_start = $grammar_c->_marpa_g_virtual_start($irl_id);
        if ( not defined $virtual_start ) {
            $chaf_ranks[$irl_id] = 98;
            next RULE;
        }

        my $original_rule_length = $grammar_c->rule_length($original_rule_id);

        my $rank                  = 0;
        my $proper_nullable_count = 0;
        RHS_IX:
        for (
            my $rhs_ix = $virtual_start;
            $rhs_ix < $original_rule_length;
            $rhs_ix++
            )
        {
            my $original_rhs_id =
                $grammar_c->rule_rhs( $original_rule_id, $rhs_ix );

            # Do nothing unless this is a proper nullable
            next RHS_IX if $grammar_c->symbol_is_nulling($original_rhs_id);
            next RHS_IX
                if not $grammar_c->symbol_is_nullable($original_rhs_id);

            my $rhs_id =
                $grammar_c->_marpa_g_irl_rhs( $irl_id, $rhs_ix - $virtual_start );
            last RHS_IX if not defined $rhs_id;
            $rank *= 2;
            $rank += ( $grammar_c->_marpa_g_isy_is_nulling($rhs_id) ? 0 : 1 );

            last RHS_IX if ++$proper_nullable_count >= 2;
        } ## end for ( my $rhs_ix = $virtual_start; $rhs_ix < ...)

        if ( $null_ranking eq 'high' ) {
            $rank = ( 2**$proper_nullable_count - 1 ) - $rank;
        }

        $chaf_ranks[$irl_id] = $rank;

    } ## end for my $irl_id ( 0 .. $grammar_c->_marpa_g_irl_count(...))

    return \@chaf_ranks;

}

sub calculate_rank_by_irl {
    my ($grammar)   = @_;
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $default_rank = $grammar->[Marpa::R2::Internal::Grammar::DEFAULT_RANK];
    my $rules     = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my @rank_by_irl = ();
    RULE: for my $irl_id ( 0 .. $grammar_c->_marpa_g_irl_count()-1 ) {
	my $xrl_id = $grammar_c->_marpa_g_source_xrl($irl_id);
	if (defined $xrl_id) {
	  my $rule = $rules->[ $xrl_id ];
	  $rank_by_irl[ $irl_id ] = $rule->[Marpa::R2::Internal::Rule::RANK];
	  next RULE;
	}
	$rank_by_irl[ $irl_id ] = $default_rank;
    }    # end for my $rule ( @{$rules} )
    return \@rank_by_irl;
}

sub do_high_rule_only {
    my ($recce)   = @_;
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $order    = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $rules     = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $chaf_ranks = rank_chaf_rules($grammar);

    my $top_or_node = $bocage->_marpa_b_top_or_node();

    # If parse is nulling, just return
    return if not defined $top_or_node;
    my @or_nodes = ($top_or_node);

    # Set up ranks by symbol
    my @rank_by_symbol = ();
    SYMBOL: for my $symbol ( @{$symbols} ) {
        my $rank = $symbol->[Marpa::R2::Internal::Symbol::TERMINAL_RANK];
        $rank_by_symbol[ $symbol->[Marpa::R2::Internal::Symbol::ID] ] = $rank;
    }    # end for my $symbol ( @{$symbols} )

    my $rank_by_irl = calculate_rank_by_irl($grammar);

    OR_NODE: for ( my $or_node = 0;; $or_node++ ) {
        my $first_and_node = $bocage->_marpa_b_or_node_first_and($or_node);
        last OR_NODE if not defined $first_and_node;
        my $last_and_node = $bocage->_marpa_b_or_node_last_and($or_node);
        my @ranking_data  = ();
        my @and_nodes     = $first_and_node .. $last_and_node;
        AND_NODE:

        for my $and_node (@and_nodes) {
            my $token = $bocage->_marpa_b_and_node_symbol($and_node);
            if ( defined $token ) {
                push @ranking_data,
                    [ $and_node, $rank_by_symbol[$token], 99 ];
                next AND_NODE;
            }
            my $cause   = $bocage->_marpa_b_and_node_cause($and_node);
            my $irl_id = $bocage->_marpa_b_or_node_irl($cause);
            push @ranking_data,
                [
                $and_node, $rank_by_irl->[$irl_id],
		$chaf_ranks->[$irl_id]
                ];
        } ## end for my $and_node (@and_nodes)

## no critic(BuiltinFunctions::ProhibitReverseSortBlock)
        my @sorted_and_data =
            sort { $b->[1] <=> $a->[1] or $b->[2] <=> $a->[2] } @ranking_data;
## use critic

        my ( $first_selected_and_node, $high_rule_rank, $high_chaf_rank ) =
            @{ $sorted_and_data[0] };
        my @selected_and_nodes = ($first_selected_and_node);
        AND_DATUM:
        for my $and_datum ( @sorted_and_data[ 1 .. $#sorted_and_data ] ) {
            my ( $and_node, $rule_rank, $chaf_rank ) = @{$and_datum};
            last AND_DATUM if $rule_rank < $high_rule_rank;
            last AND_DATUM if $chaf_rank < $high_chaf_rank;
            push @selected_and_nodes, $and_node;
        } ## end for my $and_datum ( @sorted_and_data[ 1 .. $#sorted_and_data...])
        $order->_marpa_o_and_node_order_set( $or_node, \@selected_and_nodes );
        push @or_nodes, grep {defined} map {
            ( $bocage->_marpa_b_and_node_predecessor($_), $bocage->_marpa_b_and_node_cause($_) )
        } @selected_and_nodes;
    } ## end for ( my $or_node = 0;; $or_node++ )
    return 1;
} ## end sub do_high_rule_only

sub do_rank_by_rule {
    my ($recce)   = @_;
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $order    = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $rules     = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $chaf_ranks = rank_chaf_rules($grammar);

    my @or_nodes = ( $bocage->_marpa_b_top_or_node() );

    # Set up ranks by symbol
    my @rank_by_symbol = ();
    SYMBOL: for my $symbol ( @{$symbols} ) {
        my $rank = $symbol->[Marpa::R2::Internal::Symbol::TERMINAL_RANK];
        $rank_by_symbol[ $symbol->[Marpa::R2::Internal::Symbol::ID] ] = $rank;
    }    # end for my $symbol ( @{$symbols} )

    # Set up ranks by rule
    my $rank_by_irl = calculate_rank_by_irl($grammar);

    my $seen = q{};
    OR_NODE: while ( my $or_node = pop @or_nodes ) {
        last OR_NODE if not defined $or_node;
        next OR_NODE if vec $seen, $or_node, 1;
        vec( $seen, $or_node, 1 ) = 1;
        my $first_and_node = $bocage->_marpa_b_or_node_first_and($or_node);
        my $last_and_node  = $bocage->_marpa_b_or_node_last_and($or_node);
        my @ranking_data   = ();
        my @and_nodes      = $first_and_node .. $last_and_node;
        AND_NODE:

        for my $and_node (@and_nodes) {
            my $token = $bocage->_marpa_b_and_node_symbol($and_node);
            if ( defined $token ) {
                push @ranking_data,
                    [ $and_node, $rank_by_symbol[$token], 99 ];
                next AND_NODE;
            }
            my $cause   = $bocage->_marpa_b_and_node_cause($and_node);
            my $irl_id = $bocage->_marpa_b_or_node_irl($cause);
            push @ranking_data,
                [
                $and_node, $rank_by_irl->[$irl_id],
		$chaf_ranks->[$irl_id]
                ];
        } ## end for my $and_node (@and_nodes)

## no critic(BuiltinFunctions::ProhibitReverseSortBlock)
        my @ranked_and_nodes =
            map { $_->[0] }
            sort { $b->[1] <=> $a->[1] or $b->[2] <=> $a->[2] } @ranking_data;
## use critic

        $order->_marpa_o_and_node_order_set( $or_node, \@ranked_and_nodes );
        push @or_nodes, grep {defined} map {
            ( $bocage->_marpa_b_and_node_predecessor($_), $bocage->_marpa_b_and_node_cause($_) )
        } @ranked_and_nodes;
    } ## end while ( my $or_node = pop @or_nodes )
    return 1;
} ## end sub do_rank_by_rule

sub trace_token_evaluation {
    my ( $recce, $value, $token_id, $value_ref ) = @_;
    my $order       = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree        = $recce->[Marpa::R2::Internal::Recognizer::T_C];
    my $grammar     = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];

    my $nook_ix     = $value->_marpa_v_nook();
    if ( not defined $nook_ix ) {
        print {$Marpa::R2::Internal::TRACE_FH} "Nulling valuator\n";
	return;
    }
    my $or_node_id  = $tree->_marpa_t_nook_or_node($nook_ix);
    my $choice      = $tree->_marpa_t_nook_choice($nook_ix);
    my $and_node_id = $order->_marpa_o_and_node_order_get( $or_node_id, $choice );
    my $token_name;
    if ( defined $token_id ) {
        $token_name = $grammar->symbol_name($token_id);
    }

    print {$Marpa::R2::Internal::TRACE_FH}
        'Pushed value from ',
        Marpa::R2::Recognizer::and_node_tag( $recce, $and_node_id ),
        ': ',
        ( $token_name ? qq{$token_name = } : q{} ),
        Data::Dumper->new( [$value_ref] )->Terse(1)->Dump
        or Marpa::R2::exception('print to trace handle failed');

   return;

} ## end sub trace_token_evaluation

# Does not modify stack
sub Marpa::R2::Internal::Recognizer::evaluate {
    my ($recce)     = @_;
    my $recce_c     = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage      = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $order       = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree        = $recce->[Marpa::R2::Internal::Recognizer::T_C];
    my $null_values = $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES];
    my $grammar     = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $token_values =
        $recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES];
    my $grammar_c    = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $symbols      = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $trace_values = $recce->[Marpa::R2::Internal::Recognizer::TRACE_VALUES]
        // 0;

    my $rule_closures =
        $recce->[Marpa::R2::Internal::Recognizer::RULE_CLOSURES];

    my $action_object_class =
        $grammar->[Marpa::R2::Internal::Grammar::ACTION_OBJECT];

    my $action_object_constructor;
    if ( defined $action_object_class ) {
        my $constructor_name = $action_object_class . q{::new};
        my $closure =
            Marpa::R2::Internal::Recognizer::resolve_semantics( $recce,
            $constructor_name );
        Marpa::R2::exception(
            qq{Could not find constructor "$constructor_name"})
            if not defined $closure;
        $action_object_constructor = $closure;
    } ## end if ( defined $action_object_class )

    my $action_object;
    if ($action_object_constructor) {
        my @warnings;
        my $eval_ok;
        my $fatal_error;
        DO_EVAL: {
            local $EVAL_ERROR = undef;
            local $SIG{__WARN__} = sub {
                push @warnings, [ $_[0], ( caller 0 ) ];
            };

            $eval_ok = eval {
                $action_object =
                    $action_object_constructor->($action_object_class);
                1;
            };
            $fatal_error = $EVAL_ERROR;
        } ## end DO_EVAL:

        if ( not $eval_ok or @warnings ) {
            Marpa::R2::Internal::code_problems(
                {   fatal_error => $fatal_error,
                    grammar     => $grammar,
                    eval_ok     => $eval_ok,
                    warnings    => \@warnings,
                    where       => 'constructing action object',
                }
            );
        } ## end if ( not $eval_ok or @warnings )
    } ## end if ($action_object_constructor)

    $action_object //= {};

    my $value            = Marpa::R2::Internal::V_C->new($tree);
    for my $token_id ( grep { defined $null_values->[$_] }
        0 .. $#$null_values )
    {
        $value->symbol_ask_me_when_null_set($token_id, 1);
    }
    my @evaluation_stack = ();
    $value->_marpa_v_trace( $trace_values ? 1 : 0 );

    EVENT: while (1) {
        my ( $value_type, @value_data ) = $value->step();
        last EVENT if not defined $value_type;

        if ( $trace_values >= 3 ) {
            for my $i ( reverse 0 .. $#evaluation_stack ) {
                printf {$Marpa::R2::Internal::TRACE_FH} 'Stack position %3d:',
                    $i
                    or Marpa::R2::exception('print to trace handle failed');
                print {$Marpa::R2::Internal::TRACE_FH} q{ },
                    Data::Dumper->new( [ $evaluation_stack[$i] ] )->Terse(1)
                    ->Dump
                    or Marpa::R2::exception('print to trace handle failed');
            } ## end for my $i ( reverse 0 .. $#evaluation_stack )
        } ## end if ( $trace_values >= 3 )

        if ( $value_type eq 'MARPA_VALUE_TOKEN' ) {
		my ( $token_id, $value_ix, $arg_n ) = @value_data;
                my $value_ref = \( $token_values->[$value_ix] );
                $evaluation_stack[$arg_n] = $value_ref;
		trace_token_evaluation($recce, $value, $token_id, $value_ref) if $trace_values;
		next EVENT;
	}

        if ( $value_type eq 'MARPA_VALUE_NULLING_SYMBOL' ) {
		my ( $token_id, $arg_n ) = @value_data;
                my $value_ref = $null_values->[$token_id];
                $evaluation_stack[$arg_n] = $value_ref;
		trace_token_evaluation($recce, $value, $token_id, $value_ref) if $trace_values;
		next EVENT;
	}

        if ( $value_type eq 'MARPA_VALUE_RULE' ) {
	    my ( $rule_id, $arg_0, $arg_n ) = @value_data;
            my $closure = $rule_closures->[$rule_id];
            if ( defined $closure ) {
                my $result;

                my @args =
                    map { defined $_ ? ${$_} : $_ } @evaluation_stack[ $arg_0 .. $arg_n ];
                if ( !$grammar_c->rule_is_keep_separation($rule_id) ) {
                    @args =
                        @args[ map { 2 * $_ }
                        ( 0 .. ( scalar @args + 1 ) / 2 - 1 ) ];
                }

                my @warnings;
                my $eval_ok;
                DO_EVAL: {
                    local $SIG{__WARN__} = sub {
                        push @warnings, [ $_[0], ( caller 0 ) ];
                    };

                    $eval_ok = eval {
                        $result = $closure->( $action_object, @args );
                        1;
                    };

                } ## end DO_EVAL:

                if ( not $eval_ok or @warnings ) {
                    my $fatal_error = $EVAL_ERROR;
                    Marpa::R2::Internal::code_problems(
                        {   fatal_error => $fatal_error,
                            grammar     => $grammar,
                            eval_ok     => $eval_ok,
                            warnings    => \@warnings,
                            where       => 'computing value',
                            long_where  => 'Computing value for rule: '
                                . $grammar->brief_rule($rule_id),
                        }
                    );
                } ## end if ( not $eval_ok or @warnings )

                $evaluation_stack[$arg_0] = \$result;

                if ($trace_values) {

                    my $argc = scalar @args;
		    my $nook_ix    = $value->_marpa_v_nook();
		    my $or_node_id = $tree->_marpa_t_nook_or_node($nook_ix);
		    my $choice     = $tree->_marpa_t_nook_choice($nook_ix);
		    my $and_node_id =
			$order->_marpa_o_and_node_order_get( $or_node_id, $choice );

                    say {$Marpa::R2::Internal::TRACE_FH} 'Popping ', $argc,
                        ' values to evaluate ',
                        Marpa::R2::Recognizer::and_node_tag(
                        $recce, $and_node_id
                        ),
                        ', rule: ', $grammar->brief_rule($rule_id)
                        or
                        Marpa::R2::exception('Could not print to trace file');

                    print {$Marpa::R2::Internal::TRACE_FH}
                        'Calculated and pushed value: ',
                        Data::Dumper->new( [$result] )->Terse(1)->Dump
                        or
                        Marpa::R2::exception('print to trace handle failed');
                } ## end if ($trace_values)

                next EVENT;

            } ## end if ( defined $closure )

            next EVENT;

        } ## end if ( $value_type eq 'MARPA_VALUE_RULE' )

        if ( $value_type eq 'MARPA_VALUE_TRACE' ) {

            TRACE_OP: {

                last TRACE_OP if not $trace_values;

                my $nook_ix    = $value->_marpa_v_nook();
                my $or_node_id = $tree->_marpa_t_nook_or_node($nook_ix);
                my $choice     = $tree->_marpa_t_nook_choice($nook_ix);
                my $and_node_id =
                    $order->_marpa_o_and_node_order_get( $or_node_id, $choice );
                my $trace_irl_id = $bocage->_marpa_b_or_node_irl($or_node_id);
                my $virtual_rhs =
                    $grammar_c->_marpa_g_irl_is_virtual_rhs($trace_irl_id);
                my $virtual_lhs =
                    $grammar_c->_marpa_g_irl_is_virtual_lhs($trace_irl_id);

                next EVENT
                    if $bocage->_marpa_b_or_node_position($or_node_id)
                        != $grammar_c->_marpa_g_irl_length($trace_irl_id);

		last TRACE_OP if not $virtual_rhs and not $virtual_lhs;

                if ( $virtual_rhs and not $virtual_lhs ) {

                    say {$Marpa::R2::Internal::TRACE_FH}
                        'Head of Virtual Rule: ',
                        Marpa::R2::Recognizer::and_node_tag(
                        $recce, $and_node_id
                        ),
                        ', rule: ', $grammar->brief_irl($trace_irl_id),
                        "\n",
                        'Incrementing virtual rule by ',
                        $grammar_c->_marpa_g_real_symbol_count($trace_irl_id),
                        ' symbols'
                        or
                        Marpa::R2::exception('Could not print to trace file');

                    last TRACE_OP;

                } ## end if ( $virtual_rhs and not $virtual_lhs )

                if ( $virtual_lhs and $virtual_rhs ) {

                    say {$Marpa::R2::Internal::TRACE_FH}
                        'Virtual Rule: ',
                        Marpa::R2::Recognizer::and_node_tag(
                        $recce, $and_node_id
                        ),
                        ', rule: ', $grammar->brief_irl($trace_irl_id),
                        "\nAdding ",
                        $grammar_c->_marpa_g_real_symbol_count($trace_irl_id)
                        or
                        Marpa::R2::exception('Could not print to trace file');

                    next EVENT;

                } ## end if ( $virtual_lhs and $virtual_rhs )

                if ( not $virtual_rhs and $virtual_lhs ) {

                    say {$Marpa::R2::Internal::TRACE_FH}
                        'New Virtual Rule: ',
                        Marpa::R2::Recognizer::and_node_tag(
                        $recce, $and_node_id
                        ),
                        ', rule: ', $grammar->brief_irl($trace_irl_id),
                        "\nReal symbol count is ",
                        $grammar_c->_marpa_g_real_symbol_count($trace_irl_id)
                        or
                        Marpa::R2::exception('Could not print to trace file');

                    next EVENT;

                } ## end if ( not $virtual_rhs and $virtual_lhs )

            } ## end TRACE_OP:

            next EVENT;

        } ## end if ( $value_type eq 'MARPA_VALUE_TRACE' )

        die "Internal error: Unknown value type $value_type";

    } ## end while (1)

    my $top_value = $evaluation_stack[0];

    return $top_value // (\undef);

} ## end sub Marpa::R2::Internal::Recognizer::evaluate

# Returns false if no parse
sub Marpa::R2::Recognizer::value {
    my ( $recce, @arg_hashes ) = @_;

    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $order = $recce->[Marpa::R2::Internal::Recognizer::O_C];

    my $parse_set_arg = $recce->[Marpa::R2::Internal::Recognizer::END];


    $recce->set(@arg_hashes);

    local $Marpa::R2::Internal::TRACE_FH =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE];

    my $furthest_earleme       = $recce_c->furthest_earleme();
    my $last_completed_earleme = $recce_c->current_earleme();
    Marpa::R2::exception(
        "Attempt to evaluate incompletely recognized parse:\n",
        "  Last token ends at location $furthest_earleme\n",
        "  Recognition done only as far as location $last_completed_earleme\n"
    ) if $furthest_earleme > $last_completed_earleme;

    my $tree = $recce->[Marpa::R2::Internal::Recognizer::T_C];
    my $tree_result;
    my $parse_count;

    if ($tree) {
        my $max_parses =
            $recce->[Marpa::R2::Internal::Recognizer::MAX_PARSES];
        my $parse_count = $tree->parse_count();
        if ( $max_parses and $parse_count > $max_parses ) {
            Marpa::R2::exception(
                "Maximum parse count ($max_parses) exceeded");
        }

    } ## end if ($tree)
    else {

        # Perhaps this call should be moved.
        # The null values are currently a function of the grammar,
        # and should be constant for the life of a recognizer.
        $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES] //=
            Marpa::R2::Internal::Recognizer::set_null_values($recce);
        Marpa::R2::Internal::Recognizer::set_actions($recce);

        my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C] =
            Marpa::R2::Internal::B_C->new( $recce_c,
            ( $parse_set_arg // -1 ) );

        return if not defined $bocage;

        my $order = $recce->[Marpa::R2::Internal::Recognizer::O_C] =
            Marpa::R2::Internal::O_C->new($bocage);

        given ( $recce->[Marpa::R2::Internal::Recognizer::RANKING_METHOD] ) {
            when ('high_rule_only') { do_high_rule_only($recce); }
            when ('rule')           { do_rank_by_rule($recce); }
        }

        $tree = $recce->[Marpa::R2::Internal::Recognizer::T_C] =
            Marpa::R2::Internal::T_C->new($order);

    } ## end else [ if ($bocage) ]

    if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_AND_NODES] ) {
        print {$Marpa::R2::Internal::TRACE_FH} 'AND_NODES: ',
            $recce->show_and_nodes()
            or Marpa::R2::exception('print to trace handle failed');
    }

    if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_OR_NODES] ) {
        print {$Marpa::R2::Internal::TRACE_FH} 'OR_NODES: ',
            $recce->show_or_nodes()
            or Marpa::R2::exception('print to trace handle failed');
    }

    if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_BOCAGE] ) {
        print {$Marpa::R2::Internal::TRACE_FH} 'BOCAGE: ',
            $recce->show_bocage()
            or Marpa::R2::exception('print to trace handle failed');
    }

    return if not defined $tree->next();
    return Marpa::R2::Internal::Recognizer::evaluate($recce);

} ## end sub Marpa::R2::Recognizer::value

1;
