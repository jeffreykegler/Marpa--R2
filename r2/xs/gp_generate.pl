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

sub usage {
     die "usage: $PROGRAM_NAME [out.xsh]";
}

if (@ARGV > 1) {
   usage();
}

my $out;
if ( @ARGV == 1 ) {
  # For safety sake, only allow output files
  # which end in '.xsh'.  This can be overriden
  # by redirecting STDOUT, for example from
  # the shell.
    my $xsh_file_name = $ARGV[0];
    if ( $xsh_file_name !~ /[.]xsh$/ ) {
        usage();
    }
    open $out, q{>}, $xsh_file_name;
} else {
   $out = *STDOUT;
}

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

print ${out} <<'END_OF_PREAMBLE';
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

END_OF_PREAMBLE

print ${out} <<END_OF_PREAMBLE;
 # Generated automatically by $PROGRAM_NAME
 # NOTE: Changes made to this file will be lost: look at $PROGRAM_NAME.

END_OF_PREAMBLE

$main::CLASS_LETTER   = 'g';
$main::LIBMARPA_CLASS = 'Marpa_Grammar';
print {$out} 'MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::G', "\n\n";

say {$out} gp_generate(qw(has_cycle));
say {$out} gp_generate(qw(is_precomputed));
say {$out} gp_generate(qw(precompute));
say {$out} gp_generate(qw(rule_count));
say {$out} gp_generate(qw(rule_is_accessible Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_keep_separation Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_loop Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_nullable Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_nulling Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_productive Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_sequence Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_length Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_lhs Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_rhs Marpa_Rule_ID rule_id int ix));
say {$out} gp_generate(qw(start_symbol));
say {$out} gp_generate(qw(start_symbol_set Marpa_Symbol_ID id));
say {$out} gp_generate(qw(symbol_count));
say {$out} gp_generate(qw(symbol_is_accessible Marpa_Symbol_ID symbol_id ));
say {$out} gp_generate(qw(symbol_is_counted Marpa_Symbol_ID symbol_id ));
say {$out} gp_generate(qw(symbol_is_nullable Marpa_Symbol_ID symbol_id ));
say {$out} gp_generate(qw(symbol_is_nulling Marpa_Symbol_ID symbol_id ));
say {$out} gp_generate(qw(symbol_is_productive Marpa_Symbol_ID symbol_id));
say {$out} gp_generate(qw(symbol_is_start Marpa_Symbol_ID symbol_id));
say {$out} gp_generate(qw(symbol_is_terminal Marpa_Symbol_ID symbol_id));
say {$out} gp_generate(qw(symbol_is_terminal_set Marpa_Symbol_ID symbol_id int boolean));
say {$out} gp_generate(qw(symbol_is_valued Marpa_Symbol_ID symbol_id));
say {$out} gp_generate(qw(symbol_is_valued_set Marpa_Symbol_ID symbol_id int boolean));
say {$out} gp_generate(qw(symbol_new));
