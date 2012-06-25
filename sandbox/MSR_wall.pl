#!perl
use 5.010;
use strict;
use warnings;

use Marpa::XS;
use MarpaX::Simple::Rules 'parse_rules';

sub numbers {
    my ( undef, @numbers ) = @_;
    return \@numbers;
}

my $wall_rules = parse_rules(<<"RULES");
     E ::= E Minus E
     E ::= E Minus Minus
     E ::= Minus Minus E
     E ::= Minus E
     E ::= Number
RULES

my $grammar = Marpa::XS::Grammar->new(
    {   start => 'E',
        rules => $wall_rules,
    }
);
$grammar->precompute();

sub do_wall {
    my $n           = shift;
    my $parse_count = 0;
    my $recce       = Marpa::XS::Recognizer->new( { grammar => $grammar } );

    # Just in case
    $recce->set( { max_parses => 999, } );
    $recce->read( 'Number', 6, 1 ) or die qq{Cannot read 1st "Number"};
    for my $token_ix ( 0 .. $n - 1 ) {
        $recce->read( 'Minus', q{-}, 1 )
            or die qq{Cannot read final "Minus", #$token_ix};
    }
    $recce->read( 'Number', 1, 1 ) or die qq{Cannot read final "Number"};
    $parse_count++ while $recce->value();
    return $parse_count;
} ## end sub do_wall

my @wall_numbers = qw(0 1 1 3 4 8 12 21 33 55 88 144 232 );

my $expected = join q{ }, @wall_numbers;
my $actual = join q{ }, 0, map { do_wall($_) } 1 .. 12;

say "Expected: $expected";
say "  Actual: $actual";
say( $actual eq $expected ? 'OK' : 'MISMATCH' );

