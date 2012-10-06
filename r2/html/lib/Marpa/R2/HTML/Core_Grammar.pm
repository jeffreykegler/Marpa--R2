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
# The date of generation was Fri Oct  5 22:17:01 2012

package Marpa::R2::HTML::Internal;

$CORE_RULES = [
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
                             'FLO_SGML'
                           ],
                  'lhs' => 'prolog',
                  'action' => 'SPE_PROLOG'
                },
                {
                  'rhs' => [
                             'FLO_SGML'
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
                             'FLO_SGML',
                             'ELE_head',
                             'FLO_SGML',
                             'ELE_body',
                             'FLO_SGML'
                           ],
                  'lhs' => 'EC_html'
                },
                {
                  'rhs' => [
                             'S_body',
                             'block_flow',
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
                             'anywhere_element'
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
                             'ITEM_SGML'
                           ],
                  'lhs' => 'mixed_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'block_item'
                           ],
                  'lhs' => 'block_flow'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'block_item'
                },
                {
                  'rhs' => [
                             'block_element'
                           ],
                  'lhs' => 'block_item'
                },
                {
                  'rhs' => [
                             'anywhere_element'
                           ],
                  'lhs' => 'block_item'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'block_item'
                },
                {
                  'rhs' => [
                             'ELE_table'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_p'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_ol'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_ul'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_dl'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_div'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_dir'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_menu'
                           ],
                  'lhs' => 'block_element'
                },
                {
                  'rhs' => [
                             'ELE_script'
                           ],
                  'lhs' => 'anywhere_element'
                },
                {
                  'rhs' => [
                             'ELE_isindex'
                           ],
                  'lhs' => 'anywhere_element'
                },
                {
                  'rhs' => [
                             'ELE_textarea'
                           ],
                  'lhs' => 'anywhere_element'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'head_element'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'anywhere_element'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'head_item'
                },
                {
                  'rhs' => [
                             'ELE_object'
                           ],
                  'lhs' => 'head_element'
                },
                {
                  'rhs' => [
                             'ELE_style'
                           ],
                  'lhs' => 'head_element'
                },
                {
                  'rhs' => [
                             'ELE_meta'
                           ],
                  'lhs' => 'head_element'
                },
                {
                  'rhs' => [
                             'ELE_link'
                           ],
                  'lhs' => 'head_element'
                },
                {
                  'rhs' => [
                             'ELE_title'
                           ],
                  'lhs' => 'head_element'
                },
                {
                  'rhs' => [
                             'ELE_base'
                           ],
                  'lhs' => 'head_element'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'inline_item'
                           ],
                  'lhs' => 'inline_flow'
                },
                {
                  'rhs' => [
                             'pcdata'
                           ],
                  'lhs' => 'inline_item'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'inline_item'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'inline_item'
                },
                {
                  'rhs' => [
                             'inline_element'
                           ],
                  'lhs' => 'inline_item'
                },
                {
                  'rhs' => [
                             'anywhere_element'
                           ],
                  'lhs' => 'inline_item'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'inline_item'
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
                             'ELE_span'
                           ],
                  'lhs' => 'inline_element'
                },
                {
                  'rhs' => [
                             'ELE_map'
                           ],
                  'lhs' => 'inline_element'
                },
                {
                  'rhs' => [
                             'ELE_applet'
                           ],
                  'lhs' => 'inline_element'
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
                             'ITEM_SGML'
                           ],
                  'lhs' => 'pcdata_flow_item'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'cdata_flow_item'
                           ],
                  'lhs' => 'cdata_flow'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'cdata_flow_item'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'cdata_flow_item'
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
                             'S_col',
                             'empty',
                             'E_col'
                           ],
                  'lhs' => 'ELE_col',
                  'action' => 'ELE_col'
                },
                {
                  'rhs' => [
                             'S_dd',
                             'mixed_flow',
                             'E_dd'
                           ],
                  'lhs' => 'ELE_dd',
                  'action' => 'ELE_dd'
                },
                {
                  'rhs' => [
                             'S_div',
                             'mixed_flow',
                             'E_div'
                           ],
                  'lhs' => 'ELE_div',
                  'action' => 'ELE_div'
                },
                {
                  'rhs' => [
                             'S_dt',
                             'inline_flow',
                             'E_dt'
                           ],
                  'lhs' => 'ELE_dt',
                  'action' => 'ELE_dt'
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
                             'S_li',
                             'mixed_flow',
                             'E_li'
                           ],
                  'lhs' => 'ELE_li',
                  'action' => 'ELE_li'
                },
                {
                  'rhs' => [
                             'S_area',
                             'empty',
                             'E_area'
                           ],
                  'lhs' => 'ELE_area',
                  'action' => 'ELE_area'
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
                             'S_p',
                             'inline_flow',
                             'E_p'
                           ],
                  'lhs' => 'ELE_p',
                  'action' => 'ELE_p'
                },
                {
                  'rhs' => [
                             'S_param',
                             'empty',
                             'E_param'
                           ],
                  'lhs' => 'ELE_param',
                  'action' => 'ELE_param'
                },
                {
                  'rhs' => [
                             'S_script',
                             'cdata_flow',
                             'E_script'
                           ],
                  'lhs' => 'ELE_script',
                  'action' => 'ELE_script'
                },
                {
                  'rhs' => [
                             'S_span',
                             'inline_flow',
                             'E_span'
                           ],
                  'lhs' => 'ELE_span',
                  'action' => 'ELE_span'
                },
                {
                  'rhs' => [
                             'S_style',
                             'cdata_flow',
                             'E_style'
                           ],
                  'lhs' => 'ELE_style',
                  'action' => 'ELE_style'
                },
                {
                  'rhs' => [
                             'S_textarea',
                             'cdata_flow',
                             'E_textarea'
                           ],
                  'lhs' => 'ELE_textarea',
                  'action' => 'ELE_textarea'
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
                             'pcdata_flow',
                             'E_title'
                           ],
                  'lhs' => 'ELE_title',
                  'action' => 'ELE_title'
                },
                {
                  'rhs' => [
                             'S_head',
                             '_C_ELE_head',
                             'E_head'
                           ],
                  'lhs' => 'ELE_head',
                  'action' => 'ELE_head'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_head'
                           ],
                  'lhs' => '_C_ELE_head'
                },
                {
                  'rhs' => [
                             'head_item'
                           ],
                  'lhs' => 'ITEM_ELE_head'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_head'
                },
                {
                  'rhs' => [
                             'S_optgroup',
                             '_C_ELE_optgroup',
                             'E_optgroup'
                           ],
                  'lhs' => 'ELE_optgroup',
                  'action' => 'ELE_optgroup'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_optgroup'
                           ],
                  'lhs' => '_C_ELE_optgroup'
                },
                {
                  'rhs' => [
                             'ELE_option'
                           ],
                  'lhs' => 'ITEM_ELE_optgroup'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_optgroup'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_optgroup'
                },
                {
                  'rhs' => [
                             'S_table',
                             '_C_ELE_table',
                             'E_table'
                           ],
                  'lhs' => 'ELE_table',
                  'action' => 'ELE_table'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_table'
                           ],
                  'lhs' => '_C_ELE_table'
                },
                {
                  'rhs' => [
                             'ELE_caption'
                           ],
                  'lhs' => 'ITEM_ELE_table'
                },
                {
                  'rhs' => [
                             'ELE_col'
                           ],
                  'lhs' => 'ITEM_ELE_table'
                },
                {
                  'rhs' => [
                             'ELE_colgroup'
                           ],
                  'lhs' => 'ITEM_ELE_table'
                },
                {
                  'rhs' => [
                             'ELE_tbody'
                           ],
                  'lhs' => 'ITEM_ELE_table'
                },
                {
                  'rhs' => [
                             'ELE_tfoot'
                           ],
                  'lhs' => 'ITEM_ELE_table'
                },
                {
                  'rhs' => [
                             'ELE_thead'
                           ],
                  'lhs' => 'ITEM_ELE_table'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_table'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_table'
                },
                {
                  'rhs' => [
                             '_C_FLO_SGML'
                           ],
                  'lhs' => 'FLO_SGML'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => '_C_FLO_SGML'
                },
                {
                  'rhs' => [
                             'comment'
                           ],
                  'lhs' => 'ITEM_SGML'
                },
                {
                  'rhs' => [
                             'pi'
                           ],
                  'lhs' => 'ITEM_SGML'
                },
                {
                  'rhs' => [
                             'decl'
                           ],
                  'lhs' => 'ITEM_SGML'
                },
                {
                  'rhs' => [
                             'whitespace'
                           ],
                  'lhs' => 'ITEM_SGML'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_SGML'
                },
                {
                  'rhs' => [
                             'S_menu',
                             '_C_ELE_menu',
                             'E_menu'
                           ],
                  'lhs' => 'ELE_menu',
                  'action' => 'ELE_menu'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_menu'
                           ],
                  'lhs' => '_C_ELE_menu'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_menu'
                },
                {
                  'rhs' => [
                             'ELE_li'
                           ],
                  'lhs' => 'ITEM_ELE_menu'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_menu'
                },
                {
                  'rhs' => [
                             'S_tr',
                             '_C_ELE_tr',
                             'E_tr'
                           ],
                  'lhs' => 'ELE_tr',
                  'action' => 'ELE_tr'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_tr'
                           ],
                  'lhs' => '_C_ELE_tr'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_tr'
                },
                {
                  'rhs' => [
                             'ELE_th'
                           ],
                  'lhs' => 'ITEM_ELE_tr'
                },
                {
                  'rhs' => [
                             'ELE_td'
                           ],
                  'lhs' => 'ITEM_ELE_tr'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_tr'
                },
                {
                  'rhs' => [
                             'S_dl',
                             '_C_ELE_dl',
                             'E_dl'
                           ],
                  'lhs' => 'ELE_dl',
                  'action' => 'ELE_dl'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_dl'
                           ],
                  'lhs' => '_C_ELE_dl'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_dl'
                },
                {
                  'rhs' => [
                             'ELE_dt'
                           ],
                  'lhs' => 'ITEM_ELE_dl'
                },
                {
                  'rhs' => [
                             'ELE_dd'
                           ],
                  'lhs' => 'ITEM_ELE_dl'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_dl'
                },
                {
                  'rhs' => [
                             'S_map',
                             '_C_ELE_map',
                             'E_map'
                           ],
                  'lhs' => 'ELE_map',
                  'action' => 'ELE_map'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_map'
                           ],
                  'lhs' => '_C_ELE_map'
                },
                {
                  'rhs' => [
                             'block_element'
                           ],
                  'lhs' => 'ITEM_ELE_map'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_map'
                },
                {
                  'rhs' => [
                             'ELE_area'
                           ],
                  'lhs' => 'ITEM_ELE_map'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_map'
                },
                {
                  'rhs' => [
                             'S_applet',
                             '_C_ELE_applet',
                             'E_applet'
                           ],
                  'lhs' => 'ELE_applet',
                  'action' => 'ELE_applet'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_applet'
                           ],
                  'lhs' => '_C_ELE_applet'
                },
                {
                  'rhs' => [
                             'ELE_param'
                           ],
                  'lhs' => 'ITEM_ELE_applet'
                },
                {
                  'rhs' => [
                             'mixed_flow_item'
                           ],
                  'lhs' => 'ITEM_ELE_applet'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_applet'
                },
                {
                  'rhs' => [
                             'S_ol',
                             '_C_ELE_ol',
                             'E_ol'
                           ],
                  'lhs' => 'ELE_ol',
                  'action' => 'ELE_ol'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_ol'
                           ],
                  'lhs' => '_C_ELE_ol'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_ol'
                },
                {
                  'rhs' => [
                             'ELE_li'
                           ],
                  'lhs' => 'ITEM_ELE_ol'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_ol'
                },
                {
                  'rhs' => [
                             'S_ul',
                             '_C_ELE_ul',
                             'E_ul'
                           ],
                  'lhs' => 'ELE_ul',
                  'action' => 'ELE_ul'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_ul'
                           ],
                  'lhs' => '_C_ELE_ul'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_ul'
                },
                {
                  'rhs' => [
                             'ELE_li'
                           ],
                  'lhs' => 'ITEM_ELE_ul'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_ul'
                },
                {
                  'rhs' => [
                             'S_tbody',
                             '_C_ELE_tbody',
                             'E_tbody'
                           ],
                  'lhs' => 'ELE_tbody',
                  'action' => 'ELE_tbody'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_tbody'
                           ],
                  'lhs' => '_C_ELE_tbody'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_tbody'
                },
                {
                  'rhs' => [
                             'ELE_tr'
                           ],
                  'lhs' => 'ITEM_ELE_tbody'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_tbody'
                },
                {
                  'rhs' => [
                             'S_dir',
                             '_C_ELE_dir',
                             'E_dir'
                           ],
                  'lhs' => 'ELE_dir',
                  'action' => 'ELE_dir'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_dir'
                           ],
                  'lhs' => '_C_ELE_dir'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_dir'
                },
                {
                  'rhs' => [
                             'ELE_li'
                           ],
                  'lhs' => 'ITEM_ELE_dir'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_dir'
                },
                {
                  'rhs' => [
                             'S_object',
                             '_C_ELE_object',
                             'E_object'
                           ],
                  'lhs' => 'ELE_object',
                  'action' => 'ELE_object'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_object'
                           ],
                  'lhs' => '_C_ELE_object'
                },
                {
                  'rhs' => [
                             'ELE_param'
                           ],
                  'lhs' => 'ITEM_ELE_object'
                },
                {
                  'rhs' => [
                             'mixed_flow_item'
                           ],
                  'lhs' => 'ITEM_ELE_object'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_object'
                },
                {
                  'rhs' => [
                             'S_tfoot',
                             '_C_ELE_tfoot',
                             'E_tfoot'
                           ],
                  'lhs' => 'ELE_tfoot',
                  'action' => 'ELE_tfoot'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_tfoot'
                           ],
                  'lhs' => '_C_ELE_tfoot'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_tfoot'
                },
                {
                  'rhs' => [
                             'ELE_tr'
                           ],
                  'lhs' => 'ITEM_ELE_tfoot'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_tfoot'
                },
                {
                  'rhs' => [
                             'S_colgroup',
                             '_C_ELE_colgroup',
                             'E_colgroup'
                           ],
                  'lhs' => 'ELE_colgroup',
                  'action' => 'ELE_colgroup'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_colgroup'
                           ],
                  'lhs' => '_C_ELE_colgroup'
                },
                {
                  'rhs' => [
                             'ELE_col'
                           ],
                  'lhs' => 'ITEM_ELE_colgroup'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_colgroup'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_colgroup'
                },
                {
                  'rhs' => [
                             'S_thead',
                             '_C_ELE_thead',
                             'E_thead'
                           ],
                  'lhs' => 'ELE_thead',
                  'action' => 'ELE_thead'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_thead'
                           ],
                  'lhs' => '_C_ELE_thead'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_thead'
                },
                {
                  'rhs' => [
                             'ELE_tr'
                           ],
                  'lhs' => 'ITEM_ELE_thead'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_thead'
                },
                {
                  'rhs' => [
                             'S_select',
                             '_C_ELE_select',
                             'E_select'
                           ],
                  'lhs' => 'ELE_select',
                  'action' => 'ELE_select'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_select'
                           ],
                  'lhs' => '_C_ELE_select'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_select'
                },
                {
                  'rhs' => [
                             'ELE_optgroup'
                           ],
                  'lhs' => 'ITEM_ELE_select'
                },
                {
                  'rhs' => [
                             'ELE_option'
                           ],
                  'lhs' => 'ITEM_ELE_select'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_ELE_select'
                }
              ];
$IS_BLOCK_ELEMENT = {
                      'xmp' => 'cdata_flow',
                      'form' => 'mixed_flow',
                      'pre' => 'inline_flow',
                      'h5' => 'inline_flow',
                      'center' => 'mixed_flow',
                      'noframes' => 'mixed_flow',
                      'plaintext' => 'cdata_flow',
                      'h6' => 'inline_flow',
                      'address' => 'inline_flow',
                      'h1' => 'inline_flow',
                      'blockquote' => 'mixed_flow',
                      'h4' => 'inline_flow',
                      'h2' => 'inline_flow',
                      'fieldset' => 'mixed_flow',
                      'hr' => 'empty',
                      'h3' => 'inline_flow',
                      'noscript' => 'mixed_flow'
                    };
$IS_INLINE_ELEMENT = {
                       'embed' => 'inline_flow',
                       'a' => 'inline_flow',
                       'input' => 'cdata_flow',
                       'strike' => 'inline_flow',
                       'rbc' => 'inline_flow',
                       'keygen' => 'inline_flow',
                       'img' => 'empty',
                       'font' => 'inline_flow',
                       'rb' => 'inline_flow',
                       'tt' => 'inline_flow',
                       'blink' => 'inline_flow',
                       'mark' => 'inline_flow',
                       'abbr' => 'inline_flow',
                       'u' => 'inline_flow',
                       'sup' => 'inline_flow',
                       'rt' => 'inline_flow',
                       'basefont' => 'empty',
                       'code' => 'inline_flow',
                       'br' => 'empty',
                       'acronym' => 'inline_flow',
                       'video' => 'inline_flow',
                       'strong' => 'inline_flow',
                       'output' => 'inline_flow',
                       's' => 'inline_flow',
                       'em' => 'inline_flow',
                       'b' => 'inline_flow',
                       'q' => 'inline_flow',
                       'label' => 'inline_flow',
                       'kbd' => 'inline_flow',
                       'rp' => 'inline_flow',
                       'small' => 'inline_flow',
                       'time' => 'inline_flow',
                       'audio' => 'inline_flow',
                       'nobr' => 'inline_flow',
                       'rtc' => 'inline_flow',
                       'samp' => 'inline_flow',
                       'var' => 'inline_flow',
                       'cite' => 'inline_flow',
                       'i' => 'inline_flow',
                       'command' => 'inline_flow',
                       'bdo' => 'inline_flow',
                       'progress' => 'inline_flow',
                       'ruby' => 'inline_flow',
                       'wbr' => 'inline_flow',
                       'dfn' => 'inline_flow',
                       'big' => 'inline_flow',
                       'sub' => 'inline_flow',
                       'meter' => 'inline_flow',
                       'button' => 'inline_flow'
                     };
$IS_HEAD_ELEMENT = {
                     'base' => 'core',
                     'link' => 'core',
                     'object' => 'core',
                     'style' => 'core',
                     'title' => 'core',
                     'meta' => 'core'
                   };
$IS_ANYWHERE_ELEMENT = {
                         'isindex' => 'core',
                         'script' => 'core',
                         'textarea' => 'core'
                       };
$IS_INLINE_ELEMENT = {
                       'embed' => 'inline_flow',
                       'strike' => 'inline_flow',
                       'input' => 'cdata_flow',
                       'a' => 'inline_flow',
                       'rbc' => 'inline_flow',
                       'keygen' => 'inline_flow',
                       'img' => 'empty',
                       'tt' => 'inline_flow',
                       'rb' => 'inline_flow',
                       'font' => 'inline_flow',
                       'mark' => 'inline_flow',
                       'map' => 'core',
                       'blink' => 'inline_flow',
                       'u' => 'inline_flow',
                       'abbr' => 'inline_flow',
                       'sup' => 'inline_flow',
                       'rt' => 'inline_flow',
                       'basefont' => 'empty',
                       'code' => 'inline_flow',
                       'video' => 'inline_flow',
                       'acronym' => 'inline_flow',
                       'br' => 'empty',
                       'strong' => 'inline_flow',
                       's' => 'inline_flow',
                       'output' => 'inline_flow',
                       'em' => 'inline_flow',
                       'q' => 'inline_flow',
                       'b' => 'inline_flow',
                       'span' => 'core',
                       'label' => 'inline_flow',
                       'applet' => 'core',
                       'rp' => 'inline_flow',
                       'kbd' => 'inline_flow',
                       'small' => 'inline_flow',
                       'time' => 'inline_flow',
                       'audio' => 'inline_flow',
                       'nobr' => 'inline_flow',
                       'samp' => 'inline_flow',
                       'rtc' => 'inline_flow',
                       'var' => 'inline_flow',
                       'cite' => 'inline_flow',
                       'select' => 'core',
                       'command' => 'inline_flow',
                       'i' => 'inline_flow',
                       'bdo' => 'inline_flow',
                       'progress' => 'inline_flow',
                       'ruby' => 'inline_flow',
                       'wbr' => 'inline_flow',
                       'dfn' => 'inline_flow',
                       'sub' => 'inline_flow',
                       'big' => 'inline_flow',
                       'meter' => 'inline_flow',
                       'button' => 'inline_flow',
                       'textarea' => 'core'
                     };
$IS_BLOCK_ELEMENT = {
                      'xmp' => 'cdata_flow',
                      'div' => 'core',
                      'table' => 'core',
                      'pre' => 'inline_flow',
                      'form' => 'mixed_flow',
                      'h5' => 'inline_flow',
                      'noframes' => 'mixed_flow',
                      'dir' => 'core',
                      'center' => 'mixed_flow',
                      'plaintext' => 'cdata_flow',
                      'ol' => 'core',
                      'h6' => 'inline_flow',
                      'address' => 'inline_flow',
                      'ul' => 'core',
                      'h1' => 'inline_flow',
                      'blockquote' => 'mixed_flow',
                      'menu' => 'core',
                      'h4' => 'inline_flow',
                      'h2' => 'inline_flow',
                      'p' => 'core',
                      'fieldset' => 'mixed_flow',
                      'hr' => 'empty',
                      'noscript' => 'mixed_flow',
                      'h3' => 'inline_flow',
                      'dl' => 'core'
                    };
$RUBY_SLIPPERS_RANK_BY_NAME = {
                                'S_col' => {
                                             'S_head' => 4,
                                             '!non_final_end' => 2,
                                             'S_table' => 1,
                                             'S_html' => 5,
                                             'S_body' => 3
                                           },
                                'S_optgroup' => {
                                                  'S_p' => 3,
                                                  'S_tbody' => 6,
                                                  'S_html' => 9,
                                                  'S_tr' => 5,
                                                  'S_head' => 8,
                                                  'S_td' => 4,
                                                  '!non_final_end' => 1,
                                                  'S_select' => 2,
                                                  'S_body' => 7
                                                },
                                'S_colgroup' => {
                                                  'S_head' => 4,
                                                  '!non_final_end' => 2,
                                                  'S_table' => 1,
                                                  'S_html' => 5,
                                                  'S_body' => 3
                                                },
                                'EOF' => {
                                           'S_head' => 5,
                                           'E_html' => 1,
                                           '!non_final_end' => 3,
                                           'E_body' => 2,
                                           'S_html' => 6,
                                           'S_body' => 4
                                         },
                                '!end_tag' => {
                                                '!non_final_end' => 1
                                              },
                                '!head_start_tag' => {
                                                       'S_head' => 2,
                                                       '!non_final_end' => 1,
                                                       'S_html' => 3
                                                     },
                                'S_param' => {
                                               'S_head' => 4,
                                               '!non_final_end' => 1,
                                               'S_object' => 2,
                                               'S_html' => 5,
                                               'S_body' => 3
                                             },
                                'PCDATA' => {
                                              'S_p' => 2,
                                              'S_tbody' => 5,
                                              'S_html' => 8,
                                              'S_tr' => 4,
                                              'S_head' => 7,
                                              'S_td' => 3,
                                              '!non_final_end' => 1,
                                              'S_body' => 6
                                            },
                                'S_caption' => {
                                                 'S_head' => 4,
                                                 '!non_final_end' => 2,
                                                 'S_table' => 1,
                                                 'S_html' => 5,
                                                 'S_body' => 3
                                               },
                                'S_th' => {
                                            'S_thead' => 5,
                                            'S_table' => 1,
                                            'S_tbody' => 4,
                                            'S_html' => 8,
                                            'S_tr' => 3,
                                            'S_head' => 7,
                                            '!non_final_end' => 2,
                                            'S_body' => 6
                                          },
                                'E_body' => {
                                              'S_head' => 3,
                                              '!non_final_end' => 1,
                                              'S_html' => 4,
                                              'S_body' => 2
                                            },
                                'S_option' => {
                                                'S_p' => 3,
                                                'S_tbody' => 6,
                                                'S_html' => 9,
                                                'S_tr' => 5,
                                                'S_head' => 8,
                                                'S_td' => 4,
                                                '!non_final_end' => 1,
                                                'S_select' => 2,
                                                'S_body' => 7
                                              },
                                '!inline_start_tag' => {
                                                         'S_p' => 2,
                                                         'S_tbody' => 5,
                                                         'S_html' => 8,
                                                         'S_tr' => 4,
                                                         'S_head' => 7,
                                                         'S_td' => 3,
                                                         '!non_final_end' => 1,
                                                         'S_body' => 6
                                                       },
                                'S_dd' => {
                                            'S_head' => 4,
                                            '!non_final_end' => 1,
                                            'S_dl' => 2,
                                            'S_html' => 5,
                                            'S_body' => 3
                                          },
                                'E_html' => {
                                              'S_head' => 4,
                                              '!non_final_end' => 2,
                                              'E_body' => 1,
                                              'S_html' => 5,
                                              'S_body' => 3
                                            },
                                'S_thead' => {
                                               'S_head' => 4,
                                               '!non_final_end' => 2,
                                               'S_table' => 1,
                                               'S_html' => 5,
                                               'S_body' => 3
                                             },
                                'S_dt' => {
                                            'S_head' => 4,
                                            '!non_final_end' => 1,
                                            'S_dl' => 2,
                                            'S_html' => 5,
                                            'S_body' => 3
                                          },
                                'S_area' => {
                                              'S_head' => 4,
                                              'S_map' => 2,
                                              '!non_final_end' => 1,
                                              'S_html' => 5,
                                              'S_body' => 3
                                            },
                                'S_tbody' => {
                                               'S_head' => 4,
                                               '!non_final_end' => 2,
                                               'S_table' => 1,
                                               'S_html' => 5,
                                               'S_body' => 3
                                             },
                                'S_tfoot' => {
                                               'S_head' => 4,
                                               '!non_final_end' => 2,
                                               'S_table' => 1,
                                               'S_html' => 5,
                                               'S_body' => 3
                                             },
                                'S_html' => {
                                              '!non_final_end' => 1
                                            },
                                'CDATA' => {
                                             'S_p' => 2,
                                             'S_tbody' => 5,
                                             'S_html' => 8,
                                             'S_tr' => 4,
                                             'S_head' => 7,
                                             'S_td' => 3,
                                             '!non_final_end' => 1,
                                             'S_body' => 6
                                           },
                                'S_tr' => {
                                            'S_head' => 5,
                                            '!non_final_end' => 2,
                                            'S_table' => 1,
                                            'S_tbody' => 3,
                                            'S_html' => 6,
                                            'S_body' => 4
                                          },
                                'S_head' => {
                                              '!non_final_end' => 1,
                                              'S_html' => 2
                                            },
                                'E_table' => {
                                               'S_head' => 4,
                                               '!non_final_end' => 2,
                                               'S_table' => 1,
                                               'S_html' => 5,
                                               'S_body' => 3
                                             },
                                '!start_tag' => {
                                                  'S_head' => 3,
                                                  '!non_final_end' => 1,
                                                  'S_html' => 4,
                                                  'S_body' => 2
                                                },
                                'S_td' => {
                                            'S_tr' => 3,
                                            'S_head' => 6,
                                            '!non_final_end' => 2,
                                            'S_table' => 1,
                                            'S_tbody' => 4,
                                            'S_html' => 7,
                                            'S_body' => 5
                                          },
                                'S_li' => {
                                            'S_head' => 4,
                                            '!non_final_end' => 2,
                                            'S_html' => 5,
                                            'S_body' => 3,
                                            'S_ul' => 1
                                          },
                                'S_body' => {
                                              'S_head' => 2,
                                              '!non_final_end' => 1,
                                              'S_html' => 3
                                            },
                                '!non_element' => {
                                                    '!non_final_end' => 1
                                                  }
                              };

