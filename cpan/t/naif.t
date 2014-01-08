use strict; use warnings; use 5.010;

use Marpa::R2;
my $grammar = Marpa::R2::Grammar->new( {
    start   => 'start',
    actions => 'main',
    default_action => 'dummy',
    rules   => [
        [ start => [qw/x y/] ], 
    ], 
} ); 
$grammar->precompute;
my $rec = Marpa::R2::Recognizer->new( { grammar => $grammar } ); 

$rec->alternative('x',\undef, 1);
$rec->earleme_complete;
$rec->alternative('y',\"some", 1);
$rec->earleme_complete;

use Data::Dumper;
say Dumper $rec->value;

sub dummy {
    shift;
    return [@_];
}


