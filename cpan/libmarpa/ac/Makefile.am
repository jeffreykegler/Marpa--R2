# Copyright 2013 Jeffrey Kegler
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

## Makefile.am -- Process this file with automake to produce Makefile.in

AM_CFLAGS = $(WARNING_CFLAGS) $(MARPA_DEBUG_FLAG)
AM_CPPFLAGS = $(WARNING_CPPFLAGS)
ACLOCAL_AMFLAGS = -I m4
noinst_LTLIBRARIES = libmarpa.la
libmarpa_la_SOURCES = marpa.c marpa.h \
    marpa_obs.c marpa_obs.h \
    marpa_avl.c marpa_avl.h \
    marpa_tavl.c marpa_tavl.h \
    marpa_ami.c marpa_ami.h \
    marpa_codes.c marpa_slif.c
nodist_libmarpa_la_SOURCES = marpa_config.h
EXTRA_DIST = VERSION
libmarpa_la_LIBADD = $(LIBOBJS)
include_HEADERS = marpa.h \
  marpa_avl.h marpa_tavl.h marpa_ami.h \
  marpa_slif.h marpa_obs.h
nodist_include_HEADERS = marpa_config.h
DISTCLEANFILES = marpa_config.h
TEXI2PDF = texi2pdf --pdf --batch --quiet

