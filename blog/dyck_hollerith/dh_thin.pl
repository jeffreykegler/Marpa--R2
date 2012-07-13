use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util;
use Marpa::R2;

# A Marpa::R2 parser for the Dyck-Hollerith language

my @stack = ();
my @token_values = ('Do not use position zero');

my $repeat;
if (@ARGV) {
    $repeat = $ARGV[0];
    die "Argument not a number" if not Scalar::Util::looks_like_number($repeat);
}

sub arg1 { return $_[1]; }
sub arg4 { return $_[4]; }
sub all_args { shift; return \@_; }

my $grammar = Marpa::R2::Thin::G->new( { if =>1 } );
my $sentence_symbol = $grammar->symbol_new();
my $string_symbol = $grammar->symbol_new();
my $array_symbol = $grammar->symbol_new();
my $elements_symbol = $grammar->symbol_new();
my $element_symbol = $grammar->symbol_new();
my $Schar_symbol = $grammar->symbol_new();
my $Scount_symbol = $grammar->symbol_new();
my $Achar_symbol = $grammar->symbol_new();
my $Acount_symbol = $grammar->symbol_new();
my $lparen_symbol = $grammar->symbol_new();
my $rparen_symbol = $grammar->symbol_new();
my $text_symbol = $grammar->symbol_new();
$grammar->start_symbol_set($sentence_symbol);
my $sentence_rule = $grammar->rule_new($sentence_symbol, [$element_symbol]);
my $string_rule = $grammar->rule_new(
    $string_symbol,
    [   $Schar_symbol, $Scount_symbol, $lparen_symbol,
        $text_symbol,  $rparen_symbol
    ]
);
my $array_rule = $grammar->rule_new(
    $array_symbol,
    [   $Achar_symbol,    $Acount_symbol, $lparen_symbol,
        $elements_symbol, $rparen_symbol
    ]
);
my $element_string_rule =
    $grammar->rule_new( $element_symbol, [$string_symbol] );
my $element_array_rule =
    $grammar->rule_new( $element_symbol, [$array_symbol] );
my $elements_rule =
    $grammar->sequence_new( $elements_symbol, $element_symbol, { min => 1 } );
$grammar->precompute();

my $recce = Marpa::R2::Thin::R->new( $grammar);
$recce->start_input();

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
	    $recce->alternative( $Schar_symbol, 0, 1); $recce->earleme_complete();
	    $recce->alternative( $Scount_symbol, 0, 1 ); $recce->earleme_complete();
	    $recce->alternative( $lparen_symbol, 0, 1 ); $recce->earleme_complete();
	    $position += 2 + (length $string_length);
	    my $token_ix = -1 + push @token_values, substr( $res, $position, $string_length );
	    $recce->alternative( $text_symbol, $token_ix, 1);
	    $recce->earleme_complete();
	    $position += $string_length;
            next INPUT;
        }
	if ($res =~ m/\G A (\d+) [(]/xms) {
            my $count = $1;
	    $recce->alternative( $Achar_symbol, 0, 1); $recce->earleme_complete();
	    $recce->alternative( $Acount_symbol, 0, 1 ); $recce->earleme_complete();
	    $recce->alternative( $lparen_symbol, 0, 1 ); $recce->earleme_complete();
	    $position += 2 + length $count;
            next INPUT;
        }
        if ( $res =~ m{\G [)] }xms ) {
	    $recce->alternative( $rparen_symbol, 0, 1 ); $recce->earleme_complete();
	    $position += 1;
            next INPUT;
        }
        die "Error reading input: ", substr( $res, $position, 100 );
} ## end for ( ;; )

my $latest_earley_set_ID = $recce->latest_earley_set();
my $bocage        = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
my $order         = Marpa::R2::Thin::O->new($bocage);
my $tree          = Marpa::R2::Thin::T->new($order);
if (not defined $tree->next()) { die "No parse" }
my $valuator          = Marpa::R2::Thin::V->new($tree);
$valuator->rule_is_valued_set($sentence_rule, 1);
$valuator->rule_is_valued_set($string_rule, 1);
$valuator->rule_is_valued_set($array_rule, 1);
$valuator->rule_is_valued_set($element_string_rule, 1);
$valuator->rule_is_valued_set($element_array_rule, 1);
$valuator->rule_is_valued_set($elements_rule, 1);
STEP: for ( ;; ) {
    my ( $type, @step_data ) = $valuator->step();
    last STEP if not defined $type;
    if ( $type eq 'MARPA_STEP_TOKEN' ) {
        my ( undef, $token_value_ix, $arg_n ) = @step_data;
        $stack[$arg_n] = $token_values[$token_value_ix];
        next STEP;
    }
    if ( $type eq 'MARPA_STEP_RULE' ) {
        my ( $rule_id, $arg_0, $arg_n ) = @step_data;
	if ($rule_id == $string_rule) {
	  $stack[$arg_0] = $stack[$arg_0 + 3];
	  next STEP;
	}
	if ($rule_id == $array_rule) {
	  $stack[$arg_0] = $stack[$arg_0 + 3];
	  next STEP;
	}
	if ($rule_id == $elements_rule) {
	  $stack[$arg_0] = [@stack[$arg_0 .. $arg_n]];
	  next STEP;
	}
      }
} ## end STEP: for ( ;; )

my $received = Dumper($stack[0]);

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
