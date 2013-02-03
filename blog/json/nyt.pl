use 5.010;

use lib '.';
use lib '../../r2/lib';
use lib '../../r2/blib/arch';
use Marpa::R2;
use MarpaX::JSON;
use Data::Dumper;

say $Marpa::R2::VERSION;

local $/ = undef;
my $json_str = <STDIN>;

my $p = MarpaX::JSON->new();
say Data::Dumper::Dumper($p->parse($json_str));

