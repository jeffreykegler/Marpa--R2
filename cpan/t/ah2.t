#!perl
# Copyright 2013 Jeffrey Kegler
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

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use Test::More tests => 26;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . ( join q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'S',
        rules => [
            [ 'S', [qw/A A A A/] ],
            [ 'A', [qw/a/] ],
            [ 'A', [qw/E/] ],
            ['E'],
        ],
        default_action     => 'main::default_action',
    }
);

$grammar->set( { terminals => ['a'], } );

$grammar->precompute();

Marpa::R2::Test::is( $grammar->show_rules, <<'EOS', 'Aycock/Horspool Rules' );
0: S -> A A A A
1: A -> a
2: A -> E /* !used */
3: E -> /* empty !used */
EOS

Marpa::R2::Test::is( $grammar->show_symbols,
    <<'EOS', 'Aycock/Horspool Symbols' );
0: S
1: A
2: a, terminal
3: E, nulling
EOS

Marpa::R2::Test::is( $grammar->show_isys,
    <<'EOS', 'Aycock/Horspool ISYs' );
0: S
1: S[], nulling
2: A
3: A[], nulling
4: a
5: E[], nulling
6: S[R0:1]
7: S[R0:2]
8: S[']
EOS

Marpa::R2::Test::is( $grammar->show_irls,
    <<'EOS', 'Aycock/Horspool IRLs' );
0: S -> A S[R0:1]
1: S -> A A[] A[] A[]
2: S -> A[] S[R0:1]
3: S[R0:1] -> A S[R0:2]
4: S[R0:1] -> A A[] A[]
5: S[R0:1] -> A[] S[R0:2]
6: S[R0:2] -> A A
7: S[R0:2] -> A A[]
8: S[R0:2] -> A[] A
9: A -> a
10: S['] -> S
EOS

Marpa::R2::Test::is(
    $grammar->show_nulling_symbols,
    q{E},
    'Aycock/Horspool Nulling Symbols'
);
Marpa::R2::Test::is(
    $grammar->show_productive_symbols,
    q{A E S a},
    'Aycock/Horspool Productive Symbols'
);
Marpa::R2::Test::is(
    $grammar->show_accessible_symbols,
    q{A E S a},
    'Aycock/Horspool Accessible Symbols'
);

Marpa::R2::Test::is( $grammar->show_ahms(),
    <<'EOS', 'Aycock/Horspool AHFA Items' );
AHFA item 0: sort = 1; postdot = "A"
    S -> . A S[R0:1]
AHFA item 1: sort = 10; postdot = "S[R0:1]"
    S -> A . S[R0:1]
AHFA item 2: sort = 14; completion
    S -> A S[R0:1] .
AHFA item 3: sort = 2; postdot = "A"
    S -> . A A[] A[] A[]
AHFA item 4: sort = 15; completion
    S -> A A[] A[] A[] .
AHFA item 5: sort = 11; postdot = "S[R0:1]"
    S -> A[] . S[R0:1]
AHFA item 6: sort = 16; completion
    S -> A[] S[R0:1] .
AHFA item 7: sort = 3; postdot = "A"
    S[R0:1] -> . A S[R0:2]
AHFA item 8: sort = 12; postdot = "S[R0:2]"
    S[R0:1] -> A . S[R0:2]
AHFA item 9: sort = 17; completion
    S[R0:1] -> A S[R0:2] .
AHFA item 10: sort = 4; postdot = "A"
    S[R0:1] -> . A A[] A[]
AHFA item 11: sort = 18; completion
    S[R0:1] -> A A[] A[] .
AHFA item 12: sort = 13; postdot = "S[R0:2]"
    S[R0:1] -> A[] . S[R0:2]
AHFA item 13: sort = 19; completion
    S[R0:1] -> A[] S[R0:2] .
AHFA item 14: sort = 5; postdot = "A"
    S[R0:2] -> . A A
AHFA item 15: sort = 6; postdot = "A"
    S[R0:2] -> A . A
AHFA item 16: sort = 20; completion
    S[R0:2] -> A A .
AHFA item 17: sort = 7; postdot = "A"
    S[R0:2] -> . A A[]
AHFA item 18: sort = 21; completion
    S[R0:2] -> A A[] .
AHFA item 19: sort = 8; postdot = "A"
    S[R0:2] -> A[] . A
AHFA item 20: sort = 22; completion
    S[R0:2] -> A[] A .
AHFA item 21: sort = 9; postdot = "a"
    A -> . a
AHFA item 22: sort = 23; completion
    A -> a .
AHFA item 23: sort = 0; postdot = "S"
    S['] -> . S
AHFA item 24: sort = 24; completion
    S['] -> S .
EOS

Marpa::R2::Test::is( $grammar->show_AHFA, <<'EOS', 'Aycock/Horspool AHFA' );
* S0:
S['] -> . S
* S1: predict
S -> . A S[R0:1]
S -> . A A[] A[] A[]
S -> A[] . S[R0:1]
S[R0:1] -> . A S[R0:2]
S[R0:1] -> . A A[] A[]
S[R0:1] -> A[] . S[R0:2]
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
A -> . a
* S2:
S -> A . S[R0:1]
* S3: predict
S[R0:1] -> . A S[R0:2]
S[R0:1] -> . A A[] A[]
S[R0:1] -> A[] . S[R0:2]
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
A -> . a
* S4:
S -> A S[R0:1] .
* S5:
S -> A A[] A[] A[] .
* S6:
S -> A[] S[R0:1] .
* S7:
S[R0:1] -> A . S[R0:2]
* S8: predict
S[R0:2] -> . A A
S[R0:2] -> . A A[]
S[R0:2] -> A[] . A
A -> . a
* S9:
S[R0:1] -> A S[R0:2] .
* S10:
S[R0:1] -> A A[] A[] .
* S11:
S[R0:1] -> A[] S[R0:2] .
* S12:
S[R0:2] -> A . A
* S13: predict
A -> . a
* S14:
S[R0:2] -> A A .
* S15:
S[R0:2] -> A A[] .
* S16:
S[R0:2] -> A[] A .
* S17:
A -> a .
* S18:
S['] -> S .
EOS

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

my $expected_earley_sets = <<'END_OF_SETS';
Last Completed: 4; Furthest: 4
Earley Set 0
S0@0-0
S1@0-0
Earley Set 1
S2@0-1 [p=S1@0-0; c=S17@0-1]
S5@0-1 [p=S1@0-0; c=S17@0-1]
S6@0-1 [p=S1@0-0; c=S10@0-1] [p=S1@0-0; c=S11@0-1]
S7@0-1 [p=S1@0-0; c=S17@0-1]
S10@0-1 [p=S1@0-0; c=S17@0-1]
S11@0-1 [p=S1@0-0; c=S15@0-1] [p=S1@0-0; c=S16@0-1]
S12@0-1 [p=S1@0-0; c=S17@0-1]
S15@0-1 [p=S1@0-0; c=S17@0-1]
S16@0-1 [p=S1@0-0; c=S17@0-1]
S17@0-1 [p=S1@0-0; s=a; t=\'a']
S18@0-1 [p=S0@0-0; c=S5@0-1] [p=S0@0-0; c=S6@0-1]
S3@1-1
S8@1-1
S13@1-1
Earley Set 2
S4@0-2 [p=S2@0-1; c=S10@1-2] [p=S2@0-1; c=S11@1-2]
S6@0-2 [p=S1@0-0; c=S9@0-2] [p=S1@0-0; c=S11@0-2]
S9@0-2 [p=S7@0-1; c=S15@1-2] [p=S7@0-1; c=S16@1-2]
S11@0-2 [p=S1@0-0; c=S14@0-2]
S14@0-2 [p=S12@0-1; c=S17@1-2]
S18@0-2 [p=S0@0-0; c=S4@0-2] [p=S0@0-0; c=S6@0-2]
S7@1-2 [p=S3@1-1; c=S17@1-2]
S10@1-2 [p=S3@1-1; c=S17@1-2]
S11@1-2 [p=S3@1-1; c=S15@1-2] [p=S3@1-1; c=S16@1-2]
S12@1-2 [p=S3@1-1; c=S17@1-2] [p=S8@1-1; c=S17@1-2]
S15@1-2 [p=S3@1-1; c=S17@1-2] [p=S8@1-1; c=S17@1-2]
S16@1-2 [p=S3@1-1; c=S17@1-2] [p=S8@1-1; c=S17@1-2]
S17@1-2 [p=S3@1-1; s=a; t=\'a'] [p=S8@1-1; s=a; t=\'a'] [p=S13@1-1; s=a; t=\'a']
S8@2-2
S13@2-2
Earley Set 3
S4@0-3 [p=S2@0-1; c=S9@1-3] [p=S2@0-1; c=S11@1-3]
S6@0-3 [p=S1@0-0; c=S9@0-3]
S9@0-3 [p=S7@0-1; c=S14@1-3]
S18@0-3 [p=S0@0-0; c=S4@0-3] [p=S0@0-0; c=S6@0-3]
S9@1-3 [p=S7@1-2; c=S15@2-3] [p=S7@1-2; c=S16@2-3]
S11@1-3 [p=S3@1-1; c=S14@1-3]
S14@1-3 [p=S12@1-2; c=S17@2-3]
S12@2-3 [p=S8@2-2; c=S17@2-3]
S15@2-3 [p=S8@2-2; c=S17@2-3]
S16@2-3 [p=S8@2-2; c=S17@2-3]
S17@2-3 [p=S8@2-2; s=a; t=\'a'] [p=S13@2-2; s=a; t=\'a']
S13@3-3
Earley Set 4
S4@0-4 [p=S2@0-1; c=S9@1-4]
S18@0-4 [p=S0@0-0; c=S4@0-4]
S9@1-4 [p=S7@1-2; c=S14@2-4]
S14@2-4 [p=S12@2-3; c=S17@3-4]
S17@3-4 [p=S13@3-3; s=a; t=\'a']
END_OF_SETS

# say STDERR "AHFA:\n", $grammar->show_AHFA();

my $input_length = 4;
for (my $i = 0; $i < $input_length; $i++) {
    # say STDERR "Earley sets at $i:\n", $recce->show_earley_sets();
    $recce->read( 'a', 'a' );
}

# say STDERR "Earley sets at end:\n", $recce->show_earley_sets();

Marpa::R2::Test::is(
    $recce->show_earley_sets(1),
    $expected_earley_sets,
    'Aycock/Horspool Earley sets'
);

my @expected = map {
    +{ map { ( $_ => 1 ) } @{$_} }
    }
    [q{}],
    [qw( (a;;;) (;a;;) (;;a;) (;;;a) )],
    [qw( (a;a;;) (a;;a;) (a;;;a) (;a;a;) (;a;;a) (;;a;a) )],
    [qw( (a;a;a;) (a;a;;a) (a;;a;a) (;a;a;a) )],
    ['(a;a;a;a)'];

$recce->set( { max_parses => 20 } );

for my $i ( 0 .. $input_length ) {

    $recce->reset_evaluation();
    $recce->set( { end => $i } );
    my $expected = $expected[$i];

    while ( my $value_ref = $recce->value() ) {

        my $value = $value_ref ? ${$value_ref} : 'No parse';
        if ( defined $expected->{$value} ) {
            delete $expected->{$value};
            Test::More::pass(qq{Expected result for length=$i, "$value"});
        }
        else {
            Test::More::fail(qq{Unexpected result for length=$i, "$value"});
        }
    } ## end while ( my $value_ref = $recce->value() )

    for my $value ( keys %{$expected} ) {
        Test::More::fail(qq{Missing result for length=$i, "$value"});
    }
} ## end for my $i ( 0 .. $input_length )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
