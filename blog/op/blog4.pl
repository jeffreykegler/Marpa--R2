#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Marpa::XS;

use Data::Dumper;
require './OP1.pm';    ## no critic (Modules::RequireBarewordIncludes)

my $rules = Marpa::Demo::OP1::parse_rules(
    <<'END_OF_GRAMMAR'
e ::=
     NUM
   | VAR
   | :group '(' e ')'
  || '-' e
  || :right e '^' e
  || e '*' e
   | e e                                          => implied_multiply
   | e '/' e
  || e '+' e
   | e '-' e
  || VAR '=' e
  || :right e '?' e ':' e                         => spaced
   | :right e '??' e ':' e ':' e                  => spaced
  || 'payment' 'on' e 'over' e 'years' 'at' e '%' => spaced
END_OF_GRAMMAR
);

sub add_brackets {
    my ( undef, @children ) = @_;
    return $children[0] if 1 == scalar @children;
    my $original = join q{}, grep {defined} @children;
    return '[' . $original . ']';
} ## end sub add_brackets

sub spaced {
    shift;
    my $original = join q{ }, grep {defined} @_;
    return '[' . $original . ']';
}

sub implied_multiply {
    return '[' . $_[1] . ' x ' . $_[2] . ']';
}

my $grammar = Marpa::XS::Grammar->new(
    {   start          => 'e',
        actions        => __PACKAGE__,
        default_action => 'add_brackets',
        rules          => $rules,
        lhs_terminals  => 0,
    }
);
$grammar->precompute;

# Order matters !!
my @terminals = (
    [ q{'at'},      qr/at\b/xms ],
    [ q{'on'},      qr/on\b/xms ],
    [ q{'over'},    qr/over\b/xms ],
    [ q{'payment'}, qr/payment\b/xms ],
    [ q{'years'},   qr/years\b/xms ],
    [ q{'??'},      qr/[?][?]/xms ],
    [ q{'?'},       qr/[?]/xms ],
    [ 'NUM',        qr/\d+/xms ],
    [ 'VAR',        qr/\w+/xms ],
    [ q{'='},       qr/[=]/xms ],
    [ q{'*'},       qr/[*]/xms ],
    [ q{'/'},       qr/[\/]/xms ],
    [ q{'+'},       qr/[+]/xms ],
    [ q{'^'},       qr/[\^]/xms ],
    [ q{'%'},       qr/[%]/xms ],
    [ q{'-'},       qr/[-]/xms ],
    [ q{':'},       qr/[:]/xms ],
    [ q{'('},       qr/[(]/xms ],
    [ q{')'},       qr/[)]/xms ],
);

sub calculate {
    my ($string) = @_;
    my $rec = Marpa::XS::Recognizer->new( { grammar => $grammar } );

    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;
            if ( not defined $rec->read( $t->[0], $1 ) ) {
                say $rec->show_progress() or die "say failed: $ERRNO";
                my $problem_position = ( pos $string ) - length $1;
                my $before_start     = $problem_position - 40;
                $before_start = 0 if $before_start < 0;
                my $before_length = $problem_position - $before_start;
                die "Problem near position $problem_position\n",
                    q{Problem is here: "},
                    ( substr $string, $before_start, $before_length + 40 ),
                    qq{"\n},
                    ( q{ } x ( $before_length + 18 ) ), qq{^\n},
                    q{Token rejected, "}, $t->[0], qq{", "$1"},
                    ;
            } ## end if ( not defined $rec->read( $t->[0], $1 ) )
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    $rec->end_input;

    my $value_ref = $rec->value;

    if ( !defined $value_ref ) {
        say $rec->show_progress() or die "say failed: $ERRNO";
        die 'Parse failed';
    }
    return ${$value_ref};

} ## end sub calculate

sub report_calculation {
    my ($string) = @_;
    return qq{Input: "$string"\n} . '  Parse: ' . calculate($string) . "\n";
}

my $output = join q{},
    report_calculation('4 3 42 + 1'),
    report_calculation('e = m c^2'),
    report_calculation('4 * 3 5 (6 7) 8 9 10'),
    report_calculation('1 ? 42 : 2 ?? 3 : 4 : 5 ? 6 : 7'),
    report_calculation(
    'payment on 1000 + 1000 over months/12 years at 5 + 1 %');

print $output or die "say failed: $ERRNO";
$output eq <<'EXPECTED_OUTPUT' or die 'FAIL: Output mismatch';
Input: "4 3 42 + 1"
  Parse: [[[4 x 3] x 42]+1]
Input: "e = m c^2"
  Parse: [e=[m x [c^2]]]
Input: "4 * 3 5 (6 7) 8 9 10"
  Parse: [[[[[[4*3] x 5] x [([6 x 7])]] x 8] x 9] x 10]
Input: "1 ? 42 : 2 ?? 3 : 4 : 5 ? 6 : 7"
  Parse: [1 ? 42 : [2 ?? 3 : 4 : [5 ? 6 : 7]]]
Input: "payment on 1000 + 1000 over months/12 years at 5 + 1 %"
  Parse: [payment on [1000+1000] over [months/12] years at [5+1] %]
EXPECTED_OUTPUT
