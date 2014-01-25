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

# Rewriting tests, to check the accuracy of the
# tracing documentation.

use 5.010;
use strict;
use warnings;

use Fatal qw(open close);
use Test::More tests => 2;

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $chaf_rule = {
    lhs => 'statement',
    rhs => [
        qw/optional_whitespace expression
            optional_whitespace optional_modifier
            optional_whitespace/
    ]
};

my $separated_sequence_rule = {
    lhs       => 'statements',
    rhs       => [qw/statement/],
    separator => 'comma',
    min       => 1
};

our $null_parse = 'Null parse';

my $sequence_rule = {
    lhs    => 'block',
    rhs    => [qw/statements/],
    min    => 0,
    action => 'main::null_parse'
};

my $grammar = Marpa::R2::Grammar->new(
    {   start   => 'block',
        terminals => [qw(block whitespace modifier expression comma)],
        rules     => [
            $chaf_rule,
            $separated_sequence_rule,
            $sequence_rule,
            { lhs => 'optional_whitespace', rhs => [qw(whitespace)] },
            { lhs => 'optional_whitespace', },
            { lhs => 'optional_modifier',   rhs => [qw(modifier)] },
            { lhs => 'optional_modifier', },
        ],
    }
);

$grammar->precompute();

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

# While we are at it, test the handling of null parses in
# the Single Parse Evaluator
$recce->end_input();

# Marpa::R2::Display::End

my $show_rules_output = $grammar->show_rules();

Marpa::R2::Test::is( $show_rules_output, <<'END_RULES', 'Rewritten Rules' );
0: statement -> optional_whitespace expression optional_whitespace optional_modifier optional_whitespace
1: statements -> statement+ /* discard_sep */
2: block -> statements*
3: optional_whitespace -> whitespace
4: optional_whitespace -> /* empty !used */
5: optional_modifier -> modifier
6: optional_modifier -> /* empty !used */
END_RULES

my $value_ref = $recce->value();
my $value = $value_ref ? ${$value_ref} : 'No Parse';

Marpa::R2::Test::is( $value, 'Null parse', 'Null parse value' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
