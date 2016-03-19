# Copyright 2015 Jeffrey Kegler
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

package Marpa::R2::Scanless::G;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '3.001_000';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::Scanless::G;

use Scalar::Util 'blessed';
use English qw( -no_match_vars );

# names of packages for strings
our $PACKAGE = 'Marpa::R2::Scanless::G';

sub Marpa::R2::Internal::Scanless::meta_grammar {

    my $meta_slg = bless [], 'Marpa::R2::Scanless::G';
    state $hashed_metag = Marpa::R2::Internal::MetaG::hashed_grammar();
    $meta_slg->[Marpa::R2::Internal::Scanless::G::TRACE_TERMINALS] = 0;
    Marpa::R2::Internal::Scanless::G::hash_to_runtime( $meta_slg,
        $hashed_metag,
        { bless_package => 'Marpa::R2::Internal::MetaAST_Nodes' } );

    my $thick_g1_grammar =
        $meta_slg->[Marpa::R2::Internal::Scanless::G::THICK_G1_GRAMMAR];
    my @mask_by_rule_id;
    $mask_by_rule_id[$_] = $thick_g1_grammar->_rule_mask($_)
        for $thick_g1_grammar->rule_ids();
    $meta_slg->[Marpa::R2::Internal::Scanless::G::MASK_BY_RULE_ID] =
        \@mask_by_rule_id;
    $meta_slg->[Marpa::R2::Internal::Scanless::G::TRACE_TERMINALS] = 0;

    return $meta_slg;

} ## end sub Marpa::R2::Internal::Scanless::meta_grammar

sub Marpa::R2::Scanless::G::new {
    my ( $class, @hash_ref_args ) = @_;

    my $slg = [];
    bless $slg, $class;

    my ($dsl, $g1_args) = Marpa::R2::Internal::Scanless::G::set ( $slg, 'new', @hash_ref_args );
    my $ast = Marpa::R2::Internal::MetaAST->new( $dsl );
    my $hashed_ast = $ast->ast_to_hash();
    Marpa::R2::Internal::Scanless::G::hash_to_runtime($slg, $hashed_ast, $g1_args);
    return $slg;
} ## end sub Marpa::R2::Scanless::G::new

sub Marpa::R2::Scanless::G::set {
    my ( $slg, @hash_ref_args ) = @_;
    Marpa::R2::Internal::Scanless::G::set ( $slg, 'set', @hash_ref_args );
    return $slg;
}

# The context flag indicates whether this ::set() is called directly by the user;
# is for the external constructor; or is for the internal ("meta") constructor.
# "Context" flags of this kind
# are much decried practice, and for good reason, but in this case
# I think it is justified.
# This logic really needs to be all in one place, and so a flag
# to trigger the minor differences needed by the various calling
# contexts is a small price to pay.
sub Marpa::R2::Internal::Scanless::G::set {
    my ( $slg, $method, @hash_ref_args ) = @_;

    # Other possible grammar options:
    # default_rank
    # inaccessible_ok
    # unproductive_ok
    # warnings

    state $copy_to_g1_args =
        { map { ( $_, 1 ); }
            qw(trace_file_handle action_object default_action bless_package) };
    state $set_method_args =
        { map { ( $_, 1 ); } qw(trace_file_handle trace_terminals) };
    state $new_method_args = {
        map { ( $_, 1 ); } qw(source trace_terminals), keys %{$copy_to_g1_args}
    };
    for my $args (@hash_ref_args) {
        my $ref_type = ref $args;
        if ( not $ref_type ) {
            Marpa::R2::exception( q{$slg->}
                    . $method
                    . qq{() expects args as ref to HASH; got non-reference instead}
            );
        } ## end if ( not $ref_type )
        if ( $ref_type ne 'HASH' ) {
            Marpa::R2::exception( q{$slg->}
                    . $method
                    . qq{() expects args as ref to HASH, got ref to $ref_type instead}
            );
        } ## end if ( $ref_type ne 'HASH' )
    } ## end for my $args (@hash_ref_args)

    my %flat_args = ();
    for my $hash_ref (@hash_ref_args) {
        ARG: for my $arg_name ( keys %{$hash_ref} ) {
            $flat_args{$arg_name} = $hash_ref->{$arg_name};
        }
    }

    my $ok_args = $set_method_args;
    $ok_args = $new_method_args if $method eq 'new';
    my @bad_args = grep { not $ok_args->{$_} } keys %flat_args;
    if ( scalar @bad_args ) {
        Marpa::R2::exception(
            q{Bad named argument(s) to $slg->}
                . $method
                . q{() method: }
                . join q{ },
            @bad_args
        );
    } ## end if ( scalar @bad_args )

    my $dsl;
    if ( $method eq 'new' ) {
        state $arg_name = 'source';
        $dsl = $flat_args{$arg_name};
        Marpa::R2::exception(
            qq{Marpa::R2::Scanless::G::new() called without a "$arg_name" argument}
        ) if not defined $dsl;
        my $ref_type = ref $dsl;
        if ( $ref_type ne 'SCALAR' ) {
            my $desc = $ref_type ? "a ref to $ref_type" : 'not a ref';
            Marpa::R2::exception(
                qq{'$arg_name' name argument to Marpa::R2::Scanless::G->new() is $desc\n},
                "  It should be a ref to a string\n"
            );
        } ## end if ( $ref_type ne 'SCALAR' )
        if ( not defined ${$dsl} ) {
            Marpa::R2::exception(
                qq{'$arg_name' name argument to Marpa::R2::Scanless::G->new() is a ref to a an undef\n},
                "  It should be a ref to a string\n"
            );
        } ## end if ( $ref_type ne 'SCALAR' )
    } ## end if ( $method eq 'new' )

    # A bit hack-ish, but some named args will be copies straight to a member of
    # the Scanless::G class, so this maps named args to the index of the array
    # that holds the members.
    state $copy_arg_to_index = {
        trace_file_handle => Marpa::R2::Internal::Scanless::G::TRACE_FILE_HANDLE,
        trace_terminals => Marpa::R2::Internal::Scanless::G::TRACE_TERMINALS
    };

    ARG: for my $arg_name ( keys %flat_args ) {
        my $index = $copy_arg_to_index->{$arg_name};
        next ARG if not defined $index;
        my $value = $flat_args{$arg_name};
        $slg->[$index] = $value;
    } ## end ARG: for my $arg_name ( keys %flat_args )

    # Normalize trace_terminals
    $slg->[Marpa::R2::Internal::Scanless::G::TRACE_TERMINALS] = 0
        if not Scalar::Util::looks_like_number(
        $slg->[Marpa::R2::Internal::Scanless::G::TRACE_TERMINALS] );

    # Trace file handle needs to be populated downwards
    if ( defined( my $trace_file_handle = $flat_args{trace_file_handle} ) ) {
        GRAMMAR:
        for my $naif_grammar (
            $slg->[Marpa::R2::Internal::Scanless::G::THICK_G1_GRAMMAR],
            @{ $slg->[Marpa::R2::Internal::Scanless::G::THICK_LEX_GRAMMARS] }
            )
        {
            next GRAMMAR if not defined $naif_grammar;
            $naif_grammar->set( { trace_file_handle => $trace_file_handle } );
        } ## end GRAMMAR: for my $naif_grammar ( $slg->[...])
    } ## end if ( defined( my $trace_file_handle = $flat_args{...}))

    if ( $method eq 'new' ) {

        # Prune flat args of all those named args which are NOT to be copied
        # into the NAIF recce args
        for my $arg_name ( keys %flat_args ) {
            delete $flat_args{$arg_name}
                if not $copy_to_g1_args->{$arg_name};
        }

        # trace file handle must always be defined
        $slg->[Marpa::R2::Internal::Scanless::G::TRACE_FILE_HANDLE] //= \*STDERR;

        return ($dsl, \%flat_args);
    } ## end if ( $method eq 'new' )

    return;

} ## end sub Marpa::R2::Internal::Scanless::G::set

sub Marpa::R2::Internal::Scanless::G::hash_to_runtime {
    my ( $slg, $hashed_source, $g1_args ) = @_;

    my $trace_terminals =
        $slg->[Marpa::R2::Internal::Scanless::G::TRACE_TERMINALS];

    # Pre-lexer G1 processing

    my $start_lhs = $hashed_source->{'start_lhs'}
        // $hashed_source->{'first_lhs'};
    Marpa::R2::exception('No rules in SLIF grammar')
        if not defined $start_lhs;
    Marpa::R2::Internal::MetaAST::start_rule_create( $hashed_source,
        $start_lhs );

    $slg->[Marpa::R2::Internal::Scanless::G::CACHE_RULEIDS_BY_LHS_NAME] = {};
    $slg->[Marpa::R2::Internal::Scanless::G::DEFAULT_G1_START_ACTION] =
        $hashed_source->{'default_g1_start_action'};

    my $trace_fh =
        $slg->[Marpa::R2::Internal::Scanless::G::TRACE_FILE_HANDLE] =
        $g1_args->{trace_file_handle} // \*STDERR;

    my $if_inaccessible_default =
        $hashed_source->{defaults}->{if_inaccessible} // 'warn';

    # Prepare the arguments for the G1 grammar
    $g1_args->{rules}   = $hashed_source->{rules}->{G1};
    $g1_args->{symbols} = $hashed_source->{symbols}->{G1};
    state $g1_target_symbol = '[:start]';
    $g1_args->{start} = $g1_target_symbol;
    $g1_args->{'_internal_'} =
        { 'if_inaccessible' => $if_inaccessible_default };

    my $thick_g1_grammar = Marpa::R2::Grammar->new($g1_args);
    my $g1_tracer        = $thick_g1_grammar->tracer();
    my $g1_thin          = $g1_tracer->grammar();

    my $symbol_ids_by_event_name_and_type = {};
    $slg->[
        Marpa::R2::Internal::Scanless::G::SYMBOL_IDS_BY_EVENT_NAME_AND_TYPE]
        = $symbol_ids_by_event_name_and_type;

    my $completion_events_by_name = $hashed_source->{completion_events};
    my $completion_events_by_id =
        $slg->[Marpa::R2::Internal::Scanless::G::COMPLETION_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$completion_events_by_name} ) {
        my ( $event_name, $is_active ) =
            @{ $completion_events_by_name->{$symbol_name} };
        my $symbol_id = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "Completion event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_completion_event_set( $symbol_id, 1 );
        $g1_thin->completion_symbol_activate( $symbol_id, 0 )
            if not $is_active;
        $slg->[Marpa::R2::Internal::Scanless::G::COMPLETION_EVENT_BY_ID]
            ->[$symbol_id] = $event_name;
        push
            @{ $symbol_ids_by_event_name_and_type->{$event_name}->{completion}
            }, $symbol_id;
    } ## end for my $symbol_name ( keys %{$completion_events_by_name...})

    my $nulled_events_by_name = $hashed_source->{nulled_events};
    my $nulled_events_by_id =
        $slg->[Marpa::R2::Internal::Scanless::G::NULLED_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$nulled_events_by_name} ) {
        my ( $event_name, $is_active ) =
            @{ $nulled_events_by_name->{$symbol_name} };
        my $symbol_id = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "nulled event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_nulled_event_set( $symbol_id, 1 );
        $g1_thin->nulled_symbol_activate( $symbol_id, 0 ) if not $is_active;
        $slg->[Marpa::R2::Internal::Scanless::G::NULLED_EVENT_BY_ID]
            ->[$symbol_id] = $event_name;
        push @{ $symbol_ids_by_event_name_and_type->{$event_name}->{nulled} },
            $symbol_id;
    } ## end for my $symbol_name ( keys %{$nulled_events_by_name} )

    my $prediction_events_by_name = $hashed_source->{prediction_events};
    my $prediction_events_by_id =
        $slg->[Marpa::R2::Internal::Scanless::G::PREDICTION_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$prediction_events_by_name} ) {
        my ( $event_name, $is_active ) =
            @{ $prediction_events_by_name->{$symbol_name} };
        my $symbol_id = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "prediction event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_prediction_event_set( $symbol_id, 1 );
        $g1_thin->prediction_symbol_activate( $symbol_id, 0 )
            if not $is_active;
        $slg->[Marpa::R2::Internal::Scanless::G::PREDICTION_EVENT_BY_ID]
            ->[$symbol_id] = $event_name;
        push
            @{ $symbol_ids_by_event_name_and_type->{$event_name}->{prediction}
            }, $symbol_id;
    } ## end for my $symbol_name ( keys %{$prediction_events_by_name...})

    my $lexeme_events_by_id =
        $slg->[Marpa::R2::Internal::Scanless::G::LEXEME_EVENT_BY_ID] = [];

    if (defined(
            my $precompute_error =
                Marpa::R2::Internal::Grammar::slif_precompute(
                $thick_g1_grammar)
        )
        )
    {
        if ( $precompute_error == $Marpa::R2::Error::UNPRODUCTIVE_START ) {

            # Maybe someday improve this by finding the start rule and showing
            # its RHS -- for now it is clear enough
            Marpa::R2::exception(qq{Unproductive start symbol});
        } ## end if ( $precompute_error == ...)
        Marpa::R2::exception(
            'Internal errror: unnkown precompute error code ',
            $precompute_error );
    } ## end if ( defined( my $precompute_error = ...))

    # Find out the list of lexemes according to G1
    my %g1_id_by_lexeme_name = ();
    SYMBOL: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id() ) {

        # Not a lexeme, according to G1
        next SYMBOL if not $g1_thin->symbol_is_terminal($symbol_id);

        my $symbol_name = $g1_tracer->symbol_name($symbol_id);
        $g1_id_by_lexeme_name{$symbol_name} = $symbol_id;

    } ## end SYMBOL: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id(...))

    # A first phase of applying defaults
    my $discard_default_adverbs = $hashed_source->{discard_default_adverbs};
    my $lexeme_declarations     = $hashed_source->{lexeme_declarations};
    my $lexeme_default_adverbs  = $hashed_source->{lexeme_default_adverbs};
    my $latm_default_value      = $lexeme_default_adverbs->{latm} // 0;

    # Current lexeme data is spread out in many places.
    # Change so that it all resides in this hash, indexed by
    # name
    my %lexeme_data = ();

    # Determine "latm" status
    LEXEME: for my $lexeme_name ( keys %g1_id_by_lexeme_name ) {
        my $declarations = $lexeme_declarations->{$lexeme_name};
        my $latm_value = $declarations->{latm} // $latm_default_value;
        $lexeme_data{$lexeme_name}{latm} = $latm_value;
    }

    # Lexers

    my $lexer_id   = 0;
    my $lexer_name = 'L0';

    my %lexer_id_by_name                    = ();
    my %thick_grammar_by_lexer_name         = ();
    my @discard_event_by_lexer_rule_id      = ();
    my %lexer_and_rule_to_g1_lexeme         = ();
    my %character_class_table_by_lexer_name = ();
    state $lex_start_symbol_name = '[:start_lex]';
    state $discard_symbol_name   = '[:discard]';

    my $lexer_rules = $hashed_source->{rules}->{$lexer_name};
    my $character_class_hash = $hashed_source->{character_classes};
    my $lexer_symbols = $hashed_source->{symbols}->{'L'};

    # If no lexer rules, fake a lexer
    # Fake a lexer -- it discards symbols in character classes which
    # never matches
    if ( not $lexer_rules ) {
        $character_class_hash = { '[[^\\d\\D]]' => [ '[^\\d\\D]', '' ] };
        $lexer_rules = [
            {   'rhs'         => [ '[[^\\d\\D]]' ],
                'lhs'         => '[:discard]',
                'symbol_as_event' => '[^\\d\\D]',
                'description' => 'Discard rule for <[[^\\d\\D]]>'
            },
        ];
        $lexer_symbols = {
            '[:discard]' => {
                'display_form' => ':discard',
                'description'  => 'Internal LHS for lexer "L0" discard'
            },
            '[[^\\d\\D]]' => {
                'dsl_form'     => '[^\\d\\D]',
                'display_form' => '[^\\d\\D]',
                'description'  => 'Character class: [^\\d\\D]'
            }
        };
    } ## end if ( not $lexer_rules )

    my %lex_lhs           = ();
    my %lex_rhs           = ();
    my %lex_separator     = ();
    my %lexer_rule_by_tag = ();

    my $rule_tag = 'rule0';
    for my $lex_rule ( @{$lexer_rules} ) {
        $lex_rule->{tag} = ++$rule_tag;
        my %lex_rule_copy = %{$lex_rule};
        $lexer_rule_by_tag{$rule_tag} = \%lex_rule_copy;
        delete $lex_rule->{event};
        delete $lex_rule->{symbol_as_event};
        $lex_lhs{ $lex_rule->{lhs} } = 1;
        $lex_rhs{$_} = 1 for @{ $lex_rule->{rhs} };
        if ( defined( my $separator = $lex_rule->{separator} ) ) {
            $lex_separator{$separator} = 1;
        }
    } ## end for my $lex_rule ( @{$lexer_rules} )

    my %this_lexer_symbols = ();
    SYMBOL:
    for my $symbol_name ( ( keys %lex_lhs ), ( keys %lex_rhs ),
        ( keys %lex_separator ) )
    {
        my $symbol_data = $lexer_symbols->{$symbol_name};
        $this_lexer_symbols{$symbol_name} = $symbol_data
            if defined $symbol_data;
    } ## end SYMBOL: for my $symbol_name ( ( keys %lex_lhs ), ( keys %lex_rhs...))

    my %is_lexeme_in_this_lexer = map { $_ => 1 }
        grep { not $lex_rhs{$_} and not $lex_separator{$_} }
        keys %lex_lhs;

    my @lex_lexeme_names = keys %is_lexeme_in_this_lexer;

    Marpa::R2::exception( "No lexemes in lexer: $lexer_name\n",
        "  An SLIF grammar must have at least one lexeme\n" )
        if not scalar @lex_lexeme_names;

    # Do I need this?
    my @unproductive =
        map {"<$_>"}
        grep { not $lex_lhs{$_} and not $_ =~ /\A \[\[ /xms }
        ( keys %lex_rhs, keys %lex_separator );
    if (@unproductive) {
        Marpa::R2::exception( 'Unproductive lexical symbols: ',
            join q{ }, @unproductive );
    }

    $this_lexer_symbols{$lex_start_symbol_name}->{display_form} =
        ':start_lex';
    $this_lexer_symbols{$lex_start_symbol_name}->{description} =
        'Internal L0 (lexical) start symbol';
    push @{$lexer_rules}, map {
        ;
        {   description => "Internal lexical start rule for <$_>",
            lhs         => $lex_start_symbol_name,
            rhs         => [$_]
        }
    } sort keys %is_lexeme_in_this_lexer;

    # Prepare the arguments for the lex grammar
    my %lex_args = ();
    $lex_args{trace_file_handle} = $trace_fh;
    $lex_args{start}             = $lex_start_symbol_name;
    $lex_args{'_internal_'} =
        { 'if_inaccessible' => $if_inaccessible_default };
    $lex_args{rules}   = $lexer_rules;
    $lex_args{symbols} = \%this_lexer_symbols;

    # Create the thick lex grammar
    my $lex_grammar = Marpa::R2::Grammar->new( \%lex_args );
    $thick_grammar_by_lexer_name{$lexer_name} = $lex_grammar;
    my $lex_tracer = $lex_grammar->tracer();
    my $lex_thin   = $lex_tracer->grammar();

    my $lex_discard_symbol_id =
        $lex_tracer->symbol_by_name($discard_symbol_name) // -1;
    my @lex_lexeme_to_g1_symbol;
    $lex_lexeme_to_g1_symbol[$_] = -1 for 0 .. $g1_thin->highest_symbol_id();

    LEXEME_NAME: for my $lexeme_name (@lex_lexeme_names) {
        next LEXEME_NAME if $lexeme_name eq $discard_symbol_name;
        next LEXEME_NAME if $lexeme_name eq $lex_start_symbol_name;
        my $g1_symbol_id = $g1_id_by_lexeme_name{$lexeme_name};
        if ( not defined $g1_symbol_id ) {
            Marpa::R2::exception(
                "A lexeme in lexer $lexer_name is not a lexeme in G1: $lexeme_name"
            );
        }
        if ( not $g1_thin->symbol_is_accessible($g1_symbol_id) ) {
            my $message =
                "A lexeme in lexer $lexer_name is not accessible from the G1 start symbol: $lexeme_name";
            say {$trace_fh} $message
                if $if_inaccessible_default eq 'warn';
            Marpa::R2::exception($message)
                if $if_inaccessible_default eq 'fatal';
        } ## end if ( not $g1_thin->symbol_is_accessible($g1_symbol_id...))
        my $lex_symbol_id = $lex_tracer->symbol_by_name($lexeme_name);
        $lexeme_data{$lexeme_name}{lexers}{$lexer_name}{'id'} =
            $lex_symbol_id;
        $lex_lexeme_to_g1_symbol[$lex_symbol_id] = $g1_symbol_id;
    } ## end LEXEME_NAME: for my $lexeme_name (@lex_lexeme_names)

    my @lex_rule_to_g1_lexeme;
    my $lex_start_symbol_id =
        $lex_tracer->symbol_by_name($lex_start_symbol_name);
    RULE_ID: for my $rule_id ( 0 .. $lex_thin->highest_rule_id() ) {
        my $lhs_id = $lex_thin->rule_lhs($rule_id);
        if ( $lhs_id == $lex_discard_symbol_id ) {
            $lex_rule_to_g1_lexeme[$rule_id] = -2;
            next RULE_ID;
        }
        if ( $lhs_id != $lex_start_symbol_id ) {
            $lex_rule_to_g1_lexeme[$rule_id] = -1;
            next RULE_ID;
        }
        my $lexer_lexeme_id = $lex_thin->rule_rhs( $rule_id, 0 );
        if ( $lexer_lexeme_id == $lex_discard_symbol_id ) {
            $lex_rule_to_g1_lexeme[$rule_id] = -1;
            next RULE_ID;
        }
        my $lexeme_id = $lex_lexeme_to_g1_symbol[$lexer_lexeme_id] // -1;
        $lex_rule_to_g1_lexeme[$rule_id] = $lexeme_id;
        next RULE_ID if $lexeme_id < 0;
        my $lexeme_name = $g1_tracer->symbol_name($lexeme_id);

        # If 1 is the default, we don't need an assertion
        next RULE_ID if not $lexeme_data{$lexeme_name}{latm};

        my $assertion_id =
            $lexeme_data{$lexeme_name}{lexers}{$lexer_name}{'assertion'};
        if ( not defined $assertion_id ) {
            $assertion_id = $lex_thin->zwa_new(0);

            if ( $trace_terminals >= 2 ) {
                say {$trace_fh} "Assertion $assertion_id defaults to 0";
            }

            $lexeme_data{$lexeme_name}{lexers}{$lexer_name}{'assertion'} =
                $assertion_id;
        } ## end if ( not defined $assertion_id )
        $lex_thin->zwa_place( $assertion_id, $rule_id, 0 );
        if ( $trace_terminals >= 2 ) {
            say {$trace_fh}
                "Assertion $assertion_id applied to $lexer_name rule ",
                slg_rule_show( $slg, $rule_id, $lex_grammar );
        }
    } ## end RULE_ID: for my $rule_id ( 0 .. $lex_thin->highest_rule_id() )

    Marpa::R2::Internal::Grammar::slif_precompute($lex_grammar);

    my @class_table          = ();

    CLASS_SYMBOL:
    for my $class_symbol ( sort keys %{$character_class_hash} ) {
        my $symbol_id = $lex_tracer->symbol_by_name($class_symbol);
        next CLASS_SYMBOL if not defined $symbol_id;
        my $cc_components = $character_class_hash->{$class_symbol};
        my ( $compiled_re, $error ) =
            Marpa::R2::Internal::MetaAST::char_class_to_re($cc_components);
        if ( not $compiled_re ) {
            $error =~ s/^/  /gxms;    #indent all lines
            Marpa::R2::exception(
                "Failed belatedly to evaluate character class\n", $error );
        }
        push @class_table, [ $symbol_id, $compiled_re ];
    } ## end CLASS_SYMBOL: for my $class_symbol ( sort keys %{...})
    $character_class_table_by_lexer_name{$lexer_name} = \@class_table;

    $lexer_and_rule_to_g1_lexeme{$lexer_name} = \@lex_rule_to_g1_lexeme;

    # Apply defaults to determine the discard event for every
    # rule id of the lexer.

    my $default_discard_event = $discard_default_adverbs->{event};
    RULE_ID: for my $rule_id ( 0 .. $lex_thin->highest_rule_id() ) {
        my $tag = $lex_grammar->tag($rule_id);
        next RULE_ID if not defined $tag;
        my $event;
        FIND_EVENT: {
            $event = $lexer_rule_by_tag{$tag}->{event};
            last FIND_EVENT if defined $event;
            my $lhs_id = $lex_thin->rule_lhs($rule_id);
            last FIND_EVENT if $lhs_id != $lex_discard_symbol_id;
            $event = $default_discard_event;
        } ## end FIND_EVENT:
        next RULE_ID if not defined $event;

        my ( $event_name, $event_starts_active ) = @{$event};
        if ( $event_name eq q{'symbol} ) {
            my @event = (
                $lexer_rule_by_tag{$tag}->{symbol_as_event},
                $event_starts_active
            );
            $discard_event_by_lexer_rule_id[$rule_id] = \@event;
            next RULE_ID;
        } ## end if ( $event_name eq q{'symbol} )
        if ( ( substr $event_name, 0, 1 ) ne q{'} ) {
            $discard_event_by_lexer_rule_id[$rule_id] = $event;
            next RULE_ID;
        }
        Marpa::R2::exception(
            qq{Discard event has unknown name: "$event_name"}
        );

    } ## end RULE_ID: for my $rule_id ( 0 .. $lex_thin->highest_rule_id() )

    # Post-lexer G1 processing

    my $thick_L0 = $thick_grammar_by_lexer_name{'L0'};
    my $thin_L0  = $thick_L0->[Marpa::R2::Internal::Grammar::C];
    my $thin_slg = $slg->[Marpa::R2::Internal::Scanless::G::C] =
        Marpa::R2::Thin::SLG->new( $thin_L0, $g1_tracer->grammar() );

    # Relies on default lexer being given number zero
    $lexer_id_by_name{'L0'} = 0;

    LEXEME: for my $lexeme_name ( keys %g1_id_by_lexeme_name ) {
        Marpa::R2::exception(
            "A lexeme in G1 is not a lexeme in any of the lexers: $lexeme_name"
        ) if not defined $lexeme_data{$lexeme_name}{'lexers'};
    }

    # At this point we know which symbols are lexemes.
    # So now let's check for inconsistencies

    # Check for lexeme declarations for things which are not lexemes
    for my $lexeme_name ( keys %{$lexeme_declarations} ) {
        Marpa::R2::exception(
            "Symbol <$lexeme_name> is declared as a lexeme, but it is not used as one.\n"
        ) if not defined $g1_id_by_lexeme_name{$lexeme_name};
    }

    # Now that we know the lexemes, check attempts to defined a
    # completion or a nulled event for one
    for my $symbol_name ( keys %{$completion_events_by_name} ) {
        Marpa::R2::exception(
            "A completion event is declared for <$symbol_name>, but it is a lexeme.\n",
            "  Completion events are only valid for symbols on the LHS of G1 rules.\n"
        ) if defined $g1_id_by_lexeme_name{$symbol_name};
    } ## end for my $symbol_name ( keys %{$completion_events_by_name...})

    for my $symbol_name ( keys %{$nulled_events_by_name} ) {
        Marpa::R2::exception(
            "A nulled event is declared for <$symbol_name>, but it is a G1 lexeme.\n",
            "  nulled events are only valid for symbols on the LHS of G1 rules.\n"
        ) if defined $g1_id_by_lexeme_name{$symbol_name};
    } ## end for my $symbol_name ( keys %{$nulled_events_by_name} )

    # Mark the lexemes, and set their data
    # Now that we have created the SLG, we can set the latm value,
    # already determined above.
    LEXEME: for my $lexeme_name ( keys %g1_id_by_lexeme_name ) {
        my $g1_lexeme_id = $g1_id_by_lexeme_name{$lexeme_name};
        my $declarations = $lexeme_declarations->{$lexeme_name};
        my $priority     = $declarations->{priority} // 0;
        $thin_slg->g1_lexeme_set( $g1_lexeme_id, $priority );
        my $latm_value = $lexeme_data{$lexeme_name}{latm} // 0;
        $thin_slg->g1_lexeme_latm_set( $g1_lexeme_id, $latm_value );
        my $pause_value = $declarations->{pause};
        if ( defined $pause_value ) {
            $thin_slg->g1_lexeme_pause_set( $g1_lexeme_id, $pause_value );
            my $is_active = 1;

            if ( defined( my $event_data = $declarations->{'event'} ) ) {
                my $event_name;
                ( $event_name, $is_active ) = @{$event_data};
                $lexeme_events_by_id->[$g1_lexeme_id] = $event_name;
                push @{ $symbol_ids_by_event_name_and_type->{$event_name}
                        ->{lexeme} }, $g1_lexeme_id;
            } ## end if ( defined( my $event_data = $declarations->{'event'...}))

            $thin_slg->g1_lexeme_pause_activate( $g1_lexeme_id, $is_active );
        } ## end if ( defined $pause_value )

    } ## end LEXEME: for my $lexeme_name ( keys %g1_id_by_lexeme_name )

    # Second phase of lexer processing
    my $lexer_rule_to_g1_lexeme = $lexer_and_rule_to_g1_lexeme{$lexer_name};

    RULE_ID: for my $lexer_rule_id ( 0 .. $#{$lexer_rule_to_g1_lexeme} ) {
        my $g1_lexeme_id = $lexer_rule_to_g1_lexeme->[$lexer_rule_id];
        my $lexeme_name  = $g1_tracer->symbol_name($g1_lexeme_id);
        my $assertion_id =
            $lexeme_data{$lexeme_name}{lexers}{$lexer_name}{'assertion'}
            // -1;
        $thin_slg->lexer_rule_to_g1_lexeme_set( $lexer_rule_id,
            $g1_lexeme_id, $assertion_id );
        my $discard_event = $discard_event_by_lexer_rule_id[$lexer_rule_id];
        if ( defined $discard_event ) {
            my ( $event_name, $is_active ) = @{$discard_event};
            $slg->[
                Marpa::R2::Internal::Scanless::G::DISCARD_EVENT_BY_LEXER_RULE
            ]->[$lexer_rule_id] = $event_name;
            push @{ $symbol_ids_by_event_name_and_type->{$event_name}
                    ->{discard} }, $lexer_rule_id;
            $thin_slg->discard_event_set( $lexer_rule_id, 1 );
            $thin_slg->discard_event_activate( $lexer_rule_id, 1 )
                if $is_active;
        } ## end if ( defined $discard_event )
    } ## end RULE_ID: for my $lexer_rule_id ( 0 .. $#{$lexer_rule_to_g1_lexeme...})

    # Second phase of G1 processing

    $thin_slg->precompute();
    $slg->[Marpa::R2::Internal::Scanless::G::THICK_G1_GRAMMAR] =
        $thick_g1_grammar;

    # More lexer processing
    # Determine events by lexer rule, applying the defaults

    {
        my $character_class_table =
            $character_class_table_by_lexer_name{$lexer_name};
        $slg->[Marpa::R2::Internal::Scanless::G::CHARACTER_CLASS_TABLES]
            ->[$lexer_id] = $character_class_table;
        $slg->[Marpa::R2::Internal::Scanless::G::THICK_LEX_GRAMMARS]
            ->[$lexer_id] = $thick_grammar_by_lexer_name{$lexer_name};
    }

    # This section violates the NAIF interface, directly changing some
    # of its internal structures.
    #
    # Some lexeme default adverbs are applied in earlier phases.
    #
    APPLY_DEFAULT_LEXEME_ADVERBS: {
        last APPLY_DEFAULT_LEXEME_ADVERBS if not $lexeme_default_adverbs;

        my $action = $lexeme_default_adverbs->{action};
        my $g1_symbols =
            $thick_g1_grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
        LEXEME:
        for my $lexeme_name ( keys %g1_id_by_lexeme_name ) {
            my $g1_lexeme_id = $g1_id_by_lexeme_name{$lexeme_name};
            my $g1_symbol    = $g1_symbols->[$g1_lexeme_id];
            next LEXEME if $lexeme_name =~ m/ \] \z/xms;
            $g1_symbol->[Marpa::R2::Internal::Symbol::LEXEME_SEMANTICS] //=
                $action;
        } ## end LEXEME: for my $lexeme_name ( keys %g1_id_by_lexeme_name )

        my $blessing = $lexeme_default_adverbs->{bless};
        last APPLY_DEFAULT_LEXEME_ADVERBS if not $blessing;
        last APPLY_DEFAULT_LEXEME_ADVERBS if $blessing eq '::undef';

        LEXEME:
        for my $lexeme_name ( keys %g1_id_by_lexeme_name ) {
            my $g1_lexeme_id = $g1_id_by_lexeme_name{$lexeme_name};
            my $g1_symbol    = $g1_symbols->[$g1_lexeme_id];
            next LEXEME if $lexeme_name =~ m/ \] \z/xms;
            if ( $blessing eq '::name' ) {
                if ( $lexeme_name =~ / [^ [:alnum:]] /xms ) {
                    Marpa::R2::exception(
                        qq{Lexeme blessing by '::name' only allowed if lexeme name is whitespace and alphanumerics\n},
                        qq{   Problematic lexeme was <$lexeme_name>\n}
                    );
                } ## end if ( $lexeme_name =~ / [^ [:alnum:]] /xms )
                my $blessing_by_name = $lexeme_name;
                $blessing_by_name =~ s/[ ]/_/gxms;
                $g1_symbol->[Marpa::R2::Internal::Symbol::BLESSING] //=
                    $blessing_by_name;
                next LEXEME;
            } ## end if ( $blessing eq '::name' )
            if ( $blessing =~ / [\W] /xms ) {
                Marpa::R2::exception(
                    qq{Blessing lexeme as '$blessing' is not allowed\n},
                    qq{   Problematic lexeme was <$lexeme_name>\n}
                );
            } ## end if ( $blessing =~ / [\W] /xms )
            $g1_symbol->[Marpa::R2::Internal::Symbol::BLESSING] //= $blessing;
        } ## end LEXEME: for my $lexeme_name ( keys %g1_id_by_lexeme_name )

    } ## end APPLY_DEFAULT_LEXEME_ADVERBS:

    return $slg;

} ## end sub Marpa::R2::Internal::Scanless::G::hash_to_runtime

sub thick_subgrammar_by_name {
    my ( $slg, $subgrammar ) = @_;

    # Allow G0 as legacy synonym for L0
    state $grammar_names = { 'G0' => 1, 'G1' => 1, 'L0' => 1 };
    $subgrammar //= 'G1';

    Marpa::R2::exception(qq{No lexer named "$subgrammar"})
        if not defined $grammar_names->{$subgrammar};

    return $slg->[Marpa::R2::Internal::Scanless::G::THICK_G1_GRAMMAR]
        if $subgrammar eq 'G1';

    return $slg->[Marpa::R2::Internal::Scanless::G::THICK_LEX_GRAMMARS]
        ->[0];
} ## end sub thick_subgrammar_by_name

sub Marpa::R2::Scanless::G::start_symbol_id {
    my ( $slg, $rule_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name( $slg, $subgrammar )->start_symbol();
}

sub Marpa::R2::Scanless::G::rule_name {
    my ( $slg, $rule_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name( $slg, $subgrammar )->rule_name($rule_id);
}

sub Marpa::R2::Scanless::G::rule_expand {
    my ( $slg, $rule_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name( $slg, $subgrammar )->tracer()
        ->rule_expand($rule_id);
}

sub Marpa::R2::Scanless::G::symbol_name {
    my ( $slg, $symbol_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)->tracer()
        ->symbol_name($symbol_id);
}

sub Marpa::R2::Scanless::G::symbol_display_form {
    my ( $slg, $symbol_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name( $slg, $subgrammar )
        ->symbol_in_display_form($symbol_id);
}

sub Marpa::R2::Scanless::G::symbol_dsl_form {
    my ( $slg, $symbol_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name( $slg, $subgrammar )
        ->symbol_dsl_form($symbol_id);
}

sub Marpa::R2::Scanless::G::symbol_description {
    my ( $slg, $symbol_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)
        ->symbol_description($symbol_id);
}

sub Marpa::R2::Scanless::G::rule_show
{
    my ( $slg, $rule_id, $subgrammar) = @_;
    return slg_rule_show($slg, $rule_id, thick_subgrammar_by_name($slg, $subgrammar));
}

sub slg_rule_show {
    my ( $slg, $rule_id, $subgrammar ) = @_;
    my $tracer       = $subgrammar->tracer();
    my $subgrammar_c = $subgrammar->[Marpa::R2::Internal::Grammar::C];
    my @symbol_ids   = $tracer->rule_expand($rule_id);
    return if not scalar @symbol_ids;
    my ( $lhs, @rhs ) =
        map { $subgrammar->symbol_in_display_form($_) } @symbol_ids;
    my $minimum    = $subgrammar_c->sequence_min($rule_id);
    my @quantifier = ();

    if ( defined $minimum ) {
        @quantifier = ( $minimum <= 0 ? q{*} : q{+} );
    }
    return join q{ }, $lhs, q{::=}, @rhs, @quantifier;
} ## end sub slg_rule_show

sub Marpa::R2::Scanless::G::show_rules {
    my ( $slg, $verbose, $subgrammar ) = @_;
    my $text     = q{};
    $verbose    //= 0;
    $subgrammar //= 'G1';

    my $thick_grammar = thick_subgrammar_by_name($slg, $subgrammar);

    my $rules     = $thick_grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $grammar_c = $thick_grammar->[Marpa::R2::Internal::Grammar::C];

    for my $rule ( @{$rules} ) {
        my $rule_id = $rule->[Marpa::R2::Internal::Rule::ID];

        my $minimum = $grammar_c->sequence_min($rule_id);
        my @quantifier =
            defined $minimum ? $minimum <= 0 ? (q{*}) : (q{+}) : ();
        my $lhs_id      = $grammar_c->rule_lhs($rule_id);
        my $rule_length = $grammar_c->rule_length($rule_id);
        my @rhs_ids =
            map { $grammar_c->rule_rhs( $rule_id, $_ ) }
            ( 0 .. $rule_length - 1 );
        $text .= join q{ }, $subgrammar, "R$rule_id",
            $thick_grammar->symbol_in_display_form($lhs_id),
            '::=',
            ( map { $thick_grammar->symbol_in_display_form($_) } @rhs_ids ),
            @quantifier;
        $text .= "\n";

        if ( $verbose >= 2 ) {

            my $description = $rule->[Marpa::R2::Internal::Rule::DESCRIPTION];
            $text .= "  $description\n" if $description;
            my @comment = ();
            $grammar_c->rule_length($rule_id) == 0
                and push @comment, 'empty';
            $thick_grammar->rule_is_used($rule_id)
                or push @comment, '!used';
            $grammar_c->rule_is_productive($rule_id)
                or push @comment, 'unproductive';
            $grammar_c->rule_is_accessible($rule_id)
                or push @comment, 'inaccessible';
            $rule->[Marpa::R2::Internal::Rule::DISCARD_SEPARATION]
                and push @comment, 'discard_sep';

            if (@comment) {
                $text .= q{  } . ( join q{ }, q{/*}, @comment, q{*/} ) . "\n";
            }

            $text .= "  Symbol IDs: <$lhs_id> ::= "
                . ( join q{ }, map {"<$_>"} @rhs_ids ) . "\n";

        } ## end if ( $verbose >= 2 )

        if ( $verbose >= 3 ) {

            my $tracer = $thick_grammar->tracer();

            $text
                .= "  Internal symbols: <"
                . $tracer->symbol_name($lhs_id)
                . q{> ::= }
                . (
                join q{ },
                map { '<' . $tracer->symbol_name($_) . '>' } @rhs_ids
                ) . "\n";

        } ## end if ( $verbose >= 3 )

    } ## end for my $rule ( @{$rules} )

    return $text;
} ## end sub Marpa::R2::Scanless::G::show_rules

sub Marpa::R2::Scanless::G::show_symbols {
    my ( $slg, $verbose, $subgrammar ) = @_;
    my $text = q{};
    $verbose    //= 0;
    $subgrammar //= 'G1';

    my $thick_grammar = thick_subgrammar_by_name($slg, $subgrammar);

    my $symbols   = $thick_grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $grammar_c = $thick_grammar->[Marpa::R2::Internal::Grammar::C];

    for my $symbol ( @{$symbols} ) {
        my $symbol_id = $symbol->[Marpa::R2::Internal::Symbol::ID];

        $text .= join q{ }, $subgrammar, "S$symbol_id",
            $thick_grammar->symbol_in_display_form($symbol_id);

        my $description = $symbol->[Marpa::R2::Internal::Symbol::DESCRIPTION];
        if ($description) {
            $text .= " -- $description";
        }
        $text .= "\n";

        if ( $verbose >= 2 ) {

            my @tag_list = ();
            $grammar_c->symbol_is_productive($symbol_id)
                or push @tag_list, 'unproductive';
            $grammar_c->symbol_is_accessible($symbol_id)
                or push @tag_list, 'inaccessible';
            $grammar_c->symbol_is_nulling($symbol_id)
                and push @tag_list, 'nulling';
            $grammar_c->symbol_is_terminal($symbol_id)
                and push @tag_list, 'terminal';

            if (@tag_list) {
                $text
                    .= q{  } . ( join q{ }, q{/*}, @tag_list, q{*/} ) . "\n";
            }

            my $tracer = $thick_grammar->tracer();
            $text .= "  Internal name: <"
                . $tracer->symbol_name($symbol_id) . qq{>\n};

        } ## end if ( $verbose >= 2 )

        if ( $verbose >= 3 ) {

            my $dsl_form = $symbol->[Marpa::R2::Internal::Symbol::DSL_FORM];
            if ($dsl_form) { $text .= qq{  SLIF name: $dsl_form\n}; }

        } ## end if ( $verbose >= 3 )

    } ## end for my $symbol ( @{$symbols} )

    return $text;
} ## end sub Marpa::R2::Scanless::G::show_symbols

sub Marpa::R2::Scanless::G::show_dotted_rule {
    my ( $slg, $rule_id, $dot_position ) = @_;
    my $grammar =  $slg->[Marpa::R2::Internal::Scanless::G::THICK_G1_GRAMMAR];
    my $tracer  = $grammar->tracer();
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my ( $lhs, @rhs ) =
    map { $grammar->symbol_in_display_form($_) } $tracer->rule_expand($rule_id);
    my $rhs_length = scalar @rhs;

    my $minimum = $grammar_c->sequence_min($rule_id);
    my @quantifier = ();
    if (defined $minimum) {
        @quantifier = ($minimum <= 0 ? q{*} : q{+} );
    }
    $dot_position = 0 if $dot_position < 0;
    if ($dot_position < $rhs_length) {
        splice @rhs, $dot_position, 0, q{.};
        return join q{ }, $lhs, q{->}, @rhs, @quantifier;
    } else {
        return join q{ }, $lhs, q{->}, @rhs, @quantifier, q{.};
    }
} ## end sub Marpa::R2::Grammar::show_dotted_rule

sub Marpa::R2::Scanless::G::rule {
    my ( $slg, @args ) = @_;
    return $slg->[Marpa::R2::Internal::Scanless::G::THICK_G1_GRAMMAR]
        ->rule(@args);
}

sub Marpa::R2::Scanless::G::rule_ids {
    my ($slg, $subgrammar) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)->rule_ids();
}

sub Marpa::R2::Scanless::G::symbol_ids {
    my ($slg, $subgrammar) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)->symbol_ids();
}

sub Marpa::R2::Scanless::G::g1_rule_ids {
    my ($slg) = @_;
    return $slg->rule_ids();
}

sub Marpa::R2::Scanless::G::g0_rule_ids {
    my ($slg) = @_;
    return $slg->rule_ids('L0');
}

sub Marpa::R2::Scanless::G::g0_rule {
    my ( $slg, @args ) = @_;
    return $slg->[Marpa::R2::Internal::Scanless::G::THICK_LEX_GRAMMARS]->[0]
        ->rule(@args);
}

# Internal methods, not to be documented

sub Marpa::R2::Scanless::G::thick_g1_grammar {
    my ($slg) = @_;
    return $slg->[Marpa::R2::Internal::Scanless::G::THICK_G1_GRAMMAR];
}

sub Marpa::R2::Scanless::G::show_irls {
    my ($slg, $subgrammar) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)->show_irls();
}

1;

# vim: expandtab shiftwidth=4:
