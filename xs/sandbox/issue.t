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

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use Test::More tests => 31;
use lib 'tool/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa::XS');
}

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . ( join q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::Grammar->new(
    {   start   => 'Top',
        strip   => 0,
        rules   => [
            [ Top => [qw/C/] ],
            [ C => [qw/A C Z/] ],
            [ C => [qw/ASeries Y/] ],
            [ ASeries => [qw/A ASeries/] ],
            [ ASeries => [qw/A/] ],
            [ ASeries => [qw/C X/] ],
            [ 'A', [qw/a/] ],
            [ 'X', [qw/x/] ],
            [ 'Y', [qw/y/] ],
            [ 'Z', [qw/z/] ],
        ],
        default_null_value => q{},
        default_action     => 'main::default_action',
    }
);

$grammar->set( { terminals => [qw(a x y z)], } );

$grammar->precompute();

Marpa::Test::is( $grammar->show_rules, <<'EOS', 'Aycock/Horspool Rules' );
EOS

Marpa::Test::is( $grammar->show_symbols,
    <<'EOS', 'Aycock/Horspool Symbols' );
EOS

Marpa::Test::is( $grammar->show_AHFA, <<'EOS', 'Aycock/Horspool AHFA' );
EOS

my $recce =
    Marpa::Recognizer->new( { grammar => $grammar, mode => 'stream' } );

my $input_length = 99;
EARLEME: for my $earleme ( 1 .. $input_length ) {
    say "PROGRESS:\n", $recce->show_progress();
    $recce->read( 'a', 'a' );
}
$recce->read( 'y', 'y' );

my $expected = '(a;a;a;a)';

$recce->set( { max_parses => 20 } );

$recce->reset_evaluation();
my $value_ref = $recce->value();
my $value = $value_ref ? ${$value_ref} : 'No parse';
Test::More::ok($value eq $expected, qq{Expected result: "$value"});

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
