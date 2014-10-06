
A Kollos roadmap
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

Write a Lua parser in Marpa.  No semantics, just create a tree and then serialize it back into Lua code.

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

1. Parsing the pure Lua statement back into themselves -- essentially just a pass-through.

2. Parsing the BNF statements into Lua statements that create a Lua data structure containing rules, symbol and adverbs.
3. 
3. Adding a postamble.  Among other things, the postamble will take the Lua data structures that were created from the BNF statements, process them into a form ready for Libmarpa, and call the Libmarpa methods to actually create the grammar.
4. 
4. 
4. Some sort of preamble will probably be needed as well.

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
