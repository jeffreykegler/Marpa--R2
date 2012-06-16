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
   my ($function, @arg_type_pairs) = @_;
   my $output = q{};
   $output .= "void\n";
   $output .= "$function( g_wrapper )\n";
   $output .= "    G_Wrapper *g_wrapper;\n";
   ARG: for (my $i=0; $i < $#arg_type_pairs; $i+=2) {
     $output .= q{    };
     $output .= join q{ }, @arg_type_pairs[ $i .. $i + 1 ];
     $output .= ";\n"
   }
   $output .= "PPCODE:\n";
   $output .= "{\n";
   $output .= "  Marpa_Grammar g = gwrapper->g;\n";
   $output .= "  int gp_result = marpa_g_" . $function . '(g)' . "\n";
   $output .= "  if ( gp_result == -1 ) { XSRETURN_UNDEF; }\n";
   $output .= "  if ( gp_result < 0 ) {\n";
   $output .= '    croak("Problem in g->' . $function . '(';
   my @format = ();
   my @variables = ();
   ARG: for (my $i=0; $i < $#arg_type_pairs; $i+=2) {
       my $arg_type = $arg_type_pairs[$i];
       my $variable = $arg_type_pairs[$i+1];
       if ($arg_type eq 'int') {
          push @format, '%d';
	  push @variables, $variable;
	  next ARG;
       }
       if ($arg_type eq 'Marpa_Rule_ID') {
          push @format, '%d';
	  push @variables, $variable;
	  next ARG;
       }
       if ($arg_type eq 'Marpa_Symbol_ID') {
          push @format, '%d';
	  push @variables, $variable;
	  next ARG;
       }
       die "Unknown arg_type $arg_type";
   }
   $output .= join q{, }, @format;
   $output .= q{): %s", };
   $output .= join q{, }, @variables;
   $output .= q{, xs_g_error (g_wrapper));} . "\n";
   $output .= "  }\n";
   $output .= q{  XPUSHs (sv_2mortal (newSViv (gp_result)));} . "\n";
   $output .= "}\n\n";
   return $output;
}

say gp_generate(qw(start_symbol int a Marpa_Rule_ID rule));

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
