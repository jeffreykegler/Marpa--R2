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

my $target_grammar = Marpa::R2::Grammar->new(
    {   start => 'start',
        rules => [ <<'END_OF_RULES' ]
start ::= prefix target
prefix ::= any_token*
target ::= expression
expression ::=
     number | scalar | scalar postfix_op
  || op_lparen expression op_rparen assoc => group
  || unop expression
  || expression binop expression
END_OF_RULES
    }
);

$target_grammar->precompute();

# Order matters !!
my @lexer_table = (
    [ number     => qr/(?:\d+(?:\.\d*)?|\.\d+)/xms ],
    [ scalar     => qr/ [\$] \w+ \b/xms ],
    [ postfix_op => qr/ [-][-] | [+][+] /xms ],
    [ unop       => qr/ [-][-] | [+][+] /xms ],
    [   binop => qr/
          [*][*] | [>][>] | [<][<]
        | [*] | [\/] | [%] | [x] \b
        | [+] | [-] | [&] | [|] | [=] | [,]
    /xms
    ],
    [   unop => qr/ [-] | [+] | [!] | [~] /xms
    ],
    [ op_lparen => qr/[(]/xms ],
    [ op_rparen => qr/[)]/xms ],
);

sub My_Error::last_completed_range {
    my ( $self, $symbol_name, $latest_earley_set ) = @_;
    my $grammar      = $self->{grammar};
    my $recce        = $self->{recce};
    my @sought_rules = ();
    for my $rule_id ( $grammar->rule_ids() ) {
        my ($lhs) = $grammar->bnf_rule($rule_id);
        push @sought_rules, $rule_id if $lhs eq $symbol_name;
    }
    die "Looking for completion of non-existent rule lhs: $symbol_name"
        if not scalar @sought_rules;
    $latest_earley_set //= $recce->latest_earley_set();
    my $earley_set = $latest_earley_set;

    # Initialize to one past the end, so we can tell if there were no hits
    my $first_origin = $latest_earley_set + 1;
    EARLEY_SET: while ( $earley_set >= 0 ) {
        my $report_items = $recce->progress($earley_set);
        ITEM: for my $report_item ( @{$report_items} ) {
            my ( $rule_id, $dot_position, $origin ) = @{$report_item};
            next ITEM if $dot_position != -1;
            next ITEM if not scalar grep { $_ == $rule_id } @sought_rules;
            next ITEM if $origin >= $first_origin;
            $first_origin = $origin;
        } ## end ITEM: for my $report_item ( @{$report_items} )
        last EARLEY_SET if $first_origin <= $latest_earley_set;
        $earley_set--;
    } ## end EARLEY_SET: while ( $earley_set >= 0 )
    return if $earley_set < 0;
    return ( $first_origin, $earley_set );
} ## end sub My_Error::last_completed_range

my @positions = (0);
my $recce = Marpa::R2::Recognizer->new( { grammar => $target_grammar, } );

# A quasi-object, for internal use only
my $self = bless {
    grammar   => $target_grammar,
    input     => \$string,
    recce     => $recce,
    positions => \@positions
    },
    'My_Error';

my $length = length $string;
pos $string = $positions[-1];
TOKEN: while ( pos $string < $length ) {

    # In this application, we do not skip comments --
    # Expressions inside strings or commments may be of
    # interest
    next TOKEN if $string =~ m/\G\s+/gcxms;    # skip whitespace

    my $position = pos $string;
    FIND_ALTERNATIVE: {
        TOKEN_TYPE: for my $t (@lexer_table) {
            my ( $token_name, $regex ) = @{$t};
            next TOKEN_TYPE if not $string =~ m/\G($regex)/gcxms;
            if ( not defined $recce->alternative($token_name) ) {
                pos $string = $position;       # reset position for matching
                next TOKEN_TYPE;
            }
            $recce->alternative('any_token');
            last FIND_ALTERNATIVE;
        } ## end TOKEN_TYPE: for my $t (@lexer_table)
        ## Nothing in the lexer table matched
        ## Just read the currrent character as an 'any_token'
        pos $string = $position + 1;
        $recce->alternative('any_token');
    } ## end FIND_ALTERNATIVE:
    $recce->earleme_complete();
    my $latest_earley_set_ID = $recce->latest_earley_set();
    $positions[$latest_earley_set_ID] = pos $string;
} ## end TOKEN: while ( pos $string < $length )

# Given a string, an earley set to position mapping,
# and two earley sets, return the slice of the string
sub My_Error::input_slice {
    my ( $self, $start, $end ) = @_;
    my $positions = $self->{positions};
    return if not defined $start;
    my $start_position = $positions->[$start];
    my $length         = $positions->[$end] - $start_position;
    return substr ${ $self->{input} }, $start_position, $length;
} ## end sub My_Error::input_slice

my $end_of_search;
my @results = ();
RESULTS: while (1) {
    my ( $origin, $end ) =
        $self->last_completed_range( 'target', $end_of_search );
    last RESULTS if not defined $origin;
    push @results, [ $origin, $end ];
    $end_of_search = $origin;
} ## end RESULTS: while (1)
for my $result ( reverse @results ) {
    my ( $origin, $end ) = @{$result};
    my $slice = $self->input_slice( $origin, $end );
    $slice =~ s/ \A \s* //xms;
    $slice =~ s/ \s* \z //xms;
    $slice =~ s/ \n / /gxms;
    $slice =~ s/ \s+ / /gxms;
    print qq{$origin-$end: } if $show_position_flag;
    say $slice;
} ## end for my $result ( reverse @results )

# vim: expandtab shiftwidth=4:
