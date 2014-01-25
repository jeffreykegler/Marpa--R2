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

# This example is from Ralf Muschall, who clearly knows English
# grammar better than most native speakers.  I've reworked the
# terminology to follow _A Comprehensive Grammar of the English
# Language_, by Quirk, Greenbaum, Leech and Svartvik.  My edition
# was the "Seventh (corrected) impression 1989".
#
# When it is not a verb, I treat "like"
# as a preposition in an adjunct of manner,
# as per 8.79, p. 557; 9.4, pp. 661; and 9.48, pp. 698-699.
#
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

sub do_sva_sentence      { return "sva($_[1];$_[2];$_[3])" }
sub do_svo_sentence      { return "svo($_[1];$_[2];$_[3])" }
sub do_adjunct           { return "adju($_[1];$_[2])" }
sub do_adjective         { return "adje($_[1])" }
sub do_qualified_subject { return "s($_[1];$_[2])" }
sub do_bare_subject      { return "s($_[1])" }
sub do_noun              { return "n($_[1])" }
sub do_verb              { return "v($_[1])" }
sub do_object            { return "o($_[1];$_[2])" }
sub do_article           { return "art($_[1])" }
sub do_preposition       { return "pr($_[1])" }

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start   => 'sentence',
        actions => 'main',
        rules   => [
            [ 'sentence', [qw(subject verb adjunct)], 'do_sva_sentence' ],
            [ 'sentence', [qw(subject verb object)],  'do_svo_sentence' ],
            [ 'adjunct',  [qw(preposition object)], 'do_adjunct' ],
            [ 'adjective',   [qw(adjective_noun_lex)], 'do_adjective' ],
            [ 'subject',     [qw(adjective noun)], 'do_qualified_subject' ],
            [ 'subject',     [qw(noun)], 'do_bare_subject' ],
            [ 'noun',        [qw(adjective_noun_lex)], 'do_noun' ],
            [ 'verb',        [qw(verb_lex)], 'do_verb' ],
            [ 'object',      [qw(article noun)], 'do_object' ],
            [ 'article',     [qw(article_lex)], 'do_article' ],
            [ 'preposition', [qw(preposition_lex)], 'do_preposition' ],
        ],
    }
);

my $expected = <<'EOS';
sva(s(n(fruit));v(flies);adju(pr(like);o(art(a);n(banana))))
sva(s(n(time));v(flies);adju(pr(like);o(art(an);n(arrow))))
svo(s(adje(fruit);n(flies));v(like);o(art(a);n(banana)))
svo(s(adje(time);n(flies));v(like);o(art(an);n(arrow)))
EOS
my @actual = ();

$grammar->precompute();

my %lexical_class = (
    'preposition_lex'    => 'like',
    'verb_lex'           => 'like flies',
    'adjective_noun_lex' => 'fruit banana time arrow flies',
    'article_lex'        => 'a an',
);
my %vocabulary = ();
while ( my ( $lexical_class, $words ) = each %lexical_class ) {
    for my $word ( split q{ }, $words ) {
        push @{ $vocabulary{$word} }, $lexical_class;
    }
}

for my $data ( 'time flies like an arrow', 'fruit flies like a banana' ) {

    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );
    die 'Failed to create recognizer' if not $recce;

    for my $word ( split q{ }, $data ) {

# Marpa::R2::Display
# name: Recognizer exhausted Synopsis

        $recce->exhausted() and die 'Recognizer exhausted';

# Marpa::R2::Display::End

        for my $type ( @{ $vocabulary{$word} } ) {
            $recce->alternative( $type, \$word, 1 )
                or die 'Recognition failed';
        }
        $recce->earleme_complete();
    } ## end for my $word ( split q{ }, $data )

# Marpa::R2::Display
# name: Recognizer end_input Synopsis

    $recce->end_input();

# Marpa::R2::Display::End

    while ( defined( my $value_ref = $recce->value() ) ) {
        my $value = $value_ref ? ${$value_ref} : 'No parse';
        push @actual, $value;
    }
} ## end for my $data ( 'time flies like an arrow', ...)

Marpa::R2::Test::is( ( join "\n", sort @actual ) . "\n",
    $expected, 'Ambiguous English sentences' );

1;    # In case used as "do" file

