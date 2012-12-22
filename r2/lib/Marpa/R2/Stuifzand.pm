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
$VERSION        = '2.033_002';
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
# Of the form '[Lex-42]' - where for '42' any other
# decimal number can be subsituted.  Anonymous lexicals.
# These symbols are their own originals.
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

# Undo any rewrite of the symbol name
sub Marpa::R2::Grammar::original_symbol_name {
   $_[0] =~ s/\[ prec \d+ \] \z//xms;
   return shift;
}

# This rule is used by the semantics of the *GENERATED*
# grammars, not the Stuifzand grammar itself.
sub external_do_arg0 {
   return $_[1];
}

sub do_rules {
    shift;
    return [ map { @{$_} } @_ ];
}

sub do_start_rule {
    my ( $self, $rhs ) = @_;
    my $do_arg0 = __PACKAGE__ . q{::} . 'external_do_arg0';
    return [
        {   lhs    => '[:start]',
            rhs    => [ $rhs->names() ],
            action => $do_arg0,
            mask   => [1]
        }
    ];
} ## end sub do_start_rule

sub do_discard_rule {
    my ( $self, $rhs ) = @_;
    my $thick_grammar = $self->{thick_grammar};
    Marpa::R2::exception( ':discard not allowed unless grammar is scannerless');
} ## end sub do_discard_rule

sub do_priority_rule {
    my ( $self, $lhs, $op_declare, $priorities ) = @_;
    my $thick_grammar = $self->{thick_grammar};
    my $priority_count = scalar @{$priorities};
    my @rules          = ();
    my @xs_rules = ();

    if ( $priority_count <= 1 ) {
        ## If there is only one priority
        for my $alternative ( @{ $priorities->[0] } ) {
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

    # mask not needed
    $sequence_rule{lhs}       = $lhs;
    $sequence_rule{separator} = $original_separator
        if defined $original_separator;
    my $proper = $adverb_list->{proper};
    $sequence_rule{proper} = $proper if defined $proper;
    return \@rules;

} ## end sub do_quantified_rule

sub create_hidden_internal_symbol {
    my ($self, $symbol_name) = @_;
    $self->{needs_symbol}->{$symbol_name} = 1;
    my $symbol = Marpa::R2::Internal::Stuifzand::Symbol->new($symbol_name);
    $symbol->hidden_set();
    return $symbol;
}

sub do_any {
    Marpa::R2::exception( ':any not allowed unless grammar is scannerless');
}

sub do_ws {
    Marpa::R2::exception( ':ws not allowed unless grammar is scannerless');
}
sub do_ws_star {
    Marpa::R2::exception( ':ws* not allowed unless grammar is scannerless');
}
sub do_ws_plus {
    Marpa::R2::exception( ':ws+ not allowed unless grammar is scannerless');
}

sub do_symbol {
    shift;
    return Marpa::R2::Internal::Stuifzand::Symbol->new( $_[0] );
}

sub do_character_class {
    Marpa::R2::exception( 'character classes not allowed unless grammar is scannerless');
} ## end sub do_character_class

sub do_rhs_primary_list { shift; return Marpa::R2::Internal::Stuifzand::Symbol_List->new(@_) }
sub do_lhs { shift; return $_[0]; }
sub do_rhs {
    shift;
    return Marpa::R2::Internal::Stuifzand::Symbol_List->new(
        map { $_->symbols() } @_ );
}
sub do_adverb_list { shift; return { map {; @{$_}} @_ } }

sub do_parenthesized_rhs_primary_list {
    my (undef, $list) = @_;
    $list->hidden_set();
    return $list;
} ## end sub do_parenthesized_symbol_list

sub do_separator_specification {
    my (undef, $separator) = @_;
    return [ separator => $separator->name() ];
}

sub do_single_quoted_string {
    Marpa::R2::exception( 'quoted strings not allowed unless grammar is scannerless');
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

my @mask_by_rule_id;
my $rule_id;

## The code after this line was automatically generated by aoh_to_thin.pl
## Date: Fri Dec 21 18:15:00 2012
$rule_id = $tracer->rule_new(
    "Marpa\:\:R2\:\:Internal\:\:Stuifzand\:\:external_do_arg0" => "\[\:start\]",
    "rules"
);
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "action", "kw\ action", "op\ arrow",
    "action\ name" );
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new( undef, "action\ name", "bare\ name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "action\ name", "reserved\ action\ name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb\ item", "action" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb\ item", "group\ association" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb\ item", "left\ association" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb\ item", "proper\ specification" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "adverb\ item", "right\ association" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( undef, "adverb\ item", "separator\ specification" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->sequence_new( undef, "adverb\ list", "adverb\ item", { min => 0, } );
$rule_id = $tracer->rule_new( undef, "alternative", "rhs", "adverb\ list" );
$mask_by_rule_id[$rule_id] = [ 1, 1 ];
$rule_id =
  $tracer->sequence_new( undef, "alternatives", "alternative",
    { separator => "op\ eq\ pri", min => 1, proper => 1, } );
$rule_id = $tracer->rule_new(
    undef, "discard\ rule",
    "kwc\ discard",
    "op\ declare\ match",
    "single\ symbol"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new( undef, "empty\ rule", "lhs", "op\ declare",
    "adverb\ list" );
$mask_by_rule_id[$rule_id] = [ 1, 1, 1 ];
$rule_id = $tracer->rule_new( undef, "group\ association",
    "kw\ assoc", "op\ arrow", "kw\ group" );
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->rule_new( undef, "left\ association",
    "kw\ assoc", "op\ arrow", "kw\ left" );
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->rule_new( undef, "lhs", "symbol\ name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "op\ declare", "op\ declare\ bnf" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "op\ declare", "op\ declare\ match" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new(
    undef, "parenthesized\ rhs\ primary\ list",
    "op\ lparen", "rhs\ primary\ list",
    "op\ rparen"
);
$mask_by_rule_id[$rule_id] = [ 0, 1, 0 ];
$rule_id =
  $tracer->sequence_new( undef, "priorities", "alternatives",
    { separator => "op\ tighter", min => 1, proper => 1, } );
$rule_id = $tracer->rule_new( undef, "priority\ rule",
    "lhs", "op\ declare", "priorities" );
$mask_by_rule_id[$rule_id] = [ 1, 1, 1 ];
$rule_id = $tracer->rule_new( undef, "proper\ specification",
    "kw\ proper", "op\ arrow", "boolean" );
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new(
    undef, "quantified\ rule",
    "lhs", "op\ declare", "single\ symbol",
    "quantifier", "adverb\ list"
);
$mask_by_rule_id[$rule_id] = [ 1, 1, 1, 1, 1 ];
$rule_id = $tracer->rule_new( undef, "quantifier", "op\ plus" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "quantifier", "op\ star" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved\ word", "kw\ action" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved\ word", "kw\ assoc" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved\ word", "kw\ group" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved\ word", "kw\ left" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved\ word", "kw\ proper" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved\ word", "kw\ right" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "reserved\ word", "kw\ separator" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->sequence_new( undef, "rhs", "rhs\ primary", { min => 1, } );
$rule_id = $tracer->rule_new( undef, "rhs\ primary", "kwc\ any" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rhs\ primary", "kwc\ ws" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rhs\ primary", "kwc\ ws\ plus" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rhs\ primary", "kwc\ ws\ star" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rhs\ primary",
    "parenthesized\ rhs\ primary\ list" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rhs\ primary", "single\ quoted\ string" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rhs\ primary", "single\ symbol" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->sequence_new( undef, "rhs\ primary\ list",
    "rhs\ primary", { min => 1, } );
$rule_id = $tracer->rule_new( undef, "right\ association",
    "kw\ assoc", "op\ arrow", "kw\ right" );
$mask_by_rule_id[$rule_id] = [ 0, 0, 0 ];
$rule_id = $tracer->rule_new( undef, "rule", "discard\ rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "empty\ rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "priority\ rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "quantified\ rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "rule", "start\ rule" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->sequence_new( undef, "rules", "rule", { min => 1, } );
$rule_id = $tracer->rule_new(
    undef,
    "separator\ specification",
    "kw\ separator",
    "op\ arrow", "single\ symbol"
);
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new( undef, "single\ symbol", "character\ class" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "single\ symbol", "symbol" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id =
  $tracer->rule_new( undef, "start\ rule", "kwc\ start", "op\ declare\ bnf",
    "symbol" );
$mask_by_rule_id[$rule_id] = [ 0, 0, 1 ];
$rule_id = $tracer->rule_new( undef, "symbol", "symbol\ name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "symbol\ name", "bare\ name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "symbol\ name", "bracketed\ name" );
$mask_by_rule_id[$rule_id] = [1];
$rule_id = $tracer->rule_new( undef, "symbol\ name", "reserved\ word" );
$mask_by_rule_id[$rule_id] = [1];
## The code before this line was automatically generated by aoh_to_thin.pl

    $grammar->start_symbol_set( $tracer->symbol_by_name('[:start]') );
    $grammar->precompute();
    return {tracer => $tracer, mask_by_rule_id => \@mask_by_rule_id };
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

sub last_rule {
   my ($tracer, $thin_recce, $string, $positions) = @_;
        return input_slice( $string, $positions,
            last_completed_range( $tracer, $thin_recce, 'rule') )
            // 'No rule was completed';
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

sub parse_rules {
    my ($thick_grammar, $string) = @_;

    # Track earley set positions in input,
    # for debuggging
    my @positions = (0);

    state $stuifzand_grammar = stuifzand_grammar();
    state $tracer            = $stuifzand_grammar->{tracer};
    state $mask_by_rule_id            = $stuifzand_grammar->{mask_by_rule_id};
    state $thin_grammar      = $tracer->grammar();
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
                'reserved word';
        next RULE if scalar @rhs != 1;
        my $reserved_word =
            Marpa::R2::Grammar::original_symbol_name( $rhs[0] );
        next RULE if 'kw ' ne substr $reserved_word, 0, 3;
        $reserved_word = substr $reserved_word, 3;
        push @terminals,
            [
            'kw ' . $reserved_word,
            qr/$reserved_word\b/xms,
            qq{"$reserved_word" keyword}
            ];
    } ## end for my $rule_id ( grep { $thin_grammar->rule_length($_...)})
    push @terminals,
        [ 'kwc start', qr/ [:] start \b /xms, ':start reserved symbol' ],
        [ 'kwc discard', qr/ [:] discard \b /xms,
        ':discard reserved symbol' ],
        [ 'kwc ws plus', qr/ [:] ws [+] /xms,    ':ws+ reserved symbol' ],
        [ 'kwc ws star', qr/ [:] ws [*] /xms,    ':ws* reserved symbol' ],
        [ 'kwc ws',      qr/ [:] ws \b/xms,      ':ws reserved symbol' ],
        [ 'kwc default', qr/ [:] default \b/xms, ':default reserved symbol' ],
        [ 'kwc any',     qr/ [:] any \b/xms,     ':any reserved symbol' ],
        [ 'op declare bnf', qr/::=/xms,    'BNF declaration operator (ws)' ],
        [ 'op declare match', qr/[~]/xms,    'match declaration operator (no ws)' ],
        [ 'op arrow',   qr/=>/xms,     'adverb operator' ],
        [ 'op lparen',  qr/[(]/xms,    'left parenthesis' ],
        [ 'op rparen',  qr/[)]/xms,    'right parenthesis' ],
        [ 'op tighter', qr/[|][|]/xms, 'tighten-precedence operator' ],
        [ 'op eq pri',  qr/[|]/xms,    'alternative operator' ],
        [ 'op plus',    qr/[+]/xms,    'plus quantification operator' ],
        [ 'op star',    qr/[*]/xms,    'star quantification operator' ],
        [ 'boolean',    qr/[01]/xms ],
        [ 'bare name',  qr/\w+/xms, ],
        [ 'bracketed name', qr/ [<] [\s\w]+ [>] /xms, ],
        [ 'reserved action name', qr/(::(whatever|undef))/xms ],
        ## no escaping or internal newlines, and disallow empty string
        [ 'single quoted string', qr/ ['] [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]+ ['] /xms ],
        [ 'character class', qr/ (?: (?: \[) (?: [^\\\[]* (?: \\. [^\\\]]* )* ) (?: \]) ) /xms,
            'character class' ],
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
                my ( $line, $column ) =
                    line_column( $string, $problem_position );
                die qq{MARPA PARSE ABEND at line $line, column $column:\n},
                    qq{=== Last rule that Marpa successfully parsed was: },
                    last_rule( $tracer, $recce, $string, \@positions ), "\n",
                    problem_happened_here($string, $problem_position),
                    qq{=== Marpa rejected token, "$1", }, ( $t->[2] // $t->[0] ), "\n";
            } ## end if ( $recce->alternative( $tracer->symbol_by_name( $t...)))
            $recce->earleme_complete();
            $latest_earley_set_ID = $recce->latest_earley_set();
            $positions[$latest_earley_set_ID] = $string_position;
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string, "\n";
    } ## end TOKEN: while ( pos $string < $length )

    $thin_grammar->throw_set(0);
    my $bocage        = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
    $thin_grammar->throw_set(1);
    if ( !defined $bocage ) {
        die qq{Last rule successfully parsed was: },
            last_rule( $tracer, $recce, $string, \@positions ),
            'Parse failed';
    } ## end if ( !defined $bocage )

    my $order         = Marpa::R2::Thin::O->new($bocage);
    my $tree          = Marpa::R2::Thin::T->new($order);
    $tree->next();
    my $valuator = Marpa::R2::Thin::V->new($tree);
    my @actions_by_rule_id;
    RULE:
    for my $rule_id ( grep { $thin_grammar->rule_length($_); }
        0 .. $thin_grammar->highest_rule_id() )
    {
        $valuator->rule_is_valued_set( $rule_id, 1 );
        my ( $lhs, @rhs ) = $tracer->rule($rule_id);
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
        $action = $tracer->action($rule_id);
        next RULE if not defined $action;
        next RULE if $action =~ / Marpa [:][:] R2 .* [:][:] external_do_arg0 \z /xms;
        $actions_by_rule_id[$rule_id] = $action;
    } ## end for my $rule_id ( grep { $thin_grammar->rule_length($_...)})

    # The parse result object
    my $self = { thick_grammar => $thick_grammar };

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
                $stack[$arg_0] =
                    $hashed_closure->( $self, @args );
                next STEP;
            }
            if ( $action eq 'do_alternative' ) {
                $stack[$arg_0] = [ @args ];
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
    return $self;
} ## end sub parse_rules

1;

# vim: expandtab shiftwidth=4:
