#!perl
# Marpa::R2 is Copyright (C) 2017, Jeffrey Kegler.
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

use 5.010001;

use strict;
use warnings;

use Test::More tests => 8;
use Data::Dumper;
use English qw( -no_match_vars );
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale( LC_ALL, "C" );

use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my @tests_data = ();
my @results    = ();

# Marpa::R2::Display
# name: Rank document synopsis

my $source = <<'END_OF_SOURCE';
  :discard ~ ws; ws ~ [\s]+
  :default ::= action => ::array
  
  Top ::= List action => main::group
  List ::= Item3 rank => 3
  List ::= Item2 rank => 2
  List ::= Item1 rank => 1
  List ::= List Item3 rank => 3
  List ::= List Item2 rank => 2
  List ::= List Item1 rank => 1
  Item3 ::= VAR '=' VAR action => main::concat
  Item2 ::= VAR '='     action => main::concat
  Item1 ::= VAR         action => main::concat
  VAR ~ [\w]+

END_OF_SOURCE

my @tests = (
    [ 'a',                 '(a)', ],
    [ 'a = b',             '(a=b)', ],
    [ 'a = b = c',         '(a=)(b=c)', ],
    [ 'a = b = c = d',     '(a=)(b=)(c=d)', ],
    [ 'a = b c = d',       '(a=b)(c=d)' ],
    [ 'a = b c = d e =',   '(a=b)(c=d)(e=)' ],
    [ 'a = b c = d e',     '(a=b)(c=d)(e)' ],
    [ 'a = b c = d e = f', '(a=b)(c=d)(e=f)' ],
);

my $grammar = Marpa::R2::Scanless::G->new( { source => \$source } );

for my $test (@tests) {
    my ( $input, $output ) = @{$test};
    my $recce = Marpa::R2::Scanless::R->new(
        {
            grammar        => $grammar,
            ranking_method => 'high_rule_only'
        }
    );
    $recce->read( \$input );
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die 'No parse';
    }
    push @results, ${$value_ref};
}

# Marpa::R2::Display::End

for my $ix ( 0 .. $#tests ) {
    my ( $input, $output ) = @{$tests[$ix]};
    my $result = $results[$ix];
    Test::More::is( $result, $output,
        sprintf( 'Ranking synopsis test #%d: "%s"', $ix, $input ) );
}

# Marpa::R2::Display
# name: rank example semantics

sub flatten {
    my ($array) = @_;

    # say STDERR 'flatten arg: ', Data::Dumper::Dumper($array);
    my $ref = ref $array;
    return [$array] if $ref ne 'ARRAY';
    my @flat = ();
  ELEMENT: for my $element ( @{$array} ) {
        my $ref = ref $element;
        if ( $ref ne 'ARRAY' ) {
            push @flat, $element;
            next ELEMENT;
        }
        my $flat_piece = flatten($element);
        push @flat, @{$flat_piece};
    }
    return \@flat;
}

sub concat {
    my ( $pp, @args ) = @_;

    # say STDERR 'concat: ', Data::Dumper::Dumper(\@args);
    my $flat = flatten( \@args );
    return join '', @{$flat};
}

sub group {
    my ( $pp, @args ) = @_;

    # say STDERR 'comma_sep args: ', Data::Dumper::Dumper(\@args);
    my $flat = flatten( \@args );
    return join '', map { +'(' . $_ . ')'; } @{$flat};
}

# Marpa::R2::Display::End

# vim: expandtab shiftwidth=4:
