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

package Marpa::R2::Scanless;

use 5.010;
use strict;
use warnings;

say STDERR "Trial ", __FILE__;

my %hashed_closures = (
    do_adverb_list               => \&do_adverb_list,
    do_any                       => \&do_any,
    do_character_class           => \&do_character_class,
    do_discard_rule              => \&do_discard_rule,
    do_empty_rule                => \&do_empty_rule,
    do_lhs                       => \&do_lhs,
    do_op_declare_bnf            => \&do_op_declare_bnf,
    do_op_declare_match          => \&do_op_declare_match,
    do_op_plus_quantifier        => \&do_op_plus_quantifier,
    do_op_star_quantifier        => \&do_op_star_quantifier,
    do_parenthesized_rhs_primary_list => \&do_parenthesized_rhs_primary_list,
    do_priority_rule             => \&do_priority_rule,
    do_quantified_rule           => \&do_quantified_rule,
    do_rhs                       => \&do_rhs,
    do_rules                     => \&do_rules,
    do_separator_specification   => \&do_separator_specification,
    do_single_quoted_string      => \&do_single_quoted_string,
    do_start_rule                => \&do_start_rule,
    do_symbol                    => \&do_symbol,
    do_rhs_primary_list               => \&do_rhs_primary_list,
    do_ws                        => \&do_ws,
    do_ws_plus                   => \&do_ws_plus,
    do_ws_star                   => \&do_ws_star,
);

# Applied first.  If a rule has only one RHS symbol,
# and the key is it, the value is the action.
my %actions_by_rhs_symbol = (
    'kwc ws star'          => 'do_ws_star',
    'kwc ws plus'          => 'do_ws_plus',
    'kwc ws'               => 'do_ws',
    'kwc any'              => 'do_any',
    'single quoted string' => 'do_single_quoted_string',
    'character class'      => 'do_character_class',
    'bracketed name'       => 'do_bracketed_name',
    'op star'              => 'do_op_star_quantifier',
    'op plus'              => 'do_op_plus_quantifier',
    'op declare bnf'       => 'do_op_declare_bnf',
    'op declare match'     => 'do_op_declare_match',
);

# Applied second.  Use the LHS symbol to
# determine the action
my %actions_by_lhs_symbol = (
    symbol                           => 'do_symbol',
    rhs                              => 'do_rhs',
    lhs                              => 'do_lhs',
    'rhs primary list'               => 'do_rhs_primary_list',
    'parenthesized rhs primary list' => 'do_parenthesized_rhs_primary_list',
    rules                            => 'do_rules',
    'start rule'                     => 'do_start_rule',
    'priority rule'                  => 'do_priority_rule',
    'empty rule'                     => 'do_empty_rule',
    'quantified rule'                => 'do_quantified_rule',
    'discard rule'                   => 'do_discard_rule',
    priorities                       => 'do_discard_separators',
    alternatives                     => 'do_discard_separators',
    alternative                      => 'do_alternative',
    'adverb list'                    => 'do_adverb_list',
    action                           => 'do_action',
    blessing                         => 'do_blessing',
    'left association'               => 'do_left_association',
    'right association'              => 'do_right_association',
    'group association'              => 'do_group_association',
    'separator specification'        => 'do_separator_specification',
    'proper specification'           => 'do_proper_specification',
);

sub Marpa::R2::Scanless::G::_source_to_ast {
    die;
    my ( $self, $p_rules_source ) = @_;

    local $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL = 1;
    my $inner_self = bless {
        self              => $self,
        lex_rules         => [],
        lexical_lhs_index => 0,
        },
        __PACKAGE__;

    # Track earley set positions in input,
    # for debuggging
    my @positions = (0);

    my $meta_recce = Marpa::R2::Internal::Scanless::meta_recce();
    my $meta_grammar = $meta_recce->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    state $mask_by_rule_id =
        $meta_grammar->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID];
    my $thin_meta_recce  = $meta_recce->[Marpa::R2::Inner::Scanless::R::C];
    $meta_recce->read($p_rules_source);
    my $thick_meta_g1_grammar =
        $meta_grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $meta_g1_tracer       = $thick_meta_g1_grammar->tracer();
    my $thin_meta_g1_grammar = $thick_meta_g1_grammar->thin();
    my $thick_meta_g1_recce = $meta_recce->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_meta_g1_recce   = $thick_meta_g1_recce->thin();
    my $thick_g1_recce =
        $meta_recce->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    $thin_meta_g1_grammar->throw_set(0);
    my $latest_earley_set_id = $thin_meta_g1_recce->latest_earley_set();
    my $bocage = Marpa::R2::Thin::B->new( $thin_meta_g1_recce, $latest_earley_set_id );
    $thin_meta_g1_grammar->throw_set(1);
    if ( !defined $bocage ) {
        die q{Last rule successfully parsed was: },
            $meta_recce->last_rule(), "\n",
            'Parse failed';
    }

    my $order = Marpa::R2::Thin::O->new($bocage);
    my $tree  = Marpa::R2::Thin::T->new($order);
    $tree->next();
    my $valuator = Marpa::R2::Thin::V->new($tree);
    my @actions_by_rule_id;

    my $meta_g1_rules = $thick_meta_g1_grammar->[Marpa::R2::Internal::Grammar::RULES];
    RULE:
    for my $rule_id ( grep { $thin_meta_g1_grammar->rule_length($_); }
        0 .. $thin_meta_g1_grammar->highest_rule_id() )
    {
        $valuator->rule_is_valued_set( $rule_id, 1 );
        my ( $lhs, @rhs ) =
            map { Marpa::R2::Grammar::original_symbol_name($_) }
            $meta_g1_tracer->rule($rule_id);
        if (scalar @rhs == 1) {
            # These actions are by rhs symbol, for rules
            # with only one RHS symbol
            my $action = $actions_by_rhs_symbol{$rhs[0]};
            if (defined $action) {
                $actions_by_rule_id[$rule_id] = $action;
                next RULE;
            }
        }
        my $action = $actions_by_lhs_symbol{$lhs};
        if (defined $action) {
            $actions_by_rule_id[$rule_id] = $action;
            next RULE;
        }
        my $rule = $meta_g1_rules->[$rule_id];
        $action = $rule->[Marpa::R2::Internal::Rule::ACTION_NAME];
        next RULE if not defined $action;
        $actions_by_rule_id[$rule_id] = $action;
    } ## end for my $rule_id ( grep { $thin_meta_g1_grammar->rule_length($_...)})

    my $p_input   = $meta_recce->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];

    my @stack = ();
    STEP: while (1) {
        my ( $type, @step_data ) = $valuator->step();
        last STEP if not defined $type;
        if ( $type eq 'MARPA_STEP_TOKEN' ) {
            my ( undef, $token_value_ix, $arg_n ) = @step_data;
            my ( $start_earley_set, $end_earley_set ) = $valuator->location();
            my ($start_position) =
                $thin_meta_recce->locations( $start_earley_set + 1 );
            my ( undef, $end_position ) =
                $thin_meta_recce->locations($end_earley_set);
            my $token = substr ${$p_input}, $start_position,
                ( $end_position - $start_position );
            $stack[$arg_n] = $token;
            next STEP;
        } ## end if ( $type eq 'MARPA_STEP_TOKEN' )
        if ( $type eq 'MARPA_STEP_RULE' ) {
            my ( $rule_id, $arg_0, $arg_n ) = @step_data;

            my @args = @stack[ $arg_0 .. $arg_n ];
            if ( not defined $thin_meta_g1_grammar->sequence_min($rule_id) ) {
                my $mask = $mask_by_rule_id->[$rule_id];
                @args = @args[ grep { $mask->[$_] } 0 .. $#args ];
            }

            my $action = $actions_by_rule_id[$rule_id];
            if ( not defined $action ) {

                # No-op -- value is arg 0
                next STEP;
            }
            my $hashed_closure = $hashed_closures{$action};
            if ( defined $hashed_closure ) {
                $stack[$arg_0] = $hashed_closure->( $inner_self, @args );
                next STEP;
            }
            if ( $action eq '::first' ) {
                # No-op -- value is arg 0
                next STEP;
            }
            if ( $action eq 'do_alternative' ) {
                $stack[$arg_0] = [@args];
                next STEP;
            }
            if ( $action eq 'do_bracketed_name' ) {
                # normalize whitespace
                $stack[$arg_0] =~ s/\A [<] \s*//xms;
                $stack[$arg_0] =~ s/ \s* [>] \z//xms;
                $stack[$arg_0] =~ s/ \s+ / /gxms;
                next STEP;
            }
            if ( $action eq 'do_array' ) {
                $stack[$arg_0] = [@args];
                next STEP;
            }
            if ( $action eq 'do_discard_separators' ) {
                my @items = ();
                for (
                    my $item_ix = $arg_0;
                    $item_ix <= $arg_n;
                    $item_ix += 2
                    )
                {
                    push @items, $stack[$item_ix];
                } ## end for ( my $item_ix = $arg_0; $item_ix <= $arg_n; ...)
                $stack[$arg_0] = \@items;
                next STEP;
            } ## end if ( $action eq 'do_discard_separators' )
            if ( $action eq 'do_action' ) {
                $stack[$arg_0] = [ action => $args[0] ];
                next STEP;
            }
            if ( $action eq 'do_blessing' ) {
                $stack[$arg_0] = [ bless => $args[0] ];
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
            if ( $action eq 'do_proper_specification' ) {
                $stack[$arg_0] = [ proper => $args[0] ];
                next STEP;
            }
            die 'Internal error: Unknown action in Scanless grammar: ',
                $action;
        } ## end if ( $type eq 'MARPA_STEP_RULE' )
        if ( $type eq 'MARPA_STEP_NULLING_SYMBOL' ) {
            my ( $symbol_id, $arg_0 ) = @step_data;
            $stack[$arg_0] = undef;
            next STEP;
        }
        die "Unexpected step type: $type";
    } ## end STEP: while (1)

    my $g1_rules = $inner_self->{g1_rules} = $stack[0];
    my $lex_rules = $inner_self->{lex_rules};

    my @ws_rules = ();
    if ( defined $inner_self->{needs_symbol} ) {
        my %needed = %{ $inner_self->{needs_symbol} };
        my %seen   = ();
        undef $inner_self->{needs_symbol};
        NEEDED_SYMBOL_LOOP: while (1) {
            my @needed_symbols =
                sort grep { !$seen{$_} } keys %needed;
            last NEEDED_SYMBOL_LOOP if not @needed_symbols;
            SYMBOL: for my $needed_symbol (@needed_symbols) {
                $seen{$needed_symbol} = 1;
                if ( $needed_symbol eq '[:ws+]' ) {
                    push @ws_rules,
                        {
                        lhs => $needed_symbol,
                        rhs => ['[:Space]'],
                        min => 1
                        };
                    $needed{'[:Space]'} = 1;
                    next SYMBOL;
                } ## end if ( $needed_symbol eq '[:ws+]' )
                if ( $needed_symbol eq '[:ws*]' ) {
                    push @ws_rules,
                        {
                        lhs => $needed_symbol,
                        rhs => ['[:Space]'],
                        min => 0
                        };
                    $needed{'[:Space]'} = 1;
                    next SYMBOL;
                } ## end if ( $needed_symbol eq '[:ws*]' )
                if ( $needed_symbol eq '[:ws]' ) {
                    push @ws_rules,
                        { lhs => '[:ws]', rhs => ['[:ws+]'],  };
                    $needed{'[:ws+]'} = 1;
                    next SYMBOL;
                } ## end if ( $needed_symbol eq '[:ws]' )
                if ( $needed_symbol eq '[:Space]' ) {
                    my $true_ws = assign_symbol_by_char_class( $inner_self,
                        '[\p{White_Space}]' );
                    push @ws_rules,
                        {
                        lhs  => '[:Space]',
                        rhs  => [ $true_ws->name() ],
                        };
                } ## end if ( $needed_symbol eq '[:Space]' )
            } ## end SYMBOL: for my $needed_symbol (@needed_symbols)
        } ## end NEEDED_SYMBOL_LOOP: while (1)
    } ## end if ( defined $inner_self->{needs_symbol} )

    push @{$g1_rules}, @ws_rules;

    $inner_self->{g1_rules}  = $g1_rules;
    $inner_self->{lex_rules} = $lex_rules;
    my %lex_lhs = ();
    my %lex_rhs = ();
    for my $lex_rule (@{$lex_rules}) {
        $lex_lhs{$lex_rule->{lhs}} = 1;
        $lex_rhs{$_} = 1 for @{$lex_rule->{rhs}};
    }

    my %lexemes = map { $_ => 1 } grep { not $lex_rhs{$_}} keys %lex_lhs;
    $inner_self->{is_lexeme} = \%lexemes;
    my @unproductive = grep { not $lex_lhs{$_} and not $_ =~ /\A \[\[ /xms } keys %lex_rhs;
    if (@unproductive) {
        Marpa::R2::exception('Unproductive lexical symbols: ', join q{ }, @unproductive);
    }
    push @{ $inner_self->{lex_rules} },
        map { ; { lhs => '[:start_lex]', rhs => [$_] } } sort keys %lexemes;

    my $raw_cc = $inner_self->{character_classes};
    if ( defined $raw_cc ) {
        my $stripped_cc = {};
        for my $symbol_name ( keys %{$raw_cc} ) {
            my ($re) = @{ $raw_cc->{$symbol_name} };
            $stripped_cc->{$symbol_name} = $re;
        }
        $inner_self->{character_classes} = $stripped_cc;
    } ## end if ( defined $raw_cc )
    return $inner_self;
} ## end sub rules_add

