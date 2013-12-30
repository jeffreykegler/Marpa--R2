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

if (scalar @ARGV != 1) {
    die("usage: $PROGRAM_NAME marpa_slif.h-ops > marpa_slif.c-ops");
}

open my $h_fh, q{>}, $ARGV[0];

my @ops = sort { $a->[0] cmp $b->[0] }
    [ "alternative",             "MARPA_OP_ALTERNATIVE" ],
    [ "bless",                   "MARPA_OP_BLESS" ],
    [ "callback",                "MARPA_OP_CALLBACK" ],
    [ "earleme_complete",        "MARPA_OP_EARLEME_COMPLETE" ],
    [ "end_marker",              "MARPA_OP_END_MARKER" ],
    [ "invalid_char",            "MARPA_OP_INVALID_CHAR" ],
    [ "noop",                    "MARPA_OP_NOOP" ],
    [ "pause",                   "MARPA_OP_PAUSE" ],
    [ "push_length",             "MARPA_OP_PUSH_LENGTH" ],
    [ "push_one",                "MARPA_OP_PUSH_ONE" ],
    [ "push_sequence",           "MARPA_OP_PUSH_SEQUENCE" ],
    [ "push_start_location",     "MARPA_OP_PUSH_START_LOCATION" ],
    [ "push_undef",              "MARPA_OP_PUSH_UNDEF" ],
    [ "push_values",             "MARPA_OP_PUSH_VALUES" ],
    [ "result_is_array",         "MARPA_OP_RESULT_IS_ARRAY" ],
    [ "result_is_constant",      "MARPA_OP_RESULT_IS_CONSTANT" ],
    [ "result_is_n_of_sequence", "MARPA_OP_RESULT_IS_N_OF_SEQUENCE" ],
    [ "result_is_rhs_n",         "MARPA_OP_RESULT_IS_RHS_N" ],
    [ "result_is_token_value",   "MARPA_OP_RESULT_IS_TOKEN_VALUE" ],
    [ "result_is_undef",         "MARPA_OP_RESULT_IS_UNDEF" ],
    [ "retry_or_set_lexer",      "MARPA_OP_RETRY_OR_SET_LEXER" ],
    [ "set_lexer",               "MARPA_OP_SET_LEXER" ];

for (my $i = 0; $i <= $#ops; $i++) {
   my (undef, $macro) = @{$ops[$i]};
   say {$h_fh} "#define $macro $i";
}

say q<static struct op_data_s op_by_name_object[] = {>;
for (my $i = 0; $i <= $#ops; $i++) {
   my ($name, $macro) = @{$ops[$i]};
   say qq<  { "$name", $macro },>;
}
say q<};>;

say q<static const char* op_name_by_id_object[] = {>;
for (my $i = 0; $i <= $#ops; $i++) {
   my ($name) = @{$ops[$i]};
   say qq<  "$name",>;
}
say q<};>;

# vim: expandtab shiftwidth=4:
