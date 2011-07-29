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

use vars qw($VERSION $STRING_VERSION @ISA $DEBUG);
$VERSION = '0.008000';
$STRING_VERSION = $VERSION;
$VERSION = eval $VERSION;
$DEBUG = 0;

use Carp;
use English qw( -no_match_vars );

use Marpa::XS::Version;

# Die if more than one of the Marpa modules is loaded
if ( defined $Marpa::MODULE ) {
    Carp::croak("You can only load one of the Marpa modules at a time\n",
        "The module ", $Marpa::MODULE, " is already loaded\n");
}
$Marpa::MODULE = "Marpa::XS";
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

$Marpa::USING_XS = 1;
$Marpa::USING_PP = 0;

eval {
    require XSLoader;
    XSLoader::load('Marpa::XS', $Marpa::XS::STRING_VERSION);
    1;
} or eval {
    my @libs = split q{ }, ExtUtils::PkgConfig->libs("glib-2.0");
    @DynaLoader::dl_resolve_using = DynaLoader::dl_findfile(@libs);
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap Marpa::XS $Marpa::XS::STRING_VERSION;
    1;
} or Carp::croak("Could not load XS version of Marpa: $EVAL_ERROR");

my $version_found = join q{.}, Marpa::XS::version();
my $version_wanted = '0.1.0';
Carp::croak('Marpa::XS ', "fails version check, wanted $version_wanted, found $version_found")
    if $version_wanted ne $version_found;

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
    Glib::Log->set_handler('Marpa', 'debug', (sub {;}), undef);
    $Marpa::XS::DEBUG = 0;
} else {
    $Marpa::XS::DEBUG = 1;
}
require Marpa::XS::PP::Internal;
require Marpa::XS::PP::Slot;
require Marpa::XS::Grammar;
require Marpa::XS::Recognizer;
require Marpa::XS::Value;
require Marpa::XS::Callback;

*Marpa::Grammar::check_terminal = \&Marpa::XS::Grammar::check_terminal;
*Marpa::Grammar::new = \&Marpa::XS::Grammar::new;
*Marpa::Grammar::precompute = \&Marpa::XS::Grammar::precompute;
*Marpa::Grammar::set = \&Marpa::XS::Grammar::set;
*Marpa::Grammar::show_AHFA = \&Marpa::XS::Grammar::show_AHFA;
*Marpa::Grammar::show_AHFA_items = \&Marpa::XS::Grammar::show_AHFA_items;
*Marpa::Grammar::show_NFA = \&Marpa::XS::Grammar::show_NFA;
*Marpa::Grammar::show_accessible_symbols = \&Marpa::XS::Grammar::show_accessible_symbols;
*Marpa::Grammar::show_dotted_rule = \&Marpa::XS::Grammar::show_dotted_rule;
*Marpa::Grammar::show_nullable_symbols = \&Marpa::XS::Grammar::show_nullable_symbols;
*Marpa::Grammar::show_nulling_symbols = \&Marpa::XS::Grammar::show_nulling_symbols;
*Marpa::Grammar::show_productive_symbols = \&Marpa::XS::Grammar::show_productive_symbols;
*Marpa::Grammar::show_problems = \&Marpa::XS::Grammar::show_problems;
*Marpa::Grammar::brief_rule = \&Marpa::XS::Grammar::brief_rule;
*Marpa::Grammar::show_rule = \&Marpa::XS::Grammar::show_rule;
*Marpa::Grammar::show_rules = \&Marpa::XS::Grammar::show_rules;
*Marpa::Grammar::show_symbol = \&Marpa::XS::Grammar::show_symbol;
*Marpa::Grammar::show_symbols = \&Marpa::XS::Grammar::show_symbols;
*Marpa::Recognizer::old_show_or_node = \&Marpa::XS::Recognizer::old_show_or_node;
*Marpa::Recognizer::old_show_and_node = \&Marpa::XS::Recognizer::old_show_and_node;
*Marpa::Recognizer::alternative = \&Marpa::XS::Recognizer::alternative;
*Marpa::Recognizer::check_terminal = \&Marpa::XS::Recognizer::check_terminal;
*Marpa::Recognizer::current_earleme = \&Marpa::XS::Recognizer::current_earleme;
*Marpa::Recognizer::earleme_complete = \&Marpa::XS::Recognizer::earleme_complete;
*Marpa::Recognizer::earley_set_size = \&Marpa::XS::Recognizer::earley_set_size;
*Marpa::Recognizer::end_input = \&Marpa::XS::Recognizer::end_input;
*Marpa::Recognizer::exhausted = \&Marpa::XS::Recognizer::exhausted;
*Marpa::Recognizer::latest_earley_set = \&Marpa::XS::Recognizer::latest_earley_set;
*Marpa::Recognizer::new = \&Marpa::XS::Recognizer::new;
*Marpa::Recognizer::read = \&Marpa::XS::Recognizer::read;
*Marpa::Recognizer::reset_evaluation = \&Marpa::XS::Recognizer::reset_evaluation;
*Marpa::Recognizer::set = \&Marpa::XS::Recognizer::set;
*Marpa::Recognizer::show_earley_sets = \&Marpa::XS::Recognizer::show_earley_sets;
*Marpa::Recognizer::show_and_nodes = \&Marpa::XS::Recognizer::show_and_nodes;
*Marpa::Recognizer::show_bocage = \&Marpa::XS::Recognizer::show_bocage;
*Marpa::Recognizer::show_iteration_stack = \&Marpa::XS::Recognizer::show_iteration_stack;
*Marpa::Recognizer::show_iteration_node = \&Marpa::XS::Recognizer::show_iteration_node;
*Marpa::Recognizer::old_show_and_nodes = \&Marpa::XS::Recognizer::old_show_and_nodes;
*Marpa::Recognizer::show_or_nodes = \&Marpa::XS::Recognizer::show_or_nodes;
*Marpa::Recognizer::old_show_or_nodes = \&Marpa::XS::Recognizer::old_show_or_nodes;
*Marpa::Recognizer::show_progress = \&Marpa::XS::Recognizer::show_progress;
*Marpa::Recognizer::status = \&Marpa::XS::Recognizer::status;
*Marpa::Recognizer::terminals_expected = \&Marpa::XS::Recognizer::terminals_expected;
*Marpa::Recognizer::tokens = \&Marpa::XS::Recognizer::tokens;
*Marpa::Recognizer::value = \&Marpa::XS::Recognizer::value;
*Marpa::location = \&Marpa::XS::location;
*Marpa::token_location = \&Marpa::XS::token_location;

return 1;

__END__
