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

package Marpa::R2::ASF;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.061_002';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

# The code in this file, for now, breaks "the rules".  It makes use
# of internal methods not documented as part of Libmarpa.
# It is intended to create documented Libmarpa methods to underlie
# this interface, and rewrite it to use them

sub Marpa::R2::Scanless::R::asf {
    my ( $slr, @arg_hashes ) = @_;
    my $slg       = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr  = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $recce     = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $grammar   = $recce->[Marpa::R2::Internal::Recognizer::GRAMMAR];
    my $recce_c   = $recce->[Marpa::R2::Internal::Recognizer::C];
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my $choice_blessing = 'choice';

    for my $args (@arg_hashes) {
        if ( defined( my $value = $args->{choice} ) ) {
            $choice_blessing = $value;
        }
    }

    # We use the bocage to make sure that conflicting evaluations
    # are not being tried at once
    my $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C];
    Marpa::R2::exception(
        "Attempt to create an ASF for a recognizer that is already being valued"
    ) if $bocage;
    $grammar_c->throw_set(0);
    $bocage = $recce->[Marpa::R2::Internal::Recognizer::B_C] =
        Marpa::R2::Thin::B->new( $recce_c, -1 );
    $grammar_c->throw_set(1);

    die "No parse" if not defined $bocage;

    my $rule_resolutions =
        $recce->[Marpa::R2::Internal::Recognizer::RULE_RESOLUTIONS] =
        Marpa::R2::Internal::Recognizer::semantics_set( $recce,
        Marpa::R2::Internal::Recognizer::default_semantics($recce) );

    my $top_or_node =  $bocage->_marpa_b_top_or_node();
    return \[ "Top or node = $top_or_node",
    $recce->or_node_tag($top_or_node),
    $recce->show_bocage ];
} ## end sub Marpa::R2::Scanless::R::asf

1;

# vim: expandtab shiftwidth=4:
