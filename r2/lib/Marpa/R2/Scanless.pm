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
$VERSION        = '2.033_002';
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
    INPUT_STRING

    TRACE_FILE_HANDLE
    READ_STRING_ERROR

END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN


package Marpa::R2::Inner::Scanless;
# names of packages for strings
our $G_PACKAGE = 'Marpa::R2::Scanless::G';
our $R_PACKAGE = 'Marpa::R2::Scanless::R';
our $GRAMMAR_LEVEL;
our $TRACE_FILE_HANDLE;

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
    push @{$self->{lex_rules}}, { lhs => '[:discard]', rhs => [$normalized_rhs->name()], mask => [0] };
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
            $rhs = $self->normalize( $rhs);
            my @rhs_names = $rhs->names();
            my @mask      = $rhs->mask();
            my %hash_rule =
                ( lhs => $lhs, rhs => \@rhs_names, mask => \@mask );
            my $action = $adverb_list->{action};
            $hash_rule{action} = $action if defined $action;
            push @{$rules}, \%hash_rule;
        } ## end for my $alternative ( @{ $priorities->[0] } )
        return [@xs_rules];
    }

    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        for my $alternative ( @{ $priorities->[$priority_ix] } ) {
            push @working_rules, [ $priority, @{$alternative} ];
        }
    } ## end for my $priority_ix ( 0 .. $priority_count - 1 )

    state $do_arg0_full_name = __PACKAGE__ . q{::} . 'external_do_arg0';
    # Default mask (all ones) is OK for this rule
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
    RULE: for my $working_rule (@working_rules) {
        my ( $priority, $rhs, $adverb_list ) = @{$working_rule};
        $rhs = $self->normalize($rhs);
        my $assoc = $adverb_list->{assoc} // 'L';
        my @new_rhs = $rhs->names();
        my @arity   = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $length  = scalar @new_rhs;

        my $current_exp = $lhs . '[prec' . $priority . ']';
        my %new_xs_rule = (lhs => $current_exp);
           $new_xs_rule{mask} = [$rhs->mask()];

        my $action = $adverb_list->{action};
        $new_xs_rule{action} = $action if defined $action;

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
    } ## end RULE: for my $rule (@rules)
    return [@xs_rules];
} ## end sub do_priority_rule

sub do_empty_rule {
    my ( $self, $lhs, $op_declare, $adverb_list ) = @_;
    my $action = $adverb_list->{action};
    # mask not needed
    my %rule = ( lhs => $lhs, rhs => []);
    $rule{action} = $action if defined $action;
    if ($op_declare eq q{::=}) {
         return \%rule;
    }
    push @{$self->{lex_rules}}, \%rule;
    return [];
}

sub do_quantified_rule {
    my ( $self, $lhs, $op_declare, $rhs, $quantifier, $adverb_list ) = @_;

    # Some properties of the sequence rule will not be altered
    # no matter how complicated this gets
    my %sequence_rule = (
        rhs => [ $rhs->name() ],
        min => ( $quantifier eq q{+} ? 1 : 0 )
    );
    my $action = $adverb_list->{action};
    $sequence_rule{action} = $action if defined $action;
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

sub create_hidden_internal_symbol {
    my ($self, $symbol_name) = @_;
    $self->{needs_symbol}->{$symbol_name} = 1;
    my $symbol = Marpa::R2::Inner::Scanless::Symbol->new($symbol_name);
    $symbol->hidden_set();
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
        $symbol = create_hidden_internal_symbol($self, $symbol_name);
        $cc_hash->{$symbol_name} = [ $regex, $symbol ];
    } ## end if ( not defined $hash_entry )
    return $symbol;
} ## end sub assign_symbol_by_char_class

sub do_any {
    my $self = shift;
    my $symbol_name = '[:any]';
    return assign_symbol_by_char_class( $self, '[\p{Cn}\P{Cn}]', $symbol_name );
}

sub do_end_of_input {
    my $self = shift;
    return $self->{end_of_input_symbol} //=
        Marpa::R2::Inner::Scanless::Symbol->new('[:$]');
}

sub do_ws { return create_hidden_internal_symbol($_[0], '[:ws]') }
sub do_ws_star { return create_hidden_internal_symbol($_[0], '[:ws*]') }
sub do_ws_plus { return create_hidden_internal_symbol($_[0], '[:ws+]') }

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

sub do_symbol_list { shift; return Marpa::R2::Inner::Scanless::Symbol_List->new(@_) }
sub do_lhs { shift; return $_[0]; }
sub do_rhs {
    shift;
    return Marpa::R2::Inner::Scanless::Symbol_List->new( @_ );
}
sub do_adverb_list { shift; return { map {; @{$_}} @_ } }

sub do_parenthesized_symbol_list {
    my (undef, $list) = @_;
    $list->hidden_set();
    return $list;
} ## end sub do_parenthesized_symbol_list

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
    do_end_of_input              => \&do_end_of_input,
    do_lhs                       => \&do_lhs,
    do_op_declare_bnf            => \&do_op_declare_bnf,
    do_op_declare_match          => \&do_op_declare_match,
    do_op_plus_quantifier        => \&do_op_plus_quantifier,
    do_op_star_quantifier        => \&do_op_star_quantifier,
    do_parenthesized_symbol_list => \&do_parenthesized_symbol_list,
    do_priority_rule             => \&do_priority_rule,
    do_quantified_rule           => \&do_quantified_rule,
    do_rhs                       => \&do_rhs,
    do_rules                     => \&do_rules,
    do_separator_specification   => \&do_separator_specification,
    do_single_quoted_string      => \&do_single_quoted_string,
    do_start_rule                => \&do_start_rule,
    do_symbol                    => \&do_symbol,
    do_symbol_list               => \&do_symbol_list,
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
    my $input = $self->[Marpa::R2::Inner::Scanless::R::INPUT_STRING];
    my $start_position = $locations->[$start]->[0];
    my $end_position = $locations->[$end]->[1];
    return substr $input, $start_position, ($end_position - $start_position);
} ## end sub input_slice

sub scanless_grammar {
    my $grammar = Marpa::R2::Thin::G->new( { if => 1 } );
    my $tracer = Marpa::R2::Thin::Trace->new($grammar);

my @mask_by_rule_id;
my $rule_id;

## The code after this line was automatically generated by aoh_to_thin.pl
## Date: Mon Dec 17 16:23:43 2012
$rule_id = $tracer->rule_new(
    "do_action" => "action",
    "kw_action", "op_arrow", "action_name"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new( undef, "action_name", "bare_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "action_name", "reserved_action_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb_item", "action" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb_item", "group_association" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb_item", "left_association" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb_item", "proper_specification" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb_item", "right_association" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb_item", "separator_specification" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->sequence_new(
    "do_adverb_list" => "adverb_list",
    "adverb_item", { min => 0, }
);
$rule_id =
  $tracer->rule_new( "do_alternative" => "alternative", "rhs", "adverb_list" );
$mask_by_rule_id[$rule_id] = [ 1, 1 ];
$rule_id = $tracer->sequence_new(
    "do_discard_separators" => "alternatives",
    "alternative", { separator => "op_eq_pri", min => 1, proper => 1, }
);
$rule_id = $tracer->rule_new(
    "do_discard_rule" => "discard_rule",
    "kw__discard", "op_declare_match", "single_symbol"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new(
    "do_empty_rule" => "empty_rule",
    "lhs", "op_declare", "adverb_list"
);
$mask_by_rule_id[$rule_id] = [ 1, 1, 1 ];
$rule_id = $tracer->rule_new(
    "do_group_association" => "group_association",
    "kw_assoc", "op_arrow", "kw_group"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->rule_new(
    "do_left_association" => "left_association",
    "kw_assoc", "op_arrow", "kw_left"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->rule_new( "do_lhs" => "lhs", "symbol_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( "do_op_declare_bnf" => "op_declare", "op_declare_bnf" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "do_op_declare_match" => "op_declare",
    "op_declare_match"
);
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->sequence_new(
    "do_discard_separators" => "priorities",
    "alternatives", { separator => "op_tighter", min => 1, proper => 1, }
);
$rule_id = $tracer->rule_new(
    "do_priority_rule" => "priority_rule",
    "lhs", "op_declare", "priorities"
);
$mask_by_rule_id[$rule_id] = [ 1, 1, 1 ];
$rule_id = $tracer->rule_new(
    "do_proper_specification" => "proper_specification",
    "kw_proper", "op_arrow", "boolean"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new(
    "do_quantified_rule" => "quantified_rule",
    "lhs", "op_declare", "single_symbol", "quantifier", "adverb_list"
);
$mask_by_rule_id[$rule_id] = [ 1, 1, 1, 1, 1 ];
$rule_id =
  $tracer->rule_new( "do_op_plus_quantifier" => "quantifier", "op_plus" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( "do_op_star_quantifier" => "quantifier", "op_star" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved_word", "kw_action" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved_word", "kw_assoc" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved_word", "kw_group" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved_word", "kw_left" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved_word", "kw_proper" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved_word", "kw_right" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved_word", "kw_separator" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->sequence_new( "do_rhs" => "rhs", "rhs_primary", { min => 1, } );
$rule_id = $tracer->rule_new( "do_any" => "rhs_primary", "kw__any" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( "do_end_of_input" => "rhs_primary", "kw__end_of_input" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( "do_ws" => "rhs_primary", "kw__ws" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( "do_ws_plus" => "rhs_primary", "kw__ws_plus" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( "do_ws_star" => "rhs_primary", "kw__ws_star" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "do_single_quoted_string" => "rhs_primary",
    "single_quoted_string"
);
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( "do_symbol_list" => "rhs_primary", "single_symbol" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "do_parenthesized_symbol_list" => "rhs_primary",
    "op_lparen", "rhs_primary_list", "op_rparen"
);
$mask_by_rule_id[$rule_id] = [ 0, 1, 0 ];
$rule_id = $tracer->sequence_new(
    "do_symbol_list" => "rhs_primary_list",
    "rhs_primary", { min => 1, }
);
$rule_id = $tracer->rule_new(
    "do_right_association" => "right_association",
    "kw_assoc", "op_arrow", "kw_right"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->rule_new( undef, "rule", "discard_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "empty_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "priority_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "quantified_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "start_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->sequence_new( "do_rules" => "rules", "rule", { min => 1, } );
$rule_id = $tracer->rule_new(
    "do_separator_specification" => "separator_specification",
    "kw_separator", "op_arrow", "single_symbol"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new(
    "do_character_class" => "single_symbol",
    "character_class"
);
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "single_symbol", "symbol" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "do_start_rule" => "start_rule",
    "kw__start", "op_declare", "symbol"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new( "do_symbol" => "symbol", "symbol_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "symbol_name", "bare_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( "do_bracketed_name" => "symbol_name", "bracketed_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "symbol_name", "reserved_word" );
$mask_by_rule_id[$rule_id] = [1];
## The code before this line was automatically generated by aoh_to_thin.pl

    $grammar->start_symbol_set( $tracer->symbol_by_name('rules') );
    $grammar->precompute();
    return {tracer => $tracer, mask_by_rule_id => \@mask_by_rule_id };
} ## end sub scanless_grammar

# 1-based numbering matches vi convention
sub line_column {
   my ($string, $position) = @_;
   my $sub_string = substr $string, 0, $position;
   my $nl_count = $sub_string =~ tr/\n//;
   return (1, length $string) if $nl_count <= 0;
   my $previous_nl = rindex $sub_string, "\n", length $string;
   return ($nl_count+1, ($position-$previous_nl)+1);
}

sub problem_happened_here {
    my ( $string, $position ) = @_;
    my $char = substr $string, $position, 1;
    my $char_in_hex = sprintf '0x%04x', ord $char;
    my $char_desc =
          $char =~ m/[\p{PosixGraph}]/xms
        ? $char
        : '[non-graphic character]';
    my $prefix =
        $position >= 72
        ? ( substr $string, $position - 72, 72 )
        : ( substr $string, 0, $position );

    return
        "* Error was at string position: $position, and at character $char_in_hex, '$char_desc'\n"
        . "* String before error:\n"
        . Marpa::R2::escape_string( $prefix, -72 ) . "\n"
        . "* String after error:\n"
        . Marpa::R2::escape_string( ( substr $string, $position, 72 ), 72 ) . "\n";
} ## end sub problem_happened_here

sub last_rule {
   my ($tracer, $thin_recce, $string, $positions) = @_;
        return input_slice( $string, $positions,
            last_completed_range( $tracer, $thin_recce, 'rule') )
            // 'No rule was completed';
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
    my $compiled_source = rules_add( $self, $rules_source );

    # die Data::Dumper::Dumper($compiled_rules);

    my %lex_args = ();
    $lex_args{$_} = $args->{$_} for qw( trace_file_handle );
    $lex_args{rules} = $compiled_source->{lex_rules};
    state $lex_target_symbol = '[:start_lex]';
    $lex_args{start} = $lex_target_symbol;
    $lex_args{'_internal_'} = 1;
    my $lex_grammar = Marpa::R2::Grammar->new( \%lex_args );
    $lex_grammar->precompute();
    my $lex_tracer     = $lex_grammar->tracer();
    my @is_lexeme      = ();
    my @lexeme_names = keys %{ $compiled_source->{is_lexeme} };
    $is_lexeme[ $lex_tracer->symbol_by_name($_) ] = 1 for @lexeme_names;
    $self->[Marpa::R2::Inner::Scanless::G::IS_LEXEME]         = \@is_lexeme;
    $self->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR] = $lex_grammar;
    my $character_class_hash = $compiled_source->{character_classes};
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
    $g1_args{$_} = $args->{$_}
        for qw( action_object default_action trace_file_handle );
    $g1_args{rules} = $compiled_source->{g1_rules};
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

    return $self;

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

sub rules_add {
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

    state $scanless_grammar = scanless_grammar();
    state $tracer           = $scanless_grammar->{tracer};
    state $mask_by_rule_id  = $scanless_grammar->{mask_by_rule_id};
    state $thin_grammar     = $tracer->grammar();
    my $recce = Marpa::R2::Thin::R->new($thin_grammar);
    $recce->start_input();
    $recce->ruby_slippers_set(1);

    # Zero position must not be used
    my @token_values = (0);

    # Order matters !!!
    my @terminals = ();
    ## This hack makes assumptions about the grammar rules
    RULE:
    for my $rule_id ( grep { $thin_grammar->rule_length($_); }
        0 .. $thin_grammar->highest_rule_id() )
    {
        my ( $lhs, @rhs ) = $tracer->rule($rule_id);
        next RULE
            if Marpa::R2::Grammar::original_symbol_name($lhs) ne
                'reserved_word';
        next RULE if scalar @rhs != 1;
        my $reserved_word =
            Marpa::R2::Grammar::original_symbol_name( $rhs[0] );
        next RULE if 'kw_' ne substr $reserved_word, 0, 3;
        $reserved_word = substr $reserved_word, 3;
        push @terminals,
            [
            'kw_' . $reserved_word,
            qr/$reserved_word\b/xms,
            qq{"$reserved_word" keyword}
            ];
    } ## end for my $rule_id ( grep { $thin_grammar->rule_length($_...)})
    push @terminals,
        [ 'kw__start', qr/ [:] start \b /xms, ':start reserved symbol' ],
        [ 'kw__discard', qr/ [:] discard \b /xms,
        ':discard reserved symbol' ],
        [ 'kw__ws_plus', qr/ [:] ws [+] /xms,    ':ws+ reserved symbol' ],
        [ 'kw__ws_star', qr/ [:] ws [*] /xms,    ':ws* reserved symbol' ],
        [ 'kw__ws',      qr/ [:] ws \b/xms,      ':ws reserved symbol' ],
        [ 'kw__default', qr/ [:] default \b/xms, ':default reserved symbol' ],
        [ 'kw__any',     qr/ [:] any \b/xms,     ':any reserved symbol' ],
        [
        'kw__end_of_input',
        qr/ [:] [\$] /xms,
        q{':$': end_of_input reserved symbol}
        ],
        [ 'op_declare_bnf', qr/::=/xms, 'BNF declaration operator (ws)' ],
        [
        'op_declare_match', qr/[~]/xms,
        'match declaration operator (no ws)'
        ],
        [ 'op_arrow',   qr/=>/xms,     'adverb operator' ],
        [ 'op_lparen',  qr/[(]/xms,    'left parenthesis' ],
        [ 'op_rparen',  qr/[)]/xms,    'right parenthesis' ],
        [ 'op_tighter', qr/[|][|]/xms, 'tighten-precedence operator' ],
        [ 'op_eq_pri',  qr/[|]/xms,    'alternative operator' ],
        [ 'op_plus',    qr/[+]/xms,    'plus quantification operator' ],
        [ 'op_star',    qr/[*]/xms,    'star quantification operator' ],
        [ 'boolean',    qr/[01]/xms ],
        [ 'bare_name',  qr/\w+/xms, ],
        [ 'bracketed_name',       qr/ [<] [\s\w]+ [>] /xms, ],
        [ 'reserved_action_name', qr/(::(whatever|undef))/xms ],
        ## no escaping or internal newlines, and disallow empty string
        [
        'single_quoted_string',
        qr/ ['] [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]+ ['] /xms
        ],
        [
        'character_class',
        qr/ (?: (?: \[) (?: [^\\\[]* (?: \\. [^\\\]]* )* ) (?: \]) ) /xms,
        'character class'
        ],
        ;

    my $rules_source = ${$p_rules_source};
    my $length       = length $rules_source;
    pos $rules_source = 0;
    my $latest_earley_set_ID = 0;
    TOKEN: while ( pos $rules_source < $length ) {

        # skip comment
        next TOKEN if $rules_source =~ m/\G \s* [#] [^\n]* \n/gcxms;

        # skip whitespace
        next TOKEN if $rules_source =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $rules_source =~ m/\G($t->[1])/gcxms;
            my $value_number = -1 + push @token_values, $1;
            my $rules_source_position = pos $rules_source;
            if ($recce->alternative( $tracer->symbol_by_name( $t->[0] ),
                    $value_number, 1 ) != $Marpa::R2::Error::NONE
                )
            {
                my $problem_position = $positions[-1];
                my ( $line, $column ) =
                    line_column( $rules_source, $problem_position );
                die qq{MARPA PARSE ABEND at line $line, column $column:\n},
                    qq{=== Last rule that Marpa successfully parsed was: },
                    last_rule( $tracer, $recce, $rules_source, \@positions ),
                    "\n",
                    problem_happened_here( $rules_source, $problem_position ),
                    qq{=== Marpa rejected token, "$1", },
                    ( $t->[2] // $t->[0] ), "\n";
            } ## end if ( $recce->alternative( $tracer->symbol_by_name( $t...)))
            $recce->earleme_complete();
            $latest_earley_set_ID = $recce->latest_earley_set();
            $positions[$latest_earley_set_ID] = $rules_source_position;
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $rules_source, pos $rules_source, 40 ),
            q{", position }, pos $rules_source, "\n";
    } ## end TOKEN: while ( pos $rules_source < $length )

    $thin_grammar->throw_set(0);
    my $bocage = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
    $thin_grammar->throw_set(1);
    if ( !defined $bocage ) {
        die qq{Last rule successfully parsed was: },
            last_rule( $tracer, $recce, $rules_source, \@positions ),
            'Parse failed';
    }

    my $order = Marpa::R2::Thin::O->new($bocage);
    my $tree  = Marpa::R2::Thin::T->new($order);
    $tree->next();
    my $valuator = Marpa::R2::Thin::V->new($tree);
    my @actions_by_rule_id;
    for my $rule_id ( grep { $thin_grammar->rule_length($_); }
        0 .. $thin_grammar->highest_rule_id() )
    {
        $valuator->rule_is_valued_set( $rule_id, 1 );
        $actions_by_rule_id[$rule_id] = $tracer->action($rule_id);
    } ## end for my $rule_id ( grep { $thin_grammar->rule_length($_...)})

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

            my @args = @stack[ $arg_0 .. $arg_n ];
            if ( not defined $thin_grammar->sequence_min($rule_id) ) {
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
        map { ; { lhs => '[:start_lex]', rhs => [$_] } } keys %lexemes;

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

sub Marpa::R2::Scanless::R::new {
    my ( $class, $args ) = @_;

    my $self = [];
    bless $self, $class;

    my $grammar = $args->{grammar};
    if ( not defined $grammar ) {
        Marpa::R2::exception(
            'Marpa::R2::Scanless::R::new() called without a "grammar" argument'
        );
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
    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE] =
        Marpa::R2::Recognizer->new( { grammar => $thick_g1_grammar } );

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
     my ($self, $string) = @_;

    Marpa::R2::exception("Multiple read()'s tried on a scannerless recognizer\n",
    "  Currently only a single scannerless read is allowed")
        if defined $self->[Marpa::R2::Inner::Scanless::R::INPUT_STRING];

    $self->[Marpa::R2::Inner::Scanless::R::INPUT_STRING] = $string;

    my $stream  = $self->[Marpa::R2::Inner::Scanless::R::STREAM];
    my $grammar  = $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thick_lex_grammar  = $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $lex_tracer       = $thick_lex_grammar->tracer();
    my $thin_lex_grammar  = $lex_tracer->grammar();
    my $g0_discard_symbol_id = $grammar->[Marpa::R2::Inner::Scanless::G::G0_DISCARD_SYMBOL_ID];
    my $lexeme_to_g1_symbol = $grammar->[Marpa::R2::Inner::Scanless::G::LEXEME_TO_G1_SYMBOL] ;
    my $thick_g1_recce = $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce = $thick_g1_recce->thin();
    my $thick_g1_grammar = $thick_g1_recce->grammar();
    my $thin_g1_grammar = $thick_g1_grammar->thin();

    # Here we access an internal value of the Recognizer class
    # Scanless is, in C++ terms, a friend class of the Recognizer
    my $token_values = $thick_g1_recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES];


    # These values are used for diagnostics,
    # so they are initialized here.
    # Event counts are initialized to 0 for "no events, no problems".
    my $lex_event_count = 0;
    my $g1_event_count = 0;
    my @found_lexemes = ();
    my @locations = ([0, 0]);
    $self->[Marpa::R2::Inner::Scanless::R::LOCATIONS] = \@locations;

    my $class_table =
        $grammar->[Marpa::R2::Inner::Scanless::G::CHARACTER_CLASS_TABLE];

    my $start_of_next_lexeme = 0;
    $stream->string_set(\$string);
    my $thin_lex_recce = $self->[Marpa::R2::Inner::Scanless::R::THIN_LEX_RECCE];
    READ: {
        state $op_alternative = Marpa::R2::Thin::U::op('alternative');
        state $op_earleme_complete =
            Marpa::R2::Thin::U::op('earleme_complete');
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
                Marpa::R2::exception( 'No lexeme found in ', $string );
            }

            my $lexeme_start_pos = $start_of_next_lexeme;
            my $lexeme_end_pos   = $start_of_next_lexeme =
                $lexeme_start_pos + $earley_set;

            @found_lexemes =
                grep { $_ != $g0_discard_symbol_id } keys %found;
            if ( scalar @found_lexemes ) {

                say STDERR 'Found lexemes @' . $lexeme_start_pos, q{-},
                    $lexeme_end_pos, q{: }, join q{ },
                    map { $lex_tracer->symbol_name($_) } @found_lexemes;

                for my $lexed_symbol_id (@found_lexemes) {
                    my $g1_lexeme = $lexeme_to_g1_symbol->[$lexed_symbol_id];
                    my $token_value = -1 + push @{$token_values},
                        (
                        substr $string,
                        $lexeme_start_pos, $lexeme_end_pos - $lexeme_start_pos
                        );
                    $thin_g1_recce->alternative( $g1_lexeme, $token_value,
                        1 );
                } ## end for my $lexed_symbol_id (@found_lexemes)
                push @locations, [ $lexeme_start_pos, $lexeme_end_pos ];
                $thin_g1_grammar->throw_set(0);
                $g1_event_count = $thin_g1_recce->earleme_complete();
                $thin_g1_grammar->throw_set(1);
                if (not defined $g1_event_count or $g1_event_count != 0) {
                    $lex_event_count = 0; # lexer was NOT the problem
                    last READ;
                }
            } ## end if ( scalar @found_lexemes )
            last READ if $lex_event_count == 0;

            $lex_event_count = 0;
            $thin_lex_recce =
                $self->[Marpa::R2::Inner::Scanless::R::THIN_LEX_RECCE] =
                Marpa::R2::Thin::R->new($thin_lex_grammar);
            $thin_lex_recce->start_input();
            $stream->recce_set($thin_lex_recce);
            $stream->pos_set($start_of_next_lexeme);

            redo READ;
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
            die sprintf "Cannot read character U+%04x: %c\n", $codepoint,
                $codepoint
                if not @ops;
            $stream->char_register( $codepoint, @ops, $op_earleme_complete );
            redo READ;
        } ## end if ( $lex_event_count == -2 )
    } ## end READ:

    my $pos = $stream->pos();
    return $pos if $lex_event_count == 0 and $g1_event_count == 0;

    ## If we are here, recovery is a matter for the caller,
    ## if it is possible at all
    my $desc;
    DESC: {
        if ( $lex_event_count > 0 ) {
            EVENT:
            for ( my $event_ix = 0; $event_ix < $lex_event_count; $event_ix++ ) {
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
            } ## end EVENT: for ( my $event_ix = 0; $event_ix < $lex_event_count; ...)
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
        if ($g1_event_count) {
            my $true_event_count = $thin_lex_grammar->event_count();
            EVENT:
            for (my $event_ix = 0; $event_ix < $true_event_count; $event_ix++) {
                my ( $event_type, $value ) = $thin_lex_grammar->event($event_ix);
                if ( $event_type eq 'MARPA_EVENT_EARLEY_ITEM_THRESHOLD' ) {
                    $desc
                        .= "G1 grammar: Earley item count ($value) exceeds warning threshold\n";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                    $desc .= "Unexpected G1 grammar event: $event_type "
                        . $lex_tracer->symbol_name($value) . "\n";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                    $desc .= "Parse exhausted: lexemes were " . join q{ },
                        map { $lex_tracer->symbol_name($_) } @found_lexemes;
                    next EVENT;
                }
            } ## end EVENT: while (1)
            last DESC;
        } ## end if ($g1_event_count)
        if ( $g1_event_count < 0 ) {
            $desc = 'G1 error: ' . $thin_g1_grammar->error();
            last DESC;
        }
    } ## end DESC:
    my $char = substr $string, $pos, 1;
    my $char_in_hex = sprintf '0x%04x', ord $char;
    my $char_desc =
          $char =~ m/[\p{PosixGraph}]/xms
        ? $char
        : '[non-graphic character]';
    my $prefix =
        $pos >= 72
        ? ( substr $string, $pos - 72, 72 )
        : ( substr $string, 0, $pos );

    my $read_string_error =
        $self->[Marpa::R2::Inner::Scanless::R::READ_STRING_ERROR] =
          "Error in string_read: $desc\n"
        . "* Error was at string position: $pos, and at character $char_in_hex, '$char_desc'\n"
        . "* String before error:\n"
        . Marpa::R2::escape_string( $prefix, -72 ) . "\n"
        . "* String after error:\n"
        . Marpa::R2::escape_string( ( substr $string, $pos, 72 ), 72 ) . "\n";
    Marpa::R2::exception($read_string_error) if $lex_event_count == -3;

    # Fall through to return undef
    return;

}

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
