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
# a preposition or a verb.  This creates syntactic ambiguity shown 
# in the parse results.

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

my $grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'PennTags',
        source => \(<<'END_OF_SOURCE'),
        
:default ::= action => [lhs,values]
lexeme default = action => [lhs,value]

S   ::= NP  VP  period  

NP  ::= NN              
    |   DT  NN          
    |   NN  NNS         

VP  ::= VBP NP          
    |   VBP PP          
    |   VBZ PP          

PP  ::= IN  NP          
    
period ~ '.'

:discard ~ whitespace
whitespace ~ [\s]+

DT  ~ 'a' | 'an'
NN  ~ 'arrow' | 'banana'
NNS ~ 'flies'
VBZ ~ 'flies' 
NN  ~ 'fruit':i
VBP ~ 'fruit':i
IN  ~ 'like'
VBP ~ 'like'
NN  ~ 'time':i
VBP ~ 'time':i

END_OF_SOURCE
    }
);

my $expected = <<'EOS';
(S 
  (NP (NN Time)) 
  (VP (VBZ flies) 
    (PP (IN like) 
      (NP (DT an) (NN arrow)))) 
  (. .))
(S 
  (NP (NN Time) (NNS flies)) 
  (VP (VBP like) 
    (NP (DT an) (NN arrow))) 
  (. .))
(S 
  (NP (NN Fruit)) 
  (VP (VBZ flies) 
    (PP (IN like) 
      (NP (DT a) (NN banana)))) 
  (. .))
(S 
  (NP (NN Fruit) (NNS flies)) 
  (VP (VBP like) 
    (NP (DT a) (NN banana))) 
  (. .))
EOS

my $paragraph = <<END_OF_PARAGRAPH;
Time flies like an arrow.
Fruit flies like a banana.
END_OF_PARAGRAPH

my @actual = ();

for my $sentence (split /\n/, $paragraph){

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar  } );

    $recce->read( \$sentence );

    while ( defined( my $value_ref = $recce->value() ) ) {
        use YAML;
        say STDERR Dump ${$value_ref};
        my $value = $value_ref ? PennTags::S::bracket( ${$value_ref} ) : 'No parse';
        push @actual, $value;
    }
}

my %s_tags; # structural tags

sub PennTags::S::bracket   { 
    %s_tags = map { $_ => undef } qw{ NP VP PP period } unless %s_tags;
    my ($tag, $contents) = @_;
    state $level++;
    my $bracketed = 
        exists $s_tags{$tag} ? ("\n" . ("  " x ($level-1))) : '';
    $tag = '.' if $tag eq 'period';
    if (ref $contents->[0]){
        $bracketed .= 
                "($tag "
            .   join(' ', map { PennTags::S::bracket($_) } @$contents) 
            .   ")";
    }
    else {
        $bracketed .= "($tag $contents->[0])";
    }
    $level--;
    return $bracketed;
}

Marpa::R2::Test::is( ( join "\n", @actual ) . "\n",
    $expected, 'Ambiguous English sentences' );

1;    # In case used as "do" file

# vim: set expandtab shiftwidth=4:

