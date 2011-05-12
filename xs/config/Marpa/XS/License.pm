# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

package Marpa::XS::Internal::License;

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Fatal qw(open close read);
use File::Spec;
use Text::Diff ();

my $copyright_line = q{Copyright 2011 Jeffrey Kegler};
( my $copyright_line_in_tex = $copyright_line )
    =~ s/ ^ Copyright \s /Copyright \\copyright\\ /xms;

my $closed_license = "$copyright_line\n" . <<'END_OF_STRING';
This document is not part of the Marpa or Marpa::XS source.
Although it may be included with a Marpa distribution that
is under an open source license, this document is
not under that open source license.
Jeffrey Kegler retains full rights.
END_OF_STRING

my $license_body = <<'END_OF_STRING';
This file is part of Marpa::XS.  Marpa::XS is free software: you can
redistribute it and/or modify it under the terms of the GNU Lesser
General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

Marpa::XS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser
General Public License along with Marpa::XS.  If not, see
http://www.gnu.org/licenses/.
END_OF_STRING

my $license = "$copyright_line\n$license_body";

# License, redone as Tex input
my $license_in_tex =
    "$copyright_line_in_tex\n" . "\\bigskip\\noindent\n" . "$license_body";
$license_in_tex =~ s/^$/\\smallskip\\noindent/gxms;

my $license_file = $license . <<'END_OF_STRING';

In the Marpa::XS distribution, the GNU Lesser General Public License
version 3 should be in a file named "COPYING.LESSER" and the The GNU
General Public License version 3 should be in a file named "COPYING".
END_OF_STRING

sub hash_comment {
    my ( $text, $char ) = @_;
    $char //= q{#};
    $text =~ s/^/$char /gxms;
    $text =~ s/ [ ] $//gxms;
    return $text;
} ## end sub hash_comment

# Assumes $text ends in \n
sub c_comment {
    my ($text) = @_;
    $text =~ s/^/ * /gxms;
    $text =~ s/ [ ] $//gxms;
    return qq{/*\n$text */\n};
} ## end sub c_comment

my $c_license          = c_comment($license);
my $xs_hash_license       = hash_comment($license);
my $pp_hash_license       = $xs_hash_license;
$pp_hash_license =~ s/Marpa[:][:]XS/Marpa::PP/gxms;
my $tex_closed_license = hash_comment( $closed_license, q{%} );
my $tex_license        = hash_comment( $license, q{%} );
my $indented_license   = $license;
$indented_license =~ s/^/  /gxms;

my $pod_section = <<'END_OF_STRING';
=head1 COPYRIGHT AND LICENSE

=for Marpa::XS::Display
ignore: 1

END_OF_STRING

$pod_section .= "$indented_license\n";

# Next line is to fake out display checking logic
# Otherwise it will think the lines to come are part
# of a display

=cut

$pod_section .= <<'END_OF_STRING';
=for Marpa::XS::Display::End

END_OF_STRING

# Next line is to fake out display checking logic
# Otherwise it will think the lines to come are part
# of a display

=cut

my %original = (
    'libmarpa/dist/marpa_obs.c'  => [ 'libmarpa/orig/gnu/obstack.c', 1022 ],
    'libmarpa/dist/marpa_obs.h'  => [ 'libmarpa/orig/gnu/obstack.h', 1022 ],
);

my %GNU_file = map { ( $_, 1 ) } qw(
    libmarpa/dist/aclocal.m4
    libmarpa/dist/config.guess
    libmarpa/dist/config.sub
    libmarpa/dist/configure
    libmarpa/dist/depcomp
    libmarpa/dist/ltmain.sh
    libmarpa/dist/m4/libtool.m4
    libmarpa/dist/m4/ltoptions.m4
    libmarpa/dist/m4/ltsugar.m4
    libmarpa/dist/m4/ltversion.m4
    libmarpa/dist/m4/lt~obsolete.m4
    libmarpa/dist/missing
    libmarpa/dist/Makefile.in
);

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

sub check_GNU_copyright {
    my ( $filename, $verbose ) = @_;
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
    'LICENSE'  => \&license_problems_in_license_file,
    'META.json' => sub {;}
    ,    # not source, and not clear how to add license at top
    'META.yml' => sub {;}
    ,    # not source, and not clear how to add license at top
    'ppport.h'       => sub {;},    # copied from CPAN, just leave it alone
    'COPYING'        => sub {;},    # GNU license text, leave it alone
    'COPYING.LESSER' => sub {;},    # GNU license text, leave it alone
    'libmarpa/dev/cwebmac.tex' => sub {;}
    ,                               # originally from Cweb, leave it alone
    'lib/Marpa/XS/Test/capture-stderr' => sub {;},

    # Mostly from Andy Lester, leave alone
    'libmarpa/dev/copyright_page_license.w' => \&copyright_page,
    'Makefile.PL'                           => \&trivial,
    'ppshim/Marpa/PP.pm'                    => \&trivial,
    'html_pp_test.sh'                       => \&trivial,
    'html_xs_test.sh'                       => \&trivial,
    'libmarpa/dist/README'                  => \&trivial,
    'libmarpa/dev/README'                   => \&trivial,
    'README'                                => \&trivial,
    'TODO'                                  => \&trivial,
    'author.t/accept_tidy'                  => \&trivial,
    'author.t/critic1'                      => \&trivial,
    'author.t/perltidyrc'                   => \&trivial,
    'author.t/spelling_exceptions.list'     => \&trivial,
    'author.t/tidy1'                        => \&trivial,
    'inc/proof/README' => sub {;}, # discussion of licensing in that directory
    'inc/proof/ah_to_leo.lyx'    => \&tex_closed,
    'inc/proof/ah2002_notes.lyx' => \&tex_closed,
    'inc/proof/proof.lyx'        => \&tex_closed,
    'libmarpa/dist/install-sh'   => \&check_X_copyright,
    'libmarpa/dist/config.h.in' =>
        check_tag( 'Generated from configure.ac by autoheader', 250 ),
);

sub file_type {
    my ($filename) = @_;
    my $closure = $files_by_type{$filename};
    return $closure if defined $closure;
    my ( $volume, $dirpart, $filepart ) = File::Spec->splitpath($filename);
    my @dirs = grep {length} File::Spec->splitdir($dirpart);
    return \&license_problems_in_pp_perl_file
        if scalar @dirs > 1
            and $dirs[0] eq 'tool'
	    and $filepart =~ /[.]pm\z/xms;
    return \&license_problems_in_pp_perl_file
        if scalar @dirs > 1
            and $dirs[0] eq 'pperl'
	    and $filepart =~ /[.]pm\z/xms;
    return \&license_problems_in_pp_perl_file
        if scalar @dirs == 4
            and $dirs[0] eq 'lib'
            and $dirs[1] eq 'Marpa'
            and $dirs[2] eq 'XS'
            and $dirs[3] eq 'PP'
	    and $filepart =~ /[.]pm\z/xms;
    return \&license_problems_in_pp_perl_file
        if scalar @dirs == 3
            and $dirs[0] eq 't'
            and $dirs[1] eq 'shared'
            and $dirs[2] eq 'common'
	    and $filepart =~ /[.]t\z/xms;
    return \&trivial
        if scalar @dirs == 2
            and $dirs[0] eq 't'
            and $dirs[1] eq 'shared'
	    and $filepart =~ /[.]t\z/xms;
    return sub {;}
        if scalar @dirs >= 2
            and $dirs[0] eq 'libmarpa'
            and $dirs[1] eq 'orig';
    return sub {;}
        if scalar @dirs >= 1 and $dirs[0] eq 'html' ;
    return \&trivial if $filepart eq '.gitignore';
    return \&check_GNU_copyright
        if $GNU_file{$filename};
    return \&license_problems_in_xs_perl_file
        if $filepart =~ /[.] (t|pl|pm|PL) \z /xms;
    return \&license_problems_in_xs_perl_file
        if $filepart eq 'typemap';
    return \&license_problems_in_pod_file if $filepart =~ /[.]pod \z/xms;
    return \&license_problems_in_c_file
        if $filepart =~ /[.] (xs|c|h) \z /xms;
    return \&license_problems_in_tex_file
        if $filepart =~ /[.] (w) \z /xms;
    return \&license_problems_in_hash_file

        # return \&license_problems_in_text_file;
} ## end sub file_type

sub Marpa::XS::License::file_license_problems {
    my ( $filename, $verbose ) = @_;
    $verbose //= 1;
    my @problems = ();
    CHECK_VS_ORIGINAL: {
        my $original = $original{$filename};
        last CHECK_VS_ORIGINAL if not defined $original;
	my ($original_file, $length);
	if (ref $original eq 'ARRAY') {
	    ($original_file, $length) = @{$original};
	} else {
	   $original_file = $original;
	}
        if ( not -r $original_file ) {
            push @problems,
                qq{Original of "$filename" is not readable: "$original_file"\n};
            last CHECK_VS_ORIGINAL;
        }
        if ( not defined $length and not files_equal( $original_file, $filename ) ) {
            push @problems,
                "Difference between original ($original_file) and $filename\n";
            last CHECK_VS_ORIGINAL;
        }
        if ( not tops_equal( $original_file, $filename, $length ) ) {
            push @problems,
                "Difference between top of original ($original_file) and $filename\n";
            last CHECK_VS_ORIGINAL;
        }
        return @problems;
    } ## end CHECK_VS_ORIGINAL:
    return @problems if @problems;
    my $closure = file_type($filename);
    if ( defined $closure ) {
        push @problems, $closure->( $filename, $verbose );
        return @problems;
    }

    # type eq "text"
    push @problems, license_problems_in_text_file( $filename, $verbose );
    return @problems;
} ## end sub Marpa::XS::License::file_license_problems

## no critic (Subroutines::RequireArgUnpacking)
sub Marpa::XS::License::license_problems {
    return map { Marpa::XS::License::file_license_problems( $_, 0 ) } @_;
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

sub license_problems_in_hash_file {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text = slurp_top( $filename, length $xs_hash_license );
    if ( $xs_hash_license ne ${$text} ) {
        my $problem = "No license language in $filename (hash style)\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( $text, \$xs_hash_license )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( $xs_hash_license ne ${$text} )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $xs_hash_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_hash_file

sub license_problems_in_pp_perl_file {
    my ( $filename, $verbose ) = @_;
    return license_problems_in_perl_file( $filename, 'pp', $verbose);
}

sub license_problems_in_xs_perl_file {
    my ( $filename, $verbose ) = @_;
    return license_problems_in_perl_file( $filename, 'xs', $verbose);
}

sub license_problems_in_perl_file {
    my ( $filename, $type, $verbose ) = @_;
    my $hash_license = $type eq 'pp' ? $pp_hash_license : $xs_hash_license;
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

sub license_problems_in_c_file {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text = slurp_top( $filename, 200 + length $c_license );
    ${$text}
        =~ s{ \A [/][*] \s+ DO \s+ NOT \s+ EDIT \s+ DIRECTLY [^\n]* \n }{}xms;
    if ( ( index ${$text}, $c_license ) < 0 ) {
        my $problem = "No license language in $filename (C style)\n";
        if ($verbose) {
            $problem
                .= "=== Differences ===\n"
                . Text::Diff::diff( $text, \$c_license )
                . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $c_license ) < 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
              "=== license for $filename should be as follows:\n"
            . $c_license
            . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_c_file

sub license_problems_in_tex_file {
    my ( $filename, $verbose ) = @_;
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

sub tex_closed {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text = slurp_top( $filename, 400 + length $tex_closed_license );

    # ${$text} =~ s{ \A [%] \s+ DO \s+ NOT \s+ EDIT \s+ DIRECTLY [^\n]* \n }{}xms;
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

    # Pod files are Perl files, and should also have the
    # license statement at the start of the file
    my @problems = license_problems_in_xs_perl_file( $filename, $verbose );

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

