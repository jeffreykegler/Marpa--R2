
A Kollos Roadmap
================

Step 1.  A Libmarpa wrapper
---------------------------

Create a straight wrapper of Libmarpa, along the lines of 
[Marpa::R2's thin interface (THIF)]
(https://github.com/jeffreykegler/Marpa--R2/blob/master/cpan/pod/Advanced/Thin.pod).

Step 2.  Add a "tracer" layer
-----------------------------

Libmarpa does not have symbol names, and without them it is almost
unuseable.
Within Marpa::R2, I use
a "tracer" layer that tracks names and IDs.
The
[Marpa::R2 code]
(https://github.com/jeffreykegler/Marpa--R2/blob/master/cpan/lib/Marpa/R2/Thin/Trace.pm)
is simple and should be translated into a Lua library.
It could also be made part of the wrapper, but in Marpa I've kept them separate.

Step 3.  A Lua parser
---------------------

Write a Lua parser in Marpa.

Step 4.  Benchmark the Marpa Lua parser against the native one
--------------------------------------------------------------

Marpa will lose, of course.  Lua is a very small language, designed to be easily parsed
by recursive descent and its native parser is very carefully hand-crafted by one of the
top programmers of our time.
But it will be interesting to see how Marpa compares.
And it leads to the next step ...

Step 5.)  Extend the Lua language into the first version of the LUIF
--------------------------------------------------------------------

The LUIF is the Lua interface -- LUA extended with BNF statements.
The LUIF works by

1. Parsing the Lua into itself -- essentially just passing it through.

2. Parsing the BNF statements into Lua code, which creates Lua data structures.

3. Adding a preamble and postamble to translated code, to make a Marpa interface.

Initially, this interface will have far fewer features than the SLIF does.
So the next steps are ...

Steps 6 and beyond.) Add SLIF features to the LUIF
--------------------------------------------------

Add features from the SLIF to the LUIF until the LUIF contains all the desirable
ones.
In the process, the interface can be improved.
As just one example,
it should be possible to have sequences on the RHS of other kinds
rule, but the SLIF would need a lot of refactoring to allow this.
The LUIF will be a clean start, and natural extensions like this
should be straightforward to incorporate.
