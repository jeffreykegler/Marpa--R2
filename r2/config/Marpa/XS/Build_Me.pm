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

package Marpa::XS::Build_Me;

use 5.010;
use strict;
use warnings;

@Marpa::XS::Build_Me::ISA = ('Module::Build');

use Config;
use File::Copy;
use IPC::Cmd;
use Module::Build;
use Fatal qw(open close chdir chmod utime);
use English qw( -no_match_vars );
use Time::Piece;

use Marpa::XS::Config;

my $preamble = <<'END_OF_STRING';
# This file is written by Build.PL
# It is not intended to be modified directly

END_OF_STRING

sub installed_contents {
    my ( $self, $package ) = @_;
    my $marpa_xs_version = $self->dist_version();
    my $text             = $preamble;
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($VERSION $STRING_VERSION)} . qq{;\n};
    $text .= q{$VERSION = '} . $marpa_xs_version . qq{';\n};
    $text .= q{$STRING_VERSION = $VERSION} . qq{;\n};
    $text .= q{$VERSION = eval $VERSION} . qq{;\n};
##use critic

    $text .= "1;\n";
    return $text;
} ## end sub installed_contents

sub xs_version_contents {
    my ( $self, $package ) = @_;
    my @use_packages =
        qw( Scalar::Util List::Util Carp Data::Dumper ExtUtils::PkgConfig Glib );
    my $text = $preamble;
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($TIMESTAMP)} . qq{;\n};
    $text .= q{$TIMESTAMP='} . localtime()->datetime . qq{';\n};
##use critic

    for my $package (@use_packages) {
        my $version = $Marpa::XS::VERSION_FOR_CONFIG{$package};
        die "No version defined for $package" if not defined $version;
        $text .= "use $package $version ();\n";
    }
    $text .= "1;\n";
    return $text;
} ## end sub xs_version_contents

sub perl_version_contents {
    my ( $self, $package, ) = @_;
    my @use_packages     = qw( Scalar::Util Carp Data::Dumper PPI Marpa::XS );
    my $text             = $preamble;
    my $marpa_xs_version = $self->dist_version();
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($TIMESTAMP)} . qq{;\n};
    $text .= q{$TIMESTAMP='} . localtime()->datetime . qq{';\n};
##use critic

    for my $package (@use_packages) {
        my $version =
              $package eq 'Marpa::XS'
            ? $marpa_xs_version
            : $Marpa::XS::VERSION_FOR_CONFIG{$package};
        die "No version defined for $package" if not defined $version;
        $text .= "use $package $version ();\n";
    } ## end for my $package (@use_packages)
    $text .= "1;\n";
    return $text;
} ## end sub perl_version_contents

sub write_file {
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
} ## end sub write_file

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

    $spec{bs_file} = File::Spec->catfile( $spec{archdir}, "${file_base}.bs" );

    $spec{lib_file} =
        File::Spec->catfile( $spec{archdir},
        "${file_base}." . $cf->get('dlext') );

    $spec{c_file} = File::Spec->catfile( $spec{src_dir}, "${file_base}.c" );

    $spec{obj_file} =
        File::Spec->catfile( $spec{src_dir},
        "${file_base}" . $cf->get('obj_ext') );

    return \%spec;
} ## end sub marpa_infer_xs_spec

# The following initially copied from Module::Build, to be customized for
# Marpa.
sub process_xs {
    my ( $self, $file ) = @_;

    my $spec = marpa_infer_xs_spec( $self, $file );

    # File name, minus the suffix
    ( my $file_base = $file ) =~ s/\. [^.]+ \z//xms;

    # .xs -> .c
    $self->add_to_cleanup( $spec->{c_file} );

    unless (
        $self->up_to_date( [ 'typemap', 'Build', $file ], $spec->{c_file} ) )
    {
        $self->compile_xs( $file, outfile => $spec->{c_file} );
    }

    # .c -> .o
    my $v = $self->dist_version;
    $self->compile_c( $spec->{c_file},
        defines => { VERSION => qq{"$v"}, XS_VERSION => qq{"$v"} } );

    # archdir
    File::Path::mkpath( $spec->{archdir}, 0, ( oct 777 ) )
        if not -d $spec->{archdir};

    # finalize libmarpa.a
    my $libmarpa_libs_dir =
        File::Spec->catdir( $self->base_dir(), qw(libmarpa build .libs) );
    my $unfinished_libmarpa_a =
        File::Spec->catfile( $libmarpa_libs_dir, 'libmarpa.a' );
    my $xs_dir = File::Spec->catdir( $self->base_dir(), 'xs' );
    my $final_libmarpa_a = File::Spec->catfile( $xs_dir, 'libmarpa.a' );
    if ( not $self->up_to_date( $unfinished_libmarpa_a, $final_libmarpa_a ) )
    {
        File::Copy::syscopy( $unfinished_libmarpa_a, $final_libmarpa_a );
        my $ranlib = $Config{ranlib};
        if ( $ranlib ne q{:} ) {
            if (not IPC::Cmd::run(
                    command =>
                        [ ( split /\s+/xms, $ranlib ), $final_libmarpa_a ],
                    verbose => 1
                )
                )
            {
                say {*STDERR} "Failed: $ranlib $final_libmarpa_a"
                    or die "say failed: $ERRNO";
                die 'Cannot run libmarpa configure';
            } ## end if ( not IPC::Cmd::run( command => [ ( split /\s+/xms...)]))
        } ## end if ( $ranlib ne q{:} )
    } ## end if ( not $self->up_to_date( $unfinished_libmarpa_a, ...))

    push @{ $self->{properties}->{objects} }, $final_libmarpa_a;

    # .xs -> .bs
    $self->add_to_cleanup( $spec->{bs_file} );
    unless ( $self->up_to_date( $file, $spec->{bs_file} ) ) {
        require ExtUtils::Mkbootstrap;
        $self->log_info(
            "ExtUtils::Mkbootstrap::Mkbootstrap('$spec->{bs_file}')\n");
        ExtUtils::Mkbootstrap::Mkbootstrap( $spec->{bs_file} )
            ;    # Original had $BSLOADLIBS - what's that?
        { my $fh = IO::File->new(">> $spec->{bs_file}") }    # create
        my $time = time;
        utime $time, $time, $spec->{bs_file};                # touch
    } ## end unless ( $self->up_to_date( $file, $spec->{bs_file} ) )

    # .o -> .(a|bundle)
    return marpa_link_c( $self, $spec );
} ## end sub process_xs

# The following was initially copied from Module::Build, and have
# been customized for Marpa.
sub marpa_link_c {
    my ( $self, $spec ) = @_;
    my $p = $self->{properties};                             # For convenience

    $self->add_to_cleanup( $spec->{lib_file} );

    my $objects = $p->{objects} || [];

    return $spec->{lib_file}
        if $self->up_to_date( [ $spec->{obj_file}, @{$objects} ],
        $spec->{lib_file} );

    say {*STDERR} $spec->{lib_file}, ' Out of date wrt ', join q{, },
        $spec->{obj_file}, @{$objects}
        or die "say failed: $ERRNO";

    my $module_name = $spec->{module_name} || $self->module_name;

    $self->cbuilder->link(
        module_name        => $module_name,
        objects            => [ $spec->{obj_file}, @{$objects} ],
        lib_file           => $spec->{lib_file},
        extra_linker_flags => $p->{extra_linker_flags}
    );

    return $spec->{lib_file};
} ## end sub marpa_link_c

sub do_libmarpa {
    my $self         = shift;
    my $cwd          = $self->cwd();
    my $base_dir     = $self->base_dir();
    my $libmarpa_dir = File::Spec->catdir( $base_dir, qw(libmarpa build) );
    -d $libmarpa_dir or mkdir $libmarpa_dir;
    chdir $libmarpa_dir;
    my $updir = File::Spec->updir();
    my $configure_script = File::Spec->catfile( $updir, 'dist', 'configure' );
    if ( not -r 'stamp-h1' ) {

        if ( $self->verbose() ) {
            print "Configuring libmarpa\n"
                or die "print failed: $ERRNO";
        }
        my $shell = $Config{sh};

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
        $shell or die q{No Bourne shell available says $Config{sh}};
##use critic

        if (not IPC::Cmd::run(
                command => [ $shell, $configure_script ],
                verbose => 1
            )
            )
        {
            say {*STDERR} "Failed: $configure_script"
                or die "say failed: $ERRNO";
            say {*STDERR} "Current directory: $libmarpa_dir"
                or die "say failed: $ERRNO";
            die 'Cannot run libmarpa configure';
        } ## end if ( not IPC::Cmd::run( command => [ $shell, ...]))
    } ## end if ( not -r 'stamp-h1' )
    else {
        if ( $self->verbose() ) {
            print "Found configuration for libmarpa\n"
                or die "print failed: $ERRNO";
        }
    } ## end else [ if ( not -r 'stamp-h1' ) ]
    if ( $self->verbose() ) {
        print "Making libmarpa: Start\n" or die "Cannot print: $ERRNO";
    }
    {

        # Make sure "configure" is writeable
        my $perm = ( stat $configure_script )[2] & ( oct 7777 );
        $perm |= oct 200;
        chmod $perm, $configure_script;
    }
    die 'Making libmarpa: Failure'
        if not IPC::Cmd::run( command => ['make'], verbose => 1 );
    chdir $cwd;
    return 1;

} ## end sub do_libmarpa

sub ACTION_manifest {
    die qq{Automatic generation of the MANIFEST file is disabled\n}
        . qq{The Marpa MANIFEST file is handwritten\n};
}

sub ACTION_licensecheck {
    my $self = shift;

## no critic(Modules::RequireBarewordIncludes)
    require 'config/Marpa/XS/License.pm';
## use critic

    my @manifest = do {
        open my $fh, q{<}, 'MANIFEST';
        local $RS = undef;
        my $text = <$fh>;
        close $fh;
        $text =~ s/[#] [^\n]* $//gxms;
        grep { defined and not / \A \s* \z /xms } split /\n/xms, $text;
    };
    my @license_problems =
        Marpa::XS::License::license_problems( \@manifest, $self->verbose() );
    if (@license_problems) {
        print {*STDERR} join q{}, @license_problems
            or die "Cannot print: $ERRNO";
        die 'Fatal error due to license language issues';
    }
} ## end sub ACTION_licensecheck

sub ACTION_distcheck {
    my $self = shift;
    $self->ACTION_licensecheck();
    return $self->SUPER::ACTION_distcheck;
}

sub ACTION_dist {
    my $self = shift;
    open my $fh, q{<}, 'Changes';
    my $changes = do {
        local $RS = undef;
        <$fh>;
    };
    close $fh;
    my $marpa_xs_version = $self->dist_version();
    die qq{"$marpa_xs_version" not in Changes file}
        if 0 > index $changes, $marpa_xs_version;
    return $self->SUPER::ACTION_dist;
} ## end sub ACTION_dist

sub write_installed_pm {
    my ( $self, @components ) = @_;
    my $filename           = 'Installed';
    my @package_components = @components[ 1 .. $#components ];
    my $contents = installed_contents( $self, join q{::}, @package_components,
        $filename );
    $filename .= q{.pm};
    return $self->write_file( $contents, @components, $filename );
} ## end sub write_installed_pm

sub ACTION_code {
    my $self = shift;
    say {*STDERR} 'Writing version files'
        or die "say failed: $ERRNO";
    write_installed_pm( $self, qw(lib Marpa XS ) );
    write_installed_pm( $self, qw(pperl Marpa Perl ) );
    my $perl_version_pm = perl_version_contents( $self, 'Marpa::Perl' );
    my $version_pm = xs_version_contents( $self, 'Marpa::XS' );
    $self->write_file( $version_pm,      qw(lib Marpa XS Version.pm) );
    $self->write_file( $perl_version_pm, qw(pperl Marpa Perl Version.pm) );
    $self->do_libmarpa();
    return $self->SUPER::ACTION_code;
} ## end sub ACTION_code

sub ACTION_clean {
    my $self = shift;

    my $curdir = File::Spec->rel2abs( File::Spec->curdir() );
    if ( $self->verbose ) {
        print "Cleaning libmarpa\n" or die "print failed: $ERRNO";
    }
    my $libmarpa_dir = File::Spec->catdir( $curdir, qw(libmarpa build) );
    File::Path::rmtree( $libmarpa_dir, { keep_root => 1 } );

    return $self->SUPER::ACTION_clean;
} ## end sub ACTION_clean

sub ACTION_test {
    my $self = shift;
    local $ENV{PERL_DL_NONLAZY} = 1;
    return $self->SUPER::ACTION_test;
}

1;
