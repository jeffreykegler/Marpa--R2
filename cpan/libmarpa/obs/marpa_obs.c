/* This file is a modification of one of the versions of the GNU obstack.c
 * which was LGPL 2.1.  Here is the copyright notice from that file:
 *
 * obstack.c - subroutines used implicitly by object stack macros
 * Copyright (C) 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1996, 1997, 1998,
 * 1999, 2000, 2001, 2002, 2003, 2004, 2005 Free Software Foundation, Inc.
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

#include <stdlib.h>

# include "config.h"

#ifdef HAVE_INTTYPES_H
# include <inttypes.h>
#endif
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif

# include "marpa.h"
# include "marpa_ami.h"
# include "marpa_obs.h"

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
/* If malloc were really smart, it would round addresses to DEFAULT_ALIGNMENT.
   But in fact it might be less smart and round addresses to as much as
   DEFAULT_ROUNDING.  So we prepare for it to do that.  */
enum
  {
    DEFAULT_ALIGNMENT = offsetof (struct fooalign, u),
    DEFAULT_ROUNDING = sizeof (union worst_aligned_object)
  };

#define DEBUG_CONTENTS_OFFSET \
  offsetof( \
    struct { \
      struct marpa_obstack_chunk_header header; \
      union worst_aligned_object contents; \
    }, contents)

/* Initialize an obstack H for use.  Specify chunk size SIZE (0 means default).
   Objects start on multiples of ALIGNMENT (0 means use default).

   Return nonzero if successful, calls obstack_alloc_failed_handler if
   allocation fails.  */

struct marpa_obstack * _marpa_obs_begin ( int size, int alignment)
{
  struct marpa_obstack_chunk *chunk;    /* points to new chunk */
  struct marpa_obstack *h;      /* points to new obstack */
  const int minimum_chunk_size = sizeof(struct marpa_obstack_chunk);
  /* Just enough room for the chunk and obstack headers */

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

#if MARPA_OBSTACK_DEBUG
  size = minimum_chunk_size;
#else
  size = MAX (minimum_chunk_size, size);
#endif

  chunk = marpa_malloc (size);
  h = &chunk->contents.obstack_header;

  h->chunk_size = size;
  h->alignment_mask = alignment - 1;
  h->chunk = chunk;

  h->next_free = h->object_base = 
    MARPA_PTR_ALIGN ((char *) chunk, ((char *)h + sizeof(*h)), alignment - 1);
    /* The first object can go after the obstack header, suitably aligned */
  h->chunk_limit = chunk->header.limit = (char *) chunk + h->chunk_size;
  chunk->header.prev = 0;
  return h;
}

/* Allocate a new current chunk for the obstack *H
   on the assumption that LENGTH bytes need to be added
   to the current object, or a new object of length LENGTH allocated.
   Unlike original GNU obstacks, does *NOT*
   copy any partial object from the end of the old chunk
   to the beginning of the new one.  */

void
_marpa_obs_newchunk (struct marpa_obstack *h, int length)
{
  struct marpa_obstack_chunk *old_chunk = h->chunk;
  struct marpa_obstack_chunk *new_chunk;
  long  new_size;
  char *object_base;

  /* Compute size for new chunk.  */
#if MARPA_OBSTACK_DEBUG
  new_size = DEBUG_CONTENTS_OFFSET + length;
#else
  new_size = (length) + h->alignment_mask + 100 + sizeof(struct marpa_obstack_chunk_header);
  if (new_size < h->chunk_size)
    new_size = h->chunk_size;
#endif

  /* Allocate and initialize the new chunk.  */
  new_chunk = marpa_malloc( new_size);
  h->chunk = new_chunk;
  new_chunk->header.prev = old_chunk;
  new_chunk->header.limit = h->chunk_limit = (char *) new_chunk + new_size;

  /* Compute an aligned object_base in the new chunk */
  object_base =
    MARPA_PTR_ALIGN ((char *) new_chunk, new_chunk->contents.contents, h->alignment_mask);

  h->object_base = object_base;
  h->next_free = h->object_base;
}

/* Return nonzero if object OBJ has been allocated from obstack H.
   This is here for debugging.
   If you use it in a program, you are probably losing.  */

/* Suppress -Wmissing-prototypes warning.  We don't want to declare this in
   obstack.h because it is just for debugging.  */
int _marpa_obs_allocated_p (struct marpa_obstack *h, void *obj);

int
_marpa_obs_allocated_p (struct marpa_obstack *h, void *obj)
{
  struct marpa_obstack_chunk *lp;       /* below addr of any objects in this chunk */
  struct marpa_obstack_chunk *plp;      /* point to previous chunk if any */

  lp = (h)->chunk;
  /* We use >= rather than > since the object cannot be exactly at
     the beginning of the chunk but might be an empty object exactly
     at the end of an adjacent chunk.  */
  while (lp != 0 && ((void *) lp >= obj || (void *) (lp)->header.limit < obj))
    {
      plp = lp->header.prev;
      lp = plp;
    }
  return lp != 0;
}

/* Free everything in H.  */
void
_marpa_obs_free (struct marpa_obstack *h)
{
  struct marpa_obstack_chunk *lp;       /* below addr of any objects in this chunk */
  struct marpa_obstack_chunk *plp;      /* point to previous chunk if any */

  if (!h)
    return;                     /* Return safely if never initialized */
  lp = h->chunk;
  while (lp != 0)
    {
      plp = lp->header.prev;
      marpa_free (lp);
      lp = plp;
    }
}

int
_marpa_obs_memory_used (struct marpa_obstack *h)
{
  struct marpa_obstack_chunk *lp;
  int nbytes = 0;

  for (lp = h->chunk; lp != 0; lp = lp->header.prev)
    {
      nbytes += lp->header.limit - (char *) lp;
    }
  return nbytes;
}

/* vim: set expandtab shiftwidth=4: */
