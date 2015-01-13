/* This file is a modification of one of the versions of the GNU obstack.c
 * which was LGPL 2.1.  Here is the copyright notice from that file:
 *
 * obstack.c - subroutines used implicitly by object stack macros
 * Copyright (C) 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1996, 1997, 1998,
 * 1999, 2000, 2001, 2002, 2003, 2004, 2005 Free Software Foundation, Inc.
 * This file is part of the GNU C Library.
 */

/*
 * Copyright 2015 Jeffrey Kegler
 * This file is part of Libmarpa.  Libmarpa is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Libmarpa is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Libmarpa.  If not, see
 * http://www.gnu.org/licenses/.
 */

# include "config.h"

# include "marpa.h"
# include "marpa_ami.h"
# include "marpa_obs.h"

/* This estimate of malloc's overhead is the one used in Linus Torvald's slab
 * allocator in git.  I assume that it assumes a 64-bit architecture.
 */
#define MALLOC_OVERHEAD 32
#define DEFAULT_CHUNK_SIZE (4096 - MALLOC_OVERHEAD)

struct marpa_obstack *
marpa__obs_begin (size_t size)
{
  struct marpa_obstack_chunk *chunk;	/* points to new chunk */
  struct marpa_obstack *h;	/* points to new obstack */
  char *object_base;
  char *chunk_base;

  /* We ignore |size| if it specifies less than the default */
  size = MAX ((int)DEFAULT_CHUNK_SIZE, size);
  chunk_base = my_malloc (size);

  /* The chunk header goes at the beginning */
  chunk = (struct marpa_obstack_chunk*)chunk_base;
  chunk->header.size = size;
  chunk->header.prev = 0;

  /* Put the header of the obstack itself after the header of its first
     chunk. */
  object_base = chunk_base + sizeof(chunk->header);
  object_base = ALIGN_POINTER (chunk_base, object_base, ALIGNOF (struct marpa_obstack));
  h = (struct marpa_obstack *)object_base;
  h->chunk = chunk;
  h->minimum_chunk_size = size;

  /* Set the obstack to "idle" with the pointer just after the
     obstack header */
  object_base += sizeof(*h);
  h->next_free = h->object_base = object_base;
  return h;
}

/* Allocate a new current chunk for the obstack *H
   on the assumption that LENGTH bytes need to be added
   to the current object, or a new object of length LENGTH allocated.
   Unlike original GNU obstacks, does *NOT*
   copy any partial object from the end of the old chunk
   to the beginning of the new one.

   In this implementation, we know the next object we will
   need, and |length| and |alignment| represent that object.
   We start the new object, and return its base addess.
   */

void*
marpa__obs_newchunk (struct marpa_obstack *h, size_t length, size_t alignment)
{
  struct marpa_obstack_chunk *old_chunk = h->chunk;
  struct marpa_obstack_chunk *new_chunk;
  size_t new_size;
  const size_t contents_offset = offsetof(struct marpa_obstack_chunk, contents);
  const size_t aligned_contents_offset = ALIGN_UP(contents_offset, alignment);
  const size_t space_needed_for_alignment = aligned_contents_offset - contents_offset;

  /* Compute size for new chunk.
   * Make sure there is enough room for |length|
   * after adjusting alignment.
   */
  new_size = contents_offset + space_needed_for_alignment + length;
  new_size = MAX(new_size, h->minimum_chunk_size);

  /* Allocate and initialize the new chunk.  */
  new_chunk = my_malloc( new_size);
  h->chunk = new_chunk;
  new_chunk->header.prev = old_chunk;
  new_chunk->header.size = new_size;

  h->object_base =  (char *)new_chunk + contents_offset + space_needed_for_alignment;
  h->next_free = h->object_base + length;
  return h->object_base;
}

/* Free everything in H.  */
void
marpa__obs_free (struct marpa_obstack *h)
{
  struct marpa_obstack_chunk *lp;       /* below addr of any objects in this chunk */
  struct marpa_obstack_chunk *plp;      /* point to previous chunk if any */

  if (!h)
    return;                     /* Return safely if never initialized */
  lp = h->chunk;
  while (lp != 0)
    {
      plp = lp->header.prev;
      my_free (lp);
      lp = plp;
    }
}

/* vim: set expandtab shiftwidth=4: */
