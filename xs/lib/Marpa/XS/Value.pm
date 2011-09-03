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

package Marpa::XS::Internal::Value;

use 5.010;
use warnings;
use strict;
use integer;

use English qw( -no_match_vars );

BEGIN {
my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::XS::Internal::Eval

    EVAL_TOS
    VEVAL_STACK
    FORK_IX
    TRACE_VAL

END_OF_STRUCTURE
    Marpa::offset($structure);
} ## end BEGIN

# This perlcritic check is broken as of 9 Aug 2010
## no critic (TestingAndDebugging::ProhibitNoWarnings)
no warnings qw(qw);
## use critic

use constant SKIP => -1;

use warnings;

sub Marpa::XS::Recognizer::parse_count {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    return $recce_c->parse_count();
}

sub Marpa::XS::Recognizer::show_bocage {
    my ($recce) = @_;
    my $text;
    my @data = ();
    my $id = 0;
    my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar     = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];
    OR_NODE: for (my $or_node_id = 0; ; $or_node_id++) {
	my $rule = $recce_c->or_node_rule($or_node_id);
	last OR_NODE if not defined $rule;
	my $position = $recce_c->or_node_position($or_node_id);
	my $or_origin = $recce_c->or_node_origin($or_node_id);
	my $origin_earleme = $recce_c->earleme($or_origin);
	my $or_set = $recce_c->or_node_set($or_node_id);
	my $current_earleme = $recce_c->earleme($or_set);
        my @and_node_ids =
            ( $recce_c->or_node_first_and($or_node_id)
                .. $recce_c->or_node_last_and($or_node_id) );
        AND_NODE:
        for my $and_node_id (@and_node_ids) {
            my $symbol = $recce_c->and_node_symbol($and_node_id);
            my $cause_tag;

            if ( defined $symbol ) {
                $cause_tag = "S$symbol";
            }
            my $cause_rule = -1;
            my $cause_id   = $recce_c->and_node_cause($and_node_id);
            if ( defined $cause_id ) {
                $cause_rule = $recce_c->or_node_rule($cause_id);
                $cause_tag =
                    Marpa::XS::Recognizer::or_node_tag( $recce, $cause_id );
            }
            my $parent_tag =
                Marpa::XS::Recognizer::or_node_tag( $recce, $or_node_id );
            my $predecessor_id = $recce_c->and_node_predecessor($and_node_id);
            my $predecessor_tag = q{-};
            if ( defined $predecessor_id ) {
                $predecessor_tag = Marpa::XS::Recognizer::or_node_tag( $recce,
                    $predecessor_id );
            }
            my $tag = join q{ }, $parent_tag, $predecessor_tag, $cause_tag;
	    my $middle_earleme = $origin_earleme;
	    if (defined $predecessor_id) {
		my $predecessor_set = $recce_c->or_node_set($predecessor_id);
		$middle_earleme = $recce_c->earleme($predecessor_set);
	    }

            push @data,
                [
                $origin_earleme, $current_earleme, $rule,
                $position,       $middle_earleme,  $cause_rule,
                ( $symbol // -1 ), $tag
                ];
        } ## end for my $and_node_id (@and_node_ids)
    } ## end for my $or_node_id ( 0 .. $#{$or_nodes} )
    my @sorted_data = map { $_->[-1] } sort {
        $a->[0] <=> $b->[0]
	or $a->[1] <=> $b->[1]
	or $a->[2] <=> $b->[2]
	or $a->[3] <=> $b->[3]
	or $a->[4] <=> $b->[4]
	or $a->[5] <=> $b->[5]
	or $a->[6] <=> $b->[6]
    } @data;
    return (join "\n", @sorted_data) . "\n";;
}

sub Marpa::XS::Recognizer::and_node_tag {
    my ( $recce, $and_node_id ) = @_;
    my $recce_c            = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $parent_or_node_id  = $recce_c->and_node_parent($and_node_id);
    my $origin             = $recce_c->or_node_origin($parent_or_node_id);
    my $origin_earleme     = $recce_c->earleme($origin);
    my $current_earley_set = $recce_c->or_node_set($parent_or_node_id);
    my $current_earleme    = $recce_c->earleme($current_earley_set);
    my $cause_id           = $recce_c->and_node_cause($and_node_id);
    my $predecessor_id     = $recce_c->and_node_predecessor($and_node_id);
    my $middle_earleme     = $origin_earleme;
    if ( defined $predecessor_id ) {
        my $middle_set = $recce_c->or_node_set($predecessor_id);
        $middle_earleme = $recce_c->earleme($middle_set);
    }
    my $position = $recce_c->or_node_position($parent_or_node_id);
    my $rule     = $recce_c->or_node_rule($parent_or_node_id);
    my $tag =
          'R'
        . $rule . q{:}
        . $position . q{@}
        . $origin_earleme . q{-}
        . $current_earleme;
    if ( defined $cause_id ) {
        my $cause_rule = $recce_c->or_node_rule($cause_id);
        $tag .= 'C' . $cause_rule;
    }
    else {
        my $symbol = $recce_c->and_node_symbol($and_node_id);
        $tag .= 'S' . $symbol;
    }
    $tag .= q{@} . $middle_earleme;
    return $tag;
} ## end sub Marpa::XS::Recognizer::and_node_tag

sub Marpa::XS::Recognizer::show_and_nodes {
    my ($recce) = @_;
    my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $text;
    my @data = ();
    AND_NODE: for ( my $id = 0;;  $id++) {
	my $parent = $recce_c->and_node_parent($id);
	my $predecessor = $recce_c->and_node_predecessor($id);
	my $cause = $recce_c->and_node_cause($id);
	my $symbol = $recce_c->and_node_symbol($id);
        last AND_NODE if not defined $parent;
	my $origin = $recce_c->or_node_origin( $parent );
	my $set = $recce_c->or_node_set( $parent );
	my $rule = $recce_c->or_node_rule( $parent );
	my $position = $recce_c->or_node_position( $parent );
        my $origin_earleme  = $recce_c->earleme($origin);
        my $current_earleme = $recce_c->earleme($set);
	my $middle_earleme = $origin_earleme;
	if (defined $predecessor) {
	    my $predecessor_set = $recce_c->or_node_set( $predecessor );
	    $middle_earleme = $recce_c->earleme($predecessor_set);
	}
        my $desc =
              'R'
            . $rule . q{:}
            . $position . q{@}
            . $origin_earleme . q{-}
            . $current_earleme;
	my $cause_rule = -1;
	if (defined $cause) {
	    $cause_rule = $recce_c->or_node_rule( $cause );
	    $desc .= 'C' . $cause_rule;
	} else {
	    $desc .= 'S' . $symbol;
	}
	$desc .= q{@} . $middle_earleme;
        push @data,
            [ $origin_earleme, $current_earleme, $rule, $position,
		$middle_earleme,
		$cause_rule,
		($symbol // -1),
		$desc ];
    } ## end for ( ;; )
    my @sorted_data = map { $_->[-1] } sort {
        $a->[0] <=> $b->[0]
	or $a->[1] <=> $b->[1]
	or $a->[2] <=> $b->[2]
	or $a->[3] <=> $b->[3]
	or $a->[4] <=> $b->[4]
	or $a->[5] <=> $b->[5]
	or $a->[6] <=> $b->[6]
    } @data;
    return (join "\n", @sorted_data) . "\n";;
}

sub Marpa::XS::Recognizer::or_node_tag {
    my ($recce, $or_node_id) = @_;
    my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $set = $recce_c->or_node_set($or_node_id);
    my $rule = $recce_c->or_node_rule($or_node_id);
    my $origin = $recce_c->or_node_origin($or_node_id);
    my $position = $recce_c->or_node_position($or_node_id);
    return 'R' . $rule . q{:} . $position . q{@} . $origin . q{-} . $set;
}

sub Marpa::XS::Recognizer::show_or_nodes {
    my ($recce, $verbose) = @_;
    my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $text;
    my @data = ();
    my $id = 0;
    OR_NODE: for ( ;; ) {
	my $origin = $recce_c->or_node_origin( $id );
	my $set = $recce_c->or_node_set( $id );
	my $rule = $recce_c->or_node_rule( $id );
	my $position = $recce_c->or_node_position( $id );
	$id++;
        last OR_NODE if not defined $origin;
        my $origin_earleme  = $recce_c->earleme($origin);
        my $current_earleme = $recce_c->earleme($set);
        my $desc =
              'R'
            . $rule . q{:}
            . $position . q{@}
            . $origin_earleme . q{-}
            . $current_earleme;
        push @data,
            [ $origin_earleme, $current_earleme, $rule, $position, $desc ];
    } ## end for ( ;; )
    my @sorted_data = map { $_->[-1] } sort {
        $a->[0] <=> $b->[0]
	or $a->[1] <=> $b->[1]
	or $a->[2] <=> $b->[2]
	or $a->[3] <=> $b->[3]
    } @data;
    return (join "\n", @sorted_data) . "\n";;
}

sub Marpa::XS::show_rank_ref {
    my ($rank_ref) = @_;
    return 'undef' if not defined $rank_ref;
    return 'SKIP'  if $rank_ref == Marpa::XS::Internal::Value::SKIP;
    return ${$rank_ref};
} ## end sub Marpa::XS::show_rank_ref

sub Marpa::XS::Recognizer::show_fork {
    my ( $recce, $fork_id, $verbose ) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];

    my $or_node_id = $recce_c->fork_or_node($fork_id);
    return if not defined $or_node_id;

    my $text = "o$or_node_id";
    my $parent = $recce_c->fork_parent($fork_id) // q{-};
    CHILD_TYPE: {
        if ( $recce_c->fork_is_cause($fork_id) )
        {
            $text .= "[c$parent]";
            last CHILD_TYPE;
        } ## end if ( $iteration_node->[...])
        if ( $recce_c->fork_is_predecessor($fork_id) )
        {
            $text .= "[p$parent]";
            last CHILD_TYPE;
        } ## end if ( $iteration_node->[...])
        $text .= '[-]';
    } ## end CHILD_TYPE:
    my $or_node_tag = Marpa::XS::Recognizer::or_node_tag($recce, $or_node_id);
    $text        .= " $or_node_tag";

    $text .= ' p';
    $text .= $recce_c->fork_predecessor_is_ready($fork_id) ? '=ok' : '-';
    $text .= ' c';
    $text .= $recce_c->fork_cause_is_ready($fork_id) ? '=ok' : '-';
    $text .= "\n";

    DESCRIBE_CHOICES: {
        my $this_choice = $recce_c->fork_choice($fork_id);
	CHOICE: for (my $choice_ix = 0; ;$choice_ix++) {
	    my $and_node_id = $recce_c->and_node_order_get($or_node_id, $choice_ix);
	    last CHOICE if not defined $and_node_id;
            $text .= " o$or_node_id" . '[' . $choice_ix . ']';
	    if (defined $this_choice and $this_choice == $choice_ix) {
		$text .= q{*};
	    }
            my $and_node_tag =
		 Marpa::XS::Recognizer::and_node_tag($recce, $and_node_id);
            $text .= " ::= a$and_node_id $and_node_tag";
	    $text .= "\n";
        } ## end for my $choice_ix ( 0 .. $#{$choices} )
    } ## end DESCRIBE_CHOICES:
    return $text;
} ## end sub Marpa::XS::Recognizer::show_fork

sub Marpa::XS::Recognizer::show_tree {
    my ( $recce, $verbose ) = @_;
    my $text = q{};
    FORK: for (my $fork_id = 0; 1; $fork_id++) {
        my $fork_text = $recce->show_fork( $fork_id, $verbose );
	last FORK if not defined $fork_text;
	$text .= "$fork_id: $fork_text";
    }
    return $text;
} ## end sub Marpa::XS::Recognizer::show_tree

package Marpa::XS::Internal::Recognizer;
our $DEFAULT_ACTION_VALUE = \undef;

package Marpa::XS::Internal::Value;

sub Marpa::XS::Internal::Recognizer::set_null_values {
    my ($recce) = @_;
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $grammar_c   = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $trace_values =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_VALUES];

    my $rules   = $grammar->[Marpa::XS::Internal::Grammar::RULES];
    my $symbols = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $default_null_value =
        $grammar->[Marpa::XS::Internal::Grammar::DEFAULT_NULL_VALUE];

    my $null_values;
    $#{$null_values} = $#{$symbols};

    SYMBOL: for my $symbol ( @{$symbols} ) {

        my $symbol_id = $symbol->[Marpa::XS::Internal::Symbol::ID];

        next SYMBOL if not $grammar_c->symbol_is_nulling( $symbol_id );

        my $null_value = undef;
        if ( $symbol->[Marpa::XS::Internal::Symbol::NULL_VALUE] ) {
            $null_value =
                ${ $symbol->[Marpa::XS::Internal::Symbol::NULL_VALUE] };
        }
        else {
            $null_value = $default_null_value;
        }
        next SYMBOL if not defined $null_value;

        $null_values->[$symbol_id] = $null_value;

        if ($trace_values) {
            print {$Marpa::XS::Internal::TRACE_FH}
                'Setting null value for symbol ',
                $symbol->[Marpa::XS::Internal::Symbol::NAME],
                ' to ', Data::Dumper->new( [ \$null_value ] )->Terse(1)->Dump
                or Marpa::exception('Could not print to trace file');
        } ## end if ($trace_values)

    } ## end for my $symbol ( @{$symbols} )

    return $null_values;

}    # set_null_values

# Given the grammar and an action name, resolve it to a closure,
# or return undef
sub Marpa::XS::Internal::Recognizer::resolve_semantics {
    my ( $recce, $closure_name ) = @_;
    my $grammar  = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $closures = $recce->[Marpa::XS::Internal::Recognizer::CLOSURES];
    my $trace_actions =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_ACTIONS];

    Marpa::exception(q{Trying to resolve 'undef' as closure name})
        if not defined $closure_name;

    if ( my $closure = $closures->{$closure_name} ) {
        if ($trace_actions) {
            print {$Marpa::XS::Internal::TRACE_FH}
                qq{Resolved "$closure_name" to explicit closure\n}
                or Marpa::exception('Could not print to trace file');
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
                    $grammar->[Marpa::XS::Internal::Grammar::ACTIONS]
            )
            )
        {
            $fully_qualified_name = $actions_package . q{::} . $closure_name;
            last DETERMINE_FULLY_QUALIFIED_NAME;
        } ## end if ( defined( my $actions_package = $grammar->[...]))

        if (defined(
                my $action_object_class =
                    $grammar->[Marpa::XS::Internal::Grammar::ACTION_OBJECT]
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
        print {$Marpa::XS::Internal::TRACE_FH}
            ( $closure ? 'Successful' : 'Failed' )
            . qq{ resolution of "$closure_name" },
            'to ', $fully_qualified_name, "\n"
            or Marpa::exception('Could not print to trace file');
    } ## end if ($trace_actions)

    return $closure;

} ## end sub Marpa::XS::Internal::Recognizer::resolve_semantics

sub Marpa::XS::Internal::Recognizer::set_actions {
    my ($recce)   = @_;
    my $grammar   = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $rules     = $grammar->[Marpa::XS::Internal::Grammar::RULES];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $default_action =
        $grammar->[Marpa::XS::Internal::Grammar::DEFAULT_ACTION];

    my $rule_closures = [];
    my $rule_constants = [];

    my $default_action_closure;
    if ( defined $default_action ) {
        $default_action_closure =
            Marpa::XS::Internal::Recognizer::resolve_semantics( $recce,
            $default_action );
        Marpa::exception(
            "Could not resolve default action named '$default_action'")
            if not $default_action_closure;
    } ## end if ( defined $default_action )

    RULE: for my $rule ( @{$rules} ) {

        my $rule_id = $rule->[Marpa::XS::Internal::Rule::ID];

        if ( my $action = $rule->[Marpa::XS::Internal::Rule::ACTION] ) {
            my $closure =
                Marpa::XS::Internal::Recognizer::resolve_semantics( $recce,
                $action );

            Marpa::exception(qq{Could not resolve action name: "$action"})
                if not defined $closure;
	    $rule_closures ->[$rule_id] = $closure;
            next RULE;
        } ## end if ( my $action = $rule->[Marpa::XS::Internal::Rule::ACTION...])

        # Try to resolve the LHS as a closure name,
        # if it is not internal.
        # If we can't resolve
        # the LHS as a closure name, it's not
        # a fatal error.
	FIND_CLOSURE_BY_LHS: {
	    my $lhs_id = $grammar_c->rule_lhs($rule_id);
	    my $action = $symbols->[$lhs_id]->[Marpa::XS::Internal::Symbol::NAME];
	    last FIND_CLOSURE_BY_LHS if substr($action, -1) eq ']';
	    my $closure =
		Marpa::XS::Internal::Recognizer::resolve_semantics( $recce,
		$action );
	    last FIND_CLOSURE_BY_LHS if not defined $closure;
	    $rule_closures ->[$rule_id] = $closure;
	    next RULE;
	} ## end FIND_CLOSURE_BY_LHS:

        if ( defined $default_action_closure ) {
	    $rule_closures ->[$rule_id] = $default_action_closure;
            next RULE;
        }

        # If there is no default action specified, the fallback
        # is to return an undef
	$rule_constants->[$rule_id] = $Marpa::XS::Internal::Recognizer::DEFAULT_ACTION_VALUE;

    } ## end for my $rule ( @{$rules} )

    $recce->[Marpa::XS::Internal::Recognizer::RULE_CLOSURES] = $rule_closures;
    $recce->[Marpa::XS::Internal::Recognizer::RULE_CONSTANTS] = $rule_constants;

}    # set_actions

# Sub-optimal.
# This routine should be written to do a depth-first traversal.

# Returns false if no parse
sub do_rank_all {
    my ( $recce, $depth_by_id ) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my @and_node_rank_refs;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $rules     = $grammar->[Marpa::XS::Internal::Grammar::RULES];

    my @or_node_rank = ();
    my @and_node_token_rank_ref = ();

    my $cycle_ranking_action =
        $grammar->[Marpa::XS::Internal::Grammar::CYCLE_RANKING_ACTION];
    my $cycle_closure;
    if ( defined $cycle_ranking_action ) {
        $cycle_closure =
            Marpa::XS::Internal::Recognizer::resolve_semantics( $recce,
            $cycle_ranking_action );
        Marpa::exception(
            "Could not resolve cycle ranking action named '$cycle_ranking_action'"
        ) if not $cycle_closure;
    } ## end if ( defined $cycle_ranking_action )

    # Set up rank closures by symbol
    my %ranking_closures_by_symbol = ();
    SYMBOL: for my $symbol ( @{$symbols} ) {
        my $ranking_action =
            $symbol->[Marpa::XS::Internal::Symbol::RANKING_ACTION];
        next SYMBOL if not defined $ranking_action;
        my $ranking_closure =
            Marpa::XS::Internal::Recognizer::resolve_semantics( $recce,
            $ranking_action );
        my $symbol_name = $symbol->[Marpa::XS::Internal::Symbol::NAME];
        Marpa::exception(
            "Could not resolve ranking action for symbol.\n",
            qq{    Symbol was "$symbol_name".},
            qq{    Ranking action was "$ranking_action".}
        ) if not defined $ranking_closure;
        $ranking_closures_by_symbol{$symbol_name} = $ranking_closure;
    }    # end for my $symbol ( @{$symbols} )

    # Get closure used in ranking, by rule
    my @ranking_closures_by_rule = ();
    RULE: for my $rule ( @{$rules} ) {

        my $ranking_action =
            $rule->[Marpa::XS::Internal::Rule::RANKING_ACTION];
	my $rule_id = $rule->[Marpa::XS::Internal::Rule::ID];
        my $cycle_rule = $grammar_c->rule_is_loop($rule_id);

        Marpa::exception(
            "Rule which cycles has an explicit ranking action\n",
            qq{   The ranking action is "$ranking_action"\n},
            qq{   To solve this problem,\n},
            qq{   Rewrite the grammar so that this rule does not cycle\n},
            qq{   Or eliminate its ranking action.\n}
        ) if $ranking_action and $cycle_rule;

        my $ranking_closure;
        if ($ranking_action) {
            $ranking_closure =
                Marpa::XS::Internal::Recognizer::resolve_semantics( $recce,
                $ranking_action );
            Marpa::exception(
                "Ranking closure '$ranking_action' not found")
                if not defined $ranking_closure;
        } ## end if ($ranking_action)

        if ($cycle_rule) {
            $ranking_closure = $cycle_closure;
        }

        next RULE if not $ranking_closure;

	# If the RHS is empty ...
	# Empty rules are never in cycles -- they are either
	# unused (because of the CHAF rewrite) or the special
	# null start rule.
	if ( $grammar_c->rule_length($rule_id) == 0 ) {
	    Marpa::exception("Ranking closure '$ranking_action' not found")
		if not defined $ranking_closure;

	    my $lhs_id = $grammar_c->rule_lhs($rule_id);
	    my $lhs_null_alias =
		$symbols->[ $grammar_c->symbol_null_alias($lhs_id) ];
	    $ranking_closures_by_symbol{ $lhs_null_alias
		    ->[Marpa::XS::Internal::Symbol::NAME] } = $ranking_closure;
	} ## end if ( $grammar_c->rule_length($rule_id) == 0 )

        $ranking_closures_by_rule[$rule_id] = $ranking_closure;

    } ## end for my $rule ( @{$rules} )

    my @and_node_worklist = ();
    AND_NODE: for my $and_node_id ( 0 .. $recce_c->and_node_count()-1 ) {

	my $parent_or_node_id = $recce_c->and_node_parent($and_node_id);
        my $rule_id  = $recce_c->or_node_rule($parent_or_node_id);
	my $semantic_rule_id = $grammar_c->semantic_equivalent($rule_id);
	my $rule_closure = 
	defined $semantic_rule_id ?  $ranking_closures_by_rule[$semantic_rule_id] : undef;
        my $token_id = $recce_c->and_node_symbol($and_node_id);
        my $token_closure;
        if ($token_id) {
            my $token_name =
                $symbols->[$token_id]->[Marpa::XS::Internal::Symbol::NAME];
            $token_closure = $ranking_closures_by_symbol{$token_name};
        }

        my $token_rank_ref;
        my $rule_rank_ref;

        # It is a feature of the ranking closures that they are always
        # called once per instance, even if the result is never used.
        # This sometimes makes for unnecessary calls,
        # but it makes these closures predictable enough
        # to allow their use for side effects.
        EVALUATION:
        for my $evaluation_data (
            [ \$token_rank_ref, $token_closure ],
            [ \$rule_rank_ref,  $rule_closure ]
            )
        {
            my ( $rank_ref_ref, $closure ) = @{$evaluation_data};
            next EVALUATION if not defined $closure;

            my @warnings;
            my $eval_ok;
            my $rank_ref;
            DO_EVAL: {
                local $Marpa::XS::Internal::CONTEXT =
                    [ 'and-node', $and_node_id, $recce ];
                local $SIG{__WARN__} =
                    sub { push @warnings, [ $_[0], ( caller 0 ) ]; };
                $eval_ok = eval { $rank_ref = $closure->(); 1; };
            } ## end DO_EVAL:

            my $fatal_error;
            CHECK_FOR_ERROR: {
                if ( not $eval_ok or scalar @warnings ) {
                    $fatal_error = $EVAL_ERROR // 'Fatal Error';
                    last CHECK_FOR_ERROR;
                }
                if ( defined $rank_ref and not ref $rank_ref ) {
                    $fatal_error =
                        "Invalid return value from ranking closure: $rank_ref";
                }
            } ## end CHECK_FOR_ERROR:

            if ( defined $fatal_error ) {

                Marpa::XS::Internal::code_problems(
                    {   fatal_error => $fatal_error,
                        grammar     => $grammar,
                        eval_ok     => $eval_ok,
                        warnings    => \@warnings,
                        where       => 'ranking and-node '
                            . Marpa::XS::Recognizer::and_node_tag(
                            $recce, $and_node_id
                            )
                    }
                );
            } ## end if ( defined $fatal_error )

            ${$rank_ref_ref} = $rank_ref // Marpa::XS::Internal::Value::SKIP;

        } ## end for my $evaluation_data ( [ \$token_rank_ref, $token_closure...])

        # Set the token rank if there is a token.
        # It is zero if there is no token, or
        # if there is one with no closure.
        # Note: token can never cause a cycle, but they
        # can cause an and-node to be skipped.
        if (defined $token_id) {
            $and_node_token_rank_ref[$and_node_id] =
                $token_rank_ref // \0;
        }

        # See if we can set the rank for this node to a constant.
        my $constant_rank_ref;
        SET_CONSTANT_RANK: {

            if ( defined $token_rank_ref && !ref $token_rank_ref ) {
                $constant_rank_ref = Marpa::XS::Internal::Value::SKIP;
                last SET_CONSTANT_RANK;
            }

            # If we have ranking closure for this rule, the rank
            # is constant:
            # 0 for a non-final node,
            # the result of the closure for a final one
            if ( defined $rule_rank_ref ) {
                $constant_rank_ref =
                    (
                    $recce_c->or_node_position($parent_or_node_id)
                        == $grammar_c->rule_length(
                        $recce_c->or_node_rule($parent_or_node_id)
                        )
                    )
                    ? $rule_rank_ref
                    : \0;
                last SET_CONSTANT_RANK;
            } ## end if ( defined $rule_rank_ref )

            # It there is a token and no predecessor, the rank
            # of this rule is a constant:
            # 0 is there was not token symbol closure
            # the result of that closure if there was one
            if ( defined $token_id
                and not defined $recce_c->and_node_predecessor($and_node_id) )
            {
                $constant_rank_ref = $token_rank_ref // \0;
            }

        } ## end SET_CONSTANT_RANK:

        if ( defined $constant_rank_ref ) {
            $and_node_rank_refs[$and_node_id] =
                $constant_rank_ref;

            next AND_NODE;
        } ## end if ( defined $constant_rank_ref )

        # If we are here there is (so far) no constant rank
        # so we stack this and-node for depth-sensitive evaluation
        push @and_node_worklist, $and_node_id;

    } ## end for my $and_node_id ( 0 .. $#{$and_nodes} )

    # From here on we may be calculating ranks, so use floating point
    no integer;

    # Now go through the and-nodes that require context to be ranked
    # This loop assumes that all cycles has been taken care of
    # with constant ranks
    AND_NODE: while ( defined( my $and_node_id = pop @and_node_worklist ) ) {

        # Go to next if we have already ranked this and-node
        next AND_NODE if defined $and_node_rank_refs[$and_node_id];

        # The rank calculated so far from the
        # children
        my $calculated_rank = 0;

        my $is_cycle = 0;
        my $is_skip  = 0;
        OR_NODE:
        for my $or_node_id (
	    grep { defined }
            $recce_c->and_node_predecessor($and_node_id),
            $recce_c->and_node_cause($and_node_id),
            )
        {
            if (defined(
                    my $or_node_initial_rank_ref =
                        $or_node_rank[$or_node_id]
                )
                )
            {
                if ( ref $or_node_initial_rank_ref ) {
                    $calculated_rank += ${$or_node_initial_rank_ref};
                    next OR_NODE;
                }

                # At this point only possible value is skip
                $and_node_rank_refs[$and_node_id] =
                    Marpa::XS::Internal::Value::SKIP;

                next AND_NODE;
            } ## end if ( defined( my $or_node_initial_rank_ref = $or_node...))
            my @ranks              = ();
            my @unranked_and_nodes = ();
	    my @and_node_ids =
		( $recce_c->or_node_first_and($or_node_id)
		    .. $recce_c->or_node_last_and($or_node_id) );
            CHILD_AND_NODE:
            for my $child_and_node_id ( @and_node_ids ) {
                my $rank_ref = $and_node_rank_refs[$child_and_node_id];
                if ( not defined $rank_ref ) {
                    push @unranked_and_nodes, $child_and_node_id;

                    next CHILD_AND_NODE;
                } ## end if ( not defined $rank_ref )

                # Right now the only defined scalar value for a rank is
                # Marpa::XS::Internal::Value::SKIP
                next CHILD_AND_NODE if not ref $rank_ref;

                push @ranks, ${$rank_ref};

            } ## end for my $child_and_node_id ( @{ $or_node->[...]})

            # If we have unranked child and nodes, those have to be
            # ranked first.  Schedule the work and move on.
            if ( scalar @unranked_and_nodes ) {

                push @and_node_worklist, $and_node_id, @unranked_and_nodes;
                next AND_NODE;
            }

            # If there were no non-skipped and-nodes, the
            # parent and-node must also be skipped
            if ( not scalar @ranks ) {
                $or_node_rank[$or_node_id] =
                    $and_node_rank_refs[$and_node_id] =
                    Marpa::XS::Internal::Value::SKIP;

                next AND_NODE;
            } ## end if ( not scalar @ranks )

            my $or_calculated_rank = List::Util::max @ranks;
	    $or_node_rank[$or_node_id] = \$or_calculated_rank;
            $calculated_rank += $or_calculated_rank;

        } ## end for my $field ( ...)

        my $token_rank_ref = $and_node_token_rank_ref[$and_node_id];
        $calculated_rank += defined $token_rank_ref ? ${$token_rank_ref} : 0;
	$and_node_rank_refs[$and_node_id] = \$calculated_rank;

    } ## end while ( defined( my $and_node_id = pop @and_node_worklist...))

    my @or_node_choices = ();
    AND_NODE: for my $and_node_id (0 .. $#and_node_rank_refs) {
	my $rank_ref = $and_node_rank_refs[$and_node_id];
	next AND_NODE if $rank_ref == Marpa::XS::Internal::Value::SKIP;
	my $or_node_id = $recce_c->and_node_parent($and_node_id);
	push @{$or_node_choices[$or_node_id]}, [ ${$rank_ref}, $and_node_id ];
    }

    OR_NODE: for my $or_node_id (0 .. $#or_node_choices) {
	my $choices = $or_node_choices[$or_node_id] // [];
	## no critic (BuiltinFunctions::ProhibitReverseSortBlock)
        my @and_node_ids = map { $_->[-1] } sort { $b->[0] <=> $a->[0] } @{$choices};
	$recce_c->and_node_order_set($or_node_id, \@and_node_ids);
    } ## end for my $or_node_id ( 0 .. $recce_c->or_node_count() -...)

    return;

} ## end sub do_rank_all

# Does not modify stack
sub Marpa::XS::Internal::Recognizer::evaluate {
    my ($recce)     = @_;
    my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $null_values = $recce->[Marpa::XS::Internal::Recognizer::NULL_VALUES];
    my $grammar     = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $token_values =
        $recce->[Marpa::XS::Internal::Recognizer::TOKEN_VALUES];
    my $grammar_c    = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols      = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $trace_values = $recce->[Marpa::XS::Internal::Recognizer::TRACE_VALUES]
        // 0;

    my $rule_constants =
        $recce->[Marpa::XS::Internal::Recognizer::RULE_CONSTANTS];
    my $rule_closures =
        $recce->[Marpa::XS::Internal::Recognizer::RULE_CLOSURES];

    my $action_object_class =
        $grammar->[Marpa::XS::Internal::Grammar::ACTION_OBJECT];

    my $action_object_constructor;
    if ( defined $action_object_class ) {
        my $constructor_name = $action_object_class . q{::new};
        my $closure =
            Marpa::XS::Internal::Recognizer::resolve_semantics( $recce,
            $constructor_name );
        Marpa::exception(qq{Could not find constructor "$constructor_name"})
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
            Marpa::XS::Internal::code_problems(
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

    my $eval = [];
    my @evaluation_stack = ();
    my $virtual_evaluation_stack = $eval->[Marpa::XS::Internal::Eval::VEVAL_STACK] = [];
    $eval->[Marpa::XS::Internal::Eval::EVAL_TOS] = -1;
    $eval->[Marpa::XS::Internal::Eval::FORK_IX] = -1;
    $eval->[Marpa::XS::Internal::Eval::TRACE_VAL] = $trace_values ? 1 : 0;

    EVENT:
    while ( my ( $token_id, $value_ix, $rule_id, $arg_0, $arg_n ) =
        Marpa::XS::Internal::Recognizer::event( $recce, $eval ) )
    {
        if ( $trace_values >= 3 ) {
            for my $i ( reverse 0 .. $arg_n ) {
                printf {$Marpa::XS::Internal::TRACE_FH} 'Stack position %3d:',
                    $i
                    or Marpa::exception('print to trace handle failed');
                print {$Marpa::XS::Internal::TRACE_FH} q{ },
                    Data::Dumper->new( [ $evaluation_stack[$i] ] )->Terse(1)
                    ->Dump
                    or Marpa::exception('print to trace handle failed');
            } ## end for my $i ( reverse 0 .. $arg_n )
        } ## end if ( $trace_values >= 3 )

	ADD_TOKEN: {
	    last ADD_TOKEN if not defined $token_id;
	    my $value_ref =
		$value_ix < 0
		? \$null_values->[$token_id]
		: \( $token_values->[$value_ix] );

	    $evaluation_stack[$arg_n] = $value_ref;

	    last ADD_TOKEN if not $trace_values;

	    my $fork_ix    = $eval->[Marpa::XS::Internal::Eval::FORK_IX];
	    my $or_node_id = $recce_c->fork_or_node($fork_ix);
	    my $choice     = $recce_c->fork_choice($fork_ix);
	    my $and_node_id =
		$recce_c->and_node_order_get( $or_node_id, $choice );
	    my $token_id = $recce_c->and_node_symbol($and_node_id);
	    my $token_name;
	    if ( defined $token_id ) {
		$token_name =
		    $symbols->[$token_id]->[Marpa::XS::Internal::Symbol::NAME];
	    }

	    print {$Marpa::XS::Internal::TRACE_FH}
		'Pushed value from ',
		Marpa::XS::Recognizer::and_node_tag( $recce, $and_node_id ),
		': ',
		( $token_name ? qq{$token_name = } : q{} ),
		Data::Dumper->new( [$value_ref] )->Terse(1)->Dump
		or Marpa::exception('print to trace handle failed');

	} ## end ADD_TOKEN:

	TRACE_OP: {

            last TRACE_OP if not $trace_values;

	    my $fork_ix = $eval->[Marpa::XS::Internal::Eval::FORK_IX];
	    my $or_node_id = $recce_c->fork_or_node($fork_ix);
	    my $choice     = $recce_c->fork_choice($fork_ix);
	    my $and_node_id =
		$recce_c->and_node_order_get( $or_node_id, $choice );
	    my $trace_rule_id    = $recce_c->or_node_rule($or_node_id);
	    my $virtual_rhs = $grammar_c->rule_is_virtual_rhs($trace_rule_id);
	    my $virtual_lhs = $grammar_c->rule_is_virtual_lhs($trace_rule_id);

	    next EVENT if  $recce_c->or_node_position($or_node_id)
                != $grammar_c->rule_length($trace_rule_id) ;

            if ( not $virtual_rhs and not $virtual_lhs ) {

                my $argc = $grammar_c->rule_length($trace_rule_id);

                say {$Marpa::XS::Internal::TRACE_FH} 'Popping ', $argc,
                    ' values to evaluate ',
                    Marpa::XS::Recognizer::and_node_tag(
                    $recce, $and_node_id
                    ),
                    ', rule: ', $grammar->brief_rule($trace_rule_id)
                    or Marpa::exception('Could not print to trace file');

                last TRACE_OP;

            } ## end if ( not $virtual_rhs and not $virtual_lhs )

            if ( $virtual_rhs and not $virtual_lhs ) {

                say {$Marpa::XS::Internal::TRACE_FH}
                    'Head of Virtual Rule: ',
                    Marpa::XS::Recognizer::and_node_tag(
                    $recce, $and_node_id
                    ),
                    ', rule: ', $grammar->brief_rule($trace_rule_id),
                    "\n",
                    "Incrementing virtual rule by ",
                    $grammar_c->real_symbol_count($trace_rule_id),
                    " symbols\n",
                    'Currently ',
                    ( scalar @{$virtual_evaluation_stack} ),
                    ' rules; ', ( $virtual_evaluation_stack->[-1] // 0 ),
                    ' symbols;',
                    or Marpa::exception('Could not print to trace file');

                last TRACE_OP;

            } ## end if ( $virtual_rhs and not $virtual_lhs )

            if ( $virtual_lhs and $virtual_rhs ) {

                say {$Marpa::XS::Internal::TRACE_FH}
                    'Virtual Rule: ',
                    Marpa::XS::Recognizer::and_node_tag(
                    $recce, $and_node_id
                    ),
                    ', rule: ', $grammar->brief_rule($trace_rule_id),
                    "\nAdding ",
                    $grammar_c->real_symbol_count($trace_rule_id),
                    ", now ",
                    ( scalar @{$virtual_evaluation_stack} ),
                    ' rules; ', $virtual_evaluation_stack->[-1], ' symbols'
                    or Marpa::exception('Could not print to trace file');

                next EVENT;

            } ## end if ( $virtual_lhs and $virtual_rhs )

            if ( not $virtual_rhs and $virtual_lhs ) {

                say {$Marpa::XS::Internal::TRACE_FH}
                    'New Virtual Rule: ',
                    Marpa::XS::Recognizer::and_node_tag(
                    $recce, $and_node_id
                    ),
                    ', rule: ', $grammar->brief_rule($trace_rule_id),
                    "\nSymbol count is ",
		    $grammar_c->real_symbol_count($trace_rule_id),
                    ", now ",
                    ( scalar @{$virtual_evaluation_stack} ), ' rules',
                    or Marpa::exception('Could not print to trace file');

                next EVENT;

            } ## end if ( not $virtual_rhs and $virtual_lhs )

        } ## end TRACE_OP:

	next EVENT if not defined $rule_id;

        my $closure = $rule_closures->[$rule_id];
        if ( defined $closure ) {
            my $result;

            my @args = map { ${$_} } @evaluation_stack[ $arg_0 .. $arg_n ];
            if ( $grammar_c->rule_is_discard_separation($rule_id) ) {
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
                Marpa::XS::Internal::code_problems(
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
                print {$Marpa::XS::Internal::TRACE_FH}
                    'Calculated and pushed value: ',
                    Data::Dumper->new( [$result] )->Terse(1)->Dump
                    or Marpa::exception('print to trace handle failed');
            } ## end if ($trace_values)

            next EVENT;

        } ## end if ( defined $closure )

        {
            my $constant_result = $rule_constants->[$rule_id];
            $evaluation_stack[$arg_0] = $constant_result;
            if ($trace_values) {
                print {$Marpa::XS::Internal::TRACE_FH}
                    'Constant result: ',
                    'Pushing 1 value on stack: ',
                    Data::Dumper->new( [$constant_result] )->Terse(1)->Dump
                    or Marpa::exception('Could not print to trace file');
            } ## end if ($trace_values)
        } ## end when (Marpa::XS::Internal::Op::CONSTANT_RESULT)
    } ## end while ( my @event = Marpa::XS::Internal::Recognizer::event...)
    
    my $top_value = $evaluation_stack[0];

    return $top_value;

} ## end sub Marpa::XS::Internal::Recognizer::evaluate

sub Marpa::XS::Internal::Recognizer::event {
    my ($recce, $eval)     = @_;
    my $recce_c     = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $grammar_c   = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $trace_val = $eval->[Marpa::XS::Internal::Eval::TRACE_VAL];
    my $virtual_evaluation_stack = $eval->[Marpa::XS::Internal::Eval::VEVAL_STACK];

    if ( $eval->[Marpa::XS::Internal::Eval::FORK_IX] < 0) {
        $eval->[Marpa::XS::Internal::Eval::FORK_IX] = $recce_c->tree_size();
    }

    my $arg_0;
    my $arg_n;
    my $token_id;
    my $value_ix;
    my $semantic_rule_id;
    my $continue = 1;

    TREE_NODE:
    while ($continue) {

	$continue = !$trace_val;

	my $fork_ix = --$eval->[Marpa::XS::Internal::Eval::FORK_IX];

	return if $fork_ix < 0;

	$arg_0 = $arg_n = $eval->[Marpa::XS::Internal::Eval::EVAL_TOS];

        my $or_node_id = $recce_c->fork_or_node($fork_ix);
        my $rule_id    = $recce_c->or_node_rule($or_node_id);
        my $choice     = $recce_c->fork_choice($fork_ix);

        my $and_node_id =
            $recce_c->and_node_order_get( $or_node_id, $choice );

	($token_id, $value_ix) = $recce_c->and_node_token($and_node_id);
	if (defined $token_id) {
	    $arg_0 = $arg_n = ++$eval->[Marpa::XS::Internal::Eval::EVAL_TOS];
	    $continue = 0;
	}

	next TREE_NODE if  $recce_c->or_node_position($or_node_id)
                != $grammar_c->rule_length($rule_id) ;

        my $virtual_rhs = $grammar_c->rule_is_virtual_rhs($rule_id);
        my $virtual_lhs = $grammar_c->rule_is_virtual_lhs($rule_id);

        OP: {

            if ( not $virtual_rhs and not $virtual_lhs ) {
                my $argc = $grammar_c->rule_length($rule_id);
		$arg_0 = $arg_n - $argc + 1;
		$eval->[Marpa::XS::Internal::Eval::EVAL_TOS] = $arg_0;
		last OP;
            } ## end if ( $op == Marpa::XS::Internal::Op::ARGC )

            if ( $virtual_rhs and not $virtual_lhs ) {
                my $real_symbol_count = $grammar_c->real_symbol_count($rule_id);
                $real_symbol_count += pop @{$virtual_evaluation_stack};
		$arg_0 = $arg_n - $real_symbol_count + 1;
		$eval->[Marpa::XS::Internal::Eval::EVAL_TOS] = $arg_0;
		last OP;
            } ## end if ( $op == Marpa::XS::Internal::Op::VIRTUAL_HEAD )

            if ( $virtual_lhs and $virtual_rhs ) {
                my $real_symbol_count = $grammar_c->real_symbol_count($rule_id);
                $virtual_evaluation_stack->[-1] += $real_symbol_count;
                next TREE_NODE;
            } ## end if ( $op == Marpa::XS::Internal::Op::VIRTUAL_KERNEL )

            if ( not $virtual_rhs and $virtual_lhs ) {
                my $real_symbol_count = $grammar_c->real_symbol_count($rule_id);
                push @{$virtual_evaluation_stack}, $real_symbol_count;
                next TREE_NODE;
            } ## end if ( $op == Marpa::XS::Internal::Op::VIRTUAL_TAIL )

        } ## end for ( my $op_ix = 0; $op_ix < scalar @{$ops}; $op_ix++)

        $semantic_rule_id = $grammar_c->semantic_equivalent($rule_id);
	if (defined $semantic_rule_id) { $continue = 0; }

    }    # TREE_NODE

    return ($token_id, $value_ix, $semantic_rule_id, $arg_0, $arg_n);

}

# Returns false if no parse
sub Marpa::XS::Recognizer::value {
    my ( $recce, @arg_hashes ) = @_;

    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];

    my $parse_set_arg = $recce->[Marpa::XS::Internal::Recognizer::END];

    local $Marpa::XS::Internal::TRACE_FH =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE];

    if ( $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] ) {
        Marpa::exception(
            qq{Arguments were passed directly to value() in a previous call\n},
            qq{Only one call to value() is allowed per recognizer when arguments are passed directly\n},
            qq{This is the second call to value()\n}
        );
    } ## end if ( $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE...])

    my $parse_count = $recce_c->parse_count() // 0;
    my $max_parses  = $recce->[Marpa::XS::Internal::Recognizer::MAX_PARSES];
    if ( $max_parses and $parse_count > $max_parses ) {
        Marpa::exception("Maximum parse count ($max_parses) exceeded");
    }

    for my $arg_hash (@arg_hashes) {

        if ( exists $arg_hash->{end} ) {
            if ($parse_count) {
                Marpa::exception(
                    q{Cannot change "end" after first parse result});
            }
            $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = 1;
            $parse_set_arg = $arg_hash->{end};
            delete $arg_hash->{end};
        } ## end if ( exists $arg_hash->{end} )

        if ( exists $arg_hash->{closures} ) {
            if ($parse_count) {
                Marpa::exception(
                    q{Cannot change "closures" after first parse result});
            }
            $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = 1;
            my $closures = $arg_hash->{closures};
            while ( my ( $action, $closure ) = each %{$closures} ) {
                Marpa::exception(qq{Bad closure for action "$action"})
                    if ref $closure ne 'CODE';
            }
            $recce->[Marpa::XS::Internal::Recognizer::CLOSURES] = $closures;
            delete $arg_hash->{closures};
        } ## end if ( exists $arg_hash->{closures} )

        if ( exists $arg_hash->{trace_actions} ) {
            $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = 1;
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_ACTIONS] =
                $arg_hash->{trace_actions};
            delete $arg_hash->{trace_actions};
        } ## end if ( exists $arg_hash->{trace_actions} )

        if ( exists $arg_hash->{trace_values} ) {
            $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = 1;
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_VALUES] =
                $arg_hash->{trace_values};
            delete $arg_hash->{trace_values};
        } ## end if ( exists $arg_hash->{trace_values} )

        # A typo made its way into the documentation, so now it's a
        # synonym.
        for my $trace_fh_alias (qw(trace_fh trace_file_handle)) {
            if ( exists $arg_hash->{$trace_fh_alias} ) {
                $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE] =
                    $Marpa::XS::Internal::TRACE_FH =
                    $arg_hash->{$trace_fh_alias};
                delete $arg_hash->{$trace_fh_alias};
            } ## end if ( exists $arg_hash->{$trace_fh_alias} )
        } ## end for my $trace_fh_alias (qw(trace_fh trace_file_handle))

        my @unknown_arg_names = keys %{$arg_hash};
        Marpa::exception(
            'Unknown named argument(s) to Marpa::XS::Recognizer::value: ',
            ( join q{ }, @unknown_arg_names ) )
            if @unknown_arg_names;

    } ## end for my $arg_hash (@arg_hashes)

    my $furthest_earleme = $recce_c->furthest_earleme();
    my $last_completed_earleme = $recce_c->current_earleme();
    Marpa::exception(
        "Attempt to evaluate incompletely recognized parse:\n",
        "  Last token ends at location $furthest_earleme\n",
        "  Recognition done only as far as location $last_completed_earleme\n"
    ) if $furthest_earleme > $last_completed_earleme;

    my $top_or_node_id;
    if ( not $parse_count ) {

	# Perhaps this call should be moved.
	# The null values are currently a function of the grammar,
	# and should be constant for the life of a recognizer.
	$recce->[Marpa::XS::Internal::Recognizer::NULL_VALUES] //=
	    Marpa::XS::Internal::Recognizer::set_null_values($recce);
	Marpa::XS::Internal::Recognizer::set_actions($recce);

        $recce_c->eval_clear();
        $top_or_node_id =
            $recce_c->eval_setup( -1, ( $parse_set_arg // -1 ) );
        if ( not defined $top_or_node_id ) {
            Marpa::exception(qq{libmarpa's marpa_value() call failed\n});
        }

	if ( $recce->[Marpa::XS::Internal::Recognizer::RANKING_METHOD] eq
	    'constant' )
	{
	    do_rank_all($recce);
	}

    }

    if ($recce->[Marpa::XS::Internal::Recognizer::TRACE_AND_NODES]) {
	print {$Marpa::XS::Internal::TRACE_FH} 'AND_NODES: ',
	    $recce->show_and_nodes()
	or Marpa::exception('print to trace handle failed');
    }

    if ($recce->[Marpa::XS::Internal::Recognizer::TRACE_OR_NODES]) {
	print {$Marpa::XS::Internal::TRACE_FH} 'OR_NODES: ',
	    $recce->show_or_nodes()
	or Marpa::exception('print to trace handle failed');
    }

    if ($recce->[Marpa::XS::Internal::Recognizer::TRACE_BOCAGE]) {
	print {$Marpa::XS::Internal::TRACE_FH} 'BOCAGE: ',
	    $recce->show_bocage()
	or Marpa::exception('print to trace handle failed');
    }

    $recce_c->tree_new();
    return if not defined $recce_c->tree_size();
    return Marpa::XS::Internal::Recognizer::evaluate( $recce );

} ## end sub Marpa::XS::Recognizer::value

1;
