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
prefix ::= <prefix lexeme>*

target ::= balanced
event target = completed target

balanced ::= 
    lparen contents rparen
  | lcurly contents rcurly
  | lsquare contents rsquare

contents ::= balanced | filler | empty
empty ::=

<prefix lexeme> ~ <deep filler>
filler ~ <deep filler>
# x5b is left square bracket
# x5d is right square bracket
<deep filler> ~ [^(){}\x5B\x5D]+

<prefix lexeme> ~ <deep lparen>
lparen ~ <deep lparen>
<deep lparen> ~ '('

<prefix lexeme> ~ <deep rparen>
rparen ~ <deep rparen>
<deep rparen> ~ ')'

<prefix lexeme> ~ <deep lcurly>
lcurly ~ <deep lcurly>
<deep lcurly> ~ '{'

<prefix lexeme> ~ <deep rcurly>
rcurly ~ <deep rcurly>
<deep rcurly> ~ '}'

<prefix lexeme> ~ <deep lsquare>
lsquare ~ <deep lsquare>
<deep lsquare> ~ '['

<prefix lexeme> ~ <deep rsquare>
rsquare ~ <deep rsquare>
<deep rsquare> ~ ']'

=== GRAMMAR ===

my $g = Marpa::R2::Scanless::G->new({
		source         => \( $grammar )
});


my $recce      = Marpa::R2::Scanless::R->new({
		grammar => $g,
		trace_terminals => 1,
		trace_values => 1
		});

my $string = 'z}ab)({[]})))(([]))zz';
my $length = length $string;
my $pos = $recce->read(\$string);
my $target_search_start = $pos;

TARGET: while ($target_search_start < $length) {
    my @first_end_span = ();
    $recce->lexeme_priority_set('prefix lexeme', 0);
    FIND_FIRST_END_SPAN: while (1) {
        my @actual_events = ();

        my $next_lexeme;
        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            if ( $name eq 'target' ) {
                @first_end_span = $recce->last_completed('target');
                say STDERR "Preliminary target at $pos: ",
                    $recce->substring(@first_end_span);
                last FIND_FIRST_END_SPAN;
            } ## end if ( $name eq 'target' )
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

        if ( $pos < $length ) {
            $pos = $recce->resume();
            next FIND_FIRST_END_SPAN;
        }
        last TARGET;
    } ## end FIND_FIRST_END_SPAN: while (1)

    # We end the prefix here
    my ($prefix_end) = $recce->g1_location_to_span($first_end_span[0]);
    $pos = $recce->resume($target_search_start, $prefix_end - $target_search_start);
    $recce->lexeme_priority_set('prefix lexeme', -1);
    $pos = $recce->resume($prefix_end);
    FIND_FIRST_START_SPAN: while (1) {
        my @actual_events = ();

        my $next_lexeme;
        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            if ( $name eq 'target' ) {
                @first_end_span = $recce->last_completed('target');
                say STDERR "Actual target at $pos: ",
                    $recce->substring(@first_end_span);
                next EVENT;
            } ## end if ( $name eq 'target' )
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

        if ( $pos < $length ) {
            $pos = $recce->resume();
            next FIND_FIRST_START_SPAN;
        }
        last TARGET;
    } ## end FIND_FIRST_START_SPAN: while (1)

    exit 0;
} ## end TARGET: while (1)

# my $ref_value = $recce->value();
# die "No parse" if not $ref_value;
# my $tree = ${$ref_value};
# say Dumper($tree);

