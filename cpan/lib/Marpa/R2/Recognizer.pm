# Copyright 2014 Jeffrey Kegler
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

package Marpa::R2::Recognizer;

use 5.010;
use warnings;
use strict;
use English qw( -no_match_vars );

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.090_000';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::Recognizer;

use English qw( -no_match_vars );

my $parse_number = 0;

# Returns the new parse object or throws an exception
sub Marpa::R2::Recognizer::new {
    my ( $class, @arg_hashes ) = @_;
    my $recce = bless [], $class;

    my $grammar;
    my $trace_file_handle;
    for my $arg_hash (@arg_hashes) {

        # Need to capture the trace file handle early
        my $value;
        if ( defined( $value = $arg_hash->{trace_file_handle} ) ) {
            delete $arg_hash->{trace_file_handle};
            $trace_file_handle = $value;
        }
        if ( defined( $value = $arg_hash->{grammar} ) ) {
            delete $arg_hash->{grammar};
            $grammar = $value;
        }
    } ## end for my $arg_hash (@arg_hashes)
    Marpa::R2::exception('No grammar specified') if not defined $grammar;

    $trace_file_handle //= $grammar->[Marpa::R2::Internal::Grammar::TRACE_FILE_HANDLE] ;
    local $Marpa::R2::Internal::TRACE_FH =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE] = $trace_file_handle;

    $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR] = $grammar;

    my $grammar_class = ref $grammar;
    Marpa::R2::exception(
        "${class}::new() grammar arg has wrong class: $grammar_class")
        if not $grammar_class eq 'Marpa::R2::Grammar';

    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $tracer    = $grammar->[Marpa::R2::Internal::Grammar::TRACER];

    my $problems = $grammar->[Marpa::R2::Internal::Grammar::PROBLEMS];
    if ($problems) {
        Marpa::R2::exception(
            Marpa::R2::Grammar::show_problems($grammar),
            "Attempt to parse grammar with fatal problems\n",
            'Marpa::R2 cannot proceed',
        );
    } ## end if ($problems)

    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C] =
        Marpa::R2::Thin::R->new($grammar_c);
    if ( not defined $recce_c ) {
        my $error_code = $grammar_c->error_code() // -1;
        if ( $error_code == $Marpa::R2::Error::NOT_PRECOMPUTED ) {
            Marpa::R2::exception(
                'Attempt to parse grammar which is not precomputed');
        }
        Marpa::R2::exception( $grammar_c->error() );
    } ## end if ( not defined $recce_c )

    $recce_c->ruby_slippers_set(1);

    if (   defined $grammar->[Marpa::R2::Internal::Grammar::ACTION_OBJECT]
        or defined $grammar->[Marpa::R2::Internal::Grammar::ACTIONS]
        or not defined $grammar->[Marpa::R2::Internal::Grammar::INTERNAL] )
    {
        $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE] =
            'legacy';
    } ## end if ( defined $grammar->[...])

    ARG_HASH: for my $arg_hash (@arg_hashes) {
        if ( defined( my $value = $arg_hash->{'leo'} ) ) {
            my $boolean = $value ? 1 : 0;
            $recce->use_leo_set($boolean);
            delete $arg_hash->{leo};
        }
    } ## end ARG_HASH: for my $arg_hash (@arg_hashes)

    ARG_HASH: for my $arg_hash (@arg_hashes) {
        if ( defined( my $value = $arg_hash->{'event_if_expected'} ) ) {
            Marpa::R2::exception(
                'value of "event_if_expected" must be a REF to an array of symbol names'
            ) if ref $value ne 'ARRAY';
            for my $symbol_name ( @{$value} ) {
                my $symbol_id = $tracer->symbol_by_name($symbol_name);
                Marpa::exception(
                    qq{Unknown symbol in "event_if_expected" value: "$symbol_name"}
                ) if not defined $symbol_id;
                $recce_c->expected_symbol_event_set( $symbol_id, 1 );
            } ## end for my $symbol_name ( @{$value} )
            delete $arg_hash->{event_if_expected};
        } ## end if ( defined( my $value = $arg_hash->{'event_if_expected'...}))
    } ## end ARG_HASH: for my $arg_hash (@arg_hashes)

    $recce->[Marpa::R2::Internal::Recognizer::WARNINGS]       = 1;
    $recce->[Marpa::R2::Internal::Recognizer::RANKING_METHOD] = 'none';
    $recce->[Marpa::R2::Internal::Recognizer::MAX_PARSES]     = 0;

    # Position 0 is not used because 0 indicates an unvalued token.
    # Position 1 is reserved for undef.
    # Position 2 is reserved for literal tokens (used in SLIF).
    $recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES] = [undef, undef, undef];

    $recce->reset_evaluation();

    if ( not $recce_c->start_input() ) {
        my $error = $grammar_c->error();
        Marpa::R2::exception( 'Recognizer start of input failed: ', $error );
    }
    $recce->[Marpa::R2::Internal::Recognizer::EVENTS] = cook_events($recce);

    $recce->set(@arg_hashes);

    my $trace_terminals =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_TERMINALS] // 0;
    if ( $trace_terminals > 1 ) {
        my @terminals_expected = @{ $recce->terminals_expected() };
        for my $terminal ( sort @terminals_expected ) {
            say {$Marpa::R2::Internal::TRACE_FH}
                qq{Expecting "$terminal" at earleme 0}
                or Marpa::R2::exception("Cannot print: $ERRNO");
        }
    } ## end if ( $trace_terminals > 1 )

    return $recce;
} ## end sub Marpa::R2::Recognizer::new

# Not documented, at least for the moment
sub Marpa::R2::Recognizer::grammar {
    $_[0]->[Marpa::R2::Internal::Recognizer::GRAMMAR];
}

sub Marpa::R2::Recognizer::thin {
    $_[0]->[Marpa::R2::Internal::Recognizer::C];
}

sub Marpa::R2::Recognizer::reset_evaluation {
    my ($recce) = @_;
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $package_source =
        $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE];
    if ( defined $package_source and $package_source ne 'legacy' ) {

        # Packaage source, once legacy, stays legacy
        # Otherwise, reset it
        $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE] =
            undef;
    } ## end if ( defined $package_source and $package_source ne ...)
    $recce->[Marpa::R2::Internal::Recognizer::NO_PARSE]          = undef;
    $recce->[Marpa::R2::Internal::Recognizer::ASF_OR_NODES]          = [];
    $recce->[Marpa::R2::Internal::Recognizer::B_C]                   = undef;
    $recce->[Marpa::R2::Internal::Recognizer::EVENTS]                = [];
    $recce->[Marpa::R2::Internal::Recognizer::O_C]                   = undef;
    $recce->[Marpa::R2::Internal::Recognizer::PER_PARSE_CONSTRUCTOR] = undef;
    $recce->[Marpa::R2::Internal::Recognizer::READ_STRING_ERROR]     = undef;
    $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE]       = undef;
    $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES]        = undef;

    $recce->[Marpa::R2::Internal::Recognizer::REGISTRATIONS]         = undef;
    $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_SYMBOL_ID] = undef;
    $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_RULE_ID]   = undef;

    $recce->[Marpa::R2::Internal::Recognizer::T_C] = undef;
    $recce->[Marpa::R2::Internal::Recognizer::TREE_MODE] = undef;
    return;
} ## end sub Marpa::R2::Recognizer::reset_evaluation

sub Marpa::R2::Recognizer::set {
    my ( $recce, @arg_hashes ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];

    # This may get changed below
    my $trace_fh =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE];

    for my $args (@arg_hashes) {

        my $ref_type = ref $args;
        if ( not $ref_type or $ref_type ne 'HASH' ) {
            Carp::croak(
                'Marpa::R2 Recognizer expects args as ref to HASH, got ',
                ( "ref to $ref_type" || 'non-reference' ),
                ' instead'
            );
        } ## end if ( not $ref_type or $ref_type ne 'HASH' )

        state $recognizer_options = {
            map { ( $_, 1 ) }
                qw(
                closures
                end
                event_if_expected
                leo
                max_parses
                semantics_package
                ranking_method
                too_many_earley_items
                trace_actions
                trace_and_nodes
                trace_bocage
                trace_earley_sets
                trace_fh
                trace_file_handle
                trace_or_nodes
                trace_terminals
                trace_values
                warnings
                )
        };

        if (my @bad_options =
            grep { not exists $recognizer_options->{$_} }
            keys %{$args}
            )
        {
            Carp::croak( 'Unknown option(s) for Marpa::R2 Recognizer: ',
                join q{ }, @bad_options );
        } ## end if ( my @bad_options = grep { not exists $recognizer_options...})

        if ( defined( my $value = $args->{'event_if_expected'} ) ) {
            ## It could be allowed, but it is not needed and this is simpler
            Marpa::R2::exception(
                q{'event_if_expected' not allowed once input has started});
        }

        if ( defined( my $value = $args->{'leo'} ) ) {
            Marpa::R2::exception(
                q{Cannot reset 'leo' once input has started});
        }

        if ( defined( my $value = $args->{'max_parses'} ) ) {
            $recce->[Marpa::R2::Internal::Recognizer::MAX_PARSES] = $value;
        }

        if ( defined( my $value = $args->{'semantics_package'} ) ) {

            # Not allowed once parsing is started
            if ( defined $recce->[Marpa::R2::Internal::Recognizer::B_C] ) {
                Marpa::R2::exception(
                    q{Cannot change 'semantics_package' named argument once parsing has started}
                );
            }

            $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE]
                //= 'semantics_package';
            if ( $recce
                ->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE] ne
                'semantics_package' )
            {
                Marpa::R2::exception(
                    qq{'semantics_package' named argument in conflict with other choices\n},
                    qq{   Usually this means you tried to use the discouraged 'action_object' named argument as well\n}
                );
            } ## end if ( $recce->[...])
            $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE] =
                $value;
        } ## end if ( defined( my $value = $args->{'semantics_package'...}))

        if ( defined( my $value = $args->{'ranking_method'} ) ) {

            # Not allowed once parsing is started
            if ( defined $recce->[Marpa::R2::Internal::Recognizer::B_C] ) {
                Marpa::R2::exception(
                    q{Cannot change ranking method once parsing has started});
            }
            state $ranking_methods = { map { ($_, 0) } qw(high_rule_only rule none) };
            Marpa::R2::exception(
                qq{ranking_method value is $value (should be one of },
                ( join q{, }, map { q{'} . $_ . q{'} } keys %{$ranking_methods} ),
                ')' )
                if not exists $ranking_methods->{$value};
            $recce->[Marpa::R2::Internal::Recognizer::RANKING_METHOD] =
                $value;
        } ## end if ( defined( my $value = $args->{'ranking_method'} ...))

        if ( defined( my $value = $args->{'trace_fh'} ) ) {
            $trace_fh =
                $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE] =
                $value;
        }

        if ( defined( my $value = $args->{'trace_file_handle'} ) ) {
            $trace_fh =
                $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE] =
                $value;
        }

        if ( defined( my $value = $args->{'trace_actions'} ) ) {
            $recce->[Marpa::R2::Internal::Recognizer::TRACE_ACTIONS] = $value;
            if ($value) {
                say {$trace_fh} 'Setting trace_actions option'
                    or Marpa::R2::exception("Cannot print: $ERRNO");
            }
        } ## end if ( defined( my $value = $args->{'trace_actions'} ))

        if ( defined( my $value = $args->{'trace_and_nodes'} ) ) {
            Marpa::R2::exception(
                'trace_and_nodes must be set to a number >= 0')
                if $value !~ /\A\d+\z/xms;
            $recce->[Marpa::R2::Internal::Recognizer::TRACE_AND_NODES] =
                $value + 0;
            if ($value) {
                say {$trace_fh} "Setting trace_and_nodes option to $value"
                    or Marpa::R2::exception("Cannot print: $ERRNO");
            }
        } ## end if ( defined( my $value = $args->{'trace_and_nodes'}...))

        if ( defined( my $value = $args->{'trace_bocage'} ) ) {
            Marpa::R2::exception('trace_bocage must be set to a number >= 0')
                if $value !~ /\A\d+\z/xms;
            $recce->[Marpa::R2::Internal::Recognizer::TRACE_BOCAGE] =
                $value + 0;
            if ($value) {
                say {$trace_fh} "Setting trace_bocage option to $value"
                    or Marpa::R2::exception("Cannot print: $ERRNO");
            }
        } ## end if ( defined( my $value = $args->{'trace_bocage'} ) )

        if ( defined( my $value = $args->{'trace_or_nodes'} ) ) {
            Marpa::R2::exception(
                'trace_or_nodes must be set to a number >= 0')
                if $value !~ /\A\d+\z/xms;
            $recce->[Marpa::R2::Internal::Recognizer::TRACE_OR_NODES] =
                $value + 0;
            if ($value) {
                say {$trace_fh} "Setting trace_or_nodes option to $value"
                    or Marpa::R2::exception("Cannot print: $ERRNO");
            }
        } ## end if ( defined( my $value = $args->{'trace_or_nodes'} ...))

        if ( defined( my $value = $args->{'trace_terminals'} ) ) {
            $recce->[Marpa::R2::Internal::Recognizer::TRACE_TERMINALS] =
                $value;
            if ($value) {
                say {$trace_fh} 'Setting trace_terminals option'
                    or Marpa::R2::exception("Cannot print: $ERRNO");
            }
        } ## end if ( defined( my $value = $args->{'trace_terminals'}...))

        if ( defined( my $value = $args->{'trace_earley_sets'} ) ) {
            $recce->[Marpa::R2::Internal::Recognizer::TRACE_EARLEY_SETS] =
                $value;
            if ($value) {
                say {$trace_fh} 'Setting trace_earley_sets option'
                    or Marpa::R2::exception("Cannot print: $ERRNO");
            }
        } ## end if ( defined( my $value = $args->{'trace_earley_sets'...}))

        if ( defined( my $value = $args->{'trace_values'} ) ) {
            $recce->[Marpa::R2::Internal::Recognizer::TRACE_VALUES] = $value;
            if ($value) {
                say {$trace_fh} 'Setting trace_values option'
                    or Marpa::R2::exception("Cannot print: $ERRNO");
            }
        } ## end if ( defined( my $value = $args->{'trace_values'} ) )

        if ( defined( my $value = $args->{'end'} ) ) {

            # Not allowed once evaluation is started
            if ( defined $recce->[Marpa::R2::Internal::Recognizer::B_C] ) {
                Marpa::R2::exception(
                    q{Cannot reset end once evaluation has started});
            }
            $recce->[Marpa::R2::Internal::Recognizer::END_OF_PARSE] = $value;
        } ## end if ( defined( my $value = $args->{'end'} ) )

        if ( defined( my $value = $args->{'closures'} ) ) {

            # Not allowed once evaluation is started
            if ( defined $recce->[Marpa::R2::Internal::Recognizer::B_C] ) {
                Marpa::R2::exception(
                    q{Cannot reset closures once evaluation has started});
            }
            my $closures =
                $recce->[Marpa::R2::Internal::Recognizer::CLOSURES] = $value;
            for my $action ( keys %{$closures} ) {
                my $closure = $closures->{$action};
                Marpa::R2::exception(qq{Bad closure for action "$action"})
                    if ref $closure ne 'CODE';
            }
        } ## end if ( defined( my $value = $args->{'closures'} ) )

        if ( defined( my $value = $args->{'warnings'} ) ) {
            $recce->[Marpa::R2::Internal::Recognizer::WARNINGS] = $value;
        }

        if ( defined( my $value = $args->{'too_many_earley_items'} ) ) {
            $recce_c->earley_item_warning_threshold_set($value);
        }

    } ## end for my $args (@arg_hashes)

    return 1;
} ## end sub Marpa::R2::Recognizer::set

sub Marpa::R2::Recognizer::latest_earley_set {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    return $recce_c->latest_earley_set();
}

sub Marpa::R2::Recognizer::check_terminal {
    my ( $recce, $name ) = @_;
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    return $grammar->check_terminal($name);
}

sub Marpa::R2::Recognizer::exhausted {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    return $recce_c->is_exhausted();
}

sub Marpa::R2::Recognizer::current_earleme {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    return $recce_c->current_earleme();
}

sub Marpa::R2::Recognizer::furthest_earleme {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    return $recce_c->furthest_earleme();
}

sub Marpa::R2::Recognizer::earleme {
    my ( $recce, $earley_set_id ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    return $recce_c->earleme($earley_set_id);
}

sub Marpa::R2::Recognizer::expected_symbol_event_set {
    my ( $recce, $symbol_name, $value ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $symbol_id =
        $grammar->[Marpa::R2::Internal::Grammar::TRACER]
        ->symbol_by_name($symbol_name);
    Marpa::exception(qq{Unknown symbol: "$symbol_name"})
        if not defined $symbol_id;
    return $recce_c->expected_symbol_event_set( $symbol_id, $value );
} ## end sub Marpa::R2::Recognizer::expected_symbol_event_set

# Now useless and deprecated
sub Marpa::R2::Recognizer::strip { return 1; }

# Viewing methods, for debugging

sub Marpa::R2::Recognizer::progress {
    my ( $recce, $ordinal_arg ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $latest_earley_set = $recce->latest_earley_set();
    my $ordinal;
    SET_ORDINAL: {
        if ( not defined $ordinal_arg ) {
            $ordinal = $latest_earley_set;
            last SET_ORDINAL;
        }
        if ( $ordinal_arg > $latest_earley_set ) {
            Marpa::R2::exception(
                qq{Argument out of bounds in recce->progress($ordinal_arg)\n},
                qq{   Argument specifies Earley set after the latest Earley set 0\n},
                qq{   The latest Earley set is Earley set $latest_earley_set\n}
            );
        } ## end if ( $ordinal_arg > $latest_earley_set )
        if ( $ordinal_arg >= 0 ) {
            $ordinal = $ordinal_arg;
            last SET_ORDINAL;
        }

        # If we are here, $ordinal_arg < 0
        $ordinal = $latest_earley_set + 1 + $ordinal_arg;
        Marpa::R2::exception(
            qq{Argument out of bounds in recce->progress($ordinal_arg)\n},
            qq{   Argument specifies Earley set before Earley set 0\n}
        ) if $ordinal < 0;
    } ## end SET_ORDINAL:
    my $result = [];
    $recce_c->progress_report_start($ordinal);
    ITEM: while (1) {
        my @item = $recce_c->progress_item();
        last ITEM if not defined $item[0];
        push @{$result}, [@item];
    }
    $recce_c->progress_report_finish();
    return $result;
} ## end sub Marpa::R2::Recognizer::progress

sub Marpa::R2::Recognizer::show_progress {
    my ( $recce, $start_ordinal, $end_ordinal ) = @_;
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];

    my $last_ordinal = $recce->latest_earley_set();

    if ( not defined $start_ordinal ) {
        $start_ordinal = $last_ordinal;
    }
    if ( $start_ordinal < 0 ) {
        $start_ordinal += $last_ordinal + 1;
    }
    else {
        if ( $start_ordinal < 0 or $start_ordinal > $last_ordinal ) {
            return
                "Marpa::PP::Recognizer::show_progress start index is $start_ordinal, "
                . "must be in range 0-$last_ordinal";
        }
    } ## end else [ if ( $start_ordinal < 0 ) ]

    if ( not defined $end_ordinal ) {
        $end_ordinal = $start_ordinal;
    }
    else {
        my $end_ordinal_argument = $end_ordinal;
        if ( $end_ordinal < 0 ) {
            $end_ordinal += $last_ordinal + 1;
        }
        if ( $end_ordinal < 0 ) {
            return
                "Marpa::PP::Recognizer::show_progress end index is $end_ordinal_argument, "
                . sprintf ' must be in range %d-%d', -( $last_ordinal + 1 ),
                $last_ordinal;
        } ## end if ( $end_ordinal < 0 )
    } ## end else [ if ( not defined $end_ordinal ) ]

    my $text = q{};
    for my $current_ordinal ( $start_ordinal .. $end_ordinal ) {
        my $current_earleme     = $recce->earleme($current_ordinal);
        my %by_rule_by_position = ();
        for my $progress_item ( @{ $recce->progress($current_ordinal) } ) {
            my ( $rule_id, $position, $origin ) = @{$progress_item};
            if ( $position < 0 ) {
                $position = $grammar_c->rule_length($rule_id);
            }
            $by_rule_by_position{$rule_id}->{$position}->{$origin}++;
        } ## end for my $progress_item ( @{ $recce->progress($current_ordinal...)})

        for my $rule_id ( sort { $a <=> $b } keys %by_rule_by_position ) {
            my $by_position = $by_rule_by_position{$rule_id};
            for my $position ( sort { $a <=> $b } keys %{$by_position} ) {
                my $raw_origins   = $by_position->{$position};
                my @origins       = sort { $a <=> $b } keys %{$raw_origins};
                my $origins_count = scalar @origins;
                my $origin_desc;
                if ( $origins_count <= 3 ) {
                    $origin_desc = join q{,}, @origins;
                }
                else {
                    $origin_desc = $origins[0] . q{...} . $origins[-1];
                }

                my $rhs_length = $grammar_c->rule_length($rule_id);
                my $item_text;

                # flag indicating whether we need to show the dot in the rule
                if ( $position >= $rhs_length ) {
                    $item_text .= "F$rule_id";
                }
                elsif ($position) {
                    $item_text .= "R$rule_id:$position";
                }
                else {
                    $item_text .= "P$rule_id";
                }
                $item_text .= " x$origins_count" if $origins_count > 1;
                $item_text
                    .= q{ @} . $origin_desc . q{-} . $current_earleme . q{ };
                $item_text
                    .= $grammar->show_dotted_rule( $rule_id, $position );
                $text .= $item_text . "\n";
            } ## end for my $position ( sort { $a <=> $b } keys %{...})
        } ## end for my $rule_id ( sort { $a <=> $b } keys ...)

    } ## end for my $current_ordinal ( $start_ordinal .. $end_ordinal)
    return $text;
} ## end sub Marpa::R2::Recognizer::show_progress

sub Marpa::R2::Recognizer::read {
    my $arg_count = scalar @_;
    my ( $recce, $symbol_name, $value ) = @_;
    return if not $recce->alternative( $symbol_name, \$value );
    return $recce->earleme_complete();
} ## end sub Marpa::R2::Recognizer::read

sub Marpa::R2::Recognizer::alternative {

    my ( $recce, $symbol_name, $value_ref, $length ) = @_;

    Marpa::R2::exception(
        'No recognizer object for Marpa::R2::Recognizer::tokens')
        if not defined $recce
            or ref $recce ne 'Marpa::R2::Recognizer';

    Marpa::R2::exception(
        "recce->alternative(): symbol name is undefined\n",
        "    The symbol name cannot be undefined\n"
    ) if not defined $symbol_name;

    Marpa::R2::exception('Attempt to read token after parsing is finished')
        if $recce->[Marpa::R2::Internal::Recognizer::FINISHED];

    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $trace_fh =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $token_values =
        $recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES];
    my $symbol_id =
        $grammar->[Marpa::R2::Internal::Grammar::TRACER]
        ->symbol_by_name($symbol_name);

    if ( not defined $symbol_id ) {
        Marpa::R2::exception(
            qq{alternative(): symbol "$symbol_name" does not exist});
    }

    my $value_ix = 1; # undef
    SET_VALUE_IX: {
        last SET_VALUE_IX if not defined $value_ref;
        my $ref_type = ref $value_ref;
        if (    $ref_type ne 'SCALAR'
            and $ref_type ne 'REF'
            and $ref_type ne 'VSTRING' )
        {
            Marpa::R2::exception('alternative(): value must be undef or ref');
        } ## end if ( $ref_type ne 'SCALAR' and $ref_type ne 'REF' and...)
        my $value = ${$value_ref};
        last SET_VALUE_IX if not defined $value;
        $value_ix = scalar @{$token_values};
        push @{$token_values}, $value;
    } ## end SET_VALUE_IX:
    $length //= 1;

    # value_ix is *never* zero.
    my $result = $recce_c->alternative( $symbol_id, $value_ix, $length );

    my $trace_terminals =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_TERMINALS];
    if ($trace_terminals) {
        my $verb =
            $result == $Marpa::R2::Error::NONE ? 'Accepted' : 'Rejected';
        my $current_earleme = $recce_c->current_earleme();
        say {$trace_fh} qq{$verb "$symbol_name" at $current_earleme-}
            . ( $length + $current_earleme )
            or Marpa::R2::exception("Cannot print: $ERRNO");
    } ## end if ($trace_terminals)

    return 1 if $result == $Marpa::R2::Error::NONE;

    # The last two are perhaps unnecessary or arguable,
    # but they preserve compatibility with Marpa::XS
    return
        if $result == $Marpa::R2::Error::UNEXPECTED_TOKEN_ID
            || $result == $Marpa::R2::Error::NO_TOKEN_EXPECTED_HERE
            || $result == $Marpa::R2::Error::INACCESSIBLE_TOKEN;

    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    Marpa::R2::exception( $grammar_c->error() );

} ## end sub Marpa::R2::Recognizer::alternative

# Perform the completion step on an earley set

sub Marpa::R2::Recognizer::end_input {
    my ($recce)          = @_;
    my $recce_c          = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $furthest_earleme = $recce_c->furthest_earleme();
    while ( $recce_c->current_earleme() < $furthest_earleme ) {
        $recce->earleme_complete();
    }
    $recce->[Marpa::R2::Internal::Recognizer::FINISHED] = 1;
    return 1;
} ## end sub Marpa::R2::Recognizer::end_input

sub Marpa::R2::Recognizer::terminals_expected {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    return [ map { $grammar->symbol_name($_) }
            $recce_c->terminals_expected() ];
} ## end sub Marpa::R2::Recognizer::terminals_expected

sub cook_events {
    my ($recce)   = @_;
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];

    my @cooked_events = ();
    my $event_count   = $grammar_c->event_count();
    EVENT: for ( my $event_ix = 0; $event_ix < $event_count; $event_ix++ ) {
        my ( $event_type, $value ) = $grammar_c->event($event_ix);
        if ( $event_type eq 'MARPA_EVENT_EARLEY_ITEM_THRESHOLD' ) {
            say {
                $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE] }
                "Earley item count ($value) exceeds warning threshold"
                or die "say: $ERRNO";
            push @cooked_events, ['EARLEY_ITEM_THRESHOLD'];
            next EVENT;
        } ## end if ( $event_type eq 'MARPA_EVENT_EARLEY_ITEM_THRESHOLD')
        if ( $event_type eq 'MARPA_EVENT_SYMBOL_EXPECTED' ) {
            push @cooked_events,
                [ 'SYMBOL_EXPECTED', $grammar->symbol_name($value) ];
            next EVENT;
        }
        if ( $event_type eq 'MARPA_EVENT_EXHAUSTED' ) {
            push @cooked_events, ['EXHAUSTED'];
            next EVENT;
        }
    } ## end EVENT: for ( my $event_ix = 0; $event_ix < $event_count; ...)
    return \@cooked_events;
} ## end sub cook_events

sub Marpa::R2::Recognizer::earleme_complete {
    my ($recce) = @_;

    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    local $Marpa::R2::Internal::TRACE_FH =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];

    my $event_count = $recce_c->earleme_complete();
    $recce->[Marpa::R2::Internal::Recognizer::EVENTS] =
        $event_count ? cook_events($recce) : [];

    if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_EARLEY_SETS] ) {
        my $latest_set = $recce_c->latest_earley_set();
        print {$Marpa::R2::Internal::TRACE_FH} "=== Earley set $latest_set\n"
            or Marpa::R2::exception("Cannot print: $ERRNO");
        print {$Marpa::R2::Internal::TRACE_FH}
            Marpa::R2::show_earley_set($latest_set)
            or Marpa::R2::exception("Cannot print: $ERRNO");
    } ## end if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_EARLEY_SETS...])

    my $trace_terminals =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_TERMINALS] // 0;
    if ( $trace_terminals > 1 ) {
        my $current_earleme    = $recce_c->current_earleme();
        my $terminals_expected = $recce->terminals_expected();
        for my $terminal ( @{$terminals_expected} ) {
            say {$Marpa::R2::Internal::TRACE_FH}
                qq{Expecting "$terminal" at $current_earleme}
                or Marpa::R2::exception("Cannot print: $ERRNO");
        }
    } ## end if ( $trace_terminals > 1 )

    return $event_count;

} ## end sub Marpa::R2::Recognizer::earleme_complete

sub Marpa::R2::Recognizer::events {
    my ($recce) = @_;
    return $recce->[Marpa::R2::Internal::Recognizer::EVENTS];
}

my @escape_by_ord = ();
$escape_by_ord[ ord q{\\} ] = q{\\\\};
$escape_by_ord[ ord eval qq{"$_"} ] = $_
    for "\\t", "\\r", "\\f", "\\b", "\\a", "\\e";
$escape_by_ord[0xa] = '\\n';
$escape_by_ord[$_] //= chr $_ for 32 .. 126;
$escape_by_ord[$_] //= sprintf( "\\x%02x", $_ ) for 0 .. 255;

sub Marpa::R2::escape_string {
    my ( $string, $length ) = @_;
    my $reversed = $length < 0;
    if ($reversed) {
        $string = reverse $string;
        $length = -$length;
    }
    my @escaped_chars = ();
    ORD: for my $ord ( map {ord} split //xms, $string ) {
        last ORD if $length <= 0;
        my $escaped_char = $escape_by_ord[$ord] // sprintf( "\\x{%04x}", $ord );
        $length -= length $escaped_char;
        push @escaped_chars, $escaped_char;
    } ## end for my $ord ( map {ord} split //xms, $string )
    @escaped_chars = reverse @escaped_chars if $reversed;
    IX: for my $ix ( reverse 0 .. $#escaped_chars ) {

        # only trailing spaces are escaped
        last IX if $escaped_chars[$ix] ne q{ };
        $escaped_chars[$ix] = '\\s';
    } ## end IX: for my $ix ( reverse 0 .. $#escaped_chars )
    return join q{}, @escaped_chars;
} ## end sub escape_string

# INTERNAL OK AFTER HERE _marpa_

sub Marpa::R2::Recognizer::use_leo_set {
    my ( $recce, $boolean ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    return $recce_c->_marpa_r_is_use_leo_set($boolean);
}

# Not intended to be documented.
# Returns the size of the last completed earley set.
# For testing, especially that the Leo items
# are doing their job.
sub Marpa::R2::Recognizer::earley_set_size {
    my ( $recce, $set_id ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    $set_id //= $recce_c->latest_earley_set();
    return $recce_c->_marpa_r_earley_set_size($set_id);
}

sub ahm_describe {
    my ($recce, $ahm_id)        = @_;
    my $recce_c        = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar        = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $irl_id = $grammar_c->_marpa_g_ahm_irl($ahm_id);
    my $dot_position = $grammar_c->_marpa_g_ahm_position($ahm_id);
    if ($dot_position < 0) { return 'R' . $irl_id . q{$} }
    return 'R' . $irl_id . q{:} . $dot_position;
}

sub Marpa::R2::show_leo_item {
    my ($recce)        = @_;
    my $recce_c        = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar        = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $tracer         = $grammar->[Marpa::R2::Internal::Grammar::TRACER];
    my $leo_base_state = $recce_c->_marpa_r_leo_base_state();
    return if not defined $leo_base_state;
    my $trace_earley_set      = $recce_c->_marpa_r_trace_earley_set();
    my $trace_earleme         = $recce_c->earleme($trace_earley_set);
    my $postdot_symbol_id     = $recce_c->_marpa_r_postdot_item_symbol();
    my $postdot_symbol_name   = $tracer->isy_name($postdot_symbol_id);
    my $predecessor_symbol_id = $recce_c->_marpa_r_leo_predecessor_symbol();
    my $base_origin_set_id    = $recce_c->_marpa_r_leo_base_origin();
    my $base_origin_earleme   = $recce_c->earleme($base_origin_set_id);

    my $text = sprintf 'L%d@%d', $postdot_symbol_id, $trace_earleme;
    my @link_texts = qq{"$postdot_symbol_name"};
    if ( defined $predecessor_symbol_id ) {
        push @link_texts, sprintf 'L%d@%d', $predecessor_symbol_id,
            $base_origin_earleme;
    }
    push @link_texts, sprintf 'S%d@%d-%d', $leo_base_state,
        $base_origin_earleme,
        $trace_earleme;
    $text .= ' [' . ( join '; ', @link_texts ) . ']';
    return $text;
} ## end sub Marpa::R2::show_leo_item

# Assumes trace token source link set by caller
sub Marpa::R2::show_token_link_choice {
    my ( $recce, $current_earleme ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $tracer  = $grammar->[Marpa::R2::Internal::Grammar::TRACER];
    my $text    = q{};
    my @pieces  = ();
    my ( $token_id, $value_ix ) = $recce_c->_marpa_r_source_token();
    my $predecessor_ahm = $recce_c->_marpa_r_source_predecessor_state();
    my $origin_set_id     = $recce_c->_marpa_r_earley_item_origin();
    my $origin_earleme    = $recce_c->earleme($origin_set_id);
    my $middle_earleme    = $origin_earleme;

    if ( defined $predecessor_ahm ) {
        my $middle_set_id = $recce_c->_marpa_r_source_middle();
        $middle_earleme = $recce_c->earleme($middle_set_id);
        push @pieces,
              'c='
            . ahm_describe($recce, $predecessor_ahm)
            . q{@}
            . $origin_earleme . q{-}
            . $middle_earleme;
    } ## end if ( defined $predecessor_ahm )
    my $symbol_name = $tracer->isy_name($token_id);
    push @pieces, 's=' . $symbol_name;
    my $token_length = $current_earleme - $middle_earleme;
    my $value =
        $recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES]->[$value_ix];
    my $token_dump = Data::Dumper->new( [ \$value ] )->Terse(1)->Dump;
    chomp $token_dump;
    push @pieces, "t=$token_dump";
    return '[' . ( join '; ', @pieces ) . ']';
} ## end sub Marpa::R2::show_token_link_choice

# Assumes trace completion source link set by caller
sub Marpa::R2::show_completion_link_choice {
    my ( $recce, $link_ahm_id, $current_earleme ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $symbols = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $text    = q{};
    my @pieces  = ();
    my $predecessor_state = $recce_c->_marpa_r_source_predecessor_state();
    my $origin_set_id     = $recce_c->_marpa_r_earley_item_origin();
    my $origin_earleme    = $recce_c->earleme($origin_set_id);
    my $middle_set_id     = $recce_c->_marpa_r_source_middle();
    my $middle_earleme    = $recce_c->earleme($middle_set_id);

    if ( defined $predecessor_state ) {
        push @pieces,
              'p='
            . ahm_describe($recce, $predecessor_state) . q{@}
            . $origin_earleme . q{-}
            . $middle_earleme;
    } ## end if ( defined $predecessor_state )
    push @pieces,
          'c=' . ahm_describe($recce, $link_ahm_id) . q{@}
        . $middle_earleme . q{-}
        . $current_earleme;
    return '[' . ( join '; ', @pieces ) . ']';
} ## end sub Marpa::R2::show_completion_link_choice

# Assumes trace completion source link set by caller
sub Marpa::R2::show_leo_link_choice {
    my ( $recce, $link_ahm_id, $current_earleme ) = @_;
    my $recce_c        = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar        = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $symbols        = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $text           = q{};
    my @pieces         = ();
    my $middle_set_id  = $recce_c->_marpa_r_source_middle();
    my $middle_earleme = $recce_c->earleme($middle_set_id);
    my $leo_transition_symbol =
        $recce_c->_marpa_r_source_leo_transition_symbol();
    push @pieces, 'l=L' . $leo_transition_symbol . q{@} . $middle_earleme;
    push @pieces,
          'c=' . ahm_describe($recce, $link_ahm_id)
        . q{@}
        . $middle_earleme . q{-}
        . $current_earleme;
    return '[' . ( join '; ', @pieces ) . ']';
} ## end sub Marpa::R2::show_leo_link_choice

# Assumes trace earley item was set by caller
sub Marpa::R2::show_earley_item {
    my ( $recce, $current_es, $item_id ) = @_;
    my $recce_c        = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $tracer    = $grammar->[Marpa::R2::Internal::Grammar::TRACER];

    my $ahm_id_of_yim = $recce_c->_marpa_r_earley_item_trace($item_id);
    return if not defined $ahm_id_of_yim;

    my $text           = q{};
    my $origin_set_id  = $recce_c->_marpa_r_earley_item_origin();
    my $earleme        = $recce_c->earleme($current_es);
    my $origin_earleme = $recce_c->earleme($origin_set_id);
    $text .= sprintf "ahm%d: %s@%d-%d", $ahm_id_of_yim,
        ahm_describe($recce, $ahm_id_of_yim),
        $origin_earleme, $earleme;
    my @lines    = $text;
    my $irl_id = $grammar_c->_marpa_g_ahm_irl($ahm_id_of_yim);
    my $dot_position = $grammar_c->_marpa_g_ahm_position($ahm_id_of_yim);
    push @lines, qq{  }
        . ahm_describe($recce, $ahm_id_of_yim)
        . q{: }
        . $tracer->show_dotted_irl($irl_id, $dot_position);
    my @sort_data = ();

    for (
        my $symbol_id = $recce_c->_marpa_r_first_token_link_trace();
        defined $symbol_id;
        $symbol_id = $recce_c->_marpa_r_next_token_link_trace()
        )
    {
        push @sort_data,
            [
            $recce_c->_marpa_r_source_middle(),
            $symbol_id,
            ( $recce_c->_marpa_r_source_predecessor_state() // -1 ),
            Marpa::R2::show_token_link_choice( $recce, $earleme )
            ];
    } ## end for ( my $symbol_id = $recce_c->_marpa_r_first_token_link_trace...)
    my @pieces = map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            || $a->[1] <=> $b->[1]
            || $a->[2] <=> $b->[2]
    } @sort_data;
    @sort_data = ();
    for (
        my $cause_AHFA_id = $recce_c->_marpa_r_first_completion_link_trace();
        defined $cause_AHFA_id;
        $cause_AHFA_id = $recce_c->_marpa_r_next_completion_link_trace()
        )
    {
        push @sort_data,
            [
            $recce_c->_marpa_r_source_middle(),
            $cause_AHFA_id,
            ( $recce_c->_marpa_r_source_predecessor_state() // -1 ),
            Marpa::R2::show_completion_link_choice(
                $recce, $cause_AHFA_id, $earleme
            )
            ];
    } ## end for ( my $cause_AHFA_id = $recce_c...)
    push @pieces, map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            || $a->[1] <=> $b->[1]
            || $a->[2] <=> $b->[2]
    } @sort_data;
    @sort_data = ();
    for (
        my $link_ahm_id = $recce_c->_marpa_r_first_leo_link_trace();
        defined $link_ahm_id;
        $link_ahm_id = $recce_c->_marpa_r_next_leo_link_trace()
        )
    {
        push @sort_data,
            [
            $recce_c->_marpa_r_source_middle(),
            $link_ahm_id,
            $recce_c->_marpa_r_source_leo_transition_symbol(),
            Marpa::R2::show_leo_link_choice(
                $recce, $link_ahm_id, $earleme
            )
            ];
    } ## end for ( my $link_ahm_id = $recce_c...)
    push @pieces, map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            || $a->[1] <=> $b->[1]
            || $a->[2] <=> $b->[2]
    } @sort_data;
    push @lines, q{  } . join q{ }, @pieces if @pieces;
    return join "\n", @lines, q{};
} ## end sub Marpa::R2::show_earley_item

sub Marpa::R2::show_earley_set {
    my ( $recce, $traced_set_id ) = @_;
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $text      = q{};
    my @sorted_data = ();
    if ( not defined $recce_c->_marpa_r_earley_set_trace($traced_set_id) ) {
        return $text;
    }
    EARLEY_ITEM: for ( my $item_id = 0;; $item_id++ ) {
        my $item_desc = Marpa::R2::show_earley_item( $recce, $traced_set_id, $item_id );
        last EARLEY_ITEM if not defined $item_desc;
        # We do not sort these any more
        push @sorted_data, $item_desc;
    } ## end EARLEY_ITEM: for ( my $item_id = 0;; $item_id++ )
    my @sort_data = ();
    POSTDOT_ITEM:
    for (
        my $postdot_symbol_id = $recce_c->_marpa_r_first_postdot_item_trace();
        defined $postdot_symbol_id;
        $postdot_symbol_id = $recce_c->_marpa_r_next_postdot_item_trace()
        )
    {

        # If there is no base Earley item,
        # then this is not a Leo item, so we skip it
        my $leo_item_desc = Marpa::R2::show_leo_item($recce);
        next POSTDOT_ITEM if not defined $leo_item_desc;
        push @sort_data, [ $postdot_symbol_id, $leo_item_desc ];
    } ## end POSTDOT_ITEM: for ( my $postdot_symbol_id = $recce_c...)
    push @sorted_data, join q{},
        map { $_->[-1] . "\n" } sort { $a->[0] <=> $b->[0] } @sort_data;
    return join q{}, @sorted_data;
} ## end sub Marpa::R2::show_earley_set

sub Marpa::R2::Recognizer::show_earley_sets {
    my ($recce)                = @_;
    my $recce_c                = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $last_completed_earleme = $recce_c->current_earleme();
    my $furthest_earleme       = $recce_c->furthest_earleme();
    my $text                   = "Last Completed: $last_completed_earleme; "
        . "Furthest: $furthest_earleme\n";
    LIST: for ( my $ix = 0;; $ix++ ) {
        my $set_desc = Marpa::R2::show_earley_set( $recce, $ix );
        last LIST if not $set_desc;
        $text .= "Earley Set $ix\n$set_desc";
    }
    return $text;
} ## end sub Marpa::R2::Recognizer::show_earley_sets

1;

# vim: set expandtab shiftwidth=4:
