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
use English qw( -no_match_vars );
use Fatal qw(open close);

my @defs;
LINE: while ( my $line = <STDIN> ) {

    next LINE if $line =~ m/ [{] Macro [}] /xms;

    if ( $line =~ /[@]deftypefun/xms ) {
        my $def = q{};
        while ( $line =~ / [@] \s* \z /xms ) {
            $def .= $line;
            $def =~ s/ [@] \s* \z//xms;
            $line = <STDIN>;
        }
        $def .= $line;
        $def =~ s/\A \s* [@] deftypefun x? \s* //xms;
        $def =~ s/ [@]var[{] ([^}]*) [}]/$1/xmsg;
        $def =~ s/ [@]code[{] ([^}]*) [}]/$1/xmsg;
        $def =~ s/\s+/ /xmsg;
        $def =~ s/\s \z/;/xmsg;
        push @defs, $def;
    } ## end if ( $line =~ /[@]deftypefun/xms )

} ## end while ( my $line = <STDIN> )

say join "\n", @defs;

# vim: expandtab shiftwidth=4:
