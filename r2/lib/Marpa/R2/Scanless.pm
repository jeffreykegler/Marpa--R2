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

package Marpa::R2::Scanless;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.041_000';
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

    THICK_LEX_GRAMMAR
    THICK_G1_GRAMMAR
    IS_LEXEME
    CHARACTER_CLASS_TABLE
    LEXEME_TO_G1_SYMBOL
    G0_DISCARD_SYMBOL_ID
    MASK_BY_RULE_ID

    TRACE_FILE_HANDLE
    DEFAULT_ACTION
    ACTION_OBJECT

END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::R2::Inner::Scanless::R

    GRAMMAR
    STREAM
    THIN_LEX_RECCE
    THICK_G1_RECCE
    LOCATIONS
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

# This rule is used by the semantics of the *GENERATED*
# grammars, not the Scanless grammar itself.
sub external_do_arg0 {
   return $_[1];
}

package Marpa::R2::Inner::Scanless::Symbol;

use constant NAME => 0;
use constant HIDE => 1;

sub new { my $class = shift; return bless { name => $_[NAME], is_hidden => ($_[HIDE]//0) }, $class }
sub is_symbol { 1 };
sub name { return $_[0]->{name} }
sub names { return $_[0]->{name} }
sub is_hidden { return $_[0]->{is_hidden} }
sub are_all_hidden { return $_[0]->{is_hidden} }

sub is_lexical { shift->{is_lexical} // 0 }
sub hidden_set { shift->{is_hidden} = 1; }
sub lexical_set { shift->{is_lexical} = 1; }
sub symbols { return $_[0]; }
sub symbol_lists { return $_[0]; }

package Marpa::R2::Inner::Scanless::Symbol_List;

sub new { my $class = shift; return bless { symbol_lists => [@_] }, $class }

sub is_symbol { 0 };

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
}

sub is_lexical { shift->{is_lexical} // 0 }
sub lexical_set { shift->{is_lexical} = 1; }

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
    my @ws      = ();
    my $normalized_rhs = $self->normalize($rhs);
    return [ { lhs => '[:start]', rhs => [$normalized_rhs->names()] } ];
} ## end sub do_start_rule

sub do_discard_rule {
    my ( $self, $rhs ) = @_;
    local $GRAMMAR_LEVEL = 0;
    my $normalized_rhs = $self->normalize($rhs);
    push @{$self->{lex_rules}}, { lhs => '[:discard]', rhs => [$normalized_rhs->name()] };
    return [];
} ## end sub do_discard_rule

# "Normalize" a symbol list, creating subrules as needed
# for lexicalization.
sub normalize {
    my ( $self, $symbols ) = @_;
    return $symbols if $GRAMMAR_LEVEL <= 0;
    return Marpa::R2::Inner::Scanless::Symbol_List->new(
        map { $_->is_symbol() ? $_ : $self->normalize($_) } $symbols->symbol_lists() )
        if not $symbols->is_lexical();
    my $is_hidden = $symbols->are_all_hidden();
    my $lexical_lhs_index = $self->{lexical_lhs_index}++;
    my $lexical_lhs       = "[Lex-$lexical_lhs_index]";
    my %lexical_rule      = (
        lhs  => $lexical_lhs,
        rhs  => [ $symbols->names() ],
        mask => [ $symbols->mask() ]
    );
    push @{ $self->{lex_rules} }, \%lexical_rule;
    my $g1_symbol = Marpa::R2::Inner::Scanless::Symbol->new($lexical_lhs);
    $g1_symbol->hidden_set() if $is_hidden;
    return $g1_symbol;
} ## end sub normalize

sub do_priority_rule {
    my ( $self, $lhs, $op_declare, $priorities ) = @_;
    my $priority_count = scalar @{$priorities};
    my @working_rules          = ();

    my @xs_rules = ();
    my $rules = $op_declare eq q{::=} ? \@xs_rules : $self->{lex_rules};
    local $GRAMMAR_LEVEL = 0 if not $op_declare eq q{::=};

    if ( $priority_count <= 1 ) {
        ## If there is only one priority
        for my $alternative ( @{ $priorities->[0] } ) {
            my ( $rhs, $adverb_list ) = @{$alternative};
            $rhs = $self->normalize($rhs);
            my @rhs_names = $rhs->names();
            my @mask      = $rhs->mask();
            if ( $GRAMMAR_LEVEL <= 0 and grep { !$_ } @mask ) {
                Marpa::R2::exception(
                    'hidden symbols are not allowed in lexical rules (rules LHS was "',
                    $lhs->name(), '")'
                );
            } ## end if ( $GRAMMAR_LEVEL <= 0 and grep { !$_ } @mask )
            my %hash_rule =
                ( lhs => $lhs, rhs => \@rhs_names, mask => \@mask );
            my $action = $adverb_list->{action};
            if ( defined $action ) {
                Marpa::R2::exception(
                    'actions not allowed in lexical rules (rules LHS was "',
                    $lhs, '")' )
                    if $GRAMMAR_LEVEL <= 0;
                $hash_rule{action} = $action;
            } ## end if ( defined $action )
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

    state $do_arg0_full_name = __PACKAGE__ . q{::} . 'external_do_arg0';
    # Default mask (all ones) is OK for this rule
    my @arg0_action = ();
    @arg0_action = ( action => $do_arg0_full_name) if $GRAMMAR_LEVEL > 0;
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
        $rhs = $self->normalize($rhs);
        my $assoc   = $adverb_list->{assoc} // 'L';
        my @new_rhs = $rhs->names();
        my @arity   = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $length  = scalar @new_rhs;

        my $current_exp = $lhs . '[prec' . $priority . ']';
        my @mask        = $rhs->mask();
        if ( $GRAMMAR_LEVEL <= 0 and grep { !$_ } @mask ) {
            Marpa::R2::exception(
                'hidden symbols are not allowed in lexical rules (rules LHS was "',
                $lhs, '")'
            );
        } ## end if ( $GRAMMAR_LEVEL <= 0 and grep { !$_ } @mask )
        my %new_xs_rule = ( lhs => $current_exp );
        $new_xs_rule{mask} = \@mask;

        my $action = $adverb_list->{action};
        if ( defined $action ) {
            Marpa::R2::exception(
                'actions not allowed in lexical rules (rules LHS was "',
                $lhs, '")' )
                if $GRAMMAR_LEVEL <= 0;
            $new_xs_rule{action} = $action;
        } ## end if ( defined $action )

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
    my $action = $adverb_list->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $GRAMMAR_LEVEL <= 0;
        $rule{action} = $action;
    } ## end if ( defined $action )

    # mask not needed
    if ( $op_declare eq q{::=} ) {
        return \%rule;
    }
    push @{ $self->{lex_rules} }, \%rule;
    return [];
} ## end sub do_empty_rule

sub do_quantified_rule {
    my ( $self, $lhs, $op_declare, $rhs, $quantifier, $adverb_list ) = @_;

    local $GRAMMAR_LEVEL = 0 if not $op_declare eq q{::=};

    # Some properties of the sequence rule will not be altered
    # no matter how complicated this gets
    my %sequence_rule = (
        rhs => [ $rhs->name() ],
        min => ( $quantifier eq q{+} ? 1 : 0 )
    );
    my $action = $adverb_list->{action};
    if ( defined $action ) {
        Marpa::R2::exception(
            'actions not allowed in lexical rules (rules LHS was "',
            $lhs, '")' )
            if $GRAMMAR_LEVEL <= 0;
        $sequence_rule{action} = $action;
    } ## end if ( defined $action )
    my @rules = ( \%sequence_rule );

    my $original_separator = $adverb_list->{separator};

    # mask not needed
    $sequence_rule{lhs}       = $lhs;
    $sequence_rule{separator} = $original_separator
        if defined $original_separator;
    my $proper = $adverb_list->{proper};
    $sequence_rule{proper} = $proper if defined $proper;

    if ($op_declare eq q{::=}) {
        return \@rules;
    } else {
       push @{$self->{lex_rules}}, @rules;
       return [];
    }

} ## end sub do_quantified_rule

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
                $char_class, "\n", "Perl said ", $EVAL_ERROR );
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
    for my $char_class ( map { "[" . (quotemeta $_) . "]" } split //xms, substr $string, 1, -1) {
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
    my ( $self, $start, $end ) = @_;
    return if not defined $start;
    my $locations = $self->[Marpa::R2::Inner::Scanless::R::LOCATIONS];
    my $p_input   = $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];
    my $start_position = $locations->[ $start + 1 ]->[0];
    my $end_position   = $locations->[$end]->[1];
    return substr ${$p_input}, $start_position,
        ( $end_position - $start_position );
} ## end sub Marpa::R2::Scanless::R::range_to_string

sub meta_grammar {
    my $hashed_metag;

## The code after this line was automatically generated by sl_to_hash.pl
## Date: Mon Dec 24 14:19:53 2012
$hashed_metag = {
                  'character_classes' => {
                                           '[[\']]' => qr/(?msx-i:['])/,
                                           '[[01]]' => qr/(?msx-i:[01])/,
                                           '[[\\#]]' => qr/(?msx-i:[\#])/,
                                           '[[\\(]]' => qr/(?msx-i:[\(])/,
                                           '[[\\)]]' => qr/(?msx-i:[\)])/,
                                           '[[\\*]]' => qr/(?msx-i:[\*])/,
                                           '[[\\+]]' => qr/(?msx-i:[\+])/,
                                           '[[\\:]]' => qr/(?msx-i:[\:])/,
                                           '[[\\<]]' => qr/(?msx-i:[\<])/,
                                           '[[\\=]]' => qr/(?msx-i:[\=])/,
                                           '[[\\>]]' => qr/(?msx-i:[\>])/,
                                           '[[\\[]]' => qr/(?msx-i:[\[])/,
                                           '[[\\\\]]' => qr/(?msx-i:[\\])/,
                                           '[[\\]]]' => qr/(?msx-i:[\]])/,
                                           '[[\\s\\w]]' => qr/(?msx-i:[\s\w])/,
                                           '[[\\s]]' => qr/(?msx-i:[\s])/,
                                           '[[\\w]]' => qr/(?msx-i:[\w])/,
                                           '[[\\x{A}\\x{B}\\x{C}\\x{D}\\x{2028}\\x{2029}]]' => qr/(?msx-i:[\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}])/,
                                           '[[\\|]]' => qr/(?msx-i:[\|])/,
                                           '[[\\~]]' => qr/(?msx-i:[\~])/,
                                           '[[^\'\\x{0A}\\x{0B}\\x{0C}\\x{0D}\\x{0085}\\x{2028}\\x{2029}]]' => qr/(?msx-i:[^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}])/,
                                           '[[^\\x{5d}\\x{0A}\\x{0B}\\x{0C}\\x{0D}\\x{0085}\\x{2028}\\x{2029}]]' => qr/(?msx-i:[^\x{5d}\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}])/,
                                           '[[^\\x{A}\\x{B}\\x{C}\\x{D}\\x{2028}\\x{2029}]]' => qr/(?msx-i:[^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}])/,
                                           '[[a]]' => qr/(?msx-i:[a])/,
                                           '[[c]]' => qr/(?msx-i:[c])/,
                                           '[[d]]' => qr/(?msx-i:[d])/,
                                           '[[e]]' => qr/(?msx-i:[e])/,
                                           '[[f]]' => qr/(?msx-i:[f])/,
                                           '[[g]]' => qr/(?msx-i:[g])/,
                                           '[[h]]' => qr/(?msx-i:[h])/,
                                           '[[i]]' => qr/(?msx-i:[i])/,
                                           '[[l]]' => qr/(?msx-i:[l])/,
                                           '[[n]]' => qr/(?msx-i:[n])/,
                                           '[[o]]' => qr/(?msx-i:[o])/,
                                           '[[p]]' => qr/(?msx-i:[p])/,
                                           '[[r]]' => qr/(?msx-i:[r])/,
                                           '[[s]]' => qr/(?msx-i:[s])/,
                                           '[[t]]' => qr/(?msx-i:[t])/,
                                           '[[u]]' => qr/(?msx-i:[u])/,
                                           '[[w]]' => qr/(?msx-i:[w])/,
                                           '[[y]]' => qr/(?msx-i:[y])/
                                         },
                  'g1_rules' => [
                                  {
                                    'lhs' => '[:start]',
                                    'rhs' => [
                                               'rules'
                                             ]
                                  },
                                  {
                                    'lhs' => 'action',
                                    'mask' => [
                                                0,
                                                0,
                                                1
                                              ],
                                    'rhs' => [
                                               '[Lex-2]',
                                               '[Lex-3]',
                                               'action name'
                                             ]
                                  },
                                  {
                                    'lhs' => 'action name',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'bare name'
                                             ]
                                  },
                                  {
                                    'lhs' => 'adverb item',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'action'
                                             ]
                                  },
                                  {
                                    'lhs' => 'adverb item',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'group association'
                                             ]
                                  },
                                  {
                                    'lhs' => 'adverb item',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'left association'
                                             ]
                                  },
                                  {
                                    'lhs' => 'adverb item',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'proper specification'
                                             ]
                                  },
                                  {
                                    'lhs' => 'adverb item',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'right association'
                                             ]
                                  },
                                  {
                                    'lhs' => 'adverb item',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'separator specification'
                                             ]
                                  },
                                  {
                                    'lhs' => 'adverb list',
                                    'min' => 0,
                                    'rhs' => [
                                               'adverb item'
                                             ]
                                  },
                                  {
                                    'lhs' => 'alternative',
                                    'mask' => [
                                                1,
                                                1
                                              ],
                                    'rhs' => [
                                               'rhs',
                                               'adverb list'
                                             ]
                                  },
                                  {
                                    'lhs' => 'alternatives',
                                    'min' => 1,
                                    'proper' => '1',
                                    'rhs' => [
                                               'alternative'
                                             ],
                                    'separator' => 'op equal priority'
                                  },
                                  {
                                    'lhs' => 'discard rule',
                                    'mask' => [
                                                0,
                                                0,
                                                1
                                              ],
                                    'rhs' => [
                                               '[Lex-1]',
                                               'op declare match',
                                               'single symbol'
                                             ]
                                  },
                                  {
                                    'lhs' => 'empty rule',
                                    'mask' => [
                                                1,
                                                1,
                                                1
                                              ],
                                    'rhs' => [
                                               'lhs',
                                               'op declare',
                                               'adverb list'
                                             ]
                                  },
                                  {
                                    'lhs' => 'group association',
                                    'mask' => [
                                                0,
                                                0,
                                                0
                                              ],
                                    'rhs' => [
                                               '[Lex-10]',
                                               '[Lex-11]',
                                               '[Lex-12]'
                                             ]
                                  },
                                  {
                                    'lhs' => 'left association',
                                    'mask' => [
                                                0,
                                                0,
                                                0
                                              ],
                                    'rhs' => [
                                               '[Lex-4]',
                                               '[Lex-5]',
                                               '[Lex-6]'
                                             ]
                                  },
                                  {
                                    'lhs' => 'lhs',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'symbol name'
                                             ]
                                  },
                                  {
                                    'lhs' => 'op declare',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'op declare bnf'
                                             ]
                                  },
                                  {
                                    'lhs' => 'op declare',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'op declare match'
                                             ]
                                  },
                                  {
                                    'lhs' => 'parenthesized rhs primary list',
                                    'mask' => [
                                                0,
                                                1,
                                                0
                                              ],
                                    'rhs' => [
                                               '[Lex-17]',
                                               'rhs primary list',
                                               '[Lex-18]'
                                             ]
                                  },
                                  {
                                    'lhs' => 'priorities',
                                    'min' => 1,
                                    'proper' => '1',
                                    'rhs' => [
                                               'alternatives'
                                             ],
                                    'separator' => 'op loosen'
                                  },
                                  {
                                    'lhs' => 'priority rule',
                                    'mask' => [
                                                1,
                                                1,
                                                1
                                              ],
                                    'rhs' => [
                                               'lhs',
                                               'op declare',
                                               'priorities'
                                             ]
                                  },
                                  {
                                    'lhs' => 'proper specification',
                                    'mask' => [
                                                0,
                                                0,
                                                1
                                              ],
                                    'rhs' => [
                                               '[Lex-15]',
                                               '[Lex-16]',
                                               'boolean'
                                             ]
                                  },
                                  {
                                    'lhs' => 'quantified rule',
                                    'mask' => [
                                                1,
                                                1,
                                                1,
                                                1,
                                                1
                                              ],
                                    'rhs' => [
                                               'lhs',
                                               'op declare',
                                               'single symbol',
                                               'quantifier',
                                               'adverb list'
                                             ]
                                  },
                                  {
                                    'lhs' => 'quantifier',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               '[Lex-19]'
                                             ]
                                  },
                                  {
                                    'lhs' => 'quantifier',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               '[Lex-20]'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs',
                                    'min' => 1,
                                    'rhs' => [
                                               'rhs primary'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs primary',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'kwc any'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs primary',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'kwc ws'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs primary',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'kwc ws plus'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs primary',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'kwc ws star'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs primary',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'parenthesized rhs primary list'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs primary',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'single quoted string'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs primary',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'single symbol'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rhs primary list',
                                    'min' => 1,
                                    'rhs' => [
                                               'rhs primary'
                                             ]
                                  },
                                  {
                                    'lhs' => 'right association',
                                    'mask' => [
                                                0,
                                                0,
                                                0
                                              ],
                                    'rhs' => [
                                               '[Lex-7]',
                                               '[Lex-8]',
                                               '[Lex-9]'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rule',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'discard rule'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rule',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'empty rule'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rule',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'priority rule'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rule',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'quantified rule'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rule',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'start rule'
                                             ]
                                  },
                                  {
                                    'lhs' => 'rules',
                                    'min' => 1,
                                    'rhs' => [
                                               'rule'
                                             ]
                                  },
                                  {
                                    'lhs' => 'separator specification',
                                    'mask' => [
                                                0,
                                                0,
                                                1
                                              ],
                                    'rhs' => [
                                               '[Lex-13]',
                                               '[Lex-14]',
                                               'single symbol'
                                             ]
                                  },
                                  {
                                    'lhs' => 'single symbol',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'character class'
                                             ]
                                  },
                                  {
                                    'lhs' => 'single symbol',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'symbol'
                                             ]
                                  },
                                  {
                                    'lhs' => 'start rule',
                                    'mask' => [
                                                0,
                                                0,
                                                1
                                              ],
                                    'rhs' => [
                                               '[Lex-0]',
                                               'op declare bnf',
                                               'symbol'
                                             ]
                                  },
                                  {
                                    'lhs' => 'symbol',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'symbol name'
                                             ]
                                  },
                                  {
                                    'lhs' => 'symbol name',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'bare name'
                                             ]
                                  },
                                  {
                                    'lhs' => 'symbol name',
                                    'mask' => [
                                                1
                                              ],
                                    'rhs' => [
                                               'bracketed name'
                                             ]
                                  }
                                ],
                  'is_lexeme' => {
                                   '[:discard]' => 1,
                                   '[Lex-0]' => 1,
                                   '[Lex-10]' => 1,
                                   '[Lex-11]' => 1,
                                   '[Lex-12]' => 1,
                                   '[Lex-13]' => 1,
                                   '[Lex-14]' => 1,
                                   '[Lex-15]' => 1,
                                   '[Lex-16]' => 1,
                                   '[Lex-17]' => 1,
                                   '[Lex-18]' => 1,
                                   '[Lex-19]' => 1,
                                   '[Lex-1]' => 1,
                                   '[Lex-20]' => 1,
                                   '[Lex-2]' => 1,
                                   '[Lex-3]' => 1,
                                   '[Lex-4]' => 1,
                                   '[Lex-5]' => 1,
                                   '[Lex-6]' => 1,
                                   '[Lex-7]' => 1,
                                   '[Lex-8]' => 1,
                                   '[Lex-9]' => 1,
                                   'bare name' => 1,
                                   'boolean' => 1,
                                   'bracketed name' => 1,
                                   'character class' => 1,
                                   'kwc any' => 1,
                                   'kwc ws' => 1,
                                   'kwc ws plus' => 1,
                                   'kwc ws star' => 1,
                                   'op declare bnf' => 1,
                                   'op declare match' => 1,
                                   'op equal priority' => 1,
                                   'op loosen' => 1,
                                   'single quoted string' => 1
                                 },
                  'lex_rules' => [
                                   {
                                     'lhs' => '[:discard]',
                                     'rhs' => [
                                                'hash comment'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:discard]',
                                     'rhs' => [
                                                'whitespace'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[:discard]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-0]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-10]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-11]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-12]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-13]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-14]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-15]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-16]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-17]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-18]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-19]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-1]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-20]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-2]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-3]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-4]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-5]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-6]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-7]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-8]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                '[Lex-9]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'bare name'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'boolean'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'bracketed name'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'character class'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'kwc any'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'kwc ws'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'kwc ws plus'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'kwc ws star'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'op declare bnf'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'op declare match'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'op equal priority'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'op loosen'
                                              ]
                                   },
                                   {
                                     'lhs' => '[:start_lex]',
                                     'rhs' => [
                                                'single quoted string'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-0]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\:]]',
                                                '[[s]]',
                                                '[[t]]',
                                                '[[a]]',
                                                '[[r]]',
                                                '[[t]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-10]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[a]]',
                                                '[[s]]',
                                                '[[s]]',
                                                '[[o]]',
                                                '[[c]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-11]',
                                     'mask' => [
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\=]]',
                                                '[[\\>]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-12]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[g]]',
                                                '[[r]]',
                                                '[[o]]',
                                                '[[u]]',
                                                '[[p]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-13]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[s]]',
                                                '[[e]]',
                                                '[[p]]',
                                                '[[a]]',
                                                '[[r]]',
                                                '[[a]]',
                                                '[[t]]',
                                                '[[o]]',
                                                '[[r]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-14]',
                                     'mask' => [
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\=]]',
                                                '[[\\>]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-15]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[p]]',
                                                '[[r]]',
                                                '[[o]]',
                                                '[[p]]',
                                                '[[e]]',
                                                '[[r]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-16]',
                                     'mask' => [
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\=]]',
                                                '[[\\>]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-17]',
                                     'mask' => [
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\(]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-18]',
                                     'mask' => [
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\)]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-19]',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\*]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-1]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\:]]',
                                                '[[d]]',
                                                '[[i]]',
                                                '[[s]]',
                                                '[[c]]',
                                                '[[a]]',
                                                '[[r]]',
                                                '[[d]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-20]',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\+]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-2]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[a]]',
                                                '[[c]]',
                                                '[[t]]',
                                                '[[i]]',
                                                '[[o]]',
                                                '[[n]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-3]',
                                     'mask' => [
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\=]]',
                                                '[[\\>]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-4]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[a]]',
                                                '[[s]]',
                                                '[[s]]',
                                                '[[o]]',
                                                '[[c]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-5]',
                                     'mask' => [
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\=]]',
                                                '[[\\>]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-6]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[l]]',
                                                '[[e]]',
                                                '[[f]]',
                                                '[[t]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-7]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[a]]',
                                                '[[s]]',
                                                '[[s]]',
                                                '[[o]]',
                                                '[[c]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-8]',
                                     'mask' => [
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[\\=]]',
                                                '[[\\>]]'
                                              ]
                                   },
                                   {
                                     'lhs' => '[Lex-9]',
                                     'mask' => [
                                                 0,
                                                 0,
                                                 0,
                                                 0,
                                                 0
                                               ],
                                     'rhs' => [
                                                '[[r]]',
                                                '[[i]]',
                                                '[[g]]',
                                                '[[h]]',
                                                '[[t]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'bare name',
                                     'min' => 1,
                                     'rhs' => [
                                                '[[\\w]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'boolean',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[01]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'bracketed name',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\<]]',
                                                'bracketed name string',
                                                '[[\\>]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'bracketed name string',
                                     'min' => 1,
                                     'rhs' => [
                                                '[[\\s\\w]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'cc character',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                'escaped cc character'
                                              ]
                                   },
                                   {
                                     'lhs' => 'cc character',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                'safe cc character'
                                              ]
                                   },
                                   {
                                     'lhs' => 'cc string',
                                     'min' => 1,
                                     'rhs' => [
                                                'cc character'
                                              ]
                                   },
                                   {
                                     'lhs' => 'character class',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\[]]',
                                                'cc string',
                                                '[[\\]]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'escaped cc character',
                                     'mask' => [
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\\\]]',
                                                'horizontal character'
                                              ]
                                   },
                                   {
                                     'lhs' => 'hash comment',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                'terminated hash comment'
                                              ]
                                   },
                                   {
                                     'lhs' => 'hash comment',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                'unterminated final hash comment'
                                              ]
                                   },
                                   {
                                     'lhs' => 'hash comment body',
                                     'min' => 0,
                                     'rhs' => [
                                                'hash comment char'
                                              ]
                                   },
                                   {
                                     'lhs' => 'hash comment char',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[^\\x{A}\\x{B}\\x{C}\\x{D}\\x{2028}\\x{2029}]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'horizontal character',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[^\\x{A}\\x{B}\\x{C}\\x{D}\\x{2028}\\x{2029}]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'kwc any',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\:]]',
                                                '[[a]]',
                                                '[[n]]',
                                                '[[y]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'kwc ws',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\:]]',
                                                '[[w]]',
                                                '[[s]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'kwc ws plus',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\:]]',
                                                '[[w]]',
                                                '[[s]]',
                                                '[[\\+]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'kwc ws star',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\:]]',
                                                '[[w]]',
                                                '[[s]]',
                                                '[[\\*]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'op declare bnf',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\:]]',
                                                '[[\\:]]',
                                                '[[\\=]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'op declare match',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\~]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'op equal priority',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\|]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'op loosen',
                                     'mask' => [
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\|]]',
                                                '[[\\|]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'safe cc character',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[^\\x{5d}\\x{0A}\\x{0B}\\x{0C}\\x{0D}\\x{0085}\\x{2028}\\x{2029}]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'single quoted string',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\']]',
                                                'string without single quote or vertical space',
                                                '[[\']]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'string without single quote or vertical space',
                                     'min' => 1,
                                     'rhs' => [
                                                '[[^\'\\x{0A}\\x{0B}\\x{0C}\\x{0D}\\x{0085}\\x{2028}\\x{2029}]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'terminated hash comment',
                                     'mask' => [
                                                 1,
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\#]]',
                                                'hash comment body',
                                                'vertical space char'
                                              ]
                                   },
                                   {
                                     'lhs' => 'unterminated final hash comment',
                                     'mask' => [
                                                 1,
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\#]]',
                                                'hash comment body'
                                              ]
                                   },
                                   {
                                     'lhs' => 'vertical space char',
                                     'mask' => [
                                                 1
                                               ],
                                     'rhs' => [
                                                '[[\\x{A}\\x{B}\\x{C}\\x{D}\\x{2028}\\x{2029}]]'
                                              ]
                                   },
                                   {
                                     'lhs' => 'whitespace',
                                     'min' => 1,
                                     'rhs' => [
                                                '[[\\s]]'
                                              ]
                                   }
                                 ]
                };
## The code before this line was automatically generated by sl_to_hash.pl

    my $self = bless [], 'Marpa::R2::Scanless::G';
    $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] = \*STDERR;
    $self->_hash_to_runtime($hashed_metag);

    my $thick_g1_grammar = $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my @mask_by_rule_id;
    $mask_by_rule_id[$_] = $thick_g1_grammar->_rule_mask($_) for $thick_g1_grammar->rule_ids();
    $self->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID] = \@mask_by_rule_id;

    return $self;

} ## end sub meta_grammar

sub Marpa::R2::Scanless::R::last_rule {
   my ($meta_recce) = @_;
   my ($start, $end) = $meta_recce->last_completed_range( 'rule' );
   return 'No rule was completed' if not defined $start;
   return $meta_recce->range_to_string( $start, $end);
}

my %grammar_options = map { $_, 1 } qw{
    action_object
    default_action
    source
    trace_file_handle
};

    # Other possible grammar options:
    # actions
    # default_empty_action
    # default_rank
    # inaccessible_ok
    # symbols
    # terminals
    # unproductive_ok
    # warnings

sub Marpa::R2::Scanless::G::new {
    my ( $class, $args ) = @_;

    my $self = [];
    bless $self, $class;

    $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] = *STDERR;

    my $ref_type = ref $args;
    if ( not $ref_type ) {
        Carp::croak(
            '$G_PACKAGE expects args as ref to HASH; arg was non-reference');
    }
    if ( $ref_type ne 'HASH' ) {
        Carp::croak(
            "$G_PACKAGE expects args as ref to HASH, got ref to $ref_type instead"
        );
    }
    if (my @bad_options =
        grep { not defined $grammar_options{$_} } keys %{$args}
        )
    {
        Carp::croak(
            "$G_PACKAGE does not know some of option(s) given to it:\n",
            "   The option(s) not recognized were ",
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
    my ($self, $hashed_source) = @_;

    my %lex_args = ();
    $lex_args{trace_file_handle} = 
        $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] // \*STDERR;
    $lex_args{rules} = $hashed_source->{lex_rules};
    state $lex_target_symbol = '[:start_lex]';
    $lex_args{start} = $lex_target_symbol;
    $lex_args{'_internal_'} = 1;
    my $lex_grammar = Marpa::R2::Grammar->new( \%lex_args );
    $lex_grammar->precompute();
    my $lex_tracer     = $lex_grammar->tracer();
    my @is_lexeme      = ();
    my @lexeme_names = keys %{ $hashed_source->{is_lexeme} };
    $is_lexeme[ $lex_tracer->symbol_by_name($_) ] = 1 for @lexeme_names;
    $self->[Marpa::R2::Inner::Scanless::G::IS_LEXEME]         = \@is_lexeme;
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
    $g1_args{action_object} = $self->[Marpa::R2::Inner::Scanless::G::ACTION_OBJECT];
    $g1_args{default_action} = $self->[Marpa::R2::Inner::Scanless::G::DEFAULT_ACTION];
    $g1_args{rules} = $hashed_source->{g1_rules};
    state $g1_target_symbol = '[:start]';
    $g1_args{start} = $g1_target_symbol;
    $g1_args{'_internal_'} = 1;
    my $thick_g1_grammar = Marpa::R2::Grammar->new( \%g1_args );
    $thick_g1_grammar->precompute();
    my $g1_tracer = $thick_g1_grammar->tracer();
    my $g1_thin   = $g1_tracer->grammar();
    my @lexeme_to_g1_symbol;
    my @g1_symbol_is_lexeme;
    $lexeme_to_g1_symbol[$_] = -1 for 0 .. $g1_thin->highest_symbol_id();
    state $discard_symbol_name = '[:discard]';
    $self->[Marpa::R2::Inner::Scanless::G::G0_DISCARD_SYMBOL_ID] =
        $lex_tracer->symbol_by_name($discard_symbol_name);

    for my $lexeme_name ( grep { $_ ne $discard_symbol_name } @lexeme_names )
    {
        my $g1_symbol_id = $g1_tracer->symbol_by_name($lexeme_name);
        if ( not defined $g1_symbol_id ) {
            Marpa::R2::exception(
                "A lexeme is not accessible from the start symbol: ",
                $lexeme_name );
        }
        my $lex_symbol_id = $lex_tracer->symbol_by_name($lexeme_name);
        $lexeme_to_g1_symbol[$lex_symbol_id] = $g1_symbol_id;
        $g1_symbol_is_lexeme[$g1_symbol_id]  = 1;
    } ## end for my $lexeme_name ( grep { $_ ne $discard_symbol_name...})

    SYMBOL_ID: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id() ) {
        if ($g1_thin->symbol_is_terminal($symbol_id)
            and not $g1_symbol_is_lexeme[$symbol_id]
            )
        {
            Marpa::R2::exception( "Unproductive symbol: ",
                $g1_tracer->symbol_name($symbol_id) );
        } ## end if ( $g1_thin->symbol_is_terminal($symbol_id); and not...)
    } ## end SYMBOL_ID: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id(...))

    $self->[Marpa::R2::Inner::Scanless::G::LEXEME_TO_G1_SYMBOL] = \@lexeme_to_g1_symbol;
    $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR] = $thick_g1_grammar;

} ## end sub Marpa::R2::Scanless::G::new

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
    'quantified rule'                => 'do_quantified_rule',
    'discard rule'                   => 'do_discard_rule',
    priorities                       => 'do_discard_separators',
    alternatives                     => 'do_discard_separators',
    alternative                      => 'do_alternative',
    'adverb list'                    => 'do_adverb_list',
    action                           => 'do_action',
    'left association'               => 'do_left_association',
    'right association'              => 'do_right_association',
    'group association'              => 'do_group_association',
    'separator specification'        => 'do_separator_specification',
    'proper specification'           => 'do_proper_specification',
);

sub Marpa::R2::Scanless::G::_source_to_hash {
    my ( $self, $p_rules_source ) = @_;

    local $GRAMMAR_LEVEL = 1;
    my $inner_self = bless {
        self              => $self,
        lex_rules         => [],
        lexical_lhs_index => 0,
        },
        __PACKAGE__;

    # Track earley set positions in input,
    # for debuggging
    my @positions = (0);

    state $meta_grammar = meta_grammar();
    state $mask_by_rule_id =
        $meta_grammar->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID];
    my $meta_recce = Marpa::R2::Scanless::R->new({ grammar => $meta_grammar});
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
        die qq{Last rule successfully parsed was: },
            $meta_recce->last_rule(), "\n",
            'Parse failed';
    }

    my $order = Marpa::R2::Thin::O->new($bocage);
    my $tree  = Marpa::R2::Thin::T->new($order);
    $tree->next();
    my $valuator = Marpa::R2::Thin::V->new($tree);
    my @actions_by_rule_id;

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
        $action = $meta_g1_tracer->action($rule_id);
        next RULE if not defined $action;
        next RULE if $action =~ / Marpa [:][:] R2 .* [:][:] external_do_arg0 \z /xms;
        $actions_by_rule_id[$rule_id] = $action;
    } ## end for my $rule_id ( grep { $thin_meta_g1_grammar->rule_length($_...)})

    my $token_values =
        $thick_g1_recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES];

    my @stack = ();
    STEP: while (1) {
        my ( $type, @step_data ) = $valuator->step();
        last STEP if not defined $type;
        if ( $type eq 'MARPA_STEP_TOKEN' ) {
            my ( undef, $token_value_ix, $arg_n ) = @step_data;
            $stack[$arg_n] = $token_values->[$token_value_ix];
            next STEP;
        }
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
                    push @{ws_rules},
                        {
                        lhs => $needed_symbol,
                        rhs => ['[:Space]'],
                        min => 1
                        };
                    $needed{'[:Space]'} = 1;
                    next SYMBOL;
                } ## end if ( $needed_symbol eq '[:ws+]' )
                if ( $needed_symbol eq '[:ws*]' ) {
                    push @{ws_rules},
                        {
                        lhs => $needed_symbol,
                        rhs => ['[:Space]'],
                        min => 0
                        };
                    $needed{'[:Space]'} = 1;
                    next SYMBOL;
                } ## end if ( $needed_symbol eq '[:ws*]' )
                if ( $needed_symbol eq '[:ws]' ) {
                    push @{ws_rules},
                        { lhs => '[:ws]', rhs => ['[:ws+]'],  };
                    $needed{'[:ws+]'} = 1;
                    next SYMBOL;
                } ## end if ( $needed_symbol eq '[:ws]' )
                if ( $needed_symbol eq '[:Space]' ) {
                    my $true_ws = assign_symbol_by_char_class( $inner_self,
                        '[\p{White_Space}]' );
                    push @{ws_rules},
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
        Marpa::R2::exception("Unproductive lexical symbols: ", join q{ }, @unproductive);
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

my %recce_options = map { $_, 1 } qw{
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

    $self->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE] =
        $grammar->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE];

    if (my @bad_options =
        grep { not defined $recce_options{$_} } keys %{$args}
        )
    {
        Marpa::R2::exception(
            "$G_PACKAGE does not know some of option(s) given to it:\n",
            "   The option(s) not recognized were ",
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
    my $lex_r            = $self->[Marpa::R2::Inner::Scanless::R::THIN_LEX_RECCE] =
        Marpa::R2::Thin::R->new($thin_lex_grammar);
    $lex_r->start_input();

    my $thick_g1_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my %g1_recce_args = ( grammar => $thick_g1_grammar );
    $g1_recce_args{$_} = $args->{$_}
        for qw( trace_values trace_file_handle );
    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE] =
        Marpa::R2::Recognizer->new( \%g1_recce_args );

    my $stream = $self->[Marpa::R2::Inner::Scanless::R::STREAM] =
        Marpa::R2::Thin::U->new($lex_r);
    return $self;
} ## end sub Marpa::R2::Scanless::R::new

sub Marpa::R2::Scanless::R::trace {
    my ($self, $level) = @_;
    $level //= 1;
    my $stream = $self->[Marpa::R2::Inner::Scanless::R::STREAM];
    $stream->trace($level);
}

sub Marpa::R2::Scanless::R::error {
    my ($self) = @_;
    return $self->[Marpa::R2::Inner::Scanless::R::READ_STRING_ERROR];
}

sub Marpa::R2::Scanless::R::read {
    my ( $self, $p_string ) = @_;

    Marpa::R2::exception(
        "Multiple read()'s tried on a scannerless recognizer\n",
        "  Currently only a single scannerless read is allowed"
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

    my $stream  = $self->[Marpa::R2::Inner::Scanless::R::STREAM];
    my $grammar = $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thick_lex_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $lex_tracer       = $thick_lex_grammar->tracer();
    my $thin_lex_grammar = $lex_tracer->grammar();

    # Defaults to non-existent symbol
    my $g0_discard_symbol_id =
        $grammar->[Marpa::R2::Inner::Scanless::G::G0_DISCARD_SYMBOL_ID] // -1;

    my $lexeme_to_g1_symbol =
        $grammar->[Marpa::R2::Inner::Scanless::G::LEXEME_TO_G1_SYMBOL];
    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce    = $thick_g1_recce->thin();
    my $thick_g1_grammar = $thick_g1_recce->grammar();
    my $g1_tracer       = $thick_g1_grammar->tracer();
    my $thin_g1_grammar  = $g1_tracer->grammar();

    # Here we access an internal value of the Recognizer class
    # Scanless is, in C++ terms, a friend class of the Recognizer
    my $token_values =
        $thick_g1_recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES];

    # These values are used for diagnostics,
    # so they are initialized here.
    # Event counts are initialized to 0 for "no events, no problems".
    my $lex_event_count = 0;
    my $g1_status  = 0;
    my $problem;

    my @found_lexemes   = ();
    my @locations       = ( [ 0, 0 ] );
    $self->[Marpa::R2::Inner::Scanless::R::LOCATIONS] = \@locations;

    my $class_table =
        $grammar->[Marpa::R2::Inner::Scanless::G::CHARACTER_CLASS_TABLE];

    my $length_of_string     = length ${$p_string};
    my $start_of_next_lexeme = 0;
    my $thin_lex_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THIN_LEX_RECCE];
    $stream->string_set( $p_string );

    READ: while ( $start_of_next_lexeme < $length_of_string ) {

        state $op_alternative = Marpa::R2::Thin::U::op('alternative');
        state $op_earleme_complete =
            Marpa::R2::Thin::U::op('earleme_complete');

        if ( not defined $thin_lex_recce ) {
            $thin_lex_recce = Marpa::R2::Thin::R->new($thin_lex_grammar);
            $thin_lex_recce->start_input();
            $stream->recce_set($thin_lex_recce);
            $stream->pos_set($start_of_next_lexeme);
        } ## end if ( not defined $thin_lex_recce )

        if ( not defined eval { $lex_event_count = $stream->read(); 1 } ) {
            my $problem_symbol = $stream->symbol_id();
            my $symbol_desc =
                $problem_symbol < 0
                ? q{}
                : "Problem was with symbol "
                . $lex_tracer->symbol_name($problem_symbol);
            die "Exception in stream read(): $EVAL_ERROR\n", $symbol_desc;
        } ## end if ( not defined eval { $lex_event_count = $stream->read...})
        if (   $thin_lex_recce->is_exhausted()
            or $lex_event_count == -1
            or $lex_event_count == 0 )
        {
            my $latest_earley_set = $thin_lex_recce->latest_earley_set();
            my $earley_set        = $latest_earley_set;
            my $is_lexeme =
                $grammar->[Marpa::R2::Inner::Scanless::G::IS_LEXEME];
            my %found = ();

            # Do not search Earley set 0 -- we do not care about
            # zero-length lexemes
            EARLEY_SET: while ( $earley_set > 0 ) {
                $thin_lex_recce->progress_report_start($earley_set);
                ITEM: while (1) {
                    my ( $rule_id, $dot_position, $origin ) =
                        $thin_lex_recce->progress_item();
                    last ITEM if not defined $rule_id;
                    next ITEM if $origin != 0;
                    next ITEM if $dot_position != -1;
                    my $lhs_id = $thin_lex_grammar->rule_lhs($rule_id);
                    next ITEM if not $is_lexeme->[$lhs_id];
                    $found{$lhs_id} = 1;
                } ## end ITEM: while (1)
                last EARLEY_SET if scalar %found;
                $earley_set--;
            } ## end EARLEY_SET: while ( $earley_set > 0 )
            if ( not scalar %found ) {
                $g1_status = $lex_event_count = 0;    # lexer was NOT the problem
                $problem = "No lexeme found at position $start_of_next_lexeme";
                last READ;
            }

            my $lexeme_start_pos = $start_of_next_lexeme;
            my $lexeme_end_pos   = $start_of_next_lexeme =
                $lexeme_start_pos + $earley_set;

            @found_lexemes =
                grep { $_ != $g0_discard_symbol_id } keys %found;
            if ( scalar @found_lexemes ) {

                my $raw_token_value = substr ${$p_string}, $lexeme_start_pos, $lexeme_end_pos - $lexeme_start_pos;

                if ($thin_g1_recce->is_exhausted()) {
                    $g1_status = $lex_event_count = 0;    # lexer was NOT the problem
                    $problem = "Parse exhausted, but lexemes remain, at position $lexeme_start_pos\n";
                    last READ;
                }

                if ($trace_terminals) {
                    say {
                        $self->[
                            Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE]
                        } 'Found lexemes @'
                        . $lexeme_start_pos, q{-}, $lexeme_end_pos, q{: },
                        (
                        join q{ },
                        map { $lex_tracer->symbol_name($_) } @found_lexemes
                        ),
                        qq{; value="$raw_token_value"};
                } ## end if ($trace_terminals)

                my $token_ix = -1 + push @{$token_values}, $raw_token_value;

                for my $lexed_symbol_id (@found_lexemes) {
                    my $g1_lexeme = $lexeme_to_g1_symbol->[$lexed_symbol_id];
                    $thin_g1_recce->alternative( $g1_lexeme, $token_ix,
                        1 );
                } ## end for my $lexed_symbol_id (@found_lexemes)
                push @locations, [ $lexeme_start_pos, $lexeme_end_pos ];
                $thin_g1_grammar->throw_set(0);
                $g1_status = $thin_g1_recce->earleme_complete();
                $thin_g1_grammar->throw_set(1);
                LOOK_FOR_G1_PROBLEMS: {
                    if ( defined $g1_status ) {
                        last LOOK_FOR_G1_PROBLEMS if $g1_status == 0;
                        if ( $g1_status > 0 ) {
                            my $significant_problems = 0;
                            my $event_count = $thin_g1_grammar->event_count();
                            for (
                                my $event_ix = 0;
                                $event_ix < $event_count;
                                $event_ix++
                                )
                            {
                                my ($event_type) =
                                    $thin_g1_grammar->event($event_ix);
                                if ( $event_type ne 'MARPA_EVENT_EXHAUSTED' )
                                {
                                    $significant_problems++;
                                }
                            } ## end for ( my $event_ix = 0; $event_ix < $g1_status;...)
                            if ( not $significant_problems ) {
                                $g1_status = 0;
                                last LOOK_FOR_G1_PROBLEMS;
                            }
                        } ## end if ( $g1_status > 0 )
                    } ## end if ( defined $g1_status )

                    # If here, there was a problem
                    $lex_event_count = 0;    # lexer was NOT the problem
                    last READ;
                } ## end LOOK_FOR_G1_PROBLEMS:
            } ## end if ( scalar @found_lexemes )

            $thin_lex_recce  = undef;
            $lex_event_count = 0;

            next READ;
        } ## end if ( $thin_lex_recce->is_exhausted() or $lex_event_count...)
        if ( $lex_event_count == -2 ) {

            # Recover by registering character, if we can
            my $codepoint = $stream->codepoint();
            my @ops;
            for my $entry ( @{$class_table} ) {
                my ( $symbol_id, $re ) = @{$entry};
                if ( chr($codepoint) =~ $re ) {

                    # if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_SL] )
                    if (0) {
                        say {$Marpa::R2::Inner::Scanless::TRACE_FILE_HANDLE}
                            "Registering character ",
                            ( sprintf 'U+%04x', $codepoint ),
                            " as symbol $symbol_id: ",
                            $lex_tracer->symbol_name($symbol_id);
                    } ## end if (0)
                    push @ops, $op_alternative, $symbol_id, 0, 1;
                } ## end if ( chr($codepoint) =~ $re )
            } ## end for my $entry ( @{$class_table} )
            Marpa::R2::exception(
                "Lexing failed at unacceptable character ",
                character_describe( chr $codepoint )
            ) if not @ops;
            $stream->char_register( $codepoint, @ops, $op_earleme_complete );
            next READ;
        } ## end if ( $lex_event_count == -2 )
    } ## end READ: while ( $start_of_next_lexeme < $length_of_string )

    my $pos = $stream->pos();
    return $pos
        if not defined $problem
            and $lex_event_count == 0
            and $g1_status == 0;

    ## If we are here, recovery is a matter for the caller,
    ## if it is possible at all
    my $desc;
    DESC: {
        if (defined $problem) {
            $desc .= "$problem\n";
        }
        if ( $lex_event_count > 0 ) {
            EVENT:
            for (
                my $event_ix = 0;
                $event_ix < $lex_event_count;
                $event_ix++
                )
            {
                my ( $event_type, $value ) =
                    $thin_lex_grammar->event($event_ix);
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
            } ## end EVENT: for ( my $event_ix = 0; $event_ix < $lex_event_count...)
            last DESC;
        } ## end if ( $lex_event_count > 0 )
        if ( $lex_event_count == -1 ) {
            $desc = 'Lexer: Character rejected';
            last DESC;
        }
        if ( $lex_event_count == -2 ) {
            $desc = 'Lexer: Unregistered character';
            last DESC;
        }
        if ( $lex_event_count == -3 ) {
            $desc = 'Unexpected return value from lexer: Parse exhausted';
            last DESC;
        }
        if ($g1_status) {
            my $true_event_count = $thin_g1_grammar->event_count();
            EVENT:
            for (
                my $event_ix = 0;
                $event_ix < $true_event_count;
                $event_ix++
                )
            {
                my ( $event_type, $value ) =
                    $thin_g1_grammar->event($event_ix);
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
                    $desc .= "Parse exhausted";
                    next EVENT;
                }
            } ## end EVENT: for ( my $event_ix = 0; $event_ix < ...)
            last DESC;
        } ## end if ($g1_status)
        if ( $g1_status < 0 ) {
            $desc = 'G1 error: ' . $thin_g1_grammar->error();
            last DESC;
        }
    } ## end DESC:
    my $read_string_error;
    if ($g1_status) {
        my ($pos) = @{ $locations[-1] };
        my $prefix =
            $pos >= 72
            ? ( substr ${$p_string}, $pos - 72, 72 )
            : ( substr ${$p_string}, 0, $pos );
        $read_string_error =
              "Error in Scanless read: G1 $desc\n"
            . "* Error was at string position: $pos\n"
            . '* Error was at lexemes: '
            . ( join q{ },
            map { $lex_tracer->symbol_name($_) } @found_lexemes )
            . "\n"
            . "* String before error:\n"
            . Marpa::R2::escape_string( $prefix, -72 ) . "\n"
            . "* String after error:\n"
            . Marpa::R2::escape_string( ( substr ${$p_string}, $pos, 72 ), 72 )
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
     # Make the thick recognizer the new "self"
     $_[0] = $_[0]->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
     goto &Marpa::R2::Recognizer::value;
}

sub Marpa::R2::Scanless::R::show_progress {
     # Make the thick recognizer the new "self"
     $_[0] = $_[0]->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
     goto &Marpa::R2::Recognizer::show_progress;
}

1;

# vim: expandtab shiftwidth=4:
