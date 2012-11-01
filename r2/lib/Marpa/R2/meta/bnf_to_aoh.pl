#!/usr/bin/perl
# Copyright 2012 Jeffrey Kegler
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

# This is a 'meta' tool, so I relax some of the
# restrictions I use to guarantee portability.
use autodie;

# Appropriate PERLLIB settings are expected to
# be external
use Marpa::R2;

use Getopt::Long;
my $verbose = 1;
my $help_flag = 0;
my $result = Getopt::Long::GetOptions( 'help' => \$help_flag );
die "usage $PROGRAM_NAME [--help] file ...\n" if $help_flag;

my $bnf = join q{}, <>;
print $bnf;
say Marpa::R2::Internal::Stuifzand::parse_rules($bnf);
