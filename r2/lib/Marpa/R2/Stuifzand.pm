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

package Marpa::R2::Stuifzand;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.023_008';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::Stuifzand;

use English qw( -no_match_vars );

# This rule is used by the semantics of the *GENERATED*
# grammars, not the Stuifzand grammar itself.
sub external_do_arg0 {
   return $_[1];
}

sub do_rules {
    shift;
    return [ map { @{$_} } @_ ];
}

sub do_priority_rule {
    my ( undef, $lhs, undef, $priorities ) = @_;
    my $priority_count = scalar @{$priorities};
    my @rules          = ();
    my @xs_rules = ();
    if ( $priority_count <= 1 ) {
        ## If there is only one priority
        for my $alternative ( @{ $priorities->[0] } ) {
            my ( $rhs, $adverb_list ) = @{ $alternative };
            my %hash_rule = ( lhs => $lhs, rhs => $rhs );
            my $action = $adverb_list->{action};
            $hash_rule{action} = $action if defined $action;
            push @xs_rules, \%hash_rule;
        }
        return [@xs_rules];
    }

    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        for my $alternative ( @{ $priorities->[$priority_ix] } ) {
            push @rules, [ $priority, @{$alternative} ];
        }
    } ## end for my $priority_ix ( 0 .. $priority_count - 1 )

    state $do_arg0_full_name = __PACKAGE__ . q{::} . 'external_do_arg0';
    @xs_rules = (
        {   lhs    => $lhs,
            rhs    => [ $lhs . '[prec0]' ],
            action => $do_arg0_full_name
        },
        (   map {
                ;
                {   lhs => ( $lhs . '[prec' . ( $_ - 1 ) . ']'),
                    rhs => [ $lhs . '[prec' . $_ . ']'],
                    action => $do_arg0_full_name
                }
            } 1 .. $priority_count - 1
        )
    );
    RULE: for my $rule (@rules) {
        my ( $priority, $rhs, $adverb_list ) = @{$rule};
        my $assoc = $adverb_list->{assoc} // 'L';
        my @new_rhs = @{$rhs};
        my @arity   = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $length  = scalar @{$rhs};

        my $current_exp = $lhs . '[prec' . $priority . ']';
        my %new_xs_rule = (lhs => $current_exp);

        my $action = $adverb_list->{action};
        $new_xs_rule{action} = $action if defined $action;

        my $next_priority = $priority + 1;
        $next_priority = 0 if $next_priority >= $priority_count;
        my $next_exp = $lhs . '[prec' . $next_priority . ']';

        if ( not scalar @arity ) {
            $new_xs_rule{rhs} = \@new_rhs;
            push @xs_rules, \%new_xs_rule;
            next RULE;
        }

        if ( scalar @arity == 1 ) {
            die 'Unnecessary unit rule in priority rule' if $length == 1;
            $new_rhs[ $arity[0] ] = $current_exp;
        }
        DO_ASSOCIATION: {
            if ( $assoc eq 'L' ) {
                $new_rhs[ $arity[0] ] = $current_exp;
                for my $rhs_ix ( @arity[ 1 .. $#arity ] ) {
                    $new_rhs[$rhs_ix] = $next_exp;
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'L' )
            if ( $assoc eq 'R' ) {
                $new_rhs[ $arity[-1] ] = $current_exp;
                for my $rhs_ix ( @arity[ 0 .. $#arity - 1 ] ) {
                    $new_rhs[$rhs_ix] = $next_exp;
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'R' )
            if ( $assoc eq 'G' ) {
                for my $rhs_ix ( @arity[ 0 .. $#arity ] ) {
                    $new_rhs[$rhs_ix] = $lhs . '[prec0]';
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'G' )
            die qq{Unknown association type: "$assoc"};
        } ## end DO_ASSOCIATION:

        $new_xs_rule{rhs} = \@new_rhs;
        push @xs_rules, \%new_xs_rule;
    } ## end RULE: for my $rule (@rules)
    return [@xs_rules];
} ## end sub do_priority_rule

sub do_empty_rule {
    my ( undef, $lhs, undef, $adverb_list ) = @_;
    my $action = $adverb_list->{action};
    return [ { lhs => $lhs, rhs => [], @{ $action || [] } } ];
}

sub do_quantified_rule {
    my ( undef, $lhs, undef, $rhs, $quantifier, $adverb_list ) = @_;
    my %hash_rule = (
        lhs => $lhs,
        rhs => [$rhs],
        min => ( $quantifier eq q{+} ? 1 : 0 )
    );
    my $action = $adverb_list->{action};
    $hash_rule{action} = $action if defined $action;
    my $separator = $adverb_list->{separator};
    $hash_rule{separator} = $separator if defined $separator;
    return [ \%hash_rule ];
} ## end sub do_quantified_rule

sub do_lhs { shift; return $_[0]; }
sub do_adverb_list { shift; return { map {; @{$_}} @_ } }

# Given a grammar,
# a recognizer and a symbol
# return the start and end earley sets
# of the last such symbol completed,
# undef if there was none.
sub last_completed_range {
    my ( $tracer, $thin_recce, $symbol_name ) = @_;
    my $thin_grammar = $tracer->grammar();
    my $symbol_id = $tracer->symbol_by_name($symbol_name);
    my @sought_rules =
        grep { $thin_grammar->rule_lhs($_) == $symbol_id; }
        0 .. $thin_grammar->highest_rule_id();
    die "Looking for completion of non-existent rule lhs: $symbol_name"
        if not scalar @sought_rules;
    my $latest_earley_set = $thin_recce->latest_earley_set();
    my $earley_set        = $latest_earley_set;

    # Initialize to one past the end, so we can tell if there were no hits
    my $first_origin = $latest_earley_set + 1;
    EARLEY_SET: while ( $earley_set >= 0 ) {
        $thin_recce->progress_report_start($earley_set);
        ITEM: while (1) {
            my ( $rule_id, $dot_position, $origin ) = $thin_recce->progress_item();
            last ITEM if not defined $rule_id;
            next ITEM if $dot_position != -1;
            next ITEM if not scalar grep { $_ == $rule_id } @sought_rules;
            next ITEM if $origin >= $first_origin;
            $first_origin = $origin;
        }
        $thin_recce->progress_report_finish();
        last EARLEY_SET if $first_origin <= $latest_earley_set;
        $earley_set--;
    } ## end EARLEY_SET: while ( $earley_set >= 0 )
    return if $earley_set < 0;
    return ( $first_origin, $earley_set );
} ## end sub last_completed_range

# Given a string, an earley set to position mapping,
# and two earley sets, return the slice of the string
sub input_slice {
    my ( $input, $positions, $start, $end ) = @_;
    return if not defined $start;
    my $start_position = $positions->[$start];
    my $length         = $positions->[$end] - $start_position;
    return substr $input, $start_position, $length;
} ## end sub input_slice

sub stuifzand_grammar {
    my $grammar = Marpa::R2::Thin::G->new( { if => 1 } );
    my $tracer = Marpa::R2::Thin::Trace->new($grammar);
    my @reserved_words = qw( action assoc separator
        left right group);
    $tracer->sequence_new( do_rules => qw(rules rule), { min => 1 } );
    $tracer->rule_new( undef, qw(rule empty_rule) );
    $tracer->rule_new( undef, qw(rule priority_rule) );
    $tracer->rule_new( undef, qw(rule quantified_rule) );
    $tracer->rule_new(
        do_priority_rule => qw(priority_rule lhs op_declare priorities) );
    $tracer->rule_new(
        do_empty_rule => qw(empty_rule lhs op_declare adverb_list) );
    $tracer->rule_new( do_quantified_rule =>
            qw(quantified_rule lhs op_declare name quantifier adverb_list) );
    $tracer->sequence_new(
        do_discard_separators => qw(priorities alternatives),
        { min => 1, separator => 'op_tighter', proper => 1 }
    );
    $tracer->sequence_new(
        do_discard_separators => qw(alternatives alternative),
        { min => 1, separator => 'op_eq_pri', proper => 1 }
    );
    $tracer->rule_new( do_alternative => qw(alternative rhs adverb_list) );
    $tracer->sequence_new(
        do_adverb_list => qw(adverb_list adverb_item),
        { min => 0 }
    );
    $tracer->rule_new( undef, qw(adverb_item action) );
    $tracer->rule_new( undef, qw(adverb_item left_association) );
    $tracer->rule_new( undef, qw(adverb_item right_association) );
    $tracer->rule_new( undef, qw(adverb_item group_association) );
    $tracer->rule_new( undef, qw(adverb_item separator_specification) );
    $tracer->rule_new( do_action => qw(action kw_action op_arrow name) );
    $tracer->rule_new(
        do_left_association => qw(left_association kw_assoc op_arrow kw_left) );
    $tracer->rule_new(
        do_right_association => qw(right_association kw_assoc op_arrow kw_right) );
    $tracer->rule_new(
        do_group_association => qw(group_association kw_assoc op_arrow kw_group) );
    $tracer->rule_new(
        do_separator_specification => qw(separator_specification kw_separator op_arrow name ) );
    $tracer->rule_new( do_lhs => qw( lhs name ) );
    $tracer->rule_new( undef, qw( rhs names ) );
    $tracer->rule_new( undef, qw( quantifier op_star ) );
    $tracer->rule_new( undef, qw( quantifier op_plus ) );
    $tracer->sequence_new( do_array => qw(names name), { min => 1 } );
    $tracer->rule_new( undef, qw( name bare_name ) );
    $tracer->rule_new( undef, qw( name reserved_word ) );
    $tracer->rule_new( undef, qw( name quoted_name ) );
    $tracer->rule_new( do_bracketed_name => qw( name bracketed_name ) );
    for my $reserved_word (@reserved_words) {
        $tracer->rule_new( undef, 'reserved_word', "kw_$reserved_word" );
    }
    $grammar->start_symbol_set( $tracer->symbol_by_name('rules') );
    $grammar->precompute();
    return {tracer => $tracer, reserved_words => \@reserved_words};
} ## end sub stuifzand_grammar

sub last_rule {
   my ($tracer, $thin_recce, $string, $positions) = @_;
        return input_slice( $string, $positions,
            last_completed_range( $tracer, $thin_recce, 'rule') )
            // 'No rule was completed';
}

sub parse_rules {
    my ($string) = @_;

    # Track earley set positions in input,
    # for debuggging
    my @positions = (0);

    state $stuifzand_grammar = stuifzand_grammar();
    state $tracer            = $stuifzand_grammar->{tracer};
    state $reserved_words    = $stuifzand_grammar->{reserved_words};
    state $thin_grammar      = $tracer->grammar();
    my $recce = Marpa::R2::Thin::R->new($thin_grammar);
    $recce->start_input();
    $recce->ruby_slippers_set(1);

    # Zero position must not be used
    my @token_values = (0);

    # Order matters !!!
    my @terminals = ();
    for my $reserved_word ( @{$reserved_words} ) {
        push @terminals,
            [
            'kw_' . $reserved_word,
            qr/$reserved_word\b/xms,
            qq{"$reserved_word" keyword}
            ];
    } ## end for my $reserved_word ( @{$reserved_words} )
    push @terminals,
        [ 'op_declare', qr/::=/xms,    'BNF declaration operator' ],
        [ 'op_arrow',   qr/=>/xms,     'adverb operator' ],
        [ 'op_tighter', qr/[|][|]/xms, 'tighten-precedence operator' ],
        [ 'op_eq_pri',  qr/[|]/xms,    'alternative operator' ],
        [ 'op_plus',    qr/[+]/xms,    'plus quantification operator' ],
        [ 'op_star',    qr/[*]/xms,    'star quantification operator' ],
        [ 'bare_name',  qr/\w+/xms, ],
        [ 'bracketed_name', qr/ [<] \w+ [>] /xms, ],
        [ 'quoted_name',    qr/['][^']+[']/xms ],
        ## [ 'reserved_name', qr/(::(whatever|undef))/xms ]
        ;

    my $length = length $string;
    pos $string = 0;
    my $latest_earley_set_ID = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip comment
        next TOKEN if $string =~ m/\G \s* [#] [^\n]* \n/gcxms;

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;
            my $value_number = -1 + push @token_values, $1;
            my $string_position = pos $string;
            if ($recce->alternative( $tracer->symbol_by_name( $t->[0] ),
                    $value_number, 1 ) != $Marpa::R2::Error::NONE
                )
            {
                my $problem_position = $positions[-1];
                die qq{Last rule successfully parsed was: },
                    last_rule( $tracer, $recce, $string, \@positions ),
                    "\n", q{Problem near position }, $problem_position,
                    q{: "},
                    ( substr $string, $problem_position, 40 ), qq{"\n},
                    qq{Token rejected, "$1", }, ( $t->[2] // $t->[0] ), "\n";
            } ## end if ( $recce->alternative( $tracer->symbol_by_name( $t...)))
            $recce->earleme_complete();
            $latest_earley_set_ID = $recce->latest_earley_set();
            $positions[$latest_earley_set_ID] = $string_position;
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    $thin_grammar->throw_set(0);
    my $bocage        = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
    $thin_grammar->throw_set(1);
    if ( !defined $bocage ) {
        ## say STDERR $recce->show_progress() or die "say failed: $ERRNO";
        die qq{Last rule successfully parsed was: },
            last_rule( $tracer, $recce, $string, \@positions ),
            'Parse failed';
    } ## end if ( !defined $bocage )

    my $order         = Marpa::R2::Thin::O->new($bocage);
    my $tree          = Marpa::R2::Thin::T->new($order);
    $tree->next();
    my $valuator = Marpa::R2::Thin::V->new($tree);
    my @actions_by_rule_id;
    for my $rule_id ( grep { $thin_grammar->rule_length($_); }
        0 .. $thin_grammar->highest_rule_id() )
    {
        $valuator->rule_is_valued_set( $rule_id, 1 );
        $actions_by_rule_id[$rule_id] = $tracer->action($rule_id);
    }

    my @stack = ();
    STEP: while (1) {
        my ( $type, @step_data ) = $valuator->step();
        last STEP if not defined $type;
        if ( $type eq 'MARPA_STEP_TOKEN' ) {
            my ( undef, $token_value_ix, $arg_n ) = @step_data;
            $stack[$arg_n] = $token_values[$token_value_ix];
            next STEP;
        }
        if ( $type eq 'MARPA_STEP_RULE' ) {
            my ( $rule_id, $arg_0, $arg_n ) = @step_data;
            my $action = $actions_by_rule_id[$rule_id];
            if ( not defined $action ) {

                # No-op -- value is arg 0
                next STEP;
            }
            if ( $action eq 'do_rules' ) {
                $stack[$arg_0] =
                    do_rules( undef, @stack[ $arg_0 .. $arg_n ] );
                next STEP;
            }
            if ( $action eq 'do_priority_rule' ) {
                $stack[$arg_0] =
                    do_priority_rule( undef, @stack[ $arg_0 .. $arg_n ] );
                next STEP;
            }
            if ( $action eq 'do_empty_rule' ) {
                $stack[$arg_0] =
                    do_empty_rule( undef, @stack[ $arg_0 .. $arg_n ] );
                next STEP;
            }
            if ( $action eq 'do_quantified_rule' ) {
                $stack[$arg_0] =
                    do_quantified_rule( undef, @stack[ $arg_0 .. $arg_n ] );
                next STEP;
            }
            if ( $action eq 'do_alternative' ) {
                $stack[$arg_0] = [ @stack[ $arg_0 .. $arg_n ] ];
                next STEP;
            }
            if ( $action eq 'do_bracketed_name' ) {
                $stack[$arg_0] =~ s/\A [<] \s*//xms;
                $stack[$arg_0] =~ s/ \s* [>] \z//xms;
                next STEP;
            }
            if ( $action eq 'do_lhs' ) {
                $stack[$arg_0] = do_lhs( undef, @stack[ $arg_0 .. $arg_n ] );
                next STEP;
            }
            if ( $action eq 'do_array' ) {
                $stack[$arg_0] = [ @stack[ $arg_0 .. $arg_n ] ];
                next STEP;
            }
            if ( $action eq 'do_discard_separators' ) {
                my @items = ();
                for (my $item_ix = $arg_0; $item_ix <= $arg_n; $item_ix += 2) {
                   push @items, $stack[$item_ix];
                }
                $stack[$arg_0] = \@items;
                next STEP;
            }
            if ( $action eq 'do_arg1' ) {
                $stack[$arg_0] = $stack[ $arg_0 + 1 ];
                next STEP;
            }
            if ( $action eq 'do_arg2' ) {
                $stack[$arg_0] = $stack[ $arg_0 + 2 ];
                next STEP;
            }
            if ( $action eq 'do_adverb_list' ) {
                $stack[$arg_0] =
                    do_adverb_list( undef, @stack[ $arg_0 .. $arg_n ] );
                next STEP;
            }
            if ( $action eq 'do_action' ) {
                $stack[$arg_0] = [ action => $stack[$arg_0 + 2] ];
                next STEP;
            }
            if ( $action eq 'do_left_association' ) {
                $stack[$arg_0] = [ assoc => 'L' ];
                next STEP;
            }
            if ( $action eq 'do_right_association' ) {
                $stack[$arg_0] = [ assoc => 'R' ];
                next STEP;
            }
            if ( $action eq 'do_group_association' ) {
                $stack[$arg_0] = [ assoc => 'G' ];
                next STEP;
            }
            if ( $action eq 'do_separator_specification' ) {
                $stack[$arg_0] = [ separator => $stack[$arg_0 + 2] ];
                next STEP;
            }
            die 'Internal error: Unknown action in Stuifzand grammar: ',
                $action;
        } ## end if ( $type eq 'MARPA_STEP_RULE' )
        if ( $type eq 'MARPA_STEP_NULLING_SYMBOL' ) {
            my ( $symbol_id, $arg_0 ) = @step_data;
            $stack[$arg_0] = undef;
            next STEP;
        }
        die "Unexpected step type: $type";
    } ## end STEP: while (1)

    my $parse = $stack[0];

    return $parse;
} ## end sub parse_rules

1;

# vim: expandtab shiftwidth=4:
