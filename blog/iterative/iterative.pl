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

our $ORIGIN;

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
$PROGRAM_NAME [-n] 'exp'
$PROGRAM_NAME [-n] < file
END_OF_USAGE_MESSAGE
} ## end sub usage

my $show_position_flag;
my $quiet_flag;
my $getopt_result = Getopt::Long::GetOptions(
    'n!' => \$show_position_flag,
    'q!' => \$quiet_flag,
);
usage() if not $getopt_result;

my $string = do { local $INPUT_RECORD_SEPARATOR = undef; <> };

## no critic (Subroutines::RequireFinalReturn)
sub do_undef       { undef; }
sub do_arg1        { $_[2]; }
sub do_what_I_mean { shift; return $_[0] if scalar @_ == 1; return \@_ }
## use critic

sub do_target {
    my $origin = ( Marpa::R2::Context::location() )[0];
    return if $origin != $ORIGIN;
    return $_[1];
} ## end sub do_target

my $perl_grammar = Marpa::R2::Grammar->new(
    {   start          => 'start',
        actions        => 'main',
        default_action => 'do_what_I_mean',
        rules          => [ <<'END_OF_RULES' ]
start ::= prefix target action => do_arg1
prefix ::= any_token* action => do_undef
target ::= expression action => do_target
expression ::=
     number
   | scalar
   | op_lparen expression op_rparen assoc => group
  || op_predecrement expression
   | op_preincrement expression
   | expression op_postincrement
   | expression op_postdecrement
  || expression op_starstar expression assoc => right
  || op_uminus expression
   | op_uplus expression
   | op_bang expression
   | op_tilde expression
  || expression op_star expression
   | expression op_slash expression
   | expression op_percent expression
   | expression kw_x expression
  || expression op_plus expression
   | expression op_minus expression
  || expression op_ltlt expression
   | expression op_gtgt expression
  || expression op_ampersand expression
  || expression op_vbar expression
   | expression op_caret expression
  || expression op_equal expression assoc => right
  || expression op_comma expression
END_OF_RULES
    }
);

$perl_grammar->precompute();

# Order matters !!
my @lexer_table = (
    [ op_postdecrement => qr/ [-][-] /xms ],
    [ op_postincrement => qr/ [+][+] /xms ],

    # More than 3 plus or minus signs is ambiguous.
    # Perl allows them if they include a postfix operator
    # and always considers them an error otherwise
    [ op_error        => qr/ [-][-][-] /xms ],
    [ op_error        => qr/ [+][+][+] /xms ],
    [ op_predecrement => qr/ [-][-] /xms ],
    [ op_preincrement => qr/ [+][+] /xms ],

    [ number => qr/(?: \d+ (?: [.] \d* )?| [.] \d+ )/xms ],
    [ scalar => qr/ [\$] \w+ \b/xms ],

    [ op_gtgt      => qr/ [>][>] /xms ],
    [ op_ltlt      => qr/ [<][>] /xms ],
    [ op_starstar  => qr/ [*][*] /xms ],
    [ kw_x         => qr/ x \b  /xms ],
    [ op_ampersand => qr/ [&] /xms ],
    [ op_bang      => qr/ [!] /xms ],
    [ op_caret     => qr/ [\^] /xms ],
    [ op_comma     => qr/ [,] /xms ],
    [ op_equal     => qr/ [=] /xms ],
    [ op_minus     => qr/ [-] /xms ],
    [ op_percent   => qr/ [%] /xms ],
    [ op_plus      => qr/ [+] /xms ],
    [ op_slash     => qr/ [\/] /xms ],
    [ op_star      => qr/ [*] /xms ],
    [ op_tilde     => qr/ [~] /xms ],
    [ op_minus     => qr/ [-] /xms ],
    [ op_plus      => qr/ [+] /xms ],
    [ op_uminus    => qr/ [-] /xms ],
    [ op_uplus     => qr/ [+] /xms ],
    [ op_vbar      => qr/ [|] /xms ],

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
my $recce = Marpa::R2::Recognizer->new( { grammar => $perl_grammar } );

# A quasi-object, for internal use only
my $self = bless {
    grammar   => $perl_grammar,
    input     => \$string,
    recce     => $recce,
    positions => \@positions
    },
    'My_Error';

my $input_length = length $string;
pos $string = $positions[-1];
TOKEN: while ( pos $string < $input_length ) {

    # In this application, we do not skip comments --
    # Expressions inside strings or commments may be of
    # interest
    next TOKEN if $string =~ m/\G\s+/gcxms;    # skip whitespace

    my $position = pos $string;
    FIND_ALTERNATIVE: {
        TOKEN_TYPE: for my $t (@lexer_table) {
            my ( $token_name, $regex ) = @{$t};
            next TOKEN_TYPE if not $string =~ m/\G($regex)/gcxms;
            if ( not defined $recce->alternative( $token_name, \$1 ) ) {
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

RESULT: for my $result ( reverse @results ) {
    my ( $origin, $end ) = @{$result};
    my $slice = $self->input_slice( $origin, $end );
    $slice =~ s/ \A \s* //xms;
    $slice =~ s/ \s* \z //xms;
    $slice =~ s/ \n / /gxms;
    $slice =~ s/ \s+ / /gxms;
    print qq{$origin-$end: }
        or die "print() failed: $ERRNO"
        if $show_position_flag;
    say $slice or die "say failed: $ERRNO";
    $recce->set( { end => $end } );
    my $value;
    VALUE: while ( not defined $value ) {
        local $main::ORIGIN = $origin;
        my $value_ref = $recce->value();
        last VALUE if not defined $value_ref;
        $value = ${$value_ref};
    } ## end VALUE: while ( not defined $value )
    if ( not defined $value ) {
        say 'No parse'
            or die "say() failed: $ERRNO";
        next RESULT;
    }
    say Data::Dumper::Dumper($value)
        or die "say() failed: $ERRNO"
        if not $quiet_flag;
    $recce->reset_evaluation();
} ## end RESULT: for my $result ( reverse @results )

# vim: expandtab shiftwidth=4:
