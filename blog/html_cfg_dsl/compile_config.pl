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


# This file is a simplification of html/lib/Marpa/R2/HTML/Config/Compile.pm

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use English qw( -no_match_vars );
use Marpa::R2 2.023_004;

sub do_is_included_statement {
    my ( $self, $external_element, undef, undef, undef, $external_group ) = @_;
    return [is_included_statement => $external_element, $external_group ];
} ## end sub do_is_included

sub do_is_a_included_statement {
    my ( $self, $external_element, undef, undef, $external_flow, undef, undef, $external_group ) = @_;
    return [is_a_included_statement => $external_element, $external_flow, $external_group ];
} ## end sub do_is_a_included

sub do_is_statement {
    my ( $self, $external_element, undef, $external_flow ) = @_;
    return [is_statement => $external_element, $external_flow ];
} ## end sub do_is

sub do_contains_statement {
    my ( $self, $external_element, undef, $external_contents ) = @_;
    return [contains_statement => $external_element, $external_contents ];
} ## end sub do_contains

sub do_array_assignment {
    my ( $self, $external_list, undef, $external_members ) = @_;
    return [array_assignment => $external_list, $external_members ];
} ## end sub do_array_assignment

sub do_ruby_statement {
    my ( $self, $external_reject_symbol, undef, $external_candidates ) = @_;
    return [ruby_statement => $external_reject_symbol, $external_candidates ];
} ## end sub do_ruby_statement

sub die_on_read_problem {
    my ( $rec, $t, $token_value, $string, $position ) = @_;
    say $rec->show_progress() or die "say failed: $ERRNO";
    my $problem_position = $position - length $1;
    my $before_start     = $problem_position - 40;
    $before_start = 0 if $before_start < 0;
    my $before_length = $problem_position - $before_start;
    die "Problem near position $problem_position\n",
        q{Problem is here: "},
        ( substr $string, $before_start, $before_length + 40 ),
        qq{"\n},
        ( q{ } x ( $before_length + 18 ) ), qq{^\n},
        q{Token rejected, "}, $t->[0], qq{", "$token_value"},
        ;
} ## end sub die_on_read_problem

sub do_array { shift; return [@_]; }

sub do_what_I_mean {

    # The first argument is the per-parse variable.
    # At this stage, just throw it away
    shift;

    # Throw away any undef's
    my @children = grep { defined } @_;

    # Return what's left
    return scalar @children > 1 ? \@children : shift @children;
}

# Order matters !!
my @terminals = (
    [ kw_CDATA => qr/CDATA\b/xms ],
    [ kw_PCDATA => qr/PCDATA\b/xms ],
    [ kw_is => qr/is\b/ixms ],
    [ kw_a => qr/a\b/ixms ],
    [ kw_contains => qr/contains\b/ixms ],
    [ kw_included => qr/included\b/ixms ],
    [ kw_in => qr/in\b/ixms ],
    [ flow => qr/[*]\w+\b/xms ],
    [ group => qr/[%]\w+\b/xms ],
    [ list => qr/[@]\w+\b/xms ],
    [ start_tag => qr/[<]\w+[>]/xms ],
    [ end_tag => qr{[<][/]\w+[>]}xms ],
    [ wildcard_start_tag => qr/[<][*][>]/xms ],
    [ wildcard_end_tag => qr{[<][/][*][>]}xms ],
    [ group_start_tag => qr/[<][%]\w+[>]/xms ],
    [ group_end_tag => qr/[<][%]\w+[>]/xms ],
    [ op_assign =>     qr/[=]/xms ],
    [ op_ruby   =>   qr/[-][>]/xms ],
    [ semi_colon   =>   qr/[;]/xms ],
);

sub create_grammar {

my $source = <<'END_OF_GRAMMAR';
translation_unit ::= statement*
statement ::= is_included_statement
    | is_a_included_statement
    | is_statement
    | contains_statement
    | list_assignment
    | ruby_statement
is_included_statement ::= element kw_is kw_included kw_in <group>
    action => do_is_included_statement
element ::= start_tag
is_a_included_statement ::= element kw_is kw_a flow kw_included kw_in <group>
    action => do_is_a_included_statement
is_statement ::= element kw_is flow
    action => do_is_statement
contains_statement ::= element kw_contains contents
    action => do_contains_statement
contents ::= content_item*
    action => do_array
list_assignment ::= list op_assign list_members
    action => do_array_assignment
list_members ::= list_member*
    action => do_array
list_member ::= ruby_symbol
list_member ::= list
content_item ::= element | <group> | kw_PCDATA | kw_CDATA
ruby_statement ::= ruby_symbol op_ruby ruby_symbol_list
    action => do_ruby_statement
ruby_symbol_list ::= ruby_symbol*
    action => do_array
ruby_symbol ::= kw_PCDATA | kw_CDATA
  | start_tag | group_start_tag | wildcard_start_tag
  | end_tag | group_end_tag | wildcard_end_tag
  | list
END_OF_GRAMMAR
 
    my $grammar = Marpa::R2::Grammar->new(
       { start => 'translation_unit',
       action_object => __PACKAGE__,
       rules =>[$source],
       default_action => 'do_what_I_mean'
       }
    );
    $grammar->precompute();
   return $grammar;
}

our $new;

sub source_by_location_range {
    my ( $self, $start, $end ) = @_;
    my $positions = $self->{positions};
    my $start_pos = $start > 0 ? $positions->[$start] : 0;
    my $end_pos   = $positions->[$end];
    return substr ${ $self->{source_ref} }, $start_pos, $end_pos - $start_pos;
} ## end sub source_by_location_range

sub compile {
    my ($source_ref) = @_;

    # A quasi-object, not used outside this routine
    my @positions = (0);
    my $self = bless { positions => \@positions, source_ref => $source_ref },
        __PACKAGE__;

    state $grammar = create_grammar();
    my $recce  = Marpa::R2::Recognizer->new( { grammar => $grammar } );
    my $string = ${$source_ref};
    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip comment
        next TOKEN if $string =~ m/\G \s* [#] [^\n]* \n/gcxms;

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;

            # say join " ", $t->[0], '->', $1;
            if ( not defined $recce->read( $t->[0], $1 ) ) {
                die_on_read_problem( $recce, $t, $1, $string, pos $string );
            }
            my $latest_earley_set = $recce->latest_earley_set();
            $positions[$latest_earley_set] = pos $string;
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    # Value not used
    my $parse_value_ref;
    my $eval_ok = eval {

        # Have the new() just return the current $self
        local *new = sub { return $self };
        $parse_value_ref = $recce->value();
        1;
    };
    if ( not defined $eval_ok ) {
        my $eval_ref_type = ref $EVAL_ERROR;
        die $EVAL_ERROR if not $eval_ref_type;
        if ( $eval_ref_type eq 'ARRAY' and $EVAL_ERROR->[0] eq 'rule' ) {
            my ( undef, $message, $start, $end ) = @{$EVAL_ERROR};
            chomp $message;
            die $message, "\n",
                "Rule with problem was: ",
                $self->source_by_location_range( $start, $end ), "\n";
        } ## end if ( $eval_ref_type eq 'ARRAY' and $EVAL_ERROR->[0] ...)
        die "Unknown exception: ", Data::Dumper::Dumper($EVAL_ERROR);
    } ## end if ( not defined $eval_ok )
    if ( not defined $parse_value_ref ) {
        die "Compile of HTML configuration failed: source did not parse";
    }

    return ${$parse_value_ref};

} ## end sub compile

my $configuration = join q{}, <>;
say Data::Dumper::Dumper(compile(\$configuration));

# vim: expandtab shiftwidth=4:
