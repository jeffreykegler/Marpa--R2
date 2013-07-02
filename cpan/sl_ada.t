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
:default ::= action => ::array
:start ::= root
root ::= lexeme+

lexeme ~ word
word ~ [\w']+
lexeme ~ ','
lexeme ~ ':'
:discard ~ whitespace
whitespace ~ [\s]+
:discard ~ [.]
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Actions',
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

my %punctuation = ( q{,} => 'comma', q{:} => 'colon' );
my $quote_length = length $quotation;
$recce->read(\$quotation, 0, 0);
$quotation =~ m/  [^\s] /xmsg;
LEXEME: while ( pos $quotation < $quote_length ) {

    # Space forward
    $quotation =~ m/ \G ( [\s]* ) /gxms;
    my ($match) = ($quotation =~ m/ \G ( [\w]+ ) /gxmsc);
    if (defined $match) {
        say STDERR qq{Found "$match" at }, pos $quotation;
        next LEXEME;
    }
    my $next_char = substr $quotation, ( pos $quotation ), 1 ;
    my $punctuation = $punctuation{ $next_char };
    die qq{Unknown char ("$next_char") at pos }, (pos $quotation), " in quote"
        if not  defined $punctuation ;
    say STDERR qq{Found "$punctuation" at }, pos $quotation;
    pos $quotation = (pos $quotation) + 1;
} ## end LEXEME: while ( pos $quotation < $quote_length )

exit 0;

my $parse_count = 0;
VALUE: while ( my $value_ref = $recce->value() ) {
    say Data::Dumper::Dumper($value_ref );
    $parse_count++;
    last VALUE;
}

say 'Parse count: ', $parse_count;

package My_Actions;
our $SELF;
sub new { return $SELF }

my $lexeme_data = <<'END_OF_DATA';
's/POS
,/,
./.
:/:
Creator/NN
a/DT
abstract/JJ
adequately/RB
agencies/NNS
all/DT
alone/RB
amidst/NN
and/CC
are/VBP
as/IN
as/RB
beauty/NN
body/NN
but/CC
can/MD
changes/NNS
completeness/NNS
connexion/NN
consciously/JJ
constitutes/VBZ
creation/NN
deeper/JJR
do/VBP
effectually/RB
entitle/VBP
especial/JJ
explicit/JJ
express/VB
facilitate/VB
facts/NNS
first/JJ
for/IN
forms/NNS
going/VBG
great/JJ
his/PRP$
human/JJ
immediate/JJ
immutable/JJ
in/IN
instrument/NN
interest/NN
interminably/RB
into/IN
intrinsic/NNS
invisibly/JJ
is/VBZ
it/PRP
its/PRP$
language/NN
live/VBP
logical/JJ
man/NN
math/NN
mathematical/JJ
merely/RB
mind/NN
minds/NNS
most/RBS
mutual/JJ
natural/JJ
not/RB
of/IN
on/IN
or/CC
other/JJ
our/PRP$
perceptions/NNS
physical/JJ
place/NN
possessing/VBG
practical/JJ
principles/NNS
profound/JJ
prominent/JJ
race/NN
read/VB
regard/VB
regarded/VBN
relationship/NN
remembered/VBN
science/NN
something/NN
symmetry/NN
tend/VB
that/DT
that/IN
that/WDT
the/DT
their/PRP$
them/PRP
thing/NN
things/NNS
think/VBP
this/DT
those/DT
through/IN
thus/RB
to/TO
together/RB
translation/NN
truth/NN
truths/NNS
unceasing/VBG
unconsciously/JJ
vast/JJ
view/VBP
visibly/JJ
we/PRP
weak/JJ
when/WRB
which/WDT
who/WP
whole/NN
whose/WP$
will/MD
with/IN
works/NNS
world/NN
yet/RB
END_OF_DATA

# vim: expandtab shiftwidth=4:
