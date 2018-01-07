# Copyright 2018 Jeffrey Kegler
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
	-test -r metag-g3.pl && mv metag-g3.pl metag-g4.pl
	-test -r metag-g2.pl && mv metag-g2.pl metag-g3.pl
	-test -r metag-g1.pl && mv metag-g1.pl metag-g2.pl
	-mv metag.pl metag-g1.pl
	perl sl_to_hash.pl < metag.bnf > metag.pl

bak:
	for f in metag*.pl; do cp $$f $$f.bak; done

diff:
	diff metag.pl metag-g1.pl || true

