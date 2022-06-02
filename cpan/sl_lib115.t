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

my $source = <<'END_OF_SOURCE';
:default ::= action => main::dwim
:start ::= module__definition 

access__modifier ::= 'public'
associated__decl ::= associated__type__decl
associated__decl ::= associated__size__decl
where__clause__opt ::=
where__clause__opt ::= where__clause
associated__size__decl_1 ::= '=' expr
associated__size__decl_1__opt ::=
associated__size__decl_1__opt ::= associated__size__decl_1
associated__size__decl ::= associated__size__head where__clause__opt associated__size__decl_1__opt
associated__size__head ::= 'size' identifier
associated__type__constraints ::= conformance__list
conformance__list__opt ::=
conformance__list__opt ::= conformance__list
associated__type__constraints ::= conformance__list__opt where__clause
associated__type__constraints__opt ::=
associated__type__constraints__opt ::= associated__type__constraints
associated__type__decl_1 ::= '=' type__expr
associated__type__decl_1__opt ::=
associated__type__decl_1__opt ::= associated__type__decl_1
associated__type__decl ::= associated__type__head associated__type__constraints__opt associated__type__decl_1__opt
associated__type__head ::= TYPE identifier
async__type__expr ::= 'async' type__expr
binding__annotation ::= COLON type__expr
binding__initializer__opt ::=
binding__initializer__opt ::= binding__initializer
binding__decl ::= binding__head binding__initializer__opt
access__modifier__opt ::=
access__modifier__opt ::= access__modifier
member__modifier__list ::=
member__modifier__list ::= member__modifier__list member__modifier
binding__head ::= access__modifier__opt member__modifier__list binding__pattern
binding__initializer ::= '=' expr
binding__introducer ::= LET
binding__introducer ::= VAR
binding__introducer ::= 'sink'
binding__introducer ::= INOUT
binding__annotation__opt ::=
binding__annotation__opt ::= binding__annotation
binding__pattern ::= binding__introducer pattern binding__annotation__opt
boolean__literal ::= 'true'
boolean__literal ::= 'false'
brace__stmt_1 ::= stmt
brace__stmt_1 ::= ';'
brace__stmt_1__list ::=
brace__stmt_1__list ::= brace__stmt_1__list brace__stmt_1
brace__stmt ::= LBRACE brace__stmt_1__list RBRACE
buffer__component__list_1 ::= ',' expr
buffer__component__list_1__list ::=
buffer__component__list_1__list ::= buffer__component__list_1__list buffer__component__list_1
q_comma_q__opt ::=
q_comma_q__opt ::= ','
buffer__component__list ::= expr buffer__component__list_1__list q_comma_q__opt
buffer__component__list__opt ::=
buffer__component__list__opt ::= buffer__component__list
buffer__literal ::= '[' buffer__component__list__opt ']'
expr__opt ::=
expr__opt ::= expr
buffer__type__expr ::= type__expr '[' expr__opt ']'
call__argument_1 ::= identifier COLON
call__argument_1__opt ::=
call__argument_1__opt ::= call__argument_1
call__argument ::= call__argument_1__opt expr
call__argument__list_1 ::= ',' call__argument
call__argument__list_1__list ::=
call__argument__list_1__list ::= call__argument__list_1__list call__argument__list_1
call__argument__list ::= call__argument call__argument__list_1__list
capture__list_1 ::= ',' binding__decl
capture__list_1__list ::=
capture__list_1__list ::= capture__list_1__list capture__list_1
capture__list ::= '[' binding__decl capture__list_1__list ']'
compound__expr ::= value__member__expr
compound__expr ::= function__call__expr
compound__expr ::= subscript__call__expr
compound__expr ::= primary__expr
compound__literal ::= buffer__literal
compound__literal ::= map__literal
cond__binding__body ::= jump__stmt
cond__binding__body ::= expr
cond__binding__stmt ::= binding__pattern '??' cond__binding__body
conditional__clause_1 ::= ',' conditional__clause__item
conditional__clause_1__list ::=
conditional__clause_1__list ::= conditional__clause_1__list conditional__clause_1
conditional__clause ::= conditional__clause__item conditional__clause_1__list
conditional__clause__item ::= binding__pattern '=' expr
conditional__clause__item ::= expr
conditional__tail__opt ::=
conditional__tail__opt ::= conditional__tail
conditional__expr ::= 'if' conditional__clause brace__stmt conditional__tail__opt
conditional__tail ::= 'else' conditional__expr
conditional__tail ::= 'else' brace__stmt
conformance__body_1 ::= conformance__member__decl
conformance__body_1 ::= ';'
conformance__body_1__list ::=
conformance__body_1__list ::= conformance__body_1__list conformance__body_1
conformance__body ::= LBRACE conformance__body_1__list RBRACE
conformance__constraint ::= name__type__expr COLON trait__composition
conformance__decl ::= conformance__head conformance__body
access__modifier__opt_1 ::=
access__modifier__opt_1 ::= access__modifier
where__clause__opt_1 ::=
where__clause__opt_1 ::= where__clause
conformance__head ::= access__modifier__opt_1 'conformance' type__expr conformance__list where__clause__opt_1
conformance__lens__type__expr ::= type__expr '::' type__identifier
conformance__list_1 ::= ',' name__type__expr
conformance__list_1__list ::=
conformance__list_1__list ::= conformance__list_1__list conformance__list_1
conformance__list ::= COLON name__type__expr conformance__list_1__list
conformance__member__decl ::= function__decl
conformance__member__decl ::= subscript__decl
conformance__member__decl ::= product__type__decl
conformance__member__decl ::= type__alias__decl
contextual__keyword ::= 'mutating'
contextual__keyword ::= 'size'
contextual__keyword ::= 'any'
contextual__keyword ::= 'in'
decl__stmt ::= type__alias__decl
decl__stmt ::= product__type__decl
decl__stmt ::= extension__decl
decl__stmt ::= conformance__decl
decl__stmt ::= function__decl
decl__stmt ::= subscript__decl
decl__stmt ::= binding__decl
default__value ::= '=' expr
do__while__stmt ::= 'do' brace__stmt 'while' expr
entity__identifier ::= identifier
entity__identifier ::= function__entity__identifier
entity__identifier ::= operator__entity__identifier
equality__constraint ::= name__type__expr '==' type__expr
where__clause__opt_2 ::=
where__clause__opt_2 ::= where__clause
existential__type__expr ::= 'any' trait__composition where__clause__opt_2
infix__tail__opt ::=
infix__tail__opt ::= infix__tail
expr ::= prefix__expr infix__tail__opt
expr__pattern ::= expr
extension__body_1 ::= extension__member__decl
extension__body_1 ::= ';'
extension__body_1__list ::=
extension__body_1__list ::= extension__body_1__list extension__body_1
extension__body ::= LBRACE extension__body_1__list RBRACE
extension__decl ::= extension__head extension__body
access__modifier__opt_2 ::=
access__modifier__opt_2 ::= access__modifier
where__clause__opt_3 ::=
where__clause__opt_3 ::= where__clause
extension__head ::= access__modifier__opt_2 'extension' type__expr where__clause__opt_3
extension__member__decl ::= function__decl
extension__member__decl ::= subscript__decl
extension__member__decl ::= product__type__decl
extension__member__decl ::= type__alias__decl
floating__point__literal ::= decimal__floating__point__literal
for__counter__decl ::= pattern
for__range ::= 'in' expr
loop__filter__opt ::=
loop__filter__opt ::= loop__filter
for__stmt ::= 'for' for__counter__decl for__range loop__filter__opt brace__stmt
function__body ::= function__bundle__body
function__body ::= brace__stmt
method__impl__list ::= method__impl
method__impl__list ::= method__impl__list method__impl
function__bundle__body ::= LBRACE method__impl__list RBRACE
call__argument__list__opt ::=
call__argument__list__opt ::= call__argument__list
function__call__expr ::= expr LPAREN call__argument__list__opt RPAREN
function__decl ::= memberwise__ctor__decl
function__body__opt ::=
function__body__opt ::= function__body
function__decl ::= function__head function__signature function__body__opt
access__modifier__opt_3 ::=
access__modifier__opt_3 ::= access__modifier
member__modifier__list_1 ::=
member__modifier__list_1 ::= member__modifier__list_1 member__modifier
generic__clause__opt ::=
generic__clause__opt ::= generic__clause
capture__list__opt ::=
capture__list__opt ::= capture__list
function__head ::= access__modifier__opt_3 member__modifier__list_1 function__identifier generic__clause__opt capture__list__opt
function__identifier ::= 'init'
function__identifier ::= 'deinit'
function__identifier ::= FUN identifier
function__identifier ::= operator__notation FUN operator
parameter__list__opt ::=
parameter__list__opt ::= parameter__list
function__signature_1 ::= ARROW type__expr
function__signature_1__opt ::=
function__signature_1__opt ::= function__signature_1
function__signature ::= LPAREN parameter__list__opt RPAREN function__signature_1__opt
generic__clause_1 ::= ',' generic__parameter
generic__clause_1__list ::=
generic__clause_1__list ::= generic__clause_1__list generic__clause_1
where__clause__opt_4 ::=
where__clause__opt_4 ::= where__clause
generic__clause ::= '<' generic__parameter generic__clause_1__list where__clause__opt_4 '>'
generic__parameter ::= generic__type__parameter
generic__parameter ::= generic__size__parameter
generic__size__parameter ::= identifier COLON 'size'
dotx3__opt ::=
dotx3__opt ::= '...'
trait__annotation__opt ::=
trait__annotation__opt ::= trait__annotation
generic__type__parameter ::= identifier dotx3__opt trait__annotation__opt
identifier ::= identifier__token
identifier ::= contextual__keyword
impl__identifier__opt ::=
impl__identifier__opt ::= impl__identifier
identifier__expr ::= entity__identifier impl__identifier__opt
implicit__member__ref ::= DOT primary__decl__ref
import__statement ::= 'import' identifier
indirect__type__expr ::= 'indirect' type__expr
infix__item ::= infix__operator prefix__expr
infix__item ::= type__casting__operator type__expr
infix__operator ::= operator
infix__operator ::= '='
infix__operator ::= '=='
infix__operator ::= '<'
infix__operator ::= '>'
infix__operator ::= '..<'
infix__operator ::= '...'
infix__item__list ::= infix__item
infix__item__list ::= infix__item__list infix__item
infix__tail ::= infix__item__list
integer__literal ::= binary__literal
integer__literal ::= octal__literal
integer__literal ::= decimal__literal
integer__literal ::= hexadecimal__literal
jump__stmt ::= cond__binding__stmt
expr__opt_1 ::=
expr__opt_1 ::= expr
jump__stmt ::= 'return' expr__opt_1
jump__stmt ::= 'yield' expr
jump__stmt ::= 'break'
jump__stmt ::= 'continue'
lambda__body ::= brace__stmt
lambda__environment ::= '[' type__expr ']'
capture__list__opt_1 ::=
capture__list__opt_1 ::= capture__list
lambda__expr ::= FUN capture__list__opt_1 function__signature lambda__body
lambda__parameter_1 ::= identifier COLON
lambda__parameter_1__opt ::=
lambda__parameter_1__opt ::= lambda__parameter_1
lambda__parameter ::= lambda__parameter_1__opt type__expr
lambda__receiver__effect ::= INOUT
lambda__receiver__effect ::= 'sink'
lambda__environment__opt ::=
lambda__environment__opt ::= lambda__environment
lamda__parameter__list__opt ::=
lamda__parameter__list__opt ::= lamda__parameter__list
lambda__receiver__effect__opt ::=
lambda__receiver__effect__opt ::= lambda__receiver__effect
lambda__type__expr ::= lambda__environment__opt LPAREN lamda__parameter__list__opt RPAREN lambda__receiver__effect__opt ARROW type__expr
lamda__parameter__list_1 ::= ',' lambda__parameter
lamda__parameter__list_1__list ::=
lamda__parameter__list_1__list ::= lamda__parameter__list_1__list lamda__parameter__list_1
lamda__parameter__list ::= lambda__parameter lamda__parameter__list_1__list
loop__filter ::= 'where' expr
loop__stmt ::= do__while__stmt
loop__stmt ::= while__stmt
loop__stmt ::= for__stmt
map__component ::= expr COLON expr
map__component__list_1 ::= ',' map__component
map__component__list_1__list ::=
map__component__list_1__list ::= map__component__list_1__list map__component__list_1
q_comma_q__opt_1 ::=
q_comma_q__opt_1 ::= ','
map__component__list ::= map__component map__component__list_1__list q_comma_q__opt_1
map__literal ::= '[' map__component__list ']'
map__literal ::= '[' COLON ']'
match__case ::= pattern brace__stmt
match__expr_1 ::= match__case
match__expr_1 ::= ';'
match__expr_1__list ::=
match__expr_1__list ::= match__expr_1__list match__expr_1
match__expr ::= 'match' expr LBRACE match__expr_1__list RBRACE
member__modifier ::= receiver__modifier
member__modifier ::= static__modifier
memberwise__ctor__decl ::= 'memberwise' 'init'
brace__stmt__opt ::=
brace__stmt__opt ::= brace__stmt
method__impl ::= method__introducer brace__stmt__opt
method__introducer ::= LET
method__introducer ::= 'sink'
method__introducer ::= INOUT
module__definition_1 ::= module__scope__decl
module__definition_1 ::= import__statement
module__definition_1__list ::=
module__definition_1__list ::= module__definition_1__list module__definition_1
module__definition ::= module__definition_1__list
module__scope__decl ::= namespace__decl
module__scope__decl ::= trait__decl
module__scope__decl ::= type__alias__decl
module__scope__decl ::= product__type__decl
module__scope__decl ::= extension__decl
module__scope__decl ::= conformance__decl
module__scope__decl ::= binding__decl
module__scope__decl ::= function__decl
module__scope__decl ::= subscript__decl
name__pattern ::= identifier
name__type__expr_1 ::= type__expr DOT
name__type__expr_1__opt ::=
name__type__expr_1__opt ::= name__type__expr_1
type__argument__list__opt ::=
type__argument__list__opt ::= type__argument__list
name__type__expr ::= name__type__expr_1__opt type__identifier type__argument__list__opt
module__scope__decl__list ::=
module__scope__decl__list ::= module__scope__decl__list module__scope__decl
namespace__body ::= LBRACE module__scope__decl__list RBRACE
namespace__decl ::= namespace__head namespace__body
access__modifier__opt_4 ::=
access__modifier__opt_4 ::= access__modifier
namespace__head ::= access__modifier__opt_4 'namespace' identifier
where__clause__opt_5 ::=
where__clause__opt_5 ::= where__clause
opaque__type__expr ::= 'some' trait__composition where__clause__opt_5
opaque__type__expr ::= 'some' '_'
operator__notation ::= 'infix'
operator__notation ::= 'prefix'
operator__notation ::= 'postfix'
parameter__decl_1 ::= identifier
parameter__decl_1 ::= '_'
identifier__opt ::=
identifier__opt ::= identifier
parameter__decl_2 ::= COLON parameter__type__expr
parameter__decl_2__opt ::=
parameter__decl_2__opt ::= parameter__decl_2
default__value__opt ::=
default__value__opt ::= default__value
parameter__decl ::= parameter__decl_1 identifier__opt parameter__decl_2__opt default__value__opt
parameter__list_1 ::= ',' parameter__decl
parameter__list_1__list ::=
parameter__list_1__list ::= parameter__list_1__list parameter__list_1
parameter__list ::= parameter__decl parameter__list_1__list
parameter__passing__convention ::= LET
parameter__passing__convention ::= INOUT
parameter__passing__convention ::= 'sink'
parameter__passing__convention ::= 'yielded'
parameter__passing__convention__opt ::=
parameter__passing__convention__opt ::= parameter__passing__convention
parameter__type__expr ::= parameter__passing__convention__opt type__expr
pattern ::= binding__pattern
pattern ::= expr__pattern
pattern ::= name__pattern
pattern ::= tuple__pattern
pattern ::= wildcard__pattern
prefix__operator__opt ::=
prefix__operator__opt ::= prefix__operator
prefix__expr ::= prefix__operator__opt suffix__expr
prefix__operator ::= operator
prefix__operator ::= 'async'
prefix__operator ::= 'await'
prefix__operator ::= '&'
type__argument__list__opt_1 ::=
type__argument__list__opt_1 ::= type__argument__list
primary__decl__ref ::= identifier__expr type__argument__list__opt_1
primary__expr ::= scalar__literal
primary__expr ::= compound__literal
primary__expr ::= primary__decl__ref
primary__expr ::= implicit__member__ref
primary__expr ::= lambda__expr
primary__expr ::= selection__expr
primary__expr ::= tuple__expr
primary__expr ::= 'nil'
primary__expr ::= '_'
product__type__body_1 ::= product__type__member__decl
product__type__body_1 ::= ';'
product__type__body_1__list ::=
product__type__body_1__list ::= product__type__body_1__list product__type__body_1
product__type__body ::= LBRACE product__type__body_1__list RBRACE
product__type__decl ::= product__type__head product__type__body
access__modifier__opt_5 ::=
access__modifier__opt_5 ::= access__modifier
generic__clause__opt_1 ::=
generic__clause__opt_1 ::= generic__clause
conformance__list__opt_1 ::=
conformance__list__opt_1 ::= conformance__list
product__type__head ::= access__modifier__opt_5 TYPE identifier generic__clause__opt_1 conformance__list__opt_1
product__type__member__decl ::= function__decl
product__type__member__decl ::= subscript__decl
product__type__member__decl ::= property__decl
product__type__member__decl ::= binding__decl
product__type__member__decl ::= product__type__decl
product__type__member__decl ::= type__alias__decl
property__annotation ::= COLON type__expr
property__decl ::= property__head property__annotation subscript__body
member__modifier__list_2 ::=
member__modifier__list_2 ::= member__modifier__list_2 member__modifier
property__head ::= member__modifier__list_2 'property' identifier
receiver__modifier ::= 'sink'
receiver__modifier ::= INOUT
receiver__modifier ::= 'yielded'
scalar__literal ::= boolean__literal
scalar__literal ::= integer__literal
scalar__literal ::= floating__point__literal
scalar__literal ::= string__literal
scalar__literal ::= unicode__scalar__literal
selection__expr ::= conditional__expr
selection__expr ::= match__expr
size__constraint__expr ::= expr
static__modifier ::= 'static'
stmt ::= brace__stmt
stmt ::= loop__stmt
stmt ::= jump__stmt
stmt ::= decl__stmt
stmt ::= expr
stored__projection__capability ::= LET
stored__projection__capability ::= INOUT
stored__projection__capability ::= 'yielded'
stored__projection__type__expr ::= '[' stored__projection__capability type__expr ']'
string__literal ::= simple__string
string__literal ::= multiline__string
subscript__body ::= brace__stmt
subscript__impl__list ::= subscript__impl
subscript__impl__list ::= subscript__impl__list subscript__impl
subscript__body ::= LBRACE subscript__impl__list RBRACE
call__argument__list__opt_1 ::=
call__argument__list__opt_1 ::= call__argument__list
subscript__call__expr ::= expr '[' call__argument__list__opt_1 ']'
subscript__decl ::= subscript__head subscript__signature subscript__body
member__modifier__list_3 ::=
member__modifier__list_3 ::= member__modifier__list_3 member__modifier
subscript__identifier__opt ::=
subscript__identifier__opt ::= subscript__identifier
generic__clause__opt_2 ::=
generic__clause__opt_2 ::= generic__clause
capture__list__opt_2 ::=
capture__list__opt_2 ::= capture__list
subscript__head ::= member__modifier__list_3 subscript__identifier__opt generic__clause__opt_2 capture__list__opt_2
subscript__identifier ::= 'subscript' identifier
subscript__identifier ::= operator__notation 'subscript' operator
brace__stmt__opt_1 ::=
brace__stmt__opt_1 ::= brace__stmt
subscript__impl ::= subscript__introducer brace__stmt__opt_1
subscript__introducer ::= LET
subscript__introducer ::= 'sink'
subscript__introducer ::= INOUT
subscript__introducer ::= 'set'
parameter__list__opt_1 ::=
parameter__list__opt_1 ::= parameter__list
q_var_q__opt ::=
q_var_q__opt ::= VAR
subscript__signature ::= LPAREN parameter__list__opt_1 RPAREN COLON q_var_q__opt type__expr
suffix__expr ::= primary__expr
suffix__expr ::= compound__expr
suffix__expr ::= suffix__expr operator
trait__annotation ::= COLON trait__composition
trait__body_1 ::= trait__requirement__decl
trait__body_1 ::= ';'
trait__body_1__list ::=
trait__body_1__list ::= trait__body_1__list trait__body_1
trait__body ::= LBRACE trait__body_1__list RBRACE
trait__composition_1 ::= '&' name__type__expr
trait__composition_1__list ::=
trait__composition_1__list ::= trait__composition_1__list trait__composition_1
trait__composition ::= name__type__expr trait__composition_1__list
trait__decl ::= trait__head trait__body
access__modifier__opt_6 ::=
access__modifier__opt_6 ::= access__modifier
trait__refinement__list__opt ::=
trait__refinement__list__opt ::= trait__refinement__list
trait__head ::= access__modifier__opt_6 'trait' identifier trait__refinement__list__opt
trait__refinement__list_1 ::= ',' name__type__expr
trait__refinement__list_1__list ::=
trait__refinement__list_1__list ::= trait__refinement__list_1__list trait__refinement__list_1
trait__refinement__list ::= COLON name__type__expr trait__refinement__list_1__list
trait__requirement__decl ::= associated__decl
trait__requirement__decl ::= function__decl
trait__requirement__decl ::= subscript__decl
trait__requirement__decl ::= property__decl
tuple__expr ::= LPAREN tuple__expr__element__list RPAREN
tuple__expr__element_1 ::= identifier COLON
tuple__expr__element_1__opt ::=
tuple__expr__element_1__opt ::= tuple__expr__element_1
tuple__expr__element ::= tuple__expr__element_1__opt expr
tuple__expr__element__list_1 ::= ',' tuple__expr__element
tuple__expr__element__list_1__opt ::=
tuple__expr__element__list_1__opt ::= tuple__expr__element__list_1
tuple__expr__element__list ::= tuple__expr__element tuple__expr__element__list_1__opt
tuple__pattern ::= LPAREN tuple__pattern__element__list RPAREN
tuple__pattern__element_1 ::= identifier COLON
tuple__pattern__element_1__opt ::=
tuple__pattern__element_1__opt ::= tuple__pattern__element_1
tuple__pattern__element ::= tuple__pattern__element_1__opt pattern
tuple__pattern__element__list_1 ::= ',' tuple__pattern__element
tuple__pattern__element__list_1__opt ::=
tuple__pattern__element__list_1__opt ::= tuple__pattern__element__list_1
tuple__pattern__element__list ::= tuple__pattern__element tuple__pattern__element__list_1__opt
tuple__type__element_1 ::= identifier COLON
tuple__type__element_1__opt ::=
tuple__type__element_1__opt ::= tuple__type__element_1
tuple__type__element ::= tuple__type__element_1__opt type__expr
tuple__type__element__list_1 ::= ',' tuple__type__element
tuple__type__element__list_1__opt ::=
tuple__type__element__list_1__opt ::= tuple__type__element__list_1
tuple__type__element__list ::= tuple__type__element tuple__type__element__list_1__opt
tuple__type__expr ::= LPAREN tuple__type__element__list RPAREN
type__alias__body ::= '=' type__expr
type__alias__body ::= '=' union__decl
type__alias__decl ::= type__alias__head type__alias__body
access__modifier__opt_7 ::=
access__modifier__opt_7 ::= access__modifier
generic__clause__opt_3 ::=
generic__clause__opt_3 ::= generic__clause
type__alias__head ::= access__modifier__opt_7 'typealias' identifier generic__clause__opt_3
type__argument_1 ::= identifier COLON
type__argument_1__opt ::=
type__argument_1__opt ::= type__argument_1
type__argument ::= type__argument_1__opt type__expr
type__argument__list_1 ::= ',' type__argument
type__argument__list_1__list ::=
type__argument__list_1__list ::= type__argument__list_1__list type__argument__list_1
type__argument__list ::= '<' type__argument type__argument__list_1__list '>'
type__casting__operator ::= 'as'
type__casting__operator ::= 'as!'
type__casting__operator ::= '_as!!'
type__expr ::= async__type__expr
type__expr ::= buffer__type__expr
type__expr ::= conformance__lens__type__expr
type__expr ::= existential__type__expr
type__expr ::= opaque__type__expr
type__expr ::= indirect__type__expr
type__expr ::= lambda__type__expr
type__expr ::= name__type__expr
type__expr ::= stored__projection__type__expr
type__expr ::= tuple__type__expr
type__expr ::= union__type__expr
type__expr ::= wildcard__type__expr
type__identifier ::= identifier
union__decl_1 ::= '|' product__type__decl
union__decl_1__list ::=
union__decl_1__list ::= union__decl_1__list union__decl_1
union__decl ::= product__type__decl union__decl_1__list
union__type__expr_1 ::= '|' type__expr
union__type__expr_1__list ::= union__type__expr_1
union__type__expr_1__list ::= union__type__expr_1__list union__type__expr_1
union__type__expr ::= type__expr union__type__expr_1__list
value__member__expr ::= expr DOT primary__decl__ref
value__member__expr ::= type__expr DOT primary__decl__ref
where__clause ::= 'where' where__clause__constraint
where__clause__constraint ::= equality__constraint
where__clause__constraint ::= conformance__constraint
where__clause__constraint ::= size__constraint__expr
while__condition__item ::= binding__pattern '=' expr
while__condition__item ::= expr
while__condition__list_1 ::= ',' while__condition__item
while__condition__list_1__list ::=
while__condition__list_1__list ::= while__condition__list_1__list while__condition__list_1
while__condition__list ::= while__condition__item while__condition__list_1__list
while__stmt ::= 'while' while__condition__list brace__stmt
wildcard__pattern ::= '_'
wildcard__type__expr ::= '_'

unicorn ~ [^\d\D]
TYPE ~ unicorn
FUN ~ unicorn
VAR ~ unicorn
LET ~ unicorn
INOUT ~ unicorn
LBRACE ~ unicorn
RBRACE ~ unicorn
LPAREN ~ unicorn
RPAREN ~ unicorn
COLON ~ unicorn
ARROW ~ unicorn
DOT ~ unicorn

# Lexemes from original
  binary__literal ~ unicorn
  decimal__floating__point__literal ~ unicorn
  decimal__literal ~ unicorn
  function__entity__identifier ~ unicorn
  hexadecimal__literal ~ unicorn
  identifier__token ~ unicorn
  impl__identifier ~ unicorn
  multiline__string ~ unicorn
  octal__literal ~ unicorn
  operator__entity__identifier ~ unicorn
  operator ~ unicorn
  simple__string ~ unicorn
  unicode__scalar__literal ~ unicorn

END_OF_SOURCE

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
my @terminals = (
     [ 'TYPE', "'type'" ],
     [ 'identifier__token', 'A' ],
     [ 'LBRACE', '{' ],
     [ 'VAR', "'var'" ],
     [ 'identifier__token', 'a' ],
     [ 'COLON', ':' ],
     [ 'identifier__token', 'Int' ],

     [ 'FUN', "'fun'" ],
     [ 'identifier__token', 'foo' ],
     [ 'LPAREN', '(' ],
     [ 'identifier__token', 'a' ],
     [ 'COLON', ':' ],
     [ 'identifier__token', 'Int' ],
     [ 'RPAREN', ')' ],
     [ 'LBRACE', '{' ],
     [ 'identifier__token', 'a' ],
     [ 'DOT', '.' ],
     [ 'identifier__token', 'Int' ],
     [ 'LPAREN', '(' ],
     [ 'RPAREN', ')' ],
     [ 'RBRACE', '}' ],

     [ 'FUN', "'fun'" ],
     [ 'identifier__token', 'foo' ],
     [ 'LPAREN', '(' ],
     [ 'identifier__token', 'a' ],
     [ 'COLON', ':' ],
     [ 'identifier__token', 'Int' ],
     [ 'RPAREN', ')' ],
     [ 'ARROW', '->' ],
     [ 'identifier__token', 'Int' ],
     [ 'LBRACE', '{' ],

     [ 'LET', 'let' ],
     [ 'LBRACE', '{' ],
     [ 'identifier__token', 'a' ],
     [ 'operator', '+' ],
     [ 'identifier__token', 'b' ],
     [ 'RBRACE', '}' ],

     [ 'INOUT', 'inout' ],
     [ 'LBRACE', '{' ],
     [ 'identifier__token', 'b' ],
     [ 'operator', '+=' ],
     [ 'identifier__token', 'a' ],
     [ 'RBRACE', '}' ],

     [ 'RBRACE', '}' ],

     [ 'RBRACE', '}' ],

);

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

$recce->read( \$string, 0, 0 );

my $length = length $string;
pos $string = 0;

TOKEN: for my $t (@terminals) {
    my ( $token_name, $long_name ) = @{$t};
    my $lexeme = $1;
    if ( not defined $recce->lexeme_read( $token_name, undef, 1, $long_name ) ) {
        die qq{Parser rejected token "$long_name"};
    }
}

say $recce->show_progress();

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
