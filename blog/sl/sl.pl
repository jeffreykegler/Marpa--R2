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

my $string = join q{}, <>;
chomp $string;

my $grammar = Marpa::R2::Grammar->new(
    {   start => 'start',
        rules => [ <<'END_OF_RULES' ]
start ::= prefix target
prefix ::= any_char*
target ::= balanced_parens
balanced_parens ::= op_lparen balanced_paren_sequence op_rparen
balanced_paren_sequence ::= balanced_parens*
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

        $recce->progress_report_start($earley_set);
        ITEM: while (1) {
            my ( $rule_id, $dot_position, $origin ) = $recce->progress_item();
            last ITEM if not defined $rule_id;
            next ITEM if $rule_id != $target_rule_id;
            next ITEM if $dot_position != -1;
            next ITEM if $origin >= $first_origin;
            $first_origin = $origin;
        } ## end ITEM: while (1)
        last EARLEY_SET if $first_origin <= $latest_earley_set;
        $earley_set--;
    } ## end EARLEY_SET: while ( $earley_set >= 0 )
    $recce->progress_report_finish();
    return if $earley_set < 0;
    return ( $first_origin, $earley_set );
} ## end sub My_Error::last_completed_target

my $thin_grammar = $grammar->thin();
my $recce = Marpa::R2::Thin::R->new($thin_grammar);
$recce->start_input();

# A quasi-object, for internal use only
my $self = bless {
    grammar   => $grammar,
    input     => \$string,
    recce     => $recce,
    },
    'My_Error';

my $length = length $string;

my $stream = Marpa::R2::Thin::U->new($recce);
$stream->ignore_rejection(1);

my $op_alternative      = Marpa::R2::Thin::U::op('alternative');
my $op_ignore_rejection = Marpa::R2::Thin::U::op('ignore_rejection');
my $op_earleme_complete   = Marpa::R2::Thin::U::op('earleme_complete');

my @class_table = (
    [ $grammar->thin_symbol('op_lparen'), qr/[(]/xms ],
    [ $grammar->thin_symbol('op_rparen'), qr/[)]/xms ],
    [ $grammar->thin_symbol('any_char'),  qr/./xms ],
);

$stream->string_set($string);
READ: {
    my $event_count = $stream->read();
    last READ if $event_count == 0;
    READ_ERROR: {
        if ( $event_count == -2 ) {
            my $codepoint = $stream->codepoint();
            printf "Unregistered character U+%04x: %c\n", $codepoint,
                $codepoint;
            my @ops;
            for my $entry (@class_table) {
                my ( $symbol_id, $re ) = @{$entry};
                push @ops, $op_alternative, $symbol_id, 0, 1
                    if chr($codepoint) =~ $re;
            }
            die "Cannot read character U+%04x: %c\n", $codepoint, $codepoint
                if not @ops;
            $stream->char_register( $codepoint, @ops, $op_earleme_complete );
            redo READ;
        } ## end if ( $event_count == -2 )
        die "Error in read: $event_count";
    } ## end READ_ERROR:
} ## end READ:

# Given a string, an earley set to position mapping,
# and two earley sets, return the slice of the string
sub My_Error::input_slice {
    my ( $self, $start, $end ) = @_;
    return if not defined $start;
    my $length         = $end - $start;
    return substr ${ $self->{input} }, $start, $length;
} ## end sub My_Error::input_slice

my $end_of_search = $recce->latest_earley_set();
my @results = ();
RESULTS: while (1) {
    my ( $origin, $end ) =
        $self->last_completed_target( $end_of_search );
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
