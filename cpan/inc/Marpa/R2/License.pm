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

package Marpa::R2::Internal::License;

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Fatal qw(open close read);
use File::Spec;
use Text::Diff ();

my $copyright_line = q{Copyright 2014 Jeffrey Kegler};
( my $copyright_line_in_tex = $copyright_line )
    =~ s/ ^ Copyright \s /Copyright \\copyright\\ /xms;

my $closed_license = "$copyright_line\n" . <<'END_OF_STRING';
This document is not part of the Marpa or Marpa::R2 source.
Although it may be included with a Marpa distribution that
is under an open source license, this document is
not under that open source license.
Jeffrey Kegler retains full rights.
END_OF_STRING

my $license_body = <<'END_OF_STRING';
This file is part of Marpa::R2.  Marpa::R2 is free software: you can
redistribute it and/or modify it under the terms of the GNU Lesser
General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

Marpa::R2 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser
General Public License along with Marpa::R2.  If not, see
http://www.gnu.org/licenses/.
END_OF_STRING

my $license = "$copyright_line\n$license_body";
my $libmarpa_license = $license;
$libmarpa_license =~ s/Marpa::R2/Libmarpa/gxms;

# License, redone as Tex input
my $license_in_tex =
    "$copyright_line_in_tex\n" . "\\bigskip\\noindent\n" . "$license_body";
$license_in_tex =~ s/^$/\\smallskip\\noindent/gxms;

my $license_file = $license . <<'END_OF_STRING';

In the Marpa::R2 distribution, the GNU Lesser General Public License
version 3 should be in a file named "COPYING.LESSER".
END_OF_STRING

my $texi_copyright = <<'END_OF_TEXI_COPYRIGHT';
Copyright @copyright{} 2014 Jeffrey Kegler.
END_OF_TEXI_COPYRIGHT

my $fdl_license = <<'END_OF_FDL_LANGUAGE';
@quotation
Permission is granted to copy, distribute and/or modify this document
under the terms of the @acronym{GNU} Free Documentation License,
Version 1.3 or any later version published by the Free Software
Foundation.
A copy of the license is included in the section entitled
``@acronym{GNU} Free Documentation License.''
@end quotation
@end copying
END_OF_FDL_LANGUAGE

my $cc_a_nd_body = <<'END_OF_CC_A_ND_LANGUAGE';
This document is licensed under
a Creative Commons Attribution-NoDerivs 3.0 United States License.
END_OF_CC_A_ND_LANGUAGE

my $cc_a_nd_license = "$copyright_line\n$cc_a_nd_body";
my $cc_a_nd_thanks = $cc_a_nd_body;

sub hash_comment {
    my ( $text, $char ) = @_;
    $char //= q{#};
    $text =~ s/^/$char /gxms;
    $text =~ s/ [ ]+ $//gxms;
    return $text;
} ## end sub hash_comment

# Assumes $text ends in \n
sub c_comment {
    my ($text) = @_;
    $text =~ s/^/ * /gxms;
    $text =~ s/ [ ] $//gxms;
    return qq{/*\n$text */\n};
} ## end sub c_comment

my $c_license          = c_comment($libmarpa_license);
my $xs_license          = c_comment($license);
my $r2_hash_license    = hash_comment($license);
my $libmarpa_hash_license    = hash_comment($libmarpa_license);
my $xsh_hash_license    = hash_comment($license, q{ #});
my $tex_closed_license = hash_comment( $closed_license, q{%} );
my $tex_license        = hash_comment( $license, q{%} );
my $tex_cc_a_nd_license = hash_comment( $cc_a_nd_license, q{%} );
my $indented_license   = $license;
$indented_license =~ s/^/  /gxms;
$indented_license =~ s/[ ]+$//gxms;

my $pod_section = <<'END_OF_STRING';
=head1 Copyright and License

=for Marpa::R2::Display
ignore: 1

END_OF_STRING

$pod_section .= "$indented_license\n";

# Next line is to fake out display checking logic
# Otherwise it will think the lines to come are part
# of a display

=cut

$pod_section .= <<'END_OF_STRING';
=for Marpa::R2::Display::End

END_OF_STRING

# Next line is to fake out display checking logic
# Otherwise it will think the lines to come are part
# of a display

=cut

my %GNU_file = (
    map {
    (
        'core/read_only/' . $_,   1,
        )
    } qw(
        aclocal.m4
        config.guess
        config.sub
        configure
        depcomp
        mdate-sh
        texinfo.tex
        ltmain.sh
        m4/libtool.m4
        m4/ltoptions.m4
        m4/ltsugar.m4
        m4/ltversion.m4
        m4/lt~obsolete.m4
        missing
        Makefile.in
    )
);;

sub ignored {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    if ($verbose) {
        say {*STDERR} "Checking $filename as ignored file" or die "say failed: $ERRNO";
    }
    return @problems;
} ## end sub trivial

sub trivial {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as trivial file" or die "say failed: $ERRNO";
    }
    my $length   = 1000;
    my @problems = ();
    my $actual_length = -s $filename;
    if (not defined $actual_length) {
        my $problem =
            qq{"Trivial" file does not exit: "$filename"\n};
        return $problem;
    }
    if ( -s $filename > $length ) {
        my $problem =
            qq{"Trivial" file is more than $length characters: "$filename"\n};
        push @problems, $problem;
    }
    return @problems;
} ## end sub trivial

sub check_GNU_copyright {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as GNU copyright file" or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text = slurp_top( $filename, 1000 );
    ${$text} =~ s/^[#]//gxms;
    if ( ${$text}
        !~ / \s copyright \s .* Free \s+ Software \s+ Foundation [\s,] /xmsi )
    {
        my $problem = "GNU copyright missing in $filename\n";
        if ($verbose) {
            $problem .= "$filename starts:\n" . ${$text} . "\n";
        }
        push @problems, $problem;
    } ## end if ( ${$text} !~ ...)
    return @problems;
} ## end sub check_GNU_copyright

sub check_X_copyright {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as X Consortium file" or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text = slurp_top( $filename, 1000 );
    if ( ${$text} !~ / \s copyright \s .* X \s+ Consortium [\s,] /xmsi ) {
        my $problem = "X copyright missing in $filename\n";
        if ($verbose) {
            $problem .= "$filename starts:\n" . ${$text} . "\n";
        }
        push @problems, $problem;
    } ## end if ( ${$text} !~ ...)
    return @problems;
} ## end sub check_X_copyright

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
    'COPYING.LESSER' => \&ignored,    # GNU license text, leave it alone
    'LICENSE' => \&license_problems_in_license_file,
    'META.json' =>
        \&ignored,    # not source, and not clear how to add license at top
    'META.yml' =>
        \&ignored,    # not source, and not clear how to add license at top
    'README'                            => \&trivial,
    'TODO'                              => \&trivial,
    'author.t/accept_tidy'              => \&trivial,
    'author.t/critic1'                  => \&trivial,
    'author.t/perltidyrc'               => \&trivial,
    'author.t/spelling_exceptions.list' => \&trivial,
    'author.t/tidy1'                    => \&trivial,
    'etc/dovg.sh'                       => \&trivial,
    'etc/compile_for_debug.sh'          => \&trivial,
    'etc/reserved_check.sh'             => \&trivial,
    'html/script/marpa_r2_html_fmt'     => gen_license_problems_in_perl_file(),
    'html/script/marpa_r2_html_score'   => gen_license_problems_in_perl_file(),
    'html/t/fmt_t_data/expected1.html'  => \&ignored,
    'html/t/fmt_t_data/expected2.html'  => \&ignored,
    'html/t/fmt_t_data/input1.html'     => \&trivial,
    'html/t/fmt_t_data/input2.html'     => \&trivial,
    'html/t/fmt_t_data/score_expected1.html'   => \&trivial,
    'html/t/fmt_t_data/score_expected2.html'   => \&trivial,
    'html/t/no_tang.html'                      => \&ignored,
    'html/t/test.html'                         => \&ignored,
    'core/read_only/LIB_VERSION'                => \&trivial,
    'core/read_only/LIB_VERSION.in'             => \&trivial,
    'core/read_only/Makefile.am'             => gen_license_problems_in_hash_file($libmarpa_hash_license),
    'core/read_only/configure.ac'             => gen_license_problems_in_hash_file($libmarpa_hash_license),
    'core/read_only/notes/shared_test.txt' => gen_license_problems_in_hash_file($libmarpa_hash_license),
    'core/read_only/Makefile.win32'             => gen_license_problems_in_hash_file($libmarpa_hash_license),
    'core/read_only/win32/do_config_h.pl' => gen_license_problems_in_perl_file($libmarpa_hash_license),
    'etc/my_suppressions'              => \&trivial,
    'xs/ppport.h' => \&ignored,    # copied from CPAN, just leave it alone
    'core/read_only/README.INSTALL' => \&trivial,

    # Leave Pfaff's licensing as is
    'core/read_only/marpa_tavl.c' => \&ignored,
    'core/read_only/marpa_tavl.h' => \&ignored,

    # MS .def file -- contents trivial
    'core/read_only/win32/marpa.def' => \&ignored,
);

# Common files in the GNU distributions
for my $distlib (
    qw(core/read_only)
    )
{
    $files_by_type{"$distlib/AUTHORS"}   = \&trivial;
    $files_by_type{"$distlib/NEWS"}      = \&trivial;
    $files_by_type{"$distlib/ChangeLog"} = \&trivial;

    ## GNU license text, leave it alone
    $files_by_type{"$distlib/COPYING.LESSER"} = \&ignored;

    ## GNU standard -- has their license language
    $files_by_type{"$distlib/INSTALL"} = \&ignored;

    $files_by_type{"$distlib/README"}     = gen_license_problems_in_text_file( $libmarpa_license );
    $files_by_type{"$distlib/stamp-h1"}   = \&trivial;
    $files_by_type{"$distlib/stamp-1"}   = \&trivial;
    $files_by_type{"$distlib/stamp-vti"}   = \&trivial;
    $files_by_type{"$distlib/install-sh"} = \&check_X_copyright;
    $files_by_type{"$distlib/config.h.in"} =
        check_tag( 'Generated from configure.ac by autoheader', 250 );
} ## end for my $distlib (...)

sub file_type {
    my ($filename) = @_;
    my $closure = $files_by_type{$filename};
    return $closure if defined $closure;
    my ( $volume, $dirpart, $filepart ) = File::Spec->splitpath($filename);
    my @dirs = grep {length} File::Spec->splitdir($dirpart);
    return gen_license_problems_in_perl_file()
        if scalar @dirs > 1
            and $dirs[0] eq 'pperl'
            and $filepart =~ /[.]pm\z/xms;
    return \&ignored if $filepart =~ /[.]tar\z/xms;

    # info files are generated -- licensing is in source
    return \&ignored if $filepart =~ /[.]info\z/xms;
    return \&trivial if $filepart eq '.gitignore';
    return \&trivial if $filepart eq '.gitattributes';
    return \&trivial if $filepart eq '.gdbinit';
    return \&check_GNU_copyright
        if $GNU_file{$filename};
    return gen_license_problems_in_perl_file()
        if $filepart =~ /[.] (t|pl|pm|PL) \z /xms;
    return gen_license_problems_in_perl_file()
        if $filepart eq 'typemap';
    return \&license_problems_in_fdl_file
        if $filepart eq 'internal.texi';
    return \&license_problems_in_fdl_file
        if $filepart eq 'api.texi';
    return \&license_problems_in_pod_file if $filepart =~ /[.]pod \z/xms;
    return gen_license_problems_in_c_file($xs_license)
        if $filepart =~ /[.] (xs) \z /xms;
    return gen_license_problems_in_c_file()
        if $filepart =~ /[.] (c|h) \z /xms;
    return \&license_problems_in_xsh_file
        if $filepart =~ /[.] (xsh) \z /xms;
    return \&license_problems_in_sh_file
        if $filepart =~ /[.] (sh) \z /xms;
    return gen_license_problems_in_c_file()
        if $filepart =~ /[.] (c|h) [.] in \z /xms;
    return \&license_problems_in_tex_file
        if $filepart =~ /[.] (w) \z /xms;
    return gen_license_problems_in_hash_file()

} ## end sub file_type

sub Marpa::R2::License::file_license_problems {
    my ( $filename, $verbose ) = @_;
    $verbose //= 0;
    if ($verbose) {
        say {*STDERR} "Checking license of $filename" or die "say failed: $ERRNO";
    }
    my @problems = ();
    return @problems if @problems;
    my $closure = file_type($filename);
    if ( defined $closure ) {
        push @problems, $closure->( $filename, $verbose );
        return @problems;
    }

    # type eq "text"
    my $problems_closure = gen_license_problems_in_text_file();
    push @problems, $problems_closure->( $filename, $verbose );
    return @problems;
} ## end sub Marpa::R2::License::file_license_problems

sub Marpa::R2::License::license_problems {
    my ( $files, $verbose ) = @_;
    return
        map { Marpa::R2::License::file_license_problems( $_, $verbose ) }
        @{$files};
} ## end sub Marpa::R2::License::license_problems

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
    return ${ slurp_top( $filename1, $length ) } eq
        ${ slurp_top( $filename2, $length ) };
}

sub license_problems_in_license_file {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text     = ${ slurp($filename) };
    if ( $text ne $license_file ) {
        my $problem = "LICENSE file is wrong\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( \$text, \$license_file )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( $text ne $license_file )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== $filename should be as follows:\n"
            . $license_file
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_license_file

sub gen_license_problems_in_hash_file {
    my ($license) = @_;
    $license //= $r2_hash_license;
    return sub {
        my ( $filename, $verbose ) = @_;
        if ($verbose) {
            say {*STDERR} "Checking $filename as hash style file"
                or die "say failed: $ERRNO";
        }
        my @problems = ();
        my $text = slurp_top( $filename, length $license );
        if ( $license ne ${$text} ) {
            my $problem = "No license language in $filename (hash style)\n";
            if ($verbose) {
                $problem
                    .= "=== Differences ===\n"
                    . Text::Diff::diff( $text, \$license )
                    . ( q{=} x 30 );
            } ## end if ($verbose)
            push @problems, $problem;
        } ## end if ( $license ne ${$text} )
        if ( scalar @problems and $verbose >= 2 ) {
            my $problem =
                  "=== license for $filename should be as follows:\n"
                . $license
                . ( q{=} x 30 );
            push @problems, $problem;
        } ## end if ( scalar @problems and $verbose >= 2 )
        return @problems;
    };
} ## end sub gen_license_problems_in_hash_file

sub license_problems_in_xsh_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as hash style file"
            or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text = slurp_top( $filename, length $xsh_hash_license );
    if ( $xsh_hash_license ne ${$text} ) {
        my $problem = "No license language in $filename (hash style)\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( $text, \$xsh_hash_license )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( $xsh_hash_license ne ${$text} )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $xsh_hash_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_xsh_file

sub license_problems_in_sh_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as sh hash style file"
            or die "say failed: $ERRNO";
    }
    my @problems = ();
    $DB::single = 1;
    my $ref_text = slurp_top( $filename, 256 + length $r2_hash_license );
    my $text = ${$ref_text};
    $text =~ s/ \A [#][!] [^\n]* \n//xms;
    $text = substr $text, 0, length $r2_hash_license;
    if ( $r2_hash_license ne $text ) {
        my $problem = "No license language in $filename (sh hash style)\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( \$text, \$r2_hash_license )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    }
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $r2_hash_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
}


sub gen_license_problems_in_perl_file {
    my ($license) = @_;
    my $perl_license = $license // $r2_hash_license;
    return sub {
        my ( $filename, $verbose ) = @_;
        if ($verbose) {
            say {*STDERR} "Checking $filename as perl file"
                or die "say failed: $ERRNO";
        }
        $verbose //= 0;
        my @problems = ();
        my $text = slurp_top( $filename, 132 + length $perl_license );

        # Delete hash bang line, if present
        ${$text} =~ s/\A [#][!] [^\n] \n//xms;
        if ( 0 > index ${$text}, $perl_license ) {
            my $problem = "No license language in $filename (perl style)\n";
            if ($verbose) {
                $problem
                    .= "=== Differences ===\n"
                    . Text::Diff::diff( $text, \$perl_license )
                    . ( q{=} x 30 );
            } ## end if ($verbose)
            push @problems, $problem;
        } ## end if ( 0 > index ${$text}, $perl_license )
        if ( scalar @problems and $verbose >= 2 ) {
            my $problem =
                  "=== license for $filename should be as follows:\n"
                . $perl_license
                . ( q{=} x 30 );
            push @problems, $problem;
        } ## end if ( scalar @problems and $verbose >= 2 )
        return @problems;
    };
} ## end sub gen_license_problems_in_perl_file

sub gen_license_problems_in_c_file {
    my ($license) = @_;
    $license //= $c_license;
    return sub {
        my ( $filename, $verbose ) = @_;
        if ($verbose) {
            say {*STDERR} "Checking $filename as C file"
                or die "say failed: $ERRNO";
        }
        my @problems = ();
        my $text = slurp_top( $filename, 500 + length $license );
        ${$text}
            =~ s{ \A [/][*] \s+ DO \s+ NOT \s+ EDIT \s+ DIRECTLY [^\n]* \n }{}xms;
        if ( ( index ${$text}, $license ) < 0 ) {
            my $problem = "No license language in $filename (C style)\n";
            if ($verbose) {
                $problem
                    .= "=== Differences ===\n"
                    . Text::Diff::diff( $text, \$license )
                    . ( q{=} x 30 );
            } ## end if ($verbose)
            push @problems, $problem;
        } ## end if ( ( index ${$text}, $license ) < 0 )
        if ( scalar @problems and $verbose >= 2 ) {
            my $problem =
                  "=== license for $filename should be as follows:\n"
                . $license
                . ( q{=} x 30 );
            push @problems, $problem;
        } ## end if ( scalar @problems and $verbose >= 2 )
        return @problems;
    };
} ## end sub gen_license_problems_in_c_line

sub license_problems_in_tex_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as TeX file" or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text = slurp_top( $filename, 200 + length $tex_license );
    ${$text}
        =~ s{ \A [%] \s+ DO \s+ NOT \s+ EDIT \s+ DIRECTLY [^\n]* \n }{}xms;
    if ( ( index ${$text}, $tex_license ) < 0 ) {
        my $problem = "No license language in $filename (TeX style)\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( $text, \$tex_license )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_license ) < 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $tex_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_tex_file

# This was the license for the lyx documents
# For the Latex versions, I switched to CC-A_ND
sub tex_closed {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text = slurp_top( $filename, 400 + length $tex_closed_license );

    if ( ( index ${$text}, $tex_closed_license ) < 0 ) {
        my $problem = "No license language in $filename (TeX style)\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( $text, \$tex_closed_license )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_closed_license ) < 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $tex_closed_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub tex_closed

# Note!!!  This license is not Debian-compatible!!!
sub tex_cc_a_nd {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text = slurp( $filename );

# say "=== Looking for\n", $tex_cc_a_nd_license, "===";
# say "=== Looking in\n", ${$text}, "===";
# say STDERR index ${$text}, $tex_cc_a_nd_license ;

    if ( ( index ${$text}, $tex_cc_a_nd_license ) != 0 ) {
        my $problem = "No CC-A-ND language in $filename (TeX style)\n";
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_cc_a_nd_license ) != 0 )
    if ( ( index ${$text}, $cc_a_nd_thanks ) < 0 ) {
        my $problem = "No CC-A-ND LaTeX thanks in $filename\n";
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_cc_a_nd_license ) != 0 )
    if ( ( index ${$text}, $copyright_line_in_tex ) < 0 ) {
        my $problem = "No copyright line in $filename\n";
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_cc_a_nd_license ) != 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $tex_closed_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub tex_closed

sub cc_a_nd {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text     = slurp($filename);
    if ( ( index ${$text}, $cc_a_nd_body ) < 0 ) {
        my $problem = "No CC-A-ND language in $filename (TeX style)\n";
        push @problems, $problem;
    }
    if ( ( index ${$text}, $copyright_line ) < 0 ) {
        my $problem = "No copyright line in $filename\n";
        push @problems, $problem;
    }
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $cc_a_nd_body
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub cc_a_nd

sub copyright_page {
    my ( $filename, $verbose ) = @_;

    my @problems = ();
    my $text     = ${ slurp($filename) };
    if ( $text =~ m/ ^ Copyright \s [^J]* \s Jeffrey \s Kegler $ /xmsp ) {
        ## no critic (Variables::ProhibitPunctuationVars);
        my $pos = length ${^PREMATCH};
        $text = substr $text, $pos;
    }
    else {
        push @problems,
            "No copyright and license language in copyright page file: $filename\n";
    }
    if ( not scalar @problems and ( index $text, $license_in_tex ) < 0 ) {
        my $problem = "No copyright/license in $filename\n";
        if ($verbose) {
            $problem .= "Missing copyright/license:\n"
                . Text::Diff::diff( \$text, \$license_in_tex );
        }
        push @problems, $problem;
    } ## end if ( not scalar @problems and ( index $text, $license_in_tex...))
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== copyright/license in $filename should be as follows:\n"
            . $license_in_tex
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub copyright_page

sub license_problems_in_pod_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as POD file" or die "say failed: $ERRNO";
    }

    # Pod files are Perl files, and should also have the
    # license statement at the start of the file
    my $closure = gen_license_problems_in_perl_file();
    my @problems = $closure->( $filename, $verbose );

    my $text = ${ slurp($filename) };
    if ( $text =~ m/ ^ [=]head1 \s+ Copyright \s+ and \s+ License /xmsp ) {
        ## no critic (Variables::ProhibitPunctuationVars);
        my $pos = length ${^PREMATCH};
        $text = substr $text, $pos;
    }
    else {
        push @problems,
            qq{No "Copyright and License" header in pod file $filename\n};
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
            . ( q{=} x 30 )
            . "\n"
            ;
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_pod_file

# In "Text" files, just look for the full language.
# No need to comment it out.
sub gen_license_problems_in_text_file {
    my ($license) = @_;
    return sub {
        my ( $filename, $verbose ) = @_;
        if ($verbose) {
            say {*STDERR} "Checking $filename as text file"
                or die "say failed: $ERRNO";
        }
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
    }
} ## end sub gen_license_problems_in_text_file

# In "Text" files, just look for the full language.
# No need to comment it out.
sub license_problems_in_fdl_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as FDL file"
            or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text     = slurp_top($filename);
    if ( ( index ${$text}, $texi_copyright ) < 0 ) {
        my $problem = "Copyright missing in texinfo file $filename\n";
        if ($verbose) {
            $problem .= "\nMissing FDL license language:\n"
                . Text::Diff::diff( $text, \$fdl_license );
        }
        push @problems, $problem;
    }
    if ( ( index ${$text}, $fdl_license ) < 0 ) {
        my $problem = "FDL language missing in text file $filename\n";
        if ($verbose) {
            $problem .= "\nMissing FDL license language:\n"
                . Text::Diff::diff( $text, \$fdl_license );
        }
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $fdl_license ) < 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== FDL licensing section for $filename should be as follows:\n"
            . $pod_section
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_fdl_file

1;

# vim: expandtab shiftwidth=4:
