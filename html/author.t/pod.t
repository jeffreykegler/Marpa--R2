#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Fatal qw( open close );
use Carp;
use Pod::Simple;
use Test::Pod;
use Test::More;

# Test that the module passes perlcritic
BEGIN {
    $OUTPUT_AUTOFLUSH = 1;
}

my %exclude = map { ( $_, 1 ) } qw(
    ../inc/drafts/Implementation.pod
);

open my $manifest, '<', 'MANIFEST'
    or Marpa::Exception("open of MANIFEST failed: $ERRNO");

my @test_files = ();
FILE: while ( my $file = <$manifest> ) {
    chomp $file;
    $file =~ s/\s*[#].*\z//xms;
    next FILE if -d $file;
    next FILE if $exclude{$file};
    my ($ext) = $file =~ / [.] ([^.]+) \z /xms;
    next FILE if not defined $ext;
    $ext = lc $ext;
    given ($ext) {
        when ('pl')  { push @test_files, $file }
        when ('pod') { push @test_files, $file }
        when ('t')   { push @test_files, $file }
        when ('pm')  { push @test_files, $file }
    } ## end given
}    # FILE
close $manifest;

Test::Pod::all_pod_files_ok(@test_files);

1;
