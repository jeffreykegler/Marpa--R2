#!perl
# Marpa::R2 is Copyright (C) 2017, Jeffrey Kegler.
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

# Tests of ranking, retro-ported from Marpa::R3

use 5.010001;

use strict;
use warnings;

use Test::More tests => 96;
use Data::Dumper;
use English qw( -no_match_vars );
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale(LC_ALL, "C");

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my @tests_data = ();

our $DEBUG = 0;

# Tests of rank adverb based on examples from Lukas Atkinson
# Here longest is highest rank, as in his original

if (1) {

    my $source = <<'END_OF_SOURCE';
  :discard ~ ws; ws ~ [\s]+
  :default ::= action => ::array

  Top ::= List action => main::group
  List ::= Item3 rank => 3
  List ::= Item2 rank => 2
  List ::= Item1 rank => 1
  List ::= List Item3 rank => 3
  List ::= List Item2 rank => 2
  List ::= List Item1 rank => 1
  Item3 ::= VAR '=' VAR action => main::concat
  Item2 ::= VAR '='     action => main::concat
  Item1 ::= VAR         action => main::concat
  VAR ~ [\w]+

END_OF_SOURCE

    my @tests = (
        [ 'a',                 '(a)', ],
        [ 'a = b',             '(a=b)', ],
        [ 'a = b = c',         '(a=)(b=c)', ],
        [ 'a = b = c = d',     '(a=)(b=)(c=d)', ],
        [ 'a = b c = d',       '(a=b)(c=d)' ],
        [ 'a = b c = d e =',   '(a=b)(c=d)(e=)' ],
        [ 'a = b c = d e',     '(a=b)(c=d)(e)' ],
        [ 'a = b c = d e = f', '(a=b)(c=d)(e=f)' ],
    );

    my $grammar = Marpa::R2::Scanless::G->new(
        { source => \$source } );
    for my $test (@tests) {
        my ( $input, $output ) = @{$test};
        do_test( $grammar, $input, $output, 'Parse OK',
            qq{Test of rank by longest: "$input"} );
    }
}

# Tests of rank adverb based on examples from Lukas Atkinson
# Here *shortest* is highest rank

if (1) {

# Marpa::R2::Display
# name: Ranking, shortest highest, version 1
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
  :discard ~ ws; ws ~ [\s]+
  :default ::= action => ::array

  Top ::= List action => main::group
  List ::= Item3 rank => 1
  List ::= Item2 rank => 2
  List ::= Item1 rank => 3
  List ::= List Item3 rank => 1
  List ::= List Item2 rank => 2
  List ::= List Item1 rank => 3
  Item3 ::= VAR '=' VAR action => main::concat
  Item2 ::= VAR '='     action => main::concat
  Item1 ::= VAR         action => main::concat
  VAR ~ [\w]+

END_OF_SOURCE


# Marpa::R2::Display
# name: Ranking results, shortest highest, version 1

    my @tests = (
        [ 'a',                 '(a)', ],
        [ 'a = b',             '(a=)(b)', ],
        [ 'a = b = c',         '(a=)(b=)(c)', ],
        [ 'a = b = c = d',     '(a=)(b=)(c=)(d)', ],
        [ 'a = b c = d',       '(a=)(b)(c=)(d)' ],
        [ 'a = b c = d e =',   '(a=)(b)(c=)(d)(e=)' ],
        [ 'a = b c = d e',     '(a=)(b)(c=)(d)(e)' ],
        [ 'a = b c = d e = f', '(a=)(b)(c=)(d)(e=)(f)' ],
    );

# Marpa::R2::Display::End

    my $grammar = Marpa::R2::Scanless::G->new(
        { source => \$source } );
    for my $test (@tests) {
        my ( $input, $output ) = @{$test};
        do_test( $grammar, $input, $output, 'Parse OK',
            qq{Test of rank by shortest: "$input"},
        );
    }
}

# Tests of rank adverb based on examples from Lukas Atkinson
# version 2
# Here longest is highest rank, as in his original

if (1) {

# Marpa::R2::Display
# name: Ranking, longest highest, version 2
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
  :discard ~ ws; ws ~ [\s]+
  :default ::= action => ::array

  Top ::= List action => main::group
  List ::= Item rank => 1
  List ::= List Item rank => 0
  Item ::= VAR '=' VAR rank => 3 action => main::concat
  Item ::= VAR '='     rank => 2 action => main::concat
  Item ::= VAR         rank => 1 action => main::concat
  VAR ~ [\w]+

END_OF_SOURCE

# Marpa::R2::Display::End

    my @tests = (
        [ 'a',                 '(a)', ],
        [ 'a = b',             '(a=b)', ],
        [ 'a = b = c',         '(a=)(b=c)', ],
        [ 'a = b = c = d',     '(a=)(b=)(c=d)', ],
        [ 'a = b c = d',       '(a=b)(c=d)' ],
        [ 'a = b c = d e =',   '(a=b)(c=d)(e=)' ],
        [ 'a = b c = d e',     '(a=b)(c=d)(e)' ],
        [ 'a = b c = d e = f', '(a=b)(c=d)(e=f)' ],
    );

    my $grammar = Marpa::R2::Scanless::G->new(
        { source => \$source } );
    for my $test (@tests) {
        my ( $input, $output ) = @{$test};
        do_test( $grammar, $input, $output, 'Parse OK',
            qq{Test of rank by longest (v2): "$input"} );
    }
}

# Tests of rank adverb based on examples from Lukas Atkinson
# version 2
# Here *shortest* is highest rank

if (1) {

# Marpa::R2::Display
# name: Ranking, shortest highest, version 2
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
  :discard ~ ws; ws ~ [\s]+
  :default ::= action => ::array

  Top ::= List action => main::group
  List ::= Item rank => 0
  List ::= List Item rank => 1
  Item ::= VAR '=' VAR rank => 1 action => main::concat
  Item ::= VAR '='     rank => 2 action => main::concat
  Item ::= VAR         rank => 3 action => main::concat
  VAR ~ [\w]+

END_OF_SOURCE

# Marpa::R2::Display::End

    my @tests = (
        [ 'a',                 '(a)', ],
        [ 'a = b',             '(a=)(b)', ],
        [ 'a = b = c',         '(a=)(b=)(c)', ],
        [ 'a = b = c = d',     '(a=)(b=)(c=)(d)', ],
        [ 'a = b c = d',       '(a=)(b)(c=)(d)' ],
        [ 'a = b c = d e =',   '(a=)(b)(c=)(d)(e=)' ],
        [ 'a = b c = d e',     '(a=)(b)(c=)(d)(e)' ],
        [ 'a = b c = d e = f', '(a=)(b)(c=)(d)(e=)(f)' ],
    );

    my $grammar = Marpa::R2::Scanless::G->new(
        { source => \$source } );
    for my $test (@tests) {
        my ( $input, $output ) = @{$test};
        do_test( $grammar, $input, $output, 'Parse OK',
            qq{Test of rank by shortest (v2): "$input"},
        );
    }
}

# Tests of rank adverb based on examples from Lukas Atkinson
# version 3: reimplemented via BNF
# Here longest is highest rank, as in his original

if (1) {

# Marpa::R2::Display
# name: Ranking via BNF, longest highest, version 3
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
  :discard ~ ws; ws ~ [\s]+
  :default ::= action => ::array

  Top            ::= Max_Boundeds action => main::group
  Top            ::= Max_Boundeds Unbounded action => main::group
  Top            ::= Unbounded action => main::group
  Max_Boundeds   ::= Max_Bounded+
  Max_Bounded    ::= Eq_Finals Var_Final3
  Max_Bounded    ::= Var_Final
  Unbounded      ::= Eq_Finals
  Eq_Finals      ::= Eq_Final+
  Var_Final      ::= Var_Final3 | Var_Final1
  Var_Final3     ::= VAR '=' VAR action => main::concat
  Eq_Final       ::= VAR '='     action => main::concat
  Var_Final1     ::= VAR         action => main::concat
  VAR ~ [\w]+

END_OF_SOURCE

# Marpa::R2::Display::End

    my @tests = (
        [ 'a',                 '(a)', ],
        [ 'a = b',             '(a=b)', ],
        [ 'a = b = c',         '(a=)(b=c)', ],
        [ 'a = b = c = d',     '(a=)(b=)(c=d)', ],
        [ 'a = b c = d',       '(a=b)(c=d)' ],
        [ 'a = b c = d e =',   '(a=b)(c=d)(e=)' ],
        [ 'a = b c = d e',     '(a=b)(c=d)(e)' ],
        [ 'a = b c = d e = f', '(a=b)(c=d)(e=f)' ],
    );

    my $grammar = Marpa::R2::Scanless::G->new(
        { source => \$source } );
    for my $test (@tests) {
        my ( $input, $output ) = @{$test};
        do_test( $grammar, $input, $output, 'Parse OK',
            qq{Test of rank by longest (v3): "$input"} );
    }
}

# Tests of rank adverb based on examples from Lukas Atkinson
# version 3: reimplemented via BNF
# Here *shortest* is highest rank

if (1) {

# Marpa::R2::Display
# name: Ranking via BNF, shortest highest, version 3
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

    my $source = <<'END_OF_SOURCE';
  :discard ~ ws; ws ~ [\s]+
  :default ::= action => ::array

  Top            ::= Max_Boundeds action => main::group
  Top            ::= Max_Boundeds Unbounded action => main::group
  Top            ::= Unbounded action => main::group
  Max_Boundeds   ::= Max_Bounded+
  Max_Bounded    ::= Eq_Finals Var_Final
  Max_Bounded    ::= Var_Final
  Unbounded      ::= Eq_Finals
  Eq_Finals      ::= Eq_Final+
  Eq_Final       ::= VAR '='     action => main::concat
  Var_Final      ::= VAR         action => main::concat
  VAR ~ [\w]+

END_OF_SOURCE

# Marpa::R2::Display::End

    my @tests = (
        [ 'a',                 '(a)', ],
        [ 'a = b',             '(a=)(b)', ],
        [ 'a = b = c',         '(a=)(b=)(c)', ],
        [ 'a = b = c = d',     '(a=)(b=)(c=)(d)', ],
        [ 'a = b c = d',       '(a=)(b)(c=)(d)' ],
        [ 'a = b c = d e =',   '(a=)(b)(c=)(d)(e=)' ],
        [ 'a = b c = d e',     '(a=)(b)(c=)(d)(e)' ],
        [ 'a = b c = d e = f', '(a=)(b)(c=)(d)(e=)(f)' ],
    );

    my $grammar = Marpa::R2::Scanless::G->new(
        { source => \$source } );
    for my $test (@tests) {
        my ( $input, $output ) = @{$test};
        do_test( $grammar, $input, $output, 'Parse OK',
            qq{Test of rank by shortest (v3): "$input"},
        );
    }
}

sub do_test {
    my ( $grammar, $test_string, $expected_value, $expected_result,
        $test_name ) = @_;
    my ( $actual_value, $actual_result ) =
        my_parser( $grammar, $test_string );
    Test::More::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Test::More::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
}

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $recce = Marpa::R2::Scanless::R->new(
        { grammar => $grammar, ranking_method => 'high_rule_only' } );

    if ( not defined eval { $recce->read( \$string ); 1 } ) {
        say $EVAL_ERROR if $DEBUG;
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $recce->read( \$string ); 1 ...})
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        return 'No parse', 'Input read to end but no parse';
    }
    return [ return ${$value_ref}, 'Parse OK' ];
} ## end sub my_parser

sub flatten {
    my ($array) = @_;
    return [] if not defined $array;
    my $ref = ref $array;
    return [$array] if $ref ne 'ARRAY';
    my @flat = ();
    ELEMENT: for my $element (@{$array}) {
       my $ref = ref $element;
       if ($ref ne 'ARRAY') {
           push @flat, $element;
           next ELEMENT;
       }
       my $flat_piece = flatten($element);
       push @flat, @{$flat_piece};
    }
    return \@flat;
}

# For use as a parse action
sub concat {
    my ($pp, @args) = @_;
    # say STDERR 'concat: ', Data::Dumper::Dumper(\@args);
    my $flat = flatten(\@args);
    # say STDERR 'flat: ', Data::Dumper::Dumper($flat);
    return join '', @{$flat};
}

# For use as a parse action
sub group {
    my ($pp, @args) = @_;
    # say STDERR 'group args: ', Data::Dumper::Dumper(\@args);
    my $flat = flatten(\@args);
    # say STDERR 'flat: ', Data::Dumper::Dumper($flat);
    return join '', map { +'(' . $_ . ')'; } grep { defined } @{$flat};
}

# vim: expandtab shiftwidth=4:
