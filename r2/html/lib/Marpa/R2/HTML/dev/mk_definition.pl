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

use lib '../../../../';
use Marpa::R2::HTML::dev::Core;
use Marpa::R2::HTML::dev::Configuration;

# Make sure the last resort defaults are always defined
for my $required_rubies_desc (qw( !start_tag !end_tag !non_element )) {
    $HTML_Configuration::RUBY_CONFIG{$required_rubies_desc} //= [];
}

DESC: for my $rubies_desc (keys %HTML_Configuration::RUBY_CONFIG) {
    my $candidates = $HTML_Configuration::RUBY_CONFIG{$rubies_desc};
    next DESC if '!non_final_end' ~~ $candidates;
    $HTML_Configuration::RUBY_CONFIG{$rubies_desc} = [@{$candidates}, '!non_final_end'];
}

my %species_handler = (
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

my @core_rules = ();
my %tag_descriptor = ();

my %element_containments = ();
my %flow_containments = ();
my %element_defined = ();
my %element_included = ();
my %species_defined = ();
for my $bnf_set_data (
    [ \$HTML_Core::CORE_BNF,         1 ],
    [ \$HTML_Configuration::CONFIGURATION_BNF, 0 ]
    )
{
    my ( $bnf_set, $is_pure_bnf_rule_ok ) = @{$bnf_set_data};
    LINE: for my $line ( split /\n/xms, ${$bnf_set} ) {
        my $definition = $line;
        chomp $definition;
        $definition =~ s/ [#] .* //xms;    # Remove comments
        next LINE
            if not $definition =~ / \S /xms;    # ignore all-whitespace line
        my $sequence = ( $definition =~ s/ [*] \s* $//xms );
        if ( $definition =~ s/ \s* [:][:][=] \s* / /xms ) {

            die "Pure BNF rules are not allowed in the configuration"
                if not $is_pure_bnf_rule_ok;

            # Production is Ordinary BNF rule
            my @symbols = ( split q{ }, $definition );
            my $lhs = shift @symbols;
            for my $contained_element ( grep { ( substr $_, 0, 4 ) eq 'ELE_' }
                @symbols )
            {
                $element_included{$contained_element} = 1;
            }
            my %rule_descriptor = (
                lhs => $lhs,
                rhs => \@symbols,
            );
            if ($sequence) {
                $rule_descriptor{min} = 0;
            }
            if ( my $handler = $species_handler{$lhs} ) {
                $species_defined{$lhs} = 1;
                $rule_descriptor{action} = $handler;
            }
            elsif ( $lhs =~ /^ELE_/xms ) {
                push @{ $element_defined{$lhs} }, 'BNF';
                $rule_descriptor{action} = "$lhs";
            }
            push @core_rules, \%rule_descriptor;
            next LINE;
        } ## end if ( $definition =~ s/ \s* [:][:][=] \s* / /xms )
        if ($definition =~ m{
      \A \s* (ELE_\w+) \s+
      is \s+ included \s+ in \s+ (GRP_\w+) \s* \z}xms
            )
        {
            my $element = $1;
            my $group   = $2;
            push @core_rules,
                {
                lhs => $group,
                rhs => [$element],
                };
            $element_included{$element} = 1;
            next LINE;
        } ## end if ( $definition =~ m{ ) (})
        if ($definition =~ m{
      \A \s* ELE_(\w+) \s+
      is \s+ a \s+ (FLO_\w+) \s+
      included \s+ in \s+ (GRP_\w+) \s* \z}xms
            )
        {
            my $tag      = $1;
            my $contents = $2;
            my $group    = $3;
            push @{ $element_defined{ 'ELE_' . $tag } }, 'is-a-included';
            $element_included{ 'ELE_' . $tag } = 1;
            $tag_descriptor{$tag} = [ $group, $contents ];
            next LINE;
        } ## end if ( $definition =~ m{ ) (})
        if ( $definition
            =~ s/ \A \s* ELE_(\w+) \s+ is \s+ (FLO_\w+) \s* \z/ /xms )
        {
            # Production is Element with flow, but no group specified
            my $tag = $1;
            push @{ $element_defined{ 'ELE_' . $tag } }, 'is-a';
            my $contents        = $2;
            my $lhs             = 'ELE_' . $tag;
            my %rule_descriptor = (
                lhs    => $lhs,
                rhs    => [ "S_$tag", $contents, "E_$tag" ],
                action => $lhs
            );
            push @core_rules, \%rule_descriptor;
            next LINE;
        } ## end if ( $definition =~ ...)
        if ( $definition =~ s/ \A \s* ((ELE)_\w+) \s+ contains \s+ / /xms ) {

            # Production is Element with custom flow
            my $element_symbol = $1;
            my @contents = split q{ }, $definition;
            push @{ $element_defined{$element_symbol} },      'contains';
            push @{ $element_containments{$element_symbol} }, @contents;
            for my $contained_element ( grep { ( substr $_, 0, 4 ) eq 'ELE_' }
                @contents )
            {
                $element_included{$contained_element} = 1;
            }
            next LINE;
        } ## end if ( $definition =~ ...)
        if ( $definition =~ s/ \A \s* ((FLO)_\w+) \s+ contains \s+ / /xms ) {

            # Production is Flow
            my $element_symbol = $1;
            my @contents = split q{ }, $definition;
            push @{ $flow_containments{$element_symbol} }, @contents;
            next LINE;
        } ## end if ( $definition =~ ...)
        die "Badly formed line in grammar description: $line";
    } ## end LINE: for my $line ( split /\n/xms, ${$bnf_set} )
} ## end for my $bnf_set_data ( \[ \$HTML_Configuration::CORE_BNF, 0 ...])

{
    my @species_not_defined = grep { not defined $species_defined{$_} }
        keys %species_handler;
    if ( scalar @species_not_defined ) {
        die
            "Definitions for the following required text components are missing: ",
            join " ", @species_not_defined;
    }
}

ELEMENT: for my $element ( keys %element_defined ) {
    my $definitions = $element_defined{$element};
    if ( $definitions->[0] ne 'BNF'
        and !$element_included{$element} )
    {
        die "$element not included anywhere";
    }

    next ELEMENT if scalar @{$definitions} <= 1;
    my $first = $definitions->[0];
    if ( grep { $_ ne $first } @{$definitions} ) {
        die "$element multiply defined";
    }
} ## end ELEMENT: for my $element ( keys %element_defined )

# Check rules, prefixes starting with '_'
# are reserved.
# Actually, checking for starting with any non-alphabetic.

{
    my @symbols = map { $_->{lhs}, @{ $_->{rhs} } } @core_rules;
    push @symbols, keys %flow_containments, keys %element_containments;
    push @symbols, map { @{$_} } values %flow_containments,
        values %element_containments;
    my @reserved = grep { $_ =~ /\A [[:^alpha:]] /xms } @symbols;
    die "Reserved symbols in use: ", join " ", @reserved if scalar @reserved;
}

my %sgml_flow_included = ();
ELEMENT: for my $main_symbol ( keys %element_containments ) {
    my @contents        = @{ $element_containments{$main_symbol} };
    my $tag             = substr $main_symbol, 4;
    my $contents_symbol = '_C_ELE_' . $tag;
    my $item_symbol     = 'ITEM_ELE_' . $tag;
    push @core_rules, {
        lhs    => $main_symbol,
        rhs    => [ "S_$tag", $contents_symbol, "E_$tag" ],
        action => $main_symbol,
        },
        {
        lhs => $contents_symbol,
        rhs => [$item_symbol],
        min => 0
        };
    for my $content_item (@contents) {
        push @core_rules,
            {
            lhs => $item_symbol,
            rhs => [$content_item],
            };
    } ## end for my $content_item (@contents)
    if ( !$sgml_flow_included{$item_symbol} ) {
        $sgml_flow_included{$item_symbol} = 1;
        push @core_rules,
            {
            lhs => $item_symbol,
            rhs => ['ITEM_SGML'],
            };
    } ## end if ( !$sgml_flow_included{$item_symbol} )
} ## end ELEMENT: for my $main_symbol ( keys %element_containments )

ELEMENT: for my $main_symbol ( keys %flow_containments ) {
    my @contents    = @{ $flow_containments{$main_symbol} };
    my $item_symbol = 'ITEM_' . substr $main_symbol, 4;
    push @core_rules,
        {
        lhs => $main_symbol,
        rhs => [$item_symbol],
        min => 0
        };
    for my $content_item (@contents) {
        push @core_rules,
            {
            lhs => $item_symbol,
            rhs => [$content_item],
            };
    } ## end for my $content_item (@contents)
    if ( !$sgml_flow_included{$item_symbol} ) {
        $sgml_flow_included{$item_symbol} = 1;
        push @core_rules,
            {
            lhs => $item_symbol,
            rhs => ['ITEM_SGML'],
            };
    } ## end if ( !$sgml_flow_included{$item_symbol} )
} ## end ELEMENT: for my $main_symbol ( keys %flow_containments )

{
    # Make sure all item symbols have a flow
    my @symbols = map { $_->{lhs}, @{ $_->{rhs} } } @core_rules;
    my %ITEM_symbols =
        map { $_ => 1 } grep { ( substr $_, 0, 5 ) eq 'ITEM_' } @symbols;
    my %FLO_symbols =
        map { $_ => 1 } grep { ( substr $_, 0, 4 ) eq 'FLO_' } @symbols;
    my %ELE_symbols =
        map { $_ => 1 } grep { ( substr $_, 0, 4 ) eq 'ELE_' } @symbols;
    my @problem = ();
    ITEM: for my $item_symbol ( keys %ITEM_symbols ) {
        if ( ( substr $item_symbol, 0, 9 ) eq 'ITEM_ELE_' ) {
            push @problem, "No matching element for $item_symbol"
                if not defined $ELE_symbols{ substr $item_symbol, 5 };
            next ITEM;
        }
        push @problem, "No matching flow for $item_symbol"
            if not
                defined $FLO_symbols{ 'FLO_' . ( substr $item_symbol, 5 ) };
    } ## end ITEM: for my $item_symbol ( keys %ITEM_symbols )
    die join "\n", @problem if scalar @problem;
}

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

{
    # Check that the tag descriptors refer to groups and flows
    # which are defined
    my %flows =
        map { $_ => 'core' }
        grep {m/\A FLO_ /xms} map { $_->{lhs} } @core_rules;
    my %groups =
        map { $_ => 'core' }
        grep {m/\A GRP_ /xms} map { $_->{lhs}, @{ $_->{rhs} } } @core_rules;
    for my $tag ( keys %tag_descriptor ) {
        my ( $group, $flow ) = @{ $tag_descriptor{$tag} };
        die qq{$tag is a "$flow", which is not defined}
            if not $flows{$flow};
        die qq{$tag included in "$group", which is not defined}
            if not $groups{$group};
    } ## end for my $tag ( keys %tag_descriptor )
}

{
    # Find the tag descriptors which refer to required
    # elements and add them

    # Required elements are those which we may have to
    # supply even though they are not in the physical input

    # Anything which has a start tag among the ruby candidates
    # is required, since we may be required to create a
    # non-physical one
    my @ruby_start_tags =
        grep { ( substr $_, 0, 2 ) eq 'S_' }
        map { @{$_} } values %HTML_Configuration::RUBY_CONFIG;

    my %defined_in_core_rules =
        map { ( substr $_, 4 ) => 'core' }
        grep {m/\A ELE_ /xms} map { $_->{lhs} } @core_rules;

    my %required_tags = map { ( substr $_, 2 ) => 1 } @ruby_start_tags;
    TAG: for my $tag ( keys %required_tags ) {
        next TAG if $defined_in_core_rules{$tag};
        my ( $group, $flow ) = @{ $tag_descriptor{$tag} };
        my $element = 'ELE_' . $tag;
        push @core_rules,
            {
            lhs    => $element,
            rhs    => [ "S_$tag", $flow, "E_$tag" ],
            action => $element
            },
            {
            lhs => $group,
            rhs => [$element],
            };
        delete $tag_descriptor{$tag};
    } ## end TAG: for my $tag ( keys %required_tags )
}

$Data::Dumper::Purity = 1;
$Data::Dumper::Sortkeys = 1;
$output .= Data::Dumper->Dump( [ \@core_rules ], [qw(CORE_RULES)] );

$output .= Data::Dumper->Dump( [ \%tag_descriptor ], [qw(TAG_DESCRIPTOR)] );

{
    my @mentioned_in_core =
        map { substr $_, 4 }
        grep {m/\A ELE_ /xms} map { @{ $_->{rhs} } } @core_rules;
    my %defined_in_core =
        map { ( substr $_, 4 ) => 'core' }
        grep {m/\A ELE_ /xms} map { $_->{lhs} } @core_rules;
    my @symbols_with_no_ruby_status =
        grep { !$defined_in_core{$_} and !$tag_descriptor{$_} } @mentioned_in_core;
    die "symbols with no ruby status: ", join " ",
        @symbols_with_no_ruby_status
        if scalar @symbols_with_no_ruby_status;
}

my %ruby_rank = ();
for my $rejected_symbol (keys %HTML_Configuration::RUBY_CONFIG) {
  my $rank = 1;
  for my $candidate (reverse @{$HTML_Configuration::RUBY_CONFIG{$rejected_symbol}})
  {
     $ruby_rank{$rejected_symbol}{$candidate} = $rank++;
  }
}

$output .= Data::Dumper->Dump( [ \%ruby_rank ], [qw(RUBY_SLIPPERS_RANK_BY_NAME)] );

open my $out_fh, q{>}, 'Definition.pm';
say {$out_fh} $output;
close $out_fh;
