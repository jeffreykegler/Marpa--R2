#!perl
# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

use 5.010;
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
            $PPI_problem = 'PPI not installed';
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
        Test::More::plan tests => 10;
    }
    Test::More::use_ok('Marpa::XS');
    Test::More::use_ok('Marpa::Perl');
} ## end BEGIN

use lib 'tool/lib';
use Marpa::Test;

# Run in utility mode?
my $utility = 0;
die if not Getopt::Long::GetOptions( utility => \$utility );

my %hash;
my %codeblock;

my $parser = Marpa::Perl->new( {} );

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

# This interface requires the user to know a lot about
# the internals of Marpa::XS.  That's OK in the internal
# testing context,
# but if I want to document this interface, it needs to
# be rethought.
sub tag_completion {
    my ($parser, $and_node_id) = @_;
    my $recce = $parser->{recce};
    die if not defined $recce;
    my $recce_c   = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar   = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    die if not defined $grammar;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $parent = $recce_c->and_node_parent($and_node_id);
    my $rule_id    = $recce_c->or_node_rule($parent);
    my $semantic_rule_id = $grammar_c->semantic_equivalent($rule_id);
    my $rules = $grammar->[Marpa::XS::Internal::Grammar::RULES];
    my $rule = $rules->[$semantic_rule_id];
    my $rule_name = $rule->[Marpa::XS::Internal::Rule::NAME];
    return if not defined $rule_name;
    my $blocktype = $rule_name eq 'anon_hash' ? 'hash'
	: $rule_name eq 'block' ? 'code'
	: $rule_name eq 'mblock' ? 'code' : undef;
    return if not defined $blocktype;
    my $PPI_tokens = $parser->{PPI_tokens};
    my $earleme_to_token = $parser->{earleme_to_PPI_token};
    my $origin          = $recce_c->or_node_origin($parent);
    my $origin_earleme  = $recce_c->earleme($origin);
    my $token = $PPI_tokens->[ $earleme_to_token->[$origin_earleme] ];
    my $location = 'line '
        . $token->logical_line_number()
        . q{, column }
        . $token->column_number;
    $hash{$location}++ if $blocktype eq 'hash';
    $codeblock{$location}++ if $blocktype eq 'code';
}

TEST: for my $test (@tests) {

    my ( $string, $expected, $expected_parse_count ) = @{$test};
    my $parser = $parser->read( \$string );
    my @values = $parser->eval( );
    $parser->foreach_completion(\&tag_completion);
    Marpa::Test::is( (scalar @values), $expected_parse_count, 'Count of values' );
    my @result;
    for my $location ( sort keys %hash ) {
        push @result, "Hash at $location\n";
    }
    for my $location ( sort keys %codeblock ) {
        push @result, "Code block at $location\n";
    }
    my $result = join q{}, sort @result;
    if ($utility) {
        say $result;
    } else {
	Marpa::Test::is( $result, $expected, qq{Test of "$string"} );
    }
    %hash      = ();
    %codeblock = ();
} ## end for my $test (@tests)

1;    # In case used as "do" file

