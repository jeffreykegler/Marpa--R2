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
# Non-element tokens
cruft ::= CRUFT
comment ::= C
pi ::= PI
decl ::= D
pcdata ::= PCDATA
cdata ::= CDATA
whitespace ::= WHITESPACE
# SGML flows
SGML_flow_item ::= comment
SGML_flow_item ::= pi
SGML_flow_item ::= decl
SGML_flow_item ::= whitespace
SGML_flow_item ::= cruft
SGML_flow ::= SGML_flow_item*

# For element x,
# ELE_x is complete element
# S_x is start tag
# E_x is end tag
# EC_x is the element's contents
#   The contents of many elements consists of zero or more items
# EI_x is a content "item" for element x

# Top-level structure
document ::= prolog ELE_html trailer EOF
prolog ::= SGML_flow
trailer ::= SGML_flow
ELE_html ::= S_html EC_html E_html
EC_html ::= SGML_flow ELE_head SGML_flow ELE_body SGML_flow
ELE_head contains head_item
ELE_body is mixed_flow

# Common types of element content
empty ::=
mixed_flow ::= mixed_flow_item*
mixed_flow_item ::= block_element
mixed_flow_item ::= inline_flow_item
block_element ::= ELE_table
block_element ::= ELE_p
block_element ::= ELE_ol
block_element ::= ELE_ul
block_element ::= ELE_dl
inline_element ::= ELE_script
inline_element ::= ELE_object
inline_element ::= ELE_select
head_item ::= ELE_script
head_item ::= ELE_object
head_item ::= ELE_style
head_item ::= ELE_meta
head_item ::= ELE_link
head_item ::= ELE_isindex
head_item ::= ELE_title
head_item ::= ELE_base
head_item ::= SGML_flow_item
inline_flow ::= inline_flow_item*
inline_flow_item ::= pcdata_flow_item
inline_flow_item ::= inline_element

# pcdata_flow ::= pcdata_flow_item*
pcdata_flow_item ::= cdata
pcdata_flow_item ::= pcdata
pcdata_flow_item ::= SGML_flow_item

# cdata_flow ::= cdata_flow_item*
# cdata_flow_item ::= cdata

# Alphabetically, by tagname
ELE_base is empty
ELE_colgroup contains ELE_col SGML_flow_item
ELE_dd is mixed_flow
ELE_dl contains SGML_flow_item ELE_dt ELE_dd
ELE_dt is inline_flow
ELE_isindex is empty
ELE_li is mixed_flow
ELE_link is empty
ELE_meta is empty
ELE_object contains ELE_param mixed_flow_item
ELE_ol contains SGML_flow_item ELE_li
ELE_optgroup contains ELE_option SGML_flow_item
ELE_p is inline_flow
ELE_param is inline_flow
ELE_script is inline_flow
ELE_select contains ELE_optgroup ELE_option
ELE_style is inline_flow
ELE_table contains ELE_caption ELE_col ELE_colgroup
ELE_table contains ELE_tbody ELE_tfoot ELE_thead
ELE_table contains SGML_flow_item
ELE_tbody contains SGML_flow_item ELE_tr
ELE_td is mixed_flow
ELE_tfoot contains SGML_flow_item ELE_tr
ELE_thead contains SGML_flow_item ELE_tr
ELE_title is inline_flow
ELE_tr contains SGML_flow_item ELE_th ELE_td
ELE_ul contains SGML_flow_item ELE_li
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

my %containments = ();
LINE: for my $line ( split /\n/xms, $BNF ) {
    my $definition = $line;
    $definition =~ s/ [#] .* //xms;    # Remove comments
    next LINE
        if not $definition =~ / \S /xms;    # ignore all-whitespace line
    my $sequence = ( $definition =~ s/ [*] \s* $//xms );
    if ( $definition =~ s/ \s* [:][:][=] \s* / /xms ) {

        # Production is Ordinary BNF rule
        my @symbols         = ( split q{ }, $definition );
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
        next LINE;
    } ## end if ( $definition =~ s/ \s* [:][:][=] \s* / /xms )
    if ( $definition =~ s/ \A \s* ELE_(\w+) \s+ is \s+ / /xms ) {
        # Production is Element with standard flow
        my $tag = $1;
        my @symbols         = ( split q{ }, $definition );
	die "Standard flow element should have exactly one content symbol: $line"
	   if scalar @symbols != 1;
        my $contents             = shift @symbols;
	my $lhs = 'ELE_' . $tag;
        my %rule_descriptor = (
            lhs => $lhs,
            rhs => [ "S_$tag", $contents, "E_$tag" ],
	    action => $lhs
        );
        push @Marpa::R2::HTML::Internal::CORE_RULES, \%rule_descriptor;
        next LINE;
    }
    if ( $definition =~ s/ \A \s* ELE_(\w+) \s+ contains \s+ / /xms ) {
        # Production is Element with custom flow
        my $tag = $1;
        push @{ $containments{$tag} }, split q{ }, $definition;
        next LINE;
    }
    die "Badly formed line in grammar description: $line";
} ## end LINE: for my $line ( split /\n/xms, $BNF )

ELEMENT: for my $tag (keys %containments) {
    my @contents = @{$containments{$tag}};
    my $element_symbol = 'ELE_' . $tag;
    my $contents_symbol = 'EC_' . $tag;
    my $item_symbol     = 'EI_' . $tag;
    push @Marpa::R2::HTML::Internal::CORE_RULES,
        {
        lhs    => $element_symbol,
        rhs    => [ "S_$tag", $contents_symbol, "E_$tag" ],
        action => $element_symbol,
        },
        {
        lhs => $contents_symbol,
        rhs => [$item_symbol],
        min => 0
        };
    for my $content_item ( @contents ) {
        push @Marpa::R2::HTML::Internal::CORE_RULES,
            {
            lhs => $item_symbol,
            rhs => [$content_item],
            };
    } ## end for my $content_item ( @{$contents} )
} ## end ELEMENT: for my $core_element_data (@core_elements)

open my $fh, q{<}, '../../../../../..//inc/Marpa/R2/legal.pl';
my $legal = join q{}, <$fh>;
close $fh;

my $output = $legal;
$output .=  "\n";

$output .= "# This file was generated automatically by $PROGRAM_NAME\n";
$output .= "# The date of generation was " . ( scalar localtime() );
$output .= "\n\n";

$output .= 'package Marpa::R2::HTML::Internal;';
$output .= "\n\n";

require Data::Dumper;
$output .= Data::Dumper->Purity(1)
    ->Dump( [ \@Marpa::R2::HTML::Internal::CORE_RULES ], [qw(CORE_RULES)] );

my @element_hierarchy = (
    [qw( span option )],
    [qw( li optgroup dd dt )],
    [qw( dir menu )],
    [qw( div )],
    [qw( ul ol dl )],
    [qw( th td )],
    [qw( tr )],
    [qw( col )],
    [qw( caption colgroup thead tfoot tbody )],
    [qw( table )],
    [qw( p )],
    [qw( head body )],
    [qw( html )],
);

my @last_resort_tags = qw(S_table E_body E_html);

my @tag_hierarchy = ();
push @tag_hierarchy,
    grep { not $_ ~~ \@last_resort_tags }
    map { 'S_' . $_ } map { @{$_} } reverse @element_hierarchy;
push @tag_hierarchy,
    grep { not $_ ~~ \@last_resort_tags }
    map { 'E_' . $_ } map { @{$_} } @element_hierarchy;
push @tag_hierarchy, @last_resort_tags;

say Data::Dumper::Dumper(\@tag_hierarchy);

open my $out_fh, q{>}, 'Core_Grammar.pm';
say {$out_fh} $output;
close $out_fh;
