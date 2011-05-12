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

.PHONY: all all_tests critic

all: all_tests

all_tests:
	-(cd ..; prove author.t/*.t ) 2>&1 | tee all.errs

critic:
	-(cd ..; prove author.t/critic.t) 2>&1 | tee critic.errs

pod:
	-(cd ..; prove author.t/pod.t)
