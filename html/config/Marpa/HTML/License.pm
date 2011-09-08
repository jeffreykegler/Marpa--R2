# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

package Marpa::HTML::Internal::License;

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Fatal qw(open close read);
use File::Spec;
use Text::Diff ();

my $copyright_line =
    q{This software is copyright (c) 2011 by Jeffrey Kegler};

my $closed_license = "$copyright_line\n" . <<'END_OF_STRING';
This document is not part of the Marpa or Marpa::XS source.
Although it may be included with a Marpa distribution that
is under an open source license, this document is
not under that open source license.
Jeffrey Kegler retains full rights.
END_OF_STRING

my $license_body = <<'END_OF_STRING';
This is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system
itself.
END_OF_STRING

my $license = "$copyright_line\n$license_body";

sub hash_comment {
    my ( $text, $char ) = @_;
    $char //= q{#};
    $text =~ s/^/$char /gxms;
    $text =~ s/ [ ] $//gxms;
    return $text;
} ## end sub hash_comment

my $hash_license       = hash_comment($license);
my $indented_license   = $license;
$indented_license =~ s/^/  /gxms;

my $pod_section = <<'END_OF_STRING';
=head1 COPYRIGHT AND LICENSE

=for Marpa::HTML::Display
ignore: 1

END_OF_STRING

$pod_section .= "$indented_license\n";

# Next line is to fake out display checking logic
# Otherwise it will think the lines to come are part
# of a display

=cut

$pod_section .= <<'END_OF_STRING';
=for Marpa::HTML::Display::End

END_OF_STRING

# Next line is to fake out display checking logic
# Otherwise it will think the lines to come are part
# of a display

=cut

sub trivial {
    my ( $filename, $verbose ) = @_;
    my $length   = 1000;
    my @problems = ();
    if ( -s $filename > $length ) {
        my $problem =
            qq{"Trivial" file is more than $length characters: "$filename"\n};
        push @problems, $problem;
    }
    return @problems;
} ## end sub trivial

sub check_tag {
    my ( $tag, $length ) = @_;
    $length //= 250;
    return sub {
        my ( $filename, $verbose ) = @_;
        my @problems = ();
        my $text = slurp_top( $filename, $length );
        if ( ( index ${$text}, $tag ) < 0 ) {
            my $problem = "tag missing in $filename\n";
            if ($verbose) {
                $problem .= "\nMissing tag:\n$tag\n";
            }
            push @problems, $problem;
        } ## end if ( ( index ${$text}, $tag ) < 0 )
        return @problems;
        }
} ## end sub check_tag

my %files_by_type = (
    'LICENSE' =>
        \&license_problems_in_license_file,    # Should be the Perl 5 license
    'META.json' => sub {;}
    ,    # not source, and not clear how to add license at top
    'META.yml' => sub {;}
    ,    # not source, and not clear how to add license at top
    'lib/Marpa/HTML/Test/capture-stderr' => sub {;},
    'script/html_fmt'                   => \&license_problems_in_perl_file,
    'script/html_score'                 => \&license_problems_in_perl_file,
    't/no_tang.html'                    => sub {;},
    't/test.html'                       => sub {;},
    't/fmt_t_data/expected1.html'       => sub {;},
    't/fmt_t_data/expected2.html'       => sub {;},
    't/fmt_t_data/input1.html'          => \&trivial,
    't/fmt_t_data/input2.html'          => \&trivial,
    't/fmt_t_data/score_expected1.html' => \&trivial,
    't/fmt_t_data/score_expected2.html' => \&trivial,
    'Makefile.PL'                       => \&trivial,
    'README'                            => \&trivial,
    'TODO'                              => \&trivial,
    'author.t/accept_tidy'              => \&trivial,
    'author.t/critic1'                  => \&trivial,
    'author.t/perltidyrc'               => \&trivial,
    'author.t/spelling_exceptions.list' => \&trivial,
    'author.t/tidy1'                    => \&trivial,
);

sub file_type {
    my ($filename) = @_;
    my $closure = $files_by_type{$filename};
    return $closure if defined $closure;
    my ( $volume, $dirpart, $filepart ) = File::Spec->splitpath($filename);
    my @dirs = grep {length} File::Spec->splitdir($dirpart);
    return sub {;}
        if scalar @dirs >= 1 and $dirs[0] eq 'html' ;
    return \&trivial if $filepart eq '.gitignore';
    return \&license_problems_in_perl_file
        if $filepart =~ /[.] (t|pl|pm|PL) \z /xms;
    return \&license_problems_in_pod_file if $filepart =~ /[.]pod \z/xms;
    return \&license_problems_in_hash_file

        # return \&license_problems_in_text_file;
} ## end sub file_type

sub Marpa::HTML::License::file_license_problems {
    my ( $filename, $verbose ) = @_;
    $verbose //= 1;
    my @problems = ();
    my $closure = file_type($filename);
    if ( defined $closure ) {
        push @problems, $closure->( $filename, $verbose );
        return @problems;
    }

    # type eq "text"
    push @problems, license_problems_in_text_file( $filename, $verbose );
    return @problems;
} ## end sub Marpa::HTML::License::file_license_problems

## no critic (Subroutines::RequireArgUnpacking)
sub Marpa::HTML::License::license_problems {
    return map { Marpa::HTML::License::file_license_problems( $_, 0 ) } @_;
}
## use critic

sub slurp {
    my ($filename) = @_;
    local $RS = undef;
    open my $fh, q{<}, $filename;
    my $text = <$fh>;
    close $fh;
    return \$text;
} ## end sub slurp

sub slurp_top {
    my ( $filename, $length ) = @_;
    $length //= 1000 + ( length $license );
    local $RS = undef;
    open my $fh, q{<}, $filename;
    my $text;
    read $fh, $text, $length;
    close $fh;
    return \$text;
} ## end sub slurp_top

sub files_equal {
    my ( $filename1, $filename2 ) = @_;
    return ${ slurp($filename1) } eq ${ slurp($filename2) };
}

sub tops_equal {
    my ( $filename1, $filename2, $length ) = @_;
    return ${ slurp_top($filename1, $length) } eq ${ slurp_top($filename2, $length) };
}

sub license_problems_in_license_file {
    my ( $filename, $verbose ) = @_;
    my @problems      = ();
    my $text          = ${ slurp($filename) };
    my $length = length $text;
    if ( $length != 18374 ) {
        my $problem = "LICENSE file is wrong: length is $length\n";
        push @problems, $problem;
    }
    my $Copyright_line = $copyright_line;
    $Copyright_line =~ s/copyright/Copyright/;
    my $copyright_pos = index $text, $copyright_line, 0;
    if ( $copyright_pos != 0 ) {
        my $problem = "LICENSE file is wrong: first copyright at position $copyright_pos\n";
        push @problems, $problem;
    }
    $copyright_pos = index $text, $Copyright_line, $copyright_pos+1;
    if ( $copyright_pos != 485 ) {
        my $problem = "LICENSE file is wrong: second copyright at position $copyright_pos\n";
        push @problems, $problem;
    }
    $copyright_pos = index $text, $Copyright_line, $copyright_pos+1;
    if ( $copyright_pos != 13304 ) {
        my $problem = "LICENSE file is wrong: third copyright at position $copyright_pos\n";
        push @problems, $problem;
    }
    return @problems;
} ## end sub license_problems_in_license_file

sub license_problems_in_hash_file {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text = slurp_top( $filename, length $hash_license );
    if ( $hash_license ne ${$text} ) {
        my $problem = "No license language in $filename (hash style)\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( $text, \$hash_license )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( $hash_license ne ${$text} )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $hash_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_hash_file

sub license_problems_in_perl_file {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text = slurp_top( $filename, 132 + length $hash_license );

    # Delete hash bang line, if present
    ${$text} =~ s/\A [#][!] [^\n] \n//xms;
    if ( 0 > index ${$text}, $hash_license ) {
        my $problem = "No license language in $filename (perl style)\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( $text, \$hash_license )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( 0 > index ${$text}, $hash_license )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $hash_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_perl_file

sub license_problems_in_pod_file {
    my ( $filename, $verbose ) = @_;

    # Pod files are Perl files, and should also have the
    # license statement at the start of the file
    my @problems = license_problems_in_hash_file( $filename, $verbose );

    my $text = ${ slurp($filename) };
    if ( $text =~ m/ ^ [=]head1 \s+ COPYRIGHT \s+ AND \s+ LICENSE /xmsp ) {
        ## no critic (Variables::ProhibitPunctuationVars);
        my $pos = length ${^PREMATCH};
        $text = substr $text, $pos;
    }
    else {
        push @problems,
            "No COPYRIGHT AND LICENSE header in pod file $filename\n";
    }
    if ( not scalar @problems and ( index $text, $pod_section ) < 0 ) {
        my $problem = "No LICENSE pod section in $filename\n";
        if ($verbose) {
            $problem .= "Missing pod section:\n"
                . Text::Diff::diff( \$text, \$pod_section );
        }
        push @problems, $problem;
    } ## end if ( not scalar @problems and ( index $text, $pod_section...))
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== licensing pod section for $filename should be as follows:\n"
            . $pod_section
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_pod_file

# In "Text" files, just look for the full language.
# No need to comment it out.
sub license_problems_in_text_file {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text     = slurp_top($filename);
    if ( ( index ${$text}, $license ) < 0 ) {
        my $problem = "Full language missing in text file $filename\n";
        if ($verbose) {
            $problem .= "\nMissing license language:\n"
                . Text::Diff::diff( $text, \$license );
        }
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $license ) < 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== licensing pod section for $filename should be as follows:\n"
            . $pod_section
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_text_file

1;

