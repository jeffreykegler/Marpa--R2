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
use Test::More tests => 3;

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

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar, } );

my $string = 'w x y z w x y z w';

read_input();

say "Ambiguity Metric: ", $recce->ambiguity_metric();
say "Ambiguity: ", $recce->ambiguous();

# Start a new recognizer, because we cannot call
# $r->ambiguous() and $r->value() on the same recognizer
$recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
read_input();

my $metric = $recce->ambiguity_metric();
Test::More::is($metric, 2, "Ambiguity Metric");

say $grammar->show_rules();
my $latest_earley_set = $recce->latest_earley_set();
for (my $i = 0; $i <= $latest_earley_set; $i++) {
    printf "=== Progress @%d ===\n", $i;
    print $recce->show_parse_items($i);
}

my %expected_value = (
    q{\['w','x',[['y','z','w','x','y','z','w']]]} => 1,
    q{[2]} => 1
);

my $i             = 0;
for my $actual_value ($recce->value()) {
    my $dumped_value = myDump( $actual_value );
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
    Test::More::ok("All expected values found");
}


sub read_input {
    $recce->read( \$string );
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
