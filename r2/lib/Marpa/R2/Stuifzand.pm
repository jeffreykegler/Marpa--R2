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

package Marpa::R2::Stuifzand;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.047_007';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

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

sub last_rule {
   my ($meta_recce) = @_;
   my ($start, $end) = $meta_recce->last_completed_range( 'rule' );
   return 'No rule was completed' if not defined $start;
   return $meta_recce->range_to_string( $start, $end);
}

my %node_status =
    map { ; ($_ , q{} ) }
    qw(
action
action_name
adverb_item
adverb_list
alternative
alternatives
array_descriptor
bare_name
blessing
blessing_name
boolean
bracketed_name
default_rule
empty_rule
group_association
left_association
lhs
op_declare
op_declare_bnf
parenthesized_rhs_primary_list
priority_rule
priorities
proper_specification
quantified_rule
quantifier
reserved_blessing_name
rhs
rhs_primary
rhs_primary_list
right_association
separator_specification
single_symbol
standard_name
start_rule
statement
statement_body
symbol
symbol_name
);

$node_status{character_class} = "Character classes are not allowed";
$node_status{discard_rule} = ":discard rules are not allowed";
$node_status{single_quoted_string} = "Quoted strings are not allowed";
$node_status{lexeme_default_statement} = "The lexeme default statement is not allowed";

my %catch_error_node = 
    map { ; ($_ , 1 ) }
    qw( alternative statement );

# This code goes to some trouble to report errors with a large enough contet
# to be meaningful -- rules or alternatives

sub Marpa::R2::Internal::Stuifzand::check_ast {
    my ($node) = @_;
    my $ref_type = ref $node;
    return if not $ref_type;
    $ref_type =~ s/\A Marpa::R2::Internal::MetaAST_Nodes:: //xms;
    my $report_error = 0;
    my $node_status = $node_status{$ref_type};
    Marpa::R2::exception(
        "Internal error: Unknown AST node in Stuifzand grammar\n",
        qq{  Node was of type "$ref_type"\n} )
        if not defined $node_status;
    # "Normal" meaning other than error reporting
    NORMAL_PROCESSING: {
        if ($node_status) {
            die "$node_status\n" if not $catch_error_node{$ref_type};
            last NORMAL_PROCESSING;
        }
        if ( $catch_error_node{$ref_type} ) {
            return if eval {
                Marpa::R2::Internal::Stuifzand::check_ast($_)
                    for @{$node};
                1;
            };
            $node_status = $EVAL_ERROR;
            last NORMAL_PROCESSING;
        } ## end if ( $catch_error_node{$ref_type} )
        Marpa::R2::Internal::Stuifzand::check_ast($_) for @{$node};
        return;
    } ## end NORMAL_PROCESSING:

    # If we are here, we are doing error processing
        my ( $start, $end ) = @{$node};
        my $problem_text = substr ${$Marpa::R2::Internal::P_SOURCE}, $start,
            ($end-$start+1);
        chomp $problem_text;
        chomp $node_status;
        Marpa::R2::exception(
            "Stuifzand (BNF) interface grammar is using a disallowed feature\n",
            q{  } . $node_status . "\n",
            "  Problem was in the following text:\n",
            $problem_text,
            "\n"
        );
} ## end sub Marpa::R2::Internal::Stuifzand::check_ast

sub parse_rules {
    my ( $p_rules_source ) = @_;
    my $self       = {};
    my $ast        = Marpa::R2::Internal::MetaAST->new($p_rules_source);
    {
    local $Marpa::R2::Internal::P_SOURCE = $p_rules_source;
    Marpa::R2::Internal::Stuifzand::check_ast($_) for @{$ast};
    }
    my $hashed_ast = $ast->ast_to_hash($p_rules_source);
    $self->{rules} = $hashed_ast->{g1_rules};
    return $self;
} ## end sub parse_rules

1;

# vim: expandtab shiftwidth=4:
