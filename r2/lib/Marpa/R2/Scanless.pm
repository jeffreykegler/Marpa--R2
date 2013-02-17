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

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.047_004';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

# The grammars and recognizers are numbered starting
# with the lexer, which is grammar 0 -- G0.
# The "higher level" grammar is G1.
# In theory, this scheme could be extended to more than
# two layers.

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::R2::Inner::Scanless::G

    C { The thin version of this object }

    THICK_LEX_GRAMMAR
    THICK_G1_GRAMMAR
    CHARACTER_CLASS_TABLE
    G0_RULE_TO_G1_LEXEME
    G0_DISCARD_SYMBOL_ID
    MASK_BY_RULE_ID

    TRACE_FILE_HANDLE
    DEFAULT_ACTION
    ACTION_OBJECT
    BLESS_PACKAGE

END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::R2::Inner::Scanless::R

    C { The thin version of this object }

    GRAMMAR
    THICK_G1_RECCE
    P_INPUT_STRING

    TRACE_FILE_HANDLE
    TRACE_TERMINALS
    READ_STRING_ERROR

END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN


package Marpa::R2::Inner::Scanless;

use Scalar::Util 'blessed';

# names of packages for strings
our $G_PACKAGE = 'Marpa::R2::Scanless::G';
our $R_PACKAGE = 'Marpa::R2::Scanless::R';
our $GRAMMAR_LEVEL;
our $TRACE_FILE_HANDLE;

package Marpa::R2::Inner::Scanless::Symbol;

use constant NAME => 0;
use constant HIDE => 1;

sub new { my $class = shift; return bless { name => $_[NAME], is_hidden => ($_[HIDE]//0) }, $class }
sub is_symbol { return 1 };
sub name { return $_[0]->{name} }
sub names { return $_[0]->{name} }
sub is_hidden { return $_[0]->{is_hidden} }
sub are_all_hidden { return $_[0]->{is_hidden} }

sub is_lexical { return shift->{is_lexical} // 0 }
sub hidden_set { return shift->{is_hidden} = 1; }
sub lexical_set { return shift->{is_lexical} = 1; }
sub mask { return shift->is_hidden() ? 0 : 1 }

sub symbols { return $_[0]; }
sub symbol_lists { return $_[0]; }

package Marpa::R2::Inner::Scanless::Symbol_List;

sub new { my $class = shift; return bless { symbol_lists => [@_] }, $class }

sub is_symbol { return 0 };

sub names {
    return map { $_->names() } @{ shift->{symbol_lists} };
}

sub are_all_hidden {
     $_->is_hidden() || return 0 for @{ shift->{symbol_lists } };
     return 1;
}

sub is_hidden {
    return map { $_->is_hidden() } @{ shift->{symbol_lists } };
}

sub hidden_set {
    $_->hidden_set() for @{ shift->{symbol_lists} };
    return 0;
}

sub is_lexical { return shift->{is_lexical} // 0 }
sub lexical_set { return shift->{is_lexical} = 1; }

sub mask {
    return
        map { $_ ? 0 : 1 } map { $_->is_hidden() } @{ shift->{symbol_lists} };
}

sub symbols {
    return map { $_->symbols() } @{ shift->{symbol_lists} };
}

# The "unflattened" list, which may contain other lists
sub symbol_lists { return @{ shift->{symbol_lists} }; }

package Marpa::R2::Inner::Scanless;

use English qw( -no_match_vars );

sub do_rules {
    shift;
    return [ map { @{$_} } @_ ];
}

sub do_start_rule {
    my ( $self, $rhs ) = @_;
    my @ws                = ();
    my $normalized_rhs    = $self->rhs_normalize($rhs);
    return [
        {   lhs    => '[:start]',
            rhs    => [ $normalized_rhs->names() ],
            action => '::first'
        }
    ];
} ## end sub do_start_rule

sub do_discard_rule {
    my ( $self, $rhs ) = @_;
    local $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL = 0;
    my $normalized_rhs = $self->rhs_normalize($rhs);
    push @{$self->{lex_rules}}, { lhs => '[:discard]', rhs => [$normalized_rhs->name()] };
    return [];
} ## end sub do_discard_rule

# "Normalize" a symbol list, creating subrules as needed
# for lexicalization.
sub rhs_normalize {
    my ( $self, $symbols ) = @_;
    return $symbols if $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0;
    if ( $symbols->is_lexical() ) {
        my $is_hidden         = $symbols->are_all_hidden();
        my $lexical_lhs_index = $self->{lexical_lhs_index}++;
        my $lexical_lhs       = "[Lex-$lexical_lhs_index]";
        my %lexical_rule      = (
            lhs  => $lexical_lhs,
            rhs  => [ $symbols->names() ],
            mask => [ $symbols->mask() ],
        );
        push @{ $self->{lex_rules} }, \%lexical_rule;
        my $g1_symbol = Marpa::R2::Inner::Scanless::Symbol->new($lexical_lhs);
        $g1_symbol->hidden_set() if $is_hidden;
        return $g1_symbol;
    } ## end if ( $symbols->is_lexical() )
    # If non-lexical single symbol, just return it
    return $symbols if $symbols->is_symbol();
    my @symbols;
    CONTAINER: for my $symbol_container ($symbols->symbol_lists()) {
         push @symbols, $self->rhs_normalize($symbol_container)->symbols();
    }
    return Marpa::R2::Inner::Scanless::Symbol_List->new(@symbols);
} ## end sub rhs_normalize

sub bless_hash_rule {
    my ( $self, $hash_rule, $blessing ) = @_;
    my $grammar_level = $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL;
    return if $grammar_level == 0;
    $blessing //= $self->{default_adverbs}->[$grammar_level]->{bless};
    return if not defined $blessing;
    FIND_BLESSING: {
        last FIND_BLESSING if $blessing =~ /\A [\w] /xms;
        return if $blessing eq '::undef';
        my $lhs = $hash_rule->{lhs};
        my @rhs = $hash_rule->{rhs};
        if ( $blessing eq '::lhs' ) {
            $blessing = $lhs;
            if ( $blessing =~ / [^ [:alnum:]] /xms ) {
                Marpa::R2::exception(
                    qq{"::lhs" blessing only allowed if LHS is whitespace and alphanumerics\n},
                    qq{   LHS was <$lhs>\n},
                    qq{   Rule was <$lhs> ::= },
                    join q{ },
                    map { '<' . $_ . '>' } @rhs
                );
            } ## end if ( $blessing =~ / [^ [:alnum:]] /xms )
            $blessing =~ s/[ ]/_/gxms;
            last FIND_BLESSING;
        } ## end if ( $blessing eq '::lhs' )
        Marpa::R2::exception(
            qq{Unknown blessing "$blessing"\n},
            qq{   Rule was <$lhs> ::= },
            join q{ }, map { '<' . $_ . '>' } @rhs
        );
    } ## end FIND_BLESSING:
    $hash_rule->{bless} = $blessing;
    return 1;
} ## end sub bless_hash_rule

sub do_priority_rule {
    my ( $self, $lhs, $op_declare, $priorities ) = @_;
    my $priority_count = scalar @{$priorities};
    my @working_rules          = ();

    my @xs_rules = ();
    my $rules = $op_declare eq q{::=} ? \@xs_rules : $self->{lex_rules};
    local $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL = 0 if not $op_declare eq q{::=};
    my $grammar_level = $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL;

    my $default_adverbs = $self->{default_adverbs}->[$grammar_level];

    if ( $priority_count <= 1 ) {
        ## If there is only one priority
        for my $alternative ( @{ $priorities->[0] } ) {
            my ( $rhs, $adverb_list ) = @{$alternative};
            $rhs = $self->rhs_normalize($rhs);
            my @rhs_names = $rhs->names();
            my @mask      = $rhs->mask();
            if ( $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0 and grep { !$_ } @mask ) {
                Marpa::R2::exception(
                    'hidden symbols are not allowed in lexical rules (rules LHS was "',
                    $lhs->name(), '")'
                );
            } ## end if ( $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0 and grep { !$_ } @mask )
            my %hash_rule =
                ( lhs => $lhs, rhs => \@rhs_names, mask => \@mask );

            my $action = $adverb_list->{action} // $default_adverbs->{action};
            if ( defined $action ) {
                Marpa::R2::exception(
                    'actions not allowed in lexical rules (rules LHS was "',
                    $lhs, '")' )
                    if $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0;
                $hash_rule{action} = $action;
            } ## end if ( defined $action )

            my $blessing = $adverb_list->{bless};
            if ( defined $blessing
                and $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0 )
            {
                Marpa::R2::exception(
                    'bless option not allowed in lexical rules (rules LHS was "',
                    $lhs, '")'
                );
            } ## end if ( defined $blessing and ...)
            $self->bless_hash_rule( \%hash_rule, $blessing );

            push @{$rules}, \%hash_rule;
        } ## end for my $alternative ( @{ $priorities->[0] } )
        return [@xs_rules];
    } ## end if ( $priority_count <= 1 )

    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        for my $alternative ( @{ $priorities->[$priority_ix] } ) {
            push @working_rules, [ $priority, @{$alternative} ];
        }
    } ## end for my $priority_ix ( 0 .. $priority_count - 1 )

    # Default mask (all ones) is OK for this rule
    my @arg0_action = ();
    @arg0_action = ( action => '::first') if $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL > 0;
    @xs_rules = (
        {   lhs    => $lhs,
            rhs    => [ $lhs . '[prec0]' ],
            @arg0_action
        },
        (   map {
                ;
                {   lhs => ( $lhs . '[prec' . ( $_ - 1 ) . ']'),
                    rhs => [ $lhs . '[prec' . $_ . ']'],
                    @arg0_action
                }
            } 1 .. $priority_count - 1
        )
    );
    RULE: for my $working_rule (@working_rules) {
        my ( $priority, $rhs, $adverb_list ) = @{$working_rule};
        $rhs = $self->rhs_normalize($rhs);
        my $assoc   = $adverb_list->{assoc} // 'L';
        my @new_rhs = $rhs->names();
        my @arity   = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $length  = scalar @new_rhs;

        my $current_exp = $lhs . '[prec' . $priority . ']';
        my @mask        = $rhs->mask();
        if ( $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0 and grep { !$_ } @mask ) {
            Marpa::R2::exception(
                'hidden symbols are not allowed in lexical rules (rules LHS was "',
                $lhs, '")'
            );
        } ## end if ( $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0 and grep { !$_ } @mask )
        my %new_xs_rule = ( lhs => $current_exp );
        $new_xs_rule{mask} = \@mask;

        my $action = $adverb_list->{action} // $default_adverbs->{action};
        if ( defined $action ) {
            Marpa::R2::exception(
                'actions not allowed in lexical rules (rules LHS was "',
                $lhs, '")' )
                if $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0;
            $new_xs_rule{action} = $action;
        } ## end if ( defined $action )

        my $blessing = $adverb_list->{bless};
        if ( defined $blessing
            and $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0 )
        {
            Marpa::R2::exception(
                'bless option not allowed in lexical rules (rules LHS was "',
                $lhs,
                '")'
            );
        } ## end if ( defined $blessing and ...)
        $self->bless_hash_rule( \%new_xs_rule, $blessing );

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
    return [@xs_rules];
} ## end sub do_priority_rule

sub do_empty_rule {
    my ( $self, $lhs, $op_declare, $adverb_list ) = @_;
    my %rule = ( lhs => $lhs, rhs => [] );

    local $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL = 0 if not $op_declare eq q{::=};
    my $grammar_level = $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL;

    my $default_adverbs = $self->{default_adverbs}->[$grammar_level];

    my $action = $adverb_list->{action} // $default_adverbs->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0;
        $rule{action} = $action;
    } ## end if ( defined $action )


    my $blessing = $adverb_list->{bless};
    if ( defined $blessing
            and $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0 ) {
        Marpa::R2::exception(
            'bless option not allowed in lexical rules (rules LHS was "',
            $lhs,
            '")'
        );
    } ## end if ( defined $blessing )
    $self->bless_hash_rule(\%rule, $blessing);

    # mask not needed
    if ( $op_declare eq q{::=} ) {
        return \%rule;
    }
    push @{ $self->{lex_rules} }, \%rule;
    return [];
} ## end sub do_empty_rule

sub do_bless_lexemes {
    my ( $self ) = @_;
    $self->{bless_lexemes} = 1;
    return [];
}

sub do_default_rule {
    my ( $self, $lhs, $op_declare, $adverb_list ) = @_;
    my $grammar_level = $op_declare eq q{::=} ? 1 : 0;
    $self->{default_adverbs}->[$grammar_level] = {};
    ADVERB: for my $key ( keys %{$adverb_list} ) {
        my $value = $adverb_list->{$key};
        if ( $key eq 'action' ) {
            $self->{default_adverbs}->[$grammar_level]->{$key} = $value;
            next ADVERB;
        }
        if ( $key eq 'bless' ) {
            $self->{default_adverbs}->[$grammar_level]->{$key} = $value;
            next ADVERB;
        }
        Marpa::R2::exception(qq{"$key" adverb not allowed in default rule"});
    } ## end ADVERB: for my $key ( keys %{$adverb_list} )
    return [];
} ## end sub do_default_rule

## no critic(Subroutines::ProhibitManyArgs)
sub do_quantified_rule {
    my ( $self, $lhs, $op_declare, $rhs, $quantifier, $adverb_list ) = @_;

    local $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL = 0 if not $op_declare eq q{::=};
    my $grammar_level = $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL;
    my $default_adverbs = $self->{default_adverbs}->[$grammar_level];

    # Some properties of the sequence rule will not be altered
    # no matter how complicated this gets
    my %sequence_rule = (
        rhs => [ $rhs->name() ],
        min => ( $quantifier eq q{+} ? 1 : 0 )
    );

    my @rules = ( \%sequence_rule );

    my $original_separator = $adverb_list->{separator};

    # mask not needed
    $sequence_rule{lhs}       = $lhs;
    $sequence_rule{separator} = $original_separator
        if defined $original_separator;
    my $proper = $adverb_list->{proper};
    $sequence_rule{proper} = $proper if defined $proper;

    my $action = $adverb_list->{action} // $default_adverbs->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0;
        $sequence_rule{action} = $action;
    } ## end if ( defined $action )

    my $blessing = $adverb_list->{bless};
    if ( defined $blessing
            and $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL <= 0 ) {
        Marpa::R2::exception(
            'bless option not allowed in lexical rules (rules LHS was "',
            $lhs,
            '")'
        );
    } ## end if ( defined $blessing )
    $self->bless_hash_rule(\%sequence_rule, $blessing);

    if ($op_declare eq q{::=}) {
        return \@rules;
    } else {
       push @{$self->{lex_rules}}, @rules;
       return [];
    }

} ## end sub do_quantified_rule
## use critic

sub create_internal_symbol {
    my ($self, $symbol_name) = @_;
    $self->{needs_symbol}->{$symbol_name} = 1;
    my $symbol = Marpa::R2::Inner::Scanless::Symbol->new($symbol_name);
    return $symbol;
}

# Return the character class symbol name,
# after ensuring everything is set up properly
sub assign_symbol_by_char_class {
    my ( $self, $char_class, $symbol_name ) = @_;

    # default symbol name always start with TWO left square brackets
    $symbol_name //= '[' . $char_class . ']';
    $self->{character_classes} //= {};
    my $cc_hash    = $self->{character_classes};
    my (undef, $symbol) = $cc_hash->{$symbol_name};
    if ( not defined $symbol ) {
        my $regex;
        if ( not defined eval { $regex = qr/$char_class/xms; 1; } ) {
            Carp::croak( 'Bad Character class: ',
                $char_class, "\n", 'Perl said ', $EVAL_ERROR );
        }
        $symbol = create_internal_symbol($self, $symbol_name);
        $cc_hash->{$symbol_name} = [ $regex, $symbol ];
    } ## end if ( not defined $hash_entry )
    return $symbol;
} ## end sub assign_symbol_by_char_class

sub do_any {
    my $self = shift;
    my $symbol_name = '[:any]';
    return assign_symbol_by_char_class( $self, '[\p{Cn}\P{Cn}]', $symbol_name );
}

sub do_ws { return create_internal_symbol($_[0], '[:ws]') }
sub do_ws_star { return create_internal_symbol($_[0], '[:ws*]') }
sub do_ws_plus { return create_internal_symbol($_[0], '[:ws+]') }

sub do_symbol {
    shift;
    return Marpa::R2::Inner::Scanless::Symbol->new( $_[0] );
}

sub do_character_class {
    my ( $self, $char_class ) = @_;
    my $symbol = assign_symbol_by_char_class($self, $char_class);
    $symbol->lexical_set();
    return $symbol;
} ## end sub do_character_class

sub do_rhs_primary_list { shift; return Marpa::R2::Inner::Scanless::Symbol_List->new(@_) }
sub do_lhs { shift; return $_[0]; }
sub do_rhs {
    shift;
    return Marpa::R2::Inner::Scanless::Symbol_List->new( @_ );
}
sub do_adverb_list { shift; return { map {; @{$_}} @_ } }

sub do_parenthesized_rhs_primary_list {
    my (undef, $list) = @_;
    $list->hidden_set();
    return $list;
} ## end sub do_parenthesized_rhs_primary_list

sub do_separator_specification {
    my (undef, $separator) = @_;
    return [ separator => $separator->name() ];
}

sub do_single_quoted_string {
    my ($self, $string ) = @_;
    my @symbols = ();
    my $symbol;
    for my $char_class ( map { '[' . (quotemeta $_) . ']' } split //xms, substr $string, 1, -1) {
        $symbol = assign_symbol_by_char_class($self, $char_class);
        push @symbols, $symbol;
    }
    my $list = Marpa::R2::Inner::Scanless::Symbol_List->new(@symbols);
    $list->lexical_set();
    return $list;
}

sub do_op_declare_bnf     { return q{::=} }
sub do_op_declare_match   { return q{~} }
sub do_op_star_quantifier { return q{*} }
sub do_op_plus_quantifier { return q{+} }

my %hashed_closures = (
    do_adverb_list               => \&do_adverb_list,
    do_any                       => \&do_any,
    do_character_class           => \&do_character_class,
    do_discard_rule              => \&do_discard_rule,
    do_empty_rule                => \&do_empty_rule,
    do_default_rule                => \&do_default_rule,
    do_bless_lexemes                => \&do_bless_lexemes,
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

# Given a scanless
# recognizer and a symbol,
# return the start and end earley sets
# of the last such symbol completed,
# undef if there was none.
sub Marpa::R2::Scanless::R::last_completed_range {
    my ( $self, $symbol_name ) = @_;
    my $grammar = $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thick_g1_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce   = $thick_g1_recce->thin();
    my $g1_tracer       = $thick_g1_grammar->tracer();
    my $thin_g1_grammar = $thick_g1_grammar->thin();
    my $symbol_id       = $g1_tracer->symbol_by_name($symbol_name);
    Marpa::R2::exception("Bad symbol in last_completed_range(): $symbol_name")
        if not defined $symbol_id;
    my @sought_rules =
        grep { $thin_g1_grammar->rule_lhs($_) == $symbol_id; }
        0 .. $thin_g1_grammar->highest_rule_id();
    die "Looking for completion of non-existent rule lhs: $symbol_name"
        if not scalar @sought_rules;
    my $latest_earley_set = $thin_g1_recce->latest_earley_set();
    my $earley_set        = $latest_earley_set;

    # Initialize to one past the end, so we can tell if there were no hits
    my $first_origin = $latest_earley_set + 1;
    EARLEY_SET: while ( $earley_set >= 0 ) {
        $thin_g1_recce->progress_report_start($earley_set);
        ITEM: while (1) {
            my ( $rule_id, $dot_position, $origin ) =
                $thin_g1_recce->progress_item();
            last ITEM if not defined $rule_id;
            next ITEM if $dot_position != -1;
            next ITEM if not scalar grep { $_ == $rule_id } @sought_rules;
            next ITEM if $origin >= $first_origin;
            $first_origin = $origin;
        } ## end ITEM: while (1)
        $thin_g1_recce->progress_report_finish();
        last EARLEY_SET if $first_origin <= $latest_earley_set;
        $earley_set--;
    } ## end EARLEY_SET: while ( $earley_set >= 0 )
    return if $earley_set < 0;
    return ( $first_origin, $earley_set );
} ## end sub Marpa::R2::Scanless::R::last_completed_range

# Given a scanless recognizer and
# and two earley sets, return the input string
sub Marpa::R2::Scanless::R::range_to_string {
    my ( $self, $start_earley_set, $end_earley_set ) = @_;
    return if not defined $start_earley_set;
    my $thin_self  = $self->[Marpa::R2::Inner::Scanless::R::C];
    my ($start_position) = $thin_self->locations($start_earley_set+1);
    my (undef, $end_position) = $thin_self->locations($end_earley_set);
    my $p_input   = $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];
    return substr ${$p_input}, $start_position,
        ( $end_position - $start_position );
} ## end sub Marpa::R2::Scanless::R::range_to_string

sub Marpa::R2::Internal::Scanless::meta_grammar {

    my $self = bless [], 'Marpa::R2::Scanless::G';
    $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] = \*STDERR;
    $self->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE] = 'Marpa::R2::Internal::MetaG_Nodes';
    state $hashed_metag = Marpa::R2::Internal::MetaG::hashed_grammar();
    $self->_hash_to_runtime($hashed_metag);

    my $thick_g1_grammar = $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my @mask_by_rule_id;
    $mask_by_rule_id[$_] = $thick_g1_grammar->_rule_mask($_) for $thick_g1_grammar->rule_ids();
    $self->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID] = \@mask_by_rule_id;

    return $self;

} ## end sub meta_grammar

sub Marpa::R2::Internal::Scanless::meta_recce {
    my ($hash_args) = @_;
    state $meta_grammar = Marpa::R2::Internal::Scanless::meta_grammar();
    $hash_args->{grammar} = $meta_grammar;
    my $self = Marpa::R2::Scanless::R->new($hash_args);
    return $self;
} ## end sub Marpa::R2::Internal::Scanless::meta_recce

sub Marpa::R2::Scanless::R::last_rule {
   my ($meta_recce) = @_;
   my ($start, $end) = $meta_recce->last_completed_range( 'rule' );
   return 'No rule was completed' if not defined $start;
   return $meta_recce->range_to_string( $start, $end);
}

sub Marpa::R2::Scanless::G::new {
    my ( $class, $args ) = @_;

    my $self = [];
    bless $self, $class;

    $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] = *STDERR;

    my $ref_type = ref $args;
    if ( not $ref_type ) {
        Carp::croak(
            "$G_PACKAGE expects args as ref to HASH; arg was non-reference");
    }
    if ( $ref_type ne 'HASH' ) {
        Carp::croak(
            "$G_PACKAGE expects args as ref to HASH, got ref to $ref_type instead"
        );
    }

    # Other possible grammar options:
    # actions
    # default_empty_action
    # default_rank
    # inaccessible_ok
    # symbols
    # terminals
    # unproductive_ok
    # warnings

state $grammar_options = { map { ($_, 1) } qw(
    action_object
    bless_package
    default_action
    source
    trace_file_handle
) };

    if (my @bad_options =
        grep { not defined $grammar_options->{$_} } keys %{$args}
        )
    {
        Carp::croak(
            "$G_PACKAGE does not know some of option(s) given to it:\n",
            '   The option(s) not recognized were ',
            ( join q{ }, map { q{"} . $_ . q{"} } @bad_options ),
            "\n"
        );
    } ## end if ( my @bad_options = grep { not defined $grammar_options...})

    if ( defined( my $value = $args->{'trace_file_handle'} ) ) {
        $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] = $value;
    }

    if ( defined( my $value = $args->{'action_object'} ) ) {
        $self->[Marpa::R2::Inner::Scanless::G::ACTION_OBJECT] = $value;
    }

    if ( defined( my $value = $args->{'bless_package'} ) ) {
        $self->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE] = $value;
    }

    if ( defined( my $value = $args->{'default_action'} ) ) {
        $self->[Marpa::R2::Inner::Scanless::G::DEFAULT_ACTION] = $value;
    }

    my $rules_source = $args->{'source'};
    if ( not defined $rules_source ) {
        Marpa::R2::exception(
            'Marpa::R2::Scanless::G::new() called without a "source" argument'
        );
    }

    $ref_type = ref $rules_source;
    if ( $ref_type ne 'SCALAR' ) {
        Marpa::R2::exception(
            qq{Marpa::R2::Scanless::G::new() type of "source" argument is "$ref_type"},
            "  It must be a ref to a string\n"
        );
    } ## end if ( $ref_type ne 'SCALAR' )
    my $hashed_source = $self->_source_to_hash( $rules_source );
    $self->_hash_to_runtime($hashed_source);

    return $self;

}

sub Marpa::R2::Scanless::G::_hash_to_runtime {
    my ( $self, $hashed_source ) = @_;

    my %lex_args = ();
    $lex_args{trace_file_handle} =
        $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] // \*STDERR;
    $lex_args{rules} = $hashed_source->{lex_rules};
    state $lex_target_symbol = '[:start_lex]';
    $lex_args{start} = $lex_target_symbol;
    $lex_args{'_internal_'} = 1;
    my $lex_grammar = Marpa::R2::Grammar->new( \%lex_args );
    $lex_grammar->precompute();
    my $lex_tracer      = $lex_grammar->tracer();
    my $g0_thin         = $lex_tracer->grammar();
    my @g0_lexeme_names = keys %{ $hashed_source->{is_lexeme} };
    $self->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR] = $lex_grammar;
    my $character_class_hash = $hashed_source->{character_classes};
    my @class_table          = ();

    for my $class_symbol ( sort keys %{$character_class_hash} ) {
        push @class_table,
            [
            $lex_tracer->symbol_by_name($class_symbol),
            $character_class_hash->{$class_symbol}
            ];
    } ## end for my $class_symbol ( sort keys %{$character_class_hash...})
    $self->[Marpa::R2::Inner::Scanless::G::CHARACTER_CLASS_TABLE] =
        \@class_table;

    # The G1 grammar
    my %g1_args = ();
    $g1_args{trace_file_handle} =
        $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] // \*STDERR;
    $g1_args{action_object} =
        $self->[Marpa::R2::Inner::Scanless::G::ACTION_OBJECT];
    $g1_args{bless_package} =
        $self->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE];
    $g1_args{default_action} =
        $self->[Marpa::R2::Inner::Scanless::G::DEFAULT_ACTION];
    $g1_args{rules}   = $hashed_source->{g1_rules};
    $g1_args{symbols} = $hashed_source->{g1_symbols};
    state $g1_target_symbol = '[:start]';
    $g1_args{start} = $g1_target_symbol;
    $g1_args{'_internal_'} = 1;
    my $thick_g1_grammar = Marpa::R2::Grammar->new( \%g1_args );
    $thick_g1_grammar->precompute();
    my $g1_tracer = $thick_g1_grammar->tracer();
    my $g1_thin   = $g1_tracer->grammar();
    my @g0_lexeme_to_g1_symbol;
    my @g1_symbol_to_g0_lexeme;
    $g0_lexeme_to_g1_symbol[$_] = -1 for 0 .. $g1_thin->highest_symbol_id();
    state $discard_symbol_name = '[:discard]';
    my $g0_discard_symbol_id =
        $self->[Marpa::R2::Inner::Scanless::G::G0_DISCARD_SYMBOL_ID] =
        $lex_tracer->symbol_by_name($discard_symbol_name) // -1;

    LEXEME_NAME: for my $lexeme_name (@g0_lexeme_names) {
        next LEXEME_NAME if $lexeme_name eq $discard_symbol_name;
        my $g1_symbol_id = $g1_tracer->symbol_by_name($lexeme_name);
        if ( not defined $g1_symbol_id ) {
            Marpa::R2::exception(
                'A lexeme is not accessible from the start symbol: ',
                $lexeme_name );
        }
        my $lex_symbol_id = $lex_tracer->symbol_by_name($lexeme_name);
        $g0_lexeme_to_g1_symbol[$lex_symbol_id] = $g1_symbol_id;
        $g1_symbol_to_g0_lexeme[$g1_symbol_id]  = $lex_symbol_id;
    } ## end LEXEME_NAME: for my $lexeme_name (@g0_lexeme_names)

    SYMBOL_ID: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id() ) {
        if ( $g1_thin->symbol_is_terminal($symbol_id)
            and not defined $g1_symbol_to_g0_lexeme[$symbol_id] )
        {
            my $symbol_name = $g1_tracer->symbol_name($symbol_id);
            if ( $lex_tracer->symbol_by_name($symbol_name) ) {
                Marpa::R2::exception(
                    "Symbol <$symbol_name> is a lexeme in G1, but not in G0.\n",
                    "  This may be because <$symbol_name> was used on a RHS in G0.\n",
                    "  A lexeme cannot be used on the RHS of a G0 rule.\n"
                );
            } ## end if ( $lex_tracer->symbol_by_name($symbol_name) )
            Marpa::R2::exception( 'Unproductive symbol: ',
                $g1_tracer->symbol_name($symbol_id) );
        } ## end if ( $g1_thin->symbol_is_terminal($symbol_id) and not...)
    } ## end SYMBOL_ID: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id(...))

    my $thin_slg = $self->[Marpa::R2::Inner::Scanless::G::C] =
        Marpa::R2::Thin::SLG->new( $lex_tracer->grammar(),
        $g1_tracer->grammar() );

    my @g0_rule_to_g1_lexeme;
    RULE_ID: for my $rule_id ( 0 .. $g0_thin->highest_rule_id() ) {
        my $lhs_id = $g0_thin->rule_lhs($rule_id);
        my $lexeme_id =
            $lhs_id == $g0_discard_symbol_id
            ? -2
            : ( $g0_lexeme_to_g1_symbol[$lhs_id] // -1 );
        $g0_rule_to_g1_lexeme[$rule_id] = $lexeme_id;
        $thin_slg->g0_rule_to_g1_lexeme_set( $rule_id, $lexeme_id );
    } ## end RULE_ID: for my $rule_id ( 0 .. $g0_thin->highest_rule_id() )

    $self->[Marpa::R2::Inner::Scanless::G::G0_RULE_TO_G1_LEXEME] =
        \@g0_rule_to_g1_lexeme;
    $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR] =
        $thick_g1_grammar;

    return 1;

} ## end sub Marpa::R2::Scanless::G::_hash_to_runtime

sub Marpa::R2::Scanless::G::show_rules {
    my ( $self ) = @_;
    my $thick_lex_grammar = $self->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $text = "Lex (G0) Rules:\n";
    $text .= $thick_lex_grammar->show_rules();
    my $thick_g1_grammar = $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    $text .= "G1 Rules:\n";
    $text .= $thick_g1_grammar->show_rules();
    return $text;
}

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
    'default rule'                     => 'do_default_rule',
    'bless lexemes statement'                     => 'do_bless_lexemes',
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

sub Marpa::R2::Scanless::G::_source_to_hash {
    my ( $self, $p_rules_source ) = @_;

    local $Marpa::R2::Inner::Scanless::GRAMMAR_LEVEL = 1;
    my $inner_self = bless {
        self              => $self,
        lex_rules         => [],
        lexical_lhs_index => 0,
        },
        __PACKAGE__;

    $inner_self->{default_adverbs}->[$_] = {} for 0, 1;

    # Track earley set positions in input,
    # for debuggging
    my @positions = (0);

    my $meta_recce   = Marpa::R2::Internal::Scanless::meta_recce();
    my $meta_grammar = $meta_recce->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    state $mask_by_rule_id =
        $meta_grammar->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID];
    my $thin_meta_recce = $meta_recce->[Marpa::R2::Inner::Scanless::R::C];
    $meta_recce->read($p_rules_source);
    my $thick_meta_g1_grammar =
        $meta_grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $meta_g1_tracer       = $thick_meta_g1_grammar->tracer();
    my $thin_meta_g1_grammar = $thick_meta_g1_grammar->thin();
    my $thick_meta_g1_recce =
        $meta_recce->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_meta_g1_recce = $thick_meta_g1_recce->thin();
    my $thick_g1_recce =
        $meta_recce->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];

    $thin_meta_g1_grammar->throw_set(0);
    my $latest_earley_set_id = $thin_meta_g1_recce->latest_earley_set();
    my $bocage =
        Marpa::R2::Thin::B->new( $thin_meta_g1_recce, $latest_earley_set_id );
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

    my $meta_g1_rules =
        $thick_meta_g1_grammar->[Marpa::R2::Internal::Grammar::RULES];
    RULE:
    for my $rule_id ( grep { $thin_meta_g1_grammar->rule_length($_); }
        0 .. $thin_meta_g1_grammar->highest_rule_id() )
    {
        $valuator->rule_is_valued_set( $rule_id, 1 );
        my ( $lhs, @rhs ) =
            map { Marpa::R2::Grammar::original_symbol_name($_) }
            $meta_g1_tracer->rule($rule_id);
        if ( scalar @rhs == 1 ) {

            # These actions are by rhs symbol, for rules
            # with only one RHS symbol
            my $action = $actions_by_rhs_symbol{ $rhs[0] };
            if ( defined $action ) {
                $actions_by_rule_id[$rule_id] = $action;
                next RULE;
            }
        } ## end if ( scalar @rhs == 1 )
        my $action = $actions_by_lhs_symbol{$lhs};
        if ( defined $action ) {
            $actions_by_rule_id[$rule_id] = $action;
            next RULE;
        }
        my $rule = $meta_g1_rules->[$rule_id];
        $action = $rule->[Marpa::R2::Internal::Rule::ACTION_NAME];
        $action = undef if $action eq '::dwim';    # temporary hack
        next RULE if not defined $action;
        $actions_by_rule_id[$rule_id] = $action;
    } ## end for my $rule_id ( grep { $thin_meta_g1_grammar->rule_length...})

    my $p_input =
        $meta_recce->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];

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
            } ## end if ( $action eq 'do_bracketed_name' )
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
                    push @ws_rules, { lhs => '[:ws]', rhs => ['[:ws+]'], };
                    $needed{'[:ws+]'} = 1;
                    next SYMBOL;
                }
                if ( $needed_symbol eq '[:Space]' ) {
                    my $true_ws = assign_symbol_by_char_class( $inner_self,
                        '[\p{White_Space}]' );
                    push @ws_rules,
                        {
                        lhs => '[:Space]',
                        rhs => [ $true_ws->name() ],
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
    for my $lex_rule ( @{$lex_rules} ) {
        $lex_lhs{ $lex_rule->{lhs} } = 1;
        $lex_rhs{$_} = 1 for @{ $lex_rule->{rhs} };
    }

    my $bless_lexemes = $inner_self->{bless_lexemes};
    my $g1_symbols    = {};
    my %is_lexeme =
        map { ( $_, 1 ); } grep { not $lex_rhs{$_} } keys %lex_lhs;
    if ($bless_lexemes) {
        LEXEME: for my $lexeme ( keys %is_lexeme ) {
            next LEXEME if $lexeme =~ m/ \] \z/xms;
            if ( $lexeme =~ / [^ [:alnum:]] /xms ) {
                Marpa::R2::exception(
                    qq{Lexeme blessing only allowed if lexeme name is whitespace and alphanumerics\n},
                    qq{   Problematic lexeme was <$lexeme>\n}
                );
            } ## end if ( $lexeme =~ / [^ [:alnum:]] /xms )
            my $blessing = $lexeme;
            $blessing =~ s/[ ]/_/gxms;
            $g1_symbols->{$lexeme}->{bless} = $blessing;
        } ## end LEXEME: for my $lexeme ( keys %is_lexeme )
    } ## end if ($bless_lexemes)
    $inner_self->{is_lexeme}  = \%is_lexeme;
    $inner_self->{g1_symbols} = $g1_symbols;

    my @unproductive =
        grep { not $lex_lhs{$_} and not $_ =~ /\A \[\[ /xms } keys %lex_rhs;
    if (@unproductive) {
        Marpa::R2::exception( 'Unproductive lexical symbols: ',
            join q{ }, @unproductive );
    }
    push @{ $inner_self->{lex_rules} },
        map { ; { lhs => '[:start_lex]', rhs => [$_] } } sort keys %is_lexeme;

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
} ## end sub Marpa::R2::Scanless::G::_source_to_hash

my %recce_options = map { ($_, 1) } qw{
    grammar
    trace_terminals
    trace_values
    trace_file_handle
};

sub Marpa::R2::Scanless::R::new {
    my ( $class, $args ) = @_;

    my $self = [];
    bless $self, $class;

    state $grammar_class = 'Marpa::R2::Scanless::G';
    my $grammar = $args->{grammar};
    if ( not blessed $grammar or not $grammar->isa('Marpa::R2::Scanless::G') )
    {
        my $desc = 'undefined';
        if ( defined $grammar ) {
            my $ref_type = ref $grammar;
            $desc = $ref_type ? "a ref to $ref_type" : 'not a ref';
        }
        Marpa::R2::exception(
            qq{'grammar' name argument to scanless_r->new() is $desc\n},
            "  It should be a ref to $grammar_class\n" );
        Marpa::R2::exception(
            'Marpa::R2::Scanless::R::new() called without a "grammar" argument'
        );
    } ## end if ( not blessed $grammar or not $grammar->isa(...))

    $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR] = $grammar;
    $self->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE] =
        $grammar->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE];

    if (my @bad_options =
        grep { not defined $recce_options{$_} } keys %{$args}
        )
    {
        Marpa::R2::exception(
            "$G_PACKAGE does not know some of option(s) given to it:\n",
            '   The option(s) not recognized were ',
            ( join q{ }, map { q{"} . $_ . q{"} } @bad_options ),
            "\n"
        );
    } ## end if ( my @bad_options = grep { not defined $recce_options...})

    if ( defined( my $value = $args->{'trace_file_handle'} ) ) {
        $self->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE] = $value;
    }
    if ( defined( my $value = $args->{'trace_terminals'} ) ) {
        $self->[Marpa::R2::Inner::Scanless::R::TRACE_TERMINALS] = $value;
    }

    $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR] = $grammar;
    my $thick_lex_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $lex_tracer       = $thick_lex_grammar->tracer();
    my $thin_lex_grammar = $lex_tracer->grammar();

    my $thick_g1_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my %g1_recce_args = ( grammar => $thick_g1_grammar );
    $g1_recce_args{$_} = $args->{$_}
        for qw( trace_values trace_file_handle );
    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE] =
        Marpa::R2::Recognizer->new( \%g1_recce_args );

    $thick_g1_recce->semantics_set();

    $self->[Marpa::R2::Inner::Scanless::R::C] = Marpa::R2::Thin::SLR->new(
        $grammar->[Marpa::R2::Inner::Scanless::G::C],
        $thick_g1_recce->thin() );

    return $self;
} ## end sub Marpa::R2::Scanless::R::new

sub Marpa::R2::Scanless::R::trace {
    my ($self, $level) = @_;
    $level //= 1;
    my $stream = $self->stream();
    return $stream->trace($level);
}

sub Marpa::R2::Scanless::R::error {
    my ($self) = @_;
    return $self->[Marpa::R2::Inner::Scanless::R::READ_STRING_ERROR];
}

sub Marpa::R2::Scanless::R::read {
    my ( $self, $p_string ) = @_;

    Marpa::R2::exception(
        "Multiple read()'s tried on a scannerless recognizer\n",
        '  Currently only a single scannerless read is allowed'
    ) if defined $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];

    if ( ( my $ref_type = ref $p_string ) ne 'SCALAR' ) {
        my $desc = $ref_type ? "a ref to $ref_type" : 'not a ref';
        Marpa::R2::exception(
            qq{Arg to scanless_r->read() is $desc\n"},
            '  It should be a ref to scalar'
        );
    } ## end if ( ( my $ref_type = ref $p_string ) ne 'SCALAR' )
    $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING] = $p_string;

    my $trace_terminals =
        $self->[Marpa::R2::Inner::Scanless::R::TRACE_TERMINALS];

    my $thin_self = $self->[Marpa::R2::Inner::Scanless::R::C];
    $thin_self->trace_terminals($trace_terminals) if $trace_terminals;
    my $stream  = $thin_self->stream();
    my $grammar = $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thick_lex_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $lex_tracer = $thick_lex_grammar->tracer();

    # Defaults to non-existent symbol
    my $g0_discard_symbol_id =
        $grammar->[Marpa::R2::Inner::Scanless::G::G0_DISCARD_SYMBOL_ID] // -1;

    my $g0_rule_to_g1_lexeme =
        $grammar->[Marpa::R2::Inner::Scanless::G::G0_RULE_TO_G1_LEXEME];
    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce    = $thick_g1_recce->thin();
    my $thick_g1_grammar = $thick_g1_recce->grammar();
    my $g1_tracer        = $thick_g1_grammar->tracer();

    my $class_table =
        $grammar->[Marpa::R2::Inner::Scanless::G::CHARACTER_CLASS_TABLE];

    my $length_of_string = length ${$p_string};
    $stream->string_set($p_string);
    OUTER_READ: while (1) {

        # These values are used for diagnostics,
        # so they are initialized here.
        # Event counts are initialized to 0 for "no events, no problems".

        # Problem codes:
        # -2 means unregistered character -- recoverable
        # -3 means parse exhausted in lexer
        # -4 means parse exhausted, but lexemes remain
        # -5 means no lexeme recognized at a position
        # -6 means trace -- recoverable
        # -7 means a lex read problem not in another category
        # -8 means an G1 earleme complete problem

        my $problem_code    = $thin_self->read();

        last OUTER_READ if not $problem_code;

        if ( $problem_code eq 'trace' ) {
            while ( my $event = $thin_self->event() ) {
                my ( $status, $lexeme_start_pos, $lexeme_end_pos, $g1_lexeme )
                    = @{$event};
                my $raw_token_value = substr ${$p_string},
                    $lexeme_start_pos,
                    $lexeme_end_pos - $lexeme_start_pos;
                my $status_desc =
                    $status eq 'accepted'
                    ? 'Found'
                    : "Rejected $status";
                say {
                    $self->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE]
                    } $status_desc, ' lexeme @', $lexeme_start_pos,
                    q{-},
                    $lexeme_end_pos, q{: },
                    $g1_tracer->symbol_name($g1_lexeme),
                    qq{; value="$raw_token_value"};
            } ## end while ( my $event = $thin_self->event() )
            next OUTER_READ;
        } ## end if ( $problem_code eq 'trace' )

        if ( $problem_code eq 'unregistered char' ) {

            state $op_alternative = Marpa::R2::Thin::op('alternative');
            state $op_earleme_complete =
                Marpa::R2::Thin::op('earleme_complete');

            # Recover by registering character, if we can
            my $codepoint = $stream->codepoint();
            my @ops;
            for my $entry ( @{$class_table} ) {
                my ( $symbol_id, $re ) = @{$entry};
                if ( chr($codepoint) =~ $re ) {

                    # if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_SL] )
                    if (0) {
                        say {$Marpa::R2::Inner::Scanless::TRACE_FILE_HANDLE}
                            'Registering character ',
                            ( sprintf 'U+%04x', $codepoint ),
                            " as symbol $symbol_id: ",
                            $lex_tracer->symbol_name($symbol_id)
                            or
                            Marpa::R2::exception("Could not say(): $ERRNO");
                    } ## end if (0)
                    push @ops, $op_alternative, $symbol_id, 0, 1;
                } ## end if ( chr($codepoint) =~ $re )
            } ## end for my $entry ( @{$class_table} )
            Marpa::R2::exception(
                'Lexing failed at unacceptable character ',
                character_describe( chr $codepoint )
            ) if not @ops;
            $stream->char_register( $codepoint, @ops, $op_earleme_complete );
            next OUTER_READ;
        } ## end if ( $problem_code eq 'unregistered char' )

        return $self->read_problem( $problem_code );

    } ## end OUTER_READ: while (1)

    return $stream->pos();
} ## end sub Marpa::R2::Scanless::R::read

## From here, recovery is a matter for the caller,
## if it is possible at all
sub Marpa::R2::Scanless::R::read_problem {
    my ($self, $problem_code ) = @_;

    die 'No problem_code in slr->read_problem()' if not $problem_code;

    my $thin_self  = $self->[Marpa::R2::Inner::Scanless::R::C];
    my $grammar = $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR];

    my $thick_lex_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $lex_tracer       = $thick_lex_grammar->tracer();
    my $stream  = $thin_self->stream();

    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce    = $thick_g1_recce->thin();
    my $thick_g1_grammar = $thick_g1_recce->grammar();
    my $g1_tracer       = $thick_g1_grammar->tracer();

    my $pos = $stream->pos();
    my $p_string = $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];
    my $length_of_string     = length ${$p_string};

    my $problem;
    my $g0_status = 0;
    my $g1_status = 0;
    CODE_TO_PROBLEM: {
        if ( $problem_code eq 'R0 exhausted before end' ) {
            my ($lexeme_start_pos) = $thin_self->lexeme_locations();
            $problem =
                "Parse exhausted, but lexemes remain, at position $lexeme_start_pos\n";
            last CODE_TO_PROBLEM;
        }
        if ( $problem_code eq 'no lexeme' ) {
            my ($lexeme_start) = $thin_self->lexeme_locations();
            $problem = "No lexeme found at position $lexeme_start";
            last CODE_TO_PROBLEM;
        }
        if ( $problem_code eq 'R0 read() problem' ) {
            $problem = undef; # let $g0_status do the work
            $g0_status = $thin_self->stream_read_result();
            last CODE_TO_PROBLEM;
        }
        if ( $problem_code eq 'R1 earleme_complete() problem' ) {
            $problem = undef; # let $g1_status do the work
            $g1_status = $thin_self->r1_earleme_complete_result();
            last CODE_TO_PROBLEM;
        }
        $problem = 'Unrecognized problem code: ' . $problem_code;
    } ## end CODE_TO_PROBLEM:

    my $desc;
    DESC: {
        if (defined $problem) {
            $desc .= "$problem\n";
        }
        if ( $g0_status > 0 ) {
            EVENT:
            for (
                my $event_ix = 0;
                $event_ix < $g0_status;
                $event_ix++
                )
            {
                my ( $event_type, $value ) =
                    $thin_self->g0()->event($event_ix);
                if ( $event_type eq 'MARPA_EVENT_EARLEY_ITEM_THRESHOLD' ) {
                    $desc
                        .= "Lexer: Earley item count ($value) exceeds warning threshold\n";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                    $desc .= "Unexpected lexer event: $event_type "
                        . $lex_tracer->symbol_name($value) . "\n";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                    $desc .= "Unexpected lexer event: $event_type\n";
                    next EVENT;
                }
            } ## end EVENT: for ( my $event_ix = 0; $event_ix < $g0_status...)
            last DESC;
        } ## end if ( $g0_status > 0 )
        if ( $g0_status == -1 ) {
            $desc = 'Lexer: Character rejected';
            last DESC;
        }
        if ( $g0_status == -2 ) {
            $desc = 'Lexer: Unregistered character';
            last DESC;
        }
        if ( $g0_status == -3 ) {
            $desc = 'Unexpected return value from lexer: Parse exhausted';
            last DESC;
        }
        if ($g1_status) {
            my $true_event_count = $thin_self->g1()->event_count();
            EVENT:
            for (
                my $event_ix = 0;
                $event_ix < $true_event_count;
                $event_ix++
                )
            {
                my ( $event_type, $value ) =
                    $thin_self->g1()->event($event_ix);
                if ( $event_type eq 'MARPA_EVENT_EARLEY_ITEM_THRESHOLD' ) {
                    $desc
                        .= "G1 grammar: Earley item count ($value) exceeds warning threshold\n";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                    $desc .= "Unexpected G1 grammar event: $event_type "
                        . $g1_tracer->symbol_name($value) . "\n";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                    $desc .= 'Parse exhausted';
                    next EVENT;
                }
            } ## end EVENT: for ( my $event_ix = 0; $event_ix < ...)
            last DESC;
        } ## end if ($g1_status)
        if ( $g1_status < 0 ) {
            $desc = 'G1 error: ' . $thin_self->g1()->error();
            last DESC;
        }
    } ## end DESC:
    my $read_string_error;
    if ($g1_status) {
        my $latest_earley_set = $thin_g1_recce->latest_earley_set();
        my (undef, $last_pos) = $thin_self->locations($latest_earley_set);
        my $prefix =
            $last_pos >= 72
            ? ( substr ${$p_string}, $last_pos - 72, 72 )
            : ( substr ${$p_string}, 0, $last_pos );
        $read_string_error =
              "Error in Scanless read: G1 $desc\n"
            . "* Error was at string position: $last_pos\n"
            . "* String before error:\n"
            . Marpa::R2::escape_string( $prefix, -72 ) . "\n"
            . "* String after error:\n"
            . Marpa::R2::escape_string( ( substr ${$p_string}, $last_pos, 72 ), 72 )
            . "\n";
    } ## end if ($g1_status)
    elsif ( $pos < $length_of_string ) {
        my $char = substr ${$p_string}, $pos, 1;
        my $char_desc = character_describe($char);
        my $prefix =
            $pos >= 72
            ? ( substr ${$p_string}, $pos - 72, 72 )
            : ( substr ${$p_string}, 0, $pos );

        $read_string_error =
              "Error in Scanless read: G1 $desc\n"
            . "* Error was at string position: $pos, and at character $char_desc\n"
            . "* String before error:\n"
            . Marpa::R2::escape_string( $prefix, -72 ) . "\n"
            . "* String after error:\n"
            . Marpa::R2::escape_string( ( substr ${$p_string}, $pos, 72 ), 72 )
            . "\n";
    } ## end elsif ( $pos < $length_of_string )
    else {
        $read_string_error =
              "Error in Scanless read: G1 $desc\n"
            . "* Error was at end of string\n"
            . "* String before error:\n"
            . Marpa::R2::escape_string( ${$p_string}, -72 ) . "\n";
    } ## end else [ if ($g1_status) ]
    $self->[Marpa::R2::Inner::Scanless::R::READ_STRING_ERROR] =
        $read_string_error;
    Marpa::R2::exception($read_string_error);

    # Never reached
    # Fall through to return undef
    return;

} ## end sub Marpa::R2::Scanless::R::read

sub character_describe {
    my ($char) = @_;
    my $text = sprintf '0x%04x', ord $char;
    $text .= q{ } .
        (
        $char =~ m/[[:graph:]]/xms
        ? qq{'$char'}
        : '(non-graphic character)'
        );
    return $text;
} ## end sub character_describe

sub Marpa::R2::Scanless::R::value {

    my ($self) = @_;
    my $thin_self  = $self->[Marpa::R2::Inner::Scanless::R::C];
    my $thick_g1_recce = $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    # dummy up the token values
    my $p_input   = $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];
    my @token_values = ('');
    my $latest_earley_set = $thick_g1_recce->latest_earley_set();
    for (my $earley_set = 1 ; $earley_set <= $latest_earley_set; $earley_set++) {
        my ($start_position, $end_position) = $thin_self->locations($earley_set);
        push @token_values, substr ${$p_input}, $start_position, ( $end_position - $start_position );
    }
    $thick_g1_recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES] = \@token_values;
    return $thick_g1_recce->value();
} ## end sub Marpa::R2::Scanless::R::value

sub Marpa::R2::Scanless::R::show_progress {
     # Make the thick recognizer the new "self"
     $_[0] = $_[0]->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
     goto &Marpa::R2::Recognizer::show_progress;
}

1;

# vim: expandtab shiftwidth=4:
