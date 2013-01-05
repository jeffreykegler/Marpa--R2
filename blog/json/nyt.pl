use 5.010;

use lib '.';
use MarpaX::JSON;
use Data::Dumper;

local $/ = undef;
my $json_str = <STDIN>;

my $p = MarpaX::JSON->new();
say Data::Dumper::Dumper($p->parse($json_str));

