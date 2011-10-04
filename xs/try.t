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

my @RESULT;
my $parser = Marpa::Perl->new( {
    long_use         => sub {
    push @RESULT, 'LONG'
    },
    revlong_use         => sub {
    push @RESULT, 'REVLONG'
    },
    perl_version_use => sub {
    push @RESULT, 'PERL'
    },
    short_use        => sub {
    push @RESULT, 'SHORT'
    } }
);

my $string;
if ($utility) {
    $string = do { local $RS = undef; <STDIN> };
} else {
    $string = do { local $RS = undef; <DATA> };
}

$parser->read( \$string );
my $result = $parser->eval( );
say STDERR "Result:\n", join "\n", @RESULT;
if ($utility) {
    say $result ?  (${$result} // 'undef') : 'no parse';
} else {
    Marpa::Test::is( $result, q{}, qq{Test of use statements} );
}

1;    # In case used as "do" file

__DATA__
use v5;
use 5;
use 5.0;
use xyz;
use v5 xyz;
use 5 xyz;
use 5.0 xyz;
use xyz v5;
use xyz 5;
use xyz 5.0;
use v5 xyz 5;
use 5 xyz 5;
use 5.0 xyz 5;
use xyz v5 5;
use xyz 5 5;
use xyz 5.0 5;
use v5 xyz 5, 5;
use 5 xyz 5, 5;
use 5.0 xyz 5, 5;
use xyz v5 5, 5;
use xyz 5 5, 5;
use xyz 5.0 5, 5;
use xyz 5.0 @a;
