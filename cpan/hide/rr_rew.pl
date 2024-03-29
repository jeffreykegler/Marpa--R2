#!perl
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
# The example from p. 166 of Leo's paper,
# augmented to test Leo prediction items.
#

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    { 
        source => \(<<'END_OF_DSL'),
top ::= break_rr 'x' | rr 'y'
break_rr ::= spacer lr
spacer ::= spacer a
spacer ::= a
lr ::= lr rr a
lr ::= a
rr ::= a rr
rr ::= a
a ::= 'a'
END_OF_DSL
    }
);

my $recce         = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
my $input         = ('a' x 20) . 'y';
my $pos           = $recce->read( \$input, 0, 0 );
READ: while (1) {
    $pos = $recce->resume($pos, 1);
    $pos // die;
    last READ if $pos >= length $input;
    say 'Earley set size ', $recce->earley_set_size();
    say $recce->show_progress();
} ## end READ: while (1)
say $recce->show_progress();
my $value_ref = $recce->value();
my $value = $value_ref ? ${$value_ref} : 'No parse';

Marpa::R2::Test::is( $value,         'aaa',           'Leo SLIF parse' );

# vim: expandtab shiftwidth=4:
