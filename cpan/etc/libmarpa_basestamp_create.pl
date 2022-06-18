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

# Must be run in cpan/ directory.
die "$PROGRAM_NAME must be run in cpan directory" if not -d 'engine';

sub usage { die "usage $PROGRAM_NAME file\n" };
use Getopt::Long;
my $verbose = 1;
my $result = Getopt::Long::GetOptions();
usage() if not $result;

my $date;
my $file_count = @ARGV;
usage() if $file_count > 1;
if ($file_count == 1) {
  my $file = $ARGV[0];
  die "'$file' is not a readable file" if not -r $file;
  $date = -M $file;
} else {
  $date = time();
}

open my $fh, '>', "engine/base.time-stamp";
printf {$fh} "%d\n", $date;
close $fh;
