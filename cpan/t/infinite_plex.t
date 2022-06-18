#!/usr/bin/perl
# Copyright 2022 Jeffrey Kegler
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

# A grammar with cycles

use 5.010001;
use strict;
use warnings;

use English qw( -no_match_vars );
use Fatal qw(open close chdir);

use Test::More tests => 4;
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

sub make_rule {
    my ( $lhs_symbol_name, $rhs_symbol_name ) = @_;
    my $action_name = "main::action_$lhs_symbol_name$rhs_symbol_name";

    no strict 'refs';
    my $closure = *{$action_name}{'CODE'};
    use strict;

    if ( not defined $closure ) {
        my $action =
            sub { $lhs_symbol_name . $rhs_symbol_name . '(' . $_[1] . ')' };

        no strict 'refs';
        *{$action_name} = $action;
        use strict;
    } ## end if ( not defined $closure )

    return [ $lhs_symbol_name, [$rhs_symbol_name], $action_name ];
} ## end sub make_rule

sub make_plex_rules {
    my ($size) = @_;
    my @symbol_names = map { chr +( $_ + ord 'A' ) } ( 0 .. $size - 1 );
    my @rules;
    for my $infinite_symbol (@symbol_names) {
        for my $rhs_symbol (@symbol_names) {
            push @rules, make_rule( $infinite_symbol, $rhs_symbol );
        }
        push @rules, make_rule( $infinite_symbol, 't' );
        push @rules, make_rule( 's', $infinite_symbol );
    } ## end for my $infinite_symbol (@symbol_names)
    return \@rules;
} ## end sub make_plex_rules

my $plex1_test = [
    '1-plex test',
    [ start => 's', rules => make_plex_rules(1) ],
    <<'EOS',
sA(AA(At(t)))
sA(At(t))
EOS
    <<'EOS',
Cycle found involving rule: 0: A -> A
EOS
];

my $plex2_test = [
    '2-plex test',
    [ start => 's', rules => make_plex_rules(2) ],
    <<'EOS',
sA(AA(AB(BA(At(t)))))
sA(AA(AB(BB(BA(At(t))))))
sA(AA(AB(BB(Bt(t)))))
sA(AA(AB(Bt(t))))
sA(AA(At(t)))
sA(AB(BA(AA(At(t)))))
sA(AB(BA(At(t))))
sA(AB(BB(BA(AA(At(t))))))
sA(AB(BB(BA(At(t)))))
sA(AB(BB(Bt(t))))
sA(AB(Bt(t)))
sA(At(t))
sB(BA(AA(AB(BB(Bt(t))))))
sB(BA(AA(AB(Bt(t)))))
sB(BA(AA(At(t))))
sB(BA(AB(BB(Bt(t)))))
sB(BA(AB(Bt(t))))
sB(BA(At(t)))
sB(BB(BA(AA(AB(Bt(t))))))
sB(BB(BA(AA(At(t)))))
sB(BB(BA(AB(Bt(t)))))
sB(BB(BA(At(t))))
sB(BB(Bt(t)))
sB(Bt(t))
EOS
    <<'EOS',
Cycle found involving rule: 0: A -> A
Cycle found involving rule: 1: A -> B
Cycle found involving rule: 4: B -> A
Cycle found involving rule: 5: B -> B
EOS
];

for my $test_data ( $plex1_test, $plex2_test ) {
    my ( $test_name, $rules, $expected_values, $expected_trace ) =
        @{$test_data};

    my $trace = q{};
    open my $MEMORY, '>', \$trace;
    my %args = (
        @{$rules},
        infinite_action   => 'warn',
        trace_file_handle => $MEMORY,
    );
    my $grammar = Marpa::R2::Grammar->new( \%args );
    $grammar->precompute();

    close $MEMORY;
    Marpa::R2::Test::is( $trace, $expected_trace, "$test_name trace" );

    my $recce = Marpa::R2::Recognizer->new(
        { grammar => $grammar, trace_file_handle => \*STDERR } );

    $recce->read( 't', 't' );

    my @values = ();
    while ( my $value_ref = $recce->value() ) {
        push @values, ${$value_ref};
    }

    my $values = join "\n", sort @values;
    Marpa::R2::Test::is( "$values\n", $expected_values, $test_name );

} ## end for my $test_data ( $plex1_test, $plex2_test )

1;    # In case used as "do" file

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
