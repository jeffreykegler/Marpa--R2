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

# The low-level ASF synopses and related tests

use 5.010;
use strict;
use warnings;

use Test::More tests => 22;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my $grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:start ::= sequence
sequence ::= item+
item ::= pair | Hesperus | Phosphorus
Hesperus ::= 'a'
Phosphorus ::= 'a'
pair ::= item item
END_OF_SOURCE
    }
);

my $slr = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
$slr->read( \'aa' );
my $asf = Marpa::R2::ASF->new( { slr => $slr } );
die 'No ASF' if  not defined $asf ;
say asf_to_basic_tree($asf);

our %GLADE_SEEN; # Silence warning

sub asf_to_basic_tree {
    my ($asf, $glade) = @_;
    local %GLADE_SEEN = ();
    my $peak = $asf->peak();
    return glade_to_basic_tree($asf, $peak);
}

sub glade_to_basic_tree {
    my ( $asf, $glade ) = @_;
    return bless [$glade], 'My_Revisited_Glade' if $GLADE_SEEN{$glade};
    $GLADE_SEEN{$glade} = 1;
    my @symches     = ();
    my $symch_count = $asf->glade_symch_count($glade);
    SYMCH: for ( my $symch_ix = 0; $symch_ix < $symch_count; $symch_ix++ ) {
        my $rule_id = $asf->symch_rule_id( $glade, $symch_ix );
        if ( $rule_id < 0 ) {
            my $literal     = $asf->glade_literal($glade);
            my $symbol_name = $asf->glade_symbol_name($glade);
            push @symches, bless [qq{Symbol $symbol_name: "$literal"}],
                'My_Token';
            next SYMCH;
        } ## end if ( $rule_id < 0 )
        my @factorings = ( display_rule( $asf, $rule_id ) );

        # ignore any truncation of the factorings
        my $factoring_count =
            $asf->symch_factoring_count( $glade, $symch_ix );
        for (
            my $factoring_ix = 0;
            $factoring_ix < $factoring_count;
            $factoring_ix++
            )
        {
            my $downglades =
                $asf->factoring_downglades( $glade, $symch_ix,
                $factoring_ix );
            push @factorings,
                map { glade_to_basic_tree( $asf, $_ ) } @{$downglades};
        } ## end for ( my $factoring_ix = 0; $factoring_ix < $factoring_count...)
        push @symches, bless \@factorings, 'My_Factorings'
            if scalar @factorings > 1;
        push @symches, $factorings[0];
    } ## end SYMCH: for ( my $symch_ix = 0; $symch_ix < $symch_count; ...)
    return bless \@symches, 'My_Symches' if scalar @symches > 1;
    return $symches[0];
} ## end sub glade_to_basic_tree

sub display_rule {
    my ($asf, $rule_id) = @_;
    my $grammar = $asf->grammar();
    my ($lhs_name, @rhs_names) = map { $grammar->symbol_display_form($_) } $grammar->rule_expand($rule_id);
    return join q{ }, "Rule $rule_id:", $lhs_name, q{::=}, @rhs_names;
}

# vim: expandtab shiftwidth=4:
