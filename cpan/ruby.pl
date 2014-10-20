#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Marpa::R2 2.097_002;
use Data::Dumper;

# This example tests the Ruby Slippers using the SLIF

my $grammar = << '=== GRAMMAR ===';
:default ::= action => [ name, value ]
lexeme default = action => [ name, value ] latm => 1 # to add token names to ast

script ::= E+ separator => semi action => [values]
E ::= 
     number action => main::number
     || E ('*') E action => main::multiply
     || E ('+') E action => main::add

:discard ~ whitespace
whitespace ~ [\s]+
number ~ [\d]+
semi ~ ';'

=== GRAMMAR ===

my $g = Marpa::R2::Scanless::G->new( { source => \($grammar) } );

# Test strings go here
#             012345678901234567890
my @strings = (
'1+2+3*4',
'1+2 3+4',
'0+42 21*2 3*7+21 3*7*2',
# '([]([])([]([]',
);

for my $string (@strings) {
    my $result = test($g, $string);
    say "Input: $string";
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Indent = 0;
    say Data::Dumper->Dump([${$result}], ['Result']);
} ## end for my $string (@strings)

sub test {
    my ( $g, $string ) = @_;
    my @found = ();

    # say STDERR "Input: $string";
    my $original_length = length $string;
    my $suffixed_string = $string . ';';
    my $target_start = 0;

    # state $recce_debug_args = { trace_terminals => 1, trace_values => 1 };
    state $recce_debug_args = {};

    my $recce = Marpa::R2::Scanless::R->new(
        {   grammar   => $g,
            rejection => 'event',
        },
        $recce_debug_args
    );
    my $pos = $recce->read( \$suffixed_string, 0, $original_length );

    READ_LOOP: while (1) {
        my $rejection = 0;
        my $pos = $recce->pos();
        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            if ( $name eq q('rejected) ) {
                $rejection = 1;
                say STDERR "You fool! you forget the semi-colon at location $pos!";
                next EVENT;

            } ## end if ( $name eq q('rejected) )
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

        last READ_LOOP if not $rejection;
        $recce->resume( $original_length, 1 );
        say STDERR "I fixed it for you.  Now you owe me.";
        $recce->resume( $pos, $original_length - $pos );
    }

   my $ref_value = $recce->value();
   return ["No parse"] if not $ref_value;
   return ["Value not a ref"] if not ref $ref_value;
   return $ref_value;
    
} ## end sub test

sub number {
   my (undef, $v1) = @_;
   return $v1->[1];
}

sub add {
   my ($undef, $v1, $v2) = @_;
   return $v1+$v2;
}

sub multiply {
   my ($undef, $v1, $v2) = @_;
   return $v1*$v2;
}

# vim: expandtab shiftwidth=4:
