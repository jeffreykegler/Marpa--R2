use 5.010;
use strict;
use warnings;

use Benchmark qw(timeit countit timestr);
use Regexp::Common qw /balanced/;
use Marpa::XS;

say $Marpa::XS::VERSION;

my $s = shift @ARGV // 1000;
if ($s =~ /\A [()]+ \z/xms) {
    say "Testing $s";
    do_marpa_xs($s);
    do_regex($s);
    exit 0;
}

my $length = $s + 0;
if (not $length or $length < 0) {
    die "Bad length $s";
}

$s = '((()())' . ( '(()' x ($length/3) )
.  ( ')' x ($length/3+1) )  ;

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

sub do_marpa_xs {
    my ($s) = @_;
    my $grammar = Marpa::Grammar->new(
        {   start => 'S',
            rules => [
                [ S => [qw(prefix first_balanced endmark1 endmark2)] ],
                {   lhs => 'S'   , rhs   => [qw(prefix first_balanced )],
                    action => 'main::arg1'
                },
                { lhs     => 'prefix', rhs => [qw(prefix_char)], min => 0 },
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

    $grammar->set( { terminals => [qw(prefix_char lparen rparen endmark1 endmark2)] } );

    $grammar->precompute();
    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    my $end_of_parse;
    CHAR: for (my $location = 1; ; $location++) {
       if ('endmark1' ~~ $recce->terminals_expected()) {
           $end_of_parse = $location - 1;
       }
	if (not ($s =~ m/(.)/xmsgc)) {
	    $end_of_parse //= $location;
	    last CHAR;
	}
       my $token = $1 eq '(' ? 'lparen' : 'rparen';
       if (not defined $end_of_parse) {
	   $recce->alternative( 'prefix_char', $1 );
	}
       if (not defined $recce->alternative( $token, $1 ))
       {
	   # the parse is exhausted if a paren is not accepted
	   $end_of_parse //= $location;
           last CHAR;
       }
       $recce->earleme_complete( );
       # say $recce->show_progress();
    }
    $recce->set( { end=>$end_of_parse } );
    my $value_ref = $recce->value();
    my $value = ref $value_ref ? ${$value_ref} : 'No parse';
    return 0 if $marpa_answer_shown;
    $marpa_answer_shown = $value;
    say "marpa: location $end_of_parse; $value";
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
