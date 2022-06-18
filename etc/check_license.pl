#!/usr/bin/perl
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

use 5.010001;
use strict;
use warnings;
use autodie;
use English qw( -no_match_vars );

use Getopt::Long;
my $verbose = 0;
my $result = Getopt::Long::GetOptions( 'verbose=i' => \$verbose );
die "usage $PROGRAM_NAME [--verbose=n] file ...\n" if not $result;

use lib 'etc';
use inc::License;

my $file_count = @ARGV;
my @license_problems =
    map { Marpa::R2::License::file_license_problems( $_, $verbose ) } @ARGV;

print join q{}, @license_problems;

my $problem_count = scalar @license_problems;

$problem_count and say +( q{=} x 50 );
say
    "Found $problem_count license language problems after examining $file_count files";
