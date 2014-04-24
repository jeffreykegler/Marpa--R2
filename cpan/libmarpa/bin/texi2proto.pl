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

sub usage {
    say STDERR "usage: $0 def_file <texi_file > proto_file";
    exit 1;
}

usage() unless @ARGV == 1;
my ($def_file) = @ARGV;
open my $def_fh, q{>}, $def_file;

my @protos;
my @defs;
LINE: while ( my $line = <STDIN> ) {

    next LINE if $line =~ m/ [{] Macro [}] /xms;

    next LINE if $line !~ m/[@]deftypefun/xms;

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
    push @protos, $def;

    $def =~ s/ \s* [(] .* //xms;
    $def =~ s/ \s* [(] .* //xms;
    $def =~ s/ \A .* \s //xms;
    push @defs, $def;

} ## end LINE: while ( my $line = <STDIN> )

say join "\n", @protos;

my $def_preamble = << 'END_OF_PREAMBLE';
; DO NOT EDIT DIRECTLY.
; This file was automatically generated.
; This file is for the Microsoft linker.
END_OF_PREAMBLE
$def_preamble .= q{; } . localtime() . "\n";

say {$def_fh} $def_preamble, "EXPORTS\n", join "\n",
    map { q{   } . $_ } @defs;

# vim: expandtab shiftwidth=4:
