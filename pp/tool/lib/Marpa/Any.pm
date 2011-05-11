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

use Marpa::PP;

package Marpa::Any;

$Marpa::Any::USING_PP = 1;
$Marpa::Any::USING_XS = 0;

*Marpa::Any::Grammar::check_terminal = \&Marpa::PP::Grammar::check_terminal;
*Marpa::Any::Grammar::new = \&Marpa::PP::Grammar::new;
*Marpa::Any::Grammar::precompute = \&Marpa::PP::Grammar::precompute;
*Marpa::Any::Grammar::set = \&Marpa::PP::Grammar::set;
*Marpa::Any::Grammar::show_AHFA = \&Marpa::PP::Grammar::show_AHFA;
*Marpa::Any::Grammar::show_NFA = \&Marpa::PP::Grammar::show_NFA;
*Marpa::Any::Grammar::show_accessible_symbols = \&Marpa::PP::Grammar::show_accessible_symbols;
*Marpa::Any::Grammar::show_nullable_symbols = \&Marpa::PP::Grammar::show_nullable_symbols;
*Marpa::Any::Grammar::show_nulling_symbols = \&Marpa::PP::Grammar::show_nulling_symbols;
*Marpa::Any::Grammar::show_productive_symbols = \&Marpa::PP::Grammar::show_productive_symbols;
*Marpa::Any::Grammar::show_problems = \&Marpa::PP::Grammar::show_problems;
*Marpa::Any::Grammar::show_rules = \&Marpa::PP::Grammar::show_rules;
*Marpa::Any::Grammar::show_symbols = \&Marpa::PP::Grammar::show_symbols;
*Marpa::Any::Recognizer::alternative = \&Marpa::PP::Recognizer::alternative;
*Marpa::Any::Recognizer::check_terminal = \&Marpa::PP::Recognizer::check_terminal;
*Marpa::Any::Recognizer::current_earleme = \&Marpa::PP::Recognizer::current_earleme;
*Marpa::Any::Recognizer::earleme_complete = \&Marpa::PP::Recognizer::earleme_complete;
*Marpa::Any::Recognizer::earley_set_size = \&Marpa::PP::Recognizer::earley_set_size;
*Marpa::Any::Recognizer::end_input = \&Marpa::PP::Recognizer::end_input;
*Marpa::Any::Recognizer::exhausted = \&Marpa::PP::Recognizer::exhausted;
*Marpa::Any::Recognizer::new = \&Marpa::PP::Recognizer::new;
*Marpa::Any::Recognizer::read = \&Marpa::PP::Recognizer::read;
*Marpa::Any::Recognizer::reset_evaluation = \&Marpa::PP::Recognizer::reset_evaluation;
*Marpa::Any::Recognizer::set = \&Marpa::PP::Recognizer::set;
*Marpa::Any::Recognizer::show_earley_sets = \&Marpa::PP::Recognizer::show_earley_sets;
*Marpa::Any::Recognizer::show_progress = \&Marpa::PP::Recognizer::show_progress;
*Marpa::Any::Recognizer::status = \&Marpa::PP::Recognizer::status;
*Marpa::Any::Recognizer::terminals_expected = \&Marpa::PP::Recognizer::terminals_expected;
*Marpa::Any::Recognizer::tokens = \&Marpa::PP::Recognizer::tokens;
*Marpa::Any::Recognizer::value = \&Marpa::PP::Recognizer::value;
*Marpa::Any::location = \&Marpa::PP::location;
*Marpa::Any::token_location = \&Marpa::PP::token_location;

1;
