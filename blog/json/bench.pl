use 5.010;

use Benchmark;

use autodie;
use JSON::XS qw//;
use JSON::PP qw//;
use lib '.';
use MyX::JSON;
use MyX::EJSON;
use MyX::EJSONPP;
use MyX::EJSONPP::Minimal;
use Benchmark qw/:hireswallclock :all/;

my $filename = shift;
say "Using ", $filename;
say "Using Marpa::R2 ", $Marpa::R2::VERSION;

open my $json_fh, q{<}, $filename;
local $/ = undef;
my $json_str = <$json_fh>;

my $p          = MyX::JSON->new;
my $ep         = MyX::EJSON->new;
my $epp        = MyX::EJSONPP->new;
my $eppminimal = MyX::EJSONPP::Minimal->new;

cmpthese(-1, {
    'JSON::XS'                => sub { JSON::XS::decode_json($json_str);},
    'JSON::PP'                => sub { JSON::PP::decode_json($json_str);},
    'SLIF JSON'               => sub { $p->parse($json_str); },
    'ESLIF JSON'              => sub { MyX::EJSON::doparse($ep, $json_str); },
    'ESLIF JSON PP'           => sub { MyX::EJSONPP::doparse($epp, $json_str); },
    'ESLIF JSON PP (minimal)' => sub { MyX::EJSONPP::Minimal::doparse($eppminimal, $json_str); },
});

