% Copyright 2013 Jeffrey Kegler
% This file is part of Marpa::R2.  Marpa::R2 is free software: you can
% redistribute it and/or modify it under the terms of the GNU Lesser
% General Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later version.
%
% Marpa::R2 is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser
% General Public License along with Marpa::R2.  If not, see
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

\def\title{Marpa's ami tools}
\def\topofcontents{\null\vfill
  \centerline{\titlefont Marpa's ami tools}
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
\def\size#1{\v #1\v}
\def\gsize{\v g\v}
\def\wsize{\v w\v}
\def\comment{\vskip\baselineskip}

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
@s MARPA_AVL_TRAV int
@s MARPA_AVL_TREE int
@s Bit_Matrix int
@s DAND int
@s DSTACK int
@s LBV int
@s Marpa_Bocage int
@s Marpa_IRL_ID int
@s Marpa_Rule_ID int
@s Marpa_Symbol_ID int
@s NOOKID int
@s NOOK_Object int
@s OR int
@s PIM int
@s PRIVATE int
@s PRIVATE_NOT_INLINE int
@s PSAR int
@s PSAR_Object int
@s PSL int
@s RULE int
@s RULEID int
@s XRL int

@** License.
\bigskip\noindent
@i copyright_page_license.w

@** About this library.
This is Marpa's ``ami'' or ``friend'' library, for macros
and functions which are useful for Libmarpa and its
``close friends''.
The contents of this library are considered ``undocumented'',
in the sense that
they are not documented for general use.
Specifically, the interfaces of these functions is subject
to radical change without notice,
and it is assumed that the safety of such changes can
be ensured by checking only Marpa itself and its ``close friend''
libraries.

A ``close friend'' library is one which is allowed
to rely on undocumented Libmarpa interfaces.
At this writing,
the only example of a ``close friend'' library is the Perl XS code which
interfaces libmarpa to Perl.

The ami interface and an internal interface differ in that
\li The ami interface must be useable in a situation where the Libmarpa
implementor does not have complete control over the namespace.
It can only create names which begin in |marpa_|, |_marpa_| or
one of its capitalization variants.
The internal interface can assume that no library will be included
unless the Libmarpa implementor decided it should be, so that most
names are available for his use.
\li The ami interface cannot use Libmarpa's error handling -- although
it can be part of the implementation of that error handlind.
The ami interface must be useable in a situation where another
error handling regime is in effect.

@** About this document.
This document is very much under construction,
enough so that readers may question why I make it
available at all.  Two reasons:
\li Despite its problems, it is the best way to read the source code
at this point.
\li Since it is essential to changing the code, not making it available
could be seen to violate the spirit of the open source.

@*0 Inlining.
Most of this code in |libmarpa|
will be frequently executed.
Inlining is used a lot.
Enough so
that it is useful to define a macro to let me know when inlining is not
used in a private function.
@s PRIVATE_NOT_INLINE int
@s PRIVATE int
@d PRIVATE_NOT_INLINE static
@d PRIVATE static inline

@*0 Marpa global Setup.

Marpa has no globals as of this writing.
For thread-safety, among other reasons,
I'll try to keep it that way.

@** Memory allocation.

@*0 Memory allocation failures.
@ By default,
a memory allocation failure
inside the Marpa library is a fatal error.
At some point I may allow this to be reset.
What else an application can do is not at all clear,
which is why the usual practice 
is to treatment memory allocation errors are
fatal, irrecoverable problems.
These functions all return |void*| in order
to avoid compiler warnings about void returns.
@<Function definitions@> =
PRIVATE_NOT_INLINE void*
_marpa_default_out_of_memory(void)
{
    abort();
}
void* (*_marpa_out_of_memory)(void) = _marpa_default_out_of_memory;

@ @<Utility variables@> =
extern void* (*_marpa_out_of_memory)(void);

@*0 Memory allocation.
libmarpa wrappers the standard memory functions
to provide more convenient behaviors.
\li The allocators do not return on failed memory allocations.
\li |my_realloc| is equivalent to |my_malloc| if called with
a |NULL| pointer.  (This is the GNU C library behavior.)
@ {\bf To Do}: @^To Do@>
For the moment, the memory allocators are hard-wired to
the C89 default |malloc| and |free|.
At some point I may allow the user to override
these choices.

@<Friend static inline functions@> =
static inline
void my_free (void *p)
{
  free (p);
}

@ The macro is defined because it is sometimes needed
to force inlining.
@<Friend static inline functions@> =
#define MALLOC_VIA_TEMP(size, temp) \
  (UNLIKELY(!((temp) = malloc(size))) ? (*_marpa_out_of_memory)() : (temp))
static inline
void* my_malloc(size_t size)
{
    void *newmem;
    return MALLOC_VIA_TEMP(size, newmem);
}

static inline
void*
my_malloc0(size_t size)
{
    void* newmem = my_malloc(size);
    memset (newmem, 0, size);
    return newmem;
}

static inline
void*
my_realloc(void *p, size_t size)
{
   if (LIKELY(p != NULL)) {
	void *newmem = realloc(p, size);
	if (UNLIKELY(!newmem)) (*_marpa_out_of_memory)();
	return newmem;
   }
   return my_malloc(size);
}

@ @<Utility macros@> =
#define my_new(type, count) ((type *)my_malloc((sizeof(type)*(count))))
#define my_renew(type, p, count) \
    ((type *)my_realloc((p), (sizeof(type)*(count))))

@** Debugging.
The |MARPA_DEBUG| flag enables intrusive debugging logic.
``Intrusive" debugging includes things which would
be annoying in production, such as detailed messages about
internal matters on |STDERR|.
|MARPA_DEBUG| is expected to be defined in the |CFLAGS|.
|MARPA_DEBUG| implies |MARPA_ENABLE_ASSERT|, but not
vice versa.
@<Utility macros@> =
#define MARPA_OFF_DEBUG1(a)
#define MARPA_OFF_DEBUG2(a, b)
#define MARPA_OFF_DEBUG3(a, b, c)
#define MARPA_OFF_DEBUG4(a, b, c, d)
#define MARPA_OFF_DEBUG5(a, b, c, d, e)
#define MARPA_OFF_ASSERT(expr)
@ Returns int so that it can be portably used
in a logically-anded expression.
@<Debug function definitions@> =
int _marpa_default_debug_handler (const char *format, ...)
{
   va_list args;
   va_start (args, format);
   vfprintf (stderr, format, args);
   va_end (args);
   putc('\n', stderr);
   return 1;
}

@ @<Utility variables@> =
extern int (*_marpa_debug_handler)(const char*, ...);
extern int _marpa_debug_level;
@ For thread-safety, these are for debugging only.
Even in debugging, while not actually initialized constants,
they are intended to be set very early
and left unchanged.
@<Utility variables@> =
#if MARPA_DEBUG > 0
extern int _marpa_default_debug_handler (const char *format, ...);
#define MARPA_DEFAULT_DEBUG_HANDLER _marpa_default_debug_handler
#else
#define MARPA_DEFAULT_DEBUG_HANDLER NULL
#endif

@ @<Global variables@> =
int (*_marpa_debug_handler)(const char*, ...) =
    MARPA_DEFAULT_DEBUG_HANDLER;
int _marpa_debug_level = 0;

@ @<Public function prototypes@> =
void marpa_debug_handler_set( int (*debug_handler)(const char*, ...) );
@ @<Function definitions@> =
void marpa_debug_handler_set( int (*debug_handler)(const char*, ...) )
{
    _marpa_debug_handler = debug_handler;
}

@ @<Public function prototypes@> =
void marpa_debug_level_set( int level );
@ @<Function definitions@> =
void marpa_debug_level_set( int level )
{
    _marpa_debug_level = level;
}

@ @<Debug macros@> =

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#if MARPA_DEBUG

#undef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 1

#define MARPA_DEBUG1(a) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)(a)) @]
#define MARPA_DEBUG2(a,b) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b))) @]
#define MARPA_DEBUG3(a,b,c) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c))) @]
#define MARPA_DEBUG4(a,b,c,d) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c),(d))) @]
#define MARPA_DEBUG5(a,b,c,d,e) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c),(d),(e))) @]

#define MARPA_ASSERT(expr) do { if LIKELY (expr) ; else \
       (*_marpa_debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
#else /* if not |MARPA_DEBUG| */
#define MARPA_DEBUG1(a) @[@]
#define MARPA_DEBUG2(a, b) @[@]
#define MARPA_DEBUG3(a, b, c) @[@]
#define MARPA_DEBUG4(a, b, c, d) @[@]
#define MARPA_DEBUG5(a, b, c, d, e) @[@]
#define MARPA_ASSERT(exp) @[@]
#endif

#ifndef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 0
#endif

#if MARPA_ENABLE_ASSERT
#undef MARPA_ASSERT
#define MARPA_ASSERT(expr) do { if LIKELY (expr) ; else \
       (*_marpa_debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
#endif

@** File layout.  
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

@ This is the license language for the header files.
\tenpoint
@<Header license language@> =
@=/*@>@/
@= * Copyright 2013 Jeffrey Kegler@>@/
@= * This file is part of Marpa::R2.  Marpa::R2 is free software: you can@>@/
@= * redistribute it and/or modify it under the terms of the GNU Lesser@>@/
@= * General Public License as published by the Free Software Foundation,@>@/
@= * either version 3 of the License, or (at your option) any later version.@>@/
@= *@>@/
@= * Marpa::R2 is distributed in the hope that it will be useful,@>@/
@= * but WITHOUT ANY WARRANTY; without even the implied warranty of@>@/
@= * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU@>@/
@= * Lesser General Public License for more details.@>@/
@= *@>@/
@= * You should have received a copy of the GNU Lesser@>@/
@= * General Public License along with Marpa::R2.  If not, see@>@/
@= * http://www.gnu.org/licenses/.@>@/
@= */@>@/
@=/*@>@/
@= * DO NOT EDIT DIRECTLY@>@/
@= * This file is written by ctangle@>@/
@= * It is not intended to be modified directly@>@/
@= */@>@/

@ \twelvepoint

@*0 |marpa_ami.h| layout.
\tenpoint
@(marpa_ami.h@> =
@<Header license language@>@;

#ifndef _MARPA_AMI_H__
#define _MARPA_AMI_H__ 1

@<Utility macros@>@;
@<Debug macros@>@;
@<Utility variables@>@;
@<Friend static inline functions@>@;
@<Public function prototypes@>@;

#endif /* |_MARPA_AMI_H__| */

@*0 |marpa_ami.c| layout.
@q This is a hack to get the @>
@q license language nearer the top of the files. @>
@ The physical structure of the |marpa_ami.c| file
\tenpoint
@c
@=/*@>@/
@= * Copyright 2013 Jeffrey Kegler@>@/
@= * This file is part of Marpa::R2.  Marpa::R2 is free software: you can@>@/
@= * redistribute it and/or modify it under the terms of the GNU Lesser@>@/
@= * General Public License as published by the Free Software Foundation,@>@/
@= * either version 3 of the License, or (at your option) any later version.@>@/
@= *@>@/
@= * Marpa::R2 is distributed in the hope that it will be useful,@>@/
@= * but WITHOUT ANY WARRANTY; without even the implied warranty of@>@/
@= * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU@>@/
@= * Lesser General Public License for more details.@>@/
@= *@>@/
@= * You should have received a copy of the GNU Lesser@>@/
@= * General Public License along with Marpa::R2.  If not, see@>@/
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
#include <stddef.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#if MARPA_DEBUG
#include <stdarg.h>
#include <stdio.h>
#endif

#include "marpa_int.h"
#include "marpa_ami.h"

@h

@<Global variables@>@;

#if MARPA_DEBUG
@<Debug function definitions@>@;
#endif

#include "ami_private.h"

@<Function definitions@>@;

@** Index.

