use 5.010;
use strict;
use warnings;

use Benchmark qw(timeit countit timestr);
use Regexp::Common qw /balanced/;
use Marpa::XS;

say $Marpa::XS::VERSION;
say $RE{balanced}{-parens=>'()<>[]{}'}{-keep};

my $length = 1000;

sub concat {
    my (undef, @args) = @_;
    return join q{}, @args;
}
sub arg1 {
    my (undef, undef, $balanced) = @_;
    return $balanced;
}

sub do_marpa_xs {
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
    $recce->read( 'lparen', '(' ) for 1 .. $length + 3;
    $recce->read( 'rparen', ')' ) for 1 .. 3;
    my $value_ref = $recce->value();
    my $value = ref $value_ref ? ${$value_ref} : 'No parse';
    say $value;

} ## end sub do_marpa_xs

sub do_regexp {
    my $s = ( '(' x $length ) . '((()))';
    $s =~ /$RE{balanced}{-parens=>'()'}{-keep}/
        and print qq{balanced parentheses: $1\n};
}

say timestr countit( 2, \&do_marpa_xs );
say timestr countit( 2, \&do_regexp );

#while (<>) {
    #/$RE{balanced}{-parens=>'()'}{-keep}/
        #and print qq{balanced parentheses: $1\n};
#}
