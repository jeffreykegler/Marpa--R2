% Copyright 2011 Jeffrey Kegler
% This file is part of Marpa::XS.  Marpa::XS is free software: you can
% redistribute it and/or modify it under the terms of the GNU Lesser
% General Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later version.
%
% Marpa::XS is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser
% General Public License along with Marpa::XS.  If not, see
% http://www.gnu.org/licenses/.

\def\li{\item{$\bullet$}}

% Here is TeX material that gets inserted after \input cwebmac
\def\hang{\hangindent 3em\indent\ignorespaces}
\def\pb{$\.|\ldots\.|$} % C brackets (|...|)
\def\v{\char'174} % vertical (|) in typewriter font
\def\dleft{[\![} \def\dright{]\!]} % double brackets
\mathchardef\RA="3221 % right arrow
\mathchardef\BA="3224 % double arrow
\def\({} % ) kludge for alphabetizing certain section names
\def\TeXxstring{\\{\TEX/\_string}}
\def\skipxTeX{\\{skip\_\TEX/}}
\def\copyxTeX{\\{copy\_\TEX/}}

\let\K=\Longleftarrow

\secpagedepth=1

\def\title{Code for Marpa}
\def\topofcontents{\null\vfill
  \centerline{\titlefont Code for Marpa}
  \vfill}
\def\botofcontents{\vfill
\noindent
@i copyright_page_license.w
\bigskip
\leftline{\sc\today\ at \hours} % timestamps the contents page
}
% \datecontentspage

\pageno=\contentspagenumber \advance\pageno by 1
\let\maybe=\iftrue

\def\marpa_sub#1{{\bf #1}: }
\def\libmarpa/{{\tt libmarpa}}
\def\QED/{{\bf QED}}
\def\Theorem/{{\bf Theorem}}
\def\Proof/{{\bf Theorem}}
\def\gsize{\v g\v}
\def\wsize{\v w\v}

@q Unreserve the C++ keywords @>
@s asm normal
@s dynamic_cast normal
@s namespace normal
@s reinterpret_cast normal
@s try normal
@s bool normal
@s explicit normal
@s new normal
@s static_cast normal
@s typeid normal
@s catch normal
@s false normal
@s operator normal
@s template normal
@s typename normal
@s class normal
@s friend normal
@s private normal
@s this normal
@s using normal
@s const_cast normal
@s public normal
@s throw normal
@s virtual normal
@s delete normal
@s mutable normal
@s protected normal
@s true normal
@s wchar_t normal
@s and normal
@s bitand normal
@s compl normal
@s not_eq normal
@s or_eq normal
@s xor_eq normal
@s and_eq normal
@s bitor normal
@s not normal
@s or normal
@s xor normal

@s error normal
@s gconstpointer int
@s gpointer int
@s gint int
@s guint int
@s gboolean int
@s PSAR int
@s PSL int

@** License.
\bigskip\noindent
@i copyright_page_license.w

@** About This Document.
This document is very much under construction,
enough so that readers may question why I make it
available at all.  Two reasons:
\li Despite its problems, it is the best way to read the source code
at this point.
\li Since it is essential to changing the code, not making it available
could be seen to violate the spirit of the open source.
@ This will eventually become a real book describing the
code.
It is already approaching that in size.
Quality is another story.
Much rewriting and reorganization is being left until the end.
\par
Marpa is a very unusual C library -- no system calls, no floating
point and almost no arithmetic.  A lot of data structures
and pointer twiddling.
I have found that a lot of good coding practices in other
contexts are not in this one.
\par
For example, I intended to fully to avoid abbreviations.
This is good practice -- in most cases all abbreviations save is
some typing, at a very high cost in readability.
In |libmarpa|, however, spelling things out usually does
{\bf not} make them more readable.
To be sure, |To_AHFA_of_EIM_by_SYMID| is pretty incomprehensible.
But is
$$Aycock\_Horspool\_Finite\_Automaton\_To\_State\_of\_Earley\_Item\_by\_Symbol\_ID$$
better?
At this point, I have a lot of practice coming back to pages of both, cold, 
and trying to figure them out.
Both are daunting, but the abbreviations, are more elegant, and look
better on the page, while unabbreviated names routinely pose almost insoluble
problems for Cweb's \TeX{} typesetting.
\par
Whichever is used, it must be kept systematic and
documented, and that is easier with the abbreviations.
In general, I believe abbreviations are used in code
far more than they should be.  But they have their place
and |libmarpa| is one of them.
\par
Because I realized that abbreviations were going to be not
just better, but almost essential if I ever was to finish this
project, I changed from a "no abbreviation" policy to one
of "abbreviate when necessary and it is necessary a lot" half
way through.
Thus the code is highly inconsistent in this respect.
At the moment,
that's true of a lot of my other coding conventions.
\par
To summarize, the reader who has not yet been scared off,
needs to be aware that the coding conventions are not yet
consistent internally, and not yet consistent with their
documentation.
@
The Cweb is being written along with the code.
If the code works right off the bat, its accompanying text
will be a first draft.
The more trouble I had understanding an issue,
and writing the code,
the more thorough the documentation.

@** Coding conventions.
@*0 Naming conventions.

@*1 Mixed Case Macros.
In programming in general, accessors are very common.
In |libmarpa|, the percentage of the logic the consists
of accessors is even higher than usual,
and their variety approaches the botanical.
Most of these accessors are simple or even trivial,
but some are not.
In an effort to make the code readable and maintainable,
I use macros for all accessors.
@ The standard C convention is that macros are all caps.
This is a good convention.  I believe in it and almost
always follow it.
But in this code I have departed from it.
@ As has been noted in the email world,
when most of a page is in caps, that page becomes
much harder and less pleasant to read.
So in this code I have made macros mixed case.
Marpa's mixed case macros are easy to spot ---
they always start with a capital, and the "major words"
also begin in capital letters.
"Verbs" and "coverbs" in the macros begin with a lower
case letter.
All words are separated with an underscore,
as is the currently accepted practice to enhance readability.
@ The "macros are all caps" convention is a long standing one.
I understand that experienced C programmers will be suspicious
of my claim that this code is special in a way that justifies
breaking the convention.
Frankly, if I were a new reader coming to this code,
I would be suspicious as well.
But I would ask anyone who wishes to criticize to first do
the following:
Look at one of the many macro-heavy pages in this code
and ask yourself -- do you genuinely wish more of this
page was in caps?

@*1 External Names.
External Names have |marpa_| or |MARPA_| as their prefix,
as appropriate under the capitalization conventions.
Many names begin with one of the major "objects" of Marpa:
grammars, recognizers, symbols, etc.
Names of functions typically end with a verb.

@*1 Booleans.
Names of booleans are often
of the form |is_x|, where |x| is some
property.  For example, the element of the symbol structure
which indicates whether the symbol is a terminal or not,
is |is_terminal|.
Boolean names are chosen so that the |TRUE| or |FALSE|
value corresponds correctly to the question implied by the
name.
Names should be as
accurate as possible consistent with brevity.
Where possible, consistent with brevity and accuracy,
positive names (|is_found|) are preferred
to negative names (|is_not_lost|).

@*1 Function names.
For function names, some final verbs have special meanings.
In the description below |obj| stands for an object,
and |fld| for a field of that object.
In cases where there is not ambiguity about which
object a field might belong to, |obj| will often be omitted.

\li |obj_fld_get| returns field |fld|
of object |obj|.
It is an internal function, and often will be declared
|static inline|.

\li |obj_fld_put| assigns a value to field |fld|
of object |obj|.
It is an internal function, and often will be declared
|static inline|.

\li |marpa_obj_fld_look| returns field |fld|
of object |obj|.
It is an external equivalent of |obj_fld_get|.
The returned value is still owned by object |obj| -- it should
not be modified or freed.
In practice, the |look| verb is often omitted.

\li |marpa_obj_fld_peek| returns field |fld|
of object |obj|.
It is an external equivalent of |obj_fld_get|.
The returned value is still owned by object |obj| -- it should
not be modified or freed.

The difference between "peek" and "look" is somewhat
subjective.
"Look" functions are expected to be called in the normal
course of operation, including in production code.
"Peek" functions break the encapsulation rules.
Their use is expected to be limited
to debugging or tracing situations.

\li |marpa_obj_fld_set| sets field |fld|
of object |obj|.
It's the external equivalent of |obj_fld_put|.

\li |marpa_obj_fld_value| returns field |fld|
of object |obj|.
It is an external equivalent of |obj_fld_get|.
The returned value is owned by the caller.

@*0 Abbreviations and Vocabulary.
@ Unexplained abbreviations and non-standard vocabulary
pose unnecessary challenges.
Particular obstacles to those who are not native speakers
of English, they are annoying to the natives as well.
This section is intended to document
all abbreviations.
Also included is the
any non-standard vocabulary 
which is not explained in detail elsewhere in the
text.
By "non-standard vocabulary",
I mean terms that
are not in a general dictionary, and
are also not in the standard reference works.
@ While development is underway, this section will be
incomplete and sometimes inaccurate.
\li alloc: Allocate.
\li assign: Find something, creating it when necessary.
\li bv: Bit Vector.
\li cmp: Compare.
Usually as |_cmp|, the suffix or "verb" of a function name.
\li \_Object: As a suffix of a type name, this means an object,
as opposed to a pointer.
When there is a choice,
most complex types are considered to be pointers
to structures or unions, rather than the structure or
union itself.
When it's necessary to have a type which
refers to the actual structure
or union {\bf directly}, not via a pointer,
that type is called the "object" form of the
type.  As an example, look at the definitions
of |EIM| and |EIM_Object|.
\li EIM: Earley item.
\li |EIM_Object|: Earley item (object).
\li EIX: Earley item index.
\li ES: Earley set.
\li g: Grammar.
\li |_ix|, |_IX|, ix, IX: Index.  Often used as a suffix.
\li Leo base item: The Earley item which "causes" a Leo item to
be added.  If a Leo chain in reconstructed from the Leo item,
\li Leo completion item: The Earley item which is the "successor"
of a Leo item to
be added.
\li Leo LHS symbol: The LHS of a Leo completion item (see which).
\li Leo item: A "transition item" as described in Leo1991.
These stand in for a Leo chain of one or more Earley tems.
Leo items can stand in for all the Earley items of a right
recursion,
and it is the use of Leo items which makes this algorithm |O(n)|
for all LR-regular grammars.
In an Earley implementation
without Leo items, a parse with right recursion
can have the time comlexity |O(n^2)|.
\li LIM: Leo item.
\li \_Object: Suffix indicating that the type is of an
actual object, and not a pointer as is usually the case.
\li PIM, pim: Postdot item.
\li p: A Pointer.  Often as |_p|, as the end of a variable name, or as |p_| at
the beginning of one.
\li pp: A Pointer to pointer.  Often as |_pp|, as the end of a variable name.
\li R, r: Recognizer.
\li RECCE, recce: Recognizer.  Originally military slang for a
reconnaissance.
\li -s, -es: Plural.  Note that the |es| suffix is often used even when
it is not good English, because it is easier to spot in text.
For example, the plural of |ES| is |ESes|.
\li |s_|: Prefix for a structure tag.  Cweb does not C code format well
unless tag names are distinct from other names.
\li |t_|: Prefix for an element tag.  Cweb does not C code format well
unless tag names are distinct from others.
Since each structure and union in C has a different namespace,
this does not suffice to make different tags unique, but it does
suffice to let Cweb distinguish tags from other items, and that is the
object.
\li |u_|: Prefix for a union tag.  Cweb does not C code format well
unless tag names are distinct from other names.

@** Development Plans.

These are notes to myself,
most of which will only be relevant
while |libmarpa| is being written.
Most of these notes will be revised
and then deleted as development proceeds.

@*1 Short Term To Do List.

@*1 Long Term To Do List.

@*1 Development Note: Marpa layers.

|libmarpa|, the library described in this document, is intended as the bottom of potentially
four layers.
The layers are, from low to high
\li |libmarpa|
\li The glue layer
\li The wrapper layer
\li The application

This glue layer will be in C and will call the |libmarpa| routines
in a way that makes them compatible with another language.
I expect this will usually be a 4GL (4th generation language),
such as Perl.
One example of a glue description lanuage is SWIG.
Another is Perl XS, and currently that is
the only glue layer implemented for |libmarpa|.

|libmarpa| itself is not enormously user-
or application-friendly.
For example, in |libmarpa|, symbols do not have
names, just symbol structures and symbol ID's.
These are all that is needed for the data crunching,
but an application writer will usually want a friendlier
interface, including names for the symbols and
many other conveniences.
For this reason, applications will typically
use |libmarpa| through a {\bf wrapper package}.
Currently the only such package is in Perl.

The top layer is the application.
My expectation is that this will also be in a 4GL.
Currently, |libmarpa|'s only application are
in Perl.

Not all these layers need be present.
For example, it is conceivable that someone might
write their application in C, in which case they could
manage without minimal or no
glue layers or package layers.

Iterfaces between layers are named after the lower
of the two layers.  For example the interface between
|libmarpa| and the glue layer is the |libmarpa| interface.

@*1 Development Note: Representing Objects.
Representation of objects is most commonly in one
of three forms: cookies, ID's or pointers to C structures.

@*2 Object ID's.
Object ID's are integers.  They are always issued in sequence.
They are guaranteed unique.
(Note that in C,
pointers to identical objects do {\bf not} necessarily
compare equal.)
If desired, they can be checked easily without risking a memory
violation.

ID's are the only object representation
that can be used in any layer or any interface,
and they are the preferred representation
in the application layer
and the package interface.

Wraparound issues for object ID's are ignored.
By the time any object ID wraps, memory will have long
since overflowed.

@*2 Object Cookies.
Ideally, outside of the |libmarpa| layer,
all objects would be represented by their ID.
However, an exception is made recognizers and grammars,
even though they do have ID's.
This is because looking up ID's for these global objects
is not thread-safe.

@ To make ID lookup for global objects could be made thread-safe,
but this involves locking data.
It is possible to do this portably, using Glib, but it seems simply
and safer to expect the calling environment to respect the opaque
nature of the grammar and recognizer cookies.

"Respecting the opaque nature of a cookie",
means not
accessing its internal contents -- using the
cookie only as a cookie.
The overall idea is that,
if an programmer 
writes trick-free higher-level code
using cookies,
any resulting errors occur
in the package or application layer.

The contents of Object Cookies are dependent on
the choice of higher-level language (HLL).
For this reason,
The cookies are never visible in the |libmarpa| layer.

In Perl's cookies, a major consideration is ensuring
that, during the lifetime of a cookie,
all the objects implied by the cookie also exist.
This means that so long as
a recognizer object cookie exists,
the underlying grammar cannot be destroyed.

@*2 Object pointers.
The most efficient representation of objects
are pointers to structures.
These are the main representation of objects
in the |libmarpa| layer.
These must not be visible in the package and application
layers.

With regard to the visibility of object pointers in the
glue layer, the situation is more complicated.
At this writing, I expect to make pointers
to most structures
completely invisible except inside |libmarpa|.
The external accessors do allow the glue layer
some access
to |libmarpa|'s internal structures.
But in the case of the |_peek|
external accessors,
it is intuitive that the memory is owned
by the |libmarpa| layer,
and expected that any use of it will be quick.

In the case of object pointers, their expected ordinary
use is be kept around to refer to the object.
But, for example, symbol object pointers must not
be freed by the glue layer, but will become invalid
when their associated grammar layer is destroyed.

This behavior is not completely unintuitive to an
experienced C programmer -- functions (like |ctime|)
which return
transient information in memory unowned by the caller
have a long tradition in UNIX.
But these are now deprecated.

But tracking the lifetime of symbol object pointers 
in the glue layer
would be tricky, so as this writing the thought is to
avoid the issue, for it and most other object pointers.
The exceptions are grammar and recognizer objects.
The base objects for these {\bf are} owned by
the glue layer, so these do not present the same
issues.
The glue layer creates
grammar and recognizer objects,
it owns them during their lifetime,
and it is up to the glue layer to destroy them.

@*1 Development Note: Converting Elements.
\li Init the data element.

\li Add a destructor.
At first arrange for this to be called when the Perl object
is destroyed.
Add a comment in the place where the destructor must eventually
be called, as a reminder.
This will usually be in the Recognizer or Grammar destructor.

\li Add whatever mutators are needed,
initially as un-inlined externals.
At the end of development, it should be possible to
eliminate the external versions of these.

\li Now that there are a full set of initializers,
destructors and mutators,
change the Perl code so that it updates both the Perl and C elements.
In other words, have the C element "shadow" the Perl element.

\li Create an internal and an external "accessor".
The external accessor is
to be used by the XS code, and by the debugging and diagnostics.
The internal accessor, declared |static internal| is for "production" uses.
For elements used only in diagnostics and debugging, no internal accessor need ever be
created.

\li
Convert all Perl code to use the external accessor of the C element.

\li Eliminate all accesses to the Perl element.

\li Eliminate the Perl element.

@*1 Development Note: Converting Objects.

\li First, all elements of an object must be converted to C,
as described above.

\li
Next, all "production" code referring to the object must be converted to C.
This probably requires the conversion of other objects to be well along.
In this context, "production" is all code except for code which does debugging,
diagnostic and "utility" functions.
Right now the only "utility" function I can think of is cloning.

\li
If the object is not a Grammar or a Recognizer,
recode the external interface so that
it no longer requires a Perl version
of the object.
Ultimately only the 
Grammar and Recognizer Perl objects will remain.

\li
Remember to use external accessors in XS,
debugging, diagnostic and cloning
code, and the internal accessors in the main routine.

\li When an object is converted to C, it's destructor will no
longer be called in the course of destroying the Perl object.
Make sure the destructor will be called when necessary.
This will usually be when the Recognizer or Grammar object is destroyed.

@<Body of public header file@> =
@ Constants
@ Version Constants @<Private global variables@> =
const unsigned int marpa_major_version = MARPA_MAJOR_VERSION;
const unsigned int marpa_minor_version = MARPA_MINOR_VERSION;
const unsigned int marpa_micro_version = MARPA_MICRO_VERSION;
const unsigned int marpa_interface_age = MARPA_INTERFACE_AGE;
const unsigned int marpa_binary_age = MARPA_BINARY_AGE;
@ Return the version in a 3 element int array
@<Function definitions@> =
void marpa_version(int* version) {
        version[0] = MARPA_MAJOR_VERSION;
        version[1] = MARPA_MINOR_VERSION,
        version[2] = MARPA_MICRO_VERSION;
}
@ @<Public function prototypes@> =
void marpa_version(int* version);

@ Header file.  |GLIB_VAR| is to
prefix variable declarations so that they
will be exported properly for Windows dlls.
@f GLIB_VAR const
@<Body of public header file@> =
GLIB_VAR const guint marpa_major_version;@/
GLIB_VAR const guint marpa_minor_version;@/
GLIB_VAR const guint marpa_micro_version;@/
GLIB_VAR const guint marpa_interface_age;@/
GLIB_VAR const guint marpa_binary_age;@#
#define MARPA_CHECK_VERSION(major,minor,micro) @| \
    @[ (MARPA_MAJOR_VERSION > (major) \
        @| || (MARPA_MAJOR_VERSION == (major) && MARPA_MINOR_VERSION > (minor)) \
        @| || (MARPA_MAJOR_VERSION == (major) && MARPA_MINOR_VERSION == (minor) \
        @|  && MARPA_MICRO_VERSION >= (micro)))
        @]@#
#define MARPA_CAT(a, b) @[ a ## b @]
@<Public defines@>@/
@<Public incomplete structures@>@/
@<Public typedefs@>@/@\
@<Callback typedefs@>@/
@<Public structures@>@/
@<Public function prototypes@>@/

@ Marpa Global Setup

Marpa does no global initialization at the moment.
I'll try to keep it that way.
If I can't, I will need to deal with the issue
of thread safety.

@*1 Complexity.
Considerable attention is paid to time and,
where it is a serious issue, space complexity.
Complexity is considered from three points of view.
{\bf Practical worst-case complexity} is the complexity of the
actual implementation, in the worst-case.
{\bf Practical average complexity} is the complexity of the
actual implementation under what are expected to be normal
circumstances.
Average complexity is of most interest to the typical user,
but worst-case considerations should not be ignored ---
in some applications,
one case of poor performance
can outweigh any number of
of excellent "average case" results.
@ Finally, there is {\bf theoretical complexity}.
This is the complexity I would claim in a write-up of the
Marpa algorithm for a Theory of Computation article.
Most of the time, this is the same as practical worst-case complexity.
Often, however, for theoretical complexity I consider
myself entitled to claim
the time complexity for a 
better algorithm, even thought that is not the one
used in the actual implementation.
@ Sorting is a good example of under what circumstances
I take the liberty of claiming a time complexity I did not
implement.
In many places in |libmarpa|,
for sorting,
the most reasonable practical
implementation (sometimes the only reasonable practical implementation)
is an $O(n^2)$ sort.
When average list size is small, for example,
a hand-optimized insertion sort is often clearly superior
to all other alternatives.
Where average list size is larger,
a call to |g_qsort| is the appropriate response.
|g_qsort| is the result of considerable thought and experience,
the GNU project has decided to base it on quicksort,
and I do not care to second-guess them on this.
But quicksort and insertion sorts are both, theoretically, $O(n^2)$.
@ Clearly, in both cases, I could drop in a merge sort and achieve
a theoretical $O(n \log n)$ worst case.
Often just as clear is that is all cases likely to occur in practice,
the merge sort would be inferior.
@ When I claim a complexity from a theoretical choice of algorithm,
rather than the actually implemented one, the following will always be
the case:
\li The existence of the theoretical algorithm must be generally accepted.
\li The complexity I claim for it must be generally accepted.
\li It must be clear that there are no obstacles to using the theoretical algorithm
whose solution is not straightforward.
@ I am a big believer in theory.
Often practical considerations didn't clearly indicate a choice of
algorithm .
In those circumstances, I usually
allowed theoretical superiority to be the deciding factor.
@ But there were cases
where the theoretically superior choice
was clearly going to be inferior in practice.
Sorting was one of them.
It would be possible to
go through |libmarpa| and replace all sorts with a merge sort.
But a slower library would be the result.

@** Grammar Objects.
@<Public incomplete structures@> = struct marpa_g;
@ @<Private structures@> = struct marpa_g {
@<Widely aligned grammar elements@>@;
@<Int aligned grammar elements@>@;
@<Bit aligned grammar elements@>@;
};
typedef struct marpa_g GRAMMARD;
@ @<Private typedefs@> =
typedef struct marpa_g* GRAMMAR;
typedef const struct marpa_g* GRAMMAR_Const;

@ @<Function definitions@> =
struct marpa_g* marpa_g_new( void)
{ struct marpa_g* g = g_slice_new(struct marpa_g);
    @<Initialize grammar elements@>@;
   return g; }
@ @<Public function prototypes@> =
struct marpa_g* marpa_g_new(void);

@ @<Function definitions@> =
void marpa_g_free(struct marpa_g *g)
{ @<Destroy grammar elements@>@;
g_slice_free(struct marpa_g, g);
}
@ @<Public function prototypes@> =
void marpa_g_free(struct marpa_g *g);

@*0 The Grammar ID.
A unique ID for the grammar.
This must be unique not just per-thread,
but process-wide.
The counter which tracks grammar ID's
(|next_grammar_id|)
is (at this writing) the only global
non-constant, and requires special handling to
keep |libmarpa| MT-safe.
(|next_grammar_id|) is accessed only via
|glib|'s special atomic operations.
@ @<Int aligned grammar elements@> = gint t_id;
@ @<Public typedefs@> = typedef gint Marpa_Grammar_ID;
@ @<Private global variables@> = static gint next_grammar_id = 1;
@ @<Initialize grammar elements@> =
g->t_id = g_atomic_int_exchange_and_add(&next_grammar_id, 1);
@ @<Function definitions@> =
gint marpa_grammar_id(struct marpa_g* g) { return g->t_id; }
@ @<Public function prototypes@> =
gint marpa_grammar_id(struct marpa_g* g);

@*0 The Grammar's Symbol List.
This lists the symbols for the grammar,
with their
|Marpa_Symbol_ID| as the index.

@<Widely aligned grammar elements@> = GArray* t_symbols;
@ @<Initialize grammar elements@> =
g->t_symbols = g_array_new(FALSE, FALSE, sizeof(SYM));
@ @<Destroy grammar elements@> =
{  Marpa_Symbol_ID id; for (id = 0; id < (Marpa_Symbol_ID)g->t_symbols->len; id++)
{ symbol_free(SYM_by_ID(g, id)); } }
g_array_free(g->t_symbols, TRUE);

@ The trace accessor returns the GArray.
It remains "owned" by the Grammar,
and must not be freed or modified.
@<Function definitions@> =
GArray *marpa_g_symbols_peek(struct marpa_g* g)
{ return g->t_symbols; }
@ @<Public function prototypes@> =
GArray *marpa_g_symbols_peek(struct marpa_g* g);

@ Symbol count accesor.
@d SYM_Count_of_G(g) ((g)->t_symbols->len)

@ Symbol by ID.
@d SYM_by_ID(g, id) (g_array_index((g)->t_symbols, SYM, (id)))

@ Adds the symbol to the list of symbols kept by the Grammar
object.
@<Private inline functions@> =
static inline
void g_symbol_add(
    struct marpa_g *g,
    Marpa_Symbol_ID symid,
    SYM symbol)
{
    g_array_insert_val(g->t_symbols, (unsigned)symid, symbol);
}

@ Check that symbol is in valid range.
@<Function definitions@> =
static inline gint symbol_is_valid(
const struct marpa_g *g, const Marpa_Symbol_ID symid) {
return symid >= 0 && (guint)symid < g->t_symbols->len;
}
@ @<Private function prototypes@> =
static inline gint symbol_is_valid(
const struct marpa_g *g, const Marpa_Symbol_ID symid);

@*0 The Grammar's Rule List.
This lists the rules for the grammar,
with their |Marpa_Rule_ID| as the index.
@<Widely aligned grammar elements@> = GArray* t_rules;
@ @<Initialize grammar elements@> =
g->t_rules = g_array_new(FALSE, FALSE, sizeof(RULE));
@ @<Destroy grammar elements@> =
g_array_free(g->t_rules, TRUE);

@ The trace accessor returns the GArray.
It remains "owned" by the Grammar,
and must not be freed or modified.
@<Function definitions@> =
GArray *marpa_g_rules_peek(struct marpa_g* g)
{ return g->t_rules; }
@ @<Public function prototypes@> =
GArray *marpa_g_rules_peek(struct marpa_g* g);

@ Rule count accesor.
@<Function definitions@> =
static inline gint rule_count(const struct marpa_g* g) {
   return g->t_rules->len;
}
@ @<Private function prototypes@> =
static inline gint rule_count(const struct marpa_g* g);

@ Internal accessor to find a rule by its id.
@d RULE_by_ID(g, id) (g_array_index((g)->t_rules, RULE, (id)))

@ Adds the rule to the list of rules kept by the Grammar
object.
@<Private inline functions@> =
static inline
void rule_add(
    struct marpa_g *g,
    RULEID rule_id,
    RULE rule)
{
    g_array_insert_val(g->t_rules, (unsigned)rule_id, rule);
    LV_Size_of_G(g) += 1 + rule->t_length;
    g->t_max_rule_length = MAX(rule->t_length, g->t_max_rule_length);
}

@ Check that rule is in valid range.
@d RULEID_of_G_is_Valid(g, rule_id)
    ((rule_id) >= 0 && (guint)(rule_id) < (g)->t_rules->len)

@*0 Start Symbol.
@<Int aligned grammar elements@> = Marpa_Symbol_ID t_start_symid;
@ @<Initialize grammar elements@> =
g->t_start_symid = -1;
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_start_symbol(struct marpa_g* g)
{ return g->t_start_symid; }
@ @<Public function prototypes@> =
Marpa_Symbol_ID marpa_start_symbol(struct marpa_g* g);
@ Returns |TRUE| on success,
|FALSE| on failure.
@<Function definitions@> =
gboolean marpa_start_symbol_set(struct marpa_g*g, Marpa_Symbol_ID symid)
{
   @<Return |FALSE| on failure@>@;
    @<Fail if grammar is precomputed@>@;
    @<Fail if grammar |symid| is invalid@>@;
    g->t_start_symid = symid;
    return TRUE;
}
@ @<Public function prototypes@> =
gboolean marpa_start_symbol_set(struct marpa_g*g, Marpa_Symbol_ID id);

@*0 Start Rules.
These are the start rules, after the grammar is augmented.
Only one of these needs to be non-NULL.
@<Int aligned grammar elements@> =
RULE t_null_start_rule;
RULE t_proper_start_rule;
@ @<Initialize grammar elements@> =
g->t_null_start_rule = NULL;
g->t_proper_start_rule = NULL;

@*0 The Grammar's Size.
Intuitively,
I define a grammar's size as the total size, in symbols, of all of its
rules.
This includes both the LHS symbol and the RHS symbol.
Since every rule has exactly one LHS symbol,
the grammar's size is always equal to the total of
all the rules lengths, plus the total number of rules.

Unused rules are not included in the theoretical number,
but Marpa does not necessarily deduct rules from the
count as they are marked useless.
This means that the
grammar will always be of this size or smaller.
As rules are marked useless, they are not necessarily deducted
from the count.
The purpose of tracking grammar size is to allocate resources,
and for that purpose a high-ball estimate is adequate.
@d Size_of_G(g) ((g)->t_size)
@d LV_Size_of_G(g) ((g)->t_size)
@ @<Int aligned grammar elements@> = int t_size;
@ @<Initialize grammar elements@> =
LV_Size_of_G(g) = 0;

@*0 The Maximum Rule Length.
This is a high-ball estimate of the length of the
longest rule in the grammar.
The actual value will always be this number or smaller.
\par
The value is used for allocating resources.
Unused rules are not included in the theoretical number,
but Marpa does not adjust this number as rules
are marked useless.
@ @<Int aligned grammar elements@> = guint t_max_rule_length;
@ @<Initialize grammar elements@> =
g->t_max_rule_length = 0;

@*0 Grammar Boolean: Precomputed.
@ @<Public function prototypes@> =
gboolean marpa_is_precomputed(const struct marpa_g* const g);
@ @d G_is_Precomputed(g) ((g)->t_is_precomputed)
@<Bit aligned grammar elements@> = unsigned int t_is_precomputed:1;
@ @<Initialize grammar elements@> =
g->t_is_precomputed = FALSE;
@ @<Function definitions@> =
gboolean marpa_is_precomputed(const struct marpa_g* const g)
{ return G_is_Precomputed(g); }

@*0 Grammar Boolean: Has Loop.
@<Bit aligned grammar elements@> = unsigned int t_has_loop:1;
@ @<Initialize grammar elements@> =
g->t_has_loop = FALSE;
@ The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gboolean marpa_has_loop(struct marpa_g* g)
{ return g->t_has_loop; }
@ @<Public function prototypes@> =
gboolean marpa_has_loop(struct marpa_g* g);

@*0 Grammar Boolean: LHS Terminal OK.
Traditionally, a BNF grammar did {\bf not} allow a symbol
which was a terminal symbol of the grammar, to also be a LHS
symbol.
By default, this is allowed under Marpa.
@<Bit aligned grammar elements@> = unsigned int t_is_lhs_terminal_ok:1;
@ @<Initialize grammar elements@> =
g->t_is_lhs_terminal_ok = TRUE;
@ The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gboolean marpa_is_lhs_terminal_ok(struct marpa_g* g)
{ return g->t_is_lhs_terminal_ok; }
@ @<Public function prototypes@> =
gboolean marpa_is_lhs_terminal_ok(struct marpa_g* g);
@ Returns |TRUE| on success,
|FALSE| on failure.
@<Function definitions@> =
gboolean marpa_is_lhs_terminal_ok_set(
struct marpa_g*g, gboolean value)
{
    if (G_is_Precomputed(g)) {
        g->t_error = "precomputed";
	return FALSE;
    }
    g->t_is_lhs_terminal_ok = value;
    return TRUE;
}
@ @<Public function prototypes@> =
gboolean marpa_is_lhs_terminal_ok_set( struct marpa_g*g, gboolean value);

@*0 Terminal Boolean Vector.
A boolean vector, with bits sets if the symbol is a
terminal.
This is not used as the working vector while doing
the census, because not all symbols have been added at
that point.
At grammar initialization, this vector cannot be sized.
It is initialized to |NULL| so that the destructor
can tell if there is a bit vector to be freed.
@<Widely aligned grammar elements@> = Bit_Vector t_bv_symid_is_terminal;
@ @<Initialize grammar elements@> = g->t_bv_symid_is_terminal = NULL;
@ @<Destroy grammar elements@> =
if (g->t_bv_symid_is_terminal) { bv_free(g->t_bv_symid_is_terminal); }

@*0 The Grammar's Context.
The "context" is a hash of miscellaneous data,
by keyword.
It is so called because its purpose is to 
provide callbacks with "context" ---
data about
|libmarpa|'s state which is not conveniently
available in other forms.
@d Context_of_G(g) ((g)->t_context)
@<Widely aligned grammar elements@> = GHashTable* t_context;
@ @<Initialize grammar elements@> =
g->t_context = g_hash_table_new_full( g_str_hash, g_str_equal, NULL, g_free );
@ @<Destroy grammar elements@> = g_hash_table_destroy(Context_of_G(g));

@ @<Public defines@> =
#define MARPA_CONTEXT_INT 1@/
#define MARPA_CONTEXT_CONST 2@/
#define MARPA_IS_CONTEXT_INT(v) @| @[ ((v)->t_type == MARPA_CONTEXT_INT) @]@/
#define MARPA_CONTEXT_INT_VALUE(v) @| \
@[ ((v)->t_type == MARPA_CONTEXT_INT \
    ? ((struct marpa_context_int_value*)v)->t_data \
    : G_MININT) @]@/
#define MARPA_CONTEXT_STRING_VALUE(v) @| \
@[ ((v)->t_type == MARPA_CONTEXT_CONST \
    ? ((struct marpa_context_const_value*)v)->t_data \
    : NULL) @]@/
@ @<Public structures@> =
struct marpa_context_int_value {
   gint t_type;
   gint t_data;
};
@ @<Public structures@> =
struct marpa_context_const_value {
   gint t_type;
   const gchar* t_data;
};
@ @<Public structures@> =
union marpa_context_value {
   gint t_type;
   struct marpa_context_int_value t_int_value;
   struct marpa_context_const_value t_const_value;
};

@ Add an integer to the context.
These functions might be converted to be public.
For now they are only for use by |libmarpa| in setting
values to be read by the higher layers,
are therefore internal.

The const qualifier on the key is deliberately discarded.
As implemented, the keys are treated as const's by
|g_hash_table_insert|, but the compiler can't know
that is my intention.
For type safety, I do want to keep the |const|
qualifier in other contexts.
@<Function definitions@> =
static inline
void g_context_int_add(struct marpa_g* g, const gchar* key, gint payload)
{
    struct marpa_context_int_value* value
	= g_new(struct marpa_context_int_value, 1);
    value->t_type = MARPA_CONTEXT_INT;
    value->t_data = payload;
    g_hash_table_insert(Context_of_G(g), (gpointer)key, value);
}
@ @<Private function prototypes@> =
static inline
void g_context_int_add(struct marpa_g* g, const gchar* key, gint value);
@ @<Function definitions@> =
static inline
void context_const_add(struct marpa_g* g, const gchar* key, const gchar* payload)
{
    struct marpa_context_const_value* value
	= g_new(struct marpa_context_const_value, 1);
    value->t_type = MARPA_CONTEXT_CONST;
    value->t_data = payload;
    g_hash_table_insert(Context_of_G(g), (gpointer)key, value);
}
@ @<Private function prototypes@> =
static inline
void context_const_add(struct marpa_g* g, const gchar* key, const gchar* value);

@ Clear the current context.
Used to create a "clean slate" in the context.
@<Function definitions@> =
static inline void g_context_clear(struct marpa_g* g) {
    g_hash_table_remove_all(Context_of_G(g)); }
@ @<Private function prototypes@> =
static inline void g_context_clear(struct marpa_g* g);

@ @<Function definitions@> =
union marpa_context_value* marpa_g_context_value(struct marpa_g* g, const gchar* key)
{ return g_hash_table_lookup(Context_of_G(g), key); }
@ @<Public function prototypes@> =
union marpa_context_value* marpa_g_context_value(struct marpa_g* g, const gchar* key);

@*0 The Grammar Obstacks.
Two obstacks with the same lifetime as the grammar.
This is a very efficient way of allocating memory which won't be
resized and which will have the same lifetime as the grammar.
One obstack is reserved for of "tricky" operations
like |obs_free|,
which require coordination with other allocations.
The other obstack is reserved for "safe" operations---%
complete allocations which are never reversed.
The dual obstacks allow me to get tricky where it is useful,
which also allowing most obstack allocations to be done safely without
the need to carefully examine their context.
@<Widely aligned grammar elements@> =
struct obstack t_obs;
struct obstack t_obs_tricky;
@ @<Initialize grammar elements@> =
obstack_init(&g->t_obs);
obstack_init(&g->t_obs_tricky);
@ @<Destroy grammar elements@> =
obstack_free(&g->t_obs, NULL);
obstack_free(&g->t_obs_tricky, NULL);

@*0 The Grammar's Error ID.
This is an error flag for the grammar.
Error status is not necessarily cleared
on successful return, so that
it is only valid when an external
function has indicated there is an error,
and becomes invalid again when another external method
is called on the grammar.
Checking it at other times may reveal "stale" error
messages.
@<Public typedefs@> =
typedef const gchar* Marpa_Error_ID;
@ @<Widely aligned grammar elements@> = Marpa_Error_ID t_error;
@ @<Initialize grammar elements@> =
g->t_error = NULL;
@ There is no destructor.
The error strings are assummed to be
{\bf not} error messages, but "cookies".
These cookies are constants residing in static memory
(which may be read-only depending on implementation).
They cannot and should not be de-allocated.
@ @<Function definitions@> =
Marpa_Error_ID marpa_g_error(const struct marpa_g* g)
{ return g->t_error ? g->t_error : "unknown error"; }
@ @<Public function prototypes@> =
Marpa_Error_ID marpa_g_error(const struct marpa_g* g);

@** Symbol Objects.
@s Marpa_Symbol_ID int
@<Public typedefs@> =
typedef gint Marpa_Symbol_ID;
@ @<Private incomplete structures@> =
struct s_symbol;
typedef struct s_symbol* SYM;
typedef const struct s_symbol* SYM_Const;
@ @<Private structures@> =
struct s_symbol {
    @<Widely aligned symbol elements@>@/
    @<Int aligned symbol elements@>@/
    @<Bit aligned symbol elements@>@/
};
typedef struct s_symbol SYM_Object;
typedef gint SYMID;

@ @<Private function prototypes@> =
static inline
SYM symbol_new(struct marpa_g *g);
@ @<Function definitions@> =
static inline SYM
symbol_new (struct marpa_g *g)
{
  SYM symbol = g_malloc (sizeof (SYM_Object));
  @<Initialize symbol elements @>@/
  {
    Marpa_Symbol_ID id = symbol->t_id;
    g_symbol_add (g, id, symbol);
  }
  return symbol;
}

@ @<Public function prototypes@> =
Marpa_Symbol_ID marpa_symbol_new(struct marpa_g *g);
@ @<Function definitions@> =
Marpa_Symbol_ID
marpa_symbol_new (struct marpa_g * g)
{
  Marpa_Symbol_ID id = symbol_new (g)->t_id;
  symbol_callback (g, id);
  return id;
}

@ @<Function definitions@> =
static inline void symbol_free(SYM symbol)
{ @<Free symbol elements@>@; g_free(symbol); }
@ @<Private function prototypes@> =
static inline void symbol_free(SYM symbol);

@ Symbol ID: This is the unique identifier for the symbol.
@<Int aligned symbol elements@> = Marpa_Symbol_ID t_id;
@ @<Initialize symbol elements@> = symbol->t_id = g->t_symbols->len;

@*0 Symbol LHS Rules Element.
This tracks the rules for which this symbol is the LHS.
It is an optimization --- the same information could be found
by scanning the rules every time this information is needed.
The implementation is a |GArray|.
@d SYMBOL_LHS_RULE_COUNT(symbol) ((symbol)->t_lhs->len)
@<Widely aligned symbol elements@> = GArray* t_lhs;
@ @<Initialize symbol elements@> =
symbol->t_lhs = g_array_new(FALSE, FALSE, sizeof(Marpa_Rule_ID));
@ @<Free symbol elements@> =
g_array_free(symbol->t_lhs, TRUE);
@ The trace accessor returns the GArray.
It remains "owned" by the Grammar,
and must not be freed or modified.
@<Function definitions@> = 
GArray *marpa_symbol_lhs_peek(struct marpa_g* g, Marpa_Symbol_ID symid)
{ @<Return |NULL| on failure@>@;
@<Fail if grammar |symid| is invalid@>@;
return SYM_by_ID(g, symid)->t_lhs; }
@ @<Public function prototypes@> =
GArray *marpa_symbol_lhs_peek(struct marpa_g* g, Marpa_Symbol_ID symid);
@ @<Function definitions@> = static inline
void symbol_lhs_add(SYM symbol, Marpa_Rule_ID rule_id)
{ g_array_append_val(symbol->t_lhs, rule_id); }
void
marpa_symbol_lhs_add(struct marpa_g*g, Marpa_Symbol_ID symid, Marpa_Rule_ID rule_id)
{ symbol_lhs_add(SYM_by_ID(g, symid), rule_id); }
@ @<Private function prototypes@> =
void
marpa_symbol_lhs_add(struct marpa_g*g, Marpa_Symbol_ID symid, Marpa_Rule_ID rule_id);

@*0 Symbol RHS Rules Element.
This tracks the rules for which this symbol is the RHS.
It is an optimization --- the same information could be found
by scanning the rules every time this information is needed.
The implementation is a |GArray|.
@<Widely aligned symbol elements@> = GArray* t_rhs;
@ @<Initialize symbol elements@> =
symbol->t_rhs = g_array_new(FALSE, FALSE, sizeof(Marpa_Rule_ID));
@ @<Free symbol elements@> = g_array_free(symbol->t_rhs, TRUE);
@ The trace accessor returns the GArray.
It remains "owned" by the Grammar,
and must not be freed or modified.
@<Function definitions@> = 
GArray *marpa_symbol_rhs_peek(struct marpa_g* g, Marpa_Symbol_ID symid)
{ @<Return |NULL| on failure@>@;
@<Fail if grammar |symid| is invalid@>@;
return SYM_by_ID(g, symid)->t_rhs; }
@ @<Public function prototypes@> =
GArray *marpa_symbol_rhs_peek(struct marpa_g* g, Marpa_Symbol_ID symid);
@ @<Function definitions@> = static inline
void symbol_rhs_add(SYM symbol, Marpa_Rule_ID rule_id)
{ g_array_append_val(symbol->t_rhs, rule_id); }
@ @<Private function prototypes@> = static inline
void symbol_rhs_add(SYM symbol, Marpa_Rule_ID rule_id);

@ Symbol Is Accessible Boolean
@<Bit aligned symbol elements@> = unsigned int t_is_accessible:1;
@ @<Initialize symbol elements@> =
symbol->t_is_accessible = FALSE;
@ The trace accessor returns the Boolean value.
Right now this function uses a pointer
to the symbol function.
If that becomes private,
the prototype of this function
must be changed.
\par
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gboolean marpa_symbol_is_accessible(struct marpa_g* g, Marpa_Symbol_ID id)
{ return SYM_by_ID(g, id)->t_is_accessible; }
@ @<Public function prototypes@> =
gboolean marpa_symbol_is_accessible(struct marpa_g* g, Marpa_Symbol_ID id);
@ The external mutator is temporary, for development.
@<Function definitions@> =
void marpa_symbol_is_accessible_set(
struct marpa_g*g, Marpa_Symbol_ID id, gboolean value)
{ SYM_by_ID(g, id)->t_is_accessible = value; }
@ @<Public function prototypes@> =
/* static inline */
void marpa_symbol_is_accessible_set( struct marpa_g*g, Marpa_Symbol_ID id, gboolean value);

@ Symbol Is Counted Boolean
@<Bit aligned symbol elements@> = unsigned int t_is_counted:1;
@ @<Initialize symbol elements@> =
symbol->t_is_counted = FALSE;
@ The trace accessor returns the Boolean value.
Right now this function uses a pointer
to the symbol function.
If that becomes private,
the prototype of this function
must be changed.
\par
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gboolean marpa_symbol_is_counted(struct marpa_g* g, Marpa_Symbol_ID id)
{ return SYM_by_ID(g, id)->t_is_counted; }
@ @<Public function prototypes@> =
gboolean marpa_symbol_is_counted(struct marpa_g* g, Marpa_Symbol_ID id);

@ Symbol Is Nullable Boolean
@<Bit aligned symbol elements@> = unsigned int t_is_nullable:1;
@ @<Initialize symbol elements@> =
symbol->t_is_nullable = FALSE;
@ The trace accessor returns the Boolean value.
Right now this function uses a pointer
to the symbol function.
If that becomes private,
the prototype of this function
must be changed.
\par
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gboolean marpa_symbol_is_nullable(struct marpa_g* g, Marpa_Symbol_ID id)
{ return SYM_by_ID(g, id)->t_is_nullable; }
@ @<Public function prototypes@> =
gboolean marpa_symbol_is_nullable(struct marpa_g* g, Marpa_Symbol_ID id);
@ The external mutator is temporary, for development.
@<Function definitions@> =
void marpa_symbol_is_nullable_set(
struct marpa_g*g, Marpa_Symbol_ID id, gboolean value)
{ SYM_by_ID(g, id)->t_is_nullable = value; }
@ @<Public function prototypes@> =
void marpa_symbol_is_nullable_set( struct marpa_g*g, Marpa_Symbol_ID id, gboolean value);

@ Symbol Is Nulling Boolean
@<Bit aligned symbol elements@> = unsigned int t_is_nulling:1;
@ @<Initialize symbol elements@> =
symbol->t_is_nulling = FALSE;
@ The trace accessor returns the Boolean value.
Right now this function uses a pointer
to the symbol function.
If that becomes private,
the prototype of this function
must be changed.
\par
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gint marpa_symbol_is_nulling(struct marpa_g* g, Marpa_Symbol_ID symid)
{ @<Return |-2| on failure@>@;
@<Fail if grammar |symid| is invalid@>@;
return SYM_by_ID(g, symid)->t_is_nulling; }
@ @<Public function prototypes@> =
gint marpa_symbol_is_nulling(struct marpa_g* g, Marpa_Symbol_ID id);
@ The external mutator is temporary, for development.
@<Function definitions@> =
void marpa_symbol_is_nulling_set(
struct marpa_g*g, Marpa_Symbol_ID id, gboolean value)
{ SYM_by_ID(g, id)->t_is_nulling = value; }
@ @<Public function prototypes@> = 
void marpa_symbol_is_nulling_set( struct marpa_g*g, Marpa_Symbol_ID id, gboolean value);

@ Symbol Is Terminal Boolean
@<Bit aligned symbol elements@> = unsigned int t_is_terminal:1;
@ @<Initialize symbol elements@> =
symbol->t_is_terminal = FALSE;
@ The trace accessor returns the Boolean value.
Right now this function uses a pointer
to the symbol function.
If that becomes private,
the prototype of this function
must be changed.
\par
The internal accessor would be trivial, so there is none.
@d SYM_is_Terminal(symbol) ((symbol)->t_is_terminal)
@d SYMID_is_Terminal(g, id) (SYM_is_Terminal(SYM_by_ID((g), (id))))
@d LV_SYMID_is_Terminal(g, id) SYMID_is_Terminal((g), (id))
@<Function definitions@> =
gboolean marpa_symbol_is_terminal(struct marpa_g* g, Marpa_Symbol_ID id)
{ return SYMID_is_Terminal(g, id); }
@ @<Public function prototypes@> =
gboolean marpa_symbol_is_terminal(struct marpa_g* g, Marpa_Symbol_ID id);
@ The external mutator is temporary, for development.
@<Function definitions@> =
void marpa_symbol_is_terminal_set(
struct marpa_g*g, Marpa_Symbol_ID id, gboolean value)
{ LV_SYMID_is_Terminal(g, id) = value; }
@ @<Public function prototypes@> =
void marpa_symbol_is_terminal_set( struct marpa_g*g, Marpa_Symbol_ID id, gboolean value);


@ Symbol Is Productive Boolean
@<Bit aligned symbol elements@> = unsigned int t_is_productive:1;
@ @<Initialize symbol elements@> =
symbol->t_is_productive = FALSE;
@ The trace accessor returns the Boolean value.
Right now this function uses a pointer
to the symbol function.
If that becomes private,
the prototype of this function
must be changed.
\par
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gboolean marpa_symbol_is_productive(struct marpa_g* g, Marpa_Symbol_ID id)
{ return SYM_by_ID(g, id)->t_is_productive; }
@ @<Public function prototypes@> =
gboolean marpa_symbol_is_productive(struct marpa_g* g, Marpa_Symbol_ID id);
@ The external mutator is temporary, for development.
@<Function definitions@> =
void marpa_symbol_is_productive_set(
struct marpa_g*g, Marpa_Symbol_ID id, gboolean value)
{ SYM_by_ID(g, id)->t_is_productive = value ? 1 : 0; }
@ @<Public function prototypes@> =
void marpa_symbol_is_productive_set( struct marpa_g*g, Marpa_Symbol_ID id, gboolean value);

@ Symbol Is Start Boolean
@<Bit aligned symbol elements@> = unsigned int t_is_start:1;
@ @<Initialize symbol elements@> = symbol->t_is_start = FALSE;
@ Accessor: The trace accessor returns the Boolean value.
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
static inline
gint symbol_is_start(SYM symbol)
{ return symbol->t_is_start; }
gint marpa_symbol_is_start( struct marpa_g*g, Marpa_Symbol_ID symid) 
{ @<Return |-2| on failure@>@;
@<Fail if grammar |symid| is invalid@>@;
   return symbol_is_start(SYM_by_ID(g, symid));
}
@ @<Private function prototypes@> =
static inline
gint symbol_is_start(SYM symbol);
@ @<Public function prototypes@> =
gint marpa_symbol_is_start( struct marpa_g*g, Marpa_Symbol_ID id);

@ Symbol Aliasing:
This is the logic for aliasing symbols.
In the Aycock-Horspool algorithm, from which Marpa is derived,
it is essential that there be no "proper nullable"
symbols.  Therefore, all proper nullable symbols in
the original grammar are converted into two, aliased,
symbols: a non-nullable (or "proper") alias and a nulling alias.
@<Bit aligned symbol elements@> =
unsigned int t_is_proper_alias:1;
unsigned int t_is_nulling_alias:1;
@ @<Widely aligned symbol elements@> =
struct s_symbol* t_alias;
@ @<Initialize symbol elements@> =
symbol->t_is_proper_alias = FALSE;
symbol->t_is_nulling_alias = FALSE;
symbol->t_alias = NULL;

@ Proper Alias Trace Accessor:
If this symbol is a nulling symbol
with a proper alias, returns the proper alias.
Otherwise, returns |NULL|.
@<Function definitions@> =
static inline
SYM symbol_proper_alias(SYM symbol)
{ return symbol->t_is_nulling_alias ? symbol->t_alias : NULL; }
Marpa_Symbol_ID marpa_symbol_proper_alias(struct marpa_g* g, Marpa_Symbol_ID symid)
{
SYM symbol;
SYM proper_alias;
@<Return |-2| on failure@>@;
@<Fail if grammar |symid| is invalid@>@;
symbol = SYM_by_ID(g, symid);
proper_alias = symbol_proper_alias(symbol);
return proper_alias == NULL ? -1 : proper_alias->t_id;
}
@ @<Private function prototypes@> =
static inline SYM symbol_proper_alias(SYM symbol);
@ @<Public function prototypes@> =
Marpa_Symbol_ID marpa_symbol_proper_alias(struct marpa_g* g, Marpa_Symbol_ID symid);

@ Nulling Alias Trace Accessor:
If this symbol is a proper (non-nullable) symbol
with a nulling alias, returns the nulling alias.
Otherwise, returns |NULL|.
@<Function definitions@> =
static inline
SYM symbol_null_alias(SYM symbol)
{ return symbol->t_is_proper_alias ? symbol->t_alias : NULL; }
Marpa_Symbol_ID marpa_symbol_null_alias(struct marpa_g* g, Marpa_Symbol_ID symid)
{
SYM symbol;
SYM alias;
@<Return |-2| on failure@>@;
@<Fail if grammar |symid| is invalid@>@;
symbol = SYM_by_ID(g, symid);
alias = symbol_null_alias(symbol);
if (alias == NULL) {
    g_context_int_add(g, "symid", symid);
    g->t_error = "no alias";
    return -1;
}
return alias->t_id;
}
@ @<Private function prototypes@> =
static inline SYM symbol_null_alias(SYM symbol);
@ @<Public function prototypes@> =
Marpa_Symbol_ID marpa_symbol_null_alias(struct marpa_g* g, Marpa_Symbol_ID symid);

@ Given a proper nullable symbol as its argument,
converts the argument into two "aliases".
The proper (non-nullable) alias will have the same symbol ID
as the arugment.
The nulling alias will have a new symbol ID.
The return value is a pointer to the nulling alias.
TODO: I expect to delete
the external version of this function after
development.
@<Function definitions@> = static inline
SYM symbol_alias_create(struct marpa_g* g,
SYM symbol)
{
    SYM alias = symbol_new(g);
    symbol->t_is_proper_alias = TRUE;
    symbol->t_is_nulling = FALSE;
    symbol->t_is_nullable = FALSE;
    symbol->t_alias = alias;
    alias->t_is_nulling_alias = TRUE;
    alias->t_is_nulling = TRUE;
    alias->t_is_nullable = TRUE;
    alias->t_is_productive = TRUE;
    alias->t_is_accessible = symbol->t_is_accessible;
    alias->t_alias = symbol;
    return alias;
}
Marpa_Symbol_ID marpa_symbol_alias_create(
struct marpa_g* g, Marpa_Symbol_ID original_id)
{ Marpa_Symbol_ID alias_id;
    if (original_id < 0) { return -1; }
    if ((guint)original_id >= g->t_symbols->len) { return -1; }
    alias_id = symbol_alias_create(g, SYM_by_ID(g, original_id))->t_id;
    symbol_callback(g, alias_id);
    return alias_id; }
@ @<Private function prototypes@> = 
static inline
SYM symbol_alias_create(struct marpa_g* g,
SYM symbol);
@ @<Public function prototypes@> = 
Marpa_Symbol_ID marpa_symbol_alias_create(
struct marpa_g* g, Marpa_Symbol_ID symid);

@ {\bf Symbol callbacks}:  The user can define a callback
(with argument) which is invoked whenever a symbol
is created.
@ Function pointer declarations are
hard to type and impossible to read.
This typedef localizes the damage.
@<Callback typedefs@> =
typedef void (Marpa_Symbol_Callback)(struct marpa_g *g, Marpa_Symbol_ID id);
@ @<Widely aligned grammar elements@> =
    Marpa_Symbol_Callback* t_symbol_callback;
    gpointer t_symbol_callback_arg;
@ @<Initialize grammar elements@> =
g->t_symbol_callback_arg = NULL;
g->t_symbol_callback = NULL;
@ @<Function definitions@> =
void marpa_symbol_callback_set(struct marpa_g *g, Marpa_Symbol_Callback*cb)
{ g->t_symbol_callback = cb; }
void marpa_symbol_callback_arg_set(struct marpa_g *g, gpointer cb_arg)
{ g->t_symbol_callback_arg = cb_arg; }
gpointer marpa_symbol_callback_arg(struct marpa_g *g)
{ return g->t_symbol_callback_arg; }
@ @<Public function prototypes@> =
void marpa_symbol_callback_set(struct marpa_g *g, Marpa_Symbol_Callback*cb);
void marpa_symbol_callback_arg_set(struct marpa_g *g, gpointer cb_arg);
gpointer marpa_symbol_callback_arg(struct marpa_g *g);
@ Do the symbol callback.
@^To Do@>  To Do: Deal with the possibility of leaking memory if the callback
never returns, but the grammar is destroyed.
@<Function definitions@> =
static inline void symbol_callback(struct marpa_g *g, Marpa_Symbol_ID id)
{ Marpa_Symbol_Callback* cb = g->t_symbol_callback;
if (cb) { (*cb)(g, id); } }
@ @<Private function prototypes@> =
static inline void symbol_callback(struct marpa_g *g, Marpa_Symbol_ID id);

@** Rule (RULE) Code.
@s Marpa_Rule_ID int
@<Public typedefs@> =
typedef gint Marpa_Rule_ID;
@ @<Private structures@> =
struct s_rule {
    @<Int aligned rule elements@>@/
    @<Bit aligned rule elements@>@/
    @<Final rule elements@>@/
};
@
@s RULE int
@s RULEID int
@<Private typedefs@> =
struct s_rule;
typedef struct s_rule* RULE;
typedef Marpa_Rule_ID RULEID;

@ @<Function definitions@> =
static inline guint rule_sizeof(guint length) {
return sizeof(struct s_rule) + length*sizeof(Marpa_Symbol_ID);
}
@ @<Private function prototypes@> =
static inline guint rule_sizeof(guint length);

@*0 Rule Construction.
@ Set up the basic data.
This logic is intended to be common to all individual rules.
The name comes from the idea that this logic "starts"
the initialization of a rule.
@ GCC complains about inlining |rule_start| -- it is
not a tiny function, and it is repeated often.
@<Function definitions@> =
static
RULE rule_start(struct marpa_g *g,
Marpa_Symbol_ID lhs, Marpa_Symbol_ID *rhs, guint length)
{
    @<Return |NULL| on failure@>@;
    RULE rule;
    @<Return failure on invalid rule symbols@>@/
    rule = obstack_alloc(&g->t_obs, rule_sizeof(length));
    @<Initialize rule symbols@>@/
    @<Initialize rule elements@>@/
    rule_add(g, rule->t_id, rule);
    @<Add this rule to the symbol rule lists@>
   return rule;
}
@ @<Private function prototypes@> =
static
RULE rule_start(struct marpa_g *g,
Marpa_Symbol_ID lhs, Marpa_Symbol_ID *rhs, guint length);

@ @<Function definitions@> =
Marpa_Rule_ID marpa_rule_new(struct marpa_g *g,
Marpa_Symbol_ID lhs, Marpa_Symbol_ID *rhs, guint length)
{
    Marpa_Rule_ID rule_id;
    RULE rule;
    if (is_rule_duplicate(g, lhs, rhs, length) == TRUE) {
	g->t_error = (Marpa_Error_ID)"duplicate rule";
        return -1;
    }@;
    rule = rule_start(g, lhs, rhs, length);
    if (!rule) { return -1; }@;
    rule_id = rule->t_id;
    rule_callback(g, rule_id);
    return rule_id;
}

@ @<Function definitions@> =
Marpa_Rule_ID marpa_sequence_new(struct marpa_g *g,
Marpa_Symbol_ID lhs_id, Marpa_Symbol_ID rhs_id, Marpa_Symbol_ID separator_id,
guint min, gint flags )
{
    @<Return |-2| on failure@>@;
    Marpa_Rule_ID original_rule_id;
    RULE original_rule;
    Marpa_Symbol_ID internal_lhs_id, *temp_rhs;@;
    if (is_rule_duplicate(g, lhs_id, &rhs_id, 1) == TRUE) {
	g_context_clear(g);
	g->t_error = (Marpa_Error_ID)"duplicate rule";
        return failure_indicator;
    }

    @<Add the original rule for a sequence@>@;
    @<Check that the separator is valid or -1@>@;
    @<Mark the counted symbols@>@;
    if (min == 0) { @<Add the nulling rule for a sequence@>@; }
    min = 1;
    @<Create the internal LHS symbol@>@;
    @<Allocate the temporary rhs buffer@>@;
    @<Add the top rule for the sequence@>@;
    if (separator_id >= 0 && !(flags & MARPA_PROPER_SEPARATION)) {
	@<Add the alternate top rule for the sequence@>@;
    }
    @<Add the minimum rule for the sequence@>@;
    @<Add the iterating rule for the sequence@>@;
    @<Free the temporary rhs buffer@>@;
    return original_rule_id;
}
@ @<Public function prototypes@> =
Marpa_Rule_ID marpa_sequence_new(struct marpa_g *g,
Marpa_Symbol_ID lhs_id, Marpa_Symbol_ID rhs_id, Marpa_Symbol_ID separator_id,
guint min, gint flags );
@ As a side effect, this checks the LHS and RHS symbols for validity.
@<Add the original rule for a sequence@> =
    original_rule = rule_start(g, lhs_id, &rhs_id, 1);
    if (!original_rule) {
	g_context_clear(g);
	g->t_error = "internal_error";
	return failure_indicator;
    }
    original_rule->t_is_used = 0;
    original_rule_id = original_rule->t_id;
    rule_callback(g, original_rule_id);

@ @<Check that the separator is valid or -1@> =
if (separator_id != -1 && !symbol_is_valid(g, separator_id)) {
    g_context_clear(g);
    g_context_int_add(g, "symid", separator_id);
    g->t_error = "bad separator";
    return failure_indicator;
}

@ @<Mark the counted symbols@> =
SYM_by_ID(g, rhs_id)->t_is_counted = 1;
if (separator_id >= 0) { SYM_by_ID(g, separator_id)->t_is_counted = 1; }
@ @<Add the nulling rule for a sequence@> =
	{ RULE rule = rule_start(g, lhs_id, 0, 0);
	if (!rule) { @<Fail with internal grammar error@>@; }
	rule->t_is_semantic_equivalent = TRUE;
	rule->t_original = original_rule_id;
	rule_callback(g, rule->t_id);
	}
@ @<Create the internal LHS symbol@> =
    internal_lhs_id = symbol_new(g)->t_id;
    symbol_callback(g, internal_lhs_id);
@ The actual size needed for the RHS buffer is determined by
the longer of minimum rule and the iterating rule.
The iterating rule may require 3 RHS symbols, if there is
a separator.
(We have $min>=1$ at this point.)
The minimum rule will require $1 + 2 * (min - 1)$ symbols
with a separator, and $min$ symbols without.
The allocation below uses a simplified expression, which
overallocates.
Worst case is the minimum rule with a separator, in
which case it allocates 4 bytes too many.
@<Allocate the temporary rhs buffer@> =
temp_rhs = g_new(Marpa_Symbol_ID, (3 + (separator_id < 0 ? 1 : 2) * min));
@ @<Free the temporary rhs buffer@> = g_free(temp_rhs);
@ @<Add the top rule for the sequence@> =
{ RULE rule;
temp_rhs[0] = internal_lhs_id;
rule = rule_start(g, lhs_id, temp_rhs, 1);
if (!rule) { @<Fail with internal grammar error@>@; }
rule->t_original = original_rule_id;
rule->t_is_semantic_equivalent = TRUE;
/* Real symbol count remains at default of 0 */
rule->t_is_virtual_rhs = TRUE;
rule->t_is_discard = !(flags & MARPA_KEEP_SEPARATION) && separator_id >= 0;
rule_callback(g, rule->t_id);
}
@ This "alternate" top rule is needed if a final separator is allowed.
@<Add the alternate top rule for the sequence@> =
{ RULE rule;
    temp_rhs[0] = internal_lhs_id;
    temp_rhs[1] = separator_id;
    rule = rule_start(g, lhs_id, temp_rhs, 2);
    if (!rule) { @<Fail with internal grammar error@>@; }
    rule->t_original = original_rule_id;
    rule->t_is_semantic_equivalent = TRUE;
    rule->t_is_virtual_rhs = TRUE;
    rule->t_real_symbol_count = 1;
    rule->t_is_discard = !(flags & MARPA_KEEP_SEPARATION);
    rule_callback(g, rule->t_id);
}
@ The traditional way to write a sequence in BNF is with one
rule to represent the minimum, and another to deal with iteration.
That's the core of Marpa's rewrite.  This is the minimum
rule.
@<Add the minimum rule for the sequence@> =
{ RULE rule;
guint rhs_ix, i;
    temp_rhs[0] = rhs_id;
    rhs_ix = 1;
    for (i = 0; i < min - 1; i++) {
        if (separator_id >= 0) temp_rhs[rhs_ix++] = separator_id;
        temp_rhs[rhs_ix++] = rhs_id;
    }
    rule = rule_start(g, internal_lhs_id, temp_rhs, rhs_ix);
    if (!rule) { @<Fail with internal grammar error@>@; }
    rule->t_is_virtual_lhs = TRUE;
    rule->t_real_symbol_count = rhs_ix;
    rule_callback(g, rule->t_id);
}
@ @<Add the iterating rule for the sequence@> =
{ RULE rule;
guint rhs_ix = 0;
    temp_rhs[rhs_ix++] = internal_lhs_id;
    if (separator_id >= 0) temp_rhs[rhs_ix++] = separator_id;
    temp_rhs[rhs_ix++] = rhs_id;
    rule = rule_start(g, internal_lhs_id, temp_rhs, rhs_ix);
    if (!rule) { @<Fail with internal grammar error@>@; }
    rule->t_is_virtual_lhs = TRUE;
    rule->t_is_virtual_rhs = TRUE;
    rule->t_real_symbol_count = rhs_ix - 1;
    rule_callback(g, rule->t_id);
}

@ Does this rule duplicate an already existing rule?
A duplicate is a rule with the same lhs symbol,
the same rhs length,
and the same symbol in each position on the rhs.

Note that this definition of duplicate applies to
sequences as well.  That means that a sequence rule
can be a duplicate of a non-sequence rule of length 1,
if they have the same lhs symbols and the same rhs
symbol.
Also, that means you cannot define sequences
that differ only in the separator, or only in the
minimum count.

I do not think the
restrictions on sequence rules represent real limitations.
Multiple sequences with the same lhs and rhs would be
very confusing.
And users who really, really want such them are free
to write the sequences out as BNF rules.
After all, sequence rules are only a shorthand.
And shorthand is counter-productive when it makes
you lose track of what you are trying to say.

The algorithm is the first get a list of all the rules
with the same LHS, which is very fast because
I have pre-computed it.
If there are no such rules, the new rule is
unique (not a duplicate).
If there are such rules, I look at them,
trying to find one that duplicates the new
rule.
For each old rule, I first compare its length to
the new rule, and then its right hand side
symbols, one by one.
If all these comparisons succeed, I conclude
that the old rule duplicates the new one
and return |TRUE|.
If, after having done the comparison for all
the "same LHS" rules, I have found no duplicates,
then I conclude there is no duplicate of the new
rule, and return |FALSE|.
@<Function definitions@> =
static inline
gboolean is_rule_duplicate(struct marpa_g* g,
Marpa_Symbol_ID lhs_id, Marpa_Symbol_ID* rhs_ids, guint length)
{
    guint ix;
    SYM lhs = SYM_by_ID(g, lhs_id);
    GArray* same_lhs_array = lhs->t_lhs;
    guint same_lhs_count = same_lhs_array->len;
    for (ix = 0; ix < same_lhs_count; ix++) {
	RULEID same_lhs_rule_id = ((RULEID *)(same_lhs_array->data))[ix];
	guint rhs_position;
	RULE rule = RULE_by_ID(g, same_lhs_rule_id);
	if (rule->t_length != length) { goto RULE_IS_NOT_DUPLICATE; }
	for (rhs_position = 0; rhs_position < rule->t_length; rhs_position++) {
	    if (rhs_symid(rule, rhs_position) != rhs_ids[rhs_position]) {
	        goto RULE_IS_NOT_DUPLICATE;
	    }
	}
	return TRUE; /* This rule duplicates the new one */
	RULE_IS_NOT_DUPLICATE: ;
    }
    return FALSE; /* No duplicate rules were found */
}
@ @<Private function prototypes@> =
static inline
gboolean is_rule_duplicate(struct marpa_g* g,
Marpa_Symbol_ID lhs_id, Marpa_Symbol_ID* rhs_ids, guint length);

@ @<Public function prototypes@> =
Marpa_Rule_ID marpa_rule_new(struct marpa_g *g,
Marpa_Symbol_ID lhs, Marpa_Symbol_ID *rhs, guint length);

@ Add the rules to the symbol's rule lists:
An obstack scratchpad might be useful for
the copy of the RHS symbols.
|alloca|, while tempting, should not used
because an unusually long RHS could cause
a stack overflow.
Even if such case is pathological,
a core dump is not the right response.
@<Add this rule to the symbol rule lists@> =
    symbol_lhs_add(SYM_by_ID(g, rule->t_symbols[0]), rule->t_id);@;
    if (rule->t_length > 0) {
	gint rh_list_ix;
	const guint alloc_size = rule->t_length*sizeof( Marpa_Symbol_ID);
	Marpa_Symbol_ID *rh_symbol_list = g_slice_alloc(alloc_size);
	gint rh_symbol_list_length = 1;
	@<Create |rh_symbol_list|,
	a duplicate-free list of the right hand side symbols@>@;
       for (rh_list_ix = 0;
	   rh_list_ix < rh_symbol_list_length;
	   rh_list_ix++) {
	    symbol_rhs_add(
		SYM_by_ID(g, rh_symbol_list[rh_list_ix]),
		rule->t_id);
       }@;
       g_slice_free1(alloc_size, rh_symbol_list);
    }

@ \marpa_sub{Create a duplicate-free list of the right hand side symbols}
The algorithm is a
hand-coded
insertion sort, modified to not insert duplicates.
@ The first goal is to optimize for the usual case,
where both the average and root mean square of
number of unique symbols on the RHS of a rule
is a small number -- usually less
than 10.
(Root mean square is more relevant than the average for
comparison with worst case performance.)
bizarrely long.
A hand-inlined insertion sort is perfect for
this.
\par It might be thought that the below could
be improved by finding the insertion point
with a binary search, but when the number of RHS symbols
for most rules is less than a certain number,
a the higher-overhead binary search is worse,
not better.
This number is probably around 8, and in practice most rules
are shorter than that.
A reasonable alternative is to only use binary search above
a certain size, but in most cases that will produce no
measurable improvement.

@ A second goal is that behavior for unusual and pathological
cases be, if not optimal, reasonable.
Worst case for insertion sort is $O(n^2)$).
(This is why I used the root mean square, not a simple average.)
This would be approached if most of the right hand symbols were
in very long rules.
$O(n^2)$ is in fact, not actually a worse case than the quicksort
on which |qsort| is usually based.
The hand-coding here means it would take some effort to
construct a case in which
the theoretical advantage of another
sort algorithm would
show up in practice.
\par If anyone comes to care about very long right hand sides,
this algorithm can be changed to switch over to mergesort
when the right hand side exceeds a certain length.
The cost of an extra comparision is tiny, but then again,
so would the likelihood of any benefit from an alternative sort
algorithm would also
be tiny.

@ The code assumes that the rhs has length greater than zero.
@<Create |rh_symbol_list|, a duplicate-free list of the right hand side symbols@> =
{
/* Handle the first symbol as a special case */
gint rhs_ix = (gint)rule->t_length-1;
rh_symbol_list[0] = rhs_symid(rule, (unsigned)rhs_ix);
rh_symbol_list_length = 1;
rhs_ix--;
for (; rhs_ix >= 0; rhs_ix--) {
    gint higher_ix;
    Marpa_Symbol_ID new_symid = rhs_symid(rule, (unsigned)rhs_ix);
    gint next_highest_ix = rh_symbol_list_length - 1;
    while (next_highest_ix >= 0) {
	Marpa_Symbol_ID current_symid = rh_symbol_list[next_highest_ix];
	if (current_symid == new_symid) goto ignore_this_symbol;
	if (current_symid < new_symid) break;
        next_highest_ix--;
    }
    /* Shift the higher symbol ID's up one slot */
    for (higher_ix = rh_symbol_list_length-1;
	    higher_ix > next_highest_ix;
	    higher_ix--) {
        rh_symbol_list[higher_ix+1] = rh_symbol_list[higher_ix];
    }
    /* Insert the next symbol */
    rh_symbol_list[next_highest_ix+1] = new_symid;
    rh_symbol_list_length++;
    ignore_this_symbol: ;
}
}

@*0 Rule Symbols.
A rule takes the traditiona form of
a left hand side (LHS), and a right hand side (RHS).
The {\bf length} of a rule is the length of the RHS ---
there is always exactly one LHS symbol.
@<Int aligned rule elements@> = guint t_length;
@ The symbols come at the end of the |marpa_rule| structure,
so that they can be variable length.
@<Final rule elements@> = Marpa_Symbol_ID t_symbols[1];

@ @<Return failure on invalid rule symbols@> =
{
    SYMID symid = lhs;
    @<Fail if grammar |symid| is invalid@>@;
}
{ guint rh_index;
    for (rh_index = 0; rh_index<length; rh_index++) {
	SYMID symid = rhs[rh_index];
	@<Fail if grammar |symid| is invalid@>@;
    }
}

@ @<Initialize rule symbols@> =
rule->t_length = length;
rule->t_symbols[0] = lhs;
{ guint i; for (i = 0; i<length; i++) {
    rule->t_symbols[i+1] = rhs[i]; } }
@ @<Function definitions@> =
static inline Marpa_Symbol_ID rule_lhs_get(RULE rule) {
    return rule->t_symbols[0]; }
@ @<Private function prototypes@> =
static inline Marpa_Symbol_ID rule_lhs_get(RULE rule);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_rule_lhs(struct marpa_g *g, Marpa_Rule_ID rule_id) {
    @<Return |-2| on failure@>@;
    @<Fail if grammar |rule_id| is invalid@>@;
    return rule_lhs_get(RULE_by_ID(g, rule_id)); }
@ @<Public function prototypes@> =
Marpa_Symbol_ID marpa_rule_lhs(struct marpa_g *g, Marpa_Rule_ID rule_id);
@ @<Function definitions@> =
static inline Marpa_Symbol_ID* rule_rhs_get(RULE rule) {
    return rule->t_symbols+1; }
@ @<Private function prototypes@> =
static inline Marpa_Symbol_ID* rule_rhs_get(RULE rule);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_rule_rh_symbol(struct marpa_g *g, Marpa_Rule_ID rule_id, guint ix) {
    RULE rule;
    @<Return |-2| on failure@>@;
    @<Fail if grammar |rule_id| is invalid@>@;
    rule = RULE_by_ID(g, rule_id);
    if (rule->t_length <= ix) return -1;
    return rhs_symid(rule, ix);
}
@ @<Public function prototypes@> =
Marpa_Symbol_ID marpa_rule_rh_symbol(struct marpa_g *g, Marpa_Rule_ID rule_id, guint ix);
@ @<Function definitions@> =
static inline gsize rule_length_get(RULE rule) {
    return rule->t_length; }
@ @<Private function prototypes@> =
static inline gsize rule_length_get(RULE rule);
@ @<Function definitions@> =
gint marpa_rule_length(struct marpa_g *g, Marpa_Rule_ID rule_id) {
    @<Return |-2| on failure@>@;
    @<Fail if grammar |rule_id| is invalid@>@;
    return rule_length_get(RULE_by_ID(g, rule_id)); }
@ @<Public function prototypes@> =
gint marpa_rule_length(struct marpa_g *g, Marpa_Rule_ID rule_id);

@*1 LHS Symbol of Rule.
@d LHS_ID_of_PRD(production) ((production)->t_symbols[0])

@*1 RHS Symbol of Rule.
@ @<Function definitions@> =
static inline Marpa_Symbol_ID
    rhs_symid(RULE  rule, guint rh_index) {
	return rule->t_symbols[rh_index+1];
    }
@ @<Private function prototypes@> =
static inline Marpa_Symbol_ID rhs_symid(RULE  rule, guint rh_index);

@*0 Rule ID.
The {\bf rule ID} is a number which
acts as the unique identifier for a rule.
@d ID_of_RULE(rule) ((rule)->t_id)
@<Int aligned rule elements@> = Marpa_Rule_ID t_id;
@ @<Initialize rule elements@> = rule->t_id = g->t_rules->len;

@*0 Rule Boolean: Keep Separator.
When this rule is evaluated by the semantics,
do they want to see the separators?
Default is that they are thrown away.
Usually the role of the separators is only syntactic,
and that is what is wanted.
For non-sequence rules, this flag should be false.
@<Public defines@> =
#define MARPA_KEEP_SEPARATION @| @[0x1@]@/
@ @<Bit aligned rule elements@> = unsigned int t_is_discard:1;
@ @<Initialize rule elements@> =
rule->t_is_discard = FALSE;
@ @<Function definitions@> =
gboolean marpa_rule_is_discard_separation(struct marpa_g* g, Marpa_Rule_ID id)
{ return RULE_by_ID(g, id)->t_is_discard; }
@ @<Public function prototypes@> =
gboolean marpa_rule_is_discard_separation(struct marpa_g* g, Marpa_Rule_ID id);

@*0 Rule Boolean: Proper Separation.
In Marpa's terminology,
proper separation means that a sequence
cannot legally end with a separator.
In "proper" separation,
the term separator is interpreted strictly,
as something which separates two list items.
A separator coming after the final list item does not separate
two items, and therefore traditionally was considered a syntax
error.
\par
Proper separation is often inconvenient,
or even counter-productive.
Increasingly, the
practice is to be "liberal"
and to allow a separator to come after the last list
item.
Liberal separation is the default in Marpa.
\par
There is not bitfield for this, because proper separation is
a completely syntactic matter,
taken care of in the rewrite itself.
@<Public defines@> =
#define MARPA_PROPER_SEPARATION @| @[0x2@]@/

@*0 Accessible Rules.
@ A rule is accessible if its LHS is accessible.
@<Function definitions@> =
static inline gint rule_is_accessible(struct marpa_g* g, RULE  rule)
{
Marpa_Symbol_ID lhs_id = LHS_ID_of_PRD(rule);
 return SYM_by_ID(g, lhs_id)->t_is_accessible; }
gint marpa_rule_is_accessible(struct marpa_g* g, Marpa_Rule_ID rule_id)
{
    @<Return |-2| on failure@>@;
RULE  rule;
    @<Fail if grammar |rule_id| is invalid@>@;
rule = RULE_by_ID(g, rule_id);
return rule_is_accessible(g, rule);
}
@ @<Private function prototypes@> =
static inline gint rule_is_accessible(struct marpa_g* g, RULE  rule);
@ @<Public function prototypes@> =
gint marpa_rule_is_accessible(struct marpa_g* g, Marpa_Rule_ID id);

@*0 Productive Rules.
@ A rule is productive if every symbol on its RHS is productive.
@<Function definitions@> =
static inline gint rule_is_productive(struct marpa_g* g, RULE  rule)
{
guint rh_ix;
for (rh_ix = 0; rh_ix < rule->t_length; rh_ix++) {
   Marpa_Symbol_ID rhs_id = rhs_symid(rule, rh_ix);
   if ( !SYM_by_ID(g, rhs_id)->t_is_productive ) return FALSE;
}
return TRUE; }
gint marpa_rule_is_productive(struct marpa_g* g, Marpa_Rule_ID rule_id)
{
    @<Return |-2| on failure@>@;
RULE  rule;
    @<Fail if grammar |rule_id| is invalid@>@;
rule = RULE_by_ID(g, rule_id);
return rule_is_productive(g, rule);
}
@ @<Private function prototypes@> =
static inline gint rule_is_productive(struct marpa_g* g, RULE  rule);
@ @<Public function prototypes@> =
gint marpa_rule_is_productive(struct marpa_g* g, Marpa_Rule_ID id);

@*0 Loop Rule.
@ A rule is a loop rule if it non-trivially
produces the string of length one
which consists only of its LHS symbol.
"Non-trivially" means the zero-step derivation does not count -- the
derivation must have at least one step.
@<Bit aligned rule elements@> = unsigned int t_is_loop:1;
@ @<Initialize rule elements@> =
rule->t_is_loop = FALSE;
@ This is the external accessor.
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gint marpa_rule_is_loop(struct marpa_g* g, Marpa_Rule_ID rule_id)
{
    @<Return |-2| on failure@>@;
    @<Fail if grammar |rule_id| is invalid@>@;
return RULE_by_ID(g, rule_id)->t_is_loop; }
@ @<Public function prototypes@> =
gint marpa_rule_is_loop(struct marpa_g* g, Marpa_Rule_ID rule_id);

@*0 Virtual Loop Rule.
@ When dealing with rules which result from the CHAF rewrite,
it is convenient to recognize the "loop rule" property as belonging
to only one of the pieces.
The "virtual loop rule" property exists for this purpose.
All virtual loop rules are loop rules,
but not vice versa.
@<Bit aligned rule elements@> = unsigned int t_is_virtual_loop:1;
@ @<Initialize rule elements@> =
rule->t_is_virtual_loop = FALSE;
@ This is the external accessor.
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gint marpa_rule_is_virtual_loop(struct marpa_g* g, Marpa_Rule_ID rule_id)
{
    @<Return |-2| on failure@>@;
    @<Fail if grammar |rule_id| is invalid@>@;
return RULE_by_ID(g, rule_id)->t_is_virtual_loop; }
@ @<Public function prototypes@> =
gint marpa_rule_is_virtual_loop(struct marpa_g* g, Marpa_Rule_ID rule_id);

@*0 Nulling Rules.
@ A rule is nulling if every symbol on its RHS is nulling.
Note that this can be vacuously true --- an empty rule is nulling.
@<Function definitions@> =
static inline gint rule_is_nulling(struct marpa_g* g, RULE  rule)
{
guint rh_ix;
for (rh_ix = 0; rh_ix < rule->t_length; rh_ix++) {
   Marpa_Symbol_ID rhs_id = rhs_symid(rule, rh_ix);
   if ( !SYM_by_ID(g, rhs_id)->t_is_nulling ) return FALSE;
}
return TRUE; }
@ @<Private function prototypes@> =
static inline gint rule_is_nulling(struct marpa_g* g, RULE  rule);

@*0 Is Rule Used?.
@<Bit aligned rule elements@> = unsigned int t_is_used:1;
@ @<Initialize rule elements@> =
rule->t_is_used = TRUE;
@ This is the external accessor.
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gint marpa_rule_is_used(struct marpa_g* g, Marpa_Rule_ID rule_id)
{
    @<Return |-2| on failure@>@;
    @<Fail if grammar |rule_id| is invalid@>@;
return RULE_by_ID(g, rule_id)->t_is_used; }
@ @<Public function prototypes@> =
gint marpa_rule_is_used(struct marpa_g* g, Marpa_Rule_ID rule_id);

@*0 Is This a Start Rule?.
@d RULE_is_Start(rule) ((rule)->t_is_start)
@<Bit aligned rule elements@> = unsigned int t_is_start:1;
@ @<Initialize rule elements@> =
rule->t_is_start = FALSE;
@ This is the external accessor.
The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gint marpa_rule_is_start(struct marpa_g* g, Marpa_Rule_ID rule_id)
{
    @<Return |-2| on failure@>@;
    @<Fail if grammar |rule_id| is invalid@>@;
return RULE_by_ID(g, rule_id)->t_is_start; }
@ @<Public function prototypes@> =
gint marpa_rule_is_start(struct marpa_g* g, Marpa_Rule_ID rule_id);

@*0 Rule Boolean: Virtual LHS.
This is for Marpa's "internal semantics".
When Marpa rewrites rules, it does so in a way invisible to
the user's semantics.
It does this by marking rules so that it can reassemble
the results of rewritten rules to appear "as if"
they were the result of evaluating the original,
un-rewritten rule.
\par
All Marpa's rewrites allow the rewritten rules to be
"dummied up" to look like the originals.
That this must be possible for any rewrite was one of
Marpa's design criteria.
It was an especially non-negotiable criteria, because
almost the only reason for parsing a grammar is to apply the
semantics specified for the original grammar.
@<Bit aligned rule elements@> = unsigned int t_is_virtual_lhs:1;
@ @<Initialize rule elements@> =
rule->t_is_virtual_lhs = FALSE;
@ The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gboolean marpa_rule_is_virtual_lhs(struct marpa_g* g, Marpa_Rule_ID id)
{ return RULE_by_ID(g, id)->t_is_virtual_lhs; }
@ @<Public function prototypes@> =
gboolean marpa_rule_is_virtual_lhs(struct marpa_g* g, Marpa_Rule_ID id);

@*0 Rule Boolean: Virtual RHS.
@<Bit aligned rule elements@> = unsigned int t_is_virtual_rhs:1;
@ @<Initialize rule elements@> =
rule->t_is_virtual_rhs = FALSE;
@ The internal accessor would be trivial, so there is none.
@<Function definitions@> =
gboolean marpa_rule_is_virtual_rhs(struct marpa_g* g, Marpa_Rule_ID id)
{ return RULE_by_ID(g, id)->t_is_virtual_rhs; }
@ @<Public function prototypes@> =
gboolean marpa_rule_is_virtual_rhs(struct marpa_g* g, Marpa_Rule_ID id);

@*0 Virtual Start Position.
For a virtual rule,
this is the RHS position in the original rule
where this one starts.
@<Int aligned rule elements@> = gint t_virtual_start;
@ @<Initialize rule elements@> = rule->t_virtual_start = -1;
@ @<Function definitions@> =
guint marpa_virtual_start(struct marpa_g *g, Marpa_Rule_ID rule_id)
{
@<Return |-2| on failure@>@;
@<Fail if grammar |rule_id| is invalid@>@;
return RULE_by_ID(g, rule_id)->t_virtual_start;
}
@ @<Public function prototypes@> =
guint marpa_virtual_start(struct marpa_g *g, Marpa_Rule_ID rule_id);

@*0 Virtual End Position.
For a virtual rule,
this is the RHS position in the original rule
at which this one ends.
@<Int aligned rule elements@> = gint t_virtual_end;
@ @<Initialize rule elements@> = rule->t_virtual_end = -1;
@ @<Function definitions@> =
guint marpa_virtual_end(struct marpa_g *g, Marpa_Rule_ID rule_id)
{
@<Return |-2| on failure@>@;
@<Fail if grammar |rule_id| is invalid@>@;
return RULE_by_ID(g, rule_id)->t_virtual_end;
}
@ @<Public function prototypes@> =
guint marpa_virtual_end(struct marpa_g *g, Marpa_Rule_ID rule_id);


@*0 Rule Callbacks.
The user can define a callback
(with argument) which is invoked whenever a rule
is created.
@ Function pointer declarations are
hard to type and impossible to read.
This typedef localizes the damage.
@<Callback typedefs@> =
typedef void (Marpa_Rule_Callback)(struct marpa_g *g, Marpa_Rule_ID id);
@ @<Widely aligned grammar elements@> =
    Marpa_Rule_Callback* t_rule_callback;
    gpointer t_rule_callback_arg;
@ @<Initialize grammar elements@> =
g->t_rule_callback_arg = NULL;
g->t_rule_callback = NULL;
@ @<Function definitions@> =
void marpa_rule_callback_set(struct marpa_g *g, Marpa_Rule_Callback*cb)
{ g->t_rule_callback = cb; }
@ @<Public function prototypes@> =
void marpa_rule_callback_set(struct marpa_g *g, Marpa_Rule_Callback*cb);
@ @<Function definitions@> =
void marpa_rule_callback_arg_set(struct marpa_g *g, gpointer cb_arg)
{ g->t_rule_callback_arg = cb_arg; }
@ @<Public function prototypes@> =
void marpa_rule_callback_arg_set(struct marpa_g *g, gpointer cb_arg);
@ @<Function definitions@> =
gpointer marpa_rule_callback_arg(struct marpa_g *g)
{ return g->t_rule_callback_arg; }
@ @<Public function prototypes@> =
gpointer marpa_rule_callback_arg(struct marpa_g *g);
@ Do the rule callback.
@^To Do@>  To Do: Deal with the possibility of leaking memory if the callback
never returns, but the grammar is destroyed.
@<Function definitions@> =
static inline void rule_callback(struct marpa_g *g, Marpa_Rule_ID id)
{ Marpa_Rule_Callback* cb = g->t_rule_callback;
if (cb) { (*cb)(g, id); } }
@ @<Private function prototypes@> =
static inline void rule_callback(struct marpa_g *g, Marpa_Rule_ID id);

@*0 Rule Original.
In many cases, Marpa will rewrite a rule.
If this rule is the result of a rewriting, this element contains
the ID of the original rule.
@ @<Int aligned rule elements@> = Marpa_Rule_ID t_original;
@ @<Initialize rule elements@> = rule->t_original = -1;
@ @<Function definitions@> =
Marpa_Rule_ID marpa_rule_original(const struct marpa_g *g, Marpa_Rule_ID id)
{ return RULE_by_ID(g, id)->t_original; }
@ @<Public function prototypes@> =
Marpa_Rule_ID marpa_rule_original(const struct marpa_g *g, Marpa_Rule_ID id);

@*0 Rule Real Symbol Count.
This is another data element used for the "internal semantics" --
the logic to reassemble results of rewritten rules so that they
look as if they came from the original, un-rewritten rules.
The value of this field is meaningful if and only if
the rule has a virtual rhs or a virtual lhs.
@ @<Int aligned rule elements@> = guint t_real_symbol_count;
@ @<Initialize rule elements@> = rule->t_real_symbol_count = 0;
@ @<Function definitions@> =
guint marpa_real_symbol_count(const struct marpa_g *g, Marpa_Rule_ID id)
{ return RULE_by_ID(g, id)->t_real_symbol_count; }
@ @<Public function prototypes@> =
guint marpa_real_symbol_count(const struct marpa_g *g, Marpa_Rule_ID id);

@*0 Semantic Equivalents.
@<Bit aligned rule elements@> = unsigned int t_is_semantic_equivalent:1;
@ @<Initialize rule elements@> =
rule->t_is_semantic_equivalent = FALSE;
@ Semantic equivalence arises out of Marpa's rewritings.
When a rule is rewritten,
some (but not all!) of the resulting rules have the
same semantics as the original rule.
It is this "original rule" that |semantic_equivalent()| returns.

If this rule is the semantic equivalent of another rule,
this external accessor returns the "original rule".
Otherwise it returns -1.
@<Function definitions@> =
Marpa_Rule_ID marpa_rule_semantic_equivalent(struct marpa_g* g, Marpa_Rule_ID id)
{
RULE  rewrite_rule = RULE_by_ID(g, id);
return rewrite_rule->t_is_semantic_equivalent ? rewrite_rule->t_original : -1; }
@ @<Public function prototypes@> =
Marpa_Rule_ID marpa_rule_semantic_equivalent(struct marpa_g* g, Marpa_Rule_ID id);

@** Precomputing the Grammar.
Marpa's logic divides roughly into three pieces -- grammar precomputation,
the actual parsing of input tokens,
and semantic evaluation.
Precomputing the grammar is complex enought to divide into several
stages of its own, which are 
covered in the next few
sections.
This section describes the top-level method for precomputation,
which is external.

@<Function definitions@> =
struct marpa_g* marpa_precompute(struct marpa_g* g)
{
     if (!census(g)) return NULL;
     if (!CHAF_rewrite(g)) return NULL;
     if (!g_augment(g)) return NULL;
    loop_detect(g);
    create_AHFA_items(g);
    create_AHFA_states(g);
    @<Populate the Terminal Boolean Vector@>@;
     return g;
}
@ @<Public function prototypes@> =
struct marpa_g* marpa_precompute(struct marpa_g* g);

@** The Grammar Census.

@*0 Implementation: Inacessible and Unproductive Rules.
The textbooks say that,
in order to automatically {\bf eliminate} inaccessible and unproductive
productions from a grammar, you have to first eliminate the
unproductive productions, {\bf then} the inaccessible ones.

In practice, this advice does not seem very helpful.
Imagine the (quite possible) case
of an unproductive start symbol.
Following the
correct procedure for automatically cleaning the grammar, I would
have to regard the start symbol and its productions as eliminated
and therefore go on to report every other production and symbol as
inaccessible.  Almost certainly all these inaccessiblity reports,
while theoretically correct, would be irrelevant.
What the user probably wants to
is to make the start symbol productive.

In |libmarpa|,
inaccessibility is determined based on the assumption that
unproductive symbols will be make productive somehow,
and not eliminated.
The downside of this choice is that, in a few uncommon cases,
a user relying entirely
on the Marpa::XS warnings to clean up his grammar will have to go through
more than a single pass of the diagnostics.
(As of this writing, I personally have yet to encounter such a case.)
The upside is that in the more frequent cases, the user is spared
a lot of useless diagnostics.

@<Function definitions@> =
static struct marpa_g* census(struct marpa_g* g)
{
    @<Return |NULL| on failure@>@;
    @<Declare census variables@>@;
    @<Return |NULL| if  empty grammar@>@;
    @<Return |NULL| if already precomputed@>@;
    @<Return |NULL| if bad start symbol@>@;
    @<Census LHS symbols@>@;
    @<Census terminals@>@;
    if (have_marked_terminals) {
	@<Fatal if LHS terminal when not allowed@>@;
    } else {
	@<Fatal if empty rule and unmarked terminals@>;
	if (g->t_is_lhs_terminal_ok) {
	    @<Mark all symbols terminal@>@;
	} else {
	    @<Mark non-LHS symbols terminal@>@;
	}
    }
    @<Census nullable symbols@>@;
    @<Census productive symbols@>@;
    @<Check that start symbol is productive@>@;
    @<Calculate reach matrix@>@;
    @<Census accessible symbols@>@;
    @<Census nulling symbols@>@;
    @<Free Boolean vectors@>@;
    @<Free Boolean matrixes@>@;
    g->t_is_precomputed = TRUE;
    return g;
}
@ @<Private function prototypes@> =
static struct marpa_g* census(struct marpa_g* g);
@ @<Declare census variables@> =
guint pre_rewrite_rule_count = g->t_rules->len;
guint pre_rewrite_symbol_count = g->t_symbols->len;

@ @<Return |NULL| if empty grammar@> =
if (g->t_rules->len <= 0) { g->t_error = "no rules"; return NULL; }
@ The upper layers have a lot of latitude with this one.
There's no harm done, so the upper layers can simply ignore this one.
On the other hand, the upper layer may see this as a sign of a major
logic error, and treat it as a fatal error.
Anything in between these two extremes is also possible.
@<Return |NULL| if already precomputed@> =
if (G_is_Precomputed(g)) { g->t_error = "precomputed"; return NULL; }
@ Loop over the rules, producing bit vector of LHS symbols, and of
symbols which are the LHS of empty rules.
While at it, set a flag to indicate if there are empty rules.

@ @<Return |NULL| if bad start symbol@> =
if (original_start_symid < 0) {
    g_context_clear(g);
    g->t_error = "no start symbol";
    return failure_indicator;
}
if (!symbol_is_valid(g, original_start_symid)) {
    g_context_clear(g);
    g_context_int_add(g, "symid", original_start_symid);
    g->t_error = "invalid start symbol";
    return failure_indicator;
}
original_start_symbol = SYM_by_ID(g, original_start_symid);
if (original_start_symbol->t_lhs->len <= 0) {
    g_context_clear(g);
    g_context_int_add(g, "symid", original_start_symid);
    g->t_error = "start symbol not on LHS";
    return failure_indicator;
}

@ @<Declare census variables@> =
Marpa_Symbol_ID original_start_symid = g->t_start_symid;
SYM original_start_symbol;

@ @<Census LHS symbols@> =
{ Marpa_Rule_ID rule_id;
lhs_v = bv_create(pre_rewrite_symbol_count);
empty_lhs_v = bv_shadow(lhs_v);
for (rule_id = 0;
	rule_id < (Marpa_Rule_ID)pre_rewrite_rule_count;
	rule_id++) {
    RULE  rule = RULE_by_ID(g, rule_id);
    Marpa_Symbol_ID lhs_id = LHS_ID_of_PRD(rule);
    bv_bit_set(lhs_v, (guint)lhs_id);
    if (rule->t_length <= 0) {
	bv_bit_set(empty_lhs_v, (guint)lhs_id);
	have_empty_rule = 1;
    }
}
}
@ Loop over the symbols, producing the boolean vector of symbols
already marked as terminal,
and a flag which indicates if there are any.
@<Census terminals@> =
{ Marpa_Symbol_ID symid;
terminal_v = bv_create(pre_rewrite_symbol_count);
for (symid = 0;
	symid < (Marpa_Symbol_ID)pre_rewrite_symbol_count;
	symid++) {
    SYM symbol = SYM_by_ID(g, symid);
    if (SYM_is_Terminal(symbol)) {
	bv_bit_set(terminal_v, (guint)symid);
	have_marked_terminals = 1;
    }
} }
@ @<Free Boolean vectors@> =
bv_free(terminal_v);
@
@s Bit_Vector int
@<Declare census variables@> =
Bit_Vector terminal_v;
gboolean have_marked_terminals = 0;

@ @<Fatal if empty rule and unmarked terminals@> =
if (have_empty_rule && g->t_is_lhs_terminal_ok) {
     g->t_error = "empty rule and unmarked terminals";
    return NULL;
}
@ Any optimization should be for the non-error case, in which
there are no LHS terminals, and the entire list of symbols must
be scanned to discover this.
It is faster to stop scanning symbols on the first error, if there is
an error, but when that happens it is a fatal error,
and for that, this code is already plenty fast enough.
@<Fatal if LHS terminal when not allowed@> = 
if (!g->t_is_lhs_terminal_ok) {
    gboolean have_bad_lhs = 0;
    guint start = 0;
    guint min, max;
    Bit_Vector bad_lhs_v = bv_clone(terminal_v);
    bv_and(bad_lhs_v, bad_lhs_v, lhs_v);
    while ( bv_scan(bad_lhs_v, start, &min, &max) ) {
	Marpa_Symbol_ID i;
	for (i = (Marpa_Symbol_ID)min; i <= (Marpa_Symbol_ID)max; i++) {
	    g_context_clear(g);
	    g_context_int_add(g, "symid", i);
	    grammar_message(g, "lhs is terminal");
	}
        start = max+2;
	have_bad_lhs = 1;
    }
    bv_free(bad_lhs_v);
    if (have_bad_lhs) {
        g->t_error = "lhs is terminal";
	return NULL;
    }
}

@ @<Mark all symbols terminal@> =
{ Marpa_Symbol_ID symid;
bv_fill(terminal_v);
for (symid = 0; symid < (Marpa_Symbol_ID)g->t_symbols->len; symid++)
{ LV_SYMID_is_Terminal(g, symid) = 1; } }
@ @<Mark non-LHS symbols terminal@> = 
{ guint start = 0;
guint min, max;
bv_not(terminal_v, lhs_v);
while ( bv_scan(terminal_v, start, &min, &max) ) {
    Marpa_Symbol_ID symid;
    for (symid = (Marpa_Symbol_ID)min; symid <= (Marpa_Symbol_ID)max; symid++) {
     LV_SYMID_is_Terminal(g, symid) = 1;
    }
    start = max+2;
}
}
@ @<Free Boolean vectors@> =
bv_free(lhs_v);
bv_free(empty_lhs_v);
@ @<Declare census variables@> =
Bit_Vector lhs_v;
Bit_Vector empty_lhs_v;
gboolean have_empty_rule = 0;

@ @<Census nullable symbols@> = 
nullable_v = bv_clone(empty_lhs_v);
rhs_closure(g, nullable_v);
{ guint min, max, start;
Marpa_Symbol_ID symid;
gint counted_nullables = 0;
    for ( start = 0; bv_scan(nullable_v, start, &min, &max); start = max+2 ) {
	for (symid = (Marpa_Symbol_ID)min; symid <= (Marpa_Symbol_ID)max; symid++) {
	    SYM symbol = SYM_by_ID(g, symid);
	    if (symbol->t_is_counted) {
		g_context_clear(g);
		g_context_int_add(g, "symid", symid);
		grammar_message(g, "counted nullable");
		counted_nullables++;
	    }
	    symbol->t_is_nullable = 1;
} }
if (counted_nullables) {
    g->t_error = "counted nullable";
    return NULL;
}
}
@ @<Declare census variables@> =
Bit_Vector nullable_v;
@ @<Free Boolean vectors@> =
bv_free(nullable_v);

@ @<Census productive symbols@> = 
productive_v = bv_shadow(nullable_v);
bv_or(productive_v, nullable_v, terminal_v);
rhs_closure(g, productive_v);
{ guint min, max, start;
Marpa_Symbol_ID symid;
    for ( start = 0; bv_scan(productive_v, start, &min, &max); start = max+2 ) {
	for (symid = (Marpa_Symbol_ID)min;
		symid <= (Marpa_Symbol_ID)max;
		symid++) {
	    SYM symbol = SYM_by_ID(g, symid);
	    symbol->t_is_productive = 1;
} }
}
@ @<Check that start symbol is productive@> =
if (!bv_bit_test(productive_v, (guint)g->t_start_symid))
{
    g_context_int_add(g, "symid", g->t_start_symid);
    g->t_error = "unproductive start symbol";
    return NULL;
}
@ @<Declare census variables@> =
Bit_Vector productive_v;
@ @<Free Boolean vectors@> =
bv_free(productive_v);

@ The reach matrix is the an $n\times n$ matrix,
where $n$ is the number of symbols.
Bit $(i,j)$ is set in the reach matrix if and only if
symbol $i$ can reach symbol $j$.
\par
This logic could be put earlier, and a child array
for each rule could be efficiently calculated during
the initialization for the calculation of the reach
matrix.
A rule-child array is a list of the rule's RHS symbols,
in sequence and without duplicates.
There are places were traversing a rule-child array,
instead of the rhs, would be more efficient.
At this point,
however, it is not clear whether use of a rule-child array
is not a pointless or even counter-productive optimization.
It would only make a difference in grammars
where many of the right hand sides repeat symbols.
@<Calculate reach matrix@> =
reach_matrix
    = matrix_create(pre_rewrite_symbol_count, pre_rewrite_symbol_count);
{ guint symid, no_of_symbols = SYM_Count_of_G(g);
for (symid = 0; symid < no_of_symbols; symid++) {
     matrix_bit_set(reach_matrix, symid, symid);
} }
{ Marpa_Rule_ID rule_id;
guint no_of_rules = rule_count(g);
for (rule_id = 0; rule_id < (Marpa_Rule_ID)no_of_rules; rule_id++) {
     RULE  rule = RULE_by_ID(g, rule_id);
     Marpa_Symbol_ID lhs_id = LHS_ID_of_PRD(rule);
     guint rhs_ix, rule_length = rule->t_length;
     for (rhs_ix = 0; rhs_ix < rule_length; rhs_ix++) {
	 matrix_bit_set(reach_matrix,
	     (guint)lhs_id, (guint)rhs_symid(rule, rhs_ix));
} } }
transitive_closure(reach_matrix);
@ @<Declare census variables@> = Bit_Matrix reach_matrix;
@ @<Free Boolean matrixes@> =
matrix_free(reach_matrix);

@ @<Census accessible symbols@> = 
accessible_v = matrix_row(reach_matrix, (guint)original_start_symid);
{ guint min, max, start;
Marpa_Symbol_ID symid;
    for ( start = 0; bv_scan(accessible_v, start, &min, &max); start = max+2 ) {
	for (symid = (Marpa_Symbol_ID)min;
		symid <= (Marpa_Symbol_ID)max;
		symid++) {
	    SYM symbol = SYM_by_ID(g, symid);
	    symbol->t_is_accessible = 1;
} }
}
@ |accessible_v| is a pointer into the |reach_matrix|.
Therefore there is no code to free it.
@<Declare census variables@> =
Bit_Vector accessible_v;

@ A symbol is nulling if and only if it is a productive symbol which does not
reach a terminal symbol.
@<Census nulling symbols@> = 
{
  Bit_Vector reaches_terminal_v = bv_shadow (terminal_v);
  guint min, max, start;
  for (start = 0; bv_scan (productive_v, start, &min, &max); start = max + 2)
    {
      Marpa_Symbol_ID productive_id;
      for (productive_id = (Marpa_Symbol_ID) min;
	   productive_id <= (Marpa_Symbol_ID) max; productive_id++)
	{
	  bv_and (reaches_terminal_v, terminal_v,
		  matrix_row (reach_matrix, (guint) productive_id));
	  if (bv_is_empty (reaches_terminal_v))
	    SYM_by_ID (g, productive_id)->t_is_nulling = 1;
	}
    }
  bv_free (reaches_terminal_v);
}

@** The CHAF Rewrite.

Nullable symbols have been a difficulty for Earley implementations
since day zero.
Aycock and Horspool came up with a solution to this problem,
part of which involved rewriting the grammar to eliminate
all proper nullables.
Marpa's CHAF rewrite is built on the work of Aycock and
Horspool.

Marpa's CHAF rewrite is one of its two rewrites of the BNF.
The other
adds a new start symbol to the grammar.

@ The rewrite strategy for Marpa is new to it.
It is an elaboration on the one developed by Aycock and Horspool.
The basic idea behind Aycock and Horspool's NNF was to elimnate
proper nullables by replacing the rules with variants which
used only nulling and non-nulling symbols.
These had to be created for every possible combination
of nulling and non-nulling symbols.
This meant that the number of NNF rules was
potentially exponential
in the length of rule of the original grammar.

@ Marpa's CHAF (Chomsky-Horspool-Aycock Form) eliminates
the problem of exponential explosion by first breaking rules
up into pieces, each piece containing no more than two proper nullables.
The number of rewritten rules in CHAF in linear in the length of
the original rule.

@ The CHAF rewrite affects only rules with proper nullables.
In this context, the proper nullables are called "factors".
Each piece of the original rule is rewritten into up to four
"factored pieces".
When there are two proper nullables, the potential CHAF rules
are
\li The PP rule:  Both factors are replaced with non-nulling symbols.
\li The PN rule:  The first factor is replaced with a non-nulling symbol,
and the second factor is replaced with a nulling symbol.
\li The NP rule: The first factor is replaced with a nulling symbol,
and the second factor is replaced with a non-nulling symbol.
\li The NN rule: Both factors are replaced with nulling symbols.

@ Sometimes the CHAF piece will have only one factor.  A one-factor
piece is rewritten into at most two factored pieces:
\li The P rule:  The factor is replaced with a non-nulling symbol.
\li The N rule:  The factor is replaced with a nulling symbol.

@ In |CHAF_rewrite|, a |rule_count| is taken before the loop over
the grammar's rules, even though rules are added in the loop.
This is not an error.
The CHAF rewrite is not recursive -- the new rules it creates
are not themselves subject to CHAF rewrite.
And rule ID's increase by one each time,
so that all the new
rules will have ID's equal to or greater than |no_of_rules|.
@ @<Function definitions@> =
static inline struct marpa_g* CHAF_rewrite(struct marpa_g* g)
{
    @<CHAF rewrite declarations@>@;
    @<CHAF rewrite allocations@>@;
     @<Alias proper nullables@>@;
    no_of_rules = rule_count(g);
    for (rule_id = 0; rule_id < no_of_rules; rule_id++) {
         RULE  rule = RULE_by_ID(g, rule_id);
	 guint rule_length = rule->t_length;
	 guint nullable_suffix_ix = 0;
	 @<Mark and skip unused rules@>@;
	 @<Calculate CHAF rule statistics@>@;
	 /* If there is no proper nullable in this rule, I am done */
	 if (factor_count <= 0) goto NEXT_RULE;
	 @<Factor the rule into CHAF rules@>@;
	 NEXT_RULE: ;
    }
    @<CHAF rewrite deallocations@>@;
    return g;
}
@ @<Private function prototypes@> =
static inline struct marpa_g* CHAF_rewrite(struct marpa_g* g);
@ @<CHAF rewrite declarations@> =
Marpa_Rule_ID rule_id;
gint no_of_rules;

@ @<Mark and skip unused rules@> =
if (!rule->t_is_used) { goto NEXT_RULE; }
if (rule_is_nulling(g, rule)) { rule->t_is_used = 0; goto NEXT_RULE; }
if (!rule_is_accessible(g, rule)) { rule->t_is_used = 0; goto NEXT_RULE; }
if (!rule_is_productive(g, rule)) { rule->t_is_used = 0; goto NEXT_RULE; }

@ For every accessible and productive proper nullable which
is not already aliased, alias it.
@<Alias proper nullables@> =
{ gint no_of_symbols = SYM_Count_of_G(g);
Marpa_Symbol_ID symid;
for (symid = 0; symid < no_of_symbols; symid++) {
     SYM symbol = SYM_by_ID(g, symid);
     SYM alias;
     if (!symbol->t_is_nullable) continue;
     if (symbol->t_is_nulling) continue;
     if (!symbol->t_is_accessible) continue;
     if (!symbol->t_is_productive) continue;
     if (symbol_null_alias(symbol)) continue;
    alias = symbol_alias_create(g, symbol);
    symbol_callback(g, alias->t_id);
} }

@*0 Compute Statistics Needed to Rewrite the Rule.
The term
"factor" is used to mean an instance of a proper nullable
symbol on the RHS of a rule.
This comes from the idea that replacing the proper nullables
with proper symbols and nulling symbols "factors" pieces
of the rule being rewritten (the original rule)
into multiple CHAF rules.
@<Calculate CHAF rule statistics@> =
{ guint rhs_ix;
factor_count = 0;
for (rhs_ix = 0; rhs_ix < rule_length; rhs_ix++) {
     Marpa_Symbol_ID symid = rhs_symid(rule, rhs_ix);
     SYM symbol = SYM_by_ID(g, symid);
     if (symbol->t_is_nulling) continue; /* Do nothing for nulling symbols */
     if (symbol_null_alias(symbol)) {
     /* If a proper nullable, record its position */
	 factor_positions[factor_count++] = rhs_ix;
	 continue;
    }@#
     nullable_suffix_ix = rhs_ix+1;
/* If not a nullable symbol, move forward the index
 of the nullable suffix location */
} }
@ @<CHAF rewrite declarations@> =
guint factor_count;
guint* factor_positions;
@ @<CHAF rewrite allocations@> =
factor_positions = g_new(guint, g->t_max_rule_length);
@ @<CHAF rewrite deallocations@> =
g_free(factor_positions);

@*0 Divide the Rule into Pieces.
@<Factor the rule into CHAF rules@> =
rule->t_is_used = 0; /* Mark the original rule unused */
{ guint unprocessed_factor_count; /* The number of proper nullables for which CHAF rules have
yet to be written */
guint factor_position_ix = 0; /* Current index into the list of factors */
Marpa_Symbol_ID current_lhs_id = LHS_ID_of_PRD(rule);
guint piece_end, piece_start = 0; /* The positions, in the original rule, where
the new (virtual) rule starts and ends */
for (unprocessed_factor_count = factor_count - factor_position_ix;
unprocessed_factor_count >= 3;
unprocessed_factor_count = factor_count - factor_position_ix) {
    @<Add non-final CHAF rules@>@;
}
if (unprocessed_factor_count == 2) {
	@<Add final CHAF rules for two factors@>@;
} else {
	@<Add final CHAF rules for one factor@>@;
} }

@ @<Create a CHAF virtual symbol@> = {
    SYM chaf_virtual_symbol = symbol_new(g);
    chaf_virtual_symbol->t_is_accessible = 1;
    chaf_virtual_symbol->t_is_productive = 1;
    chaf_virtual_symid = chaf_virtual_symbol->t_id;
    g_context_clear(g);
    g_context_int_add(g, "rule_id", rule_id);
    g_context_int_add(g, "lhs_id", LHS_ID_of_PRD(rule));
    g_context_int_add(g, "virtual_end", (gint)piece_end);
    symbol_callback(g, chaf_virtual_symid);
}

@*0 Temporary buffers for the CHAF right hand sides.
Two temporary buffers are used in factoring out CHAF rules.
|piece_rhs| is for the normal case, where only the symbols
of the current piece are on the RHS.
In certain cases, where the remainder of the rule is nulling,
further factoring is unnecessary and the CHAF rewrite simply
finishes out the rule with nulling symbols.
In such cases, the RHS is built in the
|remaining_rhs| buffer.
@<CHAF rewrite declarations@> =
Marpa_Symbol_ID* piece_rhs;
Marpa_Symbol_ID* remaining_rhs;
@ @<CHAF rewrite allocations@> =
piece_rhs = g_new(Marpa_Symbol_ID, g->t_max_rule_length);
remaining_rhs = g_new(Marpa_Symbol_ID, g->t_max_rule_length);
@ @<CHAF rewrite deallocations@> =
g_free(piece_rhs);
g_free(remaining_rhs);

@*0 Factor A Non-Final Piece.
@ As long as I have more than 3 unprocessed factors, I am working on a non-final
rule.
@<Add non-final CHAF rules@> =
    Marpa_Symbol_ID chaf_virtual_symid;
    guint first_factor_position = factor_positions[factor_position_ix];
    guint first_factor_piece_position = first_factor_position - piece_start;
    guint second_factor_position = factor_positions[factor_position_ix+1];
    if (second_factor_position >= nullable_suffix_ix) {
	piece_end = second_factor_position-1;
        /* The last factor is in the nullable suffix, so the virtual RHS must be nullable */
	@<Create a CHAF virtual symbol@>@;
	@<Add CHAF rules for nullable continuation@>@;
	factor_position_ix++;
    } else {
	gint second_factor_piece_position = second_factor_position - piece_start;
	piece_end = second_factor_position;
	@<Create a CHAF virtual symbol@>@;
	@<Add CHAF rules for proper continuation@>@;
	factor_position_ix += 2;
    }
    current_lhs_id = chaf_virtual_symid;
    piece_start = piece_end+1;

@*0 Add CHAF Rules for Nullable Continuations.
For a piece that has a nullable continuation,
the virtual RHS counts
as one of the two allowed proper nullables.
That means the piece must
end before the second proper nullable (or factor).
@<Add CHAF rules for nullable continuation@> =
{
    guint remaining_rhs_length, piece_rhs_length;
    @<Add PP CHAF rule for nullable continuation@>;
    @<Add PN CHAF rule for nullable continuation@>;
    @<Add NP CHAF rule for nullable continuation@>;
    @<Add NN CHAF rule for nullable continuation@>;
}

@ Note that since the first part of |remaining_rhs| is exactly the same
as the first part of |piece_rhs| so I copy it here in preparation
for the PN rule.
@<Add PP CHAF rule for nullable continuation@> =
{
guint real_symbol_count = piece_end - piece_start + 1;
for (piece_rhs_length = 0; piece_rhs_length < real_symbol_count; piece_rhs_length++) {
   remaining_rhs[piece_rhs_length] =
   piece_rhs[piece_rhs_length] = rhs_symid(rule, piece_start+piece_rhs_length);
}
piece_rhs[piece_rhs_length++] = chaf_virtual_symid;
}
{ RULE  chaf_rule;
    guint real_symbol_count = piece_rhs_length - 1;
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;
}

@ @<Add PN CHAF rule for nullable continuation@> =
{ guint chaf_rule_length = rule->t_length - piece_start;
for (remaining_rhs_length=piece_rhs_length-1 ;
	remaining_rhs_length < chaf_rule_length;
	remaining_rhs_length++) {
    Marpa_Symbol_ID original_id = rhs_symid(rule, piece_start+remaining_rhs_length);
    SYM alias = symbol_null_alias(SYM_by_ID(g, original_id));
    remaining_rhs[remaining_rhs_length] = alias ? alias->t_id : original_id;
} }
{ RULE  chaf_rule;
    guint real_symbol_count = remaining_rhs_length;
    chaf_rule = rule_start(g, current_lhs_id, remaining_rhs, remaining_rhs_length);
    @<Set CHAF rule flags and call back@>@;
}

@ Note, while I have the nulling alias for the first factor,
|remaining_rhs| is altered to be ready for the NN rule.
@<Add NP CHAF rule for nullable continuation@> = {
    Marpa_Symbol_ID proper_id = rhs_symid(rule, first_factor_position);
    SYM alias = symbol_null_alias(SYM_by_ID(g, proper_id));
    remaining_rhs[first_factor_piece_position] =
	piece_rhs[first_factor_piece_position] =
	alias->t_id;
}
{ RULE  chaf_rule;
 guint real_symbol_count = piece_rhs_length-1;
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;
}

@ If this piece is nullable (|piece_start| at or
after |nullable_suffix_ix|), I don't add an NN choice,
because nulling both factors makes the entire piece nulling,
and nulling rules cannot be fed directly to
the Marpa parse engine.
Note that |remaining_rhs| was altered above.
@<Add NN CHAF rule for nullable continuation@> =
if (piece_start < nullable_suffix_ix) {
 RULE  chaf_rule;
 guint real_symbol_count = remaining_rhs_length;
    chaf_rule = rule_start(g, current_lhs_id, remaining_rhs, remaining_rhs_length);
    @<Set CHAF rule flags and call back@>@;
}

@*0 Add CHAF Rules for Proper Continuations.
@ Open block and declarations.
@<Add CHAF rules for proper continuation@> = {
    guint piece_rhs_length;
RULE  chaf_rule;
guint real_symbol_count;
Marpa_Symbol_ID first_factor_proper_id, second_factor_proper_id,
	first_factor_alias_id, second_factor_alias_id;
real_symbol_count = piece_end - piece_start + 1;

@ The PP Rule.
@<Add CHAF rules for proper continuation@> = 
    for (piece_rhs_length = 0; piece_rhs_length < real_symbol_count; piece_rhs_length++) {
	piece_rhs[piece_rhs_length] = rhs_symid(rule, piece_start+piece_rhs_length);
    }
    piece_rhs[piece_rhs_length++] = chaf_virtual_symid;
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;

@ The PN Rule.
@<Add CHAF rules for proper continuation@> = 
    second_factor_proper_id = rhs_symid(rule, second_factor_position);
    piece_rhs[second_factor_piece_position]
	= second_factor_alias_id = alias_by_id(g, second_factor_proper_id);
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;

@ The NP Rule.
@<Add CHAF rules for proper continuation@> = 
    first_factor_proper_id = rhs_symid(rule, first_factor_position);
    piece_rhs[first_factor_piece_position]
	= first_factor_alias_id = alias_by_id(g, first_factor_proper_id);
    piece_rhs[second_factor_piece_position] = second_factor_proper_id;
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;

@ The NN Rule.
@<Add CHAF rules for proper continuation@> = 
    piece_rhs[second_factor_piece_position] = second_factor_alias_id;
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;

@ Close the block
@<Add CHAF rules for proper continuation@> = }

@*0 Add Final CHAF Rules for Two Factors.
Open block, declarations and setup.
@<Add final CHAF rules for two factors@> = {
guint first_factor_position = factor_positions[factor_position_ix];
guint first_factor_piece_position = first_factor_position - piece_start;
guint second_factor_position = factor_positions[factor_position_ix+1];
guint second_factor_piece_position = second_factor_position - piece_start;
guint real_symbol_count;
guint piece_rhs_length;
RULE  chaf_rule;
Marpa_Symbol_ID first_factor_proper_id, second_factor_proper_id,
	first_factor_alias_id, second_factor_alias_id;
piece_end = rule->t_length-1;
real_symbol_count = piece_end - piece_start + 1;

@ The PP Rule.
@<Add final CHAF rules for two factors@> = 
    for (piece_rhs_length = 0; piece_rhs_length < real_symbol_count; piece_rhs_length++) {
	piece_rhs[piece_rhs_length] = rhs_symid(rule, piece_start+piece_rhs_length);
    }
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;

@ The PN Rule.
@<Add final CHAF rules for two factors@> =
    second_factor_proper_id = rhs_symid(rule, second_factor_position);
    piece_rhs[second_factor_piece_position]
	= second_factor_alias_id = alias_by_id(g, second_factor_proper_id);
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;

@ The NP Rule.
@<Add final CHAF rules for two factors@> =
    first_factor_proper_id = rhs_symid(rule, first_factor_position);
    piece_rhs[first_factor_piece_position]
	= first_factor_alias_id = alias_by_id(g, first_factor_proper_id);
    piece_rhs[second_factor_piece_position] = second_factor_proper_id;
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;

@ The NN Rule.  This is added only if it would not turn this into
a nulling rule.
@<Add final CHAF rules for two factors@> =
if (piece_start < nullable_suffix_ix) {
    piece_rhs[second_factor_piece_position] = second_factor_alias_id;
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;
}

@ Close the block
@<Add final CHAF rules for two factors@> = }

@*0 Add Final CHAF Rules for One Factor.
@<Add final CHAF rules for one factor@> = {
guint piece_rhs_length;
RULE  chaf_rule;
Marpa_Symbol_ID first_factor_proper_id, first_factor_alias_id;
guint real_symbol_count;
guint first_factor_position = factor_positions[factor_position_ix];
guint first_factor_piece_position = factor_positions[factor_position_ix] - piece_start;
piece_end = rule->t_length-1;
real_symbol_count = piece_end - piece_start + 1;

@ The P Rule.
@<Add final CHAF rules for one factor@> = 
    for (piece_rhs_length = 0; piece_rhs_length < real_symbol_count; piece_rhs_length++) {
	piece_rhs[piece_rhs_length] = rhs_symid(rule, piece_start+piece_rhs_length);
    }
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;

@ The N Rule.  This is added only if it would not turn this into
a nulling rule.
@<Add final CHAF rules for one factor@> =
if (piece_start < nullable_suffix_ix) {
    first_factor_proper_id = rhs_symid(rule, first_factor_position);
    first_factor_alias_id = alias_by_id(g, first_factor_proper_id);
    piece_rhs[first_factor_piece_position] = first_factor_alias_id;
    chaf_rule = rule_start(g, current_lhs_id, piece_rhs, piece_rhs_length);
    @<Set CHAF rule flags and call back@>@;
}

@ Close the block
@<Add final CHAF rules for one factor@> = }

@ Some of the code for adding CHAF rules is common to
them all.
This include the setting of many of the elements of the 
rule structure, and performing the call back.
@<Set CHAF rule flags and call back@> =
chaf_rule->t_is_used = 1;
chaf_rule->t_original = rule_id;
chaf_rule->t_is_virtual_lhs = piece_start > 0;
chaf_rule->t_is_semantic_equivalent = !chaf_rule->t_is_virtual_lhs;
chaf_rule->t_is_virtual_rhs = chaf_rule->t_length > real_symbol_count;
chaf_rule->t_virtual_start = piece_start;
chaf_rule->t_virtual_end = piece_start + real_symbol_count - 1;
chaf_rule->t_real_symbol_count = real_symbol_count;
    rule_callback(g, chaf_rule->t_id);

@ This utility routine translates a proper symbol id to a nulling symbol ID.
It is assumed that the caller has ensured that
|proper_id| is valid and that an alias actually exists.
@<Function definitions@> =
static inline
Marpa_Symbol_ID alias_by_id(struct marpa_g* g, Marpa_Symbol_ID proper_id) {
     SYM alias = symbol_null_alias(SYM_by_ID(g, proper_id));
     return alias->t_id;
}
@ @<Private function prototypes@> =
static inline
Marpa_Symbol_ID alias_by_id(struct marpa_g* g, Marpa_Symbol_ID proper_id);

@** Adding a New Start Symbol.
This is such a common rewrite that it has a special name
in the literature --- it is called "augmenting the grammar".

@ @<Function definitions@> =
static inline
struct marpa_g* g_augment(struct marpa_g* g) {
    Marpa_Symbol_ID proper_new_start_id = -1;
    SYM proper_old_start = NULL;
    SYM nulling_old_start = NULL;
    SYM proper_new_start = NULL;
    SYM old_start = SYM_by_ID(g, g->t_start_symid);
    @<Find and classify the old start symbols@>@;
    if (proper_old_start) { @<Set up a new proper start rule@> }
    if (nulling_old_start) { @<Set up a new nulling start rule@> }
    return g;
}
@ @<Private function prototypes@> =
static inline struct marpa_g* g_augment(struct marpa_g* g);

@ @<Find and classify the old start symbols@> =
if (old_start->t_is_nulling) {
   old_start->t_is_accessible = 0;
    nulling_old_start = old_start;
} else {
    proper_old_start = old_start;
    nulling_old_start = symbol_null_alias(old_start);
}
old_start->t_is_start = 0;

@ @<Set up a new proper start rule@> = {
  RULE new_start_rule;
  proper_old_start->t_is_start = 0;
  proper_new_start = symbol_new (g);
  proper_new_start_id = proper_new_start->t_id;
  g->t_start_symid = proper_new_start_id;
  proper_new_start->t_is_accessible = TRUE;
  proper_new_start->t_is_productive = TRUE;
  proper_new_start->t_is_start = TRUE;
  g_context_clear (g);
  g_context_int_add (g, "old_start_id", old_start->t_id);
  symbol_callback (g, proper_new_start_id);
  new_start_rule = rule_start (g, proper_new_start_id, &old_start->t_id, 1);
  new_start_rule->t_is_start = 1;
  new_start_rule->t_is_virtual_lhs = 1;
  new_start_rule->t_real_symbol_count = 1;
  new_start_rule->t_is_used = TRUE;
  g->t_proper_start_rule = new_start_rule;
  rule_callback (g, new_start_rule->t_id);
}

@ Set up the new nulling start rule, if the old start symbol was
nulling or had a null alias.  A new nulling start symbol
must be created.  It is an alias of the new proper start symbol,
if there is one.  Otherwise it is a new, nulling, symbol.
@<Set up a new nulling start rule@> = {
  Marpa_Symbol_ID nulling_new_start_id;
  RULE new_start_rule;
  SYM nulling_new_start;
  if (proper_new_start)
    {				/* There are two start symbols */
      nulling_new_start = symbol_alias_create (g, proper_new_start);
      nulling_new_start_id = nulling_new_start->t_id;
    }
  else
    {				/* The only start symbol is a nulling symbol */
      nulling_new_start = symbol_new (g);
      nulling_new_start_id = nulling_new_start->t_id;
      g->t_start_symid = nulling_new_start_id;
      nulling_new_start->t_is_nulling = TRUE;
      nulling_new_start->t_is_nullable = TRUE;
      nulling_new_start->t_is_productive = TRUE;
      nulling_new_start->t_is_accessible = TRUE;
    }
  nulling_new_start->t_is_start = TRUE;
  g_context_clear (g);
  g_context_int_add (g, "old_start_id", old_start->t_id);
  symbol_callback (g, nulling_new_start_id);
  new_start_rule = rule_start (g, nulling_new_start_id, 0, 0);
  new_start_rule->t_is_start = 1;
  new_start_rule->t_is_virtual_lhs = 1;
  new_start_rule->t_real_symbol_count = 1;
  new_start_rule->t_is_used = TRUE;
  g->t_null_start_rule = new_start_rule;
  rule_callback (g, new_start_rule->t_id);
}

@** Loops.
Loops are rules which non-trivially derive their own LHS.
More precisely, a rule is a loop if and only if it
non-trivially derives a string which contains its LHS symbol
and is of length 1.
In my experience,
and according to Grune and Jacobs 2008 (pp. 48-49),
loops are never of practical use.

@ Marpa allows loops, for two reasons.
First, I want to be able to claim that
Marpa handles {\bf all} context-free grammars.
This is of real value to the user, because
it makes
it very easy for her
to know beforehand whether Marpa can
handle a particular grammar.
If she can write the grammar in BNF, then Marpa can handle it ---
it's that simple.
For Marpa to make this claim,
it must be able to handle grammars
with loops.

Second, a user's drafts of a grammar might contain cycles.
A parser generator which did not handle them would force
the user's first order of business to be removing them.
That might be inconvenient.

@ The grammar precomputations and the recognition
phase have been set up so that
loops are a complete non-issue --- they are dealt with like
any other situation, without additional overhead.
However, loops do impose overhead and require special
handling in the evaluation phase.
It is unlikely that a user will want to leave one in
a production grammar.

@ Marpa detects all loops during its grammar
precomputation.
|libmarpa| assumes that parsing will go through as usual,
with the loops.
But it enables the upper layers to make other choices
by passing a message for every symbol involved in a
loop,
as well as a final message with the count of looping symbols.

@<Function definitions@> =
static inline
void loop_detect(struct marpa_g* g)
{ guint no_of_rules = rule_count(g);
gint loop_rule_count = 0;
Bit_Matrix unit_transition_matrix
    = matrix_create( no_of_rules , no_of_rules);
@<Mark direct unit transitions in |unit_transition_matrix|@>@;
transitive_closure(unit_transition_matrix);
@<Mark loop rules@>@;
if (loop_rule_count) g->t_has_loop = TRUE;
@<Report loop rule count@>@;
matrix_free(unit_transition_matrix);
}
@ @<Private function prototypes@> =
static inline
void loop_detect(struct marpa_g* g);

@ Note that direct transitions are marked in advance,
but not trivial ones.
That is, bit |(x,x)| is not set |TRUE| in advance.
In other words, for this purpose,
unit transitions are not in general reflexive.
@<Mark direct unit transitions in |unit_transition_matrix|@> = {
Marpa_Rule_ID rule_id;
for (rule_id = 0; rule_id < (Marpa_Rule_ID)no_of_rules; rule_id++) {
     RULE  rule = RULE_by_ID(g, rule_id);
     Marpa_Symbol_ID proper_id;
     guint rhs_ix, rule_length;
     if (!rule->t_is_used) continue;
     rule_length = rule->t_length;
     proper_id = -1;
     for (rhs_ix = 0; rhs_ix < rule_length; rhs_ix++) {
	 Marpa_Symbol_ID symid = rhs_symid(rule, rhs_ix);
	 SYM symbol = SYM_by_ID(g, symid);
	 if (symbol->t_is_nullable) continue; /* After the CHAF rewrite, nullable $\E$ nulling */
	 if (proper_id >= 0) goto NEXT_RULE; /* More
	     than one proper symbol -- not a unit rule */
	 proper_id = symid;
    }
    @#
    if (proper_id < 0) continue; /* A
	nulling start rule is allowed, so there may be no proper symbol */
     { SYM rhs_symbol = SYM_by_ID(g, proper_id);
     GArray* lhs_rules = rhs_symbol->t_lhs;
     guint ix, no_of_lhs_rules = lhs_rules->len;
     for (ix = 0; ix < no_of_lhs_rules; ix++) {
	 /* Direct loops ($A \RA A$) only need the $(rule_id, rule_id)$ bit set,
	    but it is not clear that it is a win to special case them. */
	 matrix_bit_set(unit_transition_matrix, (guint)rule_id,
	     (guint)g_array_index(lhs_rules, Marpa_Rule_ID, ix));
     } }
     NEXT_RULE: ;
} }

@ Virtual loop rule are loop rules from the virtual point of view.
When CHAF rules, which are rewritten into multiple pieces,
it is inconvenient to see each piece as a loop rule.
Therefore only certain of CHAF pieces that are loop rules
are regarded as virtual loop rules.
All non-CHAF rules are virtual loop rules including,
at this point, sequence rules.
@<Mark loop rules@> = { Marpa_Rule_ID rule_id;
for (rule_id = 0; rule_id < (Marpa_Rule_ID)no_of_rules; rule_id++) {
    RULE  rule;
    if (!matrix_bit_test(unit_transition_matrix, (guint)rule_id, (guint)rule_id))
	continue;
    loop_rule_count++;
    rule = RULE_by_ID(g, rule_id);
    rule->t_is_loop = TRUE;
    rule->t_is_virtual_loop = rule->t_virtual_start < 0 || !rule->t_is_virtual_rhs;
    g_context_clear(g);
    g_context_int_add(g, "rule_id", rule_id);
    grammar_message(g, "loop rule");
} }

@ The higher layers can differ greatly in their treatment
of loop rules.  It is perfectly reasonable for a higher layer to treat a loop
rule as a fatal error.
It is also reasonable for a higher layer to always silently allow them.
There are lots of possibilities in between these two extremes.
To assist the upper layers, the reporting is very thorough ---
there is not just a message for each loop rule, but also a final tally.
@<Report loop rule count@> =
g_context_clear(g);
g_context_int_add(g, "loop_rule_count", loop_rule_count);
grammar_message(g, "loop rule tally");

@** The Aycock-Horspool Finite Automata.

@*0 Some Statistics on AHFA states.
For Perl's grammar, the discovered states range in size from 1 to 20 items,
but the numbers are heavily skewed toward the low
end.  Here are the item counts that appear, with the percent of the total
discovered AHFA states with that item count in parentheses.
in parentheses:
1   (67.05\%);
2   (25.67\%);
3   (2.87\%);
4   (2.68\%);
5   (0.19\%);
6   (0.38\%);
7   (0.19\%);
8   (0.57\%);
9   (0.19\%); and
20   (0.19\%).

@ As can be seen, well over 90\% of the total discovered states have
just one or two items.
The average size is 1.5235,
and the average of the $|size|^2$ is 3.9405.

@ For the HTML grammars I used, the totals are even more lopsided:
80.96\% of all discovered states have only 1 item.
All the others (19.04\%) have 2 items.
The average size is 1.1904,
and the average of the $|size|^2$ is 1.5712.

@ The number of predicted states tends to be much more
evenly distributed.
It also tends to be much larger, and
the average for practical grammars may be $O(s)$,
where $s$ is the size of the grammar.
This is the same as the theoretical worst case.

Here are the number of items for predicted states for the Perl grammar.
The number of states with that item count in is parentheses:
1 item (3),
2 items (5),
3 items (4),
4 items (3),
5 items (1),
6 items (2),
7 items (2),
64 items (1),
71 items (1),
77 items (1),
79 items (1),
81 items (1),
83 items (1),
85 items (1),
88 items (1),
90 items (1),
98 items (1),
100 items (1),
102 items (1),
104 items (1),
106 items (1),
108 items (1),
111 items (1),
116 items (1),
127 items (1),
129 items (1),
132 items (1),
135 items (1),
136 items (1),
137 items (1),
141 items (1),
142 items (4),
143 items (2),
144 items (1),
149 items (1),
151 items (1),
156 items (1),
157 items (1),
220 items (1),
224 items (1),
225 items (1).
And here is the same data for some grammar of HTML:
1 item (95),
2 items (95),
4 items (95),
11 items (181),
14 items (181),
15 items (294),
16 items (112),
18 items (349),
19 items (120),
20 items (190),
21 items (63),
22 items (22),
24 items (8),
25 items (16),
26 items (16),
28 items (2),
29 items (16).


@** AHFA Item (AIM) Code.
AHFA states are sets of AHFA items.
AHFA items are named by analogy with LR(0) items.
LR(0) items play the same role in the LR(0) automaton that
AHFA items play in the AHFA ---
the states of the automata correspond to sets of the items.
Also like LR(0) items,
each AHFA items correponds one-to-one to a duple,
the duple being a a rule and a position in that rule.
@<Public typedefs@> =
typedef gint Marpa_AHFA_Item_ID;
@
@d Position_of_AIM(aim) ((aim)->t_position)
@d LV_Position_of_AIM(aim) Position_of_AIM(aim)
@d Sort_Key_of_AIM(aim) ((aim)->t_sort_key)
@d LV_Sort_Key_of_AIM(aim) Sort_Key_of_AIM(aim)
@<Private structures@> =
struct s_AHFA_item {
    Marpa_AHFA_Item_ID t_sort_key;
    RULE  t_production;
    @<Int aligned AHFA item elements@>@;
    gint t_position; /* position in the RHS, -1 for a completion */
};
@ @<Private typedefs@> =
struct s_AHFA_item;
typedef struct s_AHFA_item* AIM;

@ A pointer to two lists of AHFA items.
The one list contains the AHFA items themselves, in
AHFA item ID order.
The other is indexed by rule ID, and contains a pointer to
the first AHFA item for that rule.
@<Widely aligned grammar elements@> =
   AIM t_AHFA_items;
   AIM* t_AHFA_items_by_rule;
@
@d AIM_Count_of_G(g) ((g)->t_aim_count)
@d LV_AIM_Count_of_G(g) AIM_Count_of_G(g) 
@<Int aligned grammar elements@> =
   guint t_aim_count;
@ The space is allocated during precomputation.
Because the grammar may be destroyed before precomputation,
I test that |g->t_AHFA_items| is non-zero.
@ @<Initialize grammar elements@> =
g->t_AHFA_items = NULL;
g->t_AHFA_items_by_rule = NULL;
@ @<Destroy grammar elements@> =
if (g->t_AHFA_items) { g_free(g->t_AHFA_items); };
if (g->t_AHFA_items_by_rule) { g_free(g->t_AHFA_items_by_rule); };

@*0 AHFA Item Accessors.
@*1 AHFA Item ID.
@d AIM_by_ID(g, id) ((g)->t_AHFA_items+(id))

@*1 AHFA Item Postdot Symbol.
|-1| if the item is a completion.
@d Postdot_SYMID_of_AIM(item) ((item)->t_postdot)
@d LV_Postdot_SYMID_of_AIM(item) Postdot_SYMID_of_AIM(item)
@d AIM_is_Completion(aim) (Postdot_SYMID_of_AIM(aim) < 0)
@d AIM_has_Completed_Start_Rule(aim)
    (AIM_is_Completion(aim) && RULE_is_Start(RULE_of_AIM(aim)))
@<Int aligned AHFA item elements@> = Marpa_Symbol_ID t_postdot;

@*1 Production of AHFA Item.
@d RULE_of_AIM(item) ((item)->t_production)
@d RULEID_of_AIM(item) ID_of_RULE(RULE_of_AIM(item))
@d LV_RULE_of_AIM(item) RULE_of_AIM(item)
@d LHS_ID_of_AIM(item) (LHS_ID_of_PRD(RULE_of_AIM(item)))

@*0 AHFA Item External Accessors.
@<Function definitions@> =
guint marpa_AHFA_item_count(struct marpa_g* g) {
    @<Return |-2| on failure@>@/
    @<Fail if grammar not precomputed@>@/
    return AIM_Count_of_G(g);
}
@ @<Public function prototypes@> =
guint marpa_AHFA_item_count(struct marpa_g* g);

@ @<Function definitions@> =
Marpa_Rule_ID marpa_AHFA_item_rule(struct marpa_g* g,
	Marpa_AHFA_Item_ID item_id) {
    @<Return |-2| on failure@>@/
    @<Fail if grammar not precomputed@>@/
    @<Fail if grammar |item_id| is invalid@>@/
    return RULE_of_AIM(AIM_by_ID(g, item_id))->t_id;
}
@ @<Public function prototypes@> =
Marpa_Rule_ID marpa_AHFA_item_rule(struct marpa_g* g, Marpa_AHFA_Item_ID item_id);
@ |-1| is the value for completions, so |-2| is the failure indicator.
@<Function definitions@> =
gint marpa_AHFA_item_position(struct marpa_g* g,
	Marpa_AHFA_Item_ID item_id) {
    @<Return |-2| on failure@>@/
    @<Fail if grammar not precomputed@>@/
    @<Fail if grammar |item_id| is invalid@>@/
    return Position_of_AIM(AIM_by_ID(g, item_id));
}
@ @<Public function prototypes@> =
gint marpa_AHFA_item_position(struct marpa_g* g, Marpa_AHFA_Item_ID item_id);
@ |-1| is the value for completions, so |-2| is the failure indicator.
@<Function definitions@> =
Marpa_Symbol_ID marpa_AHFA_item_postdot(struct marpa_g* g,
	Marpa_AHFA_Item_ID item_id) {
    @<Return |-2| on failure@>@/
    @<Fail if grammar not precomputed@>@/
    @<Fail if grammar |item_id| is invalid@>@/
    return Postdot_SYMID_of_AIM(AIM_by_ID(g, item_id));
}
@ @<Public function prototypes@> =
Marpa_Symbol_ID marpa_AHFA_item_postdot(struct marpa_g* g, Marpa_AHFA_Item_ID item_id);
@ @<Function definitions@> =
gint marpa_AHFA_item_sort_key(struct marpa_g* g,
	Marpa_AHFA_Item_ID item_id) {
    @<Return |-2| on failure@>@/
    @<Fail if grammar not precomputed@>@/
    @<Fail if grammar |item_id| is invalid@>@/
    return Sort_Key_of_AIM(AIM_by_ID(g, item_id));
}
@ @<Public function prototypes@> =
gint marpa_AHFA_item_sort_key(struct marpa_g* g, Marpa_AHFA_Item_ID item_id);

@ Check that symbol is in valid range.
@<Function definitions@> =
static inline gboolean item_is_valid(
const struct marpa_g *g, Marpa_AHFA_Item_ID item_id) {
return item_id < (Marpa_AHFA_Item_ID)AIM_Count_of_G(g) && item_id >= 0;
}
@ @<Private function prototypes@> =
static inline gboolean item_is_valid(
const struct marpa_g *g, Marpa_AHFA_Item_ID item_id);

@ I do not use a |DSTACK| because I can initially size the
item stack to |Size_of_G(g)|, which is a reasonable allocation,
but guaranteed to be greater than
or equal to the final numbers of items.
That means that I can avoid the overhead of checking the array
size when adding each new AHFA item.
@<Function definitions@> =
static inline
void create_AHFA_items(struct marpa_g* g) {
    Marpa_Rule_ID rule_id;
    guint no_of_items;
    guint no_of_rules = rule_count(g);
    AIM base_item = g_new(struct s_AHFA_item, Size_of_G(g));
    AIM current_item = base_item;
    for (rule_id = 0; rule_id < (Marpa_Rule_ID)no_of_rules; rule_id++) {
	@<Create the AHFA items for a rule@>@;
	NEXT_RULE: ;
    }
    no_of_items = LV_AIM_Count_of_G(g) = current_item - base_item;
    g->t_AHFA_items = g_renew(struct s_AHFA_item, base_item, no_of_items);
    @<Set up the items-by-rule list@>@;
    @<Set up the AHFA item ids@>@;
}
@ @<Private function prototypes@> =
static inline void create_AHFA_items(struct marpa_g* g);

@ @<Create the AHFA items for a rule@> =
guint rhs_ix;
RULE  rule = RULE_by_ID(g, rule_id);
if (!rule->t_is_used) goto NEXT_RULE;
for (rhs_ix = 0; rhs_ix < rule->t_length; rhs_ix++) {
     @<Create an AHFA item for a precompletion@>@;
     current_item++;
     NEXT_RH_SYMBOL: ;
}
@<Create an AHFA item for a completion@>@;
current_item++;

@ @<Create an AHFA item for a precompletion@> =
Marpa_Symbol_ID rh_symid = rhs_symid(rule, rhs_ix);
SYM symbol = SYM_by_ID(g, rh_symid);
if (symbol->t_is_nullable) goto NEXT_RH_SYMBOL;
LV_Sort_Key_of_AIM(current_item) = current_item - base_item;
LV_Postdot_SYMID_of_AIM(current_item) = rh_symid;
LV_RULE_of_AIM(current_item) = rule;
LV_Position_of_AIM(current_item) = rhs_ix;

@ @<Create an AHFA item for a completion@> =
LV_Sort_Key_of_AIM(current_item) = current_item - base_item;
LV_Postdot_SYMID_of_AIM(current_item) =  -1;
LV_Position_of_AIM(current_item) = -1;
LV_RULE_of_AIM(current_item) = rule;

@ This is done after creating the AHFA items, because in
theory the |g_renew| might have moved them.
This is not likely since the |g_renew| shortened the array,
but if you are hoping for portability,
you want to follow the rules.
@<Set up the items-by-rule list@> = {
AIM* items_by_rule = g_new0(AIM, no_of_rules); /* Must be
zeroed because not all entries will be populated */
AIM items = g->t_AHFA_items;
Marpa_Rule_ID highest_found_rule_id = -1; /* The highest ID of a rule whose AHFA items
    have been found */
Marpa_AHFA_Item_ID item_id;
for (item_id = 0; item_id < (Marpa_AHFA_Item_ID)no_of_items; item_id++) {
     AIM item = items+item_id;
     Marpa_Rule_ID rule_id_for_item = LV_RULE_of_AIM(item)->t_id;
     if (rule_id_for_item <= highest_found_rule_id) continue;
     items_by_rule[rule_id_for_item] = item;
     highest_found_rule_id = rule_id_for_item;
}
g->t_AHFA_items_by_rule = items_by_rule;
}

@ The AHFA items were created with a temporary ID which sorts them
by rule, then by position within that rule.  We need one that sort the AHFA items
by (from major to minor) postdot symbol, then rule, then position.
A postdot symbol of $-1$ should sort high.
@ @<Function definitions@> =
static gint cmp_by_AHFA_item_id (gconstpointer ap,
	gconstpointer bp, gpointer user_data @, G_GNUC_UNUSED) {
    AIM a = *(AIM*)ap;
    AIM b = *(AIM*)bp;
    gint a_postdot = Postdot_SYMID_of_AIM(a);
    gint b_postdot = Postdot_SYMID_of_AIM(b);
    if (a_postdot == b_postdot)
      return Sort_Key_of_AIM (a) - Sort_Key_of_AIM (b);
    if (a_postdot < 0) return 1;
    if (b_postdot < 0) return -1;
    return a_postdot-b_postdot;
}
@ @<Private function prototypes@> =
static gint cmp_by_AHFA_item_id (gconstpointer a,
	gconstpointer b, gpointer user_data);
@ @<Set up the AHFA item ids@> = { Marpa_AHFA_Item_ID item_id;
AIM* sort_array = g_new(struct s_AHFA_item*, no_of_items);
AIM items = g->t_AHFA_items;
for (item_id = 0; item_id < (Marpa_AHFA_Item_ID)no_of_items; item_id++) {
    /* Create an array of pointers to the old items,
      in order to sort them
      */
    sort_array[item_id] = items+item_id; 
}
g_qsort_with_data(sort_array,
    (gint)no_of_items, sizeof(AIM), cmp_by_AHFA_item_id, (gpointer)NULL);
for (item_id = 0; item_id < (Marpa_AHFA_Item_ID)no_of_items; item_id++) {
    LV_Sort_Key_of_AIM(sort_array[item_id]) = item_id;
}
g_free(sort_array); }

@** AHFA State (AHFA) Code.

This algorithm to create the AHFA states is new with |libmarpa|.
It is based on noting that the states to be created fall into
distinct classes, and that considerable optimization is possible
if the classes of AHFA states are optimized separately.
@ In their paper Aycock and Horspool divide the states of their
automaton into
call non-kernel and kernel states.
In the AHFA, kernel states are called discovered AHFA states.
Non-kernel states are called predicted AHFA states.
If an AHFA states contains a start rule or
or an AHFA item for which at least some
non-nulling symbol has been recognized,
it is an {\bf discovered} AHFA state.
Otherwise, the AHFA state will contain only predictions,
and is a {\bf predicted} AHFA state.
@ Predicted AHFA states are so called because they only contain
items which predict, according to the grammar,
what might be found in the input.
Discovered AHFA states are so called because either they "report"
the start of the input
or they "report" symbols actually found in the input.
There is only one case in which
a discovered AHFA state will contain a prediction ---
that is when the AHFA state contains an
AHFA item for the nulling start rule.
@ {\bf The Initial AHFA State}:
This is the only state which can
contain an AHFA item for a null rule.
It only takes one of three possible forms.
Listing the reasons that it makes sense to special-case
this class would take more space than the code to do it.
@ {\bf The Initial AHFA Prediction State}:
This state is paired with a special-cased state, so it would
require going out of our way to {\bf not} special-case this
state as well.
It does
share with the other initial state that property that it is not
necessary to check to ensure it does not duplicate an existing
state.
Other than that, the code is much like that to create any other
prediction state.
@ {\bf Discovered States with 1 item}:
These may be specially optimized for.
Sorting the items can be dispensed with.
Checking for duplicates can be done using an array indexed by
the ID of the only AHFA item.
Statistics for practical grammars show that most discovered states
contain only a single AHFA item, so there is a big payoff from
special-casing these.
@ {\bf Discovered States with 2 or more items}:
For non-singleton discovered states,
I use a hand-written insertion sort,
and check for duplicates using a hash with a customized key.
Further optimizations are possible, but
few discovered states fall into this case.
Also, discovered states of 2 items are a large enough class to justify
separating out, if a significant optimization for them could be
found.
@ {\bf Predicted States}:
These are treated differently from discovered states.
The items in these are always a subset of the initial items for rules,
and therefore correspond one-to-one with a powerset of the rules.
This fact is used in precomputing rule bit vectors, by postdot symbol,
to speed up the construction of these.
An advantage of using bit vectors is that a radix sort of the items
happens as a side effect.
Because prediction states follow a very different distribution from
discovered states, they have their own hash for checking duplicates.

@<Public typedefs@> =
typedef gint Marpa_AHFA_State_ID;

@ {\bf Estimating the number of AHFA States}: Based on the numbers given previously
for Perl and HTML,
$2s$ is a good high-ball estimate of the number of AHFA states for
grammars of practical interest,
where $s$ is the size of the grammar.
I come up with this as follows.

Let the size of an AHFA state be the number of AHFA items it contains.
\li It is impossible for the number of AHFA items to greater than
the size of the grammar.
\li It is impossible for the number of discovered states of size 1
to be greater than the number of AHFA items.
\li The number of discovered states of size 2 or greater
will typically be half the number of discovered states of size 1,
or less.
\li The number of predicted states will typically be
considerably less than half the number of discovered states.

The three possibilities just enumerated exhaust the possibilities for AHFA states.
The total is ${s \over 2} + {s \over 2} + s = 2s$.
Typically, the number of AHFA states should be less than this estimate.

@d AHFA_by_ID(id) (g->t_AHFA+(id))
@d Complete_SYMIDARY_of_AHFA(state) ((state)->t_complete_symbols)
@d Complete_SYM_Count_of_AHFA(state) ((state)->t_complete_symbol_count)
@d AHFA_has_Completed_Start_Rule(ahfa) ((ahfa)->t_has_completed_start_rule)
@<Private incomplete structures@> = struct s_AHFA_state;
@ @<Private structures@> =
struct s_AHFA_state_key {
    Marpa_AHFA_State_ID t_id;
};
struct s_AHFA_state {
    struct s_AHFA_state_key t_key;
    struct s_AHFA_state* t_empty_transition;
    AHFA* t_to_ahfa_ary;
    SYMID* t_complete_symbols;
    @<Widely aligned AHFA state elements@>@;
    @<Int aligned AHFA state elements@>@;
    guint t_complete_symbol_count;
    guint t_has_completed_start_rule:1;
    @<Bit aligned AHFA elements@>@;
};
typedef struct s_AHFA_state AHFAD;

@*0. AHFA Item Container.
@ @d AIM_Count_of_AHFA(ahfa) ((ahfa)->t_item_count)
@ @d LV_AIM_Count_of_AHFA(ahfa) AIM_Count_of_AHFA(ahfa)
@<Int aligned AHFA state elements@> =
guint t_item_count;
@ @d AIMs_of_AHFA(ahfa) ((ahfa)->t_items)
@d LV_AIMs_of_AHFA(ahfa) AIMs_of_AHFA(ahfa)
@<Widely aligned AHFA state elements@> =
AIM* t_items;

@*0. Is AHFA Predicted?.
@ This boolean indicates whether the
{\bf AHFA state} is predicted,
as opposed to whether it contains any predicted 
AHFA items.
This makes a difference in AHFA state 0.
When the null parse is allowed.
AHFA state 0 will contain an AHFA item
which is {\bf both} a prediction
and a completion.
AHFA state 0 is, however, {\bf never}
a predicted AHFA state.
@d AHFA_is_Predicted(ahfa) ((ahfa)->t_is_predict)
@d LV_AHFA_is_Predicted(ahfa) AHFA_is_Predicted(ahfa)
@<Bit aligned AHFA elements@> =
guint t_is_predict:1;

@ @<Private typedefs@> =
typedef struct s_AHFA_state* AHFA;
typedef gint AHFAID;

@ @<Widely aligned grammar elements@> = struct s_AHFA_state* t_AHFA;
@
@d AHFA_Count_of_G(g) ((g)->t_AHFA_len)
@d LV_AHFA_Count_of_G(g) ((g)->t_AHFA_len)
@<Int aligned grammar elements@> = gint t_AHFA_len;
@ @<Initialize grammar elements@> =
g->t_AHFA = NULL;
LV_AHFA_Count_of_G(g) = 0;
@*0 Destructor.
@<Destroy grammar elements@> = if (g->t_AHFA) {
AHFAID id;
for (id = 0; id < AHFA_Count_of_G(g); id++) {
   AHFA ahfa_state = AHFA_by_ID(id);
   @<Free AHFA state@>@;
}
STOLEN_DQUEUE_DATA_FREE(g->t_AHFA);
}

@ Most of the data is on the obstack, and will be freed with that.
@<Free AHFA state@> = {
 AHFA* ahfa_transition_array = ahfa_state->t_to_ahfa_ary;
  if (ahfa_transition_array) g_free(ahfa_state->t_to_ahfa_ary);
}

@*0 ID of AHFA State.
@d ID_of_AHFA(state) ((state)->t_key.t_id)

@*0 Validate AHFA ID.
Check that symbol is in valid range.
@<Function definitions@> =
static inline gint AHFA_state_id_is_valid(
const struct marpa_g *g, AHFAID AHFA_state_id) {
return AHFA_state_id < AHFA_Count_of_G(g) && AHFA_state_id >= 0;
}
@ @<Private function prototypes@> =
static inline gint AHFA_state_id_is_valid(
const struct marpa_g *g, AHFAID AHFA_state_id);

@*0 Convert AHFA index to AHFA ID.
@ Given an AHFA state
and an index into the array of items for an AHFA state,
return the |AHFA_Item_ID|.
The caller must ensure that
the index is in range.
@<Function definitions@> =
static inline Marpa_AHFA_Item_ID AHFA_state_item_ix2id(
const struct marpa_g *g, const AHFA state, guint item_ix) {
   return state->t_items[item_ix] - g->t_AHFA_items;
}
@ @<Private function prototypes@> =
static inline Marpa_AHFA_Item_ID AHFA_state_item_ix2id(
const struct marpa_g *g, const AHFA state, guint item_ix);

@*0 Postdot Symbols.
@d Postdot_SYM_Count_of_AHFA(state) ((state)->t_postdot_sym_count)
@d LV_Postdot_SYM_Count_of_AHFA(state) Postdot_SYM_Count_of_AHFA(state) 
@d Postdot_SYMID_Ary_of_AHFA(state) ((state)->t_postdot_symid_ary)
@d LV_Postdot_SYMID_Ary_of_AHFA(state) Postdot_SYMID_Ary_of_AHFA(state)
@<Widely aligned AHFA state elements@> = Marpa_Symbol_ID* t_postdot_symid_ary;
@ @<Int aligned AHFA state elements@> = guint t_postdot_sym_count;

@*0 AHFA State External Accessors.
@<Function definitions@> =
guint marpa_AHFA_state_count(struct marpa_g* g) {
    return AHFA_Count_of_G(g);
}
@ @<Public function prototypes@> =
guint marpa_AHFA_state_count(struct marpa_g* g);

@ @<Function definitions@> =
gint
marpa_AHFA_state_item_count(struct marpa_g* g, AHFAID AHFA_state_id)
{ @<Return |-2| on failure@>@/
    AHFA state;
    @<Fail if grammar not precomputed@>@/
    @<Fail if grammar |AHFA_state_id| is invalid@>@/
    state = AHFA_by_ID(AHFA_state_id);
    return state->t_item_count;
}
@ @<Public function prototypes@> =
gint marpa_AHFA_state_item_count(struct marpa_g* g, Marpa_AHFA_State_ID AHFA_state_id);

@ @<Function definitions@> =
Marpa_AHFA_Item_ID marpa_AHFA_state_item(struct marpa_g* g,
     AHFAID AHFA_state_id,
	guint item_ix) {
    AHFA state;
    @<Return |-2| on failure@>@/
    @<Fail if grammar not precomputed@>@/
    @<Fail if grammar |AHFA_state_id| is invalid@>@/
    state = AHFA_by_ID(AHFA_state_id);
    if (item_ix >= state->t_item_count) {
	g_context_clear(g);
	g_context_int_add(g, "item_ix", (gint)item_ix);
	g_context_int_add(g, "AHFA_state_id", AHFA_state_id);
	g->t_error = "invalid state item ix";
	return failure_indicator;
    }
    return AHFA_state_item_ix2id(g, state, item_ix);
}
@ @<Public function prototypes@> =
Marpa_AHFA_Item_ID marpa_AHFA_state_item(struct marpa_g* g,
     Marpa_AHFA_State_ID AHFA_state_id,
	guint item_ix);

@*0 Symbol Transitions of AHFA State.
@
Complexity is fine --- $O(1)$ in the length of the input,
but nonetheless this implementation might be improved.
This operation is at the heart of the parse engine,
and worth a careful look.
@ One alternative is to use bison's solution,
which is a type of perfect hashing.
Calculating AHFA transitions
is very closely related to accessing an LALR table ---
for this purpose, both are essentially LR(0) tables.
Time and space tradeoffs of the two algorithms
are, if not identical, very, very similar.
So the result of bison's experience is probably
the best solution here.
@ Another alternative is to use
a sparse 2-dimensional array.
This would be easy to implement
and very fast,
but the array will be $a\cdot s$
in size,
where $a$ is the number of AHFA states,
and 
where $s$ is the number of symbols.
Since most transitions are not defined, most of the space would be wasted.
@ The trend is for memory to get cheap, favoring the 2-dimensional array.
But I expect the trend will also be for grammars to get larger,
and the space required by the 2-dimensional array is roughly
$O(n^2)$ in the size of the grammar.

@ @<Public function prototypes@> =
gint marpa_AHFA_state_transitions(struct marpa_g* g,
    Marpa_AHFA_State_ID AHFA_state_id,
    GArray *result);
@ @<Function definitions@> =
gint marpa_AHFA_state_transitions(struct marpa_g* g,
    Marpa_AHFA_State_ID AHFA_state_id,
    GArray *result) {

    @<Return |-2| on failure@>@;
    AHFA from_ahfa_state;
    AHFA* to_ahfa_array;
    SYMID symid;
    gint symbol_count;

    @<Fail if grammar not precomputed@>@;
    @<Fail if grammar |AHFA_state_id| is invalid@>@;
    @<Fail grammar if elements of |result| are not |sizeof(gint)|@>@;
    from_ahfa_state = AHFA_by_ID(AHFA_state_id);
    to_ahfa_array = from_ahfa_state->t_to_ahfa_ary; 
    symbol_count = SYM_Count_of_G(g);
    g_array_set_size(result, 0);
    for (symid = 0; symid < symbol_count; symid++) {
        AHFA to_ahfa_state = to_ahfa_array[symid];
	if (!to_ahfa_state) continue;
	g_array_append_val (result, symid);
	g_array_append_val (result, ID_of_AHFA(to_ahfa_state));
    }
    return result->len;
}

@*0 Empty Transition of AHFA State.
@d Empty_Transition_of_AHFA(state) ((state)->t_empty_transition)
@ In the external accessor,
-1 is a valid return value, indicating no empty transition.
@<Function definitions@> =
AHFAID marpa_AHFA_state_empty_transition(struct marpa_g* g,
     AHFAID AHFA_state_id) {
    AHFA state;
    AHFA empty_transition_state;
    @<Return |-2| on failure@>@/
    @<Fail if grammar not precomputed@>@/
    @<Fail if grammar |AHFA_state_id| is invalid@>@/
    state = AHFA_by_ID(AHFA_state_id);
    empty_transition_state = Empty_Transition_of_AHFA (state);
    if (empty_transition_state)
      return ID_of_AHFA (empty_transition_state);
    return -1;
}
@ @<Public function prototypes@> =
Marpa_AHFA_State_ID marpa_AHFA_state_empty_transition(struct marpa_g* g,
     Marpa_AHFA_State_ID AHFA_state_id);

@ @<Function definitions@> =
gint marpa_AHFA_state_is_predict(struct marpa_g* g,
	AHFAID AHFA_state_id) {
    AHFA state;
    @<Return |-2| on failure@>@/
    @<Fail if grammar not precomputed@>@/
    @<Fail if grammar |AHFA_state_id| is invalid@>@/
    state = AHFA_by_ID(AHFA_state_id);
    return AHFA_is_Predicted(state);
}
@ @<Public function prototypes@> =
gint marpa_AHFA_state_is_predict(struct marpa_g* g,
	Marpa_AHFA_State_ID AHFA_state_id);

@*0 Completed Start Rule.
This external acccessor returns the rule ID of
the completed start rule of an AHFA state.
Most often there is none, in which case
|-1| is returned.
For other failures, |-2| is returned.
@ @<Public function prototypes@> =
Marpa_Rule_ID marpa_AHFA_completed_start_rule(struct marpa_g* g,
	Marpa_AHFA_State_ID AHFA_state_id);
@ I know that the completed start rule is this AHFA state is
unique, via the following theorem.
\Theorem/ No AHFA state contains more than one completed start rule.
\Proof/: As proved elsewhere in this document,
an AFHA state with a completed start rule is either AHFA state 0
or a 1-item discovered AHFA state.
Clearly the AHFA item which is the completed start rule is 
unique in a 1-item AHFA state.
From its construction we know that
AHFA state 0 contains at most two rules:
a predicted non-null start rule
and a predicted null start rule.
A predicted non-null rule is not a completed rule.
Therefore only the predicted null start rule
can be a completed start rule in AHFA state 0.
\QED/.
@ @.To Do@> {\bf To Do}:
This function can probably be eliminated after conversion
is complete, along with the flag for whether a rule is a start rule
and the flag for tracking whether an AHFA has a completed start rule.

@<Function definitions@> =
Marpa_Rule_ID marpa_AHFA_completed_start_rule(struct marpa_g* g,
	Marpa_AHFA_State_ID AHFA_state_id) {
    const gint no_completed_start_rule = -1;
    @<Return |-2| on failure@>@;
    AHFA state;
    @<Fail if grammar not precomputed@>@;
    @<Fail if grammar |AHFA_state_id| is invalid@>@;
    state = AHFA_by_ID (AHFA_state_id);
    if (AHFA_has_Completed_Start_Rule(state)) {
	const gint ahfa_item_count = state->t_item_count;
	const AIM* ahfa_items = state->t_items;
	gint ahfa_ix;
	for (ahfa_ix = 0; ahfa_ix < ahfa_item_count; ahfa_ix++)
	  {
	    const AIM ahfa_item = ahfa_items[ahfa_ix];
	    if (AIM_is_Completion (ahfa_item))
	      {
		const RULE rule = RULE_of_AIM (ahfa_item);
		if (RULE_is_Start (rule))
		  return ID_of_RULE (rule);
	      }
	  }
      @<Fail with internal grammar error@>@;
  }
  return no_completed_start_rule;
}

@*0 Leo LHS Symbol.
The Leo LHS symbol is the LHS of the AHFA state's rule,
if that state can be a Leo completion.
Otherwise it is |-1|.
The value of the Leo completion symbol is used to
determine if an Earley item
with this AHFA state is eligible to be a Leo completion.
@d Leo_LHS_ID_of_AHFA(state) ((state)->t_leo_lhs_sym)
@d LV_Leo_LHS_ID_of_AHFA(state) Leo_LHS_ID_of_AHFA(state)
@d AHFA_is_Leo_Completion(state) (Leo_LHS_ID_of_AHFA(state) >= 0)
@ @<Int aligned AHFA state elements@> = SYMID t_leo_lhs_sym;
@ @<Public function prototypes@> =
Marpa_Symbol_ID marpa_AHFA_state_leo_lhs_symbol(struct marpa_g* g,
	Marpa_AHFA_State_ID AHFA_state_id);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_AHFA_state_leo_lhs_symbol(struct marpa_g* g,
	Marpa_AHFA_State_ID AHFA_state_id) {
    @<Return |-2| on failure@>@;
    AHFA state;
    @<Fail if grammar not precomputed@>@;
    @<Fail if grammar |AHFA_state_id| is invalid@>@;
    state = AHFA_by_ID(AHFA_state_id);
    return Leo_LHS_ID_of_AHFA(state);
}

@*0 Internal Accessors.
@ The ordering of the AHFA states can be arbitrarily chosen
to be efficient to compute.
The only requirement is that states with identical sets
of items compare equal.
Here the length is the first subkey, because
that will be enough to order most predicted states.
The discovered states will be efficient to compute because
they will tend either to be short,
or quickly differentiated
by length.
\par
Note that this function is not used for discovered AHFA states of
size 1.
Checking those for duplicates is optimized, using an array
indexed by the ID of their only AHFA item.
@<Private function prototypes@> =
static gint AHFA_state_cmp(gconstpointer a, gconstpointer b);
@ @<Function definitions@> =
static gint AHFA_state_cmp(
    gconstpointer ap,
    gconstpointer bp)
{
    guint i;
    AIM* items_a;
    AIM* items_b;
    const AHFA state_a = (AHFA)ap;
    const AHFA state_b = (AHFA)bp;
    guint length = state_a->t_item_count;
    gint subkey = length - state_b->t_item_count;
    if (subkey) return subkey;
    if (length != state_b->t_item_count) return FALSE;
    items_a = state_a->t_items;
    items_b = state_b->t_items;
    for (i = 0; i < length; i++) {
    subkey = Sort_Key_of_AIM (items_a[i]) - Sort_Key_of_AIM (items_b[i]);
   if (subkey) return subkey;
}
return 0;
}

@*0 AHFA State Mutators.
@<Function definitions@> =
static
void create_AHFA_states(struct marpa_g* g) {
   AHFA p_working_state;
   const guint initial_no_of_states = 2*Size_of_G(g);
   AIM AHFA_item_0_p = g->t_AHFA_items;
   guint no_of_symbols = SYM_Count_of_G(g);
   guint no_of_rules = rule_count(g);
   Bit_Matrix prediction_matrix;
   RULE* rule_by_sort_key = g_new(RULE, no_of_rules);
    GTree* duplicates;
    AHFA* singleton_duplicates;
   DQUEUE_DECLARE(states);
    @<Initialize duplicates data structures@>@;
   DQUEUE_INIT(states, AHFAD, initial_no_of_states);
   @<Construct prediction matrix@>@;
   @<Construct initial AHFA states@>@;
   while ((p_working_state = DQUEUE_NEXT(states, AHFAD))) {
       @<Process an AHFA state from the working stack@>@;
   }
   g->t_AHFA = DQUEUE_BASE(states, AHFAD); /* "Steals"
       the |DQUEUE|'s data */
   LV_AHFA_Count_of_G(g) = DQUEUE_END(states);
   g_free(rule_by_sort_key);
   matrix_free(prediction_matrix);
   @<Free duplicates data structures@>@;
}
@ @<Private function prototypes@> =
static void create_AHFA_states(struct marpa_g* g);

@ @<Process an AHFA state from the working stack@> = {
guint no_of_items = p_working_state->t_item_count;
guint current_item_ix=0;
AIM*item_list;
Marpa_Symbol_ID working_symbol;
item_list = p_working_state->t_items;
working_symbol = Postdot_SYMID_of_AIM(item_list[0]); /*
    Every AHFA has at least one item */
if (working_symbol < 0) goto NEXT_AHFA_STATE; /*
    All items in this state are completions */
    while (1) { /* Loop over all items for this state */
	guint first_working_item_ix = current_item_ix;
	guint no_of_items_in_new_state;
	for (current_item_ix++;
		current_item_ix < no_of_items;
		current_item_ix++) {
	    if (Postdot_SYMID_of_AIM(item_list[current_item_ix]) != working_symbol) break;
	}
	no_of_items_in_new_state = current_item_ix - first_working_item_ix;
	if (no_of_items_in_new_state == 1) {
	    @<Create a 1-item discovered AHFA state@>@/
	} else {
	    @<Create a discovered AHFA state with 2+ items@>@/
	}
	NEXT_WORKING_SYMBOL: ;
	if (current_item_ix >= no_of_items) break;
	working_symbol = Postdot_SYMID_of_AIM(item_list[current_item_ix]);
	if (working_symbol < 0) break;
    }@#
NEXT_AHFA_STATE: ;
}

@ @<Initialize duplicates data structures@> = { guint item_id;
guint no_of_items_in_grammar = AIM_Count_of_G(g);
duplicates = g_tree_new(AHFA_state_cmp);
singleton_duplicates = g_new(AHFA, no_of_items_in_grammar);
for ( item_id = 0; item_id < no_of_items_in_grammar; item_id++) {
    singleton_duplicates[item_id] = NULL; // All zero bits are not necessarily a NULL pointer
} }
@ @<Free duplicates data structures@> =
g_free(singleton_duplicates);
g_tree_destroy(duplicates);

@ @<Construct initial AHFA states@> = {
   AHFA p_initial_state = DQUEUE_PUSH(states, AHFAD);@/
   Marpa_Rule_ID start_rule_id;
   AIM start_item;
   SYM start_symbol = SYM_by_ID(g, g->t_start_symid);
   SYM start_alias
       = symbol_null_alias(start_symbol);
    gint no_of_items_in_new_state = start_alias ? 2 : 1;
    AIM* item_list
	= obstack_alloc(&g->t_obs, no_of_items_in_new_state*sizeof(AIM));
    start_rule_id = g_array_index(start_symbol->t_lhs, Marpa_Rule_ID, 0); /* The start rule
	is the unique rule that has the start symbol as its LHS */
    start_item = g->t_AHFA_items_by_rule[start_rule_id]; /* The start item is the
       initial item for the start rule */
    item_list[0] = start_item;
    if (start_alias) {
       Marpa_Rule_ID alias_rule_id
	    = g_array_index(start_alias->t_lhs, Marpa_Rule_ID, 0); /* Start alias
	    rule is the unique rule that has
	   the start alias as its LHS */
	item_list[1] = g->t_AHFA_items_by_rule[alias_rule_id];
    }
    p_initial_state->t_items = item_list;
    p_initial_state->t_item_count = no_of_items_in_new_state;
    p_initial_state->t_key.t_id = 0;
    LV_AHFA_is_Predicted(p_initial_state) = 0;
    LV_Leo_LHS_ID_of_AHFA(p_initial_state) = -1;
    p_initial_state->t_to_ahfa_ary = to_ahfa_array_new(g);
    p_initial_state->t_empty_transition = NULL;
    if (start_symbol->t_is_nulling)
      {				// Special case the null parse
	p_initial_state->t_complete_symbol_count = 1;
	p_initial_state->t_has_completed_start_rule = 1;
	p_initial_state->t_complete_symbols =
	  obstack_alloc (&g->t_obs, sizeof (SYMID));
	*(p_initial_state->t_complete_symbols) = g->t_start_symid;
	LV_Postdot_SYM_Count_of_AHFA(p_initial_state) = 0;
      }
    else
      {
	SYMID* postdot_symbol_ids;
	LV_Postdot_SYM_Count_of_AHFA(p_initial_state) = 1;
	postdot_symbol_ids = LV_Postdot_SYMID_Ary_of_AHFA(p_initial_state) = 
	  obstack_alloc (&g->t_obs, sizeof (SYMID));
	*postdot_symbol_ids = Postdot_SYMID_of_AIM(start_item);
	if (start_alias)
	  {
	    p_initial_state->t_complete_symbol_count = 1;
	    p_initial_state->t_has_completed_start_rule = 1;
	    p_initial_state->t_complete_symbols =
	      obstack_alloc (&g->t_obs, sizeof (SYMID));
	    *(p_initial_state->t_complete_symbols) =
	      LHS_ID_of_PRD (RULE_by_ID (g, start_rule_id));
	  }
	else
	  {
	    p_initial_state->t_complete_symbol_count = 0;
	    p_initial_state->t_has_completed_start_rule = 0;
	  }
	    p_initial_state->t_empty_transition =
	    create_predicted_AHFA_state (g,
			     matrix_row (prediction_matrix,
					 (guint)
					 Postdot_SYMID_of_AIM (start_item)),
			     rule_by_sort_key, &states, duplicates);
      }
}

@* Discovered AHFA States.
@ {\bf Theorem}:
An AHFA state that contains a start rule completion is either
AHFA state 0 or a 1-item discovered state.
{\bf Proof}:
AHFA state 0 contains a start rule completion in any grammar
for which the null parse is valid.
AHFA state 0 also contains the non-null parse predicted rule.
\par
The grammar is augmented,
so that no other rule predicts the start rules.
This means that AHFA state 0 will contain the only predicted
start rules.
The form of the non-null predicted start rule
is $S' \leftarrow \cdot S$,
where $S'$ is the augmented start symbol and $S$ was
the start symbol in the original grammar.
This rule will be the only transition out of AHFA state 0.
Call the to-state of this transition, state $n$.
State $n$ will clearly contain a completed start rule
( $S' \leftarrow S \cdot$ ),
which will be rule for the only AHFA item in AHFA state $n$.
\par
Since only state 0 contains 
$S' \leftarrow \cdot S$,
only AHFA state $n$ will contain 
$S' \leftarrow S \cdot$.
Therefore all AHFA states containing start rule completions
are either AHFA state 0, or 1-item discovered AHFA states.
{\bf QED}.
@<Create a 1-item discovered AHFA state@> = {
    AHFA p_new_state;
    AIM* new_state_item_list;
    AIM single_item_p = item_list[first_working_item_ix];
    Marpa_AHFA_Item_ID single_item_id;
    Marpa_Symbol_ID postdot;
    single_item_p++;		// Transition to next item for this rule
    single_item_id = single_item_p - AHFA_item_0_p;
    p_new_state = singleton_duplicates[single_item_id];
    if (p_new_state)
      {				/* Do not add, this is a duplicate */
	AHFA_transition_add (p_working_state, working_symbol, p_new_state);
	goto NEXT_WORKING_SYMBOL;
      }
    p_new_state = DQUEUE_PUSH (states, AHFAD);
    /* Create a new AHFA state */
    singleton_duplicates[single_item_id] = p_new_state;
    new_state_item_list = p_new_state->t_items =
	obstack_alloc (&g->t_obs, sizeof (AIM));
    new_state_item_list[0] = single_item_p;
    p_new_state->t_item_count = 1;
    LV_AHFA_is_Predicted(p_new_state) = 0;
    if (AIM_has_Completed_Start_Rule(single_item_p)) {
	p_new_state->t_has_completed_start_rule = 1;
    } else {
	p_new_state->t_has_completed_start_rule = 0;
    }
    LV_Leo_LHS_ID_of_AHFA(p_new_state) = -1;
    p_new_state->t_key.t_id = p_new_state - DQUEUE_BASE (states, AHFAD);
    p_new_state->t_to_ahfa_ary = to_ahfa_array_new(g);
    AHFA_transition_add (p_working_state, working_symbol, p_new_state);
    postdot = Postdot_SYMID_of_AIM(single_item_p);
    if (postdot >= 0)
      {
	p_new_state->t_complete_symbol_count = 0;
	p_new_state->t_postdot_sym_count = 1;
	p_new_state->t_postdot_symid_ary =
	  obstack_alloc (&g->t_obs, sizeof (SYMID));
	*(p_new_state->t_postdot_symid_ary) = postdot;
    /* If the sole item is not a completion
     attempt to create a predicted AHFA state as well */
	p_new_state->t_empty_transition =
	  create_predicted_AHFA_state (g,
				       matrix_row (prediction_matrix,
						   (guint) postdot),
				       rule_by_sort_key, &states, duplicates);
      }
    else
      {
	SYMID lhs_id;
	p_new_state->t_complete_symbol_count = 1;
	p_new_state->t_complete_symbols =
	  obstack_alloc (&g->t_obs, sizeof (SYMID));
	lhs_id = LHS_ID_of_PRD (single_item_p->t_production);
	*(p_new_state->t_complete_symbols) = lhs_id;
	p_new_state->t_postdot_sym_count = 0;
	p_new_state->t_empty_transition = NULL;
	@<If this state can be a Leo completion,
	set the Leo completion symbol to |lhs_id|@>@;
  }
}

@
Assuming this is a 1-item completion, mark this state as
a Leo completion if the last non-nulling symbol is on a LHS.
(This eliminates rule which end in a terminal-only symbol from
consideration in the Leo logic.)
We know that there is a non-nulling symbol, because there is
one is every non-nulling rule, the only non-nulling rule will
be in AHFA state 0, and AHFA state 0 is
handled as a special cases.
\par
As a note, the current logic makes an item an leo completion
if the last non-nulling symbol is on a LHS.
With a bit more trouble, I could determine
which rules are right-recursive.
I would need to compute a transitive closure on the relationship
"X right-derives Y" and then consider a state to be
a Leo completion
only if the LHS of the rule in its only item right-derives its
last non-nulling symbol.

@ The expression below takes the first (and only) item in
the current state, and finds its closest previous non-nulling
symbol.
This will be the postdot symbol of the AHFA item just prior,
which can be found by simply decrementing the pointer.
If the predot symbol of an item is on the LHS of any rule,
then that state is a Leo completion.
@<If this state can be a Leo completion,
set the Leo completion symbol to |lhs_id|@> = {
  AIM previous_ahfa_item = single_item_p - 1;
  SYMID predot_symid = Postdot_SYMID_of_AIM(previous_ahfa_item);
  if (SYMBOL_LHS_RULE_COUNT (SYM_by_ID (g, predot_symid))
      > 0)
    {
	LV_Leo_LHS_ID_of_AHFA(p_new_state) = lhs_id;
    }
}

@ Discovered AHFA states are usually quite small
and the insertion sort here is probably optimal for the usual cases.
It is $O(n^2)$ for the large AHFA states, but at present there is
little value in coding for such cases.
Average complexity -- probably $O(1)$.
Implemented worst-case complexity: $O(n^2)$.
Theoretical complexity: $O(n \log n)$, because another sort can easily be
substituted for the insertion sort.
\par
Note the mixture of indexing and old-fashioned pointer twiddling
in the insertion sort.
I am usually of the opinion that the pointer twiddling should be left
to the optimizer, but in this case I think that a little bit of
pointer twiddling actually makes the code clearer than it would
be if written 100\% using indexes.
@<Create a discovered AHFA state with 2+ items@> = {
AHFA p_new_state;
guint predecessor_ix;
guint no_of_new_items_so_far = 0;
AIM* item_list_for_new_state;
AHFA queued_AHFA_state;
p_new_state = DQUEUE_PUSH(states, AHFAD);
item_list_for_new_state = p_new_state->t_items = obstack_alloc(&g->t_obs_tricky,
    no_of_items_in_new_state * sizeof(AIM));
p_new_state->t_item_count = no_of_items_in_new_state;
for (predecessor_ix = first_working_item_ix;
     predecessor_ix < current_item_ix; predecessor_ix++)
  {
    gint pre_insertion_point_ix = no_of_new_items_so_far - 1;
    AIM new_item_p = item_list[predecessor_ix] + 1;	// Transition to the next item
    while (pre_insertion_point_ix >= 0)
      {				// Insert the new item, ordered by |sort_key|
	AIM *current_item_pp =
	  item_list_for_new_state + pre_insertion_point_ix;
	if (Sort_Key_of_AIM (new_item_p) >=
	    Sort_Key_of_AIM (*current_item_pp))
	  break;
	*(current_item_pp + 1) = *current_item_pp;
	pre_insertion_point_ix--;
      }
    item_list_for_new_state[pre_insertion_point_ix + 1] = new_item_p;
    no_of_new_items_so_far++;
  }
queued_AHFA_state = assign_AHFA_state(p_new_state, duplicates);
if (queued_AHFA_state)
  {				// The new state would be a duplicate
// Back it out and go on to the next in the queue
    (void) DQUEUE_POP (states, AHFAD);
    obstack_free (&g->t_obs_tricky, item_list_for_new_state);
    AHFA_transition_add (p_working_state, working_symbol, queued_AHFA_state);
    /* |AHFA_transition_add()| allocates obstack memory, but uses the 
       "non-tricky" obstack */
    goto NEXT_WORKING_SYMBOL;
  }
// If we added the new state, finish up its data.
p_new_state->t_key.t_id = p_new_state - DQUEUE_BASE(states, AHFAD);
LV_AHFA_is_Predicted(p_new_state) = 0;
p_new_state->t_has_completed_start_rule = 0;
LV_Leo_LHS_ID_of_AHFA(p_new_state) =-1;
p_new_state->t_to_ahfa_ary = to_ahfa_array_new(g);
@<Calculate complete and postdot symbols for discovered state@>@/
AHFA_transition_add(p_working_state, working_symbol, p_new_state);
@<Calculate the predicted rule vector for this state
and add the predicted AHFA state@>@/
}

@ @<Calculate complete and postdot symbols for discovered state@> =
{
  guint symbol_count = SYM_Count_of_G (g);
  guint item_ix;
  guint no_of_postdot_symbols;
  guint no_of_complete_symbols;
  Bit_Vector complete_v = bv_create (symbol_count);
  Bit_Vector postdot_v = bv_create (symbol_count);
  for (item_ix = 0; item_ix < no_of_items_in_new_state; item_ix++)
    {
      AIM item = item_list_for_new_state[item_ix];
      Marpa_Symbol_ID postdot = Postdot_SYMID_of_AIM (item);
      if (postdot < 0)
	{
	  bv_bit_set (complete_v, (guint) LHS_ID_of_PRD (item->t_production));
	}
      else
	{
	  bv_bit_set (postdot_v, (guint) postdot);
	}
    }
if ((no_of_postdot_symbols = p_new_state->t_postdot_sym_count =
     bv_count (postdot_v)))
  {
    guint min, max, start;
    Marpa_Symbol_ID *p_symbol = p_new_state->t_postdot_symid_ary =
      obstack_alloc (&g->t_obs,
		     no_of_postdot_symbols * sizeof (SYMID));
    for (start = 0; bv_scan (postdot_v, start, &min, &max); start = max + 2)
      {
	Marpa_Symbol_ID postdot;
	for (postdot = (Marpa_Symbol_ID) min;
	     postdot <= (Marpa_Symbol_ID) max; postdot++)
	  {
	    *p_symbol++ = postdot;
	  }
      }
  }
if ((no_of_complete_symbols = p_new_state->t_complete_symbol_count =
     bv_count (complete_v)))
  {
    guint min, max, start;
    Marpa_Symbol_ID *p_symbol = p_new_state->t_complete_symbols =
      obstack_alloc (&g->t_obs,
		     no_of_complete_symbols * sizeof (SYMID));
    for (start = 0; bv_scan (complete_v, start, &min, &max); start = max + 2)
      {
	Marpa_Symbol_ID complete_symbol;
	for (complete_symbol = (Marpa_Symbol_ID) min;
	     complete_symbol <= (Marpa_Symbol_ID) max; complete_symbol++)
	  {
	    *p_symbol++ = complete_symbol;
	  }
      }
  }
    bv_free (postdot_v);
    bv_free (complete_v);
}

@ Find the AHFA state in the argument,
creating it if it does not exist.
When it does not exist, insert it
in the sequence of states
and return |NULL|.
When it does exist, return a pointer to it.
@ @<Private function prototypes@> =
static inline AHFA assign_AHFA_state(
AHFA state_p, GTree* duplicates);
@ @<Function definitions@> =
static inline AHFA
assign_AHFA_state (AHFA sought_state, GTree* duplicates)
{
  const AHFA state_found = g_tree_lookup(duplicates, sought_state);
  if (state_found) return state_found;
  g_tree_insert(duplicates, sought_state, sought_state);
  return NULL;
}

@ @<Calculate the predicted rule vector for this state
and add the predicted AHFA state@> = {
guint item_ix;
Marpa_Symbol_ID postdot = -1; // Initialized to prevent GCC warning
for (item_ix = 0; item_ix < no_of_items_in_new_state; item_ix++) {
    postdot = Postdot_SYMID_of_AIM(item_list_for_new_state[item_ix]);
    if (postdot >= 0) break;
}
p_new_state->t_empty_transition = NULL;
if (postdot >= 0) { // If any item is not a completion ...
    Bit_Vector predicted_rule_vector
	= bv_shadow(matrix_row(prediction_matrix, (guint)postdot));
    for (item_ix = 0; item_ix < no_of_items_in_new_state; item_ix++) {
    // "or" the other non-complete items into the prediction rule vector
	postdot = Postdot_SYMID_of_AIM(item_list_for_new_state[item_ix]);
	if (postdot < 0) continue;
	bv_or_assign(predicted_rule_vector, 
	    matrix_row(prediction_matrix, (guint)postdot));
    }
    p_new_state->t_empty_transition = create_predicted_AHFA_state(g,
	predicted_rule_vector,
	 rule_by_sort_key,
	 &states,
	 duplicates); // Add the predicted rule
} }

@*0 Predicted AHFA States.
The method for building predicted AHFA states is optimized using
precomputed bit vectors.
This should be very fast,
but It is possible to think other methods might
be better, at least in some cases.  The bit vectors are $O(s)$ in length, where $s$ is the
size of the grammar, and so is the time complexity of the method used.
@ It may be possible to look at a list of
only the AHFA items actually present in each state,
which might be $O(\log s)$ in the average case.  An advantage of the bit vectors is they
implicitly perform a radix sort.
This would have to be performed explicitly for an enumerated
list of AHFA items, making the putative average case $O(\log s \cdot \log \log s)$.
@ In the worst case, however, the number of AHFA items in the predicted states is
$O(s)$, making the time complexity
of a list solution, $O(s \cdot \log s)$.
In normal cases,
the practical advantages of bit vectors are overwhelming and swamp the theoretical
time complexity.
The advantage of listing AHFA items is restricted to a putative "average" case,
and even there would not kick in until the grammars became very large.
My conclusion is that alternatives to the bit vector implementation deserve
further investigation, but that at present, and overall,
bit vectors appear clearly superior to the alternatives.
@ For the predicted states, I construct a symbol-by-rule matrix
of predictions.  First, I determine which symbols directly predict
others.  Then I compute the transitive closure.
Finally, I convert this to a symbol-by-rule matrix.
The symbol-by-rule matrix will be used in constructing the prediction
states.

@ @<Construct prediction matrix@> = {
    Bit_Matrix symbol_by_symbol_matrix = matrix_create(no_of_symbols, no_of_symbols);
    @<Initialize the symbol-by-symbol matrix@>@/
    transitive_closure(symbol_by_symbol_matrix);
    @<Create the prediction matrix from the symbol-by-symbol matrix@>@/
    matrix_free(symbol_by_symbol_matrix);
}

@ @<Initialize the symbol-by-symbol matrix@> =
{ Marpa_Rule_ID rule_id;
Marpa_Symbol_ID symid;
    AIM* items_by_rule = g->t_AHFA_items_by_rule;
    for (symid = 0; symid < (Marpa_Symbol_ID)no_of_symbols; symid++) {
	// If a symbol appears on a LHS, it predicts itself.
	SYM symbol = SYM_by_ID(g, symid);
	if (!SYMBOL_LHS_RULE_COUNT(symbol)) continue;
	matrix_bit_set(symbol_by_symbol_matrix,
	    (guint)symid, (guint)symid);
    }
    for (rule_id = 0; rule_id < (Marpa_Rule_ID)no_of_rules; rule_id++) {
	Marpa_Symbol_ID from, to;
        AIM item = items_by_rule[rule_id];
	    // Get the initial item for the rule
	RULE  rule;
	if (!item) continue; // Not all rules have items
	rule = item->t_production;
	from = LHS_ID_of_PRD(rule);
	to = Postdot_SYMID_of_AIM(item);
	if (to < 0) continue; // There is no symbol-to-symbol transition
	// for a completion item
	matrix_bit_set(symbol_by_symbol_matrix,
	    (guint)from, (guint)to); // Set a bit in the matrix
} }

@ At this point I have a full matrix showing which symbol implies a prediction
of which others.  To save repeated processing when building the AHFA prediction states,
I now convert it into a matrix from symbols to the rules they predict.
Specifically, if symbol |S1| predicts symbol |S2|, then symbol |S1|
predicts every rule
with |S2| on its LHS.
@<Create the prediction matrix from the symbol-by-symbol matrix@> = {
AIM* items_by_rule = g->t_AHFA_items_by_rule;
    Marpa_Symbol_ID from_symid;
    guint* sort_key_by_rule_id = g_new(guint, no_of_rules);
    guint no_of_predictable_rules = 0;
    @<Populate |sort_key_by_rule_id| with first pass value;
	calculate |no_of_predictable_rules|@>@/
    @<Populate |rule_by_sort_key|@>@/
    @<Populate |sort_key_by_rule_id| with second pass value@>@/
    @<Populate the prediction matrix@>@/
    g_free(sort_key_by_rule_id);
}

@ For creating prediction AHFA states, we need to have an ordering of rules
by their postdot symbol.
A "predictable rule" is one whose initial item has a postdot symbol.
The following facts hold:
\li A rule is predictable iff it is both used and non-nulling.
\li A rule is predictable iff it is a used rule which is not the nulling start rule.
\li A rule is predictable iff it has any item with a postdot symbol.
\par
Here we take a first pass at this, letting the value be the postdot symbol for
the predictable rules.
|G_MAXINT| is used for the others, so that they will sort high.
(|G_MAXINT| is used and not |G_MAXUINT|, because the sort routines
work with signed values.)
This first pass fully captures the order, but
our final result needs to be an unique ID for every "predictable rule",
so that it can be used as the index in a bit vector.
@<Populate |sort_key_by_rule_id| with first pass value;
calculate |no_of_predictable_rules|@> =
{
  Marpa_Rule_ID rule_id;
  for (rule_id = 0; rule_id < (Marpa_Rule_ID) no_of_rules; rule_id++)
    {
      AIM item = items_by_rule[rule_id];
      SYMID postdot;
      if (!item)
	goto NOT_A_PREDICTABLE_RULE;
      postdot = Postdot_SYMID_of_AIM (item);
      if (postdot < 0)
	goto NOT_A_PREDICTABLE_RULE;
      sort_key_by_rule_id[rule_id] = postdot;
      no_of_predictable_rules++;
      continue;
    NOT_A_PREDICTABLE_RULE:
      sort_key_by_rule_id[rule_id] = G_MAXINT;
    }
}

@ @<Populate |rule_by_sort_key|@> =
{ Marpa_Rule_ID rule_id;
for (rule_id = 0; rule_id < (Marpa_Rule_ID)no_of_rules; rule_id++) {
    rule_by_sort_key[rule_id] = RULE_by_ID(g, rule_id);
}
g_qsort_with_data(rule_by_sort_key, (gint)no_of_rules,
    sizeof(RULE), cmp_by_rule_sort_key,
    (gpointer)sort_key_by_rule_id);
}

@ @<Function definitions@> = static gint
cmp_by_rule_sort_key(gconstpointer ap,
	gconstpointer bp, gpointer user_data) {
    RULE a = *(RULE*)ap;
    RULE b = *(RULE*)bp;
    guint* sort_key_by_rule_id = (guint*)user_data;
    Marpa_Rule_ID a_id = a->t_id;
    Marpa_Rule_ID b_id = b->t_id;
    guint sort_key_a = sort_key_by_rule_id[a_id];
    guint sort_key_b = sort_key_by_rule_id[b_id];
    if (sort_key_a == sort_key_b) return a_id - b_id;
    return sort_key_a - sort_key_b;
}
@ @<Private function prototypes@> = static
gint cmp_by_rule_sort_key(gconstpointer ap,
	gconstpointer bp, gpointer user_data);

@ We have now sorted the rules into the final sort key order.
With this final version of the sort keys,
populate the index from rule id to sort key.
@<Populate |sort_key_by_rule_id| with second pass value@> = {
guint sort_key;
for (sort_key = 0; sort_key < no_of_rules; sort_key++) {
     RULE  rule = rule_by_sort_key[sort_key];
      sort_key_by_rule_id[rule->t_id] = sort_key;
} }

@ @<Populate the prediction matrix@> =
{
  prediction_matrix = matrix_create (no_of_symbols, no_of_predictable_rules);
  for (from_symid = 0; from_symid < (Marpa_Symbol_ID) no_of_symbols;
       from_symid++)
    {
      // for every row of the symbol-by-symbol matrix
      guint min, max, start;
      for (start = 0;
	   bv_scan (matrix_row
		    (symbol_by_symbol_matrix, (guint) from_symid), start,
		    &min, &max); start = max + 2)
	{
	  Marpa_Symbol_ID to_symid;
	  for (to_symid = min; to_symid <= (Marpa_Symbol_ID) max;
	       to_symid++)
	    {
	      // for every predicted symbol
	      SYM to_symbol = SYM_by_ID (g, to_symid);
	      GArray *lhs_rules = to_symbol->t_lhs;
	      guint ix, no_of_lhs_rules = lhs_rules->len;
	      for (ix = 0; ix < no_of_lhs_rules; ix++)
		{
		  // For every rule with that symbol on its LHS
		  Marpa_Rule_ID rule_with_this_lhs_symbol =
		    g_array_index (lhs_rules, Marpa_Rule_ID, ix);
		  guint sort_key =
		    sort_key_by_rule_id[rule_with_this_lhs_symbol];
		  if (sort_key >= no_of_predictable_rules)
		    continue;	/*
				   We only need to predict rules which have items */
		  matrix_bit_set (prediction_matrix, (guint) from_symid,
				  sort_key);
		  // Set the $(symbol, rule sort key)$ bit in the matrix
		}
	    }
	}
    }
}

@ @<Private function prototypes@> =
static AHFA
create_predicted_AHFA_state(
     struct marpa_g* g,
     Bit_Vector prediction_rule_vector,
     RULE* rule_by_sort_key,
     DQUEUE states_p,
     GTree* duplicates
     );
@ @<Function definitions@> =
static AHFA
create_predicted_AHFA_state(
     struct marpa_g* g,
     Bit_Vector prediction_rule_vector,
     RULE* rule_by_sort_key,
     DQUEUE states_p,
     GTree* duplicates
     ) {
AIM* item_list_for_new_state;
AHFA p_new_state;
guint item_list_ix = 0;
guint no_of_items_in_new_state = bv_count( prediction_rule_vector);
	if (no_of_items_in_new_state == 0) return NULL;
item_list_for_new_state = obstack_alloc (&g->t_obs,
	       no_of_items_in_new_state * sizeof (AIM));
{
  guint start, min, max;
  for (start = 0; bv_scan (prediction_rule_vector, start, &min, &max);
       start = max + 2)
    {				// Scan the prediction rule vector again, this time to populate the list
      guint rule_sort_key;
      for (rule_sort_key = min; rule_sort_key <= max; rule_sort_key++)
	{
	  /* Add the initial item for the predicted rule */
	  RULE rule = rule_by_sort_key[rule_sort_key];
	  item_list_for_new_state[item_list_ix++] =
	    g->t_AHFA_items_by_rule[rule->t_id];
	}
    }
}
p_new_state = DQUEUE_PUSH((*states_p), AHFAD);@/
    p_new_state->t_items = item_list_for_new_state;
    p_new_state->t_item_count = no_of_items_in_new_state;
    { AHFA queued_AHFA_state = assign_AHFA_state(p_new_state, duplicates);
        if (queued_AHFA_state) {
		 /* The new state would be a duplicate.
		 Back it out and return the one that already exists */
	    (void)DQUEUE_POP((*states_p), AHFAD);
	    obstack_free(&g->t_obs, item_list_for_new_state);
	    return queued_AHFA_state;
	}
    }
    // The new state was added -- finish up its data
    p_new_state->t_key.t_id = p_new_state - DQUEUE_BASE((*states_p), AHFAD);
    LV_AHFA_is_Predicted(p_new_state) = 1;
    p_new_state->t_has_completed_start_rule = 0;
    LV_Leo_LHS_ID_of_AHFA(p_new_state) = -1;
    p_new_state->t_empty_transition = NULL;
    p_new_state->t_to_ahfa_ary = to_ahfa_array_new(g);
    p_new_state->t_complete_symbol_count = 0;
    @<Calculate postdot symbols for predicted state@>@/
    return p_new_state;
}

@ @<Calculate postdot symbols for predicted state@> =
{
  guint symbol_count = SYM_Count_of_G (g);
  guint item_ix;
  guint no_of_postdot_symbols;
  Bit_Vector postdot_v = bv_create (symbol_count);
    for (item_ix = 0; item_ix < no_of_items_in_new_state; item_ix++)
      {
	AIM item = item_list_for_new_state[item_ix];
	SYMID postdot = Postdot_SYMID_of_AIM (item);
	if (postdot >= 0)
	  bv_bit_set (postdot_v, (guint) postdot);
      }
    if ((no_of_postdot_symbols = p_new_state->t_postdot_sym_count =
     bv_count (postdot_v)))
  {
    guint min, max, start;
    Marpa_Symbol_ID *p_symbol = p_new_state->t_postdot_symid_ary =
      obstack_alloc (&g->t_obs,
		     no_of_postdot_symbols * sizeof (SYMID));
    for (start = 0; bv_scan (postdot_v, start, &min, &max); start = max + 2)
      {
	Marpa_Symbol_ID postdot;
	for (postdot = (Marpa_Symbol_ID) min;
	     postdot <= (Marpa_Symbol_ID) max; postdot++)
	  {
	    *p_symbol++ = postdot;
	  }
      }
  }
    bv_free (postdot_v);
}

@** Transition Code.
@d To_AHFA_of_AHFA_by_SYMID(from_ahfa, id) ((from_ahfa)->t_to_ahfa_ary[id])
@d To_AHFA_of_EIM_by_SYMID(eim, id) To_AHFA_of_AHFA_by_SYMID(AHFA_of_EIM(eim), (id))

@ @<Private function prototypes@> = static inline
AHFA* to_ahfa_array_new(struct marpa_g* g);
@ @<Function definitions@> = static inline
AHFA* to_ahfa_array_new(struct marpa_g* g) {
    gint symbol_count = SYM_Count_of_G(g);
    gint symid = 0;
    AHFA* new_to_ahfa_array = g_malloc(symbol_count * sizeof(AHFA));
    while (symid < symbol_count) new_to_ahfa_array[symid++] = NULL; /*
        |g_malloc0| will not work because NULL is not guaranteed
	to be a bitwise zero. */
    return new_to_ahfa_array;
}

@ @<Function definitions@> = static inline
void AHFA_transition_add(AHFA from_ahfa, SYMID symid, AHFA to_ahfa)
{
    from_ahfa->t_to_ahfa_ary[symid] = to_ahfa;
}
@ @<Private function prototypes@> = static inline
void AHFA_transition_add(AHFA from_ahfa, SYMID symid, AHFA to_ahfa);

@** Populating the Terminal Boolean Vector.
@<Populate the Terminal Boolean Vector@> = {
    gint symbol_count = SYM_Count_of_G(g);
    gint symid;
    Bit_Vector bv_is_terminal = bv_create( (guint)symbol_count );
    g->t_bv_symid_is_terminal = bv_is_terminal;
    for (symid = 0; symid < symbol_count; symid++) {
      if (!SYMID_is_Terminal(g, symid)) continue;
      bv_bit_set(bv_is_terminal, (guint)symid);
    }
}

@** Recognizer (RECCE) Code.
@<Public incomplete structures@> =
struct marpa_r;
typedef struct marpa_r* RECCE;
@ @<Recognizer structure@> =
struct marpa_r {
@<Widely aligned recognizer elements@>@/
@<Int aligned recognizer elements@>@/
@<Bit aligned recognizer elements@>@/
};

@ @<Public function prototypes@> =
struct marpa_r* marpa_r_new( const struct marpa_g* const g );
@ The grammar must not be deallocated for the life of the
recognizer.
In the event of an error creating the recognizer,
|NULL| is returned and the error status
of the {\bf grammar} is set.
For this reason, the grammar is not |const|.
@<Function definitions@> =
struct marpa_r* marpa_r_new( const struct marpa_g* const g )
{ RECCE r;
    @<Return |NULL| on failure@>@/
    r = g_slice_new(struct marpa_r);
    r->t_grammar = g;
    @<Initialize recognizer obstack@>@;
    @<Initialize recognizer elements@>@;
    if (!G_is_Precomputed(g)) {
	R_ERROR("grammar not precomputed");
	return failure_indicator;
    }
   return r; }

@ @<Function definitions@> =
void marpa_r_free(struct marpa_r *r)
{
@<Destroy recognizer elements@>@;
if (r->t_sym_workarea) g_free(r->t_sym_workarea);
if (r->t_workarea2) g_free(r->t_workarea2);
@<Free working bit vectors for symbols@>@;
@<Destroy recognizer obstack@>@;
g_slice_free(struct marpa_r, r);
}
@ @<Public function prototypes@> =
void marpa_r_free(struct marpa_r *r);

@*0 The Recognizer ID.
A unique ID for the recognizer.
This must be unique not just per-thread,
but process-wide.
The counter which tracks recognizer ID's
(|next_recce_id|)
is (at this writing) the only global
non-constant, and requires special handling to
keep |libmarpa| MT-safe.
(|next_recce_id|) is accessed only via
|glib|'s special atomic operations.
@ @<Int aligned recognizer elements@> = gint t_id;
@ @<Public typedefs@> = typedef gint Marpa_Recognizer_ID;
@ @<Private global variables@> = static gint next_recce_id = 1;
@ @<Initialize recognizer elements@> =
r->t_id = g_atomic_int_exchange_and_add(&next_recce_id, 1);
@ @<Function definitions@> =
gint marpa_r_id(struct marpa_r* r) { return r->t_id; }
@ @<Public function prototypes@> =
gint marpa_r_id(struct marpa_r* r);

@*0 The Grammar for the Recognizer.
Initialized in |marpa_r_new|.
@d G_of_R(r) ((r)->t_grammar)
@d AHFA_Count_of_R(r) AHFA_Count_of_G(G_of_R(r))
@ @<Widely aligned recognizer elements@> = const struct marpa_g *t_grammar;

@*0 Recognizer Phase.
The recognizer has phases, such as "input"
and "evaluation",
and states, such as "exhausted".
The main distinction is that the
phases are mutually exclusive---%
entering one means leaving another.
"Exhausted" is not a phase, because when a parser is
exhausted it may gone into the evaluation phase, then
return to the input phase,
All that time it will remain "exhausted".
@<Public typedefs@> =
enum enum_phase {
    no_such_phase = 0, // 0 is never a valid phase
    initial_phase,
    input_phase,
    evaluation_phase,
    error_phase
};
typedef enum enum_phase Marpa_Phase;
@ @d Phase_of_R(r) ((r)->t_phase)
@d LV_Phase_of_R(r) Phase_of_R(r)
@<Int aligned recognizer elements@> = 
Marpa_Phase t_phase;
@ @<Initialize recognizer elements@> =
LV_Phase_of_R(r) = initial_phase;
@ @<Public function prototypes@> =
Marpa_Phase marpa_phase(struct marpa_r* r);
@ @<Function definitions@> =
Marpa_Phase marpa_phase(struct marpa_r* r)
{ return Phase_of_R(r); }

@*0 Earley Set Container.
@d First_ES_of_R(r) ((r)->t_first_earley_set)
@d LV_First_ES_of_R(r) First_ES_of_R(r)
@<Widely aligned recognizer elements@> =
ES t_first_earley_set;
ES t_latest_earley_set;
EARLEME t_current_earleme;
@ @<Initialize recognizer elements@> =
r->t_first_earley_set = NULL;
r->t_latest_earley_set = NULL;
r->t_current_earleme = -1;
@ @<Destroy recognizer elements@> =
{
  if (r->t_earley_item_tree)
    g_tree_destroy (r->t_earley_item_tree);
}

@*0 Current Earleme.
@d Latest_ES_of_R(r) ((r)->t_latest_earley_set)
@d LV_Latest_ES_of_R(r) Latest_ES_of_R(r)
@d Current_Earleme_of_R(r) ((r)->t_current_earleme)
@d LV_Current_Earleme_of_R(r) (Current_Earleme_of_R(r))
@ @<Public function prototypes@> =
guint marpa_current_earleme(struct marpa_r* r);
@ @<Function definitions@> =
guint marpa_current_earleme(struct marpa_r* r)
{ return Current_Earleme_of_R(r); }

@ @d Current_ES_of_R(r) current_es_of_r(r)
@<Private function prototypes@> =
static inline ES current_es_of_r(RECCE r);
@ @<Function definitions@> =
static inline ES current_es_of_r(RECCE r)
{
    const ES latest = Latest_ES_of_R(r);
    if (Earleme_of_ES(latest) == Current_Earleme_of_R(r)) return latest;
    return NULL;
}

@*0 Earley Set Warning Threshold.
@d DEFAULT_EIM_WARNING_THRESHOLD (100)
@<Int aligned recognizer elements@> = guint t_earley_item_warning_threshold;
@ @<Initialize recognizer elements@> =
r->t_earley_item_warning_threshold = MAX(DEFAULT_EIM_WARNING_THRESHOLD, AIM_Count_of_G(g)*2);
@ @<Public function prototypes@> =
guint marpa_earley_item_warning_threshold(struct marpa_r* r);
@ @<Function definitions@> =
guint marpa_earley_item_warning_threshold(struct marpa_r* r)
{ return r->t_earley_item_warning_threshold; }

@ @<Public function prototypes@> =
gboolean marpa_earley_item_warning_threshold_set(struct marpa_r*r, guint threshold);
@ Returns |TRUE| on success,
|FALSE| on failure.
@<Function definitions@> =
gboolean marpa_earley_item_warning_threshold_set(struct marpa_r*r, guint threshold)
{
    r->t_earley_item_warning_threshold = threshold == 0 ? EIM_FATAL_THRESHOLD : threshold;
    return TRUE;
}

@*0 Furthest Earleme.
The "furthest" or highest-numbered earleme.
This is the earleme of the last Earley set that contains anything.
Marpa allows variable length tokens,
so it needs to track how far out tokens might be found.
No complete or predicted Earley item will be found after the current earleme.
@d Furthest_Earleme_of_R(r) ((r)->t_furthest_earleme)
@d LV_Furthest_Earleme_of_R(r) Furthest_Earleme_of_R(r)
@<Int aligned recognizer elements@> = Marpa_Earleme t_furthest_earleme;
@ @<Initialize recognizer elements@> = r->t_furthest_earleme = 0;
@ @<Public function prototypes@> =
guint marpa_furthest_earleme(struct marpa_r* r);
@ @<Function definitions@> =
guint marpa_furthest_earleme(struct marpa_r* r)
{ return Furthest_Earleme_of_R(r); }

@*0 Symbol Workarea.
This is used in the completion
phase for each Earley set.
It is used in building the list of postdot items,
and when building the Leo items.
It is sized to hold one |gpointer| for
every symbol.
@.To Do@>
It may be possible to free this space when the recognition phase
is finished.
@<Widely aligned recognizer elements@> = gpointer* t_sym_workarea;
@ @<Initialize recognizer elements@> = r->t_sym_workarea = NULL;
@ @<Allocate symbol workarea@> =
    r->t_sym_workarea = g_malloc(sym_workarea_size);

@*0 Workarea 2.
This is used in the completion
phase for each Earley set.
when building the Leo items.
It is sized to hold two |gpointer|'s for
every symbol.
@.To Do@>
It may be possible to free this space when the recognition phase
is finished.
@<Widely aligned recognizer elements@> = gpointer* t_workarea2;
@ @<Initialize recognizer elements@> = r->t_workarea2 = NULL;
@ @<Allocate recognizer workareas@> =
{
  const guint sym_workarea_size = sizeof (gpointer) * symbol_count_of_g;
  @<Allocate symbol workarea@>@;
  r->t_workarea2 = g_malloc(2u * sym_workarea_size);
}

@*0 Working Bit Vectors for Symbols.
These are two bit vectors, sized to the number of symbols
in the grammar,
for utility purposes.
They are used in the completion
phase for each Earley set,
to keep track of the new postdot items and
Leo items.
@.To Do@>
It may be possible to free this space when the recognition phase
is finished.
@<Widely aligned recognizer elements@> =
Bit_Vector t_bv_sym;
Bit_Vector t_bv_sym2;
Bit_Vector t_bv_sym3;
@ @<Initialize recognizer elements@> =
r->t_bv_sym = NULL;
r->t_bv_sym2 = NULL;
r->t_bv_sym3 = NULL;
@ @<Allocate recognizer's bit vectors for symbols@> = {
  r->t_bv_sym = bv_create( (guint)symbol_count_of_g );
  r->t_bv_sym2 = bv_create( (guint)symbol_count_of_g );
  r->t_bv_sym3 = bv_create( (guint)symbol_count_of_g );
}
@ @<Free working bit vectors for symbols@> =
if (r->t_bv_sym) bv_free(r->t_bv_sym);
if (r->t_bv_sym2) bv_free(r->t_bv_sym2);
if (r->t_bv_sym3) bv_free(r->t_bv_sym3);

@*0 Expected Symbol Boolean Vector.
A boolean vector by symbol ID,
with the bits set if the symbol is expected
at the current earleme.
This vector is not size until input starts.
When the recognizer is created,
this bit vector is initialized to |NULL| so that the destructor
can tell if there is a bit vector to be freed.
@<Widely aligned recognizer elements@> = Bit_Vector t_bv_symid_is_expected;
@ @<Initialize recognizer elements@> = r->t_bv_symid_is_expected = NULL;
@ @<Allocate recognizer's bit vectors for symbols@> = 
    r->t_bv_symid_is_expected = bv_create( (guint)symbol_count_of_g );
@ @<Free working bit vectors for symbols@> =
if (r->t_bv_symid_is_expected) { bv_free(r->t_bv_symid_is_expected); }
@ Returns |-2| if there was a failure.
There is a check that the expectations of this
function and its caller about size of the |GArray| elements match.
This is a check worth making.
Mistakes happen,
a mismatch might arise as a portability issue,
and if I do not "fail fast" here the ultimate problem
could be very hard to debug.
@<Public function prototypes@> =
gint marpa_terminals_expected(struct marpa_r* r, GArray* result);
@ @<Function definitions@> =
gint marpa_terminals_expected(struct marpa_r* r, GArray* result)
{
    @<Return |-2| on failure@>@;
    guint min, max, start;
    @<Fail recognizer if |GArray| elements are not |sizeof(gint)|@>@;
    g_array_set_size(result, 0);
    for (start = 0; bv_scan (r->t_bv_symid_is_expected, start, &min, &max);
	 start = max + 2)
      {
	gint symid;
	for (symid = (gint) min; symid <= (gint) max; symid++)
	  {
	    g_array_append_val (result, symid);
	  }
      }
    return (gint)result->len;
}

@*0 Tracing.
A boolean, set if we are tracing earley sets.
If set, a |GTree| is used to allow fast lookup
of earley sets by earleme.
Keeping this tree takes $O(n \log n)$ time,
which means that the grammar's time complexity becomes
$O( s(n) \cdot n \log n )$, where $s(n)$ is the time it takes to
process an earley set.

Without tracing the time complexity is
$O( s(n) \cdot n )$, so tracing worsens the time complexity by
a factor of $\log n$.
Unless otherwise stated,
time complexity results elsewhere in this document
assume that tracing is not enabled.
@ @<Widely aligned recognizer elements@> =
GTree* t_earley_item_tree;
@
@<Initialize recognizer elements@> =
r->t_earley_item_tree = g_tree_new(trace_earley_item_cmp);

@*0 Leo-Related Booleans.
@*1 Turning Leo Logic Off and On.
A trace flag, set if we are using Leo items.
This flag is set by default.
It has two uses.
@ This flag is very useful for testing.
Since Leo items do not affect function, only effiency,
it is possible for the Leo logic to be broken or
disabled without most tests noticiing.
To make sure the Leo logic is intact,
one of |libmarpa|'s tests runs one pass
with Leo items off and another with Leo items on
and compares them.
@ This flag also allows the Leo logic
to be turned off in certain cases in which the Leo logic
actually slows things down.
The Leo logic could be turned off if the user knows there is
no right recursion, although the actual gain,
would typically be small or not measurable.
@ A real gain would occur in the case of highly ambiguous
grammars, all or most of whose parses are actually evaluated.
Since those Earley items eliminated by the Leo logic
are actually recreated on an as-needed basis in the evaluation
phase, in cases when most of the Earley items are needed
for evaluation, the Leo logic would be eliminated Earley
items only to have to add most of them later.
In these cases,
the Leo logic would impose a small overhead.
@ The author's current view is that it is best
to start by assuming that the Leo logic should
be left on.
In the rare event, that it turns out that the Leo
logic is counter-productive,
this flag can be used to test if turning the Leo
logic off is helpful.
@ It should be borne in mind that even when the Leo logic
imposes a small cost in typical cases,
it may act as a safeguard.
The time complexity explosions prevented by Leo logic can
easily mean the difference between an impractical computation
and a practical one.
In most applications, it is worth incurring an small
overhead in the average case to prevent failures,
even rare ones.
@ There are two booleans.
One is a flag that can be set and
unset externally,
indicating the application's intention to use Leo logic.
An internal boolean tracks whether the Leo logic is
actually enabled at any given point.
@ The reason for having two booleans
is that the Leo logic is only turned
on once Earley set 0 is complete.
While Earley set 0 is being processed the internal flag will always
be unset, while the external flag may be set or unset, as the user
decided.
After Earley set 0 is complete, both booleans will have the same value.
@<Bit aligned recognizer elements@> =
unsigned int t_use_leo_flag:1;
unsigned int t_is_using_leo:1;
@ @<Initialize recognizer elements@> =
r->t_use_leo_flag = 1;
r->t_is_using_leo = 0;
@ Returns 1 if the "use Leo" flag is set,
0 if not,
and |-2| if there was an error.
@<Public function prototypes@> =
gboolean marpa_is_use_leo(struct marpa_r* r);
@ @<Function definitions@> =
gint marpa_is_use_leo(struct marpa_r* r)
{
   @<Return |-2| on failure@>@/
    @<Fail if recognizer has fatal error@>@;
    return r->t_use_leo_flag ? 1 : 0;
}
@ Returns |TRUE| on success,
|FALSE| on failure.
@<Function definitions@> =
gboolean marpa_is_use_leo_set(
struct marpa_r*r, gboolean value)
{
   @<Return |FALSE| on failure@>@/
    @<Fail if recognizer has fatal error@>@;
    r->t_use_leo_flag = value;
    return TRUE;
}
@ @<Public function prototypes@> =
gboolean marpa_is_use_leo_set( struct marpa_r*r, gboolean value);

@*1 Is The Parser Exhausted?.
A parser is "exhausted" if it cannot accept any more input.
Both successful and failed parses can be "exhausted".
In many grammars,
the parse is always exhausted as soon as it succeeds.
And even if the parse is exhausted at a point
where there is no good parse, 
there may be good parses at earlemes prior to the
earleme at which the parse became exhausted.
@d R_is_Exhausted(r) ((r)->t_is_exhausted)
@d LV_R_is_Exhausted(r) R_is_Exhausted(r)
@<Bit aligned recognizer elements@> = unsigned int t_is_exhausted:1;
@ @<Initialize recognizer elements@> = r->t_is_exhausted = 0;
@ Exhaustion is a boolean, not a phase.
Once exhausted a parse stays exhausted,
even though the phase may change.
@<Public function prototypes@> =
gboolean marpa_is_exhausted(struct marpa_r* r);
@ @<Function definitions@> =
gint marpa_is_exhausted(struct marpa_r* r)
{
   @<Return |-2| on failure@>@/
    @<Fail if recognizer has fatal error@>@;
    return r->t_is_exhausted ? 1 : 0;
}

@*1 Is Leo Expansion in Progress?.
This boolean indicates whether we are in the process of expanding
Leo items into Earley items.
It's use by the logic which warns
when the Earley item warning threshold is exceeded.
Leo expansion is expected to add a lot of Earley items to a single
Earley set, so the Earley item "warning threshold exceeded"
message is disable during Leo expansion.
@<Bit aligned recognizer elements@> =
unsigned int t_is_leo_expanding:1;
@ @<Initialize recognizer elements@> =
r->t_is_leo_expanding = 0;

@*0 The Recognizer's Context.
As in the grammar,
The "context" is a hash of miscellaneous data,
by keyword,
whose
purpose is to 
provide callbacks with
data about the recognizer's
state which is not conveniently
available in other forms.
@d Context_of_R(r) ((r)->t_context)
@<Widely aligned recognizer elements@> = GHashTable* t_context;
@ @<Initialize recognizer elements@> =
r->t_context = g_hash_table_new_full( g_str_hash, g_str_equal, NULL, g_free );
@ @<Destroy recognizer elements@> = g_hash_table_destroy(Context_of_R(r));

@ Add an integer to the context.
The const qualifier on the key is deliberately discarded.
As implemented, the keys are treated as const's by
|g_hash_table_insert|, but the compiler can't know
that is my intention.
For type safety, I do want to keep the |const|
qualifier in other contexts.
@<Function definitions@> =
static inline
void r_context_int_add(struct marpa_r* r, const gchar* key, gint payload)
{
    struct marpa_context_int_value* value = g_new(struct marpa_context_int_value, 1);
    value->t_type = MARPA_CONTEXT_INT;
    value->t_data = payload;
    g_hash_table_insert(Context_of_R(r), (gpointer)key, value);
}
@ @<Private function prototypes@> =
static inline
void r_context_int_add(struct marpa_r* r, const gchar* key, gint value);
@ @<Function definitions@> =
static inline
void r_context_const_add(struct marpa_r* r, const gchar* key, const gchar* payload)
{
    struct marpa_context_const_value* value = g_new(struct marpa_context_const_value, 1);
    value->t_type = MARPA_CONTEXT_CONST;
    value->t_data = payload;
    g_hash_table_insert(Context_of_R(r), (gpointer)key, value);
}
@ @<Private function prototypes@> =
static inline
void r_context_const_add(struct marpa_r* r, const gchar* key, const gchar* value);

@ Clear the current context.
Used to create a "clean slate" in the context.
@<Function definitions@> =
static inline void r_context_clear(struct marpa_r* r) {
    g_hash_table_remove_all(Context_of_R(r)); }
@ @<Private function prototypes@> =
static inline void r_context_clear(struct marpa_r* r);

@ @<Function definitions@> =
union marpa_context_value* marpa_r_context_value(struct marpa_r* r, const gchar* key)
{ return g_hash_table_lookup(Context_of_R(r), key); }
@ @<Public function prototypes@> =
union marpa_context_value* marpa_r_context_value(struct marpa_r* r, const gchar* key);

@*0 The Recognizer Obstack.
Create an obstack with the lifetime of the recognizer.
This is a very efficient way of allocating memory which won't be
resized and which will have the same lifetime as the recognizer.
@<Widely aligned recognizer elements@> = struct obstack t_obs;
@ @<Initialize recognizer obstack@> = obstack_init(&r->t_obs);
@ @<Destroy recognizer obstack@> = obstack_free(&r->t_obs, NULL);

@*0 The Recognizer's Error ID.
This is an error flag for the recognizer.
Error status is not necessarily cleared
on successful return, so that
it is only valid when an external
function has indicated there is an error,
and becomes invalid again when another external method
is called on the recognizer.
Checking it at other times may reveal "stale" error
messages.
@ @<Widely aligned recognizer elements@> =
Marpa_Error_ID t_error;
Marpa_Error_ID t_fatal_error;
@ @<Initialize recognizer elements@> =
r->t_error = NULL;
r->t_fatal_error = NULL;
@ There is no destructor.
The error strings are assummed to be
{\bf not} error messages, but "cookies".
These cookies are constants residing in static memory
(which may be read-only depending on implementation).
They cannot and should not be de-allocated.
@ @<Function definitions@> =
Marpa_Error_ID marpa_r_error(const struct marpa_r* r)
{ return r->t_error ? r->t_error : "unknown error"; }
@ @<Public function prototypes@> =
Marpa_Error_ID marpa_r_error(const struct marpa_r* r);

@** Earlemes.
In most parsers, the input is modeled as a token stream ---
a sequence of tokens.
In this model the idea of location is not complex.
The first token is at location 0, the second at location 1,
etc.
@ Marpa allows ambiguous and variable length tokens, and requires
a more flexible idea of location, with a unit of length.
The unit of token length in Marpa is called an Earleme.
The locations themselves are often called earlemes.
@ |EARLEME_THRESHOLD| is less than |G_MAXINT| so that
I can prevent overflow without getting fancy -- overflow
by addition is impossible as long as earlemes are below
the threshold.
@ I considered defining earlemes as |glong| or |gint64|.
My thought on the matter is that machines with 32-bit int's
will in a not very long time
become museum pieces.
And in the meantime this
definition of |EARLEME_THRESHOLD| probably allows as large as
parse as the memories on those machines will be
able to handle.
@d EARLEME_THRESHOLD (G_MAXINT/4)
@<Public typedefs@> = typedef gint Marpa_Earleme;
@ @<Private typedefs@> = typedef Marpa_Earleme EARLEME;

@** Earley Set (ES) Code.
@<Public typedefs@> = typedef gint Marpa_Earley_Set_ID;
@ @d Next_ES_of_ES(set) ((set)->t_next_earley_set)
@d LV_Next_ES_of_ES(set) Next_ES_of_ES(set)
@d Postdot_SYM_Count_of_ES(set) ((set)->t_postdot_sym_count)
@d First_PIM_of_ES_by_SYMID(set, symid) (first_pim_of_es_by_symid((set), (symid)))
@d PIM_SYM_P_of_ES_by_SYMID(set, symid) (pim_sym_p_find((set), (symid)))
@<Private incomplete structures@> =
struct s_earley_set;
typedef struct s_earley_set *ES;
typedef const struct s_earley_set *ES_Const;
struct s_earley_set_key;
typedef struct s_earley_set_key *ESK;
@ @<Private structures@> =
struct s_earley_set_key {
    EARLEME t_earleme;
};
typedef struct s_earley_set_key ESK_Object;
@ @<Private structures@> =
struct s_earley_set {
    ESK_Object t_key;
    gint t_postdot_sym_count;
    @<Int aligned Earley set elements@>@;
    union u_postdot_item** t_postdot_ary;
    ES t_next_earley_set;
    @<Widely aligned Earley set elements@>@/
};

@*0 Earley Item Container.
@d EIM_Count_of_ES(set) ((set)->t_eim_count)
@d LV_EIM_Count_of_ES(set) EIM_Count_of_ES(set)
@<Int aligned Earley set elements@> =
gint t_eim_count;
@ @d EIMs_of_ES(set) ((set)->t_earley_items)
@d LV_EIMs_of_ES(set) EIMs_of_ES(set)
@<Widely aligned Earley set elements@> =
EIM* t_earley_items;

@*0 Ordinal.
The ordinal of the Earley set---
its number in sequence.
It is different from the earleme, because there may be
gaps in the earleme sequence.
There are never gaps in the sequence of ordinals.
@d ES_Count_of_R(r) ((r)->t_earley_set_count)
@d Ord_of_ES(set) ((set)->t_ordinal)
@<Int aligned Earley set elements@> =
    gint t_ordinal;
@ @d ES_Ord_is_Valid(r, ordinal)
    ((ordinal) >= 0 && (ordinal) < ES_Count_of_R(r))
@<Int aligned recognizer elements@> =
gint t_earley_set_count;
@ @<Initialize recognizer elements@> =
r->t_earley_set_count = 0;

@*0 Constructor.
@<Private function prototypes@> =
static inline ES earley_set_new (RECCE r, EARLEME id);
@ @<Function definitions@> =
static inline ES
earley_set_new( RECCE r, EARLEME id)
{
  ESK_Object key;
  ES set;
  set = obstack_alloc (&r->t_obs, sizeof (*set));
  key.t_earleme = id;
  set->t_key = key;
  set->t_postdot_ary = NULL;
  set->t_postdot_sym_count = 0;
  LV_EIM_Count_of_ES(set) = 0;
  set->t_ordinal = r->t_earley_set_count++;
  LV_EIMs_of_ES(set) = NULL;
  LV_Next_ES_of_ES(set) = NULL;
  @<Initialize Earley set PSL data@>@/
  return set;
}

@*0 Destructor.
@<Destroy recognizer elements@> =
{
  ES set;
  for (set = First_ES_of_R (r); set; set = Next_ES_of_ES (set))
    {
      if (EIMs_of_ES(set))
	g_free (EIMs_of_ES(set));
    }
}

@*0 ID of Earley Set.
@d Earleme_of_ES(set) ((set)->t_key.t_earleme)

@*0 Trace Functions.
Many of the
trace functions use
a "trace Earley set" which is
tracked on a per-recognizer basis.
The "trace Earley set" is tracked separately
from the current Earley set for the parse.
The two may coincide, but should not be confused.
@<Widely aligned recognizer elements@> =
struct s_earley_set* t_trace_earley_set;
@ @<Initialize recognizer elements@> =
r->t_trace_earley_set = NULL;

@ @<Public function prototypes@> =
Marpa_Earleme marpa_trace_earleme(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Earleme marpa_trace_earleme(struct marpa_r *r)
{
  @<Return |-2| on failure@>@;
  ES trace_earley_set = r->t_trace_earley_set;
  @<Fail if recognizer initial@>@;
  if (!trace_earley_set) {
      R_ERROR("no trace es");
      return failure_indicator;
  }
  return Earleme_of_ES(trace_earley_set);
}

@ Given the ID (ordinal) of an Earley set,
return the earleme.
In the default, token-stream model, ID and earleme
are the same, but this is not the case in other input
models.
If the ordinal is out of bounds, this function
returns -1, which can be treated as a soft failure.
On other problems, it returns -2.
@<Public function prototypes@> =
Marpa_Earleme marpa_earleme(struct marpa_r* r, Marpa_Earley_Set_ID set_id);
@ @<Function definitions@> =
Marpa_Earleme marpa_earleme(struct marpa_r* r, Marpa_Earley_Set_ID set_id)
{
    const gint es_does_not_exist = -1;
    @<Return |-2| on failure@>@;
    ES* earley_set_p;
    @<Fail if recognizer initial@>@;
    @<Fail if recognizer has fatal error@>@;
    if (set_id < 0) {
        R_ERROR("invalid es ordinal");
	return failure_indicator;
    }
    r_update_earley_sets(r);
    if (set_id >= DSTACK_LENGTH(r->t_earley_set_stack)) {
        return es_does_not_exist;
    }
    earley_set_p = P_ES_of_R_by_Ord(r, set_id);
    return Earleme_of_ES(*earley_set_p);
}

@ Note that this trace function returns the earley set size
of the {\bf current earley set}.
@ @^To Do@>  To Do: Change this so it takes an ordinal of
the set as an argument.
@<Public function prototypes@> =
gint marpa_current_earley_set_size(struct marpa_r *r);
@ @<Function definitions@> =
gint marpa_current_earley_set_size(struct marpa_r *r)
{
    @<Return |-2| on failure@>@;
    @<Fail if recognizer initial@>@;
    @<Fail if recognizer has fatal error@>@;
  return EIM_Count_of_ES(Current_ES_of_R(r));
}

@** Earley Item (EIM) Code.
@ {\bf Optimization Principles:}
\li Optimization should favor unambiguous grammars,
but not heavily penalize ambiguous grammars.
\li Optimization should favor mildly ambiguous grammars,
but not heavily penalize very ambiguous grammars.
\li Optimization should focus on saving space,
perhaps even if at a slight cost in time.
@ Space savings are important
because in practical applications
there can easily be many millions of
Earley items and links.
If there are 1M copies of a structure,
each byte saved is a 1M saved.

@ The solution arrived at is to optimize for Earley items
with a single source, storing that source in the item
itself.
For Earley item with multiple sources, a special structure
of linked lists is used.
When a second source is added,
the first source is copied into the lists,
and its original space used for pointers to the linked
lists.
@ This solution is optimized both
for the unambiguous case,
and for adding the third and additional
sources.
The only awkwardness takes place
when the second source is added, and the first one must
be recopied to make way for pointers to the linked lists.
@d EIM_FATAL_THRESHOLD (G_MAXINT/4)
@d Complete_SYMIDARY_of_EIM(item) 
    Complete_SYMIDARY_of_AHFA(AHFA_of_EIM(item))
@d Complete_SYM_Count_of_EIM(item)
    Complete_SYM_Count_of_AHFA(AHFA_of_EIM(item))
@d Leo_LHS_ID_of_EIM(eim) Leo_LHS_ID_of_AHFA(AHFA_of_EIM(eim))
@ It might be slightly faster if this boolean is memoized in the Earley item
when the Earley item is initialized.
@d Earley_Item_is_Completion(item)
    (Complete_SYM_Count_of_EIM(item) > 0)
@<Public typedefs@> = typedef gint Marpa_Earley_Item_ID;
@ The ID of the Earley item is per-Earley-set, so that
to uniquely specify the Earley item you must also specify
the Earley set.
@d ES_of_EIM(item) ((item)->t_key.t_set)
@d Ord_of_EIM(item) ((item)->t_ordinal)
@d LV_Ord_of_EIM(item) Ord_of_EIM(item)
@d Earleme_of_EIM(item) Earleme_of_ES(ES_of_EIM(item))
@d AHFAID_of_EIM(item) (ID_of_AHFA(AHFA_of_EIM(item)))
@d AHFA_of_EIM(item) ((item)->t_key.t_state)
@d Origin_Earleme_of_EIM(item) (Earleme_of_ES(Origin_of_EIM(item)))
@d Origin_of_EIM(item) ((item)->t_key.t_origin)
@<Private incomplete structures@> =
struct s_earley_item;
typedef struct s_earley_item* EIM;
typedef const struct s_earley_item* EIM_Const;
struct s_earley_item_key;
typedef struct s_earley_item_key* EIK;

@ @<Earley item structure@> =
struct s_earley_item_key {
     AHFA t_state;
     ES t_origin;
     ES t_set;
};
typedef struct s_earley_item_key EIK_Object;
struct s_earley_item {
     EIK_Object t_key;
     union u_source_container t_container;
     gint t_ordinal;
     @<Bit aligned Earley item elements@>@/
};
typedef struct s_earley_item EIM_Object;

@*0 Constructor.
Find an Earley item object, creating it if it does not exist.
Only in a couple of cases per parse (in AHFA state 0),
do we already
know that the Earley item is unique in the set.
These are not worth optimizing for.
@<Private function prototypes@> =
static inline EIM earley_item_create(const RECCE r,
    const EIK_Object key);
@ @<Function definitions@> =
static inline EIM earley_item_create(const RECCE r,
    const EIK_Object key)
{
  @<Return |NULL| on failure@>@;
  EIM new_item;
  EIM* top_of_work_stack;
  const ES set = key.t_set;
  const guint count = ++LV_EIM_Count_of_ES(set);
  @<Check count against Earley item thresholds@>@;
  new_item = obstack_alloc (&r->t_obs, sizeof (*new_item));
  new_item->t_key = key;
  new_item->t_source_type = NO_SOURCE;
  LV_Ord_of_EIM(new_item) = count - 1;
  LV_EIM_is_Leo_Expanded(new_item) = 1; /* Will be unset when
     and if a Leo link is added */
  top_of_work_stack = WORK_EIM_PUSH(r);
  *top_of_work_stack = new_item;
  g_tree_insert(r->t_earley_item_tree, new_item, new_item);
  return new_item;
}

@ @<Private function prototypes@> =
static inline
EIM old_earley_item_assign (const RECCE r, const ES set, const ES origin, const AHFA state);
@ @<Function definitions@> =
static inline EIM old_earley_item_assign (
    const RECCE r, const ES set, const ES origin, const AHFA state)
{
    EIM item;
    EIK_Object key;
    key.t_origin = origin;
    key.t_state = state;
    key.t_set = set;
    item = g_tree_lookup(r->t_earley_item_tree, &key);
    if (item) return item;
    return earley_item_create(r, key);
}

@ @<Private function prototypes@> =
static inline
EIM earley_item_assign (const RECCE r, const ES set, const ES origin, const AHFA state);
@ @<Function definitions@> =
static inline EIM
earley_item_assign (const RECCE r, const ES set, const ES origin,
		    const AHFA state)
{
  EIK_Object key;
  EIM eim;
  PSL psl;
  AHFAID ahfa_id = ID_of_AHFA(state);
  PSL *psl_owner = &Dot_PSL_of_ES (origin);
  if (!*psl_owner)
    {
      psl_claim (psl_owner, Dot_PSAR_of_R(r));
    }
  psl = *psl_owner;
  eim = PSL_Datum (psl, ahfa_id);
  if (eim
      && Earleme_of_EIM (eim) == Earleme_of_ES (set)
      && Earleme_of_ES (Origin_of_EIM (eim)) == Earleme_of_ES (origin))
    {
      return eim;
    }
  key.t_origin = origin;
  key.t_state = state;
  key.t_set = set;
  eim = earley_item_create (r, key);
  LV_PSL_Datum (psl, ahfa_id) = eim;
  return eim;
}

@ The fatal threshold always applies.
The warning threshold does not count against items added by a Leo expansion.
@<Check count against Earley item thresholds@> = 
if (count >= r->t_earley_item_warning_threshold)
    {
      if (G_UNLIKELY(count >= EIM_FATAL_THRESHOLD))
      { /* Set the recognizer to a fatal error */
	  r_context_clear (r);
	  R_FATAL("eim count exceeds fatal threshold");
	  return failure_indicator;
	}
      if (!r->t_is_leo_expanding) {
	  r_context_clear (r);
	  r_message (r, "earley item count exceeds threshold");
	}
}

@*0 Destructor.
No destructor.  All earley item elements are either owned by other objects.
The Earley item itself is on the obstack.

@*0 Comparison Function.
This must be valid for comparing Earley item keys,
so it does not use any non-key elements.
This function is for comparison of Earley items in the
|GTree| used for tracing.
@<Private function prototypes@> =
static inline gint trace_earley_item_cmp(gconstpointer ap, gconstpointer bp);
@ @<Function definitions@> =
static inline gint trace_earley_item_cmp(gconstpointer ap, gconstpointer bp)
{
  const EIM_Object* eim_a = ap;
  const EIM_Object* eim_b = bp;
  gint subkey = Earleme_of_EIM (eim_a) - Earleme_of_EIM (eim_b);
  if (subkey) return subkey;
  return earley_item_cmp(ap, bp, 0);
}
@ @<Private function prototypes@> =
static inline gint earley_item_cmp(gconstpointer ap,
    gconstpointer bp,
    gpointer user_data @, G_GNUC_UNUSED);
@ @<Function definitions@> =
static inline gint earley_item_cmp (gconstpointer ap,
		 gconstpointer bp, gpointer user_data @, G_GNUC_UNUSED)
{
  const struct s_earley_item* eim_a = ap;
  const struct s_earley_item* eim_b = bp;
  gint subkey =
    AHFAID_of_EIM (eim_a) -
    AHFAID_of_EIM (eim_b);
  if (subkey) return subkey;
  return Origin_Earleme_of_EIM (eim_a) - Origin_Earleme_of_EIM (eim_b);
}

@*0 Source of the Earley Item.
@d NO_SOURCE (0U)
@d SOURCE_IS_TOKEN (1U)
@d SOURCE_IS_COMPLETION (2U)
@d SOURCE_IS_LEO (3U)
@d SOURCE_IS_AMBIGUOUS (4U)
@d Source_Type_of_EIM(item) ((item)->t_source_type)
@d Earley_Item_has_No_Source(item) ((item)->t_source_type == NO_SOURCE)
@d Earley_Item_has_Token_Source(item) ((item)->t_source_type == SOURCE_IS_TOKEN)
@d Earley_Item_has_Complete_Source(item) ((item)->t_source_type == SOURCE_IS_COMPLETION)
@d Earley_Item_has_Leo_Source(item) ((item)->t_source_type == SOURCE_IS_LEO)
@d Earley_Item_is_Ambiguous(item) ((item)->t_source_type == SOURCE_IS_AMBIGUOUS)
@<Bit aligned Earley item elements@> =
unsigned int t_source_type:3;

@*0 Flag marking Leo Expansion.
This flag is used to indicate the expansion of Leo items.
It is initally set, indicating that it is vacuously true.
This interpretation fits the purpose,
which is to tell code which encounters
this Leo item whether there are Leo items which need expansion.
@d EIM_is_Leo_Expanded(eim) ((eim)->t_is_leo_expanded)
@d LV_EIM_is_Leo_Expanded(eim) EIM_is_Leo_Expanded(eim)
@<Bit aligned Earley item elements@> =
unsigned int t_is_leo_expanded:1;

@ @<Private function prototypes@> =
static const char* invalid_source_type_message(guint type);
@ Not inline, because not used in critical paths.
This is for creating error messages.
@<Function definitions@> =
static const char* invalid_source_type_message(guint type) {
     switch (type) {
    case NO_SOURCE:
    return "invalid source type: none";
    case SOURCE_IS_TOKEN: 
     return "invalid source type: token";
    case SOURCE_IS_COMPLETION:
     return "invalid source type: completion";
    case SOURCE_IS_LEO:
     return "invalid source type: leo";
    case SOURCE_IS_AMBIGUOUS:
     return "invalid source type: ambiguous";
     }
     return "unknown source type";
}

@*0 Trace Functions.
Many of the
trace functions use
a "trace Earley item" which is
tracked on a per-recognizer basis.
@<Widely aligned recognizer elements@> =
EIM t_trace_earley_item;
@ @<Initialize recognizer elements@> =
r->t_trace_earley_item = NULL;
@ This function returns the AHFA state ID of an Earley item,
and sets the trace Earley item,
if it successfully finds an Earley item
in the trace Earley set with the specified
AHFA state ID and origin earleme.
If there is no such Earley item,
it returns |-1|,
and clears the trace Earley item.
On failure for other reasons,
it returns |-2|,
and clears the trace Earley item.
@ The trace Earley item is cleared if no matching
Earley item is found, and on failure.
The trace source link is always
cleared, regardless of success or failure.
@ @^To Do@>  To Do: Deprecated.  To be deleted.
@<Public function prototypes@> =
Marpa_AHFA_State_ID
marpa_old_earley_item_trace (struct marpa_r *r,
    Marpa_Earley_Set_ID origin_set_id,
    Marpa_AHFA_State_ID state_id);
@ @<Function definitions@> =
Marpa_AHFA_State_ID
marpa_old_earley_item_trace (struct marpa_r *r,
    Marpa_Earley_Set_ID origin_set_id,
    Marpa_AHFA_State_ID state_id)
{
  const gint no_match = -1;
  @<Return |-2| on failure@>@;
  ES current_set = r->t_trace_earley_set;
  ES origin_set;
  EIM item;
  EIK_Object item_key;
  GRAMMAR_Const g = G_of_R(r);
  @<Fail if recognizer initial@>@;
  trace_source_link_clear(r);
  if (!current_set) {
      @<Clear trace Earley item data@>@;
      R_ERROR("no trace es");
      return failure_indicator;
  }
    if (origin_set_id < 0) {
        R_ERROR("invalid es ordinal");
	return failure_indicator;
    }
    r_update_earley_sets(r);
    if (origin_set_id >= DSTACK_LENGTH(r->t_earley_set_stack)) {
        R_ERROR("origin es does not exist");
        return failure_indicator;
    }
  origin_set = ES_of_R_by_Ord (r, origin_set_id);
  if (!origin_set) {
      @<Clear trace Earley item data@>@;
      R_ERROR("origin es not found");
      return failure_indicator;
    }
  item_key.t_state = AHFA_by_ID (state_id);
  item_key.t_origin = origin_set;
  item_key.t_set = current_set;
  item = r->t_trace_earley_item = g_tree_lookup(r->t_earley_item_tree, &item_key);
  if (!item) {
      @<Clear trace Earley item data@>@/
      return no_match;
    }
  return AHFAID_of_EIM(item);
}

@ This function sets
the trace Earley set to the one indicated
by the ID
of the argument.
On success,
the earleme of the new trace Earley set is
returned.
@ Various other trace data depends on the Earley
set, and must be consistent with it.
This function clears all such data,
unless it is called while the recognizer is in
a trace-unsafe state (initial, fatal, etc.)
or unless the the Earley set requested by the
argument is already the trace Earley set.
On failure because the ID is for a non-existent
Earley set which does not
exist, |-1| is returned.
The upper levels may choose to treat this as a soft failure.
This may be treated as a soft failure by the upper levels.
On failure because the ID is illegal (less than zero)
or for other failures, |-2| is returned.
The upper levels may choose to treat these as hard failures.
@ @<Public function prototypes@> =
Marpa_Earleme
marpa_earley_set_trace (struct marpa_r *r, Marpa_Earley_Set_ID set_id);
@ @<Function definitions@> =
Marpa_Earleme
marpa_earley_set_trace (struct marpa_r *r, Marpa_Earley_Set_ID set_id)
{
  ES earley_set;
  const gint es_does_not_exist = -1;
  @<Return |-2| on failure@>@/
  @<Fail recognizer if not trace-safe@>@;
    if (r->t_trace_earley_set && Ord_of_ES (r->t_trace_earley_set) == set_id)
      { /* If the set is already
	   the current earley set,
	   return successfully without resetting any of the dependant data */
	return Earleme_of_ES (r->t_trace_earley_set);
      }
  @<Clear trace Earley set dependent data@>@;
    if (set_id < 0)
    {
	R_ERROR ("invalid es ordinal");
	return failure_indicator;
    }
  r_update_earley_sets (r);
    if (set_id >= DSTACK_LENGTH (r->t_earley_set_stack))
      {
	return es_does_not_exist;
      }
    earley_set = ES_of_R_by_Ord (r, set_id);
  r->t_trace_earley_set = earley_set;
  return Earleme_of_ES(earley_set);
}

@ @<Clear trace Earley set dependent data@> = {
  r->t_trace_earley_set = NULL;
  trace_earley_item_clear(r);
  @<Clear trace postdot item data@>@;
}

@ @<Public function prototypes@> =
Marpa_AHFA_State_ID
marpa_earley_item_trace (struct marpa_r *r,
    Marpa_Earley_Item_ID item_id);
@ @<Function definitions@> =
Marpa_AHFA_State_ID
marpa_earley_item_trace (struct marpa_r *r, Marpa_Earley_Item_ID item_id)
{
  const gint eim_does_not_exist = -1;
  @<Return |-2| on failure@>@;
  ES trace_earley_set;
  EIM earley_item;
  EIM *earley_items;
  @<Fail recognizer if not trace-safe@>@;
  trace_earley_set = r->t_trace_earley_set;
  if (!trace_earley_set)
    {
      @<Clear trace Earley set dependent data@>@;
      R_ERROR ("no trace es");
      return failure_indicator;
    }
  trace_earley_item_clear (r);
  if (item_id < 0)
    {
      R_ERROR ("invalid eim ordinal");
      return failure_indicator;
    }
  if (item_id >= EIM_Count_of_ES (trace_earley_set))
    {
      return eim_does_not_exist;
    }
  earley_items = EIMs_of_ES (trace_earley_set);
  earley_item = earley_items[item_id];
  r->t_trace_earley_item = earley_item;
  return AHFAID_of_EIM (earley_item);
}

@ Clear all the data elements specifically
for the trace Earley item.
The difference between this code and
|trace_earley_item_clear| is
that |trace_earley_item_clear| 
also clears the source link.
@<Clear trace Earley item data@> =
      r->t_trace_earley_item = NULL;

@ @<Private function prototypes@> =
static inline void trace_earley_item_clear(struct marpa_r* r);
@ @<Function definitions@> =
static inline void trace_earley_item_clear(struct marpa_r* r)
{
    @<Clear trace Earley item data@>@/
    trace_source_link_clear(r);
}

@ @<Private function prototypes@> =
Marpa_Earleme marpa_earley_item_origin(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Earleme marpa_earley_item_origin(struct marpa_r *r)
{
  @<Return |-2| on failure@>@;
  EIM item = r->t_trace_earley_item;
  @<Fail if recognizer initial@>@;
  if (!item) {
      @<Clear trace Earley item data@>@;
      R_ERROR("no trace eim");
      return failure_indicator;
  }
  return Origin_Earleme_of_EIM(item);
}

@** Earley Index (EIX) Code.
Postdot items are of two kinds: Earley indexes
and Leo items.
The payload of an Earley index is simple:
a pointer to an Earley item.
The other elements of the EIX are overhead to 
support the chain of postdot items for
a postdot symbol.
@d Next_PIM_of_EIX(eix) ((eix)->t_next)
@d LV_Next_PIM_of_EIX(eix) Next_PIM_of_EIX(eix)
@d EIM_of_EIX(eix) ((eix)->t_earley_item)
@d LV_EIM_of_EIX(eix) EIM_of_EIX(eix)
@d Postdot_SYMID_of_EIX(eix) ((eix)->t_postdot_symid)
@d LV_Postdot_SYMID_of_EIX(eix) Postdot_SYMID_of_EIX(eix)
@<Private incomplete structures@> =
struct s_earley_ix;
typedef struct s_earley_ix* EIX;
union u_postdot_item;
@ @<Private structures@> =
struct s_earley_ix {
     union u_postdot_item* t_next;
     SYMID t_postdot_symid;
     EIM t_earley_item; // Never NULL if this is an index item
};
typedef struct s_earley_ix EIX_Object;

@** Leo Item (LIM) Code.
Leo items originate from the "transition items" of Joop Leo's 1991 paper.
They are set up so their first fields are identical to those of
the Earley item indexes,
so that they can be linked together in the same chain.
Because the Earley index is at the beginning of each Leo item,
LIMs can be treated as a kind of EIX.
@d EIX_of_LIM(lim) ((EIX)(lim))
@ Both Earley indexes and Leo items are
postdot items, so that Leo items also require
the fields to maintain the chain of postdot items.
For this reason, Leo items contain an Earley index,
but one
with a |NULL| Earley item pointer.
@d Postdot_SYMID_of_LIM(leo) (Postdot_SYMID_of_EIX(EIX_of_LIM(leo)))
@d LV_Postdot_SYMID_of_LIM(leo) Postdot_SYMID_of_LIM(leo)
@d Next_PIM_of_LIM(leo) (Next_PIM_of_EIX(EIX_of_LIM(leo)))
@d LV_Next_PIM_of_LIM(leo) Next_PIM_of_LIM(leo)
@d Origin_of_LIM(leo) ((leo)->t_origin)
@d LV_Origin_of_LIM(leo) Origin_of_LIM(leo)
@d Top_AHFA_of_LIM(leo) ((leo)->t_top_ahfa)
@d LV_Top_AHFA_of_LIM(leo) Top_AHFA_of_LIM(leo)
@d Predecessor_LIM_of_LIM(leo) ((leo)->t_predecessor)
@d LV_Predecessor_LIM_of_LIM(leo) Predecessor_LIM_of_LIM(leo)
@d Base_EIM_of_LIM(leo) ((leo)->t_base)
@d LV_Base_EIM_of_LIM(leo) Base_EIM_of_LIM(leo)
@d ES_of_LIM(leo) ((leo)->t_set)
@d LV_ES_of_LIM(leo) ES_of_LIM(leo)
@d Chain_Length_of_LIM(leo) ((leo)->t_chain_length)
@d LV_Chain_Length_of_LIM(leo) Chain_Length_of_LIM(leo)
@d Earleme_of_LIM(lim) Earleme_of_ES(ES_of_LIM(lim))
@<Private incomplete structures@> =
struct s_leo_item;
typedef struct s_leo_item* LIM;
@ @<Private structures@> =
struct s_leo_item {
     EIX_Object t_earley_ix;
     ES t_origin;
     AHFA t_top_ahfa;
     LIM t_predecessor;
     EIM t_base;
     ES t_set;
     gint t_chain_length;
};
typedef struct s_leo_item LIM_Object;

@*0 Trace Functions.
The functions in this section are all accessors.
The trace Leo item is selected by setting the trace postdot item
to a Leo item.

@ @<Private function prototypes@> =
Marpa_Symbol_ID marpa_leo_predecessor_symbol(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_leo_predecessor_symbol(struct marpa_r *r)
{
  const Marpa_Symbol_ID no_predecessor = -1;
  @<Return |-2| on failure@>@;
  PIM postdot_item = r->t_trace_postdot_item;
  LIM predecessor_leo_item;
  @<Fail recognizer if not trace-safe@>@;
  if (!postdot_item) {
      R_ERROR("no trace pim");
      return failure_indicator;
  }
  if (EIM_of_PIM(postdot_item)) {
      R_ERROR("pim is not lim");
      return failure_indicator;
  }
  predecessor_leo_item = Predecessor_LIM_of_LIM(LIM_of_PIM(postdot_item));
  if (!predecessor_leo_item) return no_predecessor;
  return Postdot_SYMID_of_LIM(predecessor_leo_item);
}

Marpa_Earleme marpa_leo_base_origin(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Earleme marpa_leo_base_origin(struct marpa_r *r)
{
  const Marpa_Earleme pim_is_not_a_leo_item = -1;
  @<Return |-2| on failure@>@;
  PIM postdot_item = r->t_trace_postdot_item;
  EIM base_earley_item;
  @<Fail recognizer if not trace-safe@>@;
  if (!postdot_item) {
      R_ERROR("no trace pim");
      return failure_indicator;
  }
  if (EIM_of_PIM(postdot_item)) return pim_is_not_a_leo_item;
  base_earley_item = Base_EIM_of_LIM(LIM_of_PIM(postdot_item));
  return Origin_Earleme_of_EIM(base_earley_item);
}

@ @<Private function prototypes@> =
Marpa_AHFA_State_ID marpa_leo_base_state(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_AHFA_State_ID marpa_leo_base_state(struct marpa_r *r)
{
  const Marpa_Earleme pim_is_not_a_leo_item = -1;
  @<Return |-2| on failure@>@;
  PIM postdot_item = r->t_trace_postdot_item;
  EIM base_earley_item;
  @<Fail recognizer if not trace-safe@>@;
  if (!postdot_item) {
      R_ERROR("no trace pim");
      return failure_indicator;
  }
  if (EIM_of_PIM(postdot_item)) return pim_is_not_a_leo_item;
  base_earley_item = Base_EIM_of_LIM(LIM_of_PIM(postdot_item));
  return AHFAID_of_EIM(base_earley_item);
}

@ This function
returns the "Leo expansion AHFA" of the current trace Leo item.
@<Private function prototypes@> =
Marpa_AHFA_State_ID marpa_leo_expansion_ahfa(struct marpa_r *r);
@ The {\bf Leo expansion AHFA} is the AHFA
of the {\bf Leo expansion Earley item}.
for this Leo item.
{\bf Leo expansion Earley items}, when
the context makes the meaning clear,
are also called {\bf Leo expansion items}
or simply {\bf Leo expansions}.
@ Every Leo item has a unique Leo expansion Earley item,
because for this purpose
the process of
Leo expansion is seen from a non-recursive point of view.
In practice, Leo expansion is recursive,
andl creation of the Leo expansion Earley item for
one Leo item
implies
the Leo expansion of all of the predecessors of that
Leo item.
@ Note that expansion of the Leo item at the top
of a Leo path is not needed---%
if a Leo item is the predecessor in
a Leo source for a Leo completion item,
the Leo completion item is the expansion of that Leo item.
@ @<Function definitions@> =
Marpa_AHFA_State_ID marpa_leo_expansion_ahfa(struct marpa_r *r)
{
    const Marpa_Earleme pim_is_not_a_leo_item = -1;
    @<Return |-2| on failure@>@;
    const PIM postdot_item = r->t_trace_postdot_item;
    @<Fail recognizer if not trace-safe@>@;
    if (!postdot_item)
      {
	R_ERROR ("no trace pim");
	return failure_indicator;
      }
    if (!EIM_of_PIM (postdot_item))
      {
	const LIM leo_item = LIM_of_PIM (postdot_item);
	const EIM base_earley_item = Base_EIM_of_LIM (leo_item);
	const SYMID postdot_symbol = Postdot_SYMID_of_LIM (leo_item);
	const AHFA to_ahfa = To_AHFA_of_EIM_by_SYMID (base_earley_item, postdot_symbol);
	return ID_of_AHFA(to_ahfa);
      }
    return pim_is_not_a_leo_item;
}


@** Postdot Item (PIM) code.
Postdot items are entries in an index,
by postdot symbol, of both the Earley items and the Leo items
for each Earley set.
@d LIM_of_PIM(pim) ((LIM)(pim))
@d EIX_of_PIM(pim) ((EIX)(pim))
@d Postdot_SYMID_of_PIM(pim) (Postdot_SYMID_of_EIX(EIX_of_PIM(pim)))
@d LV_Postdot_SYMID_of_PIM(pim) Postdot_SYMID_of_PIM(pim)
@d EIM_of_PIM(pim) (EIM_of_EIX(EIX_of_PIM(pim)))
@d LV_EIM_of_PIM(pim) EIM_of_PIM(pim)
@d Next_PIM_of_PIM(pim) (Next_PIM_of_EIX(EIX_of_PIM(pim)))
@d LV_Next_PIM_of_PIM(pim) Next_PIM_of_PIM(pim)

@ |PIM_of_LIM| assumes that PIM is in fact a LIM.
|PIM_is_LIM| is available to check this.
@d PIM_of_LIM(pim) ((PIM)(pim))
@d PIM_is_LIM(pim) (EIM_of_EIX(EIX_of_PIM(pim)) == NULL)
@s PIM int
@<Private structures@> =
union u_postdot_item {
    LIM_Object t_leo;
    EIX_Object t_earley;
};
typedef union u_postdot_item* PIM;

@*0 Symbol of a Postdot Item.
@d Symbol_ID_of_Postdot_Item(postdot) ((postdot)->t_earley.transition_symid)

@ This function searches for the
first postdot item for an Earley set
and a symbol ID.
If successful, it
returns that postdot item.
If it fails, it returns |NULL|.
@<Private function prototypes@> =
static inline PIM* pim_sym_p_find(ES set, SYMID symid);
@ @<Function definitions@> =
static inline PIM*
pim_sym_p_find (ES set, SYMID symid)
{
  gint lo = 0;
  gint hi = Postdot_SYM_Count_of_ES(set) - 1;
  PIM* postdot_array = set->t_postdot_ary;
  while (hi >= lo) { // A binary search
       gint trial = lo+(hi-lo)/2; // guards against overflow
       PIM trial_pim = postdot_array[trial];
       SYMID trial_symid = Postdot_SYMID_of_PIM(trial_pim);
       if (trial_symid == symid) return postdot_array+trial;
       if (trial_symid < symid) {
           lo = trial+1;
       } else {
           hi = trial-1;
       }
  }
  return NULL;
}
@ @<Private function prototypes@> =
static inline PIM first_pim_of_es_by_symid(ES set, SYMID symid);
@ @<Function definitions@> =
static inline PIM first_pim_of_es_by_symid(ES set, SYMID symid)
{
   PIM* pim_sym_p = pim_sym_p_find(set, symid);
   return pim_sym_p ? *pim_sym_p : NULL;
}

@*0 Trace Functions.
Many of the
trace functions use
a "trace postdot item".
This is
tracked on a per-recognizer basis.
@<Widely aligned recognizer elements@> =
union u_postdot_item** t_trace_pim_sym_p;
union u_postdot_item* t_trace_postdot_item;
@ @<Initialize recognizer elements@> =
r->t_trace_pim_sym_p = NULL;
r->t_trace_postdot_item = NULL;
@ |marpa_postdot_symbol_trace|
takes a recognizer and a symbol ID
as an argument.
It sets the trace postdot item to the first
postdot item for the symbol ID.
If there is no postdot item 
for that symbol ID,
it returns |-1|.
On failure for other reasons,
it returns |-2|
and clears the trace postdot item.
@<Public function prototypes@> =
Marpa_Symbol_ID
marpa_postdot_symbol_trace (struct marpa_r *r,
    Marpa_Symbol_ID symid);
@ @<Function definitions@> =
Marpa_Symbol_ID
marpa_postdot_symbol_trace (struct marpa_r *r,
    Marpa_Symbol_ID symid)
{
  @<Return |-2| on failure@>@;
  ES current_es = r->t_trace_earley_set;
  PIM* pim_sym_p;
  PIM pim;
  @<Clear trace postdot item data@>@;
  @<Fail recognizer if not trace-safe@>@;
  @<Fail if recognizer |symid| is invalid@>@;
  if (!current_es) {
      R_ERROR("no pim");
      return failure_indicator;
  }
  pim_sym_p = PIM_SYM_P_of_ES_by_SYMID(current_es, symid);
  pim = *pim_sym_p;
  if (!pim) return -1;
  r->t_trace_pim_sym_p = pim_sym_p;
  r->t_trace_postdot_item = pim;
  return symid;
}

@ @<Clear trace postdot item data@> =
r->t_trace_pim_sym_p = NULL;
r->t_trace_postdot_item = NULL;

@ Set trace postdot item to the first in the trace Earley set,
and return its postdot symbol ID.
If the trace Earley set has no postdot items, return -1 and
clear the trace postdot item.
On other failures, return -2 and clear the trace
postdot item.
@<Public function prototypes@> =
Marpa_Symbol_ID
marpa_first_postdot_item_trace (struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID
marpa_first_postdot_item_trace (struct marpa_r *r)
{
  @<Return |-2| on failure@>@;
  ES current_earley_set = r->t_trace_earley_set;
  PIM pim;
  PIM* pim_sym_p;
  @<Clear trace postdot item data@>@;
  @<Fail recognizer if not trace-safe@>@;
  if (!current_earley_set) {
      @<Clear trace Earley item data@>@;
      R_ERROR("no trace es");
      return failure_indicator;
  }
  if (current_earley_set->t_postdot_sym_count <= 0) return -1;
  pim_sym_p = current_earley_set->t_postdot_ary+0;
  pim = pim_sym_p[0];
  r->t_trace_pim_sym_p = pim_sym_p;
  r->t_trace_postdot_item = pim;
  return Postdot_SYMID_of_PIM(pim);
}

@ Set the trace postdot item to the one after
the current trace postdot item,
and return its postdot symbol ID.
If the current trace postdot item is the last,
return -1 and clear the trace postdot item.
On other failures, return -2 and clear the trace
postdot item.
@<Public function prototypes@> =
Marpa_Symbol_ID
marpa_next_postdot_item_trace (struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID
marpa_next_postdot_item_trace (struct marpa_r *r)
{
  const SYMID no_more_postdot_symbols = -1;
  @<Return |-2| on failure@>@;
  ES current_set = r->t_trace_earley_set;
  PIM pim;
  PIM* pim_sym_p;

  pim_sym_p = r->t_trace_pim_sym_p;
  pim = r->t_trace_postdot_item;
  @<Clear trace postdot item data@>@;
  if (!pim_sym_p || !pim) {
      R_ERROR("no trace pim");
      return failure_indicator;
  }
  @<Fail recognizer if not trace-safe@>@;
  if (!current_set) {
      R_ERROR("no trace es");
      return failure_indicator;
  }
  pim = Next_PIM_of_PIM(pim);
  if (!pim) { /* If no next postdot item for this symbol,
       then look at next symbol */
       pim_sym_p++;
       if (pim_sym_p - current_set->t_postdot_ary
	   >= current_set->t_postdot_sym_count) {
	   return no_more_postdot_symbols;
       }
      pim = *pim_sym_p;
  }
  r->t_trace_pim_sym_p = pim_sym_p;
  r->t_trace_postdot_item = pim;
  return Postdot_SYMID_of_PIM(pim);
}

@ @<Private function prototypes@> =
Marpa_AHFA_State_ID marpa_postdot_item_symbol(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_AHFA_State_ID marpa_postdot_item_symbol(struct marpa_r *r)
{
  @<Return |-2| on failure@>@;
  PIM postdot_item = r->t_trace_postdot_item;
  @<Fail recognizer if not trace-safe@>@;
  if (!postdot_item) {
      R_ERROR("no trace pim");
      return failure_indicator;
  }
  return Postdot_SYMID_of_PIM(postdot_item);
}


@** Source Objects.
These are distinguished by context.
@*0 The Relationship between Leo items and Ambiguity.
The relationship between Leo items and ambiguous sources bears
some explaining.
Leo sources must be unique, but only when their predecessor's
Earley set is considered.
That is, for every pairing of Earley item and Earley set,
if there be only one Leo source in that Earley item
with a predecessor in that Earley set.
But there may be other sources (both Leo and non-Leo),
a long as their predecessors
are in different Earley sets.
@ One way to look at these Leo ambiguities is as different
"factorings" of the Earley item.
Assume the last (or transition) symbol of an Earley item
is a token.
An Earley item will often have both a predecessor and a token,
and these can "factor", or divide up, the distance between
an Earley item's origin and its current set in different ways.
@ The Earley item can have only one origin,
and only one transition symbol.
But that transition symbol does not have to start at the origin
and can start anywhere between the origin and the current
set of the Earley item.
For example, for an Earley item at earleme 14, with its origin at 10,
tokens may start at earlemes 10, 11, 12 and 13.
Each may have its own Leo source.
At those earlemes without a Leo source, there may be any number
of non-Leo sources.
@ In this way, an Earley item with a Leo source can be ambiguous.
The discussion above assumed the final symbol was a token.
The situation for completion Earley items is similar,
and these also can both have a Leo source and 
be ambiguous.
@*0 Optimization.
There will be a lot of these structures in a long
parse, so space optimization is important.
I have some latitude in the number of linked lists
in a ambiguous source.
If an |int| is the same size as a |void*|,
then space for three |void*| in ambiguous sources
comes "free".
If |void*| is $n$ bytes larger than an |int|,
then each unambiguous source uses $n$ bytes
more than it has to, although there are
compensating improvements in
speed and simplicity.
Any programmer trying to take advantage
of architectures where |int|
is shorter than |void*| will need to
assure herself that the space she saves in 
the |ambiguous_source| struct was not simply wasted
by alignment within structures or during memory allocation.
@d Next_SRCL_of_SRCL(link) ((link)->t_next)
@d LV_Next_SRCL_of_SRCL(link) Next_SRCL_of_SRCL(link)
@ @<Private typedefs@> =
struct s_source;
typedef struct s_source* SRC;
@ @<Source object structure@>= 
struct s_source {
     gpointer t_predecessor;
     gpointer t_cause;
     SYMID t_symbol_id;
};

@ @<Private typedefs@> =
struct s_source_link;
typedef struct s_source_link* SRCL;
@ @<Source object structure@>= 
struct s_source_link {
    SRCL t_next;
    struct s_source t_source;
};

@ @<Source object structure@>= 
struct s_ambiguous_source {
    SRCL t_leo;
    SRCL t_token;
    SRCL t_completion;
};

@ @<Source object structure@>= 
union u_source_container {
    struct s_ambiguous_source t_ambiguous;
    struct s_source t_unique;
};

@
@d Source_of_SRCL(link) ((link)->t_source)
@d Source_of_EIM(eim) ((eim)->t_container.t_unique)
@d Predecessor_of_Source(srcd) ((srcd).t_predecessor)
@d Predecessor_of_SRC(source) Predecessor_of_Source(*(source))
@d Predecessor_of_EIM(item) Predecessor_of_Source(Source_of_EIM(item))
@d Predecessor_of_SRCL(link) Predecessor_of_Source(Source_of_SRCL(link))
@d LV_Predecessor_of_SRCL(link) Predecessor_of_SRCL(link)
@d Cause_of_Source(srcd) ((srcd).t_cause)
@d Cause_of_SRC(source) Cause_of_Source(*(source))
@d Cause_of_EIM(item) Cause_of_Source(Source_of_EIM(item))
@d Cause_of_SRCL(link) Cause_of_Source(Source_of_SRCL(link))
@d Token_Value_of_Source(srcd) ((srcd).t_cause)
@d Token_Value_of_SRC(source) Token_Value_of_Source(*(source))
@d Token_Value_of_EIM(item) Token_Value_of_Source(Source_of_EIM(item))
@d Token_Value_of_SRCL(link) Token_Value_of_Source(Source_of_SRCL(link))
@d LV_Token_Value_of_SRCL(link) Token_Value_of_SRCL(link)
@d Symbol_ID_of_Source(srcd) ((srcd).t_symbol_id)
@d Symbol_ID_of_SRC(source) Symbol_ID_of_Source(*(source))
@d Symbol_ID_of_SRCL(link) Symbol_ID_of_Source(Source_of_SRCL(link))
@d LV_Symbol_ID_of_SRCL(link) Symbol_ID_of_SRCL(link)

@ @d Cause_AHFA_State_ID_of_SRC(source)
    AHFAID_of_EIM((EIM)Cause_of_SRC(source))
@d Leo_Transition_Symbol_ID_of_SRC(leo_source)
    Postdot_SYMID_of_LIM((LIM)Predecessor_of_SRC(leo_source))

@
@d First_Completion_Link_of_EIM(item) ((item)->t_container.t_ambiguous.t_completion)
@d LV_First_Completion_Link_of_EIM(item) First_Completion_Link_of_EIM(item)
@d First_Token_Link_of_EIM(item) ((item)->t_container.t_ambiguous.t_token)
@d LV_First_Token_Link_of_EIM(item) First_Token_Link_of_EIM(item)
@d First_Leo_SRCL_of_EIM(item) ((item)->t_container.t_ambiguous.t_leo)
@d LV_First_Leo_SRCL_of_EIM(item) First_Leo_SRCL_of_EIM(item)

@ @<Function definitions@> = static inline
void
token_link_add (struct marpa_r *r,
		EIM item,
		EIM predecessor,
		SYMID token_id,
		gpointer value)
{
  SRCL new_link;
  guint previous_source_type = Source_Type_of_EIM (item);
  if (previous_source_type == NO_SOURCE)
    {
      Source_Type_of_EIM (item) = SOURCE_IS_TOKEN;
      item->t_container.t_unique.t_predecessor = predecessor;
      item->t_container.t_unique.t_cause = value;
      item->t_container.t_unique.t_symbol_id = token_id;
      return;
    }
  if (previous_source_type != SOURCE_IS_AMBIGUOUS)
    { // If the sourcing is not already ambiguous, make it so
      earley_item_ambiguate (r, item);
    }
  new_link = obstack_alloc (&r->t_obs, sizeof (*new_link));
  new_link->t_next = First_Token_Link_of_EIM (item);
  new_link->t_source.t_predecessor = predecessor;
  new_link->t_source.t_cause = value;
  new_link->t_source.t_symbol_id = token_id;
  LV_First_Token_Link_of_EIM (item) = new_link;
}
@ @<Private function prototypes@> = static inline void
token_link_add (struct marpa_r *r,
		EIM item,
		EIM predecessor,
		SYMID token_id,
		gpointer value);

@ @<Private function prototypes@> = static inline void
completion_link_add (struct marpa_r *r,
		EIM item,
		EIM predecessor,
		EIM cause);
@
Each possible cause
link is only visited once.
It may be paired with several different predecessors.
Each cause may complete several different LHS symbols
and Marpa::XS will seek predecessors for each at
the parent location.
Two different completed LHS symbols might be postdot
symbols for the same predecessor Earley item.
For this reason,
predecessor-cause pairs
might not be unique
within an Earley item.
@ Since a completion link consists entirely of
the predecessor-cause pair, this means duplicate
completion links are possible.
The maximum possible number of such duplicates is the
number of complete LHS symbols for the current AHFA state.
This is alway a constant and typically a small one,
but it is also typically larger than 1.
@ This is not an issue for unambiguous parsing.
It {\bf is} an issue for iterating ambiguous parses.
The strategy currently taken is to do nothing about duplicates
in the recognition phase,
and to eliminate them in the evaluation phase.
Ultimately, duplicates must be eliminated by rule and
position -- eliminating duplicates by AHFA state is
{\bf not} sufficient.
Since I do not pull out the
individual rules and positions until the evaluation phase,
at this writing it seems to make sense to deal with
duplicates there.
@ As shown above, the number of duplicate completion links
is never more than $O(n)$ where $n$ is the number of Earley items.
For academic purposes, it
is probably possible to contrive a parse which generates
a lot of duplicates.
The actual numbers
I have encountered have always been very small,
even in grammars of only academic interest.
@ The carrying cost of the extra completion links can be safely
assumed to be very low,
in comparision with the cost of searching for them.
This means that the major consideration in deciding
where to eliminate duplicates,
is time efficiency.
Duplicate completion links should be eliminated
at the point where that elimination can be accomplished
most efficiently.
@<Function definitions@> = static inline
void
completion_link_add (struct marpa_r *r,
		EIM item,
		EIM predecessor,
		EIM cause)
{
  SRCL new_link;
  guint previous_source_type = Source_Type_of_EIM (item);
  if (previous_source_type == NO_SOURCE)
    {
      Source_Type_of_EIM (item) = SOURCE_IS_COMPLETION;
      item->t_container.t_unique.t_predecessor = predecessor;
      item->t_container.t_unique.t_cause = cause;
      item->t_container.t_unique.t_symbol_id = -1;
      return;
    }
  if (previous_source_type != SOURCE_IS_AMBIGUOUS)
    { // If the sourcing is not already ambiguous, make it so
      earley_item_ambiguate (r, item);
    }
  new_link = obstack_alloc (&r->t_obs, sizeof (*new_link));
  new_link->t_next = First_Completion_Link_of_EIM (item);
  new_link->t_source.t_predecessor = predecessor;
  new_link->t_source.t_cause = cause;
  new_link->t_source.t_symbol_id = -1;
  LV_First_Completion_Link_of_EIM (item) = new_link;
}

@ @<Function definitions@> = static inline
void
leo_link_add (struct marpa_r *r,
		EIM item,
		LIM predecessor,
		EIM cause)
{
  SRCL new_link;
  guint previous_source_type = Source_Type_of_EIM (item);
  LV_EIM_is_Leo_Expanded(item) = 0;
  if (previous_source_type == NO_SOURCE)
    {
      Source_Type_of_EIM (item) = SOURCE_IS_LEO;
      item->t_container.t_unique.t_predecessor = predecessor;
      item->t_container.t_unique.t_cause = cause;
      item->t_container.t_unique.t_symbol_id = -1;
      return;
    }
  if (previous_source_type != SOURCE_IS_AMBIGUOUS)
    { // If the sourcing is not already ambiguous, make it so
      earley_item_ambiguate (r, item);
    }
  new_link = obstack_alloc (&r->t_obs, sizeof (*new_link));
  new_link->t_next = First_Leo_SRCL_of_EIM (item);
  new_link->t_source.t_predecessor = predecessor;
  new_link->t_source.t_cause = cause;
  new_link->t_source.t_symbol_id = -1;
  LV_First_Leo_SRCL_of_EIM(item) = new_link;
}
@ @<Private function prototypes@> = static inline void
leo_link_add (struct marpa_r *r,
		EIM item,
		LIM predecessor,
		EIM cause);

@ {\bf Convert an Earley item to an ambiguous one.}
|earley_item_ambiguate|
assumes it is called when there is exactly one source.
In other words, is assumes that the Earley item
is not unsourced,
and that it is not already ambiguous.
Ambiguous sources should have more than one source,
and
|earley_item_ambiguate|
is assuming that a new source will be added as followup.
@
Inlining |earley_item_ambiguate| might help in some
circumstance, but at this point
|earley_item_ambiguate| is not marked |inline|.
|earley_item_ambiguate|
is not short,
it is referenced in several places,
it is only called for ambiguous Earley items,
and even for these it is only called when the
Earley item first becomes ambiguous.
@<Function definitions@> = static 
void earley_item_ambiguate (struct marpa_r * r, EIM item)
{
  guint previous_source_type = Source_Type_of_EIM (item);
  Source_Type_of_EIM (item) = SOURCE_IS_AMBIGUOUS;
  switch (previous_source_type)
    {
    case SOURCE_IS_TOKEN: @<Ambiguate token source@>@;
      return;
    case SOURCE_IS_COMPLETION: @<Ambiguate completion source@>@;
      return;
    case SOURCE_IS_LEO: @<Ambiguate Leo source@>@;
      return;
    }
}
@ @<Private function prototypes@> = static 
void earley_item_ambiguate (struct marpa_r * r, EIM item);

@ @<Ambiguate token source@> = {
  SRCL new_link = obstack_alloc (&r->t_obs, sizeof (*new_link));
  new_link->t_next = NULL;
  new_link->t_source = item->t_container.t_unique;
  LV_First_Leo_SRCL_of_EIM (item) = NULL;
  LV_First_Completion_Link_of_EIM (item) = NULL;
  LV_First_Token_Link_of_EIM (item) = new_link;
}

@ @<Ambiguate completion source@> = {
  SRCL new_link = obstack_alloc (&r->t_obs, sizeof (*new_link));
  new_link->t_next = NULL;
  new_link->t_source = item->t_container.t_unique;
  LV_First_Leo_SRCL_of_EIM (item) = NULL;
  LV_First_Completion_Link_of_EIM (item) = new_link;
  LV_First_Token_Link_of_EIM (item) = NULL;
}

@ @<Ambiguate Leo source@> = {
  SRCL new_link = obstack_alloc (&r->t_obs, sizeof (*new_link));
  new_link->t_next = NULL;
  new_link->t_source = item->t_container.t_unique;
  LV_First_Leo_SRCL_of_EIM (item) = new_link;
  LV_First_Completion_Link_of_EIM (item) = NULL;
  LV_First_Token_Link_of_EIM (item) = NULL;
}

@*0 Trace Functions.
Many trace functions track a "trace source link".
There is only one of these, shared among all types of
source link.
It is an error to call a trace function that is
inconsistent with the type of the current trace
source link.
@<Widely aligned recognizer elements@> =
SRC t_trace_source;
SRCL t_trace_next_source_link;
@ @<Bit aligned recognizer elements@> =
unsigned int t_trace_source_type:3;
@ @<Initialize recognizer elements@> =
r->t_trace_source = NULL;
r->t_trace_next_source_link = NULL;
r->t_trace_source_type = NO_SOURCE;

@*1 Trace First Token Link.
@ Set the trace source link to a token link,
if there is one, otherwise clear the trace source link.
Returns the symbol ID if there was a token source link,
|-1| if there was none,
and |-2| on some other kind of failure.
@<Public function prototypes@> =
Marpa_Symbol_ID marpa_first_token_link_trace(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_first_token_link_trace(struct marpa_r *r)
{
   @<Return |-2| on failure@>@;
   SRC source;
   guint source_type;
    EIM item = r->t_trace_earley_item;
    @<Fail recognizer if not trace-safe@>@;
    @<Set |item|, failing if necessary@>@;
    source_type = Source_Type_of_EIM (item);
    switch (source_type)
      {
      case SOURCE_IS_TOKEN:
	r->t_trace_source_type = SOURCE_IS_TOKEN;
	source = &(item->t_container.t_unique);
	r->t_trace_source = source;
	r->t_trace_next_source_link = NULL;
	return Symbol_ID_of_SRC (source);
      case SOURCE_IS_AMBIGUOUS:
	{
	  SRCL full_link =
	    First_Token_Link_of_EIM (item);
	  if (full_link)
	    {
	      r->t_trace_source_type = SOURCE_IS_TOKEN;
	      r->t_trace_next_source_link = Next_SRCL_of_SRCL (full_link);
	      r->t_trace_source = &(full_link->t_source);
	      return Symbol_ID_of_SRCL (full_link);
	    }
	}
      }
    trace_source_link_clear(r);
    return -1;
}

@*1 Trace Next Token Link.
@ Set the trace source link to the next token link,
if there is one.
Otherwise clear the trace source link.
@ Returns the symbol ID if there is
a next token source link,
|-1| if there was none,
and |-2| on some other kind of failure.
@<Public function prototypes@> =
Marpa_Symbol_ID marpa_next_token_link_trace(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_next_token_link_trace(struct marpa_r *r)
{
   @<Return |-2| on failure@>@;
   SRCL full_link;
    EIM item;
    @<Fail recognizer if not trace-safe@>@;
    @<Set |item|, failing if necessary@>@;
    if (r->t_trace_source_type != SOURCE_IS_TOKEN) {
	trace_source_link_clear(r);
	R_ERROR("not tracing token links");
        return failure_indicator;
    }
    if (!r->t_trace_next_source_link) {
	trace_source_link_clear(r);
        return -1;
    }
    full_link = r->t_trace_next_source_link;
    r->t_trace_next_source_link = Next_SRCL_of_SRCL (full_link);
    r->t_trace_source = &(full_link->t_source);
    return Symbol_ID_of_SRCL (full_link);
}

@*1 Trace First Completion Link.
@ Set the trace source link to a completion link,
if there is one, otherwise clear the completion source link.
Returns the AHFA state ID of the cause
if there was a completion source link,
|-1| if there was none,
and |-2| on some other kind of failure.
@<Public function prototypes@> =
Marpa_Symbol_ID marpa_first_completion_link_trace(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_first_completion_link_trace(struct marpa_r *r)
{
   @<Return |-2| on failure@>@;
   SRC source;
   guint source_type;
    EIM item = r->t_trace_earley_item;
    @<Fail recognizer if not trace-safe@>@;
    @<Set |item|, failing if necessary@>@;
    switch ((source_type = Source_Type_of_EIM (item)))
      {
      case SOURCE_IS_COMPLETION:
	r->t_trace_source_type = SOURCE_IS_COMPLETION;
	source = &(item->t_container.t_unique);
	r->t_trace_source = source;
	r->t_trace_next_source_link = NULL;
	return Cause_AHFA_State_ID_of_SRC (source);
      case SOURCE_IS_AMBIGUOUS:
	{
	  SRCL completion_link = First_Completion_Link_of_EIM (item);
	  if (completion_link)
	    {
	      source = &(completion_link->t_source);
	      r->t_trace_source_type = SOURCE_IS_COMPLETION;
	      r->t_trace_next_source_link = Next_SRCL_of_SRCL (completion_link);
	      r->t_trace_source = source;
	      return Cause_AHFA_State_ID_of_SRC (source);
	    }
	}
      }
    trace_source_link_clear(r);
    return -1;
}

@*1 Trace Next Completion Link.
@ Set the trace source link to the next completion link,
if there is one.
Otherwise clear the trace source link.
@ Returns the symbol ID if there is
a next completion source link,
|-1| if there was none,
and |-2| on some other kind of failure.
@<Public function prototypes@> =
Marpa_Symbol_ID marpa_next_completion_link_trace(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_next_completion_link_trace(struct marpa_r *r)
{
   @<Return |-2| on failure@>@;
   SRC source;
   SRCL completion_link; 
    EIM item;
    @<Fail recognizer if not trace-safe@>@;
    @<Set |item|, failing if necessary@>@;
    if (r->t_trace_source_type != SOURCE_IS_COMPLETION) {
	trace_source_link_clear(r);
	R_ERROR("not tracing completion links");
        return failure_indicator;
    }
    if (!r->t_trace_next_source_link) {
	trace_source_link_clear(r);
        return -1;
    }
    completion_link = r->t_trace_next_source_link;
    r->t_trace_next_source_link = Next_SRCL_of_SRCL (r->t_trace_next_source_link);
    source = &(completion_link->t_source);
    r->t_trace_source = source;
    return Cause_AHFA_State_ID_of_SRC (source);
}

@*1 Trace First Leo Link.
@ Set the trace source link to a Leo link,
if there is one, otherwise clear the Leo source link.
Returns the AHFA state ID of the cause
if there was a Leo source link,
|-1| if there was none,
and |-2| on some other kind of failure.
@<Public function prototypes@> =
Marpa_Symbol_ID marpa_first_leo_link_trace(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID
marpa_first_leo_link_trace (struct marpa_r *r)
{
  @<Return |-2| on failure@>@;
  SRC source;
  guint source_type;
  EIM item = r->t_trace_earley_item;
  @<Fail recognizer if not trace-safe@>@;
  @<Set |item|, failing if necessary@>@;
  switch ((source_type = Source_Type_of_EIM (item)))
	{
	case SOURCE_IS_LEO:
	  r->t_trace_source_type = SOURCE_IS_LEO;
	  source = &(item->t_container.t_unique);
	  r->t_trace_source = source;
	  r->t_trace_next_source_link = NULL;
	  return Cause_AHFA_State_ID_of_SRC (source);
	case SOURCE_IS_AMBIGUOUS:
	  {
	    SRCL full_link =
	      First_Leo_SRCL_of_EIM (item);
	    if (full_link)
	      {
		source = &(full_link->t_source);
		r->t_trace_source_type = SOURCE_IS_LEO;
		r->t_trace_next_source_link = (SRCL)
		  Next_SRCL_of_SRCL (full_link);
		r->t_trace_source = source;
		return Cause_AHFA_State_ID_of_SRC (source);
	      }
	  }
	}
  trace_source_link_clear (r);
  return -1;
}

@*1 Trace Next Leo Link.
@ Set the trace source link to the next Leo link,
if there is one.
Otherwise clear the trace source link.
@ Returns the symbol ID if there is
a next Leo source link,
|-1| if there was none,
and |-2| on some other kind of failure.
@<Public function prototypes@> =
Marpa_Symbol_ID marpa_next_leo_link_trace(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID
marpa_next_leo_link_trace (struct marpa_r *r)
{
  @<Return |-2| on failure@>@/
  SRCL full_link;
  SRC source;
  EIM item;
  @<Fail recognizer if not trace-safe@>@/
  @<Set |item|, failing if necessary@>@/
  if (r->t_trace_source_type != SOURCE_IS_LEO)
    {
      trace_source_link_clear (r);
      R_ERROR("not tracing leo links");
      return failure_indicator;
    }
  if (!r->t_trace_next_source_link)
    {
      trace_source_link_clear (r);
      return -1;
    }
  full_link = r->t_trace_next_source_link;
  source = &(full_link->t_source);
  r->t_trace_source = source;
  r->t_trace_next_source_link =
    Next_SRCL_of_SRCL(r->t_trace_next_source_link);
  return Cause_AHFA_State_ID_of_SRC (source);
}

@ @<Set |item|, failing if necessary@> =
    item = r->t_trace_earley_item;
    if (!item) {
	trace_source_link_clear(r);
	R_ERROR("no eim");
        return failure_indicator;
    }

@*1 Clear Trace Source Link.
@ @<Private function prototypes@> =
static inline void trace_source_link_clear(struct marpa_r* r);
@ @<Function definitions@> =
static inline void trace_source_link_clear(struct marpa_r* r) {
    r->t_trace_next_source_link = NULL;
    r->t_trace_source = NULL;
    r->t_trace_source_type = NO_SOURCE;
}

@*1 Return the Predecessor AHFA State.
Returns the predecessor AHFA State,
or -1 if there is no predecessor.
If the recognizer is trace-safe,
there is no trace source link,
the trace source link is a Leo source,
or there is some other failure,
|-2| is returned.
@<Public function prototypes@> =
Marpa_AHFA_State_ID marpa_source_predecessor_state(struct marpa_r *r);
@ @<Function definitions@> =
AHFAID marpa_source_predecessor_state(struct marpa_r *r)
{
   @<Return |-2| on failure@>@/
   guint source_type;
   SRC source;
    @<Fail recognizer if not trace-safe@>@/
   source_type = r->t_trace_source_type;
    @<Set source, failing if necessary@>@/
    switch (source_type)
    {
    case SOURCE_IS_TOKEN:
    case SOURCE_IS_COMPLETION: {
        EIM predecessor = Predecessor_of_SRC(source);
	if (!predecessor) return -1;
	return AHFAID_of_EIM(predecessor);
    }
    }
    R_ERROR(invalid_source_type_message(source_type));
    return failure_indicator;
}

@*1 Return the Leo Transition Symbol.
The Leo transition symbol is defined only for sources
with a Leo predecessor.
The transition from a predecessor to the Earley item
containing a source will always be over exactly one symbol.
In the case of a Leo source, this symbol will be
the Leo transition symbol.
@ Returns the symbol ID of the Leo transition symbol.
If the recognizer is not trace-safe,
if there is no trace source link,
if the trace source link is not a Leo source,
or there is some other failure,
|-2| is returned.
@<Public function prototypes@> =
Marpa_Symbol_ID marpa_source_leo_transition_symbol(struct marpa_r *r);
@ @<Function definitions@> =
Marpa_Symbol_ID marpa_source_leo_transition_symbol(struct marpa_r *r)
{
   @<Return |-2| on failure@>@/
   guint source_type;
   SRC source;
    @<Fail recognizer if not trace-safe@>@/
   source_type = r->t_trace_source_type;
    @<Set source, failing if necessary@>@/
    switch (source_type)
    {
    case SOURCE_IS_LEO:
	return Leo_Transition_Symbol_ID_of_SRC(source);
    }
    R_ERROR(invalid_source_type_message(source_type));
    return failure_indicator;
}

@*1 Return the Middle Earleme.
Every source has a "middle earleme" defined.
Every source has
\li An origin (or start earleme).
\li An end earleme (the current set).
\li A "middle earleme".
An Earley item can be thought of as covering a "span"
from its origin to the current set.
For each source,
this span is divided into two pieces at the middle
earleme.
@ Informally, the middle earleme can be thought of as
dividing the span between the predecessor and either
the source's cause or its token.
If the source has no predecessor, the middle earleme
is the same as the origin.
If there is a predecessor, the middle earleme is
the current set of the predecessor.
If there is a cause, the middle earleme is always the same
as the origin of the cause.
If there is a token,
the middle earleme is always where the token starts.
@<Public function prototypes@> =
Marpa_Earleme marpa_source_middle(struct marpa_r* r);
@ The "predecessor set" is the earleme of the predecessor.
Returns |-1| if there is no predecessor.
If there are other failures, such as
there being no source link,
|-2| is returned.
@<Function definitions@> =
Marpa_Earleme marpa_source_middle(struct marpa_r* r)
{
   @<Return |-2| on failure@>@/
   const Marpa_Earleme no_predecessor = -1;
   guint source_type;
   SRC source;
    @<Fail recognizer if not trace-safe@>@/
   source_type = r->t_trace_source_type;
    @<Set source, failing if necessary@>@/
    switch (source_type)
      {
      case SOURCE_IS_LEO:
	{
	  LIM predecessor = Predecessor_of_SRC (source);
	  if (!predecessor) return no_predecessor;
	  return
	    Earleme_of_EIM (Base_EIM_of_LIM (predecessor));
	}
      case SOURCE_IS_TOKEN:
      case SOURCE_IS_COMPLETION:
	{
	  EIM predecessor = Predecessor_of_SRC (source);
	  if (!predecessor) return no_predecessor;
	  return Earleme_of_EIM (predecessor);
	}
    }
    R_ERROR(invalid_source_type_message (source_type));
    return failure_indicator;
}

@*1 Return the Token Value.
@<Public function prototypes@> =
gboolean marpa_source_token_value(struct marpa_r* r, gpointer* value_p);
@ If successful, returns |TRUE| and
writes the value of the token into |value_p|.
On failure, returns |FALSE|.
Possible failures include
the recognizer not being trace-safe,
there being no source link,
and the source link not being a token link.
@<Function definitions@> =
gboolean marpa_source_token_value(struct marpa_r* r, gpointer* value_p)
{
   @<Return |FALSE| on failure@>@;
   guint source_type;
   SRC source;
    @<Fail recognizer if not trace-safe@>@;
   source_type = r->t_trace_source_type;
    @<Set source, failing if necessary@>@;
    if (source_type == SOURCE_IS_TOKEN) {
	  *value_p = Token_Value_of_SRC (source);
	   return TRUE;
	}
    R_ERROR(invalid_source_type_message (source_type));
    return failure_indicator;
}

@ @<Set source, failing if necessary@> =
    source = r->t_trace_source;
    if (!source) {
	R_ERROR("no trace source link");
        return failure_indicator;
    }

@** Alternative Tokens (ALT) Code.
Because Marpa allows more than one token at every
earleme, Marpa's tokens are also called "alternatives".
@<Private incomplete structures@> =
struct s_alternative;
typedef struct s_alternative* ALT;
typedef const struct s_alternative* ALT_Const;
@
@d Token_ID_of_ALT(alt) ((alt)->t_token_id)
@d Token_Value_of_ALT(alt) ((alt)->t_token_value)
@d Start_ES_of_ALT(alt) ((alt)->t_start_earley_set)
@d Start_Earleme_of_ALT(alt) Earleme_of_ES(Start_ES_of_ALT(alt))
@d End_Earleme_of_ALT(alt) ((alt)->t_end_earleme)
@<Private structures@> =
struct s_alternative {
    SYMID t_token_id;
    void *t_token_value;
    ES t_start_earley_set;
    EARLEME t_end_earleme;
};
typedef struct s_alternative ALT_Object;

@ @<Widely aligned recognizer elements@> =
DSTACK_DECLARE(t_alternatives);
@ The value of |INITIAL_ALTERNATIVES_CAPACITY| is 1 for testing while this
code is being developed.
Once the code is stable it should be increased.
@d INITIAL_ALTERNATIVES_CAPACITY 1
@<Initialize recognizer elements@> =
DSTACK_INIT(r->t_alternatives, ALT_Object, INITIAL_ALTERNATIVES_CAPACITY);
@ @<Destroy recognizer elements@> = DSTACK_DESTROY(r->t_alternatives);

@ This functions returns the index at which to insert a new
alternative, or -1 if the new alternative is a duplicate.
(Duplicate alternatives should not be inserted.)
@<Private function prototypes@> =
static inline gint alternative_insertion_point(RECCE r, ALT new_alternative);
@ A variation of binary search.
@<Function definitions@> = 
static inline gint
alternative_insertion_point (RECCE r, ALT new_alternative)
{
  DSTACK alternatives = &r->t_alternatives;
  ALT alternative;
  gint hi = DSTACK_LENGTH(*alternatives) - 1;
  gint lo = 0;
  gint trial;
  // Special case when zero alternatives.
  if (hi < 0)
    return 0;
  alternative = DSTACK_BASE(*alternatives, ALT_Object);
  for (;;)
    {
      gint outcome;
      trial = lo + (hi - lo) / 2;
      outcome = alternative_cmp (new_alternative, alternative+trial);
      if (outcome == 0)
	return -1;
      if (outcome > 0)
	{
	  lo = trial + 1;
	}
      else
	{
	  hi = trial - 1;
	}
      if (hi < lo)
	return outcome > 0 ? trial + 1 : trial;
    }
}

@ This is a convenience function for setting up an alternative.
@<Private function prototypes@> =
static inline void alternative_set(
ALT alternative, ES start, EARLEME end, SYMID token_id, gpointer value);
@ @<Function definitions@> =
static inline void alternative_set(
ALT alternative, ES start, EARLEME end, SYMID token_id, gpointer value)
{
    alternative->t_token_id = token_id;
    alternative->t_token_value = value;
    alternative->t_start_earley_set = start;
    alternative->t_end_earleme = end;
}

@ This is the comparison function for sorting alternatives.
The alternatives array also acts as a stack, with the alternatives
ending at the lowest numbered earleme on top of the stack.
This allows alternatives to be popped off the stack as the
earlemes are processed in numerical order.
@<Private function prototypes@> =
static inline gint alternative_cmp(const ALT_Const a, const ALT_Const b);
@ So that the alternatives array can act as a stack,
the end earleme of the alternatives must be the major key,
and must sort in reverse order.
Of the remaining two keys,
the more minor key is the start earleme, because that way its slightly
costlier evaluation can sometimes be avoided.
@<Function definitions@> =
static inline gint alternative_cmp(const ALT_Const a, const ALT_Const b) {
     gint subkey = End_Earleme_of_ALT(b) - End_Earleme_of_ALT(a);
     if (subkey) return subkey;
     subkey = Token_ID_of_ALT(a) - Token_ID_of_ALT(b);
     if (subkey) return subkey;
     return Start_Earleme_of_ALT(a) - Start_Earleme_of_ALT(b);
}

@ This function pops an alternative from the stack, if it matches
the earleme argument.
If no alternative on the stack has its end earleme at the
earleme argument, |NULL| is returned.
The data pointed to by the return value may be overwritten when
new alternatives are added, so it must be used before the next
call that adds data to the alternatives stack.
@<Private function prototypes@> =
static inline ALT alternative_pop(RECCE r, EARLEME earleme);
@ @<Function definitions@> =
static inline ALT alternative_pop(RECCE r, EARLEME earleme)
{
    DSTACK alternatives = &r->t_alternatives;
    ALT top_of_stack = DSTACK_TOP(*alternatives, ALT_Object);
    if (!top_of_stack) return NULL;
    if (earleme != End_Earleme_of_ALT(top_of_stack)) return NULL;
    return DSTACK_POP(*alternatives, ALT_Object);
}

@ This function inserts an alternative into the stack, 
in sorted order,
if the alternative is not a duplicate.
It returns -1 if the alternative is a duplicate,
and the insertion point (which must be zero or more) otherwise.
@<Private function prototypes@> =
static inline gint alternative_insert(RECCE r, ALT alternative);
@ @<Function definitions@> =
static inline gint alternative_insert(RECCE r, ALT new_alternative)
{
  ALT top_of_stack, base_of_stack;
  DSTACK alternatives = &r->t_alternatives;
  gint ix;
  gint insertion_point = alternative_insertion_point (r, new_alternative);
  if (insertion_point < 0)
    return insertion_point;
  top_of_stack = DSTACK_PUSH(*alternatives, ALT_Object); // may change base
  base_of_stack = DSTACK_BASE(*alternatives, ALT_Object); // base will not change after this
   for (ix = top_of_stack-base_of_stack; ix > insertion_point; ix--) {
       base_of_stack[ix] = base_of_stack[ix-1];
   }
   base_of_stack[insertion_point] = *new_alternative;
   return insertion_point;
}

@** Starting Recognizer Input.
@ @<Public function prototypes@> = gboolean marpa_start_input(struct marpa_r *r);
@ @<Function definitions@> = gboolean marpa_start_input(struct marpa_r *r)
{
    ES set0;
    EIM item;
    EIK_Object key;
    AHFA state;
    GRAMMAR_Const g = G_of_R(r);
    const gint symbol_count_of_g = SYM_Count_of_G(g);
    @<Return |FALSE| on failure@>@;
    @<Fail if recognizer not initial@>@;
    @<Allocate recognizer workareas@>@;
    psar_reset(Dot_PSAR_of_R(r));
    @<Allocate recognizer's bit vectors for symbols@>@;
    @<Initialize Earley item work stacks@>@;
    LV_Phase_of_R(r) = input_phase;
    LV_Current_Earleme_of_R(r) = 0;
    set0 = earley_set_new(r, 0);
    LV_Latest_ES_of_R(r) = set0;
    LV_First_ES_of_R(r) = set0;
    state = AHFA_by_ID(0);
    key.t_origin = set0;
    key.t_state = state;
    key.t_set = set0;
    item = earley_item_create(r, key);
    state = Empty_Transition_of_AHFA(state);
    if (state) {
	key.t_state = state;
	item = earley_item_create(r, key);
    }
    postdot_items_create(r, set0);
    earley_set_update_items(r, set0);
    r->t_is_using_leo = r->t_use_leo_flag;
    return TRUE;
}

@** Read a Token Alternative.
The ordinary semantics of a parser generator is a token-stream
semantics.
The input is a sequence of $n$ tokens.
Every token is of length 1.
The tokens fill the locations from 0 to $n-1$.
The first token goes into location 0,
the next into location 1,
and so on up to location $n-1$.
@ In Marpa terms, a token-stream
corresponds to reading exactly one token alternative at every location.
In Marpa, the input locations are also called earlemes.
@ Marpa allows other models of the input besides the token stream model.
Tokens may be ambiguous -- that is, more than one token may occur
at any location.
Tokens vary in length -- tokens may be of any length greater than
or equal to one.
This means tokens can span multiple earlemes.
As a consequence,
there may be no tokens at some earlemes.
@ |marpa_alternative|, by enforcing a limit on token length and on
the furthest location, indirectly enforces a limit on the
number of earley sets and the maximum earleme location.
If tokens ending at location $n$ cannot be scanned, then clearly
the parse can
never reach location $n$.
@ Whether token rejection is considered a failure is
a matter for the upper layers to define.
Retrying rejected tokens is one way to implement the
important "Ruby Slippers" parsing technique.
On the other hand it is traditional,
and often quite reasonable,
to always treat rejection of a token as a fatal error.
@ Returns current earleme (which may be zero) on success.
If the token is rejected because it is not
expected, returns |-1|.
If the token is rejected as a duplicate
expected, returns |-3|.
On failure for other reasons, returns |-2|.
@ Rejection because a token is unexpected can a common
occurrence in an application---%
an application may use this function to try out
various alternatives.
Rejection because a token is a duplicate is more likely to be
a hard failure, but it is possible that an application will
also see this as a normal data path.
The general failures reported with |-2| will typically be
treated by the application as fatal errors.
@<Public function prototypes@> = gboolean marpa_alternative(struct marpa_r *r,
Marpa_Symbol_ID token_id, void *value, gint length);
@ @<Function definitions@> =
gboolean marpa_alternative(struct marpa_r *r,
Marpa_Symbol_ID token_id, void *token_value, gint length) {
    @<Return |-2| on failure@>@;
    const gint duplicate_token_indicator = -3;
    const gint unexpected_token_indicator = -1;
    ES current_earley_set;
    const EARLEME current_earleme = Current_Earleme_of_R(r);
    EARLEME target_earleme;
    @<Fail if recognizer not in input phase@>@;
    @<Fail if recognizer exhausted@>@;
    @<|marpa_alternative| initial check for failure conditions@>@;
    @<Set |current_earley_set|, failing if token is unexpected@>@;
    @<Set |target_earleme| or fail@>@;
    @<Insert alternative into stack, failing if token is duplicate@>@;
    return current_earleme;
}

@ @<|marpa_alternative| initial check for failure conditions@> = {
    const SYM_Const token = SYM_by_ID(G_of_R(r), token_id);
    if (!SYM_is_Terminal(token)) {
	R_ERROR("token is not a terminal");
	return failure_indicator;
    }
    if (length <= 0) {
	R_ERROR("token length negative or zero");
	return failure_indicator;
    }
    if (length >= EARLEME_THRESHOLD) {
	R_ERROR("token too long");
	return failure_indicator;
    }
}

@ @<Set |target_earleme| or fail@> = {
    target_earleme = current_earleme + length;
    if (target_earleme >= EARLEME_THRESHOLD) {
	r_context_clear(r);
	r_context_int_add(r, "target_earleme", target_earleme);
	R_ERROR_CXT("parse too long");
	return failure_indicator;
    }
}

@ If no postdot item is found at the current Earley set for this
item, the token ID is unexpected, and |unexpected_token_indicator| is returned.
The application can treat this as a fatal error.
The application can also use this as a mechanism to test alternatives,
in which case, returning |unexpected_token_indicator| is a perfectly normal data path.
This last is part of an important technique:
"Ruby Slippers" parsing.
@<Set |current_earley_set|, failing if token is unexpected@> = {
    current_earley_set = Current_ES_of_R (r);
    if (!current_earley_set) return unexpected_token_indicator;
    if (!First_PIM_of_ES_by_SYMID (current_earley_set, token_id))
	return unexpected_token_indicator;
}

@ Insert an alternative into the alternatives stack,
detecting if we are attempting to add the same token twice.
Two tokens are considered the same if
\li they have the same token ID, and
\li they have the same length, and
\li they have the same origin.
Because $|origin|+|token_length| = |current_earleme|$,
Two tokens at the same current earleme are the same if they
have the same token ID and origin.
By the same equation,
two tokens at the same current earleme are the same if they
have the same token ID and token length.
It is up to the higher layers to determine if rejection
of a duplicate token is a fatal error.
The Earley sets and items will not have been
altered by the attempt.
@<Insert alternative into stack, failing if token is duplicate@> =
{
  ALT_Object alternative;
    if (Furthest_Earleme_of_R (r) < target_earleme)
      LV_Furthest_Earleme_of_R (r) = target_earleme;
  alternative_set (&alternative,
		   current_earley_set, target_earleme, token_id, token_value);
  if (alternative_insert (r, &alternative) < 0)
    return duplicate_token_indicator;
}

@** Complete an Earley Set.
In the Aycock-Horspool variation of Earley's algorithm,
the two main phases are scanning and completion.
This section is devoted to the logic for completion.
@d Work_EIMs_of_R(r) DSTACK_BASE((r)->t_eim_work_stack, EIM)
@d Work_EIM_Count_of_R(r) DSTACK_LENGTH((r)->t_eim_work_stack)
@d WORK_EIMS_CLEAR(r) DSTACK_CLEAR((r)->t_eim_work_stack)
@d WORK_EIM_PUSH(r) DSTACK_PUSH((r)->t_eim_work_stack, EIM)
@<Widely aligned recognizer elements@> = DSTACK_DECLARE(t_eim_work_stack);
@ @<Initialize recognizer elements@> = DSTACK_ZERO_INIT(r->t_eim_work_stack);
@ @<Initialize Earley item work stacks@> =
    DSTACK_IS_INITIALIZED(r->t_eim_work_stack) ||
	DSTACK_INIT (r->t_eim_work_stack, EIM ,
	     MAX (1024, r->t_earley_item_warning_threshold));
@ @<Destroy recognizer elements@> = DSTACK_DESTROY(r->t_eim_work_stack);

@ The completion stack is initialized to a very high-ball estimate of the
number of completions per Earley set.
It will grow if needed.
Large stacks may needed for very ambiguous grammars.
@<Widely aligned recognizer elements@> = DSTACK_DECLARE(t_completion_stack);
@ @<Initialize recognizer elements@> = DSTACK_ZERO_INIT(r->t_completion_stack);
@ @<Initialize Earley item work stacks@> =
    DSTACK_IS_INITIALIZED(r->t_completion_stack) ||
    DSTACK_INIT (r->t_completion_stack, EIM ,
	     MAX (1024, r->t_earley_item_warning_threshold));
@ @<Destroy recognizer elements@> = DSTACK_DESTROY(r->t_completion_stack);

@ The completion stack is initialized to a very high-ball estimate of the
number of completions per Earley set.
It will grow if needed.
Large stacks may needed for very ambiguous grammars.
@<Widely aligned recognizer elements@> = DSTACK_DECLARE(t_earley_set_stack);
@ @<Initialize recognizer elements@> = DSTACK_ZERO_INIT(r->t_earley_set_stack);
@ @<Destroy recognizer elements@> = DSTACK_DESTROY(r->t_earley_set_stack);

@ This function returns the number of terminals expected on success.
On failure, it returns |-2|.
If the completion of the earleme left the parse exhausted, 0 is
returned.
@
While, if the completion of the earleme left the parse exhausted, 0 is
returned, the converse is not true if tokens may be longer than one earleme.
In those alternative input models, it is possible that no terminals are
expected at the current earleme, but other terminals might be expected
at later earlemes.
That means that the parse can be continued---%
it is not exhausted.
In those alternative input models,
if the distinction between zero terminals expected and an
exhausted parse is significant to the higher layers,
they must explicitly check the phase whenever this function
returns zero.
@<Public function prototypes@> =
Marpa_Earleme marpa_earleme_complete(struct marpa_r* r);
@ @<Function definitions@> =
Marpa_Earleme
marpa_earleme_complete(struct marpa_r* r)
{
  @<Return |-2| on failure@>@;
  EIM* cause_p;
  ES current_earley_set;
  EARLEME current_earleme;
  gint count_of_expected_terminals;
    bv_clear (r->t_bv_symid_is_expected);
    @<Initialize |current_earleme|@>@;
    @<Return 0 if no alternatives@>@;
    @<Initialize |current_earley_set|@>@;
    @<Scan from the alternative stack@>@;
    @<Pre-populate the completion stack@>@;
    while ((cause_p = DSTACK_POP(r->t_completion_stack, EIM))) {
      EIM cause = *cause_p;
        @<Add new Earley items for |cause|@>@;
    }
    postdot_items_create(r, current_earley_set);

    count_of_expected_terminals = bv_count (r->t_bv_symid_is_expected);
    if (count_of_expected_terminals <= 0
	&& Earleme_of_ES (current_earley_set) >= Furthest_Earleme_of_R (r))
      { /* If no terminals are expected, and there are no Earley items in
           uncompleted Earley sets, we can make no further progress.
	   The parse is "exhausted". */
	LV_R_is_Exhausted(r) = 1;
      }
    earley_set_update_items(r, current_earley_set);
    return count_of_expected_terminals;
}

@ @<Initialize |current_earleme|@> = {
  current_earleme = ++(LV_Current_Earleme_of_R(r));
  if (current_earleme > Furthest_Earleme_of_R (r))
    {
	LV_R_is_Exhausted(r) = 1;
	R_ERROR("parse exhausted");
	return failure_indicator;
     }
}

@ Create a new Earley set.  We know that it does not
exist.
@<Initialize |current_earley_set|@> = {
    current_earley_set = earley_set_new (r, current_earleme);
    LV_Next_ES_of_ES(Latest_ES_of_R(r)) = current_earley_set;
    LV_Latest_ES_of_R(r) = current_earley_set;
}

@ If there are no alternatives for this earleme
return 0 without creating an
Earley set.
The return value of 0 indicates that there are no terminals
which will be accepted at this earleme.
In the default (token stream) model of input,
this means that the parse is exhausted.
@<Return 0 if no alternatives@> = {
    ALT top_of_stack = DSTACK_TOP(r->t_alternatives, ALT_Object);
    if (!top_of_stack) return 0;
    if (current_earleme != End_Earleme_of_ALT(top_of_stack)) return 0;
}

@ @<Scan from the alternative stack@> =
{
  ALT alternative;
  while ((alternative = alternative_pop (r, current_earleme)))
    @<Scan an Earley item from alternative@>@;
}

@ @<Scan an Earley item from alternative@> =
{
  ES start_earley_set = Start_ES_of_ALT (alternative);
  SYMID token_id = Token_ID_of_ALT (alternative);
  PIM pim = First_PIM_of_ES_by_SYMID (start_earley_set, token_id);
  for ( ; pim ; pim = Next_PIM_of_PIM (pim)) {
      AHFA scanned_AHFA, prediction_AHFA;
      EIM scanned_earley_item;
      EIM predecessor = EIM_of_PIM (pim);
      if (!predecessor)
	continue;		// Ignore Leo items when scanning
      scanned_AHFA = To_AHFA_of_EIM_by_SYMID (predecessor, token_id);
      scanned_earley_item = earley_item_assign (r,
						current_earley_set,
						Origin_of_EIM (predecessor),
						scanned_AHFA);
      token_link_add (r, scanned_earley_item, predecessor, token_id,
	  Token_Value_of_ALT(alternative));
      prediction_AHFA = Empty_Transition_of_AHFA (scanned_AHFA);
      if (!prediction_AHFA) continue;
      scanned_earley_item = earley_item_assign (r,
						    current_earley_set,
						    current_earley_set,
						    prediction_AHFA);
    }
}

@ @<Pre-populate the completion stack@> = {
    EIM* work_earley_items = DSTACK_BASE (r->t_eim_work_stack, EIM );
    gint no_of_work_earley_items = DSTACK_LENGTH (r->t_eim_work_stack );
    gint ix;
    DSTACK_CLEAR(r->t_completion_stack);
    for (ix = 0;
         ix < no_of_work_earley_items;
	 ix++) {
	EIM earley_item = work_earley_items[ix];
	EIM* tos;
	if (!Earley_Item_is_Completion (earley_item))
	  continue;
	tos = DSTACK_PUSH (r->t_completion_stack, EIM);
	*tos = earley_item;
      }
    }

@ For the current completion cause,
add those Earley items it "causes".
@<Add new Earley items for |cause|@> =
{
  Marpa_Symbol_ID *complete_symbols = Complete_SYMIDARY_of_EIM (cause);
  gint count = Complete_SYM_Count_of_EIM (cause);
  ES middle = Origin_of_EIM (cause);
  gint symbol_ix;
  for (symbol_ix = 0; symbol_ix < count; symbol_ix++)
    {
      Marpa_Symbol_ID complete_symbol = complete_symbols[symbol_ix];
      @<Add new Earley items for |complete_symbol| and |cause|@>@;
    }
}

@ @<Add new Earley items for |complete_symbol| and |cause|@> =
{
  PIM postdot_item;
  for (postdot_item = First_PIM_of_ES_by_SYMID (middle, complete_symbol);
       postdot_item; postdot_item = Next_PIM_of_PIM (postdot_item))
    {
      EIM predecessor = EIM_of_PIM (postdot_item);
      EIM effect;
      AHFA effect_AHFA_state;
      if (predecessor)
	{ /* Not a Leo item */
	  @<Add effect, plus any prediction, for non-Leo predecessor@>@;
	}
      else
	{			/* A Leo item */
	  @<Add effect of Leo item@>@;
	  break;		/* When I encounter a Leo item,
				   I skip everything else for this postdot
				   symbol */
	}
    }
}

@ @<Add effect, plus any prediction, for non-Leo predecessor@> =
{
    ES origin = Origin_of_EIM(predecessor);
     effect_AHFA_state = To_AHFA_of_EIM_by_SYMID(predecessor, complete_symbol);
     effect = earley_item_assign(r, current_earley_set,
          origin, effect_AHFA_state);
     if (Earley_Item_has_No_Source(effect)) {
         /* If it has no source, then it is new */
         if (Earley_Item_is_Completion(effect)) {
	     @<Push effect onto completion stack@>@;
	 }
	 @<Add Earley item predicted by completion, if there is one@>@;
     }
     completion_link_add(r, effect, predecessor, cause);
}

@ @<Push effect onto completion stack@> = {
    EIM* tos = DSTACK_PUSH (r->t_completion_stack, EIM);
    *tos = effect;
}



@ @<Add Earley item predicted by completion, if there is one@> = {
  AHFA prediction_AHFA_state =
    Empty_Transition_of_AHFA (effect_AHFA_state);
  if (prediction_AHFA_state)
    {
      earley_item_assign (r, current_earley_set, current_earley_set,
			  prediction_AHFA_state);
    }
}

@ @<Add effect of Leo item@> = {
    LIM leo_item = LIM_of_PIM (postdot_item);
    ES origin = Origin_of_LIM (leo_item);
    effect_AHFA_state = Top_AHFA_of_LIM (leo_item);
    effect = earley_item_assign (r, current_earley_set,
				 origin, effect_AHFA_state);
    if (Earley_Item_has_No_Source (effect))
      {
	/* If it has no source, then it is new */
	@<Push effect onto completion stack@>@;
      }
    leo_link_add (r, effect, leo_item, cause);
}

@ @<Private function prototypes@> =
static inline void earley_set_update_items(RECCE r, ES set);
@ @<Function definitions@> =
static inline void earley_set_update_items(RECCE r, ES set) {
    EIM* working_earley_items;
    EIM* finished_earley_items;
    gint working_earley_item_count;
    gint i;
    if (!EIMs_of_ES(set)) {
        EIMs_of_ES(set) = g_new(EIM, EIM_Count_of_ES(set));
    } else {
        EIMs_of_ES(set) = g_renew(EIM, EIMs_of_ES(set), EIM_Count_of_ES(set));
    }
    finished_earley_items = EIMs_of_ES(set);
    working_earley_items = Work_EIMs_of_R(r);
    working_earley_item_count = Work_EIM_Count_of_R(r);
    for (i = 0; i < working_earley_item_count; i++) {
	 EIM earley_item = working_earley_items[i];
	 gint ordinal = Ord_of_EIM(earley_item);
         finished_earley_items[ordinal] = earley_item;
    }
    WORK_EIMS_CLEAR(r);
}

@ @<Private function prototypes@> =
static inline void r_update_earley_sets(RECCE r);
@ @d P_ES_of_R_by_Ord(r, ord) DSTACK_INDEX((r)->t_earley_set_stack, ES, (ord))
@d ES_of_R_by_Ord(r, ord) (*P_ES_of_R_by_Ord((r), (ord)))
@<Function definitions@> =
static inline void r_update_earley_sets(RECCE r) {
    ES set;
    ES first_unstacked_earley_set;
    if (!DSTACK_IS_INITIALIZED(r->t_earley_set_stack)) {
	first_unstacked_earley_set = First_ES_of_R(r);
	DSTACK_INIT (r->t_earley_set_stack, ES,
		 MAX (1024, ES_Count_of_R(r)));
    } else {
	 ES* top_of_stack = DSTACK_TOP(r->t_earley_set_stack, ES);
	 first_unstacked_earley_set = Next_ES_of_ES(*top_of_stack);
    }
    for (set = first_unstacked_earley_set; set; set = Next_ES_of_ES(set)) {
          ES* top_of_stack = DSTACK_PUSH(r->t_earley_set_stack, ES);
	  (*top_of_stack) = set;
    }
}

@** Create the Postdot Items.
@ This function inserts regular (non-Leo) postdot items into
the postdot list.
It is assumed that the caller has ensured this is not a duplicate.
@<Private function prototypes@> =
static void
postdot_items_create (struct marpa_r *r, ES set);
@ Not inlined, because of its size, and because it is used
twice -- once in initializing the Earley set 0,
and once for completing later Earley sets.
Earley set 0 is very much a special case, and it
might be a good idea to have
separate code to handle it,
in which case both could be inlined.
@ Leo items are not created for Earley set 0.
They are always optional, and add little at that point.
In that way I can avoid dealing with empty productions in
the Leo logic.
Empty productions only occur in dealing with the null parse,
and only in Earley set 0.
@<Function definitions@> =
static void
postdot_items_create (struct marpa_r *r, ES current_earley_set)
{
    gpointer * const pim_workarea = r->t_sym_workarea;
    GRAMMAR_Const g = G_of_R(r);
    Marpa_Earleme current_earley_set_id = Earleme_of_ES(current_earley_set);
    Bit_Vector bv_pim_symbols = r->t_bv_sym;
    Bit_Vector bv_lim_symbols = r->t_bv_sym2;
    bv_clear (bv_pim_symbols);
    bv_clear (bv_lim_symbols);
    @<Start EIXes in PIM workarea@>@;
    if (r->t_is_using_leo) {
	@<Start LIMs in PIM workarea@>@;
	@<Add predecessors to LIMs@>@;
    }
    @<Copy PIM workarea to postdot item array@>@;
    bv_and(r->t_bv_symid_is_expected, bv_pim_symbols, g->t_bv_symid_is_terminal);
}

@ This code creates the Earley indexes in the PIM workarea.
At this point there are no Leo items.
@<Start EIXes in PIM workarea@> = {
    EIM* work_earley_items = DSTACK_BASE (r->t_eim_work_stack, EIM );
    gint no_of_work_earley_items = DSTACK_LENGTH (r->t_eim_work_stack );
    gint ix;
    for (ix = 0;
         ix < no_of_work_earley_items;
	 ix++) {
	EIM earley_item = work_earley_items[ix];
      AHFA state = AHFA_of_EIM (earley_item);
      gint symbol_ix;
      gint postdot_symbol_count = Postdot_SYM_Count_of_AHFA (state);
      Marpa_Symbol_ID *postdot_symbols =
	Postdot_SYMID_Ary_of_AHFA (state);
      for (symbol_ix = 0; symbol_ix < postdot_symbol_count; symbol_ix++)
	{
	  PIM old_pim = NULL;
	  PIM new_pim;
	  Marpa_Symbol_ID symid;
	  new_pim = obstack_alloc (&r->t_obs, sizeof (EIX_Object));
	  symid = postdot_symbols[symbol_ix];
	  LV_Postdot_SYMID_of_PIM(new_pim) = symid;
	  LV_EIM_of_PIM(new_pim) = earley_item;
	  if (bv_bit_test(bv_pim_symbols, (guint)symid))
	      old_pim = pim_workarea[symid];
	  if (old_pim) {
	      LV_Next_PIM_of_PIM(new_pim) = old_pim;
	  } else {
	      LV_Next_PIM_of_PIM(new_pim) = NULL;
	      current_earley_set->t_postdot_sym_count++;
	  }
	  pim_workarea[symid] = new_pim;
	  bv_bit_set(bv_pim_symbols, (guint)symid);
	}
    }
}

@ This code creates the Earley indexes in the PIM workarea.
The Leo items do not contain predecessors or have the
predecessor-dependent information set at this point.
@ The origin and predecessor will be filled in later,
when the predecessor is known.
The top AHFA to-state is set to |NULL|,
and that will be used as an indicator that the fields
of this 
Leo item have not been fully populated.
@d LIM_is_Populated(leo) (Origin_of_LIM(leo) != NULL)
@<Start LIMs in PIM workarea@> = {
    guint min, max, start;
    for (start = 0; bv_scan (bv_pim_symbols, start, &min, &max); start = max + 2) {
	SYMID symid;
	for (symid = (SYMID)min; symid <= (SYMID) max; symid++) {
            PIM this_pim = pim_workarea[symid];
	    EIM leo_base;
	    AHFA base_to_ahfa;
	    if (Next_PIM_of_PIM(this_pim)) continue; /*
	        If there is more than one EIX, do not create a
		Leo item */
	    leo_base = EIM_of_PIM(this_pim);
	    base_to_ahfa = To_AHFA_of_EIM_by_SYMID(leo_base, symid);
	    if (!AHFA_is_Leo_Completion(base_to_ahfa)) continue;
	    @<Create a new, unpopulated, LIM@>@;
	}
    }
}

@ The Top AHFA of the new LIM is temporarily used
to memoize
the value of the AHFA to-state for the LIM's
base EIM.
That may become its actual value,
once it is populated.
@<Create a new, unpopulated, LIM@> = {
    LIM new_lim;
    new_lim = obstack_alloc(&r->t_obs, sizeof(*new_lim));
    LV_Postdot_SYMID_of_LIM(new_lim) = symid;
    LV_EIM_of_PIM(new_lim) = NULL;
    LV_Predecessor_LIM_of_LIM(new_lim) = NULL;
    LV_Origin_of_LIM(new_lim) = NULL;
    LV_Chain_Length_of_LIM(new_lim) = -1;
    LV_Top_AHFA_of_LIM(new_lim) = base_to_ahfa;
    LV_Base_EIM_of_LIM(new_lim) = leo_base;
    LV_ES_of_LIM(new_lim) = current_earley_set;
    LV_Next_PIM_of_LIM(new_lim) = this_pim;
    pim_workarea[symid] = new_lim;
    bv_bit_set(bv_lim_symbols, (guint)symid);
}

@ This code fully populates the data in the LIMs.
It determines the Leo predecesors of the LIMs, if any,
then populates that datum and the predecessor-dependent
data.
@ The algorithm is fast, if not a model of simplicity.
The LIMs are processed in an outer loop in order by
symbol ID, as well as in an inner loop which processes
predecessor chains from bottom to top.
It is very much possible that the
same LIM will be encountered twice,
once in each loop.
The code always checks to see if a LIM is
already populated,
before populating it.
@ The outer loop ensures that all LIMs are eventually
populated.  It uses the PIM workarea, guided by
a bit vector which indicates the LIM's.
@ It is possible for a LIM to be encountered which may have a predecessor,
but which cannot be immediately populated.
This is because predecessors link the LIMs in chains, and such chains
must be populated in order.
Any "links" in the chain of LIMs which are in previous Earley sets
will already be populated.
But a chain of LIMs may all be in the current Earley set, the
one we are currently processing.
In this case, there is a chicken-and-egg issue, which is
resolved by arranging those LIMs in chain link order,
and processing them in that order.
This is the business of the inner loop.
@ When a LIM is encountered which cannot be populated immediately,
its chain is followed and copied into |lim_chain|, which is in
effect a stack.  The chain ends when it reaches
a LIM which can be populated immediately.
@ A special case is when the LIM chain cycles back to the LIM
which started the chain.
When this happens, the LIM chain is terminated.
The bottom of such a chain
(which, since it is a cycle, is also the top)
is populated with a predecessor of
|NULL| and appropriate predecessor-dependent data.
@ {\bf Theorem}: The number of links
in a LIM chain is never more than the number
of symbols in the grammar.
{\bf Proof}: A LIM chain consists of the predecessors of LIMs,
all of which are in the same Earley set.
A LIM is uniquely determined by a duple of Earley set and transition symbol.
This means, in a single Earley set, there is at most one LIM per symbol.
{\bf QED}.
@ {\bf Complexity}: Time complexity is $O(n)$, where $n$ is the number
of LIMs.  This can be shown as follows:
\li The outer loop processes each LIM exactly once.
\li A LIM is never put onto a LIM chain if it is already populated.
\li A LIM is never taken off a LIM chain without being populated.
\li Based on the previous two observations, we know that a LIM will
be put onto a LIM chain at most once.
\li Ignoring the inner loop processing, the amount of processing done for each
LIM in the outer loop LIM is $O(1)$.
\li The amount of processing done for each LIM
in the inner loop is $O(1)$.
\li Total processing for all $n$ LIMs is therefore $n(O(1)+O(1))=O(n)$.
@ The |bv_ok_for_chain| is a vector of bits by symbol ID.
A bit is set if there is a LIM for that symbol ID that is OK for addition
to the LIM chain.
To be OK for addition to the LIM chain, the postdot item for the symbol
ID must
\li In fact actually be a Leo item (LIM).
\li Must not have been populated.
\li Must not have already been added to a LIM chain for this
Earley set.\par
@<Add predecessors to LIMs@> = {
  const Bit_Vector bv_ok_for_chain = r->t_bv_sym3;
  guint min, max, start;

  bv_copy(bv_ok_for_chain, bv_lim_symbols);
  for (start = 0; bv_scan (bv_lim_symbols, start, &min, &max);
       start = max + 2)
    { /* This is the outer loop.  It loops over the symbols IDs,
	  visiting only the symbols with LIMs. */
      SYMID main_loop_symbol_id;
      for (main_loop_symbol_id = (SYMID) min;
	  main_loop_symbol_id <= (SYMID) max;
	  main_loop_symbol_id++)
	{
	  LIM predecessor_lim;
	  LIM lim_to_process = pim_workarea[main_loop_symbol_id];
          if (LIM_is_Populated(lim_to_process)) continue; /* LIM may
	      have already been populated in the LIM chain loop */
	    @<Find predecessor LIM of unpopulated LIM@>@;
	    if (predecessor_lim && LIM_is_Populated(predecessor_lim)) {
	        @<Populate |lim_to_process| from |predecessor_lim|@>@;
		continue;
	    }
	    if (!predecessor_lim) { /* If there is no predecessor LIM to
	       populate, we know that we should populate from the base
	       Earley item */
	       @<Populate |lim_to_process| from its base Earley item@>@;
	       continue;
	    }
	   @<Create and populate a LIM chain@>@;
	}
    }
}

@ Find the predecessor LIM from the PIM workarea.
If the predecessor
starts at the current Earley set, I need to look in
the PIM workarea.
Otherwise the PIM item array by symbol is already
set up and I can find it there.
@ The LHS of the completed rule and of the applicable rule
in the base item will be the same, because the two rules
are the same.
Given the |main_loop_symbol_id| we can look up either the
appropriate rule in the base Earley item's AHFA state,
or the Leo completion's AHFA state.
It is most convenient to find the LHS of the completed
rule as the
only possible Leo LHS of the Leo completion's AHFA state.
The AHFA state for the Leo completion is guaranteed
to have only one rule.
The base Earley item's AHFA state can have multiple
rules, and in its list of rules there can
be transitions to Leo
completions via several different symbols.
@ This code only works for unpopulated LIMs,
because it relies on the Top AHFA value containing
the base AHFA to-state.
In a populated LIM, this will not necessarily be the case.
@<Find predecessor LIM of unpopulated LIM@> = {
    const EIM base_eim = Base_EIM_of_LIM(lim_to_process);
    const ES predecessor_set = Origin_of_EIM(base_eim);
    const AHFA base_to_ahfa = Top_AHFA_of_LIM(lim_to_process);
    const SYMID predecessor_transition_symbol = Leo_LHS_ID_of_AHFA(base_to_ahfa);
    PIM predecessor_pim;
    if (Earleme_of_ES(predecessor_set) < current_earley_set_id) {
	predecessor_pim
	= First_PIM_of_ES_by_SYMID (predecessor_set, predecessor_transition_symbol);
    } else {
        predecessor_pim = pim_workarea[predecessor_transition_symbol];
    }
    predecessor_lim = PIM_is_LIM(predecessor_pim) ? LIM_of_PIM(predecessor_pim) : NULL;
}

@ @<Create and populate a LIM chain@> = {
  gpointer* const lim_chain = r->t_workarea2;
  gint lim_chain_ix;
  @<Create a LIM chain@>@;
  @<Populate the LIMs in the LIM chain@>@;
}

@ At this point we know that
\li |lim_to_process != NULL|
\li |lim_to_process| is not populated
\li |predecessor_lim != NULL|
\li |predecessor_lim| is not populated
@ Cycles can occur in the LIM chain.  They are broken by refusing to
put the same LIM on LIM chain twice.  Since a LIM chain links are one-to-one,
ensuring that the LIM on the bottom of the chain is never added to the LIM
chain is enough to enforce this.
@ When I am about to add a LIM twice to the LIM chain, instead I break the
chain at that point.  The top of chain will then have no LIM predecesor,
instead of being part of a cycle.  Since the LIM information is always optional,
and in that case would be useless, breaking the chain in this way causes no
problems.
@<Create a LIM chain@> = {
     SYMID postdot_symid_of_lim_to_process
	 = Postdot_SYMID_of_LIM(lim_to_process);
    lim_chain_ix = 0;
    lim_chain[lim_chain_ix++] = LIM_of_PIM(lim_to_process);
	bv_bit_clear(bv_ok_for_chain, (guint)postdot_symid_of_lim_to_process);
	/* Make sure this LIM
	is not added to a LIM chain again for this Earley set */ @#
    while (1) {
	 lim_to_process = predecessor_lim; /* I know at this point that
	     |predecessor_lim| is unpopulated, so I also know that
	     |lim_to_process| is unpopulated.  This means I also know that
	     |lim_to_process| is in the current Earley set, because all LIMs
	     in previous Earley sets are already
	     populated. */ @#

	 postdot_symid_of_lim_to_process = Postdot_SYMID_of_LIM(lim_to_process);
	if (!bv_bit_test(bv_ok_for_chain, (guint)postdot_symid_of_lim_to_process)) {
	/* If I am about to add a previously added LIM to the LIM chain, I
	   break the LIM chain at this point.
	     The predecessor LIM has not yet been changed,
	     so that it is still appropriate for
	     the LIM at the top of the chain.  */
	    break;
	}

        @<Find predecessor LIM of unpopulated LIM@>@;

	lim_chain[lim_chain_ix++] = LIM_of_PIM(lim_to_process); /* 
	    |lim_to_process| is not populated, as shown above */

	bv_bit_clear(bv_ok_for_chain, (guint)postdot_symid_of_lim_to_process);
	/* Make sure this LIM
	is not added to a LIM chain again for this Earley set */ @#

	if (!predecessor_lim) break; /* |predecesssor_lim = NULL|,
	so that we are forced to break the LIM chain before it */ @#

	if (LIM_is_Populated(predecessor_lim)) break;
	/* |predecesssor_lim| is populated, so that if we
	break before |predecessor_lim|, we are ready to populate the entire LIM
	   chain. */
    }
}

@ @<Populate the LIMs in the LIM chain@> =
for (lim_chain_ix--; lim_chain_ix >= 0; lim_chain_ix--) {
    lim_to_process = lim_chain[lim_chain_ix];
    if (predecessor_lim && LIM_is_Populated(predecessor_lim)) {
	@<Populate |lim_to_process| from |predecessor_lim|@>@;
    } else {
	@<Populate |lim_to_process| from its base Earley item@>@;
    }
    predecessor_lim = lim_to_process;
}

@ @<Populate |lim_to_process| from |predecessor_lim|@> = {
LV_Predecessor_LIM_of_LIM(lim_to_process) = predecessor_lim;
LV_Origin_of_LIM(lim_to_process) = Origin_of_LIM(predecessor_lim);
LV_Chain_Length_of_LIM(lim_to_process) = 
    Chain_Length_of_LIM(lim_to_process)+1;
LV_Top_AHFA_of_LIM(lim_to_process) = Top_AHFA_of_LIM(predecessor_lim);
}

@ If we have reached this code, either we do not have a predecessor
LIM, or we have one which is useless for populating |lim_to_process|.
If a predecessor LIM is not itself populated, it will be useless
for populating its successor.
An unpopulated predecessor LIM
may occur when there is a predecessor LIM
which proved impossible to populate because it is part of a cycle.
@ The predecessor LIM and the top AHFA to-state were initialized
to the appropriate values for this case,
and do not need to be changed.
The predecessor LIM was initialized to |NULL|,
and the top AHFA to-state was initialized to the AHFA to-state
of the base EIM.
@<Populate |lim_to_process| from its base Earley item@> = {
  EIM base_eim = Base_EIM_of_LIM(lim_to_process);
  LV_Origin_of_LIM (lim_to_process) = Origin_of_EIM (base_eim);
  LV_Chain_Length_of_LIM(lim_to_process) =  0;
}

@ @<Copy PIM workarea to postdot item array@> = {
    PIM *postdot_array
	= current_earley_set->t_postdot_ary
	= obstack_alloc (&r->t_obs,
	       current_earley_set->t_postdot_sym_count * sizeof (PIM));
    guint min, max, start;
    gint postdot_array_ix = 0;
    for (start = 0; bv_scan (bv_pim_symbols, start, &min, &max); start = max + 2) {
	SYMID symid;
	for (symid = (SYMID)min; symid <= (SYMID) max; symid++) {
            PIM this_pim = pim_workarea[symid];
	    if (this_pim) postdot_array[postdot_array_ix++] = this_pim;
	}
    }
}

@** Expand the Leo Items.
\libmarpa/ expands Leo items on a "lazy" basis.
When an or-node is about to be populated, it is necessary to
examine all of the descendants of its Earley items.
If one of the or-nodes Earley items is a Leo completion,
these do not necessarily exist at that point,
and must be created.

@ This function returns the total of the lengths
of all the newly expanded Leo paths.
If this item was not
actually a Leo completion,
there will be no Leo paths,
and the return value will be zero.
Each Earley item is counted every time it appears in
a Leo path, which means that the total of the path
lengths may count the same Earley item
several times.
@ Some Earley items in the Leo paths will exist
before this function call,
others will be created.
Earley items in the Leo path will already exist
for several reasons:
\li The Leo completion item itself always exists before
this function call.
It is counted in the total path lengths,
once for each Leo path.
This means that the total of the Leo path lengths will never be less
than the number of Leo paths.
\li Any Leo competion base items.
One of these exists for every path
whose base is a
completed Earley item, and not a token.
\li Any other Earley item in the Leo path item which was already created
for other reasons.
If an Earley item in a Leo path already exists, a new Earley
item is not created ---
instead a source link is added to the present Earley item.
@<Private function prototypes@> =
static gint leo_completion_expand(RECCE r, EIM leo_completion);
@ @<Function definitions@> =
static gint leo_completion_expand(RECCE r, EIM leo_completion)
{
    gint leo_path_lengths = 0;
    const ES earley_set_of_this_path = ES_of_EIM(leo_completion);
    LIM this_lim = NULL;
    EIM previous_eim_on_this_path = NULL;
    SRCL next_leo_link = NULL;
    if (EIM_is_Leo_Expanded(leo_completion)) return 0; /* Do not
	Leo expand an EIM more than once */
    LV_EIM_is_Leo_Expanded(leo_completion) = 1;
    switch ( Source_Type_of_EIM (leo_completion))  {
    case SOURCE_IS_AMBIGUOUS: {
	 const SRCL leo_link = First_Leo_SRCL_of_EIM(leo_completion);
	 if (!leo_link) return 0;
	 @<Unpack values from Leo link@>@;
	 next_leo_link = Next_SRCL_of_SRCL(leo_link);
    }
     break;
    case SOURCE_IS_LEO:
      this_lim = Predecessor_of_EIM(leo_completion);
      previous_eim_on_this_path = Cause_of_EIM(leo_completion);
      leo_path_lengths += 2; /* Add 2, one for the Leo completion,
          one for its cause (the "Leo completion base item") */
      break;
    }
    if (!this_lim) return 0; /* Returns 0 if this is not a Leo completion
        and there is no Leo path */
    r->t_is_leo_expanding = 1; /* This boolean will disable the
        message which usually results
        when the Earley item warning threshold is exceeded */
    for (;;) {
         @<Expand a LIM chain@>@;
	 if (!next_leo_link) break;
	 {
	     const SRCL leo_link = next_leo_link;
	     next_leo_link = Next_SRCL_of_SRCL(leo_link);
	     @<Unpack values from Leo link@>@;
	 }
    }
    earley_set_update_items(r, earley_set_of_this_path);
    r->t_is_leo_expanding = 0;
     /* Turn Earley item "warning threshold exceeded" messages
        back on.  */
    return leo_path_lengths;
}

@ @<Unpack values from Leo link@> = {
	 this_lim = Predecessor_of_SRCL(leo_link);
	 previous_eim_on_this_path = Cause_of_SRCL(leo_link);
	 leo_path_lengths += 2; /* Add 2, one for the Leo completion,
		  one for its cause (the "Leo completion base item") */
}

@ @<Expand a LIM chain@> = {
    LIM next_lim;
    while ( ( next_lim = Predecessor_LIM_of_LIM(this_lim) )  ) {
	@<Expand LIMs above the bottom of the chain@>@;
	this_lim = next_lim;
    }
  completion_link_add (r, leo_completion, Base_EIM_of_LIM(this_lim), previous_eim_on_this_path); /*
      At the top of the chain, we only need to add a source link connecting
	our newly built chain to the Leo completion Earley item that is at its
	top. */
}

@ For each Leo item above the bottom, a new Earley item
must be created.
@<Expand LIMs above the bottom of the chain@> =
{
  const EIM base_eim_of_this_lim = Base_EIM_of_LIM (this_lim);
  const SYMID postdot_symbol_of_this_lim = Postdot_SYMID_of_LIM (this_lim);
  EIM new_eim_for_this_path =
    old_earley_item_assign (r, earley_set_of_this_path,
			ES_of_LIM (next_lim),
			To_AHFA_of_EIM_by_SYMID (base_eim_of_this_lim,
						 postdot_symbol_of_this_lim));
  leo_path_lengths++;
  completion_link_add (r, new_eim_for_this_path,
      base_eim_of_this_lim,
      previous_eim_on_this_path);
  previous_eim_on_this_path = new_eim_for_this_path;
}

@*0 External Function.
@ This is the external function to expand all
the Leo items for a Leo completion.
On success,
it returns the number of new Earley created.
This may be zero, if the Earley item is not in
fact a Leo completion.
On failure, this function returns |-2|.
@<Public function prototypes@> =
gint marpa_leo_completion_expand(struct marpa_r *r);
@ This function was created to allow |libmarpa| to be written
in stages --- while the evaluator is not yet converted to C,
it can call this function to expand |libmarpa|'s Leo completions.
I am undecided whether to keep this function after development.
It could be used by an application that decides it wants to expand
Leo completions on a more "eager" basis than |libmarpa| does.
@ @<Function definitions@> =
gint marpa_leo_completion_expand(struct marpa_r *r)
{
  @<Return |-2| on failure@>@;
  EIM item = r->t_trace_earley_item;
  @<Fail recognizer if not trace-safe@>@;
  if (!item) {
      @<Clear trace Earley item data@>@;
      R_ERROR("no trace eim");
      return failure_indicator;
  }
  return leo_completion_expand(r, item);
}

@** Evaluation --- Preliminary Notes.
Work on the evaluation code is not yet really underway,
but some relevant notes are by-products of other work.
These are collected here.

@*0 Alternate Start Rules.
Note that a start symbol only works if it is
on the LHS of just one rule.
This is not an issue with the main start symbol, because
Marpa uses an augmented grammar.
It {\bf is} an issue for alternate start symbols, when
I implement those, because an arbitrary symbol might be
on the LHS of several rules.

@ Possibilities:
\li Require alternate start be specified as a rule, not a symbol.
\li Allow alternate start symbols, but only if they are on the LHS of a
single rule.
I don't like this it it limits the ability of grammar writers
to do on-the-fly experiments.
\li Both of the above.  That certainly covers the bases,
but it is just one more interface
complication.

@ Note that even when a start rule is supplies, that does
not necessarily point to an unique Earley item.
A completed rule can belong to several different AHFA states.
That could be OK, because even so origin, current earleme
and the links will all be identical for all such Earley items.

@*0 Statistics on Completed LHS Symbols per AHFA State.
An AHFA state may contain completions for more than one LHS,
but that is rare in practical use, and the number of completed
LHS symbols in the exceptions remains low.
The very complex perl AHFA contains 271 states with completions.
Of these 268 have only one completed symbol.
The other three AHFA states complete only two different LHS symbols.
Two states have completions with both
a |term_hi| and a |indirob| on the LHS.
One state has completions for both a
|sideff| and an |mexpr|.
@ My HTML test grammars make the
same point more strongly.
My HTML parser generates grammars on the fly.
These HTML grammars can differ from each other.
because Marpa takes the HTML input into account when
generating the grammar.
In my HTML test suite,
14,782 of the AHFA states include one or more completions.
Not a single one has more than one completed LHS symbol.

@*0 Relationship of Earley Items to Or-Nodes.
Several Earley items may be the source of the same or-node,
but the or-node only keeps track of one.  This is sufficient,
because the Earley item is tracked by the or-node only for its
links and,
by the following theorem,
the links for every Earley item which is the source
of the same or-node must be the same.

@ {\bf Theorem}: If two Earley items are sources of the same or-node,
they have the same links.
{\bf Outline of Proof}:
No or-node results from a predicted Earley
item, so every Earley item which is the source of an or-node
is itself the result of a transition over a symbol from
another Earley item.  
So I can restrict my discussion to discovered Earley items.
For the same reason, I can assume all source links have
predecessors defined.

@ {\bf Shared Predot Lemma}: An AHFA state is either predicted,
or all its LR0 items share the same predot symbol.
{\bf Proof}:  Straightforward, based on the construction of
an AHFA.

@ {\bf EIM Lemma }: If two Earley items are sources of the same or-node,
they share the same origin ES, the same current ES and the same
predot symbol.
{\bf Proof of Lemma}:
Showing that the Earley items share the same origin and current
ES is straightforward, based on the or-node's construction.
They share at least one LR0 item in their AHFA states---%
the LR0 item which defines the or-node.
Because they share at least one LR0 item and because, by the
Shared Predot Lemma, every LR0
item in a discovered AHFA state has the same predot symbol,
the two Earley items also
share the same predot symbol.

@ {\bf Completion Source Lemma}:
A discovered Earley item has a completion source link if and only if
the origin ES of the link's predecessor,
the current ES of the link's cause
and the transition symbol match, respectively,
the origin ES, current ES and predot symbol of the discovered EIM.
{\bf Proof}: Based on the construction of EIMs.

@ {\bf Token Source Lemma}:
A discovered Earley item has a token source link if and only if
origin ES of the link's predecessor, the current ES of the link's cause
and the token symbol match, respectively,
the origin ES, current ES and predot symbol of the discovered EIM.
{\bf Proof}: Based on the construction of EIMs.

@ Source links are either completion source links or token source links.
The theorem for completion source links follows from the EIM Lemma and the
Completion Source Lemma.
The theorem for token source links follows from the EIM Lemma and the
Token Source Lemma.
{\bf QED}.

@*0 CHAF Duplicate And-Nodes.
There are three ways in which the same and-node can occur multiple
times as the descendant of a single or-node.
@ First, an or-node can have several different Earley items as
its source.  This is dealt with by noticing that in building the
or-node, we only use the source links of an Earley item, and
that these are always identical.  Therefore we can arbitrarily
select any one of the possible source Earley items to be
the or-node's "unique" Earley item source.
@ The second source of duplication is duplicate source links
for the same Earley item.
I prevent token source links from duplicating,
and the Leo logic does not allow duplicate Leo source links.
Completion source links are prevented from duplicating by
making the transition symbol part of its "signature",
and making sure the source link transition symbol matches
the predot symbol of the or-node.
@ A third source of duplication is the 
when different source links of the same Earley item share
a dotted rule.
This happen frequently enough to be an issue even for practical
grammars.

@** Evaluation.
I am frankly not quite sure what the return value of this function should be.
It is basically pass/fail, but some other information might be useful.
@<Public function prototypes@> =
gint marpa_eval_setup(struct marpa_r* r, Marpa_Rule_ID rule_id, Marpa_Earley_Set_ID ordinal);
@ @<Function definitions@> =
gint marpa_eval_setup(struct marpa_r* r, Marpa_Rule_ID rule_id, Marpa_Earley_Set_ID ordinal) {
    const gint no_parse = -1;
    @<Bocage setup locals@>@;
    r_update_earley_sets(r);
    obstack_init(&bocage_setup_obs);
    @<Return if function guards fail;
	set |end_of_parse_es| and |completed_start_rule|@>@;
    @<Find |start_eim|@>@;
    LV_Phase_of_R(r) = evaluation_phase;
    obstack_init(&bocage_setup_obs);
    @<Allocate bocage setup working data@>@;
    @<Traverse Earley sets to create bocage@>@;
    @<Deallocate bocage setup working data@>@;
    obstack_free(&bocage_setup_obs, NULL);
    return 1; // For now, just return 1
}

@ @<Bocage setup locals@> =
@<Return |-2| on failure@>@;
const GRAMMAR_Const g = G_of_R(r);
ES end_of_parse_es;
RULE completed_start_rule;
EIM start_eim = NULL;
struct s_bocage_setup_per_es {
     Bit_Vector was_earley_item_stacked;
};
struct s_bocage_setup_per_es* per_es_data = NULL;
struct obstack bocage_setup_obs;
guint total_earley_items_in_parse;

@ @<Return if function guards fail;
set |end_of_parse_es| and |completed_start_rule|@> =
{
    EARLEME end_of_parse_earleme;
    @<Fail if recognizer has fatal error@>@;
    switch (Phase_of_R (r))
      {
      default:
	R_ERROR ("recce not evaluation-ready");
	return failure_indicator;
      case input_phase:
      case evaluation_phase:
	break;
      }

    if (ordinal == -1)
      {
	end_of_parse_es = Current_ES_of_R (r);
      }
    else
      {				// ordinal != -1
	if (!ES_Ord_is_Valid (r, ordinal))
	  {
	    R_ERROR ("invalid es ordinal");
	    return failure_indicator;
	  }
	end_of_parse_es = ES_of_R_by_Ord (r, ordinal);
      }

    if (!end_of_parse_es)
      return no_parse;
    end_of_parse_earleme = Earleme_of_ES (end_of_parse_es);
    if (rule_id == -1) {
	completed_start_rule =
	  end_of_parse_earleme ? g->t_proper_start_rule : g->t_null_start_rule;
	if (!completed_start_rule)
	  return no_parse;
    } else {
      if (!RULEID_of_G_is_Valid (g, rule_id))
	{
	  R_ERROR ("invalid rule id");
	  return failure_indicator;
	}
      completed_start_rule = RULE_by_ID (g, rule_id);
    }
}

@
@<Allocate bocage setup working data@>=
{
  guint ix;
  guint earley_set_count = ES_Count_of_R (r);
  total_earley_items_in_parse = 0;
  per_es_data =
    obstack_alloc (&bocage_setup_obs,
		   sizeof (struct s_bocage_setup_per_es) * earley_set_count);
  for (ix = 0; ix < earley_set_count; ix++)
    {
      const ES_Const earley_set = ES_of_R_by_Ord (r, ix);
      const guint item_count = EIM_Count_of_ES (earley_set);
      total_earley_items_in_parse += item_count;
      per_es_data[ix].was_earley_item_stacked =
	bv_obs_create (&bocage_setup_obs, item_count);
    }
}

@ @<Traverse Earley sets to create bocage@>=
{
    const EIM *top_of_stack;
    FSTACK_DECLARE (stack, EIM);
    FSTACK_INIT (stack, EIM, total_earley_items_in_parse);
    *(FSTACK_PUSH (stack)) = start_eim;
    bv_bit_set (per_es_data[Ord_of_ES (ES_of_EIM (start_eim))].
	    was_earley_item_stacked, (guint)Ord_of_EIM (start_eim));
    while ((top_of_stack = FSTACK_POP (stack)))
    {
          const EIM_Const earley_item = *top_of_stack;
        guint source_type = Source_Type_of_EIM (earley_item);
        @<Push child Earley items from token sources@>@;
        @<Push child Earley items from completion sources@>@;
        @<Push child Earley items from Leo sources@>@;
    }
}

@ @<Push child Earley items from token sources@> =
{
  SRCL source_link = NULL;
  EIM push_candidate = NULL;
  switch (source_type)
    {
    case SOURCE_IS_TOKEN:
      push_candidate = Predecessor_of_EIM (earley_item);
      break;
    case SOURCE_IS_AMBIGUOUS:
      source_link = First_Token_Link_of_EIM (earley_item);
      if (source_link)
	{
	  push_candidate = Predecessor_of_SRCL (source_link);
	  source_link = Next_SRCL_of_SRCL (source_link);
	}
    }
  for (;;)
    {
      if (push_candidate) {
	  @<Put |push_candidate| on |stack| if not in bit vector@>@;
	}
	if (!source_link) break;
	push_candidate = Predecessor_of_SRCL (source_link);
	source_link = Next_SRCL_of_SRCL (source_link);
    }
}

@ @<Push child Earley items from completion sources@> =
{
  SRCL source_link = NULL;
  EIM push_candidates[2];
  switch (source_type)
    {
    case SOURCE_IS_COMPLETION:
      push_candidates[0] = Predecessor_of_EIM (earley_item);
      push_candidates[1] = Cause_of_EIM (earley_item);
      break;
    case SOURCE_IS_AMBIGUOUS:
      source_link = First_Completion_Link_of_EIM (earley_item);
      if (source_link)
	{
	  push_candidates[0] = Predecessor_of_SRCL (source_link);
	  push_candidates[1] = Cause_of_SRCL (source_link);
	  source_link = Next_SRCL_of_SRCL (source_link);
	} else {
	  push_candidates[0] = push_candidates[1] = NULL;
	}
	break;
    default:
	  push_candidates[0] = push_candidates[1] = NULL;
	  break;
    }
  while (push_candidates[1])
    {
      EIM push_candidate = push_candidates[0];
      if (push_candidate) {
	  @<Put |push_candidate| on |stack| if not in bit vector@>@;
      }
      push_candidate = push_candidates[1];
      @<Put |push_candidate| on |stack| if not in bit vector@>@;
      if (!source_link) break;
      push_candidates[0] = Predecessor_of_SRCL (source_link);
      push_candidates[1] = Cause_of_SRCL (source_link);
      source_link = Next_SRCL_of_SRCL (source_link);
    }
}

@ @<Push child Earley items from Leo sources@> =
{
  SRCL source_link = NULL;
  EIM push_candidate = NULL;
  LIM leo_predecessor = NULL;
  switch (source_type)
    {
    case SOURCE_IS_LEO:
      leo_predecessor = Predecessor_of_EIM (earley_item);
      push_candidate = Cause_of_EIM (earley_item);
      break;
    case SOURCE_IS_AMBIGUOUS:
      source_link = First_Leo_SRCL_of_EIM (earley_item);
      if (source_link)
	{
	  leo_predecessor = Predecessor_of_SRCL (source_link);
	  push_candidate = Cause_of_SRCL (source_link);
	  source_link = Next_SRCL_of_SRCL (source_link);
	}
      break;
    }
  while (push_candidate)
    {
	while (1) {
	    @<Put |push_candidate| on |stack| if not in bit vector@>@;
	    if (!leo_predecessor) break;
	    push_candidate = Base_EIM_of_LIM(leo_predecessor);
	    leo_predecessor = Predecessor_LIM_of_LIM(leo_predecessor);
        }
	if (!source_link) break;
	  leo_predecessor = Predecessor_of_SRCL (source_link);
	  push_candidate = Cause_of_SRCL (source_link);
	  source_link = Next_SRCL_of_SRCL (source_link);
    }
}

@ @<Put |push_candidate| on |stack| if not in bit vector@>= {
if (!bv_bit_test_and_set
    (per_es_data[Ord_of_ES (ES_of_EIM (push_candidate))].
     was_earley_item_stacked, (guint)Ord_of_EIM (push_candidate)))
  {
    *(FSTACK_PUSH (stack)) = push_candidate;
  }
}

@ @<Deallocate bocage setup working data@>= {
;
}

@ Predicted AFHA states can be skipped since they
contain no completions.
Note that AFHA state 0 is not marked as a predicted AHFA state,
even though it can contain a predicted AHFA item.
@ A linear search of the AHFA items is used.
As shown elsewhere in this document,
discovered AHFA states for practical grammars tend to be
very small---%
less than two AHFA items.
Size of the AHFA state is a function of the grammar, so
any reasonable search is $O(1)$ in terms of the length of
the input.
@ The search for the start Earley item is done once
per parse---%
$O(s)$, where $s$ is the size of the end of parse Earley set.
This makes it very hard to justify any precomputations to
help the search, because if they have to be done once per
Earley set, that is a $O(\wsize \cdot s')$ overhead,
where $\wsize$ is the length of the input, and where
$s'$ is the average size of an Earley set.
It is hard to believe that for practical grammars
that $O(\wsize \cdot s') <= O(s)$, which
is what it would take for any per-Earley set overhead
to make sense.
@<Find |start_eim|@> =
{
    gint eim_ix;
    EIM* const earley_items = EIMs_of_ES(end_of_parse_es);
    const RULEID sought_rule_id = ID_of_RULE(completed_start_rule);
    const gint earley_item_count = EIM_Count_of_ES(end_of_parse_es);
    for (eim_ix = 0; eim_ix < earley_item_count; eim_ix++) {
        const EIM earley_item = earley_items[eim_ix];
	const AHFA ahfa_state = AHFA_of_EIM(earley_item);
	if (Origin_Earleme_of_EIM(earley_item) > 0) continue; // Not a start EIM
	if (!AHFA_is_Predicted(ahfa_state)) {
	    gint aim_ix;
	    AIM* const ahfa_items = AIMs_of_AHFA(ahfa_state);
	    const gint ahfa_item_count = AIM_Count_of_AHFA(ahfa_state);
	    for (aim_ix = 0; aim_ix < ahfa_item_count; aim_ix++) {
		 const AIM ahfa_item = ahfa_items[aim_ix];
	         if (RULEID_of_AIM(ahfa_item) == sought_rule_id) {
		      start_eim = earley_item;
		      break;
		 }
	    }
	}
	if (start_eim) break;
    }
}

@ @<Public function prototypes@> =
gint marpa_eval_clear(struct marpa_r* r);
@ @<Function definitions@> =
gint marpa_eval_clear(struct marpa_r* r) {
    @<Return |-2| on failure@>@;
    @<Fail if recognizer has fatal error@>@;
    if (Phase_of_R(r) != evaluation_phase) {
	R_ERROR("recce not being evaluated");
	return failure_indicator;
    }
    LV_Phase_of_R(r) = input_phase;
    return 1; // For now, just return 1
}

@** Boolean Vectors.
Marpa's boolean vectors are adapted from
Steffen Beyer's Bit-Vector package on CPAN.
This is a combined Perl package and C library for handling
bit vectors.
Someone seeking a general bit vector package should
look at Steffen's instead.
|libmarpa|'s boolean vectors are tightly tied in
with its own needs and environment.
@<Private typedefs@> =
typedef guint Bit_Vector_Word;
typedef Bit_Vector_Word* Bit_Vector;
@ Some defines and constants
@d BV_BITS(bv) *(bv-3)
@d BV_SIZE(bv) *(bv-2)
@d BV_MASK(bv) *(bv-1)
@<Private global variables@> =
static const guint bv_wordbits = sizeof(Bit_Vector_Word)*8u;
static const guint bv_modmask = sizeof(Bit_Vector_Word)*8u-1u;
static const guint bv_hiddenwords = 3;
static const guint bv_lsb = 1u;
static const guint bv_msb = (1u << (sizeof(Bit_Vector_Word)*8u-1u));

@ Given a number of bits, compute the size.
@<Function definitions@> =
static inline guint bv_bits_to_size(guint bits)
{
    return (bits+bv_modmask)/bv_wordbits;
}
@ @<Private function prototypes@> =
static inline guint bv_bits_to_size(guint bits);
@ Given a number of bits, compute the unused-bit mask.
@<Function definitions@> =
static inline guint bv_bits_to_unused_mask(guint bits)
{
    guint mask = bits & bv_modmask;
    if (mask) mask = (guint) ~(~0uL << mask); else mask = (guint) ~0uL;
    return(mask);
}
@ @<Private function prototypes@> =
static inline guint bv_bits_to_unused_mask(guint bits);

@*0 Create a Boolean Vector.
@<Private function prototypes@> =
static inline Bit_Vector bv_create(guint bits);
@ Always start with an all-zero vector.
Note this code is a bit tricky ---
the pointer returned is to the data.
This is offset from the |g_malloc|'d space,
by |bv_hiddenwords|.
@<Function definitions@> =
static inline Bit_Vector bv_create(guint bits)
{
    guint size = bv_bits_to_size(bits);
    guint bytes = (size + bv_hiddenwords) << sizeof(guint);
    guint* addr = (Bit_Vector) g_malloc0((size_t) bytes);
    *addr++ = bits;
    *addr++ = size;
    *addr++ = bv_bits_to_unused_mask(bits);
    return addr;
}

@*0 Create a Boolean Vector on an Obstack.
@<Private function prototypes@> =
static inline Bit_Vector bv_obs_create(struct obstack *obs, guint bits);
@ Always start with an all-zero vector.
Note this code is a bit tricky ---
the pointer returned is to the data.
This is offset from the |g_malloc|'d space,
by |bv_hiddenwords|.
@<Function definitions@> =
static inline Bit_Vector
bv_obs_create (struct obstack *obs, guint bits)
{
  guint size = bv_bits_to_size (bits);
  guint bytes = (size + bv_hiddenwords) << sizeof (guint);
  guint *addr = (Bit_Vector) obstack_alloc (obs, (size_t) bytes);
  *addr++ = bits;
  *addr++ = size;
  *addr++ = bv_bits_to_unused_mask (bits);
  if (size > 0) {
      Bit_Vector bv = addr;
      while (size--) *bv++ = 0u;
  }
  return addr;
}


@*0 Shadow a Boolean Vector.
Create another vector the same size as the original, but with
all bits unset.
@<Function definitions@> =
static inline Bit_Vector bv_shadow(Bit_Vector bv)
{
    return bv_create(BV_BITS(bv));
}
@ @<Private function prototypes@> =
static inline Bit_Vector bv_shadow(Bit_Vector bv);

@*0 Clone a Boolean Vector.
Given a boolean vector, creates a new vector which is
an exact duplicate.
This call allocates a new vector, which must be |g_free|'d.
@<Function definitions@> = static inline
Bit_Vector bv_copy(Bit_Vector bv_to, Bit_Vector bv_from)
{
    guint *p_to = bv_to;
    const guint bits = BV_BITS(bv_to);
    if (bits > 0)
    {
        gint count = BV_SIZE(bv_to);
	while (count--) *p_to++ = *bv_from++;
    }
    return(bv_to);
}
@ @<Private function prototypes@> =
static inline
Bit_Vector bv_copy(Bit_Vector bv_to, Bit_Vector bv_from);

@*0 Clone a Boolean Vector.
Given a boolean vector, creates a new vector which is
an exact duplicate.
This call allocates a new vector, which must be |g_free|'d.
@<Function definitions@> = static inline
Bit_Vector bv_clone(Bit_Vector bv)
{
    return bv_copy(bv_shadow(bv), bv);
}
@ @<Private function prototypes@> =
static inline
Bit_Vector bv_clone(Bit_Vector bv);

@*0 Free a Boolean Vector.
@<Function definitions@> =
static inline void bv_free(Bit_Vector vector) {
    vector -= bv_hiddenwords;
    g_free(vector);
}
@ @<Private function prototypes@> =
static inline void bv_free(Bit_Vector vector);

@*0 The Number of Bytes in a Boolean Vector.
@<Function definitions@> =
static inline gint bv_bytes(Bit_Vector bv) {
    return (BV_SIZE(bv)+bv_hiddenwords)*sizeof(Bit_Vector_Word);
}
@ @<Private function prototypes@> =
static inline gint bv_bytes(Bit_Vector bv);

@*0 Fill a Boolean Vector.
@<Function definitions@> =
static inline void bv_fill(Bit_Vector bv)
{
    guint size = BV_SIZE(bv);
    if (size <= 0) return;
    while (size--) *bv++ = ~0u;
    --bv;
    *bv &= BV_MASK(bv);
}
@ @<Private function prototypes@> =
static inline void bv_fill(Bit_Vector bv);

@*0 Clear a Boolean Vector.
@ @<Private function prototypes@> =
static inline void bv_clear(Bit_Vector bv);
@ @<Function definitions@> =
static inline void bv_clear(Bit_Vector bv)
{
    guint size = BV_SIZE(bv);
    if (size <= 0) return;
    while (size--) *bv++ = 0u;
}

@*0 Set a Boolean Vector Bit.
@ @<Function definitions@> =
static inline void bv_bit_set(Bit_Vector vector, guint bit) {
    *(vector+(bit/bv_wordbits)) |= (bv_lsb << (bit%bv_wordbits));
}
@ @<Private function prototypes@> =
static inline void bv_bit_set(Bit_Vector vector, guint bit);

@*0 Clear a Boolean Vector Bit.
@<Function definitions@> =
static inline void bv_bit_clear(Bit_Vector vector, guint bit) {
    *(vector+(bit/bv_wordbits)) &= ~ (bv_lsb << (bit%bv_wordbits));
}
@ @<Private function prototypes@> =
static inline void bv_bit_clear(Bit_Vector vector, guint bit);

@*0 Test a Boolean Vector Bit.
@<Function definitions@> =
static inline gboolean bv_bit_test(Bit_Vector vector, guint bit) {
    return (*(vector+(bit/bv_wordbits)) & (bv_lsb << (bit%bv_wordbits))) != 0u;
}
@ @<Private function prototypes@> =
static inline gboolean bv_bit_test(Bit_Vector vector, guint bit);

@*0 Test and Set a Boolean Vector Bit.
Ensure that a bit is set and returning its value to the call.
@ @<Private function prototypes@> =
static inline gboolean bv_bit_test_and_set(Bit_Vector vector, guint bit);
@ @<Function definitions@> =
static inline gboolean
bv_bit_test_and_set (Bit_Vector vector, guint bit)
{
  Bit_Vector addr = vector + (bit / bv_wordbits);
  guint mask = bv_lsb << (bit % bv_wordbits);
  if ((*addr & mask) != 0u)
    return 1;
  *addr |= mask;
  return 0;
}

@*0 Set a Boolean Vector to all Ones.
@*0 Test a Boolean Vector for all Zeroes.
@<Function definitions@> =
static inline
gboolean bv_is_empty(Bit_Vector addr)
{
    guint  size = BV_SIZE(addr);
    gboolean r = TRUE;
    if (size > 0) {
        *(addr+size-1) &= BV_MASK(addr);
        while (r && (size-- > 0)) r = ( *addr++ == 0 );
    }
    return(r);
}
@ @<Private function prototypes@> =
static inline
gboolean bv_is_empty(Bit_Vector addr);

@*0 Bitwise-negate a Boolean Vector.
@<Function definitions@>=
static inline void bv_not(Bit_Vector X, Bit_Vector Y)
{
    guint size = BV_SIZE(X);
    guint mask = BV_MASK(X);
    while (size-- > 0) *X++ = ~*Y++;
    *(--X) &= mask;
}
@ @<Private function prototypes@> =
static inline void bv_not(Bit_Vector X, Bit_Vector Y);

@*0 Bitwise-and a Boolean Vector.
@<Function definitions@>=
static inline void bv_and(Bit_Vector X, Bit_Vector Y, Bit_Vector Z)
{
    guint size = BV_SIZE(X);
    guint mask = BV_MASK(X);
    while (size-- > 0) *X++ = *Y++ & *Z++;
    *(--X) &= mask;
}
@ @<Private function prototypes@> =
static inline void bv_and(Bit_Vector X, Bit_Vector Y, Bit_Vector Z);

@*0 Bitwise-or a Boolean Vector.
@<Function definitions@>=
static inline void bv_or(Bit_Vector X, Bit_Vector Y, Bit_Vector Z)
{
    guint size = BV_SIZE(X);
    guint mask = BV_MASK(X);
    while (size-- > 0) *X++ = *Y++ | *Z++;
    *(--X) &= mask;
}
@ @<Private function prototypes@> =
static inline void bv_or(Bit_Vector X, Bit_Vector Y, Bit_Vector Z);

@*0 Bitwise-or-assign a Boolean Vector.
@<Function definitions@>=
static inline void bv_or_assign(Bit_Vector X, Bit_Vector Y)
{
    guint size = BV_SIZE(X);
    guint mask = BV_MASK(X);
    while (size-- > 0) *X++ |= *Y++;
    *(--X) &= mask;
}
@ @<Private function prototypes@> =
static inline void bv_or_assign(Bit_Vector X, Bit_Vector Y);

@*0 Scan a Boolean Vector.
@<Function definitions@>=
static inline
gboolean bv_scan(Bit_Vector bv, guint start,
                                    guint* min, guint* max)
{
    guint  size = BV_SIZE(bv);
    guint  mask = BV_MASK(bv);
    guint  offset;
    guint  bitmask;
    guint  value;
    gboolean empty;

    if (size == 0) return FALSE;
    if (start >= BV_BITS(bv)) return FALSE;
    *min = start;
    *max = start;
    offset = start / bv_wordbits;
    *(bv+size-1) &= mask;
    bv += offset;
    size -= offset;
    bitmask = (guint)1 << (start & bv_modmask);
    mask = ~ (bitmask | (bitmask - (guint)1));
    value = *bv++;
    if ((value & bitmask) == 0)
    {
        value &= mask;
        if (value == 0)
        {
            offset++;
            empty = TRUE;
            while (empty && (--size > 0))
            {
                if ((value = *bv++)) empty = FALSE; else offset++;
            }
            if (empty) return FALSE;
        }
        start = offset * bv_wordbits;
        bitmask = bv_lsb;
        mask = value;
        while (!(mask & bv_lsb))
        {
            bitmask <<= 1;
            mask >>= 1;
            start++;
        }
        mask = ~ (bitmask | (bitmask - 1));
        *min = start;
        *max = start;
    }
    value = ~ value;
    value &= mask;
    if (value == 0)
    {
        offset++;
        empty = TRUE;
        while (empty && (--size > 0))
        {
            if ((value = ~ *bv++)) empty = FALSE; else offset++;
        }
        if (empty) value = bv_lsb;
    }
    start = offset * bv_wordbits;
    while (! (value & bv_lsb))
    {
        value >>= 1;
        start++;
    }
    *max = --start;
    return TRUE;
}
@ @<Private function prototypes@> =
static inline
gboolean bv_scan(
    Bit_Vector bv, guint start, guint* min, guint* max);

@*0 Count the bits in a Boolean Vector.
@<Function definitions@>=
static inline guint
bv_count (Bit_Vector v)
{
  guint start, min, max;
  guint count = 0;
  for (start = 0; bv_scan (v, start, &min, &max); start = max + 2)
    {
      count += max - min + 1;
    }
    return count;
}
@ @<Private function prototypes@> =
static inline guint bv_count (Bit_Vector v);

@*0 The RHS Closure of a Vector.
Despite the fact that they are actually tied closely to their
use in |libmarpa|, most of the logic of boolean vectors has
a "pure math" appearance.
This routine has a direct connection with the grammar.
\par
Several properties of symbols that need to be determined
have the property that, if
all the symbols on the RHS of any rule have that property,
so does its LHS symbol.
@ The RHS closure looks a lot like the transitive closure,
but there are several major differences.
The biggest difference is that
the RHS closure deals with properties and takes a {\bf vector} to another
vector;
the transitive closure is for a relation and takes a transition {\bf matrix}
to another transition matrix.
@ There are two properties of the RHS closure to note.
First, it is reflexive.
Any symbol in a set is in the RHS closure of that set.
@ Second, the RHS closure is vacuously true.
For any RHS closure property,
every symbol which is on the LHS of an empty rule has that property.
This means the RHS closure operation can only be used for
properties which can meaningfully be regarded as vacuously
true.
In |libmarpa|, two important symbol properties are
RHS clousure properties:
the property of being productive,
and the property of being nullable.

@*0 Produce the RHS Closure of a Vector.
This routine takes a symbol vector and a grammar,
and turns the original vector into the RHS closure of that vector.
The orignal vector is destroyed.
\par
If I decide rules should have a unique right hand symbol list,
this is one place to use it.
Duplicate symbols on the RHS are visited uselessly.
@<Function definitions@> =
static void
rhs_closure (struct marpa_g *g, Bit_Vector bv)
{
  guint min, max, start = 0;
  Marpa_Symbol_ID *top_of_stack = NULL;
  FSTACK_DECLARE (stack, Marpa_Symbol_ID);
  FSTACK_INIT (stack, Marpa_Symbol_ID, SYM_Count_of_G(g));
  while (bv_scan (bv, start, &min, &max))
    {
      guint symid;
      for (symid = min; symid <= max; symid++)
	{
	  *(FSTACK_PUSH (stack)) = symid;
	}
      start = max + 2;
    }
  while ((top_of_stack = FSTACK_POP (stack)))
    {
      guint rule_ix;
      GArray *rules = SYM_by_ID (g, *top_of_stack)->t_rhs;
      for (rule_ix = 0; rule_ix < rules->len; rule_ix++)
	{
	  Marpa_Rule_ID rule_id =
	    g_array_index (rules, Marpa_Rule_ID, rule_ix);
	  RULE rule = RULE_by_ID (g, rule_id);
	  guint rule_length;
	  guint rh_ix;
	  Marpa_Symbol_ID lhs_id = LHS_ID_of_PRD (rule);
	  if (bv_bit_test (bv, (guint) lhs_id))
	    goto NEXT_RULE;
	  rule_length = rule->t_length;
	  for (rh_ix = 0; rh_ix < rule_length; rh_ix++)
	    {
	      if (!bv_bit_test (bv, (guint) rhs_symid (rule, rh_ix)))
		goto NEXT_RULE;
	    }
	  /* If I am here, the bits for the RHS symbols are all
	   * set, but the one for the LHS symbol is not.
	   */
	  bv_bit_set (bv, (guint) lhs_id);
	  *(FSTACK_PUSH (stack)) = lhs_id;
	NEXT_RULE:;
	}
    }
  FSTACK_DESTROY (stack);
}
@ @<Private function prototypes@> =
static void rhs_closure(struct marpa_g* g, Bit_Vector bv);

@** Boolean Matrixes.
Marpa's Boolean matrixes are implemented differently
from the matrixes in
Steffen Beyer's Bit-Vector package on CPAN,
but like Beyer's matrixes are build on that package.
Beyer's matrixes are a single Boolean vector
which special routines index by row and column.
Marpa's matrixes are arrays of vectors.

Since there are "hidden words" before the data
in each vectors, Marpa must repeat these for each
row of a vector.  Consequences:
\li Marpa matrixes use a few extra bytes per row of space.
\li Marpa's matrix pointers cannot be used as vectors.
\li Marpa's rows {\bf can} be used as vectors.
\li Marpa's matrix pointers point to the beginning of
the allocated space.  |Bit_Vector| pointers use trickery
and include "hidden words" before the pointer.
@ Note that |typedef|'s for |Bit_Matrix|
and |Bit_Vector| are identical.
@s Bit_Matrix int
@<Private typedefs@> =
typedef Bit_Vector_Word* Bit_Matrix;

@*0 Create a Boolean Matrix.
@ Here the pointer returned is the actual start of the
|g_malloc|'d space.
This is {\bf not} the case with vectors, whose pointer is offset for
the "hidden words".
@<Function definitions@> =
static inline Bit_Matrix matrix_create(guint rows, guint columns)
{
    guint bv_data_words = bv_bits_to_size(columns);
    guint row_bytes = (bv_data_words + bv_hiddenwords) * sizeof(Bit_Vector_Word);
    guint bv_mask = bv_bits_to_unused_mask(columns);
    Bit_Vector_Word* matrix_addr = g_malloc0((size_t)(row_bytes * rows));
    guint row;
    for (row = 0; row < rows; row++) {
	guint row_start = row*(bv_data_words+bv_hiddenwords);
	matrix_addr[row_start] = columns;
	matrix_addr[row_start+1] = bv_data_words;
	matrix_addr[row_start+2] = bv_mask;
    }
    return matrix_addr;
}
@ @<Private function prototypes@> =
static inline Bit_Matrix matrix_create(guint rows, guint columns);

@*0 Free a Boolean Matrix.
@<Function definitions@> =
static inline void matrix_free(Bit_Matrix matrix) {
    g_free(matrix);
}
@ @<Private function prototypes@> =
static inline void matrix_free(Bit_Matrix matrix);

@*0 Find the Number of Columns in a Boolean Matrix.
The column count returned is for the first row.
It is assumed that 
all rows have the same number of columns.
Note that, in this implementation, the matrix has no
idea internally of how many rows it has.
@<Function definitions@> =
static inline gint matrix_columns(Bit_Matrix matrix) {
    Bit_Vector row0 = matrix+bv_hiddenwords;
     return BV_BITS(row0);
}
@ @<Private function prototypes@> =
static inline gint matrix_columns(Bit_Matrix matrix);

@*0 Find a Row of a Boolean Matrix.
Here's where the slight extra overhead of repeating
identical "hidden word" data for each row of a matrix
pays off.
This simply returns a pointer into the matrix.
This is adequate if the data is not changed.
If it is changed, the vector should be cloned.
There is a bit of arithmetic, to deal with the
hidden words offset.
@<Function definitions@> =
static inline Bit_Vector matrix_row(Bit_Matrix matrix, guint row) {
    Bit_Vector row0 = matrix+bv_hiddenwords;
    guint words_per_row = BV_SIZE(row0)+bv_hiddenwords;
    return row0 + row*words_per_row;
}
@ @<Private function prototypes@> =
static inline Bit_Vector matrix_row(Bit_Matrix matrix, guint row);

@*0 Set a Boolean Matrix Bit.
@ @<Function definitions@> =
static inline void matrix_bit_set(Bit_Matrix matrix, guint row, guint column) {
    Bit_Vector vector = matrix_row(matrix, row);
    bv_bit_set(vector, column);
}
@ @<Private function prototypes@> =
static inline void matrix_bit_set(Bit_Matrix matrix, guint row, guint column);

@*0 Clear a Boolean Matrix Bit.
@ @<Function definitions@> =
static inline void matrix_bit_clear(Bit_Matrix matrix, guint row, guint column) {
    Bit_Vector vector = matrix_row(matrix, row);
    bv_bit_clear(vector, column);
}
@ @<Private function prototypes@> =
static inline void matrix_bit_clear(Bit_Matrix matrix, guint row, guint column);

@*0 Test a Boolean Matrix Bit.
@ @<Function definitions@> =
static inline gboolean matrix_bit_test(Bit_Matrix matrix, guint row, guint column) {
    Bit_Vector vector = matrix_row(matrix, row);
    return bv_bit_test(vector, column);
}
@ @<Private function prototypes@> =
static inline gboolean matrix_bit_test(Bit_Matrix matrix, guint row, guint column);

@*0 Produce the Transitive Closure of a Boolean Matrix.
This routine takes a matrix representing a relation
and produces a matrix that represents the transitive closure
of the relation.
The matrix is assumed to be square.
The input matrix will be destroyed.
@<Function definitions@> =
static void transitive_closure(Bit_Matrix matrix)
{
      struct transition { guint from, to; } * top_of_stack = NULL;
      guint size = matrix_columns(matrix);
      guint row;
      DSTACK_DECLARE(stack);
      DSTACK_INIT(stack, struct transition, 1024);
      for (row = 0; row < size; row++) {
          guint min, max, start;
	  Bit_Vector row_vector = matrix_row(matrix, row);
	for ( start = 0; bv_scan(row_vector, start, &min, &max); start = max+2 ) {
	    guint column;
	    for (column = min; column <= max; column++) {
		struct transition *t = DSTACK_PUSH(stack, struct transition);
		t->from = row;
		t->to = column;
    } } }
    while ((top_of_stack = DSTACK_POP(stack, struct transition))) {
	guint old_from = top_of_stack->from;
	guint old_to = top_of_stack->to;
	guint new_ix;
	for (new_ix = 0; new_ix < size; new_ix++) {
	     /* Optimizations based on reuse of the same row are
	       probably best left to the compiler's optimizer.
	      */
	     if (!matrix_bit_test(matrix, new_ix, old_to) && 
	     matrix_bit_test(matrix, new_ix, old_from)) {
		 struct transition *t = (DSTACK_PUSH(stack, struct transition));
		  matrix_bit_set(matrix, new_ix, old_to);
		 t->from = new_ix;
		 t->to = old_to;
		}
	     if (!matrix_bit_test(matrix, old_from, new_ix) && 
	     matrix_bit_test(matrix, old_to, new_ix)) {
		 struct transition *t = (DSTACK_PUSH(stack, struct transition));
		  matrix_bit_set(matrix, old_from, new_ix);
		 t->from = old_from;
		 t->to = new_ix;
		}
	}
    }
      DSTACK_DESTROY(stack);
}
@ @<Private function prototypes@> =
static void transitive_closure(Bit_Matrix matrix);

@** Efficient Stacks and Queues.
@ The interface for these macros is somewhat hackish,
in that the user often
must be aware of the implementation of the
macros.
Arguably, using these macros is not
all that easier than
hand-writing each instance.
But the most important goal was safety -- by
writing this stuff once I have a greater assurance
that it is tested and bug-free.
Another important goal was that there be
no compromise on efficiency,
when compared to hand-written code.

@*0 Fixed Size Stacks.
|libmarpa| uses stacks and worklists extensively.
Often a reasonable maximum size is known when they are
set up, in which case they can be made very fast.
@d FSTACK_DECLARE(name, type) struct { gint t_count; type* t_base; } name;
@d FSTACK_INIT(name, type, n) ((name.t_count = 0), (name.t_base = g_new(type, n)))
@d FSTACK_PUSH(name) (name.t_base+name.t_count++)
@d FSTACK_POP(name) (name.t_count <= 0 ? NULL : name.t_base+(--name.t_count))
@d FSTACK_DESTROY(name) (g_free(name.t_base))

@*0 Dynamic Stacks.
|libmarpa| uses stacks and worklists extensively.
This stack interface resizes itself dynamically.
There are two disadvantages.

\li There is more overhead ---
overflow must be checked for with each push,
and the resizings, while fast, do take time.

\li The stack may be moved after any |DSTACK_PUSH|
operation, making all pointers into it invalid.
Data must be retrieved from the stack before the
next |DSTACK_PUSH|.

@d DSTACK_DECLARE(this) struct s_dstack this
@d DSTACK_INIT(this, type, initial_size)
  (((this).t_count = 0),
  ((this).t_base = g_new(type, ((this).t_capacity = (initial_size)))))

@ |DSTACK_ZERO_INIT| is for cases where the dstack is not
immediately initialized to a useful value,
and might never be.
All fields are zeroed so that when the containing object
is destroyed, the deallocation logic knows that no
memory has been allocated and therefore no attempt
to free memory should be made.
@d DSTACK_IS_INITIALIZED(this) ((this).t_base)
@d DSTACK_ZERO_INIT(this)
  (((this).t_count = (this).t_capacity = 0), ((this).t_base = NULL))

@ A stack reinitialized by
|DSTACK_CLEAR| contains 0 elements,
but has the same capacity as it had before the reinitialization.
This saves the cost of reallocating the dstack's buffer,
and leaves its capacity at what is hopefully
a stable, high-water mark, which will make future
resizings unnecessary.
@d DSTACK_CLEAR(this) ((this).t_count = 0)
@d DSTACK_PUSH(this, type)
    (((this).t_count >= (this).t_capacity ? dstack_resize(&(this), sizeof(type)) : 0),
     ((type *)(this).t_base+(this).t_count++))
@d DSTACK_POP(this, type) ((this).t_count <= 0 ? NULL :
    ( (type*)(this).t_base+(--(this).t_count)))
@d DSTACK_INDEX(this, type, ix) (DSTACK_BASE((this), type)+(ix))
@d DSTACK_TOP(this, type) (DSTACK_LENGTH(this) <= 0
   ? NULL
   : DSTACK_INDEX((this), type, DSTACK_LENGTH(this)-1))
@d DSTACK_BASE(this, type) ((type *)(this).t_base)
@d DSTACK_LENGTH(this) ((this).t_count)

@
|DSTACK|'s can have their data "stolen", by other containers.
The |STOLEN_DSTACK_DATA_FREE| macro is intended
to help the "thief" container
deallocate the data it now has "stolen".
@d STOLEN_DSTACK_DATA_FREE(data) ((data) && (g_free(data), 1))
@d DSTACK_DESTROY(this) STOLEN_DSTACK_DATA_FREE(this.t_base)

@<Private incomplete structures@> =
struct s_dstack;
typedef struct s_dstack* DSTACK;
@ @<Private utility structures@> =
struct s_dstack { gint t_count; gint t_capacity; gpointer t_base; };
@ @<Function definitions@> =
static inline gpointer dstack_resize(struct s_dstack* this, gsize type_bytes) {
    this->t_capacity *= 2;
    this->t_base = g_realloc(this->t_base, this->t_capacity*type_bytes);
    return this->t_base;
}
@ @<Private function prototypes@> =
static inline gpointer dstack_resize(struct s_dstack* this, gsize type_size);

@*0 Dynamic Queues.
This is simply a dynamic stack extended with a second
index.
These is no destructor at this point, because so far all uses
of this let another container "steal" the data from this one.
When one exists, it will simply call the dynamic stack destructor.
Instead I define a destructor for the "thief" container to use
when it needs to free the data.

@d DQUEUE_DECLARE(this) struct s_dqueue this
@d DQUEUE_INIT(this, type, initial_size)
    ((this.t_current=0), DSTACK_INIT(this.t_stack, type, initial_size))
@d DQUEUE_PUSH(this, type) DSTACK_PUSH(this.t_stack, type)
@d DQUEUE_POP(this, type) DSTACK_POP(this.t_stack, type)
@d DQUEUE_NEXT(this, type) (this.t_current >= DSTACK_LENGTH(this.t_stack)
    ? NULL
    : (DSTACK_BASE(this.t_stack, type))+this.t_current++)
@d DQUEUE_BASE(this, type) DSTACK_BASE(this.t_stack, type)
@d DQUEUE_END(this) DSTACK_LENGTH(this.t_stack)
@d STOLEN_DQUEUE_DATA_FREE(data) STOLEN_DSTACK_DATA_FREE(data)

@<Private incomplete structures@> =
struct s_dqueue;
typedef struct s_dqueue* DQUEUE;
@ @<Private structures@> =
struct s_dqueue { gint t_current; struct s_dstack t_stack; };

@** Per-Earley-Set List (PSL) Code.
There are several cases where Marpa needs to
look up a triple $\langle s,s',k \rangle$,
where $s$ and $s'$ are earlemes, and $0<k<\gsize$,
where $n$ is the number of AHFA items.
Earley items, or-nodes and and-nodes are examples.
Lookup for these needs to be $O(1)$
to justify Marpa's time complexity claims.
@
To obtain $O(1)$,
Marpa uses a special data structure, the Per-Earley-Set List.
The Per-Earley-Set Lists rely on the following being true:
\li It can be arranged so
that only one $s'$ is being considered at a time,
so that we are in fact looking up a duple $\langle s,k \rangle$.
\li In all cases of interest
we will have pointers available that take
us directly to all of the
Earley sets involved,
so that lookup of the data for an Earley set is $O(1)$.
\li The value of $k$ is always less than a constant.
Therefore any reasonable algorithm
for the search and insertion of $k$ is $O(1)$.
@ The idea is that each Earley set has a list of values
for all the keys $k$.
We arrange to consider only one Earley set $s$ at a time.
A pointer takes us to the Earley set $s'$ in $O(1)$ time.
Each Earley set has a list of values indexed by $k$.
Since this list is of a size less than a constant,
search and insertion in it is $O(1)$.
Thus each search and insertion for the triple
$\langle s,s',k \rangle$ takes $O(1)$ time.
@ The PSL's are kept in a linked list.
Each contains |Size_of_PSL| |gpointer|'s.
|t_owner| is the address of the location
that "owns" this PSL.
That location will be NULL'ed
when deallocating.
@<Private incomplete structures@> =
struct s_per_earley_set_list;
typedef struct s_per_earley_set_list *PSL;
@ @d Sizeof_PSL(psar)
    (sizeof(PSL_Object) + (psar->t_psl_length - 1) * sizeof(gpointer))
@d PSL_Datum(psl, i) ((psl)->t_data[(i)])
@d LV_PSL_Datum(psl, i) PSL_Datum((psl), (i))
@<Private structures@> =
struct s_per_earley_set_list {
    PSL t_prev;
    PSL t_next;
    PSL* t_owner;
    gpointer t_data[1];
};
typedef struct s_per_earley_set_list PSL_Object;
@ The per-Earley-set lists are allcated from per-Earley-set arenas.
@<Private incomplete structures@> =
struct s_per_earley_set_arena;
typedef struct s_per_earley_set_arena *PSAR;
@ The "dot" PSAR is to track earley items whose origin
or current earleme is at the "dot" location,
that is, the current Earley set.
The "predict" PSAR
is to track earley items for predictions
at locations other than the current earleme.
The "predict" PSAR
is used for predictions which result from
scanned items.
Since they are predictions, their current Earley set
and origin are at the same earleme.
This earleme will be somewhere after the current earleme.
@<Private structures@> =
struct s_per_earley_set_arena {
      guint t_psl_length;
      PSL t_first_psl;
      PSL t_first_free_psl;
};
typedef struct s_per_earley_set_arena PSAR_Object;
@ @d Dot_PSAR_of_R(r) (&(r)->t_dot_psar_object)
@<Widely aligned recognizer elements@> =
struct s_per_earley_set_arena t_dot_psar_object;
@ @<Initialize recognizer elements@> =
  psar_init(r, Dot_PSAR_of_R(r));
@ @<Destroy recognizer elements@> =
  psar_destroy(Dot_PSAR_of_R(r));
@ @<Private function prototypes@> =
static inline void psar_init(const RECCE r, const PSAR psar);
static inline void psar_destroy(const PSAR psar);
static inline PSL psl_new(const PSAR psar);
@ @<Function definitions@> =
static inline void
psar_init (const RECCE r, const PSAR psar)
{
  psar->t_psl_length = AHFA_Count_of_R (r);
  psar->t_first_psl = psar->t_first_free_psl = psl_new (psar);
}
@ @<Function definitions@> =
static inline void psar_destroy(const PSAR psar)
{
     PSL psl = psar->t_first_psl;
     while (psl) {
	  PSL next_psl = psl->t_next;
	PSL* owner = psl->t_owner;
	if (owner) *owner = NULL;
	  g_slice_free1(Sizeof_PSL(psar), psl);
	  psl = next_psl;
     }
}
@ @<Function definitions@> =
static inline PSL psl_new(const PSAR psar) {
     guint i;
     PSL new_psl = g_slice_alloc(Sizeof_PSL(psar));
     new_psl->t_next = NULL;
     new_psl->t_prev = NULL;
     new_psl->t_owner = NULL;
    for (i = 0; i < psar->t_psl_length; i++) {
	LV_PSL_Datum(new_psl, i) = NULL;
    }
     return new_psl;
}
@ This temporary data and perhaps should be keep track of on a per-phase
obstack.
@d Dot_PSL_of_ES(es) ((es)->t_dot_psl)
@d LV_Dot_PSL_of_ES(es) Dot_PSL_of_ES(es)
@<Widely aligned Earley set elements@> =
    PSL t_dot_psl;
@ @<Initialize Earley set PSL data@> =
{ set->t_dot_psl = NULL; }

@ A PSAR reset nulls out the data in the PSL's.
It is a moderately expensive operation, usually
avoided by having the logic check for "stale" data.
But when the PSAR is needed for a
a different type of PSL data,
one which will require different stale-detection logic,
the old PSL data need to be nulled.
@<Private function prototypes@> =
static inline void psar_reset(const PSAR psar);
@ @<Function definitions@> =
static inline void psar_reset(const PSAR psar) {
    PSL psl = psar->t_first_psl;
    while (psl && psl->t_owner) {
	guint i;
	for (i = 0; i < psar->t_psl_length; i++) {
	    LV_PSL_Datum(psl, i) = NULL;
	}
	psl = psl->t_next;
    }
    psar_dealloc(psar);
}

@ A PSAR dealloc removes an owner's claim to the all of
its PSLs,
and puts them back on the free list.
It does {\bf not} null out the stale PSL items.
@<Private function prototypes@> =
static inline void psar_dealloc(const PSAR psar);
@ @<Function definitions@> =
static inline void psar_dealloc(const PSAR psar) {
    PSL psl = psar->t_first_psl;
    while (psl) {
	PSL* owner = psl->t_owner;
	if (!owner) break;
	(*owner) = NULL;
	psl->t_owner = NULL;
	psl = psl->t_next;
    }
     psar->t_first_free_psl = psar->t_first_psl;
}


@ A PSL dealloc removes an owner's claim to the PSL,
and puts it back on the free list.
It does {\bf not} clear out the data.
A deallocated PSL contains stale data.
@<Private function prototypes@> =
static inline void psl_dealloc(const PSAR psar, const PSL psl);
@ @<Function definitions@> =
static inline void psl_dealloc(const PSAR psar, const PSL psl) {
    if (!psl) return;
    (*psl->t_owner) = NULL;
    psl->t_owner = NULL;
    @<Unlink |psl| from |psar|@>@;
    @<Link |psl| into |psar| after |t_first_free_psl|@>@;
}
@ @<Unlink |psl| from |psar|@> = {
    if (!psl->t_prev) { // If |psl| was first, set a new first PSL
         psar->t_first_psl = psar->t_first_psl->t_next;
	 psar->t_first_psl->t_prev = NULL;
    } else {
         psl->t_prev->t_next = psl->t_next;
	 /* |psl->t_next != NULL| if |psl| is in use */
         psl->t_next->t_prev = psl->t_prev;
    }
}
@ @<Link |psl| into |psar| after |t_first_free_psl|@> = {
    PSL first_free = psar->t_first_free_psl;
    psl->t_next = first_free->t_next;
    psl->t_prev = first_free;
    first_free->t_next = psl;
}
@ This function "claims" a PSL.
The address of the claimed PSL and the PSAR
from which to claim it are arguments.
The caller must ensure that
there is not a PSL already
at the claiming address.
@<Private function prototypes@> =
static inline void psl_claim(
    PSL* const psl_owner, const PSAR psar);
@ @<Function definitions@> =
static inline void psl_claim(
    PSL* const psl_owner, const PSAR psar) {
     PSL new_psl = psl_alloc(psar);
     (*psl_owner) = new_psl;
     new_psl->t_owner = psl_owner;
}

@ This function "allocates" a PSL.
It gets a free PSL from the PSAR.
There must always be at least one free PSL in a PSAR.
This function replaces the allocated PSL with
a new free PSL when necessary.
@ @<Private function prototypes@> =
static inline PSL psl_alloc(const PSAR psar);
@ @<Function definitions@> =
static inline PSL psl_alloc(const PSAR psar) {
    PSL free_psl = psar->t_first_free_psl;
    PSL next_psl = free_psl->t_next;
    if (!next_psl) {
        next_psl = free_psl->t_next = psl_new(psar);
	next_psl->t_prev = free_psl;
    }
    psar->t_first_free_psl = next_psl;
    return free_psl;
}

@** Memory Allocation.

@ By default,
a memory allocation failure
inside the Marpa library is a fatal error.
If this is a problem, the application can change
configure |g_malloc| to use its own allocator
which does something else on failure.
What else an application can do is not at all clear,
which is why the usual practice 
is to treatment memory allocation errors are
fatal, irrecoverable problems.

@ An error
in memory allocation will be logged
in the domain that |g_malloc|
is using, not in the domain being used by Marpa.

@ |libmarpa| uses |g_malloc|, either directly or indirectly.
Indirect use of |g_malloc| comes via obstacks and |g_slice|.
Both of these are more efficient, but both also
limit the ability to resize memory.
Obstacks also sharply limit the ability
to control the lifetime of the memory.
\par
It should be noted that the libraries used by |libmarpa| may
also allocate memory, using their own methods.
This allocation is often also |g_malloc| based.
\par
Obstacks are particularly useful for |libmarpa|.
Much of the memory allocated in |libmarpa| is
\li In individual allocations less than 4K, often considerable less.
\li Once created, are kept for the entire life of the either the grammar or the recognizer.
\li Once created, is never resized.
For these, obstacks are perfect.
|libmarpa|'s grammar has an obstacks.
Small allocations needed for the lifetime of the grammar
are allocated on these as the grammar object is built.
All these allocations are are conveniently and quickly deallocated when
the grammar's obstack is destroyed along with its parent grammar.
@d obstack_chunk_alloc g_malloc
@d obstack_chunk_free g_free

@*0 Why the obstacks are renamed.
Regretfully, I realized I simply could not simply include the
GNU obstacks, because of three obstacles.
First, the error handling is not thread-safe.  In fact,
since it relies on a global error handler, it is not even
safe for use by multiple libraries within one thread.
Since
the obstack "error handling" consisted of exactly one
"out of memory" message, which Marpa will never use because
it uses |g_malloc|, this risk comes at no benefit whatsoever.
Removing the error handling was far easier than leaving it
in.

@ Second, there were also portability complications
caused by the unneeded features of obstacks.
\li The GNU obtacks had a complex set of |ifdef|'s intended
to allow the same code to be part of GNU libc,
or not part of it, and the portability aspect of these
was daunting.
\li GNU obstack's lone error message was dragging in
GNU's internationalization.
(|libmarpa| avoids internationalization by leaving all
messaging and naming to the higher layers.)
It was far easier to rip out these features than to
deal with the issues they raised,
especially the portability
issues.

@ Third, if I did choose to try to use GNU obstacks in its
original form, |libmarpa| would have to deal with issues
of interposing identical function names in the linking process.
I aim at portability, even to systems that I have no
direct access to.
This is, of course, a real challenge when
it comes to debugging.
It was not cheering to think of the prospect
of multiple
libraries with obstack functions being resolved by the linkers
of widely different systems.
If, for example, a function that I intended to be used was not the
one linked, the bug would usually be a silent one.

@ Porting to systems with no native obstack meant that I was
already in the business of maintaining my own obstacks code,
whether I liked it or not.
The only reasonable alternative seemed to be
to create my own version of obstacks,
essentially copying the GNU implementation,
but eliminating the unnecessary
but problematic features.
Namespace issues could then be dealt with by
renaming the external functions.

@** External Failure Reports.
Most of
|libmarpa|'s external functions return failure under
one or more circumstances --- for
example, they may have been called incorrectly.
Many of the external routines share failure logic in
common.
I found it convenient to gather much of this logic here.

@ External routines will differ in the exact value
they return on failure.
Routines returning a pointer will return a |NULL|.
External routines which return an integer value
will return either |-2| as a general failure
indicator,
so that |-1| can be reserved for special purposes.
@ The circumstances under
which |-1| is returned are described in the section
for each external function call.
Typical meanings of |-1| are
"not defined", or "does not exist".

@ The final decision about the meaning of
return values is up to the higher layers.
A general failure return
(|NULL| or |-2|) will
typically be a hard failure.
A |-1| return may be reasonably be
interpreted as a normal
return value, a soft failure,
or a hard failure,
depending on the context.

@ For this reason,
all the logic in this section expects |failure_indication|
to be set in the scope in which it is used.
All failures treated in this section are general failures,
so that |-1| is not used as a return value.

@ Routines with nothing else to return often use |FALSE| as the failure indicator.
@<Return |FALSE| on failure@> = const gboolean failure_indicator = FALSE;
@ Routines returning pointers often use |NULL| as the failure indicator.
@<Return |NULL| on failure@> = const gpointer failure_indicator = NULL;
@ Routines returning integer value use |-2| as the
general failure indicator.
@<Return |-2| on failure@> = const int failure_indicator = -2;

@*0 Grammar Failures.
|g| is assumed to be the value of the relevant grammar,
when one is required.
@<Fail if grammar is precomputed@> =
if (G_is_Precomputed(g)) {
    g_context_clear(g);
    g->t_error = "grammar precomputed";
    return failure_indicator;
}
@ @<Fail if grammar not precomputed@> =
if (!G_is_Precomputed(g)) {
    g_context_clear(g);
    g->t_error = "grammar not precomputed";
    return failure_indicator;
}
@ @<Fail if grammar |symid| is invalid@> =
if (!symbol_is_valid(g, symid)) {
    g_context_clear(g);
    g_context_int_add(g, "symid", symid);
    g->t_error = "invalid symbol id";
    return failure_indicator;
}
@ @<Fail if grammar |rule_id| is invalid@> =
if (!RULEID_of_G_is_Valid(g, rule_id)) {
    g_context_clear(g);
    g_context_int_add(g, "rule_id", rule_id);
    g->t_error = "invalid rule id";
    return failure_indicator;
}
@ @<Fail if grammar |item_id| is invalid@> =
if (!item_is_valid(g, item_id)) {
    g_context_clear(g);
    g_context_int_add(g, "item_id", item_id);
    g->t_error = "invalid item id";
    return failure_indicator;
}
@ @<Fail if grammar |AHFA_state_id| is invalid@> =
if (!AHFA_state_id_is_valid(g, AHFA_state_id)) {
    g_context_clear(g);
    g_context_int_add(g, "AHFA_state_id", AHFA_state_id);
    g->t_error = "invalid AHFA state id";
    return failure_indicator;
}
@ @<Fail grammar if elements of |result| are not |sizeof(gint)|@> =
if (sizeof(gint) != g_array_get_element_size(result)) {
     g_context_clear(g);
     g_context_int_add(g, "expected size", sizeof(gint));
     g->t_error = "garray size mismatch";
     return failure_indicator;
}
@ @<Fail with internal grammar error@> = {
    g_context_clear(g);
    g->t_error = "internal error";
    return failure_indicator;
}

@*0 Recognizer Failures.
|r| is assumed to be the value of the relevant recognizer,
when one is required.
@<Fail if recognizer not initial@> =
if (Phase_of_R(r) != initial_phase) {
    R_ERROR("not initial recce phase");
    return failure_indicator;
}
@ @<Fail if recognizer initial@> =
if (Phase_of_R(r) == initial_phase) {
    R_ERROR("initial recce phase");
    return failure_indicator;
}
@ @<Fail if recognizer exhausted@> =
if (R_is_Exhausted(r)) {
    R_ERROR("recce exhausted");
    return failure_indicator;
}
@ @<Fail if recognizer not in input phase@> =
if (Phase_of_R(r) != input_phase) {
    R_ERROR("recce not in input phase");
    return failure_indicator;
}
@ @<Fail recognizer if not trace-safe@> =
switch (Phase_of_R(r)) {
default:
    R_ERROR("recce not trace-safe");
    return failure_indicator;
case input_phase:
case evaluation_phase:
break;
}
@ @<Fail if recognizer has fatal error@> =
if (Phase_of_R(r) == error_phase) {
    R_ERROR(r->t_fatal_error);
    return failure_indicator;
}
@ @<Fail if recognizer |symid| is invalid@> =
if (!symbol_is_valid(G_of_R(r), symid)) {
    r_context_clear(r);
    r_context_int_add(r, "symid", symid);
    R_ERROR_CXT("invalid symid");
    return failure_indicator;
}
@ @<Fail recognizer if |GArray| elements are not |sizeof(gint)|@> =
if (sizeof(gint) != g_array_get_element_size(result)) {
     r_context_clear(r);
     r_context_int_add(r, "expected size", sizeof(gint));
     R_ERROR_CXT("garray size mismatch");
     return failure_indicator;
}
@ @<Fail with internal recognizer error@> = 
{
    r_context_clear(r);
    R_FATAL("internal error");
    return failure_indicator;
}

@ The central error routine for the recognizer.
There are two flags which control its behavior.
One flag makes a error recognizer-fatal.
When there is a recognizer-fatal error, all
subsequent
invocations of external functions for that recognizer
object will fail.
It is a design goal of libmarpa to leave as much discretion
about error handling to the higher layers as possible.
Because of this, even the most severe errors
are not necessarily made recognizer-fatal.
|libmarpa| makes an
error recognizer-fatal only when the integrity of the
recognizer object is so thorougly compromised
that |libmarpa|'s external functions cannot proceed
without risking internal memory errors,
such as bus errors and segment violations.
"Recognizer-fatal" status is thus,
not a means of dictating to the higher layers that a
|libmarpa| condition must be application-fatal,
but a way of preventing a recognizer error from becoming
application-fatal without the application's consent.
@d FATAL_FLAG (0x1u)
@ Another flag indicates that the caller set up the
context.
By default, |r_error| clears the context.
@d CONTEXT_FLAG (0x2u)
@ Several convenience macros are provided.
These are easier and less error-prone
than specifying the flags.
Not being error-prone
is important since there are many calls to |r_error|
in the code.
@d R_ERROR(message) (r_error(r, (message), 0u))
@d R_ERROR_CXT(message) (r_error(r, (message), CONTEXT_FLAG))
@d R_FATAL(message) (r_error(r, (message), FATAL_FLAG))
@d R_FATAL_CXT(message) (r_error(r, (message), CONTEXT_FLAG|FATAL_FLAG))
@<Private function prototypes@> =
static void r_error( struct marpa_r* r, Marpa_Message_ID message, guint flags );
@ Not inlined.  |r_error|
occurs in the code quite often,
but |r_error|
should actually be invoked only in exceptional circumstances.
In this case space clearly is much more important than speed.
@<Function definitions@> =
static void r_error( struct marpa_r* r, Marpa_Message_ID message, guint flags ) {
    if (!(flags & CONTEXT_FLAG)) r_context_clear(r);
    r->t_error = message;
    if (flags & FATAL_FLAG) r->t_fatal_error = r->t_error;
    r_message(r, message);
}

@** Messages and Logging.
The main messaging system for |libmarpa| relies on callbacks
to upper layers.
But there are many cases in which it is not appropriate
to rely on the upper layers.
These cases include
serious internal problems,
memory allocation failures,
and debugging.

\par As a fallback messaging and logging system,
|libmarpa| uses |glib|'s Message Logging framework.
When the messsage domain is
under |libmarpa|'s control,
Marpa sets the domain to |"Marpa"|.
In many cases, such as memory allocation failures,
the domain will be as set by |glib|.
@ Set the Logging Domain
@<Logging domain@> =
#undef G_LOG_DOMAIN@/
#define G_LOG_DOMAIN "Marpa"@/

@*0 Message callbacks.
The user can define a callback
(with argument) which is invoked whenever |libmarpa|
has a message for the upper layers.
Note a lot of strings are used for convenience
in these messages.
These should be considered "cookies", 
as is they were file name or variables names.
They should not be regarded as part of the user
interface, even if some default or fallback routines
may sometimes expose them to the user.
And they should
not be subject to internationalization or localization.

These message cookies are always null-terminated in
the 7-bit ASCII character set.
This is a lowest common denominator, and is not a choice
binding on the upper layers,
which may use one of the Unicode encoding or anything
else.
Cookies often are mnemonics in the English language,
but this should not be regarded
as a reason to subject them to translation ---
at least not unless you are also translating the variable
names and file names.

The intent is to have all internationalization,
localization and string encoding issues dealt with
by the upper layers.
@<Public typedefs@> =
typedef const gchar* Marpa_Message_ID;

@* Grammar Messages.
@ Function pointer declarations are
hard to type and impossible to read.
This typedef localizes the damage.
@<Callback typedefs@> =
typedef void (Marpa_G_Message_Callback)(struct marpa_g *g, Marpa_Message_ID id);
@ @<Widely aligned grammar elements@> =
    Marpa_G_Message_Callback* t_message_callback;
    gpointer t_message_callback_arg;
@ @<Initialize grammar elements@> =
g->t_message_callback_arg = NULL;
g->t_message_callback = NULL;
@ @<Function definitions@> =
void marpa_g_message_callback_set(struct marpa_g *g, Marpa_G_Message_Callback*cb)
{ g->t_message_callback = cb; }
void marpa_g_message_callback_arg_set(struct marpa_g *g, gpointer cb_arg)
{ g->t_message_callback_arg = cb_arg; }
gpointer marpa_g_message_callback_arg(struct marpa_g *g)
{ return g->t_message_callback_arg; }
@ @<Public function prototypes@> =
void marpa_g_message_callback_set(struct marpa_g *g, Marpa_G_Message_Callback*cb);
void marpa_g_message_callback_arg_set(struct marpa_g *g, gpointer cb_arg);
gpointer marpa_g_message_callback_arg(struct marpa_g *g);
@ Do the message callback.
The name of this function is spelled out to avoid a conflict with a
|glib| function.
Note that the memory management assumes that the 
callback either exits or returns control to |libmarpa|.
A |longjmp| out of a callback will probably cause a memory leak.
@<Function definitions@> =
static inline void grammar_message(struct marpa_g *g, Marpa_Message_ID id)
{ Marpa_G_Message_Callback* cb = g->t_message_callback;
if (cb) { (*cb)(g, id); } }
@ @<Private function prototypes@> =
static inline void grammar_message(struct marpa_g *g, Marpa_Message_ID id);

@* Recognizer Messages.
@ Essentially the same as grammar messages,
except they live in and use the recognizer object.
@<Callback typedefs@> =
typedef void (Marpa_R_Message_Callback)(struct marpa_r *r, Marpa_Message_ID id);
@ @d Message_Callback_of_R(r) ((r)->t_message_callback)
@d Message_Callback_Arg_of_R(r) ((r)->t_message_callback_arg)
@<Widely aligned recognizer elements@> =
    Marpa_R_Message_Callback* t_message_callback;
    gpointer t_message_callback_arg;
@ @<Initialize recognizer elements@> =
r->t_message_callback_arg = NULL;
r->t_message_callback = NULL;
@ @<Function definitions@> =
void marpa_r_message_callback_set(struct marpa_r *r, Marpa_R_Message_Callback*cb)
{ r->t_message_callback = cb; }
void marpa_r_message_callback_arg_set(struct marpa_r *r, gpointer cb_arg)
{ r->t_message_callback_arg = cb_arg; }
gpointer marpa_r_message_callback_arg(struct marpa_r *r)
{ return Message_Callback_Arg_of_R(r); }
@ @<Public function prototypes@> =
void marpa_r_message_callback_set(struct marpa_r *r, Marpa_R_Message_Callback*cb);
void marpa_r_message_callback_arg_set(struct marpa_r *r, gpointer cb_arg);
gpointer marpa_r_message_callback_arg(struct marpa_r *r);
@ @<Function definitions@> =
static inline void r_message(struct marpa_r *r, Marpa_Message_ID id)
{ Marpa_R_Message_Callback* cb = Message_Callback_of_R(r);
if (cb) { (*cb)(r, id); } }
@ @<Private function prototypes@> =
static inline void r_message(struct marpa_r *r, Marpa_Message_ID id);

@** Debugging.
The |MARPA_DEBUG| flag enables intrusive debugging logic.
"Intrusive" debugging includes things which would
be annoying in production, such as detailed messages about
internal matters on |STDERR|.
@<Debug macros@> =
#define MARPA_DEBUG @[ 0 @]
#if MARPA_DEBUG
#define MARPA_DEBUG1(a) @[ g_debug((a)) @]
#define MARPA_DEBUG2(a, b) @[ g_debug((a),(b)) @]
#define MARPA_DEBUG3(a, b, c) @[ g_debug((a),(b),(c)) @]
#define MARPA_DEBUG4(a, b, c, d) @[ g_debug((a),(b),(c),(d)) @]
#else /* if not |MARPA_DEBUG| */
#define MARPA_DEBUG1(a) @[@]
#define MARPA_DEBUG2(a, b) @[@]
#define MARPA_DEBUG3(a, b, c) @[@]
#define MARPA_DEBUG4(a, b, c, d) @[@]
#endif

@*0 Earley Item Tag.
A function to print a descriptive tag for
an Earley item.
@<Private function prototypes@> =
#if MARPA_DEBUG
static inline gchar* eim_tag(gchar *buffer, EIM eim);
#endif
@ It is passed a buffer to keep it thread-safe.
@<Function definitions@> =
#if MARPA_DEBUG
static inline gchar*
eim_tag (gchar *buffer, EIM eim)
{
  sprintf (buffer, "S%d@@%d-%d",
	   AHFAID_of_EIM (eim), Origin_Earleme_of_EIM (eim), Earleme_of_EIM (eim));
	return buffer;
}
#endif

@*0 Leo Item Tag.
A function to print a descriptive tag for
an Leo item.
@<Private function prototypes@> =
#if MARPA_DEBUG
static inline gchar*
lim_tag (gchar *buffer, LIM lim);
#endif
@ This function is passed a buffer to keep it thread-safe.
be made thread-safe.
@<Function definitions@> =
#if MARPA_DEBUG
static inline gchar*
lim_tag (gchar *buffer, LIM lim)
{
  sprintf (buffer, "L%d@@%d",
	   Postdot_SYMID_of_LIM (lim), Earleme_of_LIM (lim));
	return buffer;
}
#endif

@** File Layout.  
@ The output files are {\bf not} source files,
but I add the license to them anyway,
as close to the top as possible.
@ Also, it is helpful to someone first
trying to orient herself,
if built source files contain a comment
to that effect and a warning
not that they are
not intended to be edited directly.
So I add such a comment.

@*0 |marpa.c| Layout.
@q This is a hack to get the @>
@q license language nearer the top of the files. @>
@ The physical structure of the |marpa.c| file
\tenpoint
@c
@=/*@>@/
@= * Copyright 2011 Jeffrey Kegler@>@/
@= * This file is part of Marpa::XS.  Marpa::XS is free software: you can@>@/
@= * redistribute it and/or modify it under the terms of the GNU Lesser@>@/
@= * General Public License as published by the Free Software Foundation,@>@/
@= * either version 3 of the License, or (at your option) any later version.@>@/
@= *@>@/
@= * Marpa::XS is distributed in the hope that it will be useful,@>@/
@= * but WITHOUT ANY WARRANTY; without even the implied warranty of@>@/
@= * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU@>@/
@= * Lesser General Public License for more details.@>@/
@= *@>@/
@= * You should have received a copy of the GNU Lesser@>@/
@= * General Public License along with Marpa::XS.  If not, see@>@/
@= * http://www.gnu.org/licenses/.@>@/
@= */@>@/
@=/*@>@/
@= * DO NOT EDIT DIRECTLY@>@/
@= * This file is written by ctangle@>@/
@= * It is not intended to be modified directly@>@/
@= */@>@/

@ \twelvepoint @c
#include "config.h"
#include "marpa.h"
@<Debug macros@>
@h
#include "marpa_obs.h"
@<Logging domain@>@;
@<Private incomplete structures@>@;
@<Private typedefs@>@;
@<Private global variables@>@;
@<Private utility structures@>@;
@<Private structures@>@;
@<Recognizer structure@>@;
@<Source object structure@>@;
@<Earley item structure@>@;
@<Private function prototypes@>@;
@<Private inline functions@>@;
@<Function definitions@>@;

@*0 |marpa.h| Layout.
@q This is a separate section in order to get the @>
@q license language nearer the top of the files. @>
@q It's hackish, but in a good cause. @>
@ The physical structure of the |marpa.h| file
\tenpoint
@(marpa.h@> =
@=/*@>@/
@= * Copyright 2011 Jeffrey Kegler@>@/
@= * This file is part of Marpa::XS.  Marpa::XS is free software: you can@>@/
@= * redistribute it and/or modify it under the terms of the GNU Lesser@>@/
@= * General Public License as published by the Free Software Foundation,@>@/
@= * either version 3 of the License, or (at your option) any later version.@>@/
@= *@>@/
@= * Marpa::XS is distributed in the hope that it will be useful,@>@/
@= * but WITHOUT ANY WARRANTY; without even the implied warranty of@>@/
@= * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU@>@/
@= * Lesser General Public License for more details.@>@/
@= *@>@/
@= * You should have received a copy of the GNU Lesser@>@/
@= * General Public License along with Marpa::XS.  If not, see@>@/
@= * http://www.gnu.org/licenses/.@>@/
@= */@>@/
@=/*@>@/
@= * DO NOT EDIT DIRECTLY@>@/
@= * This file is written by ctangle@>@/
@= * It is not intended to be modified directly@>@/
@= */@>@/

@ \twelvepoint
@(marpa.h@> =
#ifndef __MARPA_H__
#define __MARPA_H__ @/
#include <stdio.h>
#include <glib.h>
@<Body of public header file@>
#endif __MARPA_H__

@** Proofs.

For |libmarpa|, more than inspection of
the code is desirable to establish confidence
that it works as intended.
For some non-obvious points, proofs are useful
to increase the level of confidence.

@*0 Leo completion states are AHFA singletons.

@ {\bf Motivation:}
|libmarpa| combines Joop Leo's enhancements to the
Earley algorithm with those of Aycock and Horspool.
While it was clear such a thing would be
possible, given enough effort, it was {\bf not}
obvious that the combined algorithm would preserve
the efficiencies of the algorithms from which it
was derived.

This proof establishes the key fact to show that,
in fact, the Leo algorithm is compatible
with the Aycock and Horspool algorithms.
The following is an outline,
which assumes familiarity with the underlying algorithms.

@ {\bf Theorem:} In |libmarpa|,
all Leo completion states are in their own LR(0) state.

@ {\bf Proof:}
In |libmarpa|, every
Leo completion LR(0) item will have a non-nulling symbol,
by Leo's definitons.
Therefore, every Leo completion will have a final non-nulling
symbol.
Call the Leo completion item's final non-nulling symbol, $S$.

Call the LR(0) DFA state containing the Leo Completion item $C$.
Call the Leo completion LR(0) item $C1$.
Suppose, for reduction to absurdity,
that another LR(0) item is combined with
the Leo completion LR(0) item in the LR(0) DFA.
Call this second LR(0) item $C2$.

If so,
there must be Leo LR(0) DFA state,
$C_{predecessor}$, where two of the
LR(0) items, after a transition on symbol $S$,
produce both $C1$ and $C2$.
That means that in $C_{predecessor}$,
there are two LR(0) items with S as the postdot symbol,
and that these two items are predecessors of $C1$ and $C2$.
Call them $P1$ and $P2$.
$P1 \neq P2$, because $C1 \neq C2$ and different LR(0)
items always have different predecessors.

Therefore $C_{predecessor}$ will contain $P1$ and $P2$,
two LR(0) items, both
with $S$ as the postdot symbol.
But by Leo's definitions, the transition on the postdot
symbol into a Leo completion state
must be unique.
Therefore $C_{predecessor}$ cannot exist.
This completes the reduction to absurdity,
and the proof.
QED.

@ {\bf Theorem:}
All Leo completion states are in their own AHFA state.

{\bf Proof:}
By the theorem above, all Leo completion states are in
their own state in the LR(0) DFA.
The conversion to an epsilion-DFA will not add any items to this
state, because the only item in it is a completion item.
And conversion to a split epsilon-DFA will not add items.
So the Leo completion item will remain in its own state as
the AHFA is constructed.
QED.

@** Index.

