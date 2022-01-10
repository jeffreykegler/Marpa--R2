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
use MyX::EJSONLua;
use MyX::EJSONLua::Minimal;
use Benchmark qw/:hireswallclock :all/;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;

#
# Init log
#
our $defaultLog4perlConf = '
log4perl.rootLogger              = INFO, Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 0
log4perl.appender.Screen.layout  = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
';
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');

my $filename = shift;
say "Using ", $filename;
say "Using Marpa::R2 ", $Marpa::R2::VERSION;
say "Using MarpaX::ESLIF ", $MarpaX::ESLIF::VERSION;

open my $json_fh, q{<}, $filename;
local $/ = undef;
my $json_str = <$json_fh>;

my $p           = MyX::JSON->new;
my $ep          = MyX::EJSON->new($log);
my $epp         = MyX::EJSONPP->new($log);
my $eppminimal  = MyX::EJSONPP::Minimal->new($log);
my $elua        = MyX::EJSONLua->new($log);
my $eluaminimal = MyX::EJSONLua::Minimal->new($log);

cmpthese(-1, {
    'JSON::XS'                 => sub { JSON::XS::decode_json($json_str);},
    'JSON::PP'                 => sub { JSON::PP::decode_json($json_str);},
    'SLIF JSON'                => sub { $p->parse($json_str); },
    'ESLIF JSON'               => sub { MyX::EJSON::doparse($ep, $json_str); },
    'ESLIF JSON PP'            => sub { MyX::EJSONPP::doparse($epp, $json_str); },
    'ESLIF JSON PP (minimal)'  => sub { MyX::EJSONPP::Minimal::doparse($eppminimal, $json_str); },
    'ESLIF JSON Lua'           => sub { MyX::EJSONLua::doparse($elua, $json_str); },
    'ESLIF JSON Lua (minimal)' => sub { MyX::EJSONLua::Minimal::doparse($eluaminimal, $json_str); },
});

