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

(cd libmarpa; make install)
version=`libmarpa/stage/configure --version | sed -ne '1s/^libmarpa configure *//p'`
tar_file=libmarpa/stage/libmarpa-$version.tar.gz
if test -d libmarpa_dist && test libmarpa_dist/stamp-h1 -nt $tar_file;
then : ;
else
  rm -rf libmarpa_dist
  mkdir libmarpa_dist.$$
  (cd libmarpa_dist.$$; tar -xzf ../$tar_file)
  mv libmarpa_dist.$$/libmarpa-$version libmarpa_dist
  date > libmarpa_dist/stamp-h1
  rmdir libmarpa_dist.$$
fi

# same thing for the doc directory
tar_file=libmarpa/doc/libmarpa-doc-$version.tar.gz
if test -d libmarpa_doc_dist && test libmarpa_doc_dist/stamp-h1 -nt $tar_file;
then exit 0;
fi
rm -rf libmarpa_doc_dist
mkdir libmarpa_doc_dist.$$
(cd libmarpa_doc_dist.$$; tar -xzf ../$tar_file)
mv libmarpa_doc_dist.$$/libmarpa-doc-$version libmarpa_doc_dist
date > libmarpa_doc_dist/stamp-h1
rmdir libmarpa_doc_dist.$$
