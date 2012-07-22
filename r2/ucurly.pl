#!perl
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

use 5.010;
use warnings;
use strict;

use English qw( -no_match_vars );
use PPI 1.206;
use Marpa::R2;
use lib 'pperl';
use Marpa::R2::Perl;

my %hash;
my %codeblock;

my @tests;
my $string = do { local $RS = undef; <STDIN> };

my $finder = Marpa::R2::Perl->new( { embedded => 1, closures => {} } );
my $parser = Marpa::R2::Perl->new( { closures => {} } );

sub linecol {
    my ($token) = @_;
    return $token->logical_line_number() . ':' . $token->column_number;
}

my $tokens = $finder->tokens(\$string);
say 'count of tokens: ', (scalar @{$tokens});
my $start = 0;
my $next_start = 0;
PERL_CODE: while (1) {
  my ($start, $end) = $finder->find_perl( $next_start );
  last PERL_CODE if not defined $start;
  say join q{ }, ('=' x 20), linecol($tokens->[$start]), 'to', linecol($tokens->[$end]), ('=' x 20);
  say map { $_->content() } @{$tokens}[$start .. $end];
  $next_start = $end+1;
}

exit 0;

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

        my $origin_earleme = $recce->earleme($origin_earley_set_id);

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
        my $token    = $PPI_tokens->[ $earleme_to_token->[$origin_earleme] ];
        my $location = 'line '
            . $token->logical_line_number()
            . q{, column }
            . $token->column_number;
        $hash{$location}++      if $blocktype eq 'hash';
        $codeblock{$location}++ if $blocktype eq 'code';
    } ## end ITEM: for my $progress_item ( @{$progress_report} )
} ## end for my $earley_set_id ( 0 .. $recce->latest_earley_set...)
my @result;
for my $location ( sort keys %hash ) {
    push @result, "Hash at $location\n";
}
for my $location ( sort keys %codeblock ) {
    push @result, "Code block at $location\n";
}
my $result = join q{}, sort @result;
say $result or die 'say builtin failed';

