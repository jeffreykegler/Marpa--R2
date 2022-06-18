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
use English qw( -no_match_vars );
use Marpa::HTML;
use WWW::Mechanize;

my $arg = shift;
say $arg;
my $mech = WWW::Mechanize->new( autocheck => 1 );
$mech->get( $arg );
my $document = $mech->content;
undef $mech;

my @result;
my $keep_me = sub { push @result, Marpa::HTML::original()  };

my $value = Marpa::HTML->new(
    {   handlers => [
            [   ':PI' => $keep_me ],
            [   ':COMMENT' => $keep_me ],
            [   'font' => $keep_me ],
        ],
    }
)->parse( \$document );

say join "\n", @result;
