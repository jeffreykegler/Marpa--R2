# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;

package Marpa::HTML::Build_Me;

use strict;
use warnings;

@Marpa::HTML::Build_Me::ISA = ('Module::Build');

use Config;
use Module::Build;
use English qw( -no_match_vars );
use Time::Piece;

use Marpa::HTML::Config;

my $preamble = <<'END_OF_STRING';
# This file is written by Build.PL
# It is not intended to be modified directly

END_OF_STRING

sub write_file {
    my ($self, $contents, @name_components) = @_;
    my $base_dir     = $self->base_dir();
    my $file_name = pop @name_components;
    my $dir_name = File::Spec->catdir( $base_dir, @name_components );
    -d $dir_name or mkdir $dir_name;
    my $path_name = File::Spec->catfile( $dir_name, $file_name );
    open my $fh, q{>}, $path_name;
    print {$fh} $contents;
    close $fh;
}

sub html_version_contents {
    my ( $self, $package ) = @_;
    my @use_packages =
    qw( );
    my $text = $preamble;
    $text .= "package $package;\n";
    $text .= q{use vars qw($TIMESTAMP)} . qq{;\n};
    $text .= q{$TIMESTAMP='} . localtime()->datetime . qq{';\n};
    for my $package (@use_packages) {
        my $version = $Marpa::HTML::VERSION_FOR_CONFIG{$package};
        die "No version defined for $package" if not defined $version;
        $text .= "use $package $version ();\n";
    }
    $text .= "1;\n";
    return $text;
} ## end sub version_contents

sub ACTION_manifest {
    die qq{Automatic generation of the MANIFEST file is disabled\n}
	. qq{The Marpa MANIFEST file is handwritten\n};
}

sub ACTION_licensecheck {
    my $license_pm = 'config/Marpa/HTML/License.pm';
    require $license_pm or die "Cannot load $license_pm";
    my @manifest = do {
	open my $fh, q{<}, 'MANIFEST';
	local $RS = undef;
	my $text = <$fh>;
	$text =~ s/[#] [^\n]* $//gxms;
	grep { defined and not / \A \s* \z /xms } split '\n', $text;
    };
    my @license_problems =
	Marpa::HTML::License::license_problems(@manifest);
    if (@license_problems) {
	print STDERR join q{}, @license_problems;
	die qq{Fatal error due to license language issues};
    }
}

sub ACTION_distcheck {
    my $self = shift;
    $self->ACTION_licensecheck();
    $self->SUPER::ACTION_distcheck;
}

sub ACTION_dist {
    my $self = shift;
    my $changes = do {
	open my $fh, q{<}, 'Changes';
	local $RS = undef;
	<$fh>;
    };
    my $marpa_xs_version = $self->dist_version();
    die qq{"$marpa_xs_version" not in Changes file}
	if 0 > index $changes, $marpa_xs_version;
    $self->SUPER::ACTION_dist;
} ## end sub ACTION_dist

sub ACTION_code {
    my $self = shift;
    say STDERR "Writing version file";
    my $version_pm = html_version_contents( $self, 'Marpa::HTML' );
    $self->write_file($version_pm, qw(lib Marpa HTML Version.pm) );
    $self->SUPER::ACTION_code;
}

1;
