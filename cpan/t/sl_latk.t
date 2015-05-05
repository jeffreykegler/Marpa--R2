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

# Based on Github issue #254 -- constructor invoked
# on per-parse argument, which should not happen.

# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Test::More tests => 12;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

package Class_Actions;

sub new {
    my ( $class ) = @_;
    return bless { ctor_desc => 'class ctor' }, $class;
}

sub do_A {
    my ( $self, $letter ) = @_;
    my $ctor_desc = $self->{ctor_desc} // 'no ctor';
    return join ';', $ctor_desc, "class method", "letter=$letter";
}

package Package_Actions;

sub new {
    my ( $class ) = @_;
    return bless { ctor_desc => 'package ctor' }, $class;
}

sub do_A {
    my ( $self, $letter ) = @_;
    my $ctor_desc = $self->{ctor_desc} // 'no ctor';
    return join ';', $ctor_desc, "package method", "letter=$letter";
}

package main;

my $grammar =
    Marpa::R2::Scanless::G->new( { source => \q(A ::= 'a' action => do_A) } );

my @tests = ();
for my $recce_arg_desc ( 'semantics_package', 'no semantics_package' ) {
    PPO:
    for my $ppo_desc ( 'no', 'unblessed', 'same blessed', 'other blessed' ) {
        my $recce_arg   = {};
        my $ctor_desc   = 'no ctor';
        my $method_desc = undef;
        if ( $recce_arg_desc eq 'semantics_package' ) {
            $recce_arg   = { semantics_package => 'Package_Actions' };
            $ctor_desc   = 'package ctor';
            $method_desc = 'package method';
        }
        my $ppo = undef;
        SET_PPO_PARMS: {
            last SET_PPO_PARMS if $ppo_desc eq 'no';
            if ( $ppo_desc eq 'unblessed' ) {
                $ppo = { desc => $ppo_desc };
                $ctor_desc = 'no ctor';
                last SET_PPO_PARMS;
            }
            if ( $ppo_desc eq 'same blessed' ) {
                $ppo         = bless { desc => $ppo_desc }, 'Package_Actions';
                $ctor_desc   = 'no ctor';
                $method_desc = 'package method' if not defined $method_desc;
                last SET_PPO_PARMS;
            } ## end if ( $ppo_desc eq 'same blessed' )
            if ( $ppo_desc eq 'other blessed' ) {
                $ppo         = bless { desc => $ppo_desc }, 'Class_Actions';
                $ctor_desc   = 'no ctor';
                $method_desc = 'class method' if not defined $method_desc;
                last SET_PPO_PARMS;
            } ## end if ( $ppo_desc eq 'other blessed' )
            die;
        } ## end SET_PPO_PARMS:
        next PPO if not defined $method_desc;
        my $value = join ';', $ctor_desc, $method_desc, 'letter=a';
        my $desc = "$recce_arg_desc; $ppo_desc ppo";
        push @tests, [ $recce_arg, $ppo, $value, 'Parse OK', $desc ];
    } ## end PPO: for my $ppo_desc ( 'no', 'unblessed', 'same blessed',...)
} ## end for my $recce_arg_desc ( 'semantics_package', 'no semantics_package')

TEST:
for my $test_data (@tests) {
    my ( $recce_arg, $ppo, $expected_value, $expected_result,
        $test_name )
        = @{$test_data};
    my ( $actual_value, $actual_result ) =
        my_parser( $grammar, $recce_arg, $ppo );
    Test::More::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Test::More::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end TEST: for my $test_data (@tests_data)

sub my_parser {
    my ( $grammar, $recce_arg, $ppo ) = @_;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar }, $recce_arg );

    if ( not defined eval { $recce->read( \'a' ); 1 } ) {
        # say $EVAL_ERROR
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $recce->read( \$string ); 1 ...})
    my $value_ref;
    if (not defined eval { $value_ref = $recce->value($ppo); 1 } ) {
        # say $EVAL_ERROR
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        return 'value() failure', $abbreviated_error;
    }
    if ( not defined $value_ref ) {
        return 'No parse', 'Input read to end but no parse';
    }
    return ${$value_ref}, 'Parse OK';
} ## end sub my_parser

# vim: expandtab shiftwidth=4:
