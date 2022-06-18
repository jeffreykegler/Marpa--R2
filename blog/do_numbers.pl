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

use 5.010;
use strict;
use warnings;

my %result;
$result{10} = [qw(
4524.89
111.71
3173.30
33429.33
47.39
)];
$result{100} = [qw(
1180.64
58.96
62.09
197.25
15.35
)];
$result{500} = [qw(
252.40
19.50
2.43
7.58
4.09
)];
$result{1000} = [qw(
117.16
10.28
0.53
1.84
2.14
)];
$result{2000} = [qw(
56.07
5.47
0.12
0.34
1.08
)];
$result{3000} = [qw(
36.35
3.72
0.05
0.13
0.74
)];


my $ix_pure_c = 0;
my $ix_marpa_xs = 1;
my $ix_rcb = 2;
my $ix_tchrist = 3;
my $ix_marpa_pp = 4;
my $ix_marpa_r2_thin = 5;
my $ix_marpa_r2 = 6;

$result{10}[$ix_marpa_r2] = 305.61;
$result{10}[$ix_marpa_r2_thin] = 2665.79;
$result{100}[$ix_marpa_r2] = 140;
$result{100}[$ix_marpa_r2_thin] = 803.23;
$result{500}[$ix_marpa_r2] = 41.03;
$result{500}[$ix_marpa_r2_thin] = 176.98;
$result{1000}[$ix_marpa_r2] = 22.47;
$result{1000}[$ix_marpa_r2_thin] = 89.81;
$result{2000}[$ix_marpa_r2] = 11.69;
$result{2000}[$ix_marpa_r2_thin] = 46.14;
$result{3000}[$ix_marpa_r2] = 7.79;
$result{3000}[$ix_marpa_r2_thin] = 30.88;

say  '<table align="center" cellpadding="5" border="1">';
say '<tr><th colspan=7>Executions per second for various methods of finding balanced parentheses<br>',
'by length of input (a higher number means a faster method)</tr>';

my @counts = qw(10 100 500 1000 2000 3000);
sub do_old_row {
    my ($desc, $ix) = @_;
    say '<tr><td>', $desc;
    for my $length (reverse @counts) {
        say '<td align="right">', sprintf "%.2f", $result{$length}[$ix];
    }
    say '</tr>';
} ## end sub do_old_row

say '<tr><td>';
for my $count (reverse @counts) {
    say '<th align="center">', $count;
}
say '</tr>';

do_old_row( 'Marpa::R2, "thin" interface', $ix_marpa_r2_thin );
do_old_row( 'Marpa::R2, standard interface', $ix_marpa_r2 );
do_old_row( 'Marpa::XS (older, stable Marpa version)', $ix_marpa_xs );
do_old_row( 'Perl regex',                         $ix_tchrist );
do_old_row( 'Regexp::Common::Balanced',           $ix_rcb );

say '</table>';
