
use 5.010;
use strict;
use warnings;

my $count = shift @ARGV;
my $result = q{};
while ($count--) {
    $result .= (int rand 2) ? '(' : ')';
}
say $result;
