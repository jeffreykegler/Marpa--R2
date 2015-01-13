#!perl
# Copyright 2015 Jeffrey Kegler
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

# Documented methods and argspecs which had no
# tests as of Sep 2012

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

BEGIN { Test::More::plan tests => 1; }

use Marpa::R2::HTML;
use lib 'tool/lib';
use Marpa::R2::Test;

my $html = <<'END_OF_HTML';
<h1 title="h1_title">Header with title attribute</h2>
<p title="p_title">Graf with title attribute
<span title="span_title">Div with title attribute</span>
stuff
</p>
<!-- A comment -->
<div title="div_title">Div with title attribute</div>
END_OF_HTML

sub handler {
    my $offset = Marpa::R2::HTML::offset() // q{-};
    my $title  = Marpa::R2::HTML::title()  // q{-};
    my $element = Marpa::R2::HTML::tagname();
    my $description =
        qq{element "$element", titled "$title", at offset $offset};
    return join "\n", @{ Marpa::R2::HTML::values() }, $description;
} ## end sub handler

my $result_ref = Marpa::R2::HTML::html( \$html, { q{*} => \&handler } );
my $result = ref $result_ref ? ${$result_ref} : 'Parse failed';
$result .= "\n";

my $expected_result = <<'END_OF_TEXT';
element "head", titled "-", at offset -
element "h1", titled "h1_title", at offset 0
element "span", titled "span_title", at offset 99
element "p", titled "p_title", at offset 54
element "div", titled "div_title", at offset 186
element "body", titled "-", at offset 0
element "html", titled "-", at offset 0
END_OF_TEXT

Marpa::R2::Test::is( $result, $expected_result, qq{"missing" features test} );
