#!/usr/bin/perl
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

# Engine Synopsis

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Getopt::Long;

use Marpa::R2 2.027_003;

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

my $string = '42*1+7';
if (!$do_demo) {
$string = shift;
}

my $grammar = Marpa::R2::Grammar->new(
    {   scannerless => 1,
        action_object        => 'My_Actions',
        default_action => 'first_arg',
        rules          => <<'END_OF_GRAMMAR',

:start ::= Expression
Expression ::=
       Number
    || Expression '*' Expression action => do_multiply
     | Expression '+' Expression action => do_add
Number ~ digits '.' digits action => do_literal
Number ~ digits action => do_literal
digits ~ [\d]+
END_OF_GRAMMAR
    }
);

$grammar->precompute();

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

my $self = bless { grammar => $grammar }, 'My_Error';
$self->{recce} = $recce;
local $My_Actions::SELF = $self;

my $event_count;
if ( not defined eval { $event_count = $recce->sl_read($string); 1 } ) {
    ## Add last expression found, and rethrow
    my $eval_error = $EVAL_ERROR;
    chomp $eval_error;
    die $self->show_last_expression(), "\n", $eval_error, "\n";
} ## end if ( not defined eval { $event_count = $recce->sl_read...})

if ( not defined $event_count ) {
    die $self->show_last_expression(), "\n", $recce->sl_error();
}
my $value_ref = $recce->value;
if ( not defined $value_ref ) {
    die $self->show_last_expression(), "\n",
        "No parse was found, after reading the entire input\n";
}

say "Value = ", ${$value_ref};
exit 0;

package My_Error;

sub My_Error::last_completed_range {
    my ( $self, $symbol_name ) = @_;
    my $grammar      = $self->{grammar};
    my $recce        = $self->{recce};
    my @sought_rules = ();
    for my $rule_id ( $grammar->rule_ids() ) {
        my ($lhs) = $grammar->bnf_rule($rule_id);
        push @sought_rules, $rule_id if $lhs eq $symbol_name;
    }
    die "Looking for completion of non-existent rule lhs: $symbol_name"
        if not scalar @sought_rules;
    my $latest_earley_set = $recce->latest_earley_set();
    my $earley_set        = $latest_earley_set;

    # Initialize to one past the end, so we can tell if there were no hits
    my $first_origin = $latest_earley_set + 1;
    EARLEY_SET: while ( $earley_set >= 0 ) {
        my $report_items = $recce->progress($earley_set);
        ITEM: for my $report_item ( @{$report_items} ) {
            my ( $rule_id, $dot_position, $origin ) = @{$report_item};
            next ITEM if $dot_position != -1;
            next ITEM if not scalar grep { $_ == $rule_id } @sought_rules;
            next ITEM if $origin >= $first_origin;
            $first_origin = $origin;
        } ## end ITEM: for my $report_item ( @{$report_items} )
        last EARLEY_SET if $first_origin <= $latest_earley_set;
        $earley_set--;
    } ## end EARLEY_SET: while ( $earley_set >= 0 )
    return if $earley_set < 0;
    return ( $first_origin, $earley_set );
} ## end sub My_Error::last_completed_range

sub My_Error::show_last_expression {
    my ($self) = @_;
    my ( $start, $end ) = $self->last_completed_range('Expression');
    return 'No expression was successfully parsed' if not defined $start;
    my $last_expression = $self->{recce}->sl_range_to_string( $start, $end );
    return "Last expression successfully parsed was: $last_expression";
} ## end sub My_Error::show_last_expression

package My_Actions;
our $SELF;
sub new { return $SELF }

sub My_Actions::do_add {
    my ( undef, $t1, $t2 ) = @_;
    return $t1 + $t2;
}

sub My_Actions::do_multiply {
    my ( undef, $t1, $t2 ) = @_;
    return $t1 * $t2;
}

sub My_Actions::do_literal {
    my $self  = shift;
    my $recce = $self->{recce};
    my ( $start, $end ) = Marpa::R2::Context::location();
    my $literal = $recce->sl_range_to_string( $start, $end );
    $literal =~ s/ \s+ \z //xms;
    $literal =~ s/ \A \s+ //xms;
    return $literal;
} ## end sub do_literal

sub My_Actions::first_arg { shift; return shift; }


# vim: expandtab shiftwidth=4:
