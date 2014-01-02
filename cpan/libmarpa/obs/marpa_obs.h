/* This file is a modification of one of the versions of the GNU obstack.h
 * which was LGPL 2.1.  Here is the copyright notice from that file:
 *
 * obstack.h - object stack macros
 * Copyright (C) 1988-1994,1996-1999,2003,2004,2005,2009
 *    Free Software Foundation, Inc.
 * This file is part of the GNU C Library.
 */

/*
 * Copyright 2013 Jeffrey Kegler
 * This file is part of Marpa::R2.  Marpa::R2 is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Marpa::R2 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Marpa::R2.  If not, see
 * http://www.gnu.org/licenses/.
 */

#ifndef _MARPA_OBS_H__
#define _MARPA_OBS_H__ 1

#ifndef MARPA_OBSTACK_DEBUG
#define MARPA_OBSTACK_DEBUG 0
#endif

#ifdef HAVE_INTTYPES_H
# include <inttypes.h>
#endif
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif

/* Determine default alignment.  */
union worst_aligned_object
{
/* intmax_t is guaranteed by AUTOCONF's AC_TYPE_INTMAX_T.
    Similarly, for uintmax_t.
*/
  uintmax_t t_imax;
  intmax_t t_uimax;
/* According to the autoconf manual, long double is provided by
   all non-obsolescent C compilers. */
  long double t_d;
  void *t_p;
};

struct fooalign
{
  char c;
  union worst_aligned_object u;
};

#define DEFAULT_ALIGNMENT (offsetof (struct fooalign, u))

/* If B is the base of an object addressed by P, return the result of
   aligning P to the next multiple of A + 1.  B and P must be of type
   char *.  A + 1 must be a power of 2.  */

#define ALIGN_UP(x, align) (((x) + (align) - 1) & ~((align) - 1))
#define ALIGN_DOWN(x, align) ((x) & ~((align) - 1))
#define ALIGN_POINTER(base, p, align) ((base) + ALIGN_UP((p)-(base), (align)))

/*
   The original GNU obstack implementation used __PTR_ALIGN,
   where pointers were converted to integers, aligned as integers,
   and converted back again.
   This is unsafe according to C89 and we are purists,
   so we don't use it. 
*/

struct marpa_obstack    /* control current object in current chunk */
{
  long chunk_size;              /* preferred size to allocate chunks in */
  struct marpa_obstack_chunk *chunk;    /* address of current struct obstack_chunk */
  char *object_base;            /* address of object we are building */
  char *next_free;              /* where to add next char to current object */
  char *chunk_limit;            /* address of char after current chunk */
};

struct marpa_obstack_chunk_header               /* Lives at front of each chunk. */
{
  char *limit;                  /* 1 past end of this chunk */
  struct marpa_obstack_chunk* prev;     /* address of prior chunk or NULL */
};

struct marpa_obstack_chunk
{
  struct marpa_obstack_chunk_header header;
  union {
    char contents[4];   /* objects begin here */
    struct marpa_obstack obstack_header;
  } contents;
};

/* Declare the external functions we use; they are in obstack.c.  */

extern void _marpa_obs_newchunk (struct marpa_obstack *, int);

extern struct marpa_obstack* _marpa_obs_begin (int, int);
#define marpa_obs_begin _marpa_obs_begin

extern int _marpa_obs_memory_used (struct marpa_obstack *);
#define marpa_obstack_memory_used(h) _marpa_obs_memory_used (h)

void _marpa_obs_free (struct marpa_obstack *__obstack);

/* Pointer to beginning of object being allocated or to be allocated next.
   Note that this might not be the final address of the object
   because a new chunk might be needed to hold the final size.  */

#define marpa_obs_base(h) ((void *) (h)->object_base)

/* Size for allocating ordinary chunks.  */

#define marpa_obstack_chunk_size(h) ((h)->chunk_size)

/* Pointer to next byte not yet allocated in current chunk.  */

#define marpa_obstack_next_free(h)      ((h)->next_free)

/* Mask specifying low bits that should be clear in address of an object.  */

#define marpa_obs_init  marpa_obs_begin (0, 0)

# define marpa_obstack_object_size(h) \
 (unsigned) ((h)->next_free - (h)->object_base)

# define marpa_obs_free(h)      (_marpa_obs_free((h)))

/* Reject any object being built, as if it never existed */
# define marpa_obs_reject(h) \
  ((h)->next_free = (h)->object_base)

# define marpa_obstack_room(h)          \
 (unsigned) ((h)->chunk_limit - (h)->next_free)

#define marpa_obs_new(h, type, count) \
    ((type *)marpa_obs_alloc((h), (sizeof(type)*(count))))

static inline
void marpa_obs_reserve (struct marpa_obstack* h, int length) {
    if (MARPA_OBSTACK_DEBUG || h->chunk_limit - h->next_free < length)
    {
       _marpa_obs_newchunk(h, length);
    }
    h->next_free = ALIGN_POINTER ((char*)h->chunk, (h->next_free+length), DEFAULT_ALIGNMENT);
}

static inline
void *marpa_obs_finish (struct marpa_obstack *h)
{
  void * const finished_object = h->object_base;
  h->next_free = ALIGN_POINTER((char *)h->chunk, h->next_free, DEFAULT_ALIGNMENT);
  if (h->next_free > h->chunk_limit) {
   h->next_free = h->chunk_limit;
  }
  h->object_base = h->next_free;
  return finished_object;
}

static inline
void* marpa_obs_alloc (struct marpa_obstack* h, int length) {
    marpa_obs_reserve(h, length);
    return marpa_obs_finish(h);
}

/* "Confirm", which is to set at its final value,
 * the size of a reserved object, currently being built.
 * The caller needs to ensure that the
 * confirmed size is less than or equal to the reserved size.
 * "Fast" here means there is no check -- it is up to the caller
 * to ensure that the confirmed size is not too big
 */
static inline
void marpa_obs_confirm_fast (struct marpa_obstack* h, int length) {
  h->next_free = h->object_base + length;
}

#endif /* marpa_obs.h */

/* vim: set expandtab shiftwidth=4: */
