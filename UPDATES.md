# Marpa::R2 Updates

## About this page

This is the updates page for Marpa::R2.
This page carries information which does not justify
a full new distribution,
but which it is useful for the user to know.

On CPAN, Marpa::R2's primary distribution mechanism,
there is no way to have true "meta" information --
even a small doc always is part of the distribution itself
and requires the creation of a completely new version.

Because Marpa is now "stable", new versions are released only
when they benefit its current users.
In effect, this means new versions occur only when a serious
bug is discovered, which (knock on wood)
happens rarely.

## No support for Perl 5.10.0

Contrary to what the documentation says, Marpa::R2 does not support Perl 5.10.0.
The reason for this was an accidental regression --
some new test scripts were taken from Marpa::R3 and these require Perl 5.10.1, causing testing to fail.
The other tests succeed and my guess is that a forced installation would work, but based on feedback from
Marpa's user community, there are no 5.10.0 users and the best choice is to end support for 5.10.0.

Perl 5.10.0 was the official release from December 2007 to August 2009.
It was extremely buggy and most users who hadn't stuck with Perl 5.8 quickly moved on to 5.10.1.
The legacy community for 5.10.0 is small to the point of invisibility.
Since 2009 new installations of 5.10.0 have been almost non-existent.
5.10.0 is not one of the perlbrew versions.

This lack of use was a major contributor to the regression bug that ended 5.10.0 support.
Marpa::R2 4.000_000 was extensively tested on CPANtesters, but tests with 5.10.0 are quite rare and the
failure reports did not appear for weeks, at which point Marpa::R2 had been released.

With the end of support, a minor bug remains.
The build of Marpa::R2 does not fail smoothly, but instead builds (successfully)
and then fails in the test phase.
If there is a next version of Marpa::R2, it should refuse to attempt installation
on Perl 5.10.0.

## Progress reports fail on trivial grammars

A trivial grammar is one which allows only null parses.
Trivial grammars are not very useful, but Marpa::R2 is documented to support them
in all respects, including tracing and progress reports.
In fact, progress reports for trivial grammars are empty.

This is considered a minor bug.
(It was not discovered by a user, but was only noticed by Jeffrey when re-reading Libmarpa's internals.)
Because Marpa::R2 is now stable, it will only be fixed if a serious bug forces a new release.
