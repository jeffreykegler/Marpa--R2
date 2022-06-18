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

dummy:

test: synopsis comment prefix

synopsis:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl synopsis.pl --demo

comment:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl comment.pl --demo

prefix:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl prefix.pl --demo | \
	    diff - prefix.out

