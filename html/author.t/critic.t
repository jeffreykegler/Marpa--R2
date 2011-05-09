#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Fatal qw( open close );
use Carp;
use Perl::Critic;
use Test::Perl::Critic;
use Test::More;

# Test that the module passes perlcritic
BEGIN {
    $OUTPUT_AUTOFLUSH = 1;
}

my %exclude = map { ( $_, 1 ) } qw(
    Makefile.PL
    bootstrap/bootstrap.pl
    bootstrap/bootstrap_header.pl
    bootstrap/bootstrap_trailer.pl
    lib/Marpa/Raw_Source.pm
    lib/Marpa/header_Raw_Source.pm
    lib/Marpa/trailer_Raw_Source.pm
    inc/Test/Weaken.pm
);

open my $manifest, '<', 'MANIFEST'
    or Marpa::Exception("open of MANIFEST failed: $ERRNO");

my @test_files = ();
FILE: while ( my $file = <$manifest> ) {
    chomp $file;
    $file =~ s/\s*[#].*\z//xms;
    next FILE if $exclude{$file};
    my ($ext) = $file =~ / [.] ([^.]+) \z /xms;
    given ( lc $ext ) {
        when (undef) {
            break
        }
        when ('pl') { push @test_files, $file }
        when ('pm') { push @test_files, $file }
        when ('t')  { push @test_files, $file }
    } ## end given
} ## end while ( my $file = <$manifest> )

close $manifest;

my $rcfile = File::Spec->catfile( 'author.t', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
Test::Perl::Critic::all_critic_ok(@test_files);

1;
