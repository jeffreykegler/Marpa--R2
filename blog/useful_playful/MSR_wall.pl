#!perl
use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Marpa::R2;
use MarpaX::Simple::Rules '0.2.6', 'parse_rules';

my $wall_rules = parse_rules(<<"RULES");
     E ::= E Minus E
     E ::= E Minus Minus
     E ::= Minus Minus E
     E ::= Minus E
     E ::= Variable
RULES

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'E',
        rules => $wall_rules,
    }
);
$grammar->precompute();

sub do_wall {
    my $n           = shift;
    my $parse_count = 0;
    my $recce       = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    # Just in case
    $recce->set( { max_parses => 999, } );
    defined $recce->read( 'Variable', '$a' )
        or die q{Cannot read 1st "Number"};
    for my $token_ix ( 0 .. $n - 1 ) {
        defined $recce->read( 'Minus', q{-} )
            or die qq{Cannot read final "Minus", #$token_ix};
    }
    defined $recce->read( 'Variable', '$b' )
        or die q{Cannot read final "Number"};
    $parse_count++ while $recce->value();
    return $parse_count;
} ## end sub do_wall

my @wall_numbers = qw(0 1 1 3 4 8 12 21 33 55 88 144 232 );

my $expected = join q{ }, @wall_numbers;
my $actual = join q{ }, 0, map { do_wall($_) } 1 .. 12;

say "Expected: $expected" or die "say failed: $ERRNO";
say "  Actual: $actual"   or die "say failed: $ERRNO";
say +( $actual eq $expected ? 'OK' : 'MISMATCH' ) or die "say failed: $ERRNO";

