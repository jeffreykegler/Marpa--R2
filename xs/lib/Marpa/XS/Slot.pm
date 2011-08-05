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

package Marpa::XS::Internal::Slot;

use 5.010;
use strict;
use warnings;
use integer;

BEGIN {
my $structure = <<'END_OF_STRUCTURE';
    :package=Marpa::XS::Internal::Slot
    VALUES
    FREE_LIST
END_OF_STRUCTURE
    Marpa::offset($structure);
} ## end BEGIN

sub new {
    my ($class) = @_;
    my $self = [];
    $self->[VALUES] = [undef];
    $self->[FREE_LIST] = [];
    bless $self, $class;
}

sub slot {
   my ($self, $value) = @_;
   return 0 if not defined $value;
   if (my $slot = pop @{$self->[FREE_LIST]}) {
       $self->[VALUES]->[$slot] = $value;
       return $slot;
   }
   return -1 + push @{$self->[VALUES]}, $value;
}

sub value {
   my ($self, $slot) = @_;
   return $self->[VALUES]->[$slot];
}

1;
