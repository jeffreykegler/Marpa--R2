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

# This file was generated automatically by Marpa::R2::HTML::Config
# The date of generation was Sun Nov 25 19:01:20 2012

package Marpa::R2::HTML::Internal::Config::Default;

$CORE_RULES = [
                {
                  'lhs' => 'Contents_ELE_applet',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_applet'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_colgroup',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_colgroup'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_dir',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_dir'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_dl',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_dl'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_map',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_map'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_menu',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_menu'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_object',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_object'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_ol',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_ol'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_optgroup',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_optgroup'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_select',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_select'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_table',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_table'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_tbody',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_tbody'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_tfoot',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_tfoot'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_thead',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_thead'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_tr',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_tr'
                           ]
                },
                {
                  'lhs' => 'Contents_ELE_ul',
                  'min' => 0,
                  'rhs' => [
                             'GRP_ELE_ul'
                           ]
                },
                {
                  'lhs' => 'Contents_html',
                  'rhs' => [
                             'FLO_SGML',
                             'ELE_head',
                             'FLO_SGML',
                             'ELE_body',
                             'FLO_SGML'
                           ]
                },
                {
                  'action' => 'ELE_applet',
                  'lhs' => 'ELE_applet',
                  'rhs' => [
                             'S_applet',
                             'Contents_ELE_applet',
                             'E_applet'
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
                  'action' => 'ELE_body',
                  'lhs' => 'ELE_body',
                  'rhs' => [
                             'S_body',
                             'FLO_block',
                             'E_body'
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
                  'action' => 'ELE_colgroup',
                  'lhs' => 'ELE_colgroup',
                  'rhs' => [
                             'S_colgroup',
                             'Contents_ELE_colgroup',
                             'E_colgroup'
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
                  'action' => 'ELE_dir',
                  'lhs' => 'ELE_dir',
                  'rhs' => [
                             'S_dir',
                             'Contents_ELE_dir',
                             'E_dir'
                           ]
                },
                {
                  'action' => 'ELE_dl',
                  'lhs' => 'ELE_dl',
                  'rhs' => [
                             'S_dl',
                             'Contents_ELE_dl',
                             'E_dl'
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
                  'action' => 'ELE_head',
                  'lhs' => 'ELE_head',
                  'rhs' => [
                             'S_head',
                             'FLO_head',
                             'E_head'
                           ]
                },
                {
                  'action' => 'ELE_html',
                  'lhs' => 'ELE_html',
                  'rhs' => [
                             'S_html',
                             'Contents_html',
                             'E_html'
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
                  'action' => 'ELE_map',
                  'lhs' => 'ELE_map',
                  'rhs' => [
                             'S_map',
                             'Contents_ELE_map',
                             'E_map'
                           ]
                },
                {
                  'action' => 'ELE_menu',
                  'lhs' => 'ELE_menu',
                  'rhs' => [
                             'S_menu',
                             'Contents_ELE_menu',
                             'E_menu'
                           ]
                },
                {
                  'action' => 'ELE_object',
                  'lhs' => 'ELE_object',
                  'rhs' => [
                             'S_object',
                             'Contents_ELE_object',
                             'E_object'
                           ]
                },
                {
                  'action' => 'ELE_ol',
                  'lhs' => 'ELE_ol',
                  'rhs' => [
                             'S_ol',
                             'Contents_ELE_ol',
                             'E_ol'
                           ]
                },
                {
                  'action' => 'ELE_optgroup',
                  'lhs' => 'ELE_optgroup',
                  'rhs' => [
                             'S_optgroup',
                             'Contents_ELE_optgroup',
                             'E_optgroup'
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
                  'action' => 'ELE_p',
                  'lhs' => 'ELE_p',
                  'rhs' => [
                             'S_p',
                             'FLO_inline',
                             'E_p'
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
                  'action' => 'ELE_select',
                  'lhs' => 'ELE_select',
                  'rhs' => [
                             'S_select',
                             'Contents_ELE_select',
                             'E_select'
                           ]
                },
                {
                  'action' => 'ELE_table',
                  'lhs' => 'ELE_table',
                  'rhs' => [
                             'S_table',
                             'Contents_ELE_table',
                             'E_table'
                           ]
                },
                {
                  'action' => 'ELE_tbody',
                  'lhs' => 'ELE_tbody',
                  'rhs' => [
                             'S_tbody',
                             'Contents_ELE_tbody',
                             'E_tbody'
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
                  'action' => 'ELE_tfoot',
                  'lhs' => 'ELE_tfoot',
                  'rhs' => [
                             'S_tfoot',
                             'Contents_ELE_tfoot',
                             'E_tfoot'
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
                  'action' => 'ELE_thead',
                  'lhs' => 'ELE_thead',
                  'rhs' => [
                             'S_thead',
                             'Contents_ELE_thead',
                             'E_thead'
                           ]
                },
                {
                  'action' => 'ELE_tr',
                  'lhs' => 'ELE_tr',
                  'rhs' => [
                             'S_tr',
                             'Contents_ELE_tr',
                             'E_tr'
                           ]
                },
                {
                  'action' => 'ELE_ul',
                  'lhs' => 'ELE_ul',
                  'rhs' => [
                             'S_ul',
                             'Contents_ELE_ul',
                             'E_ul'
                           ]
                },
                {
                  'lhs' => 'FLO_SGML',
                  'min' => 0,
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'FLO_block',
                  'min' => 0,
                  'rhs' => [
                             'GRP_block'
                           ]
                },
                {
                  'lhs' => 'FLO_cdata',
                  'min' => 0,
                  'rhs' => [
                             'GRP_cdata'
                           ]
                },
                {
                  'lhs' => 'FLO_empty',
                  'rhs' => []
                },
                {
                  'lhs' => 'FLO_head',
                  'min' => 0,
                  'rhs' => [
                             'GRP_head'
                           ]
                },
                {
                  'lhs' => 'FLO_inline',
                  'min' => 0,
                  'rhs' => [
                             'GRP_inline'
                           ]
                },
                {
                  'lhs' => 'FLO_mixed',
                  'min' => 0,
                  'rhs' => [
                             'GRP_mixed'
                           ]
                },
                {
                  'lhs' => 'FLO_pcdata',
                  'min' => 0,
                  'rhs' => [
                             'GRP_pcdata'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_applet',
                  'rhs' => [
                             'ELE_param'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_applet',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_applet',
                  'rhs' => [
                             'GRP_mixed'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_colgroup',
                  'rhs' => [
                             'ELE_col'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_colgroup',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_dir',
                  'rhs' => [
                             'ELE_li'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_dir',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_dl',
                  'rhs' => [
                             'ELE_dd'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_dl',
                  'rhs' => [
                             'ELE_dt'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_dl',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_map',
                  'rhs' => [
                             'ELE_area'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_map',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_map',
                  'rhs' => [
                             'GRP_block'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_menu',
                  'rhs' => [
                             'ELE_li'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_menu',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_object',
                  'rhs' => [
                             'ELE_param'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_object',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_object',
                  'rhs' => [
                             'GRP_mixed'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_ol',
                  'rhs' => [
                             'ELE_li'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_ol',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_optgroup',
                  'rhs' => [
                             'ELE_option'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_optgroup',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_select',
                  'rhs' => [
                             'ELE_optgroup'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_select',
                  'rhs' => [
                             'ELE_option'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_select',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_table',
                  'rhs' => [
                             'ELE_caption'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_table',
                  'rhs' => [
                             'ELE_col'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_table',
                  'rhs' => [
                             'ELE_colgroup'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_table',
                  'rhs' => [
                             'ELE_tbody'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_table',
                  'rhs' => [
                             'ELE_tfoot'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_table',
                  'rhs' => [
                             'ELE_thead'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_table',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_tbody',
                  'rhs' => [
                             'ELE_tr'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_tbody',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_tfoot',
                  'rhs' => [
                             'ELE_tr'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_tfoot',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_thead',
                  'rhs' => [
                             'ELE_tr'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_thead',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_tr',
                  'rhs' => [
                             'ELE_td'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_tr',
                  'rhs' => [
                             'ELE_th'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_tr',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_ul',
                  'rhs' => [
                             'ELE_li'
                           ]
                },
                {
                  'lhs' => 'GRP_ELE_ul',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_SGML',
                  'rhs' => [
                             'comment'
                           ]
                },
                {
                  'lhs' => 'GRP_SGML',
                  'rhs' => [
                             'cruft'
                           ]
                },
                {
                  'lhs' => 'GRP_SGML',
                  'rhs' => [
                             'decl'
                           ]
                },
                {
                  'lhs' => 'GRP_SGML',
                  'rhs' => [
                             'pi'
                           ]
                },
                {
                  'lhs' => 'GRP_SGML',
                  'rhs' => [
                             'whitespace'
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
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_menu'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_ol'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_p'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_table'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'ELE_ul'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_block',
                  'rhs' => [
                             'GRP_anywhere'
                           ]
                },
                {
                  'lhs' => 'GRP_cdata',
                  'rhs' => [
                             'CRUFT'
                           ]
                },
                {
                  'lhs' => 'GRP_cdata',
                  'rhs' => [
                             'cdata'
                           ]
                },
                {
                  'lhs' => 'GRP_head',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_head',
                  'rhs' => [
                             'GRP_anywhere'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'ELE_applet'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'ELE_map'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'ELE_select'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'GRP_anywhere'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'cdata'
                           ]
                },
                {
                  'lhs' => 'GRP_inline',
                  'rhs' => [
                             'pcdata'
                           ]
                },
                {
                  'lhs' => 'GRP_mixed',
                  'rhs' => [
                             'GRP_block'
                           ]
                },
                {
                  'lhs' => 'GRP_mixed',
                  'rhs' => [
                             'GRP_inline'
                           ]
                },
                {
                  'lhs' => 'GRP_pcdata',
                  'rhs' => [
                             'GRP_SGML'
                           ]
                },
                {
                  'lhs' => 'GRP_pcdata',
                  'rhs' => [
                             'cdata'
                           ]
                },
                {
                  'lhs' => 'GRP_pcdata',
                  'rhs' => [
                             'pcdata'
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
                  'action' => 'SPE_COMMENT',
                  'lhs' => 'comment',
                  'rhs' => [
                             'C'
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
                  'action' => 'SPE_DECL',
                  'lhs' => 'decl',
                  'rhs' => [
                             'D'
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
                  'action' => 'SPE_PCDATA',
                  'lhs' => 'pcdata',
                  'rhs' => [
                             'PCDATA'
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
                  'action' => 'SPE_WHITESPACE',
                  'lhs' => 'whitespace',
                  'rhs' => [
                             'WHITESPACE'
                           ]
                }
              ];
$RUNTIME_TAG = {
                 'a' => 'FLO_inline',
                 'abbr' => 'FLO_inline',
                 'acronym' => 'FLO_inline',
                 'address' => 'FLO_inline',
                 'audio' => 'FLO_inline',
                 'b' => 'FLO_inline',
                 'base' => 'FLO_empty',
                 'basefont' => 'FLO_empty',
                 'bdo' => 'FLO_inline',
                 'big' => 'FLO_inline',
                 'blink' => 'FLO_inline',
                 'blockquote' => 'FLO_mixed',
                 'br' => 'FLO_empty',
                 'button' => 'FLO_inline',
                 'center' => 'FLO_mixed',
                 'cite' => 'FLO_inline',
                 'code' => 'FLO_inline',
                 'command' => 'FLO_inline',
                 'dfn' => 'FLO_inline',
                 'div' => 'FLO_mixed',
                 'em' => 'FLO_inline',
                 'embed' => 'FLO_inline',
                 'fieldset' => 'FLO_mixed',
                 'font' => 'FLO_inline',
                 'form' => 'FLO_mixed',
                 'h1' => 'FLO_inline',
                 'h2' => 'FLO_inline',
                 'h3' => 'FLO_inline',
                 'h4' => 'FLO_inline',
                 'h5' => 'FLO_inline',
                 'h6' => 'FLO_inline',
                 'hr' => 'FLO_empty',
                 'i' => 'FLO_inline',
                 'img' => 'FLO_empty',
                 'input' => 'FLO_empty',
                 'isindex' => 'FLO_empty',
                 'kbd' => 'FLO_inline',
                 'keygen' => 'FLO_inline',
                 'label' => 'FLO_inline',
                 'link' => 'FLO_empty',
                 'mark' => 'FLO_inline',
                 'meta' => 'FLO_empty',
                 'meter' => 'FLO_inline',
                 'nobr' => 'FLO_inline',
                 'noframes' => 'FLO_mixed',
                 'noscript' => 'FLO_mixed',
                 'output' => 'FLO_inline',
                 'plaintext' => 'FLO_cdata',
                 'pre' => 'FLO_inline',
                 'progress' => 'FLO_inline',
                 'q' => 'FLO_inline',
                 'rb' => 'FLO_inline',
                 'rbc' => 'FLO_inline',
                 'rp' => 'FLO_inline',
                 'rt' => 'FLO_inline',
                 'rtc' => 'FLO_inline',
                 'ruby' => 'FLO_inline',
                 's' => 'FLO_inline',
                 'samp' => 'FLO_inline',
                 'script' => 'FLO_cdata',
                 'small' => 'FLO_inline',
                 'span' => 'FLO_inline',
                 'strike' => 'FLO_inline',
                 'strong' => 'FLO_inline',
                 'style' => 'FLO_cdata',
                 'sub' => 'FLO_inline',
                 'sup' => 'FLO_inline',
                 'textarea' => 'FLO_cdata',
                 'time' => 'FLO_inline',
                 'title' => 'FLO_pcdata',
                 'tt' => 'FLO_inline',
                 'u' => 'FLO_inline',
                 'var' => 'FLO_inline',
                 'video' => 'FLO_inline',
                 'wbr' => 'FLO_inline',
                 'xmp' => 'FLO_cdata'
               };
$RUBY_SLIPPERS_RANK_BY_NAME = {
                                '<!element>' => {
                                                  '</*>' => 1
                                                },
                                '<%head>' => {
                                               '</*>' => 1,
                                               'S_head' => 2,
                                               'S_html' => 3
                                             },
                                '<%inline>' => {
                                                 '</*>' => 1,
                                                 'S_body' => 6,
                                                 'S_head' => 7,
                                                 'S_html' => 8,
                                                 'S_p' => 2,
                                                 'S_tbody' => 5,
                                                 'S_td' => 3,
                                                 'S_tr' => 4
                                               },
                                '<*>' => {
                                           '</*>' => 1,
                                           'S_body' => 2,
                                           'S_head' => 3,
                                           'S_html' => 4
                                         },
                                '</*>' => {
                                            '</*>' => 1
                                          },
                                'CDATA' => {
                                             '</*>' => 1,
                                             'S_body' => 6,
                                             'S_head' => 7,
                                             'S_html' => 8,
                                             'S_p' => 2,
                                             'S_tbody' => 5,
                                             'S_td' => 3,
                                             'S_tr' => 4
                                           },
                                'EOF' => {
                                           '</*>' => 3,
                                           'E_body' => 2,
                                           'E_html' => 1,
                                           'S_body' => 4,
                                           'S_head' => 5,
                                           'S_html' => 6
                                         },
                                'E_body' => {
                                              '</*>' => 1,
                                              'S_body' => 2,
                                              'S_head' => 3,
                                              'S_html' => 4
                                            },
                                'E_html' => {
                                              '</*>' => 2,
                                              'E_body' => 1,
                                              'S_body' => 3,
                                              'S_head' => 4,
                                              'S_html' => 5
                                            },
                                'E_table' => {
                                               '</*>' => 2,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_table' => 1
                                             },
                                'PCDATA' => {
                                              '</*>' => 1,
                                              'S_body' => 6,
                                              'S_head' => 7,
                                              'S_html' => 8,
                                              'S_p' => 2,
                                              'S_tbody' => 5,
                                              'S_td' => 3,
                                              'S_tr' => 4
                                            },
                                'S_area' => {
                                              '</*>' => 1,
                                              'S_body' => 3,
                                              'S_head' => 4,
                                              'S_html' => 5,
                                              'S_map' => 2
                                            },
                                'S_body' => {
                                              '</*>' => 1,
                                              'S_head' => 2,
                                              'S_html' => 3
                                            },
                                'S_caption' => {
                                                 '</*>' => 2,
                                                 'S_body' => 3,
                                                 'S_head' => 4,
                                                 'S_html' => 5,
                                                 'S_table' => 1
                                               },
                                'S_col' => {
                                             '</*>' => 2,
                                             'S_body' => 3,
                                             'S_head' => 4,
                                             'S_html' => 5,
                                             'S_table' => 1
                                           },
                                'S_colgroup' => {
                                                  '</*>' => 2,
                                                  'S_body' => 3,
                                                  'S_head' => 4,
                                                  'S_html' => 5,
                                                  'S_table' => 1
                                                },
                                'S_dd' => {
                                            '</*>' => 1,
                                            'S_body' => 3,
                                            'S_dl' => 2,
                                            'S_head' => 4,
                                            'S_html' => 5
                                          },
                                'S_dt' => {
                                            '</*>' => 1,
                                            'S_body' => 3,
                                            'S_dl' => 2,
                                            'S_head' => 4,
                                            'S_html' => 5
                                          },
                                'S_head' => {
                                              '</*>' => 1,
                                              'S_html' => 2
                                            },
                                'S_html' => {
                                              '</*>' => 1
                                            },
                                'S_li' => {
                                            '</*>' => 2,
                                            'S_body' => 3,
                                            'S_head' => 4,
                                            'S_html' => 5,
                                            'S_ul' => 1
                                          },
                                'S_optgroup' => {
                                                  '</*>' => 1,
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
                                                '</*>' => 1,
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
                                               '</*>' => 1,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_object' => 2
                                             },
                                'S_tbody' => {
                                               '</*>' => 2,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_table' => 1
                                             },
                                'S_td' => {
                                            '</*>' => 2,
                                            'S_body' => 5,
                                            'S_head' => 6,
                                            'S_html' => 7,
                                            'S_table' => 1,
                                            'S_tbody' => 4,
                                            'S_tr' => 3
                                          },
                                'S_tfoot' => {
                                               '</*>' => 2,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_table' => 1
                                             },
                                'S_th' => {
                                            '</*>' => 2,
                                            'S_body' => 6,
                                            'S_head' => 7,
                                            'S_html' => 8,
                                            'S_table' => 1,
                                            'S_tbody' => 4,
                                            'S_thead' => 5,
                                            'S_tr' => 3
                                          },
                                'S_thead' => {
                                               '</*>' => 2,
                                               'S_body' => 3,
                                               'S_head' => 4,
                                               'S_html' => 5,
                                               'S_table' => 1
                                             },
                                'S_tr' => {
                                            '</*>' => 2,
                                            'S_body' => 4,
                                            'S_head' => 5,
                                            'S_html' => 6,
                                            'S_table' => 1,
                                            'S_tbody' => 3
                                          }
                              };
$IS_EMPTY_ELEMENT = {
                      'area' => 1,
                      'base' => 1,
                      'basefont' => 1,
                      'br' => 1,
                      'col' => 1,
                      'hr' => 1,
                      'img' => 1,
                      'input' => 1,
                      'isindex' => 1,
                      'link' => 1,
                      'meta' => 1,
                      'param' => 1
                    };
$PRIMARY_GROUP_BY_TAG = {
                          'a' => 'GRP_inline',
                          'abbr' => 'GRP_inline',
                          'acronym' => 'GRP_inline',
                          'address' => 'GRP_block',
                          'applet' => 'GRP_inline',
                          'audio' => 'GRP_inline',
                          'b' => 'GRP_inline',
                          'base' => 'GRP_head',
                          'basefont' => 'GRP_inline',
                          'bdo' => 'GRP_inline',
                          'big' => 'GRP_inline',
                          'blink' => 'GRP_inline',
                          'blockquote' => 'GRP_block',
                          'br' => 'GRP_inline',
                          'button' => 'GRP_inline',
                          'center' => 'GRP_block',
                          'cite' => 'GRP_inline',
                          'code' => 'GRP_inline',
                          'command' => 'GRP_inline',
                          'dfn' => 'GRP_inline',
                          'dir' => 'GRP_block',
                          'div' => 'GRP_block',
                          'dl' => 'GRP_block',
                          'em' => 'GRP_inline',
                          'embed' => 'GRP_inline',
                          'fieldset' => 'GRP_block',
                          'font' => 'GRP_inline',
                          'form' => 'GRP_block',
                          'h1' => 'GRP_block',
                          'h2' => 'GRP_block',
                          'h3' => 'GRP_block',
                          'h4' => 'GRP_block',
                          'h5' => 'GRP_block',
                          'h6' => 'GRP_block',
                          'hr' => 'GRP_block',
                          'i' => 'GRP_inline',
                          'img' => 'GRP_inline',
                          'input' => 'GRP_inline',
                          'isindex' => 'GRP_anywhere',
                          'kbd' => 'GRP_inline',
                          'keygen' => 'GRP_inline',
                          'label' => 'GRP_inline',
                          'link' => 'GRP_head',
                          'map' => 'GRP_inline',
                          'mark' => 'GRP_inline',
                          'menu' => 'GRP_block',
                          'meta' => 'GRP_head',
                          'meter' => 'GRP_inline',
                          'nobr' => 'GRP_inline',
                          'noframes' => 'GRP_block',
                          'noscript' => 'GRP_block',
                          'object' => 'GRP_anywhere',
                          'ol' => 'GRP_block',
                          'output' => 'GRP_inline',
                          'p' => 'GRP_block',
                          'plaintext' => 'GRP_block',
                          'pre' => 'GRP_block',
                          'progress' => 'GRP_inline',
                          'q' => 'GRP_inline',
                          'rb' => 'GRP_inline',
                          'rbc' => 'GRP_inline',
                          'rp' => 'GRP_inline',
                          'rt' => 'GRP_inline',
                          'rtc' => 'GRP_inline',
                          'ruby' => 'GRP_inline',
                          's' => 'GRP_inline',
                          'samp' => 'GRP_inline',
                          'script' => 'GRP_anywhere',
                          'select' => 'GRP_inline',
                          'small' => 'GRP_inline',
                          'span' => 'GRP_inline',
                          'strike' => 'GRP_inline',
                          'strong' => 'GRP_inline',
                          'style' => 'GRP_head',
                          'sub' => 'GRP_inline',
                          'sup' => 'GRP_inline',
                          'table' => 'GRP_block',
                          'textarea' => 'GRP_anywhere',
                          'time' => 'GRP_inline',
                          'title' => 'GRP_head',
                          'tt' => 'GRP_inline',
                          'u' => 'GRP_inline',
                          'ul' => 'GRP_block',
                          'var' => 'GRP_inline',
                          'video' => 'GRP_inline',
                          'wbr' => 'GRP_inline',
                          'xmp' => 'GRP_block'
                        };
