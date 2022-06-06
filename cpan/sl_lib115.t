#!/usr/bin/perl
# Copyright 2018 Jeffrey Kegler
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

# Dave Abrahams Libmarpa issue 115
# "Bad ambiguity report"

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
associated-size-decl_1 ::= '=' expr
associated-size-decl_1-opt ::= 
associated-size-decl_1-opt ::= associated-size-decl_1
associated-size-decl ::= associated-size-head where-clause-opt associated-size-decl_1-opt
associated-size-head ::= 'size' identifier
associated-type-constraints ::= conformance-list
conformance-list-opt ::= 
conformance-list-opt ::= conformance-list
associated-type-constraints ::= conformance-list-opt where-clause
associated-type-constraints-opt ::= 
associated-type-constraints-opt ::= associated-type-constraints
associated-type-decl_1 ::= '=' type-expr
associated-type-decl_1-opt ::= 
associated-type-decl_1-opt ::= associated-type-decl_1
associated-type-decl ::= associated-type-head associated-type-constraints-opt associated-type-decl_1-opt
associated-type-head ::= 'type' identifier
async-type-expr ::= 'async' type-expr
binding-annotation ::= ':' type-expr
binding-initializer-opt ::= 
binding-initializer-opt ::= binding-initializer
binding-decl ::= binding-head binding-initializer-opt
access-modifier-opt ::= 
access-modifier-opt ::= access-modifier
member-modifier-list ::= 
member-modifier-list ::= member-modifier-list member-modifier
binding-head ::= access-modifier-opt member-modifier-list binding-pattern
binding-initializer ::= '=' expr
binding-introducer ::= 'let'
binding-introducer ::= 'var'
binding-introducer ::= 'sink'
binding-introducer ::= 'inout'
binding-annotation-opt ::= 
binding-annotation-opt ::= binding-annotation
binding-pattern ::= binding-introducer pattern binding-annotation-opt
boolean-literal ::= 'true'
boolean-literal ::= 'false'
brace-stmt_1 ::= stmt
brace-stmt_1 ::= ';'
brace-stmt_1-list ::= 
brace-stmt_1-list ::= brace-stmt_1-list brace-stmt_1
brace-stmt ::= '{' brace-stmt_1-list '}'
buffer-component-list_1 ::= ',' expr
buffer-component-list_1-list ::= 
buffer-component-list_1-list ::= buffer-component-list_1-list buffer-component-list_1
','-opt ::= 
','-opt ::= ','
buffer-component-list ::= expr buffer-component-list_1-list ','-opt
buffer-component-list-opt ::= 
buffer-component-list-opt ::= buffer-component-list
buffer-literal ::= '[' buffer-component-list-opt ']'
expr-opt ::= 
expr-opt ::= expr
buffer-type-expr ::= type-expr '[' expr-opt ']'
call-argument_1 ::= identifier ':'
call-argument_1-opt ::= 
call-argument_1-opt ::= call-argument_1
call-argument ::= call-argument_1-opt expr
call-argument-list_1 ::= ',' call-argument
call-argument-list_1-list ::= 
call-argument-list_1-list ::= call-argument-list_1-list call-argument-list_1
call-argument-list ::= call-argument call-argument-list_1-list
capture-list_1 ::= ',' binding-decl
capture-list_1-list ::= 
capture-list_1-list ::= capture-list_1-list capture-list_1
capture-list ::= '[' binding-decl capture-list_1-list ']'
compound-expr ::= value-member-expr
compound-expr ::= function-call-expr
compound-expr ::= subscript-call-expr
compound-expr ::= primary-expr
compound-literal ::= buffer-literal
compound-literal ::= map-literal
cond-binding-body ::= jump-stmt
cond-binding-body ::= expr
cond-binding-stmt ::= binding-pattern '??' cond-binding-body
conditional-clause_1 ::= ',' conditional-clause-item
conditional-clause_1-list ::= 
conditional-clause_1-list ::= conditional-clause_1-list conditional-clause_1
conditional-clause ::= conditional-clause-item conditional-clause_1-list
conditional-clause-item ::= binding-pattern '=' expr
conditional-clause-item ::= expr
conditional-tail-opt ::= 
conditional-tail-opt ::= conditional-tail
conditional-expr ::= 'if' conditional-clause brace-stmt conditional-tail-opt
conditional-tail ::= 'else' conditional-expr
conditional-tail ::= 'else' brace-stmt
conformance-body_1 ::= conformance-member-decl
conformance-body_1 ::= ';'
conformance-body_1-list ::= 
conformance-body_1-list ::= conformance-body_1-list conformance-body_1
conformance-body ::= '{' conformance-body_1-list '}'
conformance-constraint ::= name-type-expr ':' trait-composition
conformance-decl ::= conformance-head conformance-body
access-modifier-opt_1 ::= 
access-modifier-opt_1 ::= access-modifier
where-clause-opt_1 ::= 
where-clause-opt_1 ::= where-clause
conformance-head ::= access-modifier-opt_1 'conformance' type-expr conformance-list where-clause-opt_1
conformance-lens-type-expr ::= type-expr '::' type-identifier
conformance-list_1 ::= ',' name-type-expr
conformance-list_1-list ::= 
conformance-list_1-list ::= conformance-list_1-list conformance-list_1
conformance-list ::= ':' name-type-expr conformance-list_1-list
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
default-value ::= '=' expr
do-while-stmt ::= 'do' brace-stmt 'while' expr
entity-identifier ::= identifier
entity-identifier ::= function-entity-identifier
entity-identifier ::= operator-entity-identifier
equality-constraint ::= name-type-expr '==' type-expr
where-clause-opt_2 ::= 
where-clause-opt_2 ::= where-clause
existential-type-expr ::= 'any' trait-composition where-clause-opt_2
infix-tail-opt ::= 
infix-tail-opt ::= infix-tail
expr ::= prefix-expr infix-tail-opt
expr-pattern ::= expr
extension-body_1 ::= extension-member-decl
extension-body_1 ::= ';'
extension-body_1-list ::= 
extension-body_1-list ::= extension-body_1-list extension-body_1
extension-body ::= '{' extension-body_1-list '}'
extension-decl ::= extension-head extension-body
access-modifier-opt_2 ::= 
access-modifier-opt_2 ::= access-modifier
where-clause-opt_3 ::= 
where-clause-opt_3 ::= where-clause
extension-head ::= access-modifier-opt_2 'extension' type-expr where-clause-opt_3
extension-member-decl ::= function-decl
extension-member-decl ::= subscript-decl
extension-member-decl ::= product-type-decl
extension-member-decl ::= type-alias-decl
floating-point-literal ::= decimal-floating-point-literal
for-counter-decl ::= pattern
for-range ::= 'in' expr
loop-filter-opt ::= 
loop-filter-opt ::= loop-filter
for-stmt ::= 'for' for-counter-decl for-range loop-filter-opt brace-stmt
function-body ::= function-bundle-body
function-body ::= brace-stmt
method-impl-list ::= method-impl
method-impl-list ::= method-impl-list method-impl
function-bundle-body ::= '{' method-impl-list '}'
call-argument-list-opt ::= 
call-argument-list-opt ::= call-argument-list
function-call-expr ::= expr '(' call-argument-list-opt ')'
function-decl ::= memberwise-ctor-decl
function-body-opt ::= 
function-body-opt ::= function-body
function-decl ::= function-head function-signature function-body-opt
access-modifier-opt_3 ::= 
access-modifier-opt_3 ::= access-modifier
member-modifier-list_1 ::= 
member-modifier-list_1 ::= member-modifier-list_1 member-modifier
generic-clause-opt ::= 
generic-clause-opt ::= generic-clause
capture-list-opt ::= 
capture-list-opt ::= capture-list
function-head ::= access-modifier-opt_3 member-modifier-list_1 function-identifier generic-clause-opt capture-list-opt
function-identifier ::= 'init'
function-identifier ::= 'deinit'
function-identifier ::= 'fun' identifier
function-identifier ::= operator-notation 'fun' operator
parameter-list-opt ::= 
parameter-list-opt ::= parameter-list
function-signature_1 ::= '->' type-expr
function-signature_1-opt ::= 
function-signature_1-opt ::= function-signature_1
function-signature ::= '(' parameter-list-opt ')' function-signature_1-opt
generic-clause_1 ::= ',' generic-parameter
generic-clause_1-list ::= 
generic-clause_1-list ::= generic-clause_1-list generic-clause_1
where-clause-opt_4 ::= 
where-clause-opt_4 ::= where-clause
generic-clause ::= '<' generic-parameter generic-clause_1-list where-clause-opt_4 '>'
generic-parameter ::= generic-type-parameter
generic-parameter ::= generic-size-parameter
generic-size-parameter ::= identifier ':' 'size'
'...'-opt ::= 
'...'-opt ::= '...'
trait-annotation-opt ::= 
trait-annotation-opt ::= trait-annotation
generic-type-parameter ::= identifier '...'-opt trait-annotation-opt
identifier ::= identifier-token
identifier ::= contextual-keyword
impl-identifier-opt ::= 
impl-identifier-opt ::= impl-identifier
identifier-expr ::= entity-identifier impl-identifier-opt
implicit-member-ref ::= '.' primary-decl-ref
import-statement ::= 'import' identifier
indirect-type-expr ::= 'indirect' type-expr
infix-item ::= infix-operator prefix-expr
infix-item ::= type-casting-operator type-expr
infix-operator ::= operator
infix-operator ::= '='
infix-operator ::= '=='
infix-operator ::= '<'
infix-operator ::= '>'
infix-operator ::= '..<'
infix-operator ::= '...'
infix-item-list ::= infix-item
infix-item-list ::= infix-item-list infix-item
infix-tail ::= infix-item-list
integer-literal ::= binary-literal
integer-literal ::= octal-literal
integer-literal ::= decimal-literal
integer-literal ::= hexadecimal-literal
jump-stmt ::= cond-binding-stmt
expr-opt_1 ::= 
expr-opt_1 ::= expr
jump-stmt ::= 'return' expr-opt_1
jump-stmt ::= 'yield' expr
jump-stmt ::= 'break'
jump-stmt ::= 'continue'
lambda-body ::= brace-stmt
lambda-environment ::= '[' type-expr ']'
capture-list-opt_1 ::= 
capture-list-opt_1 ::= capture-list
lambda-expr ::= 'fun' capture-list-opt_1 function-signature lambda-body
lambda-parameter_1 ::= identifier ':'
lambda-parameter_1-opt ::= 
lambda-parameter_1-opt ::= lambda-parameter_1
lambda-parameter ::= lambda-parameter_1-opt type-expr
lambda-receiver-effect ::= 'inout'
lambda-receiver-effect ::= 'sink'
lambda-environment-opt ::= 
lambda-environment-opt ::= lambda-environment
lamda-parameter-list-opt ::= 
lamda-parameter-list-opt ::= lamda-parameter-list
lambda-receiver-effect-opt ::= 
lambda-receiver-effect-opt ::= lambda-receiver-effect
lambda-type-expr ::= lambda-environment-opt '(' lamda-parameter-list-opt ')' lambda-receiver-effect-opt '->' type-expr
lamda-parameter-list_1 ::= ',' lambda-parameter
lamda-parameter-list_1-list ::= 
lamda-parameter-list_1-list ::= lamda-parameter-list_1-list lamda-parameter-list_1
lamda-parameter-list ::= lambda-parameter lamda-parameter-list_1-list
loop-filter ::= 'where' expr
loop-stmt ::= do-while-stmt
loop-stmt ::= while-stmt
loop-stmt ::= for-stmt
map-component ::= expr ':' expr
map-component-list_1 ::= ',' map-component
map-component-list_1-list ::= 
map-component-list_1-list ::= map-component-list_1-list map-component-list_1
','-opt_1 ::= 
','-opt_1 ::= ','
map-component-list ::= map-component map-component-list_1-list ','-opt_1
map-literal ::= '[' map-component-list ']'
map-literal ::= '[' ':' ']'
match-case ::= pattern brace-stmt
match-expr_1 ::= match-case
match-expr_1 ::= ';'
match-expr_1-list ::= 
match-expr_1-list ::= match-expr_1-list match-expr_1
match-expr ::= 'match' expr '{' match-expr_1-list '}'
member-modifier ::= receiver-modifier
member-modifier ::= static-modifier
memberwise-ctor-decl ::= 'memberwise' 'init'
brace-stmt-opt ::= 
brace-stmt-opt ::= brace-stmt
method-impl ::= method-introducer brace-stmt-opt
method-introducer ::= 'let'
method-introducer ::= 'sink'
method-introducer ::= 'inout'
module-definition_1 ::= module-scope-decl
module-definition_1 ::= import-statement
module-definition_1-list ::= 
module-definition_1-list ::= module-definition_1-list module-definition_1
module-definition ::= module-definition_1-list
module-scope-decl ::= namespace-decl
module-scope-decl ::= trait-decl
module-scope-decl ::= type-alias-decl
module-scope-decl ::= product-type-decl
module-scope-decl ::= extension-decl
module-scope-decl ::= conformance-decl
module-scope-decl ::= binding-decl
module-scope-decl ::= function-decl
module-scope-decl ::= subscript-decl
name-pattern ::= identifier
name-type-expr_1 ::= type-expr '.'
name-type-expr_1-opt ::= 
name-type-expr_1-opt ::= name-type-expr_1
type-argument-list-opt ::= 
type-argument-list-opt ::= type-argument-list
name-type-expr ::= name-type-expr_1-opt type-identifier type-argument-list-opt
module-scope-decl-list ::= 
module-scope-decl-list ::= module-scope-decl-list module-scope-decl
namespace-body ::= '{' module-scope-decl-list '}'
namespace-decl ::= namespace-head namespace-body
access-modifier-opt_4 ::= 
access-modifier-opt_4 ::= access-modifier
namespace-head ::= access-modifier-opt_4 'namespace' identifier
where-clause-opt_5 ::= 
where-clause-opt_5 ::= where-clause
opaque-type-expr ::= 'some' trait-composition where-clause-opt_5
opaque-type-expr ::= 'some' '_'
operator-notation ::= 'infix'
operator-notation ::= 'prefix'
operator-notation ::= 'postfix'
parameter-decl_1 ::= identifier
parameter-decl_1 ::= '_'
identifier-opt ::= 
identifier-opt ::= identifier
parameter-decl_2 ::= ':' parameter-type-expr
parameter-decl_2-opt ::= 
parameter-decl_2-opt ::= parameter-decl_2
default-value-opt ::= 
default-value-opt ::= default-value
parameter-decl ::= parameter-decl_1 identifier-opt parameter-decl_2-opt default-value-opt
parameter-list_1 ::= ',' parameter-decl
parameter-list_1-list ::= 
parameter-list_1-list ::= parameter-list_1-list parameter-list_1
parameter-list ::= parameter-decl parameter-list_1-list
parameter-passing-convention ::= 'let'
parameter-passing-convention ::= 'inout'
parameter-passing-convention ::= 'sink'
parameter-passing-convention ::= 'yielded'
parameter-passing-convention-opt ::= 
parameter-passing-convention-opt ::= parameter-passing-convention
parameter-type-expr ::= parameter-passing-convention-opt type-expr
pattern ::= binding-pattern
pattern ::= expr-pattern
pattern ::= name-pattern
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
primary-decl-ref ::= identifier-expr type-argument-list-opt_1
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
product-type-body_1-list ::= product-type-body_1-list product-type-body_1
product-type-body ::= '{' product-type-body_1-list '}'
product-type-decl ::= product-type-head product-type-body
access-modifier-opt_5 ::= 
access-modifier-opt_5 ::= access-modifier
generic-clause-opt_1 ::= 
generic-clause-opt_1 ::= generic-clause
conformance-list-opt_1 ::= 
conformance-list-opt_1 ::= conformance-list
product-type-head ::= access-modifier-opt_5 'type' identifier generic-clause-opt_1 conformance-list-opt_1
product-type-member-decl ::= function-decl
product-type-member-decl ::= subscript-decl
product-type-member-decl ::= property-decl
product-type-member-decl ::= binding-decl
product-type-member-decl ::= product-type-decl
product-type-member-decl ::= type-alias-decl
property-annotation ::= ':' type-expr
property-decl ::= property-head property-annotation subscript-body
member-modifier-list_2 ::= 
member-modifier-list_2 ::= member-modifier-list_2 member-modifier
property-head ::= member-modifier-list_2 'property' identifier
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
stored-projection-capability ::= 'let'
stored-projection-capability ::= 'inout'
stored-projection-capability ::= 'yielded'
stored-projection-type-expr ::= '[' stored-projection-capability type-expr ']'
string-literal ::= simple-string
string-literal ::= multiline-string
subscript-body ::= brace-stmt
subscript-impl-list ::= subscript-impl
subscript-impl-list ::= subscript-impl-list subscript-impl
subscript-body ::= '{' subscript-impl-list '}'
call-argument-list-opt_1 ::= 
call-argument-list-opt_1 ::= call-argument-list
subscript-call-expr ::= expr '[' call-argument-list-opt_1 ']'
subscript-decl ::= subscript-head subscript-signature subscript-body
member-modifier-list_3 ::= 
member-modifier-list_3 ::= member-modifier-list_3 member-modifier
subscript-identifier-opt ::= 
subscript-identifier-opt ::= subscript-identifier
generic-clause-opt_2 ::= 
generic-clause-opt_2 ::= generic-clause
capture-list-opt_2 ::= 
capture-list-opt_2 ::= capture-list
subscript-head ::= member-modifier-list_3 subscript-identifier-opt generic-clause-opt_2 capture-list-opt_2
subscript-identifier ::= 'subscript' identifier
subscript-identifier ::= operator-notation 'subscript' operator
brace-stmt-opt_1 ::= 
brace-stmt-opt_1 ::= brace-stmt
subscript-impl ::= subscript-introducer brace-stmt-opt_1
subscript-introducer ::= 'let'
subscript-introducer ::= 'sink'
subscript-introducer ::= 'inout'
subscript-introducer ::= 'set'
parameter-list-opt_1 ::= 
parameter-list-opt_1 ::= parameter-list
'var'-opt ::= 
'var'-opt ::= 'var'
subscript-signature ::= '(' parameter-list-opt_1 ')' ':' 'var'-opt type-expr
suffix-expr ::= primary-expr
suffix-expr ::= compound-expr
suffix-expr ::= suffix-expr operator
trait-annotation ::= ':' trait-composition
trait-body_1 ::= trait-requirement-decl
trait-body_1 ::= ';'
trait-body_1-list ::= 
trait-body_1-list ::= trait-body_1-list trait-body_1
trait-body ::= '{' trait-body_1-list '}'
trait-composition_1 ::= '&' name-type-expr
trait-composition_1-list ::= 
trait-composition_1-list ::= trait-composition_1-list trait-composition_1
trait-composition ::= name-type-expr trait-composition_1-list
trait-decl ::= trait-head trait-body
access-modifier-opt_6 ::= 
access-modifier-opt_6 ::= access-modifier
trait-refinement-list-opt ::= 
trait-refinement-list-opt ::= trait-refinement-list
trait-head ::= access-modifier-opt_6 'trait' identifier trait-refinement-list-opt
trait-refinement-list_1 ::= ',' name-type-expr
trait-refinement-list_1-list ::= 
trait-refinement-list_1-list ::= trait-refinement-list_1-list trait-refinement-list_1
trait-refinement-list ::= ':' name-type-expr trait-refinement-list_1-list
trait-requirement-decl ::= associated-decl
trait-requirement-decl ::= function-decl
trait-requirement-decl ::= subscript-decl
trait-requirement-decl ::= property-decl
tuple-expr ::= '(' tuple-expr-element-list ')'
tuple-expr-element_1 ::= identifier ':'
tuple-expr-element_1-opt ::= 
tuple-expr-element_1-opt ::= tuple-expr-element_1
tuple-expr-element ::= tuple-expr-element_1-opt expr
tuple-expr-element-list_1 ::= ',' tuple-expr-element
tuple-expr-element-list_1-opt ::= 
tuple-expr-element-list_1-opt ::= tuple-expr-element-list_1
tuple-expr-element-list ::= tuple-expr-element tuple-expr-element-list_1-opt
tuple-pattern ::= '(' tuple-pattern-element-list ')'
tuple-pattern-element_1 ::= identifier ':'
tuple-pattern-element_1-opt ::= 
tuple-pattern-element_1-opt ::= tuple-pattern-element_1
tuple-pattern-element ::= tuple-pattern-element_1-opt pattern
tuple-pattern-element-list_1 ::= ',' tuple-pattern-element
tuple-pattern-element-list_1-opt ::= 
tuple-pattern-element-list_1-opt ::= tuple-pattern-element-list_1
tuple-pattern-element-list ::= tuple-pattern-element tuple-pattern-element-list_1-opt
tuple-type-element_1 ::= identifier ':'
tuple-type-element_1-opt ::= 
tuple-type-element_1-opt ::= tuple-type-element_1
tuple-type-element ::= tuple-type-element_1-opt type-expr
tuple-type-element-list_1 ::= ',' tuple-type-element
tuple-type-element-list_1-opt ::= 
tuple-type-element-list_1-opt ::= tuple-type-element-list_1
tuple-type-element-list ::= tuple-type-element tuple-type-element-list_1-opt
tuple-type-expr ::= '(' tuple-type-element-list ')'
type-alias-body ::= '=' type-expr
type-alias-body ::= '=' union-decl
type-alias-decl ::= type-alias-head type-alias-body
access-modifier-opt_7 ::= 
access-modifier-opt_7 ::= access-modifier
generic-clause-opt_3 ::= 
generic-clause-opt_3 ::= generic-clause
type-alias-head ::= access-modifier-opt_7 'typealias' identifier generic-clause-opt_3
type-argument_1 ::= identifier ':'
type-argument_1-opt ::= 
type-argument_1-opt ::= type-argument_1
type-argument ::= type-argument_1-opt type-expr
type-argument-list_1 ::= ',' type-argument
type-argument-list_1-list ::= 
type-argument-list_1-list ::= type-argument-list_1-list type-argument-list_1
type-argument-list ::= '<' type-argument type-argument-list_1-list '>'
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
union-decl_1 ::= '|' product-type-decl
union-decl_1-list ::= 
union-decl_1-list ::= union-decl_1-list union-decl_1
union-decl ::= product-type-decl union-decl_1-list
union-type-expr_1 ::= '|' type-expr
union-type-expr_1-list ::= union-type-expr_1
union-type-expr_1-list ::= union-type-expr_1-list union-type-expr_1
union-type-expr ::= type-expr union-type-expr_1-list
value-member-expr ::= expr '.' primary-decl-ref
value-member-expr ::= type-expr '.' primary-decl-ref
where-clause ::= 'where' where-clause-constraint
where-clause-constraint ::= equality-constraint
where-clause-constraint ::= conformance-constraint
where-clause-constraint ::= size-constraint-expr
while-condition-item ::= binding-pattern '=' expr
while-condition-item ::= expr
while-condition-list_1 ::= ',' while-condition-item
while-condition-list_1-list ::= 
while-condition-list_1-list ::= while-condition-list_1-list while-condition-list_1
while-condition-list ::= while-condition-item while-condition-list_1-list
while-stmt ::= 'while' while-condition-list brace-stmt
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
     [ 'DUMMY', 'DUMMY' ], # Avoid use of zero location
     [ q{'type'}, "'type'", 5, 4 ],
     [ 'identifier-token', 'A', 10, 1 ],
     [ q['{'], '{', 12,  1 ],
     [ q{'var'}, "'var'", 20, 3 ],
     [ 'identifier-token', 'a', 24, 1 ],
     [ q{':'}, ':', 25, 1 ],
     [ 'identifier-token', 'Int', 27, 3 ],

     [ q{'fun'}, "'fun'", 37, 3 ],
     [ 'identifier-token', 'foo', 41, 3 ],
     [ q{'('}, '(', 44, 1 ],
     [ 'identifier-token', 'a', 45, 1 ],
     [ q{':'}, ':', 46, 1 ],
     [ 'identifier-token', 'Int', 48, 3 ],
     [ q{')'}, ')', 51, 1 ],
     [ q['{'], '{', 53, 1 ],
     [ 'identifier-token', 'a', 55, 1 ],
     [ q{'.'}, '.', 56, 1 ],
     [ 'identifier-token', 'copy', 57, 4 ],
     [ q{'('}, '(', 61, 1 ],
     [ q{')'}, ')', 62, 1],
     [ q['}'], '}', 64, 1 ],

     [ q{'fun'}, "'fun'", 72, 3 ],
     [ 'identifier-token', 'foo', 76, 3 ],
     [ q{'('}, '(', 79, 1 ],
     [ 'identifier-token', 'b', 80, 1 ],
     [ q{':'}, ':', 81, 1 ],
     [ 'identifier-token', 'Int', 83, 3 ],
     [ q{')'}, ')', 86, 1 ],
     [ q{'->'}, '->', 88, 2 ],
     [ 'identifier-token', 'Int', 91, 3 ],
     [ q['{'], '{', 95, 1 ],

     [ q{'let'}, 'let', 105, 3 ],
     [ q['{'], '{', 111, 1 ],
     [ 'identifier-token', 'a', 113, 1 ],
     [ 'operator', '+', 115, 1 ],
     [ 'identifier-token', 'b', 117, 1 ],
     [ q['}'], '}', 119, 1 ], # right brace

     [ q{'inout'}, 'inout', 129, 5 ],
     [ q['{'], '{', 135, 1 ],
     [ 'identifier-token', 'b', 137, 1 ],
     [ 'operator', '+=', 139, 2 ],
     [ 'identifier-token', 'a', 142, 1 ],
     [ q['}'], '}', 144, 1 ], # right brace

     [ q['}'], '}', 152, 1 ], # right brace

     [ q['}'], '}', 158, 1 ], # right brace

);

push @terminals, qw(
binary_x2d_literal
decimal_x2d_floating_x2d_point_x2d_literal
decimal_x2d_literal
function_x2d_entity_x2d_identifier
hexadecimal_x2d_literal
identifier_x2d_token
impl_x2d_identifier
multiline_x2d_string
octal_x2d_literal
operator_x2d_entity_x2d_identifier
simple_x2d_string
unicode_x2d_scalar_x2d_literal
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

# 
# Token sequence:
# 
# 'type' identifier '{'
# 'var' identifier ':' identifier
# 'fun' identifier '(' identifier ':' identifier ')' '{' identifier '.' identifier '(' ')' '}'
# 'fun' identifier '(' identifier ':' identifier ')' '->' identifier '{'
# 'let' '{' identifier '+' identifier '}'
# 'inout' '{' identifier operator identifier '}'
# '}'
# '}'
# 

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

my $string = <<'EOS';
    type A {
      var a: Int
      fun foo(a: Int) { a.copy() }
      fun foo(b: Int) -> Int {
        let   { a + b }
        inout { b += a }
      }
    }
EOS

read_input();

# say $recce->show_progress(5);
say "Ambiguity Metric: ", $recce->ambiguity_metric();
say "Ambiguity: ", $recce->ambiguous();

# Start a new recognizer, because we cannot call
# $r->ambiguous() and $r->value() on the same recognizer
$recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
read_input();
say "Ambiguity Metric: ", $recce->ambiguity_metric();

Marpa::R2::Thin::debug_level_set(1);
my $value_ref = $recce->value();
if ( not defined $value_ref ) {
    die "No parse was found, after reading the entire input\n";
}

my $expected_value = \[
];

Test::More::is(
    Data::Dumper::Dumper($value_ref),
    Data::Dumper::Dumper($expected_value),
    'Value of parse'
);

sub read_input {
    $recce->read( \$string, 0, 0 );

    my $length = length $string;
    pos $string = 0;

  TOKEN: for ( my $i = 1 ; $i < @input ; $i++ ) {
        my ( $token_name, $long_name, $start, $length ) = @{ $input[$i] };
        if (
            not defined $recce->lexeme_read(
                $R2name{$token_name}, $start - 1, $length, $long_name
            )
          )
        {
            die qq{Parser rejected token "$long_name"};
        }
    }
}

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
