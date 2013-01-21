use 5.010;

use Benchmark;

use autodie;
# use JSON::XS;
use JSON::PP 'decode_json';
use lib '.';
use MarpaX::JSON;
use Benchmark qw/:hireswallclock :all/;

open my $json_fh, q{<}, 'ucd1m.json';
local $/ = undef;
my $json_str = <$json_fh>;

my $p = MarpaX::JSON->new;

cmpthese(-1, {
    # 'JSON::XS'     => sub { JSON::XS::decode_json($json_str);},
    'JSON::PP'     => sub { JSON::PP::decode_json($json_str);},
    'MarpaX::JSON' => sub { $p->parse($json_str); },
});

