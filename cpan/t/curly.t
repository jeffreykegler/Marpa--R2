#!perl
# Copyright 2018 Jeffrey Kegler
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
use warnings;
use strict;

use English qw( -no_match_vars );

use Getopt::Long ();
use Test::More ( import => [] );
use lib 'pperl';

BEGIN {
    my $PPI_problem;
    CHECK_PPI: {
        if ( not eval { require PPI } ) {
            $PPI_problem = "PPI not installed: $EVAL_ERROR";
            last CHECK_PPI;
        }
        if ( not PPI->VERSION(1.206) ) {
            $PPI_problem = 'PPI 1.206 not installed';
        }
    } ## end CHECK_PPI:
    if ($PPI_problem) {
        Test::More::plan skip_all => $PPI_problem;
    }
    else {
        Test::More::plan tests => 8;
    }
} ## end BEGIN

use Marpa::R2;
use Marpa::R2::Perl;
use lib 'inc';
use Marpa::R2::Test;

# Run in utility mode?
my $utility = 0;
die if not Getopt::Long::GetOptions( utility => \$utility );

my %hash;
my %codeblock;

my @tests;
if ($utility) {
    my $string = do { local $RS = undef; <STDIN> };
    @tests = ( [ $string, q{} ] );
}
else {
    @tests = (
        [   '{42;{1,2,3;4}}', << 'END_OF_RESULT', 1
Code block at line 1, column 1
Code block at line 1, column 5
END_OF_RESULT
        ],
        [   '{42;{1,2,3,4}}', << 'END_OF_RESULT', 2
Code block at line 1, column 1
Code block at line 1, column 5
Hash at line 1, column 5
END_OF_RESULT
        ],
        [   '{42;{;1,2,3;4}}', << 'END_OF_RESULT', 1
Code block at line 1, column 1
Code block at line 1, column 5
END_OF_RESULT
        ],
        [   '{42;+{1,2,3,4}}', << 'END_OF_RESULT', 1
Code block at line 1, column 1
Hash at line 1, column 6
END_OF_RESULT
        ],
    );
} ## end else [ if ($utility) ]

my $parser = Marpa::R2::Perl->new( { closures => {} } );

TEST: for my $test (@tests) {

    my ( $string, $expected, $expected_parse_count ) = @{$test};
    $parser = $parser->read( \$string );
    my @values    = $parser->eval();
    my $recce     = $parser->{recce};
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $rules     = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    for my $earley_set_id ( 0 .. $recce->latest_earley_set() ) {
        my $progress_report = $recce->progress($earley_set_id);
        ITEM: for my $progress_item ( @{$progress_report} ) {
            my ( $rule_id, $position, $origin_earley_set_id ) = @{$progress_item};
            last ITEM if not defined $rule_id;
            next ITEM if $position >= 0;
            $position = $grammar_c->rule_length($rule_id);

# Marpa::R2::Display
# name: earleme() Synopsis

            my $origin_earleme = $recce->earleme($origin_earley_set_id);

# Marpa::R2::Display::End

            my $rule      = $rules->[$rule_id];
            my $rule_name = $rule->[Marpa::R2::Internal::Rule::NAME];
            next ITEM if not defined $rule_name;
            my $blocktype =
                  $rule_name eq 'anon_hash' ? 'hash'
                : $rule_name eq 'block'     ? 'code'
                : $rule_name eq 'mblock'    ? 'code'
                :                             undef;
            next ITEM if not defined $blocktype;
            my $PPI_tokens       = $parser->{PPI_tokens};
            my $earleme_to_token = $parser->{earleme_to_PPI_token};
            my $token = $PPI_tokens->[ $earleme_to_token->[$origin_earleme] ];
            my $location = 'line '
                . $token->logical_line_number()
                . q{, column }
                . $token->column_number;
            $hash{$location}++      if $blocktype eq 'hash';
            $codeblock{$location}++ if $blocktype eq 'code';
        } ## end for my $progress_item ( @{$progress_report} )
    } ## end for my $earley_set_id ( 0 .. $recce->latest_earley_set...)
    Marpa::R2::Test::is(
        ( scalar @values ),
        $expected_parse_count,
        'Count of values'
    );
    my @result;
    for my $location ( sort keys %hash ) {
        push @result, "Hash at $location\n";
    }
    for my $location ( sort keys %codeblock ) {
        push @result, "Code block at $location\n";
    }
    my $result = join q{}, sort @result;
    if ($utility) {
        say $result or die 'say builtin failed';
    }
    else {
        Marpa::R2::Test::is( $result, $expected, qq{Test of "$string"} );
    }
    %hash      = ();
    %codeblock = ();
} ## end for my $test (@tests)

# vim: expandtab shiftwidth=4:
