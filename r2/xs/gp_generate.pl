#!perl
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

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use autodie;

# Portability is NOT emphasized here -- this script is part
# of the development environment, not the configuration or
# installation environment

sub gp_generate {
    my ( $function, @arg_type_pairs ) = @_;
    my $output = q{};

    # For example, 'g_wrapper'
    my $wrapper_variable = $main::CLASS_LETTER . '_wrapper';

    # For example, 'G_Wrapper'
    my $wrapper_type = ( uc $main::CLASS_LETTER ) . '_Wrapper';

    # For example, 'g_wrapper'
    my $libmarpa_method = 'marpa_' . $main::CLASS_LETTER . '_' . $function;

    # For example, 'g_wrapper'
    my $xs_error_method = 'xs_' . $main::CLASS_LETTER . '_error';

    $output .= "void\n";
    my @args = ();
    ARG: for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 ) {
        push @args, $arg_type_pairs[ $i + 1 ];
    }
    $output
        .= "$function( " . ( join q{, }, $wrapper_variable, @args ) . " )\n";
    $output .= "    $wrapper_type *$wrapper_variable;\n";
    ARG: for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 ) {
        $output .= q{    };
        $output .= join q{ }, @arg_type_pairs[ $i .. $i + 1 ];
        $output .= ";\n";
    }
    $output .= "PPCODE:\n";
    $output .= "{\n";
    $output
        .= "  $main::LIBMARPA_CLASS self = $wrapper_variable->$main::CLASS_LETTER;\n";
    $output .= "  int gp_result = $libmarpa_method("
        . ( join q{, }, 'self', @args ) . ");\n";
    $output .= "  if ( gp_result == -1 ) { XSRETURN_UNDEF; }\n";
    $output .= "  if ( gp_result < 0 ) {\n";
    $output .= '    croak("Problem in g->' . $function . '(';
    my @format    = ();
    my @variables = ();
    ARG: for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 ) {
        my $arg_type = $arg_type_pairs[$i];
        my $variable = $arg_type_pairs[ $i + 1 ];
        if ( $arg_type eq 'int' ) {
            push @format,    '%d';
            push @variables, $variable;
            next ARG;
        }
        if ( $arg_type eq 'Marpa_Rule_ID' ) {
            push @format,    '%d';
            push @variables, $variable;
            next ARG;
        }
        if ( $arg_type eq 'Marpa_Symbol_ID' ) {
            push @format,    '%d';
            push @variables, $variable;
            next ARG;
        }
        die "Unknown arg_type $arg_type";
    } ## end for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 )
    $output .= join q{, }, @format;
    $output .= q{): %s", } . "\n";
    $output .= q{      } . join q{, }, @variables,
        qq{$xs_error_method( $wrapper_variable )};
    $output .= q{);} . "\n";
    $output .= "  }\n";
    $output .= q{  XPUSHs (sv_2mortal (newSViv (gp_result)));} . "\n";
    $output .= "}\n";
    return $output;
} ## end sub gp_generate

$main::CLASS_LETTER   = 'g';
$main::LIBMARPA_CLASS = 'Marpa_Grammar';
print 'MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::G', "\n\n";

say gp_generate(qw(start_symbol));
say gp_generate(qw(start_symbol_set Marpa_Symbol_ID id));

# void
# start_symbol( g_wrapper )
#     G_Wrapper *g_wrapper;
# PPCODE:
# {
#   Marpa_Grammar g = g_wrapper->g;
#   Marpa_Symbol_ID id = marpa_g_start_symbol (g);
#   if (id <= -2)
#     {
#       croak ("Problem in g->start_symbol(): %s", xs_g_error (g_wrapper));
#     }
#   if (id < 0)
#     {
#       XSRETURN_UNDEF;
#     }
#   XPUSHs (sv_2mortal (newSViv (id)));
# }
