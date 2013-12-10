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
use Fatal qw(open close);

if (scalar @ARGV != 3) {
    die("usage: $PROGRAM_NAME marpa_api.h codes.h codes.c");
}

open my $api_h, '>', $ARGV[0];
open my $codes_h, '>', $ARGV[1];
open my $codes_c, '>', $ARGV[2];

# In addition to be taken from the texinfo, document
# error codes are checked against this list.
# The actual numeric value is based on order in
# this list, not in the document.
# This is to allow the descriptions of the error
# codes in the list to be reordered without
# impacting the code.
#
# So that data for error codes can be kept
# memory-efficiently in an array,
# error codes are assigned numbers in sequence
# and based on their order in this list.
# For backward compatibility, new error codes
# should always be added at the end.
my @error_codes = qw(
MARPA_ERR_NONE
MARPA_ERR_AHFA_IX_NEGATIVE
MARPA_ERR_AHFA_IX_OOB
MARPA_ERR_ANDID_NEGATIVE
MARPA_ERR_ANDID_NOT_IN_OR
MARPA_ERR_ANDIX_NEGATIVE
MARPA_ERR_BAD_SEPARATOR
MARPA_ERR_BOCAGE_ITERATION_EXHAUSTED
MARPA_ERR_COUNTED_NULLABLE
MARPA_ERR_DEVELOPMENT
MARPA_ERR_DUPLICATE_AND_NODE
MARPA_ERR_DUPLICATE_RULE
MARPA_ERR_DUPLICATE_TOKEN
MARPA_ERR_YIM_COUNT
MARPA_ERR_YIM_ID_INVALID
MARPA_ERR_EVENT_IX_NEGATIVE
MARPA_ERR_EVENT_IX_OOB
MARPA_ERR_GRAMMAR_HAS_CYCLE
MARPA_ERR_INACCESSIBLE_TOKEN
MARPA_ERR_INTERNAL
MARPA_ERR_INVALID_AHFA_ID
MARPA_ERR_INVALID_AIMID
MARPA_ERR_INVALID_BOOLEAN
MARPA_ERR_INVALID_IRLID
MARPA_ERR_INVALID_NSYID
MARPA_ERR_INVALID_LOCATION
MARPA_ERR_INVALID_RULE_ID
MARPA_ERR_INVALID_START_SYMBOL
MARPA_ERR_INVALID_SYMBOL_ID
MARPA_ERR_I_AM_NOT_OK
MARPA_ERR_MAJOR_VERSION_MISMATCH
MARPA_ERR_MICRO_VERSION_MISMATCH
MARPA_ERR_MINOR_VERSION_MISMATCH
MARPA_ERR_NOOKID_NEGATIVE
MARPA_ERR_NOT_PRECOMPUTED
MARPA_ERR_NOT_TRACING_COMPLETION_LINKS
MARPA_ERR_NOT_TRACING_LEO_LINKS
MARPA_ERR_NOT_TRACING_TOKEN_LINKS
MARPA_ERR_NO_AND_NODES
MARPA_ERR_NO_EARLEY_SET_AT_LOCATION
MARPA_ERR_NO_OR_NODES
MARPA_ERR_NO_PARSE
MARPA_ERR_NO_RULES
MARPA_ERR_NO_START_SYMBOL
MARPA_ERR_NO_TOKEN_EXPECTED_HERE
MARPA_ERR_NO_TRACE_YIM
MARPA_ERR_NO_TRACE_YS
MARPA_ERR_NO_TRACE_PIM
MARPA_ERR_NO_TRACE_SRCL
MARPA_ERR_NULLING_TERMINAL
MARPA_ERR_ORDER_FROZEN
MARPA_ERR_ORID_NEGATIVE
MARPA_ERR_OR_ALREADY_ORDERED
MARPA_ERR_PARSE_EXHAUSTED
MARPA_ERR_PARSE_TOO_LONG
MARPA_ERR_PIM_IS_NOT_LIM
MARPA_ERR_POINTER_ARG_NULL
MARPA_ERR_PRECOMPUTED
MARPA_ERR_PROGRESS_REPORT_EXHAUSTED
MARPA_ERR_PROGRESS_REPORT_NOT_STARTED
MARPA_ERR_RECCE_NOT_ACCEPTING_INPUT
MARPA_ERR_RECCE_NOT_STARTED
MARPA_ERR_RECCE_STARTED
MARPA_ERR_RHS_IX_NEGATIVE
MARPA_ERR_RHS_IX_OOB
MARPA_ERR_RHS_TOO_LONG
MARPA_ERR_SEQUENCE_LHS_NOT_UNIQUE
MARPA_ERR_SOURCE_TYPE_IS_AMBIGUOUS
MARPA_ERR_SOURCE_TYPE_IS_COMPLETION
MARPA_ERR_SOURCE_TYPE_IS_LEO
MARPA_ERR_SOURCE_TYPE_IS_NONE
MARPA_ERR_SOURCE_TYPE_IS_TOKEN
MARPA_ERR_SOURCE_TYPE_IS_UNKNOWN
MARPA_ERR_START_NOT_LHS
MARPA_ERR_SYMBOL_VALUED_CONFLICT
MARPA_ERR_TERMINAL_IS_LOCKED
MARPA_ERR_TOKEN_IS_NOT_TERMINAL
MARPA_ERR_TOKEN_LENGTH_LE_ZERO
MARPA_ERR_TOKEN_TOO_LONG
MARPA_ERR_TREE_EXHAUSTED
MARPA_ERR_TREE_PAUSED
MARPA_ERR_UNEXPECTED_TOKEN_ID
MARPA_ERR_UNPRODUCTIVE_START
MARPA_ERR_VALUATOR_INACTIVE
MARPA_ERR_VALUED_IS_LOCKED
MARPA_ERR_RANK_TOO_LOW
MARPA_ERR_RANK_TOO_HIGH
MARPA_ERR_SYMBOL_IS_NULLING
MARPA_ERR_SYMBOL_IS_UNUSED
MARPA_ERR_NO_SUCH_RULE_ID
MARPA_ERR_NO_SUCH_SYMBOL_ID
MARPA_ERR_BEFORE_FIRST_TREE
MARPA_ERR_SYMBOL_IS_NOT_COMPLETION_EVENT
MARPA_ERR_SYMBOL_IS_NOT_NULLED_EVENT
MARPA_ERR_SYMBOL_IS_NOT_PREDICTION_EVENT
);

my @event_codes = qw(
MARPA_EVENT_NONE
MARPA_EVENT_COUNTED_NULLABLE
MARPA_EVENT_EARLEY_ITEM_THRESHOLD
MARPA_EVENT_EXHAUSTED
MARPA_EVENT_LOOP_RULES
MARPA_EVENT_NULLING_TERMINAL
MARPA_EVENT_SYMBOL_COMPLETED
MARPA_EVENT_SYMBOL_EXPECTED
MARPA_EVENT_SYMBOL_NULLED
MARPA_EVENT_SYMBOL_PREDICTED
);

my @step_type_codes = qw(
MARPA_STEP_INTERNAL1
MARPA_STEP_RULE
MARPA_STEP_TOKEN
MARPA_STEP_NULLING_SYMBOL
MARPA_STEP_TRACE
MARPA_STEP_INACTIVE
MARPA_STEP_INTERNAL2
MARPA_STEP_INITIAL
);

my @defs = ();

my %error_number = map { $error_codes[$_], $_ } (0 .. $#error_codes);
my @errors_seen = ();
my @error_number_matches = ();
my @errors = ();
my $current_error_number = undef;
my @error_suggested_messages = ();

my %event_number = map { $event_codes[$_], $_ } (0 .. $#event_codes);
my @events_seen = ();
my @events = ();
my $current_event_number = undef;
my @event_suggested_messages = ();

my %step_type_number = map { $step_type_codes[$_], $_ } (0 .. $#step_type_codes);
my @step_types_seen = ();
my @step_types = ();
my $current_step_type_number = undef;

LINE: while ( my $line = <STDIN> ) {

    if ( defined $current_error_number ) {
        my ($documented_value) =
            ( $line =~ /^Numeric \s* value [:] \s (\d+) [.] $/xms );
        if ( defined $documented_value ) {
            if ( $documented_value != $current_error_number ) {
                die
                    "Error number mismatch $current_error_number is $documented_value in doc";
            }
            $error_number_matches[$current_error_number]++;
        } ## end if ( defined $documented_value )
        my ($message) =
            ( $line =~ /Suggested \s* message [:] \s " ([^"]*) " /xms );
        if ($message) {
            $error_suggested_messages[$current_error_number] = $message;
            $current_error_number = undef;
        }
    } ## end if ( defined $current_error_number )

    if ( $line =~ /[@]deftypevr/xms ) {
        my ($error) = ($line =~ m/(MARPA_ERR_.*)\b/xms);
	if ($error) {
	    my $error_number = $error_number{$error};
	    die("$error not in list in $PROGRAM_NAME") if not defined $error_number;
	    $current_error_number = $error_number;
	    $errors_seen[$error_number] = 1;
	    $errors[$current_error_number] = $error;
	}
    }

     if ( defined $current_event_number ) {
        my ($message) = ($line =~ /Suggested \s* message [:] \s " ([^"]*) " /xms );
        if ($message) {
            $event_suggested_messages[$current_event_number] = $message;
            $current_event_number = undef;
        }
     }
    if ( $line =~ /[@]deftypevr.*MARPA_EVENT_/xms ) {
        my ($event) = ($line =~ m/(MARPA_EVENT_.*)\b/xms);
	if ($event) {
	    my $event_number = $event_number{$event};
	    die("$event not in list in $PROGRAM_NAME") if not defined $event_number;
	    $current_event_number = $event_number;
	    $events_seen[$event_number] = 1;
	    $events[$current_event_number] = $event;
	}
    }
    if ( $line =~ /[@]deftypevr.*MARPA_STEP_/xms ) {
        my ($step_type) = ($line =~ m/(MARPA_STEP_.*)\b/xms);
	if ($step_type) {
	    my $step_type_number = $step_type_number{$step_type};
	    die("$step_type not in list in $PROGRAM_NAME") if not defined $step_type_number;
	    $current_step_type_number = $step_type_number;
	    $step_types_seen[$step_type_number] = 1;
	    $step_types[$current_step_type_number] = $step_type;
	}
    }

    next LINE if $line =~ m/ [{] Macro [}] /xms;

    if ( $line =~ /[@]deftypefun/xms ) {
        my $def = q{};
        while ( $line =~ / [@] \s* \z /xms ) {
            $def .= $line;
            $def =~ s/ [@] \s* \z//xms;
            $line = <STDIN>;
        }
        $def .= $line;
        $def =~ s/\A \s* [@] deftypefun x? \s* //xms;
        $def =~ s/ [@]var[{] ([^}]*) [}]/$1/xmsg;
        $def =~ s/ [@]code[{] ([^}]*) [}]/$1/xmsg;
        $def =~ s/\s+/ /xmsg;
        $def =~ s/\s \z/;/xmsg;
        push @defs, $def;
    } ## end if ( $line =~ /[@]deftypefun/xms )

} ## end while ( my $line = <STDIN> )

my @events_not_seen = grep { !$events_seen[$_] } (0 .. $#event_codes);
if (@events_not_seen) {
  for my $event_not_seen (@events_not_seen) {
      say STDERR "Event not in document: ", $event_codes[$event_not_seen];
  }
  die 'Event(s) in list, but not in document';
}

my @errors_not_seen = grep { !$errors_seen[$_] } (0 .. $#error_codes);
if (@errors_not_seen) {
  for my $error_not_seen (@errors_not_seen) {
      say STDERR "Error not in document: ", $error_codes[$error_not_seen];
  }
  die 'Error(s) in list, but not in document';
}

my $error_code_issues = 0;
ERROR_CODE: for my $error_code ( 0 .. $#error_codes ) {
    my $matches = $error_number_matches[$error_code] // 0;
    next ERROR_CODE if $matches == 1;
    say STDERR
        "Problem: Error number $error_code has $matches errors associated with it";
    $error_code_issues++;
} ## end ERROR_CODE: for my $error_code ( 0 .. $#error_codes )
die 'Error(s) in list, but no number in document' if $error_code_issues;

my $common_preamble = <<'COMMON_PREAMBLE';
/*
 * Copyright 2013 Jeffrey Kegler
 * This file is part of Marpa::R2.  Marpa::R2 is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Marpa::R2 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Marpa::R2.  If not, see
 * http://www.gnu.org/licenses/.
 */
/*
 * DO NOT EDIT DIRECTLY
 * This file is written by texi2proto.pl
 * It is not intended to be modified directly
 */

COMMON_PREAMBLE

my $notlib_preamble = <<'NOTLIB_PREAMBLE';
/*
 * This file is not part compiled into libmarpa
 * It exists for use by the higher levels,
 * which can either compile it as a C file,
 * or read it a a text file.
 */

NOTLIB_PREAMBLE

print {$codes_h} $common_preamble, $notlib_preamble, <<'STRUCT_DECLARATION';
struct s_marpa_error_description {
    Marpa_Error_Code error_code;
    const char* name;
    const char* suggested;
};
struct s_marpa_event_description {
    Marpa_Event_Type event_code;
    const char* name;
    const char* suggested;
};
struct s_marpa_step_type_description {
    Marpa_Step_Type step_type;
    const char* name;
};

STRUCT_DECLARATION

say {$api_h} $common_preamble;
say {$api_h} join "\n", @defs;

my $error_count = scalar @errors;
say {$api_h} "#define MARPA_ERROR_COUNT $error_count";
for ( my $error_number = 0; $error_number < $error_count; $error_number++ ) {
    say {$api_h} '#define '
        . $errors[$error_number] . q{ }
        . $error_number;
}

my $event_count = scalar @events;
say {$api_h} "#define MARPA_EVENT_COUNT $event_count";
for ( my $event_number = 0; $event_number < $event_count; $event_number++ ) {
    say {$api_h} '#define '
        . $events[$event_number] . q{ }
        . $event_number;
}

my $step_type_count = scalar @step_types;
say {$api_h} "#define MARPA_STEP_COUNT $step_type_count";
for ( my $step_type_number = 0; $step_type_number < $step_type_count; $step_type_number++ ) {
    say {$api_h} '#define '
        . $step_types[$step_type_number] . q{ }
        . $step_type_number;
}

print {$codes_c} $common_preamble, $notlib_preamble;
say {$codes_c} <<'COMMENT';
/*
 * This is not a complete C file.
 * In particular, it lacks definitions of its structures.
 * To compile this code, you must include it in a larger file.
 * Applications may prefer to read it as a text file.
 */
COMMENT

say {$codes_c}
    'const struct s_marpa_error_description marpa_error_description[] = {';
for ( my $error_number = 0; $error_number < $error_count; $error_number++ ) {
    my $error_name = $errors[$error_number];
    my $suggested_description = $error_suggested_messages[$error_number]
        // $error_name;
    say {$codes_c}
        qq[  { $error_number, "$error_name", "$suggested_description" },];
} ## end for ( my $error_number = 0; $error_number < $error_count...)
say {$codes_c} '};';

say {$codes_c}
    'const struct s_marpa_event_description marpa_event_description[] = {';
for ( my $event_number = 0; $event_number < $event_count; $event_number++ ) {
    my $suggested_description = $event_suggested_messages[$event_number]
        // "Unknown event";
    my $event_name = $events[$event_number];
    say {$codes_c}
        qq[  { $event_number, "$event_name", "$suggested_description" },];
} ## end for ( my $event_number = 0; $event_number < $event_count...)
say {$codes_c} '};';

say {$codes_c}
    'const struct s_marpa_step_type_description marpa_step_type_description[] = {';
for (
    my $step_type_number = 0;
    $step_type_number < $step_type_count;
    $step_type_number++
    )
{
    my $step_type_name = $step_types[$step_type_number];
    say {$codes_c} qq[  { $step_type_number, "$step_type_name" },];
} ## end for ( my $step_type_number = 0; $step_type_number...)
say {$codes_c} '};';

