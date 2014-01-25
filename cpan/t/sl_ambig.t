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

# Tests of ambiguity detection in the target grammar
# (as opposed to the SLIF DSL itself).

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

my $source = \(<<'END_OF_SOURCE');
:default ::= action => ::array
pair ::= duple | item item
duple ::= item item
item ::= Hesperus | Phosphorus
Hesperus ::= 'a'
Phosphorus ::= 'a'
END_OF_SOURCE

my $input           = 'aa';
my $expected_value   = 'Application grammar is ambiguous';
my $expected_result = <<'END_OF_MESSAGE';
Ambiguous symch at Glade=2, Symbol=<pair>:
  The ambiguity is from line 1, column 1 to line 1, column 2
  Text is: aa
  There are 2 symches
  Symch 0 is a rule: pair ::= duple
  Symch 1 is a rule: pair ::= item item
END_OF_MESSAGE
my $test_name = 'Symch ambiguity';

my $grammar = Marpa::R2::Scanless::G->new( { source  => $source } );
my $recce   = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
my $is_ambiguous_parse = 1;

my ( $actual_value, $actual_result );
PROCESSING: {

    if ( not defined eval { $recce->read( \$input ); 1 } ) {
        say $EVAL_ERROR if $DEBUG;
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        $actual_value  = 'No parse';
        $actual_result = $abbreviated_error;
        $is_ambiguous_parse = 0;
        last PROCESSING;
    } ## end if ( not defined eval { $recce->read( \$input ); 1 })

# Marpa::R2::Display
# name: ASF ambiguity reporting

    if ( $recce->ambiguity_metric() > 1 ) {
        my $asf = Marpa::R2::ASF->new( { slr => $recce } );
        die 'No ASF' if not defined $asf;
        my $ambiguities = Marpa::R2::Internal::ASF::ambiguities($asf);

        # Only report the first two
        my @ambiguities = grep {defined} @{$ambiguities}[ 0 .. 1 ];

        $actual_value = 'Application grammar is ambiguous';
        $actual_result =
            Marpa::R2::Internal::ASF::ambiguities_show( $asf, \@ambiguities );
        last PROCESSING;
    } ## end if ( $recce->ambiguity_metric() > 1 )

# Marpa::R2::Display::End

    $is_ambiguous_parse = 0;

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
Test::More::is( $actual_result, $expected_result, qq{Result of $test_name} );

if ( !$is_ambiguous_parse ) {
    Test::More::fail(qq{glade_span() start});
    Test::More::fail(qq{glade_span() length});
}
else {
    $recce->series_restart();
    my $asf = Marpa::R2::ASF->new( { slr => $recce } );
    my $glade_id = $asf->peak;

# Marpa::R2::Display
# name: glade_span() example

    my ( $glade_start, $glade_length ) = $asf->glade_span($glade_id);

# Marpa::R2::Display::End

    Test::More::is( $glade_start,  0, qq{glade_span() start} );
    Test::More::is( $glade_length, 2, qq{glade_span() length} );

} ## end else [ if ( !$is_ambiguous_parse ) ]

# vim: expandtab shiftwidth=4:
