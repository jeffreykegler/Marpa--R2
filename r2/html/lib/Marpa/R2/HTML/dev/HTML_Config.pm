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

package HTML_Config;

use English qw( -no_match_vars );

our $BNF = <<'END_OF_BNF';
# Non-element tokens
comment ::= C
pi ::= PI
decl ::= D
pcdata ::= PCDATA
cdata ::= CDATA
whitespace ::= WHITESPACE
cruft ::= CRUFT

# FLO_SGML and ITEM_SGML defined by BNF rules,
# because they must explicity include cruft
FLO_SGML ::= ITEM_SGML*
ITEM_SGML ::= comment
ITEM_SGML ::= pi
ITEM_SGML ::= decl
ITEM_SGML ::= whitespace
ITEM_SGML ::= cruft

# For element x,
# ELE_x is complete element
# S_x is start tag
# E_x is end tag
#   The contents of many elements consists of zero or more items

# Top-level structure
document ::= prolog ELE_html trailer EOF
prolog ::= FLO_SGML
trailer ::= FLO_SGML
ELE_html ::= S_html EC_html E_html
EC_html ::= FLO_SGML ELE_head FLO_SGML ELE_body FLO_SGML
ELE_head is FLO_head
ELE_body is FLO_block

# Common types of element content
empty ::=

FLO_mixed contains anywhere_element block_element GRP_inline
FLO_mixed contains cdata pcdata

FLO_block contains block_element anywhere_element

block_element ::= ELE_table
block_element ::= ELE_p
block_element ::= ELE_ol
block_element ::= ELE_ul
block_element ::= ELE_dl
block_element ::= ELE_div
block_element ::= ELE_dir
block_element ::= ELE_menu

# isindex can also be a block element
# and script can be a block and an inline element
# these will become "anywhere" elements
anywhere_element ::= ELE_script
anywhere_element ::= ELE_isindex
anywhere_element ::= ELE_textarea

FLO_head contains head_element anywhere_element

head_element ::= ELE_object
head_element ::= ELE_style
head_element ::= ELE_meta
head_element ::= ELE_link
head_element ::= ELE_title
head_element ::= ELE_base

FLO_inline contains pcdata cdata GRP_inline anywhere_element

GRP_inline ::= ELE_object
GRP_inline ::= ELE_select
GRP_inline ::= ELE_span
GRP_inline ::= ELE_map
GRP_inline ::= ELE_applet

FLO_pcdata contains cdata pcdata

# FLO_cdata and ITEM_cdata defined by "hand" (BNF)
# because they do NOT allow SGML items as part of
# their flow
FLO_cdata ::= ITEM_cdata*
ITEM_cdata ::= cdata
ITEM_cdata ::= CRUFT

# Alphabetically, by tagname
ELE_base is empty
ELE_col is empty
ELE_colgroup contains ELE_col
ELE_dd is FLO_mixed
ELE_div is FLO_mixed
ELE_dl contains ELE_dt ELE_dd
ELE_dt is FLO_inline
ELE_isindex is empty
ELE_li is FLO_mixed
ELE_map contains block_element ELE_area
ELE_area is empty
ELE_link is empty
ELE_meta is empty
ELE_object contains ELE_param ITEM_mixed
ELE_applet contains ELE_param ITEM_mixed
ELE_ol contains ELE_li
ELE_dir contains ELE_li
ELE_menu contains ELE_li
ELE_optgroup contains ELE_option
ELE_p is FLO_inline
ELE_param is empty
ELE_script is FLO_cdata
ELE_select contains ELE_optgroup ELE_option
ELE_span is FLO_inline
ELE_style is FLO_cdata
ELE_table contains ELE_caption ELE_col ELE_colgroup
ELE_table contains ELE_tbody ELE_tfoot ELE_thead
ELE_textarea is FLO_cdata
ELE_tbody contains ELE_tr
ELE_td is FLO_mixed
ELE_tfoot contains ELE_tr
ELE_thead contains ELE_tr
ELE_title is FLO_pcdata
ELE_tr contains ELE_th ELE_td
ELE_ul contains ELE_li
END_OF_BNF

our %HANDLER = (
    cruft      => 'SPE_CRUFT',
    comment    => 'SPE_COMMENT',
    pi         => 'SPE_PI',
    decl       => 'SPE_DECL',
    document   => 'SPE_TOP',
    whitespace => 'SPE_WHITESPACE',
    pcdata     => 'SPE_PCDATA',
    cdata      => 'SPE_CDATA',
    prolog     => 'SPE_PROLOG',
    trailer    => 'SPE_TRAILER',
);

# block_element is for block-level ONLY elements.
# Note that isindex can be both a head element and
# and block level element in the body.
# ISINDEX is classified as a header_element
our %IS_BLOCK_ELEMENT = (
    address    => 'FLO_inline',
    blockquote => 'FLO_mixed',
    center     => 'FLO_mixed',
    dir        => 'core',
    div        => 'core',
    dl         => 'core',
    fieldset   => 'FLO_mixed',
    form       => 'FLO_mixed',
    h1         => 'FLO_inline',
    h2         => 'FLO_inline',
    h3         => 'FLO_inline',
    h4         => 'FLO_inline',
    h5         => 'FLO_inline',
    h6         => 'FLO_inline',
    hr         => 'empty',
    menu       => 'core',
    noframes   => 'FLO_mixed',
    noscript   => 'FLO_mixed',
    ol         => 'core',
    p          => 'core',
    plaintext  => 'FLO_cdata',
    pre        => 'FLO_inline',
    table      => 'core',
    ul         => 'core',
    xmp        => 'FLO_cdata',
);

our %IS_INLINE_ELEMENT = (
    a        => 'FLO_inline',
    abbr     => 'FLO_inline',
    acronym  => 'FLO_inline',
    applet   => 'core',
    audio    => 'FLO_inline',
    b        => 'FLO_inline',
    basefont => 'empty',
    bdo      => 'FLO_inline',
    big      => 'FLO_inline',
    blink    => 'FLO_inline',
    br       => 'empty',
    button   => 'FLO_inline',
    cite     => 'FLO_inline',
    code     => 'FLO_inline',
    command  => 'FLO_inline',
    dfn      => 'FLO_inline',
    em       => 'FLO_inline',
    embed    => 'FLO_inline',
    font     => 'FLO_inline',
    i        => 'FLO_inline',
    img      => 'empty',
    input    => 'empty',
    input    => 'FLO_cdata',
    kbd      => 'FLO_inline',
    keygen   => 'FLO_inline',
    label    => 'FLO_inline',
    map     => 'core',
    mark     => 'FLO_inline',
    meter    => 'FLO_inline',
    nobr     => 'FLO_inline',
    output   => 'FLO_inline',
    progress => 'FLO_inline',
    q        => 'FLO_inline',
    rb       => 'FLO_inline',
    rbc      => 'FLO_inline',
    rp       => 'FLO_inline',
    rt       => 'FLO_inline',
    rtc      => 'FLO_inline',
    ruby     => 'FLO_inline',
    s        => 'FLO_inline',
    samp     => 'FLO_inline',
    select   => 'core',
    small    => 'FLO_inline',
    span     => 'core',
    strike   => 'FLO_inline',
    strong   => 'FLO_inline',
    sub      => 'FLO_inline',
    sup      => 'FLO_inline',
    textarea => 'core',
    time     => 'FLO_inline',
    tt       => 'FLO_inline',
    u        => 'FLO_inline',
    var      => 'FLO_inline',
    video    => 'FLO_inline',
    wbr      => 'FLO_inline',
);

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


# Make sure the last resort defaults are always defined
for my $required_rubies_desc (qw( !start_tag !end_tag !non_element )) {
    $RUBY_CONFIG{$required_rubies_desc} //= [];
}

DESC: for my $rubies_desc (keys %RUBY_CONFIG) {
    my $candidates = $RUBY_CONFIG{$rubies_desc};
    next DESC if '!non_final_end' ~~ $candidates;
    $RUBY_CONFIG{$rubies_desc} = [@{$candidates}, '!non_final_end'];
}

1;
