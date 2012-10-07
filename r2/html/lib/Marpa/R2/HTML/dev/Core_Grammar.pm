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
# The date of generation was Sat Oct  6 17:30:55 2012

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
                             'CRUFT'
                           ],
                  'lhs' => 'cruft',
                  'action' => 'SPE_CRUFT'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'FLO_SGML'
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
                             'cruft'
                           ],
                  'lhs' => 'ITEM_SGML'
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
                             'S_head',
                             'FLO_head',
                             'E_head'
                           ],
                  'lhs' => 'ELE_head',
                  'action' => 'ELE_head'
                },
                {
                  'rhs' => [
                             'S_body',
                             'FLO_block',
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
                  'rhs' => [
                             'ELE_table'
                           ],
                  'lhs' => 'GRP_block'
                },
                {
                  'rhs' => [
                             'ELE_p'
                           ],
                  'lhs' => 'GRP_block'
                },
                {
                  'rhs' => [
                             'ELE_ol'
                           ],
                  'lhs' => 'GRP_block'
                },
                {
                  'rhs' => [
                             'ELE_ul'
                           ],
                  'lhs' => 'GRP_block'
                },
                {
                  'rhs' => [
                             'ELE_dl'
                           ],
                  'lhs' => 'GRP_block'
                },
                {
                  'rhs' => [
                             'ELE_div'
                           ],
                  'lhs' => 'GRP_block'
                },
                {
                  'rhs' => [
                             'ELE_dir'
                           ],
                  'lhs' => 'GRP_block'
                },
                {
                  'rhs' => [
                             'ELE_menu'
                           ],
                  'lhs' => 'GRP_block'
                },
                {
                  'rhs' => [
                             'ELE_script'
                           ],
                  'lhs' => 'GRP_anywhere'
                },
                {
                  'rhs' => [
                             'ELE_isindex'
                           ],
                  'lhs' => 'GRP_anywhere'
                },
                {
                  'rhs' => [
                             'ELE_textarea'
                           ],
                  'lhs' => 'GRP_anywhere'
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
                  'rhs' => [
                             'ELE_object'
                           ],
                  'lhs' => 'GRP_inline'
                },
                {
                  'rhs' => [
                             'ELE_select'
                           ],
                  'lhs' => 'GRP_inline'
                },
                {
                  'rhs' => [
                             'ELE_span'
                           ],
                  'lhs' => 'GRP_inline'
                },
                {
                  'rhs' => [
                             'ELE_map'
                           ],
                  'lhs' => 'GRP_inline'
                },
                {
                  'rhs' => [
                             'ELE_applet'
                           ],
                  'lhs' => 'GRP_inline'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_cdata'
                           ],
                  'lhs' => 'FLO_cdata'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'ITEM_cdata'
                },
                {
                  'rhs' => [
                             'CRUFT'
                           ],
                  'lhs' => 'ITEM_cdata'
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
                             'FLO_mixed',
                             'E_dd'
                           ],
                  'lhs' => 'ELE_dd',
                  'action' => 'ELE_dd'
                },
                {
                  'rhs' => [
                             'S_div',
                             'FLO_mixed',
                             'E_div'
                           ],
                  'lhs' => 'ELE_div',
                  'action' => 'ELE_div'
                },
                {
                  'rhs' => [
                             'S_dt',
                             'FLO_inline',
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
                             'FLO_mixed',
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
                             'FLO_inline',
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
                             'FLO_cdata',
                             'E_script'
                           ],
                  'lhs' => 'ELE_script',
                  'action' => 'ELE_script'
                },
                {
                  'rhs' => [
                             'S_span',
                             'FLO_inline',
                             'E_span'
                           ],
                  'lhs' => 'ELE_span',
                  'action' => 'ELE_span'
                },
                {
                  'rhs' => [
                             'S_style',
                             'FLO_cdata',
                             'E_style'
                           ],
                  'lhs' => 'ELE_style',
                  'action' => 'ELE_style'
                },
                {
                  'rhs' => [
                             'S_textarea',
                             'FLO_cdata',
                             'E_textarea'
                           ],
                  'lhs' => 'ELE_textarea',
                  'action' => 'ELE_textarea'
                },
                {
                  'rhs' => [
                             'S_td',
                             'FLO_mixed',
                             'E_td'
                           ],
                  'lhs' => 'ELE_td',
                  'action' => 'ELE_td'
                },
                {
                  'rhs' => [
                             'S_title',
                             'FLO_pcdata',
                             'E_title'
                           ],
                  'lhs' => 'ELE_title',
                  'action' => 'ELE_title'
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
                             'ELE_li'
                           ],
                  'lhs' => 'ITEM_ELE_menu'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
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
                             'ITEM_SGML'
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
                             'ITEM_SGML'
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
                             'GRP_block'
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
                             'ITEM_SGML'
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
                             'ITEM_mixed'
                           ],
                  'lhs' => 'ITEM_ELE_applet'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
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
                             'ELE_li'
                           ],
                  'lhs' => 'ITEM_ELE_ol'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_ol'
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
                             'ELE_tr'
                           ],
                  'lhs' => 'ITEM_ELE_tbody'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_tbody'
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
                             'ELE_li'
                           ],
                  'lhs' => 'ITEM_ELE_ul'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_ul'
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
                             'ELE_li'
                           ],
                  'lhs' => 'ITEM_ELE_dir'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
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
                             'ITEM_mixed'
                           ],
                  'lhs' => 'ITEM_ELE_object'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
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
                             'ELE_tr'
                           ],
                  'lhs' => 'ITEM_ELE_tfoot'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
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
                             'ELE_tr'
                           ],
                  'lhs' => 'ITEM_ELE_thead'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
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
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_ELE_select'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_pcdata'
                           ],
                  'lhs' => 'FLO_pcdata'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'ITEM_pcdata'
                },
                {
                  'rhs' => [
                             'pcdata'
                           ],
                  'lhs' => 'ITEM_pcdata'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_pcdata'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_inline'
                           ],
                  'lhs' => 'FLO_inline'
                },
                {
                  'rhs' => [
                             'pcdata'
                           ],
                  'lhs' => 'ITEM_inline'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'ITEM_inline'
                },
                {
                  'rhs' => [
                             'GRP_inline'
                           ],
                  'lhs' => 'ITEM_inline'
                },
                {
                  'rhs' => [
                             'GRP_anywhere'
                           ],
                  'lhs' => 'ITEM_inline'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_inline'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_head'
                           ],
                  'lhs' => 'FLO_head'
                },
                {
                  'rhs' => [
                             'head_element'
                           ],
                  'lhs' => 'ITEM_head'
                },
                {
                  'rhs' => [
                             'GRP_anywhere'
                           ],
                  'lhs' => 'ITEM_head'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_head'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_mixed'
                           ],
                  'lhs' => 'FLO_mixed'
                },
                {
                  'rhs' => [
                             'GRP_anywhere'
                           ],
                  'lhs' => 'ITEM_mixed'
                },
                {
                  'rhs' => [
                             'GRP_block'
                           ],
                  'lhs' => 'ITEM_mixed'
                },
                {
                  'rhs' => [
                             'GRP_inline'
                           ],
                  'lhs' => 'ITEM_mixed'
                },
                {
                  'rhs' => [
                             'cdata'
                           ],
                  'lhs' => 'ITEM_mixed'
                },
                {
                  'rhs' => [
                             'pcdata'
                           ],
                  'lhs' => 'ITEM_mixed'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_mixed'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'ITEM_block'
                           ],
                  'lhs' => 'FLO_block'
                },
                {
                  'rhs' => [
                             'GRP_block'
                           ],
                  'lhs' => 'ITEM_block'
                },
                {
                  'rhs' => [
                             'GRP_anywhere'
                           ],
                  'lhs' => 'ITEM_block'
                },
                {
                  'rhs' => [
                             'ITEM_SGML'
                           ],
                  'lhs' => 'ITEM_block'
                }
              ];
$IS_BLOCK_ELEMENT = {
                      'xmp' => 'FLO_cdata',
                      'form' => 'FLO_mixed',
                      'pre' => 'FLO_inline',
                      'h5' => 'FLO_inline',
                      'center' => 'FLO_mixed',
                      'noframes' => 'FLO_mixed',
                      'plaintext' => 'FLO_cdata',
                      'h6' => 'FLO_inline',
                      'address' => 'FLO_inline',
                      'h1' => 'FLO_inline',
                      'blockquote' => 'FLO_mixed',
                      'h4' => 'FLO_inline',
                      'h2' => 'FLO_inline',
                      'fieldset' => 'FLO_mixed',
                      'hr' => 'empty',
                      'h3' => 'FLO_inline',
                      'noscript' => 'FLO_mixed'
                    };
$IS_INLINE_ELEMENT = {
                       'embed' => 'FLO_inline',
                       'a' => 'FLO_inline',
                       'input' => 'FLO_cdata',
                       'strike' => 'FLO_inline',
                       'rbc' => 'FLO_inline',
                       'keygen' => 'FLO_inline',
                       'img' => 'empty',
                       'font' => 'FLO_inline',
                       'rb' => 'FLO_inline',
                       'tt' => 'FLO_inline',
                       'blink' => 'FLO_inline',
                       'mark' => 'FLO_inline',
                       'abbr' => 'FLO_inline',
                       'u' => 'FLO_inline',
                       'sup' => 'FLO_inline',
                       'rt' => 'FLO_inline',
                       'basefont' => 'empty',
                       'code' => 'FLO_inline',
                       'br' => 'empty',
                       'acronym' => 'FLO_inline',
                       'video' => 'FLO_inline',
                       'strong' => 'FLO_inline',
                       'output' => 'FLO_inline',
                       's' => 'FLO_inline',
                       'em' => 'FLO_inline',
                       'b' => 'FLO_inline',
                       'q' => 'FLO_inline',
                       'label' => 'FLO_inline',
                       'kbd' => 'FLO_inline',
                       'rp' => 'FLO_inline',
                       'small' => 'FLO_inline',
                       'time' => 'FLO_inline',
                       'audio' => 'FLO_inline',
                       'nobr' => 'FLO_inline',
                       'rtc' => 'FLO_inline',
                       'samp' => 'FLO_inline',
                       'var' => 'FLO_inline',
                       'cite' => 'FLO_inline',
                       'i' => 'FLO_inline',
                       'command' => 'FLO_inline',
                       'bdo' => 'FLO_inline',
                       'progress' => 'FLO_inline',
                       'ruby' => 'FLO_inline',
                       'wbr' => 'FLO_inline',
                       'dfn' => 'FLO_inline',
                       'big' => 'FLO_inline',
                       'sub' => 'FLO_inline',
                       'meter' => 'FLO_inline',
                       'button' => 'FLO_inline'
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
                       'embed' => 'FLO_inline',
                       'strike' => 'FLO_inline',
                       'input' => 'FLO_cdata',
                       'a' => 'FLO_inline',
                       'rbc' => 'FLO_inline',
                       'keygen' => 'FLO_inline',
                       'img' => 'empty',
                       'tt' => 'FLO_inline',
                       'rb' => 'FLO_inline',
                       'font' => 'FLO_inline',
                       'mark' => 'FLO_inline',
                       'map' => 'core',
                       'blink' => 'FLO_inline',
                       'u' => 'FLO_inline',
                       'abbr' => 'FLO_inline',
                       'sup' => 'FLO_inline',
                       'rt' => 'FLO_inline',
                       'basefont' => 'empty',
                       'code' => 'FLO_inline',
                       'video' => 'FLO_inline',
                       'acronym' => 'FLO_inline',
                       'br' => 'empty',
                       'strong' => 'FLO_inline',
                       's' => 'FLO_inline',
                       'output' => 'FLO_inline',
                       'em' => 'FLO_inline',
                       'q' => 'FLO_inline',
                       'b' => 'FLO_inline',
                       'span' => 'core',
                       'label' => 'FLO_inline',
                       'applet' => 'core',
                       'rp' => 'FLO_inline',
                       'kbd' => 'FLO_inline',
                       'small' => 'FLO_inline',
                       'time' => 'FLO_inline',
                       'audio' => 'FLO_inline',
                       'nobr' => 'FLO_inline',
                       'samp' => 'FLO_inline',
                       'rtc' => 'FLO_inline',
                       'var' => 'FLO_inline',
                       'cite' => 'FLO_inline',
                       'select' => 'core',
                       'command' => 'FLO_inline',
                       'i' => 'FLO_inline',
                       'bdo' => 'FLO_inline',
                       'progress' => 'FLO_inline',
                       'ruby' => 'FLO_inline',
                       'wbr' => 'FLO_inline',
                       'dfn' => 'FLO_inline',
                       'sub' => 'FLO_inline',
                       'big' => 'FLO_inline',
                       'meter' => 'FLO_inline',
                       'button' => 'FLO_inline',
                       'textarea' => 'core'
                     };
$IS_BLOCK_ELEMENT = {
                      'xmp' => 'FLO_cdata',
                      'div' => 'core',
                      'table' => 'core',
                      'pre' => 'FLO_inline',
                      'form' => 'FLO_mixed',
                      'h5' => 'FLO_inline',
                      'noframes' => 'FLO_mixed',
                      'dir' => 'core',
                      'center' => 'FLO_mixed',
                      'plaintext' => 'FLO_cdata',
                      'ol' => 'core',
                      'h6' => 'FLO_inline',
                      'address' => 'FLO_inline',
                      'ul' => 'core',
                      'h1' => 'FLO_inline',
                      'blockquote' => 'FLO_mixed',
                      'menu' => 'core',
                      'h4' => 'FLO_inline',
                      'h2' => 'FLO_inline',
                      'p' => 'core',
                      'fieldset' => 'FLO_mixed',
                      'hr' => 'empty',
                      'noscript' => 'FLO_mixed',
                      'h3' => 'FLO_inline',
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

