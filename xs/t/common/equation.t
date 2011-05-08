#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.
# An ambiguous equation

use 5.010;
use strict;
use warnings;

use Test::More tests => 13;

use Marpa::XS::Test;
use English qw( -no_match_vars );
use Fatal qw( close open );

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

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
        Marpa::XS::exception("Unknown op: $op");
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

my $grammar = Marpa::XS::Grammar->new(
    {   start   => 'E',
        strip   => 0,
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

# Marpa::XS::Display
# name: show_symbols Synopsis

print $grammar->show_symbols()
    or die "print failed: $ERRNO";

# Marpa::XS::Display::End

restore_stdout();

Marpa::XS::Test::is( ${$actual_ref},
    <<'END_SYMBOLS', 'Ambiguous Equation Symbols' );
0: E, lhs=[0 1] rhs=[0 2] terminal
1: Op, lhs=[] rhs=[0] terminal
2: Number, lhs=[] rhs=[1] terminal
3: E['], lhs=[2] rhs=[]
END_SYMBOLS

$actual_ref = save_stdout();

# Marpa::XS::Display
# name: show_rules Synopsis

print $grammar->show_rules()
    or die "print failed: $ERRNO";

# Marpa::XS::Display::End

Marpa::XS::Test::is( ${$actual_ref},
    <<'END_RULES', 'Ambiguous Equation Rules' );
0: E -> E Op E
1: E -> Number
2: E['] -> E /* vlhs real=1 */
END_RULES

# Alternative tests: AHFA items if XS, NFA items if PP

if ($Marpa::XS::USING_XS) {

$actual_ref = save_stdout();

print $grammar->show_AHFA_items()
    or die "print failed: $ERRNO";

Marpa::XS::Test::is( ${$actual_ref},
    <<'EOS', 'Ambiguous Equation AHFA Items' );
AHFA item 0: sort = 0; postdot = "E"
    E -> . E Op E
AHFA item 1: sort = 3; postdot = "Op"
    E -> E . Op E
AHFA item 2: sort = 1; postdot = "E"
    E -> E Op . E
AHFA item 3: sort = 5; completion
    E -> E Op E .
AHFA item 4: sort = 4; postdot = "Number"
    E -> . Number
AHFA item 5: sort = 6; completion
    E -> Number .
AHFA item 6: sort = 2; postdot = "E"
    E['] -> . E
AHFA item 7: sort = 7; completion
    E['] -> E .
EOS

} # USING_XS

if ($Marpa::XS::USING_PP) {
    $actual_ref = save_stdout();
    print $grammar->show_NFA()
        or die "print failed: $ERRNO";
    Marpa::XS::Test::is( ${$actual_ref},
        <<'END_NFA', 'Ambiguous Equation NFA' );
S0: /* empty */
 empty => S7
S1: E -> . E Op E
 empty => S1 S5
 <E> => S2
S2: E -> E . Op E
 <Op> => S3
S3: E -> E Op . E
 empty => S1 S5
 <E> => S4
S4: E -> E Op E .
S5: E -> . Number
 <Number> => S6
S6: E -> Number .
S7: E['] -> . E
 empty => S1 S5
 <E> => S8
S8: E['] -> E .
END_NFA
} # USING_PP

$actual_ref = save_stdout();

# Marpa::XS::Display
# name: show_AHFA Synopsis

print $grammar->show_AHFA()
    or die "print failed: $ERRNO";

# Marpa::XS::Display::End

Marpa::XS::Test::is( ${$actual_ref},
    <<'END_AHFA', 'Ambiguous Equation AHFA' );
* S0:
E['] -> . E
 <E> => S2; leo(E['])
* S1: predict
E -> . E Op E
E -> . Number
 <E> => S3
 <Number> => S4
* S2: leo-c
E['] -> E .
* S3:
E -> E . Op E
 <Op> => S1; S5
* S4:
E -> Number .
* S5:
E -> E Op . E
 <E> => S6; leo(E)
* S6: leo-c
E -> E Op E .
END_AHFA

$actual_ref = save_stdout();

# Marpa::XS::Display
# name: show_problems Synopsis

print $grammar->show_problems()
    or die "print failed: $ERRNO";

# Marpa::XS::Display::End

Marpa::XS::Test::is(
    ${$actual_ref},
    "Grammar has no problems\n",
    'Ambiguous Equation Problems'
);

restore_stdout();

my $recce = Marpa::XS::Recognizer->new( { grammar => $grammar } );

$recce->tokens(
    [   [ 'Number', 2,    1 ],
        [ 'Op',     q{-}, 1 ],
        [ 'Number', 0,    1 ],
        [ 'Op',     q{*}, 1 ],
        [ 'Number', 3,    1 ],
        [ 'Op',     q{+}, 1 ],
        [ 'Number', 1,    1 ],
    ]
);

$actual_ref = save_stdout();

# Marpa::XS::Display
# name: show_earley_sets Synopsis

print $recce->show_earley_sets()
    or die "print failed: $ERRNO";

# Marpa::XS::Display::End

my $expected_earley_sets = <<'END_OF_EARLEY_SETS';
Last Completed: 7; Furthest: 7
Earley Set 0
S0@0-0
S1@0-0
Earley Set 1
S2@0-1 [p=S0@0-0; c=S4@0-1]
S3@0-1 [p=S1@0-0; c=S4@0-1]
S4@0-1 [p=S1@0-0; s=Number; t=\2]
Earley Set 2
S5@0-2 [p=S3@0-1; s=Op; t=\'-']
S1@2-2
Earley Set 3
S2@0-3 [p=S0@0-0; c=S6@0-3]
S3@0-3 [p=S1@0-0; c=S6@0-3]
S6@0-3 [p=S5@0-2; c=S4@2-3]
S3@2-3 [p=S1@2-2; c=S4@2-3]
S4@2-3 [p=S1@2-2; s=Number; t=\0]
Earley Set 4
S5@0-4 [p=S3@0-3; s=Op; t=\'*']
S5@2-4 [p=S3@2-3; s=Op; t=\'*']
S1@4-4
Earley Set 5
S2@0-5 [p=S0@0-0; c=S6@0-5]
S3@0-5 [p=S1@0-0; c=S6@0-5]
S6@0-5 [p=S5@0-2; c=S6@2-5] [p=S5@0-4; c=S4@4-5]
S3@2-5 [p=S1@2-2; c=S6@2-5]
S6@2-5 [p=S5@2-4; c=S4@4-5]
S3@4-5 [p=S1@4-4; c=S4@4-5]
S4@4-5 [p=S1@4-4; s=Number; t=\3]
Earley Set 6
S5@0-6 [p=S3@0-5; s=Op; t=\'+']
S5@2-6 [p=S3@2-5; s=Op; t=\'+']
S5@4-6 [p=S3@4-5; s=Op; t=\'+']
S1@6-6
Earley Set 7
S2@0-7 [p=S0@0-0; c=S6@0-7]
S3@0-7 [p=S1@0-0; c=S6@0-7]
S6@0-7 [p=S5@0-2; c=S6@2-7] [p=S5@0-4; c=S6@4-7] [p=S5@0-6; c=S4@6-7]
S3@2-7 [p=S1@2-2; c=S6@2-7]
S6@2-7 [p=S5@2-4; c=S6@4-7] [p=S5@2-6; c=S4@6-7]
S3@4-7 [p=S1@4-4; c=S6@4-7]
S6@4-7 [p=S5@4-6; c=S4@6-7]
S3@6-7 [p=S1@6-6; c=S4@6-7]
S4@6-7 [p=S1@6-6; s=Number; t=\1]
END_OF_EARLEY_SETS

Marpa::XS::Test::is( ${$actual_ref},
    $expected_earley_sets, 'Ambiguous Equation Earley Sets' );

restore_stdout();

$actual_ref = save_stdout();

# Marpa::XS::Display
# name: show_progress Synopsis

print $recce->show_progress()
    or die "print failed: $ERRNO";

# Marpa::XS::Display::End

Marpa::XS::Test::is( ${$actual_ref},
    <<'END_OF_PROGRESS_REPORT', 'Ambiguous Equation Progress Report' );
R0:1 x4 @0...6-7 E -> E . Op E
F0 x3 @0,2,4-7 E -> E Op E .
F1 @6-7 E -> Number .
F2 @0-7 E['] -> E .
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

# Marpa::XS::Display
# name: Recognizer set Synopsis

$recce->set( { max_parses => 10, } );

# Marpa::XS::Display::End

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
