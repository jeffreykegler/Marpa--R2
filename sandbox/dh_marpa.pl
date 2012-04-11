use 5.010;
use strict;
use warnings;
use Parse::RecDescent;
use Data::Dumper;
use Scalar::Util;
use Marpa::XS;

# A Marpa::XS parser for the Dyck-Hollerith language

my $repeat;
if (@ARGV) {
    $repeat = $ARGV[0];
    die "Argument not a number" if not Scalar::Util::looks_like_number($repeat);
}

sub arg2 { return $_[3]; }
sub do_what_I_mean {
    shift;
    my @children = grep {defined} @_;
    return scalar @children > 1 ? \@children : shift @children;
}

my $grammar = Marpa::XS::Grammar->new(
    {   start            => 'sentence',
        lhs_terminals => 0,
        default_action   => 'main::do_what_I_mean',
        rules            => [
            [ 'sentence', [qw(element)] ],
            [ 'string', [qw(S_count lparen text rparent)],   'main::arg2' ],
            [ 'array',  [qw(A_count lparen elements rparent)], 'main::arg2' ],
            { lhs => 'elements', rhs => [qw(element)], min => 0 },
            [ 'element', [qw(string)] ],
            [ 'element', [qw(array)] ],
        ]
    }
);

$grammar->precompute();
my $recce = Marpa::XS::Recognizer->new({ grammar => $grammar});

my $res;
if ($repeat) {
    $res = "A$repeat(" . ('A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))' x $repeat) . ')';
} else {
    $res = 'A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))';
}

exit 0;

while (length($res)) {
}

exit 0;
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


