/* This file is a modification of one of the versions of the GNU obstack.c
 * which was LGPL 2.1.  Here is the copyright notice from that file:
 *
 * obstack.c - subroutines used implicitly by object stack macros
 * Copyright (C) 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1996, 1997, 1998,
 * 1999, 2000, 2001, 2002, 2003, 2004, 2005 Free Software Foundation, Inc.
 * This file is part of the GNU C Library.
 */

/*
 * Copyright 2012 Jeffrey Kegler
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

#include <stddef.h>
#include <stdlib.h>
#include <string.h>

# include "config.h"

#ifdef HAVE_INTTYPES_H
# include <inttypes.h>
#endif
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif

# include "marpa_util.h"
# include "marpa_obs.h"

/* Determine default alignment.  */
union fooround
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
  union fooround u;
};
/* If malloc were really smart, it would round addresses to DEFAULT_ALIGNMENT.
   But in fact it might be less smart and round addresses to as much as
   DEFAULT_ROUNDING.  So we prepare for it to do that.  */
enum
  {
    DEFAULT_ALIGNMENT = offsetof (struct fooalign, u),
    DEFAULT_ROUNDING = sizeof (union fooround)
  };

/* Initialize an obstack H for use.  Specify chunk size SIZE (0 means default).
   Objects start on multiples of ALIGNMENT (0 means use default).

   Return nonzero if successful, calls obstack_alloc_failed_handler if
   allocation fails.  */

struct obstack * _marpa_obs_begin ( int size, int alignment)
{
  struct _obstack_chunk *chunk;	/* points to new chunk */
  struct obstack *h;	/* points to new obstack */
  const int minimum_chunk_size = 
    offsetof(struct _obstack_chunk, contents) +
    alignof(struct obstack) +
    sizeof(struct obstack);
    /* Minimum size is the offset of the contents, plus a high-ball estimate of what is
    needed to align the obstack header, plus the size of obstack header. */

  if (alignment == 0)
    alignment = DEFAULT_ALIGNMENT;
  if (size == 0)
    /* Default size is what GNU malloc can fit in a 4096-byte block.  */
    {
      /* 12 is sizeof (mhead) and 4 is EXTRA from GNU malloc.
         Use the values for range checking, because if range checking is off,
         the extra bytes won't be missed terribly, but if range checking is on
         and we used a larger request, a whole extra 4096 bytes would be
         allocated.

         These number are irrelevant to the new GNU malloc.  I suspect it is
         less sensitive to the size of the request.  */
      int extra = ((((12 + DEFAULT_ROUNDING - 1) & ~(DEFAULT_ROUNDING - 1))
		    + 4 + DEFAULT_ROUNDING - 1) & ~(DEFAULT_ROUNDING - 1));
      size = 4096 - extra;
    }
  size = MAX (minimum_chunk_size, size);
  chunk = my_malloc (size);
  h = (struct obstack *)
    (__PTR_ALIGN ((char *) chunk, chunk->contents,
		      alignof (struct obstack) - 1));
    /* The obstack structure is near the beginning of the first chunk,
       just after the header of the chunk itself. */

  h->chunk_size = size;
  h->alignment_mask = alignment - 1;
  h->chunk = chunk;

  h->next_free = h->object_base = 
    __PTR_ALIGN ((char *) chunk, ((char *)h + sizeof(*h)), alignment - 1);
    /* The first object can go after the obstack header, suitably aligned */
  h->chunk_limit = chunk->limit = (char *) chunk + h->chunk_size;
  chunk->prev = 0;
  /* The initial chunk now contains no empty object.  */
  h->maybe_empty_object = 0;
  return h;
}

/* Allocate a new current chunk for the obstack *H
   on the assumption that LENGTH bytes need to be added
   to the current object, or a new object of length LENGTH allocated.
   Copies any partial object from the end of the old chunk
   to the beginning of the new one.  */

void
_marpa_obs_newchunk (struct obstack *h, int length)
{
  struct _obstack_chunk *old_chunk = h->chunk;
  struct _obstack_chunk *new_chunk;
  long	new_size;
  long obj_size = h->next_free - h->object_base;
  long i;
  char *object_base;

  /* Compute size for new chunk.  */
  new_size = (obj_size + length) + (obj_size >> 3) + h->alignment_mask + 100;
  if (new_size < h->chunk_size)
    new_size = h->chunk_size;

  /* Allocate and initialize the new chunk.  */
  new_chunk = my_malloc( new_size);
  h->chunk = new_chunk;
  new_chunk->prev = old_chunk;
  new_chunk->limit = h->chunk_limit = (char *) new_chunk + new_size;

  /* Compute an aligned object_base in the new chunk */
  object_base =
    __PTR_ALIGN ((char *) new_chunk, new_chunk->contents, h->alignment_mask);

  for (i = obj_size - 1; i >= 0; i--) object_base[i] = (h->object_base)[i];

  /* If the object just copied was the only data in OLD_CHUNK,
     free that chunk and remove it from the chain.
     But not if that chunk might contain an empty object.  */
  if (! h->maybe_empty_object
      && (h->object_base
	  == __PTR_ALIGN ((char *) old_chunk, old_chunk->contents,
			  h->alignment_mask)))
    {
      new_chunk->prev = old_chunk->prev;
      my_free( old_chunk);
    }

  h->object_base = object_base;
  h->next_free = h->object_base + obj_size;
  /* The new chunk certainly contains no empty object yet.  */
  h->maybe_empty_object = 0;
}

/* Return nonzero if object OBJ has been allocated from obstack H.
   This is here for debugging.
   If you use it in a program, you are probably losing.  */

/* Suppress -Wmissing-prototypes warning.  We don't want to declare this in
   obstack.h because it is just for debugging.  */
int _marpa_obs_allocated_p (struct obstack *h, void *obj);

int
_marpa_obs_allocated_p (struct obstack *h, void *obj)
{
  struct _obstack_chunk *lp;	/* below addr of any objects in this chunk */
  struct _obstack_chunk *plp;	/* point to previous chunk if any */

  lp = (h)->chunk;
  /* We use >= rather than > since the object cannot be exactly at
     the beginning of the chunk but might be an empty object exactly
     at the end of an adjacent chunk.  */
  while (lp != 0 && ((void *) lp >= obj || (void *) (lp)->limit < obj))
    {
      plp = lp->prev;
      lp = plp;
    }
  return lp != 0;
}

/* Free everything in H.  */
void
_marpa_obs_free (struct obstack *h)
{
  struct _obstack_chunk *lp;	/* below addr of any objects in this chunk */
  struct _obstack_chunk *plp;	/* point to previous chunk if any */

  if (!h)
    return;			/* Return safely if never initialized */
  lp = h->chunk;
  while (lp != 0)
    {
      plp = lp->prev;
      my_free (lp);
      lp = plp;
    }
}

int
_marpa_obs_memory_used (struct obstack *h)
{
  struct _obstack_chunk *lp;
  int nbytes = 0;

  for (lp = h->chunk; lp != 0; lp = lp->prev)
    {
      nbytes += lp->limit - (char *) lp;
    }
  return nbytes;
}
