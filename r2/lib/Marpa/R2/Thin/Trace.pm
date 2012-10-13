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

package Marpa::R2::Thin::Trace;

use 5.010;
use warnings;
use strict;

use vars qw($VERSION $STRING_VERSION);
$VERSION = '2.021_008';
$STRING_VERSION = $VERSION;
$VERSION = eval $VERSION;

sub new {
    my ($class, $grammar) = @_;
    my $self = bless {}, $class;
    $self->{g} = $grammar;
    $self->{rule_by_name} = {};
    $self->{symbol_by_name} = {};
    $self->{rule_names} = {};
    $self->{symbol_names} = {};
    return $self;
}

sub rule_by_name {
   my ($self, $name) = @_;
   my $rule = $self->{rule_by_name}->{$name};
   die qq{No rule with name "$name"} if not defined $rule;
   return $rule;
}

sub rule_name {
   my ($self, $rule_id) = @_;
   my $rule_name = $self->{rule_name}->[$rule_id];
   $rule_name = 'R' . $rule_id if not defined $rule_name;
   return $rule_name;
}

sub rule_name_set {
   my ($self, $name, $rule_id) = @_;
   $self->{rule_name}->[$rule_id] = $name;
   $self->{rule_by_name}->{$name} = $rule_id;
   return $rule_id;
}

sub rule_new {
    my ( $self, $lhs, @rhs ) = @_;
    die "Missing lhs" if not defined $lhs;
    return $self->{g}->rule_new( $self->symbol_by_name($lhs),
        [ map { $self->symbol_by_name($_) } @rhs ] );
} ## end sub rule_new

sub symbol_by_name {
   my ($self, $name) = @_;
   my $symbol = $self->{symbol_by_name}->{$name};
   die qq{No symbol with name "$name"} if not defined $symbol;
   return $symbol;
}

sub symbol_name {
   my ($self, $symbol_id) = @_;
   my $symbol_name = $self->{symbol_name}->[$symbol_id];
   $symbol_name = 'R' . $symbol_id if not defined $symbol_name;
   return $symbol_name;
}

sub symbol_name_set {
   my ($self, $name, $symbol_id) = @_;
   $self->{symbol_name}->[$symbol_id] = $name;
   $self->{symbol_by_name}->{$name} = $symbol_id;
   return $symbol_id;
}

sub symbol_new {
   my ($self, $name) = @_;
   return $self->symbol_name_set($name, $self->{g}->symbol_new());
}

sub dotted_rule {
    my ( $self, $rule_id, $dot_position ) = @_;
    my $grammar     = $self->{g};
    my $rule_length = $grammar->rule_length($rule_id);
    $dot_position = $rule_length if $dot_position < 0;
    my $lhs         = $self->symbol_name( $grammar->rule_lhs($rule_id) );
    my @rhs =
        map { $self->symbol_name( $grammar->rule_rhs( $rule_id, $_ ) ) }
        ( 0 .. $rule_length - 1 );
    $dot_position = 0 if $dot_position < 0;
    splice( @rhs, $dot_position, 0, q{.} );
    return join q{ }, $lhs, q{::=}, @rhs;
} ## end sub dotted_rule

sub progress_report {
    my ( $self, $recce, $ordinal ) = @_;
    my $result = q{};
    $ordinal //= $recce->latest_earley_set();
    $recce->progress_report_start($ordinal);
    ITEM: while (1) {
        my ( $rule_id, $dot_position, $origin ) = $recce->progress_item();
        last ITEM if not defined $rule_id; 
        $result
            .= q{@}
            . $origin . q{: }
            . $self->dotted_rule( $rule_id, $dot_position ) . "\n";
    } ## end ITEM: while (1)
    $recce->progress_report_finish();
    return $result;
} ## end sub progress_report

1;
