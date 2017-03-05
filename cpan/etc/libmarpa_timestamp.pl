#!/usr/bin/perl
# Copyright 2015 Jeffrey Kegler
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

# For development -- don't obsess about portability.

# It creates timestamps up to 3 minutes after that of
# the base file.  In theory, these could be in the
# future.  Again, this runs on the development platforms
# only and hopefully very-near-future timestamps are
# not a issue.

use 5.010;
use strict;
use warnings;
use autodie;
use English qw( -no_match_vars );
use File::Find;
use Data::Dumper;

# Must be run in cpan/ directory.
die "$PROGRAM_NAME must be run in cpan directory" if not -d 'engine';

my $base_file =  "engine/base.time-stamp";
open my $fh, '<', $base_file;
my $raw_timestamp = <$fh>;
my $base_time = $raw_timestamp;
$base_time =~ s/\s//xmsg;
die "Bad timestamp in '$base_file': $raw_timestamp"
  if $base_time !~ /\A \d+ \z/xms;
$base_time += 0;

my %inc = (
  'engine/read_only/aclocal.m4' => 1,
  'engine/read_only/configure' => 2,
  'engine/read_only/Makefile.in' => 3,
  'engine/read_only/config.h.in' => 3
);

sub restamp_file {
    my $inc = $inc{$File::Find::name};
    $inc //= 0;
    my $timestamp = $base_time + $inc * 60;
    utime $timestamp, $timestamp, $_;
}

File::Find::find(\&restamp_file, 'engine');

if (0) {
  my %mtimes = ();
  File::Find::find(sub {
      $mtimes{$File::Find::name} = -M $_;
  }, 'engine');
  say Data::Dumper::Dumper(\%mtimes);
}

# vim: expandtab shiftwidth=4:
