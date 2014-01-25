#!/usr/bin/perl
# Copyright 2014 Jeffrey Kegler
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

# This example parses ambiguous English sentences.  The target annotation
# is Penn Treebank's syntactic bracketing tags.  For details, see
# http://www.cis.upenn.edu/~treebank/

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Test::More tests => 3;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

# Marpa::R2::Display
# name: ASF synopsis grammar
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

my $dsl = <<'END_OF_SOURCE';

S   ::= NP  VP  period  action => do_S

NP  ::= NN              action => do_NP_NN      
    |   NNS             action => do_NP_NNS   
    |   DT  NN          action => do_NP_DT_NN   
    |   NN  NNS         action => do_NP_NN_NNS
    |   NNS CC NNS      action => do_NP_NNS_CC_NNS

VP  ::= VBZ NP          action => do_VP_VBZ_NP
    | VP VBZ NNS        action => do_VP_VP_VBZ_NNS
    | VP CC VP          action => do_VP_VP_CC_VP
    | VP VP CC VP       action => do_VP_VP_VP_CC_VP
    | VBZ               action => do_VP_VBZ

period ~ '.'

:discard ~ whitespace
whitespace ~ [\s]+

CC ~ 'and'
DT  ~ 'a' | 'an'
NN  ~ 'panda'
NNS  ~ 'shoots' | 'leaves'
VBZ ~ 'eats' | 'shoots' | 'leaves'

END_OF_SOURCE

# Marpa::R2::Display::End

my $grammar = Marpa::R2::Scanless::G->new(
    { source => \$dsl } );

# Marpa::R2::Display
# name: ASF synopsis output
# start-after-line: END_OF_OUTPUT
# end-before-line: '^END_OF_OUTPUT$'

my $full_expected = <<'END_OF_OUTPUT';
(S (NP (DT a) (NN panda))
   (VP (VBZ eats) (NP (NNS shoots) (CC and) (NNS leaves)))
   (. .))
(S (NP (DT a) (NN panda))
   (VP (VP (VBZ eats) (NP (NNS shoots))) (CC and) (VP (VBZ leaves)))
   (. .))
(S (NP (DT a) (NN panda))
   (VP (VP (VBZ eats)) (VP (VBZ shoots)) (CC and) (VP (VBZ leaves)))
   (. .))
END_OF_OUTPUT

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: ASF synopsis input

my $sentence = 'a panda eats shoots and leaves.';

# Marpa::R2::Display::End

my @actual = ();

my $recce = Marpa::R2::Scanless::R->new( { 
    grammar => $grammar,
    semantics_package => 'PennTags'
} );

$recce->read( \$sentence );

while ( defined( my $value_ref = $recce->value() ) ) {
    my $value = $value_ref ? ${$value_ref} : 'No parse';
    push @actual, $value;
}

Marpa::R2::Test::is( ( join "\n", sort @actual ) . "\n",
    $full_expected, 'Ambiguous English sentence using value()' );

# Marpa::R2::Display
# name: ASF synopsis code

my $panda_grammar = Marpa::R2::Scanless::G->new(
    { source => \$dsl } );
my $panda_recce = Marpa::R2::Scanless::R->new( 
    { grammar => $panda_grammar,
      semantics_package => 'PennTags' } );
$panda_recce->read( \$sentence );
my $asf = Marpa::R2::ASF->new( { slr=>$panda_recce } );
my $full_result = $asf->traverse( {}, \&full_traverser );
my $pruned_result = $asf->traverse( {}, \&pruning_traverser );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: ASF synopsis full traverser code
sub full_traverser {

    # This routine converts the glade into a list of Penn-tagged elements
    # by calling semantic action closures fetched from the recognizer.
    # It is called recursively.
    my ($glade, $scratch)     = @_;
    my $rule_id     = $glade->rule_id();
    my $symbol_id   = $glade->symbol_id();
    my $symbol_name = $panda_grammar->symbol_name($symbol_id);

    # A token is a single choice and we just return it as a literal wrapped
    # to match the rule closures parameter list
    if ( not defined $rule_id ) {
        return [ $glade->literal() ];
    } ## end if ( not defined $rule_id )
    
    # Our result will be a list of choices
    my @return_value = ();

    CHOICE: while (1) {

        # The parse results at each position are a list of choices, so
        # to produce a new result list, we need to take a Cartesian
        # product of all the choices
        my @results = $glade->all_choices();

        # Special case for the start rule: just collapse one level of lists
        if ( $symbol_name eq '[:start]' ) {
            return [ map { join q{}, @{$_} } @results ];
        }

        # Now we have a list of choices, as a list of lists.  Each sub list
        # is a list of parse results, which we need to pass to the rule closures
        # and join into a single Penn-tagged element.  The result will be 
        # to collapse one level of lists, and leave us with a list of 
        # Penn-tagged elements.
        
        # First, we take the semantic action closure of the rule as defined in the 
        # recognizer's semantic package. 
        my $closure = $panda_recce->rule_closure( $glade->rule_id() );
        # Note: $glade->rule_id() is used instead of the above $rule_id, because
        # $glade->next() must have been called and the current glade (and thus
        # the rule) might have changed 
        
        # Now, we need to check if the semantic action of the rule is defined 
        # as a closure. For now, we just die if it is not.
        #
        # However, start, length, lhs, and values builtins can be emulated by
        # using $glade->span(), $glade->symbol_id(), and $glade->rh_values().
        # Stull, defining closures would probably serve you better.
        unless (defined $closure and ref $closure eq 'CODE'){
            die "The semantics of Rule #" . $glade->rule_id() . "is not defined as a closure.";
        }

        push @return_value, map { $closure->( {}, @{$_} ) } @results;

        # Look at the next alternative in this glade, or end the
        # loop if there is none
        last CHOICE if not defined $glade->next();

    } ## end CHOICE: while (1)
    
    # Return the list of Penn-tagged elements for this glade
    return \@return_value;
} ## end sub full_traverser

# Marpa::R2::Display::End

my $cooked_result =  join "\n", (sort @{$full_result}), q{};
Marpa::R2::Test::is( $cooked_result, $full_expected,
    'Ambiguous English sentence using ASF' );

# Marpa::R2::Display
# name: ASF synopsis pruning traverser code

sub pruning_traverser {

    # This routine converts the glade into a list of Penn-tagged elements.  It is called recursively.
    my ($glade, $scratch)     = @_;
    my $rule_id     = $glade->rule_id();
    my $symbol_id   = $glade->symbol_id();
    my $symbol_name = $panda_grammar->symbol_name($symbol_id);

    # A token is a single choice, and we know enough to fully Penn-tag it
    if ( not defined $rule_id ) {
        return $glade->literal(); # wrap for the closure call
    }

    my @return_value = $glade->rh_values();

    if ($symbol_name eq '[:start]'){
        # Special case for the start rule
        return $return_value[0] . "\n"  ;
    }
    else{
        my $closure = $panda_recce->rule_closure($rule_id);
        die "The semantics of Rule $rule_id is not defined as a closure." 
            unless defined $closure and ref $closure eq 'CODE';
        return $closure->( {}, @return_value );
    }
}

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: ASF pruned synopsis output
# start-after-line: END_OF_OUTPUT
# end-before-line: '^END_OF_OUTPUT$'

my $pruned_expected = <<'END_OF_OUTPUT';
(S (NP (DT a) (NN panda))
   (VP (VBZ eats) (NP (NNS shoots) (CC and) (NNS leaves)))
   (. .))
END_OF_OUTPUT

# Marpa::R2::Display::End

Marpa::R2::Test::is( $pruned_result, $pruned_expected,
    'Ambiguous English sentence using ASF: pruned' );

sub PennTags::do_S  { "(S $_[1]\n   $_[2]\n   (. .))" }

sub PennTags::do_NP_NN          { "(NP (NN $_[1]))" }
sub PennTags::do_NP_NNS         { "(NP (NNS $_[1]))" }
sub PennTags::do_NP_DT_NN       { "(NP (DT $_[1]) (NN $_[2]))" }
sub PennTags::do_NP_NN_NNS      { "(NP (NN $_[1]) (NNS $_[2]))" }
sub PennTags::do_NP_NNS_CC_NNS  { "(NP (NNS $_[1]) (CC $_[2]) (NNS $_[3]))" }

sub PennTags::do_VP_VBZ_NP      { "(VP (VBZ $_[1]) $_[2])" }
sub PennTags::do_VP_VP_VBZ_NNS  { "(VP $_[1] (VBZ $_[2]) (NNS $_[3]))" }
sub PennTags::do_VP_VP_CC_VP    { "(VP $_[1] (CC $_[2]) $_[3])" }
sub PennTags::do_VP_VP_VP_CC_VP { "(VP $_[1] $_[2] (CC $_[3]) $_[4])" }
sub PennTags::do_VP_VBZ         { "(VP (VBZ $_[1]))" }

1;    # In case used as "do" file

