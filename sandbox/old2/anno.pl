#!perl
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

use 5.010;
use warnings;
use strict;

use English qw( -no_match_vars );
use Getopt::Long;
use PPI 1.206;

use Marpa::R2;
use lib 'pperl';
use Marpa::R2::Perl;

my $verbose = 99;
my $result = GetOptions( "verbose=i" => \$verbose, );

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
my $not_perl_found = 0;
my $start = 0;
my $next_start = 0;
my $last_token_printed = -1;
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
            linecol( $tokens->[$next_start] ), 'to',
            linecol( $tokens->[$end] ),
            ( '=' x 20 );
        $next_start = $end + 1;
        next PERL_CODE;
    } ## end if ( not defined $start )

    my $not_perl_start = $last_token_printed + 1;
    my $not_perl_end   = $start - 1;
    if ( $not_perl_end >= $not_perl_start ) {
        $not_perl_found += ( $not_perl_end - $not_perl_start ) + 1;
        say join q{ }, ( '=' x 20 ), 'NOT Perl from',
            linecol( $tokens->[$not_perl_start] ), 'to',
            linecol( $tokens->[$not_perl_end] ), ( '=' x 20 );
        my $not_perl_code = join q{},
            map { $_->content() }
            @{$tokens}[ $not_perl_start .. $not_perl_end ];
        say $not_perl_code;
    } ## end if ( $not_perl_end >= $not_perl_start )

    $perl_found += ( $end - $start ) + 1;
    say join q{ }, ( '=' x 20 ), 'Perl from', linecol( $tokens->[$start] ),
        'to',
        linecol( $tokens->[$end] ), ( '=' x 20 );
    $last_token_printed = $end;
    my $perl_code = join q{},
        map { $_->content() } @{$tokens}[ $start .. $end ];
    say $perl_code;

    $next_start = $end + 1;
} ## end PERL_CODE: while (1)

printf "not perl tokens = %d; perl tokens = %d; all tokens=%d; %.2f%%\n",
    $not_perl_found, $perl_found, $count_of_tokens,
    ( $perl_found / $count_of_tokens ) * 100;

