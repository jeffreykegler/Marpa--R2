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
SGML_item ::= comment
SGML_item ::= pi
SGML_item ::= decl
SGML_item ::= whitespace
SGML_item ::= cruft
SGML_flow ::= SGML_item*

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
ELE_body is block_flow

# Common types of element content
empty ::=

mixed_flow ::= mixed_flow_item*
mixed_flow_item ::= anywhere_element
mixed_flow_item ::= block_element
mixed_flow_item ::= inline_element
mixed_flow_item ::= cdata
mixed_flow_item ::= pcdata
mixed_flow_item ::= SGML_item

block_flow ::= block_item*
block_item ::= SGML_item
block_item ::= block_element
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

head_item ::= anywhere_element
head_item ::= SGML_item
head_item ::= head_element
head_element ::= ELE_object
head_element ::= ELE_style
head_element ::= ELE_meta
head_element ::= ELE_link
head_element ::= ELE_title
head_element ::= ELE_base

inline_flow ::= inline_item*
inline_item ::= pcdata
inline_item ::= cdata
inline_item ::= SGML_item
inline_item ::= inline_element
inline_item ::= anywhere_element
inline_element ::= ELE_object
inline_element ::= ELE_select
inline_element ::= ELE_span
inline_element ::= ELE_map
inline_element ::= ELE_applet

pcdata_flow ::= pcdata_flow_item*
pcdata_flow_item ::= cdata
pcdata_flow_item ::= pcdata
pcdata_flow_item ::= SGML_item

cdata_flow ::= cdata_flow_item*
cdata_flow_item ::= cdata
cdata_flow_item ::= cruft

# Alphabetically, by tagname
ELE_base is empty
ELE_col is empty
ELE_colgroup contains ELE_col SGML_item
ELE_dd is mixed_flow
ELE_div is mixed_flow
ELE_dl contains SGML_item ELE_dt ELE_dd
ELE_dt is inline_flow
ELE_isindex is empty
ELE_li is mixed_flow
ELE_map contains block_element SGML_item ELE_area
ELE_area is empty
ELE_link is empty
ELE_meta is empty
ELE_object contains ELE_param mixed_flow_item
ELE_applet contains ELE_param mixed_flow_item
ELE_ol contains SGML_item ELE_li
ELE_dir contains SGML_item ELE_li
ELE_menu contains SGML_item ELE_li
ELE_optgroup contains ELE_option SGML_item
ELE_p is inline_flow
ELE_param is empty
ELE_script is cdata_flow
ELE_select contains ELE_optgroup ELE_option
ELE_span is inline_flow
ELE_style is cdata_flow
ELE_table contains ELE_caption ELE_col ELE_colgroup
ELE_table contains ELE_tbody ELE_tfoot ELE_thead
ELE_table contains SGML_item
ELE_tbody contains SGML_item ELE_tr
ELE_td is mixed_flow
ELE_tfoot contains SGML_item ELE_tr
ELE_thead contains SGML_item ELE_tr
ELE_title is pcdata_flow
ELE_tr contains SGML_item ELE_th ELE_td
ELE_ul contains SGML_item ELE_li
END_OF_BNF

my @core_rules = ();

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
        push @core_rules, \%rule_descriptor;
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
        push @core_rules, \%rule_descriptor;
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
    push @core_rules,
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
        push @core_rules,
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

$output .= Data::Dumper->Purity(1)
    ->Dump( [ \@core_rules ], [qw(CORE_RULES)] );

my @core_elements = grep { /\A ELE_ /xms } map { $_->{lhs} } @core_rules;

# block_element is for block-level ONLY elements.
# Note that isindex can be both a head element and
# and block level element in the body.
# ISINDEX is classified as a header_element
my %is_block_element = (
    address    => 'inline_flow',
    blockquote => 'mixed_flow',
    center     => 'mixed_flow',
    dir        => 'core',
    div        => 'core',
    dl         => 'core',
    fieldset   => 'mixed_flow',
    form       => 'mixed_flow',
    h1         => 'inline_flow',
    h2         => 'inline_flow',
    h3         => 'inline_flow',
    h4         => 'inline_flow',
    h5         => 'inline_flow',
    h6         => 'inline_flow',
    hr         => 'empty',
    menu       => 'core',
    noframes   => 'mixed_flow',
    noscript   => 'mixed_flow',
    ol         => 'core',
    p          => 'core',
    pre        => 'inline_flow',
    table      => 'core',
    ul         => 'core',
);

my @non_core_block_elements = ();
ELEMENT: for my $element (keys %is_block_element) {
    if ($is_block_element{$element} eq 'core')
    {
       next ELEMENT if 'ELE_' . $element ~~ \@core_elements;
       die "Core grammar is missing a block element $element";
    }
    push @non_core_block_elements, $element;
}

my %non_core_block_hash =
    map { $_, $is_block_element{$_} }
    @non_core_block_elements;

$output .= Data::Dumper->Purity(1)
    ->Dump( [ \%non_core_block_hash ], [qw(IS_BLOCK_ELEMENT)] );

my %is_inline_element = (
    a        => 'inline_flow',
    abbr     => 'inline_flow',
    acronym  => 'inline_flow',
    applet   => 'core',
    audio    => 'inline_flow',
    b        => 'inline_flow',
    basefont => 'empty',
    bdo      => 'inline_flow',
    big      => 'inline_flow',
    blink    => 'inline_flow',
    br       => 'empty',
    button   => 'inline_flow',
    cite     => 'inline_flow',
    code     => 'inline_flow',
    command  => 'inline_flow',
    dfn      => 'inline_flow',
    em       => 'inline_flow',
    embed    => 'inline_flow',
    font     => 'inline_flow',
    i        => 'inline_flow',
    img      => 'empty',
    input    => 'empty',
    kbd      => 'inline_flow',
    keygen   => 'inline_flow',
    label    => 'inline_flow',
    map     => 'core',
    mark     => 'inline_flow',
    meter    => 'inline_flow',
    nobr     => 'inline_flow',
    output   => 'inline_flow',
    progress => 'inline_flow',
    q        => 'inline_flow',
    rb       => 'inline_flow',
    rbc      => 'inline_flow',
    rp       => 'inline_flow',
    rt       => 'inline_flow',
    rtc      => 'inline_flow',
    ruby     => 'inline_flow',
    s        => 'inline_flow',
    samp     => 'inline_flow',
    select   => 'core',
    small    => 'inline_flow',
    span     => 'core',
    strike   => 'inline_flow',
    strong   => 'inline_flow',
    sub      => 'inline_flow',
    sup      => 'inline_flow',
    textarea => 'pcdata_flow',
    time     => 'inline_flow',
    tt       => 'inline_flow',
    u        => 'inline_flow',
    var      => 'inline_flow',
    video    => 'inline_flow',
    wbr      => 'inline_flow',
);

my @non_core_inline_elements = ();
ELEMENT: for my $element (keys %is_inline_element) {
    if ($is_inline_element{$element} eq 'core')
    {
       next ELEMENT if 'ELE_' . $element ~~ \@core_elements;
       die "Core grammar is missing a inline element $element";
    }
    push @non_core_inline_elements, $element;
}

my %non_core_inline_hash =
    map { $_, $is_inline_element{$_} }
    @non_core_inline_elements;

$output .= Data::Dumper->Purity(1)
    ->Dump( [ \%non_core_inline_hash ], [qw(IS_INLINE_ELEMENT)] );

my @duplicated_elements =
    grep { $_ ~~ \@core_elements }
    map { 'ELE_' . $_ }
    @non_core_block_elements,
    @non_core_inline_elements,
    ;
if (@duplicated_elements) {
    say STDERR 'Runtime elements also in the core grammar:';
    say STDERR q{    }, join " ", @duplicated_elements;
    die "Elements cannot be both runtime and in the core grammar";
}

my @head_rubies   = qw( S_html S_head );
my @block_rubies  = qw( S_html S_head S_body );
my @inline_rubies = ( @block_rubies, qw(S_tbody S_tr S_td S_p) );

my %rubies = (
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
    $rubies{$required_rubies_desc} //= [];
}

DESC: for my $rubies_desc (keys %rubies) {
    my $candidates = $rubies{$rubies_desc};
    next DESC if '!non_final_end' ~~ $candidates;
    $rubies{$rubies_desc} = [@{$candidates}, '!non_final_end'];
}

my %is_anywhere_element = map { ( substr $_, 4 ) => 'core' }
    grep { 'ELE_' eq substr $_, 0, 4 }
    map { $_->{rhs}->[0] }
    grep { $_->{lhs} eq 'anywhere_element' } @core_rules;
my %is_head_element = map { ( substr $_, 4 ) => 'core' }
    grep { 'ELE_' eq substr $_, 0, 4 }
    map { $_->{rhs}->[0] }
    grep { $_->{lhs} eq 'head_element' } @core_rules;

my @core_symbols = map { substr $_, 4 } grep { m/\A ELE_ /xms } map { $_->{lhs}, @{$_->{rhs}} } @core_rules;
{
    my %seen = map { ( substr $_, 2 ) => 1 } grep {m/ \A S_ /xms} keys %rubies;
    $seen{$_} = 1 for keys %is_block_element;
    $seen{$_} = 1 for keys %is_inline_element;
    $seen{$_} = 1 for keys %is_anywhere_element;
    $seen{$_} = 1 for keys %is_head_element;
    my @symbols_with_no_ruby_status = grep { !$seen{$_} } @core_symbols;
    die "symbols with no ruby status: ", join " ",
        @symbols_with_no_ruby_status
        if scalar @symbols_with_no_ruby_status;
}

my %ruby_rank = ();
for my $rejected_symbol (keys %rubies) {
  my $rank = 1;
  for my $candidate (reverse @{$rubies{$rejected_symbol}})
  {
     $ruby_rank{$rejected_symbol}{$candidate} = $rank++;
  }
}

$output .= Data::Dumper->Purity(1) ->Dump( [ \%is_head_element ], [qw(IS_HEAD_ELEMENT)] );
$output .= Data::Dumper->Purity(1) ->Dump( [ \%is_anywhere_element ], [qw(IS_ANYWHERE_ELEMENT)] );
$output .= Data::Dumper->Purity(1) ->Dump( [ \%is_inline_element ], [qw(IS_INLINE_ELEMENT)] );
$output .= Data::Dumper->Purity(1) ->Dump( [ \%is_block_element ], [qw(IS_BLOCK_ELEMENT)] );

$output .= Data::Dumper->Purity(1)
    ->Dump( [ \%ruby_rank ], [qw(RUBY_SLIPPERS_RANK_BY_NAME)] );

open my $out_fh, q{>}, 'Core_Grammar.pm';
say {$out_fh} $output;
close $out_fh;
