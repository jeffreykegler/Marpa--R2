#!perl
# Copyright 2014 Jeffrey Kegler
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

if (scalar @ARGV != 1) {
    die("usage: $PROGRAM_NAME error_codes.c > marpa.h-err");
}

open my $codes_c, '>', $ARGV[0];

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

my %error_number = map { $error_codes[$_], $_ } (0 .. $#error_codes);
my @errors_seen = ();
my @error_number_matches = ();
my @errors = ();
my $current_error_number = undef;
my @error_suggested_messages = ();

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

} ## end while ( my $line = <STDIN> )

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


my $error_count = scalar @errors;
say "#define MARPA_ERROR_COUNT $error_count";
for ( my $error_number = 0; $error_number < $error_count; $error_number++ ) {
    say '#define '
        . $errors[$error_number] . q{ }
        . $error_number;
}

say {$codes_c} 'const struct marpa_error_description_s marpa_error_description[] = {';
for ( my $error_number = 0; $error_number < $error_count; $error_number++ ) {
    my $error_name = $errors[$error_number];
    my $suggested_description = $error_suggested_messages[$error_number]
        // $error_name;
    say {$codes_c}
        qq[  { $error_number, "$error_name", "$suggested_description" },];
} ## end for ( my $error_number = 0; $error_number < $error_count...)
say {$codes_c} '};';

# vim: expandtab shiftwidth=4:
