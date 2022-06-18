#!perl
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

use 5.010;
use strict;
use warnings;

use Marpa::XS;

use Data::Dumper;
require './OP.pm';

my $rules =
    Marpa::Blog::OP::parse_rules( "e ::= NUM || :right e POWER e || e STAR e || e PLUS e" );

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


my $grammar = Marpa::XS::Grammar->new(
    {   start          => 'e',
        actions        => __PACKAGE__,
        default_action => 'do_what_I_mean',
        rules          => $rules,
        lhs_terminals  => 0,
    }
);
$grammar->precompute;


# Order matters !!
my @terminals = (
    [ 'POWER',  qr/[*][*]/ ],
    [ 'NUM',  qr/\d+/ ],
    [ 'STAR', qr/[*]/ ],
    [ 'PLUS', qr/[+]/ ],
);

sub calculate {
    my ($string) = @_;
    my $rec = Marpa::XS::Recognizer->new( { grammar => $grammar } );
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
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    $rec->end_input;

    my $value_ref = $rec->value;

    if ( !defined $value_ref ) {
        say $rec->show_progress();
        die "Parse failed";
    }
    my $d = Data::Dumper->new([$value_ref]);
    say $d->Indent(0)->Terse(1)->Maxdepth(0)->Dump();
} ## end sub calculate

calculate( '4 * 3 + 1' );
calculate( '5 * 4 * 3 ** 2 ** 2 ** 2+ 1' );
