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

sub arg3 { return $_[4]; }
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
            [ 'string', [qw(Schar Scount lparen text rparen)],   'main::arg3' ],
            [ 'array',  [qw(Achar Acount lparen elements rparen)], 'main::arg3' ],
            { lhs => 'elements', rhs => [qw(element)], min => 0 },
            [ 'element', [qw(string)] ],
            [ 'element', [qw(array)] ],
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
pos $res = 0;

INPUT: for ( ;; ) {
    my @terminals_expected = @{ $recce->terminals_expected() };
    last INPUT if length $res <= pos $res;
        if ( 'Schar' ~~ \@terminals_expected and $res =~ m{\G S (\d+) [(] }pxmsgc ) {
	    $recce->read( 'Schar', 'S' );
	    $recce->read( 'Scount', $1 );
            $string_length = $1;
	    $recce->read( 'lparen' );
	    $recce->read( 'text', substr( $res, pos($res), $string_length ));
            pos ($res) += $string_length;
            next INPUT;
        }
        if ( $res =~ m{\G (\d+)}pxmsgc ) {
	    $recce->read( 'Acount', $1 );
            next INPUT;
        }
        if ( $res =~ m{\G A }pxmsgc ) {
	    $recce->read( 'Achar' );
            next INPUT;
        }
        if ( $res =~ m{\G [(] }pxmsgc ) {
	    $recce->read( 'lparen' );
            next INPUT;
        }
        if ( $res =~ m{\G [)] }pxmsgc ) {
	    $recce->read( 'rparen' );
            next INPUT;
        }
    say "POS=", pos($res);
        die("Error reading input: ",
            substr( $res, 0, 100 ),
            "\nWas expecting ",
            join q{ }, @terminals_expected
        );
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


