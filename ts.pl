#!/usr/bin/env perl

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
