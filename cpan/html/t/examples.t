#!perl
# Copyright 2022 Jeffrey Kegler
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

use 5.010001;
use strict;
use warnings;
use English qw( -no_match_vars );
use List::Util;
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

BEGIN { Test::More::plan tests => 2; }

use Marpa::R2::HTML;
use lib 'tool/lib';
use Marpa::R2::Test;

# Non-synopsis example in HTML.pod

# Marpa::R2::Display
# name: 'HTML Pod: Handler Precedence'

my $html = <<'END_OF_HTML';
<span class="high">High Span</span>
<span class="low">Low Span</span>
<div class="high">High Div</div>
<div class="low">Low Div</div>
<div class="oddball">Oddball Div</div>
END_OF_HTML

our @RESULTS = ();
Marpa::R2::HTML::html(
    \$html,
    {   q{*} => sub {
            push @RESULTS, 'wildcard handler: ' . Marpa::R2::HTML::contents();
        },
        'div' => sub {
            push @RESULTS, '"div" handler: ' . Marpa::R2::HTML::contents();
        },
        '.high' => sub {
            push @RESULTS, '".high" handler: ' . Marpa::R2::HTML::contents();
        },
        'div.high' => sub {
            push @RESULTS,
                '"div.high" handler: ' . Marpa::R2::HTML::contents();
        },
        '.oddball' => sub {
            push @RESULTS,
                '".oddball" handler: ' . Marpa::R2::HTML::contents();
        },
        'body' => sub {undef},
        'head' => sub {undef},
        'html' => sub {undef},
        'p'    => sub {undef},
    }
);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: 'HTML Pod: Handler Precedence Result'
# start-after-line: EXPECTED_RESULT
# end-before-line: '^EXPECTED_RESULT$'

my $expected_result = <<'EXPECTED_RESULT';
".high" handler: High Span
wildcard handler: Low Span
"div.high" handler: High Div
"div" handler: Low Div
".oddball" handler: Oddball Div
EXPECTED_RESULT

# Marpa::R2::Display::End

my $result = join "\n", @RESULTS;
Marpa::R2::Test::is( "$result\n", $expected_result,
    'handler precedence example' );

# Marpa::R2::Display
# name: 'HTML Pod: Structure vs. Element Example'
# start-after-line: END_OF_EXAMPLE
# end-before-line: '^END_OF_EXAMPLE$'

my $tagged_html_example = <<'END_OF_EXAMPLE';
    <title>Short</title><p>Text</head><head>
END_OF_EXAMPLE

# Marpa::R2::Display::End

my $expected_structured_result = <<'END_OF_EXPECTED';
    <html>
<head>
<title>Short</title></head>
<body>
<p>Text</p>
</head><head>
</body>
</html>
END_OF_EXPECTED

sub supply_missing_tags {
    my $tagname = Marpa::R2::HTML::tagname();
    return
          ( Marpa::R2::HTML::start_tag() // "<$tagname>\n" )
        . Marpa::R2::HTML::contents()
        . ( Marpa::R2::HTML::end_tag() // "</$tagname>\n" );
} ## end sub supply_missing_tags
my $structured_html_ref =
    Marpa::R2::HTML::html( \$tagged_html_example,
    { q{*} => \&supply_missing_tags } );

Marpa::R2::Test::is( ${$structured_html_ref}, $expected_structured_result,
    'structure vs. tags example' );

