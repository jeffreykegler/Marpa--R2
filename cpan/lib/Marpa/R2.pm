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

package Marpa::R2;

use 5.010001;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION @ISA $DEBUG);
$VERSION        = '11.003_000';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic
$DEBUG = 0;

use Carp;
use English qw( -no_match_vars );
use XSLoader;

use Marpa::R2::Version;

$Marpa::R2::USING_XS = 1;
$Marpa::R2::USING_PP = 0;
$Marpa::R2::LIBMARPA_FILE = '[built-in]';

LOAD_EXPLICIT_LIBRARY: {
    last LOAD_EXPLICIT_LIBRARY if  not $ENV{'MARPA_AUTHOR_TEST'};
    my $file = $ENV{MARPA_LIBRARY};
    last LOAD_EXPLICIT_LIBRARY if  not $file;

    require DynaLoader;
    package DynaLoader;
    my $bs = $file;
    $bs =~ s/(\.\w+)?(;\d*)?$/\.bs/; # look for .bs 'beside' the library

    if (-s $bs) { # only read file if it's not empty
#       print STDERR "BS: $bs ($^O, $dlsrc)\n" if $dl_debug;
        eval { do $bs; };
        warn "$bs: $@\n" if $@;
    }

    my $bootname = "marpa_g_new";
    @DynaLoader::dl_require_symbols = ($bootname);

    my $libref = dl_load_file($file, 0) or do { 
        require Carp;
        Carp::croak("Can't load libmarpa library: '$file'" . dl_error());
    };
    push(@DynaLoader::dl_librefs,$libref);  # record loaded object

    my @unresolved = dl_undef_symbols();
    if (@unresolved) {
        require Carp;
        Carp::carp("Undefined symbols present after loading $file: @unresolved\n");
    }

    dl_find_symbol($libref, $bootname) or do {
        require Carp;
        Carp::croak("Can't find '$bootname' symbol in $file\n");
    };

    push(@DynaLoader::dl_shared_objects, $file); # record files loaded
    $Marpa::R2::LIBMARPA_FILE = $file;
}

XSLoader::load( 'Marpa::R2', $Marpa::R2::STRING_VERSION );

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

require Marpa::R2::MetaG;
( $version_result = version_ok($Marpa::R2::MetaG::VERSION) )
    and die 'Marpa::R2::MetaG::VERSION ', $version_result;

require Marpa::R2::SLG;
( $version_result = version_ok($Marpa::R2::Scanless::G::VERSION) )
    and die 'Marpa::R2::Scanless::G::VERSION ', $version_result;

require Marpa::R2::SLR;
( $version_result = version_ok($Marpa::R2::Scanless::R::VERSION) )
    and die 'Marpa::R2::Scanless::R::VERSION ', $version_result;

require Marpa::R2::MetaAST;
( $version_result = version_ok($Marpa::R2::MetaAST::VERSION) )
    and die 'Marpa::R2::MetaAST::VERSION ', $version_result;

require Marpa::R2::Stuifzand;
( $version_result = version_ok($Marpa::R2::Stuifzand::VERSION) )
    and die 'Marpa::R2::Stuifzand::VERSION ', $version_result;

require Marpa::R2::ASF;
( $version_result = version_ok($Marpa::R2::ASF::VERSION) )
    and die 'Marpa::R2::ASF::VERSION ', $version_result;

sub Marpa::R2::exception {
    my $exception = join q{}, @_;
    $exception =~ s/ \n* \z /\n/xms;
    die($exception) if $Marpa::R2::JUST_DIE;
    CALLER: for ( my $i = 0; 1; $i++) {
        my ($package ) = caller($i);
        last CALLER if not $package;
        last CALLER if not 'Marpa::R2::' eq substr $package, 0, 11;
        $Carp::Internal{ $package } = 1;
    }
    Carp::croak($exception, q{Marpa::R2 exception});
}

package Marpa::R2::Internal::X;

use overload (
    q{""} => sub {
        my ($self) = @_;
        return $self->{message} // $self->{fallback_message};
    },
    fallback => 1
);

sub new {
    my ( $class, @hash_ref_args ) = @_;
    my %x_object = ();
    for my $hash_ref_arg (@hash_ref_args) {
        if ( ref $hash_ref_arg ne "HASH" ) {
            my $ref_type = ref $hash_ref_arg;
            my $ref_desc = $ref_type ? "ref to $ref_type" : "not a ref";
            die
                "Internal error: args to Marpa::R2::Internal::X->new is $ref_desc -- it should be hash ref";
        } ## end if ( ref $hash_ref_arg ne "HASH" )
        $x_object{$_} = $hash_ref_arg->{$_} for keys %{$hash_ref_arg};
    } ## end for my $hash_ref_arg (@hash_ref_args)
    my $name = $x_object{name};
    die("Internal error: an excepion must have a name") if not $name;
    $x_object{fallback_message} = qq{Exception "$name" thrown};
    return bless \%x_object, $class;
} ## end sub new

sub name {
    my ($self) = @_;
    return $self->{name};
}

1;

# vim: set expandtab shiftwidth=4:
