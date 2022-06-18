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

#!perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
BEGIN { require './OP4.pm' }

my $OP_rules = Marpa::R2::Demo::OP4::parse_rules( <<'END_OF_RULES');
    <top> ::= <first rule> <more rules> :action<do_top>
    <first rule> ::= <short rule> :action<do_array>
    <more rules> ::= :action<do_empty_array>
    <short rule> ::= <rhs> :action<do_short_rule>
    <rhs> ::= <concatenation> :action<do_arg0>
    <concatenation> ::=
    <concatenation> ::= <concatenation> <opt ws> <quantified atom> :action<do_concatenation>
    <opt ws> ::= :action<do_undef>
    <opt ws> ::= <opt ws> <ws char> :action<do_undef>
    <quantified atom> ::= <atom> <opt ws> <quantifier> :action<do_quantification>
    <quantified atom> ::= <atom> :action<do_arg0>
    <atom> ::= <quoted literal> :action<do_arg0>
    <quoted literal> ::= <single quote> <single quoted char seq> <single quote>
      :action<do_arg1>
    <single quoted char seq> ::= <single quoted char>*
    <atom> ::= <self> :action<do_array>
    <self> ::= '<~~>' :action<do_self>
    <quantifier> ::= '*'
END_OF_RULES

say <<'END_OF_CODE';
package Marpa::R2::Sixish::Own_Rules;
END_OF_CODE

say Data::Dumper->Dump([$OP_rules], [qw(rules)]);

print <<'END_OF_CODE';
1;
END_OF_CODE

