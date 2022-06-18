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

package Marpa::R2::Sixish::Own_Rules;

$rules = [
           {
             'rhs' => [
                        '<first rule>',
                        '<more rules>'
                      ],
             'lhs' => '<top>',
             'action' => 'do_top'
           },
           {
             'rhs' => [
                        '<short rule>'
                      ],
             'lhs' => '<first rule>',
             'action' => 'do_array'
           },
           {
             'rhs' => [],
             'lhs' => '<more rules>',
             'action' => 'do_empty_array'
           },
           {
             'rhs' => [
                        '<rhs>'
                      ],
             'lhs' => '<short rule>',
             'action' => 'do_short_rule'
           },
           {
             'rhs' => [
                        '<concatenation>'
                      ],
             'lhs' => '<rhs>',
             'action' => 'do_arg0'
           },
           {
             'rhs' => [],
             'lhs' => '<concatenation>'
           },
           {
             'rhs' => [
                        '<concatenation>',
                        '<opt ws>',
                        '<quantified atom>'
                      ],
             'lhs' => '<concatenation>',
             'action' => 'do_concatenation'
           },
           {
             'rhs' => [],
             'lhs' => '<opt ws>',
             'action' => 'do_undef'
           },
           {
             'rhs' => [
                        '<opt ws>',
                        '<ws char>'
                      ],
             'lhs' => '<opt ws>',
             'action' => 'do_undef'
           },
           {
             'rhs' => [
                        '<atom>',
                        '<opt ws>',
                        '<quantifier>'
                      ],
             'lhs' => '<quantified atom>',
             'action' => 'do_quantification'
           },
           {
             'rhs' => [
                        '<atom>'
                      ],
             'lhs' => '<quantified atom>',
             'action' => 'do_arg0'
           },
           {
             'rhs' => [
                        '<quoted literal>'
                      ],
             'lhs' => '<atom>',
             'action' => 'do_arg0'
           },
           {
             'rhs' => [
                        '<single quote>',
                        '<single quoted char seq>',
                        '<single quote>'
                      ],
             'lhs' => '<quoted literal>',
             'action' => 'do_arg1'
           },
           {
             'min' => 0,
             'rhs' => [
                        '<single quoted char>'
                      ],
             'lhs' => '<single quoted char seq>'
           },
           {
             'rhs' => [
                        '<self>'
                      ],
             'lhs' => '<atom>',
             'action' => 'do_array'
           },
           {
             'rhs' => [
                        '\'<~~>\''
                      ],
             'lhs' => '<self>',
             'action' => 'do_self'
           },
           {
             'rhs' => [
                        '\'*\''
                      ],
             'lhs' => '<quantifier>'
           }
         ];

1;
