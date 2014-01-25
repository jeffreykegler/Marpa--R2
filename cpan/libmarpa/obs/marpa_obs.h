/* This file is a modification of one of the versions of the GNU obstack.h
 * which was LGPL 2.1.  Here is the copyright notice from that file:
 *
 * obstack.h - object stack macros
 * Copyright (C) 1988-1994,1996-1999,2003,2004,2005,2009
 *    Free Software Foundation, Inc.
 * This file is part of the GNU C Library.
 */

/*
 * Copyright 2014 Jeffrey Kegler
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

/* Suppress 'unnamed type definition in parentheses' warning
   in #define ALIGNOF(type) below 
   under MS C compiler older than .NET 2003 */
#if defined(_MSC_VER) && _MSC_VER >= 1310 && !defined(__cplusplus)
#pragma warning(disable:4116)
#endif

#define ALIGNOF(type) offsetof (struct { char c; type element; }, element)

/* If B is the base of an object addressed by P, return the result of
   aligning P to the next multiple of A + 1.  B and P must be of type
   char *.  A + 1 must be a power of 2.  */

#define ALIGN_UP(x, align) (((x) + (align) - 1) & ~((align) - 1))
#define ALIGN_DOWN(x, align) ((x) & ~((align) - 1))
#define ALIGN_POINTER(base, p, align) \
    ((base) + (ptrdiff_t)ALIGN_UP((size_t)((p)-(base)), (align)))

/*
   The original GNU obstack implementation used __PTR_ALIGN,
   where pointers were converted to integers, aligned as integers,
   and converted back again.
   This is unsafe according to C89 and we are purists,
   so we don't use it. 
*/

/* |object_base| is the base of the object currently being built.
   |next_free| is the potential base of the next object, and therefore
   a limit (we hope!) on the size of the one currently being built.
   |object_base| == |next_free| if we are "idle" --
   not currently building an object.  An obstack is "idle" when
   it is initialized.

   Objects are "started" by moving |next_free| forward so that
   |next_free| > |object_base|.  Objects are finished by setting
   |next_free| == |object_base|, so the obstack is again "idle".
*/

struct marpa_obstack    /* control current object in current chunk */
{
  struct marpa_obstack_chunk *chunk;    /* address of current struct obstack_chunk */
  char *object_base;
  char *next_free;
  size_t minimum_chunk_size;              /* preferred size to allocate chunks in */
};

struct marpa_obstack_chunk_header               /* Lives at front of each chunk. */
{
  struct marpa_obstack_chunk* prev;     /* address of prior chunk or NULL */
  size_t size;
};

struct marpa_obstack_chunk
{
  struct marpa_obstack_chunk_header header;
  /* objects begin here in the second and subsequent chunks */
  char contents[4];
};

extern void* marpa__obs_newchunk (struct marpa_obstack *, size_t, size_t);

extern struct marpa_obstack* marpa__obs_begin (size_t);

void marpa__obs_free (struct marpa_obstack *__obstack);

/* Pointer to beginning of object being allocated or to be allocated next.
   Note that this might not be the final address of the object
   because a new chunk might be needed to hold the final size.  */

#define marpa_obs_base(h) ((void *) (h)->object_base)

#define marpa_obs_init  marpa__obs_begin (0)

# define marpa_obstack_object_size(h) \
 (unsigned) ((h)->next_free - (h)->object_base)

# define marpa_obs_free(h)      (marpa__obs_free((h)))

/* Reject any object being built, as if it never existed */
# define marpa_obs_reject(h) \
  ((h)->next_free = (h)->object_base)

# define marpa_obstack_room(h)          \
 ((h)->chunk->header.size - ((h)->next_free - (char*)((h)->chunk)))

#define marpa_obs_new(h, type, count) \
    ((type *)marpa__obs_alloc((h), (sizeof(type)*((size_t)(count))), ALIGNOF(type)))

/* Start an object */
static inline void*
marpa_obs_start (struct marpa_obstack *h, size_t length, size_t alignment)
{
  const size_t current_offset = (size_t)(h->next_free - (char *) (h->chunk));
  const size_t aligned_offset = ALIGN_UP (current_offset, alignment);
  if (aligned_offset + length > h->chunk->header.size)
    {
      return marpa__obs_newchunk (h, length, alignment);
    }
  h->object_base = (char *) (h->chunk) + aligned_offset;
  h->next_free = h->object_base + length;
  return h->object_base;
}

static inline
void *marpa_obs_finish (struct marpa_obstack *h)
{
  void * const finished_object = h->object_base;
  h->object_base = h->next_free;
  return finished_object;
}

static inline void *
marpa__obs_alloc (struct marpa_obstack *h, size_t length, size_t alignment)
{
  marpa_obs_start (h, length, alignment);
  return marpa_obs_finish (h);
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
