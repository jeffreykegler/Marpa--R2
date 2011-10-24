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
use Test::More tests => 11;
Test::More::use_ok('HTML::PullParser');
Test::More::use_ok('Marpa::HTML::Test');

# This is just a dummy value for the synopsis
my %empty_elements = ();

# Marpa::HTML::Display
# name: 'HTML Synopsis: Delete Tables'

use Marpa::HTML qw(html);

my $with_table = 'Text<table><tr><td>I am a cell</table> More Text';
my $no_table   = html(
    \$with_table,
    {   table => sub { return q{} }
    }
);

# Marpa::HTML::Display::End

# Marpa::HTML::Display
# name: 'HTML Synopsis: Delete Everything But Tables'

my %handlers_to_keep_only_tables = (
    table  => sub { return Marpa::HTML::original() },
    ':TOP' => sub { return \( join q{}, @{ Marpa::HTML::values() } ) }
);
my $only_table = html( \$with_table, \%handlers_to_keep_only_tables );

# Marpa::HTML::Display::End

# Marpa::HTML::Display
# name: 'HTML Synopsis: Defective Tables'

my $with_bad_table = 'Text<tr>I am a cell</table> More Text';
my $only_bad_table = html( \$with_bad_table, \%handlers_to_keep_only_tables );

# Marpa::HTML::Display::End

# Marpa::HTML::Display
# name: 'HTML Synopsis: Delete Comments'

my $with_comment = 'Text <!-- I am a comment --> I am not a comment';
my $no_comment   = html(
    \$with_comment,
    {   ':COMMENT' => sub { return q{} }
    }
);

# Marpa::HTML::Display::End

# Marpa::HTML::Display
# name: 'HTML Synopsis: Change Title'

my $old_title = '<title>Old Title</title>A little html text';
my $new_title = html(
    \$old_title,
    {   'title' => sub { return '<title>New Title</title>' }
    }
);

# Marpa::HTML::Display::End

# Marpa::HTML::Display
# name: 'HTML Synopsis: Delete by Class'

my $stuff_to_be_edited = '<p>A<p class="delete_me">B<p>C';
my $edited_stuff       = html(
    \$stuff_to_be_edited,
    {   '.delete_me' => sub { return q{} }
    }
);

# Marpa::HTML::Display::End

# Marpa::HTML::Display
# name: 'HTML Synopsis: Supply Missing Tags'

sub supply_missing_tags {
    my $tagname = Marpa::HTML::tagname();
    return if $empty_elements{$tagname};
    return
          ( Marpa::HTML::start_tag() // "<$tagname>\n" )
        . Marpa::HTML::contents()
        . ( Marpa::HTML::end_tag() // "</$tagname>\n" );
} ## end sub supply_missing_tags
my $html_with_just_a_title = '<title>I am a title and That is IT!';
my $valid_html_with_all_tags =
    html( \$html_with_just_a_title, { q{*} => \&supply_missing_tags } );

# Marpa::HTML::Display::End

# Marpa::HTML::Display
# name: 'HTML Synopsis: Maximum Element Depth'

sub depth_below_me {
    return List::Util::max( 0, @{ Marpa::HTML::values() } );
}
my %handlers_to_calculate_maximum_element_depth = (
    q{*}   => sub { return 1 + depth_below_me() },
    ':TOP' => sub { return depth_below_me() },
);
my $maximum_depth_with_just_a_title = html( \$html_with_just_a_title,
    \%handlers_to_calculate_maximum_element_depth );

# Marpa::HTML::Display::End

my $maximum_depth_with_all_tags_supplied = html( $valid_html_with_all_tags,
    \%handlers_to_calculate_maximum_element_depth );
Marpa::HTML::Test::is( $maximum_depth_with_just_a_title,
    3, 'compute maximum depth' );
Marpa::HTML::Test::is(
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

Marpa::HTML::Test::is( ${$no_table}, 'Text More Text', 'delete tables' );
Marpa::HTML::Test::is(
    ${$only_table},
    '<table><tr><td>I am a cell</table>',
    'keep only tables'
);
Marpa::HTML::Test::is(
    ${$only_bad_table},
    '<tr>I am a cell</table>',
    'keep only tables -- bad table'
);
Marpa::HTML::Test::is(
    ${$no_comment},
    'Text  I am not a comment',
    'delete comments'
);
Marpa::HTML::Test::is(
    ${$new_title},
    '<title>New Title</title>A little html text',
    'replace title'
);
Marpa::HTML::Test::is( ${$edited_stuff}, '<p>A<p>C', 'delete by class name' );
Marpa::HTML::Test::is(
    ${$valid_html_with_all_tags},
    $expected_valid_html_with_all_tags,
    'supply tags'
);
