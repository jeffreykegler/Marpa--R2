#!/usr/bin/perl
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

# Test new g1len action
# and now-deprecated g1length action

use 5.010001;
use strict;
use warnings;
use Scalar::Util;
use Data::Dumper;
use Test::More tests => 11;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

say 'Libmarpa tag: ' . Marpa::R2::Thin::tag();

my $bnf = <<'END_OF_BNF';
:default ::= action => [name,g1start,g1len,g1length,values]
lexeme default = latm => 1
top ::= beginning middle end
beginning ::= '(beginning)'
middle ::= '(middle)'
end ::= '(end)'

:discard ~ whitespace
whitespace ~ [\s]+
END_OF_BNF

my $grammar = Marpa::R2::Scanless::G->new(
    {
        source          => \$bnf,
    }
);

my $string = '(beginning) (middle) (end)';

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
$recce->read( \$string );

my $value_ref1;
my %parses = (
q{\['top',0,3,4,['beginning',0,1,2,'(beginning)'],['middle',1,1,2,'(middle)'],['end',2,1,2,'(end)']]}
      => '' );
PARSE: while (1) {
    my $value_ref = $recce->value();
    $value_ref1 = $value_ref if not defined $value_ref1;
    last PARSE if not defined $value_ref;
    my $dumped_value = myDump( $value_ref );
    $parses{$dumped_value} = 'found';
}
my %expected_parses = (
q{\['top',0,3,4,['beginning',0,1,2,'(beginning)'],['middle',1,1,2,'(middle)'],['end',2,1,2,'(end)']]}
      => 'found' );
cmpHash(\%parses, \%expected_parses, 'Parses');

my %expected_substrings = (
    q{<top> using g1len}          => '(beginning) (middle) (end)',
    q{<top> using g1length}       => '(beginning) (middle) (end)',
    q{<beginning> using g1len}    => '(beginning)',
    q{<beginning> using g1length} => '(beginning)',
    q{<middle> using g1len}       => '(middle)',
    q{<middle> using g1length}    => '(middle)',
    q{<end> using g1len}          => '(end)',
    q{<end> using g1length}       => '(end)',
);
my %substrings = ();
showNode($recce, \%substrings, $$value_ref1);
cmpHash(\%substrings, \%expected_substrings, "Substrings");

sub showNode {
    my ( $recce, $substrings, $node ) = @_;
    return if ref $node ne 'ARRAY';
    my ( $name, $g1start, $g1len, $g1length, @values ) = @$node;
    $substrings->{ "<$name> using g1len"} = $recce->substring( $g1start, $g1len );
    $substrings->{ "<$name> using g1length"} = $recce->substring( $g1start, $g1length-1 );
    for my $childNode (@values) {
        showNode( $recce, $substrings, $childNode );
    }
}

sub myDump {
    my $v = shift;
    return Data::Dumper->new( [$v] )->Indent(0)->Terse(1)->Dump;
}

sub cmpHash {
    my ( $got, $wanted, $tag ) = @_;
    my $i = 0;
  GOT: for my $key ( sort keys %$got ) {
        my $v        = $got->{$key};
        my $wanted_v = $wanted->{$key};
          if ( defined $wanted_v ) {
            delete $wanted->{$key};
            if ( $wanted_v eq $v ) {
                Test::More::pass("Value of $key in $tag matches: $v");
                next GOT;
            }
            Test::More::fail("Mismatch for $key in $tag: $wanted_v vs. $v");
        }
        else {
            Test::More::fail("Unexpected item in $tag: $key");
            Test::More::diag("Value of unexpected item in $tag was $v");
        }
        $i++;
    }
    my @not_found       = sort keys %$wanted;
    my $not_found_count = scalar @not_found;
    if ($not_found_count) {
        Test::More::fail("$not_found_count expected item(s) not found in $tag");
        for my $value (@not_found) {
            Test::More::diag("$value");
        }
    }
    else {
        Test::More::pass("All expected items found in $tag");
    }
}

# vim: expandtab shiftwidth=4:
