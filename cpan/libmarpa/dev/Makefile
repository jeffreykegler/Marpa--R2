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

CWEAVE = cweave -p
CTANGLE = ctangle -p

.PHONY: docs

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
	pdftex -interaction=batchmode -halt-on-error $* || cat $*.log

all: legacy.pdf marpa.pdf sources

sources: marpa.c marpa.h.p50 marpa.h.p80 marpa.h.p80

C_LANGUAGE_PREAMBLE = ../shared/license.c ../shared/do_not_edit.c
MARPA_C_PIECES = $(C_LANGUAGE_PREAMBLE) marpa.c.p10 marpa.c.p40 marpa.c.p50

marpa.c: $(MARPA_C_PIECES)
	cat $(MARPA_C_PIECES) > $@

marpa.h.p50 marpa.c.p10 marpa.c.p50: ../shared/copyright_page_license.w marpa.w
	$(CTANGLE) marpa.w

marpa.h.p80: api.texi internal.texi
	cat api.texi internal.texi | \
	  perl ../bin/texi2proto.pl > marpa.h.p80

CPPWRAP = perl ../bin/cppwrap.pl

marpa.c.p40: marpa.w
	perl w2private_h.pl < $? | $(CPPWRAP) $@ > $@

cwebmac.tex: ../shared/cwebmac.tex
	cp $? $@

marpa.pdf: marpa.tex cwebmac.tex

legacy.pdf: legacy.tex cwebmac.tex

docs: marpa.pdf legacy.pdf

update_texi:
	emacs -batch api.texi \
	    -eval '(texinfo-master-menu 1)' \
	    -f save-buffer -kill
	emacs -batch internal.texi \
	    -eval '(texinfo-master-menu 1)' \
	    -f save-buffer -kill

CLEAN_FILES = marpa.c marpa.c.p10 marpa.c.p40 marpa.c.p50 \
  marpa.h.p50 marpa.h.p80 \
  marpa.idx marpa.log marpa.pdf marpa.scn marpa.tex marpa.toc \
  legacy.idx legacy.log legacy.pdf legacy.scn legacy.tex legacy.toc

clean:
	rm -f $(CLEAN_FILES)
