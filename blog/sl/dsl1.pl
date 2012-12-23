#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Getopt::Long;

use Marpa::R2 2.027_003;

my $do_demo = 0;
my $getopt_result = GetOptions( "demo!" => \$do_demo, );

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
$PROGRAM_NAME --demo
$PROGRAM_NAME 'exp' [...]

Run $PROGRAM_NAME with either the "--demo" argument
or a series of calculator expressions.
END_OF_USAGE_MESSAGE
} ## end sub usage

my $input_string;
if ( not $getopt_result ) {
    usage();
}
if ($do_demo) {
    if ( scalar @ARGV > 0 ) { say join " ", @ARGV; usage(); }
}
else { # NOT $do_demo
 if ( scalar @ARGV <= 0 ) { usage(); }
 $input_string = join " ", @ARGV;
}

my $grammar = Marpa::R2::Scanless::G->new(
    {   
        action_object  => 'My_Actions',
        default_action => 'do_what_I_mean',
        source          => \(<<'END_OF_GRAMMAR'),
:start ::= expression
expression ::=
     NUM
   | VAR
   | '(' expression ')' assoc => group action => do_parens
  || '-' expression action => do_uminus
  || expression '**' expression
    assoc => right action => do_power
  || expression '*' expression action => do_multiply
   | expression '/' expression action => do_divide
  || expression '+' expression action => do_add
   | expression '-' expression action => do_subtract
  || expression '&' expression action => do_bitand
  || expression '^' expression action => do_bitxor
   | expression '|' expression action => do_bitor
  || VAR '=' expression action => do_assign
NUM ~ [\d]+
VAR ~ [\w]
:discard ~ whitespace
whitespace ~ [\s]+
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
    }
);

sub calculate {
    my ($p_string) = @_;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

    ## A quasi-object, for internal use only
    local $My_Actions::SELF = bless {
        recce   => $recce,
        },
        'My_Actions';

    $recce->read($p_string);
    my $value_ref = $recce->value;

    if ( !defined $value_ref ) {
        say $recce->show_progress() or die "say failed: $ERRNO";
        die 'Parse failed';
    }
    return ${$value_ref};

} ## end sub calculate

sub report_calculation {
    my ($string) = @_;
    return qq{Input: "$string"\n} . '  Parse: ' . calculate(\$string) . "\n";
}

if (defined $input_string) {
    print report_calculation($input_string);
    exit 0;
}

my $output = join q{},
    report_calculation('4 * 3 + 42 / 1'),
    report_calculation('4 * 3 / (a = b = 5) + 42 - 1'),
    report_calculation('4 * 3 /  5 - - - 3 + 42 - 1'),
    report_calculation('- a - b'),
    report_calculation('1 * 2 + 3 * 4 ** 2 ** 2 ** 2 * 42 + 1');

print $output or die "print failed: $ERRNO";
$output eq <<'EXPECTED_OUTPUT' or die 'FAIL: Output mismatch';
Input: "4 * 3 + 42 / 1"
  Parse: [[4*3]+[42/1]]
Input: "4 * 3 / (a = b = 5) + 42 - 1"
  Parse: [[[[4*3]/([a=[b=5]])]+42]-1]
Input: "4 * 3 /  5 - - - 3 + 42 - 1"
  Parse: [[[[[4*3]/5]-[-[-3]]]+42]-1]
Input: "- a - b"
  Parse: [[-a]-b]
Input: "1 * 2 + 3 * 4 ** 2 ** 2 ** 2 * 42 + 1"
  Parse: [[[1*2]+[[3*[4**[2**[2**2]]]]*42]]+1]
EXPECTED_OUTPUT

package My_Actions;
our $SELF;
sub new { return $SELF }

sub do_what_I_mean {
    my ($self, @children) = @_;
    return $children[0] if scalar @children == 1;
    return \@children;
} ## end sub do_what_I_mean

sub do_parens   { shift; return '(' . $_[1] . ')' }
sub do_power    { shift; return '[' . $_[0] . '**' . $_[2] . ']' }
sub do_multiply { shift; return '[' . $_[0] . '*' . $_[2] . ']' }
sub do_divide   { shift; return '[' . $_[0] . '/' . $_[2] . ']' }
sub do_add      { shift; return '[' . $_[0] . '+' . $_[2] . ']' }
sub do_subtract { shift; return '[' . $_[0] . '-' . $_[2] . ']' }
sub do_bitand   { shift; return '[' . $_[0] . '&' . $_[2] . ']' }
sub do_bitxor   { shift; return '[' . $_[0] . '^' . $_[2] . ']' }
sub do_bitor    { shift; return '[' . $_[0] . '|' . $_[2] . ']' }
sub do_uminus   { shift; return '[-' . $_[1] . ']' }
sub do_assign   { shift; return '[' . $_[0] . '=' . $_[2] . ']' }

