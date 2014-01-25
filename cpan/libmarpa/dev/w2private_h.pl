#!perl
# Copyright 2014 Jeffrey Kegler
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
use Fatal qw(open close);

if (scalar @ARGV != 0) {
    die("usage: $PROGRAM_NAME < marpa.w > private.h");
}

my $file = do { local $RS = undef; <STDIN>; };
for my $prototype ($file =~ m/^PRIVATE_NOT_INLINE \s (.*?) \s* ^[{]/gxms)
{
   $prototype =~ s/[@][,]//g; # Remove Cweb spacing
   say 'static ' . $prototype . q{;};
}
for my $prototype ($file =~ m/^PRIVATE \s (.*?) \s* ^[{]/gxms)
{
   $prototype =~ s/[@][,]//g; # Remove Cweb spacing
   say 'static inline ' . $prototype . q{;};
}

