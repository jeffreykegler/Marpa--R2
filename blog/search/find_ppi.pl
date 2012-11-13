#!/usr/bin/perl
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
use strict;
use warnings;
use English qw( -no_match_vars );
use PPI;

my $string    = join q{}, <>;
my @PPI_token_by_earley_set = ();

my $document = PPI::Document->new(\$string);
$document->index_locations();
my @tokens =$document->tokens();

TOKEN: for my $PPI_token (@tokens) {
    say join " ", (ref $PPI_token), $PPI_token->content();
} ## end TOKEN: while ( pos $string < $length )
