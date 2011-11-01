use 5.010;
use strict;
use warnings;

use Benchmark qw(timeit countit timestr);
use Regexp::Common qw /balanced/;
use Marpa::XS;

say $Marpa::XS::VERSION;

if (scalar @ARGV) {
    my $s = shift @ARGV;
    say $s;
    do_marpa_xs($s);
    do_regexp($s);
    exit 0;
}

my $length = 1000;
my $s = ('(' x $length) . '((()))';

sub concat {
    my (undef, @args) = @_;
    return join q{}, @args;
}
sub arg1 {
    my (undef, undef, $balanced) = @_;
    return $balanced;
}

sub do_marpa_xs {
    my ($s) = @_;
    my $grammar = Marpa::Grammar->new(
        {   start => 'S',
            rules => [
                [ S => [qw(anything first_balanced endmark)] ],
                {   lhs => 'S'   , rhs   => [qw(anything first_balanced )],
                    action => 'main::arg1'
                },
                { lhs     => 'anything', rhs => [qw(anychar)], min => 0 },
                [ anychar => [qw(lparen)] ],
                [ anychar => [qw(rparen)] ],
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

    $grammar->set( { terminals => [qw(lparen rparen endmark)] } );

    $grammar->precompute();
    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    my $end_of_parse = undef;
    my $location = 0;
    CHAR: while ($s =~ m/(.)/xmsgc) {
       $location++;
       my $token = $1 eq '(' ? 'lparen' : 'rparen';
       my $result = $recce->read( $token, $1 );
       if ($result > 2) {
           $end_of_parse = $location;
	}
    }
    say "end_of_parse: ", ($end_of_parse // 'undef');
    {
        my $value_ref = $recce->value( );
        my $value = ref $value_ref ? ${$value_ref} : 'No parse';
        say "earleme: default;  $value";
    } ## end for my $i ( 1 .. $end_of_parse )
    for my $i (1 .. $recce->current_earleme() ) {
        $recce->reset_evaluation();
	$recce->set( { end=>$i } );
        my $value_ref = $recce->value();
        my $value = ref $value_ref ? ${$value_ref} : 'No parse';
        say "earleme: $i;  $value";
    } ## end for my $i ( 1 .. $end_of_parse )

} ## end sub do_marpa_xs

sub do_regexp {
    my ($s) = @_;
    $s =~ /$RE{balanced}{-parens=>'()'}{-keep}/
        and print qq{balanced parentheses: $1\n};
}

say timestr countit( 2, sub { do_marpa_xs($s) } );
say timestr countit( 2, sub { do_regexp($s) } );

#while (<>) {
    #/$RE{balanced}{-parens=>'()'}{-keep}/
        #and print qq{balanced parentheses: $1\n};
#}
