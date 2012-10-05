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
$VERSION        = '2.021_002';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

our @EXPORT_OK;
use base qw(Exporter);
BEGIN { @EXPORT_OK = qw(html); }

package Marpa::R2::HTML::Internal;

# Data::Dumper is used in tracing
use Data::Dumper;

use Carp ();
use HTML::Parser 3.69;
use HTML::Entities qw(decode_entities);
use HTML::Tagset ();

use Marpa::R2::HTML::Core_Grammar;

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

# constants

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';
    :package=Marpa::R2::HTML::Internal::TDesc
    TYPE
    START_TOKEN
    END_TOKEN
    VALUE
    RULE_ID
END_OF_STRUCTURE
    Marpa::R2::offset($structure);
} ## end BEGIN

use constant PHYSICAL_TOKEN      => 42;
use constant RUBY_SLIPPERS_TOKEN => 43;

our @LIBMARPA_ERROR_NAMES = Marpa::R2::Thin::error_names();
our $UNEXPECTED_TOKEN_ID;
our $NO_MARPA_ERROR;
ERROR: for my $error_number ( 0 .. $#LIBMARPA_ERROR_NAMES ) {
    my $error_name = $LIBMARPA_ERROR_NAMES[$error_number];
    if ( $error_name eq 'MARPA_ERR_UNEXPECTED_TOKEN_ID' ) {
        $UNEXPECTED_TOKEN_ID = $error_number;
        next ERROR;
    }
    if ( $error_name eq 'MARPA_ERR_NONE' ) {
        $NO_MARPA_ERROR = $error_number;
        next ERROR;
    }
} ## end ERROR: for my $error_number ( 0 .. $#LIBMARPA_ERROR_NAMES )

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';
    :package=Marpa::R2::HTML::Internal::Token
    TOKEN_NAME
    TYPE
    LINE
    COL
    =COLUMN
    START_OFFSET
    END_OFFSET
    ATTR
    =IS_CDATA
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

sub earleme_to_linecol {
    my ( $self, $earleme ) = @_;
    my $html_parser_tokens = $self->{tokens};
    my $html_token_ix = $self->{earleme_to_html_token_ix}->[$earleme] + 1;

    die if not defined $html_token_ix;

    return @{ $html_parser_tokens->[$html_token_ix] }[
        Marpa::R2::HTML::Internal::Token::LINE,
        Marpa::R2::HTML::Internal::Token::COLUMN,
    ];

} ## end sub earleme_to_linecol

sub earleme_to_offset {
    my ( $self, $earleme ) = @_;
    my $html_parser_tokens = $self->{tokens};
    my $html_token_ix = $self->{earleme_to_html_token_ix}->[$earleme] + 1;

    die if not defined $html_token_ix;

    return $html_parser_tokens->[$html_token_ix]
        ->[Marpa::R2::HTML::Internal::Token::END_OFFSET];

} ## end sub earleme_to_offset

sub add_handler {
    my ( $self, $handler_description ) = @_;
    my $ref_type = ref $handler_description || 'not a reference';
    Marpa::R2::exception(
        "Long form handler description should be ref to hash, but it is $ref_type"
    ) if $ref_type ne 'HASH';
    my $element     = delete $handler_description->{element};
    my $class       = delete $handler_description->{class};
    my $pseudoclass = delete $handler_description->{pseudoclass};
    my $action      = delete $handler_description->{action};
    Marpa::R2::exception(
        'Unknown option(s) in Long form handler description: ',
        ( join q{ }, keys %{$handler_description} )
    ) if scalar keys %{$handler_description};

    Marpa::R2::exception('Handler action must be CODE ref')
        if ref $action ne 'CODE';

    if ( defined $pseudoclass ) {
        $self->{handler_by_species}->{$pseudoclass} = $action;
        return 1;
    }

    $element = q{*} if not $element;
    $element = lc $element;
    $class //= q{*};
    $self->{handler_by_element_and_class}->{ join q{;}, $element, $class } =
        $action;
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
        my ( $element, $class, $pseudoclass );
        my $action = $handler_specs->{$specifier};
        ( $element, $class ) = ( $specifier =~ /\A ([^.]*) [.] (.*) \z/xms )
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
                class       => $class,
                pseudoclass => $pseudoclass,
                action      => $action
            }
        );
    } ## end HANDLER_SPEC: for my $specifier ( keys %{$handler_specs} )

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
                    qw(trace_fh trace_values trace_handlers
                        trace_conflicts trace_rules 
                        trace_terminals trace_cruft)
                ]
                )
            {
                Marpa::R2::exception("unknown option: $option");
            } ## end if ( not $option ~~ [ ...])
            $self->{$option} = $option_hash->{$option};
        } ## end OPTION: for my $option ( keys %{$option_hash} )
    } ## end ARG: for my $arg (@_)
    return $self;
} ## end sub create

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

@Marpa::R2::HTML::Internal::CORE_TERMINALS =
    qw(C D PI CRUFT CDATA PCDATA WHITESPACE EOF );

push @Marpa::R2::HTML::Internal::CORE_TERMINALS,
    keys %Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS;

sub handler_find {
    my ( $self, $rule_id, $class ) = @_;
    my $trace_handlers = $self->{trace_handlers};
    my $handler;
    $class //= q{*};
    my $action = $self->{thick_grammar}->action($rule_id);
    FIND_HANDLER: {

        last FIND_HANDLER if not defined $action;

        if ( index( $action, 'SPE_' ) == 0 ) {
            my $species = substr $action, 4;
            $handler = $self->{handler_by_species}->{$species};
            say {*STDERR}
                qq{Rule $rule_id: Found handler by species: "$species"}
                or Carp::croak("Cannot print: $ERRNO")
                if $trace_handlers and defined $handler;
            last FIND_HANDLER;
        } ## end if ( index( $action, 'SPE_' ) == 0 )

        ## At this point action always is defined
        ## and starts with 'ELE_'
        my $element = substr $action, 4;

        my @handler_keys = (
            ( join q{;}, $element, $class ),
            ( join q{;}, q{*},     $class ),
            ( join q{;}, $element, q{*} ),
            ( join q{;}, q{*},     q{*} ),
        );
        ($handler) =
            grep {defined}
            @{ $self->{handler_by_element_and_class} }{@handler_keys};

        say {*STDERR} qq{Rule $rule_id: Found handler by action and class: "},
            ( grep { defined $self->{handler_by_element_and_class}->{$_} }
                @handler_keys )[0], q{"}
            or Carp::croak("Cannot print: $ERRNO")
            if $trace_handlers and defined $handler;

    } ## end FIND_HANDLER:
    return $handler if defined $handler;

    say {*STDERR} qq{Rule $rule_id: Using default handler for action "},
        ( $action // q{*} ), qq{" and class: "$class"}
        or Carp::croak("Cannot print: $ERRNO")
        if $trace_handlers;

    return 'default_handler';
} ## end sub handler_find

# "Original" value of a token range -- that is, the corresponding
# text of the original document, unchanged.
# Returned as a reference, because it may be very long
sub token_range_to_original {
    my ( $self, $first_token_ix, $last_token_ix ) = @_;

    return \q{} if not defined $first_token_ix;
    my $document = $self->{document};
    my $tokens   = $self->{tokens};
    my $start_offset =
        $tokens->[$first_token_ix]
        ->[Marpa::R2::HTML::Internal::Token::START_OFFSET];
    my $end_offset =
        $tokens->[$last_token_ix]
        ->[Marpa::R2::HTML::Internal::Token::END_OFFSET];
    my $original = substr ${$document}, $start_offset,
        ( $end_offset - $start_offset );
    return \$original;
} ## end sub token_range_to_original

# "Original" value of token -- that is, the corresponding
# text of the original document, unchanged.
# The empty string if there is no such text.
# Returned as a reference, because it may be very long
sub tdesc_item_to_original {
    my ( $self, $tdesc_item ) = @_;

    my $text            = q{};
    my $document        = $self->{document};
    my $tokens          = $self->{tokens};
    my $tdesc_item_type = $tdesc_item->[0];
    return q{} if not defined $tdesc_item_type;

    if ( $tdesc_item_type eq 'PHYSICAL_TOKEN' ) {
        return token_range_to_original(
            $self,
            $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::START_TOKEN],
            $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::END_TOKEN],
        );
    } ## end if ( $tdesc_item_type eq 'PHYSICAL_TOKEN' )
    if ( $tdesc_item_type eq 'VALUED_SPAN' ) {
        return token_range_to_original(
            $self,
            $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::START_TOKEN],
            $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::END_TOKEN],
        );
    } ## end if ( $tdesc_item_type eq 'VALUED_SPAN' )
    return q{};
} ## end sub tdesc_item_to_original

# Given a token range and a tdesc list,
# return a reference to the literal value.
sub range_and_values_to_literal {
    my ( $self, $next_token_ix, $final_token_ix, $tdesc_list ) = @_;

    my @flat_tdesc_list = ();
    TDESC_ITEM: for my $tdesc_item ( @{$tdesc_list} ) {
        my $type = $tdesc_item->[0];
        next TDESC_ITEM if not defined $type;
        next TDESC_ITEM if $type eq 'ZERO_SPAN';
        next TDESC_ITEM if $type eq 'RUBY_SLIPPERS_TOKEN';
        if ( $type eq 'VALUES' ) {
            push @flat_tdesc_list,
                @{ $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::VALUE] };
            next TDESC_ITEM;
        }
        push @flat_tdesc_list, $tdesc_item;
    } ## end TDESC_ITEM: for my $tdesc_item ( @{$tdesc_list} )

    my @literal_pieces = ();
    TDESC_ITEM: for my $tdesc_item (@flat_tdesc_list) {

        my ( $tdesc_item_type, $next_explicit_token_ix,
            $furthest_explicit_token_ix )
            = @{$tdesc_item};

        if ( not defined $next_explicit_token_ix ) {
            ## An element can contain no HTML tokens -- it may contain
            ## only Ruby Slippers tokens.
            ## Treat this as a special case.
            if ( $tdesc_item_type eq 'VALUED_SPAN' ) {
                my $value =
                    $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::VALUE]
                    // q{};
                push @literal_pieces, \( q{} . $value );
            } ## end if ( $tdesc_item_type eq 'VALUED_SPAN' )
            next TDESC_ITEM;
        } ## end if ( not defined $next_explicit_token_ix )

        push @literal_pieces,
            token_range_to_original( $self, $next_token_ix,
            $next_explicit_token_ix - 1 )
            if $next_token_ix < $next_explicit_token_ix;
        if ( $tdesc_item_type eq 'VALUED_SPAN' ) {
            my $value =
                $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::VALUE];
            if ( defined $value ) {
                push @literal_pieces, \( q{} . $value );
                $next_token_ix = $furthest_explicit_token_ix + 1;
                next TDESC_ITEM;
            }
            ## FALL THROUGH
        } ## end if ( $tdesc_item_type eq 'VALUED_SPAN' )
        push @literal_pieces,
            token_range_to_original( $self, $next_explicit_token_ix,
            $furthest_explicit_token_ix )
            if $next_explicit_token_ix <= $furthest_explicit_token_ix;
        $next_token_ix = $furthest_explicit_token_ix + 1;
    } ## end TDESC_ITEM: for my $tdesc_item (@flat_tdesc_list)

    return \( join q{}, map { ${$_} } @literal_pieces );

} ## end sub range_and_values_to_literal

sub parse {
    my ( $self, $document_ref ) = @_;

    my %tags = ();

    Marpa::R2::exception(
        "parse() already run on this object\n",
        'For a new parse, create a new object'
    ) if $self->{document};

    my $trace_cruft     = $self->{trace_cruft};
    my $trace_terminals = $self->{trace_terminals} // 0;
    my $trace_conflicts = $self->{trace_conflicts};
    my $trace_handlers  = $self->{trace_handlers};
    my $trace_values    = $self->{trace_values};
    my $trace_fh        = $self->{trace_fh};
    my $ref_type        = ref $document_ref;
    Marpa::R2::exception('Arg to parse() must be ref to string')
        if not $ref_type
            or $ref_type ne 'SCALAR'
            or not defined ${$document_ref};

    my $document = $self->{document} = $document_ref;

    my @raw_tokens = ();
    my $p          = HTML::Parser->new(
        api_version => 3,
        start_h     => [
            \@raw_tokens, q{tagname,'S',line,column,offset,offset_end,attr}
        ],
        end_h =>
            [ \@raw_tokens, q{tagname,'E',line,column,offset,offset_end} ],
        text_h => [
            \@raw_tokens,
            q{'WHITESPACE','T',line,column,offset,offset_end,is_cdata}
        ],
        comment_h =>
            [ \@raw_tokens, q{'C','C',line,column,offset,offset_end} ],
        declaration_h =>
            [ \@raw_tokens, q{'D','D',line,column,offset,offset_end} ],
        process_h =>
            [ \@raw_tokens, q{'PI','PI',line,column,offset,offset_end} ],
        unbroken_text => 1
    );

    $p->parse( ${$document} );
    $p->eof;

    my %terminals =
        map { $_ => 1 } @Marpa::R2::HTML::Internal::CORE_TERMINALS;
    my @html_parser_tokens = ();
    HTML_PARSER_TOKEN:
    for my $raw_token (@raw_tokens) {
        my ( $dummy, $token_type, $line, $column, $offset, $offset_end ) =
            @{$raw_token};

        PROCESS_BY_TYPE: {
            if ( $token_type eq 'T' ) {
                if (substr(
                        ${$document}, $offset, ( $offset_end - $offset )
                    ) =~ / \S /xms
                    )
                {
                    my $is_cdata = $raw_token
                        ->[Marpa::R2::HTML::Internal::Token::IS_CDATA];
                    $raw_token->[Marpa::R2::HTML::Internal::Token::TOKEN_NAME]
                        = $is_cdata ? 'CDATA' : 'PCDATA';
                } ## end if ( substr( ${$document}, $offset, ( $offset_end - ...)))
                last PROCESS_BY_TYPE;
            } ## end if ( $token_type eq 'T' )
            if ( $token_type eq 'S' ) {
                my $tag_name = $raw_token
                    ->[Marpa::R2::HTML::Internal::Token::TOKEN_NAME];
                $tags{$tag_name}++;
                my $terminal = "S_$tag_name";
                $raw_token->[Marpa::R2::HTML::Internal::Token::TOKEN_NAME] =
                    $terminal;
                $terminals{$terminal}++;
                last PROCESS_BY_TYPE;
            } ## end if ( $token_type eq 'S' )
            if ( $token_type eq 'E' ) {

                # If it's a virtual token from HTML::Parser,
                # pretend it never existed.
                # HTML::Parser supplies missing
                # end tags for title elements, but for no
                # others.
                # This is not helpful and we need to special-case
                # these zero-length tags and throw them away.
                next HTML_PARSER_TOKEN if $offset_end <= $offset;

                my $tag_name = $raw_token
                    ->[Marpa::R2::HTML::Internal::Token::TOKEN_NAME];
                $tags{$tag_name}++;
                my $terminal = "E_$tag_name";
                $raw_token->[Marpa::R2::HTML::Internal::Token::TOKEN_NAME] =
                    $terminal;
                $terminals{$terminal}++;
                last PROCESS_BY_TYPE;
            } ## end if ( $token_type eq 'E' )
        } ## end PROCESS_BY_TYPE:
        push @html_parser_tokens, $raw_token;
    } ## end HTML_PARSER_TOKEN: for my $raw_token (@raw_tokens)

    # Points AFTER the last HTML
    # Parser token.
    # The other logic needs to be ready for this.
    {
        my $document_length = length ${$document};
        my $last_token      = $html_parser_tokens[-1];
        push @html_parser_tokens,
            [
            'EOF', 'EOF',
            @{$last_token}[
                Marpa::R2::HTML::Internal::Token::LINE,
            Marpa::R2::HTML::Internal::Token::COLUMN
            ],
            $document_length,
            $document_length
            ];
    }

    # conserve memory
    $p          = undef;
    @raw_tokens = ();

    my @rules     = @{$Marpa::R2::HTML::Internal::CORE_RULES};
    my @terminals = keys %terminals;

    # Special cases which are dealt with elsewhere.
    # As of now the only special cases are elements with optional
    # start and end tags
    for my $special_element (qw(html head body table tbody tr td)) {
        delete $tags{$special_element};
    }

    for my $rule (@rules) {
        my $lhs = $rule->{lhs};
        if ( 0 == index $lhs, 'ELE_' ) {
            my $tag = substr $lhs, 4;
            my $end_tag = 'E_' . $tag;
            delete $tags{$tag};

            # There may be no
            # end tag in the input.
            # This silences the warning.
            if ( not $terminals{$end_tag} ) {
                push @terminals, $end_tag;
                $terminals{$end_tag} = 1;
            }

        } ## end if ( 0 == index $lhs, 'ELE_' )
    } ## end for my $rule (@rules)

    ELEMENT: for my $tag ( keys %tags ) {
        my $start_tag = "S_$tag";
        my $end_tag   = "E_$tag";
        my $contents;
        my $element_type;
        FIND_TYPE_AND_CONTENTS: {
            $contents = $Marpa::R2::HTML::Internal::IS_BLOCK_ELEMENT->{$tag};
            if ( defined $contents ) {
                $element_type = 'block_element';
                last FIND_TYPE_AND_CONTENTS;
            }
            $contents = $Marpa::R2::HTML::Internal::IS_INLINE_ELEMENT->{$tag};
            if ( defined $contents ) {
                $element_type = 'inline_element';
                last FIND_TYPE_AND_CONTENTS;
            }
            $element_type = 'anywhere_element';
            $contents     = 'mixed_flow';
        } ## end FIND_TYPE_AND_CONTENTS:

        push @rules,
            {
            lhs => $element_type,
            rhs => ["ELE_$tag"],
            },
            {
            lhs    => "ELE_$tag",
            rhs    => [ $start_tag, $contents, $end_tag ],
            action => "ELE_$tag",
            };

        # There may be no
        # end tag in the input.
        # This silences the warning.
        if ( not $terminals{$end_tag} ) {
            push @terminals, $end_tag;
            $terminals{$end_tag} = 1;
        }

    } ## end ELEMENT: for my $tag ( keys %tags )


    my $grammar = Marpa::R2::Grammar->new(
        {   rules          => \@rules,
            start          => 'document',
            terminals      => \@terminals,
            default_action => 'Marpa::R2::HTML::Internal::default_action',
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

    my $thin_grammar = $grammar->thin();

    # Memoize this -- we will use it a lot
    my $highest_symbol_id = $thin_grammar->highest_symbol_id();

    # For the Ruby Slippers engine
    # We need to know quickly if a symbol is a start tag;
    my @is_start_tag = ();

    # Find Ruby slippers ranks, by symbol ID
    my @ruby_rank_by_id = ();
    {
        my @non_final_end_tag_ids = ();
        my $rank_by_name =
            $Marpa::R2::HTML::Internal::RUBY_SLIPPERS_RANK_BY_NAME;
        SYMBOL:
        for my $symbol_id ( 0 .. $highest_symbol_id ) {
            my $symbol_name = $grammar->symbol_name($symbol_id);
            next SYMBOL if not 0 == index $symbol_name, 'E_';
            next SYMBOL if $symbol_name ~~ [qw(E_body E_html)];
            push @non_final_end_tag_ids, $symbol_id;
        } ## end SYMBOL: for my $symbol_id ( 0 .. $highest_symbol_id )

        my %ruby_vectors = ();
        for my $rejected_symbol_name ( keys %{$rank_by_name} ) {
            my @ruby_vector_by_id = ( (0) x ( $highest_symbol_id + 1 ) );
            my $rank_by_candidate_name =
                $rank_by_name->{$rejected_symbol_name};
            CANDIDATE:
            for my $candidate_name ( keys %{$rank_by_candidate_name} ) {
                my $rank = $rank_by_candidate_name->{$candidate_name};
                if ( $candidate_name eq '!non_final_end' ) {
                    $ruby_vector_by_id[$_] = $rank for @non_final_end_tag_ids;
                    next CANDIDATE;
                }
                my $candidate_id = $grammar->thin_symbol($candidate_name);
                die "Unknown ruby slippers candidate name: $candidate_name"
                    if not defined $candidate_id;
                $ruby_vector_by_id[$candidate_id] = $rank
                    for @non_final_end_tag_ids;
            } ## end CANDIDATE: for my $candidate_name ( keys %{...})
            $ruby_vectors{$rejected_symbol_name} = \@ruby_vector_by_id;
        } ## end for my $rejected_symbol_name ( keys %{$rank_by_name} )

        my @no_ruby_slippers_vector = ( (0) x ( $highest_symbol_id + 1 ) );
        SYMBOL: for my $rejected_symbol_id ( 0 .. $highest_symbol_id ) {
            if ( not $thin_grammar->symbol_is_terminal($rejected_symbol_id) )
            {
                $ruby_rank_by_id[$rejected_symbol_id] =
                    \@no_ruby_slippers_vector;
                next SYMBOL;
            } ## end if ( not $thin_grammar->symbol_is_terminal(...))
            my $rejected_symbol_name =
                $grammar->symbol_name($rejected_symbol_id);
            my $placement;
            FIND_PLACEMENT: {
                my $prefix = substr $rejected_symbol_name, 0, 2;
                if ( $prefix eq 'S_' ) {
                    $placement = 'start';
                    $is_start_tag[$rejected_symbol_id] = 1;
                    last FIND_PLACEMENT;
                }
                if ( $prefix eq 'E_' ) {
                    $placement = 'end';
                }
            } ## end FIND_PLACEMENT:
            my $ruby_vector = $ruby_vectors{$rejected_symbol_name};
            if ( defined $ruby_vector ) {
                $ruby_rank_by_id[$rejected_symbol_id] = $ruby_vector;
                next SYMBOL;
            }
            if ( not defined $placement ) {
                $ruby_rank_by_id[$rejected_symbol_id] =
                    $ruby_vectors{'!non_element'}
                    // \@no_ruby_slippers_vector;
                next SYMBOL;
            } ## end if ( not defined $placement )
            my $tag = substr $rejected_symbol_name, 2;
            my $type =
                $Marpa::R2::HTML::Internal::IS_INLINE_ELEMENT->{$tag}
                ? 'inline'
                : $Marpa::R2::HTML::Internal::IS_BLOCK_ELEMENT->{$tag}
                ? 'block'
                : $Marpa::R2::HTML::Internal::IS_HEAD_ELEMENT->{$tag} ? 'head'
                :   'anywhere';
            $ruby_vector =
                $ruby_vectors{ q{!} . $type . q{_} . $placement . q{_tag} };
            if ( defined $ruby_vector ) {
                $ruby_rank_by_id[$rejected_symbol_id] = $ruby_vector;
                next SYMBOL;
            }
            $ruby_vector = $ruby_vectors{ q{!} . $placement . q{_tag} };
            if ( defined $ruby_vector ) {
                $ruby_rank_by_id[$rejected_symbol_id] = $ruby_vector;
                next SYMBOL;
            }
            $ruby_rank_by_id[$rejected_symbol_id] = \@no_ruby_slippers_vector;
        } ## end SYMBOL: for my $rejected_symbol_id ( 0 .. $highest_symbol_id )

    }

    my $recce = Marpa::R2::Thin::R->new($thin_grammar);
    $recce->start_input();

    $self->{thick_grammar}            = $grammar;
    $self->{recce}                    = $recce;
    $self->{tokens}                   = \@html_parser_tokens;
    $self->{earleme_to_html_token_ix} = [-1];

    # These variables track virtual start tokens as
    # a protection against infinite loops.
    my %start_virtuals_used           = ();
    my $earleme_of_last_start_virtual = -1;

    # first token is a dummy, so that ix is never 0
    # this is done because 0 has a special meaning as a Libmarpa
    # token value
    my $latest_html_token = -1;
    my $token_number      = 0;
    my $token_count       = scalar @html_parser_tokens;

    # this array track the last token number (location) at which
    # the symbol with this number was last read.  It's used
    # to prevent the same Ruby Slippers token being added
    # at the same location more than once.
    # If allowed, this could cause an infinite loop.
    # Note that only start tags are tracked -- the rest of the
    # array stays at -1.
    my @terminal_last_seen = ( (-1) x ( $highest_symbol_id + 1 ) );

    $thin_grammar->throw_set(0);
    RECCE_RESPONSE: while ( $token_number < $token_count ) {
        my $token = $html_parser_tokens[$token_number];

        my $marpa_symbol_id =
            $grammar->thin_symbol(
            $token->[Marpa::R2::HTML::Internal::Token::TOKEN_NAME] );
        my $read_result =
            $recce->alternative( $marpa_symbol_id, PHYSICAL_TOKEN, 1 );
        if ( $read_result != $UNEXPECTED_TOKEN_ID ) {
            if ( $read_result != $NO_MARPA_ERROR ) {
                die $thin_grammar->error();
            }
            if ($trace_terminals) {
                say {$trace_fh} 'Token accepted: ',
                    $token->[Marpa::R2::HTML::Internal::Token::TOKEN_NAME],
                    or Carp::croak("Cannot print: $ERRNO");
            }
            if ( $recce->earleme_complete() < 0 ) {
                die $thin_grammar->error();
            }
            my $last_html_token_of_marpa_token = $token_number;
            $token_number++;
            if ( defined $last_html_token_of_marpa_token ) {
                $latest_html_token = $last_html_token_of_marpa_token;
            }
            my $current_earleme = $recce->current_earleme();
            die $thin_grammar->error() if not defined $current_earleme;
            $self->{earleme_to_html_token_ix}->[$current_earleme] =
                $latest_html_token;
            next RECCE_RESPONSE;
        } ## end if ( $read_result != $UNEXPECTED_TOKEN_ID )

        my $rejected_terminal_name = $token->[0];
        my $rejected_terminal_id =
            $grammar->thin_symbol($rejected_terminal_name);
        if ($trace_terminals) {
            say {$trace_fh} 'Literal Token not accepted: ',
                $rejected_terminal_name
                or Carp::croak("Cannot print: $ERRNO");
        }

        my $highest_candidate_rank = 0;
        my $virtual_terminal_to_add;
        my $ruby_vector        = $ruby_rank_by_id[$rejected_terminal_id];
        my @terminals_expected = $recce->terminals_expected();
        die $thin_grammar->error() if not defined $terminals_expected[0];
        CANDIDATE: for my $candidate_id (@terminals_expected) {
            my $this_candidate_rank = $ruby_vector->[$candidate_id];
            if ($trace_terminals) {
                say {$trace_fh} 'Considering candidate: ',
                    $grammar->symbol_name($candidate_id),
                    "; rank is $this_candidate_rank; highest rank so far is $highest_candidate_rank"
                    or Carp::croak("Cannot print: $ERRNO");
            } ## end if ($trace_terminals)
            if ( $this_candidate_rank > $highest_candidate_rank ) {
                if ($trace_terminals) {
                    say {$trace_fh} 'Considering candidate: ',
                        $grammar->symbol_name($candidate_id),
                        '; last seen at ', $terminal_last_seen[$candidate_id],
                        "; current token number is $token_number"
                        or Carp::croak("Cannot print: $ERRNO");
                } ## end if ($trace_terminals)
                next CANDIDATE
                    if $terminal_last_seen[$candidate_id] == $token_number;
                if ($trace_terminals) {
                    say {$trace_fh} 'Current best candidate: ',
                        $grammar->symbol_name($candidate_id),
                        or Carp::croak("Cannot print: $ERRNO");
                }
                $highest_candidate_rank  = $this_candidate_rank;
                $virtual_terminal_to_add = $candidate_id;
            } ## end if ( $this_candidate_rank > $highest_candidate_rank )
        } ## end CANDIDATE: for my $candidate_id (@terminals_expected)

        if ( defined $virtual_terminal_to_add ) {

            if ($trace_terminals) {
                say {$trace_fh} 'Adding Ruby Slippers token: ',
                    $grammar->symbol_name($virtual_terminal_to_add),
                    or Carp::croak("Cannot print: $ERRNO");
            }

            my $ruby_slippers_result =
                $recce->alternative( $virtual_terminal_to_add,
                RUBY_SLIPPERS_TOKEN, 1 );
            if ( $ruby_slippers_result != $NO_MARPA_ERROR ) {
                die $thin_grammar->error();
            }
            if ( $recce->earleme_complete() < 0 ) {
                die $thin_grammar->error();
            }

            # Only keep track of start tags.  We need to be able to add end
            # tags repeatedly.
            # Adding end tags cannot cause an infinite loop, because each
            # one ends an element and only a finite number of elements
            # can have been started.
            $terminal_last_seen[$virtual_terminal_to_add] = $token_number
                if $is_start_tag[$virtual_terminal_to_add];

            my $current_earleme = $recce->current_earleme();
            die $thin_grammar->error() if not defined $current_earleme;
            $self->{earleme_to_html_token_ix}->[$current_earleme] =
                $latest_html_token;
            next RECCE_RESPONSE;
        } ## end if ( defined $virtual_terminal_to_add )

        # If we didn't find a token to add, add the
        # current physical token as CRUFT.

        if ($trace_terminals) {
            say {$trace_fh} 'Adding rejected token as cruft: ',
                $rejected_terminal_name
                or Carp::croak("Cannot print: $ERRNO");
        }

        # Cruft tokens are not virtual.
        # They are the real things, hacked up.
        $token->[0] = 'CRUFT';
        if ($trace_cruft) {
            my $current_earleme = $recce->current_earleme();
            die $thin_grammar->error() if not defined $current_earleme;
            my ( $line, $col ) =
                earleme_to_linecol( $self, $current_earleme );

            # HTML::Parser uses one-based line numbers,
            # but zero-based column numbers
            # The convention (in vi and cut) is that
            # columns are also one-based.
            $col++;

            say {$trace_fh} qq{Cruft at line $line, column $col: "},
                ${
                token_range_to_original(
                    $self, $token_number, $token_number
                )
                },
                q{"}
                or Carp::croak("Cannot print: $ERRNO");
        } ## end if ($trace_cruft)

    } ## end RECCE_RESPONSE: while ( $token_number < $token_count )
    $thin_grammar->throw_set(1);

    if ($trace_terminals) {
        say {$trace_fh} 'at end of tokens'
            or Carp::croak("Cannot print: $ERRNO");
    }

    $Marpa::R2::HTML::INSTANCE = $self;
    local $Marpa::R2::HTML::Internal::PARSE_INSTANCE = $self;
    my $latest_earley_set_ID = $recce->latest_earley_set();
    my $bocage = Marpa::R2::Thin::B->new( $recce, $latest_earley_set_ID );
    my $order  = Marpa::R2::Thin::O->new($bocage);
    my $tree   = Marpa::R2::Thin::T->new($order);
    $tree->next();

    my @stack = ();
    local $Marpa::R2::HTML::Internal::STACK = \@stack;
    my %memoized_handlers = ();

    my $valuator = Marpa::R2::Thin::V->new($tree);
    local $Marpa::R2::HTML::Internal::RECCE    = $recce;
    local $Marpa::R2::HTML::Internal::VALUATOR = $valuator;

    for my $rule_id ( $grammar->rule_ids() ) {
        $valuator->rule_is_valued_set( $rule_id, 1 );
    }
    STEP: while (1) {
        my ( $type, @step_data ) = $valuator->step();
        last STEP if not defined $type;
        if ( $type eq 'MARPA_STEP_TOKEN' ) {
            say {*STDERR} join q{ }, $type, @step_data,
                $grammar->symbol_name( $step_data[0] )
                or Carp::croak("Cannot print: $ERRNO")
                if $trace_values;
            my ( undef, $token_value, $arg_n ) = @step_data;
            if ( $token_value eq RUBY_SLIPPERS_TOKEN ) {
                $stack[$arg_n] = ['RUBY_SLIPPERS_TOKEN'];
                say {*STDERR} "Stack:\n", Data::Dumper::Dumper( \@stack )
                    or Carp::croak("Cannot print: $ERRNO")
                    if $trace_values;
                next STEP;
            } ## end if ( $token_value eq RUBY_SLIPPERS_TOKEN )
            my ( $start_earley_set_id, $end_earley_set_id ) =
                $valuator->location();
            my $start_earleme = $recce->earleme($start_earley_set_id);
            my $start_html_token_ix =
                $self->{earleme_to_html_token_ix}->[$start_earleme];
            my $end_earleme = $recce->earleme($end_earley_set_id);
            my $end_html_token_ix =
                $self->{earleme_to_html_token_ix}->[$end_earleme];
            $stack[$arg_n] = [
                'PHYSICAL_TOKEN' => $start_html_token_ix + 1,
                $end_html_token_ix,
            ];
            say {*STDERR} "Stack:\n", Data::Dumper::Dumper( \@stack )
                or Carp::croak("Cannot print: $ERRNO")
                if $trace_values;
            next STEP;
        } ## end if ( $type eq 'MARPA_STEP_TOKEN' )
        if ( $type eq 'MARPA_STEP_RULE' ) {
            say {*STDERR} join q{ }, ( $type, @step_data )
                or Carp::croak("Cannot print: $ERRNO")
                if $trace_values;
            my ( $rule_id, $arg_0, $arg_n ) = @step_data;

            my $attributes = undef;
            my $class      = undef;
            my $action     = $grammar->action($rule_id);
            local $Marpa::R2::HTML::Internal::START_TAG_IX   = undef;
            local $Marpa::R2::HTML::Internal::END_TAG_IX_REF = undef;
            local $Marpa::R2::HTML::Internal::ELEMENT        = undef;
            local $Marpa::R2::HTML::Internal::SPECIES        = q{};

            if ( defined $action and ( index $action, 'ELE_' ) == 0 ) {
                $Marpa::R2::HTML::Internal::SPECIES =
                    $Marpa::R2::HTML::Internal::ELEMENT = substr $action, 4;
                my $start_tag_marpa_token = $stack[$arg_0];

                my $start_tag_type = $start_tag_marpa_token
                    ->[Marpa::R2::HTML::Internal::TDesc::TYPE];
                if ( defined $start_tag_type
                    and $start_tag_type eq 'PHYSICAL_TOKEN' )
                {
                    my $start_tag_ix    = $start_tag_marpa_token->[1];
                    my $start_tag_token = $html_parser_tokens[$start_tag_ix];
                    if ( $start_tag_token
                        ->[Marpa::R2::HTML::Internal::Token::TYPE] eq 'S' )
                    {
                        $Marpa::R2::HTML::Internal::START_TAG_IX =
                            $start_tag_ix;
                        $attributes = $start_tag_token
                            ->[Marpa::R2::HTML::Internal::Token::ATTR];
                    } ## end if ( $start_tag_token->[...])
                } ## end if ( defined $start_tag_type and $start_tag_type eq ...)
            } ## end if ( defined $action and ( index $action, 'ELE_' ) ==...)
            if ( defined $action and ( index $action, 'SPE_' ) == 0 ) {
                $Marpa::R2::HTML::Internal::SPECIES = q{:} . substr $action,
                    4;
            }
            local $Marpa::R2::HTML::Internal::ATTRIBUTES = $attributes;
            $class = $attributes->{class} // q{*};
            local $Marpa::R2::HTML::Internal::CLASS = $class;
            local $Marpa::R2::HTML::Internal::ARG_0 = $arg_0;
            local $Marpa::R2::HTML::Internal::ARG_N = $arg_n;

            my ( $start_earley_set_id, $end_earley_set_id ) =
                $valuator->location();

            my $start_earleme = $recce->earleme($start_earley_set_id);
            my $start_html_token_ix =
                $self->{earleme_to_html_token_ix}->[$start_earleme] + 1;
            my $end_earleme = $recce->earleme($end_earley_set_id);
            my $end_html_token_ix =
                $self->{earleme_to_html_token_ix}->[$end_earleme];

            if ( $start_html_token_ix > $end_html_token_ix ) {
                $start_html_token_ix = $end_html_token_ix = undef;
            }
            local $Marpa::R2::HTML::Internal::START_HTML_TOKEN_IX =
                $start_html_token_ix;
            local $Marpa::R2::HTML::Internal::END_HTML_TOKEN_IX =
                $end_html_token_ix;

            my $handler_key =
                $rule_id . q{;} . $Marpa::R2::HTML::Internal::CLASS;

            my $handler = $memoized_handlers{$handler_key};

            $trace_handlers
                and $handler
                and say {*STDERR}
                qq{Found memoized handler for rule $rule_id, class "},
                ( $class // q{*} ), q{"};

            if ( not defined $handler ) {
                $handler = $memoized_handlers{$handler_key} =
                    handler_find( $self, $rule_id, $class );
            }

            COMPUTE_VALUE: {
                if ( ref $handler ) {
                    $stack[$arg_0] = [
                        VALUED_SPAN => $start_html_token_ix,
                        $end_html_token_ix,
                        ( scalar $handler->() ),
                        $rule_id
                    ];
                    last COMPUTE_VALUE;
                } ## end if ( ref $handler )
                my @flat_tdesc_list = ();
                STACK_IX:
                for my $stack_ix ( $Marpa::R2::HTML::Internal::ARG_0 ..
                    $Marpa::R2::HTML::Internal::ARG_N )
                {
                    my $tdesc_item =
                        $Marpa::R2::HTML::Internal::STACK->[$stack_ix];
                    my $tdesc_type = $tdesc_item->[0];
                    next STACK_IX if not defined $tdesc_type;
                    if ( $tdesc_type eq 'VALUES' ) {
                        push @flat_tdesc_list,
                            @{ $tdesc_item
                                ->[Marpa::R2::HTML::Internal::TDesc::VALUE] };
                        next STACK_IX;
                    } ## end if ( $tdesc_type eq 'VALUES' )
                    next STACK_IX if $tdesc_type ne 'VALUED_SPAN';
                    push @flat_tdesc_list, $tdesc_item;
                } ## end STACK_IX: for my $stack_ix ( $Marpa::R2::HTML::Internal::ARG_0...)
                if ( scalar @flat_tdesc_list <= 1 ) {
                    $stack[$arg_0] = [
                        VALUED_SPAN => $start_html_token_ix,
                        $end_html_token_ix,
                        $flat_tdesc_list[0]
                            ->[Marpa::R2::HTML::Internal::TDesc::VALUE],
                        $rule_id
                    ];
                    last COMPUTE_VALUE;
                } ## end if ( scalar @flat_tdesc_list <= 1 )
                $stack[$arg_0] = [
                    VALUES => $start_html_token_ix,
                    $end_html_token_ix,
                    \@flat_tdesc_list,
                    $rule_id
                ];
            } ## end COMPUTE_VALUE:

            if ($trace_values) {
                say {*STDERR} "rule $rule_id: ", join q{ },
                    $grammar->rule($rule_id)
                    or Carp::croak("Cannot print: $ERRNO");
                say {*STDERR} "Stack:\n", Data::Dumper::Dumper( \@stack )
                    or Carp::croak("Cannot print: $ERRNO");
            } ## end if ($trace_values)
            next STEP;
        } ## end if ( $type eq 'MARPA_STEP_RULE' )

        if ( $type eq 'MARPA_STEP_NULLING_SYMBOL' ) {
            my ( $symbol_id, $arg_n ) = @step_data;
            my $symbol_name = $grammar->symbol_name($symbol_id);
            $stack[$arg_n] = ['ZERO_SPAN'];

            if ($trace_values) {
                say {*STDERR} join q{ }, $type, @step_data,
                    $grammar->symbol_name($symbol_id)
                    or Carp::croak("Cannot print: $ERRNO");
                say {*STDERR} "Stack:\n", Data::Dumper::Dumper( \@stack )
                    or Carp::croak("Cannot print: $ERRNO");
            } ## end if ($trace_values)
            next STEP;
        } ## end if ( $type eq 'MARPA_STEP_NULLING_SYMBOL' )
        die "Unexpected step type: $type";
    } ## end STEP: while (1)

    my $result = $stack[0];
    Marpa::R2::exception('No parse: evaler returned undef')
        if not defined $result;

    if ( ref $self->{handler_by_species}->{TOP} ) {
        ## This is a user-defined handler.  We assume it returns
        ## a VALUED_SPAN.
        $result = $result->[Marpa::R2::HTML::Internal::TDesc::VALUE];
    }
    else {
        ## The TOP handler was the default handler.
        ## We now want to "literalize" its result.
        FIND_LITERALIZEABLE: {
            my $type = $result->[Marpa::R2::HTML::Internal::TDesc::TYPE];
            if ( $type eq 'VALUES' ) {
                $result = $result->[Marpa::R2::HTML::Internal::TDesc::VALUE];
                last FIND_LITERALIZEABLE;
            }
            if ( $type eq 'VALUED_SPAN' ) {
                $result = [$result];
                last FIND_LITERALIZEABLE;
            }
            die 'Internal: TOP result is not literalize-able';
        } ## end FIND_LITERALIZEABLE:
        $result = range_and_values_to_literal( $self, 0, $#html_parser_tokens,
            $result );
    } ## end else [ if ( ref $self->{handler_by_species}->{TOP} ) ]

    return $result;

} ## end sub parse

sub Marpa::R2::HTML::html {
    my ( $document_ref, @args ) = @_;
    my $html = Marpa::R2::HTML::Internal::create(@args);
    return Marpa::R2::HTML::Internal::parse( $html, $document_ref );
}

1;
