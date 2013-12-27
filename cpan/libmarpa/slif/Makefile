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

# Code for the "Scanless interface" or SLIF, an upper
# layer for libmarpa.

CWEAVE = cweave -p
CTANGLE = ctangle -p

.PHONY: all

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

all: marpa_slif.pdf sources

sources: marpa_slif.c slif_private.h

license.c: ../public/license.c
	cp $? $@

do_not_edit.c: ../public/do_not_edit.c
	cp $? $@

copyright_page_license.w: ../dev/copyright_page_license.w
	cp $? $@

C_LANGUAGE_PREAMBLE = license.c do_not_edit.c
MARPA_SLIF_H_PIECES =  $(C_LANGUAGE_PREAMBLE) marpa_slif.h.p50
MARPA_SLIF_C_PIECES = $(C_LANGUAGE_PREAMBLE) marpa_slif.c.p50

marpa_slif.h.p50 marpa_slif.c.p50: copyright_page_license.w marpa_slif.w
	$(CTANGLE) marpa_slif.w

cwebmac.tex: ../dev/cwebmac.tex
	cp $? $@

marpa_slif.tex: cwebmac.tex copyright_page_license.w

marpa_slif.pdf: marpa_slif.tex

marpa_slif.c: $(MARPA_SLIF_C_PIECES)
	cat $(MARPA_SLIF_C_PIECES) > $@

w2private_h.pl: ../dev/w2private_h.pl
	cp $? $@

slif_private.h: marpa_slif.w w2private_h.pl
	perl w2private_h.pl slif_private.h < marpa_slif.w

marpa_slif.h.p5: internal.texi texi2code.pl
	cat internal.texi | perl texi2code.pl marpa_slif.h.p5

update_texi:
	emacs -batch internal.texi \
	    -f texinfo-every-node-update \
	    -f texinfo-all-menus-update \
	    -f save-buffer -kill
