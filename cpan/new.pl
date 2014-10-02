#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Marpa::R2;
use File::Slurp 'read_file';
use Data::Dumper;

$Data::Dumper::Deepcopy = 1; # for better dumps

my $grammar = << '=== GRAMMAR ===';
:default ::= action => [ name, value ]
lexeme default = action => [ name, value ] latm => 1 # to add token names to ast

<prefixed target> ::= prefix target
prefix ::= lexeme*

target ::= balanced
event target = completed target

balanced ::= 
    lparen contents rparen
  | lcurly contents rcurly
  | lsquare contents rsquare

contents ::= filler | empty


empty ::=
lexeme ::= <stray bracket> | filler

# x5b is left square bracket
# x5d is right square bracket
filler ~ [^(){}\x5B\x5D]+

<stray bracket> ::= bracket

lparen ~ '(' rparen ~ ')'
lcurly ~ '{' rcurly ~ '}'
lsquare ~ '[' rsquare ~ ']'
# <stray lparen> = '(' <stray rparen> = ')'
# <stray lcurly> = '{' <stray rcurly> = '}'
# <stray lsquare> = '[' <stray rsquare> = ']'
bracket ~ [(){}\x5B\x5D]
=== GRAMMAR ===

my $g = Marpa::R2::Scanless::G->new({
		source         => \( $grammar )
});


my $recce      = Marpa::R2::Scanless::R->new({
		grammar => $g,
		trace_terminals => 99,
		trace_values => 1
		});

my $string = 'z}ab)({[]})))(([]))';
my $length = length $string;
my $pos = $recce->read(\$string);

TARGET: while (1) {
    FIND_FIRST_MATCH: while (1) {
        my @actual_events = ();

        my $next_lexeme;
        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            if ( $name eq 'target' ) {
                my @g1_span = $recce->last_completed('target');
                say STDERR "Preliminary target at $pos: ",
                    $recce->substring(@g1_span);
                last FIND_FIRST_MATCH;
            } ## end if ( $name eq 'target' )
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

        if ( $pos < $length ) {
            $pos = $recce->resume();
            next FIND_FIRST_MATCH;
        }
        last TARGET;
    } ## end FIND_FIRST_MATCH: while (1)

    exit 0;
} ## end TARGET: while (1)

# my $ref_value = $recce->value();
# die "No parse" if not $ref_value;
# my $tree = ${$ref_value};
# say Dumper($tree);

