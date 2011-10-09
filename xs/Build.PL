#!/usr/bin/perl
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

use 5.010;
use strict;
use warnings;
use Fatal qw(open close mkdir chdir);
use File::Spec 0.82;
use IPC::Cmd;
use File::Path;

use Config;
use Module::Build;
use ExtUtils::PkgConfig;
use Glib::Install::Files;

use lib File::Spec->catdir('config');
use Marpa::XS::Build_Me;
use Marpa::XS::Config;

my $gperl_h_location = $Glib::Install::Files::CORE;

my %glib2_info              = ExtUtils::PkgConfig->find('glib-2.0');
my $glib_2_0_compiler_flags = $glib2_info{cflags};
my $glib_2_0_linker_flags   = $glib2_info{libs};

my %build_requires =
    map { ( $_, $Marpa::XS::VERSION_FOR_CONFIG{$_} ) }
    qw( ExtUtils::CBuilder Test::More );
my %configure_requires =
    map { ( $_, $Marpa::XS::VERSION_FOR_CONFIG{$_} ) }
    qw( ExtUtils::PkgConfig Module::Build Glib );
my %requires =
    map { ( $_, $Marpa::XS::VERSION_FOR_CONFIG{$_} ) }
    qw( Scalar::Util List::Util Task::Weaken Carp Data::Dumper ExtUtils::PkgConfig Glib );
my %recommends =
    map { ( $_, $Marpa::XS::VERSION_FOR_CONFIG{$_} ) } qw( PPI Test::Weaken );

my %pod_files = ();
$pod_files{'pod/Marpa_XS.pod'} = 'lib/Marpa/XS.pod';

my @no_index_namespace_inclusive = (

    # not for now, at least
    qw(Marpa::Perl Marpa::Test Marpa::Display ),

    # never intended to see the light of day
    qw( Marpa::XS::Internal Marpa::PP ),

);

my @files_to_cleanup = (
    'lib/Marpa/XS/Version.pm', 'pperl/Marpa/Perl/Version.pm',
    'lib/Marpa/XS/Installed.pm', 'pperl/Marpa/Perl/Installed.pm',
    'lib/Marpa/XS.o',          'libmarpa/main/build',
);

my $build = Marpa::XS::Build_Me->new(
    add_to_cleanup     => \@files_to_cleanup,
    module_name          => 'Marpa::XS',
    dist_author        => 'Jeffrey Kegler',
    dist_abstract      => 'XS Version of Marpa',
    recommends         => \%recommends,
    requires           => \%requires,
    configure_requires => \%configure_requires,
    build_requires     => \%build_requires,
    dynamic_config     => 1,
    extra_compiler_flags =>
        "$glib_2_0_compiler_flags -I$gperl_h_location -Ilibmarpa/dist",
    extra_linker_flags => "$glib_2_0_linker_flags",
    PL_files           => {},
    xs_files           => { 'xs/XS.xs' => 'lib/Marpa/XS.xs' },
    meta_merge         => {
        resources =>
            { repository => 'git://github.com/jeffreykegler/Marpa-XS.git', },
        no_index => {
            directory => [qw( pperl config inc tool t html devlib libmarpa author.t )],
            namespace => [
                'Marpa::XS::Recognizer', 'Marpa::XS::Grammar',
                @no_index_namespace_inclusive
            ],
            package => [@no_index_namespace_inclusive],
        }
    },
    pod_files          => \%pod_files,
    create_readme      => 0,
    create_makefile_pl => 'small',
    test_files         => [ map { glob $_ } qw(t/*.t t/shared/*.t) ],
);

$build->create_build_script;
