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

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 3;
use Fatal qw(open close);

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
    my ( $grammar_args, $tokens ) = @_;

    my $grammar;
    my $eval_ok =
        eval { $grammar = Marpa::R2::Grammar->new($grammar_args); 1; };
    die "Exception while creating Grammar:\n$EVAL_ERROR"
        if not $eval_ok;
    die "Grammar not created\n" if not $grammar;
    $grammar->precompute();

    my $recce;
    $eval_ok = eval {
        $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );
        1;
    };

    die "Exception while creating Recognizer:\n$EVAL_ERROR"
        if not $eval_ok;
    die "Recognizer not created\n" if not $recce;

    for my $token ( @{$tokens} ) {
        my $earleme_result;
        $eval_ok = eval {
            $recce->alternative( @{$token} );
            $earleme_result = $recce->earleme_complete();
            1;
        };
        die "Exception while recognizing earleme:\n$EVAL_ERROR"
            if not $eval_ok;
        die "Parsing exhausted\n"
            if not defined $earleme_result;
    } ## end for my $token ( @{$tokens} )

    $eval_ok = eval { $recce->end_input(); 1; };
    die "Exception while recognizing end of input:\n$EVAL_ERROR"
        if not $eval_ok;

    my $value_ref = $recce->value();
    die "No parse\n" if not $value_ref;
    return ${$value_ref};
} ## end sub test_grammar

# RHS too long is not testable
# Perl runs out of memory first

# test a grammar with no limit problems
my $result_on_success = '(a;a)';

my $placebo = {
    start => 'S',
    rules => [
        #<<< no perltidy
        [ 'S', [ qw(A A) ] ],
        [ 'A', [qw/a/] ]
        #>>>
    ],
    default_action => 'main::default_action',
};

sub gen_tokens {
    my ($earleme_length) = @_;
    return [ [ 'a', \'a', 1 ], [ 'a', \'a', $earleme_length ] ];
}

my $value;
my $eval_ok = eval { $value = test_grammar( $placebo, gen_tokens(1) ); 1; };
if ( not defined $eval_ok ) {
    Test::More::diag($EVAL_ERROR);
    Test::More::fail('Placebo grammar');
}
else { Test::More::is( $value, $result_on_success, 'Placebo grammar' ) }

## lots of test values in the following, some of them pretty
## arbitrary

$eval_ok = eval { $value = test_grammar( $placebo, gen_tokens(20_031) ); 1; };
if ( not defined $eval_ok ) { Test::More::fail('Earleme very long') }
else {
    Test::More::is( $value, $result_on_success,
        'Earleme very long, but still OK' );
}

$eval_ok =
    eval { $value = test_grammar( $placebo, gen_tokens( 2**31 ) ); 1; };
REPORT_RESULT: {
    if ( defined $eval_ok ) {
        Test::More::diag("Earleme too long test returned value: $value");
        Test::More::fail('Did not catch problem with earleme too long');
        last REPORT_RESULT;
    }
    if ( $EVAL_ERROR
        =~ / \A Exception \s while \s recognizing \s earleme /xms )
    {
        Test::More::pass('Caught over-long earleme');
        last REPORT_RESULT;
    } ## end if ( $EVAL_ERROR =~ ...)
    Test::More::is( $EVAL_ERROR, q{}, 'Grammar with earleme too long' );
} ## end REPORT_RESULT:

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
