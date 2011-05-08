#!/usr/bin/perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
use strict;
use warnings;

use Test::More tests => 7;

use English qw( -no_match_vars );
use Fatal qw( open close );
use Marpa::XS::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

sub catch_problem {
    my ( $test_name, $test, $expected_result, $expected_error ) = @_;
    my $result;
    my $eval_ok = eval {
        $result = $test->();
        1;
    };
    my $eval_error = $EVAL_ERROR;

    Test::More::is( $result, $expected_result, "Result: $test_name" );
    if ($eval_ok) {
        Test::More::fail("Failed to catch problem: $test_name");
    }
    elsif ( index( $eval_error, $expected_error ) < 0 ) {
        my $diag_message =
            "Failed to find expected message, was expecting:\n";
        my $temp;
        $temp = $expected_error;
        $temp =~ s/^/=== /xmsg;
        chomp $temp;
        $diag_message .= "$temp\n";
        $diag_message .= "This was the message actually received:\n";
        $temp = $eval_error;
        $temp =~ s/^/=== /xmsg;
        chomp $temp;
        $diag_message .= "$temp\n";
        Test::More::diag($diag_message);
        Test::More::fail("Unexpected message: $test_name");
    } ## end elsif ( index( $eval_error, $expected_error ) < 0 )
    else {
        Test::More::pass("Successfully caught problem: $test_name");
    }
    return;
} ## end sub catch_problem

my $grammar = Marpa::XS::Grammar->new(
    {   start => 'Top',
        strip => 0,
        rules => [
            { lhs => 'Top',  rhs => [qw/Term/], min => 1 },
            { lhs => 'Term', rhs => [qw/a/] },
            { lhs => 'Term', rhs => [qw/b/] },
            { lhs => 'Term', rhs => [qw/c/] },
            { lhs => 'Term', rhs => [qw/d/] },
        ],
    }
);

$grammar->precompute();

my $test_name;
my $trace;
my $expected_trace;
my $memory;
my $recce;

# First test that duplicates are Detected
$test_name = 'duplicate terminal 1';
$trace     = q{};
## no critic (InputOutput::RequireBriefOpen)
open $memory, q{>}, \$trace;
$recce = Marpa::XS::Recognizer->new(
    {   grammar           => $grammar,
        trace_terminals   => 1,
        trace_file_handle => $memory
    }
);

sub duplicate_terminal_1 {

# Marpa::XS::Display
# name: Recognizer alternative Synopsis

    defined $recce->alternative( 'a', 42, 1 )
        or return 'First alternative failed';

# Marpa::XS::Display::End

    return $recce->alternative( 'a', 711, 1 );
}

catch_problem( $test_name, \&duplicate_terminal_1, undef,
    q{"a" already scanned with length 1} );

$expected_trace = q{Accepted "a" at 0-1};
if ( index( $trace, $expected_trace ) < 0 ) {
    my $diag_message =
        "Failed to get expected trace result, was expecting:\n";
    $diag_message .= $expected_trace;
    $diag_message .= "This were the traces actually received:\n";
    my $temp = $trace;
    chomp $temp;
    $diag_message .= "$temp\n";
    Test::More::diag($diag_message);
    Test::More::fail("Trace messages are wrong: $test_name");
} ## end if ( index( $trace, $expected_trace ) < 0 )
else {
    Test::More::pass("Tracing OK: $test_name");
}

# 2nd test that duplicates are Detected
$test_name = 'duplicate terminal 2';
$trace     = q{};
close $memory;
open $memory, q{>}, \$trace;
$recce = Marpa::XS::Recognizer->new(
    {   grammar           => $grammar,
        trace_terminals   => 1,
        trace_file_handle => $memory
    }
);

sub duplicate_terminal_2 {

    # Should be OK, because different symbols
    defined $recce->alternative( 'a', 11, 1 )
        or return 'alternative a at 0 failed';
    defined $recce->alternative( 'b', 12, 1 )
        or return 'alternative b at 0 failed';

# Marpa::XS::Display
# name: Recognizer earleme_complete Synopsis

    $recce->earleme_complete();

# Marpa::XS::Display::End

    # Should be OK, because different lengths
    defined $recce->alternative( 'a', 21, 3 )
        or return 'alternative a at 1 failed';
    defined $recce->alternative( 'a', 22, 1 )
        or return 'alternative b at 1 failed';
    $recce->earleme_complete();
    defined $recce->alternative( 'd', 42, 2 )
        or return 'first alternative d at 2 failed';
    defined $recce->alternative( 'b', 22, 1 )
        or return 'alternative b at 1 failed';

    # this should cause an abend -- a 2nd d, with the same length
    return $recce->alternative( 'd', 711, 2 );
} ## end sub duplicate_terminal_2

catch_problem( $test_name, \&duplicate_terminal_2, undef,
    q{"d" already scanned with length 2 at location 2} );

$expected_trace = <<'EOS';
Setting trace_terminals option
Accepted "a" at 0-1
Accepted "b" at 0-1
Accepted "a" at 1-4
Accepted "a" at 1-2
Accepted "d" at 2-4
Accepted "b" at 2-3
EOS

if ( index( $trace, $expected_trace ) < 0 ) {
    my $diag_message =
        "Failed to get expected trace result, was expecting:\n";
    $diag_message .= $expected_trace;
    $diag_message .= "This were the traces actually received:\n";
    my $temp = $trace;
    chomp $temp;
    $diag_message .= "$temp\n";
    Test::More::diag($diag_message);
    Test::More::fail("Trace messages are wrong: $test_name");
} ## end if ( index( $trace, $expected_trace ) < 0 )
else {
    Test::More::pass("Tracing OK: $test_name");
}

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
