# Copyright 2013 Jeffrey Kegler
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

package Marpa::R2::Scanless;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.067_002';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

# The grammars and recognizers are numbered starting
# with the lexer, which is grammar 0 -- G0.
# The "higher level", structural, grammar is G1.

package Marpa::R2::Inner::Scanless;

use Scalar::Util 'blessed';

# names of packages for strings
our $G_PACKAGE = 'Marpa::R2::Scanless::G';
our $R_PACKAGE = 'Marpa::R2::Scanless::R';
our $GRAMMAR_LEVEL;
our $TRACE_FILE_HANDLE;

package Marpa::R2::Inner::Scanless::Symbol;

use constant NAME => 0;
use constant HIDE => 1;

sub new {
    my $class = shift;
    return bless { name => $_[NAME], is_hidden => ( $_[HIDE] // 0 ) }, $class;
}
sub is_symbol      { return 1 }
sub name           { return $_[0]->{name} }
sub names          { return $_[0]->{name} }
sub is_hidden      { return $_[0]->{is_hidden} }
sub are_all_hidden { return $_[0]->{is_hidden} }

sub is_lexical { return shift->{is_lexical} // 0 }
sub hidden_set  { return shift->{is_hidden}  = 1; }
sub lexical_set { return shift->{is_lexical} = 1; }
sub mask { return shift->is_hidden() ? 0 : 1 }

sub symbols      { return $_[0]; }
sub symbol_lists { return $_[0]; }

package Marpa::R2::Inner::Scanless::Symbol_List;

sub new { my $class = shift; return bless { symbol_lists => [@_] }, $class }

sub is_symbol { return 0 }

sub names {
    return map { $_->names() } @{ shift->{symbol_lists} };
}

sub are_all_hidden {
    $_->is_hidden() || return 0 for @{ shift->{symbol_lists} };
    return 1;
}

sub is_hidden {
    return map { $_->is_hidden() } @{ shift->{symbol_lists} };
}

sub hidden_set {
    $_->hidden_set() for @{ shift->{symbol_lists} };
    return 0;
}

sub is_lexical { return shift->{is_lexical} // 0 }
sub lexical_set { return shift->{is_lexical} = 1; }

sub mask {
    return
        map { $_ ? 0 : 1 } map { $_->is_hidden() } @{ shift->{symbol_lists} };
}

sub symbols {
    return map { $_->symbols() } @{ shift->{symbol_lists} };
}

# The "unflattened" list, which may contain other lists
sub symbol_lists { return @{ shift->{symbol_lists} }; }

package Marpa::R2::Inner::Scanless;

use English qw( -no_match_vars );

sub Marpa::R2::Scanless::R::last_completed_range {
    my ( $self,  $symbol_name ) = @_;
    my ( $start, $length )      = $self->last_completed($symbol_name);
    return if not defined $start;
    my $end = $start + $length;
    return ( $start, $end );
} ## end sub Marpa::R2::Scanless::R::last_completed_range

# Given a scanless
# recognizer and a symbol,
# return the start earley set
# and length
# of the last such symbol completed,
# undef if there was none.
sub Marpa::R2::Scanless::R::last_completed {
    my ( $slr, $symbol_name ) = @_;
    my $slg = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thick_g1_grammar =
        $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $thick_g1_recce =
        $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce = $thick_g1_recce->thin();
    my $sought_rules =
        $slg->[Marpa::R2::Inner::Scanless::G::CACHE_RULEIDS_BY_LHS_NAME]
        ->{$symbol_name};
    if ( not defined $sought_rules ) {
        my $g1_tracer       = $thick_g1_grammar->tracer();
        my $thin_g1_grammar = $thick_g1_grammar->thin();
        my $symbol_id       = $g1_tracer->symbol_by_name($symbol_name);
        Marpa::R2::exception("Bad symbol in last_completed(): $symbol_name")
            if not defined $symbol_id;
        $sought_rules =
            $slg->[Marpa::R2::Inner::Scanless::G::CACHE_RULEIDS_BY_LHS_NAME]
            ->{$symbol_name} =
            [ grep { $thin_g1_grammar->rule_lhs($_) == $symbol_id; }
                0 .. $thin_g1_grammar->highest_rule_id() ];
        Marpa::R2::exception(
            "Looking for completion of non-existent rule lhs: $symbol_name")
            if not scalar @{$sought_rules};
    } ## end if ( not defined $sought_rules )
    my $latest_earley_set = $thin_g1_recce->latest_earley_set();
    my $earley_set        = $latest_earley_set;

    # Initialize to one past the end, so we can tell if there were no hits
    my $first_origin = $latest_earley_set + 1;
    EARLEY_SET: while ( $earley_set >= 0 ) {
        $thin_g1_recce->progress_report_start($earley_set);
        ITEM: while (1) {
            my ( $rule_id, $dot_position, $origin ) =
                $thin_g1_recce->progress_item();
            last ITEM if not defined $rule_id;
            next ITEM if $dot_position != -1;
            next ITEM if not scalar grep { $_ == $rule_id } @{$sought_rules};
            next ITEM if $origin >= $first_origin;
            $first_origin = $origin;
        } ## end ITEM: while (1)
        $thin_g1_recce->progress_report_finish();
        last EARLEY_SET if $first_origin <= $latest_earley_set;
        $earley_set--;
    } ## end EARLEY_SET: while ( $earley_set >= 0 )
    return if $earley_set < 0;
    return ( $first_origin, ( $earley_set - $first_origin ) );
} ## end sub Marpa::R2::Scanless::R::last_completed

# In terms of earley sets.
# Kept for backward compatibiity
sub Marpa::R2::Scanless::R::range_to_string {
    my ( $self, $start_earley_set, $end_earley_set ) = @_;
    return $self->substring( $start_earley_set,
        $end_earley_set - $start_earley_set );
}

# Substring in terms of earley sets.
# Necessary for the use of show_progress()
# Given a scanless recognizer and
# and two earley sets, return the input string
sub Marpa::R2::Scanless::R::substring {
    my ( $slr, $start_earley_set, $length_in_parse_locations ) = @_;
    return
        if not defined $start_earley_set
            or not defined $length_in_parse_locations;
    my $thick_g1_recce =
        $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce     = $thick_g1_recce->thin();
    my $latest_earley_set = $thin_g1_recce->latest_earley_set();

    my $earley_set_for_first_position = $start_earley_set + 1;
    my $earley_set_for_last_position =
        $start_earley_set + $length_in_parse_locations;

    die 'Error in $slr->substring(',
        "$start_earley_set, $length_in_parse_locations", '): ',
        "start ($start_earley_set) is at or after latest_earley_set ($latest_earley_set)"
        if $earley_set_for_first_position > $latest_earley_set;
    die 'Error in $slr->substring(',
        "$start_earley_set, $length_in_parse_locations", '): ',
        "end ( $start_earley_set + $length_in_parse_locations ) is after latest_earley_set ($latest_earley_set)"
        if $earley_set_for_last_position > $latest_earley_set;

    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my ($first_start_position) =
        $thin_slr->span($earley_set_for_first_position);
    my ( $last_start_position, $last_length ) =
        $thin_slr->span($earley_set_for_last_position);
    my $length_in_characters =
        ( $last_start_position + $last_length ) - $first_start_position;

    # Negative lengths are quite possible if the application has jumped around in
    # the input.
    return q{} if $length_in_characters <= 0;
    my $p_input = $slr->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];
    return substr ${$p_input}, $first_start_position, $length_in_characters;
} ## end sub Marpa::R2::Scanless::R::substring

sub Marpa::R2::Scanless::R::g1_location_to_span {
    my ( $self, $g1_location ) = @_;
    my $thin_self = $self->[Marpa::R2::Inner::Scanless::R::C];
    return $thin_self->span($g1_location);
}

# Substring in terms of locations in the input stream
# This is the one users will be most interested in.
sub Marpa::R2::Scanless::R::literal {
    my ( $slr, $start_pos, $length ) = @_;
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $stream   = $thin_slr->stream();
    return $stream->substring( $start_pos, $length );
} ## end sub Marpa::R2::Scanless::R::literal

sub Marpa::R2::Internal::Scanless::meta_grammar {

    my $self = bless [], 'Marpa::R2::Scanless::G';
    $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] = \*STDERR;
    $self->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE] =
        'Marpa::R2::Internal::MetaAST_Nodes';
    state $hashed_metag = Marpa::R2::Internal::MetaG::hashed_grammar();
    $self->_hash_to_runtime($hashed_metag);

    my $thick_g1_grammar =
        $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my @mask_by_rule_id;
    $mask_by_rule_id[$_] = $thick_g1_grammar->_rule_mask($_)
        for $thick_g1_grammar->rule_ids();
    $self->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID] =
        \@mask_by_rule_id;

    return $self;

} ## end sub Marpa::R2::Internal::Scanless::meta_grammar

sub Marpa::R2::Internal::Scanless::meta_recce {
    my ($hash_args) = @_;
    state $meta_grammar = Marpa::R2::Internal::Scanless::meta_grammar();
    $hash_args->{grammar} = $meta_grammar;
    my $self = Marpa::R2::Scanless::R->new($hash_args);
    return $self;
} ## end sub Marpa::R2::Internal::Scanless::meta_recce

sub Marpa::R2::Scanless::G::new {
    my ( $class, $args ) = @_;

    my $self = [];
    bless $self, $class;

    $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE]       = *STDERR;
    $self->[Marpa::R2::Inner::Scanless::G::CACHE_RULEIDS_BY_LHS_NAME] = {};

    my $ref_type = ref $args;
    if ( not $ref_type ) {
        Carp::croak(
            "$G_PACKAGE expects args as ref to HASH; arg was non-reference");
    }
    if ( $ref_type ne 'HASH' ) {
        Carp::croak(
            "$G_PACKAGE expects args as ref to HASH, got ref to $ref_type instead"
        );
    }

    # Other possible grammar options:
    # actions
    # default_empty_action
    # default_rank
    # inaccessible_ok
    # symbols
    # terminals
    # unproductive_ok
    # warnings

    my $rules_source;
    $self->[Marpa::R2::Inner::Scanless::G::G1_ARGS] = {};
    ARG: for my $arg_name ( keys %{$args} ) {
        my $value = $args->{$arg_name};
        if ( $arg_name eq 'action_object' ) {
            $self->[Marpa::R2::Inner::Scanless::G::G1_ARGS]->{$arg_name} =
                $value;
            next ARG;
        }
        if ( $arg_name eq 'bless_package' ) {
            $self->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE] = $value;
            next ARG;
        }
        if ( $arg_name eq 'default_action' ) {
            $self->[Marpa::R2::Inner::Scanless::G::G1_ARGS]->{$arg_name} =
                $value;
            next ARG;
        }
        if ( $arg_name eq 'source' ) {
            $rules_source = $value;
            next ARG;
        }
        $self->set( { $arg_name => $value });
        next ARG;
    } ## end ARG: for my $arg_name ( keys %{$args} )

    if ( not defined $rules_source ) {
        Marpa::R2::exception(
            'Marpa::R2::Scanless::G::new() called without a "source" argument'
        );
    }

    $ref_type = ref $rules_source;
    if ( $ref_type ne 'SCALAR' ) {
        Marpa::R2::exception(
            qq{Marpa::R2::Scanless::G::new() type of "source" argument is "$ref_type"},
            "  It must be a ref to a string\n"
        );
    } ## end if ( $ref_type ne 'SCALAR' )
    my $parse = {};
    my $ast = Marpa::R2::Internal::MetaAST->new( $rules_source, $parse );
    my $hashed_ast = $ast->ast_to_hash($parse);
    $self->_hash_to_runtime($hashed_ast);

    return $self;

} ## end sub Marpa::R2::Scanless::G::new

sub Marpa::R2::Scanless::G::set {
    my ( $slg, $args ) = @_;

    my $ref_type = ref $args;
    if ( not $ref_type ) {
        Carp::croak(
            "\$slg->set() expects args as ref to HASH; arg was non-reference"
        );
    }
    if ( $ref_type ne 'HASH' ) {
        Carp::croak(
            "\$slg->set() expects args as ref to HASH, got ref to $ref_type instead"
        );
    }

    # Other possible grammar options:
    # actions
    # default_empty_action
    # default_rank
    # inaccessible_ok
    # symbols
    # terminals
    # unproductive_ok
    # warnings

    ARG: for my $arg_name ( keys %{$args} ) {
        my $value = $args->{$arg_name};
        if ( $arg_name eq 'trace_file_handle' ) {
            $slg->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] =
                $value;
            next ARG;
        }
        Carp::croak(
            '$slg->set does not know one of the options given to it:',
            qq{\n   The options not recognized was "$arg_name"\n}
        );
    } ## end ARG: for my $arg_name ( keys %{$args} )

    return $slg;

} ## end sub Marpa::R2::Scanless::G::set

sub Marpa::R2::Scanless::G::_hash_to_runtime {
    my ( $self, $hashed_source ) = @_;

    my $g0_lexeme_by_name = $hashed_source->{is_lexeme};
    my @g0_lexeme_names   = keys %{$g0_lexeme_by_name};
    Marpa::R2::exception( "There are no lexemes\n",
        "  An SLIF grammar must have at least one lexeme\n" )
        if not scalar @g0_lexeme_names;

    my %lex_args = ();
    $lex_args{trace_file_handle} =
        $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] // \*STDERR;
    $lex_args{rules} = $hashed_source->{g0_rules};
    state $lex_target_symbol = '[:start_lex]';
    $lex_args{start} = $lex_target_symbol;
    $lex_args{'_internal_'} = 1;
    my $lex_grammar = Marpa::R2::Grammar->new( \%lex_args );
    $lex_grammar->precompute();
    my $lex_tracer = $lex_grammar->tracer();
    my $g0_thin    = $lex_tracer->grammar();
    $self->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR] = $lex_grammar;
    my $character_class_hash = $hashed_source->{character_classes};
    my @class_table          = ();

    for my $class_symbol ( sort keys %{$character_class_hash} ) {
        push @class_table,
            [
            $lex_tracer->symbol_by_name($class_symbol),
            $character_class_hash->{$class_symbol}
            ];
    } ## end for my $class_symbol ( sort keys %{$character_class_hash...})
    $self->[Marpa::R2::Inner::Scanless::G::CHARACTER_CLASS_TABLE] =
        \@class_table;

    # The G1 grammar
    my $g1_args = $self->[Marpa::R2::Inner::Scanless::G::G1_ARGS];
    $g1_args->{trace_file_handle} =
        $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] // \*STDERR;
    $g1_args->{bless_package} =
        $self->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE];
    $g1_args->{rules}   = $hashed_source->{g1_rules};
    $g1_args->{symbols} = $hashed_source->{g1_symbols};
    state $g1_target_symbol = '[:start]';
    $g1_args->{start} = $g1_target_symbol;
    $g1_args->{'_internal_'} = 1;
    my $thick_g1_grammar = Marpa::R2::Grammar->new($g1_args);
    my $g1_tracer        = $thick_g1_grammar->tracer();
    my $g1_thin          = $g1_tracer->grammar();

    my $symbol_ids_by_event_name_and_type = {};
    $self->[Marpa::R2::Inner::Scanless::G::SYMBOL_IDS_BY_EVENT_NAME_AND_TYPE]
        = $symbol_ids_by_event_name_and_type;

    my $completion_events_by_name = $hashed_source->{completion_events};
    my $completion_events_by_id =
        $self->[Marpa::R2::Inner::Scanless::G::COMPLETION_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$completion_events_by_name} ) {
        my $event_name = $completion_events_by_name->{$symbol_name};
        my $symbol_id  = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "Completion event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_completion_event_set( $symbol_id, 1 );
        $self->[Marpa::R2::Inner::Scanless::G::COMPLETION_EVENT_BY_ID]
            ->[$symbol_id] = $completion_events_by_name->{$symbol_name};
        push @{ $symbol_ids_by_event_name_and_type->{$event_name}
                ->{completion} }, $symbol_id;
    } ## end for my $symbol_name ( keys %{$completion_events_by_name...})

    my $nulled_events_by_name = $hashed_source->{nulled_events};
    my $nulled_events_by_id =
        $self->[Marpa::R2::Inner::Scanless::G::NULLED_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$nulled_events_by_name} ) {
        my $event_name = $nulled_events_by_name->{$symbol_name};
        my $symbol_id  = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "nulled event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_nulled_event_set( $symbol_id, 1 );
        $self->[Marpa::R2::Inner::Scanless::G::NULLED_EVENT_BY_ID]
            ->[$symbol_id] = $nulled_events_by_name->{$symbol_name};
        push @{ $symbol_ids_by_event_name_and_type->{$event_name}->{nulled} },
            $symbol_id;
    } ## end for my $symbol_name ( keys %{$nulled_events_by_name} )

    my $prediction_events_by_name = $hashed_source->{prediction_events};
    my $prediction_events_by_id =
        $self->[Marpa::R2::Inner::Scanless::G::PREDICTION_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$prediction_events_by_name} ) {
        my $event_name = $prediction_events_by_name->{$symbol_name};
        my $symbol_id  = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "prediction event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_prediction_event_set( $symbol_id, 1 );
        $self->[Marpa::R2::Inner::Scanless::G::PREDICTION_EVENT_BY_ID]
            ->[$symbol_id] = $prediction_events_by_name->{$symbol_name};
        push @{ $symbol_ids_by_event_name_and_type->{$event_name}
                ->{prediction} }, $symbol_id;
    } ## end for my $symbol_name ( keys %{$prediction_events_by_name...})

    my $lexeme_events_by_id =
        $self->[Marpa::R2::Inner::Scanless::G::LEXEME_EVENT_BY_ID] = [];

    $thick_g1_grammar->precompute();
    my @g0_lexeme_to_g1_symbol;
    my @g1_symbol_to_g0_lexeme;
    $g0_lexeme_to_g1_symbol[$_] = -1 for 0 .. $g1_thin->highest_symbol_id();
    state $discard_symbol_name = '[:discard]';
    my $g0_discard_symbol_id =
        $self->[Marpa::R2::Inner::Scanless::G::G0_DISCARD_SYMBOL_ID] =
        $lex_tracer->symbol_by_name($discard_symbol_name) // -1;

    LEXEME_NAME: for my $lexeme_name (@g0_lexeme_names) {
        next LEXEME_NAME if $lexeme_name eq $discard_symbol_name;
        my $g1_symbol_id = $g1_tracer->symbol_by_name($lexeme_name);
        if ( not defined $g1_symbol_id ) {
            Marpa::R2::exception(
                'A lexeme is not accessible from the start symbol: ',
                $lexeme_name );
        }
        my $lex_symbol_id = $lex_tracer->symbol_by_name($lexeme_name);
        $g0_lexeme_to_g1_symbol[$lex_symbol_id] = $g1_symbol_id;
        $g1_symbol_to_g0_lexeme[$g1_symbol_id]  = $lex_symbol_id;
    } ## end LEXEME_NAME: for my $lexeme_name (@g0_lexeme_names)

    SYMBOL_ID: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id() ) {
        if ( $g1_thin->symbol_is_terminal($symbol_id)
            and not defined $g1_symbol_to_g0_lexeme[$symbol_id] )
        {
            my $symbol_name = $g1_tracer->symbol_name($symbol_id);
            if ( $lex_tracer->symbol_by_name($symbol_name) ) {
                Marpa::R2::exception(
                    "Symbol <$symbol_name> is a lexeme in G1, but not in G0.\n",
                    "  This may be because <$symbol_name> was used on a RHS in G0.\n",
                    "  A lexeme cannot be used on the RHS of a G0 rule.\n"
                );
            } ## end if ( $lex_tracer->symbol_by_name($symbol_name) )
            Marpa::R2::exception( 'Unproductive symbol: ',
                $g1_tracer->symbol_name($symbol_id) );
        } ## end if ( $g1_thin->symbol_is_terminal($symbol_id) and not...)
    } ## end SYMBOL_ID: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id(...))

    my $thin_slg = $self->[Marpa::R2::Inner::Scanless::G::C] =
        Marpa::R2::Thin::SLG->new( $lex_tracer->grammar(),
        $g1_tracer->grammar() );

    my $lexeme_declarations = $hashed_source->{lexeme_declarations};
    for my $lexeme_name ( keys %{$lexeme_declarations} ) {
        Marpa::R2::exception(
            "Symbol <$lexeme_name> is declared as a lexeme, but it is not used as one.\n"
        ) if not $g0_lexeme_by_name->{$lexeme_name};

        my $declarations = $lexeme_declarations->{$lexeme_name};
        my $g1_lexeme_id = $g1_tracer->symbol_by_name($lexeme_name);

        if ( defined( my $value = $declarations->{priority} ) ) {
            $thin_slg->g1_lexeme_priority_set( $g1_lexeme_id, $value );
        }
        my $pause_value = $declarations->{pause};
        if ( defined $pause_value ) {
            $thin_slg->g1_lexeme_pause_set( $g1_lexeme_id, $pause_value );

            if ( defined( my $event_name = $declarations->{'event'} ) ) {
                $lexeme_events_by_id->[$g1_lexeme_id] = $event_name;
                push @{ $symbol_ids_by_event_name_and_type->{$event_name}
                        ->{lexeme} }, $g1_lexeme_id;
            }
        } ## end if ( defined $pause_value )

    } ## end for my $lexeme_name ( keys %{$lexeme_declarations} )

    # Now that we know the lexemes, check attempts to defined a
    # completion or a nulled event for one
    for my $symbol_name ( keys %{$completion_events_by_name} ) {
        Marpa::R2::exception(
            "A completion event is declared for <$symbol_name>, but it is a G1 lexeme.\n",
            "  Completion events are only valid for symbols on the LHS of G1 rules.\n"
        ) if $g0_lexeme_by_name->{$symbol_name};
    } ## end for my $symbol_name ( keys %{$completion_events_by_name...})
    for my $symbol_name ( keys %{$nulled_events_by_name} ) {
        Marpa::R2::exception(
            "A nulled event is declared for <$symbol_name>, but it is a G1 lexeme.\n",
            "  nulled events are only valid for symbols on the LHS of G1 rules.\n"
        ) if $g0_lexeme_by_name->{$symbol_name};
    } ## end for my $symbol_name ( keys %{$nulled_events_by_name} )

    my @g0_rule_to_g1_lexeme;
    RULE_ID: for my $rule_id ( 0 .. $g0_thin->highest_rule_id() ) {
        my $lhs_id = $g0_thin->rule_lhs($rule_id);
        my $lexeme_id =
            $lhs_id == $g0_discard_symbol_id
            ? -2
            : ( $g0_lexeme_to_g1_symbol[$lhs_id] // -1 );
        $g0_rule_to_g1_lexeme[$rule_id] = $lexeme_id;
        $thin_slg->g0_rule_to_g1_lexeme_set( $rule_id, $lexeme_id );
    } ## end RULE_ID: for my $rule_id ( 0 .. $g0_thin->highest_rule_id() )

    $thin_slg->precompute();
    $self->[Marpa::R2::Inner::Scanless::G::G0_RULE_TO_G1_LEXEME] =
        \@g0_rule_to_g1_lexeme;
    $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR] =
        $thick_g1_grammar;

    return 1;

} ## end sub Marpa::R2::Scanless::G::_hash_to_runtime

sub Marpa::R2::Scanless::G::show_rules {
    my ($self) = @_;
    my $thick_lex_grammar =
        $self->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $text = "Lex (G0) Rules:\n";
    $text .= $thick_lex_grammar->show_rules();
    my $thick_g1_grammar =
        $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    $text .= "G1 Rules:\n";
    $text .= $thick_g1_grammar->show_rules();
    return $text;
} ## end sub Marpa::R2::Scanless::G::show_rules

sub Marpa::R2::Scanless::R::new {
    my ( $class, $args ) = @_;

    my $self = [];
    bless $self, $class;

    state $grammar_class = 'Marpa::R2::Scanless::G';
    my $grammar = $args->{grammar};
    if ( not blessed $grammar or not $grammar->isa('Marpa::R2::Scanless::G') )
    {
        my $desc = 'undefined';
        if ( defined $grammar ) {
            my $ref_type = ref $grammar;
            $desc = $ref_type ? "a ref to $ref_type" : 'not a ref';
        }
        Marpa::R2::exception(
            qq{'grammar' name argument to scanless_r->new() is $desc\n},
            "  It should be a ref to $grammar_class\n" );
        Marpa::R2::exception(
            'Marpa::R2::Scanless::R::new() called without a "grammar" argument'
        );
    } ## end if ( not blessed $grammar or not $grammar->isa(...))

    $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR] = $grammar;
    $self->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE] =
        $grammar->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE];

    my $g1_recce_args = {};
    $g1_recce_args->{too_many_earley_items} = -1;
    ARG: for my $arg_name ( keys %{$args} ) {
        my $value = $args->{$arg_name};
        next ARG if $arg_name eq 'grammar';    # already handled
        if ( $arg_name eq 'max_parses' ) {
            $g1_recce_args->{$arg_name} = $value;
            next ARG;
        }
        if ( $arg_name eq 'too_many_earley_items' ) {
            if ( $value < 0 ) {
                Marpa::R2::exception(
                    q{The "too_many_earley_items" option must be greater than or equal to 0}
                );
            }
            $g1_recce_args->{$arg_name} = $value;
            next ARG;
        } ## end if ( $arg_name eq 'too_many_earley_items' )
        if ( $arg_name eq 'trace_file_handle' ) {
            $g1_recce_args->{$arg_name} = $value;
            $self->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE] =
                $value;
            next ARG;
        } ## end if ( $arg_name eq 'trace_file_handle' )
        if ( $arg_name eq 'trace_g0' ) {
            $self->[Marpa::R2::Inner::Scanless::R::TRACE_G0] = $value;
            next ARG;
        }
        if ( $arg_name eq 'trace_terminals' ) {
            $self->[Marpa::R2::Inner::Scanless::R::TRACE_TERMINALS] = $value;
            next ARG;
        }
        if ( $arg_name eq 'ranking_method' ) {
            $g1_recce_args->{$arg_name} = $value;
            next ARG;
        }
        if ( $arg_name eq 'trace_values' ) {
            $g1_recce_args->{$arg_name} = $value;
            next ARG;
        }
        if ( $arg_name eq 'trace_actions' ) {
            $g1_recce_args->{$arg_name} = $value;
            next ARG;
        }
        Marpa::R2::exception(
            "$R_PACKAGE does not know one of options given to it:\n",
            qq{   The options not recognized was "$arg_name"\n}
        );
    } ## end ARG: for my $arg_name ( keys %{$args} )

    $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR] = $grammar;
    my $thick_lex_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $lex_tracer       = $thick_lex_grammar->tracer();
    my $thin_lex_grammar = $lex_tracer->grammar();

    my $thick_g1_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    $g1_recce_args->{grammar} = $thick_g1_grammar;
    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE] =
        Marpa::R2::Recognizer->new($g1_recce_args);

    $thick_g1_recce->semantics_set();

    my $thin_self = Marpa::R2::Thin::SLR->new(
        $grammar->[Marpa::R2::Inner::Scanless::G::C],
        $thick_g1_recce->thin() );
    my $too_many_earley_items = $g1_recce_args->{too_many_earley_items};
    $thin_self->earley_item_warning_threshold_set($too_many_earley_items)
        if $too_many_earley_items >= 0;
    $self->[Marpa::R2::Inner::Scanless::R::C]      = $thin_self;
    $self->[Marpa::R2::Inner::Scanless::R::EVENTS] = [];
    Marpa::R2::Inner::Scanless::convert_libmarpa_events($self);

    return $self;
} ## end sub Marpa::R2::Scanless::R::new

sub Marpa::R2::Scanless::R::thin {
    return $_[0]->[Marpa::R2::Inner::Scanless::R::C];
}

sub Marpa::R2::Scanless::R::trace {
    my ( $self, $level ) = @_;
    $level //= 1;
    my $stream = $self->stream();
    return $stream->trace($level);
} ## end sub Marpa::R2::Scanless::R::trace

sub Marpa::R2::Scanless::R::trace_g0 {
    my ( $self, $level ) = @_;
    $level //= 1;
    my $stream = $self->stream();
    return $stream->trace_g0($level);
} ## end sub Marpa::R2::Scanless::R::trace_g0

sub Marpa::R2::Scanless::R::error {
    my ($self) = @_;
    return $self->[Marpa::R2::Inner::Scanless::R::READ_STRING_ERROR];
}

sub Marpa::R2::Scanless::R::read {
    my ( $self, $p_string, $start_pos, $length ) = @_;

    $start_pos //= 0;
    $length    //= -1;
    Marpa::R2::exception(
        "Multiple read()'s tried on a scannerless recognizer\n",
        '  Currently the string cannot be changed once set'
    ) if defined $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];

    if ( ( my $ref_type = ref $p_string ) ne 'SCALAR' ) {
        my $desc = $ref_type ? "a ref to $ref_type" : 'not a ref';
        Marpa::R2::exception(
            qq{Arg to Marpa::R2::Scanless::R::read() is $desc\n},
            '  It should be a ref to scalar' );
    } ## end if ( ( my $ref_type = ref $p_string ) ne 'SCALAR' )
    $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING] = $p_string;

    my $thin_slr = $self->[Marpa::R2::Inner::Scanless::R::C];
    my $trace_terminals =
        $self->[Marpa::R2::Inner::Scanless::R::TRACE_TERMINALS] // 0;
    my $trace_g0 = $self->[Marpa::R2::Inner::Scanless::R::TRACE_G0] // 0;
    $thin_slr->trace_terminals($trace_terminals) if $trace_terminals;
    $thin_slr->trace_g0($trace_g0)               if $trace_g0;
    my $stream = $thin_slr->stream();

    $stream->string_set($p_string);

    return 0 if @{ $self->[Marpa::R2::Inner::Scanless::R::EVENTS] };

    return $self->resume( $start_pos, $length );

} ## end sub Marpa::R2::Scanless::R::read

my $libmarpa_trace_event_handlers = {

    'g1 accepted lexeme' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $lexeme_start_pos, $lexeme_end_pos, $g1_lexeme ) =
            @{$event};
        my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
        my $stream   = $thin_slr->stream();
        my $raw_token_value =
            $stream->substring( $lexeme_start_pos,
            $lexeme_end_pos - $lexeme_start_pos );
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        my $thick_g1_recce =
            $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $thick_g1_grammar = $thick_g1_recce->grammar();
        my $g1_tracer        = $thick_g1_grammar->tracer();
        say {$trace_file_handle} 'Accepted lexeme @',
            $lexeme_start_pos,
            q{-},
            $lexeme_end_pos, q{: },
            $g1_tracer->symbol_name($g1_lexeme),
            qq{; value="$raw_token_value"}
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g1 unexpected lexeme' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $lexeme_start_pos, $lexeme_end_pos, $g1_lexeme ) =
            @{$event};
        my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
        my $stream   = $thin_slr->stream();
        my $raw_token_value =
            $stream->substring( $lexeme_start_pos,
            $lexeme_end_pos - $lexeme_start_pos );
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        my $thick_g1_recce =
            $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $thick_g1_grammar = $thick_g1_recce->grammar();
        my $g1_tracer        = $thick_g1_grammar->tracer();
        say {$trace_file_handle} 'Rejected lexeme @',
            $lexeme_start_pos,
            q{-},
            $lexeme_end_pos, q{: },
            $g1_tracer->symbol_name($g1_lexeme),
            qq{; value="$raw_token_value"}
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g1 duplicate lexeme' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $lexeme_start_pos, $lexeme_end_pos, $g1_lexeme ) =
            @{$event};
        my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
        my $stream   = $thin_slr->stream();
        my $raw_token_value =
            $stream->substring( $lexeme_start_pos,
            $lexeme_end_pos - $lexeme_start_pos );
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        my $thick_g1_recce =
            $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $thick_g1_grammar = $thick_g1_recce->grammar();
        my $g1_tracer        = $thick_g1_grammar->tracer();
        say {$trace_file_handle}
            'Rejected as duplicate lexeme @',
            $lexeme_start_pos,
            q{-},
            $lexeme_end_pos, q{: },
            $g1_tracer->symbol_name($g1_lexeme),
            qq{; value="$raw_token_value"}
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g1 attempting lexeme' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $lexeme_start_pos, $lexeme_end_pos, $g1_lexeme ) =
            @{$event};
        my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
        my $stream   = $thin_slr->stream();
        my $raw_token_value =
            $stream->substring( $lexeme_start_pos,
            $lexeme_end_pos - $lexeme_start_pos );
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        my $thick_g1_recce =
            $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $thick_g1_grammar = $thick_g1_recce->grammar();
        my $g1_tracer        = $thick_g1_grammar->tracer();
        say {$trace_file_handle}
            'Attempting to read lexeme @',
            $lexeme_start_pos,
            q{-},
            $lexeme_end_pos, q{: },
            $g1_tracer->symbol_name($g1_lexeme),
            qq{; value="$raw_token_value"}
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g0 reading codepoint' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $codepoint, $position ) = @{$event};
        my $char      = chr $codepoint;
        my @char_desc = ();
        push @char_desc, qq{"$char"}
            if $char =~ /[\p{IsGraph}]/xms;
        push @char_desc, ( sprintf '0x%04x', $codepoint );
        my $char_desc = join q{ }, @char_desc;
        my ( $line, $column ) = $slr->line_column($position);
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        say {$trace_file_handle}
            "G0 reading codepoint $char_desc at line $line, column $column"
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g0 accepted codepoint' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $codepoint, $position, $token_id ) = @{$event};
        my $char      = chr $codepoint;
        my @char_desc = ();
        push @char_desc, qq{"$char"}
            if $char =~ /[\p{IsGraph}]/xms;
        push @char_desc, ( sprintf '0x%04x', $codepoint );
        my $char_desc = join q{ }, @char_desc;
        my $grammar = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
        my $thick_lex_grammar =
            $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
        my $g0_tracer   = $thick_lex_grammar->tracer();
        my $symbol_name = $g0_tracer->symbol_name($token_id);
        my ( $line, $column ) = $slr->line_column($position);
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        say {$trace_file_handle}
            "G0 codepoint $char_desc accepted as <$symbol_name> at line $line, column $column"
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g0 rejected codepoint' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $codepoint, $position, $token_id ) = @{$event};
        my $char      = chr $codepoint;
        my @char_desc = ();
        push @char_desc, qq{"$char"}
            if $char =~ /[\p{IsGraph}]/xms;
        push @char_desc, ( sprintf '0x%04x', $codepoint );
        my $char_desc = join q{ }, @char_desc;
        my $grammar = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
        my $thick_lex_grammar =
            $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
        my $g0_tracer   = $thick_lex_grammar->tracer();
        my $symbol_name = $g0_tracer->symbol_name($token_id);
        my ( $line, $column ) = $slr->line_column($position);
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        say {$trace_file_handle}
            "G0 codepoint $char_desc rejected as <$symbol_name> at line $line, column $column"
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g0 restarted recognizer' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $position ) = @{$event};
        my ( $line, $column ) = $slr->line_column($position);
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        say {$trace_file_handle}
            "G0 restarted recognizer at line $line, column $column"
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'discarded lexeme' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $g0_rule_id, $start, $end ) = @{$event};
        my $grammar = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
        my $thick_lex_grammar =
            $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
        my $g0_tracer = $thick_lex_grammar->tracer();
        my ( undef, @rhs ) =
            map { Marpa::R2::Grammar::original_symbol_name($_) }
            $g0_tracer->rule($g0_rule_id);
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        say {$trace_file_handle} 'Discarded lexeme @',
            "$start-$end: ", join q{ }, @rhs
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g1 pausing before lexeme' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $start, $length, $lexeme_id ) = @{$event};
        my $end = $start + $length - 1;
        my $thick_g1_recce =
            $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $thick_g1_grammar = $thick_g1_recce->grammar();
        my $g1_tracer        = $thick_g1_grammar->tracer();
        my $lexeme_name      = Marpa::R2::Grammar::original_symbol_name(
            $g1_tracer->symbol_name($lexeme_id) );
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        say {$trace_file_handle} 'Paused before lexeme @',
            "$start-$end: <$lexeme_name>"
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'g1 pausing after lexeme' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $start, $length, $lexeme_id ) = @{$event};
        my $end = $start + $length - 1;
        my $thick_g1_recce =
            $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $thick_g1_grammar = $thick_g1_recce->grammar();
        my $g1_tracer        = $thick_g1_grammar->tracer();
        my $lexeme_name      = Marpa::R2::Grammar::original_symbol_name(
            $g1_tracer->symbol_name($lexeme_id) );
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        say {$trace_file_handle} 'Paused after lexeme @',
            "$start-$end: <$lexeme_name>"
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
    'ignored lexeme' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, undef, $g1_symbol_id, $start, $end ) = @{$event};
        my $thick_g1_recce =
            $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
        my $thick_g1_grammar = $thick_g1_recce->grammar();
        my $g1_tracer        = $thick_g1_grammar->tracer();
        my $lexeme           = Marpa::R2::Grammar::original_symbol_name(
            $g1_tracer->symbol_name($g1_symbol_id) );
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        say {$trace_file_handle} 'Ignored lexeme @', "$start-$end: $lexeme"
            or Marpa::R2::exception("Could not say(): $ERRNO");
    },
};

my $libmarpa_event_handlers = {
    q{'trace} => sub {
        my ( $slr, $event ) = @_;
        my $handler = $libmarpa_trace_event_handlers->{ $event->[1] };
        if ( defined $handler ) {
            $handler->( $slr, $event );
        }
        else {
            my $trace_file_handle =
                $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
            say {$trace_file_handle} 'Trace event: ', join q{ }, @{$event}
                or Marpa::R2::exception("Could not say(): $ERRNO");
        } ## end else [ if ( defined $handler ) ]
        return 0;
    },

    'symbol completed' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, $completed_symbol_id ) = @{$event};
        my $slg = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
        my $completion_event_by_id =
            $slg->[Marpa::R2::Inner::Scanless::G::COMPLETION_EVENT_BY_ID];
        push @{ $slr->[Marpa::R2::Inner::Scanless::R::EVENTS] },
            [ $completion_event_by_id->[$completed_symbol_id] ];
        return 1;
    },

    'symbol nulled' => sub {
        my ( $slr,  $event )            = @_;
        my ( undef, $nulled_symbol_id ) = @{$event};
        my $slg = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
        my $nulled_event_by_id =
            $slg->[Marpa::R2::Inner::Scanless::G::NULLED_EVENT_BY_ID];
        push @{ $slr->[Marpa::R2::Inner::Scanless::R::EVENTS] },
            [ $nulled_event_by_id->[$nulled_symbol_id] ];
        return 1;
    },

    'symbol predicted' => sub {
        my ( $slr, $event ) = @_;
        my ( undef, $predicted_symbol_id ) = @{$event};
        my $slg = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
        my $prediction_event_by_id =
            $slg->[Marpa::R2::Inner::Scanless::G::PREDICTION_EVENT_BY_ID];
        push @{ $slr->[Marpa::R2::Inner::Scanless::R::EVENTS] },
            [ $prediction_event_by_id->[$predicted_symbol_id] ];
        return 1;
    },

    # 'after lexeme' is same -- copied over below
    'before lexeme' => sub {
        my ( $slr,  $event )     = @_;
        my ( undef, $lexeme_id ) = @{$event};
        my $slg = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
        my $lexeme_event =
            $slg->[Marpa::R2::Inner::Scanless::G::LEXEME_EVENT_BY_ID]
            ->[$lexeme_id];
        push @{ $slr->[Marpa::R2::Inner::Scanless::R::EVENTS] },
            [$lexeme_event]
            if defined $lexeme_event;
        return 1;
    },

    'unknown g1 event' => sub {
        my ( $slr, $event ) = @_;
        Marpa::R2::exception( ( join q{ }, 'Unknown event:', @{$event} ) );
        return 0;
    },

    'no acceptable input' => sub {
        ## Do nothing at this point
        return 0;
    },
};

$libmarpa_event_handlers->{'after lexeme'} = $libmarpa_event_handlers->{'before lexeme'};

# Return 1 if internal scanning should pause
sub Marpa::R2::Inner::Scanless::convert_libmarpa_events {
    my ($slr)    = @_;
    my $pause    = 0;
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    EVENT: for my $event ( $thin_slr->events() ) {
        my ($event_type) = @{$event};
        my $handler = $libmarpa_event_handlers->{$event_type};
        Marpa::R2::exception( ( join q{ }, 'Unknown event:', @{$event} ) )
            if not defined $handler;
        $pause = 1 if $handler->( $slr, $event );
    } ## end EVENT: for my $event ( $thin_slr->events() )
    return $pause;
} ## end sub Marpa::R2::Inner::Scanless::convert_libmarpa_events

sub Marpa::R2::Scanless::R::resume {
    my ( $self, $start_pos, $length ) = @_;
    Marpa::R2::exception(
        "Attempt to resume an SLIF recce which has no string set\n",
        '  The string should be set first using read()'
        )
        if not defined $self->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];

    my $thin_slr = $self->[Marpa::R2::Inner::Scanless::R::C];
    my $trace_terminals =
        $self->[Marpa::R2::Inner::Scanless::R::TRACE_TERMINALS] // 0;
    my $trace_g0 = $self->[Marpa::R2::Inner::Scanless::R::TRACE_G0] // 0;
    $thin_slr->trace_terminals($trace_terminals) if $trace_terminals;
    $thin_slr->trace_g0($trace_g0)               if $trace_g0;

    $thin_slr->pos_set( $start_pos, $length );
    $self->[Marpa::R2::Inner::Scanless::R::EVENTS] = [];

    OUTER_READ: while (1) {

        my $problem_code = $thin_slr->read();
        last OUTER_READ if not $problem_code;
        my $stream = $thin_slr->stream();
        my $pause =
            Marpa::R2::Inner::Scanless::convert_libmarpa_events($self);

        if ( $trace_g0 > 2 ) {
            my $stream_pos = $stream->pos();
            my $trace_file_handle =
                $self->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
            my $grammar = $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
            my $thick_lex_grammar =
                $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
            my $g0_tracer = $thick_lex_grammar->tracer();
            my ( $line, $column ) = $self->line_column($stream_pos);
            print {$trace_file_handle}
                qq{\n=== Progress report at line $line, column $column\n},
                $g0_tracer->stream_progress_report($stream),
                qq{=== End of progress report at line $line, column $column\n},
                or Marpa::R2::exception("Cannot print(): $ERRNO");
        } ## end if ( $trace_g0 > 2 )

        last OUTER_READ if $pause;
        next OUTER_READ if $problem_code eq 'event';
        next OUTER_READ if $problem_code eq 'trace';

        if ( $problem_code eq 'unregistered char' ) {

            state $op_alternative = Marpa::R2::Thin::op('alternative');
            state $op_earleme_complete =
                Marpa::R2::Thin::op('earleme_complete');

            # Recover by registering character, if we can
            my $codepoint = $stream->codepoint();
            my @ops;
            my $grammar = $self->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
            for my $entry (
                @{  $grammar->[
                        Marpa::R2::Inner::Scanless::G::CHARACTER_CLASS_TABLE]
                }
                )
            {

                my ( $symbol_id, $re ) = @{$entry};
                if ( chr($codepoint) =~ $re ) {

                    if ($trace_terminals) {
                        my $thick_lex_grammar = $grammar->[
                            Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
                        my $g0_tracer         = $thick_lex_grammar->tracer();
                        my $trace_file_handle = $self->[
                            Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
                        say {$trace_file_handle}
                            'Registering character ',
                            ( sprintf 'U+%04x', $codepoint ),
                            " as symbol $symbol_id: ",
                            $g0_tracer->symbol_name($symbol_id)
                            or
                            Marpa::R2::exception("Could not say(): $ERRNO");
                    } ## end if ($trace_terminals)
                    push @ops, $op_alternative, $symbol_id, 0, 1;
                } ## end if ( chr($codepoint) =~ $re )
            } ## end for my $entry ( @{ $grammar->[...]})

            Marpa::R2::exception(
                'Lexing failed at unacceptable character ',
                character_describe( chr $codepoint )
            ) if not @ops;
            $stream->char_register( $codepoint, @ops, $op_earleme_complete );
            next OUTER_READ;
        } ## end if ( $problem_code eq 'unregistered char' )

        return $self->read_problem($problem_code);

    } ## end OUTER_READ: while (1)

    return $thin_slr->pos();
} ## end sub Marpa::R2::Scanless::R::resume

sub Marpa::R2::Scanless::R::event {
    my ( $self, $event_ix ) = @_;
    return $self->[Marpa::R2::Inner::Scanless::R::EVENTS]->[$event_ix];
}

sub Marpa::R2::Scanless::R::events {
    my ($self) = @_;
    return $self->[Marpa::R2::Inner::Scanless::R::EVENTS];
}

## From here, recovery is a matter for the caller,
## if it is possible at all
sub Marpa::R2::Scanless::R::read_problem {
    my ( $slr, $problem_code ) = @_;

    die 'No problem_code in slr->read_problem()' if not $problem_code;

    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $grammar  = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];

    my $thick_lex_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
    my $lex_tracer = $thick_lex_grammar->tracer();
    my $stream     = $thin_slr->stream();

    my $trace_file_handle =
        $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];

    my $thick_g1_recce =
        $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce    = $thick_g1_recce->thin();
    my $thick_g1_grammar = $thick_g1_recce->grammar();
    my $g1_tracer        = $thick_g1_grammar->tracer();

    my $pos      = $stream->pos();
    my $p_string = $slr->[Marpa::R2::Inner::Scanless::R::P_INPUT_STRING];
    my $length_of_string = length ${$p_string};

    my $problem;
    my $g0_status = 0;
    my $g1_status = 0;
    CODE_TO_PROBLEM: {
        if ( $problem_code eq 'R0 exhausted before end' ) {
            my ($lexeme_start) = $thin_slr->lexeme_span();
            my ( $line, $column ) = $slr->line_column($lexeme_start);
            $problem =
                "Parse exhausted, but lexemes remain, at line $line, column $column\n";
            last CODE_TO_PROBLEM;
        } ## end if ( $problem_code eq 'R0 exhausted before end' )
        if ( $problem_code eq 'no lexeme' ) {
            my ($lexeme_start) = $thin_slr->lexeme_span();
            my ( $line, $column ) = $slr->line_column($lexeme_start);
            $problem = "No lexeme found at line $line, column $column";
            last CODE_TO_PROBLEM;
        } ## end if ( $problem_code eq 'no lexeme' )
        if ( $problem_code eq 'R0 read() problem' ) {
            $problem = undef;    # let $g0_status do the work
            $g0_status = $thin_slr->stream_read_result();
            last CODE_TO_PROBLEM;
        }
        if ( $problem_code eq 'no lexemes accepted' ) {
            my $problem_pos = $stream->problem_pos();
            my ( $line, $column ) = $slr->line_column($problem_pos);
            $problem = "No lexemes accepted at line $line, column $column";
            last CODE_TO_PROBLEM;
        } ## end if ( $problem_code eq 'no lexemes accepted' )
        $problem = 'Unrecognized problem code: ' . $problem_code;
    } ## end CODE_TO_PROBLEM:

    my $desc;
    DESC: {
        if ( defined $problem ) {
            $desc .= "$problem";
        }
        if ( $g0_status > 0 ) {
            EVENT:
            for ( my $event_ix = 0; $event_ix < $g0_status; $event_ix++ ) {
                my ( $event_type, $value ) =
                    $thin_slr->g0()->event($event_ix);
                if ( $event_type eq 'MARPA_EVENT_EARLEY_ITEM_THRESHOLD' ) {
                    $desc = join "\n", $desc,
                        "Lexer: Earley item count ($value) exceeds warning threshold";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                    $desc = join "\n", $desc,
                        "Unexpected lexer event: $event_type "
                        . $lex_tracer->symbol_name($value);
                    next EVENT;
                } ## end if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' )
                if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                    $desc = join "\n", $desc,
                        "Unexpected lexer event: $event_type";
                    next EVENT;
                }
            } ## end EVENT: for ( my $event_ix = 0; $event_ix < $g0_status; ...)
            last DESC;
        } ## end if ( $g0_status > 0 )
        if ( $g0_status == -1 ) {
            $desc = 'Lexer: Character rejected';
            last DESC;
        }
        if ( $g0_status == -2 ) {
            $desc = 'Lexer: Unregistered character';
            last DESC;
        }
        if ( $g0_status == -3 ) {
            $desc = 'Unexpected return value from lexer: Parse exhausted';
            last DESC;
        }
        if ($g1_status) {
            my $true_event_count = $thin_slr->g1()->event_count();
            EVENT:
            for (
                my $event_ix = 0;
                $event_ix < $true_event_count;
                $event_ix++
                )
            {
                my ( $event_type, $value ) =
                    $thin_slr->g1()->event($event_ix);
                if ( $event_type eq 'MARPA_EVENT_EARLEY_ITEM_THRESHOLD' ) {
                    $desc = join "\n", $desc,
                        "G1 grammar: Earley item count ($value) exceeds warning threshold\n";
                    next EVENT;
                }
                if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
                    $desc = join "\n", $desc,
                        "Unexpected G1 grammar event: $event_type "
                        . $g1_tracer->symbol_name($value);
                    next EVENT;
                } ## end if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' )
                if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
                    $desc = join "\n", $desc, 'Parse exhausted';
                    next EVENT;
                }
                Marpa::R2::exception( $desc, "\n",
                    qq{Unknown event: "$event_type"; event value = $value\n}
                );
            } ## end EVENT: for ( my $event_ix = 0; $event_ix < ...)
            last DESC;
        } ## end if ($g1_status)
        if ( $g1_status < 0 ) {
            $desc = 'G1 error: ' . $thin_slr->g1()->error();
            chomp $desc;
            last DESC;
        }
    } ## end DESC:
    my $read_string_error;
    if ($g1_status) {
        my $latest_earley_set = $thin_g1_recce->latest_earley_set();
        my ( $start_location, $length ) = $thin_slr->span($latest_earley_set);
        my ( $line,           $column ) = $thin_slr->line_column($pos);
        my $last_pos = $start_location + $length;
        my $prefix =
            $last_pos >= 50
            ? ( substr ${$p_string}, $last_pos - 50, 50 )
            : ( substr ${$p_string}, 0, $last_pos );
        $read_string_error =
              "Error in SLIF parse: $desc\n"
            . '* String before error: '
            . Marpa::R2::escape_string( $prefix, -50 ) . "\n"
            . "* The error was at line $line, column $column, ...\n"
            . '* here: '
            . Marpa::R2::escape_string(
            ( substr ${$p_string}, $last_pos, 50 ), 50 )
            . "\n";
    } ## end if ($g1_status)
    elsif ( $pos < $length_of_string ) {
        my $char = substr ${$p_string}, $pos, 1;
        my $char_desc = character_describe($char);
        my ( $line, $column ) = $thin_slr->line_column($pos);
        my $prefix =
            $pos >= 50
            ? ( substr ${$p_string}, $pos - 50, 50 )
            : ( substr ${$p_string}, 0, $pos );

        $read_string_error =
              "Error in SLIF parse: $desc\n"
            . '* String before error: '
            . Marpa::R2::escape_string( $prefix, -50 ) . "\n"
            . "* The error was at line $line, column $column, and at character $char_desc, ...\n"
            . '* here: '
            . Marpa::R2::escape_string( ( substr ${$p_string}, $pos, 50 ),
            50 )
            . "\n";
    } ## end elsif ( $pos < $length_of_string )
    else {
        $read_string_error =
              "Error in SLIF parse: $desc\n"
            . "* Error was at end of input\n"
            . '* String before error: '
            . Marpa::R2::escape_string( ${$p_string}, -50 ) . "\n";
    } ## end else [ if ($g1_status) ]

    if ( $slr->[Marpa::R2::Inner::Scanless::R::TRACE_G0] ) {
        my $stream_pos = $stream->pos();
        my $trace_file_handle =
            $slr->[Marpa::R2::Inner::Scanless::R::TRACE_FILE_HANDLE];
        my $grammar = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
        my $thick_lex_grammar =
            $grammar->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR];
        my $g0_tracer = $thick_lex_grammar->tracer();
        my ( $line, $column ) = $slr->line_column($stream_pos);
        $read_string_error .=
            qq{\n=== G0 Progress report at line $line, column $column\n} .
            $g0_tracer->stream_progress_report($stream);
    } ## end if ( $slr->[Marpa::R2::Inner::Scanless::R::TRACE_G0...])

    $slr->[Marpa::R2::Inner::Scanless::R::READ_STRING_ERROR] =
        $read_string_error;
    Marpa::R2::exception($read_string_error);

    # Never reached
    # Fall through to return undef
    return;

} ## end sub Marpa::R2::Scanless::R::read_problem

sub character_describe {
    my ($char) = @_;
    my $text = sprintf '0x%04x', ord $char;
    $text .= q{ }
        . (
        $char =~ m/[[:graph:]]/xms
        ? qq{'$char'}
        : '(non-graphic character)'
        );
    return $text;
} ## end sub character_describe

sub Marpa::R2::Scanless::R::value {

    my ($self) = @_;
    my $thick_g1_recce =
        $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thick_g1_value = $thick_g1_recce->value($self);
    return $thick_g1_value;
} ## end sub Marpa::R2::Scanless::R::value

sub Marpa::R2::Scanless::R::show_progress {
    my ( $self, @args ) = @_;
    return $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE]
        ->show_progress(@args);
}

sub Marpa::R2::Scanless::R::progress {
    my ( $self, @args ) = @_;
    return $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE]
        ->progress(@args);
}

sub Marpa::R2::Scanless::R::terminals_expected {
    my ($self) = @_;
    return $self->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE]
        ->terminals_expected();
}

# Latest and current G1 location are the same
sub Marpa::R2::Scanless::R::latest_g1_location {
    my ($slg) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE]
        ->latest_earley_set();
}

# Latest and current G1 location are the same
sub Marpa::R2::Scanless::R::current_g1_location {
    my ($slg) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE]
        ->latest_earley_set();
}

sub Marpa::R2::Scanless::G::rule {
    my ( $slg, @args ) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR]
        ->rule(@args);
}

sub Marpa::R2::Scanless::G::g1_rule_ids {
    my ($slg) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR]->rule_ids();
}

sub Marpa::R2::Scanless::G::g0_rule_ids {
    my ($slg) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR]->rule_ids();
}

sub Marpa::R2::Scanless::G::g0_rule {
    my ( $slg, @args ) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR]
        ->rule(@args);
}

sub Marpa::R2::Scanless::R::lexeme_alternative {
    my ( $slr, $symbol_name, @value ) = @_;
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];

    Marpa::R2::exception(
        "slr->alternative(): symbol name is undefined\n",
        "    The symbol name cannot be undefined\n"
    ) if not defined $symbol_name;

    my $slg        = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $g1_grammar = $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $g1_tracer  = $g1_grammar->tracer();
    my $symbol_id  = $g1_tracer->symbol_by_name($symbol_name);
    if ( not defined $symbol_id ) {
        Marpa::R2::exception(
            qq{slr->alternative(): symbol "$symbol_name" does not exist});
    }

    my $result = $thin_slr->g1_alternative( $symbol_id, @value );
    return 1 if $result == $Marpa::R2::Error::NONE;

    # The last two are perhaps unnecessary or arguable,
    # but they preserve compatibility with Marpa::XS
    return
        if $result == $Marpa::R2::Error::UNEXPECTED_TOKEN_ID
            || $result == $Marpa::R2::Error::NO_TOKEN_EXPECTED_HERE
            || $result == $Marpa::R2::Error::INACCESSIBLE_TOKEN;

    Marpa::R2::exception( qq{Problem reading symbol "$symbol_name": },
        ( scalar $g1_grammar->error() ) );
} ## end sub Marpa::R2::Scanless::R::lexeme_alternative

# Returns 0 on unthrown failure, current location on success
sub Marpa::R2::Scanless::R::lexeme_complete {
    my ( $slr, $start, $length ) = @_;
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    $slr->[Marpa::R2::Inner::Scanless::R::EVENTS] = [];
    my $return_value = $thin_slr->g1_lexeme_complete( $start, $length );
    Marpa::R2::Inner::Scanless::convert_libmarpa_events($slr);
    return $return_value;
} ## end sub Marpa::R2::Scanless::R::lexeme_complete

# Returns 0 on unthrown failure, current location on success,
# undef if lexeme not accepted.
sub Marpa::R2::Scanless::R::lexeme_read {
    my ( $slr, $symbol_name, $start, $length, @value ) = @_;
    return if not $slr->lexeme_alternative( $symbol_name, @value );
    return $slr->lexeme_complete( $start, $length );
}

sub Marpa::R2::Scanless::R::pause_span {
    my ($slr) = @_;
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    return $thin_slr->pause_span();
}

sub Marpa::R2::Scanless::R::pause_lexeme {
    my ($slr)    = @_;
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $grammar  = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thick_g1_grammar =
        $grammar->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $g1_tracer = $thick_g1_grammar->tracer();
    my $symbol    = $thin_slr->pause_lexeme();
    return if not defined $symbol;
    return $g1_tracer->symbol_name($symbol);
} ## end sub Marpa::R2::Scanless::R::pause_lexeme

sub Marpa::R2::Scanless::R::line_column {
    my ( $slr, $pos ) = @_;
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    if ( not defined $pos ) {
        my $stream = $thin_slr->stream();
        $pos = $stream->pos();
    }
    return $thin_slr->line_column($pos);
} ## end sub Marpa::R2::Scanless::R::line_column

# no return value documented
sub Marpa::R2::Scanless::R::activate {
    my ( $slr, $event_name, $activate ) = @_;
    my $slg      = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    $activate //= 1;
    my $thick_g1_recce =
        $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $thin_g1_recce = $thick_g1_recce->thin();
    my $event_symbol_ids_by_type =
        $slg
        ->[Marpa::R2::Inner::Scanless::G::SYMBOL_IDS_BY_EVENT_NAME_AND_TYPE]
        ->{$event_name};
    $thin_g1_recce->completion_symbol_activate( $_, $activate )
        for @{ $event_symbol_ids_by_type->{completion} };
    $thin_g1_recce->nulled_symbol_activate( $_, $activate )
        for @{ $event_symbol_ids_by_type->{nulled} };
    $thin_g1_recce->prediction_symbol_activate( $_, $activate )
        for @{ $event_symbol_ids_by_type->{prediction} };
    $thin_slr->lexeme_event_activate( $_, $activate )
        for @{ $event_symbol_ids_by_type->{lexeme} };
    return 1;
} ## end sub Marpa::R2::Scanless::R::activate

# Internal methods, not to be documented

sub Marpa::R2::Scanless::G::thick_g1_grammar {
    my ($slg) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
}

sub Marpa::R2::Scanless::R::thick_g1_recce {
    my ($slr) = @_;
    return $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
}

1;

# vim: expandtab shiftwidth=4:
