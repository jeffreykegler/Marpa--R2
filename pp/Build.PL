#!/usr/bin/perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::PP.  Marpa::PP is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::PP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::PP.  If not, see
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

my $marpa_pp_version = '0.005_001';

use lib File::Spec->catdir('config');
use Marpa::PP::Build_Me;
use Marpa::PP::Config;

my %build_requires =
    map { ( $_, $Marpa::PP::VERSION_FOR_CONFIG{$_} ) }
    qw( ExtUtils::CBuilder Test::More );
my %configure_requires =
    map { ( $_, $Marpa::PP::VERSION_FOR_CONFIG{$_} ) }
    qw( Module::Build );
my %requires =
    map { ( $_, $Marpa::PP::VERSION_FOR_CONFIG{$_} ) }
    qw( Scalar::Util List::Util Task::Weaken Carp Data::Dumper Storable );
my %recommends =
    map { ( $_, $Marpa::PP::VERSION_FOR_CONFIG{$_} ) } qw( PPI Test::Weaken );

my %pod_files = map { ( "pod/$_" => "lib/Marpa/PP/$_" ) } qw(
    Advanced/Algorithm.pod
    Advanced/Bibliography.pod
    Advanced/Implementation.pod
    Advanced/Models.pod
    Grammar.pod
    Parse_Terms.pod
    Recognizer.pod
    Semantics.pod
    Support.pod
    Tracing.pod
);
$pod_files{'pod/Marpa_PP.pod'} = 'lib/Marpa/PP.pod';

my @no_index_namespace_inclusive = (

    # not for now, at least
    qw(Marpa::PP::Perl Marpa::PP::Offset Marpa::PP::Test Marpa::PP::Display ),

    # never intended to see the light of day
    qw( Marpa::PP::Internal),

);

my @files_to_cleanup = (
    'lib/Marpa/PP/Version.pm', 'lib/Marpa/PP/Perl/Version.pm',
    'libmarpa/main/build',
);

my $build = Marpa::PP::Build_Me->new(
    add_to_cleanup     => \@files_to_cleanup,
    dist_name          => 'Marpa-PP',
    dist_author        => 'Jeffrey Kegler',
    dist_version       => $marpa_pp_version,
    dist_abstract      => 'PP Version of Marpa (Experimental)',
    recommends         => \%recommends,
    requires           => \%requires,
    configure_requires => \%configure_requires,
    build_requires     => \%build_requires,
    dynamic_config     => 1,
    PL_files           => {},
    meta_merge         => {
        resources =>
            { repository => 'git://github.com/jeffreykegler/Marpa-PP.git', },
        no_index => {
            directory => [qw( config inc t author.t )],
            namespace => [
                'Marpa::PP::Recognizer', 'Marpa::PP::Grammar',
                @no_index_namespace_inclusive
            ],
            package => [@no_index_namespace_inclusive],
        }
    },
    meta_add => {
        distribution_type => 'module',
        provides          => {
            'Marpa::PP' => {
                file    => 'lib/Marpa/PP.pm',
                version => $marpa_pp_version,
            },
        },
    },
    pod_files          => \%pod_files,
    create_readme      => 0,
    create_makefile_pl => 'small',
    test_files         => [ map { glob $_ } qw(t/*.t t/shared/*.t) ],
);

$build->create_build_script;
