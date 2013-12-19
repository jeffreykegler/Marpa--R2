#!/usr/bin/perl
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

# This example parses ambiguous English sentences.  The target annotation
# is Penn Treebank's syntactic bracketing tags.  For details, see
# http://www.cis.upenn.edu/~treebank/

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Test::More tests => 4;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

# Marpa::R2::Display
# name: ASF synopsis grammar
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

my $dsl = <<'END_OF_SOURCE';

:default ::= action => [values] bless => ::lhs
lexeme default = action => [value] bless => ::name

S   ::= NP  VP  period  bless => S

NP  ::= NN              bless => NP
    |   NNS          bless => NP
    |   DT  NN          bless => NP
    |   NN  NNS         bless => NP
    |   NNS CC NNS  bless => NP

VP  ::= VBZ NP          bless => VP
    | VP VBZ NNS        bless => VP
    | VP CC VP bless => VP
    | VP VP CC VP bless => VP
    | VBZ bless => VP

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
    { bless_package => 'PennTags', source => \$dsl, } );

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

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

$recce->read( \$sentence );

while ( defined( my $value_ref = $recce->value() ) ) {
    my $value = $value_ref ? ${$value_ref}->bracket() : 'No parse';
    push @actual, $value;
}

Marpa::R2::Test::is( ( join "\n", sort @actual ) . "\n",
    $full_expected, 'Ambiguous English sentence using value()' );

# Marpa::R2::Display
# name: ASF synopsis code

my $panda_grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
my $panda_recce = Marpa::R2::Scanless::R->new( { grammar => $panda_grammar } );
$panda_recce->read( \$sentence );
my $asf = Marpa::R2::ASF->new( { slr=>$panda_recce } );
my $full_result = $asf->traverse( {}, \&full_traverser );
my $pruned_result = $asf->traverse( {}, \&pruning_traverser );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: ASF synopsis full traverser code

sub full_traverser {

    # This routine converts the glade into a list of Penn-tagged elements.  It is called recursively.
    my ($glade, $scratch)     = @_;
    my $rule_id     = $glade->rule_id();
    my $symbol_id   = $glade->symbol_id();
    my $symbol_name = $panda_grammar->symbol_name($symbol_id);

    # A token is a single choice, and we know enough to fully Penn-tag it
    if ( not defined $rule_id ) {
        my $literal = $glade->literal();
        my $penn_tag = penn_tag($symbol_name);
        return ["($penn_tag $literal)"];
    } ## end if ( not defined $rule_id )

    # Our result will be a list of choices
    my @return_value = ();

    CHOICE: while (1) {

        # The results at each position are a list of choices, so
        # to produce a new result list, we need to take a Cartesian
        # product of all the choices
        my $length = $glade->rh_length();
        my @results = ( [] );
        for my $rh_ix ( 0 .. $length - 1 ) {
            my @new_results = ();
            for my $old_result (@results) {
                my $child_value = $glade->rh_value($rh_ix);
                for my $new_value ( @{ $child_value } ) {
                    push @new_results, [ @{$old_result}, $new_value ];
                }
            }
            @results = @new_results;
        } ## end for my $rh_ix ( 0 .. $length - 1 )

        # Special case for the start rule
        if ( $symbol_name eq '[:start]' ) {
            return [ map { join q{}, @{$_} } @results ];
        }

        # Now we a list of choices, as a list of lists.  Each sub list
        # is a list of Penn-tagged elements, which we need to join into
        # a single Penn-tagged element.  The result will be to collapse
        # one level of lists, and leave us with a list of Penn-tagged
        # elements
        my $join_ws = q{ };
        $join_ws = qq{\n   } if $symbol_name eq 'S';
        push @return_value,
            map { '(' . penn_tag($symbol_name) . q{ } . ( join $join_ws, @{$_} ) . ')' }
            @results;

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

sub penn_tag {
   my ($symbol_name) = @_;
   return q{.} if $symbol_name eq 'period';
   return $symbol_name;
}

sub pruning_traverser {

    # This routine converts the glade into a list of Penn-tagged elements.  It is called recursively.
    my ($glade, $scratch)     = @_;
    my $rule_id     = $glade->rule_id();
    my $symbol_id   = $glade->symbol_id();
    my $symbol_name = $panda_grammar->symbol_name($symbol_id);

    # A token is a single choice, and we know enough to fully Penn-tag it
    if ( not defined $rule_id ) {
        my $literal = $glade->literal();
        my $penn_tag = penn_tag($symbol_name);
        return "($penn_tag $literal)";
    }

    my $length = $glade->rh_length();
    my @return_value = map { $glade->rh_value($_) } 0 .. $length - 1;

    # Special case for the start rule
    return (join q{ }, @return_value) . "\n" if  $symbol_name eq '[:start]' ;

    my $join_ws = q{ };
    $join_ws = qq{\n   } if $symbol_name eq 'S';
    my $penn_tag = penn_tag($symbol_name);
    return "($penn_tag " . ( join $join_ws, @return_value ) . ')';

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

my $located_actual = $asf->traverse( {}, \&located_traverser );

sub located_traverser {

    # This routine converts the glade into a list of Penn-tagged elements.  It is called recursively.
    my ($glade, $scratch)     = @_;
    my $rule_id     = $glade->rule_id();
    my $symbol_id   = $glade->symbol_id();
    my $symbol_name = $panda_grammar->symbol_name($symbol_id);

    # A token is a single choice, and we know enough to fully Penn-tag it
    if ( not defined $rule_id ) {
        my $literal = $glade->literal();
        my $penn_tag = penn_tag($symbol_name);
        return "($penn_tag $literal)";
    }

    my $rh_length = $glade->rh_length();
    my @return_value = map { $glade->rh_value($_) } 0 .. $rh_length - 1;

    # Special case for the start rule
    return (join q{ }, @return_value) . "\n" if  $symbol_name eq '[:start]' ;

# Marpa::R2::Display::Start
# name: ASF span() traverser method example

    my ( $start, $length ) = $glade->span();
    my $end = $start + $length - 1;

# Marpa::R2::Display::End

    my $location = q{@};
    $location .= $start >= $end ? $start : "$start-$end";
    my $join_ws = q{ };
    $join_ws = qq{\n   } if $symbol_name eq 'S';
    return "($symbol_name$location " . ( join $join_ws, @return_value ) . ')';
    my $penn_tag = penn_tag($symbol_name);
    return "($penn_tag$location " . ( join $join_ws, @return_value ) . ')';

}

# name: ASF located synopsis output
# start-after-line: END_OF_OUTPUT
# end-before-line: '^END_OF_OUTPUT$'

my $located_expected = <<'END_OF_OUTPUT';
(S@0-30 (NP@0-6 (DT a) (NN panda))
   (VP@8-29 (VBZ eats) (NP@13-29 (NNS shoots) (CC and) (NNS leaves)))
   (. .))
END_OF_OUTPUT

# Marpa::R2::Display::End

Marpa::R2::Test::is(  $located_actual, $located_expected, 'Located Penn tag example' );

package PennTags;

sub contents {
    join( $_[0], map { $_->bracket() } @{ $_[1] } );
}

sub PennTags::S::bracket { "(S " . contents( "\n   ", $_[0] ) . ")" }
sub PennTags::NP::bracket { "(NP " . contents( ' ', $_[0] ) . ")" }
sub PennTags::VP::bracket { "(VP " . contents( ' ', $_[0] ) . ")" }
sub PennTags::PP::bracket { "(PP " . contents( ' ', $_[0] ) . ")" }

sub PennTags::CC::bracket  {"(CC $_[0]->[0])"}
sub PennTags::DT::bracket  {"(DT $_[0]->[0])"}
sub PennTags::IN::bracket  {"(IN $_[0]->[0])"}
sub PennTags::NN::bracket  {"(NN $_[0]->[0])"}
sub PennTags::NNS::bracket {"(NNS $_[0]->[0])"}
sub PennTags::VB::bracket  {"(VB $_[0]->[0])"}
sub PennTags::VBP::bracket {"(VBP $_[0]->[0])"}
sub PennTags::VBZ::bracket {"(VBZ $_[0]->[0])"}

sub PennTags::period::bracket {"(. .)"}

1;    # In case used as "do" file

