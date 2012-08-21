#!perl

use 5.010;
use strict;
use warnings;

use Marpa::XS;

use Data::Dumper;
require './OP.pm';

my $rules =
    Marpa::Blog::OP::parse_rules( "e ::= NUM || e STAR e || e PLUS e" );

sub do_what_I_mean {

    # The first argument is the per-parse variable.
    # Until we know what to do with it, just throw it away
    shift;

    # Throw away any undef's
    my @children = grep {defined} @_;

    # Return what's left
    return scalar @children > 1 ? \@children : shift @children;
} ## end sub do_what_I_mean

say Data::Dumper::Dumper($rules);

my ($string) = '4 * 3 + 1';

my $grammar = Marpa::XS::Grammar->new(
    {   start          => 'e',
        actions        => __PACKAGE__,
        default_action => 'do_what_I_mean',
        rules          => $rules,
        lhs_terminals  => 0,
    }
);
$grammar->precompute;

my $rec = Marpa::XS::Recognizer->new( { grammar => $grammar } );

# Order matters !!
my @terminals =
    ( [ 'NUM', qr/\d+/ ], [ 'STAR', qr/[*]/ ], [ 'PLUS', qr/[+]/ ], );

my $length = length $string;
pos $string = 0;
TOKEN: while ( pos $string < $length ) {

    # skip whitespace
    next TOKEN if $string =~ m/\G\s+/gc;

    # read other tokens
    TOKEN_TYPE: for my $t (@terminals) {
        next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gc;
        if ( not defined $rec->read( $t->[0], $1 ) ) {
            die die q{Problem before position }, pos $string, ': ',
                ( substr $string, pos $string, 40 ),
                qq{\nToken rejected, "}, $t->[0], qq{", "$1"},
                ;
        } ## end if ( not defined $rec->read( $t->[0], $1 ) )
        next TOKEN;
    }

    die q{No token at "}, ( substr $string, pos $string, 40 ),
        q{", position }, pos $string;
} ## end TOKEN: while ( pos $string < $length )

$rec->end_input;

my $value_ref = $rec->value;

if ( !defined $value_ref ) {
    say $rec->show_progress();
    die "Parse failed";
}
say Data::Dumper::Dumper($value_ref);

