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

use Test::More tests => 3;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $base_dsl = <<'END_OF_DSL';
:start ::= S
A ::= 'a'
A ::= empty
empty ::=
S ::= A A A A null-ranking => high
END_OF_DSL

(my $ambig_dsl = $base_dsl) =~ s/null-ranking/null ranking/xms;
(my $unambig_dsl = $base_dsl) =~ s/null-ranking/, null ranking/xms;

say STDERR $base_dsl;
say STDERR $ambig_dsl;
say STDERR $unambig_dsl;

for my $dsl ( $base_dsl, $unambig_dsl, $ambig_dsl ) {
    my $slg = Marpa::R2::Scanless::G->new( { source => \$dsl } );
    my $slr = Marpa::R2::Scanless::R->new(
        {
            grammar        => $slg,
            ranking_method => 'high_rule_only'
        }
    );

    $slr->read( \'aaaa' );

    my $result = $slr->value();
    die "No parse" if not defined $result;
    Test::More::is( ${$result}, q{}, 'Test of ambiguity' );

}

1;    # In case used as "do" file

# vim: expandtab shiftwidth=4:
