#!perl
# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Fatal qw(open close);
use File::Spec;

use lib 'lib';
use Test::More tests => 7;
Test::More::use_ok('Marpa::HTML::Test');
Test::More::use_ok('Marpa::HTML::Test::Util');
Test::More::use_ok('HTML::PullParser');

my @script_dir = qw( blib script );
my @data_dir   = qw( t fmt_t_data );

for my $test (qw(1 2)) {
    my $expected;
    my $output = Marpa::HTML::Test::Util::run_command(
        File::Spec->catfile( @script_dir, 'html_fmt' ),
        File::Spec->catfile( @data_dir, ( 'input' . $test . '.html' ) ) );
    local $RS = undef;
    open my $fh, q{<},
        File::Spec->catfile( @data_dir, ( 'expected' . $test . '.html' ) );
    $expected = <$fh>;
    close $fh;
    Marpa::HTML::Test::is( $output, $expected, 'html_fmt test' );
} ## end for my $test (qw(1 2))

