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

package Marpa::R2::HTML::Config::Dump;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use English qw( -no_match_vars );

use Marpa::R2::HTML::Config::Default;

sub as_string {
    my ($self) = @_;

    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Sortkeys = 1;
    my @contents = $self->{config}->contents();

    # Start with the legal language
    return \(
              ( join q{}, <DATA> ) . "\n"
            . "# This file was generated automatically by $PROGRAM_NAME\n"
            . "# The date of generation was "
            . ( scalar localtime() ) . "\n" . "\n"
            . "package Marpa::R2::HTML::Internal::Config::Default;\n" . "\n"
            . Data::Dumper->Dump( \@contents,
            [qw(CORE_RULES TAG_DESCRIPTOR RUBY_SLIPPERS_RANK_BY_NAME)]
            )
    );

} ## end sub write

1;

__DATA__
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
