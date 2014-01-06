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

.PHONY: install docs sources

# Order matters -- configure.ac must be first
DOC_SOURCE_FILES = \
    doc/configure.ac \
    doc/Makefile.am \
    doc/fdl-1.3.texi \
    doc/lgpl-3.0.texi \
    doc/api.texi \
    doc/internal.texi \
    doc/NEWS \
    doc/README \
    doc/ChangeLog \
    doc/COPYING.LESSER \
    doc/AUTHORS

# Order matters -- configure.ac must be first
CONFIGURE_FILES = \
    stage/configure.ac \
    stage/Makefile.am

STAGE_FILES = \
    $(CONFIGURE_FILES) \
    stage/AUTHORS \
    stage/ChangeLog \
    stage/COPYING.LESSER \
    stage/marpa_ami.c \
    stage/marpa_ami.h \
    stage/marpa_avl.c \
    stage/marpa_avl.h \
    stage/marpa.c \
    stage/marpa_codes.c \
    stage/marpa.h \
    stage/marpa_obs.c \
    stage/marpa_obs.h \
    stage/marpa_slif.c \
    stage/marpa_slif.h \
    stage/marpa_tavl.c \
    stage/marpa_tavl.h \
    stage/NEWS \
    stage/README \
    stage/VERSION

dummy:
	@echo install is the main target

doc/configure.ac: ac_doc/configure.ac
	test -d doc || mkdir doc
	cp $? $@

doc/Makefile.am: ac_doc/Makefile.am
	cp $? $@

stage/configure.ac: ac/configure.ac
	test -d stage || mkdir stage
	cp $? $@

stage/Makefile.am: ac/Makefile.am
	cp $? $@

stage/marpa.c: dev/marpa.c
	cp $? $@

stage/marpa.h: public/marpa.h
	cp $? $@

stage/marpa_slif.h: public/marpa_slif.h
	cp $? $@

stage/marpa_obs.c: obs/marpa_obs.c
	cp $? $@

stage/marpa_obs.h: obs/marpa_obs.h
	cp $? $@

stage/marpa_ami.c: ami/marpa_ami.c
	cp $? $@

stage/marpa_codes.c: public/marpa_codes.c
	cp $? $@

stage/marpa_slif.c: slif/marpa_slif.c
	cp $? $@

stage/marpa_ami.h: ami/marpa_ami.h
	cp $? $@

stage/marpa_avl.c: avl/marpa_avl.c
	cp $? $@

stage/marpa_avl.h: avl/marpa_avl.h
	cp $? $@

stage/marpa_tavl.h: tavl/marpa_tavl.h
	cp $? $@

stage/marpa_tavl.c: tavl/marpa_tavl.c
	cp $? $@

stage/README: ac/README
	cp $? $@

stage/VERSION: public/VERSION
	cp $? $@

stage/NEWS: ac/NEWS
	cp $? $@

stage/AUTHORS: ac/AUTHORS
	cp $? $@

stage/COPYING.LESSER: ac/COPYING.LESSER
	cp $? $@

stage/ChangeLog: ac/ChangeLog
	cp $? $@

doc/README: ac_doc/README
	cp $? $@

doc/NEWS: ac_doc/NEWS
	cp $? $@

doc/AUTHORS: ac_doc/AUTHORS
	cp $? $@

doc/COPYING.LESSER: ac_doc/COPYING.LESSER
	cp $? $@

doc/ChangeLog: ac_doc/ChangeLog
	cp $? $@

doc/fdl-1.3.texi: ac_doc/fdl-1.3.texi
	cp $? $@

doc/lgpl-3.0.texi: ac_doc/lgpl-3.0.texi
	cp $? $@

doc/api.texi: dev/api.texi
	cp $? $@

doc/internal.texi: dev/internal.texi
	cp $? $@

stage/configure: $(STAGE_FILES)
	test -d stage || mkdir stage
	test -d stage/m4 || mkdir stage/m4
	cd stage && autoreconf -iv

stage/Makefile: stage/configure
	cd stage && ./configure

doc/api.pdf: doc/Makefile doc/api.texi
	cd doc && make pdf

doc/api.html/index.html: doc/Makefile doc/api.texi
	cd doc && make html

doc/internal.pdf: doc/Makefile doc/internal.texi
	cd doc && make pdf

doc/internal.html/index.html: doc/Makefile doc/internal.texi
	cd doc && make html

install: sources stage/stamp-h1 doc/stamp-h1

MAKEABLE_DIR = ami dev slif tavl public
CLEANABLE_DIR = $(MAKEABLE_DIR)

sources:
	for d in $(MAKEABLE_DIR); do (cd $$d; make); done

clean:
	for d in $(CLEANABLE_DIR); do (cd $$d; make clean); done

stage/stamp-h1: stage/Makefile $(STAGE_FILES)
	(cd stage; make dist)
	date > $@

doc/stamp-h1: doc/Makefile docs
	(cd doc; make dist)
	date > $@

doc/configure: $(DOC_SOURCE_FILES)
	test -d doc/m4 || mkdir doc/m4
	cd doc && autoreconf -ivf

doc/Makefile: doc/configure
	cd doc && ./configure

docs: doc/Makefile \
  doc/api.pdf doc/api.html/index.html \
  doc/internal.pdf doc/internal.html/index.html

