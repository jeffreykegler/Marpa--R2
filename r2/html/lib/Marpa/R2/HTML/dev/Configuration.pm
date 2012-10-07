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

use 5.010;
use strict;
use warnings;
use autodie;
use Data::Dumper;

package HTML_Configuration;

use English qw( -no_match_vars );

# Alphabetically, by tagname
our $CONFIGURATION_BNF = <<'END_OF_CONFIG_BNF';
ELE_a is a FLO_inline included in GRP_inline
ELE_abbr is a FLO_inline included in GRP_inline
ELE_acronym is a FLO_inline included in GRP_inline
ELE_address is a FLO_inline included in GRP_block
ELE_applet contains ELE_param ITEM_mixed
ELE_applet is included in GRP_inline
ELE_area is FLO_empty
ELE_audio is a FLO_inline included in GRP_inline
ELE_b is a FLO_inline included in GRP_inline
ELE_base is a FLO_empty included in GRP_head
ELE_basefont is a FLO_empty included in GRP_inline
ELE_bdo is a FLO_inline included in GRP_inline
ELE_big is a FLO_inline included in GRP_inline
ELE_blink is a FLO_inline included in GRP_inline
ELE_blockquote is a FLO_mixed included in GRP_block
ELE_br is a FLO_empty included in GRP_inline
ELE_button is a FLO_inline included in GRP_inline
ELE_caption is FLO_inline
ELE_center is a FLO_mixed included in GRP_block
ELE_cite is a FLO_inline included in GRP_inline
ELE_code is a FLO_inline included in GRP_inline
ELE_col is FLO_empty
ELE_colgroup contains ELE_col
ELE_command is a FLO_inline included in GRP_inline
ELE_dd is FLO_mixed
ELE_dfn is a FLO_inline included in GRP_inline
ELE_dir contains ELE_li
ELE_dir is included in GRP_block
ELE_div is a FLO_mixed included in GRP_block
ELE_dl contains ELE_dt ELE_dd
ELE_dl is included in GRP_block
ELE_dt is FLO_inline
ELE_em is a FLO_inline included in GRP_inline
ELE_embed is a FLO_inline included in GRP_inline
ELE_fieldset is a FLO_mixed included in GRP_block
ELE_font is a FLO_inline included in GRP_inline
ELE_form is a FLO_mixed included in GRP_block
ELE_h1 is a FLO_inline included in GRP_block
ELE_h2 is a FLO_inline included in GRP_block
ELE_h3 is a FLO_inline included in GRP_block
ELE_h4 is a FLO_inline included in GRP_block
ELE_h5 is a FLO_inline included in GRP_block
ELE_h6 is a FLO_inline included in GRP_block
ELE_hr is a FLO_empty included in GRP_block
ELE_i is a FLO_inline included in GRP_inline
ELE_img is a FLO_empty included in GRP_inline
ELE_input is a FLO_empty included in GRP_inline
ELE_isindex is a FLO_empty included in GRP_anywhere
ELE_kbd is a FLO_inline included in GRP_inline
ELE_keygen is a FLO_inline included in GRP_inline
ELE_label is a FLO_inline included in GRP_inline
ELE_li is FLO_mixed
ELE_link is a FLO_empty included in GRP_head
ELE_map contains GRP_block ELE_area
ELE_map is included in GRP_inline
ELE_mark is a FLO_inline included in GRP_inline
ELE_menu contains ELE_li
ELE_menu is included in GRP_block
ELE_meta is a FLO_empty included in GRP_head
ELE_meter is a FLO_inline included in GRP_inline
ELE_nobr is a FLO_inline included in GRP_inline
ELE_noframes is a FLO_mixed included in GRP_block
ELE_noscript is a FLO_mixed included in GRP_block
ELE_object contains ELE_param ITEM_mixed
ELE_object is included in GRP_anywhere
ELE_ol contains ELE_li
ELE_ol is included in GRP_block
ELE_optgroup contains ELE_option
ELE_option is FLO_pcdata
ELE_output is a FLO_inline included in GRP_inline
ELE_p is a FLO_inline included in GRP_block
ELE_param is FLO_empty
ELE_plaintext is a FLO_cdata included in GRP_block
ELE_pre is a FLO_inline included in GRP_block
ELE_progress is a FLO_inline included in GRP_inline
ELE_q is a FLO_inline included in GRP_inline
ELE_rb is a FLO_inline included in GRP_inline
ELE_rbc is a FLO_inline included in GRP_inline
ELE_rp is a FLO_inline included in GRP_inline
ELE_rt is a FLO_inline included in GRP_inline
ELE_rtc is a FLO_inline included in GRP_inline
ELE_ruby is a FLO_inline included in GRP_inline
ELE_s is a FLO_inline included in GRP_inline
ELE_samp is a FLO_inline included in GRP_inline
ELE_script is a FLO_cdata included in GRP_anywhere
ELE_select contains ELE_optgroup ELE_option
ELE_select is included in GRP_inline
ELE_small is a FLO_inline included in GRP_inline
ELE_span is a FLO_inline included in GRP_inline
ELE_strike is a FLO_inline included in GRP_inline
ELE_strong is a FLO_inline included in GRP_inline
ELE_style is a FLO_cdata included in GRP_head
ELE_sub is a FLO_inline included in GRP_inline
ELE_sup is a FLO_inline included in GRP_inline
ELE_table contains ELE_caption ELE_col ELE_colgroup
ELE_table contains ELE_tbody ELE_tfoot ELE_thead
ELE_table is included in GRP_block
ELE_tbody contains ELE_tr
ELE_td is FLO_mixed
ELE_textarea is a FLO_cdata included in GRP_anywhere
ELE_tfoot contains ELE_tr
ELE_th is FLO_mixed
ELE_thead contains ELE_tr
ELE_time is a FLO_inline included in GRP_inline
ELE_title is a FLO_pcdata included in GRP_head
ELE_tr contains ELE_th ELE_td
ELE_tt is a FLO_inline included in GRP_inline
ELE_u is a FLO_inline included in GRP_inline
ELE_ul contains ELE_li
ELE_ul is included in GRP_block
ELE_var is a FLO_inline included in GRP_inline
ELE_video is a FLO_inline included in GRP_inline
ELE_wbr is a FLO_inline included in GRP_inline
ELE_xmp is a FLO_cdata included in GRP_block
END_OF_CONFIG_BNF

my @head_rubies   = qw( S_html S_head );
my @block_rubies  = qw( S_html S_head S_body );
my @inline_rubies = ( @block_rubies, qw(S_tbody S_tr S_td S_p) );

our %RUBY_CONFIG = (
    S_html              => [],
    S_head              => [qw( S_html )],
    S_body              => [qw( S_html S_head )],
    CDATA               => \@inline_rubies,
    PCDATA              => \@inline_rubies,
    '!start_tag'        => \@block_rubies,
    '!inline_start_tag' => \@inline_rubies,
    '!head_start_tag'   => \@head_rubies,
    S_area              => [ @block_rubies, 'S_map' ],
    S_option            => [ @inline_rubies, 'S_select' ],
    S_optgroup          => [ @inline_rubies, 'S_select' ],
    S_param             => [ @block_rubies, 'S_object' ],
    S_li                => [ @block_rubies, qw( !non_final_end S_ul) ],
    S_dt                => [ @block_rubies, 'S_dl' ],
    S_dd                => [ @block_rubies, 'S_dl' ],
    S_caption           => [ @block_rubies, qw( !non_final_end S_table ) ],
    S_col               => [ @block_rubies, qw( !non_final_end S_table ) ],
    S_colgroup          => [ @block_rubies, qw( !non_final_end S_table ) ],
    S_tbody             => [ @block_rubies, qw( !non_final_end S_table ) ],
    S_tfoot             => [ @block_rubies, qw( !non_final_end S_table ) ],
    S_thead             => [ @block_rubies, qw( !non_final_end S_table ) ],
    E_table             => [ @block_rubies, qw( !non_final_end S_table ) ],
    S_tr => [ @block_rubies, qw( S_tbody !non_final_end S_table ) ],
    S_th =>
        [ @block_rubies, qw( S_thead S_tbody S_tr !non_final_end S_table ) ],
    S_td => [ @block_rubies, qw( S_tbody S_tr !non_final_end S_table ) ],
    E_body => [qw( S_html S_head S_body )],
    E_html => [qw( S_html S_head S_body !non_final_end E_body )],
    EOF    => [qw( S_html S_head S_body !non_final_end E_body E_html)]
);

1;
