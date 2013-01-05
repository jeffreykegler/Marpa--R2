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
$VERSION        = '2.041_000';
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

sub last_rule {
   my ($meta_recce) = @_;
   my ($start, $end) = $meta_recce->last_completed_range( 'rule' );
   return 'No rule was completed' if not defined $start;
   return $meta_recce->range_to_string( $start, $end);
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
    my ($thick_grammar, $p_rules_source) = @_;

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

    # The parse result object
    my $self = { thick_grammar => $thick_grammar };

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
