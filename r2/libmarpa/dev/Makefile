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

all: marpa.pdf marpa.c marpa.h.in api.h.in error.h.in error.c.in docs

docs: api.pdf api/index.html

api/index.html: api.texi
	makeinfo --html api.texi

api.pdf: api.texi
	texi2dvi --pdf api.texi

marpa.c marpa.h.in: copyright_page_license.w marpa.w

error.c.in error.h.in api.h.in: api.texi texi2code.pl
	perl texi2code.pl api.h.in error.h.in error.c.in < api.texi

marpa.pdf: marpa.tex cwebmac.tex

../build_dist/marpa.tar.gz: marpa.c \
    marpa.h.in api.h.in error.c.in error.h.in \
    ../build_dist/Makefile
	cp marpa.c api.h.in error.h.in error.c.in marpa.h.in ../stage_dist
	cd ../build_dist && make dist
	version=`cat ../build_dist/VERSION`; \
	    cd ../build_dist \
	    && mv marpa-$$version.tar.gz marpa.tar.gz

../build_dist/Makefile: ../stage_dist/configure ../stage_dist/Makefile.in
	cd ../build_dist && ../stage_dist/configure

../VERSION: ../build_dist/VERSION ../build_dist/marpa.tar.gz
	cp ../build_dist/VERSION ../VERSION
	version=`cat ../VERSION`; \
	    cd ..  \
	    && tar -xvzf build_dist/marpa.tar.gz \
	    && rm -rf dist \
	    && mv marpa-$$version dist

install: ../VERSION
