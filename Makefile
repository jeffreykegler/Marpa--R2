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

.PHONY: libs dummy

dummy: 

libs:
	(cd pp; ./Build install --install_base ../dxslib)
	(cd pp; ./Build install --install_base ../dpplib)
	(cd xs; ./Build install --install_base ../dxslib)

pp_html_test:
	(cd html; \
	PERL5LIB=$$HOME/projects/marpa/all/dpplib/lib/perl5:$$PERL5LIB prove -Ilib --verbose xt; \
	PERL5LIB=$$HOME/projects/marpa/all/dpplib/lib/perl5:$$PERL5LIB prove -Ilib t )

xs_html_test:
	(cd html; \
	PERL5LIB=$$HOME/projects/marpa/all/dxslib/lib/perl5:$$PERL5LIB prove -Ilib --verbose xt; \
	PERL5LIB=$$HOME/projects/marpa/all/dxslib/lib/perl5:$$PERL5LIB prove -Ilib t )

pp_etc_make:
	(cd pp/etc;  make)

xs_etc_make: libs
	(cd xs/etc;  \
	PERL5LIB=$$HOME/projects/marpa/all/dxslib/lib/perl5:$$PERL5LIB make)
