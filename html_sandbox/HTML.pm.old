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

package Marpa::R2::HTML;

use 5.010;
use strict;
use warnings;

use vars qw( $VERSION $STRING_VERSION );
$VERSION        = '2.020000';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

our @EXPORT_OK;
use base qw(Exporter);
BEGIN { @EXPORT_OK = qw(html); }

package Marpa::R2::HTML::Internal;

use Carp ();
use HTML::PullParser;
use HTML::Entities qw(decode_entities);
use HTML::Tagset ();

# versions below must be coordinated with
# those required in Build.PL

use English qw( -no_match_vars );
use Marpa::R2;
{
    my $submodule_version = $Marpa::R2::VERSION;
    die 'Marpa::R2::VERSION not defined' if not defined $submodule_version;
    die
        "Marpa::R2::VERSION ($submodule_version) does not match Marpa::R2::HTML::VERSION ",
        $Marpa::R2::HTML::VERSION
        if $submodule_version != $Marpa::R2::HTML::VERSION;
}

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';
    :package=Marpa::R2::HTML::Internal::TDesc
    TYPE
    START_TOKEN
    END_TOKEN
END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';
    :package=Marpa::R2::HTML::Internal::TDesc::Element
    TYPE
    START_TOKEN
    END_TOKEN
    VALUE
    NODE_DATA
END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN

%Marpa::R2::HTML::PULL_PARSER_OPTIONS = (
    start       => q{'S',line,column,offset,offset_end,tagname,attr},
    end         => q{'E',line,column,offset,offset_end,tagname},
    text        => q{'T',line,column,offset,offset_end,is_cdata},
    comment     => q{'C',line,column,offset,offset_end},
    declaration => q{'D',line,column,offset,offset_end},
    process     => q{'PI',line,column,offset,offset_end},

    # options that default on
    unbroken_text => 1,
);

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';
    :package=Marpa::R2::HTML::Internal::Token
    TYPE
    LINE
    COL
    =COLUMN
    START_OFFSET
    END_OFFSET
    TAGNAME
    =IS_CDATA
    ATTR
END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN

use Marpa::R2::HTML::Callback;
{
    my $submodule_version = $Marpa::R2::HTML::Callback::VERSION;
    die 'Marpa::R2::HTML::Callback::VERSION not defined'
        if not defined $submodule_version;
    die
        "Marpa::R2::HTML::Callback::VERSION ($submodule_version) does not match Marpa::R2::HTML::VERSION ",
        $Marpa::R2::HTML::VERSION
        if $submodule_version != $Marpa::R2::HTML::VERSION;
}

sub per_element_handlers {
    my ( $element, $user_handlers ) = @_;
    return {} if not $element;
    return {} if not $user_handlers;
    my $wildcard_handlers    = $user_handlers->{ANY} // {};
    my %handlers             = %{$wildcard_handlers};
    my $per_element_handlers = $user_handlers->{$element} // {};
    @handlers{ keys %{$per_element_handlers} } =
        values %{$per_element_handlers};
    return \%handlers;
} ## end sub per_element_handlers

sub tdesc_list_to_literal {
    my ( $self, $tdesc_list ) = @_;

    my $text     = q{};
    my $document = $self->{document};
    my $tokens   = $self->{tokens};
    TDESC: for my $tdesc ( @{$tdesc_list} ) {
        given ( $tdesc->[Marpa::R2::HTML::Internal::TDesc::TYPE] ) {
            when ('POINT') { break; }
            when ('VALUED_SPAN') {
                if (defined(
                        my $value = $tdesc->[
                            Marpa::R2::HTML::Internal::TDesc::Element::VALUE]
                    )
                    )
                {
                    $text .= $value;
                    break;    # next TDESC;
                } ## end if ( defined( my $value = $tdesc->[...]))

                # next TDESC if no first token id
                #<<< As of 2009-11-22 perltidy cycles on this code
                break
                    if not defined( my $first_token_id = $tdesc
                        ->[ Marpa::R2::HTML::Internal::TDesc::START_TOKEN ] );
                #>>>

                # next TDESC if no last token id
                #<<< As of 2009-11-22 perltidy cycles on this code
                break
                    if not defined( my $last_token_id =
                        $tdesc->[Marpa::R2::HTML::Internal::TDesc::END_TOKEN] );
                #>>>

                my $offset =
                    $tokens->[$first_token_id]
                    ->[Marpa::R2::HTML::Internal::Token::START_OFFSET];
                my $end_offset =
                    $tokens->[$last_token_id]
                    ->[Marpa::R2::HTML::Internal::Token::END_OFFSET];
                $text .= substr ${$document}, $offset,
                    ( $end_offset - $offset );
            } ## end when ('VALUED_SPAN')
            when ('UNVALUED_SPAN') {
                my $first_token_id =
                    $tdesc->[Marpa::R2::HTML::Internal::TDesc::START_TOKEN];
                my $last_token_id =
                    $tdesc->[Marpa::R2::HTML::Internal::TDesc::END_TOKEN];
                my $offset =
                    $tokens->[$first_token_id]
                    ->[Marpa::R2::HTML::Internal::Token::START_OFFSET];
                my $end_offset =
                    $tokens->[$last_token_id]
                    ->[Marpa::R2::HTML::Internal::Token::END_OFFSET];

                $text .= substr ${$document}, $offset,
                    ( $end_offset - $offset );
            } ## end when ('UNVALUED_SPAN')
            default {
                Marpa::R2::exception(
                    qq{Internal error: unknown tdesc type "$_"});
            }
        } ## end given
    } ## end for my $tdesc ( @{$tdesc_list} )
    return \$text;
} ## end sub tdesc_list_to_literal

# Convert a list of text descriptions to text
sub default_top_handler {
    my ( $dummy, @tdesc_lists ) = @_;
    my $self = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
    my @tdesc_list = map { @{$_} } grep {defined} @tdesc_lists;
    return tdesc_list_to_literal( $self, \@tdesc_list );

} ## end sub default_top_handler

sub wrap_user_top_handler {
    my ($user_handler) = @_;
    return sub {
        my ( $dummy, @tdesc_lists ) = @_;
        my @tdesc_list = map { @{$_} } grep {defined} @tdesc_lists;
        return undef if not scalar @tdesc_list;
        local $Marpa::R2::HTML::Internal::TDESC_LIST = \@tdesc_list;
        local $Marpa::R2::HTML::Internal::PER_NODE_DATA =
            { pseudoclass => 'TOP' };
        return scalar $user_handler->();
    };
} ## end sub wrap_user_top_handler

# Convert a list of text descriptions to a
# single, shortened text description
sub create_tdesc_handler {
    my ( $self, $element ) = @_;
    my $handlers_by_class =
        per_element_handlers( $element,
        ( $self ? $self->{user_handlers_by_class} : {} ) );
    my $handlers_by_id =
        per_element_handlers( $element,
        ( $self ? $self->{user_handlers_by_id} : {} ) );

    return sub {
        my ( $dummy, @tdesc_lists ) = @_;

        my @tdesc_list = map { @{$_} } grep {defined} @tdesc_lists;
        return undef if not scalar @tdesc_list;
        local $Marpa::R2::HTML::Internal::TDESC_LIST = \@tdesc_list;

        my @token_ids = sort { $a <=> $b } grep {defined} map {
            @{$_}[
                Marpa::R2::HTML::Internal::TDesc::START_TOKEN,
                Marpa::R2::HTML::Internal::TDesc::END_TOKEN
                ]
        } @tdesc_list;

        my $first_token_id_in_node = $token_ids[0];
        my $last_token_id_in_node  = $token_ids[-1];
        my $per_node_data          = {
            element        => $element,
            first_token_id => $first_token_id_in_node,
            last_token_id  => $last_token_id_in_node,
        };

        if ( $tdesc_list[0]->[Marpa::R2::HTML::Internal::TDesc::TYPE] ne
            'POINT' )
        {
            $per_node_data->{start_tag_token_id} = $first_token_id_in_node;
        }

        if ( $tdesc_list[-1]->[Marpa::R2::HTML::Internal::TDesc::TYPE] ne
            'POINT' )
        {
            $per_node_data->{end_tag_token_id} = $last_token_id_in_node;
        }

        local $Marpa::R2::HTML::Internal::PER_NODE_DATA = $per_node_data;

        my $self           = $Marpa::R2::HTML::Internal::PARSE_INSTANCE;
        my $trace_fh       = $self->{trace_fh};
        my $trace_handlers = $self->{trace_handlers};

        my $tokens = $self->{tokens};

        my $user_handler;
        GET_USER_HANDLER: {
            if ( my $id = Marpa::R2::HTML::id() ) {
                if ( $user_handler = $handlers_by_id->{$id} ) {
                    if ($trace_handlers) {
                        say {$trace_fh}
                            "Resolved to user handler by element ($element) and id ($id)"
                            or Carp::croak("Cannot print: $ERRNO");
                    }
                    last GET_USER_HANDLER;
                } ## end if ( $user_handler = $handlers_by_id->{$id} )
            } ## end if ( my $id = Marpa::R2::HTML::id() )
            if ( my $class = Marpa::R2::HTML::class() ) {
                if ( $user_handler = $handlers_by_class->{$class} ) {
                    if ($trace_handlers) {
                        say {$trace_fh}
                            "Resolved to user handler by element ($element) and class ($class)"
                            or Carp::croak("Cannot print: $ERRNO");
                    }
                    last GET_USER_HANDLER;
                } ## end if ( $user_handler = $handlers_by_class->{$class} )
            } ## end if ( my $class = Marpa::R2::HTML::class() )
            $user_handler = $handlers_by_class->{ANY};
            if ( $trace_handlers and $user_handler ) {
                say {$trace_fh} +(
                    defined $element
                    ? "Resolved to user handler by element ($element)"
                    : 'Resolved to default user handler'
                ) or Carp::croak("Cannot print: $ERRNO");
            } ## end if ( $trace_handlers and $user_handler )
        } ## end GET_USER_HANDLER:

        if ( defined $user_handler ) {

            # scalar context needed for the user handler
            # because so that a bare return returns undef
            # and not an empty list.
            return [
                [   VALUED_SPAN => $first_token_id_in_node,
                    $last_token_id_in_node, ( scalar $user_handler->() ),
                    $per_node_data
                ]
            ];
        } ## end if ( defined $user_handler )

        my $doc          = $self->{doc};
        my @tdesc_result = ();

        my $first_token_id_in_current_span;
        my $last_token_id_in_current_span;

        TDESC: for my $tdesc ( @tdesc_list, ['FINAL'] ) {

            my $next_tdesc;
            my $first_token_id;
            my $last_token_id;
            PARSE_TDESC: {
                my $ref_type = ref $tdesc;
                if ( not $ref_type or $ref_type ne 'ARRAY' ) {
                    $next_tdesc = $tdesc;
                    last PARSE_TDESC;
                }
                given ( $tdesc->[Marpa::R2::HTML::Internal::TDesc::TYPE] ) {
                    when ('POINT') { break; }
                    when ('VALUED_SPAN') {
                        if (not defined(
                                my $value = $tdesc->[
                                    Marpa::R2::HTML::Internal::TDesc::Element::VALUE
                                ]
                            )
                            )
                        {
                            #<<< As of 2009-11-22 pertidy cycles on this
                            $first_token_id = $tdesc->[
                                Marpa::R2::HTML::Internal::TDesc::START_TOKEN ];
                            $last_token_id =
                                $tdesc
                                ->[ Marpa::R2::HTML::Internal::TDesc::END_TOKEN
                                ];
                            #>>>
                            break;    # last PARSE_TDESC;
                        } ## end if ( not defined( my $value = $tdesc->[ ...]))
                        $next_tdesc = $tdesc;
                    } ## end when ('VALUED_SPAN')
                    when ('FINAL') {
                        $next_tdesc = $tdesc;
                    }
                    when ('UNVALUED_SPAN') {
                        $first_token_id = $tdesc
                            ->[Marpa::R2::HTML::Internal::TDesc::START_TOKEN];
                        $last_token_id = $tdesc
                            ->[Marpa::R2::HTML::Internal::TDesc::END_TOKEN];
                    } ## end when ('UNVALUED_SPAN')
                    default {
                        Marpa::R2::exception(
                            "Unknown text description type: $_");
                    }
                } ## end given
            } ## end PARSE_TDESC:

            if ( defined $first_token_id and defined $last_token_id ) {
                if ( defined $first_token_id_in_current_span ) {
                    if ( $first_token_id
                        <= $last_token_id_in_current_span + 1 )
                    {
                        $last_token_id_in_current_span = $last_token_id;
                        next TDESC;
                    } ## end if ( $first_token_id <= ...)
                    push @tdesc_result,
                        [
                        'UNVALUED_SPAN',
                        $first_token_id_in_current_span,
                        $last_token_id_in_current_span
                        ];
                } ## end if ( defined $first_token_id_in_current_span )
                $first_token_id_in_current_span = $first_token_id;
                $last_token_id_in_current_span  = $last_token_id;
                next TDESC;
            } ## end if ( defined $first_token_id and defined $last_token_id)

            if ( defined $next_tdesc ) {
                if ( defined $first_token_id_in_current_span ) {
                    push @tdesc_result,
                        [
                        'UNVALUED_SPAN',
                        $first_token_id_in_current_span,
                        $last_token_id_in_current_span
                        ];

                    $first_token_id_in_current_span =
                        $last_token_id_in_current_span = undef;
                } ## end if ( defined $first_token_id_in_current_span )
                my $ref_type = ref $next_tdesc;

                last TDESC
                    if $ref_type eq 'ARRAY'
                        and
                        $next_tdesc->[Marpa::R2::HTML::Internal::TDesc::TYPE]
                        eq 'FINAL';
                push @tdesc_result, $next_tdesc;
            } ## end if ( defined $next_tdesc )

        } ## end for my $tdesc ( @tdesc_list, ['FINAL'] )

        return \@tdesc_result;
    };
} ## end sub create_tdesc_handler

sub wrap_user_tdesc_handler {
    my ( $user_handler, $per_node_data ) = @_;

    return sub {
        my ( $dummy, @tdesc_lists ) = @_;
        my @tdesc_list = map { @{$_} } grep {defined} @tdesc_lists;
        return undef if not scalar @tdesc_list;
        local $Marpa::R2::HTML::Internal::TDESC_LIST = \@tdesc_list;
        my @token_ids = sort { $a <=> $b } grep {defined} map {
            @{$_}[
                Marpa::R2::HTML::Internal::TDesc::START_TOKEN,
                Marpa::R2::HTML::Internal::TDesc::END_TOKEN
                ]
        } @tdesc_list;

        my $first_token_id = $token_ids[0];
        my $last_token_id  = $token_ids[-1];
        $per_node_data //= {};
        $per_node_data->{first_token_id} = $first_token_id;
        $per_node_data->{last_token_id}  = $last_token_id;
        local $Marpa::R2::HTML::Internal::PER_NODE_DATA = $per_node_data;

        # scalar context needed for the user handler
        # because so that a bare return returns undef
        # and not an empty list.
        return [
            [   VALUED_SPAN => $first_token_id,
                $last_token_id, ( scalar $user_handler->() ),
                $per_node_data
            ]
        ];

    };
} ## end sub wrap_user_tdesc_handler

sub earleme_to_linecol {
    my ( $self, $token_offset ) = @_;
    my $html_parser_tokens = $self->{tokens};

    # Special start of file for undefined offset
    if ( not defined $token_offset ) {
        return ( 1, 0 );
    }

    # Special case needed for a token offset after the last
    # token.  This happens with the EOF.
    if ( $token_offset < 0 or $token_offset > $#{$html_parser_tokens} ) {
        $token_offset = $#{$html_parser_tokens};
    }

    return @{ $html_parser_tokens->[$token_offset] }[
        Marpa::R2::HTML::Internal::Token::LINE,
        Marpa::R2::HTML::Internal::Token::COLUMN,
    ];

} ## end sub earleme_to_linecol

sub earleme_to_offset {

    my ( $self, $token_offset ) = @_;
    my $html_parser_tokens = $self->{tokens};

    # Special start of file for undefined offset
    if ( not defined $token_offset ) {
        return 0;
    }

    # Special case needed for a token offset after the last
    # token.  This happens with the EOF.
    my $offset;
    if ( $token_offset < 0 or $token_offset > $#{$html_parser_tokens} ) {
        $offset = length ${ $self->{document} };
    }
    else {
        $offset =
            $html_parser_tokens->[$token_offset]
            ->[Marpa::R2::HTML::Internal::Token::END_OFFSET];
    }
    return $offset;

} ## end sub earleme_to_offset

my %ARGS = (
    start       => q{'S',offset,offset_end,tagname,attr},
    end         => q{'E',offset,offset_end,tagname},
    text        => q{'T',offset,offset_end,is_cdata},
    process     => q{'PI',offset,offset_end},
    comment     => q{'C',offset,offset_end},
    declaration => q{'D',offset,offset_end},

    # options that default on
    unbroken_text => 1,
);

sub add_handler {
    my ( $self, $handler_description ) = @_;
    my $ref_type = ref $handler_description || 'not a reference';
    Marpa::R2::exception(
        "Long form handler description should be ref to hash, but it is $ref_type"
    ) if $ref_type ne 'HASH';
    my $element     = delete $handler_description->{element};
    my $id          = delete $handler_description->{id};
    my $class       = delete $handler_description->{class};
    my $pseudoclass = delete $handler_description->{pseudoclass};
    my $action      = delete $handler_description->{action};
    Marpa::R2::exception(
        'Unknown option(s) in Long form handler description: ',
        ( join q{ }, keys %{$handler_description} )
    ) if scalar keys %{$handler_description};

    Marpa::R2::exception('Handler action must be CODE ref')
        if ref $action ne 'CODE';

    $element = ( not $element or $element eq q{*} ) ? 'ANY' : lc $element;
    if ( defined $pseudoclass ) {
        $self->{user_handlers_by_pseudoclass}->{$element}->{$pseudoclass} =
            $action;
        return 1;
    }

    if ( defined $id ) {
        $self->{user_handlers_by_id}->{$element}->{ lc $id } = $action;
        return 1;
    }
    $class = defined $class ? lc $class : 'ANY';
    $self->{user_handlers_by_class}->{$element}->{$class} = $action;
    return 1;
} ## end sub add_handler

sub add_handlers_from_hashes {
    my ( $self, $handler_specs ) = @_;
    my $ref_type = ref $handler_specs || 'not a reference';
    Marpa::R2::exception(
        "handlers arg must must be ref to ARRAY, it is $ref_type")
        if $ref_type ne 'ARRAY';
    for my $handler_spec ( keys %{$handler_specs} ) {
        add_handler( $self, $handler_spec );
    }
    return 1;
} ## end sub add_handlers_from_hashes

sub add_handlers {
    my ( $self, $handler_specs ) = @_;
    HANDLER_SPEC: for my $specifier ( keys %{$handler_specs} ) {
        my ( $element, $id, $class, $pseudoclass );
        my $action = $handler_specs->{$specifier};
        ( $element, $id ) = ( $specifier =~ /\A ([^#]*) [#] (.*) \z/xms )
            or ( $element, $class ) =
               ( $specifier =~ /\A ([^.]*) [.] (.*) \z/xms )
            or ( $element, $pseudoclass ) =
            ( $specifier =~ /\A ([^:]*) [:] (.*) \z/xms )
            or $element = $specifier;
        if ($pseudoclass
            and not $pseudoclass ~~ [
                qw(TOP PI DECL COMMENT PROLOG TRAILER WHITESPACE CDATA PCDATA CRUFT)
            ]
            )
        {
            Marpa::R2::exception(
                qq{pseudoclass "$pseudoclass" is not known:\n},
                "Specifier was $specifier\n" );
        } ## end if ( $pseudoclass and not $pseudoclass ~~ [ ...])
        if ( $pseudoclass and $element ) {
            Marpa::R2::exception(
                qq{pseudoclass "$pseudoclass" may not have an element specified:\n},
                "Specifier was $specifier\n"
            );
        } ## end if ( $pseudoclass and $element )
        add_handler(
            $self,
            {   element     => $element,
                id          => $id,
                class       => $class,
                pseudoclass => $pseudoclass,
                action      => $action
            }
        );
    } ## end for my $specifier ( keys %{$handler_specs} )

    return 1;
} ## end sub add_handlers

# If we factor this package, this will be the constructor.
## no critic (Subroutines::RequireArgUnpacking)
sub create {

    ## use critic
    my $self = {};
    $self->{trace_fh} = \*STDERR;
    ARG: for my $arg (@_) {
        my $ref_type = ref $arg || 'not a reference';
        if ( $ref_type eq 'HASH' ) {
            Marpa::R2::HTML::Internal::add_handlers( $self, $arg );
            next ARG;
        }
        Marpa::R2::exception(
            "Argument must be hash or refs to hash: it is $ref_type")
            if $ref_type ne 'REF';
        my $option_hash = ${$arg};
        $ref_type = ref $option_hash || 'not a reference';
        Marpa::R2::exception(
            "Argument must be hash or refs to hash: it is ref to $ref_type")
            if $ref_type ne 'HASH';
        OPTION: for my $option ( keys %{$option_hash} ) {
            if ( $option eq 'handlers' ) {
                add_handlers_from_hashes( $self, $option_hash->{$option} );
            }
            if (not $option ~~ [
                    qw(trace_fh trace_values trace_handlers trace_actions
                        trace_conflicts trace_ambiguity trace_rules trace_QDFA
                        trace_earley_sets trace_terminals trace_cruft)
                ]
                )
            {
                Marpa::R2::exception("unknown option: $option");
            } ## end if ( not $option ~~ [ ...])
            $self->{$option} = $option_hash->{$option};
        } ## end for my $option ( keys %{$option_hash} )
    } ## end for my $arg (@_)
    return $self;
} ## end sub create

# block_element is for block-level ONLY elements.
# head is for anything legal inside the HTML header.
# Note that isindex can be both a head element and
# and block level element in the body.
# ISINDEX is classified as a header_element
%Marpa::R2::HTML::Internal::ELEMENT_TYPE = (
    (   map { $_ => 'block_element' }
            qw(
            h1 h2 h3 h4 h5 h6
            ul ol dir menu
            pre
            p dl div center
            noscript noframes
            blockquote form hr
            table fieldset address
            )
    ),
    (   map { $_ => 'header_element' }
            qw(
            script style meta link object title isindex base
            )
    ),
    ( map { $_ => 'list_item_element' } qw( li dd dt ) ),
    ( map { $_ => 'table_cell_element' } qw( td th ) ),
    ( map { $_ => 'table_row_element' } qw( tr ) ),
);

@Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS = qw(
    E_html
    E_body
    S_table
    E_head
    E_table
    E_tbody
    E_tr
    E_td
    S_td
    S_tr
    S_tbody
    S_head
    S_body
    S_html
);

%Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS = ();
for my $rank ( 0 .. $#Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS ) {
    $Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS{
        $Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS[$rank] } = $rank;
}

%Marpa::R2::HTML::Internal::VIRTUAL_TOKEN_HIERARCHY = ();
{
    my $hierarchy = <<'END_OF_STRING';
th td
tr
col
caption colgroup tfoot thead tbody
table
body head
html
END_OF_STRING

    my $iota = 0;
    my @hierarchy;
    for my $level ( split /\n/xms, $hierarchy ) {
        push @hierarchy,
            map { ( "S_$_" => $iota, "E_$_" => $iota ) }
            ( split q{ }, $level );
        $iota++;
    } ## end for my $level ( split /\n/xms, $hierarchy )
    %Marpa::R2::HTML::Internal::VIRTUAL_TOKEN_HIERARCHY = @hierarchy;
    $Marpa::R2::HTML::Internal::VIRTUAL_TOKEN_HIERARCHY{EOF} =
        $Marpa::R2::HTML::Internal::VIRTUAL_TOKEN_HIERARCHY{E_tbody};
}

# This display set to be ignored
# until the HTML::Implementation doc
# is ready.

# Marpa::R2::Display
# name: HTML BNF
# ignore: 1
# start-after-line: END_OF_BNF
# end-before-line: '^END_OF_BNF$'

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
ELE_body ::= S_body flow E_body
ELE_table ::= S_table table_flow E_table
ELE_tbody ::= S_tbody table_section_flow E_tbody
ELE_tr ::= S_tr table_row_flow E_tr
ELE_td ::= S_td flow E_td
flow ::= flow_item*
flow_item ::= cruft
flow_item ::= SGML_item
flow_item ::= ELE_table
flow_item ::= list_item_element
flow_item ::= header_element
flow_item ::= block_element
flow_item ::= inline_element
flow_item ::= whitespace
flow_item ::= cdata
flow_item ::= pcdata
head_item ::= header_element
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
empty ::=
END_OF_BNF

@Marpa::R2::HTML::Internal::CORE_RULES = ();

my %handler = (
    cruft      => '!CRUFT_handler',
    comment    => '!COMMENT_handler',
    pi         => '!PI_handler',
    decl       => '!DECL_handler',
    document   => '!TOP_handler',
    whitespace => '!WHITESPACE_handler',
    pcdata     => '!PCDATA_handler',
    cdata      => '!CDATA_handler',
    prolog     => '!PROLOG_handler',
    trailer    => '!TRAILER_handler',
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
        $rule_descriptor{action} = "!$lhs";
    }
    push @Marpa::R2::HTML::Internal::CORE_RULES, \%rule_descriptor;
} ## end for my $bnf_production ( split /\n/xms, $BNF )

@Marpa::R2::HTML::Internal::CORE_TERMINALS =
    qw(C D PI CRUFT CDATA PCDATA WHITESPACE EOF );

push @Marpa::R2::HTML::Internal::CORE_TERMINALS,
    keys %Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS;

no strict 'refs';
*{'Marpa::R2::HTML::Internal::default_action'} = create_tdesc_handler();
use strict;

%Marpa::R2::HTML::Internal::EMPTY_ELEMENT = map { $_ => 1 } qw(
    area base basefont br col frame hr
    img input isindex link meta param);

%Marpa::R2::HTML::Internal::CONTENTS = (
    'p'        => 'inline_flow',
    'select'   => 'Contents_select',
    'option'   => 'pcdata_flow',
    'optgroup' => 'Contents_optgroup',
    'dt'       => 'inline_flow',
    'dd'       => 'list_item_flow',
    'li'       => 'list_item_flow',
    'colgroup' => 'Contents_colgroup',
    'thead'    => 'table_section_flow',
    'tfoot'    => 'table_section_flow',
    'tbody'    => 'table_section_flow',
    'table'    => 'table_flow',
    ( map { $_ => 'empty' } keys %Marpa::R2::HTML::Internal::EMPTY_ELEMENT ),
);

sub parse {
    my ( $self, $document_ref ) = @_;

    my %start_tags = ();
    my %end_tags   = ();

    Marpa::R2::exception(
        "parse() already run on this object\n",
        'For a new parse, create a new object'
    ) if $self->{document};

    my $trace_cruft     = $self->{trace_cruft};
    my $trace_terminals = $self->{trace_terminals} // 0;
    my $trace_conflicts = $self->{trace_conflicts};
    my $trace_fh        = $self->{trace_fh};
    my $ref_type        = ref $document_ref;
    Marpa::R2::exception('Arg to parse() must be ref to string')
        if not $ref_type
            or $ref_type ne 'SCALAR'
            or not defined ${$document_ref};

    my %pull_parser_args;
    my $document = $pull_parser_args{doc} = $self->{document} = $document_ref;
    my $pull_parser =
        HTML::PullParser->new( %pull_parser_args,
        %Marpa::R2::HTML::PULL_PARSER_OPTIONS )
        || Carp::croak('Could not create pull parser');

    my @tokens = ();

    my %terminals =
        map { $_ => 1 } @Marpa::R2::HTML::Internal::CORE_TERMINALS;
    my %optional_terminals =
        %Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS;
    my @html_parser_tokens = ();
    my @marpa_tokens       = ();
    HTML_PARSER_TOKEN:
    while ( my $html_parser_token = $pull_parser->get_token ) {
        my ( $token_type, $line, $column, $offset, $offset_end ) =
            @{$html_parser_token};

        # If it's a virtual token from HTML::Parser,
        # pretend it never existed.
        # We figure out where the missing tags are,
        # and HTML::Parser's guesses are not helpful.
        next HTML_PARSER_TOKEN if $offset_end <= $offset;

        my $token_number = scalar @html_parser_tokens;
        push @html_parser_tokens, $html_parser_token;

        given ($token_type) {
            when ('T') {
                my $is_cdata = $html_parser_token
                    ->[Marpa::R2::HTML::Internal::Token::IS_CDATA];
                push @marpa_tokens,
                    [
                    (   substr(
                            ${$document}, $offset,
                            ( $offset_end - $offset )
                            ) =~ / \A \s* \z /xms ? 'WHITESPACE'
                        : $is_cdata ? 'CDATA'
                        : 'PCDATA'
                    ),
                    [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('T')
            when ('S') {
                my $tag_name = $html_parser_token
                    ->[Marpa::R2::HTML::Internal::Token::TAGNAME];
                $start_tags{$tag_name}++;
                my $terminal = "S_$tag_name";
                $terminals{$terminal}++;
                push @marpa_tokens,
                    [
                    $terminal,
                    [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('S')
            when ('E') {
                my $tag_name = $html_parser_token
                    ->[Marpa::R2::HTML::Internal::Token::TAGNAME];
                $end_tags{$tag_name}++;
                my $terminal = "E_$tag_name";
                $terminals{$terminal}++;
                push @marpa_tokens,
                    [
                    $terminal,
                    [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ('E')
            when ( [qw(C D)] ) {
                push @marpa_tokens,
                    [
                    $_, [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ( [qw(C D)] )
            when ( ['PI'] ) {
                push @marpa_tokens,
                    [
                    $_, [ [ 'UNVALUED_SPAN', $token_number, $token_number ] ],
                    ];
            } ## end when ( ['PI'] )
            default { Carp::croak("Unprovided-for event: $_") }
        } ## end given
    } ## end while ( my $html_parser_token = $pull_parser->get_token)

    # Points AFTER the last HTML
    # Parser token.
    # The other logic needs to be ready for this.
    push @marpa_tokens, [ 'EOF', [ ['POINT'] ] ];

    $pull_parser = undef;    # conserve memory

    my @rules     = @Marpa::R2::HTML::Internal::CORE_RULES;
    my @terminals = keys %terminals;

    my %pseudoclass_element_actions = ();
    my %element_actions             = ();

    # Special cases which are dealt with elsewhere.
    # As of now the only special cases are elements with optional
    # start and end tags
    for my $special_element (qw(html head body table tbody tr td)) {
        delete $start_tags{$special_element};
        $element_actions{"!ELE_$special_element"} = $special_element;
    }

    ELEMENT: for ( keys %start_tags ) {
        my $start_tag    = "S_$_";
        my $end_tag      = "E_$_";
        my $contents     = $Marpa::R2::HTML::Internal::CONTENTS{$_} // 'flow';
        my $element_type = $Marpa::R2::HTML::Internal::ELEMENT_TYPE{$_}
            // 'inline_element';

        push @rules,
            {
            lhs => $element_type,
            rhs => ["ELE_$_"],
            },
            {
            lhs    => "ELE_$_",
            rhs    => [ $start_tag, $contents, $end_tag ],
            action => "!ELE_$_",
            };

        # There may be no
        # end tag in the input.
        # This silences the warning.
        if ( not $terminals{$end_tag} ) {
            push @terminals, $end_tag;
            $terminals{$end_tag}++;
        }

        # Make each new optional terminal the highest ranking
        $optional_terminals{$end_tag} = keys %optional_terminals;

        $element_actions{"!ELE_$_"} = $_;
    } ## end for ( keys %start_tags )

    # The question is where to put cruft -- in the current element,
    # or at a higher level.  As a first step, we set up a system of
    # levels for specific elements, going from the lowest, where no
    # cruft is allowed, to the highest, where everything is
    # acceptable as cruft, if only because it has nowhere else to go.

    # First step, set up the levels, using specific elements.
    # Some of these elements will are stand-ins for large category.
    # For example, the HR element stands in for those elements
    # such as empty elements,
    # which tolerate zero cruft, while SPAN stands in for
    # inline elements and DIV stands in for the class of
    # block-level elements

    my %ok_as_cruft = ();
    DECIDE_CRUFT_TREATMENT: {
        my %level             = ();
        my @elements_by_level = (
            [qw( HR HEAD )],
            [qw( SPAN OPTION )],
            [qw( LI OPTGROUP DD DT )],
            [qw( DIR MENU )],
            [qw( DIV )],
            [qw( UL OL DL )],
            [qw( TH TD )],
            [qw( TR )],
            [qw( COL )],
            [qw( CAPTION COLGROUP THEAD TFOOT TBODY )],
            [qw( TABLE )],
            [qw( BODY )],
            [qw( HTML )],
        );

        # EOF comes after everything -- it is
        # the highest level of all
        $level{EOF} = scalar @elements_by_level;

        # Assign levels to the end tags of the elements
        # in the above table.
        for my $level ( 0 .. $#elements_by_level ) {
            for my $element ( @{ $elements_by_level[$level] } ) {
                $level{ 'S_' . lc $element } = $level{ 'E_' . lc $element } =
                    $level;
            }
        } ## end for my $level ( 0 .. $#elements_by_level )

        my $no_cruft_allowed = $level{E_hr};
        my $block_level      = $level{E_div};
        my $inline_level     = $level{E_span};

        # Now that we have set out the structure of levels
        # fill it in for all the terminals we have yet to
        # define.
        TERMINAL:
        for my $terminal ( grep { not defined $level{$_} }
            ( @terminals, keys %optional_terminals ) )
        {

            # With the exception of EOF,
            # only tags can have levels because only they really
            # tell us anyting about "state" --
            # whether we are awaiting something
            # or are inside something.
            if ( $terminal !~ /^[SE]_/xms ) {
                $level{$terminal} = $no_cruft_allowed;
                next TERMINAL;
            }
            my $element = substr $terminal, 2;
            if ( $Marpa::R2::HTML::Internal::EMPTY_ELEMENT{$element} ) {
                $level{$terminal} = $no_cruft_allowed;
                next TERMINAL;
            }

            my $element_type =
                $Marpa::R2::HTML::Internal::ELEMENT_TYPE{$element};
            if ( defined $element_type
                and $element_type ~~ [qw(block_element header_element)] )
            {
                $level{$terminal} = $block_level;
                next TERMINAL;
            } ## end if ( defined $element_type and $element_type ~~ [...])

            $level{$terminal} = $inline_level;

        } ## end for my $terminal ( grep { not defined $level{$_} } ( ...))

        EXPECTED_TERMINAL:
        for my $expected_terminal ( keys %optional_terminals ) {

            # Regardless of levels, allow no cruft before a start tag.
            # Start whatever it is, then deal with the cruft.
            next EXPECTED_TERMINAL if $expected_terminal =~ /^S_/xms;

            # For end tags, use the levels
            TERMINAL: for my $actual_terminal (@terminals) {
                $ok_as_cruft{$expected_terminal}{$actual_terminal} =
                    $level{$actual_terminal} < $level{$expected_terminal};
            }
        } ## end for my $expected_terminal ( keys %optional_terminals )

    } ## end DECIDE_CRUFT_TREATMENT:

    my $grammar = Marpa::R2::Grammar->new(
        {   rules           => \@rules,
            start           => 'document',
            terminals       => \@terminals,
            inaccessible_ok => 1,
            unproductive_ok => 1,
            default_action  => 'Marpa::R2::HTML::Internal::default_action',
            default_empty_action => '::undef',
        }
    );
    $grammar->precompute();

    if ( $self->{trace_rules} ) {
        say {$trace_fh} $grammar->show_rules()
            or Carp::croak("Cannot print: $ERRNO");
    }
    if ( $self->{trace_QDFA} ) {
        say {$trace_fh} $grammar->show_QDFA()
            or Carp::croak("Cannot print: $ERRNO");
    }

    my $recce = Marpa::R2::Recognizer->new(
        {   grammar           => $grammar,
            trace_terminals   => $self->{trace_terminals},
            trace_earley_sets => $self->{trace_earley_sets},
        }
    );

    $self->{recce}  = $recce;
    $self->{tokens} = \@html_parser_tokens;

    # These variables track virtual start tokens as
    # a protection against infinite loops.
    my %start_virtuals_used           = ();
    my $earleme_of_last_start_virtual = -1;

    my $marpa_token = shift @marpa_tokens;
    RECCE_RESPONSE: while ( defined $marpa_token ) {

        my $read_result = $recce->read( @{$marpa_token} );
        if ( defined $read_result ) {
            $marpa_token = shift @marpa_tokens;
            next RECCE_RESPONSE;
        }

        my $actual_terminal = $marpa_token->[0];
        if ($trace_terminals) {
            say {$trace_fh} 'Literal Token not accepted: ', $actual_terminal
                or Carp::croak("Cannot print: $ERRNO");
        }

        my $virtual_token_to_add;

        FIND_VIRTUAL_TOKEN: {
            my $virtual_terminal;
            my @virtuals_expected =
                sort { $optional_terminals{$a} <=> $optional_terminals{$b} }
                grep { defined $optional_terminals{$_} }
                @{ $recce->terminals_expected() };
            if ($trace_conflicts) {
                say {$trace_fh} 'Conflict of virtual choices'
                    or Carp::croak("Cannot print: $ERRNO");
                say {$trace_fh} "Actual Token is $actual_terminal"
                    or Carp::croak("Cannot print: $ERRNO");
                say {$trace_fh} +( scalar @virtuals_expected ),
                    ' virtual terminals expected: ', join q{ },
                    @virtuals_expected
                    or Carp::croak("Cannot print: $ERRNO");
            } ## end if ($trace_conflicts)

            LOOKAHEAD_VIRTUAL_TERMINAL:
            while ( my $candidate = pop @virtuals_expected ) {

                # Start an implied table only if the next token is one which
                # can only occur inside a table
                if ( $candidate eq 'S_table' ) {
                    if (not $actual_terminal ~~ [
                            qw(
                                S_caption S_col S_colgroup S_thead S_tfoot
                                S_tbody S_tr S_th S_td
                                E_caption E_col E_colgroup E_thead E_tfoot
                                E_tbody E_tr E_th E_td
                                E_table
                                )
                        ]
                        )
                    {
                        next LOOKAHEAD_VIRTUAL_TERMINAL;
                    } ## end if ( not $actual_terminal ~~ [ qw(...)])

                    # The above test implies the others below, so
                    # this virtual table start terminal is OK.
                    $virtual_terminal = $candidate;
                    last LOOKAHEAD_VIRTUAL_TERMINAL;
                } ## end if ( $candidate eq 'S_table' )

                # For other than <table>, we are permissive.
                # Unless the lookahead gives us
                # a specific reason to
                # reject the virtual terminal, we accept it.

                # No need to check lookahead, unless we are starting
                # an element
                if ( $candidate !~ /^S_/xms ) {
                    $virtual_terminal = $candidate;
                    last LOOKAHEAD_VIRTUAL_TERMINAL;
                }

#<<< no perltidy cycles as of 12 Mar 2010

                my $candidate_level =
                    $Marpa::R2::HTML::Internal::VIRTUAL_TOKEN_HIERARCHY{
                    $candidate };

#>>>
                # If the candidate is not part of the hierarchy, no need to check
                # lookahead
                if ( not defined $candidate_level ) {
                    $virtual_terminal = $candidate;
                    last LOOKAHEAD_VIRTUAL_TERMINAL;
                }

                my $actual_terminal_level =
                    $Marpa::R2::HTML::Internal::VIRTUAL_TOKEN_HIERARCHY{
                    $actual_terminal};

                # If the actual terminal is not part of the hierarchy, no need to check
                # lookahead, either
                if ( not defined $actual_terminal_level ) {
                    $virtual_terminal = $candidate;
                    last LOOKAHEAD_VIRTUAL_TERMINAL;
                }

                # Here we are trying to deal with a higher-level element's
                # start or end, by starting a new lower level element.
                # This won't work, because we'll have to close it
                # immediately with another virtual terminal.
                # At best this means useless, empty elements.
                # At worst, it means an infinite loop where
                # empty lower-level elements are repeatedly added.
                #
                next LOOKAHEAD_VIRTUAL_TERMINAL
                    if $candidate_level <= $actual_terminal_level;

                $virtual_terminal = $candidate;
                last LOOKAHEAD_VIRTUAL_TERMINAL;

            } ## end while ( my $candidate = pop @virtuals_expected )

            if ($trace_terminals) {
                say {$trace_fh} 'Converting Token: ', $actual_terminal
                    or Carp::croak("Cannot print: $ERRNO");
                if ( defined $virtual_terminal ) {
                    say {$trace_fh} 'Candidate as Virtual Token: ',
                        $virtual_terminal
                        or Carp::croak("Cannot print: $ERRNO");
                }
            } ## end if ($trace_terminals)

            # Depending on the expected (optional or virtual)
            # terminal and the actual
            # terminal, we either want to add the actual one as cruft, or add
            # the virtual one to move on in the parse.

            if ( $trace_terminals > 1 and defined $virtual_terminal ) {
                say {$trace_fh}
                    "OK as cruft when expecting $virtual_terminal: ",
                    join q{ }, keys %{ $ok_as_cruft{$virtual_terminal} }
                    or Carp::croak("Cannot print: $ERRNO");
            } ## end if ( $trace_terminals > 1 and defined $virtual_terminal)

            last FIND_VIRTUAL_TOKEN if not defined $virtual_terminal;
            last FIND_VIRTUAL_TOKEN
                if $ok_as_cruft{$virtual_terminal}{$actual_terminal};

            CHECK_FOR_INFINITE_LOOP: {

                # It is sufficient to check for start tags.
                # Just ending things will never cause an infinite loop.
                last CHECK_FOR_INFINITE_LOOP if $virtual_terminal !~ /^S_/xms;

                # Are we at the same earleme as we were when the last
                # virtual start was added?  If not, no problem.
                # But we need to reinitialize.
                my $current_earleme = $recce->current_earleme();
                if ( $current_earleme != $earleme_of_last_start_virtual ) {
                    $earleme_of_last_start_virtual = $current_earleme;
                    %start_virtuals_used           = ();
                    last CHECK_FOR_INFINITE_LOOP;
                }

                # Is this the first time we've added this start
                # terminal?  If so, we're OK.
                last CHECK_FOR_INFINITE_LOOP
                    if $start_virtuals_used{$virtual_terminal}++ <= 1;

                # Attempt to add duplicate.
                # Give up on adding virtual at this location,
                # and warn the user.
                ( my $tagname = $virtual_terminal ) =~ s/^S_//xms;
                say {$trace_fh}
                    "Warning: attempt to add <$tagname> twice at the same place"
                    or Carp::croak("Cannot print: $ERRNO");
                last FIND_VIRTUAL_TOKEN;

            } ## end CHECK_FOR_INFINITE_LOOP:

            my $tdesc_list = $marpa_token->[1];
            my $first_tdesc_start_token =
                $tdesc_list->[0]
                ->[Marpa::R2::HTML::Internal::TDesc::START_TOKEN];
            $virtual_token_to_add = [
                $virtual_terminal, [ [ 'POINT', $first_tdesc_start_token ] ]
            ];

        } ## end FIND_VIRTUAL_TOKEN:

        if ( defined $virtual_token_to_add ) {
            $recce->read( @{$virtual_token_to_add} );
            next RECCE_RESPONSE;
        }

        # If we didn't find a token to add, add the
        # current physical token as CRUFT.

        if ($trace_terminals) {
            say {$trace_fh} 'Adding actual token as cruft: ', $actual_terminal
                or Carp::croak("Cannot print: $ERRNO");
        }

        # Cruft tokens are not virtual.
        # They are the real things, hacked up.
        $marpa_token->[0] = 'CRUFT';
        if ($trace_cruft) {
            my ( $line, $col ) =
                earleme_to_linecol( $self, $recce->current_earleme() );

            # HTML::Parser uses one-based line numbers,
            # but zero-based column numbers
            # The convention (in vi and cut) is that
            # columns are also one-based.
            $col++;

            say {$trace_fh} qq{Cruft at line $line, column $col: "},
                ${ tdesc_list_to_literal( $self, $marpa_token->[1] ) }, q{"}
                or Carp::croak("Cannot print: $ERRNO");
        } ## end if ($trace_cruft)

    } ## end while ( defined $marpa_token )

    if ($trace_terminals) {
        say {$trace_fh} 'at end of tokens'
            or Carp::croak("Cannot print: $ERRNO");
    }

    $recce->end_input();

    my %closure = ();
    {
        my $user_top_handler =
            $self->{user_handlers_by_pseudoclass}->{ANY}->{TOP};
        $closure{'!TOP_handler'} =
            defined $user_top_handler
            ? wrap_user_top_handler($user_top_handler)
            : \&Marpa::R2::HTML::Internal::default_top_handler;
    } ## end if ( defined( my $user_top_handler = $self->{...}))

    if ( defined $self->{user_handlers_by_class}->{ANY}->{ANY} ) {
        $closure{'!DEFAULT_ELE_handler'} =
            $self->{user_handlers_by_class}->{ANY}->{ANY};
    }

    PSEUDO_CLASS:
    for my $pseudoclass (
        qw(PI DECL COMMENT PROLOG TRAILER WHITESPACE CDATA PCDATA CRUFT))
    {
        my $pseudoclass_action =
            $self->{user_handlers_by_pseudoclass}->{ANY}->{$pseudoclass};
        my $pseudoclass_action_name = "!$pseudoclass" . '_handler';
        if ($pseudoclass_action) {
            $closure{$pseudoclass_action_name} =
                wrap_user_tdesc_handler( $pseudoclass_action,
                { pseudoclass => $pseudoclass } );
            next PSEUDO_CLASS;
        } ## end if ($pseudoclass_action)
        $closure{$pseudoclass_action_name} =
            \&Marpa::R2::HTML::Internal::default_action;
    } ## end for my $pseudoclass (...)

    while ( my ( $element_action, $element ) = each %element_actions ) {
        $closure{$element_action} = create_tdesc_handler( $self, $element );
    }

    ELEMENT_ACTION:
    while ( my ( $element_action, $data ) =
        each %pseudoclass_element_actions )
    {

        # As of now, there are
        # no per-element pseudo-classes, and since I can't regression test
        # this logic any more, I'm commenting it out.
        Marpa::R2::exception('per-element pseudo-classes not implemented');

        # my ( $pseudoclass, $element ) = @{$data};
        # my $pseudoclass_action =
        #    $self->{user_handlers_by_pseudoclass}->{$element}
        #    ->{$pseudoclass}
        #    // $self->{user_handlers_by_pseudoclass}->{ANY}->{$pseudoclass};
        # if ( defined $pseudoclass_action ) {
        #    $pseudoclass_action =
        #        wrap_user_tdesc_handler($pseudoclass_action);
        # }
        # $pseudoclass_action //= \&Marpa::R2::HTML::Internal::default_action;
        # $closure{$element_action} = $pseudoclass_action;
    } ## end while ( my ( $element_action, $data ) = each ...)

    my $value = do {
        local $Marpa::R2::HTML::Internal::PARSE_INSTANCE = $self;
        local $Marpa::R2::HTML::INSTANCE                 = {};
        $recce->set(
            {   trace_values  => $self->{trace_values},
                trace_actions => $self->{trace_actions},
                closures      => \%closure,
            }
        );
        $recce->value();
    };
    Marpa::R2::exception('No parse: evaler returned undef')
        if not defined $value;
    return ${$value};

} ## end sub parse

sub Marpa::R2::HTML::html {
    my ( $document_ref, @args ) = @_;
    my $html = Marpa::R2::HTML::Internal::create(@args);
    return Marpa::R2::HTML::Internal::parse( $html, $document_ref );
}

1;
