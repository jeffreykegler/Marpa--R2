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
$VERSION        = '2.067_001';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::MetaAST;

use English qw( -no_match_vars );

sub new {
    my ( $class, $p_rules_source, $parse ) = @_;

    my $meta_recce   = Marpa::R2::Internal::Scanless::meta_recce();
    my $meta_grammar = $meta_recce->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    state $mask_by_rule_id =
        $meta_grammar->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID];
    $meta_recce->read($p_rules_source);

    my $thick_meta_g1_grammar =
        $meta_grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $meta_g1_tracer       = $thick_meta_g1_grammar->tracer();
    my $thin_meta_g1_grammar = $thick_meta_g1_grammar->thin();
    my $thick_meta_g1_recce =
        $meta_recce->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thick_g1_recce =
        $meta_recce->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    my $value_ref = $meta_recce->value();
    Marpa::R2::exception('Parse of BNF/Scanless source failed')
        if not defined $value_ref;
    $parse->{meta_recce} = $meta_recce if defined $parse;
    return bless ${$value_ref}, $class;

} ## end sub new

sub Marpa::R2::Internal::MetaAST::Parse::substring {
    my ( $parse, $start, $length ) = @_;
    my $meta_slr      = $parse->{meta_recce};
    my $thin_meta_slr = $meta_slr->[Marpa::R2::Inner::Scanless::R::C];
    my $string        = $thin_meta_slr->substring( $start, $length );
    chomp $string;
    return $string;
} ## end sub Marpa::R2::Internal::MetaAST::Parse::substring

sub ast_to_hash {
    my ( $ast, $parse ) = @_;
    $parse->{g0_rules} = [];
    $parse->{g1_rules} = [];
    bless $parse, 'Marpa::R2::Internal::MetaAST::Parse';

    my ( undef, undef, @statements ) = @{$ast};

    # This is the last ditch exception catcher
    # It forces all Marpa exceptions to be die's,
    # then catches them and rethrows using Carp.
    #
    # The plan is to use die(), with higher levels
    # catching and re-die()'ing after adding
    # helpful location information.  After the
    # re-throw it is caught here and passed to
    # Carp.
    my $eval_ok = eval {
        local $Marpa::R2::JUST_DIE = 1;
        $_->evaluate($parse) for @statements;
        1;
    };
    Marpa::R2::exception($EVAL_ERROR) if not $eval_ok;

    my $g1_rules = $parse->{g1_rules};
    my $g0_rules = $parse->{g0_rules};
    my %lex_lhs  = ();
    my %lex_rhs  = ();
    for my $lex_rule ( @{$g0_rules} ) {
        $lex_lhs{ $lex_rule->{lhs} } = 1;
        $lex_rhs{$_} = 1 for @{ $lex_rule->{rhs} };
    }

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
                    my $blessing_by_name = $lexeme;
                    $blessing_by_name =~ s/[ ]/_/gxms;
                    $g1_symbols->{$lexeme}->{bless} = $blessing_by_name;
                    last DETERMINE_BLESSING;
                } ## end if ( $blessing eq '::name' )
                if ( $blessing =~ / [\W] /xms ) {
                    Marpa::R2::exception(
                        qq{Blessing lexeme as '$blessing' is not allowed\n},
                        qq{   Problematic lexeme was <$lexeme>\n}
                    );
                } ## end if ( $blessing =~ / [\W] /xms )
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
            ## expect to be caught and rethrown
            die qq{A Marpa rule contained a duplicate key\n},
                qq{  The key was "$key"\n}
                if exists $self->{$key};
            $self->{$key} = $hash_to_add->{$key};
        } ## end for my $key ( keys %{$hash_to_add} )
    } ## end for my $hash_to_add (@hashes)
    return $self;
} ## end sub Marpa::R2::Internal::MetaAST::Proto_Alternative::combine

sub Marpa::R2::Internal::MetaAST::Parse::bless_hash_rule {
    my ( $parse, $hash_rule, $blessing, $original_lhs ) = @_;
    my $grammar_level = $Marpa::R2::Internal::GRAMMAR_LEVEL;
    return if $grammar_level == 0;
    return if not defined $blessing;
    FIND_BLESSING: {
        last FIND_BLESSING if $blessing =~ /\A [\w] /xms;
        return if $blessing eq '::undef';

        # Rule may be half-formed, but assume we have lhs
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
        Marpa::R2::exception( qq{Unknown blessing "$blessing"\n} );
    } ## end FIND_BLESSING:
    $hash_rule->{bless} = $blessing;
    return 1;
} ## end sub Marpa::R2::Internal::MetaAST::Parse::bless_hash_rule

sub Marpa::R2::Internal::MetaAST_Nodes::bare_name::name { return $_[0]->[2] }

sub Marpa::R2::Internal::MetaAST_Nodes::reserved_action_name::name {
    my ( $self, $parse ) = @_;
    return $self->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::action_name::name {
    my ( $self, $parse ) = @_;
    return $self->[2]->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::event_name::name {
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
    my ( $self, $parse ) = @_;
    return $self->[2]->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::standard_name::name {
    return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::lhs::name {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $symbol ) = @{$values};
    return $symbol->name($parse);
}

# After development, delete this
sub Marpa::R2::Internal::MetaAST_Nodes::lhs::evaluate {
    my ( $values, $parse ) = @_;
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
    my ( undef, undef, $bracketed_name ) = @{$values};

    # normalize whitespace
    $bracketed_name =~ s/\A [<] \s*//xms;
    $bracketed_name =~ s/ \s* [>] \z//xms;
    $bracketed_name =~ s/ \s+ / /gxms;
    return $bracketed_name;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::bracketed_name::name

sub Marpa::R2::Internal::MetaAST_Nodes::single_quoted_name::name {
    my ($values) = @_;
    my ( undef, undef, $single_quoted_name ) = @{$values};

    # normalize whitespace
    $single_quoted_name =~ s/\A ['] \s*//xms;
    $single_quoted_name =~ s/ \s* ['] \z//xms;
    $single_quoted_name =~ s/ \s+ / /gxms;
    return $single_quoted_name;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::single_quoted_name::name

sub Marpa::R2::Internal::MetaAST_Nodes::parenthesized_rhs_primary_list::evaluate
{
    my ( $data, $parse ) = @_;
    my ( undef, undef, @values ) = @{$data};
    my @symbol_lists = map { $_->evaluate($parse); } @values;
    my $flattened_list =
        Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbol_lists);
    $flattened_list->mask_set(0);
    return $flattened_list;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::parenthesized_rhs_primary_list::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::rhs::evaluate {
    my ( $data, $parse ) = @_;
    my ( $start, $length, @values ) = @{$data};
    my $rhs = eval {
        my @symbol_lists = map { $_->evaluate($parse) } @values;
        my $flattened_list =
            Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbol_lists);
        bless {
            rhs  => $flattened_list->names($parse),
            mask => $flattened_list->mask()
            },
            $PROTO_ALTERNATIVE;
    };
    if ( not $rhs ) {
        my $eval_error = $EVAL_ERROR;
        chomp $eval_error;
        Marpa::R2::exception(
            qq{$eval_error\n},
            q{  RHS involved was },
            $parse->substring( $start, $length )
        );
    } ## end if ( not $rhs )
    return $rhs;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::rhs::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::rhs_primary::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, @values ) = @{$data};
    my @symbol_lists = map { $_->evaluate($parse) } @values;
    return Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbol_lists);
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::rhs_primary::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::rhs_primary_list::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, @values ) = @{$data};
    my @symbol_lists = map { $_->evaluate($parse) } @values;
    return Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbol_lists);
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::rhs_primary_list::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::action::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $child ) = @{$values};
    return bless { action => $child->name($parse) }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::blessing::evaluate {
    my ( $values, $parse ) = @_;
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

sub Marpa::R2::Internal::MetaAST_Nodes::event_specification::evaluate {
    my ($values) = @_;
    my $child = $values->[2];
    return bless { event => $child->name() }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::proper_specification::evaluate {
    my ($values) = @_;
    my $child = $values->[2];
    return bless { proper => $child->value() }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::pause_specification::evaluate {
    my ($values) = @_;
    my $child = $values->[2];
    return bless { pause => $child->value() }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::priority_specification::evaluate {
    my ($values) = @_;
    my $child = $values->[2];
    return bless { priority => $child->value() }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::rank_specification::evaluate {
    my ($values) = @_;
    my $child = $values->[2];
    return bless { rank => $child->value() }, $PROTO_ALTERNATIVE;
}

sub Marpa::R2::Internal::MetaAST_Nodes::before_or_after::value {
    return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::boolean::value {
    return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::signed_integer::value {
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
    my ( $start, $length, undef, $op_declare, $raw_adverb_list ) = @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    my $adverb_list = $raw_adverb_list->evaluate($parse);

    # A default rule clears the previous default
    my %default_adverbs = ();
    $parse->{default_adverbs}->[$grammar_level] = \%default_adverbs;

    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' and $grammar_level == 1 ) {
            $default_adverbs{$key} = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'bless' and $grammar_level == 1 ) {
            $default_adverbs{$key} = $adverb_list->{$key};
            next ADVERB;
        }
        die qq{Adverb "$key" not allowed in G$grammar_level default rule\n},
            '  Rule was ', $parse->substring( $start, $length ), "\n";
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::default_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::lexeme_default_statement::evaluate {
    my ( $data, $parse ) = @_;
    my ( $start, $length, $raw_adverb_list ) = @{$data};
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = 1;

    my $adverb_list = $raw_adverb_list->evaluate($parse);
    if ( exists $parse->{lexeme_default_adverbs} ) {
        my $problem_rule = $parse->substring( $start, $length );
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
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::lexeme_default_statement::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::priority_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $raw_lhs, $op_declare, $raw_priorities ) =
        @{$values};

    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = $grammar_level;
    my $lhs = $raw_lhs->name($parse);

    my ( undef, undef, @priorities ) = @{$raw_priorities};
    my $priority_count = scalar @priorities;
    my @working_rules  = ();

    my $rules = $grammar_level >= 1 ? $parse->{g1_rules} : $parse->{g0_rules};

    my $default_adverbs = $parse->{default_adverbs}->[$grammar_level];

    if ( $priority_count <= 1 ) {
        ## If there is only one priority
        my ( undef, undef, @alternatives ) = @{ $priorities[0] };
        for my $alternative (@alternatives) {
            my ($alternative_start, $alternative_end,
                $raw_rhs,           $raw_adverb_list
            ) = @{$alternative};
            my ( $proto_rule, $adverb_list );
            my $eval_ok = eval {
                $proto_rule  = $raw_rhs->evaluate($parse);
                $adverb_list = $raw_adverb_list->evaluate($parse);
                1;
            };
            if ( not $eval_ok ) {
                my $eval_error = $EVAL_ERROR;
                chomp $eval_error;
                Marpa::R2::exception(
                    qq{$eval_error\n},
                    qq{  The problem was in this RHS alternative:\n},
                    q{  },
                    $parse->substring( $alternative_start, $alternative_end ),
                    "\n"
                );
            } ## end if ( not $eval_ok )
            my @rhs_names = @{ $proto_rule->{rhs} };
            my @mask      = @{ $proto_rule->{mask} };
            if ( $grammar_level <= 0 and grep { !$_ } @mask ) {
                Marpa::R2::exception(
                    qq{hidden symbols are not allowed in lexical rules (rules LHS was "$lhs")}
                );
            }
            my %hash_rule =
                ( lhs => $lhs, rhs => \@rhs_names, mask => \@mask );

            my $action;
            my $blessing;
            my $rank;
            ADVERB: for my $key ( keys %{$adverb_list} ) {
                my $value = $adverb_list->{$key};
                if ( $key eq 'action' ) {
                    $action = $adverb_list->{$key};
                    next ADVERB;
                }
                if ( $key eq 'assoc' ) {

                    # OK, but ignored
                    next ADVERB;
                }
                if ( $key eq 'bless' ) {
                    $blessing = $adverb_list->{$key};
                    next ADVERB;
                }
                if ( $key eq 'rank' ) {
                    $rank = $adverb_list->{$key};
                    next ADVERB;
                }
                my ( $line, $column ) =
                    $parse->{meta_recce}->line_column($start);
                die qq{Adverb "$key" not allowed in an empty rule\n},
                    '  Rule was ', $parse->substring( $start, $length ), "\n";
            } ## end ADVERB: for my $key ( keys %{$adverb_list} )

            $action //= $default_adverbs->{action};
            if ( defined $action ) {
                Marpa::R2::exception(
                    'actions not allowed in lexical rules (rules LHS was "',
                    $lhs, '")' )
                    if $grammar_level <= 0;
                $hash_rule{action} = $action;
            } ## end if ( defined $action )

            $rank //= $default_adverbs->{rank};
            if ( defined $rank ) {
                Marpa::R2::exception(
                    'ranks not allowed in lexical rules (rules LHS was "',
                    $lhs, '")' )
                    if $grammar_level <= 0;
                $hash_rule{rank} = $rank;
            } ## end if ( defined $rank )

            $blessing //= $default_adverbs->{bless};
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
        ## no critic(Subroutines::ProhibitExplicitReturnUndef)
        return undef;
    } ## end if ( $priority_count <= 1 )

    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        my ( undef, undef, @alternatives ) = @{ $priorities[$priority_ix] };
        for my $alternative (@alternatives) {
            my ($alternative_start, $alternative_end,
                $raw_rhs,           $raw_adverb_list
            ) = @{$alternative};
            my ( $adverb_list, $rhs );
            my $eval_ok = eval {
                $adverb_list = $raw_adverb_list->evaluate($parse);
                $rhs         = $raw_rhs->evaluate($parse);
                1;
            };
            if ( not $eval_ok ) {
                my $eval_error = $EVAL_ERROR;
                chomp $eval_error;
                Marpa::R2::exception(
                    qq{$eval_error\n},
                    qq{  The problem was in this RHS alternative:\n},
                    q{  },
                    $parse->substring( $alternative_start, $alternative_end ),
                    "\n"
                );
            } ## end if ( not $eval_ok )
            push @working_rules, [ $priority, $rhs, $adverb_list ];
        } ## end for my $alternative (@alternatives)
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
        my ( $priority, $rhs, $adverb_list ) = @{$working_rule};
        my @new_rhs = @{ $rhs->{rhs} };
        my @arity   = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $rhs_length  = scalar @new_rhs;

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

        my $action;
        my $assoc;
        my $blessing;
        my $rank;
        ADVERB: for my $key ( keys %{$adverb_list} ) {
            my $value = $adverb_list->{$key};
            if ( $key eq 'action' ) {
                $action = $adverb_list->{$key};
                next ADVERB;
            }
            if ( $key eq 'assoc' ) {
                $assoc = $adverb_list->{$key};
                next ADVERB;
            }
            if ( $key eq 'bless' ) {
                $blessing = $adverb_list->{$key};
                next ADVERB;
            }
            if ( $key eq 'rank' ) {
                $rank = $adverb_list->{$key};
                next ADVERB;
            }
            my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
            die qq{Adverb "$key" not allowed in an empty rule\n},
                '  Rule was ', $parse->substring( $start, $length ), "\n";
        } ## end ADVERB: for my $key ( keys %{$adverb_list} )

        $assoc //= 'L';

        $action //= $default_adverbs->{action};
        if ( defined $action ) {
            Marpa::R2::exception(
                'actions not allowed in lexical rules (rules LHS was "',
                $lhs, '")' )
                if $grammar_level <= 0;
            $new_xs_rule{action} = $action;
        } ## end if ( defined $action )

        $rank //= $default_adverbs->{rank};
        if ( defined $rank ) {
            Marpa::R2::exception(
                'ranks not allowed in lexical rules (rules LHS was "',
                $lhs, '")' )
                if $grammar_level <= 0;
            $new_xs_rule{rank} = $rank;
        } ## end if ( defined $rank )

        $blessing //= $default_adverbs->{bless};
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
            die 'Unnecessary unit rule in priority rule' if $rhs_length == 1;
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
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::priority_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::empty_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $raw_lhs, $op_declare, $raw_adverb_list ) =
        @{$values};

    my $lhs = $raw_lhs->name($parse);
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = $grammar_level;

    my %rule = ( lhs => $lhs, rhs => [] );
    my $adverb_list = $raw_adverb_list->evaluate($parse);

    my $default_adverbs = $parse->{default_adverbs}->[$grammar_level];

    my $action;
    my $blessing;
    my $rank;
    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' ) {
            $action = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'bless' ) {
            $blessing = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'rank' ) {
            $action = $adverb_list->{$key};
            next ADVERB;
        }
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die qq{Adverb "$key" not allowed in an empty rule\n},
            '  Rule was ', $parse->substring( $start, $length ), "\n";
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )

    $action //= $default_adverbs->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $grammar_level <= 0;
        $rule{action} = $action;
    } ## end if ( defined $action )

    $rank //= $default_adverbs->{rank};
    if ( defined $rank ) {
        Marpa::R2::exception(
            'ranks not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $grammar_level <= 0;
        $rule{rank} = $rank;
    } ## end if ( defined $rank )

    $blessing //= $default_adverbs->{bless};
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
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::empty_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::lexeme_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $symbol, $unevaluated_adverb_list ) = @{$values};

    my $symbol_name  = $symbol->name();
    my $declarations = $parse->{lexeme_declarations}->{$symbol_name};
    if ( defined $declarations ) {
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die "Duplicate lexeme rule for <$symbol_name>\n",
            "  Only one lexeme rule is allowed for each symbol\n",
            "  Location was line $line, column $column\n",
            '  Rule was ', $parse->substring( $start, $length ), "\n";
    } ## end if ( defined $declarations )

    my $adverb_list = $unevaluated_adverb_list->evaluate();
    my %declarations;
    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $raw_value = $adverb_list->{$key};
        if ( $key eq 'priority' ) {
            $declarations{$key} = $raw_value + 0;
            next ADVERB;
        }
        if ( $key eq 'pause' ) {
            if ( $raw_value eq 'before' ) {
                $declarations{$key} = -1;
                next ADVERB;
            }
            if ( $raw_value eq 'after' ) {
                $declarations{$key} = 1;
                next ADVERB;
            }
            my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
            die qq{Bad value for "pause" adverb: "$raw_value"},
                "  Location was line $line, column $column\n",
                '  Rule was ', $parse->substring( $start, $length ), "\n";
        } ## end if ( $key eq 'pause' )
        if ( $key eq 'event' ) {
            $declarations{$key} = $raw_value;
            next ADVERB;
        }
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die qq{"$key" adverb not allowed in lexeme rule"\n},
            "  Location was line $line, column $column\n",
            '  Rule was ', $parse->substring( $start, $length ), "\n";
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )
    if ( exists $declarations{'event'} and not exists $declarations{'pause'} )
    {
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die
            qq{"event" adverb not allowed without "pause" adverb in lexeme rule"\n},
            "  Location was line $line, column $column\n",
            '  Rule was ', $parse->substring( $start, $length ), "\n";
    } ## end if ( exists $declarations{'event'} and not exists $declarations...)
    $parse->{lexeme_declarations}->{$symbol_name} = \%declarations;
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::lexeme_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::statement::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, $statement_body ) = @{$data};
    $statement_body->evaluate($parse);
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::statement::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::statement_body::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, $statement ) = @{$data};
    $statement->evaluate($parse);
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::statement_body::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::start_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $symbol ) = @{$values};
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = 0;
    push @{ $parse->{g1_rules} },
        {
        lhs    => '[:start]',
        rhs    => $symbol->names($parse),
        action => '::first'
        };
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::start_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::discard_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $symbol ) = @{$values};
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = 0;
    push @{ $parse->{g0_rules} },
        { lhs => '[:discard]', rhs => $symbol->names($parse) };
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::discard_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::quantified_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $lhs, $op_declare, $rhs, $quantifier,
        $proto_adverb_list )
        = @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    local $Marpa::R2::Internal::GRAMMAR_LEVEL = $grammar_level;

    my $adverb_list     = $proto_adverb_list->evaluate($parse);
    my $default_adverbs = $parse->{default_adverbs}->[$grammar_level];

    # Some properties of the sequence rule will not be altered
    # no matter how complicated this gets
    my %sequence_rule = (
        rhs => [ $rhs->name($parse) ],
        min => ( $quantifier->evaluate($parse) eq q{+} ? 1 : 0 )
    );

    my @rules = ( \%sequence_rule );

    my $action;
    my $blessing;
    my $separator;
    my $proper;
    my $rank;
    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' ) {
            $action = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'bless' ) {
            $blessing = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'proper' ) {
            $proper = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'rank' ) {
            $action = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'separator' ) {
            $separator = $adverb_list->{$key};
            next ADVERB;
        }
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die qq{Adverb "$key" not allowed in quantified rule\n},
            '  Rule was ', $parse->substring( $start, $length ), "\n";
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )

    # mask not needed
    my $lhs_name = $lhs->name($parse);
    $sequence_rule{lhs} = $lhs_name;

    $sequence_rule{separator} = $separator
        if defined $separator;
    $sequence_rule{proper} = $proper if defined $proper;

    $action //= $default_adverbs->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $grammar_level <= 0;
        $sequence_rule{action} = $action;
    } ## end if ( defined $action )

    $rank //= $default_adverbs->{rank};
    if ( defined $rank ) {
        Marpa::R2::exception(
            'ranks not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $grammar_level <= 0;
        $sequence_rule{rank} = $rank;
    } ## end if ( defined $rank )

    $blessing //= $default_adverbs->{bless};
    if ( defined $blessing and $grammar_level <= 0 ) {
        Marpa::R2::exception(
            'bless option not allowed in lexical rules (rules LHS was "',
            $lhs, '")' );
    }
    $parse->bless_hash_rule( \%sequence_rule, $blessing, $lhs_name );

    if ( $grammar_level > 0 ) {
        push @{ $parse->{g1_rules} }, @rules;
    }
    else {
        push @{ $parse->{g0_rules} }, @rules;
    }
    return 'quantified rule consumed';

} ## end sub Marpa::R2::Internal::MetaAST_Nodes::quantified_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::completion_event_declaration::evaluate
{
    my ( $values, $parse ) = @_;
    my ( $start, $length, $raw_event_name, $raw_symbol_name ) = @{$values};
    my $event_name        = $raw_event_name->name();
    my $symbol_name       = $raw_symbol_name->name();
    my $completion_events = $parse->{completion_events} //= {};
    if ( defined $completion_events->{$symbol_name} ) {
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die qq{Completion event for symbol "$symbol_name" declared twice\n},
            qq{  That is not allowed\n},
            '  Second declaration was ', $parse->substring( $start, $length ),
            "\n",
            "  Problem occurred at line $line, column $column\n";
    } ## end if ( defined $completion_events->{$symbol_name} )
    $completion_events->{$symbol_name} = $event_name;
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::completion_event_declaration::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::nulled_event_declaration::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $raw_event_name, $raw_symbol_name ) = @{$values};
    my $event_name    = $raw_event_name->name();
    my $symbol_name   = $raw_symbol_name->name();
    my $nulled_events = $parse->{nulled_events} //= {};
    if ( defined $nulled_events->{$symbol_name} ) {
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die qq{nulled event for symbol "$symbol_name" declared twice\n},
            qq{  That is not allowed\n},
            '  Second declaration was ', $parse->substring( $start, $length ),
            "\n",
            "  Problem occurred at line $line, column $column\n";
    } ## end if ( defined $nulled_events->{$symbol_name} )
    $nulled_events->{$symbol_name} = $event_name;
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::nulled_event_declaration::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::prediction_event_declaration::evaluate
{
    my ( $values, $parse ) = @_;
    my ( $start, $length, $raw_event_name, $raw_symbol_name ) = @{$values};
    my $event_name        = $raw_event_name->name();
    my $symbol_name       = $raw_symbol_name->name();
    my $prediction_events = $parse->{prediction_events} //= {};
    if ( defined $prediction_events->{$symbol_name} ) {
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die qq{prediction event for symbol "$symbol_name" declared twice\n},
            qq{  That is not allowed\n},
            '  Second declaration was ', $parse->substring( $start, $length ),
            "\n",
            "  Problem occurred at line $line, column $column\n";
    } ## end if ( defined $prediction_events->{$symbol_name} )
    $prediction_events->{$symbol_name} = $event_name;
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::prediction_event_declaration::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::alternatives::evaluate {
    my ( $values, $parse ) = @_;
    return bless [ map { $_->evaluate( $_, $parse ) } @{$values} ],
        ref $values;
}

sub Marpa::R2::Internal::MetaAST_Nodes::alternative::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $rhs, $adverbs ) = @{$values};
    my $alternative = eval {
        Marpa::R2::Internal::MetaAST::Proto_Alternative->combine(
            map { $_->evaluate($parse) } $rhs, $adverbs );
    };
    if ( not $alternative ) {
        Marpa::R2::exception(
            $EVAL_ERROR, "\n",
            q{  Alternative involved was },
            $parse->substring( $start, $length )
        );
    } ## end if ( not $alternative )
    return $alternative;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::alternative::evaluate

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
    return Marpa::R2::Internal::MetaAST::Symbol_List->new(
        $symbol->name($parse) );
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::single_symbol::evaluate

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
    my ($self) = @_;
    return $self->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::symbol_name::name {
    my ( $self, $parse ) = @_;
    return $self->evaluate($parse)->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::symbol_name::names {
    my ( $self, $parse ) = @_;
    return [ $self->name($parse) ];
}

sub Marpa::R2::Internal::MetaAST_Nodes::adverb_list::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, @raw_items ) = @{$data};
    my (@adverb_items) = map { $_->evaluate($parse) } @raw_items;
    return Marpa::R2::Internal::MetaAST::Proto_Alternative->combine(
        @adverb_items);
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::adverb_list::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::character_class::name {
    my ( $self, $parse ) = @_;
    return $self->evaluate($parse)->name($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::character_class::names {
    my ( $self, $parse ) = @_;
    return [ $self->name($parse) ];
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
    my $g1_symbol =
        Marpa::R2::Internal::MetaAST::Symbol_List->new($lexical_lhs);
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
        mask => [ map { ; 1 } @{$lexical_rhs} ],
    );
    push @{ $parse->{g0_rules} }, \%lexical_rule;
    my $g1_symbol =
        Marpa::R2::Internal::MetaAST::Symbol_List->new($lexical_lhs);
    return $g1_symbol;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::single_quoted_string::evaluate

package Marpa::R2::Internal::MetaAST::Symbol_List;

use English qw( -no_match_vars );

sub new {
    my ( $class, $name ) = @_;
    return bless { names => [ q{} . $name ], mask => [1] }, $class;
}

sub combine {
    my ( $class, @lists ) = @_;
    my $self = {};
    $self->{names} = [ map { @{ $_->names() } } @lists ];
    $self->{mask}  = [ map { @{ $_->mask() } } @lists ];
    return bless $self, $class;
} ## end sub combine

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
    Marpa::R2::exception( 'list->name() on symbol list of length ',
        scalar @{$names} )
        if scalar @{$names} != 1;
    return $self->{names}->[0];
} ## end sub name
sub names { return shift->{names} }
sub mask  { return shift->{mask} }

sub mask_set {
    my ( $self, $mask ) = @_;
    return $self->{mask} = [ map {$mask} @{ $self->{mask} } ];
}

1;

# vim: expandtab shiftwidth=4:
