# Copyright 2022 Jeffrey Kegler
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

.PHONY: dummy all html_meta

dummy:
	@echo '!!!' The main target is '"all"' '!!!'

all: ../lib/Marpa/R2/Internal.pm html_meta

../lib/Marpa/R2/Internal.pm: make_internal_pm.pl
	perl make_internal_pm.pl > $@

html_meta:
	(cd ../html/meta; make all)
