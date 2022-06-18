#!/usr/bin/perl
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

use Marpa::R2 2.027_003;

our $ORIGIN;

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
$PROGRAM_NAME [-n] 'exp'
$PROGRAM_NAME [-n] < file
END_OF_USAGE_MESSAGE
} ## end sub usage

my $show_position_flag;
my $quiet_flag;
my $trace_level = 0;
my $getopt_result = Getopt::Long::GetOptions(
    'n!' => \$show_position_flag,
    'trace_level=i' => \$trace_level,
    'q!' => \$quiet_flag,
);
usage() if not $getopt_result;

my $string = do { local $INPUT_RECORD_SEPARATOR = undef; <> };

my $perl_grammar = Marpa::R2::Grammar->new(
    {   scannerless => 1,
        action_object        => 'My_Actions',
        default_action => 'do_what_I_mean',
        rules          => [ <<'END_OF_RULES' ]
:start ~ start
start ~ (prefix) target
prefix ~ any_char*
any_char ~ :any
target ~ expression action => do_target
expression ::=
     number
   | scalar
   | op_lparen expression op_rparen assoc => group
  || '--' expression action => do_predecrement
   | '++' expression action => do_preincrement
   | expression '--' action => do_postdecrement
   | expression '++' action => do_postincrement
  || expression '**' expression assoc => right action => do_power
  || '-' expression action => do_uminus
   | '+' expression action => do_uplus
   | '!' expression action => do_bang
   | '~' expression action => do_tilde
  || expression '*' expression action => do_multiply
   | expression '/' expression action => do_divide
   | expression '%' expression action => do_modulo
   | expression 'x' expression action => do_x_op
  || expression '+' expression action => do_add
   | expression '-' expression action => do_subtract
  || expression '<<' expression action => do_lshift
   | expression '>>' expression action => do_rshift
  || expression '&' expression action => do_bitand
  || expression '|' expression action => do_bitor
   | expression '^' expression action => do_bitxor
  || expression '=' expression assoc => right action => do_assign
  || expression ',' expression action => do_comma
optional_digits ~ [\d]*
digits ~ [\d]+
number ~ digits action => do_literal
number ~ digits [.] digits action => do_literal
bare_word ~ [\w]+
scalar ~ '$' bare_word action => do_literal
END_OF_RULES
    }
);

$perl_grammar->precompute();

sub My_Error::last_completed_range {
    my ( $self, $symbol_name, $latest_earley_set ) = @_;
    my $grammar      = $self->{grammar};
    my $recce        = $self->{recce};
    my @sought_rules = ();
    for my $rule_id ( $grammar->rule_ids() ) {
        my ($lhs) = $grammar->bnf_rule($rule_id);
        push @sought_rules, $rule_id if $lhs eq $symbol_name;
    }
    die "Looking for completion of non-existent rule lhs: $symbol_name"
        if not scalar @sought_rules;
    $latest_earley_set //= $recce->latest_earley_set();
    my $earley_set = $latest_earley_set;

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

my $recce = Marpa::R2::Recognizer->new( { grammar => $perl_grammar } );

# A quasi-object, for internal use only
my $self = bless {
    grammar   => $perl_grammar,
    input     => \$string,
    recce     => $recce,
    },
    'My_Error';

local $My_Actions::SELF = $self;
my $event_count;

$recce->sl_trace($trace_level) if $trace_level;
for my $char (split //, $string) {
if ( not defined eval { $event_count = $recce->sl_read($char); 1 } ) {

    # Add last expression found, and rethrow
    my $eval_error = $EVAL_ERROR;
    chomp $eval_error;
    die "\n", $eval_error, "\n";
} ## end if ( not defined eval { $event_count = $recce->sl_read...})
if ( not defined $event_count ) {
    die "\n", $recce->sl_error();
}
say "Size=", $recce->earley_set_size();
}

# Given a string, an earley set to position mapping,
# and two earley sets, return the slice of the string
sub My_Error::input_slice {
    my ( $self, $start, $end ) = @_;
    return if not defined $start;
    return substr ${ $self->{input} }, $start, $end - $start;
}

my $end_of_search;
my @results = ();
RESULTS: while (1) {
    my ( $origin, $end ) =
        $self->last_completed_range( 'target', $end_of_search );
    last RESULTS if not defined $origin;
    push @results, [ $origin, $end ];
    $end_of_search = $origin;
} ## end RESULTS: while (1)

RESULT: for my $result ( reverse @results ) {
    my ( $origin, $end ) = @{$result};
    my $slice = $self->input_slice( $origin, $end );
    $slice =~ s/ \A \s* //xms;
    $slice =~ s/ \s* \z //xms;
    $slice =~ s/ \n / /gxms;
    $slice =~ s/ \s+ / /gxms;
    print qq{$origin-$end: }
        or die "print() failed: $ERRNO"
        if $show_position_flag;
    say $slice or die "say failed: $ERRNO";
    $recce->set( { end => $end } );
    my $value;
    VALUE: while ( not defined $value ) {
        local $main::ORIGIN = $origin;
        my $value_ref = $recce->value();
        last VALUE if not defined $value_ref;
        $value = ${$value_ref};
    } ## end VALUE: while ( not defined $value )
    if ( not defined $value ) {
        say 'No parse'
            or die "say() failed: $ERRNO";
        next RESULT;
    }
    say Data::Dumper::Dumper($value)
        or die "say() failed: $ERRNO"
        if not $quiet_flag;
    $recce->reset_evaluation();
} ## end RESULT: for my $result ( reverse @results )

package My_Actions;
our $SELF;
sub new { return $SELF }

## no critic (Subroutines::RequireFinalReturn)
sub do_arg1        { $_[2]; }
sub do_what_I_mean { shift; return $_[0] if scalar @_ == 1; return \@_ }
## use critic

sub do_target {
    my $origin = ( Marpa::R2::Context::location() )[0];
    return if $origin != $ORIGIN;
    return $_[1];
} ## end sub do_target

sub do_add { shift; return [ '+', @_ ] }
sub do_assign{ shift; return [ '=', @_ ] }
sub do_bang{ shift; return [ '!', @_ ] }
sub do_bitand{ shift; return [ '&', @_ ] }
sub do_bitor{ shift; return [ '|', @_ ] }
sub do_bitxor{ shift; return [ '^', @_ ] }
sub do_comma{ shift; return [ ',', @_ ] }
sub do_divide{ shift; return [ '/', @_ ] }
sub do_lshift{ shift; return [ '<<', @_ ] }
sub do_modulo{ shift; return [ '%', @_ ] }
sub do_multiply{ shift; return [ '*', @_ ] }
sub do_postdecrement{ shift; return [ @_, '--' ] }
sub do_postincrement{ shift; return [ @_, '++' ] }
sub do_power{ shift; return [ '**', @_ ] }
sub do_predecrement{ shift; return [ '--', @_ ] }
sub do_preincrement{ shift; return [ '++', @_ ] }
sub do_rshift{ shift; return [ '>>', @_ ] }
sub do_subtract{ shift; return [ '-', @_ ] }
sub do_tilde{ shift; return [ '~', @_ ] }
sub do_uminus{ shift; return [ 'u-', @_ ] }
sub do_uplus{ shift; return [ 'u+', @_ ] }
sub do_x_op{ shift; return [ 'x', @_ ] }

sub do_literal {
    my $self = shift;
    my $recce = $self->{recce};
    my ( $start, $end ) = Marpa::R2::Context::location();
    my $result = $recce->sl_range_to_string($start, $end);
    $result =~ s/ \A \s+ //xms;
    $result =~ s/ \s+ \z //xms;
    return $result;
} ## end sub do_literal

# vim: expandtab shiftwidth=4:
