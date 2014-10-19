#!perl
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

# Tests of glade traversal from rns
# Originally to report github issue #184

use 5.010;
use strict;
use warnings;

use Test::More tests => 3;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my $g = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),

    :default ::= action => [ name, value]
    lexeme default = action => [ name, value ] latm => 1

        Expr ::=
              Number
           | Expr '**' Expr
           | Expr '-' Expr

        Number ~ [\d]+

    :discard ~ whitespace
    whitespace ~ [\s]+

END_OF_SOURCE
    }
);

my $input = <<EOI;
2**7-3**10
EOI

my $r = Marpa::R2::Scanless::R->new( { grammar => $g } );
$r->read( \$input );

{
 my $ambiguous_status = $r->ambiguous();
my $expected = <<'EOS';
Ambiguous symch at Glade=2, Symbol=<Expr>:
  The ambiguity is from line 1, column 1 to line 1, column 10
  Text is: 2**7-3**10
  There are 2 symches
  Symch 0 is a rule: Expr ::= Expr '**' Expr
  Symch 1 is a rule: Expr ::= Expr '-' Expr
EOS
Marpa::R2::Test::is($ambiguous_status, $expected, 'ambiguous_status()');
Test::More::ok( ( $r->ambiguity_metric() > 1 ), 'ambiguity_metric()');
}

{
    $r->series_restart();
    my $asf = Marpa::R2::ASF->new( { slr => $r } );
    my $full_result = $asf->traverse( {}, \&full_traverser );
    my $actual = join "\n", @{$full_result}, q{};
    my $expected = <<'EOS';
(Expr (Expr (Expr (2)) (**) (Expr (Expr (7)) (-) (Expr (3)))) (**) (Expr (10)))
(Expr (Expr (Expr (Expr (2)) (**) (Expr (7))) (-) (Expr (3))) (**) (Expr (10)))
(Expr (Expr (2)) (**) (Expr (Expr (Expr (7)) (-) (Expr (3))) (**) (Expr (10))))
(Expr (Expr (2)) (**) (Expr (Expr (7)) (-) (Expr (Expr (3)) (**) (Expr (10)))))
(Expr (Expr (Expr (2)) (**) (Expr (7))) (-) (Expr (Expr (3)) (**) (Expr (10))))
EOS
    Marpa::R2::Test::is( $actual, $expected, 'Result of ASF traversal' );
}

sub full_traverser {

    # This routine converts the glade into a list of elements.  It is called recursively.
    my ( $glade, $scratch ) = @_;
    my $rule_id     = $glade->rule_id();
    my $symbol_id   = $glade->symbol_id();
    my $symbol_name = $g->symbol_name($symbol_id);

    # A token is a single choice, and we know enough to return it
    if ( not defined $rule_id ) {
        my $literal = $glade->literal();
        return ["($literal)"];
    }

    # Our result will be a list of choices
    my @return_value = ();

    CHOICE: while (1) {

        # The results at each position are a list of choices, so
        # to produce a new result list, we need to take a Cartesian
        # product of all the choices
        my $length = $glade->rh_length();
        my @results = ( [] );
        for my $rh_ix ( 0 .. $length - 1 ) {
            my @new_results = ();
            for my $old_result (@results) {
                my $child_value = $glade->rh_value($rh_ix);
                for my $new_value ( @{$child_value} ) {
                    push @new_results, [ @{$old_result}, $new_value ];
                }
            } ## end for my $old_result (@results)
            @results = @new_results;
        } ## end for my $rh_ix ( 0 .. $length - 1 )

        # Special case for the start rule
        if ( $symbol_name eq '[:start]' ) {
            return [ map { join q{}, @{$_} } @results ];
        }

        # Now we have a list of choices, as a list of lists.  Each sub list
        # is a list of elements, which we need to join into
        # a single element.  The result will be to collapse
        # one level of lists, and leave us with a list of
        # elements
        my $join_ws = q{ };
        $join_ws = qq{\n   } if $symbol_name eq 'S';
        push @return_value,
            map { '(' . $symbol_name . q{ } . ( join $join_ws, @{$_} ) . ')' }
            @results;

        # Look at the next alternative in this glade, or end the
        # loop if there is none
        last CHOICE if not defined $glade->next();

    } ## end CHOICE: while (1)

    # Return the list of elements for this glade
    return \@return_value;
} ## end sub full_traverser

# vim: expandtab shiftwidth=4:
