#!/usr/bin/perl
# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;
use strict;
use warnings;
use Carp;
use Fatal qw(open close);
use English qw( -no_match_vars );

use Module::Build;

use lib File::Spec->catdir('config');
use Marpa::HTML::Build_Me;
use Marpa::HTML::Config;

my %build_requires =
    map { ( $_, $Marpa::HTML::VERSION_FOR_CONFIG{$_} ) }
    qw( Test::More );
my %configure_requires =
    map { ( $_, $Marpa::HTML::VERSION_FOR_CONFIG{$_} ) }
    qw( Module::Build );
my %requires =
    map { ( $_, $Marpa::HTML::VERSION_FOR_CONFIG{$_} ) }
    qw( Scalar::Util List::Util Carp Data::Dumper HTML::Parser HTML::PullParser Marpa::PP );
my %recommends =
    map { ( $_, $Marpa::HTML::VERSION_FOR_CONFIG{$_} ) } qw( Marpa::XS );
$requires{perl} = 5.010;

my $build = Marpa::HTML::Build_Me->new(
    dist_name          => 'Marpa-HTML',
    module_name        => 'Marpa::HTML',
    dist_author        => 'Jeffrey Kegler',
    dist_abstract      => 'High-level HTML Parsing',
    recommends         => \%recommends,
    configure_requires => \%configure_requires,
    requires           => \%requires,
    build_requires     => \%build_requires,
    PL_files => {},    # workaround Module::Build bug
    script_files => [ 'script/html_fmt', 'script/html_score', ],
    pod_files    => {
        'lib/Marpa/HTML/Doc/Support.pod' => 'lib/Marpa/Support.pod',
        'lib/Marpa/HTML/Doc/HTML.pod'    => 'lib/Marpa/HTML.pod',
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/jeffreykegler/Marpa--HTML.git',
        },
        no_index => {
            directory => [qw( inc t author.t save )],
            namespace => [
                'Marpa::HTML::Internal', 'Marpa::HTML::Display::Internal',
                'Marpa::HTML::Test',
            ],
            package => [

                # not public, at least for now
                qw(Marpa::HTML::Offset Marpa::HTML::Test Marpa::HTML::Display ),

                # never intended to see the light of day
                qw(Marpa::HTML::Internal),

            ],
        },
    },
    meta_add => {
        distribution_type => 'module',
        provides => { 'Marpa::HTML' => { file => 'lib/Marpa/HTML.pm', }, },
    },
    create_readme      => 0,
    create_makefile_pl => 'small',
    test_files => [ map { glob $_ } qw(t/*.t t/*/*.t lib/Marpa/HTML/t/*.t) ],
);

$build->create_build_script;
