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

CONFIGURE_FILES = \
    ../stage/Makefile.am \
    ../stage/configure.ac

STAGE_FILES = \
    $(CONFIGURE_FILES) \
    ../stage/api.texi \
    ../stage/codes.c \
    ../stage/codes.h \
    ../stage/marpa.c \
    ../stage/marpa.h \
    ../stage/marpa_api.h \
    ../stage/marpa_obs.c \
    ../stage/marpa_obs.h \
    ../stage/private.h

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

marpa.h marpa.c: copyright_page_license.w marpa.w
	$(CTANGLE) marpa.w

codes.c codes.h marpa_api.h: api.texi texi2code.pl
	perl texi2code.pl marpa_api.h codes.h codes.c < api.texi

private.h: marpa.w w2private_h.pl
	perl w2private_h.pl private.h < marpa.w

marpa.pdf: marpa.tex cwebmac.tex

../stage/configure.ac: dist/configure.ac
	cp $? $@

../stage/Makefile.am: dist/Makefile.am
	cp $? $@

../stage/api.texi: api.texi
	cp $? $@

../stage/codes.c: codes.c
	cp $? $@

../stage/codes.h: codes.h
	cp $? $@

../stage/marpa.c: marpa.c
	cp $? $@

../stage/marpa.h: marpa.h
	cp $? $@

../stage/marpa_api.h: marpa_api.h
	cp $? $@

../stage/marpa_obs.c: marpa_obs.c
	cp $? $@

../stage/marpa_obs.h: marpa_obs.h
	cp $? $@

../stage/private.h: private.h
	cp $? $@

../stage/configure: $(CONFIGURE_FILES)
	test -d ../stage/m4 || mkdir ../stage/m4
	cd ../stage && autoreconf -iv

../stage/Makefile: ../stage/configure
	cd ../stage && ../stage/configure

../stage/api.pdf: ../stage/Makefile ../stage/api.texi
	cd ../stage && make pdf

install: $(STAGE_FILES) ../stage/configure

docs: marpa.pdf ../stage/api.pdf
