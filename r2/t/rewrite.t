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

# Rewriting tests, to check the accuracy of the
# tracing documentation.

use 5.010;
use strict;
use warnings;

use Fatal qw(open close);
use Test::More tests => 3;

use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

my $chaf_rule =
#<<< no perltidy
# Marpa::XS::Display
# name: CHAF Rule

{   lhs => 'statement',
    rhs => [
        qw/optional_whitespace expression
            optional_whitespace optional_modifier
            optional_whitespace/
    ]
}

# Marpa::XS::Display::End
; # semicolon to terminate rule

#>>> no perltidy

my $separated_sequence_rule =
#<<< no perltidy
# Marpa::XS::Display
# name: Separated Sequence Rule

{
    lhs       => 'statements',
    rhs       => [qw/statement/],
    separator => 'comma',
    min       => 1
}

# Marpa::XS::Display::End
; # semicolon to terminate rule

#>>> no perltidy

my $sequence_rule =
#<<< no perltidy
# Marpa::XS::Display
# name: Sequence Rule

    { lhs => 'block', rhs => [qw/statements/], min => 0 },

# Marpa::XS::Display::End
; # semicolon to terminate rule

#>>> no perltidy

my $grammar = Marpa::Grammar->new(
    {   start   => 'block',
        strip   => 0,
        symbols => {
            'block' => {
                terminal   => 1,
                null_value => 'Null parse'
            }
        },
        terminals => [qw(whitespace modifier expression comma)],
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

my $recce = Marpa::Recognizer->new( { grammar => $grammar } );

# While we are at it, test the handling of null parses in
# the Single Parse Evaluator
my @tokens = ();

$recce->tokens( \@tokens );

# Marpa::XS::Display::End

my $show_rules_output = $grammar->show_rules();

# Marpa::XS::Display
# name: Rewrite show_rules Output
# start-after-line: END_RULES
# end-before-line: '^END_RULES$'

Marpa::Test::is( $show_rules_output, <<'END_RULES', 'Rewritten Rules' );
0: statement -> optional_whitespace expression optional_whitespace optional_modifier optional_whitespace /* !used */
1: statements -> statement /* !used discard_sep */
2: statements -> statements[Subseq:8:5] /* vrhs real=0 */
3: statements -> statements[Subseq:8:5] comma /* vrhs real=1 */
4: statements[Subseq:8:5] -> statement /* vlhs real=1 */
5: statements[Subseq:8:5] -> statements[Subseq:8:5] comma statement /* vlhs vrhs real=2 */
6: block -> statements /* !used */
7: block -> /* empty !used */
8: block -> block[Subseq:0:8] /* vrhs real=0 */
9: block[Subseq:0:8] -> statements /* vlhs real=1 */
10: block[Subseq:0:8] -> block[Subseq:0:8] statements /* vlhs vrhs real=1 */
11: optional_whitespace -> whitespace
12: optional_whitespace -> /* empty !used */
13: optional_modifier -> modifier
14: optional_modifier -> /* empty !used */
15: statement -> optional_whitespace expression statement[R0:2] /* vrhs real=2 */
16: statement -> optional_whitespace expression optional_whitespace[] optional_modifier[] optional_whitespace[]
17: statement -> optional_whitespace[] expression statement[R0:2] /* vrhs real=2 */
18: statement -> optional_whitespace[] expression optional_whitespace[] optional_modifier[] optional_whitespace[]
19: statement[R0:2] -> optional_whitespace statement[R0:3] /* vlhs vrhs real=1 */
20: statement[R0:2] -> optional_whitespace optional_modifier[] optional_whitespace[] /* vlhs real=3 */
21: statement[R0:2] -> optional_whitespace[] statement[R0:3] /* vlhs vrhs real=1 */
22: statement[R0:3] -> optional_modifier optional_whitespace /* vlhs real=2 */
23: statement[R0:3] -> optional_modifier optional_whitespace[] /* vlhs real=2 */
24: statement[R0:3] -> optional_modifier[] optional_whitespace /* vlhs real=2 */
25: block['] -> block /* vlhs real=1 */
26: block['][] -> /* empty vlhs real=1 */
END_RULES

# Marpa::XS::Display::End

my $value_ref = $recce->value();
my $value = $value_ref ? ${$value_ref} : 'No Parse';

Marpa::Test::is( $value, 'Null parse', 'Null parse value' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
