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

my $input_string = '42*1+7';
if ( !$do_demo ) {
    $input_string = shift;
}

my $grammar = Marpa::R2::Scanless::G->new(
    {   
        action_object  => 'My_Actions',
        default_action => 'first_arg',
        source          => \(<<'END_OF_GRAMMAR'),

:start ::= Expression
Expression ::=
       Number
    || Expression '*' Expression action => do_multiply
    || Expression '+' Expression action => do_add
Number ~ digits '.' digits
Number ~ digits
digits ~ [\d]+

:discard ~ whitespace
whitespace ~ [\s]+
# allow comments
:discard ~ <hash comment>
<hash comment> ~ <terminated hash comment> | <unterminated
   final hash comment>
<terminated hash comment> ~ '#' <hash comment body> <vertical space char>
<unterminated final hash comment> ~ '#' <hash comment body>
<hash comment body> ~ <hash comment char>*
<vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
<hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_OF_GRAMMAR
    }
);

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

my $self = bless { grammar => $grammar }, 'My_Actions';
$self->{recce} = $recce;
local $My_Actions::SELF = $self;

if ( not defined eval { $recce->read( \$input_string ); 1 } ) {
    ## Add last expression found, and rethrow
    my $eval_error = $EVAL_ERROR;
    chomp $eval_error;
    die $self->show_last_expression(), "\n", $eval_error, "\n";
} ## end if ( not defined eval { $recce->read( \$input_string...)})

my $value_ref = $recce->value;
if ( not defined $value_ref ) {
    die $self->show_last_expression(), "\n",
        "No parse was found, after reading the entire input\n";
}

say "Value = ", ${$value_ref};
exit 0;

package My_Actions;
our $SELF;
sub new { return $SELF }

sub My_Actions::do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub My_Actions::do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}

sub My_Actions::first_arg { shift; return shift; }

sub show_last_expression {
    my ($self) = @_;
    my $recce = $self->{recce};
    my ( $start, $end ) = $recce->last_completed_range('Expression');
    return 'No expression was successfully parsed' if not defined $start;
    my $last_expression = $recce->range_to_string( $start, $end );
    return "Last expression successfully parsed was: $last_expression";
} ## end sub show_last_expression

# vim: expandtab shiftwidth=4:
