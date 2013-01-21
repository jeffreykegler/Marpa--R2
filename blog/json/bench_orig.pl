# use 5.010;

use Benchmark;

use JSON::XS;
use JSON::PP;
use lib '.';
use MarpaX::JSON;
use Benchmark qw/:hireswallclock :all/;

my $json_str = q${"test":[1,2,3,4,5],"test2":[],"test3":[]}$;

my $p = MarpaX::JSON->new;

cmpthese(-1, {
    'JSON::XS'     => sub { JSON::XS::decode_json($json_str);},
    'JSON::PP'     => sub { JSON::PP::decode_json($json_str);},
    'MarpaX::JSON' => sub { $p->parse($json_str); },
});

