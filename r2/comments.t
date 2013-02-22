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

# Read a file and print the C-style comments

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use GetOpt::Long;
use Test::More tests => 1;

use Marpa::R2 2.046000;

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME < file
    $PROGRAM_NAME --rand
END_OF_USAGE_MESSAGE
} ## end sub usage

my $random_flag = 0;
my $getopt_result = Getopt::Long::GetOptions( 'random!' => \$random_flag, );
usage() if not $getopt_result;
usage() if scalar @ARGV;

my $input;
if ($random_flag) {
    my @chars = map { substr "/*x ", int(rand(4)), 1 } 0 .. 80;
    $input = join "", @chars;
    say "Input: ", $input;
} else {
    $input = do { local $INPUT_RECORD_SEPARATOR = undef; <STDIN> };
}

my $rules = <<'END_OF_GRAMMAR';
:start ::= text
<text> ::= <well formed text>
<text> ::= <well formed text> (<unmatched comment start>)
<well formed text> ::= <text segment>* action => do_array
<text segment> ::= <C style comment> action => do_comment

:discard ~ <slash free text>
<slash free text> ~ [^/]+
<unmatched comment start> ~ '/*'
:discard ~ <any single character>
<any single character> ~ [\D\d]
<C style comment> ~ '/*' <comment interior> '*/'
<comment interior> ~
    <optional non stars>
    <optional star prefixed segments>
    <optional pre final stars>
<optional non stars> ~ [^*]*
<optional star prefixed segments> ~ <star prefixed segment>*
<star prefixed segment> ~ <stars> [^/*] <optional star free text>
<stars> ~ [*]+
<optional star free text> ~ [^*]*
<optional pre final stars> ~ [*]*
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Actions',
        default_action => 'do_dwim',
        source         => \$rules,
    }
);

sub calculate {
    my ($p_string) = @_;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar, } );
    my $self = bless { grammar => $grammar }, 'My_Actions';
    $self->{recce}        = $recce;
    local $My_Actions::SELF = $self;

    my $eval_result = eval { $recce->read($p_string); 1 };
    if ( not defined $eval_result ) {

        # Add last expression found, and rethrow
        my $eval_error = $EVAL_ERROR;
        say $EVAL_ERROR;
        chomp $eval_error;
        say $recce->show_progress();
        die $self->show_last('C style comment'), "\n", $eval_error, "\n";
    } ## end if ( not defined $eval_result )
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die $self->show_last('C style comment'), "\n",
            "No parse was found, after reading the entire input\n";
    }
    return ${$value_ref};

} ## end sub calculate

my $marpa_value = calculate(\$input);
if ( !defined $marpa_value ) {
    die 'NO PARSE!';
}
say Data::Dumper::Dumper(\$marpa_value);

my @regex_value = ($input =~ m/
  (?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/))
/gxms);

Test::More::is_deeply($marpa_value, \@regex_value, 'Compare Marpa to Regex');

package My_Actions;
our $SELF;
sub new { return $SELF }

sub do_comment {
    my ($self, $comment) = @_;
    return $comment;
}

sub do_array {
   shift;
   return [@_];
}

sub do_dwim {
   shift;
   my $rule_id = $Marpa::R2::Context::rule;
   my ($lhs) = $Marpa::R2::Context::grammar->rule($rule_id);
   # say STDERR "=== $lhs = ", join " ", @_;
   return undef if not scalar @_;
   return $_[0] if scalar @_ == 1;
   return \@_;
}

sub show_last {
    my ($self, $symbol) = @_;
    my $recce = $self->{recce};
    my ( $start, $end ) = $recce->last_completed_range($symbol);
    return 'No expression was successfully parsed' if not defined $start;
    my $last_expression = $recce->range_to_string( $start, $end );
    return "Last expression successfully parsed was: $last_expression";
} ## end sub show_last_expression

# vim: expandtab shiftwidth=4:
