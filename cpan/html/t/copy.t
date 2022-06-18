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

use 5.010001;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open close);
use Test::More;
use lib 'config';
use lib 'html/lib';
use Marpa::R2::Test;

BEGIN {
    use lib 'html/tool/lib';
    my $eval_result = eval { require Marpa::R2::HTML::Test::Util; 1 };
    if ( !$eval_result ) {
        Test::More::plan tests => 1;
        Test::More::fail(
            "Could not load Marpa::R2::HTML::Test::Util; $EVAL_ERROR");
        exit 0;
    } ## end if ( !$eval_result )
} ## end BEGIN

BEGIN { Marpa::R2::HTML::Test::Util::load_or_skip_all('HTML::Parser'); }

BEGIN { Test::More::plan tests => 1; }

use Marpa::R2::HTML;

my $document;
{
    local $RS = undef;
    open my $fh, q{<:utf8}, 'html/t/test.html';
    $document = <$fh>;
    close $fh
};

my $value = Marpa::R2::HTML::html( \$document );

Marpa::R2::Test::is( ${$value}, $document, 'Straight copy using defaults' );
