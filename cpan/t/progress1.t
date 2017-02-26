#!perl
# Copyright 2015 Jeffrey Kegler
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

# Note: ah2.t and bocage.t folded into this test

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010001;
use strict;
use warnings;

use Test::More tests => 11;
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale(LC_ALL, "C");

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    my (undef, $v) = @_;
    my $v_count = scalar @{$v};
    return q{}   if $v_count <= 0;
    return $v->[0] if $v_count == 1;
    return '(' . ( join q{;}, @{$v}) . ')';
}

## use critic

my $dsl = <<'END_OF_DSL';
:default ::= action => main::default_action
:start ::= S
S ::= A A A A A A A
A ::=
A ::= 'a'
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new( {   source => \$dsl });

GRAMMAR_TESTS_FOLDED_FROM_ah2_t: {

Marpa::R2::Test::is( $grammar->show_rules, <<'EOS', 'Aycock/Horspool Rules' );
G1 R0 S ::= A A A A A A A
G1 R1 A ::=
G1 R2 A ::= 'a'
G1 R3 :start ::= S
EOS

Marpa::R2::Test::is( $grammar->show_symbols,
    <<'EOS', 'Aycock/Horspool Symbols' );
G1 S0 :start -- Internal G1 start symbol
G1 S1 'a' -- Internal lexical symbol for "'a'"
G1 S2 S
G1 S3 A
EOS

Marpa::R2::Test::is( $grammar->show_irls,
    <<'EOS', 'Aycock/Horspool IRLs' );
0: S -> A S[R0:1]
1: S -> A A[] A[] A[] A[] A[] A[]
2: S -> A[] S[R0:1]
3: S[R0:1] -> A S[R0:2]
4: S[R0:1] -> A A[] A[] A[] A[] A[]
5: S[R0:1] -> A[] S[R0:2]
6: S[R0:2] -> A S[R0:3]
7: S[R0:2] -> A A[] A[] A[] A[]
8: S[R0:2] -> A[] S[R0:3]
9: S[R0:3] -> A S[R0:4]
10: S[R0:3] -> A A[] A[] A[]
11: S[R0:3] -> A[] S[R0:4]
12: S[R0:4] -> A S[R0:5]
13: S[R0:4] -> A A[] A[]
14: S[R0:4] -> A[] S[R0:5]
15: S[R0:5] -> A A
16: S[R0:5] -> A A[]
17: S[R0:5] -> A[] A
18: A -> [Lex-0]
19: [:start] -> S
20: [:start]['] -> [:start]
EOS

}

my ($S_sym) = grep { $grammar->symbol_name($_) eq 'S' } $grammar->symbol_ids();
my ($target_rule) = grep { ($grammar->rule_expand($_))[0] eq $S_sym } $grammar->rule_ids();
my $target_rule_length = -1 + scalar (() = $grammar->rule_expand($target_rule));

my $recce = Marpa::R2::Scanless::R->new( {   grammar => $grammar });
my $input_length = 7;
my $input = ('a' x $input_length);
$recce->read( \$input );

sub earley_set_display {
    my ($earley_set) = @_;
    my @target_items =
      grep { $_->[0] eq $target_rule } @{ $recce->progress($earley_set) };
    my @data = ();
    for my $target_item (@target_items) {
        my ( $rule_id, $dot, $origin ) = @{$target_item};
        my $cooked_dot = $dot < 0 ? $target_rule_length : $dot;
        my $desc .=
            "S:$dot " . '@'
          . "$origin-$earley_set "
          . $grammar->show_dotted_rule( $rule_id, $cooked_dot );
        my @datum = ( $cooked_dot, $origin, $rule_id, $dot, $origin, $desc );
        push @data, \@datum;
    }
    my @sorted = map { $_->[-1] } sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @data;
    return join "\n", "=== Earley Set $earley_set ===", @sorted, '';
}

Marpa::R2::Test::is( earley_set_display(0), <<'EOS', 'Earley Set 0' );
=== Earley Set 0 ===
S:0 @0-0 S -> . A A A A A A A
S:1 @0-0 S -> A . A A A A A A
S:2 @0-0 S -> A A . A A A A A
S:3 @0-0 S -> A A A . A A A A
S:4 @0-0 S -> A A A A . A A A
S:5 @0-0 S -> A A A A A . A A
S:6 @0-0 S -> A A A A A A . A
EOS

Marpa::R2::Test::is( earley_set_display(1), <<'EOS', 'Earley Set 1' );
=== Earley Set 1 ===
S:1 @0-1 S -> A . A A A A A A
S:2 @0-1 S -> A A . A A A A A
S:3 @0-1 S -> A A A . A A A A
S:4 @0-1 S -> A A A A . A A A
S:5 @0-1 S -> A A A A A . A A
S:6 @0-1 S -> A A A A A A . A
S:-1 @0-1 S -> A A A A A A A .
EOS

Marpa::R2::Test::is( earley_set_display(2), <<'EOS', 'Earley Set 2' );
=== Earley Set 2 ===
S:2 @0-2 S -> A A . A A A A A
S:3 @0-2 S -> A A A . A A A A
S:4 @0-2 S -> A A A A . A A A
S:5 @0-2 S -> A A A A A . A A
S:6 @0-2 S -> A A A A A A . A
S:-1 @0-2 S -> A A A A A A A .
EOS

Marpa::R2::Test::is( earley_set_display(3), <<'EOS', 'Earley Set 3' );
=== Earley Set 3 ===
S:3 @0-3 S -> A A A . A A A A
S:4 @0-3 S -> A A A A . A A A
S:5 @0-3 S -> A A A A A . A A
S:6 @0-3 S -> A A A A A A . A
S:-1 @0-3 S -> A A A A A A A .
EOS

Marpa::R2::Test::is( earley_set_display(4), <<'EOS', 'Earley Set 4' );
=== Earley Set 4 ===
S:4 @0-4 S -> A A A A . A A A
S:5 @0-4 S -> A A A A A . A A
S:6 @0-4 S -> A A A A A A . A
S:-1 @0-4 S -> A A A A A A A .
EOS

Marpa::R2::Test::is( earley_set_display(5), <<'EOS', 'Earley Set 5' );
=== Earley Set 5 ===
S:5 @0-5 S -> A A A A A . A A
S:6 @0-5 S -> A A A A A A . A
S:-1 @0-5 S -> A A A A A A A .
EOS

Marpa::R2::Test::is( earley_set_display(6), <<'EOS', 'Earley Set 6' );
=== Earley Set 6 ===
S:6 @0-6 S -> A A A A A A . A
S:-1 @0-6 S -> A A A A A A A .
EOS

Marpa::R2::Test::is( earley_set_display(7), <<'EOS', 'Earley Set 7' );
=== Earley Set 7 ===
S:-1 @0-7 S -> A A A A A A A .
EOS

# vim: expandtab shiftwidth=4:
