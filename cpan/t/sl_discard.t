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

# Example of use of discard events

use 5.010001;
use strict;
use warnings;
use Test::More tests => 1;
use English qw( -no_match_vars );
use Scalar::Util;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

# Marpa::R2::Display
# name: SLIF discard event synopsis

use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {
        source        => \(<<'END_OF_SOURCE'),
:default ::= action => [g1start, g1len, values]
lexeme default = latm => 1

Script ::= Expression+ separator => comma action => do_expression
comma ~ [,]
Expression ::= Subexpression action => [g1start,g1len,value]
Subexpression ::=
    Number action => do_number
    | ('(') Subexpression (')') assoc => group action => do_paren
   || Subexpression ('**') Subexpression assoc => right action => do_power
   || Subexpression ('*') Subexpression  action => do_multiply
    | Subexpression ('/') Subexpression  action => do_divide
   || Subexpression ('+') Subexpression  action => do_add
    | Subexpression ('-') Subexpression  action => do_subtract

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
# Hardy-Ramanujan number
1729, 1**3+12**3, 9**3+10**3,
# Next highest taxicab number
# note: weird spacing is deliberate
87539319, 167**3+ 436**3,228**3 + 423**3,255**3+414**3
EOI

my $output_re =
            qr/\A 86[.]3\d+ \s+ 126 \s+ 125 \s+ 16 \s+ 1729 \s+ 1729 \s+ 1729 .*\z/xms;


    my $length = length $input;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar,
    semantics_package => 'My_Nodes',
    } );

    my $pos = $recce->read(\$input);

    my @events = ();
    READ: while (1) {

        my @actual_events = ();

        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ( $name, @other_stuff ) = @{$event};
            # say STDERR 'Event received!!! -- ', Data::Dumper::Dumper($event);
            push @events, $event;
        }

        last READ if $pos >= $length;
        $pos = $recce->resume($pos);
    } ## end READ: while (1)

    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse was found, after reading the entire input\n";
    }

    my $event_ix = 0;
    my $result = '';
    for my $expression (@{${$value_ref}}) {
        my ($g1start, $g1len, $value) = @{$expression};
        my $g1end = $g1start+$g1len;
        $result .= qq{expression: "} . $recce->substring( $g1start, $g1len ) .
            qq{" = } . round_value($value);
        $result .= "\n";
        EVENT: while ($event_ix <= $#events) {
            my $event = $events[$event_ix];
            my $g1loc = $event->[3];
            last EVENT if $g1loc >= $g1end;
            my $type = $g1loc == $g1start ? 'preceding' : 'internal';
            $result .= join q{ }, $type, display_event($recce, @{$event});
            $result .= "\n";
            $event_ix++;
        }
        $result .= "\n";
    }

    EVENT: while ( $event_ix <= $#events ) {
        my $event = $events[$event_ix];
        $result .= join q{ }, 'trailing', display_event($recce, @{$event});
        $result .= "\n";
        $event_ix++;
    } ## end EVENT: while ( $event_ix <= $#events )


# round value down, for testing on platforms
# with various float precisions
sub round_value {
    my ( $value ) = @_;
    return (int $value*100)/100;
}

sub display_event {
    my ( $recce, $event_name, $start, $end ) = @_;
    if ($event_name eq 'ws') {
       return "ws of length " . ($end-$start);
    }
    my $literal = $recce->literal($start, ($end-$start));
    $literal =~ s/\n/\\n/xmsg;
    return qq{$event_name: "$literal"};
}

my $expected_result = <<'END_OF_RESULT';
expression: "42*2+7/3" = 86.33

expression: "42*(2+7)/3" = 126
preceding ws of length 1

expression: "2**7-3" = 125
preceding ws of length 1

expression: "2**(7-3)" = 16
preceding ws of length 1

expression: "1729" = 1729
preceding ws of length 1
preceding comment: "# Hardy-Ramanujan number\n"

expression: "1**3+12**3" = 1729
preceding ws of length 1

expression: "9**3+10**3" = 1729
preceding ws of length 1

expression: "87539319" = 87539319
preceding ws of length 1
preceding comment: "# Next highest taxicab number\n"
preceding comment: "# note: weird spacing is deliberate\n"

expression: "167**3+ 436**3" = 87539319
preceding ws of length 1
internal ws of length 1

expression: "228**3 + 423**3" = 87539319
internal ws of length 1
internal ws of length 1

expression: "255**3+414**3" = 87539319

trailing ws of length 1
END_OF_RESULT

Marpa::R2::Test::is($result, $expected_result, "interweave of events and parse tree");

package My_Nodes;

sub My_Nodes::do_expression {
    my ($parse, @values) = @_;
    return \@values;
    # say STDERR "pushing value: ", Data::Dumper::Dumper(\@_);
}

sub My_Nodes::do_number {
    my ($parse, $number) = @_;
    return $number+0;
}

sub My_Nodes::do_paren  {
    my ($parse, $expr) = @_;
    return $expr;
}

sub My_Nodes::do_add {
    my ($parse, $right, $left) = @_;
    return $right + $left;
}

sub My_Nodes::do_subtract {
    my ($parse, $right, $left) = @_;
    return $right - $left;
}

sub My_Nodes::do_multiply {
    my ($parse, $right, $left) = @_;
    return $right * $left;
}

sub My_Nodes::do_divide {
    my ($parse, $right, $left) = @_;
    return $right / $left;
}

sub My_Nodes::do_power {
    my ($parse, $right, $left) = @_;
    return $right ** $left;
}

# vim: expandtab shiftwidth=4:
