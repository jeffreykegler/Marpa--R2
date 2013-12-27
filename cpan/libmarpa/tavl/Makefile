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

CFLAGS = -g -W -Wall -ansi -pedantic # enable many GCC warnings
LDFLAGS = -g

testers = tavl-test
targets = $(testers)
programs = $(targets)

sources =					tavl.c tavl.h tavl-test.c			

all: programs
programs: $(programs)
sources: $(sources)

tavl-test: tavl.o tavl-test.o test.o

tavl-test.c: tavl.h test.h

test.c: test.h
bsts.c: test.h

pfaff_version = 2.0.3

check: $(testers)
	@for d in $(testers); do		\
		echo "Checking $$d.";		\
		./check-table ./$$d || exit 1;	\
		echo;				\
	done

clean:
	rm -f $(programs)
	rm -f *.o *.tmp
	rm -f a.out foo*

.PHONY: all
.PHONY: docs 
.PHONY: programs sources
.PHONY: clean
