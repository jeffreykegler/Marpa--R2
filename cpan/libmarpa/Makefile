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

.PHONY: install docs

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
    stage/marpa.c \
    stage/marpa.h \
    stage/marpa_slif.h \
    stage/marpa_util.h \
    stage/marpa_int.h \
    stage/marpa_obs.c \
    stage/marpa_obs.h \
    stage/marpa_ami.h \
    stage/marpa_ami.c \
    stage/marpa_avl.h \
    stage/private.h \
    stage/ami_private.h \
    stage/marpa_avl.c \
    stage/NEWS \
    stage/VERSION.in \
    stage/README \
    stage/ChangeLog \
    stage/COPYING.LESSER \
    stage/AUTHORS

dummy:
	@echo install is the main target

doc/configure.ac: dev/doc_dist/configure.ac
	test -d doc || mkdir doc
	cp $? $@

doc/Makefile.am: dev/doc_dist/Makefile.am
	cp $? $@

stage/configure.ac: dev/dist/configure.ac
	test -d stage || mkdir stage
	cp $? $@

stage/Makefile.am: dev/dist/Makefile.am
	cp $? $@

stage/marpa.c: dev/marpa.c
	cp $? $@

stage/marpa.h: public/marpa.h
	cp $? $@

stage/marpa_slif.h: public/marpa_slif.h
	cp $? $@

stage/marpa_int.h: dev/marpa_int.h
	cp $? $@

stage/marpa_util.h: dev/marpa_util.h
	cp $? $@

stage/marpa_obs.c: obs/marpa_obs.c
	cp $? $@

stage/marpa_obs.h: obs/marpa_obs.h
	cp $? $@

stage/marpa_ami.c: ami/marpa_ami.c
	cp $? $@

stage/marpa_ami.h: ami/marpa_ami.h
	cp $? $@

stage/marpa_avl.c: avl/marpa_avl.c
	cp $? $@

stage/marpa_avl.h: avl/marpa_avl.h
	cp $? $@

stage/private.h: dev/private.h
	cp $? $@

stage/ami_private.h: ami/ami_private.h
	cp $? $@

stage/README: dev/dist/README
	cp $? $@

stage/VERSION.in: dev/dist/VERSION.in
	cp $? $@

stage/NEWS: dev/dist/NEWS
	cp $? $@

stage/AUTHORS: dev/dist/AUTHORS
	cp $? $@

stage/COPYING.LESSER: dev/dist/COPYING.LESSER
	cp $? $@

stage/ChangeLog: dev/dist/ChangeLog
	cp $? $@

doc/README: dev/doc_dist/README
	cp $? $@

doc/NEWS: dev/doc_dist/NEWS
	cp $? $@

doc/AUTHORS: dev/doc_dist/AUTHORS
	cp $? $@

doc/COPYING.LESSER: dev/doc_dist/COPYING.LESSER
	cp $? $@

doc/ChangeLog: dev/doc_dist/ChangeLog
	cp $? $@

doc/fdl-1.3.texi: dev/doc_dist/fdl-1.3.texi
	cp $? $@

doc/lgpl-3.0.texi: dev/doc_dist/lgpl-3.0.texi
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

install: dev_sources ami_sources code_sources stage/stamp-h1 doc/stamp-h1

dev_sources:
	cd dev && make

ami_sources:
	cd ami && make

codes_sources:
	cd codes && make

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

