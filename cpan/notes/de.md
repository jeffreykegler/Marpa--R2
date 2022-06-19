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

# Design notes for discard events

Defining a discard event for a token causes an event to be generated
when an instance of that token is discarded.  (Note that I avoid calling
discarded tokens "lexemes".  This is for pedantic reasons.)

I will allow the `event` adverb for discard statements.
The following are some possible
variants of the discard statement:

```
   :discard ~ ws event => 'wsdiscard'=off

   :discard ~ <ws> event => wsdiscard=on

   :discard ~ ws event => 'wsdiscard'
```

These cause the event `wsdiscard` to be generated when a `<ws>`
token is discarded.
The `=on` or `=off` after the event name determines whether the event is
initialized as active or inactive.
If set to `on` (the default), the event is initialized
active.  If set to `off`, the event is initialized inactive.

I add the ability to initialize discard events as active
or inactive,
because I expect that applications will often
want to define grammars which allow the possibility of events on discard
tokens, but that applications
will also often want the ability to initialize them to inactive.

A new named parameter of the `$recce->new()` method will allow the
application to change this initial setting, on a per-token basis.
The main expected use of this is to turn on, at runtime, discard events
that were initialized to inactive.

There will also be a new `discard default` statement, modeled on the
`lexeme default` statement.  An example:

```
   discard default => event => ::name=off
```

This says that,
for all `:discard` statements with no explicit event name,
the event name is based on the name of the discarded symbol,
and that the event is initialized
to inactive.

Discard events will be non-lexeme, named events,
and will be accessible via the `$recce->events()` method.
Conceptually, they always occur after the token has been discarded.
The event described will have 4 elements:

    * the event name, as with all events;

    * the physical input location where the discarded token starts;

    * the length of the discarded token in physical
      input locations; and

    * the last G1 location of a lexeme.

(Recall that lexemes, by definition, are not discarded.)
If no lexeme has yet been recognized, the G1 location will be zero.
The main use of the G1 location will be for syncing discarded
tokens with a parse tree.

Marpa::R2 parse event descriptors have been documented as 
containing 1 or more elements, but those currently implemented
always contain only one element, the event name.
Discard events will therefore be the first event
whose descriptor
actually contains more than a single element.
