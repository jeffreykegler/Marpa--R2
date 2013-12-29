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
@i ../shared/copyright_page_license.w
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
@i ../shared/copyright_page_license.w

@** Introduction.
@*0 About this library.
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

@*0 About this document.
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
@<Private macros@> =
#define PRIVATE_NOT_INLINE static
#define PRIVATE static inline

@** Memory allocation.
libmarpa wrappers the standard memory functions
to provide more convenient behaviors.
\li The allocators do not return on failed memory allocations.
\li |marpa_realloc| is equivalent to |marpa_malloc| if called with
a |NULL| pointer.  (This is the GNU C library behavior.)
@ {\bf To Do}: @^To Do@>
For the moment, the memory allocators are hard-wired to
the C89 default |malloc| and |free|.
At some point I may allow the user to override
these choices.

@<Friend static inline functions@> =
static inline
void marpa_free (void *p)
{
  free (p);
}

@ @<Friend static inline functions@> =

static inline
void* marpa_malloc(size_t size)
{
    void *newmem = malloc(size);
    if (_MARPA_UNLIKELY(!newmem)) { (*marpa__out_of_memory)(); }
    return newmem;
}

static inline
void*
marpa_malloc0(size_t size)
{
    void* newmem = marpa_malloc(size);
    memset (newmem, 0, size);
    return newmem;
}

static inline
void*
marpa_realloc(void *p, size_t size)
{
   if (_MARPA_LIKELY(p != NULL)) {
        void *newmem = realloc(p, size);
        if (_MARPA_UNLIKELY(!newmem)) (*marpa__out_of_memory)();
        return newmem;
   }
   return marpa_malloc(size);
}

@
@d marpa_new(type, count) ((type *)marpa_malloc((sizeof(type)*(count))))
@d marpa_renew(type, p, count) 
    ((type *)marpa_realloc((p), (sizeof(type)*(count))))

@** Dynamic stacks.
|libmarpa| uses stacks and worklists extensively.
This stack interface resizes itself dynamically.
There are two disadvantages.

\li There is more overhead ---
overflow must be checked for with each push,
and the resizings, while fast, do take time.

\li The stack may be moved after any |MARPA_DSTACK_PUSH|
operation, making all pointers into it invalid.
Data must be retrieved from the stack before the
next |MARPA_DSTACK_PUSH|.
In the special 2-argument form,
|MARPA_DSTACK_INIT2|, the stack is initialized
to a size convenient for the memory allocator.
{\bf To Do}: @^To Do@>
Right now this is hard-wired to 1024, but I should
use the better calculation made by the obstack code.
@d MARPA_DSTACK_DECLARE(this) struct marpa_dstack_s this
@d MARPA_DSTACK_INIT(this, type, initial_size)
(
    ((this).t_count = 0),
    ((this).t_base = marpa_new(type, ((this).t_capacity = (initial_size))))
)
@d MARPA_DSTACK_INIT2(this, type)
    MARPA_DSTACK_INIT((this), type, MAX(4, 1024/sizeof(this)))

@ |MARPA_DSTACK_SAFE| is for cases where the dstack is not
immediately initialized to a useful value,
and might never be.
All fields are zeroed so that when the containing object
is destroyed, the deallocation logic knows that no
memory has been allocated and therefore no attempt
to free memory should be made.
@d MARPA_DSTACK_IS_INITIALIZED(this) ((this).t_base)
@d MARPA_DSTACK_SAFE(this)
  (((this).t_count = (this).t_capacity = 0), ((this).t_base = NULL))

@ A stack reinitialized by
|MARPA_DSTACK_CLEAR| contains 0 elements,
but has the same capacity as it had before the reinitialization.
This saves the cost of reallocating the dstack's buffer,
and leaves its capacity at what is hopefully
a stable, high-water mark, which will make future
resizings unnecessary.
@d MARPA_DSTACK_CLEAR(this) ((this).t_count = 0)
@d MARPA_DSTACK_PUSH(this, type) (
      (_MARPA_UNLIKELY((this).t_count >= (this).t_capacity)
      ? marpa_dstack_resize2(&(this), sizeof(type))
      : 0),
     ((type *)(this).t_base+(this).t_count++)
   )
@d MARPA_DSTACK_POP(this, type) ((this).t_count <= 0 ? NULL :
    ( (type*)(this).t_base+(--(this).t_count)))
@d MARPA_DSTACK_INDEX(this, type, ix) (MARPA_DSTACK_BASE((this), type)+(ix))
@d MARPA_DSTACK_TOP(this, type) (MARPA_DSTACK_LENGTH(this) <= 0
   ? NULL
   : MARPA_DSTACK_INDEX((this), type, MARPA_DSTACK_LENGTH(this)-1))
@d MARPA_DSTACK_BASE(this, type) ((type *)(this).t_base)
@d MARPA_DSTACK_LENGTH(this) ((this).t_count)
@d MARPA_DSTACK_CAPACITY(this) ((this).t_capacity)

@
|DSTACK|'s can have their data ``stolen", by other containers.
The |MARPA_STOLEN_DSTACK_DATA_FREE| macro is intended
to help the ``thief" container
deallocate the data it now has ``stolen".
@d MARPA_STOLEN_DSTACK_DATA_FREE(data) (marpa_free(data))
@d MARPA_DSTACK_DESTROY(this) MARPA_STOLEN_DSTACK_DATA_FREE(this.t_base)
@s MARPA_DSTACK int
@<Friend incomplete structures@> =
struct marpa_dstack_s;
typedef struct marpa_dstack_s* MARPA_DSTACK;
@ @<Friend structures@> =
struct marpa_dstack_s { int t_count; int t_capacity; void * t_base; };
@ @<Friend static inline functions@> =
static inline void * marpa_dstack_resize2(struct marpa_dstack_s* this, size_t type_bytes)
{
    return marpa_dstack_resize(this, type_bytes, this->t_capacity*2);
}

@ 
@d MARPA_DSTACK_RESIZE(this, type, new_size)
  (marpa_dstack_resize((this), sizeof(type), (new_size)))
@ @<Friend static inline functions@> =
static inline void *
marpa_dstack_resize (struct marpa_dstack_s *this, size_t type_bytes,
                     int new_size)
{
  if (new_size > this->t_capacity)
    {                           /* We do not shrink the stack
                                   in this method */
      this->t_capacity = new_size;
      this->t_base = marpa_realloc (this->t_base, new_size * type_bytes);
    }
  return this->t_base;
}

@** Debugging.
The |MARPA_DEBUG| flag enables intrusive debugging logic.
``Intrusive" debugging includes things which would
be annoying in production, such as detailed messages about
internal matters on |STDERR|.
|MARPA_DEBUG| is expected to be defined in the |CFLAGS|.
|MARPA_DEBUG| implies |MARPA_ENABLE_ASSERT|, but not
vice versa.
@<Debug macros@> =
#define MARPA_OFF_DEBUG1(a)
#define MARPA_OFF_DEBUG2(a, b)
#define MARPA_OFF_DEBUG3(a, b, c)
#define MARPA_OFF_DEBUG4(a, b, c, d)
#define MARPA_OFF_DEBUG5(a, b, c, d, e)
#define MARPA_OFF_ASSERT(expr)
@ Returns int so that it can be portably used
in a logically-anded expression.
@<Function definitions@> =
int marpa__default_debug_handler (const char *format, ...)
{
   va_list args;
   va_start (args, format);
   vfprintf (stderr, format, args);
   va_end (args);
   putc('\n', stderr);
   return 1;
}


@ @<Debug macros@> =

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#if MARPA_DEBUG

#undef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 1

#define MARPA_DEBUG1(a) @[ (marpa__debug_level && \
    (*marpa__debug_handler)(a)) @]
#define MARPA_DEBUG2(a,b) @[ (marpa__debug_level && \
    (*marpa__debug_handler)((a),(b))) @]
#define MARPA_DEBUG3(a,b,c) @[ (marpa__debug_level && \
    (*marpa__debug_handler)((a),(b),(c))) @]
#define MARPA_DEBUG4(a,b,c,d) @[ (marpa__debug_level && \
    (*marpa__debug_handler)((a),(b),(c),(d))) @]
#define MARPA_DEBUG5(a,b,c,d,e) @[ (marpa__debug_level && \
    (*marpa__debug_handler)((a),(b),(c),(d),(e))) @]

#define MARPA_ASSERT(expr) do { if _MARPA_LIKELY (expr) ; else \
       (*marpa__debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
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
#define MARPA_ASSERT(expr) do { if _MARPA_LIKELY (expr) ; else \
       (*marpa__debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
#endif

@*0 Internal macros.
@<Internal macros@> =

#if     __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ > 4)
#define UNUSED __attribute__((__unused__))
#else
#define UNUSED
#endif

#if defined (__GNUC__) && defined (__STRICT_ANSI__)
#  undef inline
#  define inline __inline__
#endif

#undef      MAX
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))

#undef      CLAMP
#define CLAMP(x, low, high)  (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

#undef STRINGIFY_ARG
#define STRINGIFY_ARG(contents)       #contents
#undef STRINGIFY
#define STRINGIFY(macro_or_string)        STRINGIFY_ARG (macro_or_string)

/* A string identifying the current code position */
#if defined(__GNUC__) && (__GNUC__ < 3) && !defined(__cplusplus)
#  define STRLOC        __FILE__ ":" STRINGIFY (__LINE__) ":" __PRETTY_FUNCTION__ "()"
#else
#  define STRLOC        __FILE__ ":" STRINGIFY (__LINE__)
#endif

/* Provide a string identifying the current function, non-concatenatable */
#if defined (__GNUC__)
#  define STRFUNC     ((const char*) (__PRETTY_FUNCTION__))
#elif defined (__STDC_VERSION__) && __STDC_VERSION__ >= 19901L
#  define STRFUNC     ((const char*) (__func__))
#else
#  define STRFUNC     ((const char*) ("???"))
#endif

#if defined __GNUC__
# define alignof(type) (__alignof__(type))
#else
# define alignof(type) (offsetof (struct { char __slot1; type __slot2; }, __slot2))
#endif

@** File layout.  
@ The output files are written in pieces,
with the license prepended,
which allows it to start the file.
The output files are {\bf not} source files,
but I add the license to them anyway.
@ Also, it is helpful to someone first
trying to orient herself,
if built source files contain a comment
to that effect and a warning
not that they are
not intended to be edited directly.
So I add such a comment.

@*0 |marpa_ami.h| layout, first piece.
@(marpa_ami.h.p10@> =

#ifndef _MARPA_AMI_H__
#define _MARPA_AMI_H__ 1

#if defined(__GNUC__) && (__GNUC__ >  2) && defined(__OPTIMIZE__)
#define _MARPA_LIKELY(expr) (__builtin_expect ((expr), 1))
#define _MARPA_UNLIKELY(expr) (__builtin_expect ((expr), 0))
#else
#define _MARPA_LIKELY(expr) (expr)
#define _MARPA_UNLIKELY(expr) (expr)
#endif

@<Debug macros@>
@<Internal macros@>

@h
@<Friend incomplete structures@>@;

@*0 |marpa_ami.h| layout, last piece.
@(marpa_ami.h.p90@> =

@<Friend structures@>@;
@<Friend static inline functions@>@;

#endif /* |_MARPA_AMI_H__| */

@*0 |marpa_ami.c| layout.
@ These C90 headers
are needed for the default debug handler.
This is strictly C90 and is always compiled in.
We don't want to require applications to obey
the |MARPA_DEBUG| flag and compile conditionally.
This means that
applications must be allowed to set the debug level
and handler, even when debugging is not compiled in,
and they will be meaningless.
@(marpa_ami.c.p10@> =

#include <stdarg.h>
#include <stdio.h>

@ @(marpa_ami.c.p10@> =
#include "config.h"

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#include "marpa.h"
#include "marpa_ami.h"

@<Private macros@>@;

@ The .c file has no contents at the moment, so just in
case, I include a dummy function.  Once there are other contents,
it should be deleted.
@(marpa_ami.c.p50@> =

@<Function definitions@>@;

@** Index.

% vim: expandtab shiftwidth=4:
