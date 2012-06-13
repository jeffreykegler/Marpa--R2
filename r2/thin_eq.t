#!perl
# Copyright 2012 Jeffrey Kegler
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

# An ambiguous equation
# A version using the thin interface

use 5.010;
use strict;
use warnings;

use Test::More tests => 12;

use lib 'inc';
use Marpa::R2::Test;
use English qw( -no_match_vars );
use Fatal qw( close open );
use Marpa::R2;

## no critic (InputOutput::RequireBriefOpen)
open my $original_stdout, q{>&STDOUT};
## use critic

sub save_stdout {
    my $save;
    my $save_ref = \$save;
    close STDOUT;
    open STDOUT, q{>}, $save_ref;
    return $save_ref;
} ## end sub save_stdout

sub restore_stdout {
    close STDOUT;
    open STDOUT, q{>&}, $original_stdout;
    return 1;
}

## no critic (Subroutines::RequireArgUnpacking, ErrorHandling::RequireCarping)

sub do_op {
    shift;
    my ( $right_string, $right_value ) = ( $_[2] =~ /^(.*)==(.*)$/xms );
    my ( $left_string,  $left_value )  = ( $_[0] =~ /^(.*)==(.*)$/xms );
    my $op = $_[1];
    my $value;
    if ( $op eq q{+} ) {
        $value = $left_value + $right_value;
    }
    elsif ( $op eq q{*} ) {
        $value = $left_value * $right_value;
    }
    elsif ( $op eq q{-} ) {
        $value = $left_value - $right_value;
    }
    else {
        die "Unknown op: $op";
    }
    return '(' . $left_string . $op . $right_string . ')==' . $value;
} ## end sub do_op

sub number {
    shift;
    my $v0 = pop @_;
    return $v0 . q{==} . $v0;
}

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . join( q{;}, @_ ) . ')';
} ## end sub default_action

my $grammar  = Marpa::R2::Thin::G->new();
my $symbol_E = $grammar->symbol_new();
$grammar->start_symbol_set($symbol_E);
my $symbol_op     = $grammar->symbol_new();
my $symbol_number = $grammar->symbol_new();
my $rule_op =
    $grammar->rule_new( $symbol_E, [ $symbol_E, $symbol_op, $symbol_E ] );
my $rule_number = $grammar->rule_new( $symbol_E, [$symbol_number] );
$grammar->precompute();

my $recce = Marpa::R2::Thin::R->new($grammar);
$recce->start_input();
my @token_values         = ( 0 .. 3 );
my $minus_token_value    = -1 + push @token_values, q{-};
my $plus_token_value     = -1 + push @token_values, q{+};
my $multiply_token_value = -1 + push @token_values, q{*};
$recce->alternative( $symbol_number, 2, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_op, $minus_token_value, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_number, 0, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_op, $plus_token_value, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_number, 3, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_op, $multiply_token_value, 1 );
$recce->earleme_complete();
$recce->alternative( $symbol_number, 1, 1 );
$recce->earleme_complete();

my $latest_earley_set_ID = $recce->latest_earley_set();
my $bocage = Marpa::R2::Thin::B->new($recce, $latest_earley_set_ID);
my $order = Marpa::R2::Thin::O->new($bocage);
my $tree = Marpa::R2::Thin::T->new($order);

my $thick_grammar = Marpa::R2::Grammar->new(
    {   start   => 'E',
        actions => 'main',
        rules   => [
            [ 'E', [qw/E Op E/], 'do_op' ],
            [ 'E', [qw/Number/], 'number' ],
        ],
        default_action => 'default_action',
    }
);

$thick_grammar->precompute();

my $thick_recce = Marpa::R2::Recognizer->new( { grammar => $thick_grammar } );

$thick_recce->read( 'Number', 2 );
$thick_recce->read( 'Op',     q{-} );
$thick_recce->read( 'Number', 0 );
$thick_recce->read( 'Op',     q{*} );
$thick_recce->read( 'Number', 3 );
$thick_recce->read( 'Op',     q{+} );
$thick_recce->read( 'Number', 1 );

my $actual_ref = save_stdout();

# Marpa::R2::Display
# name: Thin show_progress Synopsis

print $thick_recce->show_progress()
    or die "print failed: $ERRNO";

# Marpa::R2::Display::End

Marpa::R2::Test::is( ${$actual_ref},
    <<'END_OF_PROGRESS_REPORT', 'Ambiguous Equation Progress Report' );
R0:1 x4 @0...6-7 E -> E . Op E
F0 x3 @0,2,4-7 E -> E Op E .
F1 @6-7 E -> Number .
END_OF_PROGRESS_REPORT

restore_stdout();

my %expected_value = (
    '(2-(0*(3+1)))==2' => 1,
    '(((2-0)*3)+1)==7' => 1,
    '((2-(0*3))+1)==3' => 1,
    '((2-0)*(3+1))==8' => 1,
    '(2-((0*3)+1))==1' => 1,
);

# Set max at 10 just in case there's an infinite loop.
# This is for debugging, after all

# Marpa::R2::Display
# name: Thin Recognizer set Synopsis

$thick_recce->set( { max_parses => 10, } );

# Marpa::R2::Display::End

my $i = 0;
while ( defined( my $value = $thick_recce->value() ) ) {
    my $value = ${$value};
    if ( defined $expected_value{$value} ) {
        delete $expected_value{$value};
        Test::More::pass("Expected Value $i: $value");
    }
    else {
        Test::More::fail("Unexpected Value $i: $value");
    }
    $i++;
} ## end while ( defined( my $value = $thick_recce->value() ) )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
