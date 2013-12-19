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
use Text::Diff;
use Getopt::Long qw(GetOptions);
use List::Util;
use Test::More 0.94;
use Carp;

use Perl::Tidy;
use Text::Wrap;

use lib 'inc';
use Marpa::R2::Display;

my $warnings = 0;
my $options_result = GetOptions( 'warnings' => \$warnings );

Marpa::R2::exception("$PROGRAM_NAME options parsing failed")
    if not $options_result;

my %exclude = map { ( $_, 1 ) } qw();
my @additional_files = qw();

my @test_files = @ARGV;
my $debug_mode = scalar @test_files;
if ( not $debug_mode ) {

    for my $additional_file (@additional_files) {
        Test::More::diag("Adding $additional_file");
        push @test_files, $additional_file;
    }

    open my $manifest, '<', 'MANIFEST'
        or Marpa::R2::exception("Cannot open MANIFEST: $ERRNO");
    FILE: while ( my $file = <$manifest> ) {
        chomp $file;
        $file =~ s/\s*[#].*\z//xms;
        next FILE if $file =~ m( [/] old_pod [/] )xms;
        next FILE if $file =~ m( html [/] etc [/] drafts [/] )xms;
        my ($ext) = $file =~ / [.] ([^.]+) \z /xms;
        next FILE if not defined $ext;
        $ext = lc $ext;
        next FILE
            if $ext ne 'pod'
                and $ext ne 'pl'
                and $ext ne 'pm'
                and $ext ne 't';
        push @test_files, $file;
    }    # FILE
    close $manifest;

    my %file_seen = ();
    FILE: for my $test_file (@test_files) {

        next FILE if $exclude{$test_file};
        next FILE if -d $test_file;
        if ( $file_seen{$test_file}++ ) {
            Test::More::diag("Duplicate file: $test_file");
        }
    } ## end for my $test_file (@test_files)
    @test_files = keys %file_seen;

} ## end if ( not $debug_mode )

my $error_file;
## no critic (InputOutput::RequireBriefOpen)
if ($debug_mode) {
    open $error_file, '>&STDOUT'
        or Marpa::R2::exception("Cannot dup STDOUT: $ERRNO");
}
else {
    open $error_file, '>', 'author.t/display.errs'
        or Marpa::R2::exception("Cannot open display.errs: $ERRNO");
}
## use critic

my $display_data = Marpa::R2::Display->new();

FILE: for my $file (@test_files) {
    if ( not -f $file ) {
        Test::More::fail(qq{"$file" is not a file});
        next FILE;
    }
    $display_data->read($file);

} ## end for my $file (@test_files)

my @formatting_instructions = qw(perltidy
    remove-display-indent
    remove-blank-last-line inline
    partial flatten normalize-whitespace);

sub format_display {
    my ( $text, $instructions, $is_copy ) = @_;
    my $result = ${$text};

    if ( $instructions->{'remove-display-indent'} and $is_copy ) {
        my ($first_line_spaces) = ( $result =~ /^ (\s+) \S/xms );
        $first_line_spaces = quotemeta $first_line_spaces;
        $result =~ s/^$first_line_spaces//gxms;
    }
    if ( $instructions->{'inline'} ) {
        my $min_indent = 99_999_999;
        my @text = grep {/ [^ ] /xms} split /\n/xms, $result;
        for my $line (@text) {
            my ($s) = ( $line =~ / \A  ([ ]* ) /xms );
            my $indent = length $s;
            $min_indent > $indent and $min_indent = $indent;
        }
        $result = join "\n", map { substr $_, $min_indent } @text;
        my $tidied;

        # perltidy options chosen to make it as likely
        # as possible that code which differs
        # only in whitespace
        # will end up the same.
        Perl::Tidy::perltidy(
            source      => \$result,
            destination => \$tidied,
            perltidyrc  => \'-sbt=0 -iob -dcsc -sil=0',
        );
        $result = $tidied;
    } ## end if ( $instructions->{'inline'} )
    if ( $instructions->{'remove-blank-last-line'} ) {
        $result =~ s/^[ \t]*\n\z//xms;
    }
    if ( $instructions->{'flatten'} ) {
        $result =~ s/[\n\r]/ /gxms;
    }
    if ( $instructions->{'normalize-whitespace'} ) {
        $result =~ s/^\s+//gxms;
        $result =~ s/\s+$//gxms;
        $result =~ s/[ \f\t]+/ /gxms;
        $result =~ s/\n+/\n/gxms;
    } ## end if ( $instructions->{'normalize-whitespace'} )
    if ( defined( my $tidy_options = $instructions->{'perltidy'} ) ) {
        my $tidied;
        Perl::Tidy::perltidy(
            source      => \$result,
            destination => \$tidied,
            perltidyrc  => \$tidy_options
        );
        $result = $tidied;
    } ## end if ( defined( my $tidy_options = $instructions->{'perltidy'...}))
    return \$result;
} ## end sub format_display

# reformat two display according to the instructions in the
# second, and compare.
sub compare {
    my ( $original, $copy ) = @_;
    my $formatted_original =
        format_display( \$original->{content}, $copy, 0 );
    my $formatted_copy = format_display( \$copy->{content}, $copy, 1 );
    if ( $copy->{partial} ) {
        return 1 if -1 != index ${$formatted_original}, ${$formatted_copy};
        Test::More::diag(
            "Partial: ",
            $copy->{filename},
            ' vs. ',
            $original->{filename},
            "\n",
            (   Text::Diff::diff $formatted_original,
                $formatted_copy,
                { STYLE => 'Table' }
            )
            # Text::Wrap::wrap( q{    }, q{    }, ${$formatted_copy} ),
            # "\nOriginal:\n",
            # Text::Wrap::wrap( q{    }, q{    }, ${$formatted_original} )
        );
        return 0;
    } ## end if ( $copy->{partial} )
    return 1 if ${$formatted_original} eq ${$formatted_copy};
    Test::More::diag(
        'Differences: ',
        $original->{filename},
        ' vs. ',
        $copy->{filename},
        "\n",
        (   Text::Diff::diff $formatted_original,
            $formatted_copy,
            { STYLE => 'Table' }
        )
    );
    return 0;
} ## end sub compare

my $tests_run        = 0;
my $displays_by_name = $display_data->{displays};
DISPLAY_NAME: for my $display_name ( keys %{$displays_by_name} ) {

    my $displays = $displays_by_name->{$display_name};
    if ( scalar @{$displays} <= 1 ) {
        Test::More::fail(
            qq{Display "$display_name" has only one instance, in file }
                . $displays->[0]->{filename} );
        $tests_run++;
    } ## end if ( scalar @{$displays} <= 1 )

    # find the "original"
    my $original_ix;
    DISPLAY: for my $display_ix ( 0 .. $#{$displays} ) {
        if (not grep { $_ ~~ \@formatting_instructions }
            keys %{ $displays->[$display_ix] }
            )
        {
            $original_ix = $display_ix;
        } ## end if ( not grep { $_ ~~ \@formatting_instructions } keys...)
    } ## end for my $display_ix ( 0 .. $#{$displays} )

    # Warn if there wasn't a clear original?
    $original_ix //= 0;    # default to the first

    DISPLAY: for my $copy_ix ( 0 .. $#{$displays} ) {
        next DISPLAY if $copy_ix == $original_ix;
        Test::More::ok compare( $displays->[$original_ix],
            $displays->[$copy_ix] ), "$display_name, copy $copy_ix";
        $tests_run++;
    } ## end for my $copy_ix ( 0 .. $#{$displays} )

} ## end for my $display_name ( keys %{$displays_by_name} )

my $verbatim_by_file = $display_data->{verbatim_lines};
VERBATIM_FILE: for my $verbatim_file ( keys %{$verbatim_by_file} ) {
    my @unchecked      = ();
    my $verbatim_lines = $verbatim_by_file->{$verbatim_file};
    for my $verbatim_line_number ( 1 .. $#{$verbatim_lines} ) {
        my $verbatim_line = $verbatim_lines->[$verbatim_line_number];
        if ($verbatim_line) {
            push @unchecked, "$verbatim_line_number: $verbatim_line";
        }
    } ## end for my $verbatim_line_number ( 1 .. $#{$verbatim_lines...})
    next VERBATIM_FILE if not @unchecked;
    Test::More::fail( qq{Verbatim line(s) not checked in "$verbatim_file": }
            . ( scalar @unchecked )
            . " lines\n"
            . ( join "\n", @unchecked ) );
    $tests_run++;
} ## end for my $verbatim_file ( keys %{$verbatim_by_file} )

Test::More::done_testing($tests_run);

__END__

# vim: set expandtab shiftwidth=4:
