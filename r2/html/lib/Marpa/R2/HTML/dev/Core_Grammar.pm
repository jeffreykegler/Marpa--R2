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
# The date of generation was Sun Sep 30 19:29:30 2012

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
                             'Contents_html',
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
                  'lhs' => 'Contents_html'
                },
                {
                  'rhs' => [
                             'S_head',
                             'Contents_head',
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
                  'lhs' => 'Contents_head'
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
                  'rhs' => [
                             'S_table',
                             'table_flow',
                             'E_table'
                           ],
                  'lhs' => 'ELE_table',
                  'action' => 'ELE_table'
                },
                {
                  'rhs' => [
                             'S_tbody',
                             'table_section_flow',
                             'E_tbody'
                           ],
                  'lhs' => 'ELE_tbody',
                  'action' => 'ELE_tbody'
                },
                {
                  'rhs' => [
                             'S_tr',
                             'table_row_flow',
                             'E_tr'
                           ],
                  'lhs' => 'ELE_tr',
                  'action' => 'ELE_tr'
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
                  'min' => 0,
                  'rhs' => [
                             'mixed_flow_item'
                           ],
                  'lhs' => 'mixed_flow'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_table'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'rhs' => [
                             'list_item_element'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'rhs' => [
                             'block_element'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'rhs' => [
                             'inline_element'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'rhs' => [
                             'pcdata'
                           ],
                  'lhs' => 'mixed_flow_item'
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
                  'min' => 0,
                  'rhs' => [
                             'pcdata_flow_item'
                           ],
                  'lhs' => 'pcdata_flow'
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
                  'min' => 0,
                  'rhs' => [
                             'select_flow_item'
                           ],
                  'lhs' => 'Contents_select'
                },
                {
                  'rhs' => [
                             'ELE_optgroup'
                           ],
                  'lhs' => 'select_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_option'
                           ],
                  'lhs' => 'select_flow_item'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'select_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'optgroup_flow_item'
                           ],
                  'lhs' => 'Contents_optgroup'
                },
                {
                  'rhs' => [
                             'ELE_option'
                           ],
                  'lhs' => 'optgroup_flow_item'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'optgroup_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'list_item_flow_item'
                           ],
                  'lhs' => 'list_item_flow'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'list_item_flow_item'
                },
                {
                  'rhs' => [
                             'header_element'
                           ],
                  'lhs' => 'list_item_flow_item'
                },
                {
                  'rhs' => [
                             'block_element'
                           ],
                  'lhs' => 'list_item_flow_item'
                },
                {
                  'rhs' => [
                             'inline_element'
                           ],
                  'lhs' => 'list_item_flow_item'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'list_item_flow_item'
                },
                {
                  'rhs' => [
                             'pcdata'
                           ],
                  'lhs' => 'list_item_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'colgroup_flow_item'
                           ],
                  'lhs' => 'Contents_colgroup'
                },
                {
                  'rhs' => [
                             'ELE_col'
                           ],
                  'lhs' => 'colgroup_flow_item'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'colgroup_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'table_row_flow_item'
                           ],
                  'lhs' => 'table_row_flow'
                },
                {
                  'rhs' => [
                             'ELE_th'
                           ],
                  'lhs' => 'table_row_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_td'
                           ],
                  'lhs' => 'table_row_flow_item'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'table_row_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'table_section_flow_item'
                           ],
                  'lhs' => 'table_section_flow'
                },
                {
                  'rhs' => [
                             'table_row_element'
                           ],
                  'lhs' => 'table_section_flow_item'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'table_section_flow_item'
                },
                {
                  'rhs' => [
                             'ELE_tr'
                           ],
                  'lhs' => 'table_row_element'
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
                             'ELE_colgroup'
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
                             'ELE_tfoot'
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
                             'SGML_flow_item'
                           ],
                  'lhs' => 'table_flow_item'
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
                             'S_script',
                             'inline_flow',
                             'E_script'
                           ],
                  'lhs' => 'ELE_script',
                  'action' => 'ELE_script'
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
                             'S_title',
                             'inline_flow',
                             'E_title'
                           ],
                  'lhs' => 'ELE_title',
                  'action' => 'ELE_title'
                },
                {
                  'rhs' => [
                             'S_object',
                             'Contents_object',
                             'E_object'
                           ],
                  'lhs' => 'ELE_object',
                  'action' => 'ELE_object'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'Item_object'
                           ],
                  'lhs' => 'Contents_object'
                },
                {
                  'rhs' => [
                             'mixed_flow_item'
                           ],
                  'lhs' => 'Item_object'
                },
                {
                  'rhs' => [
                             'ELE_param'
                           ],
                  'lhs' => 'Item_object'
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
                             'S_base',
                             'empty',
                             'E_base'
                           ],
                  'lhs' => 'ELE_base',
                  'action' => 'ELE_base'
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
                             'S_meta',
                             'empty',
                             'E_meta'
                           ],
                  'lhs' => 'ELE_meta',
                  'action' => 'ELE_meta'
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
                  'rhs' => [],
                  'lhs' => 'empty'
                }
              ];

