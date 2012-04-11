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
my $recce = Marpa::XS::Recognizer->new({ grammar => $grammar, trace_terminals=>1});

my $res;
if ($repeat) {
    $res = "A$repeat(" . ('A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))' x $repeat) . ')';
} else {
    $res = 'A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))';
}

my $string_length = 0;

INPUT: for ( ;; ) {
    my @terminals_expected = @{$recce->terminals_expected()};

say "Expecting: ", join q{ }, @terminals_expected;

    my $found;
    my $expected_terminal;
    FIND_TOKEN:
    for my $i (0 .. $#terminals_expected) {
	$expected_terminal = $terminals_expected[$i];
        if ( 'Scount' eq $expected_terminal ) {
            $res =~ s{\A \d+}{$string_length = $found = ${^MATCH}, ''}epxmsg and last FIND_TOKEN;
        } ## end if ( 'Scount' eq $expected_terminal )
        if ( 'Acount' eq $expected_terminal ) {
            $res =~ s{\A \d+}{$found = ${^MATCH}, ''}epxmsg and last FIND_TOKEN;
        }
        if ( 'Achar' eq $expected_terminal ) {
            $res =~ s{\A A}{$found = ${^MATCH}, ''}epxmsg and last FIND_TOKEN;
        }
        if ( 'Schar' eq $expected_terminal ) {
            $res =~ s{\A S}{$found = ${^MATCH}, ''}epxmsg and last FIND_TOKEN;
        }
        if ( 'lparen' eq $expected_terminal ) {
            $res =~ s{\A [(]}{$found = ${^MATCH}, ''}epxmsg and last FIND_TOKEN;
	}
        if ( 'rparen' eq $expected_terminal ) {
            $res =~ s{\A [)]}{$found = ${^MATCH}, ''}epxmsg and last FIND_TOKEN;
	}
        if ( 'text' eq $expected_terminal ) {
	     $found = substr($res, 0, $string_length);
	     $res = substr($res, $string_length);
	     last FIND_TOKEN;
	}
    } ## end while ( defined( $expected_terminal = shift @{...}))
    if (not defined $found) {
	die("Error reading input: ",
	    substr( $res, 0, 100 ),
	    "\nWas expecting ",
	    join q{ }, @terminals_expected
	);
    }
say "Found ", $found;
    $recce->read($expected_terminal, $found);
    last INPUT if length $res <= 0;
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


