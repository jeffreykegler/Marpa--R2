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

package Marpa::R2::Suggested;

use 5.010;
use strict;
use warnings;

use Fatal qw(open close chdir chmod utime);
use English qw( -no_match_vars );
use Time::Piece;

my $timestamp = localtime()->datetime;

my $prefix = <<"PREFIX";
/*
    DO NOT EDIT
    This file was generated automatically by $PROGRAM_NAME
    on $timestamp
 */

static const char* suggested_message(int error_code)
{
    switch (error_code) {
PREFIX

my $suffix = <<"SUFFIX";
    default: return NULL;
    }
}
SUFFIX

sub suggested_xs_contents {
    my ($error_list) = @_;
    open my $error_fh, q{<}, $error_list;
    my $result = $prefix;
    for my $line (<$error_fh>) {
	say STDERR $line;
        my ($macro, $message) = ($line =~ m/ \A ([^\s]*) \s+ [0-9]+ \s+ (.*) \z/xms);
	$message =~ s/\s*\z//xms;
	$message =~ s/"//gxms; # just in case
	$result .= qq{    case $macro: return "$message";\n};
    }
    return $result . $suffix;
}

1;
