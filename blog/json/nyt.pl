use 5.010;

use lib '.';
use lib '.';
use lib '../../r2/lib';
use lib '../../r2/blib/arch';
use Marpa::R2 2.043_002;
use MarpaX::JSON;
use Data::Dumper;

local $/ = undef;
my $json_str = <STDIN>;

my $p = MarpaX::JSON->new();
say Data::Dumper::Dumper($p->parse($json_str));

