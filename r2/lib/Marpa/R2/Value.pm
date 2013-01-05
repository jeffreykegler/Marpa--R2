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

package Marpa::R2::Value;

use 5.010;
use warnings;
use strict;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.041_000';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::Value;

use English qw( -no_match_vars );

use constant SKIP => -1;

sub Marpa::R2::show_rank_ref {
    my ($rank_ref) = @_;
    return 'undef' if not defined $rank_ref;
    return 'SKIP'  if $rank_ref == Marpa::R2::Internal::Value::SKIP;
    return ${$rank_ref};
} ## end sub Marpa::R2::show_rank_ref

package Marpa::R2::Internal::Value;

# Given the grammar and an action name, resolve it to a closure,
# or return undef
sub Marpa::R2::Internal::Recognizer::resolve_semantics {
    my ( $recce, $closure_name ) = @_;
    my $grammar  = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $closures = $recce->[Marpa::R2::Internal::Recognizer::CLOSURES];
    my $trace_actions =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_ACTIONS];

    # A reserved closure name;
    return [ '::whatever', undef ] if not defined $closure_name;
    if ( substr( $closure_name, 0, 2 ) eq q{::} ) {
        return [ $closure_name, undef ]  if $closure_name eq '::whatever';
        return [ $closure_name, \undef ] if $closure_name eq '::undef';
        Marpa::R2::exception(
            qq{Unknown reserved action name "$closure_name"\n},
            q{  Action names beginning with "::" are reserved}
        );
    } ## end if ( substr( $closure_name, 0, 2 ) eq q{::} )

    if ( my $closure = $closures->{$closure_name} ) {
        if ($trace_actions) {
            print {$Marpa::R2::Internal::TRACE_FH}
                qq{Resolved "$closure_name" to explicit closure\n}
                or Marpa::R2::exception('Could not print to trace file');
        }

        return [ $closure_name, $closure ];
    } ## end if ( my $closure = $closures->{$closure_name} )

    my $fully_qualified_name;
    DETERMINE_FULLY_QUALIFIED_NAME: {
        if ( $closure_name =~ /([:][:])|[']/xms ) {
            $fully_qualified_name = $closure_name;
            last DETERMINE_FULLY_QUALIFIED_NAME;
        }
        if (defined(
                my $actions_package =
                    $grammar->[Marpa::R2::Internal::Grammar::ACTIONS]
            )
            )
        {
            $fully_qualified_name = $actions_package . q{::} . $closure_name;
            last DETERMINE_FULLY_QUALIFIED_NAME;
        } ## end if ( defined( my $actions_package = $grammar->[...]))

        if (defined(
                my $action_object_class =
                    $grammar->[Marpa::R2::Internal::Grammar::ACTION_OBJECT]
            )
            )
        {
            $fully_qualified_name =
                $action_object_class . q{::} . $closure_name;
        } ## end if ( defined( my $action_object_class = $grammar->[...]))
    } ## end DETERMINE_FULLY_QUALIFIED_NAME:

    return if not defined $fully_qualified_name;

    my $closure;
    my $type;
    TYPE: {
        no strict 'refs';
        $closure = *{$fully_qualified_name}{'CODE'};
        use strict;
        if ( defined $closure ) {
            $type = 'CODE';
            last TYPE;
        }
        no strict 'refs';
        $closure = *{$fully_qualified_name}{'SCALAR'};
        use strict;

        # Currently $closure is always defined, but this
        # behavior is said to be subject to change in perlref
        if ( defined $closure and defined ${$closure} ) {
            $type = 'SCALAR';
            last TYPE;
        }
        $closure = undef;
    } ## end TYPE:

    if ( defined $closure ) {
        if ($trace_actions) {
            print {$Marpa::R2::Internal::TRACE_FH}
                qq{Successful resolution of action "$closure_name" as $type },
                'to ', $fully_qualified_name, "\n"
                or Marpa::R2::exception('Could not print to trace file');
        } ## end if ($trace_actions)
        return [ $fully_qualified_name, $closure ];
    } ## end if ( defined $closure )

    if ($trace_actions) {
        print {$Marpa::R2::Internal::TRACE_FH}
            qq{Failed resolution of action "$closure_name" },
            'to ', $fully_qualified_name, "\n"
            or Marpa::R2::exception('Could not print to trace file');
    } ## end if ($trace_actions)

    return;

} ## end sub Marpa::R2::Internal::Recognizer::resolve_semantics

sub Marpa::R2::Internal::Recognizer::set_actions {
    my ($recce)       = @_;
    my $grammar       = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c     = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $tracer        = $grammar->[Marpa::R2::Internal::Grammar::TRACER];
    my $rules         = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $symbols       = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $rule_closures = [];
    my $trace_actions =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_ACTIONS] // 0;

    my $default_action =
        $grammar->[Marpa::R2::Internal::Grammar::DEFAULT_ACTION];
    my $default_action_resolution =
        Marpa::R2::Internal::Recognizer::resolve_semantics( $recce,
        $default_action );
    Marpa::R2::exception(
        "Could not resolve default action named '$default_action'")
        if not $default_action_resolution;

    my $default_empty_action =
        $grammar->[Marpa::R2::Internal::Grammar::DEFAULT_EMPTY_ACTION];
    my $default_empty_action_resolution;
    if ($default_empty_action) {
        $default_empty_action_resolution =
            Marpa::R2::Internal::Recognizer::resolve_semantics( $recce,
            $default_empty_action );
        Marpa::R2::exception(
            "Could not resolve default empty rule action named '$default_empty_action'"
        ) if not $default_empty_action_resolution;
    } ## end if ($default_empty_action)

    my $rule_resolutions = [];

    RULE: for my $rule ( @{$rules} ) {

        my $rule_id = $rule->[Marpa::R2::Internal::Rule::ID];

        if ( my $action = $tracer->action($rule_id) ) {
            my $resolution =
                Marpa::R2::Internal::Recognizer::resolve_semantics( $recce,
                $action );

            Marpa::R2::exception(qq{Could not resolve action name: "$action"})
                if not defined $resolution;
            $rule_resolutions->[$rule_id] = $resolution;
            next RULE;
        } ## end if ( my $action = $tracer->action($rule_id) )

        if (    $default_empty_action
            and $grammar_c->rule_length($rule_id) == 0 )
        {
            $rule_resolutions->[$rule_id] = $default_empty_action_resolution;
            next RULE;
        } ## end if ( $default_empty_action and $grammar_c->rule_length...)

        $rule_resolutions->[$rule_id] = $default_action_resolution;

    } ## end RULE: for my $rule ( @{$rules} )

    if ( $trace_actions >= 2 ) {
        RULE: for my $rule_id ( 0 .. $#{$rules} ) {
            my ( $resolution_name, $closure ) =
                @{ $rule_resolutions->[$rule_id] };
            say {$Marpa::R2::Internal::TRACE_FH} 'Rule ',
                $grammar->brief_rule($rule_id),
                qq{ resolves to "$resolution_name"}
                or Marpa::R2::exception('print to trace handle failed');
        } ## end RULE: for my $rule_id ( 0 .. $#{$rules} )
    } ## end if ( $trace_actions >= 2 )

    my @resolution_by_lhs;
    my @nullable_ruleids_by_lhs;

    # Because a "whatever" resolution can be *anything*, it cannot
    # be used along with a non-whatever resolution.  That is because
    # you could never be sure that what seems to be
    # a valid non-whatever resolution is not something random from
    # a whatever resolution
    RULE: for my $rule_id ( 0 .. $#{$rules} ) {
        my ( $new_resolution, $closure ) = @{ $rule_resolutions->[$rule_id] };
        my $lhs_id = $grammar_c->rule_lhs($rule_id);
        $resolution_by_lhs[$lhs_id] //= $new_resolution;
        my $current_resolution = $resolution_by_lhs[$lhs_id];
        if ($new_resolution ne $current_resolution
            and (  $current_resolution eq '::whatever'
                or $new_resolution eq '::whatever' )
            )
        {
            Marpa::R2::exception(
                'Symbol "',
                $grammar->symbol_name($lhs_id),
                qq{" has two resolutions "$current_resolution" and "$new_resolution"\n},
                qq{  These would confuse the semantics\n}
            );
        } ## end if ( $new_resolution ne $current_resolution and ( ...))
        if ( $new_resolution ne '::whatever' ) {
            $rule_closures->[$rule_id] = $closure;
        }
        push @{ $nullable_ruleids_by_lhs[$lhs_id] }, $rule_id
            if $grammar_c->rule_is_nullable($rule_id);
    } ## end RULE: for my $rule_id ( 0 .. $#{$rules} )

    # A LHS can be nullable via more than one rule,
    # and that means more than one semantics might be specified for
    # the nullable symbol.  This logic deals with that.
    my @null_symbol_closures;
    LHS:
    for ( my $lhs_id = 0; $lhs_id <= $#nullable_ruleids_by_lhs; $lhs_id++ ) {
        my $ruleids = $nullable_ruleids_by_lhs[$lhs_id];
        my $resolution_rule;

        # No nullable rules for this LHS?  No problem.
        next LHS if not defined $ruleids;
        my $rule_count = scalar @{$ruleids};

        # I am not sure if this test is necessary
        next LHS if $rule_count <= 0;

        # Just one nullable rule?  Then that's our semantics.
        if ( $rule_count == 1 ) {
            $resolution_rule = $ruleids->[0];
            my ( $resolution_name, $closure ) =
                @{ $rule_resolutions->[$resolution_rule] };
            if ($trace_actions) {
                my $lhs_name = $grammar->symbol_name($lhs_id);
                say {$Marpa::R2::Internal::TRACE_FH}
                    qq{Nulled symbol "$lhs_name" },
                    qq{ resolved to "$resolution_name" from rule },
                    $grammar->brief_rule($resolution_rule)
                    or Marpa::R2::exception('print to trace handle failed');
            } ## end if ($trace_actions)
            $null_symbol_closures[$lhs_id] = $resolution_rule;
            next LHS;
        } ## end if ( $rule_count == 1 )

        # More than one rule?  Are any empty?
        # If so, use the semantics of the empty rule
        my @empty_rules =
            grep { $grammar_c->rule_length($_) <= 0 } @{$ruleids};
        if ( scalar @empty_rules ) {
            $resolution_rule = $empty_rules[0];
            my ( $resolution_name, $closure ) =
                @{ $rule_resolutions->[$resolution_rule] };
            if ($trace_actions) {
                my $lhs_name = $grammar->symbol_name($lhs_id);
                say {$Marpa::R2::Internal::TRACE_FH}
                    qq{Nulled symbol "$lhs_name" },
                    qq{ resolved to "$resolution_name" from rule },
                    $grammar->brief_rule($resolution_rule)
                    or Marpa::R2::exception('print to trace handle failed');
            } ## end if ($trace_actions)
            $null_symbol_closures[$lhs_id] = $resolution_rule;
            next LHS;
        } ## end if ( scalar @empty_rules )

        # Multiple rules, none of them empty.
        my ( $first_resolution_name, @other_resolution_names ) =
            map { $rule_resolutions->[$_]->[0] } @{$ruleids};

        # Do they have more than one semantics?
        # Just call it an error and let the user sort it out.
        if ( grep { $_ ne $first_resolution_name } @other_resolution_names ) {
            my %seen = map { ( $_, 1 ); } $first_resolution_name,
                @other_resolution_names;
            Marpa::R2::exception(
                'When nulled, symbol ',
                $grammar->symbol_name($lhs_id),
                ' can have more than one semantics: ',
                ( join q{, }, ( keys %seen ) ),
                "\n",
                qq{  Marpa needs there to be only one\n}
            );
        } ## end if ( grep { $_ ne $first_resolution_name } ...)

        # Multiple rules, but they all have one semantics.
        # So (obviously) use that semantics
        $resolution_rule = $ruleids->[0];
        my ( $resolution_name, $closure ) =
            @{ $rule_resolutions->[$resolution_rule] };
        if ($trace_actions) {
            my $lhs_name = $grammar->symbol_name($lhs_id);
            say {$Marpa::R2::Internal::TRACE_FH}
                qq{Nulled symbol "$lhs_name" },
                qq{ resolved to "$resolution_name" from rule },
                $grammar->brief_rule($resolution_rule)
                or Marpa::R2::exception('print to trace handle failed');
        } ## end if ($trace_actions)
        $null_symbol_closures[$lhs_id] = $resolution_rule;

    } ## end LHS: for ( my $lhs_id = 0; $lhs_id <= $#nullable_ruleids_by_lhs...)

    $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES] =
        \@null_symbol_closures;
    $recce->[Marpa::R2::Internal::Recognizer::RULE_CLOSURES] = $rule_closures;

    return 1;
}    # set_actions

our $CONTEXT_EXCEPTION_CLASS = __PACKAGE__ . '::Context_Exception';

sub Marpa::R2::Context::bail { ## no critic (Subroutines::RequireArgUnpacking)
    if ( scalar @_ == 1 and ref $_[0] ) {
        die bless { exception_object => $_[0] }, $CONTEXT_EXCEPTION_CLASS;
    }
    my $error_string = join q{}, @_;
    my ( $package, $filename, $line ) = caller;
    chomp $error_string;
    die bless { message => qq{User bailed at line $line in file "$filename"\n}
            . $error_string
            . "\n" }, $CONTEXT_EXCEPTION_CLASS;
} ## end sub Marpa::R2::Context::bail
## use critic

sub Marpa::R2::Context::location {
    my $valuator = $Marpa::R2::Internal::Context::VALUATOR;
    Marpa::R2::exception(
        'Marpa::R2::Context::location called outside of a valuation context')
        if not defined $valuator;
    return $valuator->location();
} ## end sub Marpa::R2::Context::location

sub code_problems {
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
    ARG: for my $arg ( keys %{$args} ) {
        my $value = $args->{$arg};
        if ( $arg eq 'fatal_error' ) { $fatal_error = $value; next ARG }
        if ( $arg eq 'grammar' )     { $grammar     = $value; next ARG }
        if ( $arg eq 'where' )       { $where       = $value; next ARG }
        if ( $arg eq 'long_where' )  { $long_where  = $value; next ARG }
        if ( $arg eq 'warnings' )    { $warnings    = $value; next ARG }
        if ( $arg eq 'eval_ok' ) {
            $eval_value = $value;
            $eval_given = 1;
            next ARG;
        }
        push @msg, "Unknown argument to code_problems: $arg";
    } ## end ARG: for my $arg ( keys %{$args} )

    GIVEN_FATAL_ERROR_REF_TYPE: {
        my $fatal_error_ref_type = ref $fatal_error;
        last GIVEN_FATAL_ERROR_REF_TYPE if not $fatal_error_ref_type;
        if ( $fatal_error_ref_type eq $CONTEXT_EXCEPTION_CLASS ) {
            my $exception_object = $fatal_error->{exception_object};
            die $exception_object if defined $exception_object;
            my $exception_message = $fatal_error->{message};
            die $exception_message if defined $exception_message;
            die "Internal error: bad $CONTEXT_EXCEPTION_CLASS object";
        } ## end if ( $fatal_error_ref_type eq $CONTEXT_EXCEPTION_CLASS)
        $fatal_error =
              "Exception thrown as object inside Marpa closure\n"
            . ( q{ } x 4 )
            . "This is not allowed\n"
            . ( q{ } x 4 )
            . qq{Exception as string is "$fatal_error"};
    } ## end GIVEN_FATAL_ERROR_REF_TYPE:

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
                'Marpa::R2 requires its semantics to return a true value';
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
    Marpa::R2::exception(@msg);

    # this is to keep perlcritic happy
    return 1;

} ## end sub code_problems

# Does not modify stack
sub Marpa::R2::Internal::Recognizer::evaluate {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $order   = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree    = $recce->[Marpa::R2::Internal::Recognizer::T_C];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $token_values =
        $recce->[Marpa::R2::Internal::Recognizer::TOKEN_VALUES];
    my $grammar_c    = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $symbols      = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $rules        = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $trace_values = $recce->[Marpa::R2::Internal::Recognizer::TRACE_VALUES]
        // 0;

    local $Marpa::R2::Context::grammar = $grammar;
    local $Marpa::R2::Context::rule    = undef;

    my $action_object_class =
        $grammar->[Marpa::R2::Internal::Grammar::ACTION_OBJECT];

    my $action_object_constructor;
    if ( defined $action_object_class ) {
        my $constructor_name = $action_object_class . q{::new};
        my $resolution =
            Marpa::R2::Internal::Recognizer::resolve_semantics( $recce,
            $constructor_name );
        Marpa::R2::exception(
            qq{Could not find constructor "$constructor_name"})
            if not defined $resolution;
        ( undef, $action_object_constructor ) = @{$resolution};
    } ## end if ( defined $action_object_class )

    my $action_object;
    if ($action_object_constructor) {
        my @warnings;
        my $eval_ok;
        my $fatal_error;
        DO_EVAL: {
            local $EVAL_ERROR = undef;
            local $SIG{__WARN__} = sub {
                push @warnings, [ $_[0], ( caller 0 ) ];
            };

            $eval_ok = eval {
                $action_object =
                    $action_object_constructor->($action_object_class);
                1;
            };
            $fatal_error = $EVAL_ERROR;
        } ## end DO_EVAL:

        if ( not $eval_ok or @warnings ) {
            code_problems(
                {   fatal_error => $fatal_error,
                    grammar     => $grammar,
                    eval_ok     => $eval_ok,
                    warnings    => \@warnings,
                    where       => 'constructing action object',
                }
            );
        } ## end if ( not $eval_ok or @warnings )
    } ## end if ($action_object_constructor)

    $action_object //= {};

    my $rule_closures =
        $recce->[Marpa::R2::Internal::Recognizer::RULE_CLOSURES];
    if ( not defined $rule_closures ) {
        Marpa::R2::Internal::Recognizer::set_actions($recce);
        $rule_closures =
            $recce->[Marpa::R2::Internal::Recognizer::RULE_CLOSURES];
    }

    my $null_values = $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES];

    my $value = Marpa::R2::Thin::V->new($tree);
    local $Marpa::R2::Internal::Context::VALUATOR = $value;
    for my $rule_id ( 0 .. $#{$rule_closures} ) {
        my $result = $value->rule_is_valued_set( $rule_id, 1 );
        if ( not $result ) {
            my $lhs_id   = $grammar_c->rule_lhs($rule_id);
            my $lhs_name = $grammar->symbol_name($lhs_id);
            Marpa::R2::exception(
                qq{Cannot assign values to rule $rule_id (lhs is "$lhs_name") },
                q{because the LHS was already treated as an unvalued symbol}
            );
        } ## end if ( not $result )
    } ## end for my $rule_id ( 0 .. $#{$rule_closures} )

    for my $token_id ( grep { defined $null_values->[$_] }
        0 .. $#{$null_values} )
    {
        my $result = $value->symbol_is_valued_set( $token_id, 1 );
        if ( not $result ) {
            my $token_name = $grammar->symbol_name($token_id);
            Marpa::R2::exception(
                qq{Cannot assign values to symbol "$token_name"},
                q{because it was already treated as an unvalued symbol}
            );
        } ## end if ( not $result )
    } ## end for my $token_id ( grep { defined $null_values->[$_] ...})
    my @evaluation_stack = ();
    value_trace( $value, $trace_values ? 1 : 0 );

    EVENT: while (1) {
        my ( $value_type, @value_data ) = $value->step();
        last EVENT if not defined $value_type;

        if ( $trace_values >= 3 ) {
            for my $i ( reverse 0 .. $#evaluation_stack ) {
                printf {$Marpa::R2::Internal::TRACE_FH} 'Stack position %3d:',
                    $i
                    or Marpa::R2::exception('print to trace handle failed');
                print {$Marpa::R2::Internal::TRACE_FH} q{ },
                    Data::Dumper->new( [ $evaluation_stack[$i] ] )->Terse(1)
                    ->Dump
                    or Marpa::R2::exception('print to trace handle failed');
            } ## end for my $i ( reverse 0 .. $#evaluation_stack )
        } ## end if ( $trace_values >= 3 )

        if ( $value_type eq 'MARPA_STEP_TOKEN' ) {
            my ( $token_id, $value_ix, $arg_n ) = @value_data;
            my $value_ref = \( $token_values->[$value_ix] );
            $evaluation_stack[$arg_n] = $value_ref;
            trace_token_evaluation( $recce, $value, $token_id, $value_ref )
                if $trace_values;
            next EVENT;
        } ## end if ( $value_type eq 'MARPA_STEP_TOKEN' )

        if ( $value_type eq 'MARPA_STEP_NULLING_SYMBOL' ) {
            my ( $token_id, $arg_n ) = @value_data;
            my $semantic_rule_id = $null_values->[$token_id];
            my $value_ref        = $rule_closures->[$semantic_rule_id];

            if ( ref $value_ref eq 'CODE' ) {
                my @warnings;
                my $eval_ok;
                my $result;

                DO_EVAL: {
                    local $SIG{__WARN__} = sub {
                        push @warnings, [ $_[0], ( caller 0 ) ];
                    };

                    $eval_ok = eval {
                        local $Marpa::R2::Context::rule = $semantic_rule_id;
                        $result = $value_ref->($action_object);
                        1;
                    };

                } ## end DO_EVAL:

                if ( not $eval_ok or @warnings ) {
                    my $fatal_error = $EVAL_ERROR;
                    code_problems(
                        {   fatal_error => $fatal_error,
                            grammar     => $grammar,
                            eval_ok     => $eval_ok,
                            warnings    => \@warnings,
                            where       => 'computing value',
                            long_where  => 'Computing value for null symbol: '
                                . $grammar->symbol_name($token_id),
                        }
                    );
                } ## end if ( not $eval_ok or @warnings )
                $value_ref = \$result;
            } ## end if ( ref $value_ref eq 'CODE' )

            $evaluation_stack[$arg_n] = $value_ref;
            trace_token_evaluation( $recce, $value, $token_id, $value_ref )
                if $trace_values;
            next EVENT;
        } ## end if ( $value_type eq 'MARPA_STEP_NULLING_SYMBOL' )

        if ( $value_type eq 'MARPA_STEP_RULE' ) {
            my ( $rule_id, $arg_0, $arg_n ) = @value_data;
            my $closure = $rule_closures->[$rule_id];

            if ( defined $closure ) {
                my $result;
                my $rule = $rules->[$rule_id];

                my @args =
                    map { defined $_ ? ${$_} : $_ }
                    @evaluation_stack[ $arg_0 .. $arg_n ];
                if ( defined $grammar_c->sequence_min($rule_id) ) {
                    if ($rule->[Marpa::R2::Internal::Rule::DISCARD_SEPARATION]
                        )
                    {
                        @args =
                            @args[ map { 2 * $_ }
                            ( 0 .. ( scalar @args + 1 ) / 2 - 1 ) ];
                    } ## end if ( $rule->[...])
                } ## end if ( defined $grammar_c->sequence_min($rule_id) )
                else {
                    my $mask = $rule->[Marpa::R2::Internal::Rule::MASK];
                    @args = @args[ grep { $mask->[$_] } 0 .. $#args ];
                }

                if ( ref $closure eq 'CODE' ) {
                    my @warnings;
                    my $eval_ok;
                    DO_EVAL: {
                        local $SIG{__WARN__} = sub {
                            push @warnings, [ $_[0], ( caller 0 ) ];
                        };

                        $eval_ok = eval {
                            local $Marpa::R2::Context::rule = $rule_id;
                            $result = $closure->( $action_object, @args );
                            1;
                        };

                    } ## end DO_EVAL:

                    if ( not $eval_ok or @warnings ) {
                        my $fatal_error = $EVAL_ERROR;
                        code_problems(
                            {   fatal_error => $fatal_error,
                                grammar     => $grammar,
                                eval_ok     => $eval_ok,
                                warnings    => \@warnings,
                                where       => 'computing value',
                                long_where  => 'Computing value for rule: '
                                    . $grammar->brief_rule($rule_id),
                            }
                        );
                    } ## end if ( not $eval_ok or @warnings )
                    $evaluation_stack[$arg_0] = \$result;
                } ## end if ( ref $closure eq 'CODE' )
                else {
                    $evaluation_stack[$arg_0] = $closure;
                }

                if ($trace_values) {
                    say {$Marpa::R2::Internal::TRACE_FH}
                        trace_stack_1( $grammar, $recce, $value, \@args,
                        $rule_id )
                        or
                        Marpa::R2::exception('Could not print to trace file');
                    print {$Marpa::R2::Internal::TRACE_FH}
                        'Calculated and pushed value: ',
                        Data::Dumper->new( [$result] )->Terse(1)->Dump
                        or
                        Marpa::R2::exception('print to trace handle failed');
                } ## end if ($trace_values)

                next EVENT;

            } ## end if ( defined $closure )

            next EVENT;

        } ## end if ( $value_type eq 'MARPA_STEP_RULE' )

        if ( $value_type eq 'MARPA_STEP_TRACE' ) {

            if ($trace_values) {
                print {$Marpa::R2::Internal::TRACE_FH}
                    trace_op( $grammar, $recce, $value, )
                    or Marpa::R2::exception('Could not print to trace file');
            }

            next EVENT;

        } ## end if ( $value_type eq 'MARPA_STEP_TRACE' )

        die "Internal error: Unknown value type $value_type";

    } ## end EVENT: while (1)

    my $top_value = $evaluation_stack[0];

    return $top_value // ( \undef );

} ## end sub Marpa::R2::Internal::Recognizer::evaluate

# Returns false if no parse
sub Marpa::R2::Recognizer::value { ## no critic (Subroutines::RequireArgUnpacking)
    my ($recce) = @_;

    Marpa::R2::exception('Too many arguments to Marpa::R2::Recognizer::value')
        if scalar @_ != 1;

    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $order     = $recce->[Marpa::R2::Internal::Recognizer::O_C];

    my $parse_set_arg = $recce->[Marpa::R2::Internal::Recognizer::END];

    local $Marpa::R2::Internal::TRACE_FH =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE];

    my $furthest_earleme       = $recce_c->furthest_earleme();
    my $last_completed_earleme = $recce_c->current_earleme();
    Marpa::R2::exception(
        "Attempt to evaluate incompletely recognized parse:\n",
        "  Last token ends at location $furthest_earleme\n",
        "  Recognition done only as far as location $last_completed_earleme\n"
    ) if $furthest_earleme > $last_completed_earleme;

    my $tree = $recce->[Marpa::R2::Internal::Recognizer::T_C];

    if ($tree) {
        my $max_parses =
            $recce->[Marpa::R2::Internal::Recognizer::MAX_PARSES];
        my $parse_count = $tree->parse_count();
        if ( $max_parses and $parse_count > $max_parses ) {
            Marpa::R2::exception(
                "Maximum parse count ($max_parses) exceeded");
        }

    } ## end if ($tree)
    else {

        $grammar_c->throw_set(0);
        my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C] =
            Marpa::R2::Thin::B->new( $recce_c, ( $parse_set_arg // -1 ) );
        $grammar_c->throw_set(1);

        return if not defined $bocage;

        $order = $recce->[Marpa::R2::Internal::Recognizer::O_C] =
            Marpa::R2::Thin::O->new($bocage);

        GIVEN_RANKING_METHOD: {
            my $ranking_method =
                $recce->[Marpa::R2::Internal::Recognizer::RANKING_METHOD];
            if ( $ranking_method eq 'high_rule_only' ) {
                do_high_rule_only($recce);
                last GIVEN_RANKING_METHOD;
            }
            if ( $ranking_method eq 'rule' ) {
                do_rank_by_rule($recce);
                last GIVEN_RANKING_METHOD;
            }
        } ## end GIVEN_RANKING_METHOD:

        $tree = $recce->[Marpa::R2::Internal::Recognizer::T_C] =
            Marpa::R2::Thin::T->new($order);

    } ## end else [ if ($tree) ]

    if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_AND_NODES] ) {
        print {$Marpa::R2::Internal::TRACE_FH} 'AND_NODES: ',
            $recce->show_and_nodes()
            or Marpa::R2::exception('print to trace handle failed');
    }

    if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_OR_NODES] ) {
        print {$Marpa::R2::Internal::TRACE_FH} 'OR_NODES: ',
            $recce->show_or_nodes()
            or Marpa::R2::exception('print to trace handle failed');
    }

    if ( $recce->[Marpa::R2::Internal::Recognizer::TRACE_BOCAGE] ) {
        print {$Marpa::R2::Internal::TRACE_FH} 'BOCAGE: ',
            $recce->show_bocage()
            or Marpa::R2::exception('print to trace handle failed');
    }

    return if not defined $tree->next();
    return Marpa::R2::Internal::Recognizer::evaluate($recce);

} ## end sub Marpa::R2::Recognizer::value

sub do_high_rule_only {
    my ($recce) = @_;
    my $order = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    $order->high_rank_only_set(1);
    $order->rank();
    return 1;
} ## end sub do_high_rule_only

sub do_rank_by_rule {
    my ($recce) = @_;
    my $order = $recce->[Marpa::R2::Internal::Recognizer::O_C];

    # Rank by rule is the default, but just in case
    $order->high_rank_only_set(0);
    $order->rank();
    return 1;
} ## end sub do_rank_by_rule

# INTERNAL OK AFTER HERE _marpa_

sub Marpa::R2::Recognizer::show_bocage {
    my ($recce) = @_;
    my $text;
    my @data      = ();
    my $id        = 0;
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage    = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    OR_NODE: for ( my $or_node_id = 0;; $or_node_id++ ) {
        my $irl_id = $bocage->_marpa_b_or_node_irl($or_node_id);
        last OR_NODE if not defined $irl_id;
        my $position        = $bocage->_marpa_b_or_node_position($or_node_id);
        my $or_origin       = $bocage->_marpa_b_or_node_origin($or_node_id);
        my $origin_earleme  = $recce_c->earleme($or_origin);
        my $or_set          = $bocage->_marpa_b_or_node_set($or_node_id);
        my $current_earleme = $recce_c->earleme($or_set);
        my @and_node_ids =
            ( $bocage->_marpa_b_or_node_first_and($or_node_id)
                .. $bocage->_marpa_b_or_node_last_and($or_node_id) );
        AND_NODE:

        for my $and_node_id (@and_node_ids) {
            my $symbol = $bocage->_marpa_b_and_node_symbol($and_node_id);
            my $cause_tag;

            if ( defined $symbol ) {
                $cause_tag = "S$symbol";
            }
            my $cause_id = $bocage->_marpa_b_and_node_cause($and_node_id);
            my $cause_irl_id;
            if ( defined $cause_id ) {
                $cause_irl_id = $bocage->_marpa_b_or_node_irl($cause_id);
                $cause_tag =
                    Marpa::R2::Recognizer::or_node_tag( $recce, $cause_id );
            }
            my $parent_tag =
                Marpa::R2::Recognizer::or_node_tag( $recce, $or_node_id );
            my $predecessor_id =
                $bocage->_marpa_b_and_node_predecessor($and_node_id);
            my $predecessor_tag = q{-};
            if ( defined $predecessor_id ) {
                $predecessor_tag = Marpa::R2::Recognizer::or_node_tag( $recce,
                    $predecessor_id );
            }
            my $tag = join q{ }, $parent_tag, $predecessor_tag, $cause_tag;
            my $middle_earleme = $origin_earleme;
            if ( defined $predecessor_id ) {
                my $predecessor_set =
                    $bocage->_marpa_b_or_node_set($predecessor_id);
                $middle_earleme = $recce_c->earleme($predecessor_set);
            }

            push @data,
                [
                $origin_earleme, $current_earleme,
                $irl_id,         $position,
                $middle_earleme, ( defined $symbol ? 0 : 1 ),
                ( $symbol // $cause_irl_id ), $tag
                ];
        } ## end AND_NODE: for my $and_node_id (@and_node_ids)
    } ## end OR_NODE: for ( my $or_node_id = 0;; $or_node_id++ )
    my @sorted_data = map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            or $a->[1] <=> $b->[1]
            or $a->[2] <=> $b->[2]
            or $a->[3] <=> $b->[3]
            or $a->[4] <=> $b->[4]
            or $a->[5] <=> $b->[5]
            or $a->[6] <=> $b->[6]
    } @data;
    return ( join "\n", @sorted_data ) . "\n";
} ## end sub Marpa::R2::Recognizer::show_bocage

sub Marpa::R2::Recognizer::and_node_tag {
    my ( $recce, $and_node_id ) = @_;
    my $bocage            = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $recce_c           = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $parent_or_node_id = $bocage->_marpa_b_and_node_parent($and_node_id);
    my $origin         = $bocage->_marpa_b_or_node_origin($parent_or_node_id);
    my $origin_earleme = $recce_c->earleme($origin);
    my $current_earley_set =
        $bocage->_marpa_b_or_node_set($parent_or_node_id);
    my $current_earleme = $recce_c->earleme($current_earley_set);
    my $cause_id        = $bocage->_marpa_b_and_node_cause($and_node_id);
    my $predecessor_id = $bocage->_marpa_b_and_node_predecessor($and_node_id);
    my $middle_earleme = $origin_earleme;

    if ( defined $predecessor_id ) {
        my $middle_set = $bocage->_marpa_b_or_node_set($predecessor_id);
        $middle_earleme = $recce_c->earleme($middle_set);
    }
    my $position = $bocage->_marpa_b_or_node_position($parent_or_node_id);
    my $irl_id   = $bocage->_marpa_b_or_node_irl($parent_or_node_id);

#<<<  perltidy introduces trailing space on this
    my $tag =
          'R'
        . $irl_id . q{:}
        . $position . q{@}
        . $origin_earleme . q{-}
        . $current_earleme;
#>>>
    if ( defined $cause_id ) {
        my $cause_irl_id = $bocage->_marpa_b_or_node_irl($cause_id);
        $tag .= 'C' . $cause_irl_id;
    }
    else {
        my $symbol = $bocage->_marpa_b_and_node_symbol($and_node_id);
        $tag .= 'S' . $symbol;
    }
    $tag .= q{@} . $middle_earleme;
    return $tag;
} ## end sub Marpa::R2::Recognizer::and_node_tag

sub Marpa::R2::Recognizer::show_and_nodes {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $text;
    my @data = ();
    AND_NODE: for ( my $id = 0;; $id++ ) {
        my $parent      = $bocage->_marpa_b_and_node_parent($id);
        my $predecessor = $bocage->_marpa_b_and_node_predecessor($id);
        my $cause       = $bocage->_marpa_b_and_node_cause($id);
        my $symbol      = $bocage->_marpa_b_and_node_symbol($id);
        last AND_NODE if not defined $parent;
        my $origin          = $bocage->_marpa_b_or_node_origin($parent);
        my $set             = $bocage->_marpa_b_or_node_set($parent);
        my $irl_id          = $bocage->_marpa_b_or_node_irl($parent);
        my $position        = $bocage->_marpa_b_or_node_position($parent);
        my $origin_earleme  = $recce_c->earleme($origin);
        my $current_earleme = $recce_c->earleme($set);
        my $middle_earleme  = $origin_earleme;

        if ( defined $predecessor ) {
            my $predecessor_set = $bocage->_marpa_b_or_node_set($predecessor);
            $middle_earleme = $recce_c->earleme($predecessor_set);
        }

#<<<  perltidy introduces trailing space on this
        my $desc =
              'R'
            . $irl_id . q{:}
            . $position . q{@}
            . $origin_earleme . q{-}
            . $current_earleme;
#>>>
        my $cause_rule = -1;
        if ( defined $cause ) {
            my $cause_irl_id = $bocage->_marpa_b_or_node_irl($cause);
            $desc .= 'C' . $cause_irl_id;
        }
        else {
            $desc .= 'S' . $symbol;
        }
        $desc .= q{@} . $middle_earleme;
        push @data,
            [
            $origin_earleme, $current_earleme, $irl_id,
            $position,       $middle_earleme,  $cause_rule,
            ( $symbol // -1 ), $desc
            ];
    } ## end AND_NODE: for ( my $id = 0;; $id++ )
    my @sorted_data = map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            or $a->[1] <=> $b->[1]
            or $a->[2] <=> $b->[2]
            or $a->[3] <=> $b->[3]
            or $a->[4] <=> $b->[4]
            or $a->[5] <=> $b->[5]
            or $a->[6] <=> $b->[6]
    } @data;
    return ( join "\n", @sorted_data ) . "\n";
} ## end sub Marpa::R2::Recognizer::show_and_nodes

sub Marpa::R2::Recognizer::or_node_tag {
    my ( $recce, $or_node_id ) = @_;
    my $bocage   = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $set      = $bocage->_marpa_b_or_node_set($or_node_id);
    my $irl_id   = $bocage->_marpa_b_or_node_irl($or_node_id);
    my $origin   = $bocage->_marpa_b_or_node_origin($or_node_id);
    my $position = $bocage->_marpa_b_or_node_position($or_node_id);
    return 'R' . $irl_id . q{:} . $position . q{@} . $origin . q{-} . $set;
} ## end sub Marpa::R2::Recognizer::or_node_tag

sub Marpa::R2::Recognizer::show_or_nodes {
    my ( $recce, $verbose ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $text;
    my @data = ();
    my $id   = 0;
    OR_NODE: for ( ;; ) {
        my $origin   = $bocage->_marpa_b_or_node_origin($id);
        my $set      = $bocage->_marpa_b_or_node_set($id);
        my $irl_id   = $bocage->_marpa_b_or_node_irl($id);
        my $position = $bocage->_marpa_b_or_node_position($id);
        $id++;
        last OR_NODE if not defined $origin;
        my $origin_earleme  = $recce_c->earleme($origin);
        my $current_earleme = $recce_c->earleme($set);

#<<<  perltidy introduces trailing space on this
        my $desc =
              'R'
            . $irl_id . q{:}
            . $position . q{@}
            . $origin_earleme . q{-}
            . $current_earleme;
#>>>
        push @data,
            [ $origin_earleme, $current_earleme, $irl_id, $position, $desc ];
    } ## end OR_NODE: for ( ;; )
    my @sorted_data = map { $_->[-1] } sort {
               $a->[0] <=> $b->[0]
            or $a->[1] <=> $b->[1]
            or $a->[2] <=> $b->[2]
            or $a->[3] <=> $b->[3]
    } @data;
    return ( join "\n", @sorted_data ) . "\n";
} ## end sub Marpa::R2::Recognizer::show_or_nodes

sub Marpa::R2::Recognizer::show_nook {
    my ( $recce, $nook_id, $verbose ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $order   = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree    = $recce->[Marpa::R2::Internal::Recognizer::T_C];

    my $or_node_id = $tree->_marpa_t_nook_or_node($nook_id);
    return if not defined $or_node_id;

    my $text = "o$or_node_id";
    my $parent = $tree->_marpa_t_nook_parent($nook_id) // q{-};
    CHILD_TYPE: {
        if ( $tree->_marpa_t_nook_is_cause($nook_id) ) {
            $text .= "[c$parent]";
            last CHILD_TYPE;
        }
        if ( $tree->_marpa_t_nook_is_predecessor($nook_id) ) {
            $text .= "[p$parent]";
            last CHILD_TYPE;
        }
        $text .= '[-]';
    } ## end CHILD_TYPE:
    my $or_node_tag =
        Marpa::R2::Recognizer::or_node_tag( $recce, $or_node_id );
    $text .= " $or_node_tag";

    $text .= ' p';
    $text .=
        $tree->_marpa_t_nook_predecessor_is_ready($nook_id)
        ? q{=ok}
        : q{-};
    $text .= ' c';
    $text .= $tree->_marpa_t_nook_cause_is_ready($nook_id) ? q{=ok} : q{-};
    $text .= "\n";

    DESCRIBE_CHOICES: {
        my $this_choice = $tree->_marpa_t_nook_choice($nook_id);
        CHOICE: for ( my $choice_ix = 0;; $choice_ix++ ) {
            my $and_node_id =
                $order->_marpa_o_and_node_order_get( $or_node_id,
                $choice_ix );
            last CHOICE if not defined $and_node_id;
            $text .= " o$or_node_id" . '[' . $choice_ix . ']';
            if ( defined $this_choice and $this_choice == $choice_ix ) {
                $text .= q{*};
            }
            my $and_node_tag =
                Marpa::R2::Recognizer::and_node_tag( $recce, $and_node_id );
            $text .= " ::= a$and_node_id $and_node_tag";
            $text .= "\n";
        } ## end CHOICE: for ( my $choice_ix = 0;; $choice_ix++ )
    } ## end DESCRIBE_CHOICES:
    return $text;
} ## end sub Marpa::R2::Recognizer::show_nook

sub Marpa::R2::Recognizer::show_tree {
    my ( $recce, $verbose ) = @_;
    my $text = q{};
    NOOK: for ( my $nook_id = 0; 1; $nook_id++ ) {
        my $nook_text = $recce->show_nook( $nook_id, $verbose );
        last NOOK if not defined $nook_text;
        $text .= "$nook_id: $nook_text";
    }
    return $text;
} ## end sub Marpa::R2::Recognizer::show_tree

sub trace_token_evaluation {
    my ( $recce, $value, $token_id, $value_ref ) = @_;
    my $order   = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree    = $recce->[Marpa::R2::Internal::Recognizer::T_C];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];

    my $nook_ix = $value->_marpa_v_nook();
    if ( not defined $nook_ix ) {
        print {$Marpa::R2::Internal::TRACE_FH} "Nulling valuator\n"
            or Marpa::R2::exception('Could not print to trace file');
        return;
    }
    my $or_node_id = $tree->_marpa_t_nook_or_node($nook_ix);
    my $choice     = $tree->_marpa_t_nook_choice($nook_ix);
    my $and_node_id =
        $order->_marpa_o_and_node_order_get( $or_node_id, $choice );
    my $token_name;
    if ( defined $token_id ) {
        $token_name = $grammar->symbol_name($token_id);
    }

    print {$Marpa::R2::Internal::TRACE_FH}
        'Pushed value from ',
        Marpa::R2::Recognizer::and_node_tag( $recce, $and_node_id ),
        ': ',
        ( $token_name ? qq{$token_name = } : q{} ),
        Data::Dumper->new( [$value_ref] )->Terse(1)->Dump
        or Marpa::R2::exception('print to trace handle failed');

    return;

} ## end sub trace_token_evaluation

sub trace_stack_1 {
    my ( $grammar, $recce, $value, $args, $rule_id ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $order   = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree    = $recce->[Marpa::R2::Internal::Recognizer::T_C];

    my $argc       = scalar @{$args};
    my $nook_ix    = $value->_marpa_v_nook();
    my $or_node_id = $tree->_marpa_t_nook_or_node($nook_ix);
    my $choice     = $tree->_marpa_t_nook_choice($nook_ix);
    my $and_node_id =
        $order->_marpa_o_and_node_order_get( $or_node_id, $choice );

    return 'Popping ', $argc,
        ' values to evaluate ',
        Marpa::R2::Recognizer::and_node_tag( $recce, $and_node_id ),
        ', rule: ', $grammar->brief_rule($rule_id);

} ## end sub trace_stack_1

sub trace_op {

    my ( $grammar, $recce, $value ) = @_;
    my $trace_output = q{};
    my $grammar_c    = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $bocage       = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $order        = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree         = $recce->[Marpa::R2::Internal::Recognizer::T_C];

    my $nook_ix    = $value->_marpa_v_nook();
    my $or_node_id = $tree->_marpa_t_nook_or_node($nook_ix);
    my $choice     = $tree->_marpa_t_nook_choice($nook_ix);
    my $and_node_id =
        $order->_marpa_o_and_node_order_get( $or_node_id, $choice );
    my $trace_irl_id = $bocage->_marpa_b_or_node_irl($or_node_id);
    my $virtual_rhs  = $grammar_c->_marpa_g_irl_is_virtual_rhs($trace_irl_id);
    my $virtual_lhs  = $grammar_c->_marpa_g_irl_is_virtual_lhs($trace_irl_id);

    return $trace_output
        if $bocage->_marpa_b_or_node_position($or_node_id)
            != $grammar_c->_marpa_g_irl_length($trace_irl_id);

    return $trace_output if not $virtual_rhs and not $virtual_lhs;

    if ( $virtual_rhs and not $virtual_lhs ) {

        $trace_output .= join q{},
            'Head of Virtual Rule: ',
            Marpa::R2::Recognizer::and_node_tag( $recce, $and_node_id ),
            ', rule: ', $grammar->brief_irl($trace_irl_id),
            "\n",
            'Incrementing virtual rule by ',
            $grammar_c->_marpa_g_real_symbol_count($trace_irl_id), ' symbols',
            "\n"
            or Marpa::R2::exception('Could not print to trace file');

        return $trace_output;

    } ## end if ( $virtual_rhs and not $virtual_lhs )

    if ( $virtual_lhs and $virtual_rhs ) {

        $trace_output .= join q{},
            'Virtual Rule: ',
            Marpa::R2::Recognizer::and_node_tag( $recce, $and_node_id ),
            ', rule: ', $grammar->brief_irl($trace_irl_id),
            "\nAdding ",
            $grammar_c->_marpa_g_real_symbol_count($trace_irl_id),
            "\n";

        return $trace_output;

    } ## end if ( $virtual_lhs and $virtual_rhs )

    if ( not $virtual_rhs and $virtual_lhs ) {

        $trace_output .= join q{},
            'New Virtual Rule: ',
            Marpa::R2::Recognizer::and_node_tag( $recce, $and_node_id ),
            ', rule: ', $grammar->brief_irl($trace_irl_id),
            "\nReal symbol count is ",
            $grammar_c->_marpa_g_real_symbol_count($trace_irl_id),
            "\n";

        return $trace_output;

    } ## end if ( not $virtual_rhs and $virtual_lhs )

    return $trace_output;
} ## end sub trace_op

sub value_trace {
    my ( $value, $trace_flag ) = @_;
    return $value->_marpa_v_trace($trace_flag);
}

1;
