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

package Marpa::R2::MetaAST;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.047_010';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::MetaAST;

sub new {
    my ( $class, $p_rules_source ) = @_;

    my $meta_recce = Marpa::R2::Internal::Scanless::meta_recce();
    my $meta_grammar = $meta_recce->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    state $mask_by_rule_id =
        $meta_grammar->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID];
    $meta_recce->read($p_rules_source);

    my $thick_meta_g1_grammar = $meta_grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $meta_g1_tracer       = $thick_meta_g1_grammar->tracer();
    my $thin_meta_g1_grammar = $thick_meta_g1_grammar->thin();
    my $thick_meta_g1_recce = $meta_recce->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thick_g1_recce = $meta_recce->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    my $value_ref = $meta_recce->value();
    Marpa::R2::exception("Parse of BNF/Scanless source failed") if not defined $value_ref;
    return bless ${$value_ref}, $class;

}

sub substring {
    my ($parse, $start, $end) = @_;
    my $string = substr ${$parse->{p_source}}, $start, ($end-$start+1);
    chomp $string;
    return $string;
}

sub ast_to_hash {
    my ( $ast, $bnf_source ) = @_;
    my $parse = bless {
        p_source => $bnf_source,
        g0_rules => [],
        g1_rules => []
    };

    my (undef, undef, @statements) = @{$ast};
    $_->evaluate($parse) for @statements;

    my $g1_rules = $parse->{g1_rules};
    my $g0_rules = $parse->{g0_rules};
    my %lex_lhs  = ();
    my %lex_rhs  = ();
    for my $lex_rule ( @{$g0_rules} ) {
        $lex_lhs{ $lex_rule->{lhs} } = 1;
        $lex_rhs{$_} = 1 for @{ $lex_rule->{rhs} };
    }

    my $lexeme_default_adverbs = $parse->{lexeme_default_adverbs};
    my $g1_symbols             = {};
    my %is_lexeme =
        map { ( $_, 1 ); } grep { not $lex_rhs{$_} } keys %lex_lhs;
    if ( my $lexeme_default_adverbs = $parse->{lexeme_default_adverbs} ) {
        my $blessing = $lexeme_default_adverbs->{bless};
        my $action   = $lexeme_default_adverbs->{action};
        LEXEME: for my $lexeme ( keys %is_lexeme ) {
            next LEXEME if $lexeme =~ m/ \] \z/xms;
            DETERMINE_BLESSING: {
                last DETERMINE_BLESSING if not $blessing;
                last DETERMINE_BLESSING if $blessing eq '::undef';
                if ( $blessing eq '::name' ) {
                    if ( $lexeme =~ / [^ [:alnum:]] /xms ) {
                        Marpa::R2::exception(
                            qq{Lexeme blessing by '::name' only allowed if lexeme name is whitespace and alphanumerics\n},
                            qq{   Problematic lexeme was <$lexeme>\n}
                        );
                    } ## end if ( $lexeme =~ / [^ [:alnum:]] /xms )
                    my $blessing = $lexeme;
                    $blessing =~ s/[ ]/_/gxms;
                    $g1_symbols->{$lexeme}->{bless} = $blessing;
                    last DETERMINE_BLESSING;
                } ## end if ( $blessing eq '::name' )
                if ( $blessing =~ / [^\w] /xms ) {
                    Marpa::R2::exception(
                        qq{Blessing lexeme as '$blessing' is not allowed\n},
                        qq{   Problematic lexeme was <$lexeme>\n}
                    );
                } ## end if ( $blessing =~ / [^\w] /xms )
                $g1_symbols->{$lexeme}->{bless} = $blessing;
            } ## end DETERMINE_BLESSING:
            $g1_symbols->{$lexeme}->{semantics} = $action;
        } ## end LEXEME: for my $lexeme ( keys %is_lexeme )
    } ## end if ( my $lexeme_default_adverbs = $parse->{...})
    $parse->{is_lexeme}  = \%is_lexeme;
    $parse->{g1_symbols} = $g1_symbols;

    my @unproductive =
        grep { not $lex_lhs{$_} and not $_ =~ /\A \[\[ /xms } keys %lex_rhs;
    if (@unproductive) {
        Marpa::R2::exception( 'Unproductive lexical symbols: ',
            join q{ }, @unproductive );
    }
    push @{ $parse->{g0_rules} },
        map { ; { lhs => '[:start_lex]', rhs => [$_] } } sort keys %is_lexeme;
    my %stripped_character_classes = ();
    {
        my $character_classes = $parse->{character_classes};
        for my $symbol_name ( sort keys %{$character_classes} ) {
            my ($re) = @{ $character_classes->{$symbol_name} };
            $stripped_character_classes{$symbol_name} = $re;
        }
    }
    $parse->{character_classes} = \%stripped_character_classes;

    return $parse;
} ## end sub ast_to_hash

# This class is for pieces of RHS alternatives, as they are
# being constructed
my $PROTO_ALTERNATIVE = 'Marpa::R2::Internal::MetaAST::Proto_Alternative';

sub Marpa::R2::Internal::MetaAST::Proto_Alternative::combine {
    my ( $class, @hashes ) = @_;
    my $self = bless {}, $class;
    for my $hash_to_add (@hashes) {
        for my $key ( keys %{$hash_to_add} ) {
            Marpa::R2::exception(
                'duplicate key in ',
                $PROTO_ALTERNATIVE,
                "::combine(): $key"
            ) if exists $self->{$key};

            $self->{$key} = $hash_to_add->{$key};
        } ## end for my $key ( keys %{$hash_to_add} )
    } ## end for my $hash_to_add (@hashes)
    return $self;
} ## end sub combine

sub Marpa::R2::Internal::MetaAST::bless_hash_rule {
    my ( $parse, $hash_rule, $blessing, $original_lhs ) = @_;
    my $grammar_level = $Marpa::R2::Internal::GRAMMAR_LEVEL;
    return if $grammar_level == 0;
    $blessing //= $parse->{default_adverbs}->[$grammar_level]->{bless};
    return if not defined $blessing;
    FIND_BLESSING: {
        last FIND_BLESSING if $blessing =~ /\A [\w] /xms;
        return if $blessing eq '::undef';
        # Rule may be half-formed, but assume with have lhs
        my $lhs = $hash_rule->{lhs};
        if ( $blessing eq '::lhs' ) {
            $blessing = $original_lhs;
            if ( $blessing =~ / [^ [:alnum:]] /xms ) {
                Marpa::R2::exception(
                    qq{"::lhs" blessing only allowed if LHS is whitespace and alphanumerics\n},
                    qq{   LHS was <$original_lhs>\n}
                );
            } ## end if ( $blessing =~ / [^ [:alnum:]] /xms )
            $blessing =~ s/[ ]/_/gxms;
            last FIND_BLESSING;
        } ## end if ( $blessing eq '::lhs' )
        Marpa::R2::exception(
            qq{Unknown blessing "$blessing"\n}
        );
    } ## end FIND_BLESSING:
    $hash_rule->{bless} = $blessing;
    return 1;
} ## end sub bless_hash_rule

sub Marpa::R2::Internal::MetaAST_Nodes::bare_name::name { return $_[0]->[2] }
sub Marpa::R2::Internal::MetaAST_Nodes::reserved_action_name::name {
    my ( $self, $parse ) = @_;
    return $self->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::action_name::name {
    my ( $self, $parse ) = @_;
    return $self->[2]->name($parse);
}


sub Marpa::R2::Internal::MetaAST_Nodes::array_descriptor::name {
    return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::reserved_blessing_name::name {
    return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::blessing_name::name {
    my ($self, $parse) = @_;
    return $self->[2]->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::standard_name::name {
    return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::lhs::name {
    my ($values, $parse) = @_;
    my (undef, undef, $symbol) = @{$values};
    return $symbol->name($parse);
}

# After development, delete this
sub Marpa::R2::Internal::MetaAST_Nodes::lhs::evaluate {
    my ($values, $parse) = @_;
    return $values->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::quantifier::evaluate {
    my ($data) = @_;
    return $data->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::op_declare::op {
    my ($values) = @_;
    return $values->[2]->op();
}

sub Marpa::R2::Internal::MetaAST_Nodes::op_declare_match::op {
    my ($values) = @_;
    return $values->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::op_declare_bnf::op {
    my ($values) = @_;
    return $values->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::bracketed_name::name {
    my ($values) = @_;
    my (undef, undef, $bracketed_name) = @{$values};

    # normalize whitespace
    $bracketed_name =~ s/\A [<] \s*//xms;
    $bracketed_name =~ s/ \s* [>] \z//xms;
    $bracketed_name =~ s/ \s+ / /gxms;
    return $bracketed_name;
} ## end sub evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::parenthesized_rhs_primary_list::evaluate {
    my ( $data, $parse ) = @_;
    my (undef, undef, @values) = @{$data};
    my @symbol_lists = map { $_->evaluate($parse); } @values;
    my $flattened_list = Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbol_lists);
    $flattened_list->mask_set(0);
    return $flattened_list;
}

sub Marpa::R2::Internal::MetaAST_Nodes::rhs::evaluate {
    my ( $data, $parse ) = @_;
    my (undef, undef, @values) = @{$data};
    my @symbol_lists = map { $_->evaluate($parse) } @values;
    my $flattened_list =
        Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbol_lists);
    return bless {
        rhs  => $flattened_list->names($parse),
        mask => $flattened_list->mask()
        },
        $PROTO_ALTERNATIVE;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::rhs::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::rhs_primary::evaluate {
    my ( $data, $parse ) = @_;
    my (undef, undef, @values) = @{$data};
    my @symbol_lists = map { $_->evaluate($parse) } @values;
    return Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbol_lists);
}

sub Marpa::R2::Internal::MetaAST_Nodes::rhs_primary_list::evaluate {
    my ( $data, $parse ) = @_;
    my (undef, undef, @values) = @{$data};
    my @symbol_lists = map { $_->evaluate($parse) } @values;
    return Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbol_lists);
}

sub Marpa::R2::Internal::MetaAST_Nodes::action::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $child ) = @{$values};
    return bless { action => $child->name($parse) }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::blessing::evaluate {
    my ($values, $parse) = @_;
    my ( undef, undef, $child ) = @{$values};
    return bless { bless => $child->name($parse) }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::right_association::evaluate {
    my ($values) = @_;
    return bless { assoc => 'R' }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::left_association::evaluate {
    my ($values) = @_;
    return bless { assoc => 'L' }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::group_association::evaluate {
    my ($values) = @_;
    return bless { assoc => 'G' }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::proper_specification::evaluate {
    my ($values) = @_;
    my $child = $values->[2];
    return bless { proper => $child->value() }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::boolean::value {
   return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::separator_specification::evaluate {
    my ( $values, $parse ) = @_;
    my $child = $values->[2];
    return bless { separator => $child->name($parse) }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::adverb_item::evaluate {
    my ( $values, $parse ) = @_;
    my $child = $values->[2]->evaluate($parse);
    return bless $child, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::default_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, undef, $op_declare, $raw_adverb_list ) =
        @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    my $adverb_list = $raw_adverb_list->evaluate($parse);

    # A default rule clears the previous default
    my %default_adverbs = ();
    $parse->{default_adverbs}->[$grammar_level] = \%default_adverbs;

    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' ) {
            $default_adverbs{$key} = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'bless' ) {
            $default_adverbs{$key} = $adverb_list->{$key};
            next ADVERB;
        }
        Marpa::R2::exception(qq{"$key" adverb not allowed in default rule});
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )
    return undef;
} ## end sub evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::lexeme_default_statement::evaluate {
    my ( $data, $parse ) = @_;
    my ( $start, $end, $raw_adverb_list ) = @{$data};
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = 1;

    my $adverb_list = $raw_adverb_list->evaluate($parse);
    if ( exists $parse->{lexeme_default_adverbs} ) {
        my $problem_rule = $parse->substring( $start, $end );
        Marpa::R2::exception(
            qq{More than one lexeme default statement is not allowed\n},
            qq{  This was the rule that caused the problem:\n},
            qq{  $problem_rule\n}
        );
    } ## end if ( exists $parse->{lexeme_default_adverbs} )
    $parse->{lexeme_default_adverbs} = {};
    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' ) {
            $parse->{lexeme_default_adverbs}->{$key} = $value;
            next ADVERB;
        }
        if ( $key eq 'bless' ) {
            $parse->{lexeme_default_adverbs}->{$key} = $value;
            next ADVERB;
        }
        Marpa::R2::exception(
            qq{"$key" adverb not allowed as lexeme default"});
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::lexeme_default_statement::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::priority_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $raw_lhs, $op_declare, $raw_priorities ) = @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = $grammar_level;
    my $lhs = $raw_lhs->name($parse);

    my (undef, undef, @priorities) = @{$raw_priorities};
    my $priority_count = scalar @priorities;
    my @working_rules  = ();

    my $rules = $grammar_level >= 1 ? $parse->{g1_rules} : $parse->{g0_rules};

    my $default_adverbs = $parse->{default_adverbs}->[$grammar_level];

    if ( $priority_count <= 1 ) {
        ## If there is only one priority
        my (undef, undef, @alternatives) = @{ $priorities[0] } ;
        for my $alternative (@alternatives) {
            my ( undef, undef, $raw_rhs, $raw_adverb_list ) = @{$alternative};
            my $proto_rule  = $raw_rhs->evaluate($parse);
            my $adverb_list = $raw_adverb_list->evaluate($parse);
            my @rhs_names   = @{ $proto_rule->{rhs} };
            my @mask        = @{ $proto_rule->{mask} };
            if ( $grammar_level <= 0 and grep { !$_ } @mask ) {
                Marpa::R2::exception(
                    qq{hidden symbols are not allowed in lexical rules (rules LHS was "$lhs")}
                );
            }
            my %hash_rule =
                ( lhs => $lhs, rhs => \@rhs_names, mask => \@mask );

            my $action = $adverb_list->{action} // $default_adverbs->{action};
            if ( defined $action ) {
                Marpa::R2::exception(
                    'actions not allowed in lexical rules (rules LHS was "',
                    $lhs, '")' )
                    if $grammar_level <= 0;
                $hash_rule{action} = $action;
            } ## end if ( defined $action )

            my $blessing = $adverb_list->{bless};
            if ( defined $blessing
                and $grammar_level <= 0 )
            {
                Marpa::R2::exception(
                    'bless option not allowed in lexical rules (rules LHS was "',
                    $lhs, '")'
                );
            } ## end if ( defined $blessing and $grammar_level <= 0 )
            $parse->bless_hash_rule( \%hash_rule, $blessing, $lhs );

            push @{$rules}, \%hash_rule;
        } ## end for my $alternative (@alternatives)
        return 'consumed trivial priority rule';
    } ## end if ( $priority_count <= 1 )

    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        my (undef, undef, @alternatives) = @{ $priorities[$priority_ix] } ;
        for my $alternative ( @alternatives) {
            my ( undef, undef, $rhs, $adverb_list ) = @{$alternative};
            push @working_rules, [ $priority, $rhs, $adverb_list ];
        }
    } ## end for my $priority_ix ( 0 .. $priority_count - 1 )

    # Default mask (all ones) is OK for this rule
    my @arg0_action = ();
    @arg0_action = ( action => '::first' ) if $grammar_level > 0;
    push @{$rules},
        { lhs => $lhs, rhs => [ $lhs . '[prec0]' ], @arg0_action }, (
        map {
            ;
            {   lhs => ( $lhs . '[prec' . ( $_ - 1 ) . ']' ),
                rhs => [ $lhs . '[prec' . $_ . ']' ],
                @arg0_action
            }
        } 1 .. $priority_count - 1
        );
    RULE: for my $working_rule (@working_rules) {
        my ( $priority, $raw_rhs, $raw_adverb_list ) = @{$working_rule};
        my $adverb_list = $raw_adverb_list->evaluate($parse);
        my $rhs = $raw_rhs->evaluate($parse);
        my $assoc   = $adverb_list->{assoc} // 'L';
        my @new_rhs = @{$rhs->{rhs}};
        my @arity   = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $length  = scalar @new_rhs;

        my $current_exp = $lhs . '[prec' . $priority . ']';
        my @mask        = @{ $rhs->{mask} };
        if ( $grammar_level <= 0 and grep { !$_ } @mask ) {
            Marpa::R2::exception(
                'hidden symbols are not allowed in lexical rules (rules LHS was "',
                $lhs, '")'
            );
        } ## end if ( $grammar_level <= 0 and grep { !$_ } @mask )
        my %new_xs_rule = ( lhs => $current_exp );
        $new_xs_rule{mask} = \@mask;

        my $action = $adverb_list->{action} // $default_adverbs->{action};
        if ( defined $action ) {
            Marpa::R2::exception(
                'actions not allowed in lexical rules (rules LHS was "',
                $lhs, '")' )
                if $grammar_level <= 0;
            $new_xs_rule{action} = $action;
        } ## end if ( defined $action )

        my $blessing = $adverb_list->{bless};
        if ( defined $blessing
            and $grammar_level <= 0 )
        {
            Marpa::R2::exception(
                'bless option not allowed in lexical rules (rules LHS was "',
                $lhs, '")'
            );
        } ## end if ( defined $blessing and $grammar_level <= 0 )
        $parse->bless_hash_rule( \%new_xs_rule, $blessing, $lhs );

        my $next_priority = $priority + 1;
        $next_priority = 0 if $next_priority >= $priority_count;
        my $next_exp = $lhs . '[prec' . $next_priority . ']';

        if ( not scalar @arity ) {
            $new_xs_rule{rhs} = \@new_rhs;
            push @{$rules}, \%new_xs_rule;
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
        push @{$rules}, \%new_xs_rule;
    } ## end RULE: for my $working_rule (@working_rules)
    return 'consumed priority rule';
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::priority_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::empty_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $lhs, $op_declare, $raw_adverb_list ) = @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = $grammar_level;

    my %rule = ( lhs => $lhs->name($parse), rhs => [] );
    my $adverb_list = $raw_adverb_list->evaluate($parse);

    my $default_adverbs = $parse->{default_adverbs}->[$grammar_level];

    my $action = $adverb_list->{action} // $default_adverbs->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $grammar_level <= 0;
        $rule{action} = $action;
    } ## end if ( defined $action )

    my $blessing = $adverb_list->{bless};
    if ( defined $blessing
        and $grammar_level <= 0 )
    {
        Marpa::R2::exception(
            'bless option not allowed in lexical rules (rules LHS was "',
            $lhs, '")' );
    } ## end if ( defined $blessing and $grammar_level <= 0 )
    $parse->bless_hash_rule( \%rule, $blessing, $lhs );

    # mask not needed
    if ( $grammar_level >= 1 ) {
        push @{ $parse->{g1_rules} }, \%rule;
    }
    else {
        push @{ $parse->{g0_rules} }, \%rule;
    }
    return 'consumed empty rule';
} ## end Marpa::R2::Internal::MetaAST_Nodes::empty_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::lexeme_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $end, undef, $op_declare, $unevaluated_adverb_list ) =
        @{$values};
    Marpa::R2::exception( "lexeme rule not allowed in G0\n",
        "  Rule was ", $parse->positions_to_string( $start, $end ) )
        if $op_declare->op() ne q{::=};
    my $adverb_list = $unevaluated_adverb_list->evaluate($parse);

    # A default rule clears the previous default
    $parse->{default_lexeme_adverbs} = {};

    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' ) {
            $parse->{default_lexeme_adverbs}->{$key} = $value;
            next ADVERB;
        }
        if ( $key eq 'bless' ) {
            $parse->{default_lexeme_adverbs}->{$key} = $value;
            next ADVERB;
        }
        Marpa::R2::exception(qq{"$key" adverb not allowed in default rule"});
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )
    return undef;
} ## end sub evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::statement::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, $statement_body ) = @{$data};
    $statement_body->evaluate($parse);
    return undef;
}

sub Marpa::R2::Internal::MetaAST_Nodes::statement_body::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, $statement ) = @{$data};
    $statement->evaluate($parse);
    return undef;
}

sub Marpa::R2::Internal::MetaAST_Nodes::start_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $end, $symbol ) = @{$values};
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = 0;
    push @{ $parse->{g1_rules} },
        {
        lhs    => '[:start]',
        rhs    => $symbol->names($parse),
        action => '::first'
        };
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::start_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::discard_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $end, $symbol ) = @{$values};
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = 0;
    push @{ $parse->{g0_rules} },
        { lhs => '[:discard]', rhs => $symbol->names($parse) };
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::discard_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::quantified_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $lhs, $op_declare, $rhs, $quantifier, $proto_adverb_list ) =
        @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = $grammar_level;

    my $adverb_list = $proto_adverb_list->evaluate($parse);
    my $default_adverbs = $parse->{default_adverbs}->[$grammar_level];

    # Some properties of the sequence rule will not be altered
    # no matter how complicated this gets
    my %sequence_rule = (
        rhs => [ $rhs->name($parse) ],
        min => ( $quantifier->evaluate($parse) eq q{+} ? 1 : 0 )
    );

    my @rules = ( \%sequence_rule );

    my $original_separator = $adverb_list->{separator};

    # mask not needed
    my $lhs_name       = $lhs->name($parse);
    $sequence_rule{lhs}       = $lhs_name;
    $sequence_rule{separator} = $original_separator
        if defined $original_separator;
    my $proper = $adverb_list->{proper};
    $sequence_rule{proper} = $proper if defined $proper;

    my $action = $adverb_list->{action} // $default_adverbs->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $grammar_level <= 0;
        $sequence_rule{action} = $action;
    } ## end if ( defined $action )

    my $blessing = $adverb_list->{bless};
    if ( defined $blessing
        and $grammar_level <= 0 )
    {
        Marpa::R2::exception(
            'bless option not allowed in lexical rules (rules LHS was "',
            $lhs, '")' );
    } ## end if ( defined $blessing and $grammar_level <= 0 )
    $parse->bless_hash_rule( \%sequence_rule, $blessing, $lhs_name );

    if ( $grammar_level > 0 ) {
        push @{ $parse->{g1_rules} }, @rules;
    }
    else {
        push @{ $parse->{g0_rules} }, @rules;
    }
    return 'quantified rule consumed';

} ## end sub Marpa::R2::Internal::MetaAST_Nodes::quantified_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::alternatives::evaluate {
    my ( $values, $parse ) = @_;
    return bless [ map { $_->evaluate( $_, $parse ) } @{$values} ],
        ref $values;
}

sub Marpa::R2::Internal::MetaAST_Nodes::alternative::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $rhs, $adverbs ) = @{$values};
    return Marpa::R2::Internal::MetaAST::Proto_Alternative->combine( map { $_->evaluate($parse) } $rhs, $adverbs);
} ## end sub evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::single_symbol::names {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $symbol ) = @{$values};
    return $symbol->names($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::single_symbol::name {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $symbol ) = @{$values};
    return $symbol->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::single_symbol::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $symbol ) = @{$values};
    return Marpa::R2::Internal::MetaAST::Symbol_List->new($symbol->name($parse));
}

sub Marpa::R2::Internal::MetaAST_Nodes::Symbol::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $symbol ) = @{$values};
    return $symbol->evaluate($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::symbol::name {
    my ( $self, $parse ) = @_;
    return $self->[2]->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::symbol::names {
    my ( $self, $parse ) = @_;
    return $self->[2]->names($parse);
}
sub Marpa::R2::Internal::MetaAST_Nodes::symbol_name::evaluate {
my ($self) = @_; return $self->[2]; }
sub Marpa::R2::Internal::MetaAST_Nodes::symbol_name::name {
my ($self, $parse) = @_;
return $self->evaluate($parse)->name($parse); }
sub Marpa::R2::Internal::MetaAST_Nodes::symbol_name::names {
    my ($self, $parse) = @_;
   return [$self->name($parse)];
}

sub Marpa::R2::Internal::MetaAST_Nodes::adverb_list::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, @raw_items ) = @{$data};
    my (@adverb_items) = map { $_->evaluate($parse) } @raw_items;
    return Marpa::R2::Internal::MetaAST::Proto_Alternative->combine(
        @adverb_items);
} ## end sub evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::character_class::name {
    my ( $self, $parse ) = @_;
    return $self->evaluate($parse)->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::character_class::evaluate {
    my ( $values, $parse ) = @_;
    my $symbol =
        Marpa::R2::Internal::MetaAST::Symbol_List->new_from_char_class(
        $parse, $values->[2] );
    return $symbol if $Marpa::R2::Internal::GRAMMAR_LEVEL <= 0;
    my $lexical_lhs_index = $parse->{lexical_lhs_index}++;
    my $lexical_lhs       = "[Lex-$lexical_lhs_index]";
    my $lexical_rhs       = $symbol->names($parse);
    my %lexical_rule      = (
        lhs  => $lexical_lhs,
        rhs  => $lexical_rhs,
        mask => [1],
    );
    push @{ $parse->{g0_rules} }, \%lexical_rule;
    my $g1_symbol = Marpa::R2::Internal::MetaAST::Symbol_List->new($lexical_lhs);
    return $g1_symbol;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::character_class::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::single_quoted_string::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $string ) = @{$values};
    my @symbols = ();
    for my $char_class (
        map { '[' . ( quotemeta $_ ) . ']' } split //xms,
        substr $string,
        1, -1
        )
    {
        my $symbol =
            Marpa::R2::Internal::MetaAST::Symbol_List->new_from_char_class(
            $parse, $char_class );
        push @symbols, $symbol;
    } ## end for my $char_class ( map { '[' . ( quotemeta $_ ) . ']'...})
    my $list = Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbols);
    return $list if $Marpa::R2::Internal::GRAMMAR_LEVEL <= 0;
    my $lexical_lhs_index = $parse->{lexical_lhs_index}++;
    my $lexical_lhs       = "[Lex-$lexical_lhs_index]";
    my $lexical_rhs       = $list->names($parse);
    my %lexical_rule      = (
        lhs  => $lexical_lhs,
        rhs  => $lexical_rhs,
        mask => [ map { ; 1 } @{$lexical_rhs} ]
    );
    push @{ $parse->{g0_rules} }, \%lexical_rule;
    my $g1_symbol = Marpa::R2::Internal::MetaAST::Symbol_List->new($lexical_lhs);
    return $g1_symbol;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::single_quoted_string::evaluate

package Marpa::R2::Internal::MetaAST::Symbol_List;

use English qw( -no_match_vars );

sub new {
    my ( $class, $name ) = @_;
    return bless { names => [ '' . $name ], mask => [1] }, $class;
}

sub combine {
    my ( $class, @lists ) = @_;
    my $self = {};
    $self->{names} = [ map { @{ $_->names() } } @lists ];
    $self->{mask}  = [ map { @{ $_->mask() } } @lists ];
    return bless $self, $class;
} ## end sub new

# Return the character class symbol name,
# after ensuring everything is set up properly
sub new_from_char_class {
    my ( $class, $parse, $char_class ) = @_;

    # character class symbol name always start with TWO left square brackets
    my $symbol_name = '[' . $char_class . ']';
    $parse->{character_classes} //= {};
    my $cc_hash = $parse->{character_classes};
    my ( undef, $symbol ) = $cc_hash->{$symbol_name};
    if ( not defined $symbol ) {
        my $regex;
        if ( not defined eval { $regex = qr/$char_class/xms; 1; } ) {
            Carp::croak( 'Bad Character class: ',
                $char_class, "\n", 'Perl said ', $EVAL_ERROR );
        }
        $symbol =
            Marpa::R2::Internal::MetaAST::Symbol_List->new($symbol_name);
        $cc_hash->{$symbol_name} = [ $regex, $symbol ];
    } ## end if ( not defined $symbol )
    return $symbol;
} ## end sub new_from_char_class

sub name {
    my ($self) = @_;
    my $names = $self->{names};
    Marpa::R2::exception( "list->name() on symbol list of length ",
        scalar @{$names} )
        if scalar @{$names} != 1;
    return $self->{names}->[0];
} ## end sub name
sub names { return shift->{names} }
sub mask { return shift->{mask} }
sub mask_set {
    my ( $self, $mask ) = @_;
    $self->{mask} = [ map { $mask } @{ $self->{mask} } ];
}

1;

# vim: expandtab shiftwidth=4:
