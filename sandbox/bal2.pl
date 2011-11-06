use 5.010;
use strict;
use warnings;

use Benchmark qw(timeit countit timestr);
use Regexp::Common qw /balanced/;
use Getopt::Long;
my $example;
my $length = 1000;
my $string;
my $pp = 0;
my $getopt_result = GetOptions(
    "length=i" => \$length,
    "example=s"   => \$example,
    "string=s"   => \$string,
    "pp" => \$pp,
);   

if ($pp) {
    require Marpa::PP;
    'Marpa::PP'->VERSION(0.010000);
    say "Marpa::PP ", $Marpa::PP::VERSION;
    no strict 'refs';
    *{'main::Marpa::grammar_new'} = \&Marpa::PP::Grammar::new;
    *{'main::Marpa::recce_new'} = \&Marpa::PP::Recognizer::new;
}
else {
    require Marpa::XS;
    'Marpa::XS'->VERSION(0.020000);
    say "Marpa::XS ", $Marpa::XS::VERSION;
    no strict 'refs';
    *{'main::Marpa::grammar_new'} = \&Marpa::XS::Grammar::new;
    *{'main::Marpa::recce_new'} = \&Marpa::XS::Recognizer::new;
}


if ( defined $string ) {
    die "Bad string: $string" if not $string =~ /\A [()]+ \z/xms;
    say "Testing $string";
    do_marpa_xs($string);
    do_regex($string);
    exit 0;
} ## end if ( defined $string )

$length += 0;
if ($length <= 0) {
    die "Bad length $length";
}

$example //= "final";
my $s;
CREATE_S: {
    my $s_balanced = '(()())((';
    if ( $example eq 'pos2' ) {
        $s = '(' . $s_balanced . ( '(' x ( $length - length $s_balanced ) );
        last CREATE_S;
    }
    if ( $example eq 'final' ) {
        $s = ( '(' x ( $length - length $s_balanced ) ) . $s_balanced;
        last CREATE_S;
    }
    die qq{Example "$example" not known};
} ## end CREATE_S:

sub concat {
    my (undef, @args) = @_;
    return join q{}, @args;
}
sub arg1 {
    my (undef, undef, $balanced) = @_;
    return $balanced;
}

my $marpa_answer_shown;
my $regex_answer_shown;

sub paren_grammar_generate {
    my $grammar = main::Marpa->grammar_new(
        {   start => 'S',
            rules => [
                [ S => [qw(prefix first_balanced endmark )] ],
                {   lhs    => 'S',
                    rhs    => [qw(prefix first_balanced )],
                    action => 'main::arg1'
                },
                { lhs => 'prefix', rhs => [qw(prefix_char)], min => 0 },
                {   lhs    => 'first_balanced',
                    rhs    => [qw(balanced)],
                    action => 'main::concat'
                },
                {   lhs    => 'balanced',
                    rhs    => [qw(lparen rparen)],
                    action => 'main::concat'
                },
                {   lhs    => 'balanced',
                    rhs    => [qw(lparen balanced_sequence rparen)],
                    action => 'main::concat'
                },
                {   lhs    => 'balanced_sequence',
                    rhs    => [qw(balanced)],
                    min    => 1,
                    action => 'main::concat'
                },
            ],
        }
    );

    $grammar->set(
        { terminals => [qw(prefix_char lparen rparen endmark )] } );

    $grammar->precompute();
    return $grammar;
} ## end sub paren_grammar_generate

sub do_marpa_xs {
    my ($s) = @_;
    my $grammar = paren_grammar_generate();
    my $recce = main::Marpa->recce_new( { grammar => $grammar } );
    my $location = 0;
    my $string_length = length $s;
    my $last_prefix_location;
    my $end_of_parse;
    # find the match which ends first -- the one which starts
    # first must start at or before it does
    CHAR: while ( $location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $token = $value eq '(' ? 'lparen' : 'rparen';
        $recce->alternative( $token,        $value );
        $recce->alternative( 'prefix_char', $value );
        $recce->earleme_complete();
        if ( 'endmark' ~~ $recce->terminals_expected() ) {
            $last_prefix_location = $location - 1;
	    $end_of_parse = $location + 1;
            last CHAR;
        }
	$location++;
    }
    if (not defined $last_prefix_location ) {
       say "No balanced parens";
       return 0;
    }
    # say "end_of_parse=", $end_of_parse, 'LINE=', __LINE__;
    # now that we know the maximum length of the prefx,
    # start over again
    $recce = main::Marpa->recce_new( { grammar => $grammar } );
    $location = 0;
    # say STDERR "last_prefix_location =$last_prefix_location ";
    CHAR: while ( 1 ) {
        my $value = substr $s, $location, 1;
        my $token = $value eq '(' ? 'lparen' : 'rparen';
	# say "Reading $token $value";
        $recce->alternative( $token,        $value );
	last CHAR if $location > $last_prefix_location;
        $recce->alternative( 'prefix_char', $value );
        $recce->earleme_complete();
	$location++;
    }
    $recce->earleme_complete();
    CHAR: while ( ++$location < $string_length ) {
        my $value = substr $s, $location, 1;
        my $token = $value eq '(' ? 'lparen' : 'rparen';
	# say "Reading $token $value";
        last CHAR if not defined $recce->alternative( $token, $value );
        $recce->earleme_complete();
        if ( 'endmark' ~~ $recce->terminals_expected() ) {
            $end_of_parse = $location + 1;
            last CHAR;
        }
    } ## end while ( $location < $string_length )
    if ($location >= $string_length) {
        if ( 'endmark' ~~ $recce->terminals_expected() ) {
            $end_of_parse = $location + 1;
            last CHAR;
        }
    }
    $recce->end_input();
    # say "end_of_parse=", $end_of_parse, 'LINE=', __LINE__;
    $recce->set( { end=>$end_of_parse } );
    my $value_ref = $recce->value();
    die "Parse failure" if not ref $value_ref;
    my $value = ${$value_ref};
    my $start_of_parse = $end_of_parse - length $value;
    return 0 if $marpa_answer_shown;
    $marpa_answer_shown = $value;
    say qq{marpa: "$value" at $start_of_parse-$end_of_parse};
    return 0;

} ## end sub do_marpa_xs

sub do_regex {
    my ($s) = @_;
    my $answer =
          $s =~ /$RE{balanced}{-parens=>'()'}{-keep}/
        ? $1
        : 'no balanced parentheses';
    return 0 if $regex_answer_shown;
    $regex_answer_shown = $answer;
    say "regex answer: $answer";
    return 0;
} ## end sub do_regex

say timestr countit( 2, sub { do_marpa_xs($s) } );
say timestr countit( 2, sub { do_regex($s) } );

say +($marpa_answer_shown eq $regex_answer_shown ? 'Answers match' : 'ANSWERS DO NOT MATCH!');
