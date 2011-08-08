#!/usr/bin/perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::PP.  Marpa::PP is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::PP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::PP.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
use strict;
use warnings;

use Test::More tests => 3;

use English qw( -no_match_vars );
use Fatal qw( open close );
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::PP');
}

my $progress_report = q{};

my $grammar = Marpa::Grammar->new(
    {   start         => 'S',
        strip         => 0,
        lhs_terminals => 0,
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

# Marpa::PP::Display::End

$grammar->precompute();

my @tokens = ( ['T'] ) x 20;

my $recce = Marpa::Recognizer->new( { grammar => $grammar } );

my $current_earleme = $recce->tokens( \@tokens );

# The call to current earlem is Useless,
# but provides an example for the docs

# Marpa::PP::Display
# name: current_earleme Example

$current_earleme = $recce->current_earleme();

# Marpa::PP::Display::End

$progress_report = $recce->show_progress();

my $value_ref = $recce->value;
Test::More::ok( $value_ref, 'Parse ok?' );

# Marpa::PP::Display
# name: Debug Leo Example Progress Report
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

Marpa::Test::is( $progress_report,
    <<'END_PROGRESS_REPORT', 'sorted progress report' );
F0 @0-20 S -> Top_sequence .
P1 @20-20 Top_sequence -> . Top Top_sequence
R1:1 @19-20 Top_sequence -> Top . Top_sequence
F1 x20 @0...19-20 Top_sequence -> Top Top_sequence .
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
F7 @0-20 S['] -> S .
END_PROGRESS_REPORT

# Marpa::PP::Display::End

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
