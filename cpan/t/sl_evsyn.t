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

test ::= a b c d e | ambig1 | ambig2
ambig1 ::= start1 mid1 z
ambig2 ::= start2 mid2 z
start1 ::= b  mid1 ::= c d
start2 ::= b c  mid2 ::= d

a ~ 'a' b ~ 'b' c ~ 'c' d ~ 'd' e ~ 'e'
z ~ 'z'

:lexeme ~ <a> pause => after event => 'a<'
:lexeme ~ <b> pause => after event => 'b<'
:lexeme ~ <e> pause => before event => '>e'

:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
my $slr = Marpa::R2::Scanless::R->new(
    { grammar => $grammar, semantics_package => 'My_Actions' } );
my $input = 'a b c d e';
my $length = length $input;
my $pos    = $slr->read( \$input );

my $actual_events = q{};

READ: while (1) {

    my @actual_events = ();

    EVENT:
    for my $event ( @{ $slr->events() } ) {
        my ($name) = @{$event};
        if ($name eq '>e') {
           $slr->lexeme_read('e', 'e');
        }
        push @actual_events, $name;
    }

    if (@actual_events) {
        $actual_events .= join q{ }, $pos, @actual_events;
        $actual_events .= "\n";
    }

    say STDERR $actual_events;

    last READ if $pos >= $length;
    $pos = $slr->resume($pos);
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
