<!--
Copyright 2022 Jeffrey Kegler
This file is part of Marpa::R2.  Marpa::R2 is free software: you can
redistribute it and/or modify it under the terms of the GNU Lesser
General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

Marpa::R2 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser
General Public License along with Marpa::R2.  If not, see
http://www.gnu.org/licenses/.
-->

# Marpa::R2 Updates

## About this page

This is the updates page as of Marpa::R2,
version 8.000000.
(For the updates pages for previous versions, see below.)
It may contain descriptions of bugs for which a fix
is in preparation.
It also carries notices which are useful to current users,
but which do not justify a full new distribution,

On CPAN, Marpa::R2's primary distribution mechanism,
there is no way to have true "meta" information --
even a small doc always is part of the distribution itself
and requires the creation of a completely new version.

Marpa is now "stable", and new features are not added to it.
New versions are released only when they benefit users
of the current functionality in a major way.
New versions usually occur only when a serious
bug is discovered.

## Bugs

### Some parses with nullable-prefixed middle recursions are ignored

A recursion is a rule with a symbol, call it the "recursion symbol",
that non-trivially
produces the string consisting only of that symbol.
"Non-trivially" means in more than one step -- every
rule with one or more symbols on the RHS is trivially
recursive.

A recursion is a middle recursion if its recursion symbol is not
the first symbol on the RHS, and not the last symbol on the RHS.
The RHS symbols to the left of the recursion symbol are the prefix
of the middle recursion.
The RHS symbols to the right of the recursion symbol are the suffix
of the middle recursion.
By definition, every middle recursion has a non-empty prefix and
a non-empty suffix.

The bug occurs in parses with a middle recursion whose prefix is
nullable, and whose suffix is non-nullable.
It seems safe to assume the reader would like an example.
The following grammar exhibits this bug:

```
  prefixExpr ::= null prefixExpr Arg2
  prefixExpr ::= Arg1
  null ::= 
```

In this grammar, `<Arg1>` and `<Arg2>` are non-nullable
terminals.

This bug, which was discovered by Dave Abrahams, went unnoticed
for ten years, because middle recursions are rare, and middle
recursions with a non-nullable prefix more so.
The most powerful grammars in widespread use are LALR(1),
the grammar class parsed by yacc and bison.
LALR(1) is weaker than LR(1).
The above grammar is not parseable by an LR(`k`) grammar,
for any `k`, so it is very far beyond power of the parsers
that have seen widespread practical use.

This bug is fixed in Marpa::R2 10.000000.

## Notices

### No support for Perl 5.10.0

Marpa::R2 no longer supports Perl 5.10.0.
There do not appear to be any Marpa::R2 users
of Perl 5.10.0.
And, in the cloud,
Perl 5.10.0 is so rare it is hard to find testing for it.

### No support for cperl and other Perl variants

We are happy to see experimentation with Perl,
but unfortunately we do not have
the resources to support anything but standard Perl.
A bug with a Perl variant will be rejected
if the bug cannot be duplicated in standard Perl.

### Limited support for AIX

Some work has been done on supporting AIX.  See
[the AIX.README file](https://github.com/jeffreykegler/Marpa--R2/blob/master/AIX.README).

## Updates pages for previous versions

[Updates page for version 6.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-6.000000.md).

[Updates page for version 4.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-4.000000.md).
