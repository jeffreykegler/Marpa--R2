#!perl
# Copyright 2011 Jeffrey Kegler
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

# A test of the Leo logic.
# Checking to see if a particularly difficult grammar
# goes quadratic.

use 5.010;
use strict;
use warnings;

use Test::More tests => 8;

use lib 'tool/lib';
use Marpa::R2::Test;

BEGIN {
    Test::More::use_ok('Marpa::R2');
}

## no critic (Subroutines::RequireArgUnpacking)

sub main::default_action {
    shift;
    return ( join q{}, grep {defined} @_ );
}

## use critic

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'S',
        rules => [
            [ 'S', [qw/C/] ],
            [ 'C', [qw/a C z/] ],
            [ 'C', [qw/A/] ],
            [ 'A', [qw/a A/] ],
            [ 'A', [qw/a/] ]
        ],
        terminals      => [qw(a y z)],
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

Marpa::R2::Test::is( $grammar->show_symbols(),
    <<'END_OF_STRING', 'Leo4 Symbols' );
END_OF_STRING

Marpa::R2::Test::is( $grammar->show_rules,
    <<'END_OF_STRING', 'Leo4 Rules' );
END_OF_STRING

Marpa::R2::Test::is( $grammar->show_AHFA, <<'END_OF_STRING', 'Leo4 AHFA' );
END_OF_STRING

my $length = 5;

my $recce = Marpa::R2::Recognizer->new( { grammar => $grammar } );

my $i                 = 0;
TOKEN: while ( $i++ < $length ) {
    $recce->read( 'a', 'a' );
    my $latest_earley_set = $recce->latest_earley_set();
    my $size = $recce->earley_set_size($latest_earley_set);
    say "Set #$i, size=$size";
    say $recce->show_progress(), "\n";
} ## end while ( $i++ < $length )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
