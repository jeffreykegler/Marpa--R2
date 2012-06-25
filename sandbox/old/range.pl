#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Scalar::Util;
use English qw( -no_match_vars );

# Code to demonstrate factoring of regex repetition
# counts into BNF

sub usage {
    die "usage: $PROGRAM_NAME start end";
}
usage() unless scalar @ARGV == 2;
my ($start, $end) = @ARGV;
usage() unless Scalar::Util::looks_like_number $start;
usage() unless Scalar::Util::looks_like_number $end;
usage() unless $start >= 0;
usage() unless $end >= $start;

my %rules;
my $block_symbol = do_block($start);
my $range_symbol = do_range($end-$start);
push @{$rules{(join '_', 'repeat', $start, $end)}}, [ $block_symbol, $range_symbol ];

# First power of 2 equal strictly less than arg
sub pow2 {
    my ($n) = @_;
    my $pow = 1;
    while ($pow < $n) { $pow *=2 }
    return $pow/2;
}

sub do_block {
    my ($size) = @_;
    my $block_symbol = "block_$size";
    return $block_symbol if exists $rules{$block_symbol};
    if ($size <= 3) {
        push @{$rules{$block_symbol}}, [('X') x $size];
	return $block_symbol;
    }
    my $part1_size = pow2($size);
    my $part1 = do_block($part1_size);
    my $part2 = do_block($size-$part1_size);
    push @{$rules{$block_symbol}}, [$part1, $part2];
    return $block_symbol;
}

sub do_range {
    my ($size) = @_;
    my $range_symbol = "range_$size";
    return $range_symbol if exists $rules{$range_symbol};
    if ($size <= 3) {
	for my $i (0 .. $size) {
	    push @{$rules{$range_symbol}}, [ do_block($i) ];
	}
	return $range_symbol;
    }
    my $part1_size = pow2($size);
    my $range1 = do_range($part1_size-1);
    my $block1 = do_block($part1_size);
    my $range2 = do_range($size-$part1_size);
    push @{$rules{$range_symbol}}, [$range1];
    push @{$rules{$range_symbol}}, [$block1, $range2];
    return $range_symbol;
}

for my $lhs (sort keys %rules) {
    for my $rhs (@{$rules{$lhs}}) {
	say join " ", $lhs, '::=', @{$rhs};
    }
}
