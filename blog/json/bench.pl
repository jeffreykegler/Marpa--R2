use 5.010;

use Benchmark;

use JSON::PP 'decode_json';
use lib '../../cpan/blib/arch';
use lib '../../cpan/lib';
use Marpa::R2 2.077_000;
use lib '.';
use MarpaX::JSON;
use Benchmark qw/:hireswallclock :all/;

my $filename = shift;
say "Using ", $filename;
say "Using Marpa::R2 ", $Marpa::R2::VERSION;

open my $json_fh, q{<}, $filename;
local $/ = undef;
my $json_str = <$json_fh>;

my $p = MarpaX::JSON->new;

cmpthese(1, {
    'JSON::PP'     => sub { JSON::PP::decode_json($json_str);},
    'MarpaX::JSON' => sub { $p->parse($json_str); },
});

