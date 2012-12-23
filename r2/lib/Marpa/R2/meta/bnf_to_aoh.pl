#!/usr/bin/perl
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

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Data::Dumper;

# This is a 'meta' tool, so I relax some of the
# restrictions I use to guarantee portability.
use autodie;

# Appropriate PERLLIB settings are expected to
# be external
use Marpa::R2;

use Getopt::Long;
my $verbose          = 1;
my $help_flag        = 0;
my $result           = Getopt::Long::GetOptions(
    'help'      => \$help_flag,
);
die "usage $PROGRAM_NAME [--help] file ...\n" if $help_flag;

my $p_bnf           = \(join q{}, <>);
my @grammar_args  = ();
my $dummy_grammar = Marpa::R2::Grammar->new( {@grammar_args} );
my $parse_result =
    Marpa::R2::Internal::Stuifzand::parse_rules( $dummy_grammar, $p_bnf );
my $aoh = $parse_result->{rules};

sub sort_bnf {
    my $cmp = $a->{lhs} cmp $b->{lhs};
    return $cmp if $cmp;
    my $a_rhs_length = scalar @{ $a->{rhs} };
    my $b_rhs_length = scalar @{ $b->{rhs} };
    $cmp = $a_rhs_length <=> $b_rhs_length;
    return $cmp if $cmp;
    for my $ix ( 0 .. $a_rhs_length ) {
        $cmp = $a->{rhs}->[$ix] cmp $b->{rhs}->[$ix];
        return $cmp if $cmp;
    }
    return 0;
} ## end sub sort_bnf
my $sorted_aoh = [ sort sort_bnf @{$aoh} ];
$Data::Dumper::Sortkeys = 1;
my $cooked_parse_result = {};
$cooked_parse_result->{rules} = $sorted_aoh;
$cooked_parse_result->{character_classes} = [sort keys %{$parse_result->{character_classes}}];
print Data::Dumper::Dumper($cooked_parse_result);
