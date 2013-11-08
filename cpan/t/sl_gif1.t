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

# Tests which require only a GIF combination-- a grammar (G),
# input (I), and an (F) ASF output, with no semantics

use 5.010;
use strict;
use warnings;

use Test::More tests => 22;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my @tests_data = ();

my $aaaa_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
    :start ::= quartet
    quartet ::= a a a a
    a ~ 'a'
END_OF_SOURCE
    }
);

push @tests_data, [
    $aaaa_grammar, 'aaaa',
    <<'END_OF_ASF',
GL2 Rule 1: quartet ::= a a a a
  GL3 Symbol a: "a"
  GL4 Symbol a: "a"
  GL5 Symbol a: "a"
  GL6 Symbol a: "a"
END_OF_ASF
    'ASF OK',
    'Basic "a a a a" grammar'
    ]
    if 1;

my $abcd_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
    :start ::= quartet
    quartet ::= a b c d
    a ~ 'a'
    b ~ 'b'
    c ~ 'c'
    d ~ 'd'
END_OF_SOURCE
    }
);

# Marpa::R2::Display
# name: ASF symch dump example grammar
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

my $venus_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:start ::= planet
planet ::= hesperus
planet ::= phosphorus
hesperus ::= venus
phosphorus ::= venus
venus ~ 'venus'
END_OF_SOURCE
    }
);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: ASF symch dump example output
# start-after-line: END_OF_OUTPUT
# end-before-line: '^END_OF_OUTPUT$'

push @tests_data, [
    $venus_grammar, 'venus',
    <<'END_OF_OUTPUT',
Symbol #0 planet has 2 symches
  Symch #0.0
  GL2 Rule 1: planet ::= hesperus
    GL3 Rule 3: hesperus ::= venus
      GL4 Symbol venus: "venus"
  Symch #0.1
  GL2 Rule 2: planet ::= phosphorus
    GL5 Rule 4: phosphorus ::= venus
      GL6 Symbol venus: "venus"
END_OF_OUTPUT
    'ASF OK',
    '"Hesperus is Phosphorus"" grammar'
    ]
    if 1;

# Marpa::R2::Display::End

push @tests_data, [
    $abcd_grammar, 'abcd',
    <<'END_OF_ASF',
GL2 Rule 1: quartet ::= a b c d
  GL3 Symbol a: "a"
  GL4 Symbol b: "b"
  GL5 Symbol c: "c"
  GL6 Symbol d: "d"
END_OF_ASF
    'ASF OK',
    'Basic "a b c d" grammar'
    ]
    if 1;

# Marpa::R2::Display
# name: ASF factoring dump example grammar
# start-after-line: END_OF_SOURCE
# end-before-line: '^END_OF_SOURCE$'

my $bb_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:start ::= top
top ::= b b
b ::= a a
b ::= a
a ~ 'a'
END_OF_SOURCE
    }
);

# Marpa::R2::Display::End

# Marpa::R2::Display
# name: ASF factoring dump example output
# start-after-line: END_OF_OUTPUT
# end-before-line: '^END_OF_OUTPUT$'

push @tests_data, [
    $bb_grammar, 'aaa',
    <<'END_OF_OUTPUT',
GL2 Rule 1: top ::= b b
  Factoring #0
    GL3 Rule 3: b ::= a
      GL4 Symbol a: "a"
    GL5 Rule 2: b ::= a a
      GL6 Symbol a: "a"
      GL7 Symbol a: "a"
  Factoring #1
    GL8 Rule 2: b ::= a a
      GL9 Symbol a: "a"
      GL10 Symbol a: "a"
    GL11 Rule 3: b ::= a
      GL12 Symbol a: "a"
END_OF_OUTPUT
    'ASF OK',
    '"b b" grammar'
    ]
    if 1;

# Marpa::R2::Display::End

my $seq_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:start ::= sequence
sequence ::= item+
item ::= pair | singleton
singleton ::= 'a'
pair ::= item item
END_OF_SOURCE
    }
);

push @tests_data, [
    $seq_grammar, 'aa',
    <<'END_OF_ASF',
GL2 Rule 1: sequence ::= item +
  Factoring #0
    GL3 Rule 2: item ::= pair
      GL4 Rule 5: pair ::= item item
        GL5 Rule 3: item ::= singleton
          GL6 Rule 4: singleton ::= 'a'
            GL7 Symbol 'a': "a"
        GL8 Rule 3: item ::= singleton
          GL9 Rule 4: singleton ::= 'a'
            GL10 Symbol 'a': "a"
  Factoring #1
    GL5 already displayed
    GL8 already displayed
END_OF_ASF
    'ASF OK',
    'Sequence grammar for "aa"'
    ]
    if 1;

push @tests_data, [
    $seq_grammar, 'aaa',
    <<'END_OF_ASF',
GL2 Rule 1: sequence ::= item +
  Factoring #0
    GL3 Rule 2: item ::= pair
      GL4 Rule 5: pair ::= item item
        Factoring #0.0
          GL5 Rule 2: item ::= pair
            GL6 Rule 5: pair ::= item item
              GL7 Rule 3: item ::= singleton
                GL8 Rule 4: singleton ::= 'a'
                  GL9 Symbol 'a': "a"
              GL10 Rule 3: item ::= singleton
                GL11 Rule 4: singleton ::= 'a'
                  GL12 Symbol 'a': "a"
          GL13 Rule 3: item ::= singleton
            GL14 Rule 4: singleton ::= 'a'
              GL15 Symbol 'a': "a"
        Factoring #0.1
          GL7 already displayed
          GL16 Rule 2: item ::= pair
            GL17 Rule 5: pair ::= item item
              GL10 already displayed
              GL13 already displayed
  Factoring #1
    GL5 already displayed
    GL13 already displayed
  Factoring #2
    GL7 already displayed
    GL10 already displayed
    GL13 already displayed
  Factoring #3
    GL7 already displayed
    GL16 already displayed
END_OF_ASF
    'ASF OK',
    'Sequence grammar for "aaa"'
    ]
    if 1;

my $venus_seq_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:start ::= sequence
sequence ::= item+
item ::= pair | Hesperus | Phosphorus
Hesperus ::= 'a'
Phosphorus ::= 'a'
pair ::= item item
END_OF_SOURCE
    }
);

push @tests_data, [
    $venus_seq_grammar, 'aa',
    <<'END_OF_ASF',
GL2 Rule 1: sequence ::= item +
  Factoring #0
    GL3 Rule 2: item ::= pair
      GL4 Rule 7: pair ::= item item
        Symbol #0 item has 2 symches
          Symch #0.0.0
          GL5 Rule 3: item ::= Hesperus
            GL6 Rule 5: Hesperus ::= 'a'
              GL7 Symbol 'a': "a"
          Symch #0.0.1
          GL5 Rule 4: item ::= Phosphorus
            GL8 Rule 6: Phosphorus ::= 'a'
              GL9 Symbol 'a': "a"
        Symbol #1 item has 2 symches
          Symch #0.1.0
          GL10 Rule 3: item ::= Hesperus
            GL11 Rule 5: Hesperus ::= 'a'
              GL12 Symbol 'a': "a"
          Symch #0.1.1
          GL10 Rule 4: item ::= Phosphorus
            GL13 Rule 6: Phosphorus ::= 'a'
              GL14 Symbol 'a': "a"
  Factoring #1
    GL5 already displayed
    GL10 already displayed
END_OF_ASF
    'ASF OK',
    'Sequence grammar for "aa"'
    ]
    if 1;

my $nulls_grammar = Marpa::R2::Scanless::G->new(
    {   source => \(<<'END_OF_SOURCE'),
:start ::= top
top ::= a a a a
a ::= 'a'
a ::=
END_OF_SOURCE
    }
);

push @tests_data, [
    $nulls_grammar, 'aaaa',
    <<'END_OF_ASF',
GL2 Rule 1: top ::= a a a a
  GL3 Rule 2: a ::= 'a'
    GL4 Symbol 'a': "a"
  GL5 Rule 2: a ::= 'a'
    GL6 Symbol 'a': "a"
  GL7 Rule 2: a ::= 'a'
    GL8 Symbol 'a': "a"
  GL9 Rule 2: a ::= 'a'
    GL10 Symbol 'a': "a"
END_OF_ASF
    'ASF OK',
    'Nulls grammar for "aaaa"'
    ]
    if 1;

push @tests_data, [
    $nulls_grammar, 'aaa',
    <<'END_OF_ASF',
GL2 Rule 1: top ::= a a a a
  Factoring #0
    GL3 Symbol a: ""
    GL4 Rule 2: a ::= 'a'
      GL5 Symbol 'a': "a"
    GL6 Rule 2: a ::= 'a'
      GL7 Symbol 'a': "a"
    GL8 Rule 2: a ::= 'a'
      GL9 Symbol 'a': "a"
  Factoring #1
    GL4 already displayed
    GL10 Symbol a: ""
    GL6 already displayed
    GL8 already displayed
  Factoring #2
    GL4 already displayed
    GL6 already displayed
    GL11 Symbol a: ""
    GL8 already displayed
  Factoring #3
    GL4 already displayed
    GL6 already displayed
    GL8 already displayed
    GL12 Symbol a: ""
END_OF_ASF
    'ASF OK',
    'Nulls grammar for "aaa"'
    ]
    if 1;

push @tests_data, [
    $nulls_grammar, 'aa',
    <<'END_OF_ASF',
GL2 Rule 1: top ::= a a a a
  Factoring #0
    GL3 Symbol a: ""
    GL4 Symbol a: ""
    GL5 Rule 2: a ::= 'a'
      GL6 Symbol 'a': "a"
    GL7 Rule 2: a ::= 'a'
      GL8 Symbol 'a': "a"
  Factoring #1
    GL3 already displayed
    GL5 already displayed
    GL9 Symbol a: ""
    GL7 already displayed
  Factoring #2
    GL3 already displayed
    GL5 already displayed
    GL7 already displayed
    GL10 Symbol a: ""
  Factoring #3
    GL5 already displayed
    GL7 already displayed
    GL11 Symbol a: ""
    GL12 Symbol a: ""
  Factoring #4
    GL5 already displayed
    GL13 Symbol a: ""
    GL9 already displayed
    GL7 already displayed
  Factoring #5
    GL5 already displayed
    GL13 already displayed
    GL7 already displayed
    GL10 already displayed
END_OF_ASF
    'ASF OK',
    'Nulls grammar for "aa"'
    ]
    if 1;

push @tests_data, [
    $nulls_grammar, 'a',
    <<'END_OF_ASF',
GL2 Rule 1: top ::= a a a a
  Factoring #0
    GL3 Rule 2: a ::= 'a'
      GL4 Symbol 'a': "a"
    GL5 Symbol a: ""
    GL6 Symbol a: ""
    GL7 Symbol a: ""
  Factoring #1
    GL8 Symbol a: ""
    GL3 already displayed
    GL9 Symbol a: ""
    GL10 Symbol a: ""
  Factoring #2
    GL8 already displayed
    GL11 Symbol a: ""
    GL12 Symbol a: ""
    GL3 already displayed
  Factoring #3
    GL8 already displayed
    GL11 already displayed
    GL3 already displayed
    GL13 Symbol a: ""
END_OF_ASF
    'ASF OK',
    'Nulls grammar for "a"'
    ]
    if 1;

TEST:
for my $test_data (@tests_data) {
    my ( $grammar, $test_string, $expected_value, $expected_result,
        $test_name )
        = @{$test_data};

    my ( $actual_value, $actual_result ) =
        my_parser( $grammar, $test_string );
    Marpa::R2::Test::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Test::More::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end TEST: for my $test_data (@tests_data)

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $slr = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

    if ( not defined eval { $slr->read( \$string ); 1 } ) {
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $slr->read( \$string ); 1 } )
    my $asf = Marpa::R2::ASF->new( { slr => $slr } );
    if ( not defined $asf ) {
        return 'No ASF', 'Input read to end but no ASF';
    }

    my $asf_desc = $asf->dump();
    return $asf_desc, 'ASF OK';

} ## end sub my_parser

# vim: expandtab shiftwidth=4:
