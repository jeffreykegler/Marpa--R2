#!perl

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
$result{10}[8] = 306;
$result{10}[7] = 500;
$result{100}[8] = 138;
$result{100}[7] = 326;
$result{500}[8] = 42.0;
$result{500}[7] = 131;
$result{1000}[8] = 22.3;
$result{1000}[7] = 74.8;
$result{2000}[8] = 11.7;
$result{2000}[7] = 40.9;
$result{3000}[8] = 7.79;
$result{3000}[7] = 27.9;
my $ix_pure_c = 0;
my $ix_marpa_xs = 1;
my $ix_rcb = 2;
my $ix_tchrist = 3;
my $ix_marpa_pp = 4;

say  '<table align="center" cellpadding="5" border="1" width="100%">';

sub do_old_row {
    my ($desc, $ix) = @_;
    say '<tr><td>', $desc;
    for my $length (reverse qw(10 100 500 1000 2000 3000)) {
        say '<td align="center">', $result{$length}[$ix];
    }
    say '</tr>';
} ## end sub do_old_row

do_old_row('Marpa::R2<br>Latest Marpa version', 8);
do_old_row('Marpa::R2::Thin<br>"Thin" interface to Marpa::R2', 7);
do_old_row('Marpa::XS<br>Older, stable version', 1);
do_old_row('Perl regex', 3);
do_old_row('Regexp::Common::Balanced', 2);

say  '</table>';
