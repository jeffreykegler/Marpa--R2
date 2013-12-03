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

#ifndef MARPA_OBS_H
#define MARPA_OBS_H 1

#include <stddef.h>

#ifndef MARPA_OBSTACK_DEBUG
#define MARPA_OBSTACK_DEBUG 0
#endif

/* If B is the base of an object addressed by P, return the result of
   aligning P to the next multiple of A + 1.  B and P must be of type
   char *.  A + 1 must be a power of 2.  */

#define __BPTR_ALIGN(B, P, A) ((B) + (((P) - (B) + (A)) & ~(A)))

/* Similiar to _BPTR_ALIGN (B, P, A), except optimize the common case
   where pointers can be converted to integers, aligned as integers,
   and converted back again.  If ptrdiff_t is narrower than a
   pointer (e.g., the AS/400), play it safe and compute the alignment
   relative to B.  Otherwise, use the faster strategy of computing the
   alignment relative to 0.

   Unsafe, so we don't use it. 
*/

/* #define __PTR_ALIGN(B, P, A)						    \
  * __BPTR_ALIGN (sizeof (ptrdiff_t) < sizeof (void *) ? (B) : (char *) 0, \
		P, A)
*/

#include <string.h>

struct obstack			/* control current object in current chunk */
{
  long chunk_size;		/* preferred size to allocate chunks in */
  struct obstack_chunk *chunk;	/* address of current struct obstack_chunk */
  char *object_base;		/* address of object we are building */
  char *next_free;		/* where to add next char to current object */
  char *chunk_limit;		/* address of char after current chunk */
  union
  {
    ptrdiff_t tempint;
    void *tempptr;
  } temp;			/* Temporary for some macros.  */
  int alignment_mask;		/* Mask of alignment for each object. */
};

struct obstack_chunk_header		/* Lives at front of each chunk. */
{
  char *limit;			/* 1 past end of this chunk */
  struct obstack_chunk* prev;	/* address of prior chunk or NULL */
};

struct obstack_chunk
{
  struct obstack_chunk_header header;
  union {
    char contents[4];	/* objects begin here */
    struct obstack obstack_header;
  } contents;
};

/* Declare the external functions we use; they are in obstack.c.  */

extern void _marpa_obs_newchunk (struct obstack *, int);
#define _obstack_newchunk _marpa_obs_newchunk

extern struct obstack* _marpa_obs_begin (int, int);
#define my_obstack_begin _marpa_obs_begin

extern int _marpa_obs_memory_used (struct obstack *);
#define _obstack_memory_used _marpa_obs_memory_used

void _marpa_obs_free (struct obstack *__obstack);

/* Pointer to beginning of object being allocated or to be allocated next.
   Note that this might not be the final address of the object
   because a new chunk might be needed to hold the final size.  */

#define my_obstack_base(h) ((void *) (h)->object_base)

/* Size for allocating ordinary chunks.  */

#define obstack_chunk_size(h) ((h)->chunk_size)

/* Pointer to next byte not yet allocated in current chunk.  */

#define obstack_next_free(h)	((h)->next_free)

/* Mask specifying low bits that should be clear in address of an object.  */

#define obstack_alignment_mask(h) ((h)->alignment_mask)

#define my_obstack_init	my_obstack_begin (0, 0)

#define my_obstack_reserve_fast(h,n) ((h)->next_free += (n))

#define obstack_memory_used(h) _obstack_memory_used (h)

# define obstack_object_size(h) \
 (unsigned) ((h)->next_free - (h)->object_base)

/* "Confirm" the size of a reserved object, currently being built.
 * Confirmed size must be less than or equal to the reserved size.
 * "Fast" here means there is no check -- it is up to the caller
 * to ensure that the confirmed size is not too big
 */
# define my_obstack_confirm_fast(h, n) \
  ((h)->next_free = (h)->object_base + (n))

/* Reject any object being built, as if it never existed */
# define my_obstack_reject(h) \
  ((h)->next_free = (h)->object_base)

# define obstack_room(h)		\
 (unsigned) ((h)->chunk_limit - (h)->next_free)

#if MARPA_OBSTACK_DEBUG
#define NEED_CHUNK(h, length) (1)
#else
#define NEED_CHUNK(h, length) \
  ((h)->chunk_limit - (h)->next_free < (length))
#endif

# define my_obstack_reserve(h,length)					\
( (h)->temp.tempint = (length),						\
  (NEED_CHUNK((h), (h)->temp.tempint)		\
   ? (_obstack_newchunk ((h), (h)->temp.tempint), 0) : 0),		\
  my_obstack_reserve_fast (h, (h)->temp.tempint))

# define my_obstack_alloc(h,length)					\
 (my_obstack_reserve ((h), (length)), my_obstack_finish ((h)))

#define my_obstack_new(h, type, count) \
    ((type *)my_obstack_alloc((h), (sizeof(type)*(count))))

# define my_obstack_finish(h)						\
( \
  (h)->temp.tempptr = (h)->object_base,					\
  (((h)->next_free - (char *) (h)->chunk				\
    > (h)->chunk_limit - (char *) (h)->chunk)				\
   ? ((h)->next_free = (h)->chunk_limit) : 0),				\
  (h)->object_base = (h)->next_free,					\
  (h)->temp.tempptr)

# define my_obstack_free(h)	(_marpa_obs_free((h)))

#endif /* marpa_obs.h */
