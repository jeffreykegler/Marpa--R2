#!/usr/bin/perl
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

# Example for synopsis in POD for overview of SLIF parse events

use 5.010001;
use strict;
use warnings;

use Test::More tests => 2;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

# Marpa::R2::Display
# name: SLIF Event synopsis

sub forty_two { return 42; };

use Marpa::R2;

my $dsl = <<'END_OF_DSL';
:default ::= action => [name,values]
lexeme default = latm => 1

test ::= a b c d e e f g h action => main::forty_two
    | a ambig1 | a ambig2
e ::= <real e> | <null e>
<null e> ::=
g ::= g1 | g3
g1 ::= g2
g2 ::= 
g3 ::= g4
g4 ::= 
d ::= <real d> | <insert d>
ambig1 ::= start1 mid1 z
ambig2 ::= start2 mid2 z
start1 ::= b  mid1 ::= c d
start2 ::= b c  mid2 ::= d

a ~ 'a' b ~ 'b' c ~ 'c'
<real d> ~ 'd'
<insert d> ~ ["] 'insert d here' ["]
<real e> ~ 'e'
f ~ 'f'
h ~ 'h'
z ~ 'z'

:lexeme ~ <a> pause => after event => '"a"'
:lexeme ~ <b> pause => after event => '"b"'
:lexeme ~ <c> pause => after event => '"c"'
:lexeme ~ <real d> pause => after event => '"d"'
:lexeme ~ <insert d> pause => before event => 'insert d'
:lexeme ~ <real e> pause => after event => '"e"'
:lexeme ~ <f> pause => after event => '"f"'
:lexeme ~ <h> pause => after event => '"h"'

event '^test' = predicted test
event 'test$' = completed test
event '^start1' = predicted start1
event 'start1$' = completed start1
event '^start2' = predicted start2
event 'start2$' = completed start2
event '^mid1' = predicted mid1
event 'mid1$' = completed mid1
event '^mid2' = predicted mid2
event 'mid2$' = completed mid2

event '^a' = predicted a
event '^b' = predicted b
event '^c' = predicted c
event 'd[]' = nulled d
event 'd$' = completed d
event '^d' = predicted d
event '^e' = predicted e
event 'e[]' = nulled e
event 'e$' = completed e
event '^f' = predicted f
event 'g[]' = nulled g
event '^g' = predicted g
event 'g$' = completed g
event 'g1[]' = nulled g1
event 'g2[]' = nulled g2
event 'g3[]' = nulled g3
event 'g4[]' = nulled g4
event '^h' = predicted h

:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
my $slr = Marpa::R2::Scanless::R->new(
    { grammar => $grammar, semantics_package => 'My_Actions' } );

my $input = q{a b c "insert d here" e e f h};
my $length = length $input;
my $pos    = $slr->read( \$input );

my $actual_events = q{};

READ: while (1) {

    my @actual_events = ();

    my $next_lexeme;
    EVENT:
    for my $event ( @{ $slr->events() } ) {
        my ($name) = @{$event};
        if ($name eq 'insert d') {
           my (undef, $length) = $slr->pause_span();
           $next_lexeme = ['real d', 'd', $length];
        }
        push @actual_events, $name;
    }

    if (@actual_events) {
        $actual_events .= join q{ }, "Events at position $pos:", @actual_events;
        $actual_events .= "\n";
    }

    if ($next_lexeme) {
        $slr->lexeme_read(@{$next_lexeme});
        $pos = $slr->pos();
        next READ;
    }
    if ($pos < $length) {
        $pos = $slr->resume();
        next READ;
    }
    last READ;
} ## end READ: while (1)

my $expected_events = <<'=== EOS ===';
Events at position 0: ^test ^a
Events at position 1: "a" ^b ^start1 ^start2
Events at position 3: "b" start1$ ^c ^mid1
Events at position 5: "c" start2$ ^d ^mid2
Events at position 6: insert d
Events at position 21: d$ mid1$ mid2$ e[] ^e ^f
Events at position 23: "e" e$ e[] ^e ^f
Events at position 25: "e" e$ ^f
Events at position 27: "f" g[] g1[] g3[] g2[] g4[] ^h
Events at position 29: "h" test$
=== EOS ===

# Marpa::R2::Display::End

my $value_ref = $slr->value();
my $value = $value_ref ? ${$value_ref} : 'No Parse';

Marpa::R2::Test::is( $actual_events, $expected_events, 'SLIF parse event synopsis' );

Test::More::is( $value, 42, 'SLIF parse event synopsis value' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
