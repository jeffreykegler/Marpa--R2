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
version 6.000000.
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

### Integer arguments of lexeme_complete() and resume() sometimes ignored

In Perl 5.18 and higher, the integer arguments of
$recce->lexeme_complete() and $recce->resume() may be ignored if Perl
considers them to be "tied".
This problem does not occur in Perl version 5.16 or older.
Most integers are not "tied", but see below.

The
[int Perl function](https://perldoc.perl.org/functions/int.html)
can be used to convert the integer to an
"untied" version.
This can be used as a workaround.

A fix to this problem has been found.
This is being treated as a serious bug,
and a new indexed release of Marpa::R2 is being prepared which
will include this fix.

"Tied" in the sense it is used in this context
is a Perl internals concept.
Most integers are not tied but,
for example, as of this writing,
the value of @LAST_MATCH_START
(see
[perlvars](https://perldoc.perl.org/perlvar.html#Variables-related-to-regular-expressions))
is "tied".

The problem occurred because of a change in the
[Perl API](https://perldoc.perl.org/perlapi.html)
as of Perl 5.18.
A description of the change can be found in the Perl
documents
[here](https://perldoc.perl.org/perlguts.html#What's-Really-Stored-in-an-SV%3f).

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

The updates page for version 4.000000 can be found
[here](https://github.com/jeffreykegler/Marpa--R2/blob/f2a676b760de8fd0e41669806744503253d76bd6/UPDATES.md).
