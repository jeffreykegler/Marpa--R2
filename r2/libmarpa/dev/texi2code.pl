#!perl
# Copyright 2011 Jeffrey Kegler
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
    die("usage: $PROGRAM_NAME api.h.in error.h.in error.c.in");
}

open my $api_h_in, '>', $ARGV[0];
open my $error_h_in, '>', $ARGV[1];
open my $error_c_in, '>', $ARGV[2];

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
MARPA_ERR_PRECOMPUTED
MARPA_ERR_START_NOT_LHS
MARPA_ERR_UNPRODUCTIVE_START
);

my %error_number = map { $error_codes[$_], $_ } (0 .. $#error_codes);
my @errors_seen = ();

my @errors = ();
my $next_error_code = 0;
my @defs = ();
my $current_error_number = undef;
my @suggested = ();
while ( my $line = <STDIN> ) {
     if ( defined $current_error_number ) {
        my ($message) = ($line =~ /Suggested \s* message [:] \s " ([^"]*) " /xms );
        if ($message) {
            $suggested[$current_error_number] = $message;
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
    if ( $line =~ /[@]deftypefun/xms ) {
        my $def = q{};
        while ( $line =~ / [@] \s* \z /xms ) {
            $def .= $line;
            $def =~ s/ [@] \s* \z//xms;
            $line = <STDIN>;
        }
        $def .= $line;
        $def =~ s/\A \s* [@] deftypefun \s* //xms;
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
 * Copyright 2011 Jeffrey Kegler
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
 * This file is not part of libmarpa
 * It exists so that the higher levels,
 * which can either compile it as a C file,
 * or read it a a text file.
 */

NOTLIB_PREAMBLE

print {$error_h_in} $common_preamble, $notlib_preamble, <<'STRUCT_DECLARATION';
struct s_marpa_error_description {
    Marpa_Error_Code error_code;
    const char* name;
    const char* suggested;
};

STRUCT_DECLARATION

say {$api_h_in} $common_preamble;
say {$api_h_in} join "\n", @defs;
my $error_count = scalar @errors;
say {$api_h_in} "#define MARPA_ERROR_COUNT $error_count";
for ( my $error_number = 0; $error_number < $error_count; $error_number++ ) {
    say {$api_h_in} '#define '
        . $errors[$error_number] . q{ }
        . $error_number;
}

print {$error_c_in} $common_preamble, $notlib_preamble;
say {$error_c_in} <<'COMMENT';
/*
 * This is not a complete C file and for separate compilation.
 * In particular, it lacks a definition of s_marpa_error_description.
 * To compile this code, you can include it in a larger file.
 * Applications may prefer to get the information by reading it
 * as a text file.
 */;
COMMENT
say {$error_c_in} 'const struct s_marpa_error_description marpa_error_description[] = {';
my @lines = ();
for (my $error_number = 0; $error_number < $error_count; $error_number++) {
   my $suggested_description = $suggested[$error_number] // "Unknown error";
   my $error_name = $errors[$error_number];
   say {$error_c_in} qq[  { $error_number, "$error_name", "$suggested_description" },];
}
say {$error_c_in} '};';

