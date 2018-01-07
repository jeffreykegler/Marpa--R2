#!perl
# Copyright 2018 Jeffrey Kegler
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
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open close);
use Test::More;
use lib 'config';
use lib 'html/lib';
use Marpa::R2::Test;

BEGIN {
    use lib 'html/tool/lib';
    my $eval_result = eval { require Marpa::R2::HTML::Test::Util; 1 };
    if ( !$eval_result ) {
        Test::More::plan tests => 1;
        Test::More::fail(
            "Could not load Marpa::R2::HTML::Test::Util; $EVAL_ERROR");
        exit 0;
    } ## end if ( !$eval_result )
} ## end BEGIN

BEGIN { Marpa::R2::HTML::Test::Util::load_or_skip_all('HTML::Parser'); }

BEGIN { Test::More::plan tests => 2; }

use Marpa::R2::HTML;
use Marpa::R2::HTML::Config::Default;

my $current_file = do {
  my $filename = $INC{'Marpa/R2/HTML/Config/Default.pm'};
  open my $fh, q{<}, $filename;
  join q{}, <$fh>;
};

my $short_round_trip_file = do {
    my $short_round_trip_ref =
        Marpa::R2::HTML::html( \"hi", \{ dump_config => 1 } );
    die "No parse" if not ref $short_round_trip_ref;
    ${$short_round_trip_ref};
};

my $long_round_trip_file = do {
  open my $source_fh, q{<}, 'g/config/default.txt';
  my $source_file = join q{}, <$source_fh>;
  close $source_fh;
    my $long_round_trip_ref =
        Marpa::R2::HTML::html( \"hi", \{ compile => \$source_file, dump_config => 1 } );
    die "No parse" if not ref $long_round_trip_ref;
    ${$long_round_trip_ref};
};

my $datestamp_re = qr/ ^ \s* [#] \s+ The \s+ date \s+ of \s+ generation \s+ was [^\n]* /xms;
$current_file =~ s/$datestamp_re/[ DATESTAMP ]/xms;
$short_round_trip_file =~ s/$datestamp_re/[ DATESTAMP ]/xms;
$long_round_trip_file =~ s/$datestamp_re/[ DATESTAMP ]/xms;

Marpa::R2::Test::is( $short_round_trip_file, $current_file, 'Default config, short round trip' );
Marpa::R2::Test::is( $long_round_trip_file, $current_file, 'Default config, long round trip' );
