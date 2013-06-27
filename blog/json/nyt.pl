use 5.010;

use lib '.';
use lib '../../cpan/lib';
use lib '../../cpan/blib/arch';
use Marpa::R2;
use MarpaX::JSON;
use Data::Dumper;

say STDERR $Marpa::R2::VERSION;

local $/ = undef;
my $json_str = <STDIN>;

my $p = MarpaX::JSON->new();
say Data::Dumper::Dumper($p->parse($json_str));

