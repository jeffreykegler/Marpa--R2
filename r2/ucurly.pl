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
use Getopt::Long;
use PPI 1.206;

use Marpa::R2;
use lib 'pperl';
use Marpa::R2::Perl;

my $task    = 'find_curly';
my $verbose = 99;
my $result = GetOptions( "verbose=i" => \$verbose, "task=s" => \$task );

my $string = do { local $RS = undef; <STDIN> };
my $finder = Marpa::R2::Perl->new( { embedded => 1, closures => {} } );
my $parser = Marpa::R2::Perl->new( { closures => {} } );

sub linecol {
    my ($token) = @_;
    return '?' if not defined $token;
    return $token->logical_line_number() . ':' . $token->column_number;
}

my $tokens = $finder->tokens(\$string);
$parser->clone_tokens($finder);
my $count_of_tokens = scalar @{$tokens};
my $perl_found = 0;
my $start = 0;
my $next_start = 0;
PERL_CODE: while (1) {
    last PERL_CODE if $next_start >= $count_of_tokens;
    my ( $start, $end ) = $finder->find_perl($next_start);
    my @issues = @{ $finder->{token_issues} };
    if ( $verbose > 1 and scalar @issues ) {
        say +( '=' x 20 );
        say @issues;
    }
    if ( not defined $start ) {
        $verbose > 1 and say join q{ }, ( '=' x 20 ), 'No Perl found',
            linecol( $tokens->[$next_start] ), 'to', linecol( $tokens->[$end] ),
            ( '=' x 20 );
        $next_start = $end + 1;
        next PERL_CODE;
    } ## end if ( not defined $start )
    $perl_found += ($end - $start) + 1;
    $verbose > 1 and say join q{ }, ( '=' x 20 ), linecol( $tokens->[$start] ), 'to',
        linecol( $tokens->[$end] ), ( '=' x 20 );
    my $perl_code = join q{}, map { $_->content() } @{$tokens}[ $start .. $end ];
    if ( $verbose > 1 ) {
        say $perl_code;
    }
    else {
        $perl_code =~ s/^\s*//;
        $perl_code =~ s/\s*$//;
        say 'Perl fragment: ', $perl_code;
    }
    if ( $task eq 'find_curly' ) {
        find_curly( $parser, $start, $end - 1 );
    }
    $next_start = $end + 1;
} ## end PERL_CODE: while (1)

printf "perl tokens = %d; all tokens=%d; %.2f%%\n", $perl_found,
    $count_of_tokens, ( $perl_found / $count_of_tokens ) * 100;

sub find_curly {
    my ( $parser, $start_ix, $end_ix ) = @_;

    $parser->read_tokens( $start_ix, $end_ix );

    my $recce            = $parser->{recce};
    my $earleme_to_token = $parser->{earleme_to_PPI_token};
    my $PPI_tokens       = $parser->{PPI_tokens};
    my $grammar          = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c        = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $rules            = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    for my $earley_set_id ( 0 .. $recce->latest_earley_set() ) {
        my @hash_locations  = ();
        my @code_locations  = ();
        my $progress_report = $recce->progress($earley_set_id);
        ITEM: for my $progress_item ( @{$progress_report} ) {
            my ( $rule_id, $position, $origin_earley_set_id ) =
                @{$progress_item};
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
            my $token = $PPI_tokens->[ $earleme_to_token->[$origin_earleme] ];
            push @hash_locations, [ $origin_earleme, $earley_set_id ]
                if $blocktype eq 'hash';
            push @code_locations, [ $origin_earleme, $earley_set_id ]
                if $blocktype eq 'code';

        } ## end ITEM: for my $progress_item ( @{$progress_report} )
        my @ambiguous = ();
        push @ambiguous, 'Ambiguous'
            if scalar @hash_locations and scalar @code_locations;
        for my $hash_location (@hash_locations) {
            my ( $start, $end ) = @{$hash_location};
            my $start_ix = $earleme_to_token->[$start];
            my $end_ix   = $earleme_to_token->[$end];
            if ( defined $end_ix ) {
                $end_ix--;
            }
            else {
                do { }
                    while not
                        defined( $end_ix = $earleme_to_token->[ --$end ] );
            }
            my $string = join q{},
                map { $_->content() } @{$tokens}[ $start_ix .. $end_ix ];
            $string =~ s/^\s*//;
            $string =~ s/\s*$//;
            say join q{ }, @ambiguous, 'Hash at',
                linecol( $PPI_tokens->[$start_ix] ),
                linecol( $PPI_tokens->[$end_ix] ), $string;
        } ## end for my $hash_location (@hash_locations)
        for my $code_location (@code_locations) {
            my ( $start, $end ) = @{$code_location};
            my $start_ix = $earleme_to_token->[$start];
            my $end_ix   = $earleme_to_token->[$end];
            if ( defined $end_ix ) {
                $end_ix--;
            }
            else {
                do { }
                    while not
                        defined( $end_ix = $earleme_to_token->[ --$end ] );
            }
            my $string = join q{},
                map { $_->content() } @{$tokens}[ $start_ix .. $end_ix ];
            $string =~ s/^\s*//;
            $string =~ s/\s*$//;
            say join q{ }, @ambiguous, 'Code block at',
                linecol( $PPI_tokens->[$start_ix] ),
                linecol( $PPI_tokens->[$end_ix] ), $string;
        } ## end for my $code_location (@code_locations)
    } ## end for my $earley_set_id ( 0 .. $recce->latest_earley_set...)

} ## end sub find_curly
