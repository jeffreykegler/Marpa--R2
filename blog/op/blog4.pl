#!perl

use 5.010;
use strict;
use warnings;

use Marpa::XS;

use Data::Dumper;
require './OP.pm';

my $rules =
    Marpa::Blog::OP::parse_rules(
<<'END_OF_GRAMMAR'
e ::=
  NUM
  | VAR
  | :group LPAREN e RPAREN => add_brackets
  || NEG e => add_brackets
  || e STAR e => add_brackets
  | e e => implied_multiply
  | e DIV e => add_brackets
  || e PLUS e => add_brackets
  | e NEG e => add_brackets
  || VAR ASSIGN e => add_brackets
  ||:right e TERNARY e COLON e => spaced_within_brackets
  | :right e QUATERNARY e COLON e COLON e => spaced_within_brackets
  || PAYMENT ON e OVER e YEARS AT e PERCENT => spaced_within_brackets
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
    [ 'AT',   qr/at\b/ ],
    [ 'ON',   qr/on\b/ ],
    [ 'OVER',   qr/over\b/ ],
    [ 'PAYMENT',   qr/payment\b/ ],
    [ 'YEARS',   qr/years\b/ ],
    [ 'QUATERNARY',   qr/[?][?]/ ],
    [ 'TERNARY', qr/[?]/ ],
    [ 'NUM',   qr/\d+/ ],
    [ 'VAR',   qr/\w+/ ],
    [ 'ASSIGN',   qr/[=]/ ],
    [ 'STAR',  qr/[*]/ ],
    [ 'DIV',  qr/[\/]/ ],
    [ 'PLUS',  qr/[+]/ ],
    [ 'PERCENT',  qr/[%]/ ],
    [ 'NEG',  qr/[-]/ ],
    [ 'COLON',  qr/[:]/ ],
    [ 'LPAREN',  qr/[(]/ ],
    [ 'RPAREN',  qr/[)]/ ],
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
