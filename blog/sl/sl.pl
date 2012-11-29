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
use Getopt::Long;

use Marpa::R2 2.024000;
say "Using ", $Marpa::R2::VERSION;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
$PROGRAM_NAME [-n] 'exp'
$PROGRAM_NAME [-n] < file
END_OF_USAGE_MESSAGE
} ## end sub usage

my $show_position_flag;
my $getopt_result = GetOptions( "n!" => \$show_position_flag, );
usage() if not $getopt_result;

my $string = do { $RS = undef; <> };
chomp $string;

my $grammar = Marpa::R2::Grammar->new(
    {
        scannerless => 1,
        rules => [ <<'END_OF_RULES' ]
:start ~ start
start ~ prefix target
prefix ~ any_char*
any_char ~ :any
target ~ balanced_parens
balanced_parens ~ [(] balanced_paren_sequence [)]
balanced_paren_sequence ~ balanced_paren_item*
balanced_paren_item ~ balanced_parens
balanced_paren_item ~ [^()]
END_OF_RULES
    }
);

$grammar->precompute();

# Relies on target being on the LHS of exactly one rule
my $target_rule_id =
    List::Util::first { ( $grammar->rule($_) )[0] eq 'target' }
$grammar->rule_ids();
die "No target?" if not defined $target_rule_id;

sub My_Error::last_completed_target {
    my ( $self, $latest_earley_set ) = @_;
    my $grammar = $self->{grammar};
    my $recce   = $self->{recce};
    $latest_earley_set //= $recce->latest_earley_set();
    my $earley_set = $latest_earley_set;

    # Initialize to one past the end, so we can tell if there were no hits
    my $first_origin = $latest_earley_set + 1;
    EARLEY_SET: while ( $earley_set >= 0 ) {
        my $report_items = $recce->progress($earley_set);
        ITEM: for my $report_item ( @{$report_items} ) {
            my ( $rule_id, $dot_position, $origin ) = @{$report_item};
            next ITEM if $dot_position != -1;
            next ITEM if $rule_id != $target_rule_id;
            next ITEM if $origin >= $first_origin;
            $first_origin = $origin;
        } ## end ITEM: for my $report_item ( @{$report_items} )
        last EARLEY_SET if $first_origin <= $latest_earley_set;
        $earley_set--;
    } ## end EARLEY_SET: while ( $earley_set >= 0 )
    return if $earley_set < 0;
    return ( $first_origin, $earley_set );

} ## end sub My_Error::last_completed_target

my $recce        = Marpa::R2::Recognizer->new({ grammar => $grammar} );

# A hack, not to be documented
my $stream = $recce->thin_stream();
$stream->ignore_rejection(1);

$recce->sl_read( $string );

# A quasi-object, for internal use only
my $self = bless {
    grammar => $grammar,
    input   => \$string,
    recce   => $recce,
    },
    'My_Error';

# Given a string, an earley set to position mapping,
# and two earley sets, return the slice of the string
sub My_Error::input_slice {
    my ( $self, $start, $end ) = @_;
    return if not defined $start;
    my $length = $end - $start;
    return substr ${ $self->{input} }, $start, $length;
} ## end sub My_Error::input_slice

my $end_of_search = $recce->latest_earley_set();
my @results       = ();
RESULTS: while (1) {
    my ( $origin, $end ) = $self->last_completed_target($end_of_search);
    last RESULTS if not defined $origin;
    push @results, [ $origin, $end ];
    $end_of_search = $origin;
} ## end RESULTS: while (1)
for my $result ( reverse @results ) {
    my ( $origin, $end ) = @{$result};
    my $slice = $self->input_slice( $origin, $end );
    print qq{$origin-$end: } if $show_position_flag;
    say +( length $slice ), ': ', substr $slice, 0, 40;
} ## end for my $result ( reverse @results )

# vim: expandtab shiftwidth=4:
