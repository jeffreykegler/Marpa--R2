#!perl
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
# Ensure various coding errors are caught

use 5.010;
use strict;
use warnings;

use Test::More tests => 8;

use lib 'tool/lib';
use Marpa::Test;
use English qw( -no_match_vars );

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

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

LINE: while ( my $line = <DATA> ) {

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
                    ( $header =~ m/\A ([^\s]*) \s+ (.*) \Z/xms );
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
} ## end while ( my $line = <DATA> )

sub canonical {
    my $template   = shift;
    my $where      = shift;
    my $long_where = shift;
    $long_where //= $where;
    $template =~ s{
            \b package \s
            Marpa [:][:] Internal [:][:] Recognizer [:][:]
            [EP] _ [0-9a-fA-F]+ [;] $
        }{package Marpa::<PACKAGE>;}xms;
    $template =~ s{ \s* at \s (\S*)code_diag[.]t \s line \s \d+}{}gxms;
    $template =~ s/[<]WHERE[>]/$where/xmsg;
    $template =~ s/[<]LONG_WHERE[>]/$long_where/xmsg;
    $template =~ s{ \s [<]DATA[>] \s line \s \d+
            }{ <DATA> line <LINE_NO>}xmsg;
    $template =~ s{
            \s at \s [(] eval \s \d+ [)] \s line \s
            }{ at (eval <LINE_NO>) line }xmsg;
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

    while ( my ( $arg, $value ) = each %{$args} ) {
        given ( lc $arg ) {
            when ('e_op_action')     { $e_op_action     = $value }
            when ('e_number_action') { $e_number_action = $value }
            when ('default_action')  { $default_action  = $value }
            default {
                die "unknown argument to run_test: $arg";
            };
        } ## end given
    } ## end while ( my ( $arg, $value ) = each %{$args} )

    ### e_op_action: $e_op_action
    ### e_number_action: $e_number_action

    my $grammar = Marpa::Grammar->new(
        {   start => 'S',
            rules => [
                [ 'S', [qw/T trailer optional_trailer1 optional_trailer2/], ],
                [ 'T', [qw/T AddOp T/], $e_op_action, ],
                [ 'T', [qw/F/], $e_pass_through, ],
                [ 'F', [qw/F MultOp F/], $e_op_action, ],
                [ 'F', [qw/Number/], $e_number_action, ],
                [ 'optional_trailer1', [qw/trailer/], ],
                [ 'optional_trailer1', [], ],
                [ 'optional_trailer2', [], ],
                [ 'trailer',           [qw/Text/], ],
            ],
            default_action     => $default_action,
            default_null_value => '[default null]',
            symbols   => { optional_trailer2 => { null_value => '[null]' } },
            terminals => [qw(Number AddOp MultOp Text)],
        }
    );
    $grammar->precompute();

    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );

    my @tokens = (
        [ Number => 2 ],
        [ MultOp => q{*} ],
        [ Number => 3 ],
        [ AddOp  => q{+} ],
        [ Number => 4 ],
        [ MultOp => q{*} ],
        [ Number => 1 ],
        [ Text   => q{trailer} ],
    );

    if ( not defined $recce->tokens( \@tokens ) ) {
        die 'Recognition failed';
    }

    $recce->end_input();

    my $expected  = '(((2*3)+(4*1))==10;trailer;[default null];[null])';
    my $value_ref = $recce->value();
    my $value     = $value_ref ? ${$value_ref} : 'No parse';
    Marpa::Test::is( $value, $expected, 'Ambiguous Equation Value' );

    return 1;

}    # sub run_test

run_test( {} );

my %where = (
    e_op_action    => 'running action',
    default_action => 'running action',
);

my %long_where = (
    e_op_action    => 'running action for 1: E -> E Op E',
    default_action => 'running action for 3: optional_trailer1 -> trailer',
);

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
            my $where      = $where{$feature};
            my $long_where = $long_where{$feature};
            Marpa::Test::is(
                canonical( $eval_error,                $where, $long_where ),
                canonical( $expected{$test}{$feature}, $where, $long_where ),
                $test_name
            );
        } ## end else [ if ( eval { run_test( { $feature => $test_arg{$test}...})})]
    } ## end for my $feature (@features)
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

## use critic

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

__DATA__

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
Test Warning 1, <DATA> line <LINE_NO>.
* WARNING MESSAGE NUMBER 1:
Test Warning 2, <DATA> line <LINE_NO>.
* ONE PLACE TO LOOK FOR THE PROBLEM IS IN THE CODE
__END__

| expected default_action run phase warning
============================================================
* THERE WERE 2 WARNING(S) IN THE MARPA SEMANTICS:
Marpa treats warnings as fatal errors
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 8: trailer -> Text
* WARNING MESSAGE NUMBER 0:
Test Warning 1, <DATA> line <LINE_NO>.
* WARNING MESSAGE NUMBER 1:
Test Warning 2, <DATA> line <LINE_NO>.
* ONE PLACE TO LOOK FOR THE PROBLEM IS IN THE CODE
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
Illegal division by zero, <DATA> line <LINE_NO>.
* ONE PLACE TO LOOK FOR THE PROBLEM IS IN THE CODE
__END__

| expected default_action run phase error
============================================================
* THE MARPA SEMANTICS PRODUCED A FATAL ERROR
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 8: trailer -> Text
* THIS WAS THE FATAL ERROR MESSAGE:
Illegal division by zero, <DATA> line <LINE_NO>.
* ONE PLACE TO LOOK FOR THE PROBLEM IS IN THE CODE
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
test call to die, <DATA> line <LINE_NO>.
* ONE PLACE TO LOOK FOR THE PROBLEM IS IN THE CODE
__END__

| expected default_action run phase die
============================================================
* THE MARPA SEMANTICS PRODUCED A FATAL ERROR
* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:
Computing value for rule: 8: trailer -> Text
* THIS WAS THE FATAL ERROR MESSAGE:
test call to die, <DATA> line <LINE_NO>.
* ONE PLACE TO LOOK FOR THE PROBLEM IS IN THE CODE
__END__

