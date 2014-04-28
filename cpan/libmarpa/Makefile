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

.PHONY: install docs sources stage_copy

dummy:
	@echo install is the main target

stage/configure: stage_copy
	test -d stage || mkdir stage
	test -d stage/m4 || mkdir stage/m4
	cd stage && autoreconf -iv

stage/Makefile: stage/configure
	cd stage && ./configure

doc/api.pdf: stage_copy doc/Makefile doc/api.texi
	cd doc && make pdf

doc/api.html/index.html: stage_copy doc/Makefile doc/api.texi
	cd doc && make html

doc/internal.pdf: stage_copy doc/Makefile doc/internal.texi
	cd doc && make pdf

doc/internal.html/index.html: stage_copy doc/Makefile doc/internal.texi
	cd doc && make html

stage_copy:
	perl bin/to_stage.pl

install: sources stage/stamp-h1 doc/stamp-h1

MAKEABLE_DIR = ami dev slif tavl public
CLEANABLE_DIR = $(MAKEABLE_DIR)

sources:
	for d in $(MAKEABLE_DIR); do (cd $$d; make); done

clean:
	for d in $(CLEANABLE_DIR); do (cd $$d; make clean); done

stage/stamp-h1: stage/Makefile stage_copy
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

