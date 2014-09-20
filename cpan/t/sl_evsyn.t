#!/usr/bin/perl
# Copyright 2014 Jeffrey Kegler
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

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

# Marpa::R2::Display
# name: Event synopsis

use Marpa::R2;

my $dsl = <<'END_OF_DSL';
:default ::= action => [name,values]
lexeme default = latm => 1

test ::= a b c d e f | a ambig1 | a ambig2
e ::= <real e> | <null e>
<null e> ::=
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
z ~ 'z'

:lexeme ~ <a> pause => after event => '"a"'
:lexeme ~ <b> pause => after event => '"b"'
:lexeme ~ <c> pause => after event => '"c"'
:lexeme ~ <real d> pause => after event => '"d"'
:lexeme ~ <insert d> pause => before event => 'insert d'
:lexeme ~ <real e> pause => after event => '"e"'
:lexeme ~ <f> pause => after event => '"f"'

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

event '^c' = predicted c
event 'd[]' = nulled d
event 'd$' = completed d
event '^d' = predicted d
event '^e' = predicted e
event 'e[]' = nulled e
event 'e$' = completed e

:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
my $slr = Marpa::R2::Scanless::R->new(
    { grammar => $grammar, semantics_package => 'My_Actions',
    trace_terminals => 99 } );
my $input = q{a b c "insert d here" e f};
my $length = length $input;
my $pos    = $slr->read( \$input );

my $actual_events = q{};

READ: while (1) {

    my @actual_events = ();

    my $next_lexeme;
    EVENT:
    for my $event ( @{ $slr->events() } ) {
        my ($name) = @{$event};
        say STDERR "$pos $name";
        if ($name eq 'insert d') {
           my (undef, $length) = $slr->pause_span();
           $next_lexeme = ['real d', 'd', $length];
        }
        push @actual_events, $name;
    }

    if (@actual_events) {
        $actual_events .= join q{ }, $pos, @actual_events;
        $actual_events .= "\n";
    }

    if ($next_lexeme) {
        say STDERR join q{ }, 'lexeme_read:', @{$next_lexeme};
        $slr->lexeme_read(@{$next_lexeme});
        next READ;
    }
    if ($pos < $length) {
        $pos = $slr->resume();
        next READ;
    }
    last READ;
} ## end READ: while (1)

my $expected_events = <<'=== EOS ===';
=== EOS ===

Test::More::is( $actual_events, $expected_events, 'SLIF parse event synopsis' );

# Marpa::R2::Display::End

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
