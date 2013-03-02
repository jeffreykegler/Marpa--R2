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

package Marpa::R2::Internal::MetaAST;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.047_007';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

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

sub ast_to_hash {
    my ($ast, $bnf_source) = @_;
    my $parse = bless {
        p_source => $bnf_source,
        g0_rules => [],
        g1_rules => []
    };
    $ast->dwim_evaluate($parse);
    return $parse;
}

sub dwim_evaluate {
    my ( $value, $parse ) = @_;
    return $value if not defined $value;
    if ( Scalar::Util::blessed($value) ) {
        return $value->evaluate($parse) if $value->can('evaluate');
        return bless [ map { dwim_evaluate( $_, $parse ) } @{$value} ],
            ref $value
            if Scalar::Util::reftype($value) eq 'ARRAY';
        return $value;
    } ## end if ( Scalar::Util::blessed($value) )
    return [ map { dwim_evaluate( $_, $parse ) } @{$value} ]
        if ref $value eq 'ARRAY';
    return $value;
} ## end sub dwim_evaluate

package Marpa::R2::Internal::MetaAST::Symbol;

use English qw( -no_match_vars );

# Make the child argument into a symbol, if it is
# not one already
sub evaluate { return $_[0] }

sub new {
    my ( $class, $self, $hide ) = @_;
    return bless { name => ( '' . $self ), is_hidden => ( $hide // 0 ) },
        $class
        if ref $self eq q{};
    return $self;
} ## end sub new

sub to_symbol_list {
    Marpa::R2::Internal::MetaAST::Symbol_List->new(@_);
}

sub create_internal_symbol {
    my ( $parse, $symbol_name ) = @_;
    $parse->{needs_symbol}->{$symbol_name} = 1;
    my $symbol = Marpa::R2::Internal::MetaAST::Symbol->new($symbol_name);
    return $symbol;
} ## end sub create_internal_symbol

# Return the character class symbol name,
# after ensuring everything is set up properly
sub assign_symbol_by_char_class {
    my ( $self, $char_class, $symbol_name ) = @_;

    # character class symbol name always start with TWO left square brackets
    $symbol_name //= '[' . $char_class . ']';
    $self->{character_classes} //= {};
    my $cc_hash = $self->{character_classes};
    my ( undef, $symbol ) = $cc_hash->{$symbol_name};
    if ( not defined $symbol ) {
        my $regex;
        if ( not defined eval { $regex = qr/$char_class/xms; 1; } ) {
            Carp::croak( 'Bad Character class: ',
                $char_class, "\n", 'Perl said ', $EVAL_ERROR );
        }
        $symbol = create_internal_symbol( $self, $symbol_name );
        $cc_hash->{$symbol_name} = [ $regex, $symbol ];
    } ## end if ( not defined $symbol )
    return $symbol;
} ## end sub assign_symbol_by_char_class

sub is_symbol      { return 1 }
sub name           { return $_[0]->{name} }
sub names          { return $_[0]->{name} }
sub is_hidden      { return $_[0]->{is_hidden} }
sub are_all_hidden { return $_[0]->{is_hidden} }

sub hidden_set  { return shift->{is_hidden}  = 1; }
sub mask { return shift->is_hidden() ? 0 : 1 }

sub symbols      { return $_[0]; }
sub symbol_lists { return $_[0]; }

package Marpa::R2::Internal::MetaAST::Symbol_List;

sub new { my $class = shift; return bless { symbol_lists => [@_] }, $class }
sub is_symbol { return 0 }

sub to_symbol_list { $_[0]; }

sub names {
    return map { $_->names() } @{ shift->{symbol_lists} };
}

sub are_all_hidden {
    $_->is_hidden() || return 0 for @{ shift->{symbol_lists} };
    return 1;
}

sub is_hidden {
    return map { $_->is_hidden() } @{ shift->{symbol_lists} };
}

sub hidden_set {
    $_->hidden_set() for @{ shift->{symbol_lists} };
    return 0;
}

sub mask {
    return
        map { $_ ? 0 : 1 } map { $_->is_hidden() } @{ shift->{symbol_lists} };
}

sub symbols {
    return map { $_->symbols() } @{ shift->{symbol_lists} };
}

# The "unflattened" list, which may contain other lists
sub symbol_lists { return @{ shift->{symbol_lists} }; }

package Marpa::R2::Internal::MetaAST::Proto_Alternative;

# This class is for pieces of RHS alternatives, as they are
# being constructed

our $PROTO_ALTERNATIVE;
BEGIN { $PROTO_ALTERNATIVE = __PACKAGE__; }

sub combine {
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

package Marpa::R2::Internal::MetaAST_Nodes::action_name;

sub evaluate {
    my ($self) = @_;
    return $self->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::bare_name::name { return $_[0]->[2] }

sub Marpa::R2::Internal::MetaAST_Nodes::reserved_blessing_name::name {
    return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::blessing_name::name {
    my ($self) = @_;
    return $self->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::standard_name::name {
    return $_[0]->[2];
}

sub Marpa::R2::Internal::MetaAST_Nodes::lhs::evaluate {
    my ($values, $parse) = @_;
    return $values->[2]->evaluate($parse);
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

package Marpa::R2::Internal::MetaAST_Nodes::rhs_primary_list;

sub evaluate {
    my ( $values, $parse ) = @_;
    my @symbol_lists = map { $_->evaluate($parse) } @{$values};
    return Marpa::R2::Internal::MetaAST::Symbol_List->new(@symbol_lists);
}

package Marpa::R2::Internal::MetaAST_Nodes::action;

sub evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $child ) = @{$values};
    return bless { action => $child->evaluate($parse) }, $PROTO_ALTERNATIVE;
}

package Marpa::R2::Internal::MetaAST_Nodes::blessing;

sub evaluate {
    my ($values) = @_;
    my ( undef, undef, $child ) = @{$values};
    return bless { bless => $child->name() }, $PROTO_ALTERNATIVE;
}

package Marpa::R2::Internal::MetaAST_Nodes::right_association;

sub evaluate {
    my ($values) = @_;
    return bless { assoc => 'R' }, $PROTO_ALTERNATIVE;
}

package Marpa::R2::Internal::MetaAST_Nodes::left_association;

sub evaluate {
    my ($values) = @_;
    return bless { assoc => 'L' }, $PROTO_ALTERNATIVE;
}

package Marpa::R2::Internal::MetaAST_Nodes::group_association;

sub evaluate {
    my ($values) = @_;
    return bless { assoc => 'G' }, $PROTO_ALTERNATIVE;
}

package Marpa::R2::Internal::MetaAST_Nodes::proper_specification;

sub evaluate {
    my ($values) = @_;
    my $child = $values->[2];
    return bless { proper => $child }, $PROTO_ALTERNATIVE;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::separator_specification;

sub evaluate {
    my ( $values, $parse ) = @_;
    my $child = $values->[2];
    return bless { separator => $child->evaluate($parse) },
        $PROTO_ALTERNATIVE;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::adverb_item;

sub evaluate {
    my ( $values, $parse ) = @_;
    my $child = $values->[2]->evaluate($parse);
    return bless $child, $PROTO_ALTERNATIVE;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::default_rule;

sub evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, undef, $op_declare, $unevaluated_adverb_list ) =
        @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    my $adverb_list = $unevaluated_adverb_list->evaluate();

    # A default rule clears the previous default
    my %default_adverbs = ();
    $parse->{default_adverbs}->[$grammar_level] = \%default_adverbs;

    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' ) {
            $default_adverbs{$key} = $value;
            next ADVERB;
        }
        if ( $key eq 'bless' ) {
            $default_adverbs{$key} = $value;
            next ADVERB;
        }
        Marpa::R2::exception(qq{"$key" adverb not allowed in default rule"});
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )
    return undef;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::lexeme_rule;

sub evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $end, undef, $op_declare, $unevaluated_adverb_list ) =
        @{$values};
    Marpa::R2::exception( "lexeme rule not allowed in G0\n",
        "  Rule was ", $parse->positions_to_string( $start, $end ) )
        if $op_declare->op() ne q{::=};
    my $adverb_list = $unevaluated_adverb_list->evaluate();

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

sub Marpa::R2::Internal::MetaAST_Nodes::discard_rule::evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $end, $symbol ) = @{$values};
    local $parse->{grammar_level} = 0;
    push @{ $parse->{g0_rules} },
        { lhs => '[:discard]', rhs => [ $symbol->evaluate()->name() ] };
    return undef;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::discard_rule::evaluate

package Marpa::R2::Internal::MetaAST_Nodes::quantified_rule;
sub evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, undef, $op_declare ) = @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    local $parse->{grammar_level} = $grammar_level;
    return
        bless [
        map { Marpa::R2::Internal::MetaAST::dwim_evaluate( $_, $parse ) }
            @{$values} ],
        __PACKAGE__;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::priority_rule;

sub evaluate {
    my ( $values, $parse ) = @_;
    my ( $start, $end, $lhs, $op_declare, $priorities ) = @{$values};
    my $grammar_level = $op_declare->op() eq q{::=} ? 1 : 0;
    local $parse->{grammar_level} = $grammar_level;
    return bless [
        lhs        => $lhs->evaluate(),
        priorities => [ map { $_->evaluate($parse) } @{$priorities} ]
        ],
        __PACKAGE__;
}

package Marpa::R2::Internal::MetaAST_Nodes::alternatives;

sub evaluate {
    my ( $values, $parse ) = @_;
    return
        bless [
        map { Marpa::R2::Internal::MetaAST::dwim_evaluate( $_, $parse ) }
            @{$values} ],
        __PACKAGE__;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::alternative;

sub evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $rhs, $adverbs ) = @{$values};
    return bless [
        rhs     => $rhs->evaluate($parse),
        adverbs => $adverbs->evaluate($parse),
        ],
        __PACKAGE__;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::rhs;

sub evaluate {
    my ( $values, $parse ) = @_;
    return
        bless [
        map { Marpa::R2::Internal::MetaAST::dwim_evaluate( $_, $parse ) }
            @{$values} ],
        __PACKAGE__;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::rhs_primary;

sub evaluate {
    my ( $values, $parse ) = @_;
    return
        bless [
        map { Marpa::R2::Internal::MetaAST::dwim_evaluate( $_, $parse ) }
            @{$values} ],
        __PACKAGE__;
} ## end sub evaluate

package Marpa::R2::Internal::MetaAST_Nodes::parenthesized_rhs_primary_list;

sub evaluate {
    my ( $values, $parse ) = @_;
    return
        bless [
        map { Marpa::R2::Internal::MetaAST::dwim_evaluate( $_, $parse ) }
            @{$values} ],
        __PACKAGE__;
} ## end sub evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::single_symbol::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $symbol ) = @{$values};
    return Marpa::R2::Internal::MetaAST::Symbol->new($symbol->name($parse));
}

sub Marpa::R2::Internal::MetaAST_Nodes::Symbol::evaluate {
    my ( $values, $parse ) = @_;
    my ( undef, undef, $symbol ) = @{$values};
    return $symbol->evaluate($parse);
}

sub Marpa::R2::Internal::MetaAST_Nodes::symbol::name { my ($self) = @_; return $self->[2]; }
sub Marpa::R2::Internal::MetaAST_Nodes::symbol_name::evaluate {
my ($self) = @_; return $self->[2]; }
sub Marpa::R2::Internal::MetaAST_Nodes::symbol_name::name {
my ($self, $parse) = @_; return $self->evaluate($parse)->name($parse); }

package Marpa::R2::Internal::MetaAST_Nodes::adverb_list;

sub evaluate {
    my ( $values, $parse ) = @_;
    my (@adverb_items) = map { $_->evaluate($parse) } @{$values};
    return Marpa::R2::Internal::MetaAST::Proto_Alternative->combine(
        @adverb_items);
} ## end sub evaluate

sub Marpa::R2::Internal::MetaAST_Nodes::character_class::name {
my ($self, $parse) = @_; return $self->evaluate($parse)->name($parse); }

sub Marpa::R2::Internal::MetaAST_Nodes::character_class::evaluate {
    my ( $values, $parse ) = @_;
    my $symbol =
        Marpa::R2::Internal::MetaAST::Symbol::assign_symbol_by_char_class(
        $parse, $values->[2] );
    $DB::single = defined $parse->{grammar_level} ? 0 : 1;
    return $symbol if $parse->{grammar_level} <= 0;
    my $lexical_lhs_index = $parse->{lexical_lhs_index}++;
    my $lexical_lhs       = "[Lex-$lexical_lhs_index]";
    my %lexical_rule      = (
        lhs  => $lexical_lhs,
        rhs  => [ $symbol->names() ],
        mask => [ $symbol->mask() ],
    );
    push @{ $parse->{g0_rules} }, \%lexical_rule;
    my $g1_symbol = Marpa::R2::Internal::MetaAST::Symbol->new($lexical_lhs);
    return $g1_symbol;
} ## end sub Marpa::R2::Internal::MetaAST_Nodes::character_class::evaluate

package Marpa::R2::Internal::MetaAST_Nodes::single_quoted_string;

sub evaluate {
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
            Marpa::R2::Internal::MetaAST::Symbol::assign_symbol_by_char_class(
            $parse, $char_class );
        push @symbols, $symbol;
    } ## end for my $char_class ( map { '[' . ( quotemeta $_ ) . ']'...})
    my $list = Marpa::R2::Internal::MetaAST::Symbol_List->new(@symbols);
    return $list if $parse->{grammar_level} <= 0;
    my $lexical_lhs_index = $parse->{lexical_lhs_index}++;
    my $lexical_lhs       = "[Lex-$lexical_lhs_index]";
    my %lexical_rule      = (
        lhs  => $lexical_lhs,
        rhs  => [ $list->names() ],
        mask => [ $list->mask() ],
    );
    push @{ $parse->{g0_rules} }, \%lexical_rule;
    my $g1_symbol = Marpa::R2::Internal::MetaAST::Symbol->new($lexical_lhs);
    return $g1_symbol;
} ## end sub evaluate

1;

# vim: expandtab shiftwidth=4:
