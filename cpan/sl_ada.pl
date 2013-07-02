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

use Marpa::R2 2.040000;

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
:start ::= sentence
sentence ::= subject unimplemented
subject ::= <noun phrase> appositives
appositives ::= <noun phrase>*
<noun phrase> ::= <pro form>
<noun phrase> ::= <adjectives> <noun>
<adjectives> ::= <adjective>*
<noun phrase> ::= <relative clause>
<relative clause> ::= <pro form> <verb phrase> <object>
<verb phrase> ::= <auxiliary verbs> <main verb>
<auxiliary verbs> ::= <auxiliary verb>*
<object> ::= <noun phrase>
unimplemented ::= word+

<pro form> ~ 'those' | 'who'
<main verb> ~ 'view'
<auxiliary verb> ~ 'will'
<noun> ~ 'science'
<adjective> ~ 'mathematical'
word ~ [\w']+
:discard ~ whitespace
whitespace ~ [\s]+
:discard ~ [,:.]
# allow comments
:discard ~ <hash comment>
<hash comment> ~ <terminated hash comment> | <unterminated
   final hash comment>
<terminated hash comment> ~ '#' <hash comment body> <vertical space char>
<unterminated final hash comment> ~ '#' <hash comment body>
<hash comment body> ~ <hash comment char>*
<vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
<hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Actions',
        default_action => 'do_what_i_mean',
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

$recce->read(\$quotation);

sub unimplemented_count {
    my ($arg) = @_;
    return 0 if ref $arg ne 'ARRAY';
    my ($type, @rest) = @{$arg};
    return scalar @rest if $type eq 'unimplemented';
    return List::Util::sum 0, map { unimplemented_count($_) } @rest;
}

my $parse_count = 0;
my $best_so_far;
my $best_result;

while ( my $value_ref = $recce->value() ) {
    $parse_count++;
    my $unimplemented_count = unimplemented_count(${$value_ref});
    if (not defined $best_so_far or $unimplemented_count < $best_so_far) {
        $best_so_far = $unimplemented_count;
        $best_result = $value_ref;
    }
}
say Data::Dumper::Dumper( ${$best_result} );
say 'Parse count: ', $parse_count;

package My_Actions;
our $SELF;
sub new { return $SELF }

sub do_what_i_mean {
    my $self = shift;
    my @children = grep { defined } @_;
    my $child_count = scalar @children;
    my $raw_child_count = scalar @_;
    return undef if not $child_count;
    if ($raw_child_count == 1 and $child_count == 1 and not ref $children[0]) {
        my (undef, $rhs) = $Marpa::R2::Context::grammar->rule($Marpa::R2::Context::rule);
        return [ $rhs =>
         [$Marpa::R2::Context::grammar->rule($Marpa::R2::Context::rule)],
        $children[0] ];
    }
    my ($lhs) = $Marpa::R2::Context::grammar->rule($Marpa::R2::Context::rule);
    return [ $lhs, 
         [$Marpa::R2::Context::grammar->rule($Marpa::R2::Context::rule)],
     @children ];
}

# vim: expandtab shiftwidth=4:
