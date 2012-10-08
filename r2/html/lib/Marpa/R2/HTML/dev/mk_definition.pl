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

my %predefined_groups =
    ( GRP_mixed => [qw( GRP_anywhere GRP_block GRP_inline cdata pcdata)] );

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
my %symbol_defined = ();
my %symbol_included = ();
my %core_symbol = ();

{
    LINE: for my $line ( split /\n/xms, $HTML_Core::CORE_BNF ) {
        my $definition = $line;
        chomp $definition;
        $definition =~ s/ [#] .* //xms;    # Remove comments
        next LINE
            if not $definition =~ / \S /xms;    # ignore all-whitespace line
        my $sequence = ( $definition =~ s/ [*] \s* $//xms );
        if ( $definition =~ s/ \s* [:][:][=] \s* / /xms ) {

            # Production is Ordinary BNF rule
            my @symbols = ( split q{ }, $definition );
            my $lhs = shift @symbols;
	    @{$symbol_defined{$lhs} } = ('BNF');
	    $core_symbol{$lhs} = 1;
	    for my $symbol (@symbols) {
	      $symbol_included{$symbol} = 1;
	      $core_symbol{$symbol} = 1;
	    }

            my %rule_descriptor = (
                lhs => $lhs,
                rhs => \@symbols,
            );
            if ($sequence) {
                $rule_descriptor{min} = 0;
            }
            if ( my $handler = $species_handler{$lhs} ) {
                $rule_descriptor{action} = $handler;
            }
            elsif ( $lhs =~ /^ELE_/xms ) {
                $rule_descriptor{action} = "$lhs";
            }
            push @core_rules, \%rule_descriptor;
            next LINE;
        } ## end if ( $definition =~ s/ \s* [:][:][=] \s* / /xms )
        die "Badly formed line in grammar description: $line";
    } ## end LINE: for my $line ( split /\n/xms, $HTML_Core::CORE_BNF )
}

# A few symbols are allowed as contents as special cases
my %allowed_contents = map { $_ => 1 } qw(cdata pcdata);
my %banned_contents = grep { not $_ =~ m/\A GRP_ /xms } %core_symbol;

{
    my @species_not_defined = grep { not defined $symbol_defined{$_} }
        keys %species_handler;
    if ( scalar @species_not_defined ) {
        die
            "Definitions for the following required text components are missing: ",
            join " ", @species_not_defined;
    }
}

LINE: for my $line ( split /\n/xms, $HTML_Configuration::CONFIGURATION_BNF ) {
    my $definition = $line;
    chomp $definition;
    $definition =~ s/ [#] .* //xms;    # Remove comments
    next LINE
        if not $definition =~ / \S /xms;    # ignore all-whitespace line
    if ($definition =~ m{
      \A \s* (ELE_\w+) \s+
      is \s+ included \s+ in \s+ (GRP_\w+) \s* \z}xms
        )
    {
        my $element = $1;
        my $group   = $2;
	die "Core symbol context cannot be changed: $definition"
	    if $core_symbol{$element};
        push @core_rules,
            {
            lhs => $group,
            rhs => [$element],
            };
        $symbol_included{$element} = 1;
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
	my $element = 'ELE_' . $tag;
	die "Core symbol context cannot be changed: $definition"
	    if $core_symbol{$element};
        push @{ $symbol_defined{ $element } }, 'is-a-included';
        $symbol_included{ $element } = 1;
        $tag_descriptor{$tag} = [ $group, $contents ];
        next LINE;
    } ## end if ( $definition =~ m{ ) (})
    if ($definition =~ s/ \A \s* ELE_(\w+) \s+ is \s+ (FLO_\w+) \s* \z/ /xms )
    {
        # Production is Element with flow, but no group specified
        my $tag = $1;
        push @{ $symbol_defined{ 'ELE_' . $tag } }, 'is-a';
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
	@contents = map { defined $predefined_groups{$_} ?  @{$predefined_groups{$_}  } : $_ } @contents;
        push @{ $symbol_defined{$element_symbol} },      'contains';
        push @{ $element_containments{$element_symbol} }, @contents;
	
        for my $contained_symbol ( @contents )
        {
            if ( not $allowed_contents{$contained_symbol} ) {
                die
                    qq{Symbol "$contained_symbol" cannot be in the contents of an element: },
                    $line
                    if $banned_contents{$contained_symbol};
		my $prefix = substr $contained_symbol, 0, 4;
                die qq{Symbol "$contained_symbol" is not an element or a group: }, $line
                    if $prefix ne 'ELE_' and $prefix ne 'GRP_';
            } ## end if ( not $allowed_contents{$contained_symbol} )
            $symbol_included{$contained_symbol} = 1;
        }
        next LINE;
    } ## end if ( $definition =~ ...)
    if ( $definition =~ s/ \A \s* ((FLO)_\w+) \s+ contains \s+ / /xms ) {

        die "Not yet implemented: ", $definition;

        # Production is Flow
        my $flow_symbol = $1;
        my @contents = split q{ }, $definition;
        push @{ $flow_containments{$flow_symbol} }, @contents;
        next LINE;
    } ## end if ( $definition =~ ...)
    die "Badly formed line in grammar description: $line";
} ## end LINE: for my $line ( split /\n/xms, ...)

ELEMENT: for my $element ( keys %symbol_defined ) {
    my $definitions = $symbol_defined{$element};
    if ( $definitions->[0] ne 'BNF'
        and !$symbol_included{$element} )
    {
        die "$element not included anywhere";
    }

    next ELEMENT if scalar @{$definitions} <= 1;
    my $first = $definitions->[0];
    if ( grep { $_ ne $first } @{$definitions} ) {
        die "$element multiply defined";
    }
} ## end ELEMENT: for my $element ( keys %symbol_defined )

my %sgml_flow_included = ();
ELEMENT: for my $main_symbol ( keys %element_containments ) {
    my @contents        = @{ $element_containments{$main_symbol} };
    my $tag             = substr $main_symbol, 4;
    my $contents_symbol = 'Contents_ELE_' . $tag;
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
    die "Internal: Flow containments not yet implemented";
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
    # Make sure groups are non-overlapping
    my %group_rules =
        map { $_->{lhs}, $_->{rhs} }
        grep { ( substr $_->{lhs}, 0, 4 ) eq 'GRP_' } @core_rules;
    my %group_by_member = ();
    my %members_by_group = ();
    while ( my ( $group, $contents ) = each %group_rules ) {
	die "Misformed rule for group contents: $group ::= ", join " ",
	    @{$contents} if scalar @{$contents} != 1;
        my $member = $contents->[0];
            die qq{"$member" is a member of two groups: "$group" and "},
                $group_by_member{$member}
                if defined $group_by_member{$member};
            $group_by_member{$member} = $group;
	    push @{$members_by_group{$group}}, $member;
    } ## end while ( my ( $group, $contents ) = each %group_rules )
    for my $tag (keys %tag_descriptor) {
        my $descriptor = $tag_descriptor{$tag};
        my ($group)    = @{$descriptor};
        my $member     = 'ELE_' . $tag;
        die qq{"$member" is a member of two groups: "$group" and "},
            $group_by_member{$member}
            if defined $group_by_member{$member};
	$group_by_member{$member} = $group;
	push @{$members_by_group{$group}}, $member;
    } ## end for my $tag (%tag_descriptor)

    # Now ensure item lists are non-overlapping
    my @item_rules =
        grep { ( substr $_->{lhs}, 0, 5 ) eq 'ITEM_' } @core_rules;

    my %members_by_item_list = ();
    for my $rule (@item_rules) {
	my $item_list = $rule->{lhs};
	my $rhs = $rule->{rhs};
        die "Misformed rule for item list contents: $item_list ::= ",
            join " ", @{$rhs}
            if scalar @{$rhs} != 1;
        my $raw_member =  $rhs->[0] ;
        my @members = ( $raw_member );
        if ( ( substr $raw_member, 0, 4 ) eq 'GRP_' ) {
            @members = @{ $members_by_group{$raw_member} };
        }

        for my $member (@members) {

            my $count = $members_by_item_list{$item_list}{$member}++;
            if ( $count > 0 ) {
                die qq{"$member" is in item list "$item_list" more than once};
            }
        } ## end for my $member (@members)
    } ## end while ( my ( $item_list, $contents ) = each %item_rules)
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
        my $descriptor = $tag_descriptor{$tag};
	die qq{Required element "ELE_$tag" was never defined}
	   if not defined $descriptor;
        my ( $group, $flow ) = @{$descriptor};
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
