#!perl
# Copyright 2012 Jeffrey Kegler
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
# A grammar with cycles

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Fatal qw(open close chdir);

use Test::More tests => 7;
use lib 'inc';
use Marpa::R2::Test;

BEGIN {
    Test::More::use_ok('Marpa::R2');
}

## no critic (Subroutines::RequireArgUnpacking)
sub default_action {
    shift;
    return join q{ }, grep { defined $_ } @_;
}
## use critic

package Test_Grammar;

# Formatted by Data::Dumper, which disagrees with
# perltidy and perlcritic about things
#<<< no perltidy

$Test_Grammar::MARPA_OPTIONS_1 = [
    {   'default_action' => 'main::default_action',
        'rules'          => [
            {   'lhs' => 's',
                'rhs' => [ 's' ]
            }
        ],
        'start'     => 's',
        'terminals' => [ 's' ],
    }
];

$Test_Grammar::MARPA_OPTIONS_2 = [
    {   'default_action' => 'main::default_action',
        'rules'          => [
            {   'lhs' => 's',
                'rhs' => [ 'a' ]
            },
            {   'lhs' => 'a',
                'rhs' => [ 's' ]
            }
        ],
        'start'     => 's',
        'terminals' => [ 'a' ],
    }
];

$Test_Grammar::MARPA_OPTIONS_8 = [
    {   'default_action' => 'main::default_action',
        default_null_value => undef,
        'rules'          => [
            {   'lhs' => 's',
                'rhs' => [ 'a' ]
            },
            {   'lhs' => 'a',
                'rhs' => [ 'b', 't', 'u' ]
            },
            {   'lhs' => 'b',
                'rhs' => [ 'v', 'c' ]
            },
            {   'lhs' => 'c',
                'rhs' => [ 'w', 'd', 'x' ]
            },
            {   'lhs' => 'd',
                'rhs' => [ 'e' ]
            },
            {   'lhs' => 'e',
                'rhs' => [ 's' ]
            },
            {   'lhs' => 't',
                'rhs' => []
            },
            {   'lhs' => 'u',
                'rhs' => []
            },
            {   'lhs' => 'v',
                'rhs' => []
            },
            {   'lhs' => 'w',
                'rhs' => []
            },
            {   'lhs' => 'x',
                'rhs' => []
            }
        ],
        'start'     => 's',
        'terminals' => [ 'e', 't', 'u', 'v', 'w', 'x' ],
    }
];

#>>>
## use critic

package main;

my $cycle1_test = [
    'cycle1',
    $Test_Grammar::MARPA_OPTIONS_1,
    [ [ [ 's', '1' ] ] ],
    '1',
    <<'EOS'
Cycle found involving rule: 0: s -> s
EOS
];

my $cycle2_test = [
    'cycle2',
    $Test_Grammar::MARPA_OPTIONS_2,
    [ [ [ 'a', '1' ] ] ],
    '1',
    <<'EOS'
Cycle found involving rule: 0: s -> a
Cycle found involving rule: 1: a -> s
EOS
];

my @cycle8_tokens = ( [ [ 'e', '1' ], [ 'v', '1' ], [ 'w', '1' ] ] );

push @cycle8_tokens, map {
    (   [   [ 'e', $_ ],
            [ 't', $_ ],
            [ 'u', $_ ],
            [ 'v', $_ ],
            [ 'w', $_ ],
            [ 'x', $_ ]
        ],
        )
} qw( 2 3 4 5 6 );

my $cycle8_test = [
    'cycle8',
    $Test_Grammar::MARPA_OPTIONS_8,
    \@cycle8_tokens,
    '1 2 3 4 5 6',
    <<'EOS'
Cycle found involving rule: 0: s -> a
Cycle found involving rule: 4: d -> e
Cycle found involving rule: 5: e -> s
Cycle found involving rule: 1: a -> b t u
Cycle found involving rule: 2: b -> v c
Cycle found involving rule: 3: c -> w d x
EOS
];

for my $test_data ( $cycle1_test, $cycle2_test, $cycle8_test ) {
    my ( $test_name, $marpa_options, $input, $expected, $expected_trace ) =
        @{$test_data};
    my $trace = q{};
    open my $MEMORY, '>', \$trace;
    my $grammar = Marpa::R2::Grammar->new(
        {   infinite_action   => 'warn',
            trace_file_handle => $MEMORY,
        },
        @{$marpa_options},
    );
    $grammar->precompute();

    my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );
    for my $earleme_input ( @{$input} ) {
        for my $token ( @{$earleme_input} ) {
            $recce->alternative(@{$token});
        }
        $recce->earleme_complete();
    }
    my $value_ref = $recce->value();
    my $value = $value_ref ? ${$value_ref} : 'No parse';

    close $MEMORY;

    Marpa::R2::Test::is( $value, $expected,       "$test_name result" );
    Marpa::R2::Test::is( $trace, $expected_trace, "$test_name trace" );

} ## end for my $test_data ( $cycle1_test, $cycle2_test, $cycle8_test)

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
