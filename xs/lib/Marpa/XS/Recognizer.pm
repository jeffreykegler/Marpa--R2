# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

package Marpa::XS::Recognizer;

use 5.010;
use warnings;

# As of 9 Aug 2010 there's a problem with this perlcritic check
## no critic (TestingAndDebugging::ProhibitNoWarnings)
no warnings 'recursion';
## use critic

use strict;
use integer;

use English qw( -no_match_vars );

# Elements of the EARLEY ITEM structure
# Note that these are Earley items as modified by Aycock & Horspool,
# with AHFA states instead of
# LR(0) items.

# We don't prune the Earley items because we want ORIGIN and SET
# around for debugging.

# Elements of the RECOGNIZER structure
BEGIN {
my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::XS::Internal::Recognizer

    C { A C structure }
    ID { A unique ID provided by libmarpa }

    GRAMMAR { the grammar used }
    FINISHED
    SLOTS { Array of slots for data to pass to libmarpa }

    TRACE_FILE_HANDLE

    END
    CLOSURES
    TRACE_ACTIONS
    TRACE_AND_NODES
    TRACE_BOCAGE
    TRACE_OR_NODES
    TRACE_VALUES
    TRACE_TASKS
    TRACING
    MAX_PARSES
    NULL_VALUES
    RANKING_METHOD
    TOKEN_VALUES

    { The following fields must be reinitialized when
    evaluation is reset }

    SINGLE_PARSE_MODE
    PARSE_COUNT :{ number of parses in an ambiguous parse :}

    AND_NODE_RANK_REFS

    ITERATION_STACK

    EVALUATOR_RULES

    { This is the end of the list of fields which
    must be reinitialized when evaluation is reset }

    TRACE_EARLEY_SETS
    TRACE_TERMINALS
    WARNINGS

    MODE

    { This is temporary during development of Marpa::XS }
    EARLEME_TO_ORDINAL

END_OF_STRUCTURE
    Marpa::offset($structure);
} ## end BEGIN

package Marpa::XS::Internal::Recognizer;

use English qw( -no_match_vars );

my $parse_number = 0;
my %recce_by_id = ();

# Temporary -- delete when Marpa::XS development is done
sub update_earleme_map {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    $recce->[Marpa::XS::Internal::Recognizer::EARLEME_TO_ORDINAL] //= [];
    my $earleme_to_ordinal = $recce->[Marpa::XS::Internal::Recognizer::EARLEME_TO_ORDINAL];
    EARLEY_SET: for (my $ordinal = scalar @{$earleme_to_ordinal}; ; $ordinal++ ) {
         my $earleme = $recce_c->earleme($ordinal);
	 last EARLEY_SET if not defined $earleme;
	 $earleme_to_ordinal->[$earleme] = $ordinal;
     }
}

sub get_recognizer_by_id {
    my ( $recce_id ) = @_;
    my $recce     = $recce_by_id{$recce_id};
    if (not defined $recce) {
	Carp::croak(
	    "Attempting to use a recognizer which has been garbage collected\n",
	    "Recognizer with id ", q{#}, "$recce_id no longer exists\n"
	);
    }
    $recce;
}

sub message_cb {
    my ( $recce_id, $message_id ) = @_;
    my $recce     = get_recognizer_by_id($recce_id);
    my $recce_c = $recce->[Marpa::XS::Internal::Grammar::C];
    my $trace_fh =
        $recce->[Marpa::XS::Internal::Grammar::TRACE_FILE_HANDLE];
    if ($message_id eq "recce not active") {
	my $phase = $recce_c->phase();
	Marpa::exception( "Recognizer not active, phase is $phase" );
	return;
    }
    Marpa::exception( qq{Unexpected message, type "$message_id"} );
    return;
}

# Returns the new parse object or throws an exception
sub Marpa::XS::Recognizer::new {
    my ( $class, @arg_hashes ) = @_;
    my $recce = bless [], $class;

    my $grammar;
    ARG_HASH: for my $arg_hash (@arg_hashes) {
        if ( defined( $grammar = $arg_hash->{grammar} ) ) {
            delete $arg_hash->{grammar};
            last ARG_HASH;
        }
    } ## end for my $arg_hash (@arg_hashes)
    Marpa::exception('No grammar specified') if not defined $grammar;

    $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR] = $grammar;

    my $grammar_class = ref $grammar;
    Marpa::exception(
        "${class}::new() grammar arg has wrong class: $grammar_class")
        if not $grammar_class eq 'Marpa::Grammar';

    my $grammar_c  = $grammar->[Marpa::XS::Internal::Grammar::C];

    my $problems = $grammar->[Marpa::XS::Internal::Grammar::PROBLEMS];
    if ($problems) {
        Marpa::exception(
            Marpa::XS::Grammar::show_problems($grammar),
            "Attempt to parse grammar with fatal problems\n",
            'Marpa::XS cannot proceed',
        );
    } ## end if ($problems)

    # set the defaults
    local $Marpa::XS::Internal::TRACE_FH = my $trace_fh =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE] =
        $grammar->[Marpa::XS::Internal::Grammar::TRACE_FILE_HANDLE];

    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C] =
        Marpa::XS::Internal::R_C->new( $grammar_c );
    if ( not defined $recce_c ) {
        my $error = $grammar_c->error();
        if ( $error eq 'grammar not precomputed' ) {
            Marpa::exception(
                'Attempt to parse grammar which is not precomputed');
        }
        Marpa::exception(
            qq{Recognizer created failed with unexpected error code: "$error"}
        );
    } ## end if ( not defined $recce_c )
    my $recce_id = $recce_c->id();
    $recce->[Marpa::XS::Internal::Recognizer::ID] = $recce_id;
    $recce_by_id{$recce_id} = $recce;
    Scalar::Util::weaken( $recce_by_id{$recce_id} );
    $recce_c->message_callback_set(\&message_cb);

    $recce->[Marpa::XS::Internal::Recognizer::WARNINGS] = 1;
    $recce->[Marpa::XS::Internal::Recognizer::MODE]           = 'default';
    $recce->[Marpa::XS::Internal::Recognizer::RANKING_METHOD] = 'none';
    $recce->[Marpa::XS::Internal::Recognizer::MAX_PARSES]     = 0;
    $recce->[Marpa::XS::Internal::Recognizer::SLOTS]     = Marpa::XS::Internal::Slot->new();
    $recce->[Marpa::XS::Internal::Recognizer::TOKEN_VALUES]     = {};
    $recce->reset_evaluation();

    $recce->set(@arg_hashes);

    if (    $grammar_c->has_loop()
        and $recce->[Marpa::XS::Internal::Recognizer::RANKING_METHOD] ne
        'none'
        and not $grammar->[Marpa::XS::Internal::Grammar::CYCLE_RANKING_ACTION]
        )
    {
        Marpa::exception(
            "The grammar cycles (is infinitely ambiguous)\n",
            "    but it has no 'cycle_ranking_action'.\n",
            "    Either rewrite the grammar to eliminate cycles\n",
            "    or define a 'cycle ranking action'\n"
        );
    }

    my $trace_terminals =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_TERMINALS] // 0;
    my $trace_tasks = $recce->[Marpa::XS::Internal::Recognizer::TRACE_TASKS]
        // 0;

    if (not $recce_c->start_input()) {
        my $error = $recce_c->error();
        Marpa::exception(
            qq{Recognizer start of input failed with unexpected error code: "$error"}
        );
    }

    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];

    $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR]     = $grammar;

    if ( $trace_terminals > 1 ) {
	my @terminals_expected = @{$recce->terminals_expected()};
        for my $terminal (sort @terminals_expected ) {
            say {$Marpa::XS::Internal::TRACE_FH}
                qq{Expecting "$terminal" at earleme 0}
                or Marpa::exception("Cannot print: $ERRNO");
        }
    } ## end if ( $trace_terminals > 1 )

    return $recce;
} ## end sub Marpa::XS::Recognizer::new

use constant RECOGNIZER_OPTIONS => [
    qw{
        closures
        end
        leo
        max_parses
        mode
        ranking_method
        too_many_earley_items
        trace_actions
        trace_and_nodes
        trace_bocage
        trace_earley_sets
        trace_fh
        trace_file_handle
        trace_or_nodes
        trace_tasks
        trace_terminals
        trace_values
        warnings
        }
];

use constant RECOGNIZER_MODES => [qw(default stream)];

sub Marpa::XS::Recognizer::reset_evaluation {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    if ( $recce->[Marpa::XS::Internal::Recognizer::PARSE_COUNT] ) {
        my $result = $recce_c->eval_clear();
        if ( not defined $result ) {
            Marpa::exception(
                qq{libmarpa's marpa_value_reset() call failed\n});
        }
    } ## end if ( $recce->[Marpa::XS::Internal::Recognizer::PARSE_COUNT...])
    $recce->[Marpa::XS::Internal::Recognizer::PARSE_COUNT]       = 0;
    $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = undef;
    $recce->[Marpa::XS::Internal::Recognizer::AND_NODE_RANK_REFS]         = [];
    $recce->[Marpa::XS::Internal::Recognizer::ITERATION_STACK]   = [];
    $recce->[Marpa::XS::Internal::Recognizer::EVALUATOR_RULES]   = [];
    return;
} ## end sub Marpa::XS::Recognizer::reset_evaluation

sub Marpa::XS::Recognizer::set {
    my ( $recce, @arg_hashes ) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];

    # This may get changed below
    my $trace_fh =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE];

    for my $args (@arg_hashes) {

        my $ref_type = ref $args;
        if ( not $ref_type or $ref_type ne 'HASH' ) {
            Carp::croak(
                'Marpa::XS Recognizer expects args as ref to HASH, got ',
                ( "ref to $ref_type" || 'non-reference' ),
                ' instead'
            );
        } ## end if ( not $ref_type or $ref_type ne 'HASH' )
        if (my @bad_options =
            grep {
                not $_ ~~ Marpa::XS::Internal::Recognizer::RECOGNIZER_OPTIONS
            }
            keys %{$args}
            )
        {
            Carp::croak( 'Unknown option(s) for Marpa::XS Recognizer: ',
                join q{ }, @bad_options );
        } ## end if ( my @bad_options = grep { not $_ ~~ ...})

        if ( defined( my $value = $args->{'leo'} ) ) {
	    my $boolean = $value ? 1 : 0;
	    $recce_c->is_use_leo_set($boolean);
        }

        if ( defined( my $value = $args->{'max_parses'} ) ) {
            $recce->[Marpa::XS::Internal::Recognizer::MAX_PARSES] = $value;
        }

        if ( defined( my $value = $args->{'mode'} ) ) {
            if (not $value ~~
                Marpa::XS::Internal::Recognizer::RECOGNIZER_MODES )
            {
                Carp::croak( 'Unknown mode for Marpa::XS Recognizer: ',
                    $value );
            } ## end if ( not $value ~~ ...)
            $recce->[Marpa::XS::Internal::Recognizer::MODE] = $value;
        } ## end if ( defined( my $value = $args->{'mode'} ) )

        if ( defined( my $value = $args->{'ranking_method'} ) ) {
            Marpa::exception(
                q{ranking_method must be 'constant' or 'none'})
                if not $value ~~ [qw(constant none)];
            $recce->[Marpa::XS::Internal::Recognizer::RANKING_METHOD] =
                $value;
        } ## end if ( defined( my $value = $args->{'ranking_method'} ...))

        if ( defined( my $value = $args->{'trace_fh'} ) ) {
            $trace_fh =
                $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE] =
                $value;
        }

        if ( defined( my $value = $args->{'trace_file_handle'} ) ) {
            $trace_fh =
                $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE] =
                $value;
        }

        if ( defined( my $value = $args->{'trace_actions'} ) ) {
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_ACTIONS] = $value;
            ## Do not allow setting this option in recognizer for single parse mode
            $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = 0;
            if ($value) {
                say {$trace_fh} 'Setting trace_actions option'
                    or Marpa::exception("Cannot print: $ERRNO");
                $recce->[Marpa::XS::Internal::Recognizer::TRACING] = 1;
            }
        } ## end if ( defined( my $value = $args->{'trace_actions'} ))

        if ( defined( my $value = $args->{'trace_and_nodes'} ) ) {
            Marpa::exception('trace_and_nodes must be set to a number >= 0')
                if $value !~ /\A\d+\z/xms;
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_AND_NODES] =
                $value + 0;
            if ($value) {
                say {$trace_fh} "Setting trace_and_nodes option to $value"
                    or Marpa::exception("Cannot print: $ERRNO");
                $recce->[Marpa::XS::Internal::Recognizer::TRACING] = 1;
            }
        } ## end if ( defined( my $value = $args->{'trace_and_nodes'} ...))

        if ( defined( my $value = $args->{'trace_bocage'} ) ) {
            Marpa::exception('trace_bocage must be set to a number >= 0')
                if $value !~ /\A\d+\z/xms;
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_BOCAGE] =
                $value + 0;
            if ($value) {
                say {$trace_fh} "Setting trace_bocage option to $value"
                    or Marpa::exception("Cannot print: $ERRNO");
                $recce->[Marpa::XS::Internal::Recognizer::TRACING] = 1;
            }
        } ## end if ( defined( my $value = $args->{'trace_bocage'} ...))

        if ( defined( my $value = $args->{'trace_or_nodes'} ) ) {
            Marpa::exception('trace_or_nodes must be set to a number >= 0')
                if $value !~ /\A\d+\z/xms;
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_OR_NODES] =
                $value + 0;
            if ($value) {
                say {$trace_fh} "Setting trace_or_nodes option to $value"
                    or Marpa::exception("Cannot print: $ERRNO");
                $recce->[Marpa::XS::Internal::Recognizer::TRACING] = 1;
            }
        } ## end if ( defined( my $value = $args->{'trace_or_nodes'} ...))

        if ( defined( my $value = $args->{'trace_tasks'} ) ) {
            Marpa::exception('trace_tasks must be set to a number >= 0')
                if $value !~ /\A\d+\z/xms;
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_TASKS] =
                $value + 0;
            if ($value) {
                say {$trace_fh} "Setting trace_tasks option to $value"
                    or Marpa::exception("Cannot print: $ERRNO");
                $recce->[Marpa::XS::Internal::Recognizer::TRACING] = 1;
            }
        } ## end if ( defined( my $value = $args->{'trace_tasks'} ) )

        if ( defined( my $value = $args->{'trace_terminals'} ) ) {
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_TERMINALS] =
                $value;
            if ($value) {
                say {$trace_fh} 'Setting trace_terminals option'
                    or Marpa::exception("Cannot print: $ERRNO");
                $recce->[Marpa::XS::Internal::Recognizer::TRACING] = 1;
            }
        } ## end if ( defined( my $value = $args->{'trace_terminals'}...))

        if ( defined( my $value = $args->{'trace_earley_sets'} ) ) {
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_EARLEY_SETS] =
                $value;
            if ($value) {
                say {$trace_fh} 'Setting trace_earley_sets option'
                    or Marpa::exception("Cannot print: $ERRNO");
                $recce->[Marpa::XS::Internal::Recognizer::TRACING] = 1;
            }
        } ## end if ( defined( my $value = $args->{'trace_earley_sets'...}))

        if ( defined( my $value = $args->{'trace_values'} ) ) {
            $recce->[Marpa::XS::Internal::Recognizer::TRACE_VALUES] = $value;
            ## Do not allow setting this option in recognizer for single parse mode
            $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = 0;
            if ($value) {
                say {$trace_fh} 'Setting trace_values option'
                    or Marpa::exception("Cannot print: $ERRNO");
                $recce->[Marpa::XS::Internal::Recognizer::TRACING] = 1;
            }
        } ## end if ( defined( my $value = $args->{'trace_values'} ) )

        if ( defined( my $value = $args->{'end'} ) ) {

            # Not allowed once parsing is started
            if ( $recce->[Marpa::XS::Internal::Recognizer::PARSE_COUNT] > 0 )
            {
                Marpa::exception(
                    q{Cannot reset end once parsing has started});
            }
            $recce->[Marpa::XS::Internal::Recognizer::END] = $value;
            ## Do not allow setting this option in recognizer for single parse mode
            $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = 0;
        } ## end if ( defined( my $value = $args->{'end'} ) )

        if ( defined( my $value = $args->{'closures'} ) ) {

            # Not allowed once parsing is started
            if ( $recce->[Marpa::XS::Internal::Recognizer::PARSE_COUNT] > 0 )
            {
                Marpa::exception(
                    q{Cannot reset end once parsing has started});
            }
            my $closures =
                $recce->[Marpa::XS::Internal::Recognizer::CLOSURES] = $value;
            ## Do not allow setting this option in recognizer for single parse mode
            $recce->[Marpa::XS::Internal::Recognizer::SINGLE_PARSE_MODE] = 0;
            while ( my ( $action, $closure ) = each %{$closures} ) {
                Marpa::exception(qq{Bad closure for action "$action"})
                    if ref $closure ne 'CODE';
            }
        } ## end if ( defined( my $value = $args->{'closures'} ) )

        if ( defined( my $value = $args->{'warnings'} ) ) {
            $recce->[Marpa::XS::Internal::Recognizer::WARNINGS] = $value;
        }

        if ( defined( my $value = $args->{'too_many_earley_items'} ) ) {
            $recce_c->earley_item_warning_threshold_set( $value );
        }

    } ## end for my $args (@arg_hashes)

    return 1;
} ## end sub Marpa::XS::Recognizer::set

# Not intended to be documented.
# Returns the size of the last completed earley set.
# For testing, especially that the Leo items
# are doing their job.
sub Marpa::XS::Recognizer::earley_set_size {
    my ($recce, $set_id) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    return $recce_c->earley_set_size($set_id);
}

sub Marpa::XS::Recognizer::latest_earley_set {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    return $recce_c->latest_earley_set();
}

sub Marpa::XS::Recognizer::check_terminal {
    my ( $recce, $name ) = @_;
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    return $grammar->check_terminal($name);
}

sub Marpa::XS::Recognizer::exhausted {
    my $recce_c = $_[0]->[Marpa::XS::Internal::Recognizer::C];
    return $recce_c->is_exhausted();
}

sub Marpa::XS::Recognizer::current_earleme {
    my $recce_c = $_[0]->[Marpa::XS::Internal::Recognizer::C];
    return $recce_c->current_earleme();
}

sub Marpa::XS::Recognizer::furthest_earleme {
    my $recce_c = $_[0]->[Marpa::XS::Internal::Recognizer::C];
    return $recce_c->furthest_earleme();
}

# Deprecated -- obsolete
sub Marpa::XS::Recognizer::status {
    my ($recce) = @_;
    my $recce_c = $_[0]->[Marpa::XS::Internal::Recognizer::C];
    return ( $recce_c->current_earleme(), $recce->terminals_expected() )
        if wantarray;
    return $recce->current_earleme();

} ## end sub Marpa::XS::Recognizer::status

# Now useless and deprecated
sub Marpa::XS::Recognizer::strip { return 1; }

# Viewing methods, for debugging

sub Marpa::XS::new_show_leo_item {
    my ($recce)        = @_;
    my $recce_c        = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar        = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $leo_base_state = $recce_c->leo_base_state();
    return if not defined $leo_base_state;
    my $trace_earley_set = $recce_c->trace_earley_set();
    my $trace_earleme = $recce_c->earleme($trace_earley_set);
    my $postdot_symbol_id     = $recce_c->postdot_item_symbol();
    my $predecessor_symbol_id = $recce_c->leo_predecessor_symbol();
    my $base_origin_set_id           = $recce_c->leo_base_origin();
    my $base_origin_earleme           = $recce_c->earleme($base_origin_set_id);
    my $symbols = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $postdot_symbol_name =
        $symbols->[$postdot_symbol_id]->[Marpa::XS::Internal::Symbol::NAME];

    my $text = sprintf 'L%d@%d', $postdot_symbol_id, $trace_earleme;
    my @link_texts = qq{"$postdot_symbol_name"};
    if ( defined $predecessor_symbol_id ) {
        push @link_texts, sprintf 'L%d@%d', $predecessor_symbol_id,
            $base_origin_earleme;
    }
    push @link_texts, sprintf 'S%d@%d-%d', $leo_base_state, $base_origin_earleme,
        $trace_earleme;
    $text .= ' [' . ( join '; ', @link_texts ) . ']';
    return $text;
} ## end sub Marpa::XS::new_show_leo_item

 # Assumes trace token source link set by caller
sub Marpa::XS::new_show_token_link_choice {
    my ($recce, $token_id) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $slots = $recce->[Marpa::XS::Internal::Recognizer::SLOTS];
    my $symbols = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $text = q{};
    my @pieces = ();
    my $predecessor_state = $recce_c->source_predecessor_state();
    my $origin_set_id = $recce_c->earley_item_origin();
    my $origin_earleme = $recce_c->earleme($origin_set_id);
    if (defined $predecessor_state) {
	my $middle_set_id = $recce_c->source_middle();
	my $middle_earleme = $recce_c->earleme($middle_set_id);
        push @pieces,
              'p=S'
            . $predecessor_state . '@'
            . $origin_earleme . '-'
            . $middle_earleme;
    }
    push @pieces, 's=' . $symbols->[$token_id]->[Marpa::XS::Internal::Symbol::NAME];
    my $slot = $recce_c->source_value();
    my $value_ref = \($slots->value($slot));
    my $token_dump = Data::Dumper->new( [$value_ref] )->Terse(1)->Dump;
    chomp $token_dump;
    push @pieces, "t=$token_dump";
    return '[' . ( join '; ', @pieces ) . ']';
}

 # Assumes trace completion source link set by caller
sub Marpa::XS::new_show_completion_link_choice {
    my ($recce, $AHFA_state_id, $current_earleme) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $slots = $recce->[Marpa::XS::Internal::Recognizer::SLOTS];
    my $symbols = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $text = q{};
    my @pieces = ();
    my $predecessor_state = $recce_c->source_predecessor_state();
    my $origin_set_id = $recce_c->earley_item_origin();
    my $origin_earleme = $recce_c->earleme($origin_set_id);
    my $middle_set_id = $recce_c->source_middle();
    my $middle_earleme = $recce_c->earleme($middle_set_id);
    if (defined $predecessor_state) {
        push @pieces,
              'p=S'
            . $predecessor_state . '@'
            . $origin_earleme . '-'
            . $middle_earleme;
    }
    push @pieces,
          'c=S'
        . $AHFA_state_id . '@'
        . $middle_earleme . '-'
        . $current_earleme;
    return '[' . ( join '; ', @pieces ) . ']';
}

 # Assumes trace completion source link set by caller
sub Marpa::XS::new_show_leo_link_choice {
    my ($recce, $AHFA_state_id, $current_earleme) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $slots = $recce->[Marpa::XS::Internal::Recognizer::SLOTS];
    my $symbols = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $text = q{};
    my @pieces = ();
    my $middle_set_id = $recce_c->source_middle();
    my $middle_earleme = $recce_c->earleme($middle_set_id);
    my $leo_transition_symbol = $recce_c->source_leo_transition_symbol();
    push @pieces,
	'l=L' . $leo_transition_symbol . '@' . $middle_earleme;
    push @pieces,
        'c=S' . $AHFA_state_id . '@' . $middle_earleme . '-' . $current_earleme;
    return '[' . ( join '; ', @pieces ) . ']';
}

 # Assumes trace earley item was set by caller
sub Marpa::XS::show_earley_item {
    my ($recce, $earleme, $state_id) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $text = q{};
    my $origin_set_id = $recce_c->earley_item_origin();
    my $origin_earleme = $recce_c->earleme($origin_set_id);
    $text .= sprintf "S%d@%d-%d", $state_id, $origin_earleme, $earleme;
    my @pieces = $text;
    my @sort_data = ();
    for (
        my $symbol_id = $recce_c->first_token_link_trace();
        defined $symbol_id;
        $symbol_id = $recce_c->next_token_link_trace()
        )
    {
        push @sort_data, [
	    $recce_c->source_middle(),
	    $symbol_id,
	    ($recce_c->source_predecessor_state() // -1),
            Marpa::XS::new_show_token_link_choice( $recce, $symbol_id )
       ];
    } ## end for ( my $symbol_id = $recce_c->first_token_link_trace...)
    push @pieces, map { $_->[-1] } sort {
        $a->[0] <=> $b->[0]
        || $a->[1] <=> $b->[1]
        || $a->[2] <=> $b->[2]
    } @sort_data;
    @sort_data = ();
    for (
        my $cause_AHFA_id = $recce_c->first_completion_link_trace();
        defined $cause_AHFA_id;
        $cause_AHFA_id = $recce_c->next_completion_link_trace()
        )
    {
        push @sort_data,
            [
            $recce_c->source_middle(),
            $cause_AHFA_id,
            ( $recce_c->source_predecessor_state() // -1 ),
            Marpa::XS::new_show_completion_link_choice(
                $recce, $cause_AHFA_id, $earleme
            )
            ];
    } ## end for ( my $AHFA_state_id = $recce_c->first_completion_link_trace...)
    push @pieces, map { $_->[-1] } sort {
        $a->[0] <=> $b->[0]
        || $a->[1] <=> $b->[1]
        || $a->[2] <=> $b->[2]
    } @sort_data;
    @sort_data = ();
    for (
        my $AHFA_state_id = $recce_c->first_leo_link_trace();
        defined $AHFA_state_id;
        $AHFA_state_id = $recce_c->next_leo_link_trace()
        )
    {
        push @sort_data,
            [
            $recce_c->source_middle(),
            $AHFA_state_id,
	    $recce_c->source_leo_transition_symbol(),
            Marpa::XS::new_show_leo_link_choice(
                $recce, $AHFA_state_id, $earleme
            )
            ];
    } ## end for ( my $AHFA_state_id = $recce_c...)
    push @pieces, map { $_->[-1] } sort {
        $a->[0] <=> $b->[0]
        || $a->[1] <=> $b->[1]
        || $a->[2] <=> $b->[2]
    } @sort_data;
    return join q{ }, @pieces;
}

sub Marpa::XS::show_earley_set {
    my ( $recce, $earleme ) = @_;
    my $recce_c        = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $text           = q{};
    update_earleme_map($recce);
    my $traced_set_id = $recce->[Marpa::XS::Internal::Recognizer::EARLEME_TO_ORDINAL]->[$earleme];
    return $text if not defined $traced_set_id;
    my @sort_data = ();
    if (not defined $recce_c->earley_set_trace($traced_set_id)) {
       return $text;
    }
    EARLEY_ITEM: for ( my $item_id = 0; ; $item_id++) {
	my $state_id = $recce_c->earley_item_trace($item_id);
	last EARLEY_ITEM if not defined $state_id;
	push @sort_data,
	    [ $recce_c->earley_item_origin(), $state_id, 
            Marpa::XS::show_earley_item( $recce, $earleme, $state_id ) ];
    } ## end for ( my $state_id = $recce_c->earley_item_first_trace...)
    my @sorted_data = map { $_->[-1] . "\n" } sort {
        $a->[0] <=> $b->[0]
        || $a->[1] <=> $b->[1]
    } @sort_data;
    @sort_data = ();
    POSTDOT_ITEM:
    for (
        my $postdot_symbol_id = $recce_c->first_postdot_item_trace();
        defined $postdot_symbol_id;
        $postdot_symbol_id = $recce_c->next_postdot_item_trace()
        )
    {

        # If there is no base Earley item,
        # then this is not a Leo item, so we skip it
        my $leo_item_desc = Marpa::XS::new_show_leo_item($recce);
        next POSTDOT_ITEM if not defined $leo_item_desc;
        push @sort_data, [ $postdot_symbol_id, $leo_item_desc ];
    } ## end for ( my $postdot_symbol_id = $recce_c->postdot_item_first_trace...)
    push @sorted_data, join q{}, map { $_->[-1] . "\n" } sort {
        $a->[0] <=> $b->[0]
    } @sort_data;
    return join q{}, @sorted_data;
} ## end sub Marpa::XS::show_earley_set

sub Marpa::XS::Recognizer::show_earley_sets {
    my ($recce) = @_;
    my $recce_c   = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $last_completed_earleme = $recce_c->current_earleme();
    my $furthest_earleme = $recce_c->furthest_earleme();
    my $text = 
          "Last Completed: $last_completed_earleme; "
        . "Furthest: $furthest_earleme\n";
    LIST: for my $ix ( 0 .. $furthest_earleme ) {
        $text .= "Earley Set $ix\n"
            . Marpa::XS::show_earley_set( $recce, $ix );
    }
    return $text;
}

BEGIN {
my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::XS::Internal::Progress_Report

    RULE_ID
    POSITION
    ORIGIN
    CURRENT

END_OF_STRUCTURE
    Marpa::offset($structure);
} ## end BEGIN

sub Marpa::XS::Recognizer::show_progress {
    my ( $recce, $start_ordinal, $end_ordinal ) = @_;
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $grammar_c   = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::XS::Internal::Recognizer::C];
    update_earleme_map($recce);

    my $last_ix = $recce_c->furthest_earleme();
    my $last_ordinal = $recce->[Marpa::XS::Internal::Recognizer::EARLEME_TO_ORDINAL]->[$last_ix];

    my $start_ix;
    if ( not defined $start_ordinal ) {
        $start_ix = $recce_c->current_earleme();
    }
    else {
        if ( $start_ordinal < 0 or $start_ordinal > $last_ordinal ) {
            return
                "Marpa::PP::Recognizer::show_progress start index is $start_ordinal, "
                . "must be in range 0-$last_ordinal";
        }
        $start_ix = $recce_c->earleme($start_ordinal);
    } ## end else [ if ( not defined $start_ordinal ) ]

    my $end_ix;
    if (not defined $end_ordinal) {
        $end_ix = $start_ix;
    } else {
	my $end_ordinal_argument = $end_ordinal;
	if ($end_ordinal < 0) {
	   $end_ordinal += $last_ordinal + 1;
	}
	if ( $end_ordinal < 0 ) {
	    return
		"Marpa::PP::Recognizer::show_progress end index is $end_ordinal_argument, "
		. sprintf " must be in range %d-%d", -($last_ordinal+1), $last_ordinal;
	}
        $end_ix = $recce_c->earleme($end_ordinal);
    }

    my $text = q{};
    for my $current ( $start_ix .. $end_ix ) {
	my %by_rule_by_position = ();
        my $reports = report_progress( $recce, $current );

        for my $report ( @{$reports} ) {
            my $rule_id =
                $report->[Marpa::XS::Internal::Progress_Report::RULE_ID];
            my $position =
                $report->[Marpa::XS::Internal::Progress_Report::POSITION];
            my $origin =
                $report->[Marpa::XS::Internal::Progress_Report::ORIGIN];

            $by_rule_by_position{$rule_id}->{$position}->{$origin}++;
        } ## end for my $report ( @{$reports} )
        for my $rule_id ( sort { $a <=> $b } keys %by_rule_by_position ) {
            my $by_position = $by_rule_by_position{$rule_id};
            for my $position ( sort { $a <=> $b } keys %{$by_position} ) {
		my $raw_origins = $by_position->{$position};
                my @origins = sort { $a <=> $b } keys %{$raw_origins};
		my $origins_count = scalar @origins;
                my $origin_desc;
                if ( $origins_count <= 3 ) {
                    $origin_desc = join q{,}, @origins;
                }
                else {
                    $origin_desc = $origins[0] . q{...} . $origins[-1];
                } ## end else [ if ( scalar @{$origins} < 3 ) ]

                my $rhs_length = $grammar_c->rule_length($rule_id);
                my $item_text;

                # flag indicating whether we need to show the dot in the rule
                if ( $position >= $rhs_length ) {
		    $item_text .= "F$rule_id";
                } ## end if ( $position >= $rhs_length )
                elsif ($position) {
		    $item_text .= "R$rule_id:$position";
                } ## end elsif ($position)
                else {
		    $item_text .= "P$rule_id";
                }
		$item_text .= " x$origins_count" if $origins_count > 1;
		$item_text .= q{ @} . $origin_desc . q{-} . $current . q{ };
		$item_text .= $grammar->show_dotted_rule( $rule_id, $position );
                $text .= $item_text . "\n";
            } ## end for my $postion ( sort { $a <=> $b } keys %{$by_position...})
        } ## end for my $rule_id ( sort { $a <=> $b } keys ...)
    } ## end for my $current ( $start_ix .. $end_ix )
    return $text;
} ## end sub Marpa::XS::Recognizer::show_progress

# This function may return duplicates.  In displaying the results,
# it is usually # desirable to sort the results,
# and that is the most convenient
# point at which to eliminate duplicates.
sub report_progress {
    my ($recce, $earleme) = @_;
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $rules = $grammar->[Marpa::XS::Internal::Grammar::RULES];
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];

    # Reports must be unique by a key
    # composted of original rule, rule position, and
    # location in the parse.  This hash is to
    # quarantee that.
    my @progress_reports = ();
    my @per_AHFA_item_data = ();

    # Building the Leo expansion items immediately would
    # require switching traced Earley sets and breaking
    # the sequence of the earley items.  So we create a
    # worklist of them for later.
    my @leo_worklist = ();

    my $traced_set_id = $recce->[Marpa::XS::Internal::Recognizer::EARLEME_TO_ORDINAL]->[$earleme];
    $recce_c->earley_set_trace($traced_set_id);
    EARLEY_ITEM: for (my $item_id = 0;
	    defined (my $AHFA_state_id = $recce_c->earley_item_trace($item_id)) ;
	    $item_id++) {
        my $origin_set_id = $recce_c->earley_item_origin();
        my $origin_earleme = $recce_c->earleme($origin_set_id);
	LEO_SOURCE: for (
	    my $AHFA_state_id = $recce_c->first_leo_link_trace();
	    defined $AHFA_state_id;
	    $AHFA_state_id = $recce_c->next_leo_link_trace()
	    )
	{

	    # The first Leo link is ignored, the current eim item
	    # is a Leo completion and therefore the Leo expansion
	    # of its own first Leo link
	    my $leo_transition_symbol = $recce_c->source_leo_transition_symbol();
	    next LEO_SOURCE if not defined $leo_transition_symbol;
	    my $previous_lim_set_id = $recce_c->source_middle();
	    push @leo_worklist, [$previous_lim_set_id, $leo_transition_symbol];
	}
	push @per_AHFA_item_data, [$origin_earleme, $AHFA_state_id];
    }
    for my $leo_workitem (@leo_worklist) {

        my ( $leo_item_set_id, $leo_item_postdot_symbol ) = @{$leo_workitem};
        LEO_ITEM: for ( ;; ) {
            $recce_c->earley_set_trace($leo_item_set_id);
            $recce_c->postdot_symbol_trace($leo_item_postdot_symbol);
            my $expansion_ahfa = $recce_c->leo_expansion_ahfa();
            push @per_AHFA_item_data,
                [ $recce_c->earleme($leo_item_set_id), $expansion_ahfa ];
            $leo_item_postdot_symbol =
                $recce_c->leo_predecessor_symbol();
            last LEO_ITEM if not defined $leo_item_postdot_symbol;
	    $leo_item_set_id = $recce_c->leo_base_origin();
        } ## end for ( ;; )
    } ## end for my $leo_workitem (@leo_worklist)
    for my $per_AHFA_item_datum (@per_AHFA_item_data) {
	my ($origin, $AHFA_state_id) = @{$per_AHFA_item_datum};
        my @AHFA_items = $grammar_c->AHFA_state_items($AHFA_state_id);
        AHFA_ITEM: for my $AHFA_item_id (@AHFA_items) {
            my $marpa_rule_id = $grammar_c->AHFA_item_rule($AHFA_item_id);
            my $marpa_rule    = $rules->[$marpa_rule_id];
            my $marpa_position =
                $grammar_c->AHFA_item_position($AHFA_item_id);
            $marpa_position < 0
                and $marpa_position = $grammar_c->rule_length($marpa_rule_id);
            my $chaf_start = $grammar_c->rule_virtual_start($marpa_rule_id);
            $chaf_start < 0 and $chaf_start = undef;
            my $original_rule_id =
                defined $chaf_start
                ? ( $grammar_c->rule_original($marpa_rule_id)
                    // $marpa_rule_id )
                : $marpa_rule_id;

            # position in original rule, to be calculated
            my $original_position;
            if ( defined $chaf_start ) {
                $original_position =
                    $marpa_position >= $grammar_c->rule_length($marpa_rule_id)
                    ? $grammar_c->rule_length($original_rule_id)
                    : ( $chaf_start + $marpa_position );
            } ## end if ( defined $chaf_start )
            $original_position //= $marpa_position;
            my $rule_id         = $original_rule_id;
            push @progress_reports, [ $rule_id, $original_position, $origin, $earleme ];
        } ## end for my $AHFA_item_id (@AHFA_items)
    } ## end for my $earley_item ( @{$earley_items} )
    return \@progress_reports;
} ## end sub report_progress

sub Marpa::XS::Recognizer::read {
    # For efficiency, not unpacked
    # my ( $recce, $symbol_name, $value ) = @_;
    my $recce = shift;
    return defined $recce->alternative(@_) ? $recce->earleme_complete() : undef;
}

sub Marpa::XS::Recognizer::alternative {

    my ( $recce, $symbol_name, $value, $length ) = @_;

    Marpa::exception(
        'No recognizer object for Marpa::XS::Recognizer::tokens')
        if not defined $recce
            or ref $recce ne 'Marpa::Recognizer';

    Marpa::exception('Attempt to read token after parsing is finished')
        if $recce->[Marpa::XS::Internal::Recognizer::FINISHED];

    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $trace_fh = $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE];
    my $slots = $recce->[Marpa::XS::Internal::Recognizer::SLOTS];
    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];
    my $symbol_id = $symbol_hash->{$symbol_name};
    my $slot = $slots->slot($value);
    $length //= 1;

    $recce->[Marpa::XS::Internal::Recognizer::TOKEN_VALUES]->{join q{;}, 
	$recce_c->current_earleme(), $length, $symbol_name} = $value;
    my $result = $recce_c->alternative( $symbol_id, $slot, $length );
    Marpa::exception(
        qq{"$symbol_name" already scanned with length $length at location },
	$recce_c->current_earleme()
    ) if defined $result and $result == -3;

    my $trace_terminals =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_TERMINALS];
     if ($trace_terminals) {
         my $verb = defined $result ? 'Accepted' : 'Rejected';
	 my $current_earleme = $result // $recce_c->current_earleme();
         say {$trace_fh} qq{$verb "$symbol_name" at $current_earleme-}
             . ( $length + $current_earleme )
             or Marpa::exception("Cannot print: $ERRNO");
     }

    return $result;

}

# Deprecated -- obsolete
sub Marpa::XS::Recognizer::tokens {

    my ( $recce, $tokens, $token_ix_ref ) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];

    Marpa::exception(
        'No recognizer object for Marpa::XS::Recognizer::tokens')
        if not defined $recce
            or ref $recce ne 'Marpa::Recognizer';

    Marpa::exception('No tokens arg for Marpa::XS::Recognizer::tokens')
        if not defined $tokens;

    my $mode = $recce->[Marpa::XS::Internal::Recognizer::MODE];
    my $interactive;

    if ( defined $token_ix_ref ) {
        my $ref_type = ref $token_ix_ref;
        if ( ref $token_ix_ref ne 'SCALAR' ) {
            my $description = $ref_type ? "ref to $ref_type" : 'not a ref';
            Marpa::exception(
                "Token index arg for Marpa::XS::Recognizer::tokens is $description, must be ref to SCALAR"
            );
        } ## end if ( ref $token_ix_ref ne 'SCALAR' )
        Marpa::exception(
            q{'Tokens index ref for Marpa::XS::Recognizer::tokens allowed only in 'stream' mode}
        ) if $mode ne 'stream';
        $interactive = 1;
    } ## end if ( defined $token_ix_ref )

    my $grammar = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    local $Marpa::XS::Internal::TRACE_FH = my $trace_fh =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE];
    my $trace_terminals =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_TERMINALS];

    Marpa::exception('Attempt to scan tokens after parsing is finished')
        if $recce->[Marpa::XS::Internal::Recognizer::FINISHED]
            and scalar @{$tokens};

    Marpa::exception('Attempt to scan tokens when parsing is exhausted')
        if $recce_c->phase() eq "exhausted" and scalar @{$tokens};

    my $symbol_hash =
        $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];

    my $next_token_earleme = my $last_completed_earleme = $recce_c->current_earleme();

    $token_ix_ref //= \( my $token_ix = 0 );

    my $token_args = $tokens->[ ${$token_ix_ref} ];

    # If the token list is empty, we will go straight to the
    # next token
    if ( not scalar @{$tokens} ) { $next_token_earleme++ }

    EARLEME: while ( ${$token_ix_ref} < scalar @{$tokens} ) {

        my $current_token_earleme = $last_completed_earleme;
	# At this point, typically, $current_token_earleme,
	# $next_token_earleme and $last_completed_earleme are
	# all equal.

        # It's not 100% clear whether it's best to leave
        # the token_ix_ref pointing at the start of the
        # earleme, or at the actual problem token.
        # Right now, we set it at the actual problem
        # token, which is probably what will turn out
        # to be easiest.
        # my $first_ix_of_this_earleme = ${$token_ix_ref};

	# For as long the $next_token_earleme does not advance ...
        TOKEN: while ( $current_token_earleme == $next_token_earleme ) {

	    # ... or until we run out of tokens
            last TOKEN if not my $token_args = $tokens->[ ${$token_ix_ref} ];
            Marpa::exception(
                'Tokens must be array refs: token #',
                ${$token_ix_ref}, " is $token_args\n",
            ) if ref $token_args ne 'ARRAY';
            ${$token_ix_ref}++;
            my ( $symbol_name, $value, $length, $offset ) = @{$token_args};

            Marpa::exception(
                "Attempt to add token '$symbol_name' at location where processing is complete:\n",
                "  Add attempted at $current_token_earleme\n",
                "  Processing complete to $last_completed_earleme\n"
            ) if $current_token_earleme < $last_completed_earleme;

	    my $symbol_id = $symbol_hash->{$symbol_name};
	    if ( not defined $symbol_id ) {
		say {$trace_fh}
		    qq{Attempted to add non-existent symbol named "$symbol_name" at $last_completed_earleme\n}
		    or Marpa::exception("Cannot print: $ERRNO");
	    }

            my $result = $recce->alternative($symbol_name, $value, $length);

            if ( not defined $result ) {
                if ( not $interactive ) {
                    Marpa::exception(
                        qq{Terminal "$symbol_name" received when not expected}
                    );
                }

                # Current token didn't actually work, so back out
                # the increment
                ${$token_ix_ref}--;

                return $recce->status();
            } ## end if ( not $postdot_data )

            $offset //= 1;
            Marpa::exception(
                'Token ' . $symbol_name . " has negative offset\n",
                "  Token starts at $last_completed_earleme, and its length is $length\n",
                "  Tokens are required to be in sequence by location\n",
            ) if $offset < 0;
            $next_token_earleme += $offset;

        } ## end while ( $current_token_earleme == $next_token_earleme )

	# We've ended the loop for the tokens at $current_token_earleme.
	# It is possible that $next_token_earleme did not advance,
	# and the loop ended when we ran out of tokens in the
	# argument list.
        # We arrange it so that the last descriptor in
        # a tokens call always advances the current earleme by at least one --
	# as if it had incremented $next_token_earleme
        $current_token_earleme++;
        $current_token_earleme = $next_token_earleme
            if $next_token_earleme > $current_token_earleme;

        $recce->earleme_complete();
        $last_completed_earleme++;

    } ## end while ( ${$token_ix_ref} < scalar @{$tokens} )

    if ( $mode eq 'stream' ) {
        while ( $last_completed_earleme < $next_token_earleme ) {
            $recce->earleme_complete();
            $last_completed_earleme++;
        }
    } ## end if ( $mode eq 'stream' )

    my $furthest_earleme = $recce_c->furthest_earleme();
    if ( $mode eq 'default' ) {
        while ( $last_completed_earleme < $furthest_earleme ) {
            $recce->earleme_complete();
            $last_completed_earleme++;
        }
        $recce->[Marpa::XS::Internal::Recognizer::FINISHED] = 1;
    } ## end if ( $mode eq 'default' )

    return $recce->status();

} ## end sub Marpa::XS::Recognizer::tokens


# Perform the completion step on an earley set

sub Marpa::XS::Recognizer::end_input {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $furthest_earleme = $recce_c->furthest_earleme();
    while ( $recce_c->current_earleme() < $furthest_earleme ) {
	$recce->earleme_complete();
    }
    $recce->[Marpa::XS::Internal::Recognizer::FINISHED] = 1;
    return 1;
} ## end sub Marpa::XS::Recognizer::end_input

sub Marpa::XS::Recognizer::terminals_expected {
    my ($recce)   = @_;
    my $recce_c   = $recce->[Marpa::XS::Internal::Recognizer::C];
    my $grammar     = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $symbols     = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    return [ map { $symbols->[$_]->[Marpa::XS::Internal::Symbol::NAME] } $recce_c->terminals_expected() ];
} ## end sub Marpa::XS::Recognizer::terminals_expected

sub Marpa::XS::Recognizer::earleme_complete {
    my ($recce) = @_;

    my $recce_c = $recce->[Marpa::XS::Internal::Recognizer::C];
    local $Marpa::XS::Internal::TRACE_FH =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_FILE_HANDLE];
    my $grammar     = $recce->[Marpa::XS::Internal::Recognizer::GRAMMAR];
    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];
    my $symbols     = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];

    my $no_of_terminals_expected = $recce_c->earleme_complete();
    if (not defined $no_of_terminals_expected) {
        my $error = $recce_c->error();
        if ( $error eq "parse exhausted" ) {
            Marpa::exception(
                qq{parse exhausted}
            );
        }
        Marpa::exception( "Uncaught error from earleme_complete(): ",
            $recce_c->error() );
    }

    if ($recce->[Marpa::XS::Internal::Recognizer::TRACE_EARLEY_SETS]) {
	my $current_earleme = $recce_c->current_earleme();
        print {$Marpa::XS::Internal::TRACE_FH}
            "=== Earley set $current_earleme\n"
            or Marpa::exception("Cannot print: $ERRNO");
        print {$Marpa::XS::Internal::TRACE_FH}
            Marpa::XS::show_earley_set($current_earleme)
            or Marpa::exception("Cannot print: $ERRNO");
    } ## end if ($trace_earley_sets)

    my $trace_terminals =
        $recce->[Marpa::XS::Internal::Recognizer::TRACE_TERMINALS] // 0;
    if ( $trace_terminals > 1 ) {
	my $current_earleme = $recce_c->current_earleme();
	my $terminals_expected = $recce->terminals_expected();
        for my $terminal (@{$terminals_expected}) {
            say {$Marpa::XS::Internal::TRACE_FH}
                qq{Expecting "$terminal" at $current_earleme}
                or Marpa::exception("Cannot print: $ERRNO");
        }
    } ## end if ( $trace_terminals > 1 )

    return $no_of_terminals_expected;

} ## end sub Marpa::XS::Recognizer::earleme_complete

1;
