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

use 5.010;

# A variation on
# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# Its order of ambiguity generates Pascal's triangle.

use strict;
use warnings;

use Test::More tests => 10;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $n = 10;

my $dsl = <<'=== END_OF_DSL ===';
:default ::= action => [name,values]
lexeme default = latm => 1

sequence ::= A action => main::one
    | A sequence action => main::add
A ::= 'a' action => main::one
=== END_OF_DSL ===

sub one { return 1 }
sub add { my (undef, $left, $right) = @_;
# say STDERR join " ", "args:", @_;
return $left+$right }

my $grammar = Marpa::R2::Scanless::G->new( { source  => \$dsl } );
my $recce   = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
my $input   = 'a' x $n;
$recce->read( \$input, 0, 0 );

my @parse_counts = (1);
for my $loc ( 1 .. $n ) {
    my $parse_number = 0;

    $recce->series_restart();
    $recce->resume( undef, 1 );
    die "No parse" if not my $value_ref = $recce->value();
    local $Data::Dumper::Deepcopy = 1;
    # say STDERR Data::Dumper::Dumper($value_ref);
    my $actual = ${$value_ref};
    Marpa::R2::Test::is( $actual, $loc,
        "Count $loc of incremental read" );

} ## end for my $loc ( 1 .. $n )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: set expandtab shiftwidth=4:
