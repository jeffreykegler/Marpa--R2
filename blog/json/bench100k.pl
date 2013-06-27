use 5.010;

use Benchmark;

# use JSON::XS;
use JSON::PP 'decode_json';
use lib '.';
use lib '../../cpan/lib';
use lib '../../cpan/blib/arch';
use Marpa::R2 2.044_000;
use MarpaX::JSON;
use Benchmark qw/:hireswallclock :all/;

my $input_file_name = 'ucd100k.json';
if (scalar @ARGV >= 1) {
  $input_file_name = shift;
}

say "Using ", $input_file_name;
say "Using Marpa::R2 ", $Marpa::R2::VERSION;

open my $json_fh, q{<}, $input_file_name;
local $/ = undef;
my $json_str = <$json_fh>;

my $p = MarpaX::JSON->new;

cmpthese(1, {
    # 'JSON::XS'     => sub { JSON::XS::decode_json($json_str);},
    'JSON::PP'     => sub { JSON::PP::decode_json($json_str);},
    'MarpaX::JSON' => sub { $p->parse($json_str); },
});

