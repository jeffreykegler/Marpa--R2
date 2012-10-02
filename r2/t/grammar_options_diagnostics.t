use 5.010;
use strict;
use warnings;

use Test::More;

use Marpa::R2;

my $grammar; 

for my $data (
    [ undef, "Marpa::R2::Grammar expects args as ref to HASH, got non-reference instead" ],
    [ \$grammar, "Marpa::R2::Grammar expects args as ref to HASH, got ref to SCALAR instead" ],
    [ [], "Marpa::R2::Grammar expects args as ref to HASH, got ref to ARRAY instead" ],
    [ {}, "Empty HASH reference passed as options for Marpa::R2::Grammar" ],
    [ { 1 => 1 }, "Unknown option(s) for Marpa::R2::Grammar:" ]
    ){
    
    my ($ref, $msg) = @$data;
    my $reftype = ref $ref;
    
    eval { $grammar = Marpa::R2::Grammar->new($ref) };
    ok $@, "Marpa::R2::Grammar constructor croaked on " 
        . ($reftype eq "HASH" and keys %$ref == 0 ? "empty " : "")
        . ($reftype || "undef" ) 
        . ($reftype eq "HASH" and exists $ref->{'1'} ? " with unknown options" : "")
        . ".";
    ok index($@, $msg) == 0, "The croak message starts with '$msg'.";
}

$grammar = Marpa::R2::Grammar->new({ rules => [ [ lhs => [qw(rhs)] ] ] });
ok $grammar->isa('Marpa::R2::Grammar'), "Marpa::R2::Grammar is constructed with no croaking if known option(s) are passed.";

done_testing;
