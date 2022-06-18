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

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Getopt::Long;

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
$PROGRAM_NAME [-n] 'exp'
$PROGRAM_NAME [-n] < file
END_OF_USAGE_MESSAGE
} ## end sub usage

my $show_position_flag;
my $getopt_result = GetOptions( "n!" => \$show_position_flag, );
usage() if not $getopt_result;

my $string = join q{}, <>;
chomp $string;
my $tchrist_regex = '(\\((?:[^()]++|(?-1))*+\\))';
my @re_results = ($string =~ m/$tchrist_regex/msxg);
say join "\n", map { (length $_) . ': ' . substr $_, 0, 40 } @re_results;

# vim: expandtab shiftwidth=4:
