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

all: proof.pdf ah2002_notes.pdf ah_to_leo.pdf recce.pdf

recce.pdf: recce.ltx
	pdflatex $?

proof.pdf: proof.ltx
	pdflatex $?
	# lyx --export pdf proof.lyx

ah2002_notes.pdf: ah2002_notes.ltx
	pdflatex $?
	# lyx --export pdf ah2002_notes.lyx

ah_to_leo.pdf: ah_to_leo.ltx
	pdflatex $?
	# lyx --export pdf ah_to_leo.lyx
