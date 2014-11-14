use strict;
use Marpa::R2;
use 5.010;

our $DATA = do {local $/; <DATA>};
my $input = "1\x{0A}2\x{0D}3\x{0D}\x{0A}4\x{85}5\x{0A}\x{0D}\x{0A}7";
my $g = Marpa::R2::Scanless::G->new({source => \$DATA});
my $r = Marpa::R2::Scanless::R->new({grammar => $g});
$r->read(\$input, 0, 0);
for my $i (0 .. length $input) {
   my ($l, $c) = $r->line_column($i);
   my $text = substr $input, $i, 20;
   $text =~ s/\n/\\n/g;
   $text =~ s/\r/\\r/g;
   say join " ", $l, $c, $text;
}
__DATA__
:start ::= test
test ::= [\w] | [\W]
