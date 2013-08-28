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
# An ambiguous equation

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;
use English qw( -no_match_vars );
use Fatal qw(open close);
use Marpa::R2;

## no critic (InputOutput::RequireBriefOpen)
open my $original_stdout, q{>&STDOUT};
## use critic

sub save_stdout {
    my $save;
    my $save_ref = \$save;
    close STDOUT;
    open STDOUT, q{>}, $save_ref;
    return $save_ref;
} ## end sub save_stdout

sub restore_stdout {
    close STDOUT;
    open STDOUT, q{>&}, $original_stdout;
    return 1;
}

# Marpa::R2::Display
# name: SLIF Null Value Example

sub do_L {
    shift;
    return 'L(' . ( join q{;}, map { $_ // '[ERROR!]' } @_ ) . ')';
}

sub do_R {
    return 'R(): I will never be called';
}

sub do_S {
    shift;
    return 'S(' . ( join q{;}, map { $_ // '[ERROR!]' } @_ ) . ')';
}

sub do_X { return 'X(' . $_[1] . ')'; }
sub do_Y { return 'Y(' . $_[1] . ')'; }

## no critic (Variables::ProhibitPackageVars)
our $null_A = 'null A';
our $null_B = 'null B';
our $null_L = 'null L';
our $null_R = 'null R';
our $null_X = 'null X';
our $null_Y = 'null Y';
## use critic

my $slg = Marpa::R2::Scanless::G->new(
    {   source => \<<'END_OF_DSL',
:start ::= S
S ::= L R action => do_S
L ::= A B X action => do_L
L ::= action => null_L
R ::= A B Y action => do_R
R ::= action => null_R
A ::= action => null_A
B ::= action => null_B
X ::= action => null_X
X ::= 'x' action => do_X
Y ::= action => null_Y
Y ::= 'y' action => do_Y
END_OF_DSL
    }
);

my $slr = Marpa::R2::Scanless::R->new(
    {   grammar           => $slg,
        semantics_package => 'main',
    }
);

$slr->read( \'x' );

# Marpa::R2::Display::End

## use critic

# Marpa::R2::Display
# name: SLIF Null Value Example Output
# start-after-line: END_OF_OUTPUT
# end-before-line: '^END_OF_OUTPUT$'

chomp( my $expected = <<'END_OF_OUTPUT');
S(L(null A;null B;X(x));null R)
END_OF_OUTPUT

# Marpa::R2::Display::End

my $value = $slr->value();
Marpa::R2::Test::is( ${$value}, $expected, 'Null example' );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
