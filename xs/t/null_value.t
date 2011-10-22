#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

package Test;

# The start rule

sub new { my $class = shift; return bless {}, $class }

## no critic (Subroutines::RequireArgUnpacking)
sub rule0 {
    return $_[1] . ', but ' . $_[2];
}
## use critic

sub rule1 { return 'A is missing' }
sub rule2 { return q{I'm sometimes null and sometimes not} }
sub rule3 { return 'B is missing' }
sub rule4 { return 'C is missing' }
sub rule5 { return 'C matches Y' }
sub rule6 { return 'Zorro was here' }

package Test_Grammar;

$Test_Grammar::MARPA_OPTIONS = [
    {   'rules' => [
            {   'action' => 'rule0',
                'lhs'    => 's',
                'rhs'    => [ 'a', 'y' ]
            },
            {   'lhs' => 'a',
                'rhs' => []
            },
            {   'action' => 'rule2',
                'lhs'    => 'a',
                'rhs'    => [ 'b', 'c' ]
            },
            {   'lhs' => 'b',
                'rhs' => []
            },
            {   'lhs' => 'c',
                'rhs' => []
            },
            {   'action' => 'rule5',
                'lhs'    => 'c',
                'rhs'    => ['y']
            },
            {   'action' => 'rule6',
                'lhs'    => 'y',
                'rhs'    => ['Z']
            }
        ],
        'start' => 's',
        symbols => {
            a => { null_value => 'A is missing' },
            b => { null_value => 'B is missing' },
            c => { null_value => 'C is missing' },
        },
        'terminals'     => ['Z'],
        'action_object' => 'Test'
    }
];

package main;

my $g = Marpa::Grammar->new( @{$Test_Grammar::MARPA_OPTIONS} );
$g->precompute();
my $recce = Marpa::Recognizer->new( { grammar => $g } );
$recce->tokens( [ [ 'Z', 'Z' ] ] );
my $ref_value = $recce->value();
my $value = $ref_value ? ${$ref_value} : 'No parse';
Marpa::Test::is(
    $value,
    'A is missing, but Zorro was here',
    'null value example'
);

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
