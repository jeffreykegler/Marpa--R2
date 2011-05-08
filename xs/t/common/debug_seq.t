#!/usr/bin/perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

# Debug Sequence Example

use 5.010;
use strict;
use warnings;

use Test::More tests => 4;

use English qw( -no_match_vars );
use Fatal qw( open close );
use Marpa::XS::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

my $progress_report = q{};

# Marpa::XS::Display
# name: Debug Sequence Example

my $grammar = Marpa::XS::Grammar->new(
    {   start         => 'Document',
        strip         => 0,
        lhs_terminals => 0,
        rules => [ { lhs => 'Document', rhs => [qw/Stuff/], min => 1 }, ],
    }
);

# Marpa::XS::Display::End

$grammar->precompute();

my @tokens = ( ( ['Stuff'] ) x 3 );

my $recce =
    Marpa::XS::Recognizer->new( { grammar => $grammar, mode => 'stream' } );

# Marpa::XS::Display
# name: Recognizer check_terminal Synopsis

my $is_document_a_terminal = $recce->check_terminal('Document');

# Marpa::XS::Display::End

Test::More::ok( !$is_document_a_terminal, 'LHS terminal?' );

my $token_ix = 0;

my ( $current_earleme, $expected_tokens ) =
    $recce->tokens( \@tokens, \$token_ix );

$progress_report = $recce->show_progress(0);

my $value_ref = $recce->value;
Test::More::ok( $value_ref, 'Parse ok?' );

# Marpa::XS::Display
# name: Debug Sequence Example Progress Report
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

Marpa::XS::Test::is( $progress_report,
    << 'END_PROGRESS_REPORT', 'progress report' );
P1 @0-0 Document -> . Document[Subseq:0:1]
P2 @0-0 Document[Subseq:0:1] -> . Stuff
P3 @0-0 Document[Subseq:0:1] -> . Document[Subseq:0:1] Stuff
P4 @0-0 Document['] -> . Document
END_PROGRESS_REPORT

# Marpa::XS::Display::End

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
