# Copyright 2022 Jeffrey Kegler
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

## Makefile.am -- Process this file with automake to produce Makefile.in

AUTOMAKE_OPTIONS = subdir-objects
AM_CFLAGS = $(WARNING_CFLAGS) $(MARPA_DEBUG_FLAG)
AM_CPPFLAGS = $(WARNING_CPPFLAGS)
RELEASE= $(MARPA_LIB_MAJOR_VERSION).$(MARPA_LIB_MINOR_VERSION).$(MARPA_LIB_MICRO_VERSION)
ACLOCAL_AMFLAGS = -I m4
lib_LTLIBRARIES = libmarpa.la
libmarpa_la_SOURCES = marpa.c marpa.h \
    marpa_obs.c marpa_obs.h \
    marpa_avl.c marpa_avl.h \
    marpa_tavl.c marpa_tavl.h \
    marpa_ami.c marpa_ami.h \
    marpa_codes.c
noinst_LIBRARIES = libmarpa.a
# This CFLAGS setting is a no-op, except that it allows
# these file to be build both with libtools and without
libmarpa_a_CFLAGS = $(AM_CFLAGS)
libmarpa_a_SOURCES = marpa.c marpa.h \
    marpa_obs.c marpa_obs.h \
    marpa_avl.c marpa_avl.h \
    marpa_tavl.c marpa_tavl.h \
    marpa_ami.c marpa_ami.h \
    marpa_codes.c

# This method for including Russ Allbery's TAP harness follows
# his suggestions in "Using the harness" on his web page
# https://www.eyrie.org/~eagle/software/c-tap-harness/readme.html
#
check_PROGRAMS = tests/runtests \
  tests/simple/rule1 tests/simple/trivial \
  tests/simple/trivial1 tests/simple/depr_unvalued \
  tests/simple/nits tests/simple/issue92a \
  tests/simple/issue92b tests/simple/issue92c

tests_runtests_CPPFLAGS = \
    -DC_TAP_SOURCE='"$(abs_top_srcdir)/tests"' \
    -DC_TAP_BUILD='"$(abs_top_builddir)/tests"'
check_LIBRARIES = tests/tap/libtap.a
tests_tap_libtap_a_CPPFLAGS = -I$(abs_top_srcdir)/tests
tests_tap_libtap_a_SOURCES = tests/tap/basic.c tests/tap/basic.h \
	tests/tap/float.c tests/tap/float.h tests/tap/macros.h

check-local: $(check_PROGRAMS)
	cd tests && ./runtests -l $(abs_top_srcdir)/tests/TESTS

# Must turn off one of the warnings for Russ's runtests
tests_runtests_CFLAGS = $(AM_CFLAGS) -Wno-sign-conversion

tests_simple_rule1_LDADD = tests/tap/libtap.a libmarpa.a
tests_simple_trivial_LDADD = tests/tap/libtap.a libmarpa.a
tests_simple_trivial1_LDADD = tests/tap/libtap.a libmarpa.a
tests_simple_depr_unvalued_LDADD = tests/tap/libtap.a libmarpa.a
tests_simple_nits_LDADD = tests/tap/libtap.a libmarpa.a
tests_simple_issue92a_LDADD = tests/tap/libtap.a libmarpa.a
tests_simple_issue92b_LDADD = tests/tap/libtap.a libmarpa.a
tests_simple_issue92c_LDADD = tests/tap/libtap.a libmarpa.a

tests_simple_rule1_CPPFLAGS = -I$(abs_top_srcdir)/tests/simple -I$(abs_top_srcdir)/tests
tests_simple_trivial_CPPFLAGS = -I$(abs_top_srcdir)/tests/simple -I$(abs_top_srcdir)/tests
tests_simple_trivial1_CPPFLAGS = -I$(abs_top_srcdir)/tests/simple -I$(abs_top_srcdir)/tests
tests_simple_depr_unvalued_CPPFLAGS = -I$(abs_top_srcdir)/tests/simple -I$(abs_top_srcdir)/tests
tests_simple_nits_CPPFLAGS = -I$(abs_top_srcdir)/tests/simple -I$(abs_top_srcdir)/tests
tests_simple_issue92a_CPPFLAGS = -I$(abs_top_srcdir)/tests/simple -I$(abs_top_srcdir)/tests
tests_simple_issue92b_CPPFLAGS = -I$(abs_top_srcdir)/tests/simple -I$(abs_top_srcdir)/tests
tests_simple_issue92c_CPPFLAGS = -I$(abs_top_srcdir)/tests/simple -I$(abs_top_srcdir)/tests

tests_simple_rule1_SOURCES = tests/simple/rule1.c
tests_simple_trivial_SOURCES = tests/simple/trivial.c
tests_simple_trivial1_SOURCES = tests/simple/trivial1.c \
  tests/simple/marpa_m_test.c tests/simple/marpa_m_test.h
tests_simple_depr_unvalued_SOURCES = tests/simple/depr_unvalued.c \
  tests/simple/marpa_m_test.c tests/simple/marpa_m_test.h
tests_simple_nits_SOURCES = tests/simple/nits.c \
  tests/simple/marpa_m_test.c tests/simple/marpa_m_test.h
tests_simple_issue92a_SOURCES = tests/simple/issue92a.c \
  tests/simple/marpa_m_test.c tests/simple/marpa_m_test.h
tests_simple_issue92b_SOURCES = tests/simple/issue92b.c \
  tests/simple/marpa_m_test.c tests/simple/marpa_m_test.h
tests_simple_issue92c_SOURCES = tests/simple/issue92c.c \
  tests/simple/marpa_m_test.c tests/simple/marpa_m_test.h

EXTRA_DIST = README.INSTALL README.AIX libmarpa.pc GIT_LOG.txt \
  win32/marpa.def Makefile.win32 win32/do_config_h.pl \
  internals/libmarpa_ami.pdf internals/libmarpa_core.pdf \
  api_docs/libmarpa_api.pdf api_docs/libmarpa_api.html api_docs/api_html.tar \
  api_docs/libmarpa_api.info \
  error_codes.table events.table steps.table \
  version.m4 libmarpa_version.sh LIB_VERSION \
  tests/libtap.sh tests/TESTS

libmarpa_la_LIBADD = $(LIBOBJS)
libmarpa_la_LDFLAGS = -release $(RELEASE)
include_HEADERS = marpa.h \
  marpa_avl.h marpa_tavl.h marpa_ami.h \
  marpa_obs.h marpa_codes.h
TEXI2PDF = texi2pdf --pdf --batch --quiet

dist-hook:
	chmod u+w $(distdir)/GIT_LOG.txt
	git log -n 5 >> $(distdir)/GIT_LOG.txt
