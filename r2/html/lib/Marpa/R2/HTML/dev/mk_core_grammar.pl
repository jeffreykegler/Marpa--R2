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

use English qw( -no_match_vars );

my $BNF = <<'END_OF_BNF';
cruft ::= CRUFT
comment ::= C
pi ::= PI
decl ::= D
pcdata ::= PCDATA
cdata ::= CDATA
whitespace ::= WHITESPACE
SGML_item ::= comment
SGML_item ::= pi
SGML_item ::= decl
SGML_flow_item ::= SGML_item
SGML_flow_item ::= whitespace
SGML_flow_item ::= cruft
SGML_flow ::= SGML_flow_item*
document ::= prolog ELE_html trailer EOF
prolog ::= SGML_flow
trailer ::= SGML_flow
ELE_html ::= S_html Contents_html E_html
Contents_html ::= SGML_flow ELE_head SGML_flow ELE_body SGML_flow
ELE_head ::= S_head Contents_head E_head
Contents_head ::= head_item*
ELE_body ::= S_body mixed_flow E_body
ELE_table ::= S_table table_flow E_table
ELE_tbody ::= S_tbody table_section_flow E_tbody
ELE_tr ::= S_tr table_row_flow E_tr
ELE_td ::= S_td mixed_flow E_td
mixed_flow ::= mixed_flow_item*
mixed_flow_item ::= cruft
mixed_flow_item ::= SGML_item
mixed_flow_item ::= ELE_table
mixed_flow_item ::= list_item_element
mixed_flow_item ::= header_element
mixed_flow_item ::= block_element
mixed_flow_item ::= inline_element
mixed_flow_item ::= whitespace
mixed_flow_item ::= cdata
mixed_flow_item ::= pcdata
head_item ::= ELE_script
head_item ::= ELE_object
head_item ::= ELE_style
head_item ::= ELE_meta
head_item ::= ELE_link
head_item ::= ELE_title
head_item ::= ELE_base
head_item ::= cruft
head_item ::= whitespace
head_item ::= SGML_item
inline_flow ::= inline_flow_item*
inline_flow_item ::= pcdata_flow_item
inline_flow_item ::= inline_element
pcdata_flow ::= pcdata_flow_item*
pcdata_flow_item ::= cdata
pcdata_flow_item ::= pcdata
pcdata_flow_item ::= cruft
pcdata_flow_item ::= whitespace
pcdata_flow_item ::= SGML_item
Contents_select ::= select_flow_item*
select_flow_item ::= ELE_optgroup
select_flow_item ::= ELE_option
select_flow_item ::= SGML_flow_item
Contents_optgroup ::= optgroup_flow_item*
optgroup_flow_item ::= ELE_option
optgroup_flow_item ::= SGML_flow_item
list_item_flow ::= list_item_flow_item*
list_item_flow_item ::= cruft
list_item_flow_item ::= SGML_item
list_item_flow_item ::= header_element
list_item_flow_item ::= block_element
list_item_flow_item ::= inline_element
list_item_flow_item ::= whitespace
list_item_flow_item ::= cdata
list_item_flow_item ::= pcdata
Contents_colgroup ::= colgroup_flow_item*
colgroup_flow_item ::= ELE_col
colgroup_flow_item ::= SGML_flow_item
table_row_flow ::= table_row_flow_item*
table_row_flow_item ::= ELE_th
table_row_flow_item ::= ELE_td
table_row_flow_item ::= SGML_flow_item
table_section_flow ::= table_section_flow_item*
table_section_flow_item ::= table_row_element
table_section_flow_item ::= SGML_flow_item
table_row_element ::= ELE_tr
table_flow ::= table_flow_item*
table_flow_item ::= ELE_colgroup
table_flow_item ::= ELE_thead
table_flow_item ::= ELE_tfoot
table_flow_item ::= ELE_tbody
table_flow_item ::= ELE_caption
table_flow_item ::= ELE_col
table_flow_item ::= SGML_flow_item
inline_element ::= ELE_script
inline_element ::= ELE_object
ELE_script ::= S_script inline_flow E_script
ELE_style ::= S_style inline_flow E_style
ELE_title ::= S_title inline_flow E_title
ELE_object ::= S_object Contents_object E_object
Contents_object ::= Item_object*
Item_object ::= mixed_flow_item
Item_object ::= ELE_param
ELE_param ::= S_param inline_flow E_param
ELE_base ::= S_base empty E_base
ELE_isindex ::= S_isindex empty E_isindex
ELE_meta ::= S_meta empty E_meta
ELE_link ::= S_link empty E_link
empty ::=
END_OF_BNF

@Marpa::R2::HTML::Internal::CORE_RULES = ();

my %handler = (
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

for my $bnf_production ( split /\n/xms, $BNF ) {
    my $sequence = ( $bnf_production =~ s/ [*] \s* $//xms );
    $bnf_production =~ s/ \s* [:][:][=] \s* / /xms;
    my @symbols         = ( split q{ }, $bnf_production );
    my $lhs             = shift @symbols;
    my %rule_descriptor = (
        lhs => $lhs,
        rhs => \@symbols,
    );
    if ($sequence) {
        $rule_descriptor{min} = 0;
    }
    if ( my $handler = $handler{$lhs} ) {
        $rule_descriptor{action} = $handler;
    }
    elsif ( $lhs =~ /^ELE_/xms ) {
        $rule_descriptor{action} = "$lhs";
    }
    push @Marpa::R2::HTML::Internal::CORE_RULES, \%rule_descriptor;
} ## end for my $bnf_production ( split /\n/xms, $BNF )

open my $fh, q{<}, '../../../../../..//inc/Marpa/R2/legal.pl';
say join q{}, <$fh>;

say "# This file was generated automatically by $PROGRAM_NAME";
say "# The date of generation was ", ( scalar localtime() ), "\n";

say "package Marpa::R2::HTML::Internal;";

require Data::Dumper;
say Data::Dumper->Purity(1)
    ->Dump( [ \@Marpa::R2::HTML::Internal::CORE_RULES ], [qw(CORE_RULES)] );
