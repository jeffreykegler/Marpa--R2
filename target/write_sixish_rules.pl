#!perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
BEGIN { require './OP4.pm' }

my $OP_rules = Marpa::R2::Demo::OP4::parse_rules( <<'END_OF_RULES');
    <top> ::= <first rule> <more rules> :action<do_top>
    <first rule> ::= <short rule> :action<do_array>
    <more rules> ::= :action<do_empty_array>
    <short rule> ::= <rhs> :action<do_short_rule>
    <rhs> ::= <concatenation> :action<do_arg0>
    <concatenation> ::=
    <concatenation> ::= <concatenation> <opt ws> <quantified atom> :action<do_concatenation>
    <opt ws> ::= :action<do_undef>
    <opt ws> ::= <opt ws> <ws char> :action<do_undef>
    <quantified atom> ::= <atom> <opt ws> <quantifier> :action<do_quantification>
    <quantified atom> ::= <atom> :action<do_arg0>
    <atom> ::= <quoted literal> :action<do_arg0>
    <quoted literal> ::= <single quote> <single quoted char seq> <single quote>
      :action<do_arg1>
    <single quoted char seq> ::= <single quoted char>*
    <atom> ::= <self> :action<do_array>
    <self> ::= '<~~>' :action<do_self>
    <quantifier> ::= '*'
END_OF_RULES

say <<'END_OF_CODE';
package Marpa::R2::Sixish::Own_Rules;
END_OF_CODE

say Data::Dumper->Dump([$OP_rules], [qw(rules)]);

print <<'END_OF_CODE';
1;
END_OF_CODE

