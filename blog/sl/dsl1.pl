#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Marpa::R2 2.027_003;

use Data::Dumper;

my $grammar = Marpa::R2::Grammar->new(
    {   scannerless => 1,
        action_object        => 'My_Actions',
        default_action => 'do_what_I_mean',
        rules          => <<'END_OF_GRAMMAR',
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
NUM ~ [\d]+ action => do_literal
VAR ~ [\w]+ action => do_literal
END_OF_GRAMMAR
    }
);
$grammar->precompute;

sub calculate {
    my ($string) = @_;
    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    ## A quasi-object, for internal use only
    my $self = bless {
        grammar => $grammar,
        recce   => $recce,
        },
        'My_Actions';

    local $My_Actions::SELF = $self;
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
    my $self = shift;
    my @children = grep { defined } @_;
    if (not scalar @children) {
      return $self->do_literal();
    }
    return $children[0] if scalar @children == 1;
    return \@children;
} ## end sub add_brackets

sub do_parens { shift; return '(' . $_[0] . ')' }
sub do_power { shift; return '[' . $_[0] . '**' . $_[1] . ']' };
sub do_multiply { shift; return '[' . $_[0] . '*' . $_[1] . ']' };
sub do_divide { shift; return '[' . $_[0] . '/' . $_[1] . ']' };
sub do_add { shift; return '[' . $_[0] . '+' . $_[1] . ']' };
sub do_subtract { shift; return '[' . $_[0] . '-' . $_[1] . ']' };
sub do_bitand { shift; return '[' . $_[0] . '&' . $_[1] . ']' };
sub do_bitxor { shift; return '[' . $_[0] . '^' . $_[1] . ']' };
sub do_bitor { shift; return '[' . $_[0] . '|' . $_[1] . ']' };
sub do_uminus { shift; return '[-' . $_[0] . ']' };
sub do_assign { shift; return '[' . $_[0] . '=' . $_[1] . ']' };

sub do_literal {
    my $self  = shift;
    my $recce = $self->{recce};
    my ( $start, $end ) = Marpa::R2::Context::location();
    my $literal = $recce->sl_range_to_string( $start, $end );
    $literal =~ s/ \s+ \z //xms;
    $literal =~ s/ \A \s+ //xms;
    return $literal;
} ## end sub do_literal

