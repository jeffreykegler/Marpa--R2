# Copyright 2012 Jeffrey Kegler
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

package Marpa::R2;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION @ISA $DEBUG);
$VERSION        = '2.021_002';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic
$DEBUG = 0;

use Carp;
use English qw( -no_match_vars );

use Marpa::R2::Version;

$Marpa::R2::USING_XS = 1;
$Marpa::R2::USING_PP = 0;

eval {
    require XSLoader;
    XSLoader::load( 'Marpa::R2', $Marpa::R2::STRING_VERSION );
    1;
} or eval {
    require DynaLoader;
## no critic(ClassHierarchies::ProhibitExplicitISA)
    push @ISA, 'DynaLoader';
    Dynaloader::bootstrap Marpa::R2 $Marpa::R2::STRING_VERSION;
    1;
} or Carp::croak("Could not load XS version of Marpa::R2: $EVAL_ERROR");

@Marpa::R2::CARP_NOT = ();
for my $start (qw(Marpa::R2)) {
    for my $middle ( q{}, '::Internal' ) {
        for my $end ( q{}, qw(::Recognizer ::Callback ::Grammar ::Value) ) {
            push @Marpa::R2::CARP_NOT, $start . $middle . $end;
        }
    }
} ## end for my $start (qw(Marpa::R2))
PACKAGE: for my $package (@Marpa::R2::CARP_NOT) {
    no strict 'refs';
    next PACKAGE if $package eq 'Marpa';
    *{ $package . q{::CARP_NOT} } = \@Marpa::R2::CARP_NOT;
}

if ( not $ENV{'MARPA_AUTHOR_TEST'} ) {
    $Marpa::R2::DEBUG = 0;
}
else {
    Marpa::R2::Thin::debug_level_set(1);
    $Marpa::R2::DEBUG = 1;
}

sub version_ok {
    my ($sub_module_version) = @_;
    return 'not defined' if not defined $sub_module_version;
    return "$sub_module_version does not match Marpa::R2::VERSION " . $VERSION
        if $sub_module_version != $VERSION;
    return;
} ## end sub version_ok

# Set up the error values
my @error_names = Marpa::R2::Thin::error_names();
for ( my $error = 0; $error <= $#error_names; ) {
    my $current_error = $error;
    (my $name = $error_names[$error] ) =~ s/\A MARPA_ERR_//xms;
    no strict 'refs';
    *{ "Marpa::R2::Error::$name" } = \$current_error;
    # This shuts up the "used only once" warning
    my $dummy = eval q{$} . 'Marpa::R2::Error::' . $name;
    $error++;
}

my $version_result;
require Marpa::R2::Internal;
( $version_result = version_ok($Marpa::R2::Internal::VERSION) )
    and die 'Marpa::R2::Internal::VERSION ', $version_result;

require Marpa::R2::Grammar;
( $version_result = version_ok($Marpa::R2::Grammar::VERSION) )
    and die 'Marpa::R2::Grammar::VERSION ', $version_result;

require Marpa::R2::Recognizer;
( $version_result = version_ok($Marpa::R2::Recognizer::VERSION) )
    and die 'Marpa::R2::Recognizer::VERSION ', $version_result;

require Marpa::R2::Value;
( $version_result = version_ok($Marpa::R2::Value::VERSION) )
    and die 'Marpa::R2::Value::VERSION ', $version_result;

1;
