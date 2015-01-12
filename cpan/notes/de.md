As the result of a discussion in this group and on the IRC channel,
I am adding "discard events" to Marpa::R2.  Here is my "design document".

Defining a discard event for a token causes an event to be generated
when an instance of that token is discarded.  (Note that I avoid calling
discarded tokens "lexemes".  This is for pedantic reasons.)

To generate the event, "ws-discard", when a <ws> token is discarded,
I will allow the 'event' adverb for discard statements.
The following are some possible
variants of the discard statement:

```
   :discard ~ ws event => 'ws-discard'=off

   :discard ~ <ws> event => wsdiscard=on

   :discard ~ ws event => 'ws-discard'
```

The '=on' or '=off' after the event name indicates how the event is
initialized.  If set to "on" (the default), the event is initialized
active.  If set to "off", the event is initialized inactive.

I add the initialization ability, because I expect users will often
want to define grammars which allow the possibility of events on discard
tokens, but will also want the ability to initialize them to inactive.
A new named parameter of the $recce->new() method will allow the
application to change this initial setting, on a per-token basis,
at runtime.

There will also be a new "discard default" statement, modeled on the
"lexeme default" statement.  An example:

```
   discard default => event => ::name=off
```

This says that all ':discard' statement with no explicit event name
the event based on the name of the discarded symbol, and initialize it
to inactive.
