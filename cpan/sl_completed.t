#!perl
# Copyright 2013 Jeffrey Kegler
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

# Test of scannerless parsing -- completion events

use 5.010;
use strict;
use warnings;

use Test::More tests => 3;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $rules = <<'END_OF_GRAMMAR';
:start ::= text
text ::= <text segment>* action => OK
<text segment> ::= subtext
<text segment> ::= <word>
subtext ::= '(' text ')'
event subtext = completed subtext

word ~ [\w]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new(
    {   action_object => 'My_Actions', source          => \$rules }
);


do_test($grammar, q{42 ( hi 42 hi ) 7 11});
do_test($grammar, q{42 ( hi) 42 (hi ) 7 11});
do_test($grammar, q{(hi 42 hi)});

sub show_last_subtext {
    my ($slr) = @_;
    my ( $start, $end ) = $slr->last_completed_range('subtext');
    return 'No expression was successfully parsed' if not defined $start;
    return $slr->range_to_string( $start, $end );
}

sub do_test {
    my ( $slg, $string ) = @_;
    my $recce  = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $length = length $string;
    my $pos    = $recce->read( \$string );
    READ: while (1) {
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            say "Event: $name";
            say "subtext: ", show_last_subtext($recce);
        }
        last READ if $pos >= $length;
        $pos = $recce->resume($pos) ;
    } ## end READ: for ( ; $pos < $length; $pos = $recce->resume() )
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse\n";
    }
    my $actual_value = ${$value_ref};
    Test::More::is( $actual_value, q{1792}, qq{Value for "$string"} );
} ## end sub do_test

package My_Actions;

sub OK { return 1792 };
sub new { return {}; }

# vim: expandtab shiftwidth=4:
