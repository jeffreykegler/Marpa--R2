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

.PHONY: all dummy

dummy:

all: Definition.pm

Definition.pm: Compile.pm Write.pm Configuration.pm Core.pm
	perl -I$(HOME)/projects/marpa/r2/r2/html/lib \
	  -MMarpa::R2::HTML::Config::Compile \
	  -MMarpa::R2::HTML::Config::Write \
	  -E 'say $${Marpa::R2::HTML::Config::Write::file_string()}' \
	  > $@
