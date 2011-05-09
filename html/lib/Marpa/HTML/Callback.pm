package Marpa::HTML::Internal::Callback;

use 5.010;
use warnings;
use strict;
use integer;

# use Smart::Comments '-ENV';

### Using smart comments <where>...

use English qw( -no_match_vars );

sub Marpa::HTML::start_tag {

    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception(q{Attempt to fetch start tag outside of a parse})
        if not defined $parse_instance;

    my $element = $Marpa::HTML::Internal::PER_NODE_DATA->{element};
    return if not $element;

    #<<< perltidy cycles on this as of 2009-11-28
    return if not defined (my $start_tag_token_id =
            $Marpa::HTML::Internal::PER_NODE_DATA->{start_tag_token_id});
    #>>>
    #
    # Inlining this might be faster, especially since I have to dummy
    # up a tdesc list to make it work.
    return ${
        Marpa::HTML::Internal::tdesc_list_to_literal( $parse_instance,
            [ [ UNVALUED_SPAN => $start_tag_token_id, $start_tag_token_id ] ]
        )
        };
} ## end sub Marpa::HTML::start_tag

sub Marpa::HTML::end_tag {

    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception(q{Attempt to fetch an end tag outside of a parse})
        if not defined $parse_instance;

    my $element = $Marpa::HTML::Internal::PER_NODE_DATA->{element};
    return if not $element;

    #<<< perltidy cycles on this as of 2009-11-28
    return if not defined (my $end_tag_token_id =
            $Marpa::HTML::Internal::PER_NODE_DATA->{end_tag_token_id});
    #>>>
    #
    # Inlining this might be faster, especially since I have to dummy
    # up a tdesc list to make it work.
    return ${
        Marpa::HTML::Internal::tdesc_list_to_literal( $parse_instance,
            [ [ UNVALUED_SPAN => $end_tag_token_id, $end_tag_token_id ] ] )
        };
} ## end sub Marpa::HTML::end_tag

sub Marpa::HTML::contents {

    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception(
        q{Attempt to fetch an element contents outside of a parse})
        if not defined $parse_instance;

    my $element = $Marpa::HTML::Internal::PER_NODE_DATA->{element};
    return if not $element;

    my $contents_start_tdesc_ix =
        defined $Marpa::HTML::Internal::PER_NODE_DATA->{start_tag_token_id}
        ? 1
        : 0;

    my $contents_end_tdesc_ix =
        defined $Marpa::HTML::Internal::PER_NODE_DATA->{end_tag_token_id}
        ? ( $#{$Marpa::HTML::Internal::TDESC_LIST} - 1 )
        : $#{$Marpa::HTML::Internal::TDESC_LIST};

    return ${
        Marpa::HTML::Internal::tdesc_list_to_literal(
            $parse_instance,
            [   @{$Marpa::HTML::Internal::TDESC_LIST}
                    [ $contents_start_tdesc_ix .. $contents_end_tdesc_ix ]
            ]
        )
        };
} ## end sub Marpa::HTML::contents

sub Marpa::HTML::values {

    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception(q{Attempt to fetch an end tag outside of a parse})
        if not defined $parse_instance;

    my @values = grep {defined}
        map { $_->[Marpa::HTML::Internal::TDesc::Element::VALUE] }
        grep { $_->[Marpa::HTML::Internal::TDesc::TYPE] eq 'VALUED_SPAN' }
        @{$Marpa::HTML::Internal::TDESC_LIST};

    return \@values;
} ## end sub Marpa::HTML::values

sub Marpa::HTML::descendants {

    my ($argspecs) = @_;

    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception(q{Attempt to fetch an end tag outside of a parse})
        if not defined $parse_instance;
    my $tokens = $parse_instance->{tokens};

    my @argspecs = ();
    for my $argspec ( split /,/xms, $argspecs ) {
        $argspec =~ s/\A \s* //xms;
        $argspec =~ s/ \s* \z//xms;
        push @argspecs, $argspec;
    }

    my @children = ();
    for my $tdesc ( @{$Marpa::HTML::Internal::TDESC_LIST} ) {
        given ( $tdesc->[Marpa::HTML::Internal::TDesc::TYPE] ) {
            when ('UNVALUED_SPAN') {
                my $start_token =
                    $tdesc->[Marpa::HTML::Internal::TDesc::START_TOKEN];
                my $end_token =
                    $tdesc->[Marpa::HTML::Internal::TDesc::END_TOKEN];
                push @children,
                    map { [ 'token', $_ ] } ( $start_token .. $end_token );
            } ## end when ('UNVALUED_SPAN')
            when ('VALUED_SPAN') {
                push @children, [ 'valued_span', $tdesc ];
            }
        } ## end given
    } ## end for my $tdesc ( @{$Marpa::HTML::Internal::TDESC_LIST})

    my @return;
    CHILD: for my $child (@children) {
        my @values = ();
        my ( $child_type, $data ) = @{$child};
        for (@argspecs) {
            when ('token_type') {
                push @values,
                    ( $child_type eq 'token' )
                    ? (
                    $tokens->[$data]->[Marpa::HTML::Internal::Token::TYPE] )
                    : undef;
            } ## end when ('token_type')
            when ('pseudoclass') {
                push @values,
                    ( $child_type eq 'valued_span' )
                    ? $data
                    ->[Marpa::HTML::Internal::TDesc::Element::NODE_DATA]
                    ->{pseudoclass}
                    : undef;
            } ## end when ('pseudoclass')
            when ('element') {
                push @values,
                    ( $child_type eq 'valued_span' )
                    ? $data
                    ->[Marpa::HTML::Internal::TDesc::Element::NODE_DATA]
                    ->{element}
                    : undef;
            } ## end when ('element')
            when ('literal_ref') {
                my $tdesc =
                    $child_type eq 'token'
                    ? [ 'UNVALUED_SPAN', $data, $data ]
                    : $data;
                push @values,
                    Marpa::HTML::Internal::tdesc_list_to_literal(
                    $parse_instance, [$tdesc] );
            } ## end when ('literal_ref')
            when ('literal') {
                my $tdesc =
                    $child_type eq 'token'
                    ? [ 'UNVALUED_SPAN', $data, $data ]
                    : $data;
                push @values,
                    ${
                    Marpa::HTML::Internal::tdesc_list_to_literal(
                        $parse_instance, [$tdesc] )
                    };
            } ## end when ('literal')
            when ('original') {
                my ( $first_token_id, $last_token_id ) =
                    $child_type eq 'token'
                    ? ( $data, $data )
                    : @{$data}[
                    Marpa::HTML::Internal::TDesc::START_TOKEN,
                    Marpa::HTML::Internal::TDesc::END_TOKEN
                    ];
                my $start_offset =
                    $tokens->[$first_token_id]
                    ->[Marpa::HTML::Internal::Token::START_OFFSET];
                my $end_offset =
                    $tokens->[$last_token_id]
                    ->[Marpa::HTML::Internal::Token::END_OFFSET];
                my $document = $parse_instance->{document};
                push @values, substr ${$document}, $start_offset,
                    ( $end_offset - $start_offset );
            } ## end when ('original')
            when ('value') {
                push @values,
                    ( $child_type eq 'valued_span' )
                    ? $data->[Marpa::HTML::Internal::TDesc::Element::VALUE]
                    : undef;
            } ## end when ('value')
            default {
                Marpa::exception(qq{Unrecognized argspec: "$_"})
            }
        } ## end for (@argspecs)
        push @return, \@values;
    } ## end for my $child (@children)

    return \@return;
} ## end sub Marpa::HTML::descendants

sub Marpa::HTML::attributes {

    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception(
        q{Attempt to fetch attributes from an undefined parse instance})
        if not defined $parse_instance;

    # It is OK to call this routine on a non-element -- you'll just
    # get back an empty list of attributes.
    my $start_tag_token_id =
        $Marpa::HTML::Internal::PER_NODE_DATA->{start_tag_token_id};
    return {} if not defined $start_tag_token_id;

    my $tokens          = $parse_instance->{tokens};
    my $start_tag_token = $tokens->[$start_tag_token_id];
    return $start_tag_token->[Marpa::HTML::Internal::Token::ATTR];
} ## end sub Marpa::HTML::attributes

# This assumes that a start token, if there is one
# with attributes, is the first token
sub create_fetch_attribute_closure {
    my ($attribute) = @_;
    return sub {
        my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
        Marpa::exception(
            qq{Attempt to fetch attribute "$attribute" outside of a parse instance}
        ) if not defined $parse_instance;

        # It is OK to call this routine on a non-element.
        my $start_tag_token_id =
            $Marpa::HTML::Internal::PER_NODE_DATA->{start_tag_token_id};

        return if not defined $start_tag_token_id;
        my $tokens          = $parse_instance->{tokens};
        my $start_tag_token = $tokens->[$start_tag_token_id];
        my $attribute_value =
            $start_tag_token->[Marpa::HTML::Internal::Token::ATTR]
            ->{$attribute};

        return defined $attribute_value ? lc $attribute_value : undef;
    };
} ## end sub create_fetch_attribute_closure

no strict 'refs';
*{'Marpa::HTML::id'}    = create_fetch_attribute_closure('id');
*{'Marpa::HTML::class'} = create_fetch_attribute_closure('class');
*{'Marpa::HTML::title'} = create_fetch_attribute_closure('title');
use strict;

package Marpa::HTML::Internal::Callback;

sub Marpa::HTML::tagname {
    return $Marpa::HTML::Internal::PER_NODE_DATA->{element};
}

sub Marpa::HTML::literal_ref {

    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception('Attempt to get literal value outside of a parse')
        if not defined $parse_instance;
    my $tdesc_list = $Marpa::HTML::Internal::TDESC_LIST;
    return Marpa::HTML::Internal::tdesc_list_to_literal( $parse_instance,
        $tdesc_list );
} ## end sub Marpa::HTML::literal_ref

sub Marpa::HTML::literal {

    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Carp::confess('Attempt to get literal value outside of a parse')
        if not defined $parse_instance;
    Marpa::exception('Attempt to get literal value outside of a parse')
        if not defined $parse_instance;
    my $tdesc_list = $Marpa::HTML::Internal::TDESC_LIST;
    return ${
        Marpa::HTML::Internal::tdesc_list_to_literal( $parse_instance,
            $tdesc_list )
        };
} ## end sub Marpa::HTML::literal

sub Marpa::HTML::offset {
    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception('Attempt to read offset outside of a parse instance')
        if not defined $parse_instance;
    return Marpa::HTML::Internal::earleme_to_offset( $parse_instance,
        $Marpa::HTML::Internal::PER_NODE_DATA->{first_token_id} );
} ## end sub Marpa::HTML::offset

sub Marpa::HTML::original {
    my $parse_instance = $Marpa::HTML::Internal::PARSE_INSTANCE;
    Marpa::exception('Attempt to read offset outside of a parse instance')
        if not defined $parse_instance;
    my $tokens   = $Marpa::HTML::Internal::PARSE_INSTANCE->{tokens};
    my $document = $Marpa::HTML::Internal::PARSE_INSTANCE->{document};
    my $first_token_id =
        $Marpa::HTML::Internal::PER_NODE_DATA->{first_token_id};
    my $last_token_id =
        $Marpa::HTML::Internal::PER_NODE_DATA->{last_token_id};
    my $start_offset =
        $tokens->[$first_token_id]
        ->[Marpa::HTML::Internal::Token::START_OFFSET];
    my $end_offset =
        $tokens->[$last_token_id]->[Marpa::HTML::Internal::Token::END_OFFSET];
    return substr ${$document}, $start_offset,
        ( $end_offset - $start_offset );
} ## end sub Marpa::HTML::original

1;
