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
$VERSION        = '2.079_004';
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

my %node_status =
    map { ; ($_ , q{} ) }
    qw(
action
action_name
adverb_item
adverb_list
adverb_list_items
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
Perl_name
priorities
priority_rule
proper_specification
quantified_rule
quantifier
reserved_action_name
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
statements
symbol
symbol_name
);


$node_status{'Marpa::R2::Internal::MetaAST'} = q{};
$node_status{character_class} = "Character classes are not allowed";
$node_status{discard_rule} = ":discard rules are not allowed";
$node_status{single_quoted_string} = "Quoted strings are not allowed";
$node_status{lexeme_default_statement} = "The lexeme default statement is not allowed";
$node_status{lexeme_rule} = "Lexeme statements are not allowed";
$node_status{completion_event_declaration} = "Completion events are not allowed";
$node_status{nulled_event_declaration} = "Nulled events are not allowed";
$node_status{prediction_event_declaration} = "Prediction events are not allowed";
$node_status{array_descriptor} = "Actions in the form of array descriptors are not allowed";
$node_status{op_declare_match} = "lexical rules are not allowed";
$node_status{priority_specification} = "The priority adverb is not allowed";
$node_status{pause_specification} = "The pause adverb is not allowed";
# 'forgiving' was never documented and may be eliminated
# $node_status{forgiving_specification} = qq{The "forgiving" adverb is not allowed};
$node_status{event_specification} = qq{The "event" adverb is not allowed};

my %catch_error_node = 
    map { ; ($_ , 1 ) }
    qw( alternative statement );

# This code goes to some trouble to report errors with a large enough contet
# to be meaningful -- rules or alternatives

sub Marpa::R2::Internal::Stuifzand::check_ast_node {
    my ($node) = @_;
    my $ref_type = ref $node;
    return if not $ref_type;
    $ref_type =~ s/\A Marpa::R2::Internal::MetaAST_Nodes:: //xms;
    my $report_error = 0;
    my $problem = $node_status{$ref_type};
    my $catch_error = $catch_error_node{$ref_type};
    return qq{Internal error: Unknown AST node (type "$ref_type") in Stuifzand grammar}
        if not defined $problem;
    # "Normal" meaning other than catching errors 
    NORMAL_PROCESSING: {
        if ($problem) {
            return $problem if not $catch_error_node{$ref_type};
            last NORMAL_PROCESSING;
        }
        for my $sub_node ( @{$node} ) {
            $problem = Marpa::R2::Internal::Stuifzand::check_ast_node($sub_node);
            if ($problem) {
                return $problem if not $catch_error;
                last NORMAL_PROCESSING;
            }
        } ## end for my $sub_node ( @{$node} )
        return;
    } ## end NORMAL_PROCESSING:

    # If we are here, we are catching an error 
        my ( $start, $end ) = @{$node};
        my $problem_was_here = substr ${$Marpa::R2::Internal::P_SOURCE}, $start,
            ($end-$start+1);
        chomp $problem_was_here;
        chomp $problem;
        Marpa::R2::exception(
            "Stuifzand (BNF) interface grammar is using a disallowed feature\n",
            q{  } . $problem . "\n",
            "  Problem was in the following text:\n",
            $problem_was_here,
            "\n"
        );
} ## end sub Marpa::R2::Internal::Stuifzand::check_ast_node

sub parse_rules {
    my ($p_rules_source) = @_;
    my $self             = {};
    my $ast              = Marpa::R2::Internal::MetaAST->new($p_rules_source);
    {
        local $Marpa::R2::Internal::P_SOURCE = $p_rules_source;
        my $problem = Marpa::R2::Internal::Stuifzand::check_ast_node(
            $ast->{top_node} );
        ## Uncaught problem -- should not happen
        if ($problem) {
            Marpa::R2::exception(
                "Stuifzand (BNF) interface grammar has a problem\n",
                q{  } . $problem . "\n",
            );
        } ## end if ($problem)
    }
    my $hashed_ast = $ast->ast_to_hash();
    my $start_lhs = $hashed_ast->{'start_lhs'} // $hashed_ast->{'first_lhs'};
    Marpa::R2::exception( 'No rules in Stuifzand grammar', )
        if not defined $start_lhs;

    my $internal_start_lhs = '[:start]';
    $hashed_ast->{'default_g1_start_action'} =
        $hashed_ast->{'default_adverbs'}->{'G1'}->{'action'};
    $hashed_ast->{'symbols'}->{'G1'}->{$internal_start_lhs} = {
        display_form => ':start',
        description  => 'Internal G1 start symbol'
    };
    push @{ $hashed_ast->{rules}->{G1} },
        {
        lhs    => $internal_start_lhs,
        rhs    => [$start_lhs],
        action => '::first'
        };

    $self->{rules} = $hashed_ast->{rules}->{G1};
    return $self;
} ## end sub parse_rules

1;

# vim: expandtab shiftwidth=4:
