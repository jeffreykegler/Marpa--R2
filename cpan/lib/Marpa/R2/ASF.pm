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

sub Marpa::R2::Scanless::R::asf {
    my ( $slr, @arg_hashes ) = @_;
    my $slg      = $slr->[Marpa::R2::Inner::Scanless::R::GRAMMAR];
    my $thin_slr = $slr->[Marpa::R2::Inner::Scanless::R::C];
    my $recce    = $slr->[Marpa::R2::Inner::Scanless::R::THICK_G1_RECCE];
    my $choice_blessing = 'choice';

    for my $args (@arg_hashes) {
        if ( defined( my $value = $args->{choice} ) ) {
            $choice_blessing = $value;
        }
    }

    my $rule_resolutions =
        Marpa::R2::Internal::Recognizer::semantics_set( $recce,
        Marpa::R2::Internal::Recognizer::default_semantics($recce) );

    return \[];
} ## end sub Marpa::R2::Scanless::R::asf

1;

# vim: expandtab shiftwidth=4:
