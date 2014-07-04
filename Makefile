# Copyright 2014 Jeffrey Kegler
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

.PHONY: dummy basic_test rebuild single_test full_test etc_make install cpan_dist_files releng

dummy: 

releng: install full_test
	cd cpan && ./Build distcheck
	cd cpan && ./Build dist
	git status

basic_test:
	(cd cpan && ./Build test) 2>&1 | tee basic_test.out

rebuild: etc_make
	(cd cpan; \
	    ./Build; \
	    ./Build test; \
	) 2>&1 | tee rebuild.out

single_test: etc_make
	(cd cpan; \
	    ./Build; \
	    ./Build test --test_files $(TEST); \
	) 2>&1 | tee single_test.out

full_test: etc_make
	(cd cpan; \
	    ./Build realclean; \
	    perl Build.PL; \
	    ./Build; \
	    ./Build distmeta; \
	    ./Build test; \
	    ./Build disttest; \
	    MARPA_USE_PERL_AUTOCONF=1 ./Build disttest; \
	) 2>&1 | tee full_test.out

install:
	(cd cpan/meta && make all)
	(cd cpan/xs && make)
	(cd cpan && perl Build.PL)
	(cd cpan && ./Build distmeta)
	(cd cpan && ./Build code)

