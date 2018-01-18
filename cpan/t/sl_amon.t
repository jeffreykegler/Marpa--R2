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

# Bug found by amon: duplicate events when mixing external
# and internal scanning.

use 5.010001;
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 2;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $g = Marpa::R2::Scanless::G->new({
    source => \q{
        Top::= 'start' TOKEN OTHER_TOKEN
        TOKEN       ~ [^\s\S]
        OTHER_TOKEN ~ [^\s\S]
        event ev_token          = predicted TOKEN
        event ev_other_token    = predicted OTHER_TOKEN
    },
});
my $r = Marpa::R2::Scanless::R->new({ grammar => $g });

# This is the "control" -- a test before where the bug
# occurred, just to make sure the context is right.
$r->read(\"start_");
{
    my @events = map { $_->[0] } @{ $r->events };
    Test::More::is( (join q{ }, @events), q{ev_token}, 'before' );
}

# Now look where the bug occurred.
# The problem was that the "ev_token" from the previous
# check for events was not cleared.
$r->lexeme_read(TOKEN => 0, 1, "_");
{
    my @events = map { $_->[0] } @{ $r->events };
    # ev_token should NOT be reported here.
    Test::More::is( (join q{ }, @events), q{ev_other_token}, 'after' );
}
