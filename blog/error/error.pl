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

# Synopsis for Stuizand interface

use 5.010;
use strict;
use warnings;
use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $grammar = Marpa::R2::Grammar->new(
    {   start          => 'Script',
        actions        => 'My_Actions',
        default_action => 'do_first_arg',
        rules          => [ <<'END_OF_RULES' ]
Script ::= Expression
Expression ::=
    Number
   | op_times Expression Expression action => do_multiply
   | op_add Expression Expression action => do_add
END_OF_RULES
    }
);

sub My_Actions::do_add       { shift; return $_[1] + $_[2] }
sub My_Actions::do_multiply  { shift; return $_[1] * $_[2] }
sub My_Actions::do_first_arg { shift; return shift; }

$grammar->precompute();

my @terminals = (
    [ Number    => qr/\d+/xms,    "Number" ],
    [ op_times  => qr/[*]/xms,    'Multiplication operator' ], # order matters!
    [ op_add    => qr/[+]/xms,    'Addition operator' ],
);

sub my_parser {
    my ( $grammar, $string ) = @_;
    my $recce         = Marpa::R2::Recognizer->new( { grammar => $grammar } );
    my $length        = length $string;
    my $last_position = 0;
    pos $string = $last_position;
    TOKEN: while (1) {
        $last_position = pos $string;
        last TOKEN if $last_position >= $length;
        next TOKEN if $string =~ m/\G\s+/gcxms;    # skip whitespace
        if ($recce->exhausted()) {
           say $recce->show_progress();
        die "Recce is exhausted";
        }
        TOKEN_TYPE: for my $t (@terminals) {
            my ( $token_name, $regex, $long_name ) = @{$t};
            next TOKEN_TYPE if not $string =~ m/\G($regex)/gcxms;
            next TOKEN if defined $recce->read( $token_name, $1 );
           say STDERR $recce->show_progress();
            die
                qq{Parser rejected token "$long_name" at position $last_position, before "},
                substr( $string, $last_position, 40 ), q{"};
        } ## end TOKEN_TYPE: for my $t (@terminals)
        die qq{No token found at position $last_position, before "},
            substr( $string, pos $string, 40 ), q{"};
    } ## end TOKEN: while (1)
    my $value_ref = $recce->value;
    if (not defined $value_ref) {
           say STDERR $recce->show_progress();
        die "No parse";
    }
    return ${$value_ref};
} ## end sub my_parser

say my_parser( $grammar, '+ * 1 * 2 3 + + 1 2 4' );
say my_parser( $grammar, '+ * 1 * 2 3 * + + 1 2 4' );
# say my_parser( $grammar, '1 + 2 +3  4 + 5 + 6 + 7' );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
