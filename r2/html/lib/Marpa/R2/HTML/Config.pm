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

package Marpa::R2::HTML;

use 5.010;
use strict;
use warnings;

use Marpa::R2::HTML::Config::Definition;

# versions below must be coordinated with
# those required in Build.PL

sub new_from_default {
    my ($class) = @_ my $self = {
        rules => $Marpa::R2::HTML::Internal::Compiled::CORE_RULES,
        descriptor_by_tag =>
            $Marpa::R2::HTML::Internal::Compiled::TAG_DESCRIPTOR,
        ruby_slippers_rank_by_name =>
            $Marpa::R2::HTML::Internal::Compiled::RUBY_SLIPPERS_RANK_BY_NAME,
    };
    bless $self, $class;
} ## end sub new_from_default

sub contents {
    my ($self) = @_;
    return @{$self}{qw(rules descriptor_by_tag, ruby_slippers_rank_by_name)};
}

1;
