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

all: marpa.pdf sources

sources: marpa.c marpa.h.p50 marpa.h.p80 marpa_int.h marpa_util.h marpa_api.h codes.h codes.c private.h

marpa.h.p50 marpa.c: copyright_page_license.w marpa.w
	$(CTANGLE) marpa.w

marpa.h.p80: api.texi internal.texi texi2proto.pl
	cat api.texi internal.texi | \
	  perl texi2proto.pl marpa_api.h

private.h: marpa.w w2private_h.pl
	perl w2private_h.pl private.h < marpa.w

marpa.pdf: marpa.tex cwebmac.tex

docs: marpa.pdf

update_texi:
	emacs -batch api.texi \
	    -f texinfo-every-node-update \
	    -f texinfo-all-menus-update \
	    -f save-buffer -kill
	emacs -batch internal.texi \
	    -f texinfo-every-node-update \
	    -f texinfo-all-menus-update \
	    -f save-buffer -kill
