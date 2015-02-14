#!/usr/bin/perl
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

# Example of use of discard events

use 5.010;
use strict;
use warnings;
use Test::More tests => 3;
use English qw( -no_match_vars );
use Scalar::Util;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

# Marpa::R2::Display
# name: SLIF DSL synopsis

use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'My_Nodes',
        source        => \(<<'END_OF_SOURCE'),
:default ::= action => [values] bless => ::lhs
lexeme default = action => [ start, length, value ]
    bless => ::name latm => 1

:start ::= Script
Script ::= Expression+ separator => comma
comma ~ [,]
Expression ::=
    Number bless => primary
    | '(' Expression ')' bless => paren assoc => group
   || Expression '**' Expression bless => exponentiate assoc => right
   || Expression '*' Expression bless => multiply
    | Expression '/' Expression bless => divide
   || Expression '+' Expression bless => add
    | Expression '-' Expression bless => subtract

Number ~ [\d]+
:discard ~ whitespace event => ws
whitespace ~ [\s]+
# allow comments
:discard ~ <hash comment> event => comment
<hash comment> ~ <terminated hash comment> | <unterminated
   final hash comment>
<terminated hash comment> ~ '#' <hash comment body> <vertical space char>
<unterminated final hash comment> ~ '#' <hash comment body>
<hash comment body> ~ <hash comment char>*
<vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
<hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_OF_SOURCE
    }
);

# Marpa::R2::Display::End

my $input = <<'EOI';
42*2+7/3, 42*(2+7)/3, 2**7-3, 2**(7-3),
# Hardy-Ramujan number
1729, 1**3+12**3, 9**3+10**3,
# Next highest taxibab number
# note: weird spacing is deliberate
87539319, 1673+ 4363,2283 + 4233,2553+4143
EOI

my $output_re = 
            qr/\A 86[.]3\d+ \s+ 126 \s+ 125 \s+ 16 \s+ 1729 \s+ 1729 \s+ 1729 .*\z/xms;


    my $length = length $input;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

    my $pos = $recce->read(\$input);

    my $actual_events = q{};
    READ: while (1) {

        my @actual_events = ();

        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ( $name, @other_stuff ) = @{$event};
            say STDERR 'Event received!!! -- ', Data::Dumper::Dumper($event);
            push @actual_events, $name;
        }

        if (@actual_events) {
            $actual_events .= join q{ }, $pos, @actual_events;
            $actual_events .= "\n";
        }
        last READ if $pos >= $length;
        $pos = $recce->resume($pos);
    } ## end READ: while (1)

    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse was found, after reading the entire input\n";
    }
    my $value = ${$value_ref}->doit();
Test::More::like( $value, $output_re, 'Example of discard events' );

package My_Nodes;

sub My_Nodes::primary::doit { return $_[0]->[0]->doit() }
sub My_Nodes::Number::doit  { return $_[0]->[2] }
sub My_Nodes::paren::doit   { my ($self) = @_; $self->[1]->doit() }

sub My_Nodes::add::doit {
    my ($self) = @_;
    $self->[0]->doit() + $self->[2]->doit();
}

sub My_Nodes::subtract::doit {
    my ($self) = @_;
    $self->[0]->doit() - $self->[2]->doit();
}

sub My_Nodes::multiply::doit {
    my ($self) = @_;
    $self->[0]->doit() * $self->[2]->doit();
}

sub My_Nodes::divide::doit {
    my ($self) = @_;
    $self->[0]->doit() / $self->[2]->doit();
}

sub My_Nodes::exponentiate::doit {
    my ($self) = @_;
    $self->[0]->doit()**$self->[2]->doit();
}

sub My_Nodes::Script::doit {
    my ($self) = @_;
    return join q{ }, map { $_->doit() } @{$self};
}

# vim: expandtab shiftwidth=4:
