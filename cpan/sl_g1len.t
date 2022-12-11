#!/usr/bin/perl
# Copyright 2022 Jeffrey Kegler
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

# Dave Abrahams marpabook repo issue 3
# Extended grammar

use 5.010001;
use strict;
use warnings;
use Scalar::Util;
use Data::Dumper;
use Test::More tests => 5;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

say 'Libmarpa tag: ' . Marpa::R2::Thin::tag();

my $bnf = <<'END_OF_BNF';
:default ::= action => [values]
lexeme default = latm => 1
A ::= 'w' 'x' B | 'w'
B ::= C
C ::= 'y' 'z' A
C ::= 'y' 'z' 'w' 'x' 'y' 'z' 'w'

:discard ~ whitespace
whitespace ~ [\s]+
END_OF_BNF

sub My_Actions::do_rule {
    my ( undef, $t1, undef, $t2 ) = @_;
    return [$t1, @{$t2}];
}

my $grammar = Marpa::R2::Scanless::G->new(
    {  
        source          => \$bnf,
    }
);

my $string = 'w x y z w x y z w';

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
$recce->read( \$string );

my $metric = $recce->ambiguity_metric();
Test::More::is($metric, 2, "Ambiguity Metric");

my $expected_items = <<'END_OF_ITEMS';
=== Progress @0 ===
P0 @0-0 L0c0 A -> . 'w' 'x' B
P1 @0-0 L0c0 A -> . 'w'
P5 @0-0 L0c0 :start -> . A
=== Progress @1 ===
R0:1 @0-1 L1c1 A -> 'w' . 'x' B
F1 @0-1 L1c1 A -> 'w' .
F5 @0-1 L1c1 :start -> A .
=== Progress @2 ===
R0:2 @0-2 L1c1-3 A -> 'w' 'x' . B
P2 @2-2 L1c3 B -> . C
P3 @2-2 L1c3 C -> . 'y' 'z' A
P4 @2-2 L1c3 C -> . 'y' 'z' 'w' 'x' 'y' 'z' 'w'
L2 [[A -> 'w' 'x' . B]; "B"; 0]
L2 [[A -> 'w' 'x' . B]; "C"; 2]
=== Progress @3 ===
R3:1 @2-3 L1c3-5 C -> 'y' . 'z' A
R4:1 @2-3 L1c3-5 C -> 'y' . 'z' 'w' 'x' 'y' 'z' 'w'
=== Progress @4 ===
P0 @4-4 L1c7 A -> . 'w' 'x' B
P1 @4-4 L1c7 A -> . 'w'
R3:2 @2-4 L1c3-7 C -> 'y' 'z' . A
R4:2 @2-4 L1c3-7 C -> 'y' 'z' . 'w' 'x' 'y' 'z' 'w'
L4 [[A -> 'w' 'x' . B]; "A"; 2]
=== Progress @5 ===
R0:1 @4-5 L1c7-9 A -> 'w' . 'x' B
F0 @0-5 L1c1-9 A -> 'w' 'x' B .
F1 @4-5 L1c7-9 A -> 'w' .
F2 @2-5 L1c3-9 B -> C .
F3 @2-5 L1c3-9 C -> 'y' 'z' A .
R4:3 @2-5 L1c3-9 C -> 'y' 'z' 'w' . 'x' 'y' 'z' 'w'
F5 @0-5 L1c1-9 :start -> A .
=== Progress @6 ===
R0:2 @4-6 L1c7-11 A -> 'w' 'x' . B
P2 @6-6 L1c11 B -> . C
P3 @6-6 L1c11 C -> . 'y' 'z' A
P4 @6-6 L1c11 C -> . 'y' 'z' 'w' 'x' 'y' 'z' 'w'
R4:4 @2-6 L1c3-11 C -> 'y' 'z' 'w' 'x' . 'y' 'z' 'w'
L6 [[A -> 'w' 'x' . B]; "B"; 4]
L6 [[A -> 'w' 'x' . B]; "C"; 6]
=== Progress @7 ===
R3:1 @6-7 L1c11-13 C -> 'y' . 'z' A
R4:1 @6-7 L1c11-13 C -> 'y' . 'z' 'w' 'x' 'y' 'z' 'w'
R4:5 @2-7 L1c3-13 C -> 'y' 'z' 'w' 'x' 'y' . 'z' 'w'
=== Progress @8 ===
P0 @8-8 L1c15 A -> . 'w' 'x' B
P1 @8-8 L1c15 A -> . 'w'
R3:2 @6-8 L1c11-15 C -> 'y' 'z' . A
R4:2 @6-8 L1c11-15 C -> 'y' 'z' . 'w' 'x' 'y' 'z' 'w'
R4:6 @2-8 L1c3-15 C -> 'y' 'z' 'w' 'x' 'y' 'z' . 'w'
L8 [[A -> 'w' 'x' . B]; "A"; 6]
=== Progress @9 ===
R0:1 @8-9 L1c15-17 A -> 'w' . 'x' B
F0 x2 @0,4-9 L1c1-17 A -> 'w' 'x' B .
F1 @8-9 L1c15-17 A -> 'w' .
F2 x2 @2,6-9 L1c3-17 B -> C .
F3 x2 @2,6-9 L1c3-17 C -> 'y' 'z' A .
R4:3 @6-9 L1c11-17 C -> 'y' 'z' 'w' . 'x' 'y' 'z' 'w'
F4 @2-9 L1c3-17 C -> 'y' 'z' 'w' 'x' 'y' 'z' 'w' .
F5 @0-9 L1c1-17 :start -> A .
END_OF_ITEMS

my @actual_items = ();
my $latest_earley_set = $recce->latest_earley_set();
for (my $i = 0; $i <= $latest_earley_set; $i++) {
    push @actual_items, (sprintf "=== Progress @%d ===\n", $i);
    push @actual_items, $recce->show_parse_items($i);
}
my $actual_items = join '', @actual_items;

Test::More::is($actual_items, $expected_items, "Parse items");

my %expected_value = (
    q{\['w','x',[['y','z','w','x','y','z','w']]]} => 1,
    q{\['w','x',[['y','z',['w','x',[['y','z',['w']]]]]]]} => 1,
);

my $i             = 0;
VALUE: while (1) {
    my $value_ref = $recce->value();
    last VALUE if not defined $value_ref;
    my $dumped_value = myDump( $value_ref );
    # say STDERR "Got: $dumped_value";
    if ( defined $expected_value{$dumped_value} ) {
        delete $expected_value{$dumped_value};
        Test::More::pass("Expected Value $i: $dumped_value");
    }
    else {
        Test::More::fail("Unexpected Value $i: $dumped_value");
    }
    $i++;
}
my @not_found       = keys %expected_value;
my $not_found_count = scalar @not_found;
if ($not_found_count) {
    Test::More::fail("$not_found_count expected value(s) not found");
    for my $value (@not_found) {
        Test::More::diag("$value");
    }
}
else {
    Test::More::pass("All expected values found");
}

sub main::dwim {
    my @result = ();
    shift;
    ARG: for my $v ( @_ ) {
        next ARG if not $v;
        my $type = Scalar::Util::reftype $v;
        if (not $type or $type ne 'ARRAY') {
           push @result, $v;
           next ARG;
        }
        my $size = scalar @{$v};
        next ARG if $size == 0;
        if ($size == 1) {
           push @result, ${$v}[0];
           next ARG;
        }
        push @result, $v;
    }
    return [@result];
}

sub myDump {
    my $v = shift;
    return Data::Dumper->new( [$v] )->Indent(0)->Terse(1)->Dump;
}

# vim: expandtab shiftwidth=4:
