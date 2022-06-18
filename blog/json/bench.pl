# Copyright 2022 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;

use Benchmark;

use autodie;
use JSON::XS qw//;
use JSON::PP qw//;
use lib '.';
use MyX::JSON;
use MyX::EJSON;
use Benchmark qw/:hireswallclock :all/;

my $filename = shift;
say "Using ", $filename;
say "Using Marpa::R2 ", $Marpa::R2::VERSION;

open my $json_fh, q{<}, $filename;
local $/ = undef;
my $json_str = <$json_fh>;

my $p = MyX::JSON->new;
my $ep = MyX::EJSON->new;

cmpthese(-1, {
    'JSON::XS'     => sub { JSON::XS::decode_json($json_str);},
    'JSON::PP'     => sub { JSON::PP::decode_json($json_str);},
    'SLIF JSON' => sub { $p->parse($json_str); },
    'ESLIF JSON' => sub { MyX::EJSON::doparse($ep, $json_str); },
});

