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

.PHONY: dummy basic_test full_test etc_make install

dummy: 

basic_test:
	(cd r2 && ./Build test)

full_test: etc_make
	(cd r2; \
	    ./Build realclean; \
	    perl Build.PL; \
	    ./Build; \
	    ./Build distmeta; \
	    ./Build test; \
	    ./Build disttest; \
	) 2>&1 | tee full_test.out

install:
	(cd r2/libmarpa/dev; make install)
	(cd r2 && perl Build.PL)
	(cd r2 && ./Build --Dev code)

fullinstall: install
	-mkdir r2/libmarpa/test/dev/m4
	(cd r2/libmarpa/test/dev && autoreconf -ivf)
	-mkdir r2/libmarpa/test/work
	(cd r2/libmarpa/test/work && sh ../dev/configure)
	(cd r2/libmarpa/test/work && make)
