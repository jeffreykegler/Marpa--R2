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

# Debug Sequence Example

use 5.010001;
use strict;
use warnings;

use Test::More tests => 3;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $progress_report = q{};

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'Document',
        rules => [ { lhs => 'Document', rhs => [qw/Stuff/], min => 1 }, ],
    }
);

$grammar->precompute();

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

# Marpa::R2::Display
# name: Recognizer check_terminal Synopsis

my $is_symbol_a_terminal = $recce->check_terminal('Document');

# Marpa::R2::Display::End

Test::More::ok( !$is_symbol_a_terminal, 'LHS terminal?' );

my $token_ix = 0;

$recce->read('Stuff');
$recce->read('Stuff');
$recce->read('Stuff');

$progress_report = $recce->show_progress(0);

my $value_ref = $recce->value;
Test::More::ok( $value_ref, 'Parse ok?' );

Marpa::R2::Test::is( $progress_report,
    << 'END_PROGRESS_REPORT', 'progress report' );
P0 @0-0 Document -> . Stuff+
END_PROGRESS_REPORT

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
