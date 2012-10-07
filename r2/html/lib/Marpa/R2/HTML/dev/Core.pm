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

use 5.010;
use strict;
use warnings;
use autodie;
use Data::Dumper;

package HTML_Core;

use English qw( -no_match_vars );

our $CORE_BNF = <<'END_OF_CORE_BNF';
# Non-element tokens
comment ::= C
pi ::= PI
decl ::= D
pcdata ::= PCDATA
cdata ::= CDATA
whitespace ::= WHITESPACE
cruft ::= CRUFT

# FLO_SGML and ITEM_SGML defined by BNF rules,
# because they must explicity include cruft
FLO_SGML ::= ITEM_SGML*
ITEM_SGML ::= comment
ITEM_SGML ::= pi
ITEM_SGML ::= decl
ITEM_SGML ::= whitespace
ITEM_SGML ::= cruft

# For element x,
# ELE_x is complete element
# S_x is start tag
# E_x is end tag
#   The contents of many elements consists of zero or more items

# Top-level structure
document ::= prolog ELE_html trailer EOF
prolog ::= FLO_SGML
trailer ::= FLO_SGML
ELE_html ::= S_html EC_html E_html
EC_html ::= FLO_SGML ELE_head FLO_SGML ELE_body FLO_SGML
ELE_head is FLO_head
ELE_body is FLO_block

# FLO_empty, FLO_cdata and ITEM_cdata defined by "hand" (BNF)
# because they do NOT allow SGML items as part of
# their flow
FLO_empty ::=
FLO_cdata ::= ITEM_cdata*
ITEM_cdata ::= cdata
ITEM_cdata ::= CRUFT

FLO_mixed contains GRP_anywhere GRP_block GRP_inline
FLO_mixed contains cdata pcdata
FLO_block contains GRP_block GRP_anywhere
FLO_head contains GRP_head GRP_anywhere
FLO_inline contains pcdata cdata GRP_inline GRP_anywhere
FLO_pcdata contains cdata pcdata

END_OF_CORE_BNF

1;
