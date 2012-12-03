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

# Synopsis for Scannerless version of Stuizand interface

use 5.010;
use strict;
use warnings;
use Test::More tests => 3;
use English qw( -no_match_vars );

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $grammar = Marpa::R2::Grammar->new(
    {   scannerless    => 1,
        action_object  => 'My_Actions',
        default_action => 'do_first_arg',
        rules          => <<'END_OF_RULES',
:start ::= Script
Script ::= Expression+ separator => [,] action => do_script
Expression ::=
    Number
    | '(' Expression ')' action => do_parens assoc => group
   || Expression '**' Expression action => do_pow assoc => right
   || Expression '*' Expression action => do_multiply
    | Expression '/' Expression action => do_divide
   || Expression '+' Expression action => do_add
    | Expression '-' Expression action => do_subtract
Number ~ [\d]+ action => do_literal
END_OF_RULES
    }
);

$grammar->precompute();

sub my_parser {
    my ( $grammar, $input_string ) = @_;
    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );
    my $self = bless { grammar => $grammar }, 'My_Actions';
    $self->{recce} = $recce;
    local $My_Actions::SELF = $self;

    my $event_count;
    if ( not defined eval { $event_count = $recce->sl_read($input_string); 1 }
        )
    {
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

    return ${$value_ref};

} ## end sub my_parser

my @tests = (
    [   '42*2+7/3, 42*(2+7)/3, 2**7-3, 2**(7-3)' =>
            qr/\A 86[.]3\d+ \s+ 126 \s+ 125 \s+ 16\z/xms
    ],
    [   '42*3+7, 42 * 3 + 7, 42 * 3+7' => qr/ \s* 133 \s+ 133 \s+ 133 \s* /xms
    ],
    [   '15329 + 42 * 290 * 711, 42*3+7, 3*3+4* 4' =>
            qr/ \s* 8675309 \s+ 133 \s+ 25 \s* /xms
    ],
);

for my $test (@tests) {
    my ( $input, $output_re ) = @{$test};
    my $value = my_parser( $grammar, $input );
    Test::More::like( $value, $output_re, 'Value of scannerless parse' );
}

package My_Actions;

our $SELF;
sub new { return $SELF }

sub do_parens    { shift; return $_[0] }
sub do_add       { shift; return $_[0] + $_[1] }
sub do_subtract  { shift; return $_[0] - $_[1] }
sub do_multiply  { shift; return $_[0] * $_[1] }
sub do_divide    { shift; return $_[0] / $_[1] }
sub do_pow       { shift; return $_[0]**$_[1] }
sub do_first_arg { shift; return shift; }
sub do_script    { shift; return join q{ }, @_ }

sub do_literal {
    my $self  = shift;
    my $recce = $self->{recce};
    my ( $start, $end ) = Marpa::R2::Context::location();
    my $literal = $recce->sl_range_to_string( $start, $end );
    $literal =~ s/ \s+ \z //xms;
    $literal =~ s/ \A \s+ //xms;
    return $literal;
} ## end sub do_literal

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
