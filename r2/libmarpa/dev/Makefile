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

MARPA_PDF_SOURCES = cwebmac.tex marpa.w copyright_page_license.w

CONFIGURE_SOURCES = \
    Makefile.am \
    configure.ac

SOURCES = $(CONFIGURE_SOURCES) \
    VERSION.in \
    api.texi \
    codes.c \
    codes.h \
    marpa.c \
    marpa.h \
    marpa_api.h \
    marpa_obs.c \
    marpa_obs.h \
    private.h

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

../marpa.tar.gz: $(SOURCES)
	cp $(SOURCES) ../stage_dist
	test -d ../stage_dist/m4 || mkdir ../stage_dist/m4
	cd ../stage_dist \
	    && autoreconf -ivf \
	    && ./configure \
	    && make dist
	version=`cat ../stage_dist/VERSION`; \
	    cd ../stage_dist \
	    && mv marpa-$$version.tar.gz ../marpa.tar.gz

../VERSION: ../marpa.tar.gz
	cp ../stage_dist/VERSION ../VERSION

../dist/configure: ../marpa.tar.gz  ../VERSION
	rm -rf ../dist
	cd .. && tar -xzf marpa.tar.gz
	version=`cat ../VERSION`; \
	    cd .. \
	    && mv marpa-$$version dist
	    && cd ../dist
	    && chmod u+w configure stamp-*

../docs/api.pdf: ../marpa.tar.gz ../VERSION
	rm -rf ../docs
	cd .. && tar -xzf marpa.tar.gz
	version=`cat ../VERSION`; \
	    cd .. \
	    && mv marpa-$$version docs \
	    && cd docs \
	    && ../stage_dist/configure \
	    && ./configure --silent \
	    && make pdf

install: ../dist/configure

docs: marpa.pdf ../docs/api.pdf
