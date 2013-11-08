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

use Test::More tests => 1;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;
use Scalar::Util;

# Marpa::R2::Display
# name: ASF low-level calls synopsis, code part 1

my $grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:start ::= pair
pair ::= duple | item item
duple ::= item item
item ::= Hesperus | Phosphorus
Hesperus ::= 'a'
Phosphorus ::= 'a'
END_OF_SOURCE
    }
);

my $slr = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
$slr->read( \'aa' );
my $asf = Marpa::R2::ASF->new( { slr => $slr } );
die 'No ASF' if not defined $asf;
my $output_as_array = asf_to_basic_tree($asf);
my $actual_output   = array_display($output_as_array);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: ASF low-level calls synopsis, output
# start-after-line: END_OF_OUTPUT
# end-before-line: '^END_OF_OUTPUT$'

my $expected_output = <<'EXPECTED_OUTPUT';
Glade 2 has 2 symches
  Glade 2, Symch 0, pair ::= duple
    Glade 6, duple ::= item item
      Glade 8 has 2 symches
        Glade 8, Symch 0, item ::= Hesperus
          Glade 13, Hesperus ::= 'a'
            Glade 15, Symbol 'a': "a"
        Glade 8, Symch 1, item ::= Phosphorus
          Glade 1, Phosphorus ::= 'a'
            Glade 17, Symbol 'a': "a"
  Glade 2, Symch 1, pair ::= item item
    Glade 8 revisited
EXPECTED_OUTPUT

# Marpa::R2::Display::End

Marpa::R2::Test::is( $actual_output, $expected_output,
    'Output for basic ASF synopsis' );

# Marpa::R2::Display
# name: ASF low-level calls synopsis, code part 2

our %GLADE_SEEN;    # Silence warning

sub asf_to_basic_tree {
    my ( $asf, $glade ) = @_;
    local %GLADE_SEEN = ();
    my $peak = $asf->peak();
    return glade_to_basic_tree( $asf, $peak );
} ## end sub asf_to_basic_tree

sub glade_to_basic_tree {
    my ( $asf, $glade ) = @_;
    return bless ["Glade $glade revisited"], 'My_Revisit'
        if $GLADE_SEEN{$glade};
    $GLADE_SEEN{$glade} = 1;
    my $grammar     = $asf->grammar();
    my @symches     = ();
    my $symch_count = $asf->glade_symch_count($glade);
    SYMCH: for ( my $symch_ix = 0; $symch_ix < $symch_count; $symch_ix++ ) {
        my $rule_id = $asf->symch_rule_id( $glade, $symch_ix );
        if ( $rule_id < 0 ) {
            my $literal      = $asf->glade_literal($glade);
            my $symbol_id    = $asf->glade_symbol_id($glade);
            my $display_form = $grammar->symbol_display_form($symbol_id);
            push @symches,
                bless [qq{Glade $glade, Symbol $display_form: "$literal"}],
                'My_Token';
            next SYMCH;
        } ## end if ( $rule_id < 0 )

        # ignore any truncation of the factorings
        my $factoring_count =
            $asf->symch_factoring_count( $glade, $symch_ix );
        my @symch_description = ("Glade $glade");
        push @symch_description, "Symch $symch_ix" if $symch_count > 1;
        push @symch_description, $grammar->show_rule($rule_id);
        my $symch_description = join q{, }, @symch_description;

        my @factorings = ($symch_description);
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
        push @symches,
            bless [
            "Glade $glade, symch $symch_ix has $factoring_count factorings",
            @factorings
            ],
            'My_Factorings'
            if $factoring_count > 1;
        push @symches, bless [ @factorings[ 0, 1 ] ], 'My_Rule';
    } ## end SYMCH: for ( my $symch_ix = 0; $symch_ix < $symch_count; ...)
    return bless [ "Glade $glade has $symch_count symches", @symches ],
        'My_Symches'
        if $symch_count > 1;
    return $symches[0];
} ## end sub glade_to_basic_tree

# Marpa::R2::Display

sub array_display {
    my ($array) = @_;
    my ( undef, @lines ) = @{ array_lines_display($array) };
    my $text = q{};
    for my $line (@lines) {
        my ( $indent, $body ) = @{$line};
        $indent -= 4;
        $text .= ( q{ } x $indent ) . $body . "\n";
    }
    return $text;
} ## end sub array_display

sub array_lines_display {
    my ($array) = @_;
    my $reftype = Scalar::Util::reftype($array) // '!undef!';
    return [ [ 0, $array ] ] if $reftype ne 'ARRAY';
    my @lines = ();
    ELEMENT: for my $element ( @{$array} ) {
        for my $line ( @{ array_lines_display($element) } ) {
            my ( $indent, $body ) = @{$line};
            push @lines, [ $indent + 2, $body ];
        }
    } ## end ELEMENT: for my $element ( @{$array} )
    return \@lines;
} ## end sub array_lines_display

# vim: expandtab shiftwidth=4:
