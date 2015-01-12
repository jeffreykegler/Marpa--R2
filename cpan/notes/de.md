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
