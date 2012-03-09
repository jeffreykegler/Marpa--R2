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
MARPA_ERR_UNKNOWN
MARPA_ERR_INTERNAL
MARPA_ERR_DEVELOPMENT
MARPA_ERR_COUNTED_NULLABLE
MARPA_ERR_DUPLICATE_RULE
MARPA_ERR_EIM_COUNT
MARPA_ERR_LHS_IS_TERMINAL
MARPA_ERR_NO_PARSE
MARPA_ERR_NO_RULES
MARPA_ERR_NO_START_SYMBOL
MARPA_ERR_NULL_RULE_UNMARKED_TERMINALS
MARPA_ERR_ORDER_FROZEN
MARPA_ERR_PRECOMPUTED
MARPA_ERR_START_NOT_LHS
MARPA_ERR_UNPRODUCTIVE_START
);

my @event_codes = qw(
MARPA_EVENT_NONE
MARPA_EVENT_EXHAUSTED
MARPA_EVENT_EARLEY_ITEM_THRESHOLD
MARPA_EVENT_LOOP_RULES
MARPA_EVENT_NEW_SYMBOL
MARPA_EVENT_NEW_RULE
MARPA_EVENT_COUNTED_NULLABLE
);

my @value_type_codes = qw(
MARPA_VALUE_INTERNAL1
MARPA_VALUE_RULE
MARPA_VALUE_TOKEN
MARPA_VALUE_NULLING_TOKEN
MARPA_VALUE_TRACE
MARPA_VALUE_INACTIVE
MARPA_VALUE_INTERNAL2
);

my @defs = ();

my %error_number = map { $error_codes[$_], $_ } (0 .. $#error_codes);
my @errors_seen = ();
my @errors = ();
my $current_error_number = undef;
my @error_suggested_messages = ();

my %event_number = map { $event_codes[$_], $_ } (0 .. $#event_codes);
my @events_seen = ();
my @events = ();
my $current_event_number = undef;
my @event_suggested_messages = ();

my %value_type_number = map { $value_type_codes[$_], $_ } (0 .. $#value_type_codes);
my @value_types_seen = ();
my @value_types = ();
my $current_value_type_number = undef;

while ( my $line = <STDIN> ) {

     if ( defined $current_error_number ) {
        my ($message) = ($line =~ /Suggested \s* message [:] \s " ([^"]*) " /xms );
        if ($message) {
            $error_suggested_messages[$current_error_number] = $message;
            $current_error_number = undef;
        }
     }
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
    if ( $line =~ /[@]deftypevr.*MARPA_VALUE_/xms ) {
        my ($value_type) = ($line =~ m/(MARPA_VALUE_.*)\b/xms);
	if ($value_type) {
	    my $value_type_number = $value_type_number{$value_type};
	    die("$value_type not in list in $PROGRAM_NAME") if not defined $value_type_number;
	    $current_value_type_number = $value_type_number;
	    $value_types_seen[$value_type_number] = 1;
	    $value_types[$current_value_type_number] = $value_type;
	}
    }

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
        $def =~ s/\s+/ /xmsg;
        $def =~ s/\s \z/;/xmsg;
        push @defs, $def;
    } ## end if ( $line =~ /[@]deftypefun/xms )

} ## end while ( my $line = <STDIN> )

for my $error_not_seen ( grep { !$errors_seen[$_] } (0 .. $#error_codes) ) {
    say STDERR "Error not in document: ", $error_codes[$error_not_seen];
}

my $common_preamble = <<'COMMON_PREAMBLE';
/*
 * Copyright 2012 Jeffrey Kegler
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
struct s_marpa_value_type_description {
    Marpa_Value_Type value_type;
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

my $value_type_count = scalar @value_types;
say {$api_h} "#define MARPA_VALUE_TYPE_COUNT $value_type_count";
for ( my $value_type_number = 0; $value_type_number < $value_type_count; $value_type_number++ ) {
    say {$api_h} '#define '
        . $value_types[$value_type_number] . q{ }
        . $value_type_number;
}

print {$codes_c} $common_preamble, $notlib_preamble;
say {$codes_c} <<'COMMENT';
/*
 * This is not a complete C file.
 * In particular, it lacks definitions of its structures.
 * To compile this code, you must include it in a larger file.
 * Applications may prefer to read it as a text file.
 */;
COMMENT

say {$codes_c}
    'const struct s_marpa_error_description marpa_error_description[] = {';
for ( my $error_number = 0; $error_number < $error_count; $error_number++ ) {
    my $suggested_description = $error_suggested_messages[$error_number]
        // "Unknown error";
    my $error_name = $errors[$error_number];
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
    'const struct s_marpa_value_type_description marpa_value_type_description[] = {';
for (
    my $value_type_number = 0;
    $value_type_number < $value_type_count;
    $value_type_number++
    )
{
    my $value_type_name = $value_types[$value_type_number];
    say {$codes_c} qq[  { $value_type_number, "$value_type_name" },];
} ## end for ( my $value_type_number = 0; $value_type_number...)
say {$codes_c} '};';

