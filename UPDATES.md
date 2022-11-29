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
version 10.000000.
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

### No known bugs

### During installation, configure fails on MacOs

On MacOs, GNU's configure tool often fails.  The appears
to be due to a bug in configure on MacOS.  The problem
does not occur in Linux, but may occur on targets other
than MacOs.

When this problem occurs, the log will contain this message:
```
config.status: error: Something went wrong bootstrapping makefile fragments
    for automatic dependency tracking.  Try re-running configure with the
    '--disable-dependency-tracking' option to at least be able to build
    the package (albeit without support for automatic dependency tracking).
```

The workaround is to set the following environment variable:
```
    MARPA_USE_PERL_AUTOCONF=1
```
This environment setting will cause the installation to use
Perl's Config::Autoconf
instead of the GNU autoconf.
The problem seems to be a bug in the GNU autoconf on certain
platforms, a bug that
Config::Autoconf does not share.

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

## Updates pages for previous versions

[Updates page for version 8.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-8.000000.md).

[Updates page for version 6.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-6.000000.md).

[Updates page for version 4.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-4.000000.md).
