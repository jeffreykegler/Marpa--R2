# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

.PHONY: dummy basic_test full_test etc_make install

dummy: 

basic_test:
	(cd r2 && ./Build test)

etc_make:
	(cd r2/etc && make)

full_test: etc_make

install:
	(cd r2/libmarpa/dev && make)
	(cd r2/libmarpa/dev && make install)
	-mkdir r2/libmarpa/dist/m4
	(cd r2/libmarpa/dist && autoreconf -ivf)
	-mkdir r2/libmarpa/test/dev/m4
	(cd r2/libmarpa/test/dev && autoreconf -ivf)
	(cd r2 && perl Build.PL)
	(cd r2 && ./Build code)
	-mkdir r2/libmarpa/test/work
	(cd r2/libmarpa/test/work && sh ../dev/configure)
	(cd r2/libmarpa/test/work && make)
