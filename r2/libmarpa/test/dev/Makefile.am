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

## Makefile.am -- Process this file with automake to produce Makefile.in

AM_CFLAGS = $(WARNING_CFLAGS)
ACLOCAL_AMFLAGS = -I m4
EXTRA_DIST = README
noinst_PROGRAMS = testleak
testleak_LDADD = $(LIBOBJS) $(GLIB_LIBS) ../../build/libmarpa.la
testleak_CFLAGS = $(GLIB_CFLAGS) $(WARNING_CFLAGS) -I../../dist


