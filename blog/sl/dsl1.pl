#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Marpa::R2 2.027_003;

use Data::Dumper;

sub add_brackets {
    my ( undef, @children ) = @_;
    return $children[0] if 1 == scalar @children;
    my $original = join q{}, grep {defined} @children;
    return '[' . $original . ']';
} ## end sub add_brackets

my $grammar = Marpa::R2::Grammar->new(
    {   scannerless => 1,
        actions        => __PACKAGE__,
        default_action => 'add_brackets',
        rules          => <<'END_OF_GRAMMAR',
:start ::= expression
expression ::=
     NUM
   | VAR
   | '(' expression ')' assoc => group
  || '-' expression
  || expression '^' expression assoc => right
  || expression '*' expression
   | expression '/' expression
  || expression '+' expression
   | expression '-' expression
  || VAR '=' expression
NUM ~ [\d]+
VAR ~ [\w]+
END_OF_GRAMMAR
    }
);
$grammar->precompute;

sub calculate {
    my ($string) = @_;
    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    $recce->sl_read($string);
    my $value_ref = $recce->value;

    if ( !defined $value_ref ) {
        say $recce->show_progress() or die "say failed: $ERRNO";
        die 'Parse failed';
    }
    return ${$value_ref};

} ## end sub calculate

sub report_calculation {
    my ($string) = @_;
    return qq{Input: "$string"\n} . '  Parse: ' . calculate($string) . "\n";
}

my $output = join q{},
    report_calculation('4 * 3 + 42 / 1'),
    report_calculation('4 * 3 / (a = b = 5) + 42 - 1'),
    report_calculation('4 * 3 /  5 - - - 3 + 42 - 1'),
    report_calculation('- a - b'),
    report_calculation('1 * 2 + 3 * 4 ^ 2 ^ 2 ^ 2 * 42 + 1');

print $output or die "print failed: $ERRNO";
$output eq <<'EXPECTED_OUTPUT' or die 'FAIL: Output mismatch';
Input: "4 * 3 + 42 / 1"
  Parse: [[4*3]+[42/1]]
Input: "4 * 3 / (a = b = 5) + 42 - 1"
  Parse: [[[[4*3]/[([a=[b=5]])]]+42]-1]
Input: "4 * 3 /  5 - - - 3 + 42 - 1"
  Parse: [[[[[4*3]/5]-[-[-3]]]+42]-1]
Input: "- a - b"
  Parse: [[-a]-b]
Input: "1 * 2 + 3 * 4 ^ 2 ^ 2 ^ 2 * 42 + 1"
  Parse: [[[1*2]+[[3*[4^[2^[2^2]]]]*42]]+1]
EXPECTED_OUTPUT
