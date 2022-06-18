#!/usr/bin/env perl
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
use strict;
use warnings FATAL => 'all';
use autodie;
use POSIX qw(strftime);
use File::Copy;
use File::Spec;
use English qw( -no_match_vars );

sub usage {
   die "Usage: $PROGRAM_NAME from";
}

usage() if scalar @ARGV != 1;
my ($from ) = @ARGV;
die "$from does not exist" if not -e $from;

# Do not worry a lot about portability
my (undef, undef, $filename) = File::Spec->splitpath($from);
my @dotted_pieces = split /[.]/xms, $filename;
my ($base, $extension);
if (@dotted_pieces > 1) {
   $base = join '.', @dotted_pieces[0 .. $#dotted_pieces-1];
   $extension = '.' . $dotted_pieces[-1];
} else {
   $base = $dotted_pieces[0];
   $extension = '';
}
my $date = strftime("%d%m%y", localtime);
my $to = join q{}, $base, '-', $date, $extension;
die "$to exists" if -e $to;
copy($from, $to);
