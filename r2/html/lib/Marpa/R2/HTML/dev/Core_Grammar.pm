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
# The date of generation was Tue Oct  2 17:59:04 2012

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
                             'block_specific_element'
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
                  'lhs' => 'block_specific_element'
                },
                {
                  'rhs' => [
                             'ELE_p'
                           ],
                  'lhs' => 'block_specific_element'
                },
                {
                  'rhs' => [
                             'ELE_ol'
                           ],
                  'lhs' => 'block_specific_element'
                },
                {
                  'rhs' => [
                             'ELE_ul'
                           ],
                  'lhs' => 'block_specific_element'
                },
                {
                  'rhs' => [
                             'ELE_dl'
                           ],
                  'lhs' => 'block_specific_element'
                },
                {
                  'rhs' => [
                             'ELE_script'
                           ],
                  'lhs' => 'inline_element'
                },
                {
                  'rhs' => [
                             'inline_specific_element'
                           ],
                  'lhs' => 'inline_element'
                },
                {
                  'rhs' => [
                             'ELE_object'
                           ],
                  'lhs' => 'inline_specific_element'
                },
                {
                  'rhs' => [
                             'ELE_select'
                           ],
                  'lhs' => 'inline_specific_element'
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
                  'rhs' => [
                             'S_ul',
                             'EC_ul',
                             'E_ul'
                           ],
                  'lhs' => 'ELE_ul',
                  'action' => 'ELE_ul'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_ul'
                           ],
                  'lhs' => 'EC_ul'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_ul'
                },
                {
                  'rhs' => [
                             'ELE_li'
                           ],
                  'lhs' => 'EI_ul'
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
                  'min' => 0,
                  'rhs' => [
                             'EI_tr'
                           ],
                  'lhs' => 'EC_tr'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
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
                             'ELE_td'
                           ],
                  'lhs' => 'EI_tr'
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
                  'min' => 0,
                  'rhs' => [
                             'EI_object'
                           ],
                  'lhs' => 'EC_object'
                },
                {
                  'rhs' => [
                             'ELE_param'
                           ],
                  'lhs' => 'EI_object'
                },
                {
                  'rhs' => [
                             'mixed_flow_item'
                           ],
                  'lhs' => 'EI_object'
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
                             'EI_head'
                           ],
                  'lhs' => 'EC_head'
                },
                {
                  'rhs' => [
                             'head_item'
                           ],
                  'lhs' => 'EI_head'
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
                  'min' => 0,
                  'rhs' => [
                             'EI_tbody'
                           ],
                  'lhs' => 'EC_tbody'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_tbody'
                },
                {
                  'rhs' => [
                             'ELE_tr'
                           ],
                  'lhs' => 'EI_tbody'
                },
                {
                  'rhs' => [
                             'S_table',
                             'EC_table',
                             'E_table'
                           ],
                  'lhs' => 'ELE_table',
                  'action' => 'ELE_table'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_table'
                           ],
                  'lhs' => 'EC_table'
                },
                {
                  'rhs' => [
                             'ELE_caption'
                           ],
                  'lhs' => 'EI_table'
                },
                {
                  'rhs' => [
                             'ELE_col'
                           ],
                  'lhs' => 'EI_table'
                },
                {
                  'rhs' => [
                             'ELE_colgroup'
                           ],
                  'lhs' => 'EI_table'
                },
                {
                  'rhs' => [
                             'ELE_tbody'
                           ],
                  'lhs' => 'EI_table'
                },
                {
                  'rhs' => [
                             'ELE_tfoot'
                           ],
                  'lhs' => 'EI_table'
                },
                {
                  'rhs' => [
                             'ELE_thead'
                           ],
                  'lhs' => 'EI_table'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_table'
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
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_colgroup'
                },
                {
                  'rhs' => [
                             'S_thead',
                             'EC_thead',
                             'E_thead'
                           ],
                  'lhs' => 'ELE_thead',
                  'action' => 'ELE_thead'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_thead'
                           ],
                  'lhs' => 'EC_thead'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_thead'
                },
                {
                  'rhs' => [
                             'ELE_tr'
                           ],
                  'lhs' => 'EI_thead'
                },
                {
                  'rhs' => [
                             'S_ol',
                             'EC_ol',
                             'E_ol'
                           ],
                  'lhs' => 'ELE_ol',
                  'action' => 'ELE_ol'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_ol'
                           ],
                  'lhs' => 'EC_ol'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_ol'
                },
                {
                  'rhs' => [
                             'ELE_li'
                           ],
                  'lhs' => 'EI_ol'
                },
                {
                  'rhs' => [
                             'S_tfoot',
                             'EC_tfoot',
                             'E_tfoot'
                           ],
                  'lhs' => 'ELE_tfoot',
                  'action' => 'ELE_tfoot'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_tfoot'
                           ],
                  'lhs' => 'EC_tfoot'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_tfoot'
                },
                {
                  'rhs' => [
                             'ELE_tr'
                           ],
                  'lhs' => 'EI_tfoot'
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
                             'S_dl',
                             'EC_dl',
                             'E_dl'
                           ],
                  'lhs' => 'ELE_dl',
                  'action' => 'ELE_dl'
                },
                {
                  'min' => 0,
                  'rhs' => [
                             'EI_dl'
                           ],
                  'lhs' => 'EC_dl'
                },
                {
                  'rhs' => [
                             'SGML_flow_item'
                           ],
                  'lhs' => 'EI_dl'
                },
                {
                  'rhs' => [
                             'ELE_dt'
                           ],
                  'lhs' => 'EI_dl'
                },
                {
                  'rhs' => [
                             'ELE_dd'
                           ],
                  'lhs' => 'EI_dl'
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
                }
              ];
$IS_BLOCK_ELEMENT = {
                      'div' => 'mixed_flow',
                      'form' => 'mixed_flow',
                      'pre' => 'inline_flow',
                      'h5' => 'mixed_flow',
                      'center' => 'mixed_flow',
                      'dir' => 'mixed_flow',
                      'noframes' => 'mixed_flow',
                      'h6' => 'mixed_flow',
                      'address' => 'mixed_flow',
                      'h1' => 'mixed_flow',
                      'blockquote' => 'mixed_flow',
                      'menu' => 'mixed_flow',
                      'h4' => 'mixed_flow',
                      'h2' => 'mixed_flow',
                      'fieldset' => 'mixed_flow',
                      'hr' => 'mixed_flow',
                      'h3' => 'mixed_flow',
                      'noscript' => 'mixed_flow'
                    };

