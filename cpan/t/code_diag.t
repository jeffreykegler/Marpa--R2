#!perl
# Copyright 2015 Jeffrey Kegler
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
# Ensure various coding errors are caught

use 5.010;
use strict;
use warnings;

use Test::More tests => 7;

use lib 'inc';
use Marpa::R2::Test;
use Fatal qw( open close );
use English qw( -no_match_vars );
use Marpa::R2;

our $DEFAULT_NULL_DESC = '[default null]';
our $NULL_DESC         = '[null]';

my @features = qw(
    e_op_action default_action
);

my @tests = ( 'run phase warning', 'run phase error', 'run phase die', );

my %good_code = (
    'e_op_action'     => 'main::e_op_action',
    'e_pass_through'  => 'main::e_pass_through',
    'e_number_action' => 'main::e_number_action',
    'default_action'  => 'main::default_action',
);

# Code to produce a run phase warning
sub run_phase_warning {
    my $x;
    warn 'Test Warning 1';
    warn 'Test Warning 2';
    $x++;
    return 1;
} ## end sub run_phase_warning

# Code to produce a run phase error
sub run_phase_error {
    my $x = 0;
    $x = 1 / 0;
    return $x++;
}

# Code to produce a run phase die()
sub run_phase_die {
    my $x = 0;
    die 'test call to die';
}

my %test_arg;
my %expected;
for my $test (@tests) {
    for my $feature (@features) {
        $test_arg{$test}{$feature} = '1;';
        $expected{$test}{$feature} = q{};
    }
} ## end for my $test (@tests)

for my $feature (@features) {
    $test_arg{'run phase warning'}{$feature} = 'main::run_phase_warning';
    $test_arg{'run phase error'}{$feature}   = 'main::run_phase_error';
    $test_arg{'run phase die'}{$feature}     = 'main::run_phase_die';
}

my $getting_headers = 1;
my @headers;
my $data = q{};

my $test_data = <<'END_OF_TEST_DATA';

| bad code run phase warning
# this should be a run phase warning
my $x = 0;
warn "Test Warning 1";
warn "Test Warning 2";
$x++;
1;
__END__

| expected e_op_action run phase warning
============================================================
* THERE WERE 2 WARNING(S) IN THE MARPA SEMANTICS:
Marpa treats warnings as fatal errors
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 3: F -> F MultOp F
* WARNING MESSAGE NUMBER 0:
Test Warning 1 at <LOCATION>
* WARNING MESSAGE NUMBER 1:
Test Warning 2 at <LOCATION>
Marpa::R2 exception at <LOCATION>
__END__

| expected default_action run phase warning
============================================================
* THERE WERE 2 WARNING(S) IN THE MARPA SEMANTICS:
Marpa treats warnings as fatal errors
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 8: trailer -> Text
* WARNING MESSAGE NUMBER 0:
Test Warning 1 at <LOCATION>
* WARNING MESSAGE NUMBER 1:
Test Warning 2 at <LOCATION>
Marpa::R2 exception at <LOCATION>
__END__

| bad code run phase error
# this should be a run phase error
my $x = 0;
$x = 711/0;
$x++;
1;
__END__

| expected e_op_action run phase error
============================================================
* THE MARPA SEMANTICS PRODUCED A FATAL ERROR
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 3: F -> F MultOp F
* THIS WAS THE FATAL ERROR MESSAGE:
Illegal division by zero at <LOCATION>
Marpa::R2 exception at <LOCATION>
__END__

| expected default_action run phase error
============================================================
* THE MARPA SEMANTICS PRODUCED A FATAL ERROR
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 8: trailer -> Text
* THIS WAS THE FATAL ERROR MESSAGE:
Illegal division by zero at <LOCATION>
Marpa::R2 exception at <LOCATION>
__END__

| bad code run phase die
# this is a call to die()
my $x = 0;
die 'test call to die';
$x++;
1;
__END__

| expected e_op_action run phase die
============================================================
* THE MARPA SEMANTICS PRODUCED A FATAL ERROR
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 3: F -> F MultOp F
* THIS WAS THE FATAL ERROR MESSAGE:
test call to die at <LOCATION>
Marpa::R2 exception at <LOCATION>
__END__

| expected default_action run phase die
============================================================
* THE MARPA SEMANTICS PRODUCED A FATAL ERROR
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 8: trailer -> Text
* THIS WAS THE FATAL ERROR MESSAGE:
test call to die at <LOCATION>
Marpa::R2 exception at <LOCATION>
__END__

END_OF_TEST_DATA

## no critic (InputOutput::RequireBriefOpen)
open my $test_data_fh, q{<}, \$test_data;
## use critic
LINE: while ( my $line = <$test_data_fh> ) {

    if ($getting_headers) {
        next LINE if $line =~ m/ \A \s* \Z/xms;
        if ( $line =~ s/ \A [|] \s+ //xms ) {
            chomp $line;
            push @headers, $line;
            next LINE;
        }
        else {
            $getting_headers = 0;
            $data            = q{};
        }
    } ## end if ($getting_headers)

    # getting data

    if ( $line =~ /\A__END__\Z/xms ) {
        HEADER: while ( my $header = pop @headers ) {
            if ( $header =~ s/\A expected \s //xms ) {
                my ( $feature, $test ) =
                    ( $header =~ m/\A (\S*) \s+ (.*) \Z/xms );
                die
                    "expected result given for unknown test, feature: $test, $feature"
                    if not defined $expected{$test}{$feature};
                $expected{$test}{$feature} = $data;
                next HEADER;
            } ## end if ( $header =~ s/\A expected \s //xms )
            if ( $header =~ s/\A good \s code \s //xms ) {
                die 'Good code should no longer be in data section';
            }
            if ( $header =~ s/\A bad \s code \s //xms ) {
                chomp $header;
                die "test code given for unknown test: $header"
                    if not defined $test_arg{$header};
                next HEADER;
            } ## end if ( $header =~ s/\A bad \s code \s //xms )
            die "Bad header: $header";
        }    # HEADER
        $getting_headers = 1;
        $data            = q{};
    }    # if $line

    $data .= $line;
} ## end LINE: while ( my $line = <$test_data_fh> )

sub canonical {
    my $template = shift;

    # allow for this test file to change name
    # as long as it remains lower-case, with
    # _ or -
    $template =~ s{
        \s at \s t[^.]+[.]t \s line \s \d+ [^\n]*
    }{ at <LOCATION>}gxms;
    return $template;
} ## end sub canonical

sub run_test {
    my $args = shift;

    my $e_op_action     = $good_code{e_op_action};
    my $e_pass_through  = $good_code{e_pass_through};
    my $e_number_action = $good_code{e_number_action};
    my $default_action  = $good_code{default_action};

    ### e_op_action default: $e_op_action
    ### e_number_action default: $e_number_action

    ARG: for my $arg ( keys %{$args} ) {
        my $value        = $args->{$arg};
        my $run_test_arg = lc $arg;
        if ( $run_test_arg eq 'e_op_action' ) {
            $e_op_action = $value;
            next ARG;
        }
        if ( $run_test_arg eq 'e_number_action' ) {
            $e_number_action = $value;
            next ARG;
        }
        if ( $run_test_arg eq 'default_action' ) {
            $default_action = $value;
            next ARG;
        }
        die "unknown argument to run_test: $arg";
    } ## end ARG: for my $arg ( keys %{$args} )

    ### e_op_action: $e_op_action
    ### e_number_action: $e_number_action

    my $grammar = Marpa::R2::Grammar->new(
        {   start => 'S',
            rules => [
                [ 'S', [qw/T trailer optional_trailer1 optional_trailer2/], ],
                [ 'T', [qw/T AddOp T/], $e_op_action, ],
                [ 'T', [qw/F/], $e_pass_through, ],
                [ 'F', [qw/F MultOp F/], $e_op_action, ],
                [ 'F', [qw/Number/], $e_number_action, ],
                [ 'optional_trailer1', [qw/trailer/], ],
                [ 'optional_trailer1', [], ],
                [ 'optional_trailer2', [], 'main::NULL_DESC' ],
                [ 'trailer',           [qw/Text/], ],
            ],
            default_action       => $default_action,
            default_empty_action => 'main::DEFAULT_NULL_DESC',
            terminals            => [qw(Number AddOp MultOp Text)],
        }
    );
    $grammar->precompute();

    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    $recce->read( Number => 2 );
    $recce->read( MultOp => q{*} );
    $recce->read( Number => 3 );
    $recce->read( AddOp  => q{+} );
    $recce->read( Number => 4 );
    $recce->read( MultOp => q{*} );
    $recce->read( Number => 1 );
    $recce->read( Text   => q{trailer} );

    $recce->end_input();

    my $expected  = '(((2*3)+(4*1))==10;trailer;[default null];[null])';
    my $value_ref = $recce->value();
    my $value     = $value_ref ? ${$value_ref} : 'No parse';
    Marpa::R2::Test::is( $value, $expected, 'Ambiguous Equation Value' );

    return 1;

}    # sub run_test

run_test( {} );

for my $test (@tests) {
    FEATURE: for my $feature (@features) {
        next FEATURE if not defined $expected{$test}{$feature};
        my $test_name = "$test in $feature";
        if ( eval { run_test( { $feature => $test_arg{$test}{$feature}, } ); }
            )
        {
            Test::More::fail(
                "$test_name did not fail -- that shouldn't happen");
        } ## end if ( eval { run_test( { $feature => $test_arg{$test}...})})
        else {
            my $eval_error = $EVAL_ERROR;
            Marpa::R2::Test::is( canonical($eval_error),
                $expected{$test}{$feature}, $test_name );
        }
    } ## end FEATURE: for my $feature (@features)
} ## end for my $test (@tests)

## no critic (Subroutines::RequireArgUnpacking)

sub e_pass_through {
    shift;
    return $_[0];
}

sub e_op_action {
    shift;
    my ( $right_string, $right_value ) = ( $_[2] =~ /^(.*)==(.*)$/xms );
    my ( $left_string,  $left_value )  = ( $_[0] =~ /^(.*)==(.*)$/xms );
    my $op = $_[1];
    my $value;
    if ( $op eq q{+} ) {
        $value = $left_value + $right_value;
    }
    elsif ( $op eq q{*} ) {
        $value = $left_value * $right_value;
    }
    elsif ( $op eq q{-} ) {
        $value = $left_value - $right_value;
    }
    else {
        die "Unknown op: $op";
    }
    return '(' . $left_string . $op . $right_string . ')==' . $value;
} ## end sub e_op_action

sub e_number_action {
    shift;
    my $v0 = pop @_;
    return $v0 . q{==} . $v0;
}

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . join( q{;}, ( map { $_ // 'undef' } @_ ) ) . ')';
} ## end sub default_action

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
