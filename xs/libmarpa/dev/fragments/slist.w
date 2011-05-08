% Copyright 2010 Jeffrey Kegler
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

% This code never used.  Saved in this file, just in case.

@ Public inline function definitions
None yet.
@<Public inline function definitions@> =

@ Header inline function definitions

This logic is only for inline functions which might need to be "public".
Those that are "local" to single translation unit should simply be 
declared |static inline| keyword.

"Public" inline functions (those which need to be visibile outside a
single translation unit) present complications.
These should have a non-inlined, "standalone" version in case they
are used where inlining is not possible.
(For instance, a pointer to them might be needed.)
Also, it is more complicated to make them portable.

There is no logic here to make the |inline| keyword portable.
Marpa expects autoconf to |#define| the |inline| keyword to
whatever is correct on the target,
so this logic uses that the |inline| keyword.

There is no guarantee, of course, that there is an inlining
keyword or that, if there is such a keyword,
that it actually does inlining.
If there is no inlining keyword, |inline| is |#define|'d
as the empty string.
If inlining actually words,
Marpa's configuration defines the |MARPA_CAN_INLINE| macro.

{|MARPA_STANDALONE| is defined in only one file, the file which should contain
the non-inlined ("standalone") definition of the inlined functions.
Marpa's public inlined functions should be declared |MARPA_PUBLIC_INLINE|.
Conditional compilation should be set up so that,
whenever |MARPA_PUBLIC_INLINE| is used,
|MARPA_STANDALONE| or |MARPA_CAN_INLINE| is defined.
\tolerance=9999\par}

@<Inlining macros@> =
#ifdef MARPA_STANDALONE
#define MARPA_PUBLIC_INLINE
#elif defined (__GNUC__) 
#define MARPA_PUBLIC_INLINE static __inline __attribute__ ((unused))
#elif MARPA_CAN_INLINE
#define MARPA_PUBLIC_INLINE static inline
#else
#define MARPA_PUBLIC_INLINE 
#endif

@ The file for standalone versions of the inline functions

@(standalone.c@> =

#define MARPA_STANDALONE 1
#include "marpa.h"

@** Templates.

@*0 Simple Lists.

@<Simple list public structure template@> =

#undef MARPA_SLIST_LINK
#define MARPA_SLIST_LINK(prefix) MARPA_CAT(prefix, _link)

struct MARPA_SLIST_LINK(MARPA_TEMPLATE_PREFIX) {
   struct MARPA_SLIST_LINK(MARPA_TEMPLATE_PREFIX) *next;
   MARPA_TEMPLATE_PAYLOAD payload;
};

@

@<Simple list public inline definition template@> =

#undef MARPA_SLIST_LINK
#define MARPA_SLIST_LINK(prefix) MARPA_CAT(prefix, _link)
#undef MARPA_SLIST_ADD
#define MARPA_SLIST_ADD(prefix) MARPA_CAT(prefix, _add)

MARPA_PUBLIC_INLINE void MARPA_SLIST_ADD(MARPA_TEMPLATE_PREFIX) (
    struct MARPA_SLIST_LINK(MARPA_TEMPLATE_PREFIX) **base,
    MARPA_TEMPLATE_PAYLOAD payload
) {
    struct MARPA_SLIST_LINK(MARPA_TEMPLATE_PREFIX) *next = *base;
    struct MARPA_SLIST_LINK(MARPA_TEMPLATE_PREFIX) *new
        = *base
        = g_malloc(sizeof(*next));
    new->next = next;
    new->payload = payload;
}

@

@<Simple list public prototype template@> =

#undef MARPA_SLIST_LINK
#define MARPA_SLIST_LINK(prefix) MARPA_CAT(prefix, _link)
#undef MARPA_SLIST_ADD
#define MARPA_SLIST_ADD(prefix) MARPA_CAT(prefix, _add)

MARPA_PUBLIC_INLINE void MARPA_SLIST_ADD(MARPA_TEMPLATE_PREFIX) (
    struct MARPA_SLIST_LINK(MARPA_TEMPLATE_PREFIX) **base,
    MARPA_TEMPLATE_PAYLOAD payload
);

