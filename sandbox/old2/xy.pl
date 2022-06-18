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

use Benchmark qw(timeit countit timestr);
use List::Util qw(min);
use Regexp::Common qw /balanced/;
use Getopt::Long;
my $example;
my $length;
my $trailer_count = 3;
my $string;
my $pp      = 0;
my $do_only = 0;
my $do_regex;
my $do_thin;
my $do_thinsl;
my $do_retrace;
my $do_resl;
my $do_r2;
my $do_flm;
my $do_timing       = 1;
my $iteration_count = -4;
my $getopt_result   = GetOptions(
    "length=i"  => \$length,
    "count=i"   => \$iteration_count,
    "trailer=i"   => \$trailer_count,
    "regex!"    => \$do_regex,
    "thin!"     => \$do_thin,
    "thinsl!"   => \$do_thinsl,
    "retrace!"  => \$do_retrace,
    "resl!"  => \$do_resl,
    "only!"     => \$do_only,
    "r2!"       => \$do_r2,
    "flm!"      => \$do_flm,
    "time!"     => \$do_timing,
);
die "getopt failed" if not defined $getopt_result;

{
    require Marpa::R2;
    'Marpa::R2'->VERSION(0.020000);
    say "Marpa::R2 ", $Marpa::R2::VERSION;
}

# Apply defaults
if ( !$do_only ) {
    $do_regex   //= 1;
    $do_thinsl  //= 1;
} ## end if ( !$do_only )


$length //= 1000;
die "Bad length $length" if $length <= 0;
die "Not long enough for trailer" if $length <= $trailer_count + 2;
my $trailer = 'z' x $trailer_count;
my $x_count = $length - (1 + length $trailer);
my $s = ('x' x $x_count) . 'y' . $trailer;
my $expected_answer = $x_count + 1;

my $thinsl_answer_shown;
my $regex_answer_shown;

my $op_alternative        = Marpa::R2::Thin::op('alternative');
my $op_alternative_ignore = Marpa::R2::Thin::op('alternative;ignore');
my $op_earleme_complete   = Marpa::R2::Thin::op('earleme_complete');

sub do_regex {
    my ($s) = @_;
    my $answer =
          $s =~ m/(\A x+ y)/xms
        ? $1
        : 'not found';
    return 0 if $regex_answer_shown;
    $regex_answer_shown = $answer;
    say qq{regex length = }, length $answer;
    return 0;
} ## end sub do_regex

sub do_thinsl {
    my ($s) = @_;

    my $thinsl_grammar      = Marpa::R2::Thin::G->new( { if => 1 } );
    my $s_x = $thinsl_grammar->symbol_new();
    my $s_y = $thinsl_grammar->symbol_new();
    my $s_z = $thinsl_grammar->symbol_new();
    my $s_x_seq            = $thinsl_grammar->symbol_new();
    my $s_target             = $thinsl_grammar->symbol_new();
    $thinsl_grammar->start_symbol_set($s_target);
    $thinsl_grammar->rule_new( $s_target,
        [ $s_x_seq, $s_y ] );
    $thinsl_grammar->sequence_new( $s_x_seq, $s_x, { min => 1 } );

    $thinsl_grammar->precompute();

    my $thinsl_recce = Marpa::R2::Thin::R->new($thinsl_grammar);

    $thinsl_recce->start_input();

    $thinsl_recce->char_register( ord('x'), $op_alternative, $s_x,
        $op_earleme_complete );
    $thinsl_recce->char_register( ord('y'), $op_alternative, $s_y,
        $op_earleme_complete );
    $thinsl_recce->char_register( ord('z'), $op_alternative, $s_z,
        $op_earleme_complete );
    $thinsl_recce->input_string_set($s);
    my $answer;
    my $event_count = $thinsl_recce->input_string_read();
    if ( not $event_count or $event_count != 1 ) {
        die "input_string_read() returned $event_count";
        return 0;
    }
    if ( ( $thinsl_grammar->event(0) )[0] eq 'MARPA_EVENT_EXHAUSTED' ) {
        $answer = $thinsl_recce->input_string_pos() + 1;
    }
    die "target not found" if not defined $answer;

    return 0 if $thinsl_answer_shown;
    $thinsl_answer_shown = $answer;
    say qq{thinsl length = }, $answer;
    return 0;

} ## end sub do_thinsl

my $tests = {};
$tests->{regex} = sub { do_regex($s) }
    if $do_regex;
$tests->{thinsl} = sub { do_thinsl($s) }
    if $do_thinsl;

if ( !$do_timing ) {
    for my $test_name ( keys %{$tests} ) {
        my $closure = $tests->{$test_name};
        say "=== $test_name ===";
        $closure->();
    }
    exit 0;
} ## end if ( !$do_timing )

Benchmark::cmpthese( $iteration_count, $tests );

if ($do_thinsl) {
    say +( $thinsl_answer_shown eq $expected_answer
        ? 'ThinSL Answer matches'
        : 'ThinSL ANSWER DOES NOT MATCH!' );
}
if ($do_regex) {
    say +( $regex_answer_shown eq $expected_answer
        ? 'Regex Answer matches'
        : 'Regex ANSWER DOES NOT MATCH!' );
}
