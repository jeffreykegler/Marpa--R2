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

package Marpa::XS::Grammar;

use 5.010;

use warnings;

# There's a problem with this perlcritic check
# as of 9 Aug 2010
## no critic (TestingAndDebugging::ProhibitNoWarnings)
no warnings qw(recursion qw);
## use critic

use strict;

# It's all integers, except for the version number
use integer;
use utf8;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '0.019_002';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

=begin Implementation:

Structures and Objects: The design is to present an object-oriented
interface, but internally to avoid overheads.  So internally, where
objects might be used, I use array with constant indices to imitate
what in C would be structures.

=end Implementation:

=cut

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';
    :package=Marpa::XS::Internal::Symbol
    ID { Unique ID }
    NAME
    LHS_RANK
    TERMINAL_RANK
    NULL_VALUE { null value }
    WARN_IF_NO_NULL_VALUE { should have a null value -- warn
    if not }
END_OF_STRUCTURE
    Marpa::offset($structure);
} ## end BEGIN

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::XS::Internal::Rule

    ID
    NAME
    ACTION { action for this rule as specified by user }
    RANK
    CHAF_RANK
    NULL_RANKING

END_OF_STRUCTURE
    Marpa::offset($structure);
} ## end BEGIN

BEGIN {
    my $structure = <<'END_OF_STRUCTURE';

    :package=Marpa::XS::Internal::Grammar

    C { A C structure }
    ID { Unique ID, from libmarpa }

    RULES { array of rule refs }
    SYMBOLS { array of symbol refs }
    ACTIONS { Default package in which to find actions }
    DEFAULT_ACTION { Action for rules without one }
    DEFAULT_RANK { Rank for rules and symbols without one }
    TRACE_FILE_HANDLE
    WARNINGS { print warnings about grammar? }
    RULE_NAME_REQUIRED
    RULE_BY_NAME

    =LAST_BASIC_DATA_FIELD

    { === Evaluator Fields === }

    SYMBOL_HASH { hash to symbol ID by name of symbol }
    DEFAULT_NULL_VALUE { default value for nulled symbols }
    ACTION_OBJECT
    INFINITE_ACTION

    =LAST_EVALUATOR_FIELD

    PROBLEMS { fatal problems }

    =LAST_RECOGNIZER_FIELD

    START_NAME { name of original symbol }
    INACCESSIBLE_OK
    UNPRODUCTIVE_OK
    TRACE_RULES

    NEXT_SYMBOL_NAME {
        Should this be one of a hash of context values;
    }

    =LAST_FIELD

END_OF_STRUCTURE
    Marpa::offset($structure);
} ## end BEGIN

package Marpa::XS::Internal::Grammar;

use English qw( -no_match_vars );

sub Marpa::XS::Internal::code_problems {
    my $args = shift;

    my $grammar;
    my $fatal_error;
    my $warnings = [];
    my $where    = '?where?';
    my $long_where;
    my @msg = ();
    my $eval_value;
    my $eval_given = 0;

    push @msg, q{=} x 60, "\n";
    while ( my ( $arg, $value ) = each %{$args} ) {
        given ($arg) {
            when ('fatal_error') { $fatal_error = $value }
            when ('grammar')     { $grammar     = $value }
            when ('where')       { $where       = $value }
            when ('long_where')  { $long_where  = $value }
            when ('warnings')    { $warnings    = $value }
            when ('eval_ok') {
                $eval_value = $value;
                $eval_given = 1;
            }
            default { push @msg, "Unknown argument to code_problems: $arg" };
        } ## end given
    } ## end while ( my ( $arg, $value ) = each %{$args} )

    my @problem_line     = ();
    my $max_problem_line = -1;
    for my $warning_data ( @{$warnings} ) {
        my ( $warning, $package, $filename, $problem_line ) =
            @{$warning_data};
        $problem_line[$problem_line] = 1;
        $max_problem_line = List::Util::max $problem_line, $max_problem_line;
    } ## end for my $warning_data ( @{$warnings} )

    $long_where //= $where;

    my $warnings_count = scalar @{$warnings};
    {
        my @problems;
        my $false_eval = $eval_given && !$eval_value && !$fatal_error;
        if ($false_eval) {
            push @problems, '* THE MARPA SEMANTICS RETURNED A PERL FALSE',
                'Marpa::XS requires its semantics to return a true value';
        }
        if ($fatal_error) {
            push @problems, '* THE MARPA SEMANTICS PRODUCED A FATAL ERROR';
        }
        if ($warnings_count) {
            push @problems,
                "* THERE WERE $warnings_count WARNING(S) IN THE MARPA SEMANTICS:",
                'Marpa treats warnings as fatal errors';
        }
        if ( not scalar @problems ) {
            push @msg, '* THERE WAS A FATAL PROBLEM IN THE MARPA SEMANTICS';
        }
        push @msg, ( join "\n", @problems ) . "\n";
    }

    push @msg, "* THIS IS WHAT MARPA WAS DOING WHEN THE PROBLEM OCCURRED:\n"
        . $long_where . "\n";

    for my $warning_ix ( 0 .. ( $warnings_count - 1 ) ) {
        push @msg, "* WARNING MESSAGE NUMBER $warning_ix:\n";
        my $warning_message = $warnings->[$warning_ix]->[0];
        $warning_message =~ s/\n*\z/\n/xms;
        push @msg, $warning_message;
    } ## end for my $warning_ix ( 0 .. ( $warnings_count - 1 ) )

    if ($fatal_error) {
        push @msg, "* THIS WAS THE FATAL ERROR MESSAGE:\n";
        my $fatal_error_message = $fatal_error;
        $fatal_error_message =~ s/\n*\z/\n/xms;
        push @msg, $fatal_error_message;
    } ## end if ($fatal_error)

    push @msg, q{* ONE PLACE TO LOOK FOR THE PROBLEM IS IN THE CODE};
    Marpa::exception(@msg);

    # this is to keep perlcritic happy
    return 1;

} ## end sub Marpa::XS::Internal::code_problems

sub Marpa::XS::uncaught_error {
    my ($error) = @_;

    # This would be Carp::confess, but in the testing
    # the stack trace includes the hoped for error
    # message, which causes spurious success reports.
    Carp::croak(
        "libmarpa reported an error which Marpa::XS did not catch\n",
        qq{  The libmarpa internal error code was "$error"},
    );
} ## end sub Marpa::XS::uncaught_error

package Marpa::XS::Internal::Grammar;

my %grammar_by_id;

sub Marpa::XS::Grammar::new {
    my ( $class, @arg_hashes ) = @_;

    my $grammar = [];
    bless $grammar, $class;

    # set the defaults and the default defaults
    $grammar->[Marpa::XS::Internal::Grammar::TRACE_FILE_HANDLE] = *STDERR;

    $grammar->[Marpa::XS::Internal::Grammar::TRACE_RULES]     = 0;
    $grammar->[Marpa::XS::Internal::Grammar::WARNINGS]        = 1;
    $grammar->[Marpa::XS::Internal::Grammar::INACCESSIBLE_OK] = {};
    $grammar->[Marpa::XS::Internal::Grammar::UNPRODUCTIVE_OK] = {};
    $grammar->[Marpa::XS::Internal::Grammar::INFINITE_ACTION] = 'fatal';
    $grammar->[Marpa::XS::Internal::Grammar::DEFAULT_RANK]    = 0;

    $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS]            = [];
    $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH]        = {};
    $grammar->[Marpa::XS::Internal::Grammar::RULES]              = [];
    $grammar->[Marpa::XS::Internal::Grammar::RULE_BY_NAME]       = {};
    $grammar->[Marpa::XS::Internal::Grammar::RULE_NAME_REQUIRED] = 0;

    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C] =
        Marpa::XS::Internal::G_C->new($grammar);
    my $grammar_id = $grammar_c->id();
    $grammar->[Marpa::XS::Internal::Grammar::ID] = $grammar_id;
    $grammar_by_id{$grammar_id} = $grammar;
    Scalar::Util::weaken( $grammar_by_id{$grammar_id} );
    $grammar_c->message_callback_set( \&message_cb );
    $grammar_c->rule_callback_set( \&wrap_rule_cb );
    $grammar_c->symbol_callback_set( \&wrap_symbol_cb );
    $grammar_c->default_value_set(-1);

    $grammar->set(@arg_hashes);

    return $grammar;
} ## end sub Marpa::XS::Grammar::new

use constant GRAMMAR_OPTIONS => [
    qw{
        action_object
        actions
        infinite_action
        default_action
        default_null_value
        default_rank
        inaccessible_ok
        lhs_terminals
        rule_name_required
        rules
        start
        strip
        symbols
        terminals
        trace_file_handle
        trace_rules
        unproductive_ok
        warnings
        }
];

sub Marpa::XS::Grammar::set {
    my ( $grammar, @arg_hashes ) = @_;

    # set trace_fh even if no tracing, because we may turn it on in this method
    my $trace_fh =
        $grammar->[Marpa::XS::Internal::Grammar::TRACE_FILE_HANDLE];
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];

    for my $args (@arg_hashes) {

        my $ref_type = ref $args;
        if ( not $ref_type or $ref_type ne 'HASH' ) {
            Carp::croak(
                'Marpa::XS Grammar expects args as ref to HASH, got ',
                ( "ref to $ref_type" || 'non-reference' ),
                ' instead'
            );
        } ## end if ( not $ref_type or $ref_type ne 'HASH' )
        if (my @bad_options =
            grep { not $_ ~~ Marpa::XS::Internal::Grammar::GRAMMAR_OPTIONS }
            keys %{$args}
            )
        {
            Carp::croak( 'Unknown option(s) for Marpa::XS Grammar: ',
                join q{ }, @bad_options );
        } ## end if ( my @bad_options = grep { not $_ ~~ ...})

        if ( defined( my $value = $args->{'trace_file_handle'} ) ) {
            $grammar->[Marpa::XS::Internal::Grammar::TRACE_FILE_HANDLE] =
                $value;
        }

        if ( defined( my $value = $args->{'trace_rules'} ) ) {
            $grammar->[Marpa::XS::Internal::Grammar::TRACE_RULES] = $value;
            if ($value) {
                my $rules = $grammar->[Marpa::XS::Internal::Grammar::RULES];
                my $rule_count = @{$rules};
                say {$trace_fh} 'Setting trace_rules'
                    or Marpa::exception("Could not print: $ERRNO");
                if ($rule_count) {
                    say {$trace_fh}
                        "Warning: Setting trace_rules after $rule_count rules have been defined"
                        or Marpa::exception("Could not print: $ERRNO");
                }
            } ## end if ($value)
        } ## end if ( defined( my $value = $args->{'trace_rules'} ) )

        # First pass options: These affect processing of other
        # options and are expected to take force for the other
        # options, even if specified afterwards

        if ( defined( my $value = $args->{'default_rank'} ) ) {
            Marpa::exception(
                'terminals option not allowed after grammar is precomputed')
                if $grammar_c->is_precomputed();
            $grammar->[Marpa::XS::Internal::Grammar::DEFAULT_RANK] = $value;
        } ## end if ( defined( my $value = $args->{'default_rank'} ) )

        # Second pass options

        if ( defined( my $value = $args->{'symbols'} ) ) {
            Marpa::exception(
                'symbols option not allowed after grammar is precomputed')
                if $grammar_c->is_precomputed();
            Marpa::exception('symbols value must be REF to HASH')
                if ref $value ne 'HASH';
            while ( my ( $symbol, $properties ) = each %{$value} ) {
                assign_user_symbol( $grammar, $symbol, $properties );
            }
        } ## end if ( defined( my $value = $args->{'symbols'} ) )

        if ( defined( my $value = $args->{'lhs_terminals'} ) ) {
            my $ok = $grammar_c->is_lhs_terminal_ok_set($value);
            if ( not $ok ) {
                my $error = $grammar_c->error();
                if ( $error eq 'precomputed' ) {
                    Marpa::exception(
                        'lhs_terminals option not allowed after grammar is precomputed'
                    );
                }
                Marpa::XS::uncaught_error($error);
            } ## end if ( not $ok )
        } ## end if ( defined( my $value = $args->{'lhs_terminals'} ))

        if ( defined( my $value = $args->{'rule_name_required'} ) ) {
            $grammar->[Marpa::XS::Internal::Grammar::RULE_NAME_REQUIRED] =
                !!$value;
        }

        if ( defined( my $value = $args->{'terminals'} ) ) {
            Marpa::exception(
                'terminals option not allowed after grammar is precomputed')
                if $grammar_c->is_precomputed();
            Marpa::exception('terminals value must be REF to ARRAY')
                if ref $value ne 'ARRAY';
            for my $symbol ( @{$value} ) {
                assign_user_symbol( $grammar, $symbol, { terminal => 1 } );
            }
        } ## end if ( defined( my $value = $args->{'terminals'} ) )

        if ( defined( my $value = $args->{'start'} ) ) {
            Marpa::exception(
                'start option not allowed after grammar is precomputed')
                if $grammar_c->is_precomputed();
            $grammar->[Marpa::XS::Internal::Grammar::START_NAME] = $value;
        } ## end if ( defined( my $value = $args->{'start'} ) )

        if ( defined( my $value = $args->{'rules'} ) ) {
            Marpa::exception(
                'rules option not allowed after grammar is precomputed')
                if $grammar_c->is_precomputed();
            Marpa::exception('rules value must be reference to array')
                if ref $value ne 'ARRAY';
            add_user_rules( $grammar, $value );
        } ## end if ( defined( my $value = $args->{'rules'} ) )

        if ( defined( my $value = $args->{'default_null_value'} ) ) {
            $grammar->[Marpa::XS::Internal::Grammar::DEFAULT_NULL_VALUE] =
                $value;
        }

        if ( defined( my $value = $args->{'actions'} ) ) {
            $grammar->[Marpa::XS::Internal::Grammar::ACTIONS] = $value;
        }

        if ( defined( my $value = $args->{'action_object'} ) ) {
            $grammar->[Marpa::XS::Internal::Grammar::ACTION_OBJECT] = $value;
        }

        if ( defined( my $value = $args->{'default_action'} ) ) {
            $grammar->[Marpa::XS::Internal::Grammar::DEFAULT_ACTION] = $value;
        }

        if ( defined( my $value = $args->{'strip'} ) ) {
            ;    # A no-op in the XS version
        }

        if ( defined( my $value = $args->{'infinite_action'} ) ) {
            if ( $value && $grammar_c->is_precomputed() ) {
                say {$trace_fh}
                    '"infinite_action" option is useless after grammar is precomputed'
                    or Marpa::exception("Could not print: $ERRNO");
            }
            Marpa::exception(
                q{infinite_action must be 'warn', 'quiet' or 'fatal'})
                if not $value ~~ [qw(warn quiet fatal)];
            $grammar->[Marpa::XS::Internal::Grammar::INFINITE_ACTION] =
                $value;
        } ## end if ( defined( my $value = $args->{'infinite_action'}...))

        if ( defined( my $value = $args->{'warnings'} ) ) {
            if ( $value && $grammar_c->is_precomputed() ) {
                say {$trace_fh}
                    q{"warnings" option is useless after grammar is precomputed}
                    or Marpa::exception("Could not print: $ERRNO");
            }
            $grammar->[Marpa::XS::Internal::Grammar::WARNINGS] = $value;
        } ## end if ( defined( my $value = $args->{'warnings'} ) )

        if ( defined( my $value = $args->{'inaccessible_ok'} ) ) {
            if ( $value && $grammar_c->is_precomputed() ) {
                say {$trace_fh}
                    q{"inaccessible_ok" option is useless after grammar is precomputed}
                    or Marpa::exception("Could not print: $ERRNO");

            } ## end if ( $value && $grammar_c->is_precomputed() )
            given ( ref $value ) {
                when (q{}) {
                    $value //= {
                    }
                }
                when ('ARRAY') {
                    $value = {
                        map { ( $_, 1 ) } @{$value}
                    }
                }
                default {
                    Marpa::exception(
                        'value of inaccessible_ok option must be boolean or an array ref'
                        )
                }
            } ## end given
            $grammar->[Marpa::XS::Internal::Grammar::INACCESSIBLE_OK] =
                $value;
        } ## end if ( defined( my $value = $args->{'inaccessible_ok'}...))

        if ( defined( my $value = $args->{'unproductive_ok'} ) ) {
            if ( $value && $grammar_c->is_precomputed() ) {
                say {$trace_fh}
                    q{"unproductive_ok" option is useless after grammar is precomputed}
                    or Marpa::exception("Could not print: $ERRNO");
            }
            given ( ref $value ) {
                when (q{}) {
                    $value //= {
                    };
                }
                when ('ARRAY') {
                    $value = {
                        map { ( $_, 1 ) } @{$value}
                    }
                }
                default {
                    Marpa::exception(
                        'value of unproductive_ok option must be boolean or an array ref'
                        )
                }
            } ## end given
            $grammar->[Marpa::XS::Internal::Grammar::UNPRODUCTIVE_OK] =
                $value;
        } ## end if ( defined( my $value = $args->{'unproductive_ok'}...))

    } ## end for my $args (@arg_hashes)

    return 1;
} ## end sub Marpa::XS::Grammar::set

sub Marpa::XS::Grammar::precompute {
    my $grammar = shift;

    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $rules     = $grammar->[Marpa::XS::Internal::Grammar::RULES];
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $trace_fh =
        $grammar->[Marpa::XS::Internal::Grammar::TRACE_FILE_HANDLE];

    my $problems = $grammar->[Marpa::XS::Internal::Grammar::PROBLEMS];
    if ($problems) {
        Marpa::exception(
            Marpa::XS::Grammar::show_problems($grammar),
            "Second attempt to precompute grammar with fatal problems\n",
            'Marpa::XS cannot proceed'
        );
    } ## end if ($problems)

    return $grammar if $grammar_c->is_precomputed();

    set_start_symbol($grammar);
    if ( not $grammar_c->precompute() ) {
        my $error = $grammar_c->error();

        # Be idempotent.  If the grammar is already precomputed, just
        # return success without doing anything.
        return $grammar if $error eq 'precomputed';

        if ( $error eq 'no rules' ) {
            Marpa::exception('Attempted to precompute grammar with no rules');
        }
        if ( $error eq 'empty rule and unmarked terminals' ) {
            Marpa::exception(
                'A grammar with empty rules must mark its terminals or unset lhs_terminals'
            );
        }
        if ( $error eq 'counted nullable' ) {
            Marpa::exception( Marpa::XS::Grammar::show_problems($grammar),
                'Counted nullables confuse Marpa -- please rewrite the grammar'
            );
        }
        if ( $error eq 'no start symbol' ) {
            Marpa::exception('No start symbol');
        }
        if ( $error eq 'start symbol not on LHS' ) {
            my $symbol_id = $grammar_c->context('symid');
            my $name =
                $symbols->[$symbol_id]->[Marpa::XS::Internal::Symbol::NAME];
            Marpa::exception(qq{Start symbol "$name" not on LHS of any rule});
        } ## end if ( $error eq 'start symbol not on LHS' )
        if ( $error eq 'unproductive start symbol' ) {
            my $symbol_id = $grammar_c->context('symid');
            my $name =
                $symbols->[$symbol_id]->[Marpa::XS::Internal::Symbol::NAME];
            Marpa::exception(qq{Unproductive start symbol: "$name"});
        } ## end if ( $error eq 'unproductive start symbol' )
        Marpa::XS::uncaught_error($error);
    } ## end if ( not $grammar_c->precompute() )

    my $default_rank = $grammar->[Marpa::XS::Internal::Grammar::DEFAULT_RANK];

    # LHS_RANK is left undefined if not explicitly set
    SYMBOL: for my $symbol ( @{$symbols} ) {
        $symbol->[Marpa::XS::Internal::Symbol::TERMINAL_RANK] //=
            $default_rank;
    }

    populate_null_values($grammar);

    # A bit hackish here: INACCESSIBLE_OK is not a HASH ref iff
    # it is a Boolean TRUE indicating that all inaccessibles are OK.
    # A Boolean FALSE will have been replaced with an empty hash.
    if ($grammar->[Marpa::XS::Internal::Grammar::WARNINGS]
        and ref(
            my $ok = $grammar->[Marpa::XS::Internal::Grammar::INACCESSIBLE_OK]
        ) eq 'HASH'
        )
    {
        SYMBOL:
        for my $symbol (
            @{ Marpa::XS::Grammar::inaccessible_symbols($grammar) } )
        {

            # Inaccessible internal symbols may be created
            # from inaccessible use symbols -- ignore these.
            # This assumes that Marpa::XS's logic
            # is correct and that
            # it is not creating inaccessible symbols from
            # accessible ones.
            next SYMBOL if $symbol =~ /\]/xms;
            next SYMBOL if $ok->{$symbol};
            say {$trace_fh} "Inaccessible symbol: $symbol"
                or Marpa::exception("Could not print: $ERRNO");
        } ## end for my $symbol ( @{ Marpa::XS::Grammar::inaccessible_symbols...})
    } ## end if ( $grammar->[Marpa::XS::Internal::Grammar::WARNINGS...])

    # A bit hackish here: UNPRODUCTIVE_OK is not a HASH ref iff
    # it is a Boolean TRUE indicating that all inaccessibles are OK.
    # A Boolean FALSE will have been replaced with an empty hash.
    if ($grammar->[Marpa::XS::Internal::Grammar::WARNINGS]
        and ref(
            my $ok = $grammar->[Marpa::XS::Internal::Grammar::UNPRODUCTIVE_OK]
        ) eq 'HASH'
        )
    {
        SYMBOL:
        for my $symbol (
            @{ Marpa::XS::Grammar::unproductive_symbols($grammar) } )
        {

            # Unproductive internal symbols may be created
            # from unproductive use symbols -- ignore these.
            # This assumes that Marpa::XS's logic
            # is correct and that
            # it is not creating unproductive symbols from
            # productive ones.
            next SYMBOL if $symbol =~ /\]/xms;
            next SYMBOL if $ok->{$symbol};
            say {$trace_fh} "Unproductive symbol: $symbol"
                or Marpa::exception("Could not print: $ERRNO");
        } ## end for my $symbol ( @{ Marpa::XS::Grammar::unproductive_symbols...})
    } ## end if ( $grammar->[Marpa::XS::Internal::Grammar::WARNINGS...])

    if ( $grammar->[Marpa::XS::Internal::Grammar::WARNINGS] ) {
        SYMBOL:
        for my $symbol (
            @{ $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS] } )
        {

            next SYMBOL
                if not $symbol
                    ->[Marpa::XS::Internal::Symbol::WARN_IF_NO_NULL_VALUE];

            next SYMBOL
                if defined $symbol->[Marpa::XS::Internal::Symbol::NULL_VALUE];

            my $symbol_name = $symbol->[Marpa::XS::Internal::Symbol::NAME];
            say {$trace_fh}
                qq{Zero length sequence for symbol without null value: "$symbol_name"}
                or Marpa::exception("Could not print: $ERRNO");
        } ## end for my $symbol ( @{ $grammar->[...]})
    } ## end if ( $grammar->[Marpa::XS::Internal::Grammar::WARNINGS...])

    RULE: for my $rule ( @{$rules} ) {
        my $rule_rank = $rule->[Marpa::XS::Internal::Rule::RANK];
        my $rule_id   = $rule->[Marpa::XS::Internal::Rule::ID];
        my $lhs_id    = $grammar_c->rule_lhs($rule_id);
        my $lhs       = $symbols->[$lhs_id];
        my $lhs_rank  = $lhs->[Marpa::XS::Internal::Symbol::LHS_RANK];
        SET_RULE_RANK: {
            last SET_RULE_RANK if defined $rule_rank;
            my $original_rule_id = $grammar_c->rule_original($rule_id);
            if ( not defined $original_rule_id ) {
                $rule_rank = $rule->[Marpa::XS::Internal::Rule::RANK] =
                    $default_rank;
                last SET_RULE_RANK;
            }
            my $original_rule = $rules->[$original_rule_id];
            $rule_rank = $rule->[Marpa::XS::Internal::Rule::RANK] =
                $original_rule->[Marpa::XS::Internal::Rule::RANK];
        } ## end SET_RULE_RANK:
        next RULE
            if not defined $lhs_rank
                or $lhs_rank == $rule->[Marpa::XS::Internal::Rule::RANK];
        Marpa::exception(
            'Rank mismatch in rule: ',
            brief_rule($rule),
            "\n",
            "LHS rank is $lhs_rank; rule rank is ",
            $rule->[Marpa::XS::Internal::Rule::RANK]
        );
    } ## end for my $rule ( @{$rules} )

    #
    # Set ranks for chaf rules
    #

    RULE: for my $rule ( @{$rules} ) {

        my $rule_id          = $rule->[Marpa::XS::Internal::Rule::ID];
        my $original_rule_id = $grammar_c->rule_original($rule_id);
        my $original_rule =
            defined $original_rule_id ? $rules->[$original_rule_id] : $rule;

        # If not null ranked, default to highest CHAF rank
        my $null_ranking =
            $original_rule->[Marpa::XS::Internal::Rule::NULL_RANKING];
        if ( not $null_ranking ) {
            $rule->[Marpa::XS::Internal::Rule::CHAF_RANK] = 99;
            next RULE;
        }

        # If this rule is marked as null ranked,
        # but it is not actually a CHAF rule, rank it below
        # all non-null-ranked rules, but above all rules with CHAF
        # ranks actually computed from the proper nullables
        my $virtual_start = $grammar_c->rule_virtual_start($rule_id);
        if ( $virtual_start < 0 ) {
            $rule->[Marpa::XS::Internal::Rule::CHAF_RANK] = 98;
            next RULE;
        }

        my $original_rule_length = $grammar_c->rule_length($original_rule_id);

        my $rank                  = 0;
        my $proper_nullable_count = 0;
        RHS_IX:
        for (
            my $rhs_ix = $virtual_start;
            $rhs_ix < $original_rule_length;
            $rhs_ix++
            )
        {
            my $original_rhs_id =
                $grammar_c->rule_rhs( $original_rule_id, $rhs_ix );

            # Do nothing unless this is a proper nullable
            next RHS_IX if $grammar_c->symbol_is_nulling($original_rhs_id);
            next RHS_IX
                if not $grammar_c->symbol_null_alias($original_rhs_id);

            my $rhs_id =
                $grammar_c->rule_rhs( $rule_id, $rhs_ix - $virtual_start );
            last RHS_IX if not defined $rhs_id;
            $rank *= 2;
            $rank += ( $grammar_c->symbol_is_nulling($rhs_id) ? 0 : 1 );

            last RHS_IX if ++$proper_nullable_count >= 2;
        } ## end for ( my $rhs_ix = $virtual_start; $rhs_ix < ...)

        if ( $null_ranking eq 'high' ) {
            $rank = ( 2**$proper_nullable_count - 1 ) - $rank;
        }
        $rule->[Marpa::XS::Internal::Rule::CHAF_RANK] = $rank;

    } ## end for my $rule ( @{$rules} )

    return $grammar;

} ## end sub Marpa::XS::Grammar::precompute

sub Marpa::XS::Grammar::rule_by_name {
    my ( $grammar, $name ) = @_;
    return $grammar->[Marpa::XS::Internal::Grammar::RULE_BY_NAME]->{$name};
}

sub Marpa::XS::Grammar::show_problems {
    my ($grammar) = @_;

    my $problems = $grammar->[Marpa::XS::Internal::Grammar::PROBLEMS];
    if ($problems) {
        my $problem_count = scalar @{$problems};
        return
            "Grammar has $problem_count problems:\n"
            . ( join "\n", @{$problems} ) . "\n";
    } ## end if ($problems)
    return "Grammar has no problems\n";
} ## end sub Marpa::XS::Grammar::show_problems

sub Marpa::XS::Grammar::show_symbol {
    my ( $grammar, $symbol ) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $text      = q{};
    my $symbol_id = $symbol->[Marpa::XS::Internal::Symbol::ID];

    my $name = $symbol->[Marpa::XS::Internal::Symbol::NAME];
    $text .= "$symbol_id: $name,";

    $text .= sprintf ' lhs=[%s]',
        join q{ },
        $grammar_c->symbol_lhs_rule_ids($symbol_id);

    $text .= sprintf ' rhs=[%s]',
        join q{ },
        $grammar_c->symbol_rhs_rule_ids($symbol_id);

    $grammar_c->symbol_is_nullable($symbol_id) and $text .= ' nullable';
    $grammar_c->symbol_is_productive($symbol_id) or $text .= ' unproductive';
    $grammar_c->symbol_is_accessible($symbol_id) or $text .= ' inaccessible';
    $grammar_c->symbol_is_nulling($symbol_id)  and $text .= ' nulling';
    $grammar_c->symbol_is_terminal($symbol_id) and $text .= ' terminal';

    $text .= "\n";
    return $text;

} ## end sub Marpa::XS::Grammar::show_symbol

sub Marpa::XS::Grammar::show_symbols {
    my ($grammar) = @_;
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $text      = q{};
    for my $symbol_ref ( @{$symbols} ) {
        $text .= $grammar->show_symbol($symbol_ref);
    }
    return $text;
} ## end sub Marpa::XS::Grammar::show_symbols

sub Marpa::XS::Grammar::show_nulling_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    return join q{ },
        sort map { $_->[Marpa::XS::Internal::Symbol::NAME] } grep {
        $grammar_c->symbol_is_nulling( $_->[Marpa::XS::Internal::Symbol::ID] )
        } @{$symbols};
} ## end sub Marpa::XS::Grammar::show_nulling_symbols

sub Marpa::XS::Grammar::show_nullable_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    return join q{ },
        sort map { $_->[Marpa::XS::Internal::Symbol::NAME] } grep {
        $grammar_c->symbol_is_nullable(
            $_->[Marpa::XS::Internal::Symbol::ID] )
        } @{$symbols};
} ## end sub Marpa::XS::Grammar::show_nullable_symbols

sub Marpa::XS::Grammar::show_productive_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    return join q{ }, sort map { $_->[Marpa::XS::Internal::Symbol::NAME] }
        grep {
        $grammar_c->symbol_is_productive(
            $_->[Marpa::XS::Internal::Symbol::ID] )
        } @{$symbols};
} ## end sub Marpa::XS::Grammar::show_productive_symbols

sub Marpa::XS::Grammar::show_accessible_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    return join q{ },
        sort map { $_->[Marpa::XS::Internal::Symbol::NAME] } grep {
        $grammar_c->symbol_is_accessible(
            $_->[Marpa::XS::Internal::Symbol::ID] )
        } @{$symbols};
} ## end sub Marpa::XS::Grammar::show_accessible_symbols

sub Marpa::XS::Grammar::inaccessible_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    return [
        sort map { $_->[Marpa::XS::Internal::Symbol::NAME] } grep {
            !$grammar_c->symbol_is_accessible(
                $_->[Marpa::XS::Internal::Symbol::ID] )
            } @{$symbols}
    ];
} ## end sub Marpa::XS::Grammar::inaccessible_symbols

sub Marpa::XS::Grammar::unproductive_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    return [
        sort map { $_->[Marpa::XS::Internal::Symbol::NAME] } grep {
            !$grammar_c->symbol_is_productive(
                $_->[Marpa::XS::Internal::Symbol::ID] )
            } @{$symbols}
    ];
} ## end sub Marpa::XS::Grammar::unproductive_symbols

sub Marpa::XS::Grammar::brief_rule {
    my ( $grammar, $rule_id ) = @_;
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $lhs_id    = $grammar_c->rule_lhs($rule_id);
    my $text .= $rule_id . ': '
        . $symbols->[$lhs_id]->[Marpa::XS::Internal::Symbol::NAME] . ' ->';
    if ( my $rh_length = $grammar_c->rule_length($rule_id) ) {
        my @rhs_ids = ();
        for my $ix ( 0 .. $rh_length - 1 ) {
            push @rhs_ids, $grammar_c->rule_rhs( $rule_id, $ix );
        }
        $text .= q{ }
            . (
            join q{ },
            map { $symbols->[$_]->[Marpa::XS::Internal::Symbol::NAME] }
                @rhs_ids
            );
    } ## end if ( my $rh_length = $grammar_c->rule_length($rule_id...))
    return $text;
} ## end sub Marpa::XS::Grammar::brief_rule

sub Marpa::XS::Grammar::brief_original_rule {
    my ( $grammar, $rule_id ) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $original_rule_id = $grammar_c->rule_original($rule_id) //= $rule_id;
    return Marpa::XS::brief_rule( $grammar, $original_rule_id );
} ## end sub Marpa::XS::Grammar::brief_original_rule

sub Marpa::XS::Grammar::brief_virtual_rule {
    my ( $grammar, $rule_id, $dot_position ) = @_;
    my $grammar_c        = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols          = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $original_rule_id = $grammar_c->rule_original($rule_id);
    if ( not defined $original_rule_id ) {
        return $grammar->show_dotted_rule( $rule_id, $dot_position )
            if defined $dot_position;
        return $grammar->brief_rule($rule_id);
    }

    my $original_lhs_id = $grammar_c->rule_lhs($original_rule_id);
    my $original_lhs    = $symbols->[$original_lhs_id];
    my $chaf_start      = $grammar_c->rule_virtual_start($rule_id);
    my $chaf_end        = $grammar_c->rule_virtual_end($rule_id);

    if ( not defined $chaf_start ) {
        return "dot at $dot_position, virtual "
            . $grammar->brief_rule($original_rule_id)
            if defined $dot_position;
        return 'virtual ' . $grammar->brief_rule($original_rule_id);
    } ## end if ( not defined $chaf_start )

    my $text .= "(part of $original_rule_id) ";
    $text .= $original_lhs->[Marpa::XS::Internal::Symbol::NAME] . ' ->';
    my @rhs_names = ();
    for my $ix ( 0 .. $grammar_c->rule_length($original_rule_id) ) {
        my $rhs_symbol_id = $grammar_c->rule_rhs( $original_rule_id, $ix );
        my $rhs_symbol_name =
            $symbols->[$rhs_symbol_id]->[Marpa::XS::Internal::Symbol::NAME];
        push @rhs_names, $rhs_symbol_name;
    } ## end for my $ix ( 0 .. $grammar_c->rule_length($original_rule_id...))

    my @chaf_symbol_start;
    my @chaf_symbol_end;

    # Mark the beginning and end of the non-CHAF symbols
    # in the CHAF rule.
    for my $chaf_ix ( $chaf_start .. $chaf_end ) {
        $chaf_symbol_start[$chaf_ix] = 1;
        $chaf_symbol_end[ $chaf_ix + 1 ] = 1;
    }

    # Mark the beginning and special CHAF symbol
    # for the "rest" of the rule.
    if ( $chaf_end < $#rhs_names ) {
        $chaf_symbol_start[ $chaf_end + 1 ] = 1;
        $chaf_symbol_end[ scalar @rhs_names ] = 1;
    }

    $dot_position =
        $dot_position >= $grammar_c->rule_length($rule_id)
        ? scalar @rhs_names
        : ( $chaf_start + $dot_position );

    for ( 0 .. scalar @rhs_names ) {
        when ( defined $chaf_symbol_end[$_] )   { $text .= ' >';  continue }
        when ($dot_position)                    { $text .= q{ .}; continue; }
        when ( defined $chaf_symbol_start[$_] ) { $text .= ' <';  continue }
        when ( $_ < scalar @rhs_names ) {
            $text .= q{ } . $rhs_names[$_]
        }
    } ## end for ( 0 .. scalar @rhs_names )

    return $text;

} ## end sub Marpa::XS::Grammar::brief_virtual_rule

sub Marpa::XS::Grammar::show_rule {
    my ( $grammar, $rule ) = @_;

    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $rule_id   = $rule->[Marpa::XS::Internal::Rule::ID];
    my @comment   = ();

    $grammar_c->rule_length($rule_id) == 0 and push @comment, 'empty';
    $grammar_c->rule_is_used($rule_id)       or push @comment, '!used';
    $grammar_c->rule_is_productive($rule_id) or push @comment, 'unproductive';
    $grammar_c->rule_is_accessible($rule_id) or push @comment, 'inaccessible';
    my $rule_is_virtual_lhs = $grammar_c->rule_is_virtual_lhs($rule_id);
    $rule_is_virtual_lhs and push @comment, 'vlhs';
    my $rule_is_virtual_rhs = $grammar_c->rule_is_virtual_rhs($rule_id);
    $rule_is_virtual_rhs and push @comment, 'vrhs';
    $grammar_c->rule_is_discard_separation($rule_id)
        and push @comment, 'discard_sep';

    if ( $rule_is_virtual_lhs or $rule_is_virtual_rhs ) {
        push @comment, sprintf 'real=%d',
            $grammar_c->real_symbol_count($rule_id);
    }

    my $text = $grammar->brief_rule($rule_id);

    if (@comment) {
        $text .= q{ } . ( join q{ }, q{/*}, @comment, q{*/} );
    }

    return $text .= "\n";

}    # sub show_rule

sub Marpa::XS::Grammar::show_rules {
    my ($grammar) = @_;
    my $rules = $grammar->[Marpa::XS::Internal::Grammar::RULES];
    my $text;

    for my $rule ( @{$rules} ) {
        $text .= $grammar->show_rule($rule);
    }
    return $text;
} ## end sub Marpa::XS::Grammar::show_rules

sub Marpa::XS::Grammar::show_dotted_rule {
    my ( $grammar, $rule_id, $dot_position ) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $lhs_id    = $grammar_c->rule_lhs($rule_id);
    my $lhs       = $symbols->[$lhs_id];

    my $text = $lhs->[Marpa::XS::Internal::Symbol::NAME] . q{ ->};

    # In the bocage, when we are starting a rule and
    # there is no current symbol, the position may
    # be -1.
    # Position has different semantics in the bocage, than in an LR-item.
    # In the bocage, the position is *AT* a symbol.
    # In the bocage the position is the number OF the current symbol.
    # An LR-item the position how far into the rule parsing has
    # proceded and is therefore between symbols (or at the end
    # or beginning or a rule).
    # Usually bocage position is one less than the analagous
    # LR-item position.
    if ( $dot_position < 0 ) {
        $text .= q{ !};
    }

    my @rhs_names = ();
    for my $ix ( 0 .. $grammar_c->rule_length($rule_id) - 1 ) {
        my $rhs_symbol_id = $grammar_c->rule_rhs( $rule_id, $ix );
        my $rhs_symbol_name =
            $symbols->[$rhs_symbol_id]->[Marpa::XS::Internal::Symbol::NAME];
        push @rhs_names, $rhs_symbol_name;
    } ## end for my $ix ( 0 .. $grammar_c->rule_length($rule_id) -...)

    POSITION: for my $position ( 0 .. scalar @rhs_names ) {
        if ( $position == $dot_position ) {
            $text .= q{ .};
        }
        my $name = $rhs_names[$position];
        next POSITION if not defined $name;
        $text .= " $name";
    } ## end for my $position ( 0 .. scalar @rhs_names )

    return $text;

} ## end sub Marpa::XS::Grammar::show_dotted_rule

sub Marpa::XS::show_AHFA_item {
    my ( $grammar, $item_id ) = @_;
    my $grammar_c  = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols    = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $postdot_id = $grammar_c->AHFA_item_postdot($item_id);
    my $sort_key   = $grammar_c->AHFA_item_sort_key($item_id);
    my $text       = "AHFA item $item_id: ";
    my @properties = ();
    push @properties, "sort = $sort_key";

    if ( $postdot_id < 0 ) {
        push @properties, 'completion';
    }
    else {
        my $postdot_symbol_name =
            $symbols->[$postdot_id]->[Marpa::XS::Internal::Symbol::NAME];
        push @properties, qq{postdot = "$postdot_symbol_name"};
    }
    $text .= join q{; }, @properties;
    $text .= "\n" . ( q{ } x 4 );
    $text .= Marpa::XS::show_brief_AHFA_item( $grammar, $item_id ) . "\n";
    return $text;
} ## end sub Marpa::XS::show_AHFA_item

sub Marpa::XS::show_brief_AHFA_item {
    my ( $grammar, $item_id ) = @_;
    my $grammar_c  = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $postdot_id = $grammar_c->AHFA_item_postdot($item_id);
    my $rule_id    = $grammar_c->AHFA_item_rule($item_id);
    my $position   = $grammar_c->AHFA_item_position($item_id);
    my $dot_position =
        $position < 0 ? $grammar_c->rule_length($rule_id) : $position;
    return $grammar->show_dotted_rule( $rule_id, $dot_position );
} ## end sub Marpa::XS::show_brief_AHFA_item

sub Marpa::XS::Grammar::show_AHFA {
    my ( $grammar, $verbose ) = @_;
    $verbose //= 1;    # legacy is to be verbose, so default to it
    my $grammar_c        = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols          = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $text             = q{};
    my $AHFA_state_count = $grammar_c->AHFA_state_count();
    STATE:
    for ( my $state_id = 0; $state_id < $AHFA_state_count; $state_id++ ) {
        $text .= "* S$state_id:";
        defined $grammar_c->AHFA_state_leo_lhs_symbol($state_id)
            and $text .= ' leo-c';
        $grammar_c->AHFA_state_is_predict($state_id) and $text .= ' predict';
        $text .= "\n";
        my @items = ();
        for my $item_id ( $grammar_c->AHFA_state_items($state_id) ) {
            push @items,
                [
                $grammar_c->AHFA_item_rule($item_id),
                $grammar_c->AHFA_item_postdot($item_id),
                Marpa::XS::show_brief_AHFA_item( $grammar, $item_id )
                ];
        } ## end for my $item_id ( $grammar_c->AHFA_state_items($state_id...))
        $text .= join "\n", map { $_->[2] }
            sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @items;
        $text .= "\n";

        next STATE if not $verbose;

        my @raw_transitions = $grammar_c->AHFA_state_transitions($state_id);
        my %transitions     = ();
        while ( my ( $symbol_id, $to_state_id ) = splice @raw_transitions, 0,
            2 )
        {
            my $symbol_name =
                $symbols->[$symbol_id]->[Marpa::XS::Internal::Symbol::NAME];
            $transitions{$symbol_name} = $to_state_id;
        } ## end while ( my ( $symbol_id, $to_state_id ) = splice ...)
        for my $transition_symbol ( sort keys %transitions ) {
            $text .= ' <' . $transition_symbol . '> => ';
            my $to_state_id = $transitions{$transition_symbol};
            my @to_descs    = ("S$to_state_id");
            my $lhs_id = $grammar_c->AHFA_state_leo_lhs_symbol($to_state_id);
            if ( defined $lhs_id ) {
                my $lhs_name =
                    $symbols->[$lhs_id]->[Marpa::XS::Internal::Symbol::NAME];
                push @to_descs, "leo($lhs_name)";
            }
            my $empty_transition_state =
                $grammar_c->AHFA_state_empty_transition($to_state_id);
            $empty_transition_state >= 0
                and push @to_descs, "S$empty_transition_state";
            $text .= ( join q{; }, sort @to_descs ) . "\n";
        } ## end for my $transition_symbol ( sort keys %transitions )

    } ## end for ( my $state_id = 0; $state_id < $AHFA_state_count...)
    return $text;
} ## end sub Marpa::XS::Grammar::show_AHFA

sub Marpa::XS::Grammar::show_AHFA_items {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $text      = q{};
    my $count     = $grammar_c->AHFA_item_count();
    for my $AHFA_item_id ( 0 .. $count - 1 ) {
        $text .= Marpa::XS::show_AHFA_item( $grammar, $AHFA_item_id );
    }
    return $text;
} ## end sub Marpa::XS::Grammar::show_AHFA_items

# Used by lexers to check that symbol is a terminal
sub Marpa::XS::Grammar::check_terminal {
    my ( $grammar, $name ) = @_;
    return 0 if not defined $name;
    my $grammar_c   = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];
    my $symbol_id   = $symbol_hash->{$name};
    return 0 if not defined $symbol_id;
    my $symbols = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $symbol  = $symbols->[$symbol_id];
    return $grammar_c->symbol_is_terminal($symbol_id) ? 1 : 0;
} ## end sub Marpa::XS::Grammar::check_terminal

sub get_grammar_by_id {
    my ($grammar_id) = @_;
    my $grammar = $grammar_by_id{$grammar_id};
    if ( not defined $grammar ) {
        Carp::croak(
            "Attempting to use a grammar which has been garbage collected\n",
            'Grammar with id ',
            q{#},
            "$grammar_id no longer exists\n"
        );
    } ## end if ( not defined $grammar )
    return $grammar;
} ## end sub get_grammar_by_id

sub message_cb {
    my ( $grammar_id, $message_id ) = @_;
    my $grammar   = get_grammar_by_id($grammar_id);
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $trace_fh =
        $grammar->[Marpa::XS::Internal::Grammar::TRACE_FILE_HANDLE];
    if ( $message_id eq 'counted nullable' ) {
        my $symbol_id = $grammar_c->context('symid');
        my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
        my $name =
            $symbols->[$symbol_id]->[Marpa::XS::Internal::Symbol::NAME];
        my $problem = qq{Nullable symbol "$name" is on rhs of counted rule};
        push @{ $grammar->[Marpa::XS::Internal::Grammar::PROBLEMS] },
            $problem;
        return;
    } ## end if ( $message_id eq 'counted nullable' )
    if ( $message_id eq 'lhs is terminal' ) {
        my $symbol_id = $grammar_c->context('symid');
        my $symbols   = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
        my $name =
            $symbols->[$symbol_id]->[Marpa::XS::Internal::Symbol::NAME];
        Marpa::exception(
            "lhs_terminals option is off, but Symbol $name is both an LHS and a terminal"
        );
    } ## end if ( $message_id eq 'lhs is terminal' )
    if ( $message_id eq 'loop rule' ) {
        return
            if $grammar->[Marpa::XS::Internal::Grammar::INFINITE_ACTION] eq
                'quiet';
        my $loop_rule_id     = $grammar_c->context('rule_id');
        my $original_rule_id = $grammar_c->rule_original($loop_rule_id);
        my $warning_rule_id  = $original_rule_id // $loop_rule_id;
        print {$trace_fh}
            'Cycle found involving rule: ',
            $grammar->brief_rule($warning_rule_id), "\n"
            or Marpa::exception("Could not print: $ERRNO");
        return;
    } ## end if ( $message_id eq 'loop rule' )
    if ( $message_id eq 'loop rule tally' ) {
        Marpa::exception('Cycle in grammar, fatal error')
            if $grammar->[Marpa::XS::Internal::Grammar::INFINITE_ACTION] eq
                'fatal'
                and $grammar_c->context('loop_rule_count');
        return;
    } ## end if ( $message_id eq 'loop rule tally' )
    Marpa::exception(qq{Unexpected message, type "$message_id"});
    return;
} ## end sub message_cb

sub wrap_symbol_cb {
    my ( $grammar_id, $symbol_id ) = @_;
    my $grammar     = get_grammar_by_id($grammar_id);
    my $grammar_c   = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols     = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];
    my $symbol      = bless [], 'Marpa::XS::Internal::Symbol';
    my $name;
    DETERMINE_NAME: {
        $name = $grammar->[Marpa::XS::Internal::Grammar::NEXT_SYMBOL_NAME];
        $grammar->[Marpa::XS::Internal::Grammar::NEXT_SYMBOL_NAME] = undef;
        last DETERMINE_NAME if defined $name;
        my $old_start_id = $grammar_c->context('old_start_id');
        if ( defined $old_start_id ) {    # This is new start symbol
            my $old_name =
                $symbols->[$old_start_id]
                ->[Marpa::XS::Internal::Symbol::NAME];
            $name = $old_name . q{[']};
            $grammar_c->symbol_is_nulling($symbol_id) and $name .= '[]';
            last DETERMINE_NAME;
        } ## end if ( defined $old_start_id )
        my $proper_alias_id = $grammar_c->symbol_proper_alias($symbol_id);
        if ( defined $proper_alias_id ) {
            my $proper_alias = $symbols->[$proper_alias_id];
            $name = $symbol->[Marpa::XS::Internal::Symbol::NAME] =
                $proper_alias->[Marpa::XS::Internal::Symbol::NAME] . '[]';
            last DETERMINE_NAME;
        } ## end if ( defined $proper_alias_id )

        # If we are here, this should be a virtual LHS from the CHAF
        # rewrite.
        my $virtual_end = $grammar_c->context('virtual_end');
        if ( defined $virtual_end ) {
            my $rule_id = $grammar_c->context('rule_id') // '[RULE?]';
            my $lhs_id  = $grammar_c->context('lhs_id')  // '[LHS?]';
            my $lhs     = $symbols->[$lhs_id];

#<<<  perltidy introduces trailing space on this
            $name =
                  $lhs->[Marpa::XS::Internal::Symbol::NAME] . '[R'
                . $rule_id . q{:}
                . ( $virtual_end + 1 ) . ']';
#>>>
            last DETERMINE_NAME;
        } ## end if ( defined $virtual_end )
        die 'Internal Marpa Perl wrapper error: No way to name unnamed symbol'
            if not defined $proper_alias_id;
    } ## end DETERMINE_NAME:
    $symbol->[Marpa::XS::Internal::Symbol::NAME] = $name;
    $symbol->[Marpa::XS::Internal::Symbol::ID]   = $symbol_id;
    $symbols->[$symbol_id]                       = $symbol;
    $symbol_hash->{$name}                        = $symbol_id;

    return;
} ## end sub wrap_symbol_cb

sub wrap_rule_cb {
    my ( $grammar_id, $new_rule_id ) = @_;
    my $grammar   = get_grammar_by_id($grammar_id);
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $new_rule  = bless [], 'Marpa::XS::Internal::Rule';
    my $rules     = $grammar->[Marpa::XS::Internal::Grammar::RULES];
    $new_rule->[Marpa::XS::Internal::Rule::ID] = $new_rule_id;
    $rules->[$new_rule_id] = $new_rule;

    my $trace_rules = $grammar->[Marpa::XS::Internal::Grammar::TRACE_RULES];
    my $trace_fh =
        $grammar->[Marpa::XS::Internal::Grammar::TRACE_FILE_HANDLE];
    if ($trace_rules) {
        my $lhs_id  = $grammar_c->rule_lhs($new_rule_id);
        my $length  = $grammar_c->rule_length($new_rule_id);
        my @rhs_ids = ();
        for my $ix ( 0 .. $length - 1 ) {
            push @rhs_ids, $grammar_c->rule_rhs( $new_rule_id, $ix );
        }
        my $symbols = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
        print {$trace_fh} 'Added rule #', $new_rule_id, ': ',
            $symbols->[$lhs_id]->[Marpa::XS::Internal::Symbol::NAME], ' -> ',
            join( q{ },
            map { $symbols->[$_]->[Marpa::XS::Internal::Symbol::NAME] }
                @rhs_ids ),
            "\n"
            or Marpa::exception("Could not print: $ERRNO");
    } ## end if ($trace_rules)
    return;
} ## end sub wrap_rule_cb

sub populate_null_values {
    my ($grammar)   = @_;
    my $grammar_c   = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $symbols     = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];
    RULE: for my $nulling_symbol ( @{$symbols} ) {

        # Copy the null values for a nulling alias from its proper alias
        my $nulling_symbol_id =
            $nulling_symbol->[Marpa::XS::Internal::Symbol::ID];
        next RULE if not $grammar_c->symbol_is_nulling($nulling_symbol_id);
        if ( $grammar_c->symbol_is_start($nulling_symbol_id) ) {
            my $old_start_symbol_id = $symbol_hash
                ->{ $grammar->[Marpa::XS::Internal::Grammar::START_NAME] };
            my $null_value =
                $symbols->[$old_start_symbol_id]
                ->[Marpa::XS::Internal::Symbol::NULL_VALUE];
            $nulling_symbol->[Marpa::XS::Internal::Symbol::NULL_VALUE] =
                $null_value;
            next RULE;
        } ## end if ( $grammar_c->symbol_is_start($nulling_symbol_id))
        my $proper_alias_id =
            $grammar_c->symbol_proper_alias($nulling_symbol_id);
        next RULE if not defined $proper_alias_id;
        my $proper_alias = $symbols->[$proper_alias_id];
        $nulling_symbol->[Marpa::XS::Internal::Symbol::NULL_VALUE] =
            $proper_alias->[Marpa::XS::Internal::Symbol::NULL_VALUE];
        $nulling_symbol->[Marpa::XS::Internal::Symbol::TERMINAL_RANK] =
            $proper_alias->[Marpa::XS::Internal::Symbol::TERMINAL_RANK];
    } ## end for my $nulling_symbol ( @{$symbols} )
    return 1;
} ## end sub populate_null_values

sub Marpa::XS::Internal::Symbol::new {
    my ( $class, $grammar, $name ) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    $grammar->[Marpa::XS::Internal::Grammar::NEXT_SYMBOL_NAME] = $name;
    my $symbol_id = $grammar_c->symbol_new();
    return $symbol_id;
} ## end sub Marpa::XS::Internal::Symbol::new

sub Marpa::XS::Internal::Symbol::null_alias {
    my ( $symbol, $grammar ) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $null_alias_id =
        $grammar_c->symbol_null_alias(
        $symbol->[Marpa::XS::Internal::Symbol::ID] );
    return if not defined $null_alias_id;
    return $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS]
        ->[$null_alias_id];
} ## end sub Marpa::XS::Internal::Symbol::null_alias

sub assign_symbol {
    my ( $grammar, $name ) = @_;

    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];
    my $symbol_id   = $symbol_hash->{$name};
    $symbol_id //= Marpa::XS::Internal::Symbol->new( $grammar, $name );

    my $symbols = $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS];
    return $symbols->[$symbol_id];
} ## end sub assign_symbol

sub assign_user_symbol {
    my $grammar   = shift;
    my $name      = shift;
    my $options   = shift;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];

    if ( my $type = ref $name ) {
        Marpa::exception(
            "Symbol name was ref to $type; it must be a scalar string");
    }
    Marpa::exception("Symbol name $name ends in ']': that's not allowed")
        if $name =~ /\]\z/xms;
    my $symbol = assign_symbol( $grammar, $name );
    my $symbol_id = $symbol->[Marpa::XS::Internal::Symbol::ID];

    # Do RANK first, so that the other options override it
    my $rank = $options->{rank};
    if ( defined $rank ) {
        Marpa::exception(qq{Symbol "$name": rank must be an integer})
            if not Scalar::Util::looks_like_number($rank)
                or not int($rank) != $rank;
        $symbol->[Marpa::XS::Internal::Symbol::LHS_RANK] =
            $symbol->[Marpa::XS::Internal::Symbol::TERMINAL_RANK] = $rank;
    } ## end if ( defined $rank )

    PROPERTY: while ( my ( $property, $value ) = each %{$options} ) {
        if (not $property ~~
            [qw(terminal rank lhs_rank terminal_rank null_value)] )
        {
            Marpa::exception(qq{Unknown symbol property "$property"});
        }
        if ( $property eq 'terminal' ) {
            $grammar_c->symbol_is_terminal_set( $symbol_id, $value );
        }
        if ( $property eq 'null_value' ) {
            $symbol->[Marpa::XS::Internal::Symbol::NULL_VALUE] = \$value;
        }
        if ( $property eq 'terminal_rank' ) {
            Marpa::exception(
                qq{Symbol "$name": terminal_rank must be an integer})
                if not Scalar::Util::looks_like_number($value)
                    or int($value) != $value;
            $symbol->[Marpa::XS::Internal::Symbol::TERMINAL_RANK] = $value;
        } ## end if ( $property eq 'terminal_rank' )
        if ( $property eq 'lhs_rank' ) {
            Marpa::exception(qq{Symbol "$name": lhs_rank must be an integer})
                if not Scalar::Util::looks_like_number($value)
                    or int($value) != $value;
            $symbol->[Marpa::XS::Internal::Symbol::LHS_RANK] = $value;
        } ## end if ( $property eq 'lhs_rank' )
    } ## end while ( my ( $property, $value ) = each %{$options} )

    return $symbol;

} ## end sub assign_user_symbol

sub Marpa::XS::Internal::Rule::action_set {
    my ( $rule, $grammar, $action ) = @_;
    my $grammar_c = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $rule_id   = $rule->[Marpa::XS::Internal::Rule::ID];
    my $rh_length = $grammar_c->rule_length($rule_id);
    if ( defined $action and $rh_length < 0 ) {
        my $lhs_id = $grammar_c->rule_lhs($rule_id);
        my $lhs_name =
            $grammar->[Marpa::XS::Internal::Grammar::SYMBOLS]->[$lhs_id]
            ->[Marpa::XS::Internal::Symbol::NAME];
        Marpa::exception(
            "Empty Rule cannot have an action\n",
            "  Rule #$rule_id: $lhs_name  -> /* empty */",
            "\n"
        );
    } ## end if ( defined $action and $rh_length < 0 )
    $rule->[Marpa::XS::Internal::Rule::ACTION] = $action;
    return 1;
} ## end sub Marpa::XS::Internal::Rule::action_set

# add one or more rules
sub add_user_rules {
    my ( $grammar, $rules ) = @_;

    RULE: for my $rule ( @{$rules} ) {

        given ( ref $rule ) {
            when ('ARRAY') {
                my $arg_count = @{$rule};

                if ( $arg_count > 4 or $arg_count < 1 ) {
                    Marpa::exception(
                        "Rule has $arg_count arguments: "
                            . join( ', ',
                            map { defined $_ ? $_ : 'undef' } @{$rule} )
                            . "\n"
                            . 'Rule must have from 1 to 4 arguments'
                    );
                } ## end if ( $arg_count > 4 or $arg_count < 1 )
                my ( $lhs, $rhs, $action ) = @{$rule};
                add_user_rule(
                    $grammar,
                    {   lhs    => $lhs,
                        rhs    => $rhs,
                        action => $action,
                    }
                );

            } ## end when ('ARRAY')
            when ('HASH') {
                add_user_rule( $grammar, $rule );
            }
            default {
                Marpa::exception(
                    'Invalid rule: ',
                    Data::Dumper->new( [$rule], ['Invalid_Rule'] )->Indent(2)
                        ->Terse(1)->Maxdepth(2)->Dump,
                    'Rule must be ref to HASH or ARRAY'
                );
            } ## end default
        } ## end given

    }    # RULE

    return;

} ## end sub add_user_rules

sub add_user_rule {
    my ( $grammar, $options ) = @_;

    Marpa::exception('Missing argument to add_user_rule')
        if not defined $grammar
            or not defined $options;

    my $grammar_c    = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $rules        = $grammar->[Marpa::XS::Internal::Grammar::RULES];
    my $default_rank = $grammar->[Marpa::XS::Internal::Grammar::DEFAULT_RANK];

    my ( $lhs_name, $rhs_names, $action );
    my ( $min, $separator_name );
    my $rank;
    my $null_ranking;
    my $rule_name;
    my $proper_separation = 0;
    my $keep_separation   = 0;

    while ( my ( $option, $value ) = each %{$options} ) {
        given ($option) {
            when ('name')         { $rule_name         = $value }
            when ('rhs')          { $rhs_names         = $value }
            when ('lhs')          { $lhs_name          = $value }
            when ('action')       { $action            = $value }
            when ('rank')         { $rank              = $value }
            when ('null_ranking') { $null_ranking      = $value }
            when ('min')          { $min               = $value }
            when ('separator')    { $separator_name    = $value }
            when ('proper')       { $proper_separation = $value }
            when ('keep')         { $keep_separation   = $value }
            default {
                Marpa::exception("Unknown user rule option: $option");
            };
        } ## end given
    } ## end while ( my ( $option, $value ) = each %{$options} )

    my $lhs = assign_user_symbol( $grammar, $lhs_name );
    $rhs_names //= [];

    my @rule_problems = ();

    my $rhs_ref_type = ref $rhs_names;
    if ( not $rhs_ref_type or $rhs_ref_type ne 'ARRAY' ) {
        my $problem =
              "RHS is not ref to ARRAY\n"
            . '  Type of rhs is '
            . ( $rhs_ref_type ? $rhs_ref_type : 'not a ref' ) . "\n";
        my $d = Data::Dumper->new( [$rhs_names], ['rhs'] );
        $problem .= $d->Dump();
        push @rule_problems, $problem;
    } ## end if ( not $rhs_ref_type or $rhs_ref_type ne 'ARRAY' )
    if ( not defined $lhs_name ) {
        push @rule_problems, "Missing LHS\n";
    }

    if ( defined $rank
        and
        ( not Scalar::Util::looks_like_number($rank) or int($rank) != $rank )
        )
    {
        push @rule_problems, "Rank must be undefined or an integer\n";
    } ## end if ( defined $rank and ( not Scalar::Util::looks_like_number...))
    $rank //= $default_rank;

    if (    defined $null_ranking
        and $null_ranking ne 'high'
        and $null_ranking ne 'low' )
    {
        push @rule_problems,
            "Null Ranking must be undefined, 'high' or 'low'\n";
    } ## end if ( defined $null_ranking and $null_ranking ne 'high'...)

    # Determine the rule's name
    my $rules_by_name =
        $grammar->[Marpa::XS::Internal::Grammar::RULE_BY_NAME];
    if ( defined $rule_name and defined $rules_by_name->{$rule_name} ) {
        push @rule_problems, qq{rule named "$rule_name" already exists};
    }
    if ( !defined $rule_name
        and $grammar->[Marpa::XS::Internal::Grammar::RULE_NAME_REQUIRED] )
    {
        $rule_name = $lhs->[Marpa::XS::Internal::Symbol::NAME];
        if ( defined $rules_by_name->{$rule_name} ) {
            push @rule_problems,
                qq{Cannot name rule from LHS; rule named "$rule_name" already exists};
        }
    } ## end if ( !defined $rule_name and $grammar->[...])

    if ( scalar @rule_problems ) {
        my %dump_options = %{$options};
        delete $dump_options{grammar};
        my $msg = ( scalar @rule_problems )
            . " problem(s) in the following rule:\n";
        my $d = Data::Dumper->new( [ \%dump_options ], ['rule'] );
        $msg .= $d->Dump();
        for my $problem_number ( 0 .. $#rule_problems ) {
            $msg
                .= 'Problem '
                . ( $problem_number + 1 ) . q{: }
                . $rule_problems[$problem_number] . "\n";
        } ## end for my $problem_number ( 0 .. $#rule_problems )
        Marpa::exception($msg);
    } ## end if ( scalar @rule_problems )

    my $rhs = [ map { assign_user_symbol( $grammar, $_ ); } @{$rhs_names} ];

    # Is this is an ordinary, non-counted rule?
    my $is_ordinary_rule = scalar @{$rhs_names} == 0 || !defined $min;
    if ( defined $separator_name and $is_ordinary_rule ) {
        if ( defined $separator_name ) {
            Marpa::exception(
                'separator defined for rule without repetitions');
        }
    } ## end if ( defined $separator_name and $is_ordinary_rule )

    my @rhs_ids = map { $_->[Marpa::XS::Internal::Symbol::ID] } @{$rhs};
    my $lhs_id = $lhs->[Marpa::XS::Internal::Symbol::ID];

    if ($is_ordinary_rule) {
        my $ordinary_rule_id = $grammar_c->rule_new( $lhs_id, \@rhs_ids );
        if ( not defined $ordinary_rule_id ) {
            my $rule_description =
                "$lhs_name -> " . ( join q{ }, @{$rhs_names} );
            my $error = $grammar_c->error();
            my $problem_description =
                $error eq 'duplicate rule'
                ? 'Duplicate rule'
                : qq{Unknown problem ("$error")};
            Marpa::exception("$problem_description: $rule_description");
        } ## end if ( not defined $ordinary_rule_id )
        my $ordinary_rule = $rules->[$ordinary_rule_id];
        $ordinary_rule->action_set( $grammar, $action );
        $ordinary_rule->[Marpa::XS::Internal::Rule::RANK] = $rank
            // $default_rank;
        $ordinary_rule->[Marpa::XS::Internal::Rule::NULL_RANKING] =
            $null_ranking;
        if ( defined $rule_name ) {
            $ordinary_rule->[Marpa::XS::Internal::Rule::NAME] = $rule_name;
            $rules_by_name->{$rule_name} = $ordinary_rule;
        }
        return;
    }    # not defined $min

    Marpa::exception('Only one rhs symbol allowed for counted rule')
        if scalar @{$rhs_names} != 1;

    # For a zero-length sequence
    # with an action
    # warn if we don't also have a null value.
    if ( $min == 0 and $action ) {
        $lhs->[Marpa::XS::Internal::Symbol::WARN_IF_NO_NULL_VALUE] = 1;
    }

    # create the separator symbol, if we're using one
    my $separator;
    my $separator_id = -1;
    if ( defined $separator_name ) {
        $separator = assign_user_symbol( $grammar, $separator_name );
        $separator_id = $separator->[Marpa::XS::Internal::Symbol::ID];
    }

    # Name the internal lhs symbol
    my $internal_lhs_name =
        $lhs_name . '[' . 'Subseq:' . $lhs_id . q{:} . $rhs_ids[0] . ']';
    $grammar->[Marpa::XS::Internal::Grammar::NEXT_SYMBOL_NAME] =
        $internal_lhs_name;

    my $original_rule_id = $grammar_c->sequence_new(
        $lhs_id,
        $rhs_ids[0],
        {   separator => $separator_id,
            keep      => $keep_separation,
            proper    => $proper_separation,
            min       => $min,
        }
    );
    if ( not defined $original_rule_id ) {
        my $rule_description = "$lhs_name -> " . ( join q{ }, @{$rhs_names} );
        my $error = $grammar_c->error();
        my $problem_description =
            $error eq 'duplicate rule'
            ? 'Duplicate rule'
            : qq{Unknown problem ("$error")};
        Marpa::exception("$problem_description: $rule_description");
    } ## end if ( not defined $original_rule_id )

    # The original rule for a sequence rule is
    # not actually used in parsing,
    # but some of the rewritten sequence rules are its
    # semantic equivalents.
    my $original_rule = $rules->[$original_rule_id];
    $original_rule->action_set( $grammar, $action );
    $original_rule->[Marpa::XS::Internal::Rule::NULL_RANKING] = $null_ranking;
    $original_rule->[Marpa::XS::Internal::Rule::RANK]         = $rank;

    if ( defined $rule_name ) {
        $original_rule->[Marpa::XS::Internal::Rule::NAME] = $rule_name;
        $rules_by_name->{$rule_name} = $original_rule;
    }

    $grammar->[Marpa::XS::Internal::Grammar::NEXT_SYMBOL_NAME] = undef;

    return;

} ## end sub add_user_rule

sub set_start_symbol {
    my $grammar = shift;

    my $grammar_c  = $grammar->[Marpa::XS::Internal::Grammar::C];
    my $start_name = $grammar->[Marpa::XS::Internal::Grammar::START_NAME];

    # Let libmarpa catch this error
    return if not defined $start_name;
    my $symbol_hash = $grammar->[Marpa::XS::Internal::Grammar::SYMBOL_HASH];
    my $start_id    = $symbol_hash->{$start_name};
    Marpa::exception(qq{Start symbol "$start_name" not in grammar})
        if not defined $start_id;

    if ( !$grammar_c->start_symbol_set($start_id) ) {
        my $error = $grammar_c->error();
        Marpa::XS::uncaught_error($error);
    }
    return 1;
} ## end sub set_start_symbol

1;
