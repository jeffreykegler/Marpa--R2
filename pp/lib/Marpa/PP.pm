# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::PP.  Marpa::PP is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::PP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::PP.  If not, see
# http://www.gnu.org/licenses/.

package Marpa::PP;

use 5.010;
use strict;
use warnings;
use vars qw($VERSION $STRING_VERSION $DEBUG);
$VERSION = '0.009_002';
$STRING_VERSION = $VERSION;
$VERSION = eval $VERSION;
$DEBUG = 0;

use Carp;
use English qw( -no_match_vars );

use Marpa::PP::Version;

# Die if more than one of the Marpa modules is loaded
if ( defined $Marpa::MODULE ) {
    Carp::croak("You can only load one of the Marpa modules at a time\n",
        "The module ", $Marpa::MODULE, " is already loaded\n");
}
$Marpa::MODULE = "Marpa::PP";
$Marpa::USING_PP = 1;
$Marpa::USING_XS = 0;
if ( defined $Marpa::VERSION ) {
    Carp::croak('Cannot load both Marpa::PP and Marpa');
}
if ( defined $Marpa::XS::VERSION ) {
    Carp::croak('Cannot load both Marpa::PP and Marpa::XS');
}

@Marpa::CARP_NOT = ();
for my $start (qw(Marpa Marpa::PP Marpa::XS))
{
    for my $middle ('', '::Internal')
    {
	for my $end ('', qw(::Recognizer ::Callback ::Grammar ::Value))
	{
	    push @Marpa::CARP_NOT, $start . $middle . $end;
	}
    }
}
PACKAGE: for my $package (@Marpa::CARP_NOT) {
    no strict 'refs';
    next PACKAGE if  $package eq 'Marpa';
    *{ $package . q{::CARP_NOT} } = \@Marpa::CARP_NOT;
}

if (not $ENV{'MARPA_AUTHOR_TEST'}) {
    $Marpa::PP::DEBUG = 0;
} else {
    $Marpa::PP::DEBUG = 1;
}

require Marpa::PP::Internal;
require Marpa::PP::Grammar;
require Marpa::PP::Recognizer;
require Marpa::PP::Value;
require Marpa::PP::Callback;

*Marpa::Grammar::check_terminal = \&Marpa::PP::Grammar::check_terminal;
*Marpa::Grammar::new = \&Marpa::PP::Grammar::new;
*Marpa::Grammar::precompute = \&Marpa::PP::Grammar::precompute;
*Marpa::Grammar::set = \&Marpa::PP::Grammar::set;
*Marpa::Grammar::show_AHFA = \&Marpa::PP::Grammar::show_AHFA;
*Marpa::Grammar::show_NFA = \&Marpa::PP::Grammar::show_NFA;
*Marpa::Grammar::show_accessible_symbols = \&Marpa::PP::Grammar::show_accessible_symbols;
*Marpa::Grammar::show_nullable_symbols = \&Marpa::PP::Grammar::show_nullable_symbols;
*Marpa::Grammar::show_nulling_symbols = \&Marpa::PP::Grammar::show_nulling_symbols;
*Marpa::Grammar::show_productive_symbols = \&Marpa::PP::Grammar::show_productive_symbols;
*Marpa::Grammar::show_problems = \&Marpa::PP::Grammar::show_problems;
*Marpa::Grammar::show_rules = \&Marpa::PP::Grammar::show_rules;
*Marpa::Grammar::show_symbols = \&Marpa::PP::Grammar::show_symbols;
*Marpa::Recognizer::alternative = \&Marpa::PP::Recognizer::alternative;
*Marpa::Recognizer::check_terminal = \&Marpa::PP::Recognizer::check_terminal;
*Marpa::Recognizer::current_earleme = \&Marpa::PP::Recognizer::current_earleme;
*Marpa::Recognizer::earleme_complete = \&Marpa::PP::Recognizer::earleme_complete;
*Marpa::Recognizer::earley_set_size = \&Marpa::PP::Recognizer::earley_set_size;
*Marpa::Recognizer::end_input = \&Marpa::PP::Recognizer::end_input;
*Marpa::Recognizer::exhausted = \&Marpa::PP::Recognizer::exhausted;
*Marpa::Recognizer::latest_earley_set = \&Marpa::PP::Recognizer::latest_earley_set;
*Marpa::Recognizer::new = \&Marpa::PP::Recognizer::new;
*Marpa::Recognizer::parse_count = \&Marpa::PP::Recognizer::parse_count;
*Marpa::Recognizer::read = \&Marpa::PP::Recognizer::read;
*Marpa::Recognizer::reset_evaluation = \&Marpa::PP::Recognizer::reset_evaluation;
*Marpa::Recognizer::set = \&Marpa::PP::Recognizer::set;
*Marpa::Recognizer::show_and_nodes = \&Marpa::PP::Recognizer::show_and_nodes;
*Marpa::Recognizer::show_earley_sets = \&Marpa::PP::Recognizer::show_earley_sets;
*Marpa::Recognizer::show_or_nodes = \&Marpa::PP::Recognizer::show_or_nodes;
*Marpa::Recognizer::show_progress = \&Marpa::PP::Recognizer::show_progress;
*Marpa::Recognizer::status = \&Marpa::PP::Recognizer::status;
*Marpa::Recognizer::terminals_expected = \&Marpa::PP::Recognizer::terminals_expected;
*Marpa::Recognizer::tokens = \&Marpa::PP::Recognizer::tokens;
*Marpa::Recognizer::value = \&Marpa::PP::Recognizer::value;
*Marpa::location = \&Marpa::PP::location;
*Marpa::token_location = \&Marpa::PP::token_location;

1;

__END__
