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

my $asf_grammar = Marpa::R2::Scanless::G->new(
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

sub my_parser {
    my ( $grammar, $string ) = @_;
    my $slr = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my ( $parse_value, $parse_status );

    if ( not defined eval { $slr->read( \$string ); 1 } ) {
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $slr->read( \$string ); 1 ...})
    my $asf_ref = $slr->raw_asf();
    if ( not defined $asf_ref ) {
        return 'No parse', 'Input read to end but no parse';
    }
    my $asf = ${$asf_ref};
    say Data::Dumper::Dumper( $asf);
    my $blessed_asf = $slr->bless_asf( $asf, { choice => 'choix', force => 'My_ASF' } );
    say Data::Dumper::Dumper($blessed_asf);
    return [ return $blessed_asf, 'Parse OK' ];
} ## end sub my_parser


my $expected_output = 
bless(
    [ 11,
        bless(
            [   11, bless(
                    [   9, bless(
                            [   8, bless(
                                    [   1, bless(
                                            [   0, bless(
                                                    [ -1, 0 ],
                                                    'My_ASF::_Lex_0_'
                                                )
                                            ],
                                            'My_ASF::singleton'
                                        )
                                    ],
                                    'My_ASF::item'
                                ),
                                bless(
                                    [   6, bless(
                                            [   5, bless(
                                                    [ -1, 5 ],
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
            [   11, bless(
                    [   2, bless(
                            [   1, bless(
                                    [ 0, bless( [ -1, 0 ], 'My_ASF::_Lex_0_' ) ],
                                    'My_ASF::singleton'
                                )
                            ],
                            'My_ASF::item'
                        )
                    ],
                    'My_ASF::sequence'
                ),
                bless(
                    [ 5, bless( [ -1, 5 ], 'My_ASF::_Lex_0_' ) ],
                    'My_ASF::singleton'
                )
            ],
            'My_ASF::sequence'
        )
    ],
    'choix'
);

my @tests_data = 
    [   $asf_grammar,
        'aa',
        $expected_output,
        'Parse OK',
        "ASF test, length=2"
    ] ;

TEST:
for my $test_data (@tests_data) {
    my ( $grammar, $test_string, $expected_value, $expected_result,
        $test_name )
        = @{$test_data};
    my ( $actual_value, $actual_result ) =
        my_parser( $grammar, $test_string );
    Test::More::is_deeply(
         $actual_value ,
         $expected_value ,
        qq{Value of $test_name}
    );
    Test::More::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end TEST: for my $test_data (@tests_data)

sub label_asf {
    my ( $slr, $asf_node ) = @_;
    my $type           = ref $asf_node;
    say STDERR "type= ", $type;
    return $asf_node if not $type;
    my $choicepoint_id = $asf_node->[0];
    my $desc;
    if ( $choicepoint_id >= 0 ) {
        $desc = $slr->brief_rule( $slr->choicepoint_rule($choicepoint_id) );
    }
    else {
        my $token_id = $asf_node->[1];
        $desc = "Token: $token_id";
    }
    return bless [ $desc, map { label_asf($slr, $_) } @{$asf_node} ], $type;
} ## end sub label_asf

# vim: expandtab shiftwidth=4:
