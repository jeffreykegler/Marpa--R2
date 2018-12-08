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

# Regression test of problem with SvIOK() in Perl XS API

use 5.010001;
use strict;
use warnings;

use Test::More tests => 2;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $rules = <<'END_OF_GRAMMAR';
:default ::= action => [name, values]
S ::= A A
A ::= 'a'
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new( { source => \$rules } );

my @actual_events;
my $input = 'axxxa';
my $length = length $input;

sub testIt {
    my ($recce) = @_;
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse\n";
    }

    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Terse    = 1;
    my $actual_value = Data::Dumper::Dumper($value_ref);
    my $expected =
      Data::Dumper::Dumper( \[ 'S', [ 'A', 'a' ], [ 'A', 'a' ] ] );

    Test::More::is( $actual_value, $expected, qq{Value for "$input"} );

}

Test::More::diag( "Marpa::R2 file: ", $INC{'Marpa/R2.pm'} );
Test::More::diag( "Marpa::R2 version: ", $Marpa::R2::VERSION );
Test::More::diag( "Perl version $^V" );

# Need to repeat code here because I am trying to preserve
# the internal flags in $resumePos, and I do not want to
# pass it out of a function.

# === Bare $resume_pos

TEST: {
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $pos = $recce->read( \$input, 0, 1 );
    pos $input = 1;
    $input =~ /\Gx+/;
    my $resumePos = $LAST_MATCH_END[0];
    my $ok = eval { $recce->resume( $resumePos ); 1 };
    if (not $ok) {
         diag($EVAL_ERROR);
         Test::More::fail('Bare integer test: no parse');
         last TEST;
    }
    testIt($recce);
}

# === int($resume_pos)

TEST: {
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $pos = $recce->read( \$input, 0, 1 );
    pos $input = 1;
    $input =~ /\Gx+/;
    my $resumePos = $LAST_MATCH_END[0];
    Test::More::diag("$^V resume pos: $resumePos");
    my $ok = eval { $recce->resume( int($resumePos) ); 1 };
    if (not $ok) {
         diag($EVAL_ERROR);
         Test::More::fail('int() output test: no parse');
         last TEST;
    }
    testIt($recce);
}

# vim: expandtab shiftwidth=4:
