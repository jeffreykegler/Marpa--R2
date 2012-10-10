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

# Test grammar exceptions -- make sure problems actually
# are detected.  These tests are for problems which are supposed
# to abend.

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 7;
use Fatal qw(open close);

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . join( q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

# NOTE: trace_result not used or tested yet.
sub test_grammar {
    my ( $test_name, $grammar_args, $expected_error, $trace_result ) = @_;
    my $trace;
    my $memory;
    my $added_args = {};
    if ($trace_result) {
        $trace = q{};
        ## no critic (InputOutput::RequireBriefOpen)
        open $memory, q{>}, \$trace;
        $added_args = { trace_file_handle => $memory };
    } ## end if ($trace_result)
    my $eval_ok = eval {
        # merge added args
        @$grammar_args{keys %$added_args} = values %$added_args;
        my $grammar = Marpa::R2::Grammar->new( $grammar_args );
        $grammar->precompute();
        1;
    };
    my $eval_error = $EVAL_ERROR;
    defined $trace_result and close $memory;
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
    return if not defined $trace_result;
    if ( index( $trace, $trace_result ) < 0 ) {
        my $diag_message =
            "Failed to get expected trace result, was expecting:\n";
        my $temp;
        $temp = $trace_result;
        $temp =~ s/^/=== /xmsg;
        chomp $temp;
        $diag_message .= "$temp\n";
        $diag_message .= "This were the traces actually received:\n";
        $temp = $eval_error;
        $temp =~ s/^/=== /xmsg;
        chomp $temp;
        $diag_message .= "$temp\n";
        Test::More::diag($diag_message);
        Test::More::fail("Unexpected trace: $test_name");
    } ## end if ( index( $trace, $trace_result ) < 0 )
    else {
        Test::More::pass("Tracing OK: $test_name");
    }
    return;
} ## end sub test_grammar

my $counted_nullable_grammar = {
    rules => [
        {   lhs => 'S',
            rhs => ['Seq'],
            min => 0,
        },
        {   lhs => 'Seq',
            rhs => [qw(A B)],
        },
        { lhs => 'A' },
        { lhs => 'B' },
    ],
    start         => 'S',
};

test_grammar(
    'counted nullable',
    $counted_nullable_grammar,
    qq{Nullable symbol "Seq" is on rhs of counted rule\n}
        . q{Counted nullables confuse Marpa -- please rewrite the grammar}
);

my $duplicate_rule_grammar = {
    rules => [
        { lhs => 'Top', rhs => ['Dup'] },
        {   lhs => 'Dup',
            rhs => ['Item'],
        },
        {   lhs => 'Dup',
            rhs => ['Item'],
        },
        { lhs => 'Item', rhs => ['a'] },
    ],
    start => 'Top',
};
test_grammar( 'duplicate rule',
    $duplicate_rule_grammar, 'Duplicate rule: Dup -> Item ' );

my $unique_lhs_grammar = {
    rules => [
        { lhs => 'Top', rhs => ['Dup'] },
        {   lhs => 'Dup',
            rhs => ['Item'],
            min => 0,
        },
        {   lhs => 'Dup',
            rhs => ['Item'],
        },
        { lhs => 'Item', rhs => ['a'] },
    ],
    start => 'Top',
};
test_grammar( 'unique_lhs',
    $unique_lhs_grammar, 'LHS of sequence rule would not be unique: Dup -> Item ' );

my $nulling_terminal_grammar = {
    rules => [
        { lhs => 'Top', rhs => ['Bad'] },
        { lhs => 'Top', rhs => ['Good'] },
        { lhs => 'Bad', rhs => [] },
    ],
    start         => 'Top',
    terminals     => ['Good', 'Bad'],
};
test_grammar(
    'nulling terminal grammar',
    $nulling_terminal_grammar,
    'Nulling symbol "Bad" is also a terminal'
);

my $no_start_grammar = {
    rules     => [ { lhs => 'Top', rhs => ['Bad'] }, ],
    terminals => ['Bad'],
};
test_grammar( 'no start symbol', $no_start_grammar, 'No start symbol' );

my $start_not_lhs_grammar = {
    rules     => [ { lhs => 'Top', rhs => ['Bad'] }, ],
    terminals => ['Bad'],
    start     => 'Bad',
};
test_grammar( 'start symbol not on lhs',
    $start_not_lhs_grammar, 'Start symbol "Bad" not on LHS of any rule' );

my $unproductive_start_grammar = {
    rules => [
        { lhs => 'Top',   rhs => ['Bad'] },
        { lhs => 'Bad',   rhs => ['Worse'] },
        { lhs => 'Worse', rhs => ['Bad'] },
        { lhs => 'Top',   rhs => ['Good'] },
    ],
    terminals => ['Good'],
    start     => 'Bad',
};
test_grammar(
    'unproductive start symbol',
    $unproductive_start_grammar,
    'Unproductive start symbol: "Bad"'
);

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
