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

package Marpa::XS;

use 5.010;
use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );

use vars qw(@ISA);
@ISA = qw( DynaLoader );
sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

use Marpa::XS::Version;

if ( defined $Marpa::PP::VERSION ) {
    Carp::croak('Attempt to load Marpa::XS when Marpa::PP ', $Marpa::PP::VERSION, ' already loaded');
}
if ( $Marpa::USING_PP ) {
    Carp::croak('Attempt to load Marpa::XS when already using Marpa::PP');
}
if ( $Marpa::USING_XS ) {
    die('Internal error: Attempt to load Marpa::XS twice');
}
if ( $Marpa::USE_PP ) {
    Carp::croak('Attempt to load Marpa::XS when USE_PP specified');
}

# Sensible defaults if not defined
$Marpa::USE_XS = 1;
$Marpa::USING_XS = 1;
$Marpa::USING_PP = 0;

require Marpa::PP;
if (!defined $Marpa::PP::VERSION ) {
    die('Internal error: VERSION not defined in Marpa::PP');
}
if ($Marpa::PP::STRING_VERSION ne $Marpa::XS::STRING_VERSION ) {
    Carp::croak("Version mismatch between Marpa::XS and Marpa::PP\n",
    "Marpa::XS is version ", $Marpa::XS::STRING_VERSION, "\n",
    "Marpa::PP is version ", $Marpa::PP::STRING_VERSION, "\n",
    "The Marpa::XS and Marpa::PP versions must match and they do not\n"
    );
}

eval {
    package DynaLoader;
    my @libs = split q{ }, ExtUtils::PkgConfig->libs("glib-2.0");
    @DynaLoader::dl_resolve_using = dl_findfile(@libs);
    bootstrap Marpa::XS $Marpa::XS::STRING_VERSION;
    1;
} or do {
    Carp::croak("Could not load XS version of Marpa: $EVAL_ERROR");
};

my $version_found = join q{.}, Marpa::XS::version();
my $version_wanted = '0.1.0';
Carp::croak('Marpa::XS ', "fails version check, wanted $version_wanted, found $version_found")
    if $version_wanted ne $version_found;

require Marpa::XS::Grammar;
require Marpa::XS::Recognizer;
require Marpa::XS::Value;
require Marpa::XS::Callback;

return 1;

__END__
