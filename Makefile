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

.PHONY: libs dummy full pp_html_test xs_html_test pp_etc_make xs_etc_make \
    pplib xslib libs

dummy: 

xs_basic_test:
	(cd xs; ./Build test)

xst: xs_basic_test xs_html_test

libs: pplib xslib

pplib:
	(cd pp; ./Build install --install_base ../dpplib)

xslib:
	(cd xs; ./Build install --install_base ../dxslib)

html_blib:
	(cd html; ./Build code)

pp_html_test: html_blib pplib
	(cd html; \
	PERL5LIB=$(CURDIR)/noxs/lib:$(CURDIR)/dpplib/lib/perl5:$$PERL5LIB prove -Ilib t )

xs_html_test: html_blib xslib
	(cd html; \
	PERL5LIB=$(CURDIR)/dxslib/lib/perl5:$$PERL5LIB prove -Ilib t )


pp_etc_make:
	(cd pp/etc; make)

xs_etc_make:
	(cd xs/etc; make)

pp_full_test: pplib pp_etc_make pp_html_test

xs_full_test: xslib xs_etc_make xs_html_test

full_test: pp_full_test  xs_full_test

html_full_test: pp_html_test xs_html_test
	
