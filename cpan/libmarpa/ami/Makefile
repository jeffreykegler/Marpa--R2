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

all: marpa_ami.pdf sources

sources: marpa_ami.c marpa_ami.h

copyright_page_license.w: ../dev/copyright_page_license.w
	cp $? $@

C_LANGUAGE_PREAMBLE = ../shared/license.c ../shared/do_not_edit.c
MARPA_AMI_H_PIECES =  $(C_LANGUAGE_PREAMBLE) marpa_ami.h.p10 marpa_ami.h.p50 marpa_ami.h.p90
MARPA_AMI_C_PIECES = $(C_LANGUAGE_PREAMBLE) marpa_ami.c.p10 marpa_ami.c.p40 marpa_ami.c.p50

marpa_ami.h.p10 marpa_ami.h.p90 marpa_ami.c.p10: copyright_page_license.w marpa_ami.w
	$(CTANGLE) marpa_ami.w

cwebmac.tex: ../dev/cwebmac.tex
	cp $? $@

marpa_ami.tex: cwebmac.tex copyright_page_license.w

marpa_ami.pdf: marpa_ami.tex

marpa_ami.h: $(MARPA_AMI_H_PIECES)
	cat $(MARPA_AMI_H_PIECES) > $@

marpa_ami.c: $(MARPA_AMI_C_PIECES)
	cat $(MARPA_AMI_C_PIECES) > $@

CPPWRAP = perl ../bin/cppwrap.pl

marpa_ami.c.p40: marpa_ami.w
	perl w2private_h.pl < $? | $(CPPWRAP) $@ > $@

marpa_ami.h.p50: internal.texi texi2code.pl
	cat internal.texi | perl texi2code.pl marpa_ami.h.p50

update_texi:
	emacs -batch internal.texi \
	    -f texinfo-every-node-update \
	    -f texinfo-all-menus-update \
	    -f save-buffer -kill
