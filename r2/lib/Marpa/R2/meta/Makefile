# Copyright 2012 Jeffrey Kegler
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

doit:
	-test -r thin-g3.pl && mv thin-g3.pl thin-g4.pl
	-test -r thin-g2.pl && mv thin-g2.pl thin-g3.pl
	-test -r thin-g1.pl && mv thin-g1.pl thin-g2.pl
	-mv thin.pl thin-g1.pl
	perl -I../../../ -I../../../../blib/arch bnf_to_aoh.pl < Stuifzand.bnf | \
	  perl aoh_to_thin.pl > thin.pl
