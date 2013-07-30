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

package Marpa::R2::Value;

use 5.010;
use warnings;
use strict;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.065_004';
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

# The external version
# Undocumented as of now.
#
# Instead of documenting this, perhaps semantics should be
# separated into its own object.
#
sub Marpa::R2::Recognizer::semantics_set {
    my ( $recce, @arg_hashes ) = @_;
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];

    # set the defaults
    local $Marpa::R2::Internal::TRACE_FH =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE] =
        $grammar->[Marpa::R2::Internal::Grammar::TRACE_FILE_HANDLE];

    $recce->[Marpa::R2::Internal::Recognizer::RULE_RESOLUTIONS] =
        Marpa::R2::Internal::Recognizer::semantics_set( $recce,
        Marpa::R2::Internal::Recognizer::default_semantics($recce) );

    if (0) {
        ARG_HASH: for my $arg_hash (@arg_hashes) {
            if (defined( my $value = $arg_hash->{'action_name_by_rule_id'} ) )
            {
                Marpa::R2::exception(
                    qq{value of "$value" must be a REF to an array rule ID's to action names}
                ) if ref $value ne 'ARRAY';
                delete $arg_hash->{$value};
                last ARG_HASH;
            } ## end if ( defined( my $value = $arg_hash->{...}))
        } ## end ARG_HASH: for my $arg_hash (@arg_hashes)
    } ## end if (0)

    return $recce;
} ## end sub Marpa::R2::Recognizer::semantics_set

# Given the grammar and an action name, resolve it to a closure,
# or return undef
sub Marpa::R2::Internal::Recognizer::resolve_action {
    my ( $recce, $closure_name ) = @_;
    my $grammar  = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $closures = $recce->[Marpa::R2::Internal::Recognizer::CLOSURES];
    my $trace_actions =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_ACTIONS];

    # A reserved closure name;
    return [ q{}, undef, '::!default' ] if not defined $closure_name;

    if ( $closure_name eq q{} ) {
        return q{The action string cannot be the empty string};
    }

    return [ q{}, \undef, $closure_name ] if $closure_name eq '::undef';
    if (   substr( $closure_name, 0, 2 ) eq q{::}
        or substr( $closure_name, 0, 1 ) eq '[' )
    {
        return [ q{}, undef, $closure_name ];
    }

    if ( my $closure = $closures->{$closure_name} ) {
        if ($trace_actions) {
            print {$Marpa::R2::Internal::TRACE_FH}
                qq{Resolved "$closure_name" to explicit closure\n}
                or Marpa::R2::exception('Could not print to trace file');
        }

        return [ $closure_name, $closure, '::array' ];
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

    return qq{Could not fully qualify "$closure_name"}
        if not defined $fully_qualified_name;

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

        # Re other symbol tables entries:
        # We ignore ARRAY and HASH because they anything
        # we resolve to is a potential array entry, something
        # that not possible for arrays and hashes except
        # indirectly, via references.
        # FORMAT is deprecated.
        # IO and GLOB seem too abstruse at the moment.

        $closure = undef;
    } ## end TYPE:

    if ( defined $closure ) {
        if ($trace_actions) {
            print {$Marpa::R2::Internal::TRACE_FH}
                qq{Successful resolution of action "$closure_name" as $type },
                'to ', $fully_qualified_name, "\n"
                or Marpa::R2::exception('Could not print to trace file');
        } ## end if ($trace_actions)
        return [ $fully_qualified_name, $closure, '::array' ];
    } ## end if ( defined $closure )

    my $error =
        qq{Failed resolution of action "$closure_name" to $fully_qualified_name \n};
    if ($trace_actions) {
        print {$Marpa::R2::Internal::TRACE_FH} $error
            or Marpa::R2::exception('Could not print to trace file');
    }

    return $error;

} ## end sub Marpa::R2::Internal::Recognizer::resolve_action


# Elaborate the semantics for a lexeme.  "Resolve" may not be quite
# the right term, since (at least right now) closures are not
# involved.
sub Marpa::R2::Internal::Recognizer::resolve_lexeme_semantics {
    my ( $recce, $lexeme_id ) = @_;
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $symbols = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $tracer    = $grammar->[Marpa::R2::Internal::Grammar::TRACER];
    my $trace_actions =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_ACTIONS];
    my $bless_package =
        $grammar->[Marpa::R2::Internal::Grammar::BLESS_PACKAGE];
    my $symbol = $symbols->[$lexeme_id];

    my $semantics = $symbol->[Marpa::R2::Internal::Symbol::LEXEME_SEMANTICS];
    $semantics = "::!default" if not defined $semantics;

    my $blessing = $symbol->[Marpa::R2::Internal::Symbol::BLESSING];
    return [$semantics, '::undef'] if not defined $blessing;
    return [$semantics, '::undef'] if $blessing eq '::undef';
    if ( $blessing =~ m/\A [:][:] /xms ) {
        my $lexeme_name = $tracer->symbol_name($lexeme_id);
        return qq{Symbol "$lexeme_name" has unknown blessing: "$blessing"};
    }
    if ( $blessing =~ m/ [:][:] /xms ) {
        return [$semantics, $blessing];
    }
    if ( not defined $bless_package ) {
        my $lexeme_name = $tracer->symbol_name($lexeme_id);
        return
            qq{Symbol "$lexeme_name" needs a blessing package, but grammar has none\n}
            . qq{  The blessing for "$lexeme_name" was "$blessing"\n};
    } ## end if ( not defined $bless_package )
    return [ $semantics, $bless_package . q{::} . $blessing ];
} ## end sub Marpa::R2::Internal::Recognizer::resolve_symbol_semantics

sub Marpa::R2::Internal::Recognizer::add_blessing {
    my ( $recce, $resolution, $blessing ) = @_;
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];

    # Among other things, this passes through error messages
    # untouched
    return $resolution if ref $resolution ne 'ARRAY';
    my ( $closure_name, $closure, $semantics ) = @{$resolution};
    return [ $closure_name, $closure, $semantics, q{} ]
        if not defined $blessing;

    $semantics = '::array' if $semantics eq '::!default';
    CHECK_SEMANTICS: {
        last CHECK_SEMANTICS if $semantics eq '::array';
        last CHECK_SEMANTICS if (substr $semantics, 0, 1) eq '[';
        return qq{Attempt to bless, but improper semantics: "$semantics"};
    }

    # Now figure out the blessings
    my $bless_package =
        $grammar->[Marpa::R2::Internal::Grammar::BLESS_PACKAGE];
    return qq{A blessed rule is in a grammar with no bless_package\n}
        . qq{  The rule was blessed as "$blessing"\n}
        if not defined $bless_package;
    return [
        $closure_name, $closure,
        $semantics, ( join q{}, $bless_package, q{::}, $blessing )
    ];
} ## end sub Marpa::R2::Internal::Recognizer::add_blessing

sub Marpa::R2::Internal::Recognizer::default_semantics {
    my ($recce)   = @_;
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $rules     = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $symbols   = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $tracer    = $grammar->[Marpa::R2::Internal::Grammar::TRACER];

    my $trace_actions =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_ACTIONS] // 0;

    my $default_action =
        $grammar->[Marpa::R2::Internal::Grammar::DEFAULT_ACTION];
    my $default_action_resolution =
        Marpa::R2::Internal::Recognizer::resolve_action( $recce,
        $default_action );
    Marpa::R2::exception(
        "Could not resolve default action named '$default_action'\n",
        q{  }, ( $default_action_resolution // 'Failed to resolve action' ) )
        if not ref $default_action_resolution;

    my $default_empty_action =
        $grammar->[Marpa::R2::Internal::Grammar::DEFAULT_EMPTY_ACTION];
    my $default_empty_action_resolution;
    if ($default_empty_action) {
        $default_empty_action_resolution =
            Marpa::R2::Internal::Recognizer::resolve_action( $recce,
            $default_empty_action );
        Marpa::R2::exception(
            "Could not resolve default empty rule action named '$default_empty_action'",
            q{  },
            (   $default_empty_action_resolution // 'Failed to resolve action'
            )
        ) if not ref $default_empty_action_resolution;
    } ## end if ($default_empty_action)

    my $rule_resolutions = [];

    RULE: for my $rule_id ( $grammar->rule_ids() ) {

        my $rule   = $rules->[$rule_id];
        my $action = $rule->[Marpa::R2::Internal::Rule::ACTION_NAME];

        my $rule_resolution;
        DETERMINE_RULE_RESOLUTION: {
            if ($action) {
                $rule_resolution =
                    Marpa::R2::Internal::Recognizer::add_blessing(
                    $recce,
                    Marpa::R2::Internal::Recognizer::resolve_action(
                        $recce, $action
                    ),
                    $rule->[Marpa::R2::Internal::Rule::BLESSING]
                    );

                last DETERMINE_RULE_RESOLUTION;
            } ## end if ($action)

            if (    $default_empty_action
                and $grammar_c->rule_length($rule_id) == 0 )
            {
                $rule_resolution =
                    Marpa::R2::Internal::Recognizer::add_blessing(
                    $recce,
                    $default_empty_action_resolution,
                    $rule->[Marpa::R2::Internal::Rule::BLESSING]
                    );
                last DETERMINE_RULE_RESOLUTION;
            } ## end if ( $default_empty_action and $grammar_c->rule_length...)

            $rule_resolution =
                Marpa::R2::Internal::Recognizer::add_blessing( $recce,
                $default_action_resolution,
                $rule->[Marpa::R2::Internal::Rule::BLESSING] );

            last DETERMINE_RULE_RESOLUTION;
        } ## end DETERMINE_RULE_RESOLUTION:

        if ( not ref $rule_resolution ) {
            my $message =
                  "Could not resolve action\n"
                . q{  Rule was }
                . $grammar->brief_rule($rule_id) . "\n";
            $message .= qq{  Action was specified as "$action"\n}
                if defined $action;
            $message .= qq{  $rule_resolution\n} if defined $rule_resolution;
            Marpa::R2::exception($message);
        } ## end if ( not ref $rule_resolution )
        $rule_resolutions->[$rule_id] = $rule_resolution;

    } ## end RULE: for my $rule_id ( $grammar->rule_ids() )

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

    my @lexeme_resolutions = ();
    SYMBOL: for my $lexeme_id ( 0 .. $#{$symbols} ) {
        my $lexeme_resolution =
            Marpa::R2::Internal::Recognizer::resolve_lexeme_semantics( $recce,
            $lexeme_id );
        if ( not ref $lexeme_resolution ) {
            my $message =
                  "Could not determine lexeme's semantics\n"
                . q{  Lexeme was }
                . $grammar->symbol_name($lexeme_id) . "\n";
            $message .= qq{  $lexeme_resolution\n}
                if defined $lexeme_resolution;
            Marpa::R2::exception($message);
        } ## end if ( not ref $lexeme_resolution )
        $lexeme_resolutions[$lexeme_id] = $lexeme_resolution;

    } ## end SYMBOL: for my $lexeme_id ( 0 .. $#{$symbols} )

    return ( $rule_resolutions, \@lexeme_resolutions );

} ## end sub Marpa::R2::Internal::Recognizer::default_semantics

# For diagnostics
sub Marpa::R2::Internal::Recognizer::brief_rule_list {
    my ( $recce, $rule_ids ) = @_;
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my @brief_rules = map { $grammar->brief_rule($_) } @{$rule_ids};
    return join q{}, map { q{    } . $_ . "\n" } @brief_rules;
} ## end sub Marpa::R2::Internal::Recognizer::brief_rule_list

sub Marpa::R2::Internal::Recognizer::semantics_set {
    my ( $recce, $rule_resolutions, $lexeme_resolutions ) = @_;
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $tracer    = $grammar->[Marpa::R2::Internal::Grammar::TRACER];
    my $rules     = $grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $symbols   = $grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];

    my $trace_actions =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_ACTIONS] // 0;

    my @closure_by_rule_id   = ();
    my @semantics_by_rule_id = ();
    my @blessing_by_rule_id  = ();

    # Set the arrays, and perform various checks on the resolutions
    # we received
    {
        # ::whatever is deprecated and has been removed from the docs
        # it is now equivalent to ::undef

        RULE:
        for my $rule_id ( $grammar->rule_ids() ) {
            my ( $new_resolution, $closure, $semantics, $blessing ) =
                @{ $rule_resolutions->[$rule_id] };
            my $lhs_id = $grammar_c->rule_lhs($rule_id);

            REFINE_SEMANTICS: {

                if ('[' eq substr $semantics,
                    0, 1 and ']' eq substr $semantics,
                    -1, 1
                    )
                {
                    # Normalize array semantics
                    $semantics =~ s/ //gxms;
                    last REFINE_SEMANTICS;
                } ## end if ( '[' eq substr $semantics, 0, 1 and ']' eq ...)

                state $allowed_semantics = {
                    map { ; ( $_, 1 ) } qw(::array ::undef ::first ::whatever ::!default),
                    q{}
                };
                last REFINE_SEMANTICS if $allowed_semantics->{$semantics};
                last REFINE_SEMANTICS if $semantics =~ m/ \A rhs \d+ \z /xms;

                Marpa::R2::exception(
                    q{Unknown semantics for rule },
                    $grammar->brief_rule($rule_id),
                    "\n",
                    qq{    Semantics were specified as "$semantics"\n}
                );

            } ## end REFINE_SEMANTICS:

            $semantics_by_rule_id[$rule_id] = $semantics;
            $blessing = '::undef' if not $blessing;
            $blessing_by_rule_id[$rule_id] = $blessing;

            $closure_by_rule_id[$rule_id] = $closure;

            if (    $blessing ne '::undef'
                and not $closure
                and $semantics ne '::array'
                and ( substr $semantics, 0, 1 ) ne '[' )
            {
                Marpa::R2::exception(
                    qq{Cannot bless rule when the semantics are "$semantics"},
                    q{  Rule is: },
                    $grammar->brief_rule($rule_id),
                    "\n",
                    qq{  Blessing is "$blessing"\n},
                    qq{  Semantics are "$semantics"\n}
                );
            } ## end if ( $blessing ne q{} and not $closure and $semantics...)

        } ## end RULE: for my $rule_id ( $grammar->rule_ids() )

    } ## end CHECK_FOR_WHATEVER_CONFLICT

    # A LHS can be nullable via more than one rule,
    # and that means more than one semantics might be specified for
    # the nullable symbol.  This logic deals with that.
    my @nullable_rule_ids_by_lhs = ();
    RULE: for my $rule_id ( $grammar->rule_ids() ) {
        my $lhs_id = $grammar_c->rule_lhs($rule_id);
        push @{ $nullable_rule_ids_by_lhs[$lhs_id] }, $rule_id
            if $grammar_c->rule_is_nullable($rule_id);
    }

    my @null_symbol_closures;
    LHS:
    for ( my $lhs_id = 0; $lhs_id <= $#nullable_rule_ids_by_lhs; $lhs_id++ ) {
        my $rule_ids = $nullable_rule_ids_by_lhs[$lhs_id];
        my $resolution_rule;

        # No nullable rules for this LHS?  No problem.
        next LHS if not defined $rule_ids;
        my $rule_count = scalar @{$rule_ids};

        # I am not sure if this test is necessary
        next LHS if $rule_count <= 0;

        # Just one nullable rule?  Then that's our semantics.
        if ( $rule_count == 1 ) {
            $resolution_rule = $rule_ids->[0];
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
            grep { $grammar_c->rule_length($_) <= 0 } @{$rule_ids};
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
        my ( $first_resolution, @other_resolutions ) =
            map { $rule_resolutions->[$_] } @{$rule_ids};

        # Do they have more than one semantics?
        # If so, just call it an error and let the user sort it out.
        my ( $first_closure_name, undef, $first_semantics, $first_blessing ) =
            @{$first_resolution};
        OTHER_RESOLUTION: for my $other_resolution (@other_resolutions) {
            my ( $other_closure_name, undef, $other_semantics,
                $other_blessing )
                = @{$other_resolution};
            next OTHER_RESOLUTION
                if $first_closure_name eq $other_closure_name;
            next OTHER_RESOLUTION if $first_semantics eq $other_semantics;
            next OTHER_RESOLUTION if $first_blessing  eq $other_blessing;
            Marpa::R2::exception(
                'When nulled, symbol ',
                $grammar->symbol_name($lhs_id),
                qq{  can have more than one semantics\n},
                qq{  Marpa needs there to be only one semantics\n},
                qq{  The rules involved are:\n},
                Marpa::R2::Internal::Recognizer::brief_rule_list(
                    $recce, $rule_ids
                )
            );
        } ## end OTHER_RESOLUTION: for my $other_resolution (@other_resolutions)

        # Multiple rules, but they all have one semantics.
        # So (obviously) use that semantics
        $resolution_rule = $rule_ids->[0];
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

    } ## end LHS: for ( my $lhs_id = 0; $lhs_id <= $#nullable_rule_ids_by_lhs...)

    # Put the resolutions together
    my %resolution_data = ();
    $resolution_data{closure}   = \@closure_by_rule_id;
    $resolution_data{semantics} = \@semantics_by_rule_id;
    $resolution_data{blessing}  = \@blessing_by_rule_id;

    # Do consistency checks

    # Set the object values
    $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES] =
        \@null_symbol_closures;

    my @semantics_by_lexeme = ();
    my @blessing_by_lexeme = ();
    # Check the lexeme semantics
    {
        # ::whatever is deprecated and has been removed from the docs
        # it is now equivalent to ::undef
        LEXEME: for my $lexeme_id ( 0 .. $#{$symbols} ) {

            my ( $semantics, $blessing ) =
                @{ $lexeme_resolutions->[$lexeme_id] };
            CHECK_SEMANTICS: {
                if ( not $semantics ) {
                    $semantics = '::!default';
                    last CHECK_SEMANTICS;
                }
                if ( ( substr $semantics, 0, 1 ) eq '[' ) {
                    $semantics =~ s/ //gxms;
                    last CHECK_SEMANTICS;
                }
                state $allowed_semantics =
                    { map { ; ( $_, 1 ) }
                        qw(::array ::undef ::!default ) };

                if ( not $allowed_semantics->{$semantics} ) {
                    Marpa::R2::exception(
                        q{Unknown semantics for lexeme },
                        $grammar->symbol_name($lexeme_id),
                        "\n",
                        qq{    Semantics were specified as "$semantics"\n}
                    );
                } ## end if ( not $allowed_semantics->{$semantics} )

            } ## end CHECK_SEMANTICS:
            CHECK_BLESSING: {
                if ( not $blessing ) {
                    $blessing = '::undef';
                    last CHECK_BLESSING;
                }
                last CHECK_BLESSING if $blessing eq '::undef';
                last CHECK_BLESSING
                    if $blessing =~ /\A [A-Za-z] [:\w]* \z /xms;
                Marpa::R2::exception(
                    q{Unknown blessing for lexeme },
                    $grammar->symbol_name($lexeme_id),
                    "\n",
                    qq{    Blessing as specified as "$blessing"\n}
                );
            } ## end CHECK_BLESSING:
            $semantics_by_lexeme[$lexeme_id] = $semantics;
            $blessing_by_lexeme[$lexeme_id]  = $blessing;

        } ## end LEXEME: for my $lexeme_id ( 0 .. $#{$symbols} )

    }

    # set the symbol resolutions
    $resolution_data{semantics_by_lexeme} = \@semantics_by_lexeme;
    $resolution_data{blessing_by_lexeme} = \@blessing_by_lexeme;

    return ( $recce->[Marpa::R2::Internal::Recognizer::RULE_RESOLUTIONS] =
            \%resolution_data );

}    # semantics_set

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

    Marpa::R2::exception(@msg);

    # this is to keep perlcritic happy
    return 1;

} ## end sub code_problems

sub Marpa::R2::Internal::Recognizer::evaluate {
    my ($recce) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $order   = $recce->[Marpa::R2::Internal::Recognizer::O_C];
    my $tree    = $recce->[Marpa::R2::Internal::Recognizer::T_C];
    my $grammar = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $trace_file_handle = $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE];
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
            Marpa::R2::Internal::Recognizer::resolve_action( $recce,
            $constructor_name );
        Marpa::R2::exception(
            qq{Could not find constructor "$constructor_name"},
            q{  }, ( $resolution // 'Failed to resolve action' ) )
            if not ref $resolution;
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

    my $rule_resolutions =
        $recce->[Marpa::R2::Internal::Recognizer::RULE_RESOLUTIONS]
        // Marpa::R2::Internal::Recognizer::semantics_set( $recce,
        Marpa::R2::Internal::Recognizer::default_semantics($recce) );

    my $null_values = $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES];
    my $semantics_by_rule_id  = $rule_resolutions->{semantics};
    my $blessing_by_rule_id   = $rule_resolutions->{blessing};
    my $closure_by_rule_id    = $rule_resolutions->{closure};
    my $semantics_by_lexeme_id = $rule_resolutions->{semantics_by_lexeme};
    my $blessing_by_lexeme_id = $rule_resolutions->{blessing_by_lexeme};

    my $value = Marpa::R2::Thin::V->new($tree);
    $value->valued_force();
    my $slr = $recce->[Marpa::R2::Internal::Recognizer::SLR];
    if ($slr) {
        $value->slr_set($slr->thin());
    }
    else {
        TOKEN_IX: for (my $token_ix = 2; $token_ix <= $#{$token_values}; $token_ix++) {
            my $token_value = $token_values->[$token_ix];
            $value->token_value_set($token_ix, $token_value) if defined $token_value;
        }
    }
    local $Marpa::R2::Internal::Context::VALUATOR = $value;
    value_trace( $value, $trace_values ? 1 : 0 );
    $value->trace_values($trace_values);
    $value->stack_mode_set();

    state $op_bless         = Marpa::R2::Thin::op('bless');
    state $op_callback      = Marpa::R2::Thin::op('callback');
    state $op_push_length   = Marpa::R2::Thin::op('push_length');
    state $op_push_one      = Marpa::R2::Thin::op('push_one');
    state $op_push_sequence = Marpa::R2::Thin::op('push_sequence');
    state $op_push_start_location =
        Marpa::R2::Thin::op('push_start_location');
    state $op_push_values        = Marpa::R2::Thin::op('push_values');
    state $op_result_is_array    = Marpa::R2::Thin::op('result_is_array');
    state $op_result_is_constant = Marpa::R2::Thin::op('result_is_constant');
    state $op_result_is_n_of_sequence =
        Marpa::R2::Thin::op('result_is_n_of_sequence');
    state $op_result_is_rhs_n = Marpa::R2::Thin::op('result_is_rhs_n');
    state $op_result_is_token_value =
        Marpa::R2::Thin::op('result_is_token_value');
    state $op_result_is_undef = Marpa::R2::Thin::op('result_is_undef');

    my @nulling_symbol_by_semantic_rule;
    NULLING_SYMBOL: for my $nulling_symbol ( 0 .. $#{$null_values} ) {
        my $semantic_rule = $null_values->[$nulling_symbol];
        next NULLING_SYMBOL if not defined $semantic_rule;
        $nulling_symbol_by_semantic_rule[$semantic_rule] = $nulling_symbol;
    }

    my @work_list = ();
    RULE: for my $rule_id ( $grammar->rule_ids() ) {

        my $semantics = $semantics_by_rule_id->[$rule_id];
        my $blessing  = $blessing_by_rule_id->[$rule_id];

        $semantics = '::undef'  if $semantics eq '::!default';
        $semantics = '[values]' if $semantics eq '::array';
        $semantics = '::undef'  if $semantics eq '::whatever';
        $semantics = '::rhs0'   if $semantics eq '::first';

        push @work_list, [ $rule_id, undef, $semantics, $blessing ];
    } ## end RULE: for my $rule_id ( $grammar->rule_ids() )

    RULE: for my $lexeme_id ( 0 .. $#{$symbols} ) {

        my $semantics = $semantics_by_lexeme_id->[$lexeme_id];
        my $blessing  = $blessing_by_lexeme_id->[$lexeme_id];

        $semantics = '::value' if $semantics eq '::!default';
        $semantics = '[value]' if $semantics eq '::array';

        push @work_list, [ undef, $lexeme_id, $semantics, $blessing ];
    } ## end RULE: for my $lexeme_id ( 0 .. $#{$symbols} )

    # Registering operations is postponed to this point, because
    # the valuator must exist for this to happen.  In the future,
    # it may be best to have a separate semantics object.
    my @nulling_closures;
    WORK_ITEM: for my $work_item (@work_list) {
        my ( $rule_id, $lexeme_id, $semantics, $blessing ) = @{$work_item};

        my ( $closure, $rule, $rule_length, $is_sequence_rule,
            $is_discard_sequence_rule, $nulling_symbol_id );
        if ( defined $rule_id ) {
            $nulling_symbol_id = $nulling_symbol_by_semantic_rule[$rule_id];
            $closure           = $closure_by_rule_id->[$rule_id];
            $rule              = $rules->[$rule_id];
            $rule_length       = $grammar_c->rule_length($rule_id);
            $is_sequence_rule  = defined $grammar_c->sequence_min($rule_id);
            $is_discard_sequence_rule = $is_sequence_rule
                && $rule->[Marpa::R2::Internal::Rule::DISCARD_SEPARATION];
        } ## end if ( defined $rule_id )

        # Determine the "fate" of the array of child values
        my $array_fate;
        ARRAY_FATE: {
            if ( defined $closure and  ref $closure eq 'CODE' )
            {
                $array_fate = $op_callback;
                last ARRAY_FATE;

            } ## end if ( defined $closure && ( ref $closure ne 'SCALAR' ...))

            if ( ( substr $semantics, 0, 1 ) eq '[' ) {
                $array_fate = $op_result_is_array;
                last ARRAY_FATE;
            }
        } ## end ARRAY_FATE:

        my @ops = ();

        SET_OPS: {

            if ( $semantics eq '::undef' ) {
                @ops = ($op_result_is_undef);
                last SET_OPS;
            }

            DO_CONSTANT: {
                last DO_CONSTANT if not defined $rule_id;
                my $thingy_ref = $closure_by_rule_id->[$rule_id];
                last DO_CONSTANT if not defined $thingy_ref;
                my $ref_type = Scalar::Util::reftype $thingy_ref;
                if ( $ref_type eq q{} ) {
                    Marpa::R2::exception(
                        qq{An action resolved to a scalar.\n},
                        qq{  This is not allowed.\n},
                        qq{  A constant action must be a reference.\n},
                        q{  Rule was },
                        $grammar->brief_rule($rule_id),
                        "\n"
                    );
                } ## end if ( $ref_type eq q{} )
                if ( $ref_type eq 'CODE' ) {

                    # Set the nulling closure is this is the nulling symbol of a rule
                    $nulling_closures[$nulling_symbol_id] = $thingy_ref
                        if defined $nulling_symbol_id and defined $rule_id;
                    last DO_CONSTANT;
                } ## end if ( $ref_type eq 'CODE' )
                if ( $ref_type eq 'SCALAR' ) {
                    my $thingy = ${$thingy_ref};
                    if ( not defined $thingy ) {
                        @ops = ($op_result_is_undef);
                        last SET_OPS;
                    }
                    my $constant_ix = $value->constant_register($thingy);
                    @ops = ( $op_result_is_constant, $constant_ix );
                    last SET_OPS;
                } ## end if ( $ref_type eq 'SCALAR' )
                if (   $ref_type eq 'HASH'
                    or $ref_type eq 'ARRAY' )
                {
                    # For hash and array, do not de-reference
                    my $constant_ix = $value->constant_register($thingy_ref);
                    @ops = ( $op_result_is_constant, $constant_ix );
                    last SET_OPS;
                } ## end if ( $ref_type eq 'HASH' or $ref_type eq 'ARRAY' )

                # When I implement ref to 'REF', I probably should not
                # de-reference, because of confusion if it becomes a
                # REF to CODE.

                Marpa::R2::exception(
                    qq{Constant action is not of an allowed type.\n},
                    qq{  It was of type reference to $ref_type.\n},
                    q{  Rule was },
                    $grammar->brief_rule($rule_id),
                    "\n"
                );
            } ## end DO_CONSTANT:

            # After this point, any closure will be a ref to 'CODE'

            if ( defined $lexeme_id and $semantics eq '::value' ) {
                @ops = ( $op_result_is_token_value );
                last SET_OPS;
            } ## end if ( defined $lexeme_id and $semantics eq '::value' )

            PROCESS_SINGLETON_RESULT: {
                last PROCESS_SINGLETON_RESULT if not defined $rule_id;

                my $singleton;
                if ( $semantics =~ m/\A [:][:] rhs (\d+)  \z/xms ) {
                    $singleton = $1 + 0;
                }

                last PROCESS_SINGLETON_RESULT if not defined $singleton;

                my $singleton_element = $singleton;
                if ($is_discard_sequence_rule) {
                    @ops =
                        ( $op_result_is_n_of_sequence, $singleton_element );
                    last SET_OPS;
                }
                if ($is_sequence_rule) {
                    @ops = ( $op_result_is_rhs_n, $singleton_element );
                    last SET_OPS;
                }
                my $mask = $rule->[Marpa::R2::Internal::Rule::MASK];
                my @elements =
                    grep { $mask->[$_] } 0 .. ( $rule_length - 1 );
                if ( not scalar @elements ) {
                    my $original_semantics =
                        $semantics_by_rule_id->[$rule_id];
                    Marpa::R2::exception(
                        q{Impossible semantics for empty rule: },
                        $grammar->brief_rule($rule_id),
                        "\n",
                        qq{    Semantics were specified as "$original_semantics"\n}
                    );
                } ## end if ( not scalar @elements )
                $singleton_element = $elements[$singleton];

                if ( not defined $singleton_element ) {
                    my $original_semantics =
                        $semantics_by_rule_id->[$rule_id];
                    Marpa::R2::exception(
                        q{Impossible semantics for rule: },
                        $grammar->brief_rule($rule_id),
                        "\n",
                        qq{    Semantics were specified as "$original_semantics"\n}
                    );
                } ## end if ( not defined $singleton_element )
                @ops = ( $op_result_is_rhs_n, $singleton_element );
                last SET_OPS;
            } ## end PROCESS_SINGLETON_RESULT:

            if ( not defined $array_fate ) {
                @ops = ($op_result_is_undef);
                last SET_OPS;
            }

            # if here, $array_fate is defined

            my @bless_ops = ();
            if ( $blessing ne '::undef' ) {
                my $constant_ix = $value->constant_register($blessing);
                push @bless_ops, $op_bless, $constant_ix;
            }

            Marpa::R2::exception(qq{Unknown semantics: "$semantics"})
                if ( substr $semantics, 0, 1 ) ne '[';

            my @push_ops = ();
            my $array_descriptor = substr $semantics, 1, -1;
            RESULT_DESCRIPTOR:
            for my $result_descriptor ( split /[,]/xms, $array_descriptor ) {
                if ( $result_descriptor eq 'start' ) {
                    push @push_ops, $op_push_start_location;
                    next RESULT_DESCRIPTOR;
                }
                if ( $result_descriptor eq 'length' ) {
                    push @push_ops, $op_push_length;
                    next RESULT_DESCRIPTOR;
                }
                if (   $result_descriptor eq 'values'
                    or $result_descriptor eq 'value' )
                {
                    if ( defined $lexeme_id ) {
                        push @push_ops, $op_push_values;
                        next RESULT_DESCRIPTOR;
                    }
                    if ($is_sequence_rule) {
                        my $push_op =
                              $is_discard_sequence_rule
                            ? $op_push_sequence
                            : $op_push_values;
                        push @push_ops, $push_op;
                        next RESULT_DESCRIPTOR;
                    } ## end if ($is_sequence_rule)
                    my $mask = $rule->[Marpa::R2::Internal::Rule::MASK];
                    if ( $rule_length > 0 ) {
                        push @push_ops,
                            map { $mask->[$_] ? ( $op_push_one, $_ ) : () }
                            0 .. $rule_length - 1;
                    }
                    next RESULT_DESCRIPTOR;
                } ## end if ( $result_descriptor eq 'values' or ...)
                Marpa::R2::exception(
                    qq{Unknown result descriptor: "$result_descriptor"\n},
                    qq{  The full semantics were "$semantics"}
                );
            } ## end RESULT_DESCRIPTOR: for my $result_descriptor ( split /[,]/xms, ...)
            @ops = ( @push_ops, @bless_ops, $array_fate );

        } ## end SET_OPS:

        if ( defined $rule_id ) {
            $value->rule_register( $rule_id, @ops );
            if ( $trace_values > 2 ) {
                say {$trace_file_handle} "Registering semantics for rule: ",
                    $grammar->brief_rule($rule_id),
                    "\n", "  Semantics are ", join q{ },
                    ( map { Marpa::R2::Thin::op_name($_) . '=' . $_ } @ops )
                    or
                    Marpa::R2::exception("Cannot say to trace file handle");
            } ## end if ( $trace_values > 2 )
        } ## end if ( defined $rule_id )

        if ( defined $nulling_symbol_id ) {
            $value->nulling_symbol_register( $nulling_symbol_id, @ops );
            if ( $trace_values > 2 ) {
                say {$trace_file_handle}
                    "Registering semantics for nulling symbol: ",
                    $grammar->symbol_name($nulling_symbol_id),
                    "\n", "  Semantics are ", join q{ },
                    ( map { Marpa::R2::Thin::op_name($_) . '=' . $_ } @ops )
                    or
                    Marpa::R2::exception("Cannot say to trace file handle");
            } ## end if ( $trace_values > 2 )
        } ## end if ( defined $nulling_symbol_id )

        if ( defined $lexeme_id ) {
            $value->token_register( $lexeme_id, @ops );
            if ( $trace_values > 2 ) {
                say {$trace_file_handle}
                    "Registering semantics for lexeme: ",
                    $grammar->symbol_name($lexeme_id),
                    "\n", "  Semantics are ", join q{ },
                    ( map { Marpa::R2::Thin::op_name($_) . '=' . $_ } @ops )
                    or
                    Marpa::R2::exception("Cannot say to trace file handle");
            } ## end if ( $trace_values > 2 )
        } ## end if ( defined $lexeme_id )

    } ## end WORK_ITEM: for my $work_item (@work_list)

    STEP: while (1) {
        my ( $value_type, @value_data ) = $value->stack_step();

        if ($trace_values) {
            EVENT: while (1) {
                my $event = $value->event();
                last EVENT if not defined $event;
                my ( $event_type, @event_data ) = @{$event};
                if ( $event_type eq 'MARPA_STEP_TOKEN' ) {
                    my ( $token_id, $token_value_ix ) = @event_data;
                    my $token_value = $token_values->[$token_value_ix];
                    trace_token_evaluation( $recce, $value, $token_id,
                        $token_value );
                    next EVENT;
                } ## end if ( $event_type eq 'MARPA_STEP_TOKEN' )
                say {$Marpa::R2::Internal::TRACE_FH} join q{ },
                    'value event:',
                    map { $_ // 'undef' } $event_type, @event_data
                    or Marpa::R2::exception('say to trace handle failed');
            } ## end EVENT: while (1)

            if ( $trace_values >= 9 ) {
                for my $i ( reverse 0 .. $value->highest_index ) {
                    printf {$Marpa::R2::Internal::TRACE_FH}
                        "Stack position %3d:\n", $i,
                        or
                        Marpa::R2::exception('print to trace handle failed');
                    print {$Marpa::R2::Internal::TRACE_FH} q{ },
                        Data::Dumper->new( [ \$value->absolute($i) ] )
                        ->Terse(1)->Dump
                        or
                        Marpa::R2::exception('print to trace handle failed');
                } ## end for my $i ( reverse 0 .. $value->highest_index )
            } ## end if ( $trace_values >= 9 )

        } ## end if ($trace_values)

        last STEP if not defined $value_type;
        next STEP if $value_type eq 'trace';

        if ( $value_type eq 'MARPA_STEP_NULLING_SYMBOL' ) {
            my ($token_id) = @value_data;
            my $value_ref = $nulling_closures[$token_id];
            my $result;

            my @warnings;
            my $eval_ok;

            DO_EVAL: {
                local $SIG{__WARN__} = sub {
                    push @warnings, [ $_[0], ( caller 0 ) ];
                };

                $eval_ok = eval {
                    local $Marpa::R2::Context::rule =
                        $null_values->[$token_id];
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

            $value->result_set($result);
            trace_token_evaluation( $recce, $value, $token_id, \$result )
                if $trace_values;
            next STEP;
        } ## end if ( $value_type eq 'MARPA_STEP_NULLING_SYMBOL' )

        if ( $value_type eq 'MARPA_STEP_RULE' ) {
            my ( $rule_id, $values ) = @value_data;
            my $closure = $closure_by_rule_id->[$rule_id];

            next STEP if not defined $closure;
            my $result;

            if ( ref $closure eq 'CODE' ) {
                my @warnings;
                my $eval_ok;
                DO_EVAL: {
                    local $SIG{__WARN__} = sub {
                        push @warnings, [ $_[0], ( caller 0 ) ];
                    };
                    local $Marpa::R2::Context::rule = $rule_id;

                    if ( Scalar::Util::blessed($values) ) {
                        $eval_ok = eval {
                            $result = $closure->( $action_object, $values );
                            1;
                        };
                        last DO_EVAL;
                    } ## end if ( Scalar::Util::blessed($values) )
                    $eval_ok = eval {
                        $result = $closure->( $action_object, @{$values} );
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
            } ## end if ( ref $closure eq 'CODE' )
            else {
                $result = ${$closure};
            }
            $value->result_set($result);

            if ($trace_values) {
                say {$Marpa::R2::Internal::TRACE_FH}
                    trace_stack_1( $grammar, $recce, $value, $values,
                    $rule_id )
                    or Marpa::R2::exception('Could not print to trace file');
                print {$Marpa::R2::Internal::TRACE_FH}
                    'Calculated and pushed value: ',
                    Data::Dumper->new( [$result] )->Terse(1)->Dump
                    or Marpa::R2::exception('print to trace handle failed');
            } ## end if ($trace_values)

            next STEP;

        } ## end if ( $value_type eq 'MARPA_STEP_RULE' )

        if ( $value_type eq 'MARPA_STEP_TRACE' ) {

            if ($trace_values) {
                print {$Marpa::R2::Internal::TRACE_FH}
                    trace_op( $grammar, $recce, $value, )
                    or Marpa::R2::exception('Could not print to trace file');
            }

            next STEP;

        } ## end if ( $value_type eq 'MARPA_STEP_TRACE' )

        die "Internal error: Unknown value type $value_type";

    } ## end STEP: while (1)

    return $value->absolute(0);

} ## end sub Marpa::R2::Internal::Recognizer::evaluate

# Returns false if no parse
sub Marpa::R2::Recognizer::value
{    ## no critic (Subroutines::RequireArgUnpacking)
    my ($recce) = @_;

    Marpa::R2::exception('Too many arguments to Marpa::R2::Recognizer::value')
        if scalar @_ != 1;

    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $order     = $recce->[Marpa::R2::Internal::Recognizer::O_C];

    my $parse_set_arg = $recce->[Marpa::R2::Internal::Recognizer::END_OF_PARSE];

    local $Marpa::R2::Internal::TRACE_FH =
        $recce->[Marpa::R2::Internal::Recognizer::TRACE_FILE_HANDLE];

    my $furthest_earleme       = $recce_c->furthest_earleme();
    my $last_completed_earleme = $recce_c->current_earleme();
    Marpa::R2::exception(
        "Attempt to evaluate incompletely recognized parse:\n",
        "  Last token ends at location $furthest_earleme\n",
        "  Recognition done only as far as location $last_completed_earleme\n"
    ) if $furthest_earleme > $last_completed_earleme;

    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $tree;

    if ($bocage) {

        $tree = $recce->[Marpa::R2::Internal::Recognizer::T_C];

        # If we have a bocage, we are initialized
        if ( not $tree ) {

            # No tree means we are in ASF mode
            Marpa::R2::exception("value() called for recognizer in ASF mode");
        }
        my $max_parses =
            $recce->[Marpa::R2::Internal::Recognizer::MAX_PARSES];
        my $parse_count = $tree->parse_count();
        if ( $max_parses and $parse_count > $max_parses ) {
            Marpa::R2::exception(
                "Maximum parse count ($max_parses) exceeded");
        }

    } ## end if ($bocage)
    else {
    # No bocage, therefore not initialized

        $grammar_c->throw_set(0);
        $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C] =
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
    return \Marpa::R2::Internal::Recognizer::evaluate($recce);

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

# Not sorted and therefore not suitable for test suite
sub Marpa::R2::Recognizer::verbose_or_nodes {
    my ($recce) = @_;
    my $text = q{};
    OR_NODE:
    for (
        my $or_node_id = 0;
        defined( my $or_node_desc = $recce->verbose_or_node($or_node_id) );
        $or_node_id++
        )
    {
        $text .= $or_node_desc;
    } ## end OR_NODE: for ( my $or_node_id = 0; defined( my $or_node_desc =...))
    return $text;
} ## end sub Marpa::R2::Recognizer::verbose_or_nodes

sub Marpa::R2::Recognizer::verbose_or_node {
    my ( $recce, $or_node_id ) = @_;
    my $recce_c = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $bocage  = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    my $origin  = $bocage->_marpa_b_or_node_origin($or_node_id);
    return if not defined $origin;
    my $grammar         = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $tracer          = $grammar->[Marpa::R2::Internal::Grammar::TRACER];
    my $set             = $bocage->_marpa_b_or_node_set($or_node_id);
    my $irl_id          = $bocage->_marpa_b_or_node_irl($or_node_id);
    my $position        = $bocage->_marpa_b_or_node_position($or_node_id);
    my $origin_earleme  = $recce_c->earleme($origin);
    my $current_earleme = $recce_c->earleme($set);
    my $text
        .= "OR-node #$or_node_id: R$irl_id" . q{:}
        . $position . q{@}
        . $origin_earleme . q{-}
        . $current_earleme . "\n";
    $text .= ( q{ } x 4 )
        . $tracer->show_dotted_irl( $irl_id, $position ) . "\n";
    return $text;
} ## end sub Marpa::R2::Recognizer::verbose_or_node

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
    my ( $recce, $value, $token_id, $token_value ) = @_;
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
        Data::Dumper->new( [ \$token_value ] )->Terse(1)->Dump
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

# vim: expandtab shiftwidth=4:
