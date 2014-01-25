#!perl
# Copyright 2014 Jeffrey Kegler
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

use lib 'tool/lib';
use lib 'html/tool/lib';
use English qw( -no_match_vars );
use Test::More;

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

use Marpa::R2::Test;
use Marpa::R2::HTML;

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open close);

my $document;
{
    local $RS = undef;
    open my $fh, q{<:utf8}, 'html/t/test.html';
    $document = <$fh>;
    close $fh;
};

my $no_tang_document;
{
    local $RS = undef;
    open my $fh, q{<:utf8}, 'html/t/no_tang.html';
    $no_tang_document = <$fh>;
    close $fh;
};

my $value = Marpa::R2::HTML::html(
    \$document,
    {   '.kTang' => sub { return q{}; }
    }
);

Marpa::R2::Test::is( ${$value}, $no_tang_document, 'remove kTang class' );
