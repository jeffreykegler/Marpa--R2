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
$VERSION        = '2.021_001';
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

use constant PHYSICAL_TOKEN => 42;
use constant RUBY_SLIPPERS_TOKEN => 43;

our @LIBMARPA_ERROR_NAMES = Marpa::R2::Thin::error_names();
our $UNEXPECTED_TOKEN_ID =
    ( grep { $LIBMARPA_ERROR_NAMES[$_] eq 'MARPA_ERR_UNEXPECTED_TOKEN_ID' }
        ( 0 .. $#LIBMARPA_ERROR_NAMES ) )[0];

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
    $self->{handler_by_element_and_class}->{join q{;}, $element, $class} = $action;
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
	( $element, $class ) =
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

@Marpa::R2::HTML::Internal::CORE_TERMINALS =
    qw(C D PI CRUFT CDATA PCDATA WHITESPACE EOF );

push @Marpa::R2::HTML::Internal::CORE_TERMINALS,
    keys %Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS;

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
            say STDERR qq{Rule $rule_id: Found handler by species: "$species"}
                if $trace_handlers and defined $handler;
            last FIND_HANDLER;
        } ## end if ( index( $action, 'SPE_' ) == 0 )

        ## At this point action always is defined
	## and starts with 'ELE_'
	my $element = substr $action, 4;

        my @handler_keys = (
            ( join q{;}, $element, $class ),
            ( join q{;}, q{*},    $class ),
            ( join q{;}, $element, q{*} ),
            ( join q{;}, q{*},    q{*} ),
        );
        ($handler) =
            grep {defined}
            @{ $self->{handler_by_element_and_class} }{@handler_keys};

        say STDERR qq{Rule $rule_id: Found handler by action and class: "},
            ( grep { defined $self->{handler_by_element_and_class}->{$_} }
                @handler_keys )[0], qq{"}
            if $trace_handlers and defined $handler;

    } ## end FIND_HANDLER:
    return $handler if defined $handler;

    say STDERR qq{Rule $rule_id: Using default handler for action "},
        ( $action // q{*} ), qq{" and class: "$class"}
        if $trace_handlers;

    return "default_handler";
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
    return '' if not defined $tdesc_item_type;

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
    return '';
} ## end sub tdesc_item_to_original

# Given a token range and a tdesc list,
# return a reference to the literal value.
sub range_and_values_to_literal {
    my ( $self, $next_token_ix, $final_token_ix, $tdesc_list) = @_;

    my @flat_tdesc_list = ();
    TDESC_ITEM: for my $tdesc_item ( @{$tdesc_list})
    {
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
    } ## end STACK_IX: for my $stack_ix ( $Marpa::R2::HTML::Internal::ARG_0 ...)

    my @literal_pieces = ();
    TDESC_ITEM: for my $tdesc_item (@flat_tdesc_list) {

        my ( $tdesc_item_type, $next_explicit_token_ix,
            $furthest_explicit_token_ix )
            = @{$tdesc_item};

	if (not defined $next_explicit_token_ix) {
	    ## An element can contain no HTML tokens -- it may contain
	    ## only Ruby Slippers tokens.
	    ## Treat this as a special case.
	  if ( $tdesc_item_type eq 'VALUED_SPAN') {
	    my $value = $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::VALUE] // q{};
            push @literal_pieces, \(q{} . $value);
	  }
	  next TDESC_ITEM;
	}

        push @literal_pieces,
            token_range_to_original( $self, $next_token_ix, $next_explicit_token_ix - 1)
            if $next_token_ix < $next_explicit_token_ix;
        if ( $tdesc_item_type eq 'VALUED_SPAN' ) {
            my $value = $tdesc_item->[Marpa::R2::HTML::Internal::TDesc::VALUE];
            if ( defined $value ) {
                push @literal_pieces, \( q{} . $value );
                $next_token_ix = $furthest_explicit_token_ix + 1;
                next TDESC_ITEM;
            }
            ## FALL THROUGH
        } ## end if ( $tdesc_item_type eq 'VALUED_SPAN' and defined )
        push @literal_pieces,
            token_range_to_original( $self, $next_explicit_token_ix, $furthest_explicit_token_ix )
            if $next_explicit_token_ix <= $furthest_explicit_token_ix;
        $next_token_ix = $furthest_explicit_token_ix + 1;
    } ## end TDESC_ITEM: for my $tdesc_item (@flat_tdesc_list)

    return \(join q{}, map { ${$_} } @literal_pieces);

}

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
    my $trace_handlers = $self->{trace_handlers};
    my $trace_values = $self->{trace_values};
    my $trace_fh        = $self->{trace_fh};
    my $ref_type        = ref $document_ref;
    Marpa::R2::exception('Arg to parse() must be ref to string')
        if not $ref_type
            or $ref_type ne 'SCALAR'
            or not defined ${$document_ref};

    my $document = $self->{document} = $document_ref;

    my @raw_tokens = ();
my $p = HTML::Parser->new(
    api_version => 3,
    start_h       => [\@raw_tokens, q{tagname,'S',line,column,offset,offset_end,attr}],
    end_h         => [\@raw_tokens, q{tagname,'E',line,column,offset,offset_end}],
    text_h        => [\@raw_tokens, q{'WHITESPACE','T',line,column,offset,offset_end,is_cdata}],
    comment_h     => [\@raw_tokens, q{'C','C',line,column,offset,offset_end}],
    declaration_h => [\@raw_tokens, q{'D','D',line,column,offset,offset_end}],
    process_h     => [\@raw_tokens, q{'PI','PI',line,column,offset,offset_end}],
    unbroken_text => 1
);

$p->parse(${$document});
$p->eof;

    my %terminals =
        map { $_ => 1 } @Marpa::R2::HTML::Internal::CORE_TERMINALS;
    my %optional_terminals =
        %Marpa::R2::HTML::Internal::CORE_OPTIONAL_TERMINALS;
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
    } ## end for my $raw_token (@raw_tokens)

    # Points AFTER the last HTML
    # Parser token.
    # The other logic needs to be ready for this.
    {
        my $document_length = length ${$document};
        my $last_token      = $html_parser_tokens[$#html_parser_tokens];
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

    my %pseudoclass_element_actions = ();
    my %element_actions             = ();

    # Special cases which are dealt with elsewhere.
    # As of now the only special cases are elements with optional
    # start and end tags
    for my $special_element (qw(html head body table tbody tr td)) {
        delete $tags{$special_element};
        $element_actions{"ELE_$special_element"} = $special_element;
    }

    ELEMENT: for ( keys %tags ) {
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
            action => "ELE_$_",
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

        $element_actions{"ELE_$_"} = $_;
    } ## end ELEMENT: for ( keys %tags )

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

        } ## end for my $terminal ( grep { not defined $level{$_} } (...))

        EXPECTED_TERMINAL:
        for my $expected_terminal ( keys %optional_terminals ) {

            # Regardless of levels, allow no cruft before a start tag.
            # Start whatever it is, then deal with the cruft.
            next EXPECTED_TERMINAL if $expected_terminal =~ /^S_/xms;

            # For end tags, use the levels
            TERMINAL: for my $actual_terminal (@terminals) {
                $ok_as_cruft{$expected_terminal}{$actual_terminal} = 1
                    if $level{$actual_terminal} < $level{$expected_terminal};
            }
        } ## end EXPECTED_TERMINAL: for my $expected_terminal ( keys %optional_terminals)

    } ## end DECIDE_CRUFT_TREATMENT:

    die Dumper(\%ok_as_cruft);

  } ## end sub parse

my ( $document_ref, @args ) = @_;
my $html = Marpa::R2::HTML::Internal::create(@args);
Marpa::R2::HTML::Internal::parse( $html, \'<p><a><b>' );

