#!perl

use 5.010;
use strict;
use warnings;

use Marpa::XS;

use Data::Dumper;
require './OP.pm';

my $rules =
    MarpaX::Blog::OP::parse_rules(
<<'END_OF_GRAMMAR'
e ::=
  NUM
  | VAR
  | :group '(' e ')' => add_brackets
  || '-' e => add_brackets
  || e '*' e => add_brackets
  | e e => implied_multiply
  | e '/' e => add_brackets
  || e '+' e => add_brackets
  | e '-' e => add_brackets
  || VAR '=' e => add_brackets
  ||:right e '?' e ':' e => spaced_within_brackets
  | :right e '??' e ':' e ':' e => spaced_within_brackets
  || 'payment' 'on' e 'over' e 'years' 'at' e '%' => spaced_within_brackets
END_OF_GRAMMAR
    );

sub pass_upward {
    shift;
    return join q{}, @_;
}

sub spaced_within_brackets {
    shift;
    my $original = join q{ }, grep { defined } @_;
    return '[' . $original . ']';
}

sub add_brackets {
    shift;
    my $original = join q{}, grep { defined } @_;
    return '[' . $original . ']';
}

sub implied_multiply {
    return '[' . $_[1] . 'x' . $_[2] . ']'; 
}

# say Data::Dumper::Dumper($rules);

my $grammar = Marpa::XS::Grammar->new(
    {   start          => 'e',
        actions        => __PACKAGE__,
	default_action => 'pass_upward',
        rules          => $rules,
        lhs_terminals  => 0,
    }
);
$grammar->precompute;


# Order matters !!
my @terminals = (
    [ q{'at'},   qr/at\b/ ],
    [ q{'on'},   qr/on\b/ ],
    [ q{'over'},   qr/over\b/ ],
    [ q{'payment'},   qr/payment\b/ ],
    [ q{'years'},   qr/years\b/ ],
    [ q{'??'},   qr/[?][?]/ ],
    [ q{'?'}, qr/[?]/ ],
    [ 'NUM',   qr/\d+/ ],
    [ 'VAR',   qr/\w+/ ],
    [ q{'='},   qr/[=]/ ],
    [ q{'*'},  qr/[*]/ ],
    [ q{'/'},  qr/[\/]/ ],
    [ q{'+'},  qr/[+]/ ],
    [ q{'%'},  qr/[%]/ ],
    [ q{'-'},  qr/[-]/ ],
    [ q{':'},  qr/[:]/ ],
    [ q{'('},  qr/[(]/ ],
    [ q{')'},  qr/[)]/ ],
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
	    my $problem_position = (pos $string) - length $1;
	    my $before_start = $problem_position - 40;
	    $before_start = 0 if $before_start < 0;
	    my $before_length = $problem_position - $before_start;
            die "Problem near position $problem_position\n",
                q{Problem is here: "}, ( substr $string, $before_start, $before_length + 40), qq{"\n},
            ( q{ } x ($before_length + 18)) , qq{^\n},
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

}

say calculate( '4 3 42 + 1' );
say calculate( '4 * 3 5 (6 7) 8 9 10' );
say calculate( '1 ? 42 : 2 ?? 3 : 4 : 5 ? 6 : 7' );
say calculate( 'payment on 1000 + 1000 over 41 years at 5 + 1 %' );
