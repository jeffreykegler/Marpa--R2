#!/usr/bin/perl
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

use 5.010001;
use strict;
use warnings;
use Fatal qw(open close mkdir chdir);
use File::Spec 0.82;
use IPC::Cmd;
use English qw( -no_match_vars );

use Config;
use Module::Build;

use lib File::Spec->catdir('inc');
use Marpa::R2::Build_Me;
use Marpa::R2::Config;

my @packages_for_perl_autoconf = qw( Config::AutoConf );
my @always_required            = qw(
    Carp
    Cwd
    Data::Dumper
    DynaLoader
    English
    Exporter
    ExtUtils::CBuilder
    ExtUtils::MakeMaker
    ExtUtils::Manifest
    ExtUtils::Mkbootstrap
    Fatal
    File::Copy
    File::Spec
    IPC::Cmd
    List::Util
    PPI
    Scalar::Util
    Test::More
    Time::Piece
    XSLoader
);

my %configure_requires =
    map { ( $_, $Marpa::R2::VERSION_FOR_CONFIG{$_} ) }
    qw( CPAN::Meta::Converter Module::Build ),
    @always_required,
    @packages_for_perl_autoconf;
$configure_requires{perl} = '5.010001';

my %requires =
    map { ( $_, $Marpa::R2::VERSION_FOR_CONFIG{$_} ) }
    qw( HTML::Entities HTML::Parser ),
    @always_required;
$requires{perl} = '5.010001';

my %recommends =
    map { ( $_, $Marpa::R2::VERSION_FOR_CONFIG{$_} ) }
    ( @packages_for_perl_autoconf, qw( PPI ) );

my %pod_files = ();
{
    local $RS = undef;
    open my $manifest_fh, q{<}, 'MANIFEST';
    my @pod_files = split /\n/xms, $manifest_fh->getline();
    close $manifest_fh;
    LINE: for my $pod_file (@pod_files) {
        $pod_file =~ s/ \s* [#] .* \z //xms;
        next LINE if not $pod_file =~ / [.] pod \z /xms;
        next LINE if $pod_file =~ m{ libmarpa [/] dev [/] old_pod [/] }xms;
        if ( ( my $destfile = $pod_file )
            =~ s{ \A pod [/] }{lib/Marpa/R2/}xms )
        {
            $pod_files{$pod_file} = $destfile;
            next LINE;
        } ## end if ( ( my $destfile = $pod_file ) =~ ...)
        if ( ( my $destfile = $pod_file )
            =~ s{ \A html [/] pod [/] }{lib/Marpa/R2/}xms )
        {
            $pod_files{$pod_file} = $destfile;
            next LINE;
        } ## end if ( ( my $destfile = $pod_file ) =~ ...)
        die "Failed to rename POD file: $pod_file";
    } ## end LINE: for my $pod_file (@pod_files)
}
$pod_files{'pod/Marpa_R2.pod'}  = 'lib/Marpa/R2.pod';
$pod_files{'html/pod/HTML.pod'} = 'lib/Marpa/R2/HTML.pod';

my %pm_files = ();
File::Find::find(
    sub {
        return if not m/[.]pm \z/xms;
        $pm_files{$File::Find::name} = $File::Find::name;
    },
    'lib'
);
File::Find::find(
    sub {
        return if not m/[.]pm \z/xms;
        my ( $vol, $dirs, $file ) = File::Spec->splitpath($File::Find::name);
        my @dirs      = File::Spec->splitdir($dirs);
        my $dest_dirs = File::Spec->catdir( @dirs[ 1 .. $#dirs ] );
        my $dest_name = File::Spec->catpath( $vol, $dest_dirs, $file );
        $pm_files{$File::Find::name} = $dest_name;
    },
    'html/lib'
);
for my $pm_file (qw(Version.pm Installed.pm)) {
    my $pm_fullname = 'lib/Marpa/R2/' . $pm_file;
    $pm_files{$pm_fullname} = $pm_fullname;
}

my @no_index_namespace_inclusive = qw(
    Marpa::R2::HTML
    Marpa::R2::Value
    Marpa::R2::Perl
    Marpa::R2::Test
    Marpa::R2::Display
    Marpa::R2::Inner
    Marpa::R2::Internal
    Marpa::R2::MetaAST
    Marpa::R2::MetaG
    Marpa::R2::Stuifzand
);

my @files_to_cleanup = (
    'lib/Marpa/R2/Version.pm',   'pperl/Marpa/R2/Perl/Version.pm',
    'lib/Marpa/R2/Installed.pm', 'pperl/Marpa/R2/Perl/Installed.pm',
    'lib/Marpa/R2.o',            'libmarpa_build'
);

my $build = Marpa::R2::Build_Me->new(
    add_to_cleanup     => \@files_to_cleanup,
    module_name        => 'Marpa::R2',
    dist_author        => 'Jeffrey Kegler',
    dist_abstract      => 'Release 2 of Marpa',
    recommends         => \%recommends,
    requires           => \%requires,
    configure_requires => \%configure_requires,
    dynamic_config     => 1,
    PL_files           => {},
    pm_files           => \%pm_files,
    script_files       => [
        'html/script/marpa_r2_html_fmt',
        'html/script/marpa_r2_html_score',
    ],
    xs_files => { 'xs/R2.xs' => 'lib/Marpa/R2.xs' },
    meta_add => {
        no_index => {
            directory => [
                qw( pperl tool libmarpa author.t
                    html/etc html/sandbox html/script html/t
                    )
            ],
            namespace => [
                'Marpa::R2::Recognizer', 'Marpa::R2::Grammar',
                @no_index_namespace_inclusive
            ],
            package =>
                [ @no_index_namespace_inclusive, 'Marpa::R2::Thin::Trace' ],
        }
    },
    meta_merge => {
        resources => {
            homepage => 'http://savage.net.au/Marpa.html',
            repository => 'git://github.com/jeffreykegler/Marpa--R2.git',
            IRC        => 'irc://irc.freenode.net/#marpa',
            x_IRC      => { 
                irc => 'irc://irc.freenode.net/#marpa', 
                web => 'http://webchat.freenode.net/?channels=%23marpa&uio=d4'
            },
        },
    },
    pod_files     => \%pod_files,
    license       => 'lgpl3',
    create_readme => 0,

    test_files => [ map { glob $_ } qw(t/*.t html/t/*.t) ],
    getoptions => { Dev => {}, 'Marpa-debug' => {} },
);

$build->create_build_script;

# vim: expandtab shiftwidth=4:
