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

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Test::More tests => 6;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $rules = <<'END_OF_GRAMMAR';
reduce_op ::=
    '+' action => do_arg0
  | '-' action => do_arg0
  | '/' action => do_arg0
  | '*' action => do_arg0
script ::= e action => do_arg0
script ::= script ';' e action => do_arg2
e ::=
     NUM action => do_arg0
   | VAR action => do_is_var
   | '(' e ')' action => do_arg1 assoc => group
  || '-' e action => do_negate
  || e '^' e action => do_binop assoc => right
  || e '*' e action => do_binop
   | e '/' e action => do_binop
  || e '+' e action => do_binop
   | e '-' e action => do_binop
  || e ',' e action => do_array
  || reduce_op 'reduce' e action => do_reduce
  || VAR '=' e action => do_set_var
END_OF_GRAMMAR

my $grammar = Marpa::R2::Grammar->new(
    {   start          => 'script',
        actions        => __PACKAGE__,
        rules          => [$rules],
    }
);
$grammar->precompute;

# Order matters !!
my @terminals = (
    [ q{'reduce'}, qr/reduce\b/xms ],
    [ 'NUM',       qr/\d+/xms ],
    [ 'VAR',       qr/\w+/xms ],
    [ q{'='},      qr/[=]/xms ],
    [ q{';'},      qr/[;]/xms ],
    [ q{'*'},      qr/[*]/xms ],
    [ q{'/'},      qr/[\/]/xms ],
    [ q{'+'},      qr/[+]/xms ],
    [ q{'-'},      qr/[-]/xms ],
    [ q{'^'},      qr/[\^]/xms ],
    [ q{'('},      qr/[(]/xms ],
    [ q{')'},      qr/[)]/xms ],
    [ q{','},      qr/[,]/xms ],
);

our $DEBUG = 1;

my %binop_closure = (
    '*' => sub { $_[0] * $_[1] },
    '/' => sub { $_[0] / $_[1] },
    '+' => sub { $_[0] + $_[1] },
    '-' => sub { $_[0] - $_[1] },
    '^' => sub { $_[0]**$_[1] },
);

my %symbol_table = ();

sub do_is_var {
    my ( undef, $var ) = @_;
    my $value = $symbol_table{$var};
    die qq{Undefined variable "$var"} if not defined $value;
    return $value;
} ## end sub do_is_var

sub do_set_var {
    my ( undef, $var, undef, $value ) = @_;
    return $symbol_table{$var} = $value;
}

sub do_negate {
    return -$_[2];
}

sub do_arg0 { return $_[1]; }
sub do_arg1 { return $_[2]; }
sub do_arg2 { return $_[3]; }

sub do_array {
    my ( undef, $left, undef, $right ) = @_;
    my @value = ();
    my $ref;
    if ( $ref = ref $left ) {
        die "Bad ref type for array operand: $ref" if $ref ne 'ARRAY';
        push @value, @{$left};
    }
    else {
        push @value, $left;
    }
    if ( $ref = ref $right ) {
        die "Bad ref type for array operand: $ref" if $ref ne 'ARRAY';
        push @value, @{$right};
    }
    else {
        push @value, $right;
    }
    return \@value;
} ## end sub do_array

sub do_binop {
    my ( undef, $left, $op, $right ) = @_;

    # goto &add_brackets if $DEBUG;
    my $closure = $binop_closure{$op};
    die qq{Do not know how to perform binary operation "$op"}
        if not defined $closure;
    return $closure->( $left, $right );
} ## end sub do_binop

sub do_reduce {
    my ( undef, $op, undef, $args ) = @_;
    my $closure = $binop_closure{$op};
    die qq{Do not know how to perform binary operation "$op"}
        if not defined $closure;
    $args = [$args] if ref $args eq '';
    my @stack = @{$args};
    OP: while (1) {
        return $stack[0] if scalar @stack <= 1;
        my $result = $closure->( $stack[-2], $stack[-1] );
        splice @stack, -2, 2, $result;
    }
    die;    # Should not get here
} ## end sub do_reduce

# For debugging
sub add_brackets {
    my ( undef, @children ) = @_;
    return $children[0] if 1 == scalar @children;
    my $original = join q{}, grep {defined} @children;
    return '[' . $original . ']';
} ## end sub add_brackets

sub die_on_read_problem {
    my ( $rec, $t, $token_value, $string, $position ) = @_;
    say $rec->show_progress() or die "say failed: $ERRNO";
    my $problem_position = $position - length $1;
    my $before_start     = $problem_position - 40;
    $before_start = 0 if $before_start < 0;
    my $before_length = $problem_position - $before_start;
    die "Problem near position $problem_position\n",
        q{Problem is here: "},
        ( substr $string, $before_start, $before_length + 40 ),
        qq{"\n},
        ( q{ } x ( $before_length + 18 ) ), qq{^\n},
        q{Token rejected, "}, $t->[0], qq{", "$token_value"},
        ;
} ## end sub die_on_read_problem

sub calculate {
    my ($string) = @_;

    %symbol_table = ();

    my $rec = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;
            if ( not defined $rec->read( $t->[0], $1 ) ) {
                die_on_read_problem( $rec, $t, $1, $string, pos $string );
            }
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    my $value_ref = $rec->value;

    if ( !defined $value_ref ) {
        say $rec->show_progress() or die "say failed: $ERRNO";
        die 'Parse failed';
    }
    return ${$value_ref};

} ## end sub calculate

sub report_calculation {
    my ($string) = @_;
    my $output   = qq{Input: "$string"\n};
    my $result   = calculate($string);
    $result = join q{,}, @{$result} if ref $result eq 'ARRAY';
    $output .= "  Parse: $result\n";
    for my $symbol ( sort keys %symbol_table ) {
        $output .= qq{"$symbol" = "} . $symbol_table{$symbol} . qq{"\n};
    }
    return $output;
} ## end sub report_calculation

if (@ARGV) {
    my $result = calculate( join ';', grep {/\S/} @ARGV );
    $result = join q{,}, @{$result} if ref $result eq 'ARRAY';
    say "Result is ", $result;
    for my $symbol ( sort keys %symbol_table ) {
        say qq{"$symbol" = "} . $symbol_table{$symbol} . qq{"};
    }
    exit 0;
} ## end if (@ARGV)

my @tests = (
    [ '4 * 3 + 42 / 1', <<'END_OF_OUTPUT'],
Input: "4 * 3 + 42 / 1"
  Parse: 54
END_OF_OUTPUT
    [ '4 * 3 / (a = b = 5) + 42 - 1', <<'END_OF_OUTPUT'],
Input: "4 * 3 / (a = b = 5) + 42 - 1"
  Parse: 43.4
"a" = "5"
"b" = "5"
END_OF_OUTPUT
    [ '4 * 3 /  5 - - - 3 + 42 - 1', <<'END_OF_OUTPUT'],
Input: "4 * 3 /  5 - - - 3 + 42 - 1"
  Parse: 40.4
END_OF_OUTPUT
    [ 'a=1;b = 5;  - a - b', <<'END_OF_OUTPUT'],
Input: "a=1;b = 5;  - a - b"
  Parse: -6
"a" = "1"
"b" = "5"
END_OF_OUTPUT
    [ '1 * 2 + 3 * 4 ^ 2 ^ 2 ^ 2 * 42 + 1', <<'END_OF_OUTPUT'],
Input: "1 * 2 + 3 * 4 ^ 2 ^ 2 ^ 2 * 42 + 1"
  Parse: 541165879299
END_OF_OUTPUT
    ['+ reduce 1 + 2, 3,4*2 , 5', <<'END_OF_OUTPUT'],
Input: "+ reduce 1 + 2, 3,4*2 , 5"
  Parse: 19
END_OF_OUTPUT
);

for my $test (@tests) {
    my ( $input, $expected_output ) = @{$test};
    my $actual_output = report_calculation($input);
    Marpa::R2::Test::is( $actual_output, $expected_output,
        qq{Parsing "$input"} );
} ## end for my $test (@tests)

# vim: expandtab shiftwidth=4:
