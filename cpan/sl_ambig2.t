#!perl
# Copyright 2013 Jeffrey Kegler
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

# Tests of ambiguity detection in the target grammar
# (as opposed to the SLIF DSL itself).

use 5.010;
use strict;
use warnings;

use Test::More tests => 14;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

our $DEBUG = 0;
my @tests_data = ();

my $symch_ambiguity = \(<<'END_OF_SOURCE');
:default ::= action => ::array
pair ::= duple | item item
duple ::= item item
item ::= Hesperus | Phosphorus
Hesperus ::= 'a'
Phosphorus ::= 'a'
END_OF_SOURCE

push @tests_data,
    [
    $symch_ambiguity, 'aa',
    'SLIF grammar failed',
    <<'END_OF_MESSAGE',
Parse of BNF/Scanless source is ambiguous
END_OF_MESSAGE
    'Symch ambiguity'
    ];


TEST:
for my $test_data (@tests_data) {
    my ( $source, $input, $expected_value, $expected_result, $test_name ) =
        @{$test_data};
    my ( $actual_value, $actual_result );
    PROCESSING: {
        my $grammar = Marpa::R2::Scanless::G->new( { source => $source } );
        my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

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

    if ( $recce->ambiguity_metric() > 1 ) {
	my $asf = Marpa::R2::ASF->new( { slr => $recce } );
	say STDERR 'No ASF' if not defined $asf;
	my $ambiguities = Marpa::R2::Internal::ASF::ambiguities( $asf );
	my @ambiguities = grep { defined } @{$ambiguities}[0 .. 1 ];
	$actual_value = 'Application grammar is ambiguous';
	$actual_result = 
            Marpa::R2::Internal::ASF::ambiguities_show( $asf, \@ambiguities );
	  last PROCESSING;
    }
        my $value_ref = $recce->value();
        if ( not defined $value_ref ) {
            $actual_value  = 'No parse';
            $actual_result = 'Input read to end but no parse';
            last PROCESSING;
        }
        $actual_value  = ${$value_ref};
        $actual_result = 'Parse OK';
        last PROCESSING;
    } ## end PROCESSING:

    Test::More::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Test::More::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end for my $test_data (@tests_data)

# vim: expandtab shiftwidth=4:
