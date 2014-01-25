#!perl
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

# Test of null ranking

use 5.010;
use strict;
use warnings;

use Test::More tests => 10;
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

# Marpa::R2::Display
# name: null-ranking adverb example

my $high_dsl = <<'END_OF_DSL';
:default ::= action => main::default_action
:start ::= S
A ::= 'a'
A ::= empty
empty ::=
S ::= A A A A null-ranking => high
END_OF_DSL

# Marpa::R2::Display::End

my $low_dsl = $high_dsl;
$low_dsl =~ s/\s+ [=][>] \s+ high \Z/ => low/xms;
my %dsl = ( high => \$high_dsl, low => \$low_dsl );

my @maximal = ( q{}, qw[(a;;;) (a;a;;) (a;a;a;) (a;a;a;a)] );
my @minimal = ( q{}, qw[(;;;a) (;;a;a) (;a;a;a) (a;a;a;a)] );

for my $maximal ( 0, 1 ) {
    my $dsl = $dsl{ $maximal ? 'low' : 'high' };
    my $slg = Marpa::R2::Scanless::G->new( { source => $dsl } );
    my $slr = Marpa::R2::Scanless::R->new(
        {   grammar        => $slg,
            ranking_method => 'high_rule_only'
        }
    );

    my $input_length = 4;
    my $input        = 'a' x $input_length;
    $slr->read( \$input );

    for my $i ( 0 .. $input_length ) {
        my $expected = $maximal ? \@maximal : \@minimal;
        my $name     = $maximal ? 'maximal' : 'minimal';

# Marpa::R2::Display
# name: SLIF recognizer series_restart() synopsis

        $slr->series_restart( { end => $i } );

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: SLIF recognizer set() synopsis

        $slr->set( { max_parses => 42 } );

# Marpa::R2::Display::End

        my $result = $slr->value();
        die "No parse" if not defined $result;
        Test::More::is( ${$result}, $expected->[$i],
            "$name parse, length=$i" );

    } ## end for my $i ( 0 .. $input_length )
} ## end for my $maximal ( 0, 1 )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
