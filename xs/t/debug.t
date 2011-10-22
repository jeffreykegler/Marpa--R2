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

use 5.010;
use strict;
use warnings;

use Test::More tests => 4;

use English qw( -no_match_vars );
use Fatal qw( open close );
use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

my $progress_report = q{};

# Marpa::XS::Display
# name: Debug Example Part 1

my $grammar = Marpa::Grammar->new(
    {   start          => 'Expression',
        actions        => 'My_Actions',
        default_action => 'first_arg',
        strip          => 0,
        rules          => [
            ## This is a deliberate error in the grammar
            ## The next line should be:
            ## { lhs => 'Expression', rhs => [qw/Term/] },
            ## I have changed the Term to 'Factor' which
            ## will cause problems.
            { lhs => 'Expression', rhs => [qw/Factor/] },
            { lhs => 'Term',       rhs => [qw/Factor/] },
            { lhs => 'Factor',     rhs => [qw/Number/] },
            {   lhs    => 'Term',
                rhs    => [qw/Term Add Term/],
                action => 'do_add'
            },
            {   lhs    => 'Factor',
                rhs    => [qw/Factor Multiply Factor/],
                action => 'do_multiply'
            },
        ],
    }
);

# Marpa::XS::Display::End

## no critic (InputOutput::RequireBriefOpen)
open my $trace_fh, q{>}, \( my $trace_output = q{} );
## use critic

# Marpa::XS::Display
# name: Grammar set Synopsis

$grammar->set( { trace_file_handle => $trace_fh } );

# Marpa::XS::Display::End

# Marpa::XS::Display
# name: Debug Example Part 2

$grammar->precompute();

my @tokens = (
    [ 'Number',   42 ],
    [ 'Multiply', q{*} ],
    [ 'Number',   1 ],
    [ 'Add',      q{+} ],
    [ 'Number',   7 ],
);

sub My_Actions::do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub My_Actions::do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}

sub My_Actions::first_arg { shift; return shift; }

my $recce =
    Marpa::Recognizer->new( { grammar => $grammar, trace_terminals => 2 } );

my $token_ix = 0;

TOKEN: for my $token_and_value (@tokens) {
    last TOKEN if not defined $recce->read( @{$token_and_value} );
}

$progress_report = $recce->show_progress( 0, -1 );

# Marpa::XS::Display::End

my $value_ref = $recce->value;
my $value = $value_ref ? ${$value_ref} : 'No Parse';

Test::More::is( $value, 42, 'value' );

# Marpa::XS::Display
# name: Debug Example Progress Report
# start-after-line: END_PROGRESS_REPORT
# end-before-line: '^END_PROGRESS_REPORT$'

Marpa::Test::is( $progress_report,
    <<'END_PROGRESS_REPORT', 'progress report' );
P0 @0-0 Expression -> . Factor
P2 @0-0 Factor -> . Number
P4 @0-0 Factor -> . Factor Multiply Factor
P5 @0-0 Expression['] -> . Expression
F0 @0-1 Expression -> Factor .
F2 @0-1 Factor -> Number .
R4:1 @0-1 Factor -> Factor . Multiply Factor
F5 @0-1 Expression['] -> Expression .
P2 @2-2 Factor -> . Number
P4 @2-2 Factor -> . Factor Multiply Factor
R4:2 @0-2 Factor -> Factor Multiply . Factor
F0 @0-3 Expression -> Factor .
F2 @2-3 Factor -> Number .
R4:1 x2 @0,2-3 Factor -> Factor . Multiply Factor
F4 @0-3 Factor -> Factor Multiply Factor .
F5 @0-3 Expression['] -> Expression .
END_PROGRESS_REPORT

# Marpa::XS::Display::End

# Marpa::XS::Display
# name: Debug Example Trace Output
# start-after-line: END_TRACE_OUTPUT
# end-before-line: '^END_TRACE_OUTPUT$'

Marpa::Test::is( $trace_output, <<'END_TRACE_OUTPUT', 'trace output' );
Inaccessible symbol: Add
Inaccessible symbol: Term
Setting trace_terminals option
Expecting "Expression" at earleme 0
Expecting "Factor" at earleme 0
Expecting "Number" at earleme 0
Accepted "Number" at 0-1
Expecting "Multiply" at 1
Accepted "Multiply" at 1-2
Expecting "Factor" at 2
Expecting "Number" at 2
Accepted "Number" at 2-3
Expecting "Multiply" at 3
Rejected "Add" at 3-4
END_TRACE_OUTPUT

# Marpa::XS::Display::End

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
