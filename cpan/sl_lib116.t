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

# Dave Abrahams Libmarpa issue 116
# "Infinite loop in marpa_t_next"

use 5.010001;
use strict;
use warnings;
use Scalar::Util;
use Data::Dumper;
use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $bnfOfBNF = <<'END_OF_BNF_OF_BNF';
:default ::= action => [values]
lexeme default = latm => 1

Rules ::= Rule*
Rule  ::= Symbol '::=' SymbolList action => do_rule
SymbolList ::= Symbol*

# Factor ::= Number action => ::first
# Term ::=
#     Term '*' Factor action => do_multiply
#     | Factor action => ::first
# Expression ::=
#     Expression '+' Term action => do_add
#     | Term action => ::first

:discard ~ whitespace
whitespace ~ [\s]+
Symbol ~ PieceList
PieceList ~ Piece
PieceList ~ PieceList '-' Piece
Piece ~ QuotedPiece
Piece ~ NormalPiece
NormalPiece ~ [0-9A-Za-z_]+
QuotedPiece ~ Quote QuoteInterior Quote
Quote ~ [']
QuoteInterior ~ [^\s']*
END_OF_BNF_OF_BNF

sub My_Actions::do_rule {
    my ( undef, $t1, undef, $t2 ) = @_;
    return [$t1, @{$t2}];
}

my $bnf = <<'EOBNF';
access-modifier ::= 'public'
associated-decl ::= associated-type-decl
associated-decl ::= associated-size-decl
where-clause-opt ::=
where-clause-opt ::= where-clause
associated-size-decl_1 ::= '=' whitespace-opt expr
associated-size-decl_1-opt ::=
associated-size-decl_1-opt ::= associated-size-decl_1
associated-size-decl ::= associated-size-head whitespace-opt where-clause-opt whitespace-opt associated-size-decl_1-opt
associated-size-head ::= 'size' whitespace-opt identifier
associated-type-constraints ::= conformance-list
conformance-list-opt ::=
conformance-list-opt ::= conformance-list
associated-type-constraints ::= conformance-list-opt whitespace-opt where-clause
associated-type-constraints-opt ::=
associated-type-constraints-opt ::= associated-type-constraints
associated-type-decl_1 ::= '=' whitespace-opt type-expr
associated-type-decl_1-opt ::=
associated-type-decl_1-opt ::= associated-type-decl_1
associated-type-decl ::= associated-type-head whitespace-opt associated-type-constraints-opt whitespace-opt associated-type-decl_1-opt
associated-type-head ::= 'type' whitespace-opt identifier
async-type-expr ::= 'async' whitespace-opt type-expr
binding-annotation ::= ':' whitespace-opt type-expr
binding-initializer-opt ::=
binding-initializer-opt ::= binding-initializer
binding-decl ::= binding-head whitespace-opt binding-initializer-opt
access-modifier-opt ::=
access-modifier-opt ::= access-modifier
member-modifier-list ::=
member-modifier-list ::= member-modifier-list whitespace-opt member-modifier
binding-head ::= access-modifier-opt whitespace-opt member-modifier-list whitespace-opt binding-pattern
binding-initializer ::= '=' whitespace-opt expr
binding-introducer ::= 'let'
binding-introducer ::= 'var'
binding-introducer ::= 'sink'
binding-introducer ::= 'inout'
binding-pattern_1 ::= tuple-pattern
binding-pattern_1 ::= wildcard-pattern
binding-pattern_1 ::= identifier
binding-annotation-opt ::=
binding-annotation-opt ::= binding-annotation
binding-pattern ::= binding-introducer whitespace-opt binding-pattern_1 whitespace-opt binding-annotation-opt
block-comment ::= block-comment-open '*/'
block-comment ::= block-comment-open block-comment '*/'
boolean-literal ::= 'true'
boolean-literal ::= 'false'
stmt-list-opt ::=
stmt-list-opt ::= stmt-list
brace-stmt ::= '{' whitespace-opt stmt-list-opt whitespace-opt '}'
buffer-component-list_1 ::= ',' whitespace-opt expr
buffer-component-list_1-list ::=
buffer-component-list_1-list ::= buffer-component-list_1-list whitespace-opt buffer-component-list_1
','-opt ::=
','-opt ::= ','
buffer-component-list ::= expr whitespace-opt buffer-component-list_1-list whitespace-opt ','-opt
buffer-component-list-opt ::=
buffer-component-list-opt ::= buffer-component-list
buffer-literal ::= '[' whitespace-opt buffer-component-list-opt whitespace-opt ']'
expr-opt ::=
expr-opt ::= expr
buffer-type-expr ::= type-expr whitespace-opt '[' whitespace-opt expr-opt whitespace-opt ']'
call-argument_1 ::= identifier whitespace-opt ':'
call-argument_1-opt ::=
call-argument_1-opt ::= call-argument_1
call-argument ::= call-argument_1-opt whitespace-opt expr
call-argument-list_1 ::= ',' whitespace-opt call-argument
call-argument-list_1-list ::=
call-argument-list_1-list ::= call-argument-list_1-list whitespace-opt call-argument-list_1
call-argument-list ::= call-argument whitespace-opt call-argument-list_1-list
capture-list_1 ::= ',' whitespace-opt binding-decl
capture-list_1-list ::=
capture-list_1-list ::= capture-list_1-list whitespace-opt capture-list_1
capture-list ::= '[' whitespace-opt binding-decl whitespace-opt capture-list_1-list whitespace-opt ']'
compound-expr ::= value-member-expr
compound-expr ::= function-call-expr
compound-expr ::= subscript-call-expr
compound-expr ::= primary-expr
compound-literal ::= buffer-literal
compound-literal ::= map-literal
cond-binding-body ::= jump-stmt
cond-binding-body ::= expr
cond-binding-stmt ::= binding-pattern whitespace-opt '??' whitespace-opt cond-binding-body
conditional-clause_1 ::= ',' whitespace-opt conditional-clause-item
conditional-clause_1-list ::=
conditional-clause_1-list ::= conditional-clause_1-list whitespace-opt conditional-clause_1
conditional-clause ::= conditional-clause-item whitespace-opt conditional-clause_1-list
conditional-clause-item ::= binding-pattern whitespace-opt '=' whitespace-opt expr
conditional-clause-item ::= expr
conditional-tail-opt ::=
conditional-tail-opt ::= conditional-tail
conditional-expr ::= 'if' whitespace-opt conditional-clause whitespace-opt brace-stmt whitespace-opt conditional-tail-opt
conditional-tail ::= 'else' whitespace-opt conditional-expr
conditional-tail ::= 'else' whitespace-opt brace-stmt
conformance-body_1 ::= conformance-member-decl
conformance-body_1 ::= ';'
conformance-body_1-list ::=
conformance-body_1-list ::= conformance-body_1-list whitespace-opt conformance-body_1
conformance-body ::= '{' whitespace-opt conformance-body_1-list whitespace-opt '}'
conformance-constraint ::= name-type-expr whitespace-opt ':' whitespace-opt trait-composition
conformance-decl ::= conformance-head whitespace-opt conformance-body
access-modifier-opt_1 ::=
access-modifier-opt_1 ::= access-modifier
where-clause-opt_1 ::=
where-clause-opt_1 ::= where-clause
conformance-head ::= access-modifier-opt_1 whitespace-opt 'conformance' whitespace-opt type-expr whitespace-opt conformance-list whitespace-opt where-clause-opt_1
conformance-lens-type-expr ::= type-expr whitespace-opt '::' whitespace-opt type-identifier
conformance-list_1 ::= ',' whitespace-opt name-type-expr
conformance-list_1-list ::=
conformance-list_1-list ::= conformance-list_1-list whitespace-opt conformance-list_1
conformance-list ::= ':' whitespace-opt name-type-expr whitespace-opt conformance-list_1-list
conformance-member-decl ::= function-decl
conformance-member-decl ::= subscript-decl
conformance-member-decl ::= product-type-decl
conformance-member-decl ::= type-alias-decl
contextual-keyword ::= 'mutating'
contextual-keyword ::= 'size'
contextual-keyword ::= 'any'
contextual-keyword ::= 'in'
decl-stmt ::= type-alias-decl
decl-stmt ::= product-type-decl
decl-stmt ::= extension-decl
decl-stmt ::= conformance-decl
decl-stmt ::= function-decl
decl-stmt ::= subscript-decl
decl-stmt ::= binding-decl
default-value ::= '=' whitespace-opt expr
do-while-stmt ::= 'do' whitespace-opt brace-stmt whitespace-opt 'while' whitespace-opt expr
entity-identifier ::= identifier
entity-identifier ::= function-entity-identifier
entity-identifier ::= operator-entity-identifier
equality-constraint ::= name-type-expr whitespace-opt '==' whitespace-opt type-expr
where-clause-opt_2 ::=
where-clause-opt_2 ::= where-clause
existential-type-expr ::= 'any' whitespace-opt trait-composition whitespace-opt where-clause-opt_2
infix-tail-opt ::=
infix-tail-opt ::= infix-tail
expr ::= prefix-expr whitespace-opt infix-tail-opt
expr-pattern ::= expr
extension-body_1 ::= extension-member-decl
extension-body_1 ::= ';'
extension-body_1-list ::=
extension-body_1-list ::= extension-body_1-list whitespace-opt extension-body_1
extension-body ::= '{' whitespace-opt extension-body_1-list whitespace-opt '}'
extension-decl ::= extension-head whitespace-opt extension-body
access-modifier-opt_2 ::=
access-modifier-opt_2 ::= access-modifier
where-clause-opt_3 ::=
where-clause-opt_3 ::= where-clause
extension-head ::= access-modifier-opt_2 whitespace-opt 'extension' whitespace-opt type-expr whitespace-opt where-clause-opt_3
extension-member-decl ::= function-decl
extension-member-decl ::= subscript-decl
extension-member-decl ::= product-type-decl
extension-member-decl ::= type-alias-decl
floating-point-literal ::= decimal-floating-point-literal
for-counter-decl ::= pattern
for-range ::= 'in' whitespace-opt expr
loop-filter-opt ::=
loop-filter-opt ::= loop-filter
for-stmt ::= 'for' whitespace-opt for-counter-decl whitespace-opt for-range whitespace-opt loop-filter-opt whitespace-opt brace-stmt
function-body ::= function-bundle-body
function-body ::= brace-stmt
method-impl-list ::= method-impl
method-impl-list ::= method-impl-list whitespace-opt method-impl
function-bundle-body ::= '{' whitespace-opt method-impl-list whitespace-opt '}'
call-argument-list-opt ::=
call-argument-list-opt ::= call-argument-list
function-call-expr ::= expr whitespace-opt '(' whitespace-opt call-argument-list-opt whitespace-opt ')'
function-decl ::= memberwise-ctor-decl
function-body-opt ::=
function-body-opt ::= function-body
function-decl ::= function-head whitespace-opt function-signature whitespace-opt function-body-opt
access-modifier-opt_3 ::=
access-modifier-opt_3 ::= access-modifier
member-modifier-list_1 ::=
member-modifier-list_1 ::= member-modifier-list_1 whitespace-opt member-modifier
generic-clause-opt ::=
generic-clause-opt ::= generic-clause
capture-list-opt ::=
capture-list-opt ::= capture-list
function-head ::= access-modifier-opt_3 whitespace-opt member-modifier-list_1 whitespace-opt function-identifier whitespace-opt generic-clause-opt whitespace-opt capture-list-opt
function-identifier ::= 'init'
function-identifier ::= 'deinit'
function-identifier ::= 'fun' whitespace-opt identifier
function-identifier ::= operator-notation whitespace-opt 'fun' whitespace-opt operator
parameter-list-opt ::=
parameter-list-opt ::= parameter-list
function-signature_1 ::= '->' whitespace-opt type-expr
function-signature_1-opt ::=
function-signature_1-opt ::= function-signature_1
function-signature ::= '(' whitespace-opt parameter-list-opt whitespace-opt ')' whitespace-opt function-signature_1-opt
generic-clause_1 ::= ',' whitespace-opt generic-parameter
generic-clause_1-list ::=
generic-clause_1-list ::= generic-clause_1-list whitespace-opt generic-clause_1
where-clause-opt_4 ::=
where-clause-opt_4 ::= where-clause
generic-clause ::= '<' whitespace-opt generic-parameter whitespace-opt generic-clause_1-list whitespace-opt where-clause-opt_4 whitespace-opt '>'
generic-parameter ::= generic-type-parameter
generic-parameter ::= generic-size-parameter
generic-size-parameter ::= identifier whitespace-opt ':' whitespace-opt 'size'
'...'-opt ::=
'...'-opt ::= '...'
trait-annotation-opt ::=
trait-annotation-opt ::= trait-annotation
generic-type-parameter ::= identifier whitespace-opt '...'-opt whitespace-opt trait-annotation-opt
horizontal-space ::= hspace
horizontal-space ::= single-line-comment
horizontal-space ::= block-comment
horizontal-space-list ::=
horizontal-space-list ::= horizontal-space-list horizontal-space
horizontal-space-opt ::= horizontal-space-list
identifier ::= identifier-token
identifier ::= contextual-keyword
impl-identifier-opt ::=
impl-identifier-opt ::= impl-identifier
identifier-expr ::= entity-identifier whitespace-opt impl-identifier-opt
implicit-member-ref ::= '.' whitespace-opt primary-decl-ref
import-statement ::= 'import' whitespace-opt identifier
indirect-type-expr ::= 'indirect' whitespace-opt type-expr
infix-item ::= infix-operator whitespace-opt prefix-expr
infix-item ::= type-casting-operator whitespace-opt type-expr
infix-operator ::= operator
infix-operator ::= '='
infix-operator ::= '=='
infix-operator ::= '<'
infix-operator ::= '>'
infix-operator ::= '..<'
infix-operator ::= '...'
infix-item-list ::= infix-item
infix-item-list ::= infix-item-list whitespace-opt infix-item
infix-tail ::= infix-item-list
integer-literal ::= binary-literal
integer-literal ::= octal-literal
integer-literal ::= decimal-literal
integer-literal ::= hexadecimal-literal
jump-stmt ::= cond-binding-stmt
expr-opt_1 ::=
expr-opt_1 ::= expr
jump-stmt ::= 'return' horizontal-space-opt expr-opt_1
jump-stmt ::= 'yield' horizontal-space-opt expr
jump-stmt ::= 'break'
jump-stmt ::= 'continue'
lambda-body ::= brace-stmt
lambda-environment ::= '[' whitespace-opt type-expr whitespace-opt ']'
capture-list-opt_1 ::=
capture-list-opt_1 ::= capture-list
lambda-expr ::= 'fun' whitespace-opt capture-list-opt_1 whitespace-opt function-signature whitespace-opt lambda-body
call-argument_1-opt_1 ::=
call-argument_1-opt_1 ::= call-argument_1
lambda-parameter ::= call-argument_1-opt_1 whitespace-opt type-expr
lambda-receiver-effect ::= 'inout'
lambda-receiver-effect ::= 'sink'
lambda-environment-opt ::=
lambda-environment-opt ::= lambda-environment
lamda-parameter-list-opt ::=
lamda-parameter-list-opt ::= lamda-parameter-list
lambda-receiver-effect-opt ::=
lambda-receiver-effect-opt ::= lambda-receiver-effect
lambda-type-expr ::= lambda-environment-opt whitespace-opt '(' whitespace-opt lamda-parameter-list-opt whitespace-opt ')' whitespace-opt lambda-receiver-effect-opt whitespace-opt '->' whitespace-opt type-expr
lamda-parameter-list_1 ::= ',' whitespace-opt lambda-parameter
lamda-parameter-list_1-list ::=
lamda-parameter-list_1-list ::= lamda-parameter-list_1-list whitespace-opt lamda-parameter-list_1
lamda-parameter-list ::= lambda-parameter whitespace-opt lamda-parameter-list_1-list
loop-filter ::= 'where' whitespace-opt expr
loop-stmt ::= do-while-stmt
loop-stmt ::= while-stmt
loop-stmt ::= for-stmt
map-component ::= expr whitespace-opt ':' whitespace-opt expr
map-component-list_1 ::= ',' whitespace-opt map-component
map-component-list_1-list ::=
map-component-list_1-list ::= map-component-list_1-list whitespace-opt map-component-list_1
','-opt_1 ::=
','-opt_1 ::= ','
map-component-list ::= map-component whitespace-opt map-component-list_1-list whitespace-opt ','-opt_1
map-literal ::= '[' whitespace-opt map-component-list whitespace-opt ']'
map-literal ::= '[' whitespace-opt ':' whitespace-opt ']'
match-case ::= pattern whitespace-opt brace-stmt
match-expr_1 ::= match-case
match-expr_1 ::= ';'
match-expr_1-list ::=
match-expr_1-list ::= match-expr_1-list whitespace-opt match-expr_1
match-expr ::= 'match' whitespace-opt expr whitespace-opt '{' whitespace-opt match-expr_1-list whitespace-opt '}'
member-modifier ::= receiver-modifier
member-modifier ::= static-modifier
memberwise-ctor-decl ::= 'memberwise' whitespace-opt 'init'
brace-stmt-opt ::=
brace-stmt-opt ::= brace-stmt
method-impl ::= method-introducer whitespace-opt brace-stmt-opt
method-introducer ::= 'let'
method-introducer ::= 'sink'
method-introducer ::= 'inout'
module-definition_1 ::= module-scope-decl
module-definition_1 ::= import-statement
module-definition_1-list ::=
module-definition_1-list ::= module-definition_1-list whitespace-opt module-definition_1
module-definition ::= whitespace-opt whitespace-opt module-definition_1-list whitespace-opt whitespace-opt
module-scope-decl ::= namespace-decl
module-scope-decl ::= trait-decl
module-scope-decl ::= type-alias-decl
module-scope-decl ::= product-type-decl
module-scope-decl ::= extension-decl
module-scope-decl ::= conformance-decl
module-scope-decl ::= binding-decl
module-scope-decl ::= function-decl
module-scope-decl ::= subscript-decl
name-type-expr_1 ::= type-expr whitespace-opt '.'
name-type-expr_1-opt ::=
name-type-expr_1-opt ::= name-type-expr_1
type-argument-list-opt ::=
type-argument-list-opt ::= type-argument-list
name-type-expr ::= name-type-expr_1-opt whitespace-opt type-identifier whitespace-opt type-argument-list-opt
module-scope-decl-list ::=
module-scope-decl-list ::= module-scope-decl-list whitespace-opt module-scope-decl
namespace-body ::= '{' whitespace-opt module-scope-decl-list whitespace-opt '}'
namespace-decl ::= namespace-head whitespace-opt namespace-body
access-modifier-opt_4 ::=
access-modifier-opt_4 ::= access-modifier
namespace-head ::= access-modifier-opt_4 whitespace-opt 'namespace' whitespace-opt identifier
where-clause-opt_5 ::=
where-clause-opt_5 ::= where-clause
opaque-type-expr ::= 'some' whitespace-opt trait-composition whitespace-opt where-clause-opt_5
opaque-type-expr ::= 'some' whitespace-opt '_'
operator-notation ::= 'infix'
operator-notation ::= 'prefix'
operator-notation ::= 'postfix'
parameter-decl_1 ::= identifier
parameter-decl_1 ::= '_'
identifier-opt ::=
identifier-opt ::= identifier
parameter-decl_2 ::= ':' whitespace-opt parameter-type-expr
parameter-decl_2-opt ::=
parameter-decl_2-opt ::= parameter-decl_2
default-value-opt ::=
default-value-opt ::= default-value
parameter-decl ::= parameter-decl_1 whitespace-opt identifier-opt whitespace-opt parameter-decl_2-opt whitespace-opt default-value-opt
parameter-list_1 ::= ',' whitespace-opt parameter-decl
parameter-list_1-list ::=
parameter-list_1-list ::= parameter-list_1-list whitespace-opt parameter-list_1
parameter-list ::= parameter-decl whitespace-opt parameter-list_1-list
parameter-passing-convention ::= 'let'
parameter-passing-convention ::= 'inout'
parameter-passing-convention ::= 'sink'
parameter-passing-convention ::= 'yielded'
parameter-passing-convention-opt ::=
parameter-passing-convention-opt ::= parameter-passing-convention
parameter-type-expr ::= parameter-passing-convention-opt whitespace-opt type-expr
pattern ::= binding-pattern
pattern ::= expr-pattern
pattern ::= tuple-pattern
pattern ::= wildcard-pattern
prefix-operator-opt ::=
prefix-operator-opt ::= prefix-operator
prefix-expr ::= prefix-operator-opt suffix-expr
prefix-operator ::= operator
prefix-operator ::= 'async'
prefix-operator ::= 'await'
prefix-operator ::= '&'
type-argument-list-opt_1 ::=
type-argument-list-opt_1 ::= type-argument-list
primary-decl-ref ::= identifier-expr whitespace-opt type-argument-list-opt_1
primary-expr ::= scalar-literal
primary-expr ::= compound-literal
primary-expr ::= primary-decl-ref
primary-expr ::= implicit-member-ref
primary-expr ::= lambda-expr
primary-expr ::= selection-expr
primary-expr ::= tuple-expr
primary-expr ::= 'nil'
primary-expr ::= '_'
product-type-body_1 ::= product-type-member-decl
product-type-body_1 ::= ';'
product-type-body_1-list ::=
product-type-body_1-list ::= product-type-body_1-list whitespace-opt product-type-body_1
product-type-body ::= '{' whitespace-opt product-type-body_1-list whitespace-opt '}'
product-type-decl ::= product-type-head whitespace-opt product-type-body
access-modifier-opt_5 ::=
access-modifier-opt_5 ::= access-modifier
generic-clause-opt_1 ::=
generic-clause-opt_1 ::= generic-clause
conformance-list-opt_1 ::=
conformance-list-opt_1 ::= conformance-list
product-type-head ::= access-modifier-opt_5 whitespace-opt 'type' whitespace-opt identifier whitespace-opt generic-clause-opt_1 whitespace-opt conformance-list-opt_1
product-type-member-decl ::= function-decl
product-type-member-decl ::= subscript-decl
product-type-member-decl ::= property-decl
product-type-member-decl ::= binding-decl
product-type-member-decl ::= product-type-decl
product-type-member-decl ::= type-alias-decl
property-annotation ::= ':' whitespace-opt type-expr
property-decl ::= property-head whitespace-opt property-annotation whitespace-opt subscript-body
member-modifier-list_2 ::=
member-modifier-list_2 ::= member-modifier-list_2 whitespace-opt member-modifier
property-head ::= member-modifier-list_2 whitespace-opt 'property' whitespace-opt identifier
receiver-modifier ::= 'sink'
receiver-modifier ::= 'inout'
receiver-modifier ::= 'yielded'
scalar-literal ::= boolean-literal
scalar-literal ::= integer-literal
scalar-literal ::= floating-point-literal
scalar-literal ::= string-literal
scalar-literal ::= unicode-scalar-literal
selection-expr ::= conditional-expr
selection-expr ::= match-expr
size-constraint-expr ::= expr
static-modifier ::= 'static'
stmt ::= brace-stmt
stmt ::= loop-stmt
stmt ::= jump-stmt
stmt ::= decl-stmt
stmt ::= expr
stmt-list ::= stmt
stmt-list ::= stmt-list stmt-separator stmt
stmt-separator_1 ::= newlines horizontal-space-opt
stmt-separator_1-list ::=
stmt-separator_1-list ::= stmt-separator_1-list stmt-separator_1
stmt-separator ::= horizontal-space-opt stmt-separator_1-list
stmt-separator_2 ::= ';' whitespace-opt
stmt-separator_2-list ::=
stmt-separator_2-list ::= stmt-separator_2-list stmt-separator_2
stmt-separator ::= whitespace-opt stmt-separator_2-list
stored-projection-capability ::= 'let'
stored-projection-capability ::= 'inout'
stored-projection-capability ::= 'yielded'
stored-projection-type-expr ::= '[' whitespace-opt stored-projection-capability whitespace-opt type-expr whitespace-opt ']'
string-literal ::= simple-string
string-literal ::= multiline-string
subscript-body ::= brace-stmt
subscript-impl-list ::= subscript-impl
subscript-impl-list ::= subscript-impl-list whitespace-opt subscript-impl
subscript-body ::= '{' whitespace-opt subscript-impl-list whitespace-opt '}'
call-argument-list-opt_1 ::=
call-argument-list-opt_1 ::= call-argument-list
subscript-call-expr ::= expr whitespace-opt '[' whitespace-opt call-argument-list-opt_1 whitespace-opt ']'
subscript-decl ::= subscript-head whitespace-opt subscript-signature whitespace-opt subscript-body
member-modifier-list_3 ::=
member-modifier-list_3 ::= member-modifier-list_3 whitespace-opt member-modifier
subscript-identifier-opt ::=
subscript-identifier-opt ::= subscript-identifier
generic-clause-opt_2 ::=
generic-clause-opt_2 ::= generic-clause
capture-list-opt_2 ::=
capture-list-opt_2 ::= capture-list
subscript-head ::= member-modifier-list_3 whitespace-opt subscript-identifier-opt whitespace-opt generic-clause-opt_2 whitespace-opt capture-list-opt_2
subscript-identifier ::= 'subscript' whitespace-opt identifier
subscript-identifier ::= operator-notation whitespace-opt 'subscript' whitespace-opt operator
brace-stmt-opt_1 ::=
brace-stmt-opt_1 ::= brace-stmt
subscript-impl ::= subscript-introducer whitespace-opt brace-stmt-opt_1
subscript-introducer ::= 'let'
subscript-introducer ::= 'sink'
subscript-introducer ::= 'inout'
subscript-introducer ::= 'set'
parameter-list-opt_1 ::=
parameter-list-opt_1 ::= parameter-list
'var'-opt ::=
'var'-opt ::= 'var'
subscript-signature ::= '(' whitespace-opt parameter-list-opt_1 whitespace-opt ')' whitespace-opt ':' whitespace-opt 'var'-opt whitespace-opt type-expr
suffix-expr ::= compound-expr
suffix-expr ::= suffix-expr operator
trait-annotation ::= ':' whitespace-opt trait-composition
trait-body_1 ::= trait-requirement-decl
trait-body_1 ::= ';'
trait-body_1-list ::=
trait-body_1-list ::= trait-body_1-list whitespace-opt trait-body_1
trait-body ::= '{' whitespace-opt trait-body_1-list whitespace-opt '}'
trait-composition_1 ::= '&' whitespace-opt name-type-expr
trait-composition_1-list ::= trait-composition_1-list whitespace-opt trait-composition_1
trait-composition ::= name-type-expr whitespace-opt trait-composition_1-list
trait-decl ::= trait-head whitespace-opt trait-body
access-modifier-opt_6 ::=
access-modifier-opt_6 ::= access-modifier
trait-refinement-list-opt ::=
trait-refinement-list-opt ::= trait-refinement-list
trait-head ::= access-modifier-opt_6 whitespace-opt 'trait' whitespace-opt identifier whitespace-opt trait-refinement-list-opt
conformance-list_1-list_1 ::=
conformance-list_1-list_1 ::= conformance-list_1-list_1 whitespace-opt conformance-list_1
trait-refinement-list ::= ':' whitespace-opt name-type-expr whitespace-opt conformance-list_1-list_1
trait-requirement-decl ::= associated-decl
trait-requirement-decl ::= function-decl
trait-requirement-decl ::= subscript-decl
trait-requirement-decl ::= property-decl
tuple-expr ::= '(' whitespace-opt tuple-expr-element-list whitespace-opt ')'
call-argument_1-opt_2 ::=
call-argument_1-opt_2 ::= call-argument_1
tuple-expr-element ::= call-argument_1-opt_2 whitespace-opt expr
tuple-expr-element-list_1 ::= ',' whitespace-opt tuple-expr-element
tuple-expr-element-list_1-opt ::=
tuple-expr-element-list_1-opt ::= tuple-expr-element-list_1
tuple-expr-element-list ::= tuple-expr-element whitespace-opt tuple-expr-element-list_1-opt
tuple-pattern ::= '(' whitespace-opt tuple-pattern-element-list whitespace-opt ')'
call-argument_1-opt_3 ::=
call-argument_1-opt_3 ::= call-argument_1
tuple-pattern-element ::= call-argument_1-opt_3 whitespace-opt pattern
tuple-pattern-element-list_1 ::= ',' whitespace-opt tuple-pattern-element
tuple-pattern-element-list_1-opt ::=
tuple-pattern-element-list_1-opt ::= tuple-pattern-element-list_1
tuple-pattern-element-list ::= tuple-pattern-element whitespace-opt tuple-pattern-element-list_1-opt
call-argument_1-opt_4 ::=
call-argument_1-opt_4 ::= call-argument_1
tuple-type-element ::= call-argument_1-opt_4 whitespace-opt type-expr
tuple-type-element-list_1 ::= ',' whitespace-opt tuple-type-element
tuple-type-element-list_1-opt ::=
tuple-type-element-list_1-opt ::= tuple-type-element-list_1
tuple-type-element-list ::= tuple-type-element whitespace-opt tuple-type-element-list_1-opt
tuple-type-expr ::= '(' whitespace-opt tuple-type-element-list whitespace-opt ')'
type-alias-body ::= '=' whitespace-opt type-expr
type-alias-body ::= '=' whitespace-opt union-decl
type-alias-decl ::= type-alias-head whitespace-opt type-alias-body
access-modifier-opt_7 ::=
access-modifier-opt_7 ::= access-modifier
generic-clause-opt_3 ::=
generic-clause-opt_3 ::= generic-clause
type-alias-head ::= access-modifier-opt_7 whitespace-opt 'typealias' whitespace-opt identifier whitespace-opt generic-clause-opt_3
call-argument_1-opt_5 ::=
call-argument_1-opt_5 ::= call-argument_1
type-argument ::= call-argument_1-opt_5 whitespace-opt type-expr
type-argument-list_1 ::= ',' whitespace-opt type-argument
type-argument-list_1-list ::=
type-argument-list_1-list ::= type-argument-list_1-list whitespace-opt type-argument-list_1
type-argument-list ::= '<' whitespace-opt type-argument whitespace-opt type-argument-list_1-list whitespace-opt '>'
type-casting-operator ::= 'as'
type-casting-operator ::= 'as!'
type-casting-operator ::= '_as!!'
type-expr ::= async-type-expr
type-expr ::= buffer-type-expr
type-expr ::= conformance-lens-type-expr
type-expr ::= existential-type-expr
type-expr ::= opaque-type-expr
type-expr ::= indirect-type-expr
type-expr ::= lambda-type-expr
type-expr ::= name-type-expr
type-expr ::= stored-projection-type-expr
type-expr ::= tuple-type-expr
type-expr ::= union-type-expr
type-expr ::= wildcard-type-expr
type-identifier ::= identifier
union-decl_1 ::= '|' whitespace-opt product-type-decl
union-decl_1-list ::=
union-decl_1-list ::= union-decl_1-list whitespace-opt union-decl_1
union-decl ::= product-type-decl whitespace-opt union-decl_1-list
union-type-expr_1 ::= '|' whitespace-opt type-expr
union-type-expr_1-list ::= union-type-expr_1
union-type-expr_1-list ::= union-type-expr_1-list whitespace-opt union-type-expr_1
union-type-expr ::= type-expr whitespace-opt union-type-expr_1-list
value-member-expr ::= expr whitespace-opt '.' whitespace-opt primary-decl-ref
value-member-expr ::= type-expr whitespace-opt '.' whitespace-opt primary-decl-ref
where-clause ::= 'where' whitespace-opt where-clause-constraint
where-clause-constraint ::= equality-constraint
where-clause-constraint ::= conformance-constraint
where-clause-constraint ::= size-constraint-expr
while-condition-item ::= binding-pattern whitespace-opt '=' whitespace-opt expr
while-condition-item ::= expr
while-condition-list_1 ::= ',' whitespace-opt while-condition-item
while-condition-list_1-list ::=
while-condition-list_1-list ::= while-condition-list_1-list whitespace-opt while-condition-list_1
while-condition-list ::= while-condition-item whitespace-opt while-condition-list_1-list
while-stmt ::= 'while' whitespace-opt while-condition-list whitespace-opt brace-stmt
whitespace-opt_1 ::= horizontal-space
whitespace-opt_1 ::= newlines
whitespace-opt_1-list ::=
whitespace-opt_1-list ::= whitespace-opt_1-list whitespace-opt_1
whitespace-opt ::= whitespace-opt_1-list
wildcard-pattern ::= '_'
wildcard-type-expr ::= '_'
EOBNF

my $BnfGrammar = Marpa::R2::Scanless::G->new( { source => \$bnfOfBNF } );
my $bnfValueRef = $BnfGrammar->parse( \$bnf, 'My_Actions' );

# say STDERR Data::Dumper::Dumper( \$bnfValueRef );

my @source = ();
push @source, <<'END_OF_SOURCE';
:default ::= action => main::dwim
:start ::= module_x2d_definition 
unicorn ~ [^\d\D]
END_OF_SOURCE

my @terminals = ();
my %R2name = ();
my %DAname = ();
{
   my @DAsyms = ();
   my $DArules = $$bnfValueRef;
   push @DAsyms, @{$_} for @{$DArules};
   DA_SYM: for my $DAsym (@DAsyms) {
      next DA_SYM if defined $R2name{$DAsym};
      my $r2name = $DAsym;
      $r2name =~ s/([^0-9A-Za-z])/sprintf("_x%02x_", ord($1) )/ge;
      die "Duplicate R2 name: $r2name for both $DAsym and ", $DAname{$r2name}
          if defined $DAname{$r2name};
      push @terminals, $r2name if $DAsym =~ /^'.*'$/;
      $DAname{$r2name} = $DAsym;
      $R2name{$DAsym} = $r2name;
   }

   for my $rule (@{$DArules}) {
      my ($lhs, @rhs) = @{$rule};
      my $rule =  join " ", $R2name{$lhs}, q{::=}, (map {$R2name{$_}} @rhs);
      # say STDERR "Adding rule: $rule";
      $rule .= "\n";
      push @source, $rule;
   }
}

# say STDERR Data::Dumper::Dumper( \%R2name );

# The start byte locations are from vim, and are 1-based,
# while Marpa is 0-based
my @input = (
     [ 'DUMMY', 'DUMMY', 0, 1 ], # Avoid use of zero location
     [ q{'type'}, "'type'", 5, 4  ],
     [ 'hspace', 'hspace', 9, 1 ],
     [ 'identifier-token', 'A', 10, 1 ],
     [ 'hspace', 'hspace', 11, 1 ],
     [ q['{'], '{', 12, 1 ],
     [ 'newlines', 'newlines', 13, 1 ],
     [ 'hspace', 'hspace', 14, 6 ],
     [ q{'fun'}, "'fun'", 20, 3 ],
     [ 'hspace', 'hspace', 23, 1 ],
     [ 'identifier-token', 'foo', 24, 3 ],
     [ q{'('}, '(', 27, 1 ],
     [ q{')'}, ')', 28, 1 ],
     [ 'hspace', 'hspace', 29, 1 ],
     [ q['{'], '{', 30, 1 ],
     [ q['}'], '}', 31, 1 ],
     [ 'newlines', 'newlines', 32, 1 ],
     [ 'hspace', 'hspace', 33, 4 ],
     [ q['}'], '}', 37, 1 ],
     [ 'newlines', 'newlines', 38, 1 ],
     [ 'hspace', 'hspace', 39, 4 ],
     [ q{'extension'}, "'extension'", 43, 9 ],
     [ 'hspace', 'hspace', 52, 1 ],
     [ 'identifier-token', 'A', 53, 1 ],
     [ 'hspace', 'hspace', 54, 1 ],
     [ q['{'], '{', 55, 1 ],
     [ 'newlines', 'newlines', 56, 1 ],
     [ 'hspace', 'hspace', 57, 6 ],
     [ q{'fun'}, "'fun'", 63, 3 ],
     [ 'hspace', 'hspace', 66, 1 ],
     [ 'identifier-token', 'bar', 67, 3 ],
     [ q{'('}, '(', 70, 1 ],
     [ q{')'}, ')', 71, 1 ],
     [ 'hspace', 'hspace', 72, 1 ],
     [ q['{'], '{', 73, 1 ],
     [ q['}'], '}', 74, 1 ],
     [ 'newlines', 'newlines', 75, 1 ],
     [ 'hspace', 'hspace', 76, 4 ],
     [ q['}'], '}', 80, 1 ],
);

push @terminals, qw(
  simple_x2d_string
  decimal_x2d_literal
  impl_x2d_identifier
  newlines
  identifier_x2d_token
  hspace
  binary_x2d_literal
  unicode_x2d_scalar_x2d_literal
  decimal_x2d_floating_x2d_point_x2d_literal
  operator_x2d_entity_x2d_identifier
  function_x2d_entity_x2d_identifier
  operator
  hexadecimal_x2d_literal
  multiline_x2d_string
  block_x2d_comment_x2d_open
  octal_x2d_literal
  single_x2d_line_x2d_comment
);

{
    my %seen = ();
    my @hashElements = ();
    for (my $i = 1; $i < @input; $i++) {
        push @hashElements, ${$input[$i]}[0], 1;
    }
    my %terminalHash = @hashElements;
    for my $terminal (keys %terminalHash) {
        die "No R2 name for $terminal" if not defined $R2name{$terminal};
        my $r2terminal = $R2name{$terminal};
        $seen{$r2terminal} = 1;
        my $line = "$r2terminal ~ unicorn\n";
        # print STDERR "Adding $line";
        push @source, $line;
    }
    TERMINAL: for my $terminal (@terminals) {
        # die "No R2 name for $terminal" if not defined $R2name{$terminal};
        next TERMINAL if $seen{$terminal};
        my $line = $terminal . " ~ unicorn\n";
        # print STDERR "Adding $line";
        push @source, $line;
    }
}

my $source = join '', @source;

my $grammar = Marpa::R2::Scanless::G->new(
    {  
        source          => \$source,
    }
);

# Token sequence:
# 
# 'type' hspace identifier hspace '{' newlines hspace 'fun' identifier
# '(' ')' hspace '{' '}' newlines hspace '}' newlines hspace 'extension'
# hspace identifier hspace '{' newlines hspace 'fun' hspace identifier '('
# ')' hspace '{' '}' newlines hspace '}'

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

my $string = <<'EOS';
    type A {
      fun foo() {}
    }
    extension A {
      fun bar() {}
    }
EOS

$recce->read( \$string, 0, 0 );

my $length = length $string;
pos $string = 0;

TOKEN: for (my $i = 1; $i < @input; $i++) {
    my ( $token_name, $long_name, $start, $length ) = @{$input[$i]};
    if ( not defined $recce->lexeme_read( $R2name{$token_name}, $start-1, $length, $long_name ) ) {
        die qq{Parser rejected token "$long_name"};
    }
}

say "Ambiguity Metric: ", $recce->ambiguity_metric();
# say "Ambiguity: ", $recce->ambiguous();

my $value_ref = $recce->value();
if ( not defined $value_ref ) {
    die "No parse was found, after reading the entire input\n";
}

my $expected_value = \[
    [
        [
            [ '\'type\'', 'hspace', 'A' ],
            'hspace',
            [
                '{',
                [
                    [ 'newlines', 'hspace' ],
                    [
                        [ '\'fun\'', 'hspace', 'foo' ],
                        [ '(', ')' ],
                        'hspace', [ '{', '}' ]
                    ]
                ],
                [ 'newlines', 'hspace' ],
                '}'
            ]
        ],
        [ 'newlines', 'hspace' ],
        [
            [ '\'extension\'', [ 'hspace', 'A' ] ],
            'hspace',
            [
                '{',
                [
                    [ 'newlines', 'hspace' ],
                    [
                        [ '\'fun\'', 'hspace', 'bar' ],
                        [ '(', ')' ],
                        'hspace', [ '{', '}' ]
                    ]
                ],
                [ 'newlines', 'hspace' ],
                '}'
            ]
        ]
    ]
];

Test::More::is(
    Data::Dumper::Dumper($value_ref),
    Data::Dumper::Dumper($expected_value),
    'Value of parse'
);

sub main::dwim {
    my @result = ();
    shift;
    ARG: for my $v ( @_ ) {
        next ARG if not $v;
        my $type = Scalar::Util::reftype $v;
        if (not $type or $type ne 'ARRAY') {
           push @result, $v;
           next ARG;
        }
        my $size = scalar @{$v};
        next ARG if $size == 0;
        if ($size == 1) {
           push @result, ${$v}[0];
           next ARG;
        }
        push @result, $v;
    }
    return [@result];
}

# vim: expandtab shiftwidth=4:
