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

# A grammars with cycles

use 5.010001;
use strict;
use warnings;
use English qw( -no_match_vars );
use Fatal qw(open close chdir);
use Test::More tests => 3;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

## no critic (Subroutines::RequireArgUnpacking)
sub show_a         { return 'A(' . $_[1] . ')' }
sub show_b         { return 'B(' . $_[1] . ')' }
sub default_action { shift; return join q{ }, @_ }
## use critic

package Test_Grammar;

$Test_Grammar::MARPA_OPTIONS = [
    {   'default_action' => 'main::default_action',
        'rules'          => [
            {   'lhs' => 's',
                'rhs' => ['a']
            },
            {   'action' => 'main::show_a',
                'lhs'    => 'a',
                'rhs'    => ['b']
            },
            {   'lhs' => 'a',
                'rhs' => ['a:k0']
            },
            {   'action' => 'main::show_b',
                'lhs'    => 'b',
                'rhs'    => ['a']
            }
        ],
        'start'           => 's',
        'terminals'       => ['a:k0'],
        'infinite_action' => 'warn'
    }
];

my $trace;
open my $MEMORY, '>', \$trace;
my $grammar = Marpa::R2::Grammar->new(
    { trace_file_handle => $MEMORY, infinite_action => 'warn' },
    @{$Test_Grammar::MARPA_OPTIONS} );
$grammar->precompute();
close $MEMORY;

Marpa::R2::Test::is( $trace, <<'EOS', 'cycle detection' );
Cycle found involving rule: 1: a -> b
Cycle found involving rule: 3: b -> a
EOS

my $recce = Marpa::R2::Recognizer->new(
    {   grammar           => $grammar,
        trace_file_handle => *STDERR,
    }
);

$recce->read( 'a:k0', 'a' );

my %expected_original = map { ( $_ => 1 ) } qw( A(B(a)) a );
my %expected = %expected_original;

while ( my $value_ref = $recce->value() ) {
    my $value = ${$value_ref};
    if ( defined $expected{$value} ) {
        Test::More::pass(qq{Expected value: "$value"});
        delete $expected{$value};
    }
} ## end while ( my $value_ref = $recce->value() )

for my $missing_value ( keys %expected ) {
    Test::More::fail(qq{Missing value: "$missing_value"});
}

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
