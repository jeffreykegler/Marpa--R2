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

package Marpa::R2::HTML::Internal::Core;

use 5.010;
use strict;
use warnings;
use Data::Dumper;

use English qw( -no_match_vars );

our $CORE_BNF = <<'END_OF_CORE_BNF';
# The tokens are not used directly
# because, in order to have handlers
# deal with them individually, I need
# a rule with which to associate the
# handler.
comment ::= C
pi ::= PI
decl ::= D
pcdata ::= PCDATA
cdata ::= CDATA
whitespace ::= WHITESPACE
cruft ::= CRUFT

FLO_SGML ::= GRP_SGML*
GRP_SGML ::= comment
GRP_SGML ::= pi
GRP_SGML ::= decl
GRP_SGML ::= whitespace
GRP_SGML ::= cruft

# For element x,
# ELE_x is complete element
# S_x is start tag
# E_x is end tag
#   The contents of many elements consists of zero or more items

# Top-level structure
document ::= prolog ELE_html trailer EOF
prolog ::= FLO_SGML
trailer ::= FLO_SGML
ELE_html ::= S_html Contents_html E_html
Contents_html ::= FLO_SGML ELE_head FLO_SGML ELE_body FLO_SGML

# FLO_empty and FLO_cdata
# do NOT allow SGML items as part of
# their flow
FLO_empty ::=

# In FLO_cdata, disallow all SGML components,
# but include cruft.
FLO_cdata ::= GRP_cdata*
GRP_cdata ::= CRUFT
GRP_cdata ::= cdata

FLO_mixed ::= GRP_mixed*
GRP_mixed ::= GRP_block
GRP_mixed ::= GRP_inline

FLO_block ::= GRP_block*
GRP_block ::= GRP_SGML
GRP_block ::= GRP_anywhere

FLO_head ::= GRP_head*
GRP_head ::= GRP_SGML
GRP_head ::= GRP_anywhere

FLO_inline ::= GRP_inline*
GRP_inline ::= GRP_SGML
GRP_inline ::= pcdata
GRP_inline ::= cdata
GRP_inline ::= GRP_anywhere

FLO_pcdata ::= GRP_pcdata*
GRP_pcdata ::= GRP_SGML
GRP_pcdata ::= pcdata
GRP_pcdata ::= cdata

END_OF_CORE_BNF

1;
