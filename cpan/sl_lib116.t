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

# Dave Abrahams Libmarpa issue 116

use 5.010001;
use strict;
use warnings;
use Test::More tests => 1;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $source = <<'END_OF_SOURCE';
:default ::= action => ::array
:start ::= module__definition 
access__modifier ::= 'public'
associated__decl ::= associated__type__decl
associated__decl ::= associated__size__decl
where__clause__opt ::=
where__clause__opt ::= where__clause
associated__size__decl_1 ::= '=' whitespace__opt expr
associated__size__decl_1__opt ::=
associated__size__decl_1__opt ::= associated__size__decl_1
associated__size__decl ::= associated__size__head whitespace__opt where__clause__opt whitespace__opt associated__size__decl_1__opt
associated__size__head ::= 'size' whitespace__opt identifier
associated__type__constraints ::= conformance__list
conformance__list__opt ::=
conformance__list__opt ::= conformance__list
associated__type__constraints ::= conformance__list__opt whitespace__opt where__clause
associated__type__constraints__opt ::=
associated__type__constraints__opt ::= associated__type__constraints
associated__type__decl_1 ::= '=' whitespace__opt type__expr
associated__type__decl_1__opt ::=
associated__type__decl_1__opt ::= associated__type__decl_1
associated__type__decl ::= associated__type__head whitespace__opt associated__type__constraints__opt whitespace__opt associated__type__decl_1__opt
associated__type__head ::= 'type' whitespace__opt identifier
async__type__expr ::= 'async' whitespace__opt type__expr
binding__annotation ::= ':' whitespace__opt type__expr
binding__initializer__opt ::=
binding__initializer__opt ::= binding__initializer
binding__decl ::= binding__head whitespace__opt binding__initializer__opt
access__modifier__opt ::=
access__modifier__opt ::= access__modifier
member__modifier__list ::=
member__modifier__list ::= member__modifier__list whitespace__opt member__modifier
binding__head ::= access__modifier__opt whitespace__opt member__modifier__list whitespace__opt binding__pattern
binding__initializer ::= '=' whitespace__opt expr
binding__introducer ::= 'let'
binding__introducer ::= 'var'
binding__introducer ::= 'sink'
binding__introducer ::= 'inout'
binding__pattern_1 ::= tuple__pattern
binding__pattern_1 ::= wildcard__pattern
binding__pattern_1 ::= identifier
binding__annotation__opt ::=
binding__annotation__opt ::= binding__annotation
binding__pattern ::= binding__introducer whitespace__opt binding__pattern_1 whitespace__opt binding__annotation__opt
block__comment ::= block__comment__open '*/'
block__comment ::= block__comment__open block__comment '*/'
boolean__literal ::= 'true'
boolean__literal ::= 'false'
stmt__list__opt ::=
stmt__list__opt ::= stmt__list
brace__stmt ::= '{' whitespace__opt stmt__list__opt whitespace__opt '}'
buffer__component__list_1 ::= ',' whitespace__opt expr
buffer__component__list_1__list ::=
buffer__component__list_1__list ::= buffer__component__list_1__list whitespace__opt buffer__component__list_1
q_comma_q__opt ::=
q_comma_q__opt ::= ','
buffer__component__list ::= expr whitespace__opt buffer__component__list_1__list whitespace__opt q_comma_q__opt
buffer__component__list__opt ::=
buffer__component__list__opt ::= buffer__component__list
buffer__literal ::= '[' whitespace__opt buffer__component__list__opt whitespace__opt ']'
expr__opt ::=
expr__opt ::= expr
buffer__type__expr ::= type__expr whitespace__opt '[' whitespace__opt expr__opt whitespace__opt ']'
call__argument_1 ::= identifier whitespace__opt ':'
call__argument_1__opt ::=
call__argument_1__opt ::= call__argument_1
call__argument ::= call__argument_1__opt whitespace__opt expr
call__argument__list_1 ::= ',' whitespace__opt call__argument
call__argument__list_1__list ::=
call__argument__list_1__list ::= call__argument__list_1__list whitespace__opt call__argument__list_1
call__argument__list ::= call__argument whitespace__opt call__argument__list_1__list
capture__list_1 ::= ',' whitespace__opt binding__decl
capture__list_1__list ::=
capture__list_1__list ::= capture__list_1__list whitespace__opt capture__list_1
capture__list ::= '[' whitespace__opt binding__decl whitespace__opt capture__list_1__list whitespace__opt ']'
compound__expr ::= value__member__expr
compound__expr ::= function__call__expr
compound__expr ::= subscript__call__expr
compound__expr ::= primary__expr
compound__literal ::= buffer__literal
compound__literal ::= map__literal
cond__binding__body ::= jump__stmt
cond__binding__body ::= expr
cond__binding__stmt ::= binding__pattern whitespace__opt '??' whitespace__opt cond__binding__body
conditional__clause_1 ::= ',' whitespace__opt conditional__clause__item
conditional__clause_1__list ::=
conditional__clause_1__list ::= conditional__clause_1__list whitespace__opt conditional__clause_1
conditional__clause ::= conditional__clause__item whitespace__opt conditional__clause_1__list
conditional__clause__item ::= binding__pattern whitespace__opt '=' whitespace__opt expr
conditional__clause__item ::= expr
conditional__tail__opt ::=
conditional__tail__opt ::= conditional__tail
conditional__expr ::= 'if' whitespace__opt conditional__clause whitespace__opt brace__stmt whitespace__opt conditional__tail__opt
conditional__tail ::= 'else' whitespace__opt conditional__expr
conditional__tail ::= 'else' whitespace__opt brace__stmt
conformance__body_1 ::= conformance__member__decl
conformance__body_1 ::= ';'
conformance__body_1__list ::=
conformance__body_1__list ::= conformance__body_1__list whitespace__opt conformance__body_1
conformance__body ::= '{' whitespace__opt conformance__body_1__list whitespace__opt '}'
conformance__constraint ::= name__type__expr whitespace__opt ':' whitespace__opt trait__composition
conformance__decl ::= conformance__head whitespace__opt conformance__body
access__modifier__opt_1 ::=
access__modifier__opt_1 ::= access__modifier
where__clause__opt_1 ::=
where__clause__opt_1 ::= where__clause
conformance__head ::= access__modifier__opt_1 whitespace__opt 'conformance' whitespace__opt type__expr whitespace__opt conformance__list whitespace__opt where__clause__opt_1
conformance__lens__type__expr ::= type__expr whitespace__opt '::' whitespace__opt type__identifier
conformance__list_1 ::= ',' whitespace__opt name__type__expr
conformance__list_1__list ::=
conformance__list_1__list ::= conformance__list_1__list whitespace__opt conformance__list_1
conformance__list ::= ':' whitespace__opt name__type__expr whitespace__opt conformance__list_1__list
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
default__value ::= '=' whitespace__opt expr
do__while__stmt ::= 'do' whitespace__opt brace__stmt whitespace__opt 'while' whitespace__opt expr
entity__identifier ::= identifier
entity__identifier ::= function__entity__identifier
entity__identifier ::= operator__entity__identifier
equality__constraint ::= name__type__expr whitespace__opt '==' whitespace__opt type__expr
where__clause__opt_2 ::=
where__clause__opt_2 ::= where__clause
existential__type__expr ::= 'any' whitespace__opt trait__composition whitespace__opt where__clause__opt_2
infix__tail__opt ::=
infix__tail__opt ::= infix__tail
expr ::= prefix__expr whitespace__opt infix__tail__opt
expr__pattern ::= expr
extension__body_1 ::= extension__member__decl
extension__body_1 ::= ';'
extension__body_1__list ::=
extension__body_1__list ::= extension__body_1__list whitespace__opt extension__body_1
extension__body ::= '{' whitespace__opt extension__body_1__list whitespace__opt '}'
extension__decl ::= extension__head whitespace__opt extension__body
access__modifier__opt_2 ::=
access__modifier__opt_2 ::= access__modifier
where__clause__opt_3 ::=
where__clause__opt_3 ::= where__clause
extension__head ::= access__modifier__opt_2 whitespace__opt 'extension' whitespace__opt type__expr whitespace__opt where__clause__opt_3
extension__member__decl ::= function__decl
extension__member__decl ::= subscript__decl
extension__member__decl ::= product__type__decl
extension__member__decl ::= type__alias__decl
floating__point__literal ::= decimal__floating__point__literal
for__counter__decl ::= pattern
for__range ::= 'in' whitespace__opt expr
loop__filter__opt ::=
loop__filter__opt ::= loop__filter
for__stmt ::= 'for' whitespace__opt for__counter__decl whitespace__opt for__range whitespace__opt loop__filter__opt whitespace__opt brace__stmt
function__body ::= function__bundle__body
function__body ::= brace__stmt
method__impl__list ::= method__impl
method__impl__list ::= method__impl__list whitespace__opt method__impl
function__bundle__body ::= '{' whitespace__opt method__impl__list whitespace__opt '}'
call__argument__list__opt ::=
call__argument__list__opt ::= call__argument__list
function__call__expr ::= expr whitespace__opt '(' whitespace__opt call__argument__list__opt whitespace__opt ')'
function__decl ::= memberwise__ctor__decl
function__body__opt ::=
function__body__opt ::= function__body
function__decl ::= function__head whitespace__opt function__signature whitespace__opt function__body__opt
access__modifier__opt_3 ::=
access__modifier__opt_3 ::= access__modifier
member__modifier__list_1 ::=
member__modifier__list_1 ::= member__modifier__list_1 whitespace__opt member__modifier
generic__clause__opt ::=
generic__clause__opt ::= generic__clause
capture__list__opt ::=
capture__list__opt ::= capture__list
function__head ::= access__modifier__opt_3 whitespace__opt member__modifier__list_1 whitespace__opt function__identifier whitespace__opt generic__clause__opt whitespace__opt capture__list__opt
function__identifier ::= 'init'
function__identifier ::= 'deinit'
function__identifier ::= 'fun' whitespace__opt identifier
function__identifier ::= operator__notation whitespace__opt 'fun' whitespace__opt operator
parameter__list__opt ::=
parameter__list__opt ::= parameter__list
function__signature_1 ::= '__>' whitespace__opt type__expr
function__signature_1__opt ::=
function__signature_1__opt ::= function__signature_1
function__signature ::= '(' whitespace__opt parameter__list__opt whitespace__opt ')' whitespace__opt function__signature_1__opt
generic__clause_1 ::= ',' whitespace__opt generic__parameter
generic__clause_1__list ::=
generic__clause_1__list ::= generic__clause_1__list whitespace__opt generic__clause_1
where__clause__opt_4 ::=
where__clause__opt_4 ::= where__clause
generic__clause ::= '<' whitespace__opt generic__parameter whitespace__opt generic__clause_1__list whitespace__opt where__clause__opt_4 whitespace__opt '>'
generic__parameter ::= generic__type__parameter
generic__parameter ::= generic__size__parameter
generic__size__parameter ::= identifier whitespace__opt ':' whitespace__opt 'size'
dot_x_3__opt ::=
dot_x_3__opt ::= '...'
trait__annotation__opt ::=
trait__annotation__opt ::= trait__annotation
generic__type__parameter ::= identifier whitespace__opt dot_x_3__opt whitespace__opt trait__annotation__opt
horizontal__space ::= hspace
horizontal__space ::= single__line__comment
horizontal__space ::= block__comment
horizontal__space__list ::=
horizontal__space__list ::= horizontal__space__list horizontal__space
horizontal__space__opt ::= horizontal__space__list
identifier ::= identifier__token
identifier ::= contextual__keyword
impl__identifier__opt ::=
impl__identifier__opt ::= impl__identifier
identifier__expr ::= entity__identifier whitespace__opt impl__identifier__opt
implicit__member__ref ::= '.' whitespace__opt primary__decl__ref
import__statement ::= 'import' whitespace__opt identifier
indirect__type__expr ::= 'indirect' whitespace__opt type__expr
infix__item ::= infix__operator whitespace__opt prefix__expr
infix__item ::= type__casting__operator whitespace__opt type__expr
infix__operator ::= operator
infix__operator ::= '='
infix__operator ::= '=='
infix__operator ::= '<'
infix__operator ::= '>'
infix__operator ::= '..<'
infix__operator ::= '...'
infix__item__list ::= infix__item
infix__item__list ::= infix__item__list whitespace__opt infix__item
infix__tail ::= infix__item__list
integer__literal ::= binary__literal
integer__literal ::= octal__literal
integer__literal ::= decimal__literal
integer__literal ::= hexadecimal__literal
jump__stmt ::= cond__binding__stmt
expr__opt_1 ::=
expr__opt_1 ::= expr
jump__stmt ::= 'return' horizontal__space__opt expr__opt_1
jump__stmt ::= 'yield' horizontal__space__opt expr
jump__stmt ::= 'break'
jump__stmt ::= 'continue'
lambda__body ::= brace__stmt
lambda__environment ::= '[' whitespace__opt type__expr whitespace__opt ']'
capture__list__opt_1 ::=
capture__list__opt_1 ::= capture__list
lambda__expr ::= 'fun' whitespace__opt capture__list__opt_1 whitespace__opt function__signature whitespace__opt lambda__body
call__argument_1__opt_1 ::=
call__argument_1__opt_1 ::= call__argument_1
lambda__parameter ::= call__argument_1__opt_1 whitespace__opt type__expr
lambda__receiver__effect ::= 'inout'
lambda__receiver__effect ::= 'sink'
lambda__environment__opt ::=
lambda__environment__opt ::= lambda__environment
lamda__parameter__list__opt ::=
lamda__parameter__list__opt ::= lamda__parameter__list
lambda__receiver__effect__opt ::=
lambda__receiver__effect__opt ::= lambda__receiver__effect
lambda__type__expr ::= lambda__environment__opt whitespace__opt '(' whitespace__opt lamda__parameter__list__opt whitespace__opt ')' whitespace__opt lambda__receiver__effect__opt whitespace__opt '__>' whitespace__opt type__expr
lamda__parameter__list_1 ::= ',' whitespace__opt lambda__parameter
lamda__parameter__list_1__list ::=
lamda__parameter__list_1__list ::= lamda__parameter__list_1__list whitespace__opt lamda__parameter__list_1
lamda__parameter__list ::= lambda__parameter whitespace__opt lamda__parameter__list_1__list
loop__filter ::= 'where' whitespace__opt expr
loop__stmt ::= do__while__stmt
loop__stmt ::= while__stmt
loop__stmt ::= for__stmt
map__component ::= expr whitespace__opt ':' whitespace__opt expr
map__component__list_1 ::= ',' whitespace__opt map__component
map__component__list_1__list ::=
map__component__list_1__list ::= map__component__list_1__list whitespace__opt map__component__list_1
q_comma_q__opt_1 ::=
q_comma_q__opt_1 ::= ','
map__component__list ::= map__component whitespace__opt map__component__list_1__list whitespace__opt q_comma_q__opt_1
map__literal ::= '[' whitespace__opt map__component__list whitespace__opt ']'
map__literal ::= '[' whitespace__opt ':' whitespace__opt ']'
match__case ::= pattern whitespace__opt brace__stmt
match__expr_1 ::= match__case
match__expr_1 ::= ';'
match__expr_1__list ::=
match__expr_1__list ::= match__expr_1__list whitespace__opt match__expr_1
match__expr ::= 'match' whitespace__opt expr whitespace__opt '{' whitespace__opt match__expr_1__list whitespace__opt '}'
member__modifier ::= receiver__modifier
member__modifier ::= static__modifier
memberwise__ctor__decl ::= 'memberwise' whitespace__opt 'init'
brace__stmt__opt ::=
brace__stmt__opt ::= brace__stmt
method__impl ::= method__introducer whitespace__opt brace__stmt__opt
method__introducer ::= 'let'
method__introducer ::= 'sink'
method__introducer ::= 'inout'
module__definition_1 ::= module__scope__decl
module__definition_1 ::= import__statement
module__definition_1__list ::=
module__definition_1__list ::= module__definition_1__list whitespace__opt module__definition_1
module__definition ::= whitespace__opt whitespace__opt module__definition_1__list whitespace__opt whitespace__opt
module__scope__decl ::= namespace__decl
module__scope__decl ::= trait__decl
module__scope__decl ::= type__alias__decl
module__scope__decl ::= product__type__decl
module__scope__decl ::= extension__decl
module__scope__decl ::= conformance__decl
module__scope__decl ::= binding__decl
module__scope__decl ::= function__decl
module__scope__decl ::= subscript__decl
name__type__expr_1 ::= type__expr whitespace__opt '.'
name__type__expr_1__opt ::=
name__type__expr_1__opt ::= name__type__expr_1
type__argument__list__opt ::=
type__argument__list__opt ::= type__argument__list
name__type__expr ::= name__type__expr_1__opt whitespace__opt type__identifier whitespace__opt type__argument__list__opt
module__scope__decl__list ::=
module__scope__decl__list ::= module__scope__decl__list whitespace__opt module__scope__decl
namespace__body ::= '{' whitespace__opt module__scope__decl__list whitespace__opt '}'
namespace__decl ::= namespace__head whitespace__opt namespace__body
access__modifier__opt_4 ::=
access__modifier__opt_4 ::= access__modifier
namespace__head ::= access__modifier__opt_4 whitespace__opt 'namespace' whitespace__opt identifier
where__clause__opt_5 ::=
where__clause__opt_5 ::= where__clause
opaque__type__expr ::= 'some' whitespace__opt trait__composition whitespace__opt where__clause__opt_5
opaque__type__expr ::= 'some' whitespace__opt '_'
operator__notation ::= 'infix'
operator__notation ::= 'prefix'
operator__notation ::= 'postfix'
parameter__decl_1 ::= identifier
parameter__decl_1 ::= '_'
identifier__opt ::=
identifier__opt ::= identifier
parameter__decl_2 ::= ':' whitespace__opt parameter__type__expr
parameter__decl_2__opt ::=
parameter__decl_2__opt ::= parameter__decl_2
default__value__opt ::=
default__value__opt ::= default__value
parameter__decl ::= parameter__decl_1 whitespace__opt identifier__opt whitespace__opt parameter__decl_2__opt whitespace__opt default__value__opt
parameter__list_1 ::= ',' whitespace__opt parameter__decl
parameter__list_1__list ::=
parameter__list_1__list ::= parameter__list_1__list whitespace__opt parameter__list_1
parameter__list ::= parameter__decl whitespace__opt parameter__list_1__list
parameter__passing__convention ::= 'let'
parameter__passing__convention ::= 'inout'
parameter__passing__convention ::= 'sink'
parameter__passing__convention ::= 'yielded'
parameter__passing__convention__opt ::=
parameter__passing__convention__opt ::= parameter__passing__convention
parameter__type__expr ::= parameter__passing__convention__opt whitespace__opt type__expr
pattern ::= binding__pattern
pattern ::= expr__pattern
pattern ::= tuple__pattern
pattern ::= wildcard__pattern
prefix__operator__opt ::=
prefix__operator__opt ::= prefix__operator
prefix__expr ::= prefix__operator__opt suffix__expr
prefix__operator ::= operator
prefix__operator ::= 'async'
prefix__operator ::= 'await'
prefix__operator ::= AMPERSAND
type__argument__list__opt_1 ::=
type__argument__list__opt_1 ::= type__argument__list
primary__decl__ref ::= identifier__expr whitespace__opt type__argument__list__opt_1
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
product__type__body_1__list ::= product__type__body_1__list whitespace__opt product__type__body_1
product__type__body ::= '{' whitespace__opt product__type__body_1__list whitespace__opt '}'
product__type__decl ::= product__type__head whitespace__opt product__type__body
access__modifier__opt_5 ::=
access__modifier__opt_5 ::= access__modifier
generic__clause__opt_1 ::=
generic__clause__opt_1 ::= generic__clause
conformance__list__opt_1 ::=
conformance__list__opt_1 ::= conformance__list
product__type__head ::= access__modifier__opt_5 whitespace__opt 'type' whitespace__opt identifier whitespace__opt generic__clause__opt_1 whitespace__opt conformance__list__opt_1
product__type__member__decl ::= function__decl
product__type__member__decl ::= subscript__decl
product__type__member__decl ::= property__decl
product__type__member__decl ::= binding__decl
product__type__member__decl ::= product__type__decl
product__type__member__decl ::= type__alias__decl
property__annotation ::= ':' whitespace__opt type__expr
property__decl ::= property__head whitespace__opt property__annotation whitespace__opt subscript__body
member__modifier__list_2 ::=
member__modifier__list_2 ::= member__modifier__list_2 whitespace__opt member__modifier
property__head ::= member__modifier__list_2 whitespace__opt 'property' whitespace__opt identifier
receiver__modifier ::= 'sink'
receiver__modifier ::= 'inout'
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
stmt__list ::= stmt
stmt__list ::= stmt__list stmt__separator stmt
stmt__separator_1 ::= newlines horizontal__space__opt
stmt__separator_1__list ::=
stmt__separator_1__list ::= stmt__separator_1__list stmt__separator_1
stmt__separator ::= horizontal__space__opt stmt__separator_1__list
stmt__separator_2 ::= ';' whitespace__opt
stmt__separator_2__list ::=
stmt__separator_2__list ::= stmt__separator_2__list stmt__separator_2
stmt__separator ::= whitespace__opt stmt__separator_2__list
stored__projection__capability ::= 'let'
stored__projection__capability ::= 'inout'
stored__projection__capability ::= 'yielded'
stored__projection__type__expr ::= '[' whitespace__opt stored__projection__capability whitespace__opt type__expr whitespace__opt ']'
string__literal ::= simple__string
string__literal ::= multiline__string
subscript__body ::= brace__stmt
subscript__impl__list ::= subscript__impl
subscript__impl__list ::= subscript__impl__list whitespace__opt subscript__impl
subscript__body ::= '{' whitespace__opt subscript__impl__list whitespace__opt '}'
call__argument__list__opt_1 ::=
call__argument__list__opt_1 ::= call__argument__list
subscript__call__expr ::= expr whitespace__opt '[' whitespace__opt call__argument__list__opt_1 whitespace__opt ']'
subscript__decl ::= subscript__head whitespace__opt subscript__signature whitespace__opt subscript__body
member__modifier__list_3 ::=
member__modifier__list_3 ::= member__modifier__list_3 whitespace__opt member__modifier
subscript__identifier__opt ::=
subscript__identifier__opt ::= subscript__identifier
generic__clause__opt_2 ::=
generic__clause__opt_2 ::= generic__clause
capture__list__opt_2 ::=
capture__list__opt_2 ::= capture__list
subscript__head ::= member__modifier__list_3 whitespace__opt subscript__identifier__opt whitespace__opt generic__clause__opt_2 whitespace__opt capture__list__opt_2
subscript__identifier ::= 'subscript' whitespace__opt identifier
subscript__identifier ::= operator__notation whitespace__opt 'subscript' whitespace__opt operator
brace__stmt__opt_1 ::=
brace__stmt__opt_1 ::= brace__stmt
subscript__impl ::= subscript__introducer whitespace__opt brace__stmt__opt_1
subscript__introducer ::= 'let'
subscript__introducer ::= 'sink'
subscript__introducer ::= 'inout'
subscript__introducer ::= 'set'
parameter__list__opt_1 ::=
parameter__list__opt_1 ::= parameter__list
q_var_q__opt ::=
q_var_q__opt ::= 'var'
subscript__signature ::= '(' whitespace__opt parameter__list__opt_1 whitespace__opt ')' whitespace__opt ':' whitespace__opt q_var_q__opt whitespace__opt type__expr
suffix__expr ::= compound__expr
suffix__expr ::= suffix__expr operator
trait__annotation ::= ':' whitespace__opt trait__composition
trait__body_1 ::= trait__requirement__decl
trait__body_1 ::= ';'
trait__body_1__list ::=
trait__body_1__list ::= trait__body_1__list whitespace__opt trait__body_1
trait__body ::= '{' whitespace__opt trait__body_1__list whitespace__opt '}'

trait__composition_1 ::= AMPERSAND whitespace__opt name__type__expr
trait__composition_1__list ::= trait__composition_1__list whitespace__opt trait__composition_1
# Missing rule in original?
trait__composition_1__list ::= trait__composition_1

trait__composition ::= name__type__expr whitespace__opt trait__composition_1__list
trait__decl ::= trait__head whitespace__opt trait__body
access__modifier__opt_6 ::=
access__modifier__opt_6 ::= access__modifier
trait__refinement__list__opt ::=
trait__refinement__list__opt ::= trait__refinement__list
trait__head ::= access__modifier__opt_6 whitespace__opt 'trait' whitespace__opt identifier whitespace__opt trait__refinement__list__opt
conformance__list_1__list_1 ::=
conformance__list_1__list_1 ::= conformance__list_1__list_1 whitespace__opt conformance__list_1
trait__refinement__list ::= ':' whitespace__opt name__type__expr whitespace__opt conformance__list_1__list_1
trait__requirement__decl ::= associated__decl
trait__requirement__decl ::= function__decl
trait__requirement__decl ::= subscript__decl
trait__requirement__decl ::= property__decl
tuple__expr ::= '(' whitespace__opt tuple__expr__element__list whitespace__opt ')'
call__argument_1__opt_2 ::=
call__argument_1__opt_2 ::= call__argument_1
tuple__expr__element ::= call__argument_1__opt_2 whitespace__opt expr
tuple__expr__element__list_1 ::= ',' whitespace__opt tuple__expr__element
tuple__expr__element__list_1__opt ::=
tuple__expr__element__list_1__opt ::= tuple__expr__element__list_1
tuple__expr__element__list ::= tuple__expr__element whitespace__opt tuple__expr__element__list_1__opt
tuple__pattern ::= '(' whitespace__opt tuple__pattern__element__list whitespace__opt ')'
call__argument_1__opt_3 ::=
call__argument_1__opt_3 ::= call__argument_1
tuple__pattern__element ::= call__argument_1__opt_3 whitespace__opt pattern
tuple__pattern__element__list_1 ::= ',' whitespace__opt tuple__pattern__element
tuple__pattern__element__list_1__opt ::=
tuple__pattern__element__list_1__opt ::= tuple__pattern__element__list_1
tuple__pattern__element__list ::= tuple__pattern__element whitespace__opt tuple__pattern__element__list_1__opt
call__argument_1__opt_4 ::=
call__argument_1__opt_4 ::= call__argument_1
tuple__type__element ::= call__argument_1__opt_4 whitespace__opt type__expr
tuple__type__element__list_1 ::= ',' whitespace__opt tuple__type__element
tuple__type__element__list_1__opt ::=
tuple__type__element__list_1__opt ::= tuple__type__element__list_1
tuple__type__element__list ::= tuple__type__element whitespace__opt tuple__type__element__list_1__opt
tuple__type__expr ::= '(' whitespace__opt tuple__type__element__list whitespace__opt ')'
type__alias__body ::= '=' whitespace__opt type__expr
type__alias__body ::= '=' whitespace__opt union__decl
type__alias__decl ::= type__alias__head whitespace__opt type__alias__body
access__modifier__opt_7 ::=
access__modifier__opt_7 ::= access__modifier
generic__clause__opt_3 ::=
generic__clause__opt_3 ::= generic__clause
type__alias__head ::= access__modifier__opt_7 whitespace__opt 'typealias' whitespace__opt identifier whitespace__opt generic__clause__opt_3
call__argument_1__opt_5 ::=
call__argument_1__opt_5 ::= call__argument_1
type__argument ::= call__argument_1__opt_5 whitespace__opt type__expr
type__argument__list_1 ::= ',' whitespace__opt type__argument
type__argument__list_1__list ::=
type__argument__list_1__list ::= type__argument__list_1__list whitespace__opt type__argument__list_1
type__argument__list ::= '<' whitespace__opt type__argument whitespace__opt type__argument__list_1__list whitespace__opt '>'
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
union__decl_1 ::= '|' whitespace__opt product__type__decl
union__decl_1__list ::=
union__decl_1__list ::= union__decl_1__list whitespace__opt union__decl_1
union__decl ::= product__type__decl whitespace__opt union__decl_1__list
union__type__expr_1 ::= '|' whitespace__opt type__expr
union__type__expr_1__list ::= union__type__expr_1
union__type__expr_1__list ::= union__type__expr_1__list whitespace__opt union__type__expr_1
union__type__expr ::= type__expr whitespace__opt union__type__expr_1__list
value__member__expr ::= expr whitespace__opt '.' whitespace__opt primary__decl__ref
value__member__expr ::= type__expr whitespace__opt '.' whitespace__opt primary__decl__ref
where__clause ::= 'where' whitespace__opt where__clause__constraint
where__clause__constraint ::= equality__constraint
where__clause__constraint ::= conformance__constraint
where__clause__constraint ::= size__constraint__expr
while__condition__item ::= binding__pattern whitespace__opt '=' whitespace__opt expr
while__condition__item ::= expr
while__condition__list_1 ::= ',' whitespace__opt while__condition__item
while__condition__list_1__list ::=
while__condition__list_1__list ::= while__condition__list_1__list whitespace__opt while__condition__list_1
while__condition__list ::= while__condition__item whitespace__opt while__condition__list_1__list
while__stmt ::= 'while' whitespace__opt while__condition__list whitespace__opt brace__stmt
whitespace__opt_1 ::= horizontal__space
whitespace__opt_1 ::= newlines
whitespace__opt_1__list ::=
whitespace__opt_1__list ::= whitespace__opt_1__list whitespace__opt_1
whitespace__opt ::= whitespace__opt_1__list
wildcard__pattern ::= '_'
wildcard__type__expr ::= '_'

unicorn ~ [^\d\D]
AMPERSAND ~ unicorn

# Lexemes from original
  simple__string ~ unicorn
  decimal__literal ~ unicorn
  impl__identifier ~ unicorn
  newlines ~ unicorn
  identifier__token ~ unicorn
  hspace ~ unicorn
  binary__literal ~ unicorn
  unicode__scalar__literal ~ unicorn
  decimal__floating__point__literal ~ unicorn
  operator__entity__identifier ~ unicorn
  function__entity__identifier ~ unicorn
  operator ~ unicorn
  hexadecimal__literal ~ unicorn
  multiline__string ~ unicorn
  block__comment__open ~ unicorn
  octal__literal ~ unicorn
  single__line__comment ~ unicorn

END_OF_SOURCE

my $grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'My_Nodes',
        source          => \$source,
    }
);


# 
# Token sequence:
# 
# 'type' hspace identifier hspace '{' newlines hspace 'fun' identifier
# '(' ')' hspace '{' '}' newlines hspace '}' newlines hspace 'extension'
# hspace identifier hspace '{' newlines hspace 'fun' hspace identifier '('
# ')' hspace '{' '}' newlines hspace '}'
# 
my @terminals = (
#    [ Number   => qr/\d+/xms,    "Number" ],
#    [ 'op pow' => qr/[\^]/xms,   'Exponentiation operator' ],
#    [ 'op pow' => qr/[*][*]/xms, 'Exponentiation' ],          # order matters!
#    [ 'op times' => qr/[*]/xms, 'Multiplication operator' ],  # order matters!
#    [ 'op divide'   => qr/[\/]/xms, 'Division operator' ],
#    [ 'op add'      => qr/[+]/xms,  'Addition operator' ],
#    [ 'op subtract' => qr/[-]/xms,  'Subtraction operator' ],
#    [ 'op lparen'   => qr/[(]/xms,  'Left parenthesis' ],
#    [ 'op rparen'   => qr/[)]/xms,  'Right parenthesis' ],
#    [ 'op comma'    => qr/[,]/xms,  'Comma operator' ],
);

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
TOKEN: while (1) {
    my $start_of_lexeme = pos $string;
    last TOKEN if $start_of_lexeme >= $length;
    next TOKEN if $string =~ m/\G\s+/gcxms;    # skip whitespace
    TOKEN_TYPE: for my $t (@terminals) {
        my ( $token_name, $regex, $long_name ) = @{$t};
        next TOKEN_TYPE if not $string =~ m/\G($regex)/gcxms;
        my $lexeme = $1;

        if ( not defined $recce->lexeme_alternative($token_name) ) {
            die
                qq{Parser rejected token "$long_name" at position $start_of_lexeme, before "},
                substr( $string, $start_of_lexeme, 40 ), q{"};
        }
        next TOKEN
            if $recce->lexeme_complete( $start_of_lexeme,
                    ( length $lexeme ) );

    } ## end TOKEN_TYPE: for my $t (@terminals)
    die qq{No token found at position $start_of_lexeme, before "},
        substr( $string, pos $string, 40 ), q{"};
} ## end TOKEN: while (1)

my $value_ref = $recce->value();
if ( not defined $value_ref ) {
    die "No parse was found, after reading the entire input\n";
}

Test::More::is( ${$value_ref}, '', 'Value of parse' );

# vim: expandtab shiftwidth=4:
