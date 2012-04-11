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


