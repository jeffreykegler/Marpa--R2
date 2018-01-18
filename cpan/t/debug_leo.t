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

use 5.010001;
use strict;
use warnings;

use Test::More tests => 2;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $progress_report = q{};

my $grammar = Marpa::R2::Grammar->new(
    {   start         => 'S',
        rules         => [
            { lhs => 'S',            rhs => [qw/Top_sequence/] },
            { lhs => 'Top_sequence', rhs => [qw/Top Top_sequence/] },
            { lhs => 'Top_sequence', rhs => [qw/Top/] },
            { lhs => 'Top',          rhs => [qw/Upper_Middle/] },
            { lhs => 'Upper_Middle', rhs => [qw/Lower_Middle/] },
            { lhs => 'Lower_Middle', rhs => [qw/Bottom/] },
            { lhs => 'Bottom',       rhs => [qw/T/] },
        ],
    }
);

# Marpa::R2::Display::End

$grammar->precompute();

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

my $current_earleme;
for (1 .. 20) {
    $current_earleme = $recce->read( 'T' );
}

# The call to current earlem is Useless,
# but provides an example for the docs

# Marpa::R2::Display
# name: current_earleme Example

$current_earleme = $recce->current_earleme();

# Marpa::R2::Display::End

$progress_report = $recce->show_progress();

my $value_ref = $recce->value;
Test::More::ok( $value_ref, 'Parse ok?' );

# Marpa::R2::Display
# name: Debug Leo Example Progress Report
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

Marpa::R2::Test::is( $progress_report,
    <<'END_PROGRESS_REPORT', 'sorted progress report' );
F0 @0-20 S -> Top_sequence .
P1 @20-20 Top_sequence -> . Top Top_sequence
R1:1 @19-20 Top_sequence -> Top . Top_sequence
F1 x19 @0...18-20 Top_sequence -> Top Top_sequence .
P2 @20-20 Top_sequence -> . Top
F2 @19-20 Top_sequence -> Top .
P3 @20-20 Top -> . Upper_Middle
F3 @19-20 Top -> Upper_Middle .
P4 @20-20 Upper_Middle -> . Lower_Middle
F4 @19-20 Upper_Middle -> Lower_Middle .
P5 @20-20 Lower_Middle -> . Bottom
F5 @19-20 Lower_Middle -> Bottom .
P6 @20-20 Bottom -> . T
F6 @19-20 Bottom -> T .
END_PROGRESS_REPORT

# Marpa::R2::Display::End

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
