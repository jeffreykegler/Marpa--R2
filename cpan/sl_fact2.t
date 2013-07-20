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
            :start ::= quartet
            quartet ::= item item
            item ::= 'a' | 'aa'
END_OF_SOURCE
    }
);

say STDERR $slg->thick_g1_grammar()->show_irls();

my $slr = Marpa::R2::Scanless::R->new( { grammar => $slg } );
my ( $parse_value, $parse_status );

if ( not defined eval { $slr->read( \'aaa' ); 1 } ) {
    my $abbreviated_error = $EVAL_ERROR;
    chomp $abbreviated_error;
    $abbreviated_error =~ s/\n.*//xms;
    $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
    die 'No parse: ', $abbreviated_error;
} ## end if ( not defined eval { $slr->read( \'aaa' ); 1 } )
my $asf = Marpa::R2::Scanless::ASF->new(
    { slr => $slr, choice => 'My_ASF::choix', force => 'My_ASF' } );

say STDERR "Or-nodes:\n", $slr->thick_g1_recce()->verbose_or_nodes();

if ( not defined $asf ) {
    return 'No parse', 'Input read to end but no parse';
}

say STDERR Data::Dumper::Dumper($asf->first_factored_rhs($asf->top()));

# my $actual_asf         = $asf->raw();
# my $actual_blessed_asf = $asf->bless($actual_asf);


# vim: expandtab shiftwidth=4:
