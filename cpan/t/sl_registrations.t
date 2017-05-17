#!perl
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

# Based on Github PR #256 -- the applications can cache registrations
# using $recce->registrations()/$recce->registrations($registrations)
# getter/setter if it creates recognizers with the same semantic settings
# thus getting faster value() calls.

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Test::More tests => 15;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my $max_actions = 5;
my $max_recces = 10;

my $grammar_source = <<EOG;
:start ::= tests
tests ::= test+ action => [values]
ws ~ [\\s]
:discard ~ ws;
test ::= 'dummy' action => main::do_dummy
EOG

# add grammar rules, actions and inputs
sub do_dummy { $_[1] }

my $input = "dummy";
for my $n_action (1..$max_actions) {
    $grammar_source .= qq{test ::= '$n_action' action => main::action$n_action\n};
    eval "sub action$n_action { qq{$n_action} }";
    $input .= qq{ $n_action};
}

# test added actions
for my $n_action (1..$max_actions) {
    is eval "action$n_action()", $n_action, "action $n_action";
}

# test recces
my @expected_value = split /\s/, $input;

# create recognizers caching their registrations because they're the same
state $registrations;
my $g = Marpa::R2::Scanless::G->new({source => \$grammar_source});
for my $n_recce (1..$max_recces) {

    my $r = Marpa::R2::Scanless::R->new({grammar => $g});

    # set, if any
    if (defined($registrations)) {
        $r->registrations($registrations);
    }

    # parse
    $r->read(\$input);
    is_deeply ${ $r->value() }, \@expected_value, qq{recce $n_recce value};

    # get, if any
    if (! defined($registrations)) {
        $registrations = $r->registrations();
    }

}
