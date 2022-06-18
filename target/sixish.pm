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

package Marpa::R2::Demo::Sixish1;

use 5.010;
use strict;
use warnings;

use Marpa::R2;
BEGIN { require './Own_Rules.pm' };

{
    my $file = './OP4.pm';
    unless ( my $return = do $file ) {
        warn "couldn't parse $file: $@" if $@;
        warn "couldn't do $file: $!" unless defined $return;
        warn "couldn't run $file" unless $return;
    }
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
    my ( $self, $ebnf ) = @_;
    my ( $lhs, $rhs ) = split /\s*[:][:][=]\s*/xms, $ebnf;
    die "Malformed EBNF: $ebnf" if not defined $lhs;
    $lhs =~ s/\A\s*//xms;
    $lhs =~ s/\s*\z//xms;
    my @rhs = split /\s+/xms, $rhs;
    return $self->{grammar}->rule_new( $self->symbol_by_name($lhs),
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
   return $self->symbol_name_set($name, $self->{grammar}->symbol_new());
}

sub dotted_rule {
    my ( $self, $rule_id, $dot_position ) = @_;
    my $grammar     = $self->{grammar};
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

sub new {
    my ($class) = @_;
    my $sixish_grammar  = Marpa::R2::Thin::G->new( { if => 1 } );
    my %char_to_symbol  = ();
    my @regex_to_symbol = ();

    my $self = bless {}, $class;
    $self->{grammar} = $sixish_grammar;
    $self->{rule_by_name} = {};
    my $symbol_by_name = $self->{symbol_by_name} = {};
    $self->{rule_names} = {};
    $self->{symbol_names} = {};
    my $actions = $self->{actions} = [];

    for my $char (split //xms, q{*<>~}) {
      $char_to_symbol{$char}  = $self->symbol_new(qq{'$char'});
    }
    $char_to_symbol{q{'}}  = $self->symbol_new('<single quote>');

    my $s_ws_char = $self->symbol_new('<ws char>');
    push @regex_to_symbol, [ qr/\s/xms, $s_ws_char ];
    my $s_single_quoted_char = $self->symbol_new('<single quoted char>');
    push @regex_to_symbol, [ qr/[^\\']/xms, $s_single_quoted_char ];

    SYMBOL: for my $symbol_name ( map { $_->{lhs}, @{ $_->{rhs} } }
        @{$Marpa::R2::Sixish::Own_Rules::rules} )
    {
	next SYMBOL if $symbol_name =~ m{ \A ['] (.*) ['] \z }xms;
        if ( not defined $symbol_by_name->{$symbol_name} ) {
            my $symbol = $self->symbol_new($symbol_name);
say STDERR "Created symbol $symbol: ", $symbol_name;
        }
    } ## end for my $symbol_name ( map { $rule->{lhs}, @{ $rule->{...}}})

    RULE: for my $rule ( @{$Marpa::R2::Sixish::Own_Rules::rules} ) {
        my $min    = $rule->{min};
        my $lhs    = $rule->{lhs};
        my $rhs    = $rule->{rhs};
        my $action = $rule->{action};
        if ( defined $min ) {
            my $rule_id = $sixish_grammar->sequence_new(
                $self->symbol_by_name($lhs),
                $self->symbol_by_name( $rhs->[0] ),
                { min => $min }
            );
            $actions->[$rule_id] = $action if defined $action;
            next RULE;
        } ## end if ( defined $min )
        my @rhs_symbols = ();
        RHS_SYMBOL: for my $rhs_symbol_name ( @{$rhs} ) {
            if ( $rhs_symbol_name =~ m{ \A ['] ([^']+) ['] \z }xms ) {
                my $single_quoted_string = $1;
                say STDERR $rhs_symbol_name;
                push @rhs_symbols, map { $char_to_symbol{$_} } split //xms,
                    $single_quoted_string;
                next RHS_SYMBOL;
            } ## end if ( $rhs_symbol_name =~ m{ \A ['] ([^']+) ['] \z }xms)
            push @rhs_symbols, $self->symbol_by_name($rhs_symbol_name);
        } ## end RHS_SYMBOL: for my $rhs_symbol_name ( @{$rhs} )
        my $rule_id = $sixish_grammar->rule_new( $self->symbol_by_name($lhs),
            \@rhs_symbols );
        $actions->[$rule_id] = $action if defined $action;

# say STDERR $self->dotted_rule($rule_id, 0);

    } ## end RULE: for my $rule ( @{$Marpa::R2::Sixish::Own_Rules::rules...})

    $sixish_grammar->start_symbol_set( $self->symbol_by_name('<top>'), );
    $sixish_grammar->precompute();

while ( my ( $char, $symbol ) = each %char_to_symbol ) {
    say STDERR qq{Symbol $symbol, "$char"};
    die qq{Symbol $symbol, "$char" is inaccessible} if not $sixish_grammar->symbol_is_accessible($symbol);
}

        $self->{grammar}         = $sixish_grammar;
        $self->{char_to_symbol}  = \%char_to_symbol;
        $self->{regex_to_symbol} = \@regex_to_symbol;

    return $self;
} ## end sub sixish_new

1;
