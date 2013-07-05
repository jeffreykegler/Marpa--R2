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

# Test of Abstract Syntax Forest

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my $slg = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
            :default ::= action => ::array
            :start ::= sequence
            sequence ::= item+
            item ::= pair | singleton
            singleton ::= 'a'
            pair ::= item item
END_OF_SOURCE
    }
);

our $EXPECTED_ASF = [
    -2, 11,
    [ [ 9, [ 8, [ 1, [ 0, [ -1, 0 ] ] ], [ 6, [ 5, [ -1, 5 ] ] ] ] ] ],
    [ [ 2, [] ], [] ]
];
$EXPECTED_ASF->[3][0][1] = $EXPECTED_ASF->[2][0][1][1];
$EXPECTED_ASF->[3][1] = $EXPECTED_ASF->[2][0][1][2][1];

my $expected_blessed_asf = bless(
    [   -1, 11,
        'Rule 1: sequence -> item+',
        bless(
            [   bless(
                    [   9,
                        'Rule 2: item -> pair',
                        bless(
                            [   8,
                                'Rule 5: pair -> item item',
                                bless(
                                    [   1,
                                        'Rule 3: item -> singleton',
                                        bless(
                                            [   0,
                                                'Rule 4: singleton -> [Lex-0]',
                                                bless(
                                                    [   -1, 'Token: [Lex-0]',
                                                        0
                                                    ],
                                                    'My_ASF::_Lex_0_'
                                                )
                                            ],
                                            'My_ASF::singleton'
                                        )
                                    ],
                                    'My_ASF::item'
                                ),
                                bless(
                                    [   6,
                                        'Rule 3: item -> singleton',
                                        bless(
                                            [   5,
                                                'Rule 4: singleton -> [Lex-0]',
                                                bless(
                                                    [   -1, 'Token: [Lex-0]',
                                                        5
                                                    ],
                                                    'My_ASF::_Lex_0_'
                                                )
                                            ],
                                            'My_ASF::singleton'
                                        )
                                    ],
                                    'My_ASF::item'
                                )
                            ],
                            'My_ASF::pair'
                        )
                    ],
                    'My_ASF::item'
                )
            ],
            'My_ASF::sequence'
        ),
        bless(
            [   bless(
                    [   2,
                        'Rule 1: sequence -> item+',
                        bless(
                            [   1,
                                'Rule 3: item -> singleton',
                                bless(
                                    [   0,
                                        'Rule 4: singleton -> [Lex-0]',
                                        bless(
                                            [ -1, 'Token: [Lex-0]', 0 ],
                                            'My_ASF::_Lex_0_'
                                        )
                                    ],
                                    'My_ASF::singleton'
                                )
                            ],
                            'My_ASF::item'
                        )
                    ],
                    'My_ASF::sequence'
                ),
                bless(
                    [   5,
                        'Rule 4: singleton -> [Lex-0]',
                        bless(
                            [ -1, 'Token: [Lex-0]', 5 ],
                            'My_ASF::_Lex_0_'
                        )
                    ],
                    'My_ASF::singleton'
                )
            ],
            'My_ASF::sequence'
        )
    ],
    'choix'
    );

my $slr = Marpa::R2::Scanless::R->new( { grammar => $slg } );
my ( $parse_value, $parse_status );

if ( not defined eval { $slr->read( \'aa' ); 1 } ) {
    my $abbreviated_error = $EVAL_ERROR;
    chomp $abbreviated_error;
    $abbreviated_error =~ s/\n.*//xms;
    $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
    return 'No parse', $abbreviated_error;
} ## end if ( not defined eval { $slr->read( \'aa' ); 1 } )
my $asf_ref = $slr->raw_asf();
if ( not defined $asf_ref ) {
    return 'No parse', 'Input read to end but no parse';
}
my $actual_asf = ${$asf_ref};

my $actual_blessed_asf =
    $slr->bless_asf( $actual_asf, { choice => 'choix', force => 'My_ASF' } );

# $Data::Dumper::Purity = 1;
# $Data::Dumper::Terse = 1;
# $Data::Dumper::Deepcopy = 1;
# say STDERR Data::Dumper::Dumper( $actual_blessed_asf );

Test::More::is_deeply( $actual_asf, $EXPECTED_ASF, 'ASF' );
Test::More::is_deeply( $actual_blessed_asf, $expected_blessed_asf,
    'Blessed ASF' );

# vim: expandtab shiftwidth=4:
