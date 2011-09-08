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

our $MINIMUM_MARPA_VERSION = '0.100';

my $class = Module::Build->subclass(
    class => 'Module::Build::Custom',
    code  => <<'SUBCLASS' );

    sub ACTION_dist {
        my $self = shift;
        open( my $manifest_fh, q{<}, 'MANIFEST' )
            or die("Cannot open MANIFEST: $!");

        my @problems;
        FILE: while ( my $file = <$manifest_fh> ) {
            chomp $file;
            next FILE if $file =~ /^\s*[#]/xms;
            next FILE if $file !~ /[.](pl|pm|t)$/xmsi;
            my $file_text = do {
                local $/ = undef;
                if ( not -r $file ) {
                    Carp::carp("Cannot open $file: $!");
                    next FILE;
                }
                open( my $fh, q{<}, $file );
                <$fh>;
            };
            if ( $file_text =~ /^ \s+ use \s+ Smart[:][:]Comments /xms ) {
                push @problems, "Smart::Comments enabled in $file";
            }
        } ## end while ( my $file = <$manifest_fh> )

        Carp::carp(join "\n", @problems, "Fatal Error\n") if @problems;
        $self->SUPER::ACTION_dist;
    } ## end sub ACTION_dist

SUBCLASS

my $build = Marpa::HTML::Build_Me->new(
    dist_name     => 'Marpa-HTML',
    module_name   => 'Marpa::HTML',
    dist_author   => 'Jeffrey Kegler',
    dist_abstract => 'High-level HTML Parsing',
    recommends      => {
	'Marpa::XS' => '0.010000',
    },
    configure_requires => { 'Module::Build' => 0.38 },
    requires      => {
        'Scalar::Util'     => 0,
        'HTML::Parser'     => '3.64',
        'HTML::PullParser' => '3.57',
	'Marpa::PP' => '0.008000',
        perl               => 5.010,
    },
    build_requires => {
        'Test::More' => 0.94,
    },
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
        provides          => {
            'Marpa::HTML' => {
                file    => 'lib/Marpa/HTML.pm',
            },
        },
    },
    create_readme      => 0,
    create_makefile_pl => 'small',
    test_files => [ map { glob $_ } qw(t/*.t t/*/*.t lib/Marpa/HTML/t/*.t) ],
);

$build->create_build_script;
