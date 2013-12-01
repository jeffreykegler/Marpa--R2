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

# This example originally came from Ralf Muschall.  Ruslan Shvedov
# reworked my implementation, converting it to the SLIF and
# Penn Treebank.  Ruslan and Ralf clearly know English grammar better than
# most of us native speakers.

# 'time', 'fruit', and 'flies' can be nouns or verbs, 'like' can be
# a preposition or a verb. This creates syntactic ambiguity that
# is shown in the parse results.

# Modifier nouns are not tagged or lexed as adjectives (JJ), because
# "Nouns that are used as modifiers, whether in isolation or in sequences,
# should be tagged as nouns (NN, NNS) rather than as adjectives (JJ)."
# -- ftp://ftp.cis.upenn.edu/pub/treebank/doc/tagguide.ps.gz

# The saying "time flies like an arrow; fruit flies like a banana"
# is attributed to Groucho Marx, but there is no reason to believe
# he ever said it.  Apparently, the saying
# first appeared on the Usenet on net.jokes in 1982.
# I've documented this whole thing on Wikipedia:
# http://en.wikipedia.org/wiki/Time_flies_like_an_arrow
#
# The permalink is:
# http://en.wikipedia.org/w/index.php?title=Time_flies_like_an_arrow&oldid=311163283

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Test::More tests => 1;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub do_S   {"(S $_[1] $_[2])"}
sub do_NP  { "(NP $_[1]" . ( $_[2] //= '' ) . ")" }
sub do_VP  {"(VP $_[1] $_[2])"}
sub do_PP  {"(PP $_[1] $_[2])"}
sub do_DT  {"(DT $_[1])"}
sub do_IN  {"(IN $_[1])"}
sub do_NN  {"(NN $_[1])"}
sub do_NNS {"(NNS $_[1])"}
sub do_VB  {"(VB $_[1])"}
sub do_VBP {"(VBP $_[1])"}
sub do_VBZ {"(VBZ $_[1])"}

## use critic

my $grammar = Marpa::R2::Scanless::G->new(
    {

        source => \(<<'END_OF_SOURCE'),

S   ::= NP VP   action => do_S

NP  ::= NN      action => do_NP
    |   DT NN   action => do_NP
    |   NN NNS  action => do_NP

VP  ::= VBP NP  action => do_VP
    |   VBP PP  action => do_VP
    |   VBZ PP  action => do_VP

PP  ::= IN NP   action => do_PP
    
DT  ::= DT_lex  action => do_DT
IN  ::= IN_lex  action => do_IN
NN  ::= NN_lex  action => do_NN
NNS ::= NNS_lex action => do_NNS
VBP ::= VBP_lex action => do_VBP
VBZ ::= VBZ_lex action => do_VBZ

DT_lex ~ unicorn 
IN_lex ~ unicorn
NN_lex ~ unicorn
NNS_lex ~ unicorn
VBP_lex ~ unicorn
VBZ_lex ~ unicorn

unicorn ~ [^\s\S]

END_OF_SOURCE
    }
);

my $expected = <<'EOS';
(S (NP (NN time)) (VP (VBZ flies) (PP (IN like) (NP (DT an)(NN arrow)))))
(S (NP (NN time)(NNS flies)) (VP (VBP like) (NP (DT an)(NN arrow))))
(S (NP (NN fruit)) (VP (VBZ flies) (PP (IN like) (NP (DT a)(NN banana)))))
(S (NP (NN fruit)(NNS flies)) (VP (VBP like) (NP (DT a)(NN banana))))
EOS

my @actual = ();

my $tags = <<END_OF_TAGS;
a       DT_lex
an      DT_lex
arrow   NN_lex
banana  NN_lex
flies   NNS_lex VBZ_lex
fruit   NN_lex  VBP_lex
like    IN_lex  VBP_lex
time    NN_lex  VBP_lex
END_OF_TAGS

my %tags = ();
for my $line ( split /\n/s, $tags ) {
    my ( $word, @tags ) = split /\s+/, $line;
    $tags{$word} = \@tags;
}

for my $data ( 'time flies like an arrow', 'fruit flies like a banana' ) {

    my $recce = Marpa::R2::Scanless::R->new(
        {   grammar           => $grammar,
            semantics_package => 'main',
        }
    );
    die 'Failed to create recognizer' if not $recce;

    $recce->read( \$data, 0, 0 );
    my $start = 0;
    for my $token ( split /(\s+)/, $data ) {
        if ( exists $tags{ lc $token } ) {
            for my $tag ( @{ $tags{$token} } ) {
                $recce->lexeme_alternative( $tag, $token );
            }
            $recce->lexeme_complete( $start, length $token )
                or die $recce->show_progress();
        } ## end if ( exists $tags{ lc $token } )
        $start += length($token);
    } ## end for my $token ( split /(\s+)/, $data )

    while ( defined( my $value_ref = $recce->value() ) ) {
        my $value = $value_ref ? ${$value_ref} : 'No parse';
        push @actual, $value;
    }

} ## end for my $data ( 'time flies like an arrow', ...)

Marpa::R2::Test::is( ( join "\n", @actual ) . "\n",
    $expected, 'Ambiguous English sentences' );

1;    # In case used as "do" file

