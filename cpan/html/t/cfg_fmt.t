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
use File::Spec;
use File::Temp;
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

BEGIN { Marpa::R2::HTML::Test::Util::load_or_skip_all('HTML::Parser'); }

BEGIN { Test::More::plan tests => 10; }

use lib 'tool/lib';
use Marpa::R2::Test;

my @script_dir = qw( blib script );

sub run_one_test {
    my ( $test_name, $html, $config_ref, $expected_ref ) = @_;
    my ( $html_fh, $html_file_name ) = File::Temp::tempfile(
        'temp_for_test_XXXXXX',
        UNLINK => 1,
        SUFFIX => '.html'
    );
    print {$html_fh} $html;
    close $html_fh;
    my ( $cfg_fh, $test_config_name ) = File::Temp::tempfile(
        'temp_for_test_XXXXXX',
        UNLINK => 1,
        SUFFIX => '.txt'
    );
    print {$cfg_fh} ${$config_ref};
    close $cfg_fh;
    my $output = Marpa::R2::HTML::Test::Util::run_command(
        File::Spec->catfile( @script_dir, 'marpa_r2_html_fmt' ),
	'--no-added-tag',
        '--compile=' . $test_config_name,
        $html_file_name
    );

    unlink $test_config_name, $html_file_name;
    Marpa::R2::Test::is( $output, ${$expected_ref}, $test_name );
} ## end sub run_one_test

my $default_config = do {
  my @g_config_dir   = qw( g config );
  my $file_name = File::Spec->catfile( qw(g config default.txt) );
  open my $fh, q{<}, $file_name;
  my $file = join q{}, <$fh>;
  close $fh;
  \$file;
};

my $test_name;
my $test_html;
my $test_config;
my $expected_output;

$test_name = 'Inline element containing inline flow';
$test_config =
    ${$default_config} . '<acme> is a *inline included in %inline';
$test_html       = '<acme>-during-<span>-more inline stuff-<p>-new block-' . "\n";
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    <p>
      <acme>
        -during-<span>
          -more inline stuff-</span></acme></p><p>
      -new block-
    </p></body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );

$test_name = 'Inline element containing block flow';
$test_config =
    ${$default_config} . '<acme> is a *inline included in %block';
# $test_html is same as in previous test
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    <acme>
      -during-<span>
        -more inline stuff-</span></acme><p>
      -new block-
    </p></body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );

$test_name = 'Block element containing mixed flow';
$test_config =
    ${$default_config} . '<acme> is a *mixed included in %block';
# $test_html is same as in previous test
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    <acme>
      -during-<span>
        -more inline stuff-</span><p>
        -new block-
      </p></acme></body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );

$test_name = 'Block element containing block flow';
$test_config =
    ${$default_config} . '<acme> is a *block included in %block';
# $test_html is same as in previous test
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    <acme>
      <p>
        -during-<span>
          -more inline stuff-</span></p><p>
        -new block-
      </p></acme></body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );

$test_name = 'Block element containing PCDATA';
$test_config =
    ${$default_config} . '<acme> is a *pcdata included in %block';
# $test_html is same as in previous test
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    <acme>
      -during-</acme><p>
      <span>
        -more inline stuff-</span></p><p>
      -new block-
    </p></body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );
 
$test_name = 'Empty block element';
$test_config =
    ${$default_config} . '<acme> is a *empty included in %block';
# $test_html is same as in previous test
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    <acme><p>
      -during-<span>
        -more inline stuff-</span></p><p>
      -new block-
    </p></body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );
 
$test_name = 'Body allows mixed flow';
$test_config = ${$default_config};
$test_config =~ s/^ \s* <body> [^\n]* $/<body> is *mixed/xms;
$test_html = 'I cannot wait for a start tag<p>I can';
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    I cannot wait for a start tag<p>
      I can</p></body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );

$test_name = 'Body allows block flow';
# This is the default
$test_config = ${$default_config};
$test_config =~ s/^ \s* <body> [^\n]* $/<body> is *block/xms;
# $test_html is same as in previous test
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    <p>
      I cannot wait for a start tag</p><p>
      I can</p></body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );

$test_name = 'Body is inline flow';
$test_config = ${$default_config};
$test_config =~ s/^ \s* <body> [^\n]* $/<body> is *inline/xms;
# $test_html is same as in previous test
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head>
  <body>
    I cannot wait for a start tag<!--
        html_fmt: Next start tag is cruft
      --><p>I can</body>
</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );

$test_name = 'Body is empty';
$test_config = ${$default_config};
$test_config =~ s/^ \s* <body> [^\n]* $/<body> is *empty/xms;
# I also need to eliminate all mentions of the </body> tag
# now that <body> is an empty element
$test_config =~ s{^ \s* [<][/]body[>] \s [^\n]* $}{}xms;
$test_config =~ s{  [<][/]body[>] }{}gxms;
# $test_html is same as in previous test
$expected_output = <<'END_OF_EXPECTED_OUTPUT';
<html>
  <head>
  </head><body><!--
      html_fmt: Next text is cruft
    -->I cannot wait for a start tag<!--
      html_fmt: Next start tag is cruft
    --><p><!--
      html_fmt: Next text is cruft
    -->I can</html>
END_OF_EXPECTED_OUTPUT
run_one_test( $test_name, $test_html, \$test_config, \$expected_output );

# vim: expandtab shiftwidth=4:
