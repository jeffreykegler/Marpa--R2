# Copyright 2012 Jeffrey Kegler
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

# uncomment the second line if you use pdftex to bypass .dvi files
#PDFTEX = dvipdfm
PDFTEX = pdftex

CWEAVE = cweave
CTANGLE = ctangle

SOURCES = cwebmac.tex marpa.w copyright_page_license.w

.SUFFIXES: .dvi .tex .w .pdf

.w.tex:
	$(CWEAVE) $*

.tex.dvi:	
	tex $<

.w.dvi:
	make $*.tex
	make $*.dvi

.w.c:
	$(CTANGLE) $*

.w.o:
	make $*.c
	make $*.o

.w.pdf:
	make $*.tex
	case "$(PDFTEX)" in \
	 dvipdfm ) tex "\let\pdf+ \input $*"; dvipdfm $* ;; \
	 pdftex ) pdftex $* ;; \
	esac

all: marpa.pdf sources

sources: marpa.c marpa.h marpa_api.h codes.h codes.c

marpa.c marpa.h: copyright_page_license.w marpa.w

codes.c codes.h marpa_api.h: api.texi texi2code.pl
	perl texi2code.pl marpa_api.h codes.h codes.c < api.texi

private.h: marpa.w w2private_h.pl
	perl w2private_h.pl private.h < marpa.w

marpa.pdf: marpa.tex cwebmac.tex

../stage_dist/configure:  ../stage_dist/configure.ac ../stage_dist/Makefile.am
	test -d ../stage_dist/m4 || mkdir ../stage_dist/m4
	cd ../stage_dist && autoreconf -ivf

../build_dist/stamp-h1: $(STAGE_FILES) ../stage_dist/configure
	test -d ../build_dist && rm -rf ../build_dist
	mkdir ../build_dist
	cd ../build_dist && ../stage_dist/configure

../build_dist/marpa.tar.gz: ../build_dist/VERSION $(STAGE_FILES) ../build_dist/stamp-h1
	cd ../build_dist && make dist
	version=`cat ../build_dist/VERSION`; \
	    cd ../build_dist \
	    && mv marpa-$$version.tar.gz marpa.tar.gz

../VERSION: ../build_dist/marpa.tar.gz
	cp ../build_dist/VERSION ../VERSION
	version=`cat ../VERSION`; \
	    cd ..  \
	    && tar -xzf build_dist/marpa.tar.gz \
	    && rm -rf dist \
	    && mv marpa-$$version dist

STAGE_FILES = \
    ../stage_dist/Makefile.am \
    ../stage_dist/VERSION.in \
    ../stage_dist/api.texi \
    ../stage_dist/codes.c \
    ../stage_dist/codes.h \
    ../stage_dist/configure.ac \
    ../stage_dist/marpa.c \
    ../stage_dist/marpa.h \
    ../stage_dist/marpa_api.h \
    ../stage_dist/marpa_obs.c \
    ../stage_dist/marpa_obs.h \
    ../stage_dist/private.h

../stage_dist/api.texi: api.texi
	cp $? $@

../stage_dist/marpa.c: marpa.c
	cp $? $@

../stage_dist/marpa.h: marpa.h
	cp $? $@

../stage_dist/marpa_api.h: marpa_api.h
	cp $? $@

../stage_dist/codes.c: codes.c
	cp $? $@

../stage_dist/codes.h: codes.h
	cp $? $@

../stage_dist/private.h: private.h
	cp $? $@

../stage_dist/configure.ac: configure.ac
	cp $? $@

../stage_dist/Makefile.am: Makefile.am
	cp $? $@

../stage_dist/VERSION.in: VERSION.in
	cp $? $@

../stage_dist/marpa_obs.c: marpa_obs.c
	cp $? $@

../stage_dist/marpa_obs.h: marpa_obs.h
	cp $? $@

install: sources ../VERSION

../docs/stamp-h1: ../stage_dist/configure
	test -d ../docs && rm -rf ../docs
	mkdir ../docs
	cd ../docs && ../stage_dist/configure

docs: ../build_dist/marpa.tar.gz ../build_dist/VERSION
	rm -rf ../docs
	cd .. && tar -xzf build_dist/marpa.tar.gz
	version=`cat ../build_dist/VERSION`; \
	    cd .. \
	    && mv marpa-$$version docs
	cd ../docs && ./configure --silent && make pdf
