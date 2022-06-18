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

for context in inline block
do for content in empty pcdata inline mixed block
do
cat <<EO_SH > acme-$context-$content.sh
cp default.cfg test.cfg
echo "ELE_acme is a FLO_$content included in GRP_$context" >> test.cfg
echo '<acme>-during-<span>-more inline stuff-<p>-new block-' |
  marpa_r2_html_fmt --no-added-tag --compile test.cfg
EO_SH
done
done
