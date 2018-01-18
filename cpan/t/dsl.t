#!perl
# Copyright 2018 Jeffrey Kegler
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

use 5.010001;
use strict;
use warnings;

use English qw( -no_match_vars );
use Test::More tests => 6;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $source = <<'END_OF_GRAMMAR';
:start ::= script
reduce_op ::=
    op_plus action => do_arg0
  | op_minus action => do_arg0
  | op_divide action => do_arg0
  | op_star action => do_arg0
script ::= e action => do_arg0
script ::= script op_semicolon e action => do_arg2
e ::=
     NUM action => do_arg0
   | VAR action => do_is_var
   | op_lparen e op_rparen action => do_arg1 assoc => group
  || op_minus e action => do_negate
  || e op_caret e action => do_power assoc => right
  || e op_star e action => do_multiply
   | e op_divide e action => do_divide
  || e op_plus e action => do_addition
   | e op_minus e action => do_subtract
  || e op_comma e action => do_array
  || reduce_op op_reduce e action => do_reduce
  || VAR op_assign e action => do_set_var
END_OF_GRAMMAR

my $grammar = Marpa::R2::Grammar->new(
    {   
        actions        => __PACKAGE__,
        source          => \$source,
    }
);
$grammar->precompute;

# Order matters !!
my @terminals = (
    [ op_reduce     => qr/reduce\b/xms ],
    [ NUM           => qr/\d+/xms ],
    [ VAR           => qr/\w+/xms ],
    [ op_assign     => qr/[=]/xms ],
    [ op_semicolon => qr/[;]/xms ],
    [ op_star       => qr/[*]/xms ],
    [ op_divide     => qr/[\/]/xms ],
    [ op_plus       => qr/[+]/xms ],
    [ op_minus      => qr/[-]/xms ],
    [ op_caret      => qr/[\^]/xms ],
    [ op_lparen     => qr/[(]/xms ],
    [ op_rparen     => qr/[)]/xms ],
    [ op_comma      => qr/[,]/xms ],
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

sub do_power { my ( undef, $left, undef, $right ) = @_; return $left**$right; }
sub do_multiply { my ( undef, $left, undef, $right ) = @_; return $left*$right; }
sub do_divide { my ( undef, $left, undef, $right ) = @_; return $left/$right; }
sub do_addition { my ( undef, $left, undef, $right ) = @_; return $left+$right; }
sub do_subtract { my ( undef, $left, undef, $right ) = @_; return $left-$right; }

my %binop_closure = (
    '*' => \&do_multiply,
    '/' => \&do_divide,
    '+' => \&do_addition,
    '-' => \&do_subtract,
    '^' => \&do_power,
);

sub do_reduce {
    my ( undef, $op, undef, $args ) = @_;
    my $closure = $binop_closure{$op};
    die qq{Do not know how to perform binary operation "$op"}
        if not defined $closure;
    $args = [$args] if ref $args eq '';
    my @stack = @{$args};
    OP: while (1) {
        return $stack[0] if scalar @stack <= 1;
        my $result = $closure->( undef, $stack[-2], undef, $stack[-1] );
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

sub calculate {
    my ($string) = @_;

    %symbol_table = ();

    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    my $length = length $string;
    my $last_position = 0;
    pos $string = $last_position;
    TOKEN: while ( 1 ) {

        $last_position = pos $string;
        last TOKEN if $last_position >= $length;

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;
            my $token_value = $1;
            next TOKEN if defined $recce->read( $t->[0], $token_value );
            # say STDERR $recce->show_progress() or die "say failed: $ERRNO";
            die q{Token rejected, "}, $t->[0], qq{", "$token_value"\n},
                qq{Problem near position $last_position: "},
                ( substr $string, $last_position, 40 ), "\n";
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    my $value_ref = $recce->value;

    if ( !defined $value_ref ) {
        say $recce->show_progress() or die "say failed: $ERRNO";
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
