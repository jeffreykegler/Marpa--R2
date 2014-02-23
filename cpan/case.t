use 5.010;
use strict;
use warnings;
use Marpa::R2;
 
use Test::More tests => 4;
 
my $source = <<'END_OF_SOURCE';
 
    inaccessible is !TREATMENT! by default
    :default ::= action => ::first
    
    start ::= !START!
    start1 ::= X
    start2 ::= Y
 
    X ~ 'X'
    Y ~ 'X'
 
END_OF_SOURCE
 
my $input = 'X';
 
for my $treatment (qw(warn ok)) {
for my $this_start  ( qw/start1 start2/ ) {
 
 
    my $this_source = $source;
    $this_source =~ s/!START!/$this_start/;
    $this_source =~ s/!TREATMENT!/$treatment/;
    my $g = Marpa::R2::Scanless::G->new({ source => \$this_source });
    
    my $r = Marpa::R2::Scanless::R->new( { grammar => $g } );
    $r->read( \$input );
    my $value_ref = $r->value();
    die "No parse" if not $value_ref;
    my $value = ${$value_ref};
 
    is $value, $input, qq{start symbol <$this_start> and input "$input"};
 
}
}
 
