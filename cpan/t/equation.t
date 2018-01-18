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
# An ambiguous equation

use 5.010001;
use strict;
use warnings;

use Test::More tests => 11;

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

my $grammar = Marpa::R2::Grammar->new(
    {   start   => 'E',
        actions => 'main',
        rules   => [
            [ 'E', [qw/E Op E/], 'do_op' ],
            [ 'E', [qw/Number/], 'number' ],
        ],
        default_action => 'default_action',
    }
);

$grammar->precompute();

my $actual_ref;
$actual_ref = save_stdout();

# Marpa::R2::Display
# name: show_symbols Synopsis

print $grammar->show_symbols()
    or die "print failed: $ERRNO";

# Marpa::R2::Display::End

restore_stdout();

Marpa::R2::Test::is( ${$actual_ref},
    <<'END_SYMBOLS', 'Ambiguous Equation Symbols' );
0: E
1: Op, terminal
2: Number, terminal
END_SYMBOLS

$actual_ref = save_stdout();

# Marpa::R2::Display
# name: show_rules Synopsis

print $grammar->show_rules()
    or die "print failed: $ERRNO";

# Marpa::R2::Display::End

restore_stdout();

Marpa::R2::Test::is( ${$actual_ref},
    <<'END_RULES', 'Ambiguous Equation Rules' );
0: E -> E Op E
1: E -> Number
END_RULES

$actual_ref = save_stdout();

print $grammar->show_ahms()
    or die "print failed: $ERRNO";

restore_stdout();

Marpa::R2::Test::is( ${$actual_ref},
    <<'EOS', 'Ambiguous Equation AHMs' );
AHM 0: postdot = "E"
    E ::= . E Op E
AHM 1: postdot = "Op"
    E ::= E . Op E
AHM 2: postdot = "E"
    E ::= E Op . E
AHM 3: completion
    E ::= E Op E .
AHM 4: postdot = "Number"
    E ::= . Number
AHM 5: completion
    E ::= Number .
AHM 6: postdot = "E"
    E['] ::= . E
AHM 7: completion
    E['] ::= E .
EOS

$actual_ref = save_stdout();

# Marpa::R2::Display
# name: show_problems Synopsis

print $grammar->show_problems()
    or die "print failed: $ERRNO";

# Marpa::R2::Display::End

Marpa::R2::Test::is(
    ${$actual_ref},
    "Grammar has no problems\n",
    'Ambiguous Equation Problems'
);

restore_stdout();

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

$recce->read( 'Number', 2 );
$recce->read( 'Op',     q{-} );
$recce->read( 'Number', 0 );
$recce->read( 'Op',     q{*} );
$recce->read( 'Number', 3 );
$recce->read( 'Op',     q{+} );
$recce->read( 'Number', 1 );

$actual_ref = save_stdout();

print $recce->show_earley_sets()
    or die "print failed: $ERRNO";

my $expected_earley_sets = <<'END_OF_EARLEY_SETS';
Last Completed: 7; Furthest: 7
Earley Set 0
ahm6: R2:0@0-0
  R2:0: E['] ::= . E
ahm0: R0:0@0-0
  R0:0: E ::= . E Op E
ahm4: R1:0@0-0
  R1:0: E ::= . Number
Earley Set 1
ahm5: R1$@0-1
  R1$: E ::= Number .
  [c=R1:0@0-0; s=Number; t=\2]
ahm1: R0:1@0-1
  R0:1: E ::= E . Op E
  [p=R0:0@0-0; c=R1$@0-1]
ahm7: R2$@0-1
  R2$: E['] ::= E .
  [p=R2:0@0-0; c=R1$@0-1]
Earley Set 2
ahm2: R0:2@0-2
  R0:2: E ::= E Op . E
  [c=R0:1@0-1; s=Op; t=\'-']
ahm0: R0:0@2-2
  R0:0: E ::= . E Op E
ahm4: R1:0@2-2
  R1:0: E ::= . Number
Earley Set 3
ahm5: R1$@2-3
  R1$: E ::= Number .
  [c=R1:0@2-2; s=Number; t=\0]
ahm1: R0:1@2-3
  R0:1: E ::= E . Op E
  [p=R0:0@2-2; c=R1$@2-3]
ahm3: R0$@0-3
  R0$: E ::= E Op E .
  [p=R0:2@0-2; c=R1$@2-3]
ahm1: R0:1@0-3
  R0:1: E ::= E . Op E
  [p=R0:0@0-0; c=R0$@0-3]
ahm7: R2$@0-3
  R2$: E['] ::= E .
  [p=R2:0@0-0; c=R0$@0-3]
Earley Set 4
ahm2: R0:2@0-4
  R0:2: E ::= E Op . E
  [c=R0:1@0-3; s=Op; t=\'*']
ahm2: R0:2@2-4
  R0:2: E ::= E Op . E
  [c=R0:1@2-3; s=Op; t=\'*']
ahm0: R0:0@4-4
  R0:0: E ::= . E Op E
ahm4: R1:0@4-4
  R1:0: E ::= . Number
Earley Set 5
ahm5: R1$@4-5
  R1$: E ::= Number .
  [c=R1:0@4-4; s=Number; t=\3]
ahm1: R0:1@4-5
  R0:1: E ::= E . Op E
  [p=R0:0@4-4; c=R1$@4-5]
ahm3: R0$@2-5
  R0$: E ::= E Op E .
  [p=R0:2@2-4; c=R1$@4-5]
ahm3: R0$@0-5
  R0$: E ::= E Op E .
  [p=R0:2@0-2; c=R0$@2-5] [p=R0:2@0-4; c=R1$@4-5]
ahm1: R0:1@0-5
  R0:1: E ::= E . Op E
  [p=R0:0@0-0; c=R0$@0-5]
ahm7: R2$@0-5
  R2$: E['] ::= E .
  [p=R2:0@0-0; c=R0$@0-5]
ahm1: R0:1@2-5
  R0:1: E ::= E . Op E
  [p=R0:0@2-2; c=R0$@2-5]
Earley Set 6
ahm2: R0:2@2-6
  R0:2: E ::= E Op . E
  [c=R0:1@2-5; s=Op; t=\'+']
ahm2: R0:2@0-6
  R0:2: E ::= E Op . E
  [c=R0:1@0-5; s=Op; t=\'+']
ahm2: R0:2@4-6
  R0:2: E ::= E Op . E
  [c=R0:1@4-5; s=Op; t=\'+']
ahm0: R0:0@6-6
  R0:0: E ::= . E Op E
ahm4: R1:0@6-6
  R1:0: E ::= . Number
Earley Set 7
ahm5: R1$@6-7
  R1$: E ::= Number .
  [c=R1:0@6-6; s=Number; t=\1]
ahm1: R0:1@6-7
  R0:1: E ::= E . Op E
  [p=R0:0@6-6; c=R1$@6-7]
ahm3: R0$@4-7
  R0$: E ::= E Op E .
  [p=R0:2@4-6; c=R1$@6-7]
ahm3: R0$@0-7
  R0$: E ::= E Op E .
  [p=R0:2@0-2; c=R0$@2-7] [p=R0:2@0-4; c=R0$@4-7] [p=R0:2@0-6; c=R1$@6-7]
ahm3: R0$@2-7
  R0$: E ::= E Op E .
  [p=R0:2@2-4; c=R0$@4-7] [p=R0:2@2-6; c=R1$@6-7]
ahm1: R0:1@2-7
  R0:1: E ::= E . Op E
  [p=R0:0@2-2; c=R0$@2-7]
ahm1: R0:1@0-7
  R0:1: E ::= E . Op E
  [p=R0:0@0-0; c=R0$@0-7]
ahm7: R2$@0-7
  R2$: E['] ::= E .
  [p=R2:0@0-0; c=R0$@0-7]
ahm1: R0:1@4-7
  R0:1: E ::= E . Op E
  [p=R0:0@4-4; c=R0$@4-7]
END_OF_EARLEY_SETS

Marpa::R2::Test::is( ${$actual_ref}, $expected_earley_sets,
    'Ambiguous Equation Earley Sets' );

restore_stdout();

$actual_ref = save_stdout();

# Marpa::R2::Display
# name: show_progress Synopsis

print $recce->show_progress()
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
# name: Recognizer set Synopsis

$recce->set( { max_parses => 10, } );

# Marpa::R2::Display::End

my $i = 0;
while ( defined( my $value = $recce->value() ) ) {
    my $value = ${$value};
    if ( defined $expected_value{$value} ) {
        delete $expected_value{$value};
        Test::More::pass("Expected Value $i: $value");
    }
    else {
        Test::More::fail("Unexpected Value $i: $value");
    }
    $i++;
} ## end while ( defined( my $value = $recce->value() ) )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
