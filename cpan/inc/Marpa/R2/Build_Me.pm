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

package Marpa::R2::Build_Me;

use 5.010001;
use strict;
use warnings;

@Marpa::R2::Build_Me::ISA = ('Module::Build');

use Config;
use ExtUtils::Manifest;
use File::Copy;
use Cwd;
use IPC::Cmd;
use Module::Build;
use Fatal qw(open close chdir chmod utime);
use English qw( -no_match_vars );
use Time::Piece;

use Marpa::R2::Config;

BEGIN {
    if ($Marpa::R2::USE_PERL_AUTOCONF) {
        say "Using Config::AutoConf";
        for my $package (qw( ExtUtils::MakeMaker Config::AutoConf ))
        {
            if ( not eval "require $package" ) {
                die "$package is not installed: $EVAL_ERROR\n",
                    "    Module $package is required for Windows and for USE_PERL_AUTOCONF mode\n";
            }
            my $version = $Marpa::R2::VERSION_FOR_CONFIG{$package};
            if ( not $package->VERSION($version) ) {
                die "Version $version of $package is not installed\n",
                    "    Version $version of $package is required for Windows and for USE_PERL_AUTOCONF mode\n";
            }
        } ## end for my $package (...)
    } ## end if ($Marpa::R2::USE_PERL_AUTOCONF)
} ## end BEGIN

my $preamble = <<'END_OF_STRING';
# This file is written by Build.PL
# It is not intended to be modified directly

END_OF_STRING

sub installed_contents {
    my ( $self, $package ) = @_;
    my $marpa_version = $self->dist_version();
    my $text             = $preamble;
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($VERSION $STRING_VERSION)} . qq{;\n};
    $text .= q{$VERSION = '} . $marpa_version . qq{';\n};
    $text .= q{$STRING_VERSION = $VERSION} . qq{;\n};
    $text .= q{$VERSION = eval $VERSION} . qq{;\n};
##use critic

    $text .= "1;\n";
    return $text;
} ## end sub installed_contents

sub xs_version_contents {
    my ( $self, $package ) = @_;
    my @use_packages =
        qw( Scalar::Util List::Util Carp Data::Dumper );
    my $text = $preamble;
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($TIMESTAMP)} . qq{;\n};
    $text .= q{$TIMESTAMP='} . localtime()->datetime . qq{';\n};
##use critic

    for my $package (@use_packages) {
        my $version = $Marpa::R2::VERSION_FOR_CONFIG{$package};
        die "No version defined for $package" if not defined $version;
        $text .= "use $package $version ();\n";
    }
    $text .= "1;\n";
    return $text;
} ## end sub xs_version_contents

sub perl_version_contents {
    my ( $self, $package, ) = @_;
    my @use_packages     = qw( Scalar::Util Carp Data::Dumper PPI Marpa::R2 );
    my $text             = $preamble;
    my $marpa_version = $self->dist_version();
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($TIMESTAMP)} . qq{;\n};
    $text .= q{$TIMESTAMP='} . localtime()->datetime . qq{';\n};
##use critic

    for my $package (@use_packages) {
        my $version =
              $package eq 'Marpa::R2'
            ? $marpa_version
            : $Marpa::R2::VERSION_FOR_CONFIG{$package};
        die "No version defined for $package" if not defined $version;
        $text .= "use $package $version ();\n";
    } ## end for my $package (@use_packages)
    $text .= "1;\n";
    return $text;
} ## end sub perl_version_contents

sub file_write {
    my ( $self, $contents, @name_components ) = @_;
    my $base_dir  = $self->base_dir();
    my $file_name = pop @name_components;
    my $dir_name  = File::Spec->catdir( $base_dir, @name_components );
    -d $dir_name or mkdir $dir_name;
    my $path_name = File::Spec->catfile( $dir_name, $file_name );
    open my $fh, q{>}, $path_name;
    print {$fh} $contents or die "print failed: $ERRNO";
    close $fh;
    return 1;
} ## end sub file_write

sub file_slurp {
    my ( $self, @name_components ) = @_;
    my $path_name = File::Spec->catfile( @name_components );
    open my $fh, q{<}, $path_name;
    my $contents = do { local $RS = undef; <$fh> };
    close $fh;
    return $contents;
}

# This is based on _infer_xs_spec() from Module::Build.  It was
# copied here in order to be customized
sub marpa_infer_xs_spec {
    my $self = shift;
    my $file = shift;

    my $cf = $self->{config};

    my %spec;

    my ( $v, $d, $f ) = File::Spec->splitpath($file);
    my @d = File::Spec->splitdir($d);
    ( my $file_base = $f ) =~ s/\. [^.]+ \z//xmsi;

    $spec{base_name} = $file_base;

    $spec{src_dir} = File::Spec->catpath( $v, $d, q{} );

    # the module name
    shift @d while @d && ( $d[0] eq 'lib' || $d[0] eq q{} );
    pop @d while @d && $d[-1] eq q{};
    $spec{module_name} = join q{::}, @d, $file_base;

    $spec{archdir} =
        File::Spec->catdir( $self->blib, 'arch', 'auto', @d, $file_base );


    require DynaLoader;
    my $modfname = defined &DynaLoader::mod2fname
                 ? DynaLoader::mod2fname([@d, $file_base])
                 : $file_base;

    $spec{bs_file} = File::Spec->catfile( $spec{archdir}, "${modfname}.bs" );

    $spec{lib_file} =
        File::Spec->catfile( $spec{archdir},
        "${modfname}." . $cf->get('dlext') );

    $spec{c_file} = File::Spec->catfile( $spec{src_dir}, "${file_base}.c" );

    $spec{obj_file} =
        File::Spec->catfile( $spec{src_dir},
        "${file_base}" . $cf->get('obj_ext') );

    return \%spec;
} ## end sub marpa_infer_xs_spec

sub gcc_is_at_least {
    my ($required) = @_;
    state $gcc_version = $Config{gccversion};
    return if not $gcc_version;
    my @actual = ($gcc_version =~ m/ \A (\d+) [.] (\d+) [.] (\d+) \z /xms);
    return if @actual != 3;
    my @required = ($required =~ m/ \A (\d+) [.] (\d+) [.] (\d+) \z /xms);
    die if scalar @required != 3;
    my $cmp = $actual[0] <=> $required[0] ||
     $actual[1] <=> $required[1]  ||
     $actual[2] <=> $required[2] ;
    return $cmp >= 0 ? 1 : 0;
}

# The following initially copied from Module::Build, to be customized for
# Marpa.
sub process_xs {
    my ( $self, $xs_file ) = @_;

    my $development_mode = $self->args('Dev');

    my $spec = marpa_infer_xs_spec( $self, $xs_file );

    my $xs_dir = File::Spec->catdir(qw(xs));
    my $gp_xsh = File::Spec->catfile( $xs_dir, 'general_pattern.xsh' );
    if ($development_mode) {
        my $gp_generate_pl = File::Spec->catfile( $xs_dir, 'gp_generate.pl' );
        if ( not $self->up_to_date( [$gp_generate_pl], $gp_xsh ) ) {
            if (not IPC::Cmd::run(
                    command => [ $EXECUTABLE_NAME, $gp_generate_pl, $gp_xsh ],
                    verbose => 1
                )
                )
            {
                die "Could not generate $gp_xsh";
            } ## end if ( not IPC::Cmd::run( command => [ $EXECUTABLE_NAME...]))
        } ## end if ( not $self->up_to_date( [$gp_generate_pl], $gp_xsh...))
    } ## end if ($development_mode)

    my $dest_gp_xsh =
        File::Spec->catfile( $spec->{src_dir}, 'general_pattern.xsh' );
    $self->copy_if_modified( from => $gp_xsh, to => $dest_gp_xsh, );

    # .xs -> .c
    $self->add_to_cleanup( $spec->{c_file} );

    my @libmarpa_build_dir = File::Spec->splitdir( $self->base_dir );
    push @libmarpa_build_dir, 'libmarpa_build' ;
    my $libmarpa_build_dir = File::Spec->catdir(@libmarpa_build_dir);

    my @xs_dependencies = ( 'typemap', 'Build', $xs_file, $dest_gp_xsh );
    push @xs_dependencies,
        map { File::Spec->catfile( @libmarpa_build_dir, $_ ) }
        qw(config.h marpa.h marpa_codes.c );

    if ( not $self->up_to_date( \@xs_dependencies, $spec->{c_file} ) ) {
        $self->verbose() and say "compiling $xs_file";
        $self->compile_xs( $xs_file, outfile => $spec->{c_file} );
    }

    # .c -> .o
    my $v = $self->dist_version;
    $self->verbose() and say "compiling $spec->{c_file}";
    my @new_ccflags = ( '-I', '"' . $libmarpa_build_dir . '"', '-I', 'xs' );

    if ( $self->config('ccname') eq 'gcc' ) {
        ## -W instead of -Wextra is case the GCC is pre 3.0.0
        ## -Winline omitted because too noisy
        push @new_ccflags, qw( -Wall -W
            -Wpointer-arith -Wstrict-prototypes -Wwrite-strings
            -Wmissing-declarations );
        # -ansi undefs 'inline' on Android, which breaks
        # the build since it's used by bionic's headers.
        push @new_ccflags, '-ansi' if $^O ne 'android';
        push @new_ccflags, '-Wdeclaration-after-statement' if gcc_is_at_least('3.4.6');
    } ## end if ( $self->config('cc') eq 'gcc' )
    if ( defined $self->args('XS-debug') ) {
        say 'XS-debug flag is on';
        if ( $self->config('ccname') eq 'gcc' ) {
            push @new_ccflags, qw( -Wall -ansi -pedantic -Wundef -Wendif-labels );
        } ## end if ( $self->config('cc') eq 'gcc' )
        elsif ( $self->config('ccname') eq 'cl' ){
            ## gcc's -Wundef is msvc's C4668 that is on with -Wall
            ## gcc's -ansi -pedantic is msvc's /Za, but windows.h can't be compiled with it
            ## msvc's equivalent for gcc's -Wendif-labels can't be found :)
            push @new_ccflags, qw( -W4 -Wp64 );
        } ## end elsif ( $self->config('ccname') eq 'cl' ){
    }
    my $ccflags = $self->config('ccflags');
    $self->config( ccflags => ( $ccflags . q{ } . join q{ }, @new_ccflags ) );
    $self->compile_c( $spec->{c_file},
        defines => { VERSION => qq{"$v"}, XS_VERSION => qq{"$v"} } );

    # archdir
    # Legacy mkpath(), for compatibility with Perl 5.10.0
    File::Path::mkpath( $spec->{archdir}, 0, ( oct 777 ) )
        if not -d $spec->{archdir};

    my @extra_linker_flags = ();
    my $libmarpa_build_directory =
        File::Spec->catdir( $self->base_dir(), 'libmarpa_build' );

    my $switched_to_file =
        File::Spec->catdir( $libmarpa_build_directory, 'SWITCHED_TO' );
    my $libmarpa_mode_file =
        File::Spec->catdir( $self->base_dir(), 'engine', 'cf', 'LIBMARPA_MODE' );
    if ( defined $self->args('libmarpa-external') ) {
        my $libmarpa_external_flags = $self->args('libmarpa-external');
        push @extra_linker_flags, split q{ }, $libmarpa_external_flags;
        $self->log_info("Using external Libmarpa\n");
        if ( -e $switched_to_file ) {
            $self->log_info("Deleting $switched_to_file\n");
            File::Path::rmtree( $switched_to_file, 0, 0 );
            die "Couldn't remove '$switched_to_file': $!\n"
                if -e $switched_to_file;
        } ## end if ( -e $switched_to_file )
        $switched_to_file = undef;

        # Is there a Libmarpa mode file?
        # If not create it.
        if ( not -e $libmarpa_mode_file ) {
            open my $fh, q{>}, $libmarpa_mode_file;
            print {$fh}
                "DO NOT EDIT -- automatically generated by $PROGRAM_NAME\n",
                "Switched to external Libmarpa: "
                . localtime()->datetime . qq{\n}
                or die "print failed: $ERRNO";
            close $fh;
        }
    } ## end if ( defined $self->args('libmarpa-external') )
    else {
        # Is there a switched to file?
        # If not create it.
        $self->log_info("Using built-in Libmarpa\n");

        if ( -e $libmarpa_mode_file ) {
            $self->log_info("Deleting $libmarpa_mode_file\n");
            File::Path::rmtree( $libmarpa_mode_file, 0, 0 );
            die "Couldn't remove '$libmarpa_mode_file': $!\n"
                if -e $libmarpa_mode_file;
        } ## end if ( -e $libmarpa_mode_file )

        if ( not -e $switched_to_file ) {
            open my $fh, q{>}, $switched_to_file;
            print {$fh}
                "DO NOT EDIT -- automatically generated by $PROGRAM_NAME\n",
                "Last switch to built-in Libmarpa: "
                . localtime()->datetime . qq{\n}
                or die "print failed: $ERRNO";
            close $fh;
        } ## end if ( not -e $switched_to_file )

        my $libmarpa_archive;
        FIND_LIBRARY: {
            if ($Marpa::R2::USE_PERL_AUTOCONF) {
                my $libmarpa_libs_dir =
                    File::Spec->catdir( $libmarpa_build_directory, 'blib',
                    'arch', 'auto', 'libmarpa' );
                $libmarpa_archive = File::Spec->catfile( $libmarpa_libs_dir,
                    "libmarpa$Config{lib_ext}" );
                last FIND_LIBRARY;
            } ## end if ($Marpa::R2::USE_PERL_AUTOCONF)
            my $libmarpa_libs_dir =
                File::Spec->catdir( $libmarpa_build_directory, '.libs' );
            $libmarpa_archive =
                File::Spec->catfile( $libmarpa_libs_dir, 'libmarpa.a' );
        } ## end FIND_LIBRARY:
        push @{ $self->{properties}->{objects} }, $libmarpa_archive;
    } ## end else [ if ( defined $self->args('libmarpa-external') ) ]

    # .xs -> .bs
    $self->add_to_cleanup( $spec->{bs_file} );
    unless ( $self->up_to_date( $xs_file, $spec->{bs_file} ) ) {
        require ExtUtils::Mkbootstrap;
        $self->log_info(
            "ExtUtils::Mkbootstrap::Mkbootstrap('$spec->{bs_file}')\n");
        ExtUtils::Mkbootstrap::Mkbootstrap( $spec->{bs_file} )
            ;    # Original had $BSLOADLIBS - what's that?
        { my $fh = IO::File->new(">> $spec->{bs_file}") }    # create
        my $time = time;
        utime $time, $time, $spec->{bs_file};                # touch
    } ## end unless ( $self->up_to_date( $xs_file, $spec->{bs_file} ) )

    # .o -> .(a|bundle)
    return marpa_link_c( $self, $spec, \@extra_linker_flags, $switched_to_file );
} ## end sub process_xs

# The following was initially copied from Module::Build, and has
# been customized for Marpa.
sub marpa_link_c {
    my ( $self, $spec, $extra_linker_flags, $switched_to_file ) = @_;
    my $p = $self->{properties};                             # For convenience

    $self->add_to_cleanup( $spec->{lib_file} );

    my $objects = $p->{objects} || [];

    my @dependencies = ($spec->{obj_file});
    push @dependencies, @{$objects};
    push @dependencies, $switched_to_file if defined $switched_to_file;
    # Always relink if libmarpa-external is specified
    if (
    not  defined $self->args('libmarpa-external') and
    $self->up_to_date( \@dependencies,
            $spec->{lib_file}
        )
        )
    {
        return $spec->{lib_file};
    } ## end if ( $self->up_to_date( [ $spec->{obj_file}, @{$objects...}]))

    my $module_name = $spec->{module_name} || $self->module_name;

    my @extra_linker_flags = @{$p->{extra_linker_flags}};
    push @extra_linker_flags, @{$extra_linker_flags};
    $self->cbuilder->link(
        module_name        => $module_name,
        objects            => [ $spec->{obj_file}, @{$objects} ],
        lib_file           => $spec->{lib_file},
        extra_linker_flags => \@extra_linker_flags
    );

    return $spec->{lib_file};
} ## end sub marpa_link_c

sub do_libmarpa {
    my $self     = shift;
    my $cwd      = $self->cwd();
    my $base_dir = $self->base_dir();

    my $dist_dir = File::Spec->catdir( $base_dir, 'engine/read_only' );
    my $build_dir = File::Spec->catdir( $base_dir, 'libmarpa_build');

    my $build_stamp_file = File::Spec->catfile( $build_dir, 'stamp-h1' );
    my $build_makefile = File::Spec->catfile( $build_dir, 'Makefile' );
    my $dist_stamp_file = File::Spec->catfile( $dist_dir, 'stamp-h1' );

    # If build directory exists and contains a stamp file more recent than the
    # tar file, we are done.
    return if  $self->up_to_date( [$dist_stamp_file], [$build_stamp_file, $build_makefile] ) ;

    # Otherwise, rebuild from scratch
    File::Path::rmtree($build_dir);

    if ( $self->verbose() ) {
                say join q{ }, "Copying files from $dist_dir to $build_dir"
                or die "print failed: $ERRNO";
    }

     ## Make sure build dir structure exists, even if empty
     my $m4_dir = File::Spec->catdir( $build_dir, 'm4' );

     # Legacy mkpath(), for compatibility with Perl 5.10.0
     File::Path::mkpath($m4_dir);

    my @copy_work_list = ();
    {
        my $from_m4_dir = File::Spec->catdir( $dist_dir, 'm4' );
        my $to_m4_dir = File::Spec->catdir( $build_dir, 'm4' );
        chdir $from_m4_dir;
        for my $file (<*>) {
          my $from_file = File::Spec->catfile($from_m4_dir, $file);
          my $to_file = File::Spec->catfile($to_m4_dir, $file);
          push @copy_work_list, [$from_file, $to_file];
        }
        chdir $cwd;
    }
    {
        chdir $dist_dir;
        FILE: for my $file (<*>) {
          next FILE if -d $file;
          next FILE if $file eq 'stamp-h1';
          my $from_file = File::Spec->catfile($dist_dir, $file);
          my $to_file = File::Spec->catfile($build_dir, $file);
          push @copy_work_list, [$from_file, $to_file];
        }
        chdir $cwd;
    }
    for my $file (@copy_work_list) {
        File::Copy::copy(@{$file});
    }

    chdir $build_dir;

    if (! $Marpa::R2::USE_PERL_AUTOCONF) {

            if ( $self->verbose() ) {
                print "Configuring libmarpa\n"
                    or die "print failed: $ERRNO";
            }

            my $shell = $Config{sh};

        ##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
            $shell or die q{No Bourne shell available says $Config{sh}};
        ##use critic
    }

    local $ENV{$_} = $ENV{$_} for qw(TMPDIR PATH_SEPARATOR CONFIG_SHELL);

    if ( $^O eq 'android' ) {
        # TMPDIR must be set due to a bug in /system/bin/sh
        # which breaks shell heredocs; this is for both
        # configure and libtool
        $ENV{TMPDIR}         ||= File::Spec->tmpdir();
        # 'configure' hardcodes /bin/sh in several spots;
        # setting CONFIG_SHELL gets all but one, the test
        # for PATH_SEPARATOR.
        $ENV{CONFIG_SHELL}   ||= $Config{sh};
        $ENV{PATH_SEPARATOR} ||= $Config{path_sep};
    }

    my $original_cflags = $ENV{CFLAGS};
    local $ENV{CFLAGS};
    $ENV{CFLAGS} = $original_cflags if defined $original_cflags;

    # We need PIC, but do not want the overhead of building the shared library
    my @configure_command_args = ();
    push @configure_command_args, qw(--with-pic --disable-shared --disable-maintainer-mode);

    my @debug_flags = ();
    if ( defined $self->args('Marpa-debug') ) {
        if ( defined $ENV{LIBMARPA_CFLAGS} ) {
            $ENV{CFLAGS} = $ENV{LIBMARPA_CFLAGS};
        }
        push @debug_flags, '-DMARPA_DEBUG=1';
        push @debug_flags, '-fno-inline', '-Wno-inline' if ($self->config('cc') eq 'gcc');
        push @configure_command_args,
            'MARPA_DEBUG_FLAG=' . ( join q{ }, @debug_flags );
    } ## end if ( defined $self->args('Marpa-debug') )

    # As of this writing, only used by Config::AutoConf logic,
    # but that may change.
    my $libmarpa_version = $self->file_slurp('LIB_VERSION');
    chomp $libmarpa_version;
    my @libmarpa_version = split /[.]/xms, $libmarpa_version;

    if ($Marpa::R2::USE_PERL_AUTOCONF) {

        #
        ## C.f. http://fr.slideshare.net/hashashin/building-c-and-c-libraries-with-perl
        #
        my @c = qw/marpa_ami.c marpa_avl.c marpa.c
            marpa_codes.c marpa_obs.c marpa_tavl.c/;
        if (! -r 'config.h') {
            #
            ## Because Config::AutoConf can only generate #define/#undef
            ## stubs, we write our config.h with these stubs, our config.h
            ## will then include a generated config_from_autoconf.h
            #
            if ( $self->verbose() ) {
                say join q{ }, "Doing config.h"
                    or die "print failed: $ERRNO";
            }
            open my $config_fh, '>>', 'config.h' || die "Cannot open config.h, $!\n";
            my $ac = Config::AutoConf->new();
            my $inline_ok = 0;
            {
                $ac->msg_checking('inline');
                my $program = $ac->lang_build_program("static inline int testinline() {return 1;}\n", 'testinline');
                $inline_ok = $ac->compile_if_else($program);
                $ac->msg_result($inline_ok ? 'yes' : 'no');
            }
            my $inline = '';
            if (! $inline_ok) {
                foreach (qw/__inline__ __inline/) {
                    my $candidate = $_;
                    $ac->msg_checking($candidate);
                    my $program = $ac->lang_build_program("static $candidate int testinline() {return 1;}\n", 'testinline');
                    my $rc = $ac->compile_if_else($program);
                    $ac->msg_result($rc ? 'yes' : 'no');
                    if ($rc) {
                        $inline = $candidate;
                        last;
                    }
                }
            }
            if ($inline) {
                print {$config_fh} <<INLINEHOOK;
#ifndef __CONFIG_WITH_STUBS_H
#ifndef __cplusplus
#define inline $inline
#endif
#include "config_from_autoconf.h"
#endif /* __CONFIG_WITH_STUBS_H */
INLINEHOOK
            } else {
                print {$config_fh} <<INLINEHOOK;
#ifndef __CONFIG_WITH_STUBS_H
#ifndef __cplusplus
/* #undef inline */
#endif
#include "config_from_autoconf.h"
#endif /* __CONFIG_WITH_STUBS_H */
INLINEHOOK
            }

            # Config::Autoconf mistakes 0 for undef, so these must be done explicitly
            say {$config_fh} join q{ }, '#define MARPA_LIB_MAJOR_VERSION', $libmarpa_version[0];
            say {$config_fh} join q{ }, '#define MARPA_LIB_MINOR_VERSION', $libmarpa_version[1];
            say {$config_fh} join q{ }, '#define MARPA_LIB_MICRO_VERSION', $libmarpa_version[2];

            close($config_fh);
            $ac = Config::AutoConf->new();
            my $sizeof_int = $ac->check_sizeof_type('int');
            if ($sizeof_int < 4) {
                die "Marpa requires that int be at least 32 bits -- on this system that is not the case";
            }

            $ac->check_stdc_headers;
            $ac->check_default_headers();

            # This check was to prepare for Perl's 64-bit pseudo-UTF8 characters inside the SLIF.
            # It needs to be rethought.
            #
            # if (!$ac->check_type('unsigned long long int')) {
                # die "Marpa requires that unsigned long long int is supported by your compiler";
            # }

            $ac->define_var('PACKAGE', "\"libmarpa\"");
            $ac->define_var('PACKAGE_BUGREPORT', "\"http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marpa\"");
            $ac->define_var('PACKAGE_NAME', "\"libmarpa\"");
            $ac->define_var('PACKAGE_STRING', "\"libmarpa $libmarpa_version[0].$libmarpa_version[1].$libmarpa_version[2]\"");
            $ac->define_var('PACKAGE_TARNAME', "\"libmarpa\"");
            $ac->define_var('PACKAGE_URL', "\"\"");
            $ac->define_var('PACKAGE_VERSION', "\"$libmarpa_version\"");
            $ac->define_var('PACKAGE_STRING', "\"$libmarpa_version\"");
            $ac->write_config_h('config_from_autoconf.h');
        }

        my @o = map {s/\.c$/$Config{obj_ext}/; $_} @c;
        if (! -r 'Makefile.PL') {
            open my $makefile_pl_fh, '>', 'Makefile.PL';
            my $CCFLAGS = @debug_flags ? "$Config{ccflags} @debug_flags" : '';
            my $linktype = 'static';
            my $blib = 'blib';
            my $name = 'libmarpa';
            print {$makefile_pl_fh} "
use ExtUtils::MakeMaker;
WriteMakefile(VERSION        => \"$libmarpa_version\",
              XS_VERSION     => \"$libmarpa_version\",
              NAME           => \"$name\",
              OBJECT         => '@o',
              CCFLAGS        => '$CCFLAGS',
              INST_LIB       => \"./$blib/lib\",
              INST_ARCHLIB   => \"./$blib/arch\",
              INST_SCRIPT    => \"./$blib/script\",
              INST_BIN       => \"./$blib/bin\",
              LINKTYPE       => $linktype);
";
            close $makefile_pl_fh;
            die 'Making Makefile: perl Failure'
                if not IPC::Cmd::run( command => [$^X, 'Makefile.PL'], verbose => 1 );
        }
    } else {
            my $shell = $Config{sh};
            my $configure_script = 'configure';
            if ( $self->verbose() ) {
                say join q{ }, "Running command:", $shell, $configure_script,
                    @configure_command_args
                    or die "print failed: $ERRNO";
            }
            if (not IPC::Cmd::run(
                    command => [ $shell, $configure_script, @configure_command_args ],
                    verbose => 1
                )
                )
            {
                say {*STDERR} "Failed: $configure_script"
                    or die "say failed: $ERRNO";
                say {*STDERR} "Current directory: $build_dir"
                    or die "say failed: $ERRNO";
                die 'Cannot run libmarpa configure';
            } ## end if ( not IPC::Cmd::run( command => [ $shell, $configure_script...]))

    }
    if ( $self->verbose() ) {
        print "Making libmarpa: Start\n" or die "Cannot print: $ERRNO";
    }
    die 'Making libmarpa: make Failure'
        if not IPC::Cmd::run( command => [$Config{make}], verbose => 1 );

    ## stamp-h1 is a by-product of the GNU autotools, but for Config::AutoConf,
    ## I need to dummy one up, so do it for both
    {
        open my $time_stamp_fh, q{>}, 'stamp-h1';
        say {$time_stamp_fh} scalar localtime();
        close $time_stamp_fh;
    }

    chdir $cwd;

    return 1;

} ## end sub do_libmarpa

sub ACTION_manifest {
    die qq{Automatic generation of the MANIFEST file is disabled\n}
        . qq{The Marpa MANIFEST file is handwritten\n};
}

sub make_writeable {
    my $file = shift;
    die qq{"$file" in "}, getcwd(), qq{" does not exist} if ! -e $file;
    my $current_mode =  (stat $file)[2];
    die qq{mode not defined for $file} if not defined $current_mode;
    chmod $current_mode | (oct 200), $file;
}

sub ACTION_licensecheck {
    my $self = shift;

    require inc::Marpa::R2::License;

    my $manifest = [keys %{ExtUtils::Manifest::maniread()}];
    my @license_problems =
        Marpa::R2::License::license_problems( $manifest, $self->verbose() );
    if (@license_problems) {
        print {*STDERR} join q{}, @license_problems
            or die "Cannot print: $ERRNO";
        die 'Fatal error due to license language issues';
    }
} ## end sub ACTION_licensecheck

sub ACTION_metacheck {
    my $self = shift;

    # does not check CPAN::Meta
    # version -- assumes updated with Module::Build
    # this should only be run when making distributions
    # not on install, so we don't have to be too paranoid
    require CPAN::Meta;

    my $marpa_version = $self->dist_version();
    my $meta = CPAN::Meta->load_file($self->metafile());
    my $provides = $meta->{provides};
    my @metacheck_problems = ();
    PROVIDED: for my $provided_name (keys %{$provides}) {
      my $provided_version = $provides->{$provided_name}->{version};
      if (not defined $provided_version) {
          push @metacheck_problems, "No version for $provided_name\n";
          next PROVIDED;
      }
      if ($provided_version ne $marpa_version) {
          push @metacheck_problems,
          "Version of $provided_name is $provided_version, but Marpa version is $marpa_version\n";
      }
    }
    if (@metacheck_problems) {
        print {*STDERR} join q{}, @metacheck_problems
            or die "Cannot print: $ERRNO";
        die 'Fatal error due to META file issues';
    }
}

sub ACTION_distcheck {
    my $self = shift;
    $self->ACTION_licensecheck();
    $self->ACTION_metacheck();
    return $self->SUPER::ACTION_distcheck;
} ## end sub ACTION_distcheck

sub ACTION_distmeta {
    my $self         = shift;
    my $return_value = $self->SUPER::ACTION_distmeta;

    # does not check CPAN::Meta
    # version -- assumes updated with Module::Build
    # this should only be run when making distributions
    # not on install, so we don't have to be too paranoid
    require CPAN::Meta;

    my $meta   = CPAN::Meta->load_file( $self->metafile() );
    my @delete = ('DynaLoader');
    for my $provided ( keys %{ $meta->{provides} } ) {
        push @delete, $provided if $provided =~ m/\AMarpa::R2::Inner::/xms;
        push @delete, $provided if $provided =~ m/\AMarpa::R2::Internal::/xms;
        push @delete, $provided if $provided =~ m/\AMarpa::R2::HTML::Internal::/xms;
        push @delete, $provided if $provided =~ m/::Internal\z/xms;
    }
    if (@delete) {
        for my $deletion (@delete) {
            delete $meta->{provides}->{$deletion};
        }
        if (defined $meta->{dynamic_config}) {
          # Make sure this stays numeric
          $meta->{dynamic_config} = $meta->{dynamic_config}+0;
        }
        $meta->save( 'META.yml', { version => '1.4' } );
        $meta->save('META.json');
        $self->log_info("Revised META.yml and META.json\n");
    } ## end if (@delete)

    return $return_value;
} ## end sub ACTION_distmeta

sub ACTION_dist {
    my $self = shift;
    open my $fh, q{<}, 'Changes';
    my $changes = do {
        local $RS = undef;
        <$fh>;
    };
    close $fh;
    my $marpa_version = $self->dist_version();
    die qq{"$marpa_version" not in Changes file}
        if 0 > index $changes, $marpa_version;
    return $self->SUPER::ACTION_dist;
} ## end sub ACTION_dist

sub write_installed_pm {
    my ( $self, @components ) = @_;
    my $filename           = 'Installed';
    my @package_components = @components[ 1 .. $#components ];
    my $contents = installed_contents( $self, join q{::}, @package_components,
        $filename );
    $filename .= q{.pm};
    return $self->file_write( $contents, @components, $filename );
} ## end sub write_installed_pm

sub ACTION_code {
    my $self               = shift;
    my @r2_perl_components = qw(pperl Marpa R2 Perl);
    my @r2_components      = qw(lib Marpa R2);
    my $config_pm_filename = File::Spec->catfile(qw(inc Marpa R2 Config.pm ));
    my $build_filename     = 'Build';
    my @derived_files      = (
        File::Spec->catfile( @r2_components,      'Version.pm' ),
        File::Spec->catfile( @r2_components,      'Installed.pm' ),
        File::Spec->catfile( @r2_perl_components, 'Version.pm' ),
        File::Spec->catfile( @r2_perl_components, 'Installed.pm' ),
    );
    if (not $self->up_to_date(
            [ $config_pm_filename, $build_filename ],
            \@derived_files
        )
        )
    {
        say {*STDERR} 'Writing version files' or die "say failed: $ERRNO";
        write_installed_pm( $self, qw(lib Marpa R2 ) );
        write_installed_pm( $self, qw(pperl Marpa R2 Perl ) );
        my $perl_version_pm =
            perl_version_contents( $self, 'Marpa::R2::Perl' );
        my $version_pm = xs_version_contents( $self, 'Marpa::R2' );
        $self->file_write( $version_pm, qw(lib Marpa R2 Version.pm) );
        $self->file_write( $perl_version_pm,
            qw(pperl Marpa R2 Perl Version.pm) );
    } ## end if ( not $self->up_to_date( [ $config_pm_filename, ...]))

    # If it's a shared library, we don't build it here.
    if ( not defined $self->args('libmarpa-external') ) {

        # If the mode file exists, any switch to the internal Libmarpa
        # must be made explicitly
        if ( not defined $self->args('libmarpa-internal') ) {
            my $libmarpa_mode_file =
                File::Spec->catdir( $self->base_dir(), 'engine', 'cf',
                'LIBMARPA_MODE' );
            die
                "Libmarpa is external, but you did not explicity specify that -- you need to\n",
                '  If you want to go back to the built-in Libmarpa, ',
                qq{use Build's "--libmarpa-internal=on" flag\n}
                if -e $libmarpa_mode_file;
        } ## end if ( not defined $self->args('libmarpa-internal') )
        $self->do_libmarpa();
    } ## end if ( not defined $self->args('libmarpa-external') )

    return $self->SUPER::ACTION_code;
} ## end sub ACTION_code

sub ACTION_clean {
    my $self = shift;

    my $curdir = File::Spec->rel2abs( File::Spec->curdir() );
    if ( $self->verbose ) {
        print "Cleaning libmarpa\n" or die "print failed: $ERRNO";
    }

    return $self->SUPER::ACTION_clean;
} ## end sub ACTION_clean

sub ACTION_test {
    my $self = shift;
    local $ENV{PERL_DL_NONLAZY} = 1;
    return $self->SUPER::ACTION_test;
}

sub ACTION_install {
    my $self = shift;
    die qq{"libmarpa-shared" not supported for "install" target\n},
        qq{  Marpa::R2 supports testing of shared libraries, but is not an installer for them\n}
        if defined $self->args('libmarpa-shared');
    return $self->SUPER::ACTION_install;
}

1;

# vim: expandtab shiftwidth=4:
