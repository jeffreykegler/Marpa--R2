#!perl
# Copyright 2022 Jeffrey Kegler
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

use 5.010001;

# Small NAIF tests

use strict;
use warnings;

use Test::More tests => 1;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my $grammar = Marpa::R2::Grammar->new( {
    start   => 'start',
    actions => 'main',
    default_action => 'My_Actions::dwim',
    rules   => [
        [ start => [qw/x y/] ], 
    ], 
} ); 

$grammar->precompute;
my $rec = Marpa::R2::Recognizer->new( { grammar => $grammar } ); 

$rec->alternative('x',\undef, 1);
$rec->earleme_complete;
$rec->alternative('y',\"some", 1);
$rec->earleme_complete;

my $value_ref = $rec->value();
die if not defined $value_ref;

Test::More::is_deeply(
    ${$value_ref},
    [ undef, 'some' ],
    "Regression test of ref to undef as toke value"
);

sub My_Actions::dwim {
    shift;
    return $_[0] if scalar @_ == 1;
    return [@_];
}

# vim: expandtab shiftwidth=4:
