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
        Test::More::plan tests => 1;
    }
} ## end BEGIN

use Marpa::R2;
use Marpa::R2::Perl;
use lib 'inc';
use Marpa::R2::Test;

# Run in utility mode?
my $utility = 0;
die if not Getopt::Long::GetOptions( utility => \$utility );

sub concat {
    shift @_;
    return join q{}, map { $_ // '!UNDEF in concat!' } @_;
}
my %closure_by_action = (
    long_use => sub {
        'LONG: ' . join q{ }, map { $_ // q{()} } @_[ 1, 3 .. $#_ ];
    },
    revlong_use => sub {
        'REVLONG: ' . join q{ }, map { $_ // q{()} } @_[ 1, 3 .. $#_ ];
    },
    perl_version_use => sub {
        'PERL: ' . join q{ }, map { $_ // q{()} } @_[ 1, 3 .. $#_ ];
    },
    short_use => sub {
        'SHORT: ' . join q{ }, map { $_ // q{()} } @_[ 1, 3 .. $#_ ];
    },
    argexpr => \&concat,
);

my %closure_by_lhs = (
    prog    => sub { return $_[1] . "\n" },
    ary     => \&concat,
    lineseq => sub {
        shift @_;
        join "\n", grep { defined and length } @_;
    },
);

sub gen_closure {
    my ( $lhs, $rhs, $action ) = @_;
    my $closure = $closure_by_action{$action} // $closure_by_lhs{$lhs};
    return $closure if defined $closure and ref $closure eq 'CODE';
    die "lhs=$lhs: $closure is not a closure" if defined $closure;
    return sub {undef}
        if scalar @{$rhs} == 0;
    return sub { $_[1] }
        if scalar @{$rhs} == 1;
    return sub {
        my @args = map { $_ // 'undef' } @_[ 1 .. $#_ ];
        return
              ( join "\n", @args )
            . "\n$lhs ::= "
            . ( join q{ }, map { $_ // q{-} } @{$rhs} ) . q{; };
    };
} ## end sub gen_closure

my $parser = Marpa::R2::Perl->new( { closures => \&gen_closure } );

my $default_input = <<'END_OF_TEST_DATA';
use v5;
use 5;
use 5.1;
use xyz;
use v5 xyz;
use 5 xyz;
use 5.1 xyz;
use xyz v5;
use xyz 5;
use xyz 5.1;
use v5 xyz 5;
use 5 xyz 5;
use 5.1 xyz 5;
use xyz v5 5;
use xyz 5 5;
use xyz 5.1 5;
use v5 xyz 5, 5;
use 5 xyz 5, 5;
use 5.1 xyz 5, 5;
use xyz v5 5, 5;
use xyz 5 5, 5;
use xyz 5.1 5, 5;
use xyz 5.1 @a;
END_OF_TEST_DATA

my $string;
if ($utility) {
    $string = do { local $RS = undef; <STDIN> };
}
else {
    $string = $default_input;
}

my $expected = <<'EOS';
PERL: use v5 ;
PERL: use 5 ;
PERL: use 5.1 ;
SHORT: use xyz () ;
REVLONG: use v5 xyz () ;
REVLONG: use 5 xyz () ;
REVLONG: use 5.1 xyz () ;
LONG: use xyz v5 () ;
LONG: use xyz 5 () ;
LONG: use xyz 5.1 () ;
REVLONG: use v5 xyz 5 ;
REVLONG: use 5 xyz 5 ;
REVLONG: use 5.1 xyz 5 ;
LONG: use xyz v5 5 ;
LONG: use xyz 5 5 ;
LONG: use xyz 5.1 5 ;
REVLONG: use v5 xyz 5,5 ;
REVLONG: use 5 xyz 5,5 ;
REVLONG: use 5.1 xyz 5,5 ;
LONG: use xyz v5 5,5 ;
LONG: use xyz 5 5,5 ;
LONG: use xyz 5.1 5,5 ;
LONG: use xyz 5.1 @a ;
EOS

$parser->read( \$string );
my $result_ref = $parser->eval();
my $result = defined $result_ref ? ${$result_ref} : 'no parse';
if ($utility) {
    say $result or die 'say builtin failed';
}
else {
    Marpa::R2::Test::is( $result, $expected, 'Test of use statements' );
}

# vim: expandtab shiftwidth=4:
