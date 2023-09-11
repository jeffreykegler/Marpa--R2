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
version 12.000000.
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

## Support

Marpa::R2 is free software.
There is no warranty.

Available resources include the following:

* Bugs should be filed as issues in this repo.

* The IRC channel is where most discussion takes place.
It is `#marpa` at
`irc.libera.chat`.
The channel
[is logged](http://colabti.org/irclogger/irclogger_log/marpa).

* In addition, there is
[a Google Groups mailing list dedicated to
Marpa](https://groups.google.com/forum/?fromgroups#!forum/marpa-parser).

* Ron Savage maintains
[Marpa's official starting
page](http://savage.net.au/Marpa.html).

* The author also maintains [a less extensive Marpa web
site](https://jeffreykegler.github.io/Marpa-web-site/).

* After `Marpa::R2` is installed,
You can read its documentation for this module with the perldoc command:
`perldoc Marpa::R2`.

## Installation note

On installation, users sometimes run have problems with
GNU's configure, apparently due to broken setups or bugs
in GNU's autotools.  The proper fix, of course, is to repair
the setup or GNU configure, but this may be impossible or
inconvenient.

A workaround is to set the following environment variable:
```
    MARPA_USE_PERL_AUTOCONF=1
```
This environment setting will cause the installation to use
Perl's Config::Autoconf,
bypassing any problems with the GNU autoconf.

## Known bugs

### Documentation error in Marpa::R2::Event pod page

In the ["Nulling events" section of
Marpa::R2::Event](https://metacpan.org/dist/Marpa-R2/view/pod/Event.pod#Nulling-events),
the sentence

> When a completion event triggers,
> its trigger location and its event location are set to the current location,
> which will be the location where the triggering instance both begins and ends.

is incorrect.  It should read as follows:

> When a **nulling** event triggers,
> its trigger location and its event location are set to the current location,
> which will be the location where the triggering instance both begins and ends.

### Changes to discussion of ordering by rule

The discussion of how to order rules in a Libmarpa parse has been
reorganized and extensively rewritten.
A new ["Algorithm"
page](https://metacpan.org/release/JKEGL/Marpa-R2-13.002_000/view/pod/Algorithm.pod)
has been added;
and major changes were made to the ["Semantics/Order"
page](https://metacpan.org/release/JKEGL/Marpa-R2-13.002_000/view/pod/Semantics/Order.pod)
and to the ["Semantics/Rank"
page](https://metacpan.org/release/JKEGL/Marpa-R2-13.002_000/view/pod/Semantics/Rank.pod)

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

[Updates page for version 10.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-10.000000.md).

[Updates page for version 8.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-8.000000.md).

[Updates page for version 6.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-6.000000.md).

[Updates page for version 4.000000](https://github.com/jeffreykegler/Marpa--R2/blob/master/etc/old_updates/UPDATES-4.000000.md).
