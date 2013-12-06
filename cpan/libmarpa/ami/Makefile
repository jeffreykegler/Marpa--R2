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

# uncomment the second line if you use pdftex to bypass .dvi files
#PDFTEX = dvipdfm
PDFTEX = pdftex

CWEAVE = cweave
CTANGLE = ctangle

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
	case "$(PDFTEX)" in \
	 dvipdfm ) tex "\let\pdf+ \input $*"; dvipdfm $* ;; \
	 pdftex ) pdftex $* ;; \
	esac

all: marpa_ami.pdf sources

sources: marpa_ami.c marpa_ami.h ami_private.h

copyright_page_license.w: ../dev/copyright_page_license.w
	cp $? $@

MARPA_AMI_H_PIECES = marpa_ami.h.p1 marpa_ami.h.p5 marpa_ami.h.p9
MARPA_AMI_C_PIECES = marpa_ami.c.p1 
C_LANGUAGE_PREAMBLE = license.c do_not_edit.c

$(MARPA_AMI_H_PIECES) $(MARPA_AMI_C_PIECES): copyright_page_license.w marpa_ami.w
	$(CTANGLE) marpa_ami.w

cwebmac.tex: ../dev/cwebmac.tex
	cp $? $@

marpa_ami.tex: cwebmac.tex copyright_page_license.w

marpa_ami.pdf: marpa_ami.tex

marpa_ami.h: $(C_LANGUAGE_PREAMBLE) $(MARPA_AMI_H_PIECES)
	cat $(C_LANGUAGE_PREAMBLE) $(MARPA_AMI_H_PIECES) > $@

marpa_ami.c: $(C_LANGUAGE_PREAMBLE) $(MARPA_AMI_C_PIECES)
	cat $(C_LANGUAGE_PREAMBLE) $(MARPA_AMI_C_PIECES) > $@

w2private_h.pl: ../dev/w2private_h.pl
	cp $? $@

ami_private.h: marpa_ami.w w2private_h.pl
	perl w2private_h.pl ami_private.h < marpa_ami.w

marpa_ami.h.p5: internal.texi texi2code.pl
	cat internal.texi | perl texi2code.pl marpa_ami.h.p5

update_texi:
	emacs -batch internal.texi \
	    -f texinfo-every-node-update \
	    -f texinfo-all-menus-update \
	    -f save-buffer -kill
