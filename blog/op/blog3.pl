#!perl

use 5.010;
use strict;
use warnings;

use Marpa::XS;

use Data::Dumper;
require './OP1.pm';

my $rules = Marpa::Demo::OP1::parse_rules(
    <<'END_OF_GRAMMAR'
e ::=
     NUM
   | VAR
   | :group '(' e ')'
  || '-' e
  || :right e '^' e
  || e '*' e
   | e '/' e
  || e '+' e
   | e '-' e
  || VAR '=' e
END_OF_GRAMMAR
);

sub add_brackets {
    shift;
    return $_[0] if 1 == scalar @_;
    my $original = join q{}, grep {defined} @_;
    return '[' . $original . ']';
} ## end sub add_brackets

# say Data::Dumper::Dumper($rules);

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
    [ 'NUM',  qr/\d+/ ],
    [ 'VAR',  qr/\w+/ ],
    [ q{'='}, qr/[=]/ ],
    [ q{'*'}, qr/[*]/ ],
    [ q{'/'}, qr/[\/]/ ],
    [ q{'+'}, qr/[+]/ ],
    [ q{'-'}, qr/[-]/ ],
    [ q{'^'}, qr/[\^]/ ],
    [ q{'('}, qr/[(]/ ],
    [ q{')'}, qr/[)]/ ],
);

sub calculate {
    my ($string) = @_;
    my $rec = Marpa::XS::Recognizer->new( { grammar => $grammar } );

    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gc;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gc;
            if ( not defined $rec->read( $t->[0], $1 ) ) {
                say $rec->show_progress();
                my $problem_position = ( pos $string ) - length $1;
                my $before_start     = $problem_position - 40;
                $before_start = 0 if $before_start < 0;
                my $before_length = $problem_position - $before_start;
                die "Problem near position $problem_position\n",
                    q{Problem is here: "},
                    ( substr $string, $before_start, $before_length + 40 ),
                    qq{"\n},
                    ( q{ } x ( $before_length + 18 ) ), qq{^\n},
                    qq{Token rejected, "}, $t->[0], qq{", "$1"},
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
        say $rec->show_progress();
        die "Parse failed";
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

print $output;
$output eq <<'EXPECTED_OUTPUT' or die "FAIL: Output mismatch";
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
