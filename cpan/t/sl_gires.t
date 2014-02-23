#!perl
# Copyright 2014 Jeffrey Kegler
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

# Tests that include a grammar, an input, and an resolution
# error message, but no (or minimal?) semantics.
#
# The intent is that this file will contain tests of the
# valuator's resolution phase

use 5.010;
use strict;
use warnings;

use Test::More tests => 4;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

our $DEBUG = 0;
my @tests_data = ();

sub My_Semantics::new {}

####

{
    my $grammar = \(<<'END_OF_SOURCE');
:start ::= test
test   ::= 'X'       action => nowhere
END_OF_SOURCE

    push @tests_data, [ $grammar, 'X',
    'Failure in value() method',
    <<'END_OF_MESSAGE',
Could not resolve rule action named 'nowhere'
  Rule was test ::= 'X'
  Failed resolution of action "nowhere" to My_Semantics::nowhere
END_OF_MESSAGE
    'Parse OK', 'Missing action' ];
}

####

{
    my $source = <<'END_OF_SOURCE';

    inaccessible is fatal by default
    :default ::= action => [symbol, name, values]
    lexeme default = action => [symbol, name, value]
    start ::= stuff*
    stuff ::= a | b
    a ::= x 
    b ::= x 
    c ::= x 
    x ::= 'x'
END_OF_SOURCE

    my $input           = 'xxx';
    my $expected_value = 'SLIF grammar failed';

    push @tests_data,
        [
        \$source, $input, $expected_value,
        "Inaccessible symbol: c\n", qq{test "inaccessible is fatal by default"}
        ];
}

###

TEST:
for my $test_data (@tests_data) {
    my ( $source, $input, $expected_value, $expected_result, $test_name ) =
        @{$test_data};
    my ( $actual_value, $actual_result );
    PROCESSING: {
        my $grammar;
        if (not defined eval {
                $grammar =
                    Marpa::R2::Scanless::G->new( { source => $source } );
                1;
            }
            )
        {
            say $EVAL_ERROR if $DEBUG;
            my $abbreviated_error = $EVAL_ERROR;

            chomp $abbreviated_error;
            $abbreviated_error =~ s/^ Marpa[:][:]R2 \s+ exception \s+ at \s+ .* \z//xms;
            $actual_value  = 'SLIF grammar failed';
            $actual_result = $abbreviated_error;
            last PROCESSING;
        } ## end if ( not defined eval { $grammar = Marpa::R2::Scanless::G...})
        my $recce = Marpa::R2::Scanless::R->new(
            { grammar => $grammar, semantics_package => 'My_Semantics' } );

        if ( not defined eval { $recce->read( \$input ); 1 } ) {
            say $EVAL_ERROR if $DEBUG;
            my $abbreviated_error = $EVAL_ERROR;
            chomp $abbreviated_error;
            $abbreviated_error =~ s/\n.*//xms;
            $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
            $actual_value  = 'No parse';
            $actual_result = $abbreviated_error;
            last PROCESSING;
        } ## end if ( not defined eval { $recce->read( \$input ); 1 })
        my $value_ref ;
        if ( not defined eval { $value_ref = $recce->value(); 1 } ) {
            say $EVAL_ERROR if $DEBUG;
            my $abbreviated_error = $EVAL_ERROR;
            chomp $abbreviated_error;
            $abbreviated_error =~ s/^ Marpa[:][:]R2 \s+ exception \s+ at \s+ .* \z//xms;
            $actual_value  = 'Failure in value() method';
            $actual_result = $abbreviated_error;
            last PROCESSING;
        }
        if ( not defined $value_ref ) {
            $actual_value  = 'No parse';
            $actual_result = 'Input read to end but no parse';
            last PROCESSING;
        }
        $actual_value  = ${$value_ref};
        $actual_result = 'Parse OK';
        last PROCESSING;
    } ## end PROCESSING:

    Marpa::R2::Test::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Marpa::R2::Test::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end for my $test_data (@tests_data)

# vim: expandtab shiftwidth=4:
