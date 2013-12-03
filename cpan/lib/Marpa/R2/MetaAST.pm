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
$VERSION        = '2.077_003';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::MetaAST;

use English qw( -no_match_vars );

sub new {
    my ( $class, $p_rules_source ) = @_;
    my $meta_recce = Marpa::R2::Internal::Scanless::meta_recce();
    $meta_recce->read($p_rules_source);
    if ( $meta_recce->ambiguity_metric() > 1 ) {
	my $asf = Marpa::R2::ASF->new( { slr => $meta_recce } );
	say STDERR 'No ASF' if not defined $asf;
	my $ambiguities = Marpa::R2::Internal::ASF::ambiguities( $asf );
	my @ambiguities = grep { defined } @{$ambiguities}[0 .. 1 ];
        Marpa::R2::exception(
            "Parse of BNF/Scanless source is ambiguous\n",
            Marpa::R2::Internal::ASF::ambiguities_show( $asf, \@ambiguities )
        );
    }
    my $value_ref = $meta_recce->value();
    Marpa::R2::exception('Parse of BNF/Scanless source failed')
        if not defined $value_ref;
    my $ast = { meta_recce => $meta_recce, top_node => ${$value_ref} };
    return bless $ast, $class;
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
    my ($ast) = @_;
    my $hashed_ast = {};

    $hashed_ast->{meta_recce} = $ast->{meta_recce};
    bless $hashed_ast, 'Marpa::R2::Internal::MetaAST::Parse';

    $hashed_ast->{current_lexer} = 'L0';
    $hashed_ast->{rules}->{G1} = [];
    my $g1_symbols = $hashed_ast->{symbols}->{G1} = {};

    my ( undef, undef, @statements ) = @{ $ast->{top_node} };

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
        $_->evaluate($hashed_ast) for @statements;
        1;
    };
    Marpa::R2::exception($EVAL_ERROR) if not $eval_ok;

    my %grammars = ();
    $grammars{$_} = 1 for keys %{ $hashed_ast->{rules} };
    my @lexers =
        grep { ( substr $_, 0, 1 ) eq 'L' } keys %grammars;

    for my $lexer (@lexers) {
        my $lexer_name = $lexer;
        NAME_LEXER: {
            if ( $lexer eq 'L0' ) {
                $lexer_name = "L0 (the default)";
                last NAME_LEXER;
            }
            last NAME_LEXER if ( substr $lexer_name, 0, 2 ) ne 'L-';
            $lexer_name = substr $lexer_name, 2;
        } ## end NAME_LEXER:
    } ## end for my $lexer (@lexers)

        my %stripped_character_classes = ();
        {
            my $character_classes = $hashed_ast->{character_classes};
            for my $symbol_name ( sort keys %{$character_classes} ) {
                my ($re) = @{ $character_classes->{$symbol_name} };
                $stripped_character_classes{$symbol_name} = $re;
            }
        }
        $hashed_ast->{character_classes} = \%stripped_character_classes;

    return $hashed_ast;
} ## end sub ast_to_hash

sub Marpa::R2::Internal::MetaAST::Parse::start_rule_setup {
    my ($ast) = @_;
    my $start_lhs = $ast->{'start_lhs'} // $ast->{'first_lhs'};
    Marpa::R2::exception('No rules in SLIF grammar')
        if not defined $start_lhs;
    Marpa::R2::Internal::MetaAST::start_rule_create( $ast, $start_lhs );
} ## end sub Marpa::R2::Internal::MetaAST::Parse::start_rule_setup

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
    return if (substr $Marpa::R2::Internal::SUBGRAMMAR, 0, 1) eq 'L';
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

sub Marpa::R2::Internal::MetaAST_Nodes::lexer_name::name {
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

sub Marpa::R2::Internal::MetaAST_Nodes::Perl_name::name {
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

sub Marpa::R2::Internal::MetaAST_Nodes::null_ranking_specification::evaluate {
    my ($values) = @_;
    my $child = $values->[2];
    return bless { null_ranking => $child->value() }, $PROTO_ALTERNATIVE;
}


sub Marpa::R2::Internal::MetaAST_Nodes::null_ranking_constant::value {
    return $_[0]->[2];
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
    my $subgrammar = $op_declare->op() eq q{::=} ? 'G1' : $parse->{current_lexer};
    my $adverb_list = $raw_adverb_list->evaluate($parse);

    # A default rule clears the previous default
    my %default_adverbs = ();
    $parse->{default_adverbs}->{$subgrammar} = \%default_adverbs;

    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' and $subgrammar eq 'G1' ) {
            $default_adverbs{$key} = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'bless' and $subgrammar eq 'G1' ) {
            $default_adverbs{$key} = $adverb_list->{$key};
            next ADVERB;
        }
        die qq{Adverb "$key" not allowed in $subgrammar default rule\n},
            '  Rule was ', $parse->substring( $start, $length ), "\n";
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::default_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::lexeme_default_statement::evaluate {
    my ( $data, $parse ) = @_;
    my ( $start, $length, $raw_adverb_list ) = @{$data};
    local $Marpa::R2::Internal::SUBGRAMMAR = 'G1';

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

    my $current_lexer = $parse->{current_lexer};
    my $subgrammar;
    if ( $op_declare->op() eq q{::=} ) {
        if ( $current_lexer ne 'L0' ) {
            my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
            die "G1 rules currently allowed only when L0 is current lexer\n",
                qq{  A prioritized rule was found when "$current_lexer" was the current lexer\n"},
                "  Location was line $line, column $column\n",
                '  Rule was ', $parse->substring( $start, $length ), "\n";
        } ## end if ( $current_lexer ne 'L0' )
        $subgrammar = 'G1';
    } ## end if ( $op_declare->op() eq q{::=} )
    else {
        $subgrammar = $current_lexer;
    }

    my $lhs = $raw_lhs->name($parse);
    $parse->{'first_lhs'} //= $lhs if $subgrammar eq 'G1';
    local $Marpa::R2::Internal::SUBGRAMMAR = $subgrammar;

    my ( undef, undef, @priorities ) = @{$raw_priorities};
    my $priority_count = scalar @priorities;
    my @working_rules  = ();

    $parse->{rules}->{$subgrammar} //= [];
    my $rules = $parse->{rules}->{$subgrammar};

    my $default_adverbs = $parse->{default_adverbs}->{$subgrammar};

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
            if ( ( substr $subgrammar, 0, 1 ) eq 'L'
                and grep { !$_ } @mask )
            {
                Marpa::R2::exception(
                    qq{hidden symbols are not allowed in lexical rules (rules LHS was "$lhs")}
                );
            }
            my %hash_rule =
                ( lhs => $lhs, rhs => \@rhs_names, mask => \@mask );

            my $action;
            my $blessing;
            my $null_ranking;
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
                if ( $key eq 'null_ranking' ) {
                    $null_ranking = $adverb_list->{$key};
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
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
                $hash_rule{action} = $action;
            } ## end if ( defined $action )

            $rank //= $default_adverbs->{rank};
            if ( defined $rank ) {
                Marpa::R2::exception(
                    'ranks not allowed in lexical rules (rules LHS was "',
                    $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
                $hash_rule{rank} = $rank;
            } ## end if ( defined $rank )

            $null_ranking //= $default_adverbs->{null_ranking};
            if ( defined $null_ranking ) {
                Marpa::R2::exception(
                    'null-ranking allowed in lexical rules (rules LHS was "',
                    $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
                $hash_rule{null_ranking} = $null_ranking;
            } ## end if ( defined $rank )

            $blessing //= $default_adverbs->{bless};
            if (defined $blessing
                and
                 ( substr $subgrammar, 0, 1 ) eq 'L' 
                )
            {
                Marpa::R2::exception(
                    'bless option not allowed in lexical rules (rules LHS was "',
                    $lhs, '")'
                );
            }
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
    @arg0_action = ( action => '::first' ) if $subgrammar eq 'G1';
    push @{$rules},
        {
        lhs => $lhs,
        rhs => [ $parse->prioritized_symbol( $lhs, 0 ) ],
        @arg0_action,
        description => qq{Internal rule top priority rule for <$lhs>},
        },
        (
        map {
            ;
            {   lhs         => $parse->prioritized_symbol( $lhs,   $_ - 1 ),
                rhs         => [ $parse->prioritized_symbol( $lhs, $_ ) ],
                description => (
                    qq{Internal rule for symbol <$lhs> priority transition from }
                        . ( $_ - 1 )
                        . qq{ to $_}
                ),
                @arg0_action
            }
        } 1 .. $priority_count - 1
        );
    RULE: for my $working_rule (@working_rules) {
        my ( $priority, $rhs, $adverb_list ) = @{$working_rule};
        my @new_rhs = @{ $rhs->{rhs} };
        my @arity   = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $rhs_length  = scalar @new_rhs;

        my $current_exp = $parse->prioritized_symbol( $lhs, $priority );
        my @mask = @{ $rhs->{mask} };
        if ( (  substr $subgrammar, 0, 1 ) eq 'L' and grep { !$_ } @mask )
        {
            Marpa::R2::exception(
                'hidden symbols are not allowed in lexical rules (rules LHS was "',
                $lhs, '")'
            );
        }
        my %new_xs_rule = ( lhs => $current_exp );
        $new_xs_rule{mask} = \@mask;

        my $action;
        my $assoc;
        my $blessing;
        my $rank;
        my $null_ranking;
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
            if ( $key eq 'null_ranking' ) {
                $null_ranking = $adverb_list->{$key};
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
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
            $new_xs_rule{action} = $action;
        } ## end if ( defined $action )

        $null_ranking //= $default_adverbs->{null_ranking};
        if ( defined $null_ranking ) {
            Marpa::R2::exception(
                'null-ranking not allowed in lexical rules (rules LHS was "',
                $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
            $new_xs_rule{null_ranking} = $null_ranking;
        } ## end if ( defined $rank )

        $rank //= $default_adverbs->{rank};
        if ( defined $rank ) {
            Marpa::R2::exception(
                'ranks not allowed in lexical rules (rules LHS was "',
                $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
            $new_xs_rule{rank} = $rank;
        } ## end if ( defined $rank )

        $blessing //= $default_adverbs->{bless};
        if ( defined $blessing
            and ( substr $subgrammar, 0, 1 ) eq 'L' )
        {
            Marpa::R2::exception(
                'bless option not allowed in lexical rules (rules LHS was "',
                $lhs, '")'
            );
        }
        $parse->bless_hash_rule( \%new_xs_rule, $blessing, $lhs );

        my $next_priority = $priority + 1;
        $next_priority = 0 if $next_priority >= $priority_count;
        my $next_exp = $parse->prioritized_symbol( $lhs, $next_priority);

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
                    $new_rhs[$rhs_ix] = $parse->prioritized_symbol( $lhs, 0 );
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

    my $current_lexer = $parse->{current_lexer};
    my $subgrammar;
    if ( $op_declare->op() eq q{::=} ) {
        if ( $current_lexer ne 'L0' ) {
            my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
            die "G1 rules currently allowed only when L0 is current lexer\n",
                qq{  An empty rule was found when "$current_lexer" was the current lexer\n"},
                "  Location was line $line, column $column\n",
                '  Rule was ', $parse->substring( $start, $length ), "\n";
        } ## end if ( $current_lexer ne 'L0' )
        $subgrammar = 'G1';
    } ## end if ( $op_declare->op() eq q{::=} )
    else {
        $subgrammar = $current_lexer;
    }

    my $lhs = $raw_lhs->name($parse);
    $parse->{'first_lhs'} //= $lhs if $subgrammar eq 'G1';
    local $Marpa::R2::Internal::SUBGRAMMAR = $subgrammar;

    my %rule = ( lhs => $lhs,
    description => qq{Empty rule for <$lhs>},
    rhs => [] );
    my $adverb_list = $raw_adverb_list->evaluate($parse);

    my $default_adverbs = $parse->{default_adverbs}->{$subgrammar};

    my $action;
    my $blessing;
    my $rank;
    my $null_ranking;
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
        if ( $key eq 'null_ranking' ) {
            $null_ranking = $adverb_list->{$key};
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

    $action //= $default_adverbs->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
        $rule{action} = $action;
    } ## end if ( defined $action )

    $null_ranking //= $default_adverbs->{null_ranking};
    if ( defined $null_ranking ) {
        Marpa::R2::exception(
            'null-ranking not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
        $rule{null_ranking} = $null_ranking;
    } ## end if ( defined $null_ranking )

    $rank //= $default_adverbs->{rank};
    if ( defined $rank ) {
        Marpa::R2::exception(
            'ranks not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
        $rule{rank} = $rank;
    } ## end if ( defined $rank )

    $blessing //= $default_adverbs->{bless};
    if ( defined $blessing
        and ( substr $subgrammar, 0, 1 ) eq 'L' )
    {
        Marpa::R2::exception(
            'bless option not allowed in lexical rules (rules LHS was "',
            $lhs, '")' );
    }
    $parse->bless_hash_rule( \%rule, $blessing, $lhs );

    # mask not needed
    push @{ $parse->{rules}->{$subgrammar} }, \%rule;

    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
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

sub Marpa::R2::Internal::MetaAST_Nodes::statements::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, @statement_list ) = @{$data};
    map { $_->evaluate($parse) } @statement_list;
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::statements::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::statement::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, $child ) = @{$data};
    $child->evaluate($parse);
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::statement::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::null_statement::evaluate {
    return undef;
}

sub Marpa::R2::Internal::MetaAST_Nodes::statement_group::evaluate {
    my ( $data, $parse ) = @_;
    my ( undef, undef, $statements ) = @{$data};
    $statements->evaluate($parse);
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
}

sub Marpa::R2::Internal::MetaAST::start_rule_create {
    my ( $parse, $symbol_name ) = @_;
    my $start_lhs = '[:start]';
    $parse->{'default_g1_start_action'} =
        $parse->{'default_adverbs'}->{'G1'}->{'action'};
    $parse->{'symbols'}->{'G1'}->{$start_lhs} = {
        display_form => ':start',
        description  => 'Internal G1 start symbol'
    };
    push @{ $parse->{rules}->{G1} },
        {
        lhs    => $start_lhs,
        rhs    => [$symbol_name],
        action => '::first'
        };
} ## end sub Marpa::R2::Internal::MetaAST::start_rule_create

sub Marpa::R2::Internal::MetaAST_Nodes::start_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $symbol ) = @{$values};
    if ( defined $parse->{'start_lhs'} ) {
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die qq{There are two start rules\n},
            qq{  That is not allowed\n},
            '  The second start rule is ',
            $parse->substring( $start, $length ),
            "\n",
            "  Problem occurred at line $line, column $column\n";
    } ## end if ( defined $parse->{'start_lhs'} )
    $parse->{'start_lhs'} = $symbol->name($parse);
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::start_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::discard_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $symbol ) = @{$values};
    my $lexer_name = $parse->{current_lexer};
    my $discard_lhs = '[:discard]';
    $parse->symbol_names_set(
        $discard_lhs,
        'L',
        {   display_form => ':discard',
            description  => qq{Internal LHS for lexer "$lexer_name" discard}
        }
    );
    my $rhs = $symbol->names($parse);
    push @{ $parse->{rules}->{$lexer_name} },
        {
        description => (
            "Discard rule for " . join q{ },
            map { '<' . $_ . '>' } @{$rhs}
        ),
        lhs => $discard_lhs,
        rhs => $rhs
        };
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::discard_rule::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::quantified_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $length, $lhs, $op_declare, $rhs, $quantifier,
        $proto_adverb_list )
        = @{$values};

    my $subgrammar;
    my $current_lexer = $parse->{current_lexer};
    if ( $op_declare->op() eq q{::=} ) {
        if ( $current_lexer ne 'L0' ) {
            my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
            die "G1 rules currently allowed only when L0 is current lexer\n",
                qq{  A quantified rule was found when "$current_lexer" was the current lexer\n"},
                "  Location was line $line, column $column\n",
                '  Rule was ', $parse->substring( $start, $length ), "\n";
        } ## end if ( $current_lexer ne 'L0' )
        $subgrammar = 'G1';
    } ## end if ( $op_declare->op() eq q{::=} )
    else {
        $subgrammar = $current_lexer;
    }

    my $lhs_name = $lhs->name($parse);
    $parse->{'first_lhs'} //= $lhs_name if $subgrammar eq 'G1';
    local $Marpa::R2::Internal::SUBGRAMMAR = $subgrammar;

    my $adverb_list     = $proto_adverb_list->evaluate($parse);
    my $default_adverbs = $parse->{default_adverbs}->{$subgrammar};

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
    my $null_ranking;
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
            $rank = $adverb_list->{$key};
            next ADVERB;
        }
        if ( $key eq 'null_ranking' ) {
            $null_ranking = $adverb_list->{$key};
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
    $sequence_rule{lhs} = $lhs_name;

    $sequence_rule{separator} = $separator
        if defined $separator;
    $sequence_rule{proper} = $proper if defined $proper;

    $action //= $default_adverbs->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
        $sequence_rule{action} = $action;
    } ## end if ( defined $action )

    $null_ranking //= $default_adverbs->{null_ranking};
    if ( defined $null_ranking ) {
        Marpa::R2::exception(
            'null-ranking not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
        $sequence_rule{null_ranking} = $null_ranking;
    } ## end if ( defined $null_ranking )

    $rank //= $default_adverbs->{rank};
    if ( defined $rank ) {
        Marpa::R2::exception(
            'ranks not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
		    if  ( substr $subgrammar, 0, 1 ) eq 'L';
        $sequence_rule{rank} = $rank;
    } ## end if ( defined $rank )

    $blessing //= $default_adverbs->{bless};
    if ( defined $blessing and ( substr $subgrammar, 0, 1 ) eq 'L' )
    {
        Marpa::R2::exception(
            'bless option not allowed in lexical rules (rules LHS was "',
            $lhs, '")' );
    }
    $parse->bless_hash_rule( \%sequence_rule, $blessing, $lhs_name );

    push @{ $parse->{rules}->{$subgrammar} }, @rules;
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;

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

sub Marpa::R2::Internal::MetaAST_Nodes::current_lexer_statement::evaluate
{
    my ( $values, $parse ) = @_;
    my ( $start, $length, $raw_lexer_name ) = @{$values};
    my $lexer_name        = $raw_lexer_name->name();
    if ( $lexer_name ne 'L0' and $lexer_name =~ m/\A [[:upper:]] [[:digit:]]+ \z/xms) {
        my ( $line, $column ) = $parse->{meta_recce}->line_column($start);
        die qq{Attempt to name a new lexer "$lexer_name"\n},
            qq{  Lexer names of the form [A-Z][0-9]+ are reserved\n},
            qq{  Please choose another name\n},
            "  Problem occurred at line $line, column $column\n";
    } ## end if ( defined $prediction_events->{$symbol_name} )
    $parse->{current_lexer} = $lexer_name;
    ## no critic(Subroutines::ProhibitExplicitReturnUndef)
    return undef;
}

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
    my ( undef, undef, $adverb_list_items ) = @{$data};
    return undef if not defined $adverb_list_items;
    return $adverb_list_items->evaluate($parse);
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::adverb_list::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::null_adverb::evaluate {
    return {};
}

sub Marpa::R2::Internal::MetaAST_Nodes::adverb_list_items::evaluate {
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
    my $character_class = $values->[2];
    my $subgrammar = $Marpa::R2::Internal::SUBGRAMMAR;
    if  (( substr $subgrammar, 0, 1 ) eq 'L') {
        return Marpa::R2::Internal::MetaAST::Symbol_List->char_class_to_symbol(
            $parse, $character_class );
    }
    # If here, in G1
    # Character classes and strings always go into L0, for now
    my $lexer_symbol = do {
        local $Marpa::R2::Internal::SUBGRAMMAR = 'L0';
        Marpa::R2::Internal::MetaAST::Symbol_List->char_class_to_symbol(
            $parse, $character_class );
    };
    my $lexical_lhs       = $parse->internal_lexeme($character_class);
    my $lexical_rhs       = $lexer_symbol->names($parse);
    my %lexical_rule      = (
        lhs  => $lexical_lhs,
        rhs  => $lexical_rhs,
        mask => [1],
    );
    push @{ $parse->{rules}->{L0} }, \%lexical_rule;
    my $g1_symbol =
        Marpa::R2::Internal::MetaAST::Symbol_List->new($lexical_lhs);
    return $g1_symbol;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::character_class::evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::single_quoted_string::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $string ) = @{$values};
    my @symbols = ();

    my $end_of_string = rindex $string, q{'};
      my $unmodified_string = substr $string, 0, $end_of_string+1;
      my $raw_flags = substr $string, $end_of_string+1;
    my $flags = Marpa::R2::Internal::MetaAST::flag_string_to_flags($raw_flags);
    my $subgrammar = $Marpa::R2::Internal::SUBGRAMMAR;

    # If we are currently in a lexical grammar, the strings go there
    # If we are currently in G1, the strings always go into L0
    my $lexical_grammar = $subgrammar eq 'G1' ? 'L0' : $subgrammar;

    for my $char_class (
        map { '[' . ( quotemeta $_ ) . ']' . $flags } split //xms,
        substr $unmodified_string,
        1, -1
        )
    {
        local $Marpa::R2::Internal::SUBGRAMMAR = $lexical_grammar;
        my $symbol =
            Marpa::R2::Internal::MetaAST::Symbol_List->char_class_to_symbol(
            $parse, $char_class );
        push @symbols, $symbol;
    } ## end for my $char_class ( map { '[' . ( quotemeta $_ ) . ']'...})
    my $list = Marpa::R2::Internal::MetaAST::Symbol_List->combine(@symbols);
    return $list if $Marpa::R2::Internal::SUBGRAMMAR ne 'G1';
    my $lexical_lhs       = $parse->internal_lexeme($string);
    my $lexical_rhs       = $list->names($parse);
    my %lexical_rule      = (
        lhs  => $lexical_lhs,
        rhs  => $lexical_rhs,
        description => "Internal rule for single-quoted string $string",
        mask => [ map { ; 1 } @{$lexical_rhs} ],
    );
    push @{ $parse->{rules}->{$lexical_grammar} }, \%lexical_rule;
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

sub Marpa::R2::Internal::MetaAST::char_class_to_re {
    my ($cc_components) = @_;
    die if ref $cc_components ne 'ARRAY';
    my ( $char_class, $flags ) = @{$cc_components};
    $flags = $flags ? '(' . q{?} . $flags . ')' : q{};
    my $regex;
    my $error;
    if ( not defined eval { $regex = qr/$flags$char_class/xms; 1; } ) {
        $error = qq{Problem in evaluating character class: "$char_class"\n};
        $error .= qq{  Flags were "$flags"\n} if $flags;
        $error .= $EVAL_ERROR;
    }
    return $regex, $error;
}

sub Marpa::R2::Internal::MetaAST::flag_string_to_flags {
    my ($raw_flag_string) = @_;
    return q{} if not $raw_flag_string;
    my @raw_flags = split m/:/xms, $raw_flag_string;
    my %flags = ();
    RAW_FLAG: for my $raw_flag (@raw_flags) {
        next RAW_FLAG if not $raw_flag;
        if ( $raw_flag eq 'i' ) {
            $flags{'i'} = 1;
            next RAW_FLAG;
        }
        if ( $raw_flag eq 'ic' ) {
            $flags{'i'} = 1;
            next RAW_FLAG;
        }
        Carp::croak(
            qq{Bad flag for character class\n},
            qq{  Flag string was $raw_flag_string\n},
            qq{  Bad flag was $raw_flag\n}
        );
    } ## end RAW_FLAG: for my $raw_flag (@raw_flags)
    my $cooked_flags = join q{}, sort keys %flags;
    return $cooked_flags;
} ## end sub flag_string_to_flags

# Return the character class symbol name,
# after ensuring everything is set up properly
sub char_class_to_symbol {
    my ( $class, $parse, $char_class ) = @_;

    my $end_of_char_class = rindex $char_class, q{]};
      my $unmodified_char_class = substr $char_class, 0, $end_of_char_class+1;
      my $raw_flags = substr $char_class, $end_of_char_class+1;
    my $flags = Marpa::R2::Internal::MetaAST::flag_string_to_flags($raw_flags);
    my $subgrammar = $Marpa::R2::Internal::SUBGRAMMAR;

    # character class symbol name always start with TWO left square brackets
    my $symbol_name = '[' . $unmodified_char_class . $flags . ']';
    $parse->{character_classes} //= {};
    my $cc_hash = $parse->{character_classes};
    my ( undef, $symbol ) = $cc_hash->{$symbol_name};
    if ( not defined $symbol ) {

        my $cc_components = [$unmodified_char_class, $flags];

        # Fast fail on badly formed char_class -- we re-evaluate the regex just in time
        # before we register characters.
        my ( $regex, $eval_error ) =
            Marpa::R2::Internal::MetaAST::char_class_to_re($cc_components);
        Carp::croak( 'Bad Character class: ',
            $char_class, "\n", 'Perl said ', $eval_error )
            if not $regex;

        $symbol =
            Marpa::R2::Internal::MetaAST::Symbol_List->new($symbol_name);
        $cc_hash->{$symbol_name} = [ $cc_components, $symbol ];
        $parse->symbol_names_set(
            $symbol_name,
            $subgrammar,
            {   dsl_form     => $char_class,
                display_form => $char_class,
                description  => "Character class: $char_class"
            }
        );
    } ## end if ( not defined $symbol )
    return $symbol;
} ## end sub char_class_to_symbol

sub Marpa::R2::Internal::MetaAST::Parse::symbol_names_set {
    my ( $parse, $symbol, $subgrammar, $args ) = @_;
    my $symbol_type = $subgrammar eq 'G1' ? 'G1' : 'L';
    for my $arg_type (keys %{$args}) {
        my $value = $args->{$arg_type};
        $parse->{symbols}->{$symbol_type}->{$symbol}->{$arg_type} = $value;
    }
}

# Return the priotized symbol name,
# after ensuring everything is set up properly
sub Marpa::R2::Internal::MetaAST::Parse::prioritized_symbol {
    my ( $parse, $base_symbol, $priority ) = @_;

    # character class symbol name always start with TWO left square brackets
    my $symbol_name = $base_symbol . '[' . $priority . ']';
    my $symbol_data =
        $parse->{symbols}->{$Marpa::R2::Internal::SUBGRAMMAR eq 'G1' ? 'G1' : 'L'}->{$symbol_name};
    return $symbol_name if defined $symbol_data;
    my $display_form =
        ( $base_symbol =~ m/\s/xms ) ? "<$base_symbol>" : $base_symbol;
    $parse->symbol_names_set(
        $symbol_name,
        $Marpa::R2::Internal::SUBGRAMMAR,
        {   legacy_name  => $base_symbol,
            dsl_form     => $base_symbol,
            display_form => $display_form,
            description  => "<$base_symbol> at priority $priority"
        }
    );
    return $symbol_name;
} ## end sub Marpa::R2::Internal::MetaAST::Parse::prioritized_symbol

# Return the prioritized symbol name,
# after ensuring everything is set up properly
sub Marpa::R2::Internal::MetaAST::Parse::internal_lexeme {
    my ( $parse, $dsl_form, @grammars ) = @_;

    # character class symbol name always start with TWO left square brackets
    my $lexical_lhs_index = $parse->{lexical_lhs_index}++;
    my $lexical_symbol    = "[Lex-$lexical_lhs_index]";
    my %names             = (
        dsl_form     => $dsl_form,
        display_form => $dsl_form,
        description  => qq{Internal lexical symbol for "$dsl_form"}
    );
    $parse->symbol_names_set( $lexical_symbol, $_, \%names ) for qw(G1 L);
    return $lexical_symbol;
} ## end sub Marpa::R2::Internal::MetaAST::Parse::internal_lexeme

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
