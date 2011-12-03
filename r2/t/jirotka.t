#!perl
# Copyright 2011 Jeffrey Kegler
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
# An ambiguous equation

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;

use lib 'tool/lib';
use Marpa::R2::Test;

use Modern::Perl;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw( close open );

BEGIN {
    Test::More::use_ok('Marpa::R2');
}

# Regression test for bug originally found and documented
# by Tomas Jirotka

## INPUT DATA
my $tokens = [
	['CREATE','Create'],
	['METRIC','Metric'],
	['ID_METRIC','m'],
	['AS','As'],
	['SELECT','Select'],
	['NUMBER',1],
	['WHERE','Where'],
	['TRUE','True'],
];

my @terminals = qw/AS BY CREATE FALSE FOR METRIC PF SELECT TRUE WHERE WITH ID_METRIC SEPARATOR NUMBER/;
my $grammar = Marpa::R2::Grammar->new(
  {
    start => 'Input',
    action_object => 'Maql_Actions',
    default_action => 'tisk',
    terminals => \@terminals,
    rules => [
      {
        lhs => 'Input',
	rhs => ['Statement'],
	min => 1,
	separator => 'SEPARATOR'
      },
      {
        lhs => 'Statement',
	rhs => [qw/CREATE TypeDef/],
      },
      {
	lhs => 'TypeDef',
        rhs => [qw/METRIC ID_METRIC AS MetricSelect/],
      },
      {
        lhs => 'MetricSelect',
        rhs => [qw/SELECT MetricExpr ByClause Match Filter WithPf/],
      },
      {
        lhs => 'MetricExpr',
        rhs => [qw/NUMBER/],
      },
##############################################################################
      {
        lhs => 'ByClause',
        rhs => [],
      },
      {
        lhs => 'ByClause',
        rhs => [qw/BY/],
      },
##############################################################################
      {
        lhs => 'Match',
        rhs => [],
      },
      {
        lhs => 'Match',
        rhs => [qw/FOR/],
      },
#############################################################################
      {
        lhs => 'Filter',
        rhs => [],
      },
      {
        lhs => 'Filter',
        rhs => [qw/WHERE FilterExpr/],
      },
      {
        lhs => 'FilterExpr',
	rhs => [qw/TRUE/],
      },
      {
        lhs => 'FilterExpr',
	rhs => [qw/FALSE/],
      },
###############################################################################
      {
        lhs => 'WithPf',
        rhs => [],
      },
      {
        lhs => 'WithPf',
        rhs => [qw/WITH PF/],
      },
###############################################################################
    ],
  }
);

$grammar->precompute();
say STDERR "GRAMMAR:\n",$grammar->show_symbols();
say STDERR "RULES:", $grammar->show_rules();
say STDERR "AHFA:\n", $grammar->show_AHFA();
say STDERR "AHFA ITEMS:\n", $grammar->show_AHFA_items();
my $recog = Marpa::R2::Recognizer->new( { grammar => $grammar ,
    trace_terminals => 1,
trace_values=>3 } );
for my $token ( @{$tokens} ) { $recog->read( @{$token} ); }
my @result = $recog->value();
say "EARLEY_SETS:\n", $recog->show_earley_sets(), "\n";
say "AND NODES:\n", $recog->show_and_nodes(), "\n";
say "OR NODES:\n", $recog->show_or_nodes(), "\n";
Marpa::R2::Test::is( Dumper( \@result ), <<'END_OF_STRING', 'Jirotka test');
$VAR1 = [
          \[
              [
                'Create',
                [
                  'Metric',
                  'm',
                  'As',
                  [
                    'Select',
                    [
                      1
                    ],
                    undef,
                    undef,
                    [
                      'Where',
                      [
                        'True'
                      ]
                    ],
                    undef
                  ]
                ]
              ]
            ]
        ];
END_OF_STRING

#############################################################################
package Maql_Actions;

sub new { }

sub tisk { shift; return \@_; }

