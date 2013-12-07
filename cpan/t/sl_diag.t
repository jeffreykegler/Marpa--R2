#!perl
# Copyright 2013 Jeffrey Kegler
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

# Test of scannerless parsing -- diagnostics

use 5.010;
use strict;
use warnings;

use Test::More tests => 10;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;

my $grammar = <<'END_OF_RULES';
:start ::= Script
Script ::= Calculation* action => do_list
Calculation ::= Expression | ('say') Expression
Expression ::=
     Number
   | ('+') Expression Expression action => do_add
Number ~ [\d] +
:discard ~ whitespace
whitespace ~ [\s]+
# allow comments
:discard ~ <hash comment>
<hash comment> ~ <terminated hash comment> | <unterminated
   final hash comment>
<terminated hash comment> ~ '#' <hash comment body> <vertical space char>
<unterminated final hash comment> ~ '#' <hash comment body>
<hash comment body> ~ <hash comment char>*
<vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
<hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_OF_RULES

my $slg = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Actions',
        default_action => 'do_arg0',
        source => \$grammar,
    }
);

my $g0_rules_description;

# Marpa::R2::Display
# name: Scanless g0_rule() synopsis

    my @g0_rule_ids = $slg->g0_rule_ids();
    for my $g0_rule_id (@g0_rule_ids) {
        $g0_rules_description .= "$g0_rule_id "
            . ( join q{ }, map {"<$_>"} $slg->g0_rule($g0_rule_id) ) . "\n";
    }

# Marpa::R2::Display::End

Marpa::R2::Test::is(
    $g0_rules_description,
    <<'END_OF_DESCRIPTION',
0 <[Lex-0]> <[[s]]> <[[a]]> <[[y]]>
1 <[Lex-1]> <[[\+]]>
2 <Number> <[[\d]]>
3 <[:discard]> <whitespace>
4 <whitespace> <[[\s]]>
5 <[:discard]> <hash comment>
6 <hash comment> <terminated hash comment>
7 <hash comment> <unterminated final hash comment>
8 <terminated hash comment> <[[\#]]> <hash comment body> <vertical space char>
9 <unterminated final hash comment> <[[\#]]> <hash comment body>
10 <hash comment body> <hash comment char>
11 <vertical space char> <[[\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]]>
12 <hash comment char> <[[^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]]>
13 <[:start_lex]> <Number>
14 <[:start_lex]> <[:discard]>
15 <[:start_lex]> <[Lex-0]>
16 <[:start_lex]> <[Lex-1]>
END_OF_DESCRIPTION
    'g0_rule_ids() and g0_rule()'
);

my $g1_rules_description;

# Marpa::R2::Display
# name: Scanless rule() synopsis

    my @g1_rule_ids = $slg->g1_rule_ids();
    for my $g1_rule_id (@g1_rule_ids) {
        $g1_rules_description .= "$g1_rule_id "
            . ( join q{ }, map {"<$_>"} $slg->rule($g1_rule_id) ) . "\n";
    }

# Marpa::R2::Display::End

Marpa::R2::Test::is(
    $g1_rules_description,
    <<'END_OF_DESCRIPTION',
0 <Script> <Calculation>
1 <Calculation> <Expression>
2 <Calculation> <[Lex-0]> <Expression>
3 <Expression> <Number>
4 <Expression> <[Lex-1]> <Expression> <Expression>
5 <[:start]> <Script>
END_OF_DESCRIPTION
    'g1_rule_ids() and rule()'
);

package My_Actions;
# The SELF object is a very awkward way of specifying the per-parse
# argument directly, one which was necessary before the $slr->value()
# method took an argument.
# This way of doing things is discourage and preserved here for testing purposes.
our $SELF;
sub new { return $SELF }

sub do_list {
    my ( $self, @results ) = @_;
    return +( scalar @results ) . ' results: ' . join q{ }, @results;
}

sub do_add  { shift; return $_[0] + $_[1] }
sub do_arg0 { shift; return shift; }

sub show_last_expression {
    my ($self) = @_;
    my $slr = $self->{recce};
    my ( $start, $end ) = $slr->last_completed_range('Expression');
    return if not defined $start;
    my $last_expression = $slr->range_to_string( $start, $end );
    return $last_expression;
} ## end sub show_last_expression

package main;

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $self = bless { grammar => $grammar }, 'My_Actions';
    local $My_Actions::SELF = $self;

    my $trace_output = q{};
    open my $trace_fh, q{>}, \$trace_output;
    my $recce = Marpa::R2::Scanless::R->new(
        {   grammar               => $grammar,
            trace_terminals       => 2,
            trace_file_handle     => $trace_fh,
            too_many_earley_items => 100,         # test this
        }
    );
    $self->{recce} = $recce;
    my ( $parse_value, $parse_status, $last_expression );

    my $eval_ok = eval { $recce->read( \$string ); 1 };
    close $trace_fh;

    if ( not defined $eval_ok ) {
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        die $self->show_last_expression(), $EVAL_ERROR;
    } ## end if ( not defined $eval_ok )
    my $value_ref = $recce->value;
    if ( not defined $value_ref ) {
        die join q{ },
            'Input read to end but no parse',
            $self->show_last_expression();
    }
    return $recce, ${$value_ref}, $trace_output;
} ## end sub my_parser

my @tests_data = (
    [ '+++ 1 2 3 + + 1 2 4', '1 results: 13', 'Parse OK', 'entire input' ],
);

TEST:
for my $test_data (@tests_data) {
    my ($test_string,     $expected_value,
        $expected_result, $expected_last_expression
    ) = @{$test_data};
    my ( $slr, $actual_value, $trace_output ) =
        my_parser( $slg, $test_string );

# Marpa::R2::Display
# name: Scanless terminals_expected() synopsis

    my @terminals_expected = @{$slr->terminals_expected()};

# Marpa::R2::Display::End

    Marpa::R2::Test::is(
        ( join q{ }, sort @terminals_expected ),
        'Number [Lex-0] [Lex-1]',
        qq{SLIF terminals_expected()}
    );

# Marpa::R2::Display
# name: Scanless show_progress() synopsis

    my $show_progress_output = $slr->show_progress();

# Marpa::R2::Display::End

    Marpa::R2::Test::is( $show_progress_output,
        <<'END_OF_EXPECTED_OUTPUT', qq{Scanless show_progess()} );
P0 @0-11 L1c1-19 Script -> . Calculation *
F0 @0-11 L1c1-19 Script -> Calculation * .
P1 @11-11 L1c19 Calculation -> . Expression
F1 @0-11 L1c1-19 Calculation -> Expression .
P2 @11-11 L1c19 Calculation -> . 'say' Expression
P3 @11-11 L1c19 Expression -> . Number
F3 @10-11 L1c17-19 Expression -> Number .
P4 @11-11 L1c19 Expression -> . '+' Expression Expression
F4 x3 @0,6,10-11 L1c1-19 Expression -> '+' Expression Expression .
F5 @0-11 L1c1-19 :start -> Script .
END_OF_EXPECTED_OUTPUT

    Marpa::R2::Test::is( $actual_value, $expected_value,
        qq{Value of "$test_string"} );
    Marpa::R2::Test::is( $trace_output,
        <<'END_OF_OUTPUT', qq{Trace output for "$test_string"} );
Setting trace_terminals option
Lexer "L0" registering character U+002b '+' as symbol 5: [\+]
Lexer "L0" registering character U+002b '+' as symbol 9: [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
Lexer "L0" accepted lexeme L1c1: '+'; value="+"
Lexer "L0" accepted lexeme L1c2: '+'; value="+"
Lexer "L0" accepted lexeme L1c3: '+'; value="+"
Lexer "L0" registering character U+0020 as symbol 7: [\s]
Lexer "L0" registering character U+0020 as symbol 9: [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
Lexer "L0" registering character U+0031 '1' as symbol 6: [\d]
Lexer "L0" registering character U+0031 '1' as symbol 9: [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
Lexer "L0" discarded lexeme L1c4: whitespace
Lexer "L0" accepted lexeme L1c5: Number; value="1"
Lexer "L0" registering character U+0032 '2' as symbol 6: [\d]
Lexer "L0" registering character U+0032 '2' as symbol 9: [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
Lexer "L0" discarded lexeme L1c6: whitespace
Lexer "L0" accepted lexeme L1c7: Number; value="2"
Lexer "L0" registering character U+0033 '3' as symbol 6: [\d]
Lexer "L0" registering character U+0033 '3' as symbol 9: [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
Lexer "L0" discarded lexeme L1c8: whitespace
Lexer "L0" accepted lexeme L1c9: Number; value="3"
Lexer "L0" discarded lexeme L1c10: whitespace
Lexer "L0" accepted lexeme L1c11: '+'; value="+"
Lexer "L0" discarded lexeme L1c12: whitespace
Lexer "L0" accepted lexeme L1c13: '+'; value="+"
Lexer "L0" discarded lexeme L1c14: whitespace
Lexer "L0" accepted lexeme L1c15: Number; value="1"
Lexer "L0" discarded lexeme L1c16: whitespace
Lexer "L0" accepted lexeme L1c17: Number; value="2"
Lexer "L0" registering character U+0034 '4' as symbol 6: [\d]
Lexer "L0" registering character U+0034 '4' as symbol 9: [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
Lexer "L0" discarded lexeme L1c18: whitespace
Lexer "L0" accepted lexeme L1c19: Number; value="4"
END_OF_OUTPUT

    my $expected_progress_output = [
        [ 0, -1, 0 ],
        [ 1, -1, 0 ],
        [ 3, -1, 10 ],
        [ 4, -1, 0 ],
        [ 4, -1, 6 ],
        [ 4, -1, 10 ],
        [ 5, -1, 0 ],
        [ 0, 0,  0 ],
        [ 1, 0,  11 ],
        [ 2, 0,  11 ],
        [ 3, 0,  11 ],
        [ 4, 0,  11 ],
    ];

# Marpa::R2::Display
# name: Scanless progress() synopsis

    my $progress_output = $slr->progress();

# Marpa::R2::Display::End

    Marpa::R2::Test::is(
        Data::Dumper::Dumper($progress_output),
        Data::Dumper::Dumper($expected_progress_output),
        qq{Scanless progress()}
    );

    my $latest_g1_location = $slr->latest_g1_location();
    Test::More::is( $latest_g1_location, 11, qq{Scanless latest_g1_location()} );

# Marpa::R2::Display
# name: Scanless current_g1_location() synopsis

    my $current_g1_location = $slr->current_g1_location();

# Marpa::R2::Display::End

    Test::More::is( $current_g1_location, 11, qq{Scanless current_g1_location()} );

    # Test translation from G1 location to input stream spans
    my %location_seen = ();
    my @spans         = ();
    for my $g1_location (
        sort { $a <=> $b }
        grep { !$location_seen{$_}++; } map { $_->[-1] } @{$progress_output}
        )
    {

# Marpa::R2::Display
# name: Scanless g1_location_to_span() synopsis

        my ( $span_start, $span_length ) =
            $slr->g1_location_to_span($g1_location);

# Marpa::R2::Display::End

        push @spans, [ $g1_location, $span_start, $span_length ];
    } ## end for my $g1_location ( sort { $a <=> $b } grep { !$location_seen...})

    # One result for each unique G1 location in progress report
    # Format of each result is [g1_location, span_start, span_length]
    my $expected_spans =
        [ [ 0, 0, 0 ], [ 6, 8, 1 ], [ 10, 16, 1 ], [ 11, 18, 1 ] ];
    Test::More::is_deeply( \@spans, $expected_spans,
        qq{Scanless g1_location_to_span()} );

} ## end TEST: for my $test_data (@tests_data)

# vim: expandtab shiftwidth=4:
