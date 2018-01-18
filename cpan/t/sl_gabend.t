#!perl
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

# Note: Converted from gabend.t

# Test grammar exceptions -- make sure problems actually
# are detected.  These tests are for problems which are supposed
# to abend.

use 5.010001;

use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 14;
use Fatal qw(open close);
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale(LC_ALL, "C");

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . join( q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

sub test_grammar {
    my ( $test_name, $dsl, $expected_error ) = @_;
    my $trace;
    my $memory;
    my $eval_ok = eval {
        my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
        1;
    };
    my $eval_error = $EVAL_ERROR;
    if ($eval_ok) {
        Test::More::fail("Failed to catch problem: $test_name");
    }
    else {
        $eval_error =~ s/ ^ Marpa::R2 \s+ exception \s+ at \s+ .* \z //xms;
        Marpa::R2::Test::is( $eval_error, $expected_error,
            "Successfully caught problem: $test_name" );
    }
    return;
}

if (1) {
    my $counted_nullable_grammar = <<'END_OF_DSL';
    S ::= Seq*
    Seq ::= A
    A ::=
END_OF_DSL

    test_grammar(
        'counted nullable',
        $counted_nullable_grammar,
        qq{Nullable symbol "Seq" is on RHS of counted rule\n}
          . qq{Counted nullables confuse Marpa -- please rewrite the grammar\n}
    );
}

if (1) {
        my $duplicate_rule_grammar = <<'END_OF_DSL';
    Top ::= Dup
    Dup ::= Item
    Dup ::= Item
    Item ::= a
END_OF_DSL
        test_grammar( 'duplicate rule',
            $duplicate_rule_grammar, <<'EOS');
Duplicate rule: Dup -> Item
EOS
}

if (1) {
        my $unique_lhs_grammar = <<'END_OF_DSL';
    Top ::= Dup
    Dup ::= Item*
    Dup ::= Item
    Item ::= a
END_OF_DSL
        test_grammar( 'unique_lhs', $unique_lhs_grammar, <<'EOS');
LHS of sequence rule would not be unique: Dup -> Item
EOS
}

# Duplicate precedenced LHS: 2 precedenced rules
if (1) {
        my $unique_lhs_grammar = <<'END_OF_DSL';
    Top ::= Dup
    Dup ::= Dup '+' Dup || Dup '-' Dup || Item1
    Dup ::= Dup '*' Dup || Dup '/' Dup || Item2
    Item1 ::= a
    Item2 ::= a
    a ~ 'a'
END_OF_DSL
        test_grammar( 'dup precedenced lhs', $unique_lhs_grammar, <<'EOS');
Duplicate rule: Dup -> Dup[0]
EOS
}

# Duplicate precedenced LHS: precedenced, then empty
if (1) {
    my $bad_lexeme_grammar = <<'END_OF_DSL';
    Top ::= Bad
    Top ::= Good
    Bad ::=
    Bad ~ [\d\D]
    Good ~ [\d\D]
END_OF_DSL
    test_grammar(
        'lexeme on G1 LHS',
        $bad_lexeme_grammar,
        <<'END_OF_MESSAGE'
<Bad> is a lexeme but it is not a legal lexeme in G1:
   Lexemes must be G1 symbols that do not appear on a G1 LHS.
END_OF_MESSAGE
    );
}

if (1) {
    my $bad_lexeme_grammar = <<'END_OF_DSL';
    Top ::= A
    A ::=
    Bad ~ [\d\D]
END_OF_DSL
    test_grammar(
        'lexeme not on G1 RHS',
        $bad_lexeme_grammar,
        <<'END_OF_MESSAGE'
<Bad> is a lexeme but it is not a legal lexeme in G1:
   Lexemes must be G1 symbols that do not appear on a G1 LHS.
END_OF_MESSAGE
    );
}

if (1) {
    my $bad_lexeme_grammar = <<'END_OF_DSL';
    Top ::= Bad | Good
    Good ~ [\d\D]
END_OF_DSL
    test_grammar(
        'lexeme not on L0 LHS',
        $bad_lexeme_grammar,
        <<'END_OF_MESSAGE'
A lexeme in G1 is not a lexeme in any of the lexers: Bad
END_OF_MESSAGE
    );
}

if (1) {
    my $bad_lexeme_grammar = <<'END_OF_DSL';
    Top ::= Bad | Good
    Good ~ Bad
    Bad ~ [\d\D]
END_OF_DSL
    test_grammar(
        'lexeme on L0 RHS',
        $bad_lexeme_grammar,
        <<'END_OF_MESSAGE'
A lexeme in G1 is not a lexeme in any of the lexers: Bad
END_OF_MESSAGE
    );
}

if (1) {
    my $bad_lexeme_grammar = <<'END_OF_DSL';
    :lexeme ~ <Bad>
    Top ::= Bad
    Bad ::= Good
    Bad ~ [\d\D]
    Good ~ [\d\D]
END_OF_DSL
    test_grammar(
        'declared lexeme on G1 LHS',
        $bad_lexeme_grammar,
        <<'END_OF_MESSAGE'
<Bad> is a lexeme but it is not a legal lexeme in G1:
   Lexemes must be G1 symbols that do not appear on a G1 LHS.
END_OF_MESSAGE
    );
}

if (1) {
    my $bad_lexeme_grammar = <<'END_OF_DSL';
    :lexeme ~ <Bad>
    Top ::= A
    A ::=
    Bad ~ [\d\D]
END_OF_DSL
    test_grammar(
        'declared lexeme not on G1 RHS',
        $bad_lexeme_grammar,
        <<'END_OF_MESSAGE'
<Bad> is a lexeme but it is not a legal lexeme in G1:
   Lexemes must be G1 symbols that do not appear on a G1 LHS.
END_OF_MESSAGE
    );
}

if (1) {
    my $bad_lexeme_grammar = <<'END_OF_DSL';
    :lexeme ~ <Bad>
    Top ::= Bad | Good
    Good ~ [\d\D]
END_OF_DSL
    test_grammar(
        'declared lexeme not on L0 LHS',
        $bad_lexeme_grammar,
        <<'END_OF_MESSAGE'
A lexeme in G1 is not a lexeme in any of the lexers: Bad
END_OF_MESSAGE
    );
}

if (1) {
    my $bad_lexeme_grammar = <<'END_OF_DSL';
    :lexeme ~ <Bad>
    Top ::= Bad | Good
    Good ~ Bad
    Bad ~ [\d\D]
END_OF_DSL
    test_grammar(
        'declared lexeme on L0 RHS',
        $bad_lexeme_grammar,
        <<'END_OF_MESSAGE'
A lexeme in G1 is not a lexeme in any of the lexers: Bad
END_OF_MESSAGE
    );
}

if (1) {
    my $start_not_lhs_grammar = <<'END_OF_DSL';
    inaccessible is fatal by default
    :start ::= Bad
    Top ::= Bad
    Bad ~ [\d\D]
END_OF_DSL
    test_grammar(
        'start symbol not on lhs',
        $start_not_lhs_grammar,
        qq{Inaccessible symbol: Top\n}
    );
}

if (1) {
    my $unproductive_start_grammar = <<'END_OF_DSL';
    :start ::= Bad
    Top ::= Bad
    Bad ::= Worse
    Worse ::= Bad
    Top ::= Good
    Good ~ [\d\D]
END_OF_DSL
    test_grammar(
        'unproductive start symbol',
        $unproductive_start_grammar,
        qq{Unproductive start symbol\n}
    );
}

# vim: expandtab shiftwidth=4:
