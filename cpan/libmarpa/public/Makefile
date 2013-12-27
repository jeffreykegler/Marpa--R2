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
C_LANGUAGE_PREAMBLE = ../shared/license.c ../shared/do_not_edit.c
MARPA_H_PIECES = $(C_LANGUAGE_PREAMBLE) \
  marpa.h.p10 marpa.h-err marpa.h-event marpa.h-step \
  marpa.h.p50 marpa.h.p80 marpa.h.p90

all: marpa_slif.h marpa.h marpa_codes.c

marpa.h.p50: ../dev/marpa.h.p50
	cp $? $@

marpa.h.p80: ../dev/marpa.h.p80
	$(CPPWRAP) $@ < $? > $@

marpa.h: $(MARPA_H_PIECES)
	cat $(MARPA_H_PIECES) > marpa.h

MARPA_SLIF_H_PIECES = $(C_LANGUAGE_PREAMBLE) marpa_slif.h.p50

marpa_slif.h.p50: ../slif/marpa_slif.h.p50
	cp $? $@

marpa_slif.h: $(MARPA_SLIF_H_PIECES)
	cat $(MARPA_SLIF_H_PIECES) > $@

# The pieces with the code data,
# not yet wrapped with the pre-processor line directive
MARPA_CODES_C_UNWRAPPED = marpa_codes.c.p10 marpa.c-err marpa.c-event marpa.c-step

MARPA_CODES_C_PIECES = $(C_LANGUAGE_PREAMBLE) $(MARPA_CODES_C_UNWRAPPED)

marpa_codes.c: $(MARPA_CODES_C_PIECES)
	(cat $(C_LANGUAGE_PREAMBLE) ; \
		for f in $(MARPA_CODES_C_UNWRAPPED); \
		do $(CPPWRAP) $$f < $$f; \
		done) > $@


marpa.c-err marpa.h-err: ../dev/api.texi
	cat ../dev/api.texi | \
	  perl texi2err.pl marpa.c-err | \
	  $(CPPWRAP) marpa.h-err > marpa.h-err

marpa.c-event marpa.h-event: ../dev/api.texi
	cat ../dev/api.texi | \
	  perl texi2event.pl marpa.c-event | \
	  $(CPPWRAP) marpa.h-event > marpa.h-event

marpa.c-step marpa.h-step: ../dev/api.texi
	cat ../dev/api.texi | \
	  perl texi2step.pl marpa.c-step | \
	  $(CPPWRAP) marpa.h-step > marpa.h-step

