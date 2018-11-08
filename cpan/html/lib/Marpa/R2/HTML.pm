# Copyright 2018 Jeffrey Kegler
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

use 5.010001;
use strict;
use warnings;

use vars qw( $VERSION $STRING_VERSION );
$VERSION        = '5.044_000';
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

use Marpa::R2::HTML::Internal;
use Marpa::R2::HTML::Config;
use Carp ();
use HTML::Parser 3.69;
use HTML::Entities qw(decode_entities);

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

use Marpa::R2::Thin::Trace;

# constants

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
        ( $element, $class ) = ( $specifier =~ /\A ([^.]*) [.] (.*) \z/oxms )
            or ( $element, $pseudoclass ) =
            ( $specifier =~ /\A ([^:]*) [:] (.*) \z/oxms )
            or $element = $specifier;
        state $allowed_pseudoclasses =
            { map { ( $_, 1 ) }
                qw(TOP PI DECL COMMENT PROLOG TRAILER WHITESPACE CDATA PCDATA CRUFT)
            };
        if ( $pseudoclass
            and not exists $allowed_pseudoclasses->{$pseudoclass} )
        {
            Marpa::R2::exception(
                qq{pseudoclass "$pseudoclass" is not known:\n},
                "Specifier was $specifier\n" );
        } ## end if ( $pseudoclass and not exists $allowed_pseudoclasses...)
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
            state $allowed_options = {
                map { ( $_, 1 ) }
                    qw(trace_fh trace_values trace_handlers
                    trace_conflicts
                    trace_terminals trace_cruft
                    dump_AHFA dump_config compile
                    )
            };
            if ( not exists $allowed_options->{$option} ) {
                Marpa::R2::exception("unknown option: $option");
            }
            $self->{$option} = $option_hash->{$option};
        } ## end OPTION: for my $option ( keys %{$option_hash} )
    } ## end ARG: for my $arg (@_)

    my $source_ref = $self->{compile};
    if ( defined $source_ref ) {
        ref $source_ref eq 'SCALAR'
            or Marpa::R2::exception(
            qq{value of "compile" option must be a SCALAR});
        $self->{config} = Marpa::R2::HTML::Config->new_from_compile($source_ref);
    } ## end if ( defined $source_ref )
    else {
        $self->{config} = Marpa::R2::HTML::Config->new();
    }

    return $self;
} ## end sub create

sub handler_find {
    my ( $self, $rule_id, $class ) = @_;
    my $trace_handlers = $self->{trace_handlers};
    my $handler;
    $class //= q{*};
    my $action = $self->{action_by_rule_id}->[$rule_id];
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

sub symbol_names_by_rule_id {
    my ( $self, $rule_id ) = @_;
    my $tracer = $self->{tracer};
    my $grammar           = $tracer->grammar();
    my $rule_length       = $grammar->rule_length($rule_id);
    return if not defined $rule_length;
    my @symbol_ids = ( $grammar->rule_lhs($rule_id) );
    push @symbol_ids,
        map { $grammar->rule_rhs( $rule_id, $_ ) } ( 0 .. $rule_length - 1 );
    return map { $tracer->symbol_name($_) } @symbol_ids;
} ## end sub symbol_names_by_rule_id

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

    my ($core_rules,   $runtime_tag,
        $rank_by_name, $is_empty_element,
        $primary_group_by_tag
    ) = $self->{config}->contents();
    $self->{is_empty_element} = $is_empty_element;
    if ($self->{dump_config}) {
         return $self->{config}->as_string();
    }
    my @action_by_rule_id = ();
    $self->{action_by_rule_id} = \@action_by_rule_id;
    my $thin_grammar = Marpa::R2::Thin::G->new( { if => 1 } );
    my $tracer = Marpa::R2::Thin::Trace->new($thin_grammar);
    $self->{tracer}                  = $tracer;

    RULE: for my $rule ( @{$core_rules} ) {
        my $lhs    = $rule->{lhs};
        my $rhs    = $rule->{rhs};
        my $min    = $rule->{min};
        my $action = $rule->{action};
        my @symbol_ids = ();
        for my $symbol_name ( $lhs, @{$rhs} ) {
            push @symbol_ids,
                $tracer->symbol_by_name($symbol_name)
                // $tracer->symbol_new($symbol_name);
        }
        my ($lhs_id, @rhs_ids) = @symbol_ids;
        my $rule_id;
        if ( defined $min ) {
            $rule_id =
                $thin_grammar->sequence_new( $lhs_id, $rhs_ids[0],
                { min => $min } );
        }
        else {
            $rule_id = $thin_grammar->rule_new( $lhs_id, \@rhs_ids );
        }
        $action_by_rule_id[$rule_id] = $action;
    } ## end RULE: for my $rule ( @{$core_rules} )

    # Some constants that we will use a lot
    my $SYMID_CRUFT = $tracer->symbol_by_name('CRUFT');
    my $SYMID_CDATA = $tracer->symbol_by_name('CDATA');
    my $SYMID_PCDATA = $tracer->symbol_by_name('PCDATA');
    my $SYMID_WHITESPACE = $tracer->symbol_by_name('WHITESPACE');
    my $SYMID_PI = $tracer->symbol_by_name('PI');
    my $SYMID_C = $tracer->symbol_by_name('C');
    my $SYMID_D = $tracer->symbol_by_name('D');
    my $SYMID_EOF = $tracer->symbol_by_name('EOF');

    my @raw_tokens = ();
    my $p          = HTML::Parser->new(
        api_version => 3,
        start_h     => [
            \@raw_tokens, q{tagname,'S',line,column,offset,offset_end,is_cdata,attr}
        ],
        end_h =>
            [ \@raw_tokens, q{tagname,'E',line,column,offset,offset_end,is_cdata} ],
        text_h => [
            \@raw_tokens,
            qq{'$SYMID_WHITESPACE','T',line,column,offset,offset_end,is_cdata}
        ],
        comment_h =>
            [ \@raw_tokens, qq{'$SYMID_C','C',line,column,offset,offset_end,is_cdata} ],
        declaration_h =>
            [ \@raw_tokens, qq{'$SYMID_D','D',line,column,offset,offset_end,is_cdata} ],
        process_h =>
            [ \@raw_tokens, qq{'$SYMID_PI','PI',line,column,offset,offset_end,is_cdata} ],
        unbroken_text => 1
    );

    $p->parse( ${$document} );
    $p->eof;

    my @html_parser_tokens = ();
    HTML_PARSER_TOKEN:
    for my $raw_token (@raw_tokens) {
        my ( undef, $token_type, $line, $column, $offset, $offset_end, $is_cdata, $attr ) =
            @{$raw_token};

        PROCESS_TOKEN_TYPE: {
            if ($is_cdata) {
                $raw_token->[Marpa::R2::HTML::Internal::Token::TOKEN_ID] =
                    $SYMID_CDATA;
                last PROCESS_TOKEN_TYPE;
            }
            if ( $token_type eq 'T' ) {

                # White space as defined in HTML 4.01
                # space (x20); ASCII tab (x09); ASCII form feed (x0C;); Zero-width space (x200B)
                # and the two characters which appear in line breaks:
                # carriage return (x0D) and line feed (x0A)
                # I avoid the Perl character codes because I do NOT want
                # localization
                $raw_token->[Marpa::R2::HTML::Internal::Token::TOKEN_ID] =
                 $SYMID_PCDATA if
                    substr(
                        ${$document}, $offset, ( $offset_end - $offset )
                    ) =~ / [^\x09\x0A\x0C\x0D\x20\x{200B}] /oxms;

                last PROCESS_TOKEN_TYPE;
            } ## end if ( $token_type eq 'T' )
            if ( $token_type eq 'E' or $token_type eq 'S' ) {

                # If it's a virtual token from HTML::Parser,
                # pretend it never existed.
                # HTML::Parser supplies missing
                # end tags for title elements, but for no
                # others.
                # This is not helpful and we need to special-case
                # these zero-length tags and throw them away.
                next HTML_PARSER_TOKEN if $offset_end <= $offset;

                my $tag_name = $raw_token
                    ->[Marpa::R2::HTML::Internal::Token::TAG_NAME];
                my $terminal    = $token_type . q{_} . $tag_name;
                my $terminal_id = $tracer->symbol_by_name($terminal);
                if ( not defined $terminal_id ) {
                    my $group_symbol = $primary_group_by_tag->{$tag_name}
                        // 'GRP_anywhere';
                    my $contents = $runtime_tag->{$tag_name} // 'FLO_mixed';
                    my @symbol_names = (
                        $group_symbol,
                        'ELE_' . $tag_name,
                        'S_' . $tag_name,
                        $contents, 'E_' . $tag_name
                    );
                    my @symbol_ids = ();
                    SYMBOL: for my $symbol_name (@symbol_names) {
                        my $symbol_id = $tracer->symbol_by_name($symbol_name);
                        if ( not defined $symbol_id ) {
                            $symbol_id = $tracer->symbol_new($symbol_name);
                        }
                        push @symbol_ids, $symbol_id;
                    } ## end SYMBOL: for my $symbol_name (@symbol_names)
                    my ( $top_id, $lhs_id, @rhs_ids ) = @symbol_ids;
                    $thin_grammar->rule_new( $top_id, [$lhs_id] );
                    my $element_rule_id =
                        $thin_grammar->rule_new( $lhs_id, \@rhs_ids );
                    $action_by_rule_id[$element_rule_id] = 'ELE_' . $tag_name;
                    $terminal_id = $tracer->symbol_by_name($terminal);

                } ## end if ( not defined $terminal_id )
                $raw_token->[Marpa::R2::HTML::Internal::Token::TOKEN_ID] =
                    $terminal_id;
                last PROCESS_TOKEN_TYPE;
            } ## end if ( $token_type eq 'E' or $token_type eq 'S' )
        } ## end PROCESS_TOKEN_TYPE:
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
            $SYMID_EOF, 'EOF',
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

    $thin_grammar->start_symbol_set( $tracer->symbol_by_name('document') );
    $thin_grammar->precompute();

    if ($self->{dump_AHFA}) {
         return \$tracer->show_AHFA();
    }

    # Memoize these -- we use highest symbol a lot
    my $highest_symbol_id = $thin_grammar->highest_symbol_id();
    my $highest_rule_id = $thin_grammar->highest_rule_id();

    # For the Ruby Slippers engine
    # We need to know quickly if a symbol is a start tag;
    my @is_start_tag = ();

    # Find Ruby slippers ranks, by symbol ID
    my @ruby_rank_by_id = ();
    {
        my @non_final_end_tag_ids = ();
        SYMBOL:
        for my $symbol_id ( 0 .. $highest_symbol_id ) {
            my $symbol_name = $tracer->symbol_name($symbol_id);
            next SYMBOL if not 0 == index $symbol_name, 'E_';
            next SYMBOL
                if $symbol_name eq 'E_body'
                    or $symbol_name eq 'E_html';
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
                if ( $candidate_name eq '</*>' ) {
                    $ruby_vector_by_id[$_] = $rank for @non_final_end_tag_ids;
                    next CANDIDATE;
                }
                my $candidate_id = $tracer->symbol_by_name($candidate_name);
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
                $tracer->symbol_name($rejected_symbol_id);
            my $placement;
            FIND_PLACEMENT: {
                my $prefix = substr $rejected_symbol_name, 0, 2;
                if ( $prefix eq 'S_' ) {
                    $placement = '';
                    $is_start_tag[$rejected_symbol_id] = 1;
                    last FIND_PLACEMENT;
                }
                if ( $prefix eq 'E_' ) {
                    $placement = '/';
                }
            } ## end FIND_PLACEMENT:
            my $ruby_vector = $ruby_vectors{$rejected_symbol_name};
            if ( defined $ruby_vector ) {
                $ruby_rank_by_id[$rejected_symbol_id] = $ruby_vector;
                next SYMBOL;
            }
            if ( not defined $placement ) {
                if ( $rejected_symbol_name eq 'CRUFT' ) {
                    $ruby_rank_by_id[$rejected_symbol_id] =
                        \@no_ruby_slippers_vector;
                    next SYMBOL;
                }
                $ruby_rank_by_id[$rejected_symbol_id] =
                    $ruby_vectors{'!non_element'}
                    // \@no_ruby_slippers_vector;
                next SYMBOL;
            } ## end if ( not defined $placement )
            my $tag = substr $rejected_symbol_name, 2;
            my $primary_group = $primary_group_by_tag->{$tag};
            my $element_type = defined $primary_group ? (substr $primary_group, 4) : 'anywhere';
            $ruby_vector =
                $ruby_vectors{ q{<} . $placement . q{%} . $element_type . q{>} };
            if ( defined $ruby_vector ) {
                $ruby_rank_by_id[$rejected_symbol_id] = $ruby_vector;
                next SYMBOL;
            }
            $ruby_vector = $ruby_vectors{ q{<} . $placement . q{*>} };
            if ( defined $ruby_vector ) {
                $ruby_rank_by_id[$rejected_symbol_id] = $ruby_vector;
                next SYMBOL;
            }
            $ruby_rank_by_id[$rejected_symbol_id] = \@no_ruby_slippers_vector;
        } ## end SYMBOL: for my $rejected_symbol_id ( 0 .. $highest_symbol_id )

    }

    my @empty_element_end_tag = ();
    {
        TAG: for my $tag (keys %{$is_empty_element}) {
            my $start_tag_id = $tracer->symbol_by_name('S_' . $tag);
            next TAG if not defined $start_tag_id;
            my $end_tag_id = $tracer->symbol_by_name('E_' . $tag);
            $empty_element_end_tag[$start_tag_id] = $end_tag_id;
        }
    }

    my $recce = Marpa::R2::Thin::R->new($thin_grammar);
    $recce->start_input();

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
    my $empty_element_end_tag;
    RECCE_RESPONSE: while ( $token_number < $token_count ) {

        if ( defined $empty_element_end_tag ) {
            my $read_result =
                $recce->alternative( $empty_element_end_tag, RUBY_SLIPPERS_TOKEN,
                1 );
            if ( $read_result != $NO_MARPA_ERROR ) {
                die $thin_grammar->error();
            }
            if ($trace_terminals) {
                say {$trace_fh} 'Virtual end tag accepted: ',
                    $tracer->symbol_name($empty_element_end_tag)
                    or Carp::croak("Cannot print: $ERRNO");
            }
            if ( $recce->earleme_complete() < 0 ) {
                die $thin_grammar->error();
            }
            my $current_earleme = $recce->current_earleme();
            die $thin_grammar->error() if not defined $current_earleme;
            $self->{earleme_to_html_token_ix}->[$current_earleme] =
                $latest_html_token;
            $empty_element_end_tag = undef;
            next RECCE_RESPONSE;
        } ## end if ( defined $empty_element_end_tag )

        my $token = $html_parser_tokens[$token_number];

        my $attempted_symbol_id = $token
                ->[Marpa::R2::HTML::Internal::Token::TOKEN_ID];
        my $read_result =
            $recce->alternative( $attempted_symbol_id, PHYSICAL_TOKEN, 1 );
        if ( $read_result != $UNEXPECTED_TOKEN_ID ) {
            if ( $read_result != $NO_MARPA_ERROR ) {
                die $thin_grammar->error();
            }
            if ($trace_terminals) {
                say {$trace_fh} 'Token accepted: ',
                    $tracer->symbol_name($attempted_symbol_id)
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

            $empty_element_end_tag = $empty_element_end_tag[$attempted_symbol_id];
            next RECCE_RESPONSE;
        } ## end if ( $read_result != $UNEXPECTED_TOKEN_ID )

        if ($trace_terminals) {
            say {$trace_fh} 'Literal Token not accepted: ',
                $tracer->symbol_name($attempted_symbol_id)
                or Carp::croak("Cannot print: $ERRNO");
        }

        my $highest_candidate_rank = 0;
        my $virtual_terminal_to_add;
        my $ruby_vector        = $ruby_rank_by_id[$attempted_symbol_id];
        my @terminals_expected = $recce->terminals_expected();
        die $thin_grammar->error() if not defined $terminals_expected[0];
        CANDIDATE: for my $candidate_id (@terminals_expected) {
            my $this_candidate_rank = $ruby_vector->[$candidate_id];
            if ($trace_terminals) {
                say {$trace_fh} 'Considering candidate: ',
                    $tracer->symbol_name($candidate_id),
                    "; rank is $this_candidate_rank; highest rank so far is $highest_candidate_rank"
                    or Carp::croak("Cannot print: $ERRNO");
            } ## end if ($trace_terminals)
            if ( $this_candidate_rank > $highest_candidate_rank ) {
                if ($trace_terminals) {
                    say {$trace_fh} 'Considering candidate: ',
                        $tracer->symbol_name($candidate_id),
                        '; last seen at ', $terminal_last_seen[$candidate_id],
                        "; current token number is $token_number"
                        or Carp::croak("Cannot print: $ERRNO");
                } ## end if ($trace_terminals)
                next CANDIDATE
                    if $terminal_last_seen[$candidate_id] == $token_number;
                if ($trace_terminals) {
                    say {$trace_fh} 'Current best candidate: ',
                        $tracer->symbol_name($candidate_id),
                        or Carp::croak("Cannot print: $ERRNO");
                }
                $highest_candidate_rank  = $this_candidate_rank;
                $virtual_terminal_to_add = $candidate_id;
            } ## end if ( $this_candidate_rank > $highest_candidate_rank )
        } ## end CANDIDATE: for my $candidate_id (@terminals_expected)

        if ( defined $virtual_terminal_to_add ) {

            if ($trace_terminals) {
                say {$trace_fh} 'Adding Ruby Slippers token: ',
                    $tracer->symbol_name($virtual_terminal_to_add),
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

            $empty_element_end_tag = $empty_element_end_tag[$virtual_terminal_to_add];

            next RECCE_RESPONSE;
        } ## end if ( defined $virtual_terminal_to_add )

        # If we didn't find a token to add, add the
        # current physical token as CRUFT.

        if ($trace_terminals) {
            say {$trace_fh} 'Adding rejected token as cruft: ',
                $tracer->symbol_name($attempted_symbol_id)
                or Carp::croak("Cannot print: $ERRNO");
        }

        my $fatal_cruft_error = $token->[Marpa::R2::HTML::Internal::Token::TOKEN_ID]
            == $SYMID_CRUFT ? 1 : 0;

        if ( $trace_cruft or $fatal_cruft_error ) {
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
            die 'Internal error: cruft token was rejected'
                if $fatal_cruft_error;
        } ## end if ( $trace_cruft or $fatal_cruft_error )

        # Cruft tokens are not virtual.
        # They are the real things, hacked up.
        $token->[Marpa::R2::HTML::Internal::Token::TOKEN_ID] = $SYMID_CRUFT;

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

    for my $rule_id ( grep { $thin_grammar->rule_length($_); }
        0 .. $thin_grammar->highest_rule_id() )
    {
        $valuator->rule_is_valued_set( $rule_id, 1 );
    }
    STEP: while (1) {
        my ( $type, @step_data ) = $valuator->step();
        last STEP if not defined $type;
        if ( $type eq 'MARPA_STEP_TOKEN' ) {
            say {*STDERR} join q{ }, $type, @step_data,
                $tracer->symbol_name( $step_data[0] )
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
            my $action     = $action_by_rule_id[$rule_id];
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
                    symbol_names_by_rule_id( $self, $rule_id )
                    or Carp::croak("Cannot print: $ERRNO");
                say {*STDERR} "Stack:\n", Data::Dumper::Dumper( \@stack )
                    or Carp::croak("Cannot print: $ERRNO");
            } ## end if ($trace_values)
            next STEP;
        } ## end if ( $type eq 'MARPA_STEP_RULE' )

        if ( $type eq 'MARPA_STEP_NULLING_SYMBOL' ) {
            my ( $symbol_id, $arg_n ) = @step_data;
            $stack[$arg_n] = ['ZERO_SPAN'];

            if ($trace_values) {
                say {*STDERR} join q{ }, $type, @step_data,
                    $tracer->symbol_name($symbol_id)
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

# vim: set expandtab shiftwidth=4:
