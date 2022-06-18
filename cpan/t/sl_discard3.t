#!/usr/bin/perl
# Copyright 2022 Jeffrey Kegler
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

# Tests of the SLIF's discard events

use 5.010001;
use strict;
use warnings;
use Test::More tests => 342;
use English qw( -no_match_vars );
use Scalar::Util;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my @settings = ( '=on', '=off', q{} );
for my $grammar_setting (@settings) {

    my $null_dsl = <<'END_OF_SOURCE';
:default ::= action => [g1start,g1length,name,values]
discard default = event => :symbol=off
lexeme default = action => [ g1start, g1length, start, length, value ]
    latm => 1

Script ::=
:discard ~ whitespace event => ws=on
whitespace ~ [\s]
END_OF_SOURCE

    $null_dsl =~ s/ =on $ /$grammar_setting/xms;

    my $null_grammar = Marpa::R2::Scanless::G->new(
        {   bless_package => 'My_Nodes',
            source        => \$null_dsl,
        }
    );

    for my $recce_setting (@settings) {

        my $event_is_on = 1;
        my $recce_arg   = {};
        if ( $recce_setting eq '=on' ) {
            $recce_arg = { event_is_active => { ws => 1 } };
        }
        elsif ( $recce_setting eq '=off' ) {
            $recce_arg = { event_is_active => { ws => 0 } };
            $event_is_on = 0;
        }
        else {
            $event_is_on = 0 if $grammar_setting eq '=off';
        }

        for my $input ( q{}, ' ', '  ' ) {

            my $recce =
                Marpa::R2::Scanless::R->new( { grammar => $null_grammar },
                $recce_arg );

            my $length = length $input;
            my $pos    = $recce->read( \$input );

            my $p_events = gather_events( $recce, $pos, $length );
            my $actual_events = join q{ },
                map { $_->[0], $_->[-1] } @{$p_events};

            my $expected_events = q{};
            if ($event_is_on) {
                $expected_events = join q{ }, ( ('ws 0') x $length );
            }

            my $test_name = "Test of $length discarded spaces";
            $test_name .= ' g' . $grammar_setting if $grammar_setting;
            $test_name .= ' r' . $recce_setting   if $recce_setting;
            Test::More::is( $actual_events, $expected_events, $test_name );

            my $value_ref = $recce->value();
            die "No parse was found\n" if not defined $value_ref;

            my $result = ${$value_ref};

            # say Data::Dumper::Dumper($result);
        } ## end for my $input ( q{}, ' ', '  ' )

# Discards with a non-trivial grammar

        my $non_trivial_dsl = <<'END_OF_SOURCE';
:default ::= action => [g1start,g1length,name,values]
discard default = event => :symbol=off
lexeme default = action => [ g1start, g1length, start, length, value ]
    latm => 1

text ::= a b
a ~ 'a'
b ~ 'b'
:discard ~ whitespace event => ws=on
whitespace ~ [\s]
END_OF_SOURCE
        $non_trivial_dsl =~ s/ =on $ /$grammar_setting/xms;

        my $non_trivial_grammar = Marpa::R2::Scanless::G->new(
            {   bless_package => 'My_Nodes',
                source        => \$non_trivial_dsl
            }
        );

        for my $pattern ( 0 .. 7 ) {

            # use binary numbers to generate all possible
            # space patterns
            my @spaces = split //xms, sprintf "%03b", $pattern;
            my @chars  = qw{a b};
            my @input  = ();
            for my $i ( 0 .. 1 ) {
                push @input, ' ' if $spaces[$i];
                push @input, $chars[$i];
            }
            push @input, ' ' if $spaces[-1];

            my @expected = ();
            for my $i ( 0 .. $#spaces ) {
                push @expected, "ws $i" if $spaces[$i];
            }

            # say join q{}, '^', @input, '$';
            my $input = join q{}, @input;

            my $recce = Marpa::R2::Scanless::R->new(
                { grammar => $non_trivial_grammar }, $recce_arg );

            my $length = length $input;
            my $pos    = $recce->read( \$input );

            my $p_events = gather_events( $recce, $pos, $length );
            my $actual_events = join q{ },
                map { $_->[0], $_->[-1] } @{$p_events};
            my $expected_events = q{};
            if ($event_is_on) {
                $expected_events = join q{ }, @expected;
            }
            my $test_name = qq{Test of non-trivial parse, input="$input"};
            $test_name .= ' g' . $grammar_setting if $grammar_setting;
            $test_name .= ' r' . $recce_setting   if $recce_setting;
            Test::More::is( $actual_events, $expected_events, $test_name );

            my $value_ref = $recce->value();
            die "No parse was found\n" if not defined $value_ref;

            my $result = ${$value_ref};
        } ## end for my $pattern ( 0 .. 7 )
    } ## end for my $recce_setting ( '=on', '=off', q{} )
} ## end for my $grammar_setting ( '=on', '=off', q{} )

# Test of 2 types of events

for my $ws_g_setting (@settings) {
    for my $bracketed_g_setting (@settings) {

        my $dsl2 = <<'END_OF_SOURCE';
:default ::= action => [g1start,g1length,name,values]
discard default = event => :symbol=off
lexeme default = action => [ g1start, g1length, start, length, value ]
    latm => 1

Script ::=
:discard ~ whitespace event => ws=on
whitespace ~ [\s]
:discard ~ bracketed event => bracketed=on
bracketed ~ '(' <no close bracket> ')'
<no close bracket> ~ [^)]*
END_OF_SOURCE

        $dsl2 =~ s/ ws=on $ /ws$ws_g_setting/xms;
        $dsl2 =~ s/ bracketed=on $ /bracketed$bracketed_g_setting/xms;

        my $grammar2 = Marpa::R2::Scanless::G->new(
            { bless_package => 'My_Nodes', source => \$dsl2, } );

        for my $ws_r_setting (@settings) {
            for my $bracketed_r_setting (@settings) {

                my %event_is_on = ( bracketed => 1, ws => 1 );
                my %event_is_active_value = ();
                if ( $ws_r_setting eq '=on' ) {
                    $event_is_active_value{ws} = 1;
                }
                elsif ( $ws_r_setting eq '=off' ) {
                    $event_is_active_value{ws} = 0;
                    $event_is_on{ws}           = 0;
                }
                else {
                    $event_is_on{ws} = 0 if $ws_g_setting eq '=off';
                }
                if ( $bracketed_r_setting eq '=on' ) {
                    $event_is_active_value{bracketed} = 1;
                }
                elsif ( $bracketed_r_setting eq '=off' ) {
                    $event_is_active_value{bracketed} = 0;
                    $event_is_on{bracketed}           = 0;
                }
                else {
                    $event_is_on{bracketed} = 0
                        if $bracketed_g_setting eq '=off';
                }
                my @extra_recce_args =
                    ( { event_is_active => \%event_is_active_value } )
                    if scalar %event_is_active_value;

                for my $input ( q{ (x) }, q{(x) }, q{ (x)} ) {
                    my $recce =
                        Marpa::R2::Scanless::R->new( { grammar => $grammar2 },
                        @extra_recce_args );

                    my $length = length $input;
                    my $pos    = $recce->read( \$input );

                    my $p_events = gather_events( $recce, $pos, $length );
                    my $actual_events = join q{ },
                        map { $_->[0], $_->[-1] } @{$p_events};
                    my $expected_events = $input;
                    if ( $event_is_on{bracketed} ) {
                        $expected_events =~ s/[(] [x]+ [)]/bracketed 0/xms;
                    }
                    else {
                        # Place an 'x' marker so we don't confuse initial
                        # and terminal spaces, during the coming substitutions
                        $expected_events =~ s/[(] [x]+ [)]/x/xms;
                    }
                    if ( $event_is_on{ws} ) {
                        $expected_events =~ s/\A \s /ws 0 /xms;
                        $expected_events =~ s/\s \z/ ws 0/xms;
                    }
                    else {
                        $expected_events =~ s/\A \s //xms;
                        $expected_events =~ s/\s \z//xms;
                    }

                    # Clean up extra spaces and the 'x' markers
                    $expected_events =~ s/x/ /gxms;
                    $expected_events =~ s/\s+/ /gxms;
                    $expected_events =~ s/\s \z//gxms;
                    $expected_events =~ s/\A \s//gxms;

                    my $test_name =
                        qq{Test of two discard types, input="$input"};
                    $test_name .= ' ws:g' . $ws_g_setting if $ws_g_setting;
                    $test_name .= ' ws:r' . $ws_r_setting if $ws_r_setting;
                    $test_name .= ' bracketed:g' . $bracketed_g_setting
                        if $bracketed_g_setting;
                    $test_name .= ' bracketed:r' . $bracketed_r_setting
                        if $bracketed_r_setting;

                    Test::More::is( $actual_events, $expected_events,
                        $test_name );

                    my $value_ref = $recce->value();
                    die "No parse was found\n" if not defined $value_ref;

                    my $result = ${$value_ref};
                } ## end for my $input ( q{ (x) }, q{(x) }, q{ (x)} )
            } ## end for my $bracketed_r_setting (@settings)
        } ## end for my $ws_r_setting (@settings)
    } ## end for my $bracketed_g_setting (@settings)
} ## end for my $ws_g_setting (@settings)

sub gather_events {
    my ($recce, $pos, $length) = @_;
    my @actual_events;
    READ: while (1) {

        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ( $name, @other_stuff ) = @{$event};
            # say STDERR 'Event received!!! -- ', Data::Dumper::Dumper($event);
            push @actual_events, $event;
        }

        last READ if $pos >= $length;
        $pos = $recce->resume($pos);
    } ## end READ: while (1)
    return \@actual_events;
} ## end sub gather_event
# vim: expandtab shiftwidth=4:
