#!perl
# Copyright 2022 Jeffrey Kegler
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

use Getopt::Long;
use Marpa::R2 2.019_000;

my $do_demo = 0;
my $getopt_result = GetOptions( "demo!" => \$do_demo, );

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
$PROGRAM_NAME --demo
$PROGRAM_NAME 'exp' [...]

Run $PROGRAM_NAME with either the "--demo" argument
or a series of calculator expressions.
END_OF_USAGE_MESSAGE
} ## end sub usage

if ( not $getopt_result ) {
    usage();
}
if ($do_demo) {
    if ( scalar @ARGV > 0 ) { say join " ", @ARGV; usage(); }
}
elsif ( scalar @ARGV <= 0 ) { usage(); }

my $rules = Marpa::Demo::OP3::parse_rules(
    <<'END_OF_GRAMMAR'
<reduce op> ::=
    '+' => do_arg0
  | '-' => do_arg0
  | '/' => do_arg0
  | '*' => do_arg0
<script> ::= <e> => do_arg0
<script> ::= <script> ';' <e> => do_arg2
<e> ::=
     <NUM> => do_arg0
   | <VAR> => do_is_var
   | :group '(' <e> ')' => do_arg1
  || '-' <e> => do_negate
  || :right <e> '^' <e> => do_binop
  || <e> '*' <e> => do_binop
   | <e> '/' <e> => do_binop
  || <e> '+' <e> => do_binop
   | <e> '-' <e> => do_binop
  || <e> ',' <e> => do_array
  || <reduce     op> 'reduce' <e> => do_reduce
  || <VAR> '=' <e> => do_set_var
END_OF_GRAMMAR
);

my $grammar = Marpa::R2::Grammar->new(
    {   start          => '<script>',
        actions        => __PACKAGE__,
    }
);
$grammar->symbol_reserved_set( '>', 0 );
$grammar->set( { rules          => $rules });
$grammar->precompute;

# Order matters !!
my @terminals = (
    [ q{'reduce'}, qr/reduce\b/xms ],
    [ '<NUM>',       qr/\d+/xms ],
    [ '<VAR>',       qr/\w+/xms ],
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

my $output = join q{},
    report_calculation('4 * 3 + 42 / 1'),
    report_calculation('4 * 3 / (a = b = 5) + 42 - 1'),
    report_calculation('4 * 3 /  5 - - - 3 + 42 - 1'),
    report_calculation('a=1;b = 5;  - a - b'),
    report_calculation('1 * 2 + 3 * 4 ^ 2 ^ 2 ^ 2 * 42 + 1'),
    report_calculation('+ reduce 1 + 2, 3,4*2 , 5');

print $output or die "print failed: $ERRNO";
$output eq <<'EXPECTED_OUTPUT' or die 'FAIL: Output mismatch';
Input: "4 * 3 + 42 / 1"
  Parse: 54
Input: "4 * 3 / (a = b = 5) + 42 - 1"
  Parse: 43.4
"a" = "5"
"b" = "5"
Input: "4 * 3 /  5 - - - 3 + 42 - 1"
  Parse: 40.4
Input: "a=1;b = 5;  - a - b"
  Parse: -6
"a" = "1"
"b" = "5"
Input: "1 * 2 + 3 * 4 ^ 2 ^ 2 ^ 2 * 42 + 1"
  Parse: 541165879299
Input: "+ reduce 1 + 2, 3,4*2 , 5"
  Parse: 19
EXPECTED_OUTPUT

# The code from this point on is yet another DSL --
# the one that specified OP3, the language in
# which the rules for the first were expressed.

package Marpa::Demo::OP3;

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Marpa::R2;

sub do_arg0 { return $_[1]; }

sub do_rules {
    shift;
    return [ map { @{$_} } @_ ];
}

sub do_priority_rule {
    my ( undef, $lhs, undef, $priorities ) = @_;
    my $priority_count = scalar @{$priorities};
    my @rules          = ();
    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        for my $alternative ( @{ $priorities->[$priority_ix] } ) {
            push @rules, [ $priority, @{$alternative} ];
        }
    } ## end for my $priority_ix ( 0 .. $priority_count - 1 )
    if ( scalar @rules <= 1 ) {

        # If there is only one rule,
        my ( $priority, $assoc, $rhs, $action ) = @{ $rules[0] };
        my @action_kv;
        push @action_kv, action => $action if defined $action;
        return [ { lhs => $lhs, rhs => $rhs, @action_kv } ];
    } ## end if ( scalar @rules <= 1 )
    my $do_arg0_full_name = __PACKAGE__ . q{::} . 'do_arg0';
    my @xs_rules = (
        {   lhs    => $lhs,
            rhs    => [ $lhs . '_0' ],
            action => $do_arg0_full_name
        },
        (   map {
                ;
                {   lhs => ( $lhs . '_' . ( $_ - 1 ) ),
                    rhs => [ $lhs . '_' . ($_) ],
                    action => $do_arg0_full_name
                }
            } 1 .. $priority_count - 1
        )
    );
    RULE: for my $rule (@rules) {
        my ( $priority, $assoc, $rhs, $action ) = @{$rule};
        my @action_kv = ();
        push @action_kv, action => $action if defined $action;
        my @new_rhs       = @{$rhs};
        my @arity         = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $length        = scalar @{$rhs};
        my $current_exp   = $lhs . '_' . $priority;
        my $next_priority = $priority + 1;
        $next_priority = 0 if $next_priority >= $priority_count;
        my $next_exp = $lhs . '_' . $next_priority;

        if ( not scalar @arity ) {
            push @xs_rules,
                {
                lhs => $current_exp,
                rhs => \@new_rhs,
                @action_kv
                };
            next RULE;
        } ## end if ( not scalar @arity )

        if ( scalar @arity == 1 ) {
            die 'Unnecessary unit rule in priority rule' if $length == 1;
            $new_rhs[ $arity[0] ] = $current_exp;
        }
        DO_ASSOCIATION: {
            if ( $assoc eq 'L' ) {
                $new_rhs[ $arity[0] ] = $current_exp;
                for my $rhs_ix ( @arity[ 1 .. $#arity ] ) {
                    $new_rhs[$rhs_ix] = $next_exp;
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'L' )
            if ( $assoc eq 'R' ) {
                $new_rhs[ $arity[-1] ] = $current_exp;
                for my $rhs_ix ( @arity[ 0 .. $#arity - 1 ] ) {
                    $new_rhs[$rhs_ix] = $next_exp;
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'R' )
            if ( $assoc eq 'G' ) {
                for my $rhs_ix ( @arity[ 0 .. $#arity ] ) {
                    $new_rhs[$rhs_ix] = $lhs . '_0';
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'G' )
            die qq{Unknown association type: "$assoc"};
        } ## end DO_ASSOCIATION:
        push @xs_rules, { lhs => $current_exp, rhs => \@new_rhs, @action_kv };
    } ## end RULE: for my $rule (@rules)
    return [@xs_rules];
} ## end sub do_priority_rule

sub do_empty_rule {
    my ( undef, $lhs, undef, $action ) = @_;
    return [ { lhs => $lhs, rhs => [], @{ $action || [] } } ];
}

sub do_quantified_rule {
    my ( undef, $lhs, undef, $rhs, $quantifier, $action ) = @_;
    my @action_kv;
    push @action_kv, action => $action if defined $action;
    return [
        {   lhs => $lhs,
            rhs => [$rhs],
            min => ( $quantifier eq q{+} ? 1 : 0 ),
            @action_kv
        }
    ];
} ## end sub do_quantified_rule

sub do_simple_rule {
    shift;
    return {
        @{ $_[0] },
        rhs => [ $_[2] ],
        @{ $_[3] || [] }
    };
} ## end sub do_simple_rule

sub do_priority1 {
    shift;
    return [ $_[0] ];
}

sub do_priority3 {
    shift;
    return [ $_[0], @{ $_[2] } ];
}
sub do_full_alternative { shift; return [ ( $_[0] // 'L' ), $_[1], $_[2] ]; }
sub do_bare_alternative { shift; return [ ( $_[0] // 'L' ), $_[1], undef ] }

sub do_alternatives_1 {
    shift;
    return [ $_[0] ];
}

sub do_alternatives_3 {
    shift;
    return [ $_[0], @{ $_[2] } ];
}
sub do_lhs { shift; return $_[0]; }
sub do_array { shift; return [@_]; }
sub do_arg1         { return $_[2]; }
sub do_right_adverb { return 'R' }
sub do_left_adverb  { return 'L' }
sub do_group_adverb { return 'G' }

sub do_what_I_mean {

    # The first argument is the per-parse variable.
    # Until we know what to do with it, just throw it away
    shift;

    # Throw away any undef's
    my @children = grep {defined} @_;

    # Return what's left
    return scalar @children > 1 ? \@children : shift @children;
} ## end sub do_what_I_mean

sub parse_rules {
    my ($string) = @_;

    my $grammar = Marpa::R2::Grammar->new(
        {   start          => 'rules',
            actions        => __PACKAGE__,
            default_action => 'do_what_I_mean',
            rules          => [
                {   lhs    => 'rules',
                    rhs    => [qw/rule/],
                    action => 'do_rules',
                    min    => 1
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare priorities/],
                    action => 'do_priority_rule'
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare action/],
                    action => 'do_empty_rule'
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare name quantifier action/],
                    action => 'do_quantified_rule'
                },

                {   lhs    => 'priorities',
                    rhs    => [qw(alternatives)],
                    action => 'do_priority1'
                },
                {   lhs    => 'priorities',
                    rhs    => [qw(alternatives op_tighter priorities)],
                    action => 'do_priority3'
                },

                {   lhs    => 'alternatives',
                    rhs    => [qw(alternative)],
                    action => 'do_alternatives_1',
                },
                {   lhs    => 'alternatives',
                    rhs    => [qw(alternative op_eq_pri alternatives)],
                    action => 'do_alternatives_3',
                },

                {   lhs    => 'alternative',
                    rhs    => [qw(adverb rhs action)],
                    action => 'do_full_alternative'
                },
                {   lhs    => 'alternative',
                    rhs    => [qw(adverb rhs)],
                    action => 'do_bare_alternative'
                },

                {   lhs    => 'adverb',
                    rhs    => [qw/op_group/],
                    action => 'do_group_adverb'
                },
                {   lhs    => 'adverb',
                    rhs    => [qw/op_right/],
                    action => 'do_right_adverb'
                },
                {   lhs    => 'adverb',
                    rhs    => [qw/op_left/],
                    action => 'do_left_adverb'
                },
                { lhs => 'adverb', rhs => [] },

                { lhs => 'action', rhs => [] },
                {   lhs    => 'action',
                    rhs    => [qw/op_arrow action_name/],
                    action => 'do_arg1'
                },

                { lhs => 'lhs', rhs => [qw/name/], action => 'do_lhs' },

                { lhs => 'rhs',        rhs => [qw/names/] },
                { lhs => 'quantifier', rhs => [qw/op_plus/] },
                { lhs => 'quantifier', rhs => [qw/op_star/] },

                {   lhs    => 'names',
                    rhs    => [qw/name/],
                    min    => 1,
                    action => 'do_array'
                },
            ],
        }
    );
    $grammar->precompute;

    my $rec = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    # Order matters !!!
    my @terminals = (
        [ 'op_right',      qr/:right\b/xms ],
        [ 'op_left',       qr/:left\b/xms ],
        [ 'op_group',      qr/:group\b/xms ],
        [ 'op_declare',    qr/::=/xms ],
        [ 'op_arrow',      qr/=>/xms ],
        [ 'op_tighter',    qr/[|][|]/xms ],
        [ 'op_eq_pri',     qr/[|]/xms ],
        [ 'reserved_name', qr/(::(whatever|undef))/xms ],
        [ 'op_plus',       qr/[+]/xms ],
        [ 'op_star',       qr/[*]/xms ],
        [ 'action_name',          qr/ \w+ /xms ],
        [ 'name',          qr/[<] [\w] [\w ]* [>]/xms ],
        [ 'name',          qr/['][^']+[']/xms ],
    );

    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;
            my $token_value = $1;
            if ( $t->[0] eq 'name' ) {

                # normalize spaces
                $token_value =~ s/ [ ]+ / /xmsg;
                $token_value =~ s/ [ ]* \z //xms;
            } ## end if ( $t->[0] eq 'name' )
            if ( not defined $rec->read( $t->[0], $token_value ) ) {
                die die q{Problem before position }, pos $string, ': ',
                    ( substr $string, pos $string, 40 ),
                    qq{\nToken rejected, "}, $t->[0], qq{", "$token_value"},
                    ;
            } ## end if ( not defined $rec->read( $t->[0], $token_value ))
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{OP: No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    my $parse_ref = $rec->value;

    if ( !defined $parse_ref ) {
        say $rec->show_progress() or die "say failed: $ERRNO";
        die 'Parse failed';
    }
    my $parse = ${$parse_ref};

    return $parse;
} ## end sub parse_rules

