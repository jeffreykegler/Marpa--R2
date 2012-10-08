#!perl
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
use Fatal qw(open close);
use File::Spec;
use Test::More;

BEGIN {
    use lib 'html/tool/lib';
    my $eval_result = eval { require Marpa::R2::HTML::Test::Util; 1 };
    if ( !$eval_result ) {
        Test::More::plan tests => 1;
        Test::More::fail(
            "Could not load Marpa::R2::HTML::Test::Util; $EVAL_ERROR");
        exit 0;
    } ## end if ( !$eval_result )
} ## end BEGIN

# The script will require HTML::Parser, so we need to check here,
# even though we do not use it
BEGIN { Marpa::R2::HTML::Test::Util::load_or_skip_all('HTML::Parser'); }

use Test::More tests => 4;

use lib 'tool/lib';
use lib 'html/tool/lib';
use Marpa::R2::Test;
use Marpa::R2::HTML::Test::Util;

my @script_dir = qw( blib script );
my @data_dir   = qw( html t fmt_t_data );

for my $test (qw(1 2)) {
    my $expected;
    my $output = Marpa::R2::HTML::Test::Util::run_command(
        File::Spec->catfile( @script_dir, 'marpa_r2_html_score' ),
        File::Spec->catfile( @data_dir, ( 'input' . $test . '.html' ) )
    );
    $output =~ s/\A [^\n]* \n//xms;
    open my $fh, q{<},
        File::Spec->catfile( @data_dir,
        ( 'score_expected' . $test . '.html' ) );
    $expected = <$fh>;
    local $RS = undef;
    $expected = <$fh>;
    close $fh;
    Marpa::R2::Test::is( $output, $expected, 'marpa_r2_html_score test' );
} ## end for my $test (qw(1 2))

