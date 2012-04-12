use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util;
use Marpa::XS;

# A Marpa::XS parser for the Dyck-Hollerith language

my $repeat;
if (@ARGV) {
    $repeat = $ARGV[0];
    die "Argument not a number" if not Scalar::Util::looks_like_number($repeat);
}

sub arg1 { return $_[1]; }
sub arg4 { return $_[4]; }
sub all_args { shift; return \@_; }

my $grammar = Marpa::XS::Grammar->new(
    {   start            => 'sentence',
        lhs_terminals => 0,
        rules            => [
            [ 'sentence', [qw(element)], 'main::arg1' ],
            [ 'string', [qw(Schar Scount lparen text rparen)],   'main::arg4' ],
            [ 'array',  [qw(Achar Acount lparen elements rparen)], 'main::arg4' ],
            { lhs => 'elements', rhs => [qw(element)], min => 1, action=>'main::all_args' },
            [ 'element', [qw(string)], 'main::arg1' ],
            [ 'element', [qw(array)], 'main::arg1' ],
        ]
    }
);

$grammar->precompute();
my $recce = Marpa::XS::Recognizer->new({ grammar => $grammar });

my $res;
if ($repeat) {
    $res = "A$repeat(" . ('A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))' x $repeat) . ')';
} else {
    $res = 'A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))';
}

my $string_length = 0;
my $position = 0;
my $input_length = length $res;

INPUT: while ($position < $input_length) {
	pos $res = $position;
	if ($res =~ m/\G S (\d+) [(]/xms) {
            my $string_length = $1;
	    $recce->read( 'Schar');
	    $recce->read( 'Scount' );
	    $recce->read( 'lparen' );
	    $position += 2 + (length $string_length);
	    $recce->read( 'text', substr( $res, $position, $string_length ));
	    $position += $string_length;
            next INPUT;
        }
	if ($res =~ m/\G A (\d+) [(]/xms) {
            my $count = $1;
	    $recce->read( 'Achar');
	    $recce->read( 'Acount' );
	    $recce->read( 'lparen' );
	    $position += 2 + length $count;
            next INPUT;
        }
        if ( $res =~ m{\G [)] }xms ) {
	    $recce->read( 'rparen' );
	    $position += 1;
            next INPUT;
        }
        die "Error reading input: ", substr( $res, $position, 100 );
} ## end for ( ;; )

my $result = $recce->value();
die "No parse" if not defined $result;
my $received = Dumper(${$result});

my $expected = <<'EXPECTED_OUTPUT';
$VAR1 = [
          [
            'Hey',
            'Hello, World!'
          ],
          'Ciao!'
        ];
EXPECTED_OUTPUT
if ($received eq $expected )
{
    say "Output matches";
} else {
    say "Output differs: $received";
}


