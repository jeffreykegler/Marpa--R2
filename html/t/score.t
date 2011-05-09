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

my @script_dir = qw( script );
my @data_dir   = qw( t fmt_t_data );

for my $test (qw(1 2)) {
    my $expected;
    my $output = Marpa::HTML::Test::Util::run_command(
        File::Spec->catfile( @script_dir, 'html_score' ),
        File::Spec->catfile( @data_dir, ( 'input' . $test . '.html' ) ) );
    $output =~ s/\A [^\n]* \n//xms;
    open my $fh, q{<},
        File::Spec->catfile( @data_dir,
        ( 'score_expected' . $test . '.html' ) );
    $expected = <$fh>;
    local $RS = undef;
    $expected = <$fh>;
    close $fh;
    Marpa::HTML::Test::is( $output, $expected, 'html_score test' );
} ## end for my $test (qw(1 2))

