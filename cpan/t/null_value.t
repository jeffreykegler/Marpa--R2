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

use 5.010001;
use strict;
use warnings;

use Test::More tests => 1;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

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
            {   'lhs'  => 'a',
                'rhs'  => [],
                action => 'rule1',
            },
            {   'action' => 'rule2',
                'lhs'    => 'a',
                'rhs'    => [ 'b', 'c' ]
            },
            {   'lhs'  => 'b',
                'rhs'  => [],
                action => 'rule3'
            },
            {   'lhs'  => 'c',
                'rhs'  => [],
                action => 'rule4'
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
        'start'         => 's',
        'terminals'     => ['Z'],
        'action_object' => 'Test'
    }
];

package main;

my $g = Marpa::R2::Grammar->new( @{$Test_Grammar::MARPA_OPTIONS} );
$g->precompute();
my $recce = Marpa::R2::Recognizer->new( { grammar => $g } );
$recce->read( 'Z', 'Z' );
my $ref_value = $recce->value();
my $value = $ref_value ? ${$ref_value} : 'No parse';
Marpa::R2::Test::is(
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
