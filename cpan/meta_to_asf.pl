#!perl
# Copyright 2018 Jeffrey Kegler
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

use 5.010001;
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
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $slr->read($p_string); 1 } )
    my $asf = Marpa::R2::ASF->new( { slr => $slr } );
    if ( not defined $asf ) {
        return 'No ASF', 'Input read to end but no ASF';
    }

    # say STDERR "Rules:\n",     $slr->thick_g1_grammar()->show_rules();
    # say STDERR "IRLs:\n",      $slr->thick_g1_grammar()->show_irls();
    # say STDERR "ISYs:\n",      $slr->thick_g1_grammar()->show_isys();
    # say STDERR "Or-nodes:\n",  $slr->thick_g1_recce()->verbose_or_nodes();
    # say STDERR "And-nodes:\n", $slr->thick_g1_recce()->show_and_nodes();
    # say STDERR "Bocage:\n",    $slr->thick_g1_recce()->show_bocage();
    my $asf_desc = show($asf);

    # say STDERR $asf->show_nidsets();
    # say STDERR $asf->show_powersets();
    return $asf_desc, 'ASF OK';

} ## end sub my_parser

# GLADE_SEEN is a local -- this is to silence warnings
our %GLADE_SEEN;

sub form_choice {
    my ( $parent_choice, $sub_choice ) = @_;
    return $sub_choice if not defined $parent_choice;
    return join q{.}, $parent_choice, $sub_choice;
}

sub show_symches {
    my ( $asf, $glade_id, $parent_choice, $item_ix ) = @_;
    if ( $GLADE_SEEN{$glade_id} ) {
        return [ [0, $glade_id, "already displayed"] ];
    }
    $GLADE_SEEN{$glade_id} = 1;

    my $grammar      = $asf->grammar();
    my @lines        = ();
    my $symch_indent = 0;

    my $symch_count  = $asf->glade_symch_count($glade_id);
    my $symch_choice = $parent_choice;
    if ( $symch_count > 1 ) {
        $item_ix //= 0;
        push @lines,
              [ 0, undef, "Symbol #$item_ix, "
            . $asf->glade_symbol_name($glade_id)
            . ", has $symch_count symches" ];
        $symch_indent += 2;
        $symch_choice = form_choice( $parent_choice, $item_ix );
    } ## end if ( $symch_count > 1 )
    for ( my $symch_ix = 0; $symch_ix < $symch_count; $symch_ix++ ) {
        my $current_choice =
            $symch_count > 1
            ? form_choice( $symch_choice, $symch_ix )
            : $symch_choice;
        my $indent = $symch_indent;
        if ( $symch_count > 1 ) {
            push @lines, [ $symch_indent , undef, "Symch #$current_choice" ];
        }
        my $rule_id = $asf->symch_rule_id( $glade_id, $symch_ix );
        if ( $rule_id >= 0 ) {
            push @lines,
                [
                $symch_indent, $glade_id,
                "Rule " . $grammar->brief_rule($rule_id)
                ];
            for my $line (
                @{ show_factorings(
                    $asf, $glade_id, $symch_ix, $current_choice
                ) }
                )
            {
                my ( $line_indent, @rest_of_line ) = @{$line};
                push @lines, [ $line_indent + $symch_indent + 2, @rest_of_line ];
            } ## end for my $line ( show_factorings( $asf, $glade_id, ...))
        } ## end if ( $rule_id >= 0 )
        else {
            my $line = show_terminal( $asf, $glade_id, $current_choice );
            my ( $line_indent, @rest_of_line ) = @{$line};
            push @lines, [ $line_indent + $symch_indent, @rest_of_line ];
        } ## end else [ if ( $rule_id >= 0 ) ]
    } ## end for ( my $symch_ix = 0; $symch_ix < $symch_count; $symch_ix...)
    # say "show_symches = ", Data::Dumper::Dumper(\@lines);
    return \@lines;
} ## end sub show_symches

# Show all the factorings of a SYMCH
sub show_factorings {
    my ( $asf, $glade_id, $symch_ix, $parent_choice ) = @_;

    my @lines;
    my $factoring_count = $asf->symch_factoring_count( $glade_id, $symch_ix );
    for (
        my $factoring_ix = 0;
        $factoring_ix < $factoring_count;
        $factoring_ix++
        )
    {
        my $indent         = 0;
        my $current_choice = $parent_choice;
        if ( $factoring_count > 1 ) {
            $indent = 2;
            $current_choice = form_choice( $parent_choice, $factoring_ix );
            push @lines, [ 0, undef, "Factoring #$current_choice" ];
        }
        my $symbol_count =
            $asf->factoring_symbol_count( $glade_id, $symch_ix,
            $factoring_ix );
        SYMBOL: for my $symbol_ix ( 0 .. $symbol_count - 1 ) {
            my $downglade_id =
                $asf->factor_downglade_id( $glade_id, $symch_ix,
                $factoring_ix, $symbol_ix );
            for my $line (
                @{ show_symches(
                    $asf, $downglade_id, $current_choice, $symbol_ix
                ) }
                )
            {
                my ( $line_indent, @rest_of_line ) = @{$line};
                push @lines, [ $line_indent + $indent, @rest_of_line ];

            } ## end for my $line ( show_symches( $asf, $downglade_id, ...))
        } ## end SYMBOL: for my $symbol_ix ( 0 .. $symbol_count - 1 )
    } ## end for ( my $factoring_ix = 0; $factoring_ix < $factoring_count...)
    return \@lines;
} ## end sub show_factorings

sub show_terminal {
    my ( $asf, $glade_id, $symch_ix, $parent_choice ) = @_;

    # There can only be one symbol in a terminal and therefore only one factoring
    my $current_choice = $parent_choice;
    my $literal        = $asf->glade_literal($glade_id);
    my $symbol_name    = $asf->glade_symbol_name($glade_id);
    return [0, $glade_id, qq{Symbol: $symbol_name "$literal"}];
} ## end sub show_terminal

sub show {
    my ($asf) = @_;
    my $peak = $asf->peak();
    local %GLADE_SEEN = ();    ## no critic (Variables::ProhibitLocalVars)
    my $lines = show_symches( $asf, $peak );
    my $next_sequenced_id = 1; # one-based
    my %sequenced_id = ();
    $sequenced_id{$_} //= $next_sequenced_id++ for grep { defined } map { $_->[1] } @{$lines};
    my $text = q{};
    for my $line ( @{$lines}[ 1 .. $#$lines ] ) {
        my ( $line_indent, $glade_id, $body ) = @{$line};
        $line_indent -= 2;
        $text .= q{ } x $line_indent;
        $text .=  'GL' . $sequenced_id{$glade_id} . q{ } if defined $glade_id;
        $text .= "$body\n";
    }
    return $text;
} ## end sub show

# vim: expandtab shiftwidth=4:
