#!perl
# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use List::Util;
use Test::More tests => 5;
Test::More::use_ok('HTML::PullParser');
Test::More::use_ok('Marpa::R2::Test');
Test::More::use_ok('Marpa::R2::HTML');

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

my $result = Marpa::R2::HTML::html(
    \$html,
    {   q{*} => sub {
            return 'wildcard handler: ' . Marpa::R2::HTML::contents();
        },
        'head' => sub { return Marpa::R2::HTML::literal() },
        'html' => sub { return Marpa::R2::HTML::literal() },
        'body' => sub { return Marpa::R2::HTML::literal() },
        'div'  => sub {
            return '"div" handler: ' . Marpa::R2::HTML::contents();
        },
        '.high' => sub {
            return '".high" handler: ' . Marpa::R2::HTML::contents();
        },
        'div.high' => sub {
            return '"div.high" handler: ' . Marpa::R2::HTML::contents();
        },
        '.oddball' => sub {
            return '".oddball" handler: ' . Marpa::R2::HTML::contents();
        },
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

Marpa::R2::Test::is( ${$result}, $expected_result, 'handler precedence example' );

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
<p>Text</head><head>
</p>
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

