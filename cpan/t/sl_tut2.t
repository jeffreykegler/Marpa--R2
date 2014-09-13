#!/usr/bin/perl
# Copyright 2014 Jeffrey Kegler
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

# Tutorial 2 synopsis

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

# Marpa::R2::Display
# name: Tutorial 2 synopsis

use Marpa::R2;

my $dsl = <<'END_OF_DSL';
:default ::= action => [name,values]
lexeme default = latm => 1

Expression ::= Term action => ::first
Term ::=
      Factor action => ::first
    | Term '+' Term action => do_add
Factor ::=
      Number action => ::first
    | Factor '*' Factor action => do_multiply
Number ~ digits
digits ~ [\d]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
my $recce = Marpa::R2::Scanless::R->new(
    { grammar => $grammar, semantics_package => 'My_Actions' } );
my $input = '42 * 1 + 7';
my $length_read = $recce->read( \$input );

die "Read ended after $length_read of ", length $input, " characters"
    if $length_read != length $input;

if ( my $ambiguous_status = $recce->ambiguous() ) {
    die "Parse is ambiguous\n", $ambiguous_status;
}

my $value_ref = $recce->value;
my $value = ${$value_ref};

sub My_Actions::do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub My_Actions::do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}

# Marpa::R2::Display::End

Test::More::is( $value, 49, 'Tutorial 2 synopsis value' );

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
