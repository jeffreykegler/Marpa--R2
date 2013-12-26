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

C_LANGUAGE_PREAMBLE = license.c do_not_edit.c
MARPA_AMI_H_PIECES =  $(C_LANGUAGE_PREAMBLE) marpa.h.p10 marpa.h.p50 marpa.h.p90

all: marpa_ami.pdf sources

sources: marpa_slif.h marpa.h-err

marpa.h: marpa.h-err

marpa.h-err: ../dev/api.texi
	cat ../dev/api.texi | perl texi2err.pl > marpa.h-err

