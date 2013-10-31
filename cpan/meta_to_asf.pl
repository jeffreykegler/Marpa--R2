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
no warnings qw(recursion);

use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2;
use Data::Dumper;

open my $metag_fh, q{<}, 'lib/Marpa/R2/meta/metag.bnf' or die;
my $metag_source = do { local $/ = undef; <$metag_fh>; };
close $metag_fh;

my $meta_grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'My_ASF',
        source        => \$metag_source
    }
);

my ( $actual_value, $actual_result ) =
    my_parser( $meta_grammar, \$metag_source );
say $actual_value;

die if $actual_result ne 'ASF OK';

sub my_parser {
    my ( $grammar, $p_string ) = @_;

    my $slr = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

    if ( not defined eval { $slr->read($p_string); 1 } ) {
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $slr->read($p_string); 1 } )
    my $asf = Marpa::R2::Scanless::ASF->new( { slr => $slr } );
    if ( not defined $asf ) {
        return 'No ASF', 'Input read to end but no ASF';
    }

    # say STDERR "Rules:\n",     $slr->thick_g1_grammar()->show_rules();
    # say STDERR "IRLs:\n",      $slr->thick_g1_grammar()->show_irls();
    # say STDERR "ISYs:\n",      $slr->thick_g1_grammar()->show_isys();
    # say STDERR "Or-nodes:\n",  $slr->thick_g1_recce()->verbose_or_nodes();
    # say STDERR "And-nodes:\n", $slr->thick_g1_recce()->show_and_nodes();
    # say STDERR "Bocage:\n",    $slr->thick_g1_recce()->show_bocage();
    my $asf_desc = $asf->show();

    # say STDERR $asf->show_nidsets();
    # say STDERR $asf->show_powersets();
    return $asf_desc, 'ASF OK';

} ## end sub my_parser

# vim: expandtab shiftwidth=4:
