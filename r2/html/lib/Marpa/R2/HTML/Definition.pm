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

# This file was generated automatically by mk_definition.pl
# The date of generation was Sun Oct  7 09:15:31 2012

package Marpa::R2::HTML::Internal;

$CORE_RULES = [
                {
                  'action' => 'SPE_COMMENT',
                  'lhs' => 'comment',
                  'rhs' => [
                             'C'
                           ]
                },
                {
                  'action' => 'SPE_PI',
                  'lhs' => 'pi',
                  'rhs' => [
                             'PI'
                           ]
                },
                {
                  'action' => 'SPE_DECL',
                  'lhs' => 'decl',
                  'rhs' => [
                             'D'
                           ]
                },
                {
                  'action' => 'SPE_PCDATA',
                  'lhs' => 'pcdata',
                  'rhs' => [
                             'PCDATA'
                           ]
                },
                {
                  'action' => 'SPE_CDATA',
                  'lhs' => 'cdata',
                  'rhs' => [
                             'CDATA'
                           ]
                },
                {
                  'action' => 'SPE_WHITESPACE',
                  'lhs' => 'whitespace',
                  'rhs' => [
                             'WHITESPACE'
                           ]
                },
                {
                  'action' => 'SPE_CRUFT',
                  'lhs' => 'cruft',
                  'rhs' => [
                             'CRUFT'
                           ]
                },
                {
                  'lhs' => 'FLO_SGML',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'lhs' => 'ITEM_SGML',
                  'rhs' => [
                             'comment'
                           ]
                },
                {
                  'lhs' => 'ITEM_SGML',
                  'rhs' => [
                             'pi'
                           ]
                },
                {
                  'lhs' => 'ITEM_SGML',
                  'rhs' => [
                             'decl'
                           ]
                },
                {
                  'lhs' => 'ITEM_SGML',
                  'rhs' => [
                             'whitespace'
                           ]
                },
                {
                  'lhs' => 'ITEM_SGML',
                  'rhs' => [
                             'cruft'
                           ]
                },
                {
                  'action' => 'SPE_TOP',
                  'lhs' => 'document',
                  'rhs' => [
                             'prolog',
                             'ELE_html',
                             'trailer',
                             'EOF'
                           ]
                },
                {
                  'action' => 'SPE_PROLOG',
                  'lhs' => 'prolog',
                  'rhs' => [
                             'FLO_SGML'
                           ]
                },
                {
                  'action' => 'SPE_TRAILER',
                  'lhs' => 'trailer',
                  'rhs' => [
                             'FLO_SGML'
                           ]
                },
                {
                  'action' => 'ELE_html',
                  'lhs' => 'ELE_html',
                  'rhs' => [
                             'S_html',
                             'EC_html',
                             'E_html'
                           ]
                },
                {
                  'lhs' => 'EC_html',
                  'rhs' => [
                             'FLO_SGML',
                             'ELE_head',
                             'FLO_SGML',
                             'ELE_body',
                             'FLO_SGML'
                           ]
                },
                {
                  'action' => 'ELE_head',
                  'lhs' => 'ELE_head',
                  'rhs' => [
                             'S_head',
                             'FLO_head',
                             'E_head'
                           ]
                },
                {
                  'action' => 'ELE_body',
                  'lhs' => 'ELE_body',
                  'rhs' => [
                             'S_body',
                             'FLO_block',
                             'E_body'
                           ]
                },
                {
                  'lhs' => 'FLO_empty',
                  'rhs' => []
                },
                {
                  'lhs' => 'FLO_cdata',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_cdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_cdata',
                  'rhs' => [
                             'cdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_cdata',
                  'rhs' => [
                             'CRUFT'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'ELE_applet'
                           ]
                },
                {
                  'action' => 'ELE_area',
                  'lhs' => 'ELE_area',
                  'rhs' => [
                             'S_area',
                             'FLO_empty',
                             'E_area'
                           ]
                },
                {
                  'action' => 'ELE_caption',
                  'lhs' => 'ELE_caption',
                  'rhs' => [
                             'S_caption',
                             'FLO_inline',
                             'E_caption'
                           ]
                },
                {
                  'action' => 'ELE_col',
                  'lhs' => 'ELE_col',
                  'rhs' => [
                             'S_col',
                             'FLO_empty',
                             'E_col'
                           ]
                },
                {
                  'action' => 'ELE_dd',
                  'lhs' => 'ELE_dd',
                  'rhs' => [
                             'S_dd',
                             'FLO_mixed',
                             'E_dd'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_dir'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_dl'
                           ]
                },
                {
                  'action' => 'ELE_dt',
                  'lhs' => 'ELE_dt',
                  'rhs' => [
                             'S_dt',
                             'FLO_inline',
                             'E_dt'
                           ]
                },
                {
                  'action' => 'ELE_li',
                  'lhs' => 'ELE_li',
                  'rhs' => [
                             'S_li',
                             'FLO_mixed',
                             'E_li'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'ELE_map'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_menu'
                           ]
                },
                {
                  'lhs' => 'GRP_anywhere',
                  'rhs' => [
                             'ELE_object'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_ol'
                           ]
                },
                {
                  'action' => 'ELE_option',
                  'lhs' => 'ELE_option',
                  'rhs' => [
                             'S_option',
                             'FLO_pcdata',
                             'E_option'
                           ]
                },
                {
                  'action' => 'ELE_param',
                  'lhs' => 'ELE_param',
                  'rhs' => [
                             'S_param',
                             'FLO_empty',
                             'E_param'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'ELE_select'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_table'
                           ]
                },
                {
                  'action' => 'ELE_td',
                  'lhs' => 'ELE_td',
                  'rhs' => [
                             'S_td',
                             'FLO_mixed',
                             'E_td'
                           ]
                },
                {
                  'action' => 'ELE_th',
                  'lhs' => 'ELE_th',
                  'rhs' => [
                             'S_th',
                             'FLO_mixed',
                             'E_th'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_ul'
                           ]
                },
                {
                  'action' => 'ELE_optgroup',
                  'lhs' => 'ELE_optgroup',
                  'rhs' => [
                             'S_optgroup',
                             '_C_ELE_optgroup',
                             'E_optgroup'
                           ]
                },
                {
                  'lhs' => '_C_ELE_optgroup',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_optgroup'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_optgroup',
                  'rhs' => [
                             'ELE_option'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_optgroup',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_table',
                  'lhs' => 'ELE_table',
                  'rhs' => [
                             'S_table',
                             '_C_ELE_table',
                             'E_table'
                           ]
                },
                {
                  'lhs' => '_C_ELE_table',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_table'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_table',
                  'rhs' => [
                             'ELE_caption'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_table',
                  'rhs' => [
                             'ELE_col'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_table',
                  'rhs' => [
                             'ELE_colgroup'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_table',
                  'rhs' => [
                             'ELE_tbody'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_table',
                  'rhs' => [
                             'ELE_tfoot'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_table',
                  'rhs' => [
                             'ELE_thead'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_table',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_menu',
                  'lhs' => 'ELE_menu',
                  'rhs' => [
                             'S_menu',
                             '_C_ELE_menu',
                             'E_menu'
                           ]
                },
                {
                  'lhs' => '_C_ELE_menu',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_menu'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_menu',
                  'rhs' => [
                             'ELE_li'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_menu',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_tr',
                  'lhs' => 'ELE_tr',
                  'rhs' => [
                             'S_tr',
                             '_C_ELE_tr',
                             'E_tr'
                           ]
                },
                {
                  'lhs' => '_C_ELE_tr',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_tr'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_tr',
                  'rhs' => [
                             'ELE_th'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_tr',
                  'rhs' => [
                             'ELE_td'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_tr',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_dl',
                  'lhs' => 'ELE_dl',
                  'rhs' => [
                             'S_dl',
                             '_C_ELE_dl',
                             'E_dl'
                           ]
                },
                {
                  'lhs' => '_C_ELE_dl',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_dl'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_dl',
                  'rhs' => [
                             'ELE_dt'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_dl',
                  'rhs' => [
                             'ELE_dd'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_dl',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_applet',
                  'lhs' => 'ELE_applet',
                  'rhs' => [
                             'S_applet',
                             '_C_ELE_applet',
                             'E_applet'
                           ]
                },
                {
                  'lhs' => '_C_ELE_applet',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_applet'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_applet',
                  'rhs' => [
                             'ELE_param'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_applet',
                  'rhs' => [
                             'ITEM_mixed'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_applet',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_map',
                  'lhs' => 'ELE_map',
                  'rhs' => [
                             'S_map',
                             '_C_ELE_map',
                             'E_map'
                           ]
                },
                {
                  'lhs' => '_C_ELE_map',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_map'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_map',
                  'rhs' => [
                             'GRP_block'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_map',
                  'rhs' => [
                             'ELE_area'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_map',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_ol',
                  'lhs' => 'ELE_ol',
                  'rhs' => [
                             'S_ol',
                             '_C_ELE_ol',
                             'E_ol'
                           ]
                },
                {
                  'lhs' => '_C_ELE_ol',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_ol'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_ol',
                  'rhs' => [
                             'ELE_li'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_ol',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_tbody',
                  'lhs' => 'ELE_tbody',
                  'rhs' => [
                             'S_tbody',
                             '_C_ELE_tbody',
                             'E_tbody'
                           ]
                },
                {
                  'lhs' => '_C_ELE_tbody',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_tbody'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_tbody',
                  'rhs' => [
                             'ELE_tr'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_tbody',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_ul',
                  'lhs' => 'ELE_ul',
                  'rhs' => [
                             'S_ul',
                             '_C_ELE_ul',
                             'E_ul'
                           ]
                },
                {
                  'lhs' => '_C_ELE_ul',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_ul'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_ul',
                  'rhs' => [
                             'ELE_li'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_ul',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_dir',
                  'lhs' => 'ELE_dir',
                  'rhs' => [
                             'S_dir',
                             '_C_ELE_dir',
                             'E_dir'
                           ]
                },
                {
                  'lhs' => '_C_ELE_dir',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_dir'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_dir',
                  'rhs' => [
                             'ELE_li'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_dir',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_object',
                  'lhs' => 'ELE_object',
                  'rhs' => [
                             'S_object',
                             '_C_ELE_object',
                             'E_object'
                           ]
                },
                {
                  'lhs' => '_C_ELE_object',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_object'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_object',
                  'rhs' => [
                             'ELE_param'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_object',
                  'rhs' => [
                             'ITEM_mixed'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_object',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_tfoot',
                  'lhs' => 'ELE_tfoot',
                  'rhs' => [
                             'S_tfoot',
                             '_C_ELE_tfoot',
                             'E_tfoot'
                           ]
                },
                {
                  'lhs' => '_C_ELE_tfoot',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_tfoot'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_tfoot',
                  'rhs' => [
                             'ELE_tr'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_tfoot',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_colgroup',
                  'lhs' => 'ELE_colgroup',
                  'rhs' => [
                             'S_colgroup',
                             '_C_ELE_colgroup',
                             'E_colgroup'
                           ]
                },
                {
                  'lhs' => '_C_ELE_colgroup',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_colgroup'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_colgroup',
                  'rhs' => [
                             'ELE_col'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_colgroup',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_thead',
                  'lhs' => 'ELE_thead',
                  'rhs' => [
                             'S_thead',
                             '_C_ELE_thead',
                             'E_thead'
                           ]
                },
                {
                  'lhs' => '_C_ELE_thead',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_thead'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_thead',
                  'rhs' => [
                             'ELE_tr'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_thead',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_select',
                  'lhs' => 'ELE_select',
                  'rhs' => [
                             'S_select',
                             '_C_ELE_select',
                             'E_select'
                           ]
                },
                {
                  'lhs' => '_C_ELE_select',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_ELE_select'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_select',
                  'rhs' => [
                             'ELE_optgroup'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_select',
                  'rhs' => [
                             'ELE_option'
                           ]
                },
                {
                  'lhs' => 'ITEM_ELE_select',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'lhs' => 'FLO_pcdata',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_pcdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_pcdata',
                  'rhs' => [
                             'cdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_pcdata',
                  'rhs' => [
                             'pcdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_pcdata',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'lhs' => 'FLO_inline',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_inline'
                           ]
                },
                {
                  'lhs' => 'ITEM_inline',
                  'rhs' => [
                             'pcdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_inline',
                  'rhs' => [
                             'cdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_inline',
                  'rhs' => [
                             'GRP_inline'
                           ]
                },
                {
                  'lhs' => 'ITEM_inline',
                  'rhs' => [
                             'GRP_anywhere'
                           ]
                },
                {
                  'lhs' => 'ITEM_inline',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'lhs' => 'FLO_head',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_head'
                           ]
                },
                {
                  'lhs' => 'ITEM_head',
                  'rhs' => [
                             'GRP_head'
                           ]
                },
                {
                  'lhs' => 'ITEM_head',
                  'rhs' => [
                             'GRP_anywhere'
                           ]
                },
                {
                  'lhs' => 'ITEM_head',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'lhs' => 'FLO_mixed',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_mixed'
                           ]
                },
                {
                  'lhs' => 'ITEM_mixed',
                  'rhs' => [
                             'GRP_anywhere'
                           ]
                },
                {
                  'lhs' => 'ITEM_mixed',
                  'rhs' => [
                             'GRP_block'
                           ]
                },
                {
                  'lhs' => 'ITEM_mixed',
                  'rhs' => [
                             'GRP_inline'
                           ]
                },
                {
                  'lhs' => 'ITEM_mixed',
                  'rhs' => [
                             'cdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_mixed',
                  'rhs' => [
                             'pcdata'
                           ]
                },
                {
                  'lhs' => 'ITEM_mixed',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'lhs' => 'FLO_block',
                  'min' => 0,
                  'rhs' => [
                             'ITEM_block'
                           ]
                },
                {
                  'lhs' => 'ITEM_block',
                  'rhs' => [
                             'GRP_block'
                           ]
                },
                {
                  'lhs' => 'ITEM_block',
                  'rhs' => [
                             'GRP_anywhere'
                           ]
                },
                {
                  'lhs' => 'ITEM_block',
                  'rhs' => [
                             'ITEM_SGML'
                           ]
                },
                {
                  'action' => 'ELE_p',
                  'lhs' => 'ELE_p',
                  'rhs' => [
                             'S_p',
                             'FLO_inline',
                             'E_p'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_p'
                           ]
                }
              ];
$TAG_DESCRIPTOR = {
                    'a' => [
                             'GRP_inline',
                             'FLO_inline'
                           ],
                    'abbr' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'acronym' => [
                                   'GRP_inline',
                                   'FLO_inline'
                                 ],
                    'address' => [
                                   'GRP_block',
                                   'FLO_inline'
                                 ],
                    'audio' => [
                                 'GRP_inline',
                                 'FLO_inline'
                               ],
                    'b' => [
                             'GRP_inline',
                             'FLO_inline'
                           ],
                    'base' => [
                                'GRP_head',
                                'FLO_empty'
                              ],
                    'basefont' => [
                                    'GRP_inline',
                                    'FLO_empty'
                                  ],
                    'bdo' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'big' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'blink' => [
                                 'GRP_inline',
                                 'FLO_inline'
                               ],
                    'blockquote' => [
                                      'GRP_block',
                                      'FLO_mixed'
                                    ],
                    'br' => [
                              'GRP_inline',
                              'FLO_empty'
                            ],
                    'button' => [
                                  'GRP_inline',
                                  'FLO_inline'
                                ],
                    'center' => [
                                  'GRP_block',
                                  'FLO_mixed'
                                ],
                    'cite' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'code' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'command' => [
                                   'GRP_inline',
                                   'FLO_inline'
                                 ],
                    'dfn' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'div' => [
                               'GRP_block',
                               'FLO_mixed'
                             ],
                    'em' => [
                              'GRP_inline',
                              'FLO_inline'
                            ],
                    'embed' => [
                                 'GRP_inline',
                                 'FLO_inline'
                               ],
                    'fieldset' => [
                                    'GRP_block',
                                    'FLO_mixed'
                                  ],
                    'font' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'form' => [
                                'GRP_block',
                                'FLO_mixed'
                              ],
                    'h1' => [
                              'GRP_block',
                              'FLO_inline'
                            ],
                    'h2' => [
                              'GRP_block',
                              'FLO_inline'
                            ],
                    'h3' => [
                              'GRP_block',
                              'FLO_inline'
                            ],
                    'h4' => [
                              'GRP_block',
                              'FLO_inline'
                            ],
                    'h5' => [
                              'GRP_block',
                              'FLO_inline'
                            ],
                    'h6' => [
                              'GRP_block',
                              'FLO_inline'
                            ],
                    'hr' => [
                              'GRP_block',
                              'FLO_empty'
                            ],
                    'i' => [
                             'GRP_inline',
                             'FLO_inline'
                           ],
                    'img' => [
                               'GRP_inline',
                               'FLO_empty'
                             ],
                    'input' => [
                                 'GRP_inline',
                                 'FLO_empty'
                               ],
                    'isindex' => [
                                   'GRP_anywhere',
                                   'FLO_empty'
                                 ],
                    'kbd' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'keygen' => [
                                  'GRP_inline',
                                  'FLO_inline'
                                ],
                    'label' => [
                                 'GRP_inline',
                                 'FLO_inline'
                               ],
                    'link' => [
                                'GRP_head',
                                'FLO_empty'
                              ],
                    'mark' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'meta' => [
                                'GRP_head',
                                'FLO_empty'
                              ],
                    'meter' => [
                                 'GRP_inline',
                                 'FLO_inline'
                               ],
                    'nobr' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'noframes' => [
                                    'GRP_block',
                                    'FLO_mixed'
                                  ],
                    'noscript' => [
                                    'GRP_block',
                                    'FLO_mixed'
                                  ],
                    'output' => [
                                  'GRP_inline',
                                  'FLO_inline'
                                ],
                    'plaintext' => [
                                     'GRP_block',
                                     'FLO_cdata'
                                   ],
                    'pre' => [
                               'GRP_block',
                               'FLO_inline'
                             ],
                    'progress' => [
                                    'GRP_inline',
                                    'FLO_inline'
                                  ],
                    'q' => [
                             'GRP_inline',
                             'FLO_inline'
                           ],
                    'rb' => [
                              'GRP_inline',
                              'FLO_inline'
                            ],
                    'rbc' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'rp' => [
                              'GRP_inline',
                              'FLO_inline'
                            ],
                    'rt' => [
                              'GRP_inline',
                              'FLO_inline'
                            ],
                    'rtc' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'ruby' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    's' => [
                             'GRP_inline',
                             'FLO_inline'
                           ],
                    'samp' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'script' => [
                                  'GRP_anywhere',
                                  'FLO_cdata'
                                ],
                    'small' => [
                                 'GRP_inline',
                                 'FLO_inline'
                               ],
                    'span' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'strike' => [
                                  'GRP_inline',
                                  'FLO_inline'
                                ],
                    'strong' => [
                                  'GRP_inline',
                                  'FLO_inline'
                                ],
                    'style' => [
                                 'GRP_head',
                                 'FLO_cdata'
                               ],
                    'sub' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'sup' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'textarea' => [
                                    'GRP_anywhere',
                                    'FLO_cdata'
                                  ],
                    'time' => [
                                'GRP_inline',
                                'FLO_inline'
                              ],
                    'title' => [
                                 'GRP_head',
                                 'FLO_pcdata'
                               ],
                    'tt' => [
                              'GRP_inline',
                              'FLO_inline'
                            ],
                    'u' => [
                             'GRP_inline',
                             'FLO_inline'
                           ],
                    'var' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'video' => [
                                 'GRP_inline',
                                 'FLO_inline'
                               ],
                    'wbr' => [
                               'GRP_inline',
                               'FLO_inline'
                             ],
                    'xmp' => [
                               'GRP_block',
                               'FLO_cdata'
                             ]
                  };
$RUBY_SLIPPERS_RANK_BY_NAME = {
                                '!end_tag' => {
                                                '!non_final_end' => 1
                                              },
                                '!head_start_tag' => {
                                                       '!non_final_end' => 1,
                                                       'S_head' => 2,
                                                       'S_html' => 3
                                                     },
                                '!inline_start_tag' => {
                                                         '!non_final_end' => 1,
                                                         'S_body' => 6,
                                                         'S_head' => 7,
                                                         'S_html' => 8,
                                                         'S_p' => 2,
                                                         'S_tbody' => 5,
                                                         'S_td' => 3,
                                                         'S_tr' => 4
                                                       },
                                '!non_element' => {
                                                    '!non_final_end' => 1
                                                  },
                                '!start_tag' => {
                                                  '!non_final_end' => 1,
                                                  'S_body' => 2,
                                                  'S_head' => 3,
                                                  'S_html' => 4
                                                },
                                'CDATA' => {
                                             '!non_final_end' => 1,
                                             'S_body' => 6,
                                             'S_head' => 7,
                                             'S_html' => 8,
                                             'S_p' => 2,
                                             'S_tbody' => 5,
                                             'S_td' => 3,
                                             'S_tr' => 4
                                           },
                                'EOF' => {
                                           '!non_final_end' => 3,
                                           'E_body' => 2,
                                           'E_html' => 1,
                                           'S_body' => 4,
                                           'S_head' => 5,
                                           'S_html' => 6
                                         },
                                'E_body' => {
                                              '!non_final_end' => 1,
                                              'S_body' => 2,
                                              'S_head' => 3,
                                              'S_html' => 4
                                            },
                                'E_html' => {
                                              '!non_final_end' => 2,
                                              'E_body' => 1,
                                              'S_body' => 3,
                                              'S_head' => 4,
                                              'S_html' => 5
                                            },
                                'E_table' => {
                                               '!non_final_end' => 2,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_table' => 1
                                             },
                                'PCDATA' => {
                                              '!non_final_end' => 1,
                                              'S_body' => 6,
                                              'S_head' => 7,
                                              'S_html' => 8,
                                              'S_p' => 2,
                                              'S_tbody' => 5,
                                              'S_td' => 3,
                                              'S_tr' => 4
                                            },
                                'S_area' => {
                                              '!non_final_end' => 1,
                                              'S_body' => 3,
                                              'S_head' => 4,
                                              'S_html' => 5,
                                              'S_map' => 2
                                            },
                                'S_body' => {
                                              '!non_final_end' => 1,
                                              'S_head' => 2,
                                              'S_html' => 3
                                            },
                                'S_caption' => {
                                                 '!non_final_end' => 2,
                                                 'S_body' => 3,
                                                 'S_head' => 4,
                                                 'S_html' => 5,
                                                 'S_table' => 1
                                               },
                                'S_col' => {
                                             '!non_final_end' => 2,
                                             'S_body' => 3,
                                             'S_head' => 4,
                                             'S_html' => 5,
                                             'S_table' => 1
                                           },
                                'S_colgroup' => {
                                                  '!non_final_end' => 2,
                                                  'S_body' => 3,
                                                  'S_head' => 4,
                                                  'S_html' => 5,
                                                  'S_table' => 1
                                                },
                                'S_dd' => {
                                            '!non_final_end' => 1,
                                            'S_body' => 3,
                                            'S_dl' => 2,
                                            'S_head' => 4,
                                            'S_html' => 5
                                          },
                                'S_dt' => {
                                            '!non_final_end' => 1,
                                            'S_body' => 3,
                                            'S_dl' => 2,
                                            'S_head' => 4,
                                            'S_html' => 5
                                          },
                                'S_head' => {
                                              '!non_final_end' => 1,
                                              'S_html' => 2
                                            },
                                'S_html' => {
                                              '!non_final_end' => 1
                                            },
                                'S_li' => {
                                            '!non_final_end' => 2,
                                            'S_body' => 3,
                                            'S_head' => 4,
                                            'S_html' => 5,
                                            'S_ul' => 1
                                          },
                                'S_optgroup' => {
                                                  '!non_final_end' => 1,
                                                  'S_body' => 7,
                                                  'S_head' => 8,
                                                  'S_html' => 9,
                                                  'S_p' => 3,
                                                  'S_select' => 2,
                                                  'S_tbody' => 6,
                                                  'S_td' => 4,
                                                  'S_tr' => 5
                                                },
                                'S_option' => {
                                                '!non_final_end' => 1,
                                                'S_body' => 7,
                                                'S_head' => 8,
                                                'S_html' => 9,
                                                'S_p' => 3,
                                                'S_select' => 2,
                                                'S_tbody' => 6,
                                                'S_td' => 4,
                                                'S_tr' => 5
                                              },
                                'S_param' => {
                                               '!non_final_end' => 1,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_object' => 2
                                             },
                                'S_tbody' => {
                                               '!non_final_end' => 2,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_table' => 1
                                             },
                                'S_td' => {
                                            '!non_final_end' => 2,
                                            'S_body' => 5,
                                            'S_head' => 6,
                                            'S_html' => 7,
                                            'S_table' => 1,
                                            'S_tbody' => 4,
                                            'S_tr' => 3
                                          },
                                'S_tfoot' => {
                                               '!non_final_end' => 2,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_table' => 1
                                             },
                                'S_th' => {
                                            '!non_final_end' => 2,
                                            'S_body' => 6,
                                            'S_head' => 7,
                                            'S_html' => 8,
                                            'S_table' => 1,
                                            'S_tbody' => 4,
                                            'S_thead' => 5,
                                            'S_tr' => 3
                                          },
                                'S_thead' => {
                                               '!non_final_end' => 2,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_table' => 1
                                             },
                                'S_tr' => {
                                            '!non_final_end' => 2,
                                            'S_body' => 4,
                                            'S_head' => 5,
                                            'S_html' => 6,
                                            'S_table' => 1,
                                            'S_tbody' => 3
                                          }
                              };

