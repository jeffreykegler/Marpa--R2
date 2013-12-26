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

.PHONY: all

# This directory does the final build of the public headers
# Because this process collects the data from the various #define's
# It also build marpa_codes.c, which contains data for reverse
# lookup of events, errors, etc., by number.

CPPWRAP = perl ../bin/cppwrap.pl
C_LANGUAGE_PREAMBLE = license.c do_not_edit.c
MARPA_H_PIECES = $(C_LANGUAGE_PREAMBLE) marpa.h.p10 marpa.h-err marpa.h.p50 marpa.h.p80 marpa.h.p90
MARPA_SLIF_H_PIECES = $(C_LANGUAGE_PREAMBLE) marpa_slif.h.p20

all: marpa_slif.h marpa.h

marpa.h.p50: ../dev/marpa.h.p50
	cp $? $@

marpa.h.p80: ../dev/marpa.h.p80
	$(CPPWRAP) $@ < $? > $@

marpa.h: $(MARPA_H_PIECES)
	cat $(MARPA_H_PIECES) > marpa.h

marpa_slif.h: $(MARPA_SLIF_H_PIECES)
	cat $(MARPA_SLIF_H_PIECES) > marpa_slif.h

UNWRAPPED_CODE_PIECES = marpa-c.err marpa.c-event marpa.c-step

marpa_codes.c: $(C_LANGUAGE_PREAMBLE) $(UNWRAPPED_CODE_PIECES)
	(cat $(C_LANGUAGE_PREAMBLE) ; \
	   for f in $(UNWRAPPED_CODE_PIECES); \
	   do $(CPPWRAP) $$f > $$f; \
	   done \
	) > $@

marpa.c-err marpa.h-err: ../dev/api.texi
	cat ../dev/api.texi | perl texi2err.pl marpa.c-err | $(CPPWRAP) $@ > $@

