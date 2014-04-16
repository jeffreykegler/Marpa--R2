#!/bin/sh
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

# Copy the libmarpa distribution to a directory
# Note: This script needs to be portable

if [ $# != 1 ] 
then
	echo "usage: $0 target-directory" 1>&2
	exit 1
fi
todir="$1"
fromdir=libmarpa_dist
if [ ! -e "$fromdir" ]
then
    echo "cannot find directory $fromdir -- you need to be in a CPAN distribution directory to run this command" 1>&2
    exit 1
fi
if [ ! -d "$fromdir" ]
then
    echo "$fromdir is not a directory -- you need to be in a CPAN distribution directory to run this command" 1>&2
    exit 1
fi
checkfile="$fromdir/configure.ac"
if [ ! -e "$checkfile" ]
then
    echo "$fromdir does not contain a configure.ac file -- you need to be in a CPAN distribution directory to run this command" 1>&2
    exit 1
fi
if [ ! -r "$checkfile" ]
then
    echo "You not have the sufficient permissions to copy $checkfile" 1>&2
    exit 1
fi
if [ -e "$todir" ]
then
    echo "cannot create directory $todir -- something with that name already exists" 1>&2
    exit 1
fi
mkdir "$todir" || exit 1
# Copy using copying user's permissions and new modification times
(cd "$fromdir"; tar cf - . ) | (cd "$todir"; tar xfom -)
