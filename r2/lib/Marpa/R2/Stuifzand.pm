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
$VERSION        = '2.033_000';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::Stuifzand::Symbol;

use constant NAME => 0;
use constant HIDE => 1;

sub new { my $class = shift; return bless { name => $_[NAME], is_hidden => ($_[HIDE]//0) }, $class }
sub name { return $_[0]->{name} }
sub names { return $_[0]->{name} }
sub is_hidden { return $_[0]->{is_hidden} }
sub hidden_set { $_[0]->{is_hidden} = 1; }
sub symbols { return $_[0]; }

package Marpa::R2::Internal::Stuifzand::Symbol_List;

sub new { my $class = shift; return bless [@_], $class }

sub names {
    return map { $_->names() } @{ $_[0] };
}
sub is_hidden {
    return map { $_->is_hidden() } @{ $_[0] };
}

sub hidden_set {
     $_->hidden_set() for @ { $_[0] };
}

sub mask {
    return map { $_ ? 0 : 1 } map { $_->is_hidden() } @{ $_[0] };
}

sub symbols {
    return map { $_->symbols() } @{ $_[0] };
}

package Marpa::R2::Internal::Stuifzand;

use English qw( -no_match_vars );

# Internal names end in ']' and are distinguished by prefix.
#
# Suffixed with '[prec%d]' --
# a symbol created to implement precedence.
# Suffix is removed to restore 'original'.
#
# Prefixed with '[[' -- a character class
# These are their own 'original'.
#
# Prefixed with '[:' -- a reserved symbol, one which in the
# grammars start with a colon.
# These are their own 'original'.
# The names tend to be suggested by the corresponding
# symbols in Perl 6.  Among them:
#     [:$] -- end of input
#     [:|w] -- word boundary
#
# Prefixed with '[SYMBOL#' - a unnamed internal symbol.
# Seeing these
# indicates some sort of internal error.  If seen,
# they will be treated as their own original.
# 
# Suffixed with '[Sep]' indicates an internal version
# of a sequence separator.  These are their own
# original, because otherwise the "original" name
# would conflict with the LHS of the sequence.
# 
# Suffixed with '[SeqLHS]' indicates an internal version
# of the sequence LHS.  The "original" name is that
# of the LHS of the sequence.

# Undo any rewrite of the symbol name
sub Marpa::R2::Grammar::original_symbol_name {
   $_[0] =~ s/\[ prec \d+ \] \z//xms;
   $_[0] =~ s/\[ SeqLHS \] \z//xms;
   return shift;
}

# This rule is used by the semantics of the *GENERATED*
# grammars, not the Stuifzand grammar itself.
sub external_do_arg0 {
   return $_[1];
}

sub do_rules {
    shift;
    # Assume whitespace and only whitespace is undef
    return [ map { @{$_} } grep { defined } @_ ];
}

sub do_start_rule {
    my ( $self, $op_declare, $rhs ) = @_;
    my $thick_grammar = $self->{thick_grammar};
    die ':start not allowed unless grammar is scannerless'
        if not $thick_grammar->[Marpa::R2::Internal::Grammar::SCANNERLESS];
    my @ws      = ();
    my @mask_kv = ();
    my @rhs = ();
    if ( $op_declare eq q{::=} ) {
        my $ws_star = '[:ws*]';
        $self->{needs_symbol}->{$ws_star} = 1;
        my $end_of_input = '[:$]';
        $self->{needs_symbol}->{$end_of_input} = 1;
        push @ws, $ws_star;
        @rhs = ( $ws_star, $rhs, $ws_star, $end_of_input );
        push @mask_kv, mask => [ 0, 1, 0, 0 ];
    } else {
        @rhs = ( $rhs );
    }
    return [ { lhs => '[:start]', rhs => \@rhs, @mask_kv } ];
} ## end sub do_start_rule

sub do_comment_rule {
    my ( $self, $rhs ) = @_;
    my $thick_grammar = $self->{thick_grammar};
    die ':comment not allowed unless grammar is scannerless'
        if not $thick_grammar->[Marpa::R2::Internal::Grammar::SCANNERLESS];
    $self->{needs_symbol}->{'[:Space]'} = 1;
    return [ { lhs => '[:Space]', rhs => [$rhs->name()], mask => [0] }, ];
} ## end sub do_comment_rule

# From least to most restrictive
my @ws_by_rank = qw( [:ws*] [:ws] [:ws+] );
my %rank_by_ws = map { $ws_by_rank[$_] => $_ } 0 .. $#ws_by_rank;

sub add_ws_to_alternative {
    my ( $self, $alternative ) = @_;
    my ( $rhs,  $adverb_list ) = @{$alternative};
    state $default_ws_symbol =
        create_hidden_internal_symbol( $self, '[:ws]' );

    # Do not add initial whitespace
    my $slot_for_ws = 0;
    my @new_symbols = ();
    SYMBOL: for my $symbol ( $rhs->symbols() ) {
        my $symbol_name = $symbol->name();
        if ( defined $rank_by_ws{$symbol_name} ) {
            push @new_symbols, $symbol;
            $slot_for_ws = 0;    # already has ws in this slot
            next SYMBOL;
        }
        if ($slot_for_ws) {
            ## Not a whitespace symbol, but this is a slot
            ## for whitespace, so add it
            push @new_symbols, $default_ws_symbol;
        }
        push @new_symbols, $symbol;
        $slot_for_ws = $symbol->{ws_after_ok} // 1;
    } ## end SYMBOL: for my $symbol ( $rhs->symbols() )
    $alternative->[0] =
        Marpa::R2::Internal::Stuifzand::Symbol_List->new(@new_symbols);
    return $alternative;
} ## end sub add_ws_to_alternative

sub do_priority_rule {
    my ( $self, $lhs, $op_declare, $priorities ) = @_;
    my $thick_grammar = $self->{thick_grammar};
    my $add_ws = $thick_grammar->[Marpa::R2::Internal::Grammar::SCANNERLESS]
        && $op_declare eq q{::=};
    my $priority_count = scalar @{$priorities};
    my @rules          = ();
    my @xs_rules = ();

    ## First check for consecutive whitespace specials
    RHS: for my $rhs ( map { $_->[0] } map { @{$_} } @{$priorities} ) {
        my @rhs_names = $rhs->names();
        my $penult    = $#rhs_names - 1;
        next RHS if $penult < 0;
        for my $rhs_ix ( 0 .. $penult ) {
            if (   defined $rank_by_ws{ $rhs_names[$rhs_ix] }
                && defined $rank_by_ws{ $rhs_names[ $rhs_ix + 1 ] } )
            {
                die
                    "Two consecutive whitespace special symbols were found in a RHS:\n",
                    q{  }, ( join q{ }, $lhs, $op_declare, $rhs->names() ),
                    "\n",
                    "  Consecutive whitespace specials are confusing and are not allowed\n";
            } ## end if ( defined $rank_by_ws{ $rhs_names[$rhs_ix] } && ...)
        } ## end for my $rhs_ix ( 0 .. $penult )
    } ## end for my $rhs ( map { $_->[0] } map { @{$_} } @{$priorities...})

    if ( $priority_count <= 1 ) {
        ## If there is only one priority
        for my $alternative ( @{ $priorities->[0] } ) {
            add_ws_to_alternative($self, $alternative) if $add_ws;
            my ( $rhs, $adverb_list ) = @{$alternative};
            my @rhs_names = $rhs->names();
            my @mask      = $rhs->mask();
            my %hash_rule =
                ( lhs => $lhs, rhs => \@rhs_names, mask => \@mask );
            my $action = $adverb_list->{action};
            $hash_rule{action} = $action if defined $action;
            push @xs_rules, \%hash_rule;
        } ## end for my $alternative ( @{ $priorities->[0] } )
        return [@xs_rules];
    }

    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        for my $alternative ( @{ $priorities->[$priority_ix] } ) {
            add_ws_to_alternative($self, $alternative) if $add_ws;
            push @rules, [ $priority, @{$alternative} ];
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
    RULE: for my $rule (@rules) {
        my ( $priority, $rhs, $adverb_list ) = @{$rule};
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
    # mask not needed
    return [ { lhs => $lhs, rhs => [], defined($action) ? (action => $action) : () } ];
}

sub do_quantified_rule {
    my ( $self, $lhs, $op_declare, $rhs, $quantifier, $adverb_list ) = @_;
    my $thick_grammar = $self->{thick_grammar};

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
    if ( $op_declare ne q{::=}
        or not $thick_grammar->[Marpa::R2::Internal::Grammar::SCANNERLESS] )
    {
        # mask not needed
        $sequence_rule{lhs}       = $lhs;
        $sequence_rule{separator} = $original_separator
            if defined $original_separator;
        my $proper = $adverb_list->{proper};
        $sequence_rule{proper} = $proper if defined $proper;
        return \@rules;
    } ## end if ( $op_declare ne q{::=} or not $thick_grammar->[...])

    # If here, we are adding whitespace

    state $do_arg0_full_name = __PACKAGE__ . q{::} . 'external_do_arg0';
    state $default_ws_symbol =
        create_hidden_internal_symbol( $self, '[:ws]' );
    my $new_separator = $lhs . '[Sep]';
    my @separator_rhs = ('[:ws]');
    push @separator_rhs, $original_separator, '[:ws]'
        if defined $original_separator;
    my %separator_rule = (
        lhs    => $new_separator,
        rhs    => \@separator_rhs,
        mask   => [ (0) x scalar @separator_rhs ],
        action => '::whatever'
    );
    push @rules, \%separator_rule;

    # With the new separator,
    # we know a few more things about the sequence rule
    $sequence_rule{proper}    = 1;
    $sequence_rule{separator} = $new_separator;

    if ( not defined $original_separator || $adverb_list->{proper} ) {

        # If originally no separator or proper separation,
        # we are pretty much done
        $sequence_rule{lhs} = $lhs;
        return \@rules;
    } ## end if ( not defined $original_separator || $adverb_list...)

    ## If here, Perl separation
    ## We need two more rules and a new LHS for the
    ## sequence rule
    my $sequence_lhs = $lhs . '[SeqLHS]';
    $sequence_rule{lhs} = $sequence_lhs;
    push @rules,
        {
        lhs    => $lhs,
        rhs    => [$sequence_lhs],
        action => $do_arg0_full_name,
        mask => [1]
        },
        {
        lhs    => $lhs,
        rhs    => [ $sequence_lhs, '[:ws]', $original_separator ],
        mask   => [ 1, 0, 0 ],
        action => $do_arg0_full_name,
        };

    return \@rules;

} ## end sub do_quantified_rule

sub create_hidden_internal_symbol {
    my ($self, $symbol_name) = @_;
    $self->{needs_symbol}->{$symbol_name} = 1;
    my $symbol = Marpa::R2::Internal::Stuifzand::Symbol->new($symbol_name);
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
        Marpa::R2::Internal::Stuifzand::Symbol->new('[:$]');
}

sub do_ws { return create_hidden_internal_symbol($_[0], '[:ws]') }
sub do_ws_star { return create_hidden_internal_symbol($_[0], '[:ws*]') }
sub do_ws_plus { return create_hidden_internal_symbol($_[0], '[:ws+]') }

sub do_symbol {
    shift;
    return Marpa::R2::Internal::Stuifzand::Symbol->new( $_[0] );
}

sub do_character_class {
    my ( $self, $char_class ) = @_;
    return assign_symbol_by_char_class($self, $char_class);
} ## end sub do_character_class

sub do_symbol_list { shift; return Marpa::R2::Internal::Stuifzand::Symbol_List->new(@_) }
sub do_lhs { shift; return $_[0]; }

sub do_rhs {
    shift;
    # Assume whitespace and only whitespace is undef
    return Marpa::R2::Internal::Stuifzand::Symbol_List->new(
        map { $_->symbols() } grep { defined } @_ );
}
sub do_adverb_list {
    shift;
    # Assume whitespace and only whitespace is undef
    return { map { ; @{$_} } grep { defined } @_ };
}

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
        $symbol->{ws_after_ok} = 0;
        push @symbols, $symbol;
    }
    $symbol->{ws_after_ok} = 1; # OK to add WS after last symbol
    my $list = Marpa::R2::Internal::Stuifzand::Symbol_List->new(@symbols);
    $list->hidden_set();
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
    do_comment_rule              => \&do_comment_rule,
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

# Given a grammar,
# a recognizer and a symbol
# return the start and end earley sets
# of the last such symbol completed,
# undef if there was none.
sub last_completed_range {
    my ( $self, $symbol_name ) = @_;
    my $tracer = $self->{tracer};
    my $thin_grammar = $tracer->grammar();
    my $thin_recce = $self->{recce};
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

my @mask_by_rule_id;
my @character_class_table = ();
my $rule_id;
my $symbol_id;

## The code after this line was automatically generated by aoh_to_thin.pl
## Date: Sun Dec  9 18:22:12 2012
$symbol_id = $tracer->symbol_new("\[\[\ \\w\]\]");
push @character_class_table, [ $symbol_id, qr/[ \w]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\'\]\]");
push @character_class_table, [ $symbol_id, qr/[']/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\#\]\]");
push @character_class_table, [ $symbol_id, qr/[\#]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\$\]\]");
push @character_class_table, [ $symbol_id, qr/[\$]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\(\]\]");
push @character_class_table, [ $symbol_id, qr/[\(]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\)\]\]");
push @character_class_table, [ $symbol_id, qr/[\)]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\*\]\]");
push @character_class_table, [ $symbol_id, qr/[\*]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\+\]\]");
push @character_class_table, [ $symbol_id, qr/[\+]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\:\]\]");
push @character_class_table, [ $symbol_id, qr/[\:]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\<\]\]");
push @character_class_table, [ $symbol_id, qr/[\<]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\=\]\]");
push @character_class_table, [ $symbol_id, qr/[\=]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\>\]\]");
push @character_class_table, [ $symbol_id, qr/[\>]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\[\]\]");
push @character_class_table, [ $symbol_id, qr/[\[]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\\\]\]");
push @character_class_table, [ $symbol_id, qr/[\\]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\]\]\]");
push @character_class_table, [ $symbol_id, qr/[\]]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\d\+\]\]");
push @character_class_table, [ $symbol_id, qr/[\d+]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\p\{White_Space\}\]\]");
push @character_class_table, [ $symbol_id, qr/[\p{White_Space}]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\w\]\]");
push @character_class_table, [ $symbol_id, qr/[\w]/xms ];
$symbol_id = $tracer->symbol_new(
    "\[\[\\x\{A\}\\x\{B\}\\x\{C\}\\x\{D\}\\x\{2028\}\\x\{2029\}\]\]");
push @character_class_table,
  [ $symbol_id, qr/[\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\|\]\]");
push @character_class_table, [ $symbol_id, qr/[\|]/xms ];
$symbol_id = $tracer->symbol_new("\[\[\\\~\]\]");
push @character_class_table, [ $symbol_id, qr/[\~]/xms ];
$symbol_id = $tracer->symbol_new(
"\[\[\^\'\\x\{0A\}\\x\{0B\}\\x\{0C\}\\x\{0D\}\\x\{0085\}\\x\{2028\}\\x\{2029\}\]\]"
);
push @character_class_table,
  [ $symbol_id, qr/[^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]/xms ];
$symbol_id = $tracer->symbol_new(
"\[\[\^\\x\{5d\}\\x\{0A\}\\x\{0B\}\\x\{0C\}\\x\{0D\}\\x\{0085\}\\x\{2028\}\\x\{2029\}\]\]"
);
push @character_class_table,
  [
    $symbol_id, qr/[^\x{5d}\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]/xms
  ];
$symbol_id = $tracer->symbol_new(
    "\[\[\^\\x\{A\}\\x\{B\}\\x\{C\}\\x\{D\}\\x\{2028\}\\x\{2029\}\]\]");
push @character_class_table,
  [ $symbol_id, qr/[^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]/xms ];
$symbol_id = $tracer->symbol_new("\[\[a\]\]");
push @character_class_table, [ $symbol_id, qr/[a]/xms ];
$symbol_id = $tracer->symbol_new("\[\[c\]\]");
push @character_class_table, [ $symbol_id, qr/[c]/xms ];
$symbol_id = $tracer->symbol_new("\[\[d\]\]");
push @character_class_table, [ $symbol_id, qr/[d]/xms ];
$symbol_id = $tracer->symbol_new("\[\[e\]\]");
push @character_class_table, [ $symbol_id, qr/[e]/xms ];
$symbol_id = $tracer->symbol_new("\[\[f\]\]");
push @character_class_table, [ $symbol_id, qr/[f]/xms ];
$symbol_id = $tracer->symbol_new("\[\[g\]\]");
push @character_class_table, [ $symbol_id, qr/[g]/xms ];
$symbol_id = $tracer->symbol_new("\[\[h\]\]");
push @character_class_table, [ $symbol_id, qr/[h]/xms ];
$symbol_id = $tracer->symbol_new("\[\[i\]\]");
push @character_class_table, [ $symbol_id, qr/[i]/xms ];
$symbol_id = $tracer->symbol_new("\[\[l\]\]");
push @character_class_table, [ $symbol_id, qr/[l]/xms ];
$symbol_id = $tracer->symbol_new("\[\[m\]\]");
push @character_class_table, [ $symbol_id, qr/[m]/xms ];
$symbol_id = $tracer->symbol_new("\[\[n\]\]");
push @character_class_table, [ $symbol_id, qr/[n]/xms ];
$symbol_id = $tracer->symbol_new("\[\[o\]\]");
push @character_class_table, [ $symbol_id, qr/[o]/xms ];
$symbol_id = $tracer->symbol_new("\[\[p\]\]");
push @character_class_table, [ $symbol_id, qr/[p]/xms ];
$symbol_id = $tracer->symbol_new("\[\[r\]\]");
push @character_class_table, [ $symbol_id, qr/[r]/xms ];
$symbol_id = $tracer->symbol_new("\[\[s\]\]");
push @character_class_table, [ $symbol_id, qr/[s]/xms ];
$symbol_id = $tracer->symbol_new("\[\[t\]\]");
push @character_class_table, [ $symbol_id, qr/[t]/xms ];
$symbol_id = $tracer->symbol_new("\[\[u\]\]");
push @character_class_table, [ $symbol_id, qr/[u]/xms ];
$symbol_id = $tracer->symbol_new("\[\[v\]\]");
push @character_class_table, [ $symbol_id, qr/[v]/xms ];
$symbol_id = $tracer->symbol_new("\[\[w\]\]");
push @character_class_table, [ $symbol_id, qr/[w]/xms ];
$symbol_id = $tracer->symbol_new("\[\[y\]\]");
push @character_class_table, [ $symbol_id, qr/[y]/xms ];
$rule_id =
  $tracer->rule_new( undef, "\[\:Space\]", "\[\[\\p\{White_Space\}\]\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new( undef, "\[\:Space\]", "hash\ comment" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id =
  $tracer->rule_new( undef, "\[\:start\]", "\[\:ws\*\]", "rules", "\[\:ws\*\]",
    "\[\:\$\]" );
$mask_by_rule_id[$rule_id] = [ 0, 1, 0, 0 ];
$rule_id =
  $tracer->sequence_new( undef, "\[\:ws\*\]", "\[\:Space\]", { min => 0, } );
$rule_id =
  $tracer->sequence_new( undef, "\[\:ws\+\]", "\[\:Space\]", { min => 1, } );
$rule_id = $tracer->rule_new( undef, "\[\:ws\]", "\[\:ws\+\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new( undef, "\[\:ws\]", "\[\:\|w\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new(
    "do_action" => "action",
    "\[\[a\]\]", "\[\[c\]\]", "\[\[t\]\]",    "\[\[i\]\]",    "\[\[o\]\]",
    "\[\[n\]\]", "\[\:ws\]",  "\[\[\\\=\]\]", "\[\[\\\>\]\]", "\[\:ws\]",
    "action_name"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ];
$rule_id = $tracer->rule_new( undef, "action_name", "bare_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    undef,       "action_name", "\[\[\\\:\]\]", "\[\[\\\:\]\]",
    "\[\[u\]\]", "\[\[n\]\]",   "\[\[d\]\]",    "\[\[e\]\]",
    "\[\[f\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0 ];
$rule_id = $tracer->rule_new(
    undef,       "action_name", "\[\[\\\:\]\]", "\[\[\\\:\]\]",
    "\[\[w\]\]", "\[\[h\]\]",   "\[\[a\]\]",    "\[\[t\]\]",
    "\[\[e\]\]", "\[\[v\]\]",   "\[\[e\]\]",    "\[\[r\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
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
    "adverb_item", { separator => "adverb_list\[Sep\]", min => 0, proper => 1, }
);
$rule_id =
  $tracer->rule_new( "\:\:whatever" => "adverb_list\[Sep\]", "\[\:ws\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new(
    "do_alternative" => "alternative",
    "rhs", "\[\:ws\]", "adverb_list"
);
$mask_by_rule_id[$rule_id] = [ 1, 0, 1 ];
$rule_id = $tracer->rule_new(
    "Marpa\:\:R2\:\:Internal\:\:Stuifzand\:\:external_do_arg0" =>
      "alternatives",
    "alternatives\[SeqLHS\]"
);
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "Marpa\:\:R2\:\:Internal\:\:Stuifzand\:\:external_do_arg0" =>
      "alternatives",
    "alternatives\[SeqLHS\]", "\[\:ws\]", "op_eq_pri"
);
$mask_by_rule_id[$rule_id] = [ 1, 0, 0 ];
$rule_id = $tracer->rule_new(
    "\:\:whatever" => "alternatives\[Sep\]",
    "\[\:ws\]", "op_eq_pri", "\[\:ws\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->sequence_new(
    "do_discard_separators" => "alternatives\[SeqLHS\]",
    "alternative",
    { separator => "alternatives\[Sep\]", min => 1, proper => 1, }
);
$rule_id = $tracer->sequence_new(
    "do_literal" => "bare_name",
    "\[\[\\w\]\]", { min => 1, }
);
$rule_id = $tracer->sequence_new(
    "do_literal" => "boolean",
    "\[\[\\d\+\]\]", { min => 1, }
);
$rule_id =
  $tracer->rule_new( undef, "cc\ character", "escaped\ cc\ character" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "cc\ character", "safe\ cc\ character" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "cc\ string", "cc\ character" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "do_literal" => "character\ class",
    "\[\[\\\[\]\]", "cc\ string", "\[\[\\\]\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 1, 0 ];
$rule_id = $tracer->rule_new(
    "do_comment_rule" => "comment_rule",
    "\[\[\\\:\]\]", "\[\[c\]\]", "\[\[o\]\]", "\[\[m\]\]", "\[\[m\]\]",
    "\[\[e\]\]",    "\[\[n\]\]", "\[\[t\]\]", "\[\:ws\]",  "\[\[\\\~\]\]",
    "\[\:ws\]",     "single_symbol"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ];
$rule_id = $tracer->rule_new(
    "do_empty_rule" => "empty_rule",
    "lhs", "\[\:ws\]", "op_declare", "\[\:ws\]", "adverb_list"
);
$mask_by_rule_id[$rule_id] = [ 1, 0, 1, 0, 1 ];
$rule_id = $tracer->rule_new(
    undef,          "escaped\ cc\ character",
    "\[\[\\\\\]\]", "horizontal\ character"
);
$mask_by_rule_id[$rule_id] = [ 0, 1 ];
$rule_id = $tracer->rule_new(
    "do_group_association" => "group_association",
    "\[\[a\]\]", "\[\[s\]\]", "\[\[s\]\]", "\[\[o\]\]", "\[\[c\]\]", "\[\:ws\]",
    "\[\[\\\=\]\]", "\[\[\\\>\]\]", "\[\:ws\]", "\[\[g\]\]", "\[\[r\]\]",
    "\[\[o\]\]", "\[\[u\]\]", "\[\[p\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
$rule_id = $tracer->rule_new(
    undef, "hash\ comment",
    "\[\[\\\#\]\]",
    "hash\ comment\ body",
    "hash\ comment\ end"
);
$mask_by_rule_id[$rule_id] = [ 0, 1, 1 ];
$rule_id = $tracer->sequence_new(
    undef,
    "hash\ comment\ body",
    "horizontal\ character",
    { min => 0, }
);
$rule_id = $tracer->rule_new( undef, "hash\ comment\ end", "\[\:\$\]" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( undef, "hash\ comment\ end", "vertical\ space\ char" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    undef,
    "horizontal\ character",
    "\[\[\^\\x\{A\}\\x\{B\}\\x\{C\}\\x\{D\}\\x\{2028\}\\x\{2029\}\]\]"
);
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new(
    "do_left_association" => "left_association",
    "\[\[a\]\]", "\[\[s\]\]", "\[\[s\]\]", "\[\[o\]\]", "\[\[c\]\]", "\[\:ws\]",
    "\[\[\\\=\]\]", "\[\[\\\>\]\]", "\[\:ws\]", "\[\[l\]\]", "\[\[e\]\]",
    "\[\[f\]\]", "\[\[t\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
$rule_id = $tracer->rule_new( "do_lhs" => "lhs", "symbol_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( "do_op_declare_match" => "op_declare", "\[\[\\\~\]\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new(
    "do_op_declare_bnf" => "op_declare",
    "\[\[\\\:\]\]", "\[\[\\\:\]\]", "\[\[\\\=\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->rule_new( undef, "op_eq_pri", "\[\[\\\|\]\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id =
  $tracer->rule_new( undef, "op_tighter", "\[\[\\\|\]\]", "\[\[\\\|\]\]" );
$mask_by_rule_id[$rule_id] = [ 0, 0 ];
$rule_id = $tracer->sequence_new(
    "do_literal" => "phrase_name",
    "\[\[\ \\w\]\]", { min => 1, }
);
$rule_id = $tracer->rule_new(
    "Marpa\:\:R2\:\:Internal\:\:Stuifzand\:\:external_do_arg0" => "priorities",
    "priorities\[SeqLHS\]"
);
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "Marpa\:\:R2\:\:Internal\:\:Stuifzand\:\:external_do_arg0" => "priorities",
    "priorities\[SeqLHS\]", "\[\:ws\]", "op_tighter"
);
$mask_by_rule_id[$rule_id] = [ 1, 0, 0 ];
$rule_id = $tracer->rule_new(
    "\:\:whatever" => "priorities\[Sep\]",
    "\[\:ws\]", "op_tighter", "\[\:ws\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->sequence_new(
    "do_discard_separators" => "priorities\[SeqLHS\]",
    "alternatives", { separator => "priorities\[Sep\]", min => 1, proper => 1, }
);
$rule_id = $tracer->rule_new(
    "do_priority_rule" => "priority_rule",
    "lhs", "\[\:ws\]", "op_declare", "\[\:ws\]", "priorities"
);
$mask_by_rule_id[$rule_id] = [ 1, 0, 1, 0, 1 ];
$rule_id = $tracer->rule_new(
    "do_proper_specification" => "proper_specification",
    "\[\[p\]\]", "\[\[r\]\]", "\[\[o\]\]",    "\[\[p\]\]",    "\[\[e\]\]",
    "\[\[r\]\]", "\[\:ws\]",  "\[\[\\\=\]\]", "\[\[\\\>\]\]", "\[\:ws\]",
    "boolean"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ];
$rule_id = $tracer->rule_new(
    "do_quantified_rule" => "quantified_rule",
    "lhs", "\[\:ws\]", "op_declare", "\[\:ws\]", "single_symbol", "\[\:ws\]",
    "quantifier", "\[\:ws\]", "adverb_list"
);
$mask_by_rule_id[$rule_id] = [ 1, 0, 1, 0, 1, 0, 1, 0, 1 ];
$rule_id =
  $tracer->rule_new( "do_op_star_quantifier" => "quantifier", "\[\[\\\*\]\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id =
  $tracer->rule_new( "do_op_plus_quantifier" => "quantifier", "\[\[\\\+\]\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->sequence_new(
    "do_rhs" => "rhs",
    "rhs_primary", { separator => "rhs\[Sep\]", min => 1, proper => 1, }
);
$rule_id = $tracer->rule_new( "\:\:whatever" => "rhs\[Sep\]", "\[\:ws\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new(
    "do_single_quoted_string" => "rhs_primary",
    "single_quoted_string"
);
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( "do_symbol_list" => "rhs_primary", "single_symbol" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "do_end_of_input" => "rhs_primary",
    "\[\[\\\:\]\]", "\[\[\\\$\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0 ];
$rule_id = $tracer->rule_new(
    "do_ws" => "rhs_primary",
    "\[\[\\\:\]\]", "\[\[w\]\]", "\[\[s\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->rule_new(
    "do_any" => "rhs_primary",
    "\[\[\\\:\]\]", "\[\[a\]\]", "\[\[n\]\]", "\[\[y\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0 ];
$rule_id = $tracer->rule_new(
    "do_ws_star" => "rhs_primary",
    "\[\[\\\:\]\]", "\[\[w\]\]", "\[\[s\]\]", "\[\[\\\*\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0 ];
$rule_id = $tracer->rule_new(
    "do_ws_plus" => "rhs_primary",
    "\[\[\\\:\]\]", "\[\[w\]\]", "\[\[s\]\]", "\[\[\\\+\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0 ];
$rule_id = $tracer->rule_new(
    "do_parenthesized_symbol_list" => "rhs_primary",
    "\[\[\\\(\]\]", "\[\:ws\]", "rhs_primary_list", "\[\:ws\]", "\[\[\\\)\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1, 0, 0 ];
$rule_id = $tracer->sequence_new(
    "do_symbol_list" => "rhs_primary_list",
    "rhs_primary",
    { separator => "rhs_primary_list\[Sep\]", min => 1, proper => 1, }
);
$rule_id =
  $tracer->rule_new( "\:\:whatever" => "rhs_primary_list\[Sep\]", "\[\:ws\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new(
    "do_right_association" => "right_association",
    "\[\[a\]\]", "\[\[s\]\]", "\[\[s\]\]", "\[\[o\]\]", "\[\[c\]\]", "\[\:ws\]",
    "\[\[\\\=\]\]", "\[\[\\\>\]\]", "\[\:ws\]", "\[\[r\]\]", "\[\[i\]\]",
    "\[\[g\]\]", "\[\[h\]\]", "\[\[t\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
$rule_id = $tracer->rule_new( undef, "rule", "comment_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "empty_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "priority_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "quantified_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "start_rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->sequence_new(
    "do_rules" => "rules",
    "rule", { separator => "rules\[Sep\]", min => 1, proper => 1, }
);
$rule_id = $tracer->rule_new( "\:\:whatever" => "rules\[Sep\]", "\[\:ws\]" );
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new( undef, "safe\ cc\ character",
"\[\[\^\\x\{5d\}\\x\{0A\}\\x\{0B\}\\x\{0C\}\\x\{0D\}\\x\{0085\}\\x\{2028\}\\x\{2029\}\]\]"
);
$mask_by_rule_id[$rule_id] = [0];
$rule_id = $tracer->rule_new(
    "do_separator_specification" => "separator_specification",
    "\[\[s\]\]",    "\[\[e\]\]",    "\[\[p\]\]", "\[\[a\]\]", "\[\[r\]\]",
    "\[\[a\]\]",    "\[\[t\]\]",    "\[\[o\]\]", "\[\[r\]\]", "\[\:ws\]",
    "\[\[\\\=\]\]", "\[\[\\\>\]\]", "\[\:ws\]",  "single_symbol"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ];
$rule_id = $tracer->rule_new(
    "do_literal" => "single_quoted_string",
    "\[\[\'\]\]", "string\ without\ single\ quote\ or\ vertical\ space",
    "\[\[\'\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 1, 0 ];
$rule_id = $tracer->rule_new(
    "do_character_class" => "single_symbol",
    "character\ class"
);
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "single_symbol", "symbol" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "do_start_rule" => "start_rule",
    "\[\[\\\:\]\]", "\[\[s\]\]", "\[\[t\]\]",  "\[\[a\]\]", "\[\[r\]\]",
    "\[\[t\]\]",    "\[\:ws\]",  "op_declare", "\[\:ws\]",  "symbol_name"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 0, 0, 0, 0, 0, 1, 0, 1 ];
$rule_id = $tracer->sequence_new(
    undef,
    "string\ without\ single\ quote\ or\ vertical\ space",
"\[\[\^\'\\x\{0A\}\\x\{0B\}\\x\{0C\}\\x\{0D\}\\x\{0085\}\\x\{2028\}\\x\{2029\}\]\]",
    { min => 1, }
);
$rule_id = $tracer->rule_new( "do_symbol" => "symbol", "symbol_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "symbol_name", "bare_name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "symbol_name", "reserved_word" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    "do_symbol" => "symbol_name",
    "\[\[\\\<\]\]", "\[\:ws\]", "phrase_name", "\[\:ws\]", "\[\[\\\>\]\]"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1, 0, 0 ];
$rule_id = $tracer->rule_new(
    undef,
    "vertical\ space\ char",
    "\[\[\\x\{A\}\\x\{B\}\\x\{C\}\\x\{D\}\\x\{2028\}\\x\{2029\}\]\]"
);
$mask_by_rule_id[$rule_id] = [0];
## The code before this line was automatically generated by aoh_to_thin.pl

    $grammar->start_symbol_set( $tracer->symbol_by_name('[:start]') );
    $grammar->precompute();
    return {
        tracer                => $tracer,
        mask_by_rule_id       => \@mask_by_rule_id,
        character_class_table => \@character_class_table
    };
} ## end sub stuifzand_grammar

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

sub last_completed_symbol {
    my ($self, $symbol_name ) = @_;
    my ( $start, $end ) = last_completed_range( $self, $symbol_name );
    return 'No rule was successfully parsed' if not defined $start;
    return
        join q{}, map { ( not defined $_ or $_ < 0 ) ? q{} : chr $_ }
        map { $self->{recce}->earley_set_value($_) } $start .. $end;
} ## end sub last_rule

sub parse_rules {
    my ($thick_grammar, $string) = @_;

    state $stuifzand_grammar = stuifzand_grammar();
    state $tracer            = $stuifzand_grammar->{tracer};
    state $character_class_table            = $stuifzand_grammar->{character_class_table};
    state $mask_by_rule_id            = $stuifzand_grammar->{mask_by_rule_id};
    state $thin_grammar      = $tracer->grammar();
    my $recce = Marpa::R2::Thin::R->new($thin_grammar);
    $recce->start_input();

    # Memoize ? Global ?
    my $word_boundary     = $tracer->symbol_by_name('[:|w]');

    my $inner_self = { tracer => $tracer, recce => $recce };

    my $stream = Marpa::R2::Thin::U->new($recce);

    my $event_count;

    $stream->string_set(\$string);
    READ: {
        state $op_alternative = Marpa::R2::Thin::U::op('alternative');
        state $op_earleme_complete =
            Marpa::R2::Thin::U::op('earleme_complete');
        if ( not defined eval { $event_count = $stream->read(); 1 } ) {
            my $problem_symbol = $stream->symbol_id();
            my $symbol_desc =
                $problem_symbol < 0
                ? q{}
                : "Problem was with symbol "
                . $tracer->symbol_name($problem_symbol);
            die "Exception in stream read(): $EVAL_ERROR\n", $symbol_desc;
        } ## end if ( not defined eval { $event_count = $stream->read...})
        last READ if $event_count == 0;
        if ( $event_count > 0 ) {
            say STDERR
                "Events occurred while parsing BNF grammar; these will be fatal errors\n",
                "  Event count: $event_count";
            for ( my $event_ix = 0; $event_ix < $event_count; $event_ix++ ) {
                my ( $event_type, $value ) = $thin_grammar->event($event_ix);
                if ( $event_type eq 'MARPA_EVENT_EARLEY_ITEM_THRESHOLD' ) {
                    say STDERR
                        "Unexpected event: Earley item count ($value) exceeds warning threshold";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                    say STDERR "Unexpected event: $event_type ",
                        $tracer->symbol_name($value);
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                    say STDERR "Unexpected event: $event_type ";
                    next EVENT;
                }
            } ## end for ( my $event_ix = 0; $event_ix < $event_count; ...)
            die "Unexpected events when parsing BNF grammar, cannot proceed";
        } ## end if ( $event_count > 0 )
        if ( $event_count == -2 ) {

            $DB::single = 1;
            # Recover by registering character, if we can
            my $codepoint = $stream->codepoint();
            my @ops;
            for my $entry ( @{$character_class_table} ) {
                my ( $symbol_id, $re ) = @{$entry};
                if ( chr($codepoint) =~ $re ) {

                    # Add an undocumented flag for this?
                    if (0) {
                        my $trace_fh =
                            $thick_grammar->[
                            Marpa::R2::Internal::Grammar::TRACE_FILE_HANDLE
                            ];
                        say {$trace_fh} "Registering character ",
                            ( sprintf 'U+%04x', $codepoint ),
                            " as symbol $symbol_id: ",
                            $tracer->symbol_name($symbol_id);
                    } ## end if (0)
                    push @ops, $op_alternative, $symbol_id, 0, 1;
                } ## end if ( chr($codepoint) =~ $re )
            } ## end for my $entry ( @{$character_class_table} )
            die sprintf "Cannot read character U+%04x: %c\n", $codepoint,
                $codepoint
                if not @ops;
            $stream->char_register( $codepoint, @ops, $op_earleme_complete );
            redo READ;
        } ## end if ( $event_count == -2 )
        if ( $event_count == -1 ) {
            for my $terminal ( $recce->terminals_expected() ) {
                state $re_word_character = qr/
		[\p{alpha}\p{GC=Mark}\p{Digit}\p{GC=Connector_Punctuation}\p{Join_Control}]
	      /xms;
                DO_WORD_BOUNDARY: {
                    last DO_WORD_BOUNDARY if $terminal != $word_boundary;
                    my $current_is_word_char = 1
                        if ( chr $stream->codepoint() ) =~ $re_word_character;
                    if ($current_is_word_char) {
                        my $previous_codepoint;
                        my $previous_location = $recce->latest_earley_set();
                        while ( not defined $previous_codepoint
                            and $previous_location > 0 )
                        {
                            $previous_codepoint = $recce->earley_set_value(
                                --$previous_location );
                        } ## end while ( not defined $previous_codepoint and ...)
                        last DO_WORD_BOUNDARY
                            if defined $previous_codepoint
                                and ( chr $previous_codepoint )
                                =~ $re_word_character;
                    } ## end if ($current_is_word_char)
                    $recce->alternative( $word_boundary, 0, 1 );
                    $recce->earleme_complete();
                    redo READ;
                } ## end DO_WORD_BOUNDARY:
            } ## end for my $terminal ( $recce->terminals_expected() )
        } ## end if ( $event_count == -1 )

        ## If we are here, the error is not recoverable
        my $pos = $stream->pos();
        my $desc;
        DESC: {
            if ( $event_count == -1 ) {
                $desc = 'Character rejected';
                last DESC;
            }
            if ( $event_count == -2 ) {
                $desc = 'Unregistered character';
                last DESC;
            }
            if ( $event_count == -3 ) {
                $desc = 'Parse exhausted';
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
              "Error in string_read: $desc\n"
            . "* Error was at string position: $pos, and at character $char_in_hex, '$char_desc'\n"
            . "* String before error:\n"
            . Marpa::R2::escape_string( $prefix, -72 ) . "\n"
            . "* String after error:\n"
            . Marpa::R2::escape_string( ( substr $string, $pos, 72 ), 72 )
            . "\n";
        Marpa::R2::exception($read_string_error);
    } ## end READ:

    # Global ?
    my $end_of_input = $tracer->symbol_by_name('[:$]');

    END_OF_INPUT: while (1) {
        my $end_of_input_expected =
            grep { $_ == $end_of_input } $recce->terminals_expected();
        last END_OF_INPUT if not $end_of_input_expected;
        $recce->alternative( $end_of_input, 0, 1 );
        $recce->earleme_complete();
    } ## end END_OF_INPUT: while (1)

    $thin_grammar->throw_set(0);
    my $latest_earley_set_ID = $recce->latest_earley_set();
    my $bocage        = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
    $thin_grammar->throw_set(1);
    if ( !defined $bocage ) {
        die qq{Last rule successfully parsed was: },
            last_completed_symbol( $inner_self, 'rule' ),
            'Parse failed';
    } ## end if ( !defined $bocage )

    my $order         = Marpa::R2::Thin::O->new($bocage);
    my $tree          = Marpa::R2::Thin::T->new($order);
    $tree->next();
    my $valuator = Marpa::R2::Thin::V->new($tree);
    my @actions_by_rule_id;
    RULE_ID: for my $rule_id ( grep { $thin_grammar->rule_length($_); }
        0 .. $thin_grammar->highest_rule_id() )
    {
        $valuator->rule_is_valued_set( $rule_id, 1 );
        my $action = $tracer->action($rule_id);
        next RULE_ID if not defined $action;
        next RULE_ID if $action eq '::whatever';
        next RULE_ID if $action eq 'Marpa::R2::Internal::Stuifzand::external_do_arg0';
        $actions_by_rule_id[$rule_id] = $action;
    }

    # The parse result object
    my $self = { thick_grammar => $thick_grammar };

    my @stack = ();
    STEP: while (1) {
        my ( $type, @step_data ) = $valuator->step();
        last STEP if not defined $type;
        if ( $type eq 'MARPA_STEP_TOKEN' ) {
            # my ( undef, $token_value_ix, $arg_n ) = @step_data;
            # $stack[$arg_n] = $token_values[$token_value_ix];
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

                # Value is first unmasked arg
                $stack[$arg_0] = shift @args;
                next STEP;
            }
            my $hashed_closure = $hashed_closures{$action};
            if ( defined $hashed_closure ) {
                $stack[$arg_0] =
                    $hashed_closure->( $self, @args );
                next STEP;
            }
            if ( $action eq 'do_literal' ) {
                my ( $start, $end ) = $valuator->location();
                $stack[$arg_0] = join q{},
                    map { ( not defined $_ or $_ < 0 ) ? q{} : chr $_ }
                    map { $recce->earley_set_value($_) } $start .. $end;
                $stack[$arg_0] =~ s/ \A \s* //xms;
                $stack[$arg_0] =~ s/ \s* \z //xms;
                next STEP;
            } ## end if ( $action eq 'do_literal' )
            if ( $action eq 'do_alternative' ) {
                $stack[$arg_0] = [ @args ];
                next STEP;
            }
            if ( $action eq 'do_bracketed_name' ) {
                $stack[$arg_0] =~ s/\A [<] \s*//xms;
                $stack[$arg_0] =~ s/ \s* [>] \z//xms;
                next STEP;
            }
            if ( $action eq 'do_array' ) {
                $stack[$arg_0] = [ @args ];
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

    my $rules = $self->{rules} = $stack[0];

    my @ws_rules = ();
    if ( defined $self->{needs_symbol} ) {
        my %needed = %{ $self->{needs_symbol} };
        my %seen   = ();
        undef $self->{needs_symbol};
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
                    push @{ws_rules}, { lhs => '[:ws]', rhs => ['[:ws+]'], mask => [0] };
                    push @{ws_rules}, { lhs => '[:ws]', rhs => ['[:|w]'], mask => [0] };
                    $needed{'[:ws+]'} = 1;
                    next SYMBOL;
                } ## end if ( $needed_symbol eq '[:ws]' )
                if ( $needed_symbol eq '[:Space]' ) {
                    my $true_ws = assign_symbol_by_char_class( $self,
                        '[\p{White_Space}]' );
                    push @{ws_rules},
                        {
                        lhs  => '[:Space]',
                        rhs  => [ $true_ws->name() ],
                        mask => [0]
                        };
                } ## end if ( $needed_symbol eq '[:Space]' )
            } ## end SYMBOL: for my $needed_symbol (@needed_symbols)
        } ## end NEEDED_SYMBOL_LOOP: while (1)
    } ## end if ( defined $self->{needs_symbol} )

    push @{$rules}, @ws_rules;

    $self->{rules} = $rules;
    my $raw_cc      = $self->{character_classes};
    if ( defined $raw_cc ) {
        my $stripped_cc = {};
        for my $symbol_name ( keys %{$raw_cc} ) {
            my ($re) = @{ $raw_cc->{$symbol_name} };
            $stripped_cc->{$symbol_name} = $re;
        }
        $self->{character_classes} = $stripped_cc;
    } ## end if ( defined $raw_cc )
    return $self;
} ## end sub parse_rules

1;

# vim: expandtab shiftwidth=4:
