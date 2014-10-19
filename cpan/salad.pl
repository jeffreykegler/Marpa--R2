#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Marpa::R2;
use File::Slurp 'read_file';
use Data::Dumper;

$Data::Dumper::Deepcopy = 1;    # for better dumps

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

contents ::= <content item>*
<content item> ::= balanced | filler
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

my $g = Marpa::R2::Scanless::G->new( { source => \($grammar) } );

# my $recce_debug_args = { trace_terminals => 1, trace_values => 1 };
my $recce_debug_args = {};

sub test {
    my ($string) = @_;
    my @found = ();
    # say STDERR "Input: $string";
    my $input_length = length $string;
    my $target_start = 0;

    TARGET: while ( $target_start < $input_length ) {
        my @shortest_span = ();
        my $recce         = Marpa::R2::Scanless::R->new(
            {   grammar    => $g,
                exhaustion => 'event',
            },
            $recce_debug_args
        );
        my $pos = $recce->read( \$string, $target_start );

        EVENT:
        for my $event ( @{ $recce->events() } ) {
            my ($name) = @{$event};
            if ( $name eq 'target' ) {
                @shortest_span = $recce->last_completed_span('target');
                # say STDERR "Preliminary target at $pos: ",
                    # $recce->literal(@shortest_span);
                next EVENT;
            } ## end if ( $name eq 'target' )
                # Not all exhaustion has an exhaustion event,
                # so we look for exhaustion explicitly below.
            next EVENT if $name eq q('exhausted);
            die join q{ }, "Spurious event at position $pos: '$name'";
        } ## end EVENT: for my $event ( @{ $recce->events() } )

        last TARGET if not scalar @shortest_span;

        # We end the prefix here
        # say STDERR join q{ }, @shortest_span;
        my $prefix_end = $shortest_span[0];
        $recce = Marpa::R2::Scanless::R->new(
            {   grammar    => $g,
                exhaustion => 'event',
                rejection => 'event',
            },
            $recce_debug_args
        );
        $recce->activate( 'target', 0 );
        $recce->read( \$string, $target_start, $prefix_end - $target_start );
        $recce->lexeme_priority_set( 'prefix lexeme', -1 );
        $pos = $recce->resume($prefix_end);

        my @longest_span = $recce->last_completed_span('target');
        # say STDERR "Actual target at $pos: ", $recce->literal(@longest_span);

        last TARGET if not scalar @longest_span;
        push @found, $recce->literal(@longest_span);
        say "Found target at $pos: ", $recce->literal(@longest_span);

        $target_start = $longest_span[0] + $longest_span[1];

    } ## end TARGET: while ( $target_start < $input_length )
    return \@found;
} ## end sub test

#             012345678901234567890
my @strings = ( 'z}ab)({[]})))(([]))zz',
'9\090]{[][][9]89]8[][]90]{[]\{}{}09[]}[',
'([]([])([]([]',
);

for my $string (@strings) {
    my $finds = test($string);
    say "Input: $string";
    for ( my $i = 0; $i < scalar @{$finds}; $i++ ) {
        say join " ", "Find", ( $i + 1 . ":" ), $finds->[$i];
    }
} ## end for my $string (@strings)

# my $ref_value = $recce->value();
# die "No parse" if not $ref_value;
# my $tree = ${$ref_value};
# say Dumper($tree);

