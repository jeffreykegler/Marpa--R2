#!perl
# Copyright 2013 Jeffrey Kegler
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

if (scalar @ARGV != 1) {
    die("usage: $PROGRAM_NAME private.h < marpa.w");
}

open my $private_h, '>', $ARGV[0];

my $common_preamble = <<'COMMON_PREAMBLE';
/*
 * Copyright 2013 Jeffrey Kegler
 * This file is part of Marpa::R2.  Marpa::R2 is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Marpa::R2 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Marpa::R2.  If not, see
 * http://www.gnu.org/licenses/.
 */
/*
 * DO NOT EDIT DIRECTLY
 * This file is written by w2private_h.pl
 * It is not intended to be modified directly
 */

COMMON_PREAMBLE

say {$private_h} $common_preamble;
my $file = do { local $RS = undef; <STDIN>; };
for my $prototype ($file =~ m/^PRIVATE_NOT_INLINE \s (.*?) \s* ^[{]/gxms)
{
   $prototype =~ s/[@][,]//g; # Remove Cweb spacing
   say {$private_h} 'static ' . $prototype . q{;};
}
for my $prototype ($file =~ m/^PRIVATE \s (.*?) \s* ^[{]/gxms)
{
   $prototype =~ s/[@][,]//g; # Remove Cweb spacing
   say {$private_h} 'static inline ' . $prototype . q{;};
}

