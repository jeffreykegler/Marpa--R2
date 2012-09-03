package Marpa::R2::Demo::OP4;

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Marpa::R2;

sub do_arg0 { return $_[1]; }

sub do_rules {
    shift;
    return [ map { @{$_} } @_ ];
}

sub do_priority_rule {
    my ( undef, $lhs, undef, $priorities ) = @_;
    my $priority_count = scalar @{$priorities};
    my @rules          = ();
    for my $priority_ix ( 0 .. $priority_count - 1 ) {
        my $priority = $priority_count - ( $priority_ix + 1 );
        for my $alternative ( @{ $priorities->[$priority_ix] } ) {
            push @rules, [ $priority, @{$alternative} ];
        }
    } ## end for my $priority_ix ( 0 .. $priority_count - 1 )
    if ( scalar @rules <= 1 ) {

        # If there is only one rule,
        my ( $priority, $assoc, $rhs, $action ) = @{ $rules[0] };
        my @action_kv;
        push @action_kv, action => $action if defined $action;
        return [ { lhs => $lhs, rhs => $rhs, @action_kv } ];
    } ## end if ( scalar @rules <= 1 )
    my $do_arg0_full_name = __PACKAGE__ . q{::} . 'do_arg0';
    my @xs_rules = (
        {   lhs    => $lhs,
            rhs    => [ $lhs . '_0' ],
            action => $do_arg0_full_name
        },
        (   map {
                ;
                {   lhs => ( $lhs . '_' . ( $_ - 1 ) ),
                    rhs => [ $lhs . '_' . ($_) ],
                    action => $do_arg0_full_name
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
} ## end sub do_priority_rule

sub do_empty_rule {
    my ( undef, $lhs, undef, $action ) = @_;
    my @action_kv;
    push @action_kv, action => $action if defined $action;
    return [ { lhs => $lhs, rhs => [], @action_kv } ];
}

sub do_quantified_rule {
    my ( undef, $lhs, undef, $rhs, $quantifier, $action ) = @_;
    my @action_kv;
    push @action_kv, action => $action if defined $action;
    return [
        {   lhs => $lhs,
            rhs => [$rhs],
            min => ( $quantifier eq q{+} ? 1 : 0 ),
            @action_kv
        }
    ];
} ## end sub do_quantified_rule

sub do_simple_rule {
    shift;
    return {
        @{ $_[0] },
        rhs => [ $_[2] ],
        @{ $_[3] || [] }
    };
} ## end sub do_simple_rule

sub do_priority1 {
    shift;
    return [ $_[0] ];
}

sub do_priority3 {
    shift;
    return [ $_[0], @{ $_[2] } ];
}
sub do_full_alternative { shift; return [ ( $_[0] // 'L' ), $_[1], $_[2] ]; }
sub do_bare_alternative { shift; return [ ( $_[0] // 'L' ), $_[1], undef ] }

sub do_alternatives_1 {
    shift;
    return [ $_[0] ];
}

sub do_alternatives_3 {
    shift;
    return [ $_[0], @{ $_[2] } ];
}
sub do_lhs { shift; return $_[0]; }
sub do_array { shift; return [@_]; }
sub do_arg1         { return $_[2]; }
sub do_right_adverb { return 'R' }
sub do_left_adverb  { return 'L' }
sub do_group_adverb { return 'G' }
sub do_action_adverb {
    my ($action_name) = ( $_[1] =~ m/[<] ( [^>]* )/xms );
    return $action_name;
}

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

    my $grammar = Marpa::R2::Grammar->new(
        {   start          => 'rules',
            actions        => __PACKAGE__,
            default_action => 'do_what_I_mean',
            rules          => [
                {   lhs    => 'rules',
                    rhs    => [qw/rule/],
                    action => 'do_rules',
                    min    => 1
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare priorities/],
                    action => 'do_priority_rule'
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare action/],
                    action => 'do_empty_rule'
                },
                {   lhs    => 'rule',
                    rhs    => [qw/lhs op_declare name quantifier action/],
                    action => 'do_quantified_rule'
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
                    rhs    => [qw/action_adverb/],
                    action => 'do_action_adverb'
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
        }
    );
    $grammar->precompute;

    my $rec = Marpa::R2::Recognizer->new( { grammar => $grammar } );

    # Order matters !!!
    my @terminals = (
        [ 'op_right',      qr/:right\b/xms ],
        [ 'op_left',       qr/:left\b/xms ],
        [ 'op_group',      qr/:group\b/xms ],
	[ 'action_adverb', qr/:action [<] [^>]* [>]/xms ],
        [ 'op_declare',    qr/::=/xms ],
        [ 'op_tighter',    qr/[|][|]/xms ],
        [ 'op_eq_pri',     qr/[|]/xms ],
        [ 'op_plus',       qr/[+]/xms ],
        [ 'op_star',       qr/[*]/xms ],
        [ 'action_name',          qr/ \w+ /xms ],
        [ 'name',          qr/[<] [\w] [\w ]* [>]/xms ],
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
            my $token_value = $1;
            if ( $t->[0] eq 'name' ) {

                # normalize spaces
                $token_value =~ s/ [ ]+ / /xmsg;
                $token_value =~ s/ [ ]* \z //xms;
            } ## end if ( $t->[0] eq 'name' )
            if ( not defined $rec->read( $t->[0], $token_value ) ) {
                die die q{Problem before position }, pos $string, ': ',
                    ( substr $string, pos $string, 40 ),
                    qq{\nToken rejected, "}, $t->[0], qq{", "$token_value"},
                    ;
            } ## end if ( not defined $rec->read( $t->[0], $token_value ))
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{OP: No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    my $parse_ref = $rec->value;

    if ( !defined $parse_ref ) {
        say $rec->show_progress() or die "say failed: $ERRNO";
        die 'Parse failed';
    }
    my $parse = ${$parse_ref};

    return $parse;
} ## end sub parse_rules

1;
