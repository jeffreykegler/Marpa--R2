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

# This file was generated automatically by mk_core_grammar.pl
# The date of generation was Tue Oct  2 08:04:44 2012

package Marpa::R2::HTML::Internal;

$CORE_RULES = [
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'cruft',
                  'action' => 'SPE_CRUFT'
                },
                {
                  'rhs' => [
                             'C'
                           ],
                  'lhs' => 'comment',
                  'action' => 'SPE_COMMENT'
                },
                {
                  'rhs' => [
                             'PI'
                           ],
                  'lhs' => 'pi',
                  'action' => 'SPE_PI'
                },
                {
                  'rhs' => [
                             'D'
                           ],
                  'lhs' => 'decl',
                  'action' => 'SPE_DECL'
                },
                {
                  'rhs' => [
                             'PCDATA'
                           ],
                  'lhs' => 'pcdata',
                  'action' => 'SPE_PCDATA'
                },
                {
                  'rhs' => [
                             'CDATA'
                           ],
                  'lhs' => 'cdata',
                  'action' => 'SPE_CDATA'
                },
                {
                  'rhs' => [
                             'WHITESPACE'
                           ],
                  'lhs' => 'whitespace',
                  'action' => 'SPE_WHITESPACE'
                },
                {
                  'rhs' => [
                             'comment'
                           ],
                  'lhs' => 'SGML_flow_item'
                },
                {
                  'rhs' => [
                             'pi'
                           ],
                  'lhs' => 'SGML_flow_item'
                },
                {
                  'rhs' => [
                             'decl'
                           ],
                  'lhs' => 'SGML_flow_item'
                },
                {
                  'rhs' => [
                             'whitespace'
                           ],
                  'lhs' => 'SGML_flow_item'
                },
                {
                  'rhs' => [
                             'cruft'
                           ],
                  'lhs' => 'SGML_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'SGML_flow'
                },
                {
                  'rhs' => [
                             'prolog',
                             'ELE_html',
                             'trailer',
                             'EOF'
                           ],
                  'lhs' => 'document',
                  'action' => 'SPE_TOP'
                },
                {
                  'rhs' => [
                             'SGML_flow'
                           ],
                  'lhs' => 'prolog',
                  'action' => 'SPE_PROLOG'
                },
                {
                  'rhs' => [
                             'SGML_flow'
                           ],
                  'lhs' => 'trailer',
                  'action' => 'SPE_TRAILER'
                },
                {
                  'rhs' => [
                             'S_html',
                             'EC_html',
                             'E_html'
                           ],
                  'lhs' => 'ELE_html',
                  'action' => 'ELE_html'
                },
                {
                  'rhs' => [
                             'SGML_flow',
                             'ELE_head',
                             'SGML_flow',
                             'ELE_body',
                             'SGML_flow'
                           ],
                  'lhs' => 'EC_html'
                },
                {
                  'rhs' => [
                             'S_head',
                             'EC_head',
                             'E_head'
                           ],
                  'lhs' => 'ELE_head',
                  'action' => 'ELE_head'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'head_item'
                           ],
                  'lhs' => 'EC_head'
                },
                {
                  'rhs' => [
                             'S_body',
                             'mixed_flow',
                             'E_body'
                           ],
                  'lhs' => 'ELE_body',
                  'action' => 'ELE_body'
                },
                {
                  'rhs' => [],
                  'lhs' => 'empty'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'mixed_flow_item'
                           ],
                  'lhs' => 'mixed_flow'
                },
                {
                  'rhs' => [
                             'block_element'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'rhs' => [
                             'inline_flow_item'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_table'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'list_item_element'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_script'
                           ],
                  'lhs' => 'inline_element'
                },
                {
                  'rhs' => [
                             'ELE_object'
                           ],
                  'lhs' => 'inline_element'
                },
                {
                  'rhs' => [
                             'ELE_select'
                           ],
                  'lhs' => 'inline_element'
                },
                {
                  'rhs' => [
                             'ELE_script'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'ELE_object'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'ELE_style'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'ELE_meta'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'ELE_link'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'ELE_isindex'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'ELE_title'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'ELE_base'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'inline_flow_item'
                           ],
                  'lhs' => 'inline_flow'
                },
                {
                  'rhs' => [
                             'pcdata_flow_item'
                           ],
                  'lhs' => 'inline_flow_item'
                },
                {
                  'rhs' => [
                             'inline_element'
                           ],
                  'lhs' => 'inline_flow_item'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'pcdata_flow_item'
                },
                {
                  'rhs' => [
                             'pcdata'
                           ],
                  'lhs' => 'pcdata_flow_item'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'pcdata_flow_item'
                },
                {
                  'rhs' => [
                             'S_base',
                             'empty',
                             'E_base'
                           ],
                  'lhs' => 'ELE_base',
                  'action' => 'ELE_base'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_colgroup'
                           ],
                  'lhs' => 'EC_colgroup'
                },
                {
                  'rhs' => [
                             'ELE_col'
                           ],
                  'lhs' => 'EI_colgroup'
                },
                {
                  'rhs' => [
                             'S_colgroup',
                             'EC_colgroup',
                             'E_colgroup'
                           ],
                  'lhs' => 'ELE_colgroup',
                  'action' => 'ELE_colgroup'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_colgroup'
                },
                {
                  'rhs' => [
                             'ELE_caption'
                           ],
                  'lhs' => 'table_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_col'
                           ],
                  'lhs' => 'table_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_colgroup'
                           ],
                  'lhs' => 'table_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_tbody'
                           ],
                  'lhs' => 'table_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_tfoot'
                           ],
                  'lhs' => 'table_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_thead'
                           ],
                  'lhs' => 'table_flow_item'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'table_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'table_flow_item'
                           ],
                  'lhs' => 'table_flow'
                },
                {
                  'rhs' => [
                             'S_isindex',
                             'empty',
                             'E_isindex'
                           ],
                  'lhs' => 'ELE_isindex',
                  'action' => 'ELE_isindex'
                },
                {
                  'rhs' => [
                             'S_link',
                             'empty',
                             'E_link'
                           ],
                  'lhs' => 'ELE_link',
                  'action' => 'ELE_link'
                },
                {
                  'rhs' => [
                             'S_meta',
                             'empty',
                             'E_meta'
                           ],
                  'lhs' => 'ELE_meta',
                  'action' => 'ELE_meta'
                },
                {
                  'rhs' => [
                             'ELE_param'
                           ],
                  'lhs' => 'Item_object'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'Item_object'
                           ],
                  'lhs' => 'EC_object'
                },
                {
                  'rhs' => [
                             'S_object',
                             'EC_object',
                             'E_object'
                           ],
                  'lhs' => 'ELE_object',
                  'action' => 'ELE_object'
                },
                {
                  'rhs' => [
                             'mixed_flow_item'
                           ],
                  'lhs' => 'Item_object'
                },
                {
                  'rhs' => [
                             'S_optgroup',
                             'EC_optgroup',
                             'E_optgroup'
                           ],
                  'lhs' => 'ELE_optgroup',
                  'action' => 'ELE_optgroup'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_optgroup'
                           ],
                  'lhs' => 'EC_optgroup'
                },
                {
                  'rhs' => [
                             'ELE_option'
                           ],
                  'lhs' => 'EI_optgroup'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_optgroup'
                },
                {
                  'rhs' => [
                             'S_param',
                             'inline_flow',
                             'E_param'
                           ],
                  'lhs' => 'ELE_param',
                  'action' => 'ELE_param'
                },
                {
                  'rhs' => [
                             'S_script',
                             'inline_flow',
                             'E_script'
                           ],
                  'lhs' => 'ELE_script',
                  'action' => 'ELE_script'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_select'
                           ],
                  'lhs' => 'EC_select'
                },
                {
                  'rhs' => [
                             'ELE_optgroup'
                           ],
                  'lhs' => 'EI_select'
                },
                {
                  'rhs' => [
                             'ELE_option'
                           ],
                  'lhs' => 'EI_select'
                },
                {
                  'rhs' => [
                             'S_select',
                             'EC_select',
                             'E_select'
                           ],
                  'lhs' => 'ELE_select',
                  'action' => 'ELE_select'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_select'
                },
                {
                  'rhs' => [
                             'S_style',
                             'inline_flow',
                             'E_style'
                           ],
                  'lhs' => 'ELE_style',
                  'action' => 'ELE_style'
                },
                {
                  'rhs' => [
                             'S_table',
                             'table_flow',
                             'E_table'
                           ],
                  'lhs' => 'ELE_table',
                  'action' => 'ELE_table'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_tbody'
                           ],
                  'lhs' => 'EC_tbody'
                },
                {
                  'rhs' => [
                             'ELE_tr'
                           ],
                  'lhs' => 'EI_tbody'
                },
                {
                  'rhs' => [
                             'S_tbody',
                             'EC_tbody',
                             'E_tbody'
                           ],
                  'lhs' => 'ELE_tbody',
                  'action' => 'ELE_tbody'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_tbody'
                },
                {
                  'rhs' => [
                             'S_td',
                             'mixed_flow',
                             'E_td'
                           ],
                  'lhs' => 'ELE_td',
                  'action' => 'ELE_td'
                },
                {
                  'rhs' => [
                             'S_title',
                             'inline_flow',
                             'E_title'
                           ],
                  'lhs' => 'ELE_title',
                  'action' => 'ELE_title'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_tr'
                           ],
                  'lhs' => 'EC_tr'
                },
                {
                  'rhs' => [
                             'ELE_td'
                           ],
                  'lhs' => 'EI_tr'
                },
                {
                  'rhs' => [
                             'ELE_th'
                           ],
                  'lhs' => 'EI_tr'
                },
                {
                  'rhs' => [
                             'S_tr',
                             'EC_tr',
                             'E_tr'
                           ],
                  'lhs' => 'ELE_tr',
                  'action' => 'ELE_tr'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_tr'
                }
              ];

