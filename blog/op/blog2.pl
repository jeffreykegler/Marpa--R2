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
    Marpa::Blog::OP::parse_rules(
<<'END_OF_GRAMMAR'

e ::=
  NUM
  || e e
    | e STAR e
  || e PLUS e
  || SUM FROM e TO e BY e
  || :right e TERN e COLON e
  || :right e QUINE e COLON e COLON e COLON e
END_OF_GRAMMAR
    );

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
    [ 'QUINE', qr/quine\b/ ],
    [ 'SUM',   qr/sum\b/ ],
    [ 'FROM',  qr/from\b/ ],
    [ 'TO',    qr/to\b/ ],
    [ 'BY',    qr/by\b/ ],
    [ 'NUM',   qr/\d+/ ],
    [ 'STAR',  qr/[*]/ ],
    [ 'PLUS',  qr/[+]/ ],
    [ 'TERN',  qr/[?]/ ],
    [ 'COLON', qr/[:]/ ],
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
say Data::Dumper::Dumper($value_ref);

}

calculate( '4 * 3 + 42 1' );
calculate( '4 * 3 4 5 + 42 1' );
calculate( '4 quine 1+3 : 4 2 : 5 ? 42 : sum from 6 to 9 by 1 : 8' );
calculate( '4 quine 1+3 : 4 2 : 5 ? 42 : sum from 6 to 9 by 1 : 8' );
calculate( '1 2 3 4 5' );
calculate( '1 ? 2 : 3 ? 4 : 5 ' );
