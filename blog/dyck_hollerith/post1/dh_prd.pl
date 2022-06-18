# Copyright 2022 Jeffrey Kegler
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

use 5.010;
use strict;
use warnings;
use Parse::RecDescent;
use Data::Dumper;
use Scalar::Util;

# Flavio Polletti's parser for the Dyck-Hollerith language

my $repeat;
if (@ARGV) {
    $repeat = $ARGV[0];
    die "Argument not a number" if not Scalar::Util::looks_like_number($repeat);
}

my $grammar = <<'END_OF_GRAMMAR';
length: /\d+/

string: 'S' length '('
   {
      $return = substr $text, 0, $item{length}, '';
      1;
   }
   ')'

any: string | array
any_with_offset: <rulevar: $length> # $thisoffset not reliable
any_with_offset: { $length = length($text) } any
   {
      $return =  {
         value  => $item{any},
         offset => $length - length($text),
      };
   }

array: 'A' length '('
   {
      my @sequence;
      for my $i (1 .. $item{length}) {
         my $record = $thisparser->any_with_offset($text);
         push @sequence, $record->{value};
         substr $text, 0, $record->{offset}, '';
      }
      $return = \@sequence;
   }
   ')'
END_OF_GRAMMAR

my $parser = Parse::RecDescent->new($grammar);
my $res;
if ($repeat) {
    $res = $parser->any("A$repeat(" . ('A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))' x $repeat) . ')');
} else {
    $res = $parser->any('A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))');
}
my $received = Dumper($res);
my $expected = <<'EXPECTED_OUTPUT';
$VAR1 = [
          [
            'Hey',
            'Hello, World!'
          ],
          'Ciao!'
        ];
EXPECTED_OUTPUT
if ( $received eq $expected )
{
    say "Output matches";
} else {
    say "Output differs: $received";
}


