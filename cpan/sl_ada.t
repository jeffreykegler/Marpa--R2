#!perl
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

# Demo of scannerless parsing -- a calculator DSL

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use GetOpt::Long;

use Marpa::R2;

sub usage {

    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME
    $PROGRAM_NAME --stdin < file
With --stdin arg, reads expression from standard input.
By default, runs a test.
END_OF_USAGE_MESSAGE
} ## end sub usage

my $stdin_flag = 0;
my $getopt_result = Getopt::Long::GetOptions( 'stdin!' => \$stdin_flag, );
usage() if not $getopt_result;

my $input;
if ($stdin_flag) {
    $input = do { local $INPUT_RECORD_SEPARATOR = undef; <> };
}

my $rules = <<'END_OF_GRAMMAR';
:default ::= action => ::array bless => ::lhs
lexeme default = action => [value] bless => ::name
:start ::= <my start>
<my start> ::= root trailer
root ::= NP WHNP S CONJP VBG NP PP comma WHADVP S
ADJP ::= JJ CC JJ
ADJP ::= RB JJR
ADVP ::= RB
ADVP ::= ADVP PP
ADVP ::= ADVP CC ADVP
ADVP ::= ADVP comma ADVP
CONJP ::= RB RB IN
CONJP ::= CC RB
NP ::= <PRP S> NN
NP ::= ADJP NNS
NP ::= DT
NP ::= DT JJ CC JJ NNS
NP ::= DT JJ NN
NP ::= DT JJ NNS
NP ::= DT ADJP NN
NP ::= DT NN
NP ::= DT NNS
NP ::= DT VBG NNS
NP ::= JJ NN
NP ::= NN
NP ::= NP comma CC NP
NP ::= NN comma NN CC JJ NNS
NP ::= NP comma SBAR comma
NP ::= NP comma CONJP NP
NP ::= NP PP
NP ::= NP SBAR
NP ::= PRP
PP ::= ADVP IN NP
PP ::= IN NP
PP ::= IN IN NP
PP ::= TO NP
PP ::= TO <PRP S> JJ JJ NNS
S ::= ADVP NP VP
S ::= NP VP
S ::= VP
SBAR ::= WHADVP S
SBAR ::= WHNP S
SBAR ::= WHPP S
SBAR ::= WHNP comma ADVP comma S
SBAR ::= S
SBAR ::= IN S
VP ::= VB NP
VP ::= VBG PP
VP ::= VBN PP PP
VP ::= VBN SBAR
VP ::= VBP NP
VP ::= VBZ NP
VP ::= VBZ VP
VP ::= VBP NP PP
VP ::= VBP ADVP VP
VP ::= MD ADVP VP
WHADVP ::= WRB
WHNP ::= <WP S> NNS
WHNP ::= WP
WHNP ::= WDT
WHPP ::= IN WHNP

trailer ::= lexeme+
lexeme ::= CC | DT | IN | JJ | JJR | MD | NN | NNS |
    POS | PRP | <PRP S> | RB | RBS | TO |
    VB | VBG | VBN | VBP | VBZ |
    WDT | WP | <WP S> | WRB

lexeme ::= comma
lexeme ::= colon
lexeme ::= period

CC ~ never
DT ~ never
IN ~ never
JJ ~ never
JJR ~ never
MD ~ never
NN ~ never
NNS ~ never
POS ~ never
PRP ~ never
<PRP S> ~ never
RB ~ never
RBS ~ never
TO ~ never
VB ~ never
VBG ~ never
VBN ~ never
VBP ~ never
VBZ ~ never
WDT ~ never
WP ~ never
<WP S> ~ never
WRB ~ never

never ~ [^\d\D]
comma ~ ','
colon ~ ':'
period ~ '.'
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Nodes',
        bless_package => 'My_Nodes',
        source         => \$rules,
    }
);

my $quotation = <<'END_OF_QUOTATION';
Those who view mathematical science,
not merely as a vast body of abstract and immutable truths,
whose intrinsic beauty,
symmetry and logical completeness,
when regarded in their connexion together as a whole,
entitle them to a prominent place in the interest of all profound
and logical minds,
but as possessing a yet deeper interest for the human race,
when it is remembered that this science constitutes the language
through which alone we can adequately express the great facts of
the natural world,
and those unceasing changes of mutual relationship which,
visibly or invisibly,
consciously or unconsciously to our immediate physical perceptions,
are interminably going on in the agencies of the creation we live amidst:
those who thus think on mathematical truth as the instrument through
which the weak mind of man can most effectually read his Creator's
works,
will regard with especial interest all that can tend to facilitate
the translation of its principles into explicit practical forms.
END_OF_QUOTATION

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar, trace_terminals => 99 } );

my %punctuation = ( q{,} => 'comma', q{:} => 'colon', q{.} => 'period' );
my $lexeme_data = setup_lexemes();
# die Data::Dumper::Dumper($lexeme_data);
my $quote_length = length $quotation;
$recce->read(\$quotation, 0, 0);
LEXEME: while ( 1 ) {

    # Space forward
    $quotation =~ m/ \G ( [\s]* ) /gxms;
    my $start = pos $quotation;
    last LEXEME if $start >= $quote_length ;
    my ($match) = ($quotation =~ m/ \G ( [']? [\w]+ ) /gxmsc);
    if ( defined $match ) {
        my $lexemes = $lexeme_data->{ lc $match };
        die qq{Unknown lexeme "$match"} if not defined $lexemes;
        for my $lexeme ( @{$lexemes} ) {
            $recce->lexeme_alternative($lexeme, $match);
            # say STDERR qq{Found "$match" as "$lexeme" at }, pos $quotation;
        }
        $recce->lexeme_complete($start, (pos $quotation) - $start);
        next LEXEME;
    } ## end if ( defined $match )
    my $next_char = substr $quotation, ( pos $quotation ), 1 ;
    my $punctuation = $punctuation{ $next_char };
    die qq{Unknown char ("$next_char") at pos }, (pos $quotation), " in quote"
        if not  defined $punctuation ;
    $recce->lexeme_alternative($punctuation, $next_char);
    $recce->lexeme_complete($start, 1);
    # say STDERR qq{Found "$punctuation" at $start};
    pos $quotation = (pos $quotation) + 1;
} ## end LEXEME: while ( pos $quotation < $quote_length )

my $parse_count = 0;
VALUE: while ( my $value_ref = $recce->value() ) {
    say Data::Dumper::Dumper($value_ref );
    $parse_count++;
    last VALUE;
}

say 'Parse count: ', $parse_count;

sub setup_lexemes {
    my %lexeme_data = ();
    push @{ $lexeme_data{"'s"} },            'POS';
    push @{ $lexeme_data{'creator'} },       'NN';
    push @{ $lexeme_data{'a'} },             'DT';
    push @{ $lexeme_data{'abstract'} },      'JJ';
    push @{ $lexeme_data{'adequately'} },    'RB';
    push @{ $lexeme_data{'agencies'} },      'NNS';
    push @{ $lexeme_data{'all'} },           'DT';
    push @{ $lexeme_data{'alone'} },         'RB';
    push @{ $lexeme_data{'amidst'} },        'NN';
    push @{ $lexeme_data{'and'} },           'CC';
    push @{ $lexeme_data{'are'} },           'VBP';
    push @{ $lexeme_data{'as'} },            'IN';
    push @{ $lexeme_data{'as'} },            'RB';
    push @{ $lexeme_data{'beauty'} },        'NN';
    push @{ $lexeme_data{'body'} },          'NN';
    push @{ $lexeme_data{'but'} },           'CC';
    push @{ $lexeme_data{'can'} },           'MD';
    push @{ $lexeme_data{'changes'} },       'NNS';
    push @{ $lexeme_data{'completeness'} },  'NNS';
    push @{ $lexeme_data{'connexion'} },     'NN';
    push @{ $lexeme_data{'consciously'} },   'RB';
    push @{ $lexeme_data{'constitutes'} },   'VBZ';
    push @{ $lexeme_data{'creation'} },      'NN';
    push @{ $lexeme_data{'deeper'} },        'JJR';
    push @{ $lexeme_data{'do'} },            'VBP';
    push @{ $lexeme_data{'effectually'} },   'RB';
    push @{ $lexeme_data{'entitle'} },       'VBP';
    push @{ $lexeme_data{'especial'} },      'JJ';
    push @{ $lexeme_data{'explicit'} },      'JJ';
    push @{ $lexeme_data{'express'} },       'VB';
    push @{ $lexeme_data{'facilitate'} },    'VB';
    push @{ $lexeme_data{'facts'} },         'NNS';
    push @{ $lexeme_data{'first'} },         'JJ';
    push @{ $lexeme_data{'for'} },           'IN';
    push @{ $lexeme_data{'forms'} },         'NNS';
    push @{ $lexeme_data{'going'} },         'VBG';
    push @{ $lexeme_data{'great'} },         'JJ';
    push @{ $lexeme_data{'his'} },           'PRP S';
    push @{ $lexeme_data{'human'} },         'JJ';
    push @{ $lexeme_data{'immediate'} },     'JJ';
    push @{ $lexeme_data{'immutable'} },     'JJ';
    push @{ $lexeme_data{'in'} },            'IN';
    push @{ $lexeme_data{'instrument'} },    'NN';
    push @{ $lexeme_data{'interest'} },      'NN';
    push @{ $lexeme_data{'interminably'} },  'RB';
    push @{ $lexeme_data{'into'} },          'IN';
    push @{ $lexeme_data{'intrinsic'} },     'NNS';
    push @{ $lexeme_data{'invisibly'} },     'RB';
    push @{ $lexeme_data{'is'} },            'VBZ';
    push @{ $lexeme_data{'it'} },            'PRP';
    push @{ $lexeme_data{'its'} },           'PRP S';
    push @{ $lexeme_data{'language'} },      'NN';
    push @{ $lexeme_data{'live'} },          'VBP';
    push @{ $lexeme_data{'logical'} },       'JJ';
    push @{ $lexeme_data{'man'} },           'NN';
    push @{ $lexeme_data{'math'} },          'NN';
    push @{ $lexeme_data{'mathematical'} },  'JJ';
    push @{ $lexeme_data{'merely'} },        'RB';
    push @{ $lexeme_data{'mind'} },          'NN';
    push @{ $lexeme_data{'minds'} },         'NNS';
    push @{ $lexeme_data{'most'} },          'RBS';
    push @{ $lexeme_data{'mutual'} },        'JJ';
    push @{ $lexeme_data{'natural'} },       'JJ';
    push @{ $lexeme_data{'not'} },           'RB';
    push @{ $lexeme_data{'of'} },            'IN';
    push @{ $lexeme_data{'on'} },            'IN';
    push @{ $lexeme_data{'or'} },            'CC';
    push @{ $lexeme_data{'other'} },         'JJ';
    push @{ $lexeme_data{'our'} },           'PRP S';
    push @{ $lexeme_data{'perceptions'} },   'NNS';
    push @{ $lexeme_data{'physical'} },      'JJ';
    push @{ $lexeme_data{'place'} },         'NN';
    push @{ $lexeme_data{'possessing'} },    'VBG';
    push @{ $lexeme_data{'practical'} },     'JJ';
    push @{ $lexeme_data{'principles'} },    'NNS';
    push @{ $lexeme_data{'profound'} },      'JJ';
    push @{ $lexeme_data{'prominent'} },     'JJ';
    push @{ $lexeme_data{'race'} },          'NN';
    push @{ $lexeme_data{'read'} },          'VB';
    push @{ $lexeme_data{'regard'} },        'VB';
    push @{ $lexeme_data{'regarded'} },      'VBN';
    push @{ $lexeme_data{'relationship'} },  'NN';
    push @{ $lexeme_data{'remembered'} },    'VBN';
    push @{ $lexeme_data{'science'} },       'NN';
    push @{ $lexeme_data{'something'} },     'NN';
    push @{ $lexeme_data{'symmetry'} },      'NN';
    push @{ $lexeme_data{'tend'} },          'VB';
    push @{ $lexeme_data{'that'} },          'DT';
    push @{ $lexeme_data{'that'} },          'IN';
    push @{ $lexeme_data{'that'} },          'WDT';
    push @{ $lexeme_data{'the'} },           'DT';
    push @{ $lexeme_data{'their'} },         'PRP S';
    push @{ $lexeme_data{'them'} },          'PRP';
    push @{ $lexeme_data{'thing'} },         'NN';
    push @{ $lexeme_data{'things'} },        'NNS';
    push @{ $lexeme_data{'think'} },         'VBP';
    push @{ $lexeme_data{'this'} },          'DT';
    push @{ $lexeme_data{'those'} },         'DT';
    push @{ $lexeme_data{'through'} },       'IN';
    push @{ $lexeme_data{'thus'} },          'RB';
    push @{ $lexeme_data{'to'} },            'TO';
    push @{ $lexeme_data{'together'} },      'RB';
    push @{ $lexeme_data{'translation'} },   'NN';
    push @{ $lexeme_data{'truth'} },         'NN';
    push @{ $lexeme_data{'truths'} },        'NNS';
    push @{ $lexeme_data{'unceasing'} },     'VBG';
    push @{ $lexeme_data{'unconsciously'} }, 'RB';
    push @{ $lexeme_data{'vast'} },          'JJ';
    push @{ $lexeme_data{'view'} },          'VBP';
    push @{ $lexeme_data{'visibly'} },       'RB';
    push @{ $lexeme_data{'we'} },            'PRP';
    push @{ $lexeme_data{'weak'} },          'JJ';
    push @{ $lexeme_data{'when'} },          'WRB';
    push @{ $lexeme_data{'which'} },         'WDT';
    push @{ $lexeme_data{'who'} },           'WP';
    push @{ $lexeme_data{'whole'} },         'NN';
    push @{ $lexeme_data{'whose'} },         'WP S';
    push @{ $lexeme_data{'will'} },          'MD';
    push @{ $lexeme_data{'with'} },          'IN';
    push @{ $lexeme_data{'works'} },         'NNS';
    push @{ $lexeme_data{'world'} },         'NN';
    push @{ $lexeme_data{'yet'} },           'RB';
    return \%lexeme_data;
} ## end sub setup_lexemes

package My_Nodes;
our $SELF;
sub new { return $SELF }

# vim: expandtab shiftwidth=4:
