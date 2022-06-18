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

package Marpa::Demo::OP1;

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Marpa::XS;

sub rules { shift; return $_[0]; }

sub priority_rule {
    my ( undef, $lhs, undef, $priorities ) = @_;
    my $priority_count = scalar @{$priorities};
    my @rules          = ();
    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        for my $alternative ( @{ $priorities->[$priority_ix] } ) {
            push @rules, [ $priority, @{$alternative} ];
        }
    } ## end for my $priority_ix ( 0 .. $priority_count - 1 )
    my @xs_rules = (
        { lhs => $lhs, rhs => [ $lhs . '_0' ] },
        (   map {
                ;
                {   lhs => ( $lhs . '_' . ( $_ - 1 ) ),
                    rhs => [ $lhs . '_' . ($_) ]
                }
            } 1 .. $priority_count - 1
        )
    );
    RULE: for my $rule (@rules) {
        my ( $priority, $assoc, $rhs, $action ) = @{$rule};
        my @action_kv = ();
        push @action_kv, action => $action if defined $action;
        my @new_rhs       = @{$rhs};
        my @arity         = grep { $new_rhs[$_] eq $lhs } 0 .. $#new_rhs;
        my $length        = scalar @{$rhs};
        my $current_exp   = $lhs . '_' . $priority;
        my $next_priority = $priority + 1;
        $next_priority = 0 if $next_priority >= $priority_count;
        my $next_exp = $lhs . '_' . $next_priority;

        if ( not scalar @arity ) {
            push @xs_rules,
                {
                lhs => $current_exp,
                rhs => \@new_rhs,
                @action_kv
                };
            next RULE;
        } ## end if ( not scalar @arity )

        if ( scalar @arity == 1 ) {
            die 'Unnecessary unit rule in priority rule' if $length == 1;
            $new_rhs[ $arity[0] ] = $current_exp;
        }
        DO_ASSOCIATION: {
            if ( $assoc eq 'L' ) {
                $new_rhs[ $arity[0] ] = $current_exp;
                for my $rhs_ix ( @arity[ 1 .. $#arity ] ) {
                    $new_rhs[$rhs_ix] = $next_exp;
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'L' )
            if ( $assoc eq 'R' ) {
                $new_rhs[ $arity[-1] ] = $current_exp;
                for my $rhs_ix ( @arity[ 0 .. $#arity - 1 ] ) {
                    $new_rhs[$rhs_ix] = $next_exp;
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'R' )
            if ( $assoc eq 'G' ) {
                for my $rhs_ix ( @arity[ 0 .. $#arity ] ) {
                    $new_rhs[$rhs_ix] = $lhs . '_0';
                }
                last DO_ASSOCIATION;
            } ## end if ( $assoc eq 'G' )
            die qq{Unknown association type: "$assoc"};
        } ## end DO_ASSOCIATION:
        push @xs_rules, { lhs => $current_exp, rhs => \@new_rhs, @action_kv };
    } ## end RULE: for my $rule (@rules)
    return [@xs_rules];
} ## end sub priority_rule

sub empty_rule { shift; return { @{ $_[0] }, rhs => [], @{ $_[2] || [] } }; }

sub quantified_rule {
    shift;
    return {
        @{ $_[0] },
        rhs => [ $_[2] ],
        min => ( $_[3] eq q{+} ? 1 : 0 ),
        @{ $_[4] || [] }
    };
} ## end sub quantified_rule

sub do_priority1        { shift; return [ $_[0] ]; }
sub do_priority3        { shift; return [ $_[0], @{ $_[2] } ]; }
sub do_full_alternative { shift; return [ ( $_[0] // 'L' ), $_[1], $_[2] ]; }
sub do_bare_alternative { shift; return [ ( $_[0] // 'L' ), $_[1], undef ] }
sub do_alternatives_1   { shift; return [ $_[0] ]; }
sub do_alternatives_3 { shift; return [ $_[0], @{ $_[2] } ] }
sub do_lhs { shift; return $_[0]; }
sub do_array { shift; return [@_]; }
sub do_arg1 { return $_[2]; }
sub do_right_adverb { return 'R' }
sub do_left_adverb  { return 'L' }
sub do_group_adverb { return 'G' }

sub do_what_I_mean {

    # The first argument is the per-parse variable.
    # Until we know what to do with it, just throw it away
    shift;

    # Throw away any undef's
    my @children = grep {defined} @_;

    # Return what's left
    return scalar @children > 1 ? \@children : shift @children;
} ## end sub do_what_I_mean

sub parse_rules {
    my ($string) = @_;

    my $grammar = Marpa::XS::Grammar->new(
        {   start          => 'rules',
            actions        => __PACKAGE__,
            default_action => 'do_what_I_mean',
            rules          => [
                {   lhs    => 'rules',
                    rhs    => [qw/rule/],
                    action => 'rules',
                    min    => 1
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare priorities/],
                    action => 'priority_rule'
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare action/],
                    action => 'empty_rule'
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare name quantifier action/],
                    action => 'quantified_rule'
                },

                {   lhs    => 'priorities',
                    rhs    => [qw(alternatives)],
                    action => 'do_priority1'
                },
                {   lhs    => 'priorities',
                    rhs    => [qw(alternatives op_tighter priorities)],
                    action => 'do_priority3'
                },

                {   lhs    => 'alternatives',
                    rhs    => [qw(alternative)],
                    action => 'do_alternatives_1',
                },
                {   lhs    => 'alternatives',
                    rhs    => [qw(alternative op_eq_pri alternatives)],
                    action => 'do_alternatives_3',
                },

                {   lhs    => 'alternative',
                    rhs    => [qw(adverb rhs action)],
                    action => 'do_full_alternative'
                },
                {   lhs    => 'alternative',
                    rhs    => [qw(adverb rhs)],
                    action => 'do_bare_alternative'
                },

                {   lhs    => 'adverb',
                    rhs    => [qw/op_group/],
                    action => 'do_group_adverb'
                },
                {   lhs    => 'adverb',
                    rhs    => [qw/op_right/],
                    action => 'do_right_adverb'
                },
                {   lhs    => 'adverb',
                    rhs    => [qw/op_left/],
                    action => 'do_left_adverb'
                },
                { lhs => 'adverb', rhs => [] },

                { lhs => 'action', rhs => [] },
                {   lhs    => 'action',
                    rhs    => [qw/op_arrow action_name/],
                    action => 'do_arg1'
                },
                {   lhs    => 'action',
                    rhs    => [qw/op_arrow name/],
                    action => 'do_arg1'
                },

                { lhs => 'lhs', rhs => [qw/name/], action => 'do_lhs' },

                { lhs => 'rhs',        rhs => [qw/names/] },
                { lhs => 'quantifier', rhs => [qw/op_plus/] },
                { lhs => 'quantifier', rhs => [qw/op_star/] },

                {   lhs    => 'names',
                    rhs    => [qw/name/],
                    min    => 1,
                    action => 'do_array'
                },
            ],
            lhs_terminals => 0,
        }
    );
    $grammar->precompute;

    my $rec = Marpa::XS::Recognizer->new( { grammar => $grammar } );

    # Order matters !!!
    my @terminals = (
        [ 'op_right',      qr/:right\b/xms ],
        [ 'op_left',       qr/:left\b/xms ],
        [ 'op_group',      qr/:group\b/xms ],
        [ 'op_declare',    qr/::=/xms ],
        [ 'op_arrow',      qr/=>/xms ],
        [ 'op_tighter',    qr/[|][|]/xms ],
        [ 'op_eq_pri',     qr/[|]/xms ],
        [ 'reserved_name', qr/(::(whatever|undef))/xms ],
        [ 'op_plus',       qr/[+]/xms ],
        [ 'op_star',       qr/[*]/xms ],
        [ 'name',          qr/\w+/xms ],
        [ 'name',          qr/['][^']+[']/xms ],
    );

    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;
            if ( not defined $rec->read( $t->[0], $1 ) ) {
                die die q{Problem before position }, pos $string, ': ',
                    ( substr $string, pos $string, 40 ),
                    qq{\nToken rejected, "}, $t->[0], qq{", "$1"},
                    ;
            } ## end if ( not defined $rec->read( $t->[0], $1 ) )
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    $rec->end_input;

    my $parse_ref = $rec->value;

    if ( !defined $parse_ref ) {
        say $rec->show_progress() or die "say failed: $ERRNO";
        die 'Parse failed';
    }
    my $parse = ${$parse_ref};

    return $parse;
} ## end sub parse_rules

1;
