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
use warnings;
use strict;
use integer;

package Marpa::R2::HTML::Callback;

use vars qw( $VERSION $STRING_VERSION );
$VERSION = '2.021_000';
$STRING_VERSION = $VERSION;
## use critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## no critic

package Marpa::R2::HTML::Internal::Callback;

use English qw( -no_match_vars );

sub Marpa::R2::HTML::start_tag {

    my $parse_instance = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    Marpa::R2::exception(q{Attempt to fetch start tag outside of a parse})
        if not defined $parse_instance;
    return undef if not defined $Marpa::R2::HTML::Internal::START_TAG_IX;

    return ${
        Marpa::R2::HTML::Internal::token_range_to_original(
            $parse_instance,
            $Marpa::R2::HTML::Internal::START_TAG_IX,
            $Marpa::R2::HTML::Internal::START_TAG_IX
        )
        };

} ## end sub Marpa::R2::HTML::start_tag

# We do not always need the end tag, so it is found lazily,
# unlike the start tag which is determined eagerly.
# Return the end token ix, or undef if none.
# As a side effect set $Marpa::R2::HTML::Internal::END_TAG_IX_REF
# to be a reference to that result
sub end_tag_set {

    my $parse_instance = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;

    # be idempotent -- but this is probably unnecessary
    return ${$Marpa::R2::HTML::Internal::END_TAG_IX_REF}
        if defined $Marpa::R2::HTML::Internal::END_TAG_IX_REF;

    # default to no end tag
    $Marpa::R2::HTML::Internal::END_TAG_IX_REF = \undef;

    # return undef if the current rule is not an element
    return undef if not $Marpa::R2::HTML::Internal::ELEMENT;

    my $arg_n              = $Marpa::R2::HTML::Internal::ARG_N;
    my $end_tag_tdesc_item = $Marpa::R2::HTML::Internal::STACK->[$arg_n];
    my $end_tag_type       = $end_tag_tdesc_item->[0];

    return undef if not defined $end_tag_type;
    return undef if $end_tag_type ne 'PHYSICAL_TOKEN';

    my $end_tag_token_ix =
        $end_tag_tdesc_item->[Marpa::R2::HTML::Internal::TDesc::END_TOKEN];
    my $tokens     = $parse_instance->{tokens};
    my $html_token = $tokens->[$end_tag_token_ix];
    my $html_token_type =
        $html_token->[Marpa::R2::HTML::Internal::Token::TYPE];
    return undef if $html_token_type ne 'E';
    $Marpa::R2::HTML::Internal::END_TAG_IX_REF = \$end_tag_token_ix;
    return $end_tag_token_ix;

} ## end sub end_tag_set

sub Marpa::R2::HTML::end_tag {

    my $parse_instance = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    Marpa::R2::exception(q{Attempt to fetch an end tag outside of a parse})
        if not defined $parse_instance;
    defined $Marpa::R2::HTML::Internal::END_TAG_IX_REF or end_tag_set();
    my $end_tag_token_ix = ${$Marpa::R2::HTML::Internal::END_TAG_IX_REF};
    return undef if not defined $end_tag_token_ix;

    return ${
        Marpa::R2::HTML::Internal::token_range_to_original( $parse_instance,
            $end_tag_token_ix, $end_tag_token_ix, )
        };
} ## end sub Marpa::R2::HTML::end_tag

sub Marpa::R2::HTML::contents {

    my $self = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    Marpa::R2::exception(
        q{Attempt to fetch an element contents outside of a parse})
        if not defined $self;

    return undef if not $Marpa::R2::HTML::Internal::ELEMENT;

    my $contents_start_ix =
        defined $Marpa::R2::HTML::Internal::START_TAG_IX
        ? $Marpa::R2::HTML::Internal::START_TAG_IX + 1
        : $Marpa::R2::HTML::Internal::START_HTML_TOKEN_IX;
    defined $Marpa::R2::HTML::Internal::END_TAG_IX_REF or end_tag_set();
    my $end_tag_token_ix = ${$Marpa::R2::HTML::Internal::END_TAG_IX_REF};
    my $contents_end_ix =
        defined $end_tag_token_ix
        ? $end_tag_token_ix + 1
        : $Marpa::R2::HTML::Internal::END_HTML_TOKEN_IX;

    # An element does not necessarily have any tokens
    return q{} if not defined $contents_start_ix;

    my $content_values = [
        @{$Marpa::R2::HTML::Internal::STACK}[
            ( $Marpa::R2::HTML::Internal::ARG_0 + 1 )
            .. ( $Marpa::R2::HTML::Internal::ARG_N - 1 )
        ]
    ];
    return ${
        Marpa::R2::HTML::Internal::range_and_values_to_literal( $self,
            $contents_start_ix, $contents_end_ix, $content_values )
        };

} ## end sub Marpa::R2::HTML::contents

sub Marpa::R2::HTML::values {

    die "Not yet implemented";

    my $parse_instance = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    Marpa::R2::exception(q{Attempt to fetch an end tag outside of a parse})
        if not defined $parse_instance;

    # my @values = grep {defined}
        # map { $_->[Marpa::R2::HTML::Internal::TDesc::Element::VALUE] }
        # grep { $_->[Marpa::R2::HTML::Internal::TDesc::TYPE] eq 'VALUED_SPAN' }
        # @{$Marpa::R2::HTML::Internal::TDESC_LIST};

    # return \@values;
} ## end sub Marpa::R2::HTML::values

sub Marpa::R2::HTML::descendants {

    my ($argspecs) = @_;

    my $parse_instance = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    Marpa::R2::exception(q{Attempt to fetch an end tag outside of a parse})
        if not defined $parse_instance;
    my $tokens = $parse_instance->{tokens};

    my @argspecs = ();
    for my $argspec ( split /,/xms, $argspecs ) {
        $argspec =~ s/\A \s* //xms;
        $argspec =~ s/ \s* \z//xms;
        push @argspecs, $argspec;
    }

    my @flat_tdesc_list = ();
    STACK_IX:
    for my $stack_ix (
        $Marpa::R2::HTML::Internal::ARG_0 .. $Marpa::R2::HTML::Internal::ARG_N
        )
    {
        my $tdesc_item = $Marpa::R2::HTML::Internal::STACK->[$stack_ix];

        my $type = $tdesc_item->[0];
        next STACK_IX if not defined $type;
        next STACK_IX if $type eq 'ZERO_SPAN';
        next STACK_IX if $type eq 'RUBY_SLIPPERS_TOKEN';
        if ( $type eq 'VALUES' ) {
            push @flat_tdesc_list,
                @{ $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::VALUE] };
            next STACK_IX;
        }
        push @flat_tdesc_list, $tdesc_item;
    } ## end STACK_IX: for my $stack_ix ( $Marpa::R2::HTML::Internal::ARG_0 ...)

    my $next_token_ix  = $Marpa::R2::HTML::Internal::START_HTML_TOKEN_IX;
    my $final_token_ix = $Marpa::R2::HTML::Internal::END_HTML_TOKEN_IX;

    my @descendants = ();
    TDESC_ITEM: for my $tdesc_item (@flat_tdesc_list) {
        my ( $tdesc_item_type, $next_explicit_token_ix,
            $furthest_explicit_token_ix )
            = @{$tdesc_item};

	if (not defined $next_explicit_token_ix) {
	    ## An element can contain no HTML tokens -- it may contain
	    ## only Ruby Slippers tokens.
	    ## Treat this as a special case.
	  if ( $tdesc_item_type eq 'VALUED_SPAN'
	      and defined $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::VALUE]
	      )
	  {
            push @descendants, [ 1, $tdesc_item ];
	  }
	  next TDESC_ITEM;
	}

        push @descendants,
            map { [ 0, $_ ] }
            ( $next_token_ix .. $next_explicit_token_ix - 1 );
        if ( $tdesc_item_type eq 'VALUED_SPAN'
            and defined $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::VALUE]
            )
        {
            push @descendants, [ 1, $tdesc_item ];
	    $next_token_ix = $furthest_explicit_token_ix + 1;
            next TDESC_ITEM;
        } ## end if ( $tdesc_item_type eq 'VALUED_SPAN' and defined ...)
        push @descendants,
            map { [ 0, $_ ] }
            ( $next_explicit_token_ix .. $furthest_explicit_token_ix );
        $next_token_ix = $furthest_explicit_token_ix + 1;
    } ## end TDESC_ITEM: for my $tdesc_item (@flat_tdesc_list)

    my @results;
    DESCENDANT: for my $descendant (@descendants) {
        my @per_descendant_results = ();
        my ( $is_valued, $data ) = @{$descendant};
        ARGSPEC: for my $argspec_ix (0 .. $#argspecs) {
	    ## Work with a copy, so we can change it
	    my $argspec = $argspecs[$argspec_ix];
	    my $deref = 1;
            if ( $argspec =~ s/_ref\z//xms ) {
	        $deref = 0;
	    }
            if ( $argspec eq 'literal' ) {
                if ($is_valued) {
                    push @per_descendant_results,
                        q{}
                        . $data->[Marpa::R2::HTML::Internal::TDesc::VALUE];
                    next ARGSPEC;
                } ## end if ($is_valued)
                $argspec = 'original';
                ## FALL THROUGH
            } ## end if ( $argspec eq 'literal' )
            if ( $argspec eq 'value' ) {
                my $value =
                      $is_valued
                    ? $data->[Marpa::R2::HTML::Internal::TDesc::VALUE]
                    : undef;

                push @per_descendant_results, $value;
                next ARGSPEC;
            } ## end if ( $argspec eq 'value' )
            if ( $argspec eq 'original' ) {
                my ( $start_ix, $end_ix ) =
                    $is_valued
                    ? (
                    @{$data}[
                        Marpa::R2::HTML::Internal::TDesc::START_TOKEN,
                    Marpa::R2::HTML::Internal::TDesc::END_TOKEN
                    ]
                    )
                    : ( $data, $data );
                my $result =
                    Marpa::R2::HTML::Internal::token_range_to_original(
                    $parse_instance, $start_ix, $end_ix );
                $result = ${$result} if $deref;
                push @per_descendant_results, $result;
                next ARGSPEC;
            } ## end if ( $argspec eq 'original' )
            die "Unimplemented argspec: $argspec";

            # when ('token_type') {
            # push @values,
            # ( $child_type eq 'token' )
            # ? (
            # $tokens->[$data]->[Marpa::R2::HTML::Internal::Token::TYPE] )
            # : undef;
            # } ## end when ('token_type')
            # when ('pseudoclass') {
            # push @values,
            # ( $child_type eq 'valued_span' )
            # ? $data
            # ->[Marpa::R2::HTML::Internal::TDesc::Element::NODE_DATA]
            # ->{pseudoclass}
            # : undef;
            # } ## end when ('pseudoclass')
            # when ('element') {
            # push @values,
            # ( $child_type eq 'valued_span' )
            # ? $data
            # ->[Marpa::R2::HTML::Internal::TDesc::Element::NODE_DATA]
            # ->{element}
            # : undef;
            # } ## end when ('element')
            # when ('literal_ref') {
            # my $tdesc =
            # $child_type eq 'token'
            # ? [ 'UNVALUED_SPAN', $data, $data ]
            # : $data;
            # push @values,
            # Marpa::R2::HTML::Internal::tdesc_list_to_literal(
            # $parse_instance, [$tdesc] );
            # } ## end when ('literal_ref')
            # when ('literal') {
            # my $tdesc =
            # $child_type eq 'token'
            # ? [ 'UNVALUED_SPAN', $data, $data ]
            # : $data;
            # push @values,
            # ${
            # Marpa::R2::HTML::Internal::tdesc_list_to_literal(
            # $parse_instance, [$tdesc] )
            # };
            # } ## end when ('literal')
            # when ('original') {
            # my ( $first_token_id, $last_token_id ) =
            # $child_type eq 'token'
            # ? ( $data, $data )
            # : @{$data}[
            # Marpa::R2::HTML::Internal::TDesc::START_TOKEN,
            # Marpa::R2::HTML::Internal::TDesc::END_TOKEN
            # ];
            # my $start_offset =
            # $tokens->[$first_token_id]
            # ->[Marpa::R2::HTML::Internal::Token::START_OFFSET];
            # my $end_offset =
            # $tokens->[$last_token_id]
            # ->[Marpa::R2::HTML::Internal::Token::END_OFFSET];
            # my $document = $parse_instance->{document};
            # push @values, substr ${$document}, $start_offset,
            # ( $end_offset - $start_offset );
            # } ## end when ('original')
            # when ('value') {
            # # push @values,
            # # ( $child_type eq 'valued_span' )
            # # ? $data->[Marpa::R2::HTML::Internal::TDesc::Element::VALUE]
            # : undef;
            # } ## end when ('value')
        } ## end ARGSPEC: for my $argspec (@argspecs)
        push @results, \@per_descendant_results;
    } ## end CHILD: for my $child (@children)

    return \@results;
} ## end sub Marpa::R2::HTML::descendants

sub Marpa::R2::HTML::attributes {

    die "Not yet implemented";

    my $parse_instance = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    Marpa::R2::exception(
        q{Attempt to fetch attributes from an undefined parse instance})
        if not defined $parse_instance;

    # It is OK to call this routine on a non-element -- you'll just
    # get back an empty list of attributes.
    my $start_tag_token_id =
        $Marpa::R2::HTML::Internal::PER_NODE_DATA->{start_tag_token_id};
    return {} if not defined $start_tag_token_id;

    my $tokens          = $parse_instance->{tokens};
    my $start_tag_token = $tokens->[$start_tag_token_id];
    return $start_tag_token->[Marpa::R2::HTML::Internal::Token::ATTR];
} ## end sub Marpa::R2::HTML::attributes

# This assumes that a start token, if there is one
# with attributes, is the first token
sub create_fetch_attribute_closure {
    return sub { die "Not yet implemented"; }
}

no strict 'refs';
*{'Marpa::R2::HTML::id'}    = create_fetch_attribute_closure('id');
*{'Marpa::R2::HTML::class'} = create_fetch_attribute_closure('class');
*{'Marpa::R2::HTML::title'} = create_fetch_attribute_closure('title');
use strict;

package Marpa::R2::HTML::Internal::Callback;

sub Marpa::R2::HTML::tagname {
    return $Marpa::R2::HTML::Internal::ELEMENT;
}

sub Marpa::R2::HTML::literal_ref {

    my $self = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    Marpa::R2::exception(
        q{Attempt to fetch an element contents outside of a parse})
        if not defined $self;

    my $contents_start_ix = $Marpa::R2::HTML::Internal::START_HTML_TOKEN_IX;

    # A rule does not necessarily have any tokens
    return \q{} if not defined $contents_start_ix;

    my $contents_end_ix = $Marpa::R2::HTML::Internal::END_HTML_TOKEN_IX;

    my $content_values = [
        @{$Marpa::R2::HTML::Internal::STACK}[
            ($Marpa::R2::HTML::Internal::ARG_0)
            .. ($Marpa::R2::HTML::Internal::ARG_N)
        ]
    ];
    return Marpa::R2::HTML::Internal::range_and_values_to_literal( $self,
        $contents_start_ix, $contents_end_ix, $content_values );

} ## end sub Marpa::R2::HTML::literal_ref

sub Marpa::R2::HTML::literal {
    return ${Marpa::R2::HTML::literal_ref()};
} ## end sub Marpa::R2::HTML::literal

sub Marpa::R2::HTML::offset {
    die "Not yet implemented";
    my $parse_instance = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    my $valuator = $Marpa::R2::HTML::Internal::VALUATOR;
    my $recce = $Marpa::R2::HTML::Internal::RECCE;
    Marpa::R2::exception('Attempt to read offset, but no evaluation in progress')
        if not defined $valuator;
    my ($earley_set_id) = $valuator->location();
    my $earleme = $recce->earleme($earley_set_id);
    return Marpa::R2::HTML::Internal::earleme_to_offset( $parse_instance,
        $earleme);
} ## end sub Marpa::R2::HTML::offset

sub Marpa::R2::HTML::original {
    die "Not yet implemented";
    my $parse_instance = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    Marpa::R2::exception('Attempt to read offset outside of a parse instance')
        if not defined $parse_instance;
    my $tokens   = $Marpa::R2::HTML::Internal::PARSE_INSTANCE->{tokens};
    my $document = $Marpa::R2::HTML::Internal::PARSE_INSTANCE->{document};
    my $first_token_id =
        $Marpa::R2::HTML::Internal::PER_NODE_DATA->{first_token_id};
    my $last_token_id =
        $Marpa::R2::HTML::Internal::PER_NODE_DATA->{last_token_id};
    my $start_offset =
        $tokens->[$first_token_id]
        ->[Marpa::R2::HTML::Internal::Token::START_OFFSET];
    my $end_offset =
        $tokens->[$last_token_id]->[Marpa::R2::HTML::Internal::Token::END_OFFSET];
    return substr ${$document}, $start_offset,
        ( $end_offset - $start_offset );
} ## end sub Marpa::R2::HTML::original

1;
