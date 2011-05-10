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
use vars qw($VERSION $STRING_VERSION);
$VERSION = '0.005_004';
$STRING_VERSION = $VERSION;
$VERSION = eval $VERSION;

use Carp;
use English qw( -no_match_vars );

use Marpa::PP::Version;

# Sensible defaults if not defined
$Marpa::PP::USE_PP =  !defined $Marpa::XS::VERSION;
$Marpa::PP::USE_XS //= ! $Marpa::PP::USE_PP;

# Die if both PP and XS were chosen
if ( $Marpa::PP::USE_PP and $Marpa::PP::USE_XS ) {
    Carp::croak('Cannot specify both USE_XS and USE_PP');
}
# Die if both PP and XS were unset
if ( ! $Marpa::PP::USE_PP and ! $Marpa::PP::USE_XS ) {
    Carp::croak('Cannot unset both USE_XS and USE_PP');
}

require Marpa::PP::Internal;
require Marpa::PP::Internal::Carp_Not;
Marpa::PP::Internal::Carp_Not->import();

if ( $Marpa::PP::USE_XS ) {
    $Marpa::USING_XS = 1;
    $Marpa::USING_PP = 0;
    return 1;
}

$Marpa::USING_XS = 0;
$Marpa::USING_PP = 1;

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
*Marpa::Recognizer::new = \&Marpa::PP::Recognizer::new;
*Marpa::Recognizer::read = \&Marpa::PP::Recognizer::read;
*Marpa::Recognizer::reset_evaluation = \&Marpa::PP::Recognizer::reset_evaluation;
*Marpa::Recognizer::set = \&Marpa::PP::Recognizer::set;
*Marpa::Recognizer::show_earley_sets = \&Marpa::PP::Recognizer::show_earley_sets;
*Marpa::Recognizer::show_progress = \&Marpa::PP::Recognizer::show_progress;
*Marpa::Recognizer::status = \&Marpa::PP::Recognizer::status;
*Marpa::Recognizer::terminals_expected = \&Marpa::PP::Recognizer::terminals_expected;
*Marpa::Recognizer::tokens = \&Marpa::PP::Recognizer::tokens;
*Marpa::Recognizer::value = \&Marpa::PP::Recognizer::value;
*Marpa::location = \&Marpa::PP::location;
*Marpa::token_location = \&Marpa::PP::token_location;

1;

__END__
