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

use Test::More;

# Perhaps make this a command line option someday
my $verbose = 0;

BEGIN {
    my $problem;
    CHECK_FOR_PROBLEM: {
        if ( not eval { require Task::Weaken } ) {
            $problem = 'Scalar::Util::weaken() not implemented';
            last CHECK_FOR_PROBLEM;
        }
        if ( not eval { require Test::Weaken } ) {
            $problem = 'Test::Weaken not installed';
            last CHECK_FOR_PROBLEM;
        }
        if ( Test::Weaken->VERSION() != 3.004000 ) {
            $problem = 'Test::Weaken 3.004000 not installed';
            last CHECK_FOR_PROBLEM;
        }
    } ## end CHECK_FOR_PROBLEM:
    if ( defined $problem ) {
        Test::More::plan skip_all => $problem;
    }
    else {
        Test::More::plan tests => 2;
    }
    Test::More::use_ok('Marpa::XS');
} ## end BEGIN

my $test = sub {
    my $g = Marpa::Grammar->new(
        {   start => 'S',
            rules => [
                [ 'S', [qw/A A A A/] ],
                [ 'A', [qw/a/] ],
                [ 'A', [qw/E/] ],
                ['E'],
            ],
            terminals => ['a'],
        }
    );
    $g->precompute();
    my $recce = Marpa::Recognizer->new( { grammar => $g } );
    $recce->tokens( [ ( [ 'a', 'a', 1 ] ) x 4 ] );
    $recce->value();
    [ $g, $recce ];
};

my $tester            = Test::Weaken->new($test);
my $unfreed_count     = $tester->test();
my $unfreed_proberefs = $tester->unfreed_proberefs();
my $total             = $tester->probe_count();
my $freed_count       = $total - $unfreed_count;

# The evaluator (for And_Node::PERL_CLOSURE) assigns a \undef, and this creates
# an undef "global".  No harm done if there's only one.

my $ignored_count = 0;
DELETE_UNDEF_CONSTANT: for my $ix ( 0 .. $#{$unfreed_proberefs} ) {
    if ( ref $unfreed_proberefs->[$ix] eq 'SCALAR'
        and not defined ${ $unfreed_proberefs->[$ix] } )
    {
        delete $unfreed_proberefs->[$ix];
        $ignored_count++;
        next DELETE_UNDEF_CONSTANT;
    } ## end if ( ref $unfreed_proberefs->[$ix] eq 'SCALAR' and not...)

    if ($verbose) {
        require Devel::Peek;
        say {*STDERR} 'Unfreed: ', $unfreed_proberefs->[$ix]
            or die 'Cannot write to STDERR';
        Devel::Peek::Dump( $unfreed_proberefs->[$ix] );
    } ## end if ($verbose)

} ## end for my $ix ( 0 .. $#{$unfreed_proberefs} )
$unfreed_count = @{$unfreed_proberefs};

# "Freed=$freed_count, ignored=$ignored_count, unfreed=$unfreed_count, total=$total"

Test::More::cmp_ok( $unfreed_count, q{==}, 0, 'All refs freed' )
    or Test::More::diag("Unfreed refs: $unfreed_count");

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
