#!perl
# Copyright 2014 Jeffrey Kegler
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
use List::Util;
use Test::More;
use lib 'tool/lib';

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

BEGIN { use Test::More tests => 9; }

use Marpa::R2::Test;

# Marpa::R2::Display
# name: 'HTML Synopsis: Delete Tables'

use Marpa::R2::HTML qw(html);

my $with_table = 'Text<table><tr><td>I am a cell</table> More Text';
my $no_table   = html(
    \$with_table,
    {   table => sub { return q{} }
    }
);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: 'HTML Synopsis: Delete Everything But Tables'

my %handlers_to_keep_only_tables = (
    table  => sub { return Marpa::R2::HTML::original() },
    ':TOP' => sub { return \( join q{}, @{ Marpa::R2::HTML::values() } ) }
);
my $only_table = html( \$with_table, \%handlers_to_keep_only_tables );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: 'HTML Synopsis: Defective Tables'

my $with_bad_table = 'Text<tr>I am a cell</table> More Text';
my $only_bad_table = html( \$with_bad_table, \%handlers_to_keep_only_tables );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: 'HTML Synopsis: Delete Comments'

my $with_comment = 'Text <!-- I am a comment --> I am not a comment';
my $no_comment   = html(
    \$with_comment,
    {   ':COMMENT' => sub { return q{} }
    }
);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: 'HTML Synopsis: Change Title'

my $old_title = '<title>Old Title</title>A little html text';
my $new_title = html(
    \$old_title,
    {   'title' => sub { return '<title>New Title</title>' }
    }
);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: 'HTML Synopsis: Delete by Class'

my $stuff_to_be_edited = '<p>A<p class="delete_me">B<p>C';
my $edited_stuff       = html(
    \$stuff_to_be_edited,
    {   '.delete_me' => sub { return q{} }
    }
);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: 'HTML Synopsis: Supply Missing Tags'

sub supply_missing_tags {
    my $tagname = Marpa::R2::HTML::tagname();
    return if Marpa::R2::HTML::is_empty_element($tagname);
    return
          ( Marpa::R2::HTML::start_tag() // "<$tagname>\n" )
        . Marpa::R2::HTML::contents()
        . ( Marpa::R2::HTML::end_tag() // "</$tagname>\n" );
} ## end sub supply_missing_tags
my $html_with_just_a_title = '<title>I am a title and That is IT!';
my $valid_html_with_all_tags =
    html( \$html_with_just_a_title, { q{*} => \&supply_missing_tags } );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: 'HTML Synopsis: Maximum Element Depth'

sub depth_below_me {
    return List::Util::max( 0, @{ Marpa::R2::HTML::values() } );
}
my %handlers_to_calculate_maximum_element_depth = (
    q{*}   => sub { return 1 + depth_below_me() },
    ':TOP' => sub { return depth_below_me() },
);
my $maximum_depth_with_just_a_title = html( \$html_with_just_a_title,
    \%handlers_to_calculate_maximum_element_depth );

# Marpa::R2::Display::End

my $maximum_depth_with_all_tags_supplied = html( $valid_html_with_all_tags,
    \%handlers_to_calculate_maximum_element_depth );
Marpa::R2::Test::is( $maximum_depth_with_just_a_title,
    3, 'compute maximum depth' );
Marpa::R2::Test::is(
    $maximum_depth_with_just_a_title,
    $maximum_depth_with_all_tags_supplied,
    'compare maximum depths'
);

my $expected_valid_html_with_all_tags = <<'END_OF_EXPECTED';
<html>
<head>
<title>I am a title and That is IT!</title>
</head>
<body>
</body>
</html>
END_OF_EXPECTED

Marpa::R2::Test::is( ${$no_table}, 'Text More Text', 'delete tables' );
Marpa::R2::Test::is(
    ${$only_table},
    '<table><tr><td>I am a cell</table>',
    'keep only tables'
);
Marpa::R2::Test::is(
    ${$only_bad_table},
    '<tr>I am a cell</table>',
    'keep only tables -- bad table'
);
Marpa::R2::Test::is(
    ${$no_comment},
    'Text  I am not a comment',
    'delete comments'
);
Marpa::R2::Test::is(
    ${$new_title},
    '<title>New Title</title>A little html text',
    'replace title'
);
Marpa::R2::Test::is( ${$edited_stuff}, '<p>A<p>C', 'delete by class name' );
Marpa::R2::Test::is(
    ${$valid_html_with_all_tags},
    $expected_valid_html_with_all_tags,
    'supply tags'
);
