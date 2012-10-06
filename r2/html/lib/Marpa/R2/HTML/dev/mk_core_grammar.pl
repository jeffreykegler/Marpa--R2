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

use lib '.';
use HTML_Config;

my @core_rules = ();

my %containments = ();
LINE: for my $line ( split /\n/xms, $HTML_Config::BNF ) {
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
        if ( my $handler = $HTML_Config::HANDLER{$lhs} ) {
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
    if ( $definition =~ s/ \A \s* ((ELE|FLO)_\w+) \s+ contains \s+ / /xms ) {
        # Production is Element with custom flow
        my $element_symbol = $1;
        push @{ $containments{$element_symbol} }, split q{ }, $definition;
        next LINE;
    }
    die "Badly formed line in grammar description: $line";
} ## end LINE: for my $line ( split /\n/xms, $HTML_Config::BNF )

my %flow_seen = ();
ELEMENT: for my $main_symbol (keys %containments) {
    my @contents = @{$containments{$main_symbol}};
    my $contents_symbol;
    my $item_symbol;
    my @main_rhs = ();
    my @action = ();
    NAME_SYMBOLS: {
        if ( (substr $main_symbol, 0, 4) eq 'ELE_' ) {
            my $tag = substr $main_symbol, 4;
            $contents_symbol = 'ELC_' . $tag;
            $item_symbol     = 'ELI_' . $tag;
            push @action, action => $main_symbol;
            @main_rhs = ( "S_$tag", $contents_symbol, "E_$tag" );
            last NAME_SYMBOLS;
        } ## end if ( substr $main_symbol, 0, 4 eq 'ELE_' )
        if ( (substr $main_symbol, 0, 4) eq 'FLO_' ) {
            my $tag = substr $main_symbol, 4;
            $contents_symbol = 'FLC_' . $tag;
            $item_symbol     = 'FLI_' . $tag;
            @main_rhs        = ($contents_symbol);
            last NAME_SYMBOLS;
        } ## end if ( substr $main_symbol, 0, 4 eq 'FLO_' )
        die "Bad containment: cannot use symbol $main_symbol";
    } ## end NAME_SYMBOLS:
    push @core_rules,
        {
        lhs    => $main_symbol,
        rhs    => \@main_rhs,
        @action
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
    if (!$flow_seen{$main_symbol}) {
	$flow_seen{$main_symbol} = 1;
        push @core_rules,
            {
            lhs => $item_symbol,
            rhs => ['CRUFT'],
            };
    }
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

my @non_core_block_elements = ();
ELEMENT: for my $element (keys %HTML_Config::IS_BLOCK_ELEMENT) {
    if ($HTML_Config::IS_BLOCK_ELEMENT{$element} eq 'core')
    {
       next ELEMENT if 'ELE_' . $element ~~ \@core_elements;
       die "Core grammar is missing a block element $element";
    }
    push @non_core_block_elements, $element;
}

my %non_core_block_hash =
    map { $_, $HTML_Config::IS_BLOCK_ELEMENT{$_} }
    @non_core_block_elements;

$output .= Data::Dumper->Purity(1)
    ->Dump( [ \%non_core_block_hash ], [qw(IS_BLOCK_ELEMENT)] );

my @non_core_inline_elements = ();
ELEMENT: for my $element (keys %HTML_Config::IS_INLINE_ELEMENT) {
    if ($HTML_Config::IS_INLINE_ELEMENT{$element} eq 'core')
    {
       next ELEMENT if 'ELE_' . $element ~~ \@core_elements;
       die "Core grammar is missing a inline element $element";
    }
    push @non_core_inline_elements, $element;
}

my %non_core_inline_hash =
    map { $_, $HTML_Config::IS_INLINE_ELEMENT{$_} }
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
    my %seen = map { ( substr $_, 2 ) => 1 } grep {m/ \A S_ /xms} keys %HTML_Config::RUBY_CONFIG;
    $seen{$_} = 1 for keys %HTML_Config::IS_BLOCK_ELEMENT;
    $seen{$_} = 1 for keys %HTML_Config::IS_INLINE_ELEMENT;
    $seen{$_} = 1 for keys %is_anywhere_element;
    $seen{$_} = 1 for keys %is_head_element;
    my @symbols_with_no_ruby_status = grep { !$seen{$_} } @core_symbols;
    die "symbols with no ruby status: ", join " ",
        @symbols_with_no_ruby_status
        if scalar @symbols_with_no_ruby_status;
}

my %ruby_rank = ();
for my $rejected_symbol (keys %HTML_Config::RUBY_CONFIG) {
  my $rank = 1;
  for my $candidate (reverse @{$HTML_Config::RUBY_CONFIG{$rejected_symbol}})
  {
     $ruby_rank{$rejected_symbol}{$candidate} = $rank++;
  }
}

$output .= Data::Dumper->Purity(1) ->Dump( [ \%is_head_element ], [qw(IS_HEAD_ELEMENT)] );
$output .= Data::Dumper->Purity(1) ->Dump( [ \%is_anywhere_element ], [qw(IS_ANYWHERE_ELEMENT)] );
$output .= Data::Dumper->Purity(1) ->Dump( [ \%HTML_Config::IS_INLINE_ELEMENT ], [qw(IS_INLINE_ELEMENT)] );
$output .= Data::Dumper->Purity(1) ->Dump( [ \%HTML_Config::IS_BLOCK_ELEMENT ], [qw(IS_BLOCK_ELEMENT)] );

$output .= Data::Dumper->Purity(1)
    ->Dump( [ \%ruby_rank ], [qw(RUBY_SLIPPERS_RANK_BY_NAME)] );

open my $out_fh, q{>}, 'Core_Grammar.pm';
say {$out_fh} $output;
close $out_fh;
