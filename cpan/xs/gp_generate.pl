#!perl
# Copyright 2013 Jeffrey Kegler
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

my %format_by_type = (
   int => '%d',
   Marpa_IRL_ID => '%d',
   Marpa_ISY_ID => '%d',
   Marpa_Rank => '%d',
   Marpa_Rule_ID => '%d',
   Marpa_Symbol_ID => '%d',
   Marpa_Earley_Set_ID => '%d',
);

sub gp_generate {
    my ( $function, @arg_type_pairs ) = @_;
    my $output = q{};

    # For example, 'g_wrapper'
    my $wrapper_variable = $main::CLASS_LETTER . '_wrapper';

    # For example, 'G_Wrapper'
    my $wrapper_type = ( uc $main::CLASS_LETTER ) . '_Wrapper';

    # For example, 'g_wrapper'
    my $libmarpa_method =
          $function =~ m/^_marpa_/xms
        ? $function
        : 'marpa_' . $main::CLASS_LETTER . '_' . $function;

    # Just g_wrapper for the grammar, self->base otherwise
    my $base = $main::CLASS_LETTER eq 'g' ? 'g_wrapper' : "$wrapper_variable->base";

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
    $output .= "  if ( gp_result < 0 && $base->throw ) {\n";
    my @format    = ();
    my @variables = ();
    ARG: for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 ) {
        my $arg_type = $arg_type_pairs[$i];
        my $variable = $arg_type_pairs[ $i + 1 ];
        if ( my $format = $format_by_type{$arg_type} ) {
            push @format,    $format;
            push @variables, $variable;
            next ARG;
        }
        die "Unknown arg_type $arg_type";
    } ## end for ( my $i = 0; $i < $#arg_type_pairs; $i += 2 )
    my $format_string =
          q{"Problem in }
        . $main::CLASS_LETTER . q{->}
        . $function . '('
        . ( join q{, }, @format )
        . q{): %s"};
    my @format_args = @variables;
    push @format_args, qq{xs_g_error( $base )};
    $output .= "    croak( $format_string,\n";
    $output .= q{     } . (join q{, }, @format_args) . ");\n";
    $output .= "  }\n";
    $output .= q{  XPUSHs (sv_2mortal (newSViv (gp_result)));} . "\n";
    $output .= "}\n";
    return $output;
} ## end sub gp_generate

print ${out} <<'END_OF_PREAMBLE';
 # Copyright 2013 Jeffrey Kegler
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

say {$out} gp_generate(qw(error_clear));
say {$out} gp_generate(qw(event_count));
say {$out} gp_generate(qw(has_cycle));
say {$out} gp_generate(qw(highest_rule_id));
say {$out} gp_generate(qw(highest_symbol_id));
say {$out} gp_generate(qw(is_precomputed));
say {$out} gp_generate(qw(precompute));
say {$out} gp_generate(qw(rule_is_accessible Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_loop Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_nullable Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_nulling Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_productive Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_is_proper_separation Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_length Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_lhs Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_null_high Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(rule_null_high_set Marpa_Rule_ID rule_id int flag));
say {$out} gp_generate(qw(rule_rhs Marpa_Rule_ID rule_id int ix));
say {$out} gp_generate(qw(sequence_min Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(sequence_separator Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(start_symbol));
say {$out} gp_generate(qw(start_symbol_set Marpa_Symbol_ID id));
say {$out} gp_generate(qw(symbol_is_accessible Marpa_Symbol_ID symbol_id ));
say {$out} gp_generate(qw(symbol_is_completion_event Marpa_Symbol_ID sym_id));
say {$out} gp_generate(qw(symbol_is_completion_event_set Marpa_Symbol_ID sym_id int value));
say {$out} gp_generate(qw(symbol_is_counted Marpa_Symbol_ID symbol_id ));
say {$out} gp_generate(qw(symbol_is_nullable Marpa_Symbol_ID symbol_id ));
say {$out} gp_generate(qw(symbol_is_nulled_event Marpa_Symbol_ID sym_id));
say {$out} gp_generate(qw(symbol_is_nulled_event_set Marpa_Symbol_ID sym_id int value));
say {$out} gp_generate(qw(symbol_is_prediction_event Marpa_Symbol_ID sym_id));
say {$out} gp_generate(qw(symbol_is_prediction_event_set Marpa_Symbol_ID sym_id int value));
say {$out} gp_generate(qw(symbol_is_nulling Marpa_Symbol_ID symbol_id ));
say {$out} gp_generate(qw(symbol_is_productive Marpa_Symbol_ID symbol_id));
say {$out} gp_generate(qw(symbol_is_start Marpa_Symbol_ID symbol_id));
say {$out} gp_generate(qw(symbol_is_terminal Marpa_Symbol_ID symbol_id));
say {$out} gp_generate(qw(symbol_is_terminal_set Marpa_Symbol_ID symbol_id int boolean));
say {$out} gp_generate(qw(symbol_is_valued Marpa_Symbol_ID symbol_id));
say {$out} gp_generate(qw(symbol_is_valued_set Marpa_Symbol_ID symbol_id int boolean));
say {$out} gp_generate(qw(symbol_new));

$main::CLASS_LETTER   = 'r';
$main::LIBMARPA_CLASS = 'Marpa_Recognizer';
print {$out} 'MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::R', "\n\n";

say {$out} gp_generate(qw(completion_symbol_activate Marpa_Symbol_ID sym_id int reactivate));
say {$out} gp_generate(qw(current_earleme));
say {$out} gp_generate(qw(earleme Marpa_Earley_Set_ID ordinal));
say {$out} gp_generate(qw(earleme_complete));
say {$out} gp_generate(qw(earley_item_warning_threshold));
say {$out} gp_generate(qw(earley_item_warning_threshold_set int too_many_earley_items));
say {$out} gp_generate(qw(earley_set_value Marpa_Earley_Set_ID ordinal));
say {$out} gp_generate(qw(expected_symbol_event_set Marpa_Symbol_ID xsyid int value));
say {$out} gp_generate(qw(furthest_earleme));
say {$out} gp_generate(qw(is_exhausted));
say {$out} gp_generate(qw(latest_earley_set));
say {$out} gp_generate(qw(latest_earley_set_value_set int value));
say {$out} gp_generate(qw(nulled_symbol_activate Marpa_Symbol_ID sym_id int reactivate));
say {$out} gp_generate(qw(prediction_symbol_activate Marpa_Symbol_ID sym_id int reactivate));
say {$out} gp_generate(qw(progress_report_finish));
say {$out} gp_generate(qw(progress_report_start Marpa_Earley_Set_ID ordinal));
say {$out} gp_generate(qw(terminal_is_expected Marpa_Symbol_ID xsyid));


$main::CLASS_LETTER   = 'b';
$main::LIBMARPA_CLASS = 'Marpa_Bocage';
print {$out} 'MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::B', "\n\n";
say {$out} gp_generate(qw(ambiguity_metric));

# Nothing (as yet) in bocage class

$main::CLASS_LETTER   = 'o';
$main::LIBMARPA_CLASS = 'Marpa_Order';
print {$out} 'MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::O', "\n\n";

say {$out} gp_generate(qw(ambiguity_metric));
say {$out} gp_generate(qw(high_rank_only_set int flag));
say {$out} gp_generate(qw(high_rank_only));
say {$out} gp_generate(qw(rank));

$main::CLASS_LETTER   = 't';
$main::LIBMARPA_CLASS = 'Marpa_Tree';
print {$out} 'MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::T', "\n\n";

say {$out} gp_generate(qw(next));
say {$out} gp_generate(qw(parse_count));

$main::CLASS_LETTER   = 'v';
$main::LIBMARPA_CLASS = 'Marpa_Value';
print {$out} 'MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::V', "\n\n";

say {$out} gp_generate(qw(valued_force));
say {$out} gp_generate(qw(rule_is_valued_set Marpa_Rule_ID symbol_id int value));
say {$out} gp_generate(qw(symbol_is_valued_set Marpa_Symbol_ID symbol_id int value));

$main::CLASS_LETTER   = 'g';
$main::LIBMARPA_CLASS = 'Marpa_Grammar';
print {$out} 'MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::G', "\n\n";

say {$out} gp_generate(qw(_marpa_g_rule_is_keep_separation Marpa_Rule_ID rule_id));
say {$out} gp_generate(qw(_marpa_g_irl_lhs Marpa_IRL_ID rule_id));
say {$out} gp_generate(qw(_marpa_g_irl_rhs Marpa_IRL_ID rule_id int ix));
say {$out} gp_generate(qw(_marpa_g_irl_length Marpa_IRL_ID rule_id));
say {$out} gp_generate(qw(_marpa_g_irl_rank Marpa_IRL_ID irl_id));
say {$out} gp_generate(qw(_marpa_g_isy_rank Marpa_ISY_ID isy_id));
