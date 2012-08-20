package Marpa::Blog::OP;

use 5.010;
use strict;
use warnings;

use Marpa::XS;

sub rules { my $m = shift; return { m => $m, rules => \@_ }; }
sub priority_rule { shift; return { @{ $_[0] }, priorities => $_[2] } }
sub empty_rule { shift; return { @{ $_[0] }, rhs => [], @{ $_[2] || [] } }; }
sub priority1 { shift; return [ $_[0] ]; }
sub priority3 { shift; return [ $_[0], @{ $_[2] } ]; }
sub do_full_alternative { shift; return [ $_[0], $_[1] ]; }
sub do_bare_alternative { shift; return [ $_[0], undef ] }
sub do_alternatives_1 { shift; return [ $_[0] ]; }
sub do_alternatives_3 { shift; return [ $_[0], @{ $_[2] } ] }
sub lhs     { shift; return [ lhs => $_[0] ]; }
sub op_star { shift; return [ rhs => [ $_[0] ], min => 0 ]; }
sub op_plus { shift; return [ rhs => [ $_[0] ], min => 1 ]; }
sub do_array { shift; return [@_]; }
sub do_bnf_rhs { shift; return \@_; }
sub do_arg1 { return $_[2]; }

sub do_what_I_mean {

    # The first argument is the per-parse variable.
    # Until we know what to do with it, just throw it away
    shift;

    # Throw away any undef's
    my @children = grep { defined } @_;

    # Return what's left
    return scalar @children > 1 ? \@children : shift @children;
}

sub parse_rules {
    my ($string) = @_;

    my $grammar = Marpa::XS::Grammar->new(
        {   start   => 'rules',
            actions => __PACKAGE__,
	    default_action => 'do_what_I_mean',
            rules   => [
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
                },

		{ lhs => 'priorities', rhs => [qw(alternatives)], action => 'priority1' },
		{ lhs => 'priorities', rhs => [qw(alternatives op_tighter priorities)], action => 'priority3' },

		{ lhs => 'alternatives', rhs => [qw(alternative)], action => 'do_alternatives_1', },
		{ lhs => 'alternatives', rhs => [qw(alternative op_eq_pri alternatives)], action => 'do_alternatives_3',
		},

		{ lhs => 'alternative', rhs => [qw(rhs action)], action => 'do_full_alternative' },
		{ lhs => 'alternative', rhs => [qw(rhs)], action => 'do_bare_alternative' },

                { lhs => 'action', rhs => [] },
                {   lhs    => 'action',
                    rhs    => [qw/op_arrow action_name/],
                    action => 'do_arg1'
                },
                {   lhs    => 'action',
                    rhs    => [qw/op_arrow name/],
                    action => 'do_arg1'
                },

                { lhs => 'lhs', rhs => [qw/name/], action => 'lhs' },

                { lhs => 'rhs', rhs => [qw/names/], action => 'do_bnf_rhs' },
                { lhs => 'rhs', rhs => [qw/name op_plus/], action => 'op_plus' },
                { lhs => 'rhs', rhs => [qw/name op_star/], action => 'op_star' },

                {   lhs    => 'names',
                    rhs    => [qw/name/],
                    min    => 1
                },
            ],
            lhs_terminals => 0,
        }
    );
    $grammar->precompute;

    my $rec = Marpa::XS::Recognizer->new( { grammar => $grammar } );

    my @terminals = (
        [ 'op_declare',    qr/::=/ ],
        [ 'op_arrow',      qr/=>/ ],
        [ 'op_tighter',    qr/[|][|]/ ],
        [ 'op_eq_pri',     qr/[|]/ ],
        [ 'reserved_name', qr/(::(whatever|undef))/ ],
        [ 'op_plus',       qr/[+]/ ],
        [ 'op_star',       qr/[*]/ ],
        [ 'name',          qr/\w+/, ],
    );

    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

	# skip whitespace
        next TOKEN if $string =~ m/\G\s+/gc;

	# read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gc;
            $rec->read( $t->[0], $1 );
            next TOKEN;
        }

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    $rec->end_input;

    my $parse_ref = $rec->value;

    if ( !defined $parse_ref ) {
	say $rec->show_progress();
        die "Parse failed";
    }
    my $parse = $$parse_ref;

    return $parse->{rules};
} ## end sub parse_rules

1;

