# Marpa::R2 Updates

## About this page

This is the updates page for Marpa::R2,
version 6.000000.
The updates page for version 4.000000 can be found
[here](https://github.com/jeffreykegler/Marpa--R2/blob/f2a676b760de8fd0e41669806744503253d76bd6/UPDATES.md).
This page carries information which does not justify
a full new distribution,
but which it is useful for the user to know.

On CPAN, Marpa::R2's primary distribution mechanism,
there is no way to have true "meta" information --
even a small doc always is part of the distribution itself
and requires the creation of a completely new version.

Marpa is now "stable", and new features are not added to it.
New versions are released only when they benefit current users.
In effect, this means new versions occur only when a serious
bug is discovered.

## No support for Perl 5.10.0

Marpa::R2 no longer supports Perl 5.10.0.
There do not appear to be any Marpa::R2 users
of Perl 5.10.0.
And, in the cloud,
Perl 5.10.0 is so rare it is hard to find testing for it.

## No support for cperl and other Perl variants

There is no support for anything but standard Perl.  A bug with a Perl variant will be rejected
if the bug cannot be duplicated in standard Perl.

