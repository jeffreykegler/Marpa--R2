# Copyright 2015 Jeffrey Kegler
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

# This file is editable.  It is used during the
# configuration process to set up version information.

package Marpa::R2;

use 5.010;

use strict;
use warnings;

my %perl_autoconf_os =
    map { $_ => 1 } qw( MSWin32 openbsd solaris sunos midnightbsd );
$Marpa::R2::USE_PERL_AUTOCONF = $ENV{MARPA_USE_PERL_AUTOCONF}
    || ( $perl_autoconf_os{$^O} // 0 );

%Marpa::R2::VERSION_FOR_CONFIG = (
    'Carp'                  => '1.08',
    'Config::AutoConf'      => '0.22',
    'CPAN::Meta::Converter' => '2.120921',
    'Cwd'                   => '3.2501',
    'Data::Dumper'          => '2.125',
    'DynaLoader'            => '1.08',
    'English'               => '1.04',
    'Exporter'              => '5.62',
    'ExtUtils::CBuilder'    => '0.27',
    'ExtUtils::MakeMaker'   => '6.42',
    'ExtUtils::Manifest'    => '1.51_01',
    'ExtUtils::Mkbootstrap' => '6.42',
    'Fatal'                 => '1.05',
    'File::Copy'            => '2.11',
    'File::Spec'            => '3.2501',
    'HTML::Entities'        => '3.68',
    'HTML::Parser'          => '3.69',
    'IPC::Cmd'              => '0.40_1',
    'List::Util'            => '1.21',
    'Module::Build'         => '0.4003',
    'PPI'                   => '1.206',
    'Scalar::Util'          => '1.21',
    'Test::More'            => '0.94',
    'Time::Piece'           => '1.12',
    'XSLoader'              => '0.08',
);

1;

# vim: expandtab shiftwidth=4:
