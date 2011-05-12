package Marpa::PP;
use Marpa::XS;
sub VERSION {
    my ($class, $need) = @_;
    return Marpa::XS->VERSION($need);
}
1;
