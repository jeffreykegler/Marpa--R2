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
    die("usage: $PROGRAM_NAME api.h.in api.c.in error.list");
}

open my $api_h_in, '>', $ARGV[0];
open my $api_c_in, '>', $ARGV[1];
open my $error_list, '>', $ARGV[2];

my @errors = ();
my $error_count = 0;
my @defs = ();
my $pending_error_list_line = undef;
while ( my $line = <STDIN> ) {
    if ( $pending_error_list_line ) {
	my ($message) = ($line =~ /Suggested \s* message [:] \s " ([^"]*) " /xms );
	if ($message) {
	    say {$error_list} $pending_error_list_line. $message;
	    $pending_error_list_line = undef;
	}
    }
    if ( $line =~ /[@]deftypevr/xms ) {
        my ($error) = ($line =~ m/(MARPA_ERR_.*)\b/xms);
	if ($error) {
	    $pending_error_list_line = $error_count . " ";
	    $errors[$error_count++] = $error;
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

my $preamble = <<'PREAMBLE';
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

PREAMBLE

say {$api_h_in} $preamble;
say {$api_h_in} join "\n", @defs;
say {$api_h_in} "extern const char* s_marpa_error_description[];";
for (my $error_number = 0; $error_number < $error_count; $error_number++)
{
   say {$api_h_in} '#define ' . $errors[$error_number] . q{ } . $error_number;
}

say {$api_c_in} $preamble;
say {$api_c_in} "const char* s_marpa_error_description[$error_count] = {";
my @lines = ();
for (my $error_number = 0; $error_number < $error_count; $error_number++) {
   push @lines, q{  "} . $errors[$error_number] . q{"};
}
say {$api_c_in} +(join ",\n", @lines), "\n};\n";
