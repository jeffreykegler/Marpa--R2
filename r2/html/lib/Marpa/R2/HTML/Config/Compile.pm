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

package Marpa::R2::HTML::Config::Compile;

use 5.010;
use strict;
use warnings;
use Data::Dumper;

use English qw( -no_match_vars );

use Marpa::R2::HTML::Config::Core;
use Marpa::R2::Thin::Trace;

# Indexes into the symbol table
use constant CONTEXT_CLOSED  => 0;
use constant CONTENTS_CLOSED => 1;
use constant CONTEXT         => 2;
use constant CONTENTS        => 3;

sub compile {
    my ($source_ref) = @_;

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

    my @core_rules           = ();
    my %runtime_tag          = ();
    my %primary_group_by_tag = ();

    {
        LINE: for my $line ( split /\n/xms, $HTML_Core::CORE_BNF ) {
            my $definition = $line;
            chomp $definition;
            $definition =~ s/ [#] .* //xms;    # Remove comments
            next LINE
                if not $definition =~ / \S /xms;  # ignore all-whitespace line
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

    my @core_symbols = map { $_->{lhs}, @{ $_->{rhs} } } @core_rules;

    # Start out by closing the context and contents of everything
    my %symbol_table = map {
        $_ =>
            [ 'Reserved by the core grammar', 'Reserved by the core grammar' ]
    } @core_symbols;

    # A few token symbols are allowed as contents -- most non-element
    # tokens are included via the SGML group
    for my $token_symbol (qw(cdata pcdata)) {
        $symbol_table{$token_symbol}->[CONTEXT_CLOSED] = 0;
    }

    # Many groups are defined to to be used
    for my $group_symbol (
        qw( GRP_anywhere GRP_pcdata GRP_cdata GRP_mixed GRP_block GRP_head GRP_inline)
        )
    {
        $symbol_table{$group_symbol}->[CONTEXT_CLOSED] = 0;
    } ## end for my $group_symbol ( ...)

    # Flow symbols are almost all allowed as contents
    FLOW_SYMBOL:
    for my $flow_symbol ( grep { $_ =~ m/\A FLO_ /xms } @core_symbols ) {

        # The SGML flow is included automatically as needed
        # and should not be explicity specified
        next FLOW_SYMBOL if $flow_symbol eq 'FLO_SGML';
        $symbol_table{$flow_symbol}->[CONTEXT_CLOSED] = 0;
    } ## end for my $flow_symbol ( grep { $_ =~ m/\A FLO_ /xms } ...)

    # A few groups are also extensible
    for my $group_symbol (qw( GRP_anywhere GRP_block GRP_head GRP_inline )) {
        $symbol_table{$group_symbol}->[CONTENTS_CLOSED] = 0;
    }

    # As very special cases the contents of the <head> and <body>
    # elements can be changed
    for my $element_symbol (qw( ELE_head ELE_body )) {
        $symbol_table{$element_symbol}->[CONTENTS_CLOSED] = 0;
    }

    {
        # Make sure everything for which we have a handler was defined in
        # the core grammar
        my @species_not_defined = grep { not defined $symbol_table{$_} }
            keys %species_handler;
        if ( scalar @species_not_defined ) {
            die
                "Definitions for the following required text components are missing: ",
                join " ", @species_not_defined;
        }
    }

    my %ruby_config = ();
    my %lists       = ();

    LINE:
    for my $line ( split /\n/xms, ${$source_ref} ) {
        my $definition = $line;
        chomp $definition;
        $definition =~ s/ [#] .* //xms;    # Remove comments
        next LINE
            if not $definition =~ / \S /xms;    # ignore all-whitespace line
        if ($definition =~ m{
	\A \s* [<](\w+)[>] \s+
	is \s+ included \s+ in \s+ [%](\w+) \s* \z}xms
            )
        {
            my $tag = $1;
            my $element       = 'ELE_' . $tag;
            my $group         = 'GRP_' . $2;
            my $element_entry = $symbol_table{$element} //= [];
            my $group_entry   = $symbol_table{$group};

            # For now, new groups cannot be defined
            Carp::croak(
                qq{Group "$group" does not exist\n},
                qq{  Problem was in this line: $line}
            ) if not defined $group_entry;

            my $closed_reason = $element_entry->[CONTEXT_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Context of "$element" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)
            $closed_reason = $group_entry->[CONTENTS_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Contents of "$group" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)


            # If this is the first, it sets the primary group
            $primary_group_by_tag{$tag} //= $group;
            push @{ $element_entry->[CONTEXT] }, $group;

            next LINE;

        } ## end if ( $definition =~ m{ ) (})
        if ($definition =~ m{
	\A \s* [<](\w+)[>] \s+
	is \s+ a \s+ [*](\w+) \s+
      included \s+ in \s+ [%](\w+) \s* \z}xms
            )
        {
            my $tag           = $1;
            my $flow          = 'FLO_' . $2;
            my $group         = 'GRP_' . $3;
            my $element       = 'ELE_' . $tag;
            my $element_entry = $symbol_table{$element} //= [];
            my $group_entry   = $symbol_table{$group};
            my $flow_entry    = $symbol_table{$flow};

            # For now, new flows and groups cannot be defined
            Carp::croak(
                qq{Group "$group" does not exist\n},
                qq{  Problem was in this line: $line}
            ) if not defined $group_entry;
            Carp::croak(
                qq{Flow "$flow" does not exist\n},
                qq{  Problem was in this line: $line}
            ) if not defined $flow_entry;

            my $closed_reason = $element_entry->[CONTEXT_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Context of "$element" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)
            $closed_reason = $element_entry->[CONTENTS_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Contents of "$element" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)
            $closed_reason = $flow_entry->[CONTEXT_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Context of "$flow" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)
            $closed_reason = $group_entry->[CONTENTS_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Contents of "$group" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)

            Carp::croak(
                qq{Contents of "$element" are already being defined:\n},
                qq{  Problem was in this line: $line} )
                if defined $element_entry->[CONTENTS];
            Carp::croak(
                qq{Context of "$element" is already being defined:\n},
                qq{  Problem was in this line: $line} )
                if defined $element_entry->[CONTEXT];

            # Always sets the primary group
            $primary_group_by_tag{$tag} = $group;
            $element_entry->[CONTENTS]  = $flow;
            $element_entry->[CONTEXT]   = $group;
            $element_entry->[CONTEXT_CLOSED] =
                $element_entry->[CONTENTS_CLOSED] =
                'Element is already fully defined';

            next LINE;
        } ## end if ( $definition =~ m{ ) (})

        if ( $definition
            =~ s/ \A \s* [<](\w+)[>] \s+ is \s+ [*](\w+) \s* \z/ /xms )
        {
            # Production is Element with flow, but no group specified
            my $tag           = $1;
            my $flow          = 'FLO_' . $2;
            my $element       = 'ELE_' . $tag;
            my $element_entry = $symbol_table{$element} //= [];
            my $flow_entry    = $symbol_table{$flow};

            # For now, new flows cannot be defined
            Carp::croak(
                qq{Flow "$flow" does not exist\n},
                qq{  Problem was in this line: $line}
            ) if not defined $flow_entry;

            my $closed_reason = $element_entry->[CONTENTS_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Contents of "$element" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)
            $closed_reason = $flow_entry->[CONTEXT_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Context of "$flow" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)

            Carp::croak(
                qq{Contents of "$element" are already being defined:\n},
                qq{  Problem was in this line: $line} )
                if defined $element_entry->[CONTENTS];

            $element_entry->[CONTENTS] = $flow;
            $element_entry->[CONTENTS_CLOSED] =
                'Contents of Element are already defined';

            next LINE;
        } ## end if ( $definition =~ ...)
        if ( $definition =~ s/ \A \s* [<](\w+)[>] \s+ contains \s+ / /xms ) {

            # Production is Element with custom flow
            my $tag = $1;
            my $element_symbol = 'ELE_' . $tag;
            my $element_entry  = $symbol_table{$element_symbol} //= [];
            my $closed_reason  = $element_entry->[CONTENTS_CLOSED];
            if ($closed_reason) {
                Carp::croak(
                    qq{Contents of "$element_symbol" cannot be changed:\n},
                    qq{  Reason: $closed_reason\n},
                    qq{  Problem was in this line: $line}
                );
            } ## end if ($closed_reason)

            my @external_contents = split q{ }, $definition;
	    my @contents = ();

            CONTAINED_SYMBOL: for my $external_content_symbol (@external_contents) {
		my $content_symbol;
		if ($external_content_symbol =~ /\A [<] (\w+) [>] \z/xms) {
		    $content_symbol = 'ELE_' . $1;
		}
		if ($external_content_symbol =~ /\A [%] (\w+)  \z/xms) {
		    $content_symbol = 'GRP_' . $1;
		}
		$content_symbol //= $external_content_symbol;
                my $content_entry = $symbol_table{$content_symbol};
                if ( not defined $content_entry ) {
                    if ( not $content_symbol =~ /\A ELE_ /xms ) {
                        Carp::croak(
                            qq{Symbol "$external_content_symbol" is undefined\n},
                            qq{  Problem was in this line: $line}
                        ) if not defined $content_entry;
                    } ## end if ( not $content_symbol =~ /\A ELE_ /xms )
                    $content_entry = [];
                } ## end if ( not defined $content_entry )
                $closed_reason = $content_entry->[CONTEXT_CLOSED];
                if ($closed_reason) {
                    Carp::croak(
                        qq{Context of "$external_content_symbol" cannot be changed:\n},
                        qq{  Reason: $closed_reason\n},
                        qq{  Problem was in this line: $line}
                    );
                } ## end if ($closed_reason)
		push @contents, $content_symbol;
            } ## end CONTAINED_SYMBOL: for my $content_symbol (@contents)

            push @{ $element_entry->[CONTENTS] }, @contents;

            next LINE;
        } ## end if ( $definition =~ ...)
        if ( $definition =~ s/ \A \s* [@](\w+) \s* = \s* / /xms ) {
            my $new_list = $1;
            die "Problem in line: $line\n",
                'list @' . $new_list . ' is already defined'
                if defined $lists{$new_list};
            my @raw_members = split q{ }, $definition;
            my @members = ();
            RAW_MEMBER: for my $raw_member (@raw_members) {
                if ( $raw_member =~ / \A [@] (.*) \z/xms ) {
                    my $member_list = $1;
                    die "Problem in line: $line\n",
                        'member list @' . $member_list . ' is not yet defined'
                        if not defined $lists{$member_list};
                    push @members, @{ $lists{$member_list} };
                    next RAW_MEMBER;
                } ## end if ( $raw_member =~ / \A [@] (.*) \z/xms )
                push @members, $raw_member;
            } ## end RAW_MEMBER: for my $raw_member (@raw_members)
            $lists{$new_list} = \@members;
            next LINE;
        } ## end if ( $definition =~ s/ \A \s* [@](\w+) \s* = \s* / /xms)
        if ( $definition =~ s{ \A \s* ([\w<*%>/]+) \s* [-][>] \s* }{}xms ) {
            my $rejected_symbol = $1;
            my @raw_candidates  = split q{ }, $definition;
            my @symbols         = ($rejected_symbol);
            RAW_CANDIDATE: for my $raw_candidate (@raw_candidates) {
                if ( $raw_candidate =~ / \A [@] (.*) \z/xms ) {
                    my $list = $1;
                    die "Problem in line: $line\n",
                        'candidate list @' . $list . ' is not yet defined'
                        if not defined $lists{$list};
                    push @symbols, @{ $lists{$list} };
                    next RAW_CANDIDATE;
                } ## end if ( $raw_candidate =~ / \A [@] (.*) \z/xms )
                push @symbols, $raw_candidate;
            } ## end RAW_CANDIDATE: for my $raw_candidate (@raw_candidates)
            my @internal_symbols = ();
            SYMBOL: for my $symbol (@symbols) {
                if ( $symbol =~ /\A (EOF|CDATA|PCDATA) \z/xms ) {
                    push @internal_symbols, $symbol;
                    next SYMBOL;
                }
                if ( $symbol
                    =~ /\A ( [<] [%] (inline|head|block) [>] ) \z/xms )
                {
                    my $special_symbol = $1;
                    push @internal_symbols, $special_symbol;
                    next SYMBOL;
                } ## end if ( $symbol =~ ...)
                if ( $symbol
                    =~ m{\A ( [<] [/] [%] (inline|head|block) [>] ) \z}xms )
                {
                    my $special_symbol = $1;
                    push @internal_symbols, $special_symbol;
                    next SYMBOL;
                } ## end if ( $symbol =~ ...)
                if ( $symbol =~ m{\A ( [<] [*] [>] ) \z}xms ) {
                    my $special_symbol = $1;
                    push @internal_symbols, $special_symbol;
                    next SYMBOL;
                }
                if ( $symbol =~ m{\A ( [<] [/] [*] [>] ) \z}xms ) {
                    my $special_symbol = $1;
                    push @internal_symbols, $special_symbol;
                    next SYMBOL;
                }
                if ( $symbol =~ /\A [<] (\w+) [>] \z/xms ) {
                    my $start_tag = 'S_' . $1;
                    push @internal_symbols, $start_tag;
                    next SYMBOL;
                }
                if ( $symbol =~ m{\A [<] [/](\w+) [>] \z}xms ) {
                    my $end_tag = 'E_' . $1;
                    push @internal_symbols, $end_tag;
                    next SYMBOL;
                }
                die "Problem in line: $line\n",
                    qq{Misformed symbol "$symbol"};
            } ## end SYMBOL: for my $symbol (@symbols)
            $rejected_symbol = shift @internal_symbols;
            $ruby_config{$rejected_symbol} = \@internal_symbols;
            next LINE;
        } ## end if ( $definition =~ ...)
        die "Badly formed line in grammar description: $line";
    } ## end LINE: for my $line ( split /\n/xms, ${$source_ref} )

    my %sgml_flow_included = ();
    SYMBOL: for my $element_symbol ( keys %symbol_table ) {
        next SYMBOL if not 'ELE_' eq substr $element_symbol, 0, 4;
        my $tag      = substr $element_symbol, 4;
        my $entry    = $symbol_table{$element_symbol};
        my $context  = $entry->[CONTEXT];
        my $contents = $entry->[CONTENTS];
        next SYMBOL if not defined $context and not defined $contents;
        if ( defined $context and not defined $contents ) {
            Carp::croak(
                qq{Element <$tag> was defined but was never given any contents}
            );
        }

        # Contents without context are OK at this point
        # We will check later for elements defined but not used
        $context //= [];

        # The special case where both are defined and both
        # are scalars is for elements to be created at runtime
        if ( not ref $context and not ref $contents ) {
            $runtime_tag{$tag} = $contents;
            next SYMBOL;
        }

        if ( ref $contents ) {
            my $contents_symbol = 'Contents_ELE_' . $tag;
            my $item_symbol     = 'GRP_ELE_' . $tag;
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
            for my $content_item ( @{$contents} ) {
                push @core_rules,
                    {
                    lhs => $item_symbol,
                    rhs => [$content_item],
                    };
            } ## end for my $content_item ( @{$contents} )
            if ( !$sgml_flow_included{$item_symbol} ) {
                $sgml_flow_included{$item_symbol} = 1;
                push @core_rules,
                    {
                    lhs => $item_symbol,
                    rhs => ['GRP_SGML'],
                    };
            } ## end if ( !$sgml_flow_included{$item_symbol} )
        } ## end if ( ref $contents )
        else {
            push @core_rules,
                {
                lhs    => $element_symbol,
                rhs    => [ "S_$tag", $contents, "E_$tag" ],
                action => $element_symbol,
                };
        } ## end else [ if ( ref $contents ) ]

        $context = [$context] if not ref $context;
        for my $context_item ( @{$context} ) {
            push @core_rules,
                {
                lhs => $context_item,
                rhs => [$element_symbol],
                };
        } ## end for my $context_item ( @{$context} )
    } ## end SYMBOL: for my $element_symbol ( keys %symbol_table )

    # Finish out the Ruby Slippers configuration
    # Make sure the last resort defaults are always defined
    for my $required_rubies_desc (qw( <*> </*> <!element> )) {
        $ruby_config{$required_rubies_desc} //= [];
    }

    DESC: for my $rubies_desc ( keys %ruby_config ) {
        my $candidates = $ruby_config{$rubies_desc};
        next DESC if '</*>' ~~ $candidates;
        $ruby_config{$rubies_desc} = [ @{$candidates}, '</*>' ];
    }

    my %is_empty_element = ();
    {
        for my $tag ( keys %runtime_tag ) {
            my $contents = $runtime_tag{$tag};
            $is_empty_element{$tag} = 1 if $contents eq 'FLO_empty';
        }
        RULE: for my $rule (@core_rules) {
            my $lhs = $rule->{lhs};
            next RULE if not 'ELE_' eq substr $lhs, 0, 4;
            my $contents = $rule->{rhs}->[1];
            $is_empty_element{ substr $lhs, 4 } = 1
                if $contents eq 'FLO_empty';
        } ## end RULE: for my $rule (@core_rules)
    }

    {
        # Make sure no ruby candidates or rejected symbols are
        # end tags of empty elements
        SYMBOL: for my $rejected_symbol ( keys %ruby_config ) {
            next SYMBOL if 'E_' ne substr $rejected_symbol, 0, 2;
            my $tag = substr $rejected_symbol, 2;
            next SYMBOL if not $is_empty_element{$tag};
            Carp::croak(
                qq{Ruby Slippers alternatives specified for </$tag>\n},
                qq{  "$tag" is an empty element and this is not allowed"}
            );
        } ## end SYMBOL: for my $rejected_symbol ( keys %ruby_config )
        SYMBOL:
        for my $candidate_symbol ( map { @{$_} } values %ruby_config )
        {
            next SYMBOL if 'E_' ne substr $candidate_symbol, 0, 2;
            my $tag = substr $candidate_symbol, 2;
            next SYMBOL if not $is_empty_element{$tag};
            Carp::croak(
                qq{Tag </$tag> specified as a Ruby Slippers alternative\n},
                qq{  "$tag" is an empty element and this is not allowed"}
            );
        } ## end for my $candidate_symbol ( map { @{$_} } values ...)
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
            map { @{$_} } values %ruby_config;

        my %defined_in_core_rules =
            map { ( substr $_, 4 ) => 'core' }
            grep {m/\A ELE_ /xms} map { $_->{lhs} } @core_rules;

        my %required_tags = map { ( substr $_, 2 ) => 1 } @ruby_start_tags;
        TAG: for my $tag ( keys %required_tags ) {
            next TAG if $defined_in_core_rules{$tag};
            my $flow = $runtime_tag{$tag};
            die qq{Required element "ELE_$tag" was never defined}
                if not defined $flow;
            my $group   = $primary_group_by_tag{$tag};
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
            delete $runtime_tag{$tag};
        } ## end TAG: for my $tag ( keys %required_tags )
    }

    {
        my @mentioned_in_core =
            map { substr $_, 4 }
            grep {m/\A ELE_ /xms} map { @{ $_->{rhs} } } @core_rules;
        my %defined_in_core =
            map { ( substr $_, 4 ) => 'core' }
            grep {m/\A ELE_ /xms} map { $_->{lhs} } @core_rules;
        my @symbols_with_no_ruby_status =
            grep { !$defined_in_core{$_} and !$runtime_tag{$_} }
            @mentioned_in_core;
        die "symbols with no ruby status: ", join " ",
            @symbols_with_no_ruby_status
            if scalar @symbols_with_no_ruby_status;
    }

    # Calculate the numeric Ruby ranks
    my %ruby_rank = ();
    for my $rejected_symbol ( keys %ruby_config ) {
        my $rank = 1;
        for my $candidate ( reverse @{ $ruby_config{$rejected_symbol} } ) {
            $ruby_rank{$rejected_symbol}{$candidate} = $rank++;
        }
    } ## end for my $rejected_symbol ( keys %ruby_config )

    {
        my %element_used =
            map { ( $_ => 1 ) }
            grep {m/\A ELE_ /xms} map { @{ $_->{rhs} } } @core_rules;
        my @elements_defined_but_not_used =
            grep { !$element_used{$_} }
            grep {m/\A ELE_ /xms} map { $_->{lhs} } @core_rules;
        die "elements defined but never used: ", join " ",
            @elements_defined_but_not_used
            if scalar @elements_defined_but_not_used;
    }

    {
        my %seen = ();
        for my $rule (@core_rules) {
            my $lhs  = $rule->{lhs};
            my $rhs  = $rule->{rhs};
            my $desc = join q{ }, $lhs, '::=', @{$rhs};
            if ( $seen{$desc} ) {
                Carp::croak("Duplicate rule: $desc");
            }
            $seen{$desc}++;
        } ## end for my $rule (@core_rules)
    }

    return {
        rules                      => \@core_rules,
        runtime_tag                => \%runtime_tag,
        ruby_slippers_rank_by_name => \%ruby_rank,
        is_empty_element           => \%is_empty_element,
        primary_group_by_tag       => \%primary_group_by_tag
    };

} ## end sub compile

1;
