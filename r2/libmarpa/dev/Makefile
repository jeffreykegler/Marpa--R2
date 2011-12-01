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

all: marpa.pdf marpa.c marpa.h.in proto.h.in

marpa.c marpa.h.in: copyright_page_license.w marpa.w

proto.h.in: api.texi
	perl texi2proto.pl < $? > $@

marpa.pdf: marpa.tex cwebmac.tex

install: ../dist/marpa.c ../dist/marpa.h.in ../dist/proto.h.in

../dist/marpa.c: marpa.c
	cp $? $@

../dist/proto.h.in: proto.h.in
	cp $? $@

../dist/marpa.h.in: marpa.h.in
	cp $? $@

