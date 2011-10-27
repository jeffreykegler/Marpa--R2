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

use 5.010;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open close);
use lib 'config';
use lib 'html/lib';

BEGIN {
    my $eval_result =
        eval { require HTML::PullParser; 'HTML::PullParser'->import; 1 };
    if ( !$eval_result ) {
        print "1..0 # Skip Could not load HTML::PullParser; $EVAL_ERROR\n";
        exit 0;
    }
    $eval_result = eval { require Marpa::R2::Config; 1 };
    if ( !$eval_result ) {
        print "1..0 # Skip Could not load Marpa::R2::Config; $EVAL_ERROR\n";
        exit 0;
    }
    my $version_wanted = $Marpa::R2::VERSION_FOR_CONFIG{'HTML::PullParser'};
    if ( !HTML::PullParser->VERSION($version_wanted) ) {
        print "1..0 # Skip HTML::PullParser version is ",
            $HTML::PullParser::VERSION, "; we wanted $version_wanted\n";
        exit 0;
    }
} ## end BEGIN

use Test::More tests => 2;

BEGIN { Test::More::use_ok('Marpa::R2::HTML'); }

my $document;
{
    local $RS = undef;
    open my $fh, q{<:utf8}, 'html/t/test.html';
    $document = <$fh>;
    close $fh
};

my $value = Marpa::R2::HTML::html( \$document );

Test::More::is( ${$value}, $document, 'Straight copy using defaults' );
