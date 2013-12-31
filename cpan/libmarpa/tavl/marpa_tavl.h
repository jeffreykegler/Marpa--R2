/* Orginally produced by texiweb from libavl.w.
    Hand-edited for Marpa by Jeffrey Kegler.
*/

/* libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
   02110-1301 USA.
*/

/* Namespace not corrected for use as public Marpa header.  The
   names are namespace safe in terms of the avl library, but for use
   as a Marpa public header they really ought to be changed into
   the 'marpa__' namespace. */

#ifndef TAVL_H
#define TAVL_H 1

#include <stddef.h>

/* Function types. */
typedef int tavl_comparison_func (const void *tavl_a, const void *tavl_b,
                                 void *tavl_param);
typedef void tavl_item_func (void *tavl_item, void *tavl_param);
typedef void *tavl_copy_func (void *tavl_item, void *tavl_param);

#ifndef LIBAVL_ALLOCATOR
#define LIBAVL_ALLOCATOR
/* Memory allocator. */
struct libavl_allocator
  {
    void *(*libavl_malloc) (struct libavl_allocator *, size_t libavl_size);
    void (*libavl_free) (struct libavl_allocator *, void *libavl_block);
  };
extern struct libavl_allocator* marpa__tavl_allocator_default;
#endif

/* Maximum TAVL height. */
#ifndef TAVL_MAX_HEIGHT
#define TAVL_MAX_HEIGHT 32
#endif

/* Tree data structure. */
struct tavl_table
  {
    struct tavl_node *tavl_root;        /* Tree's root. */
    tavl_comparison_func *tavl_compare; /* Comparison function. */
    void *tavl_param;                   /* Extra argument to |tavl_compare|. */
    size_t tavl_count;                  /* Number of items in tree. */
    unsigned int tavl_duplicate_found:1;
  };

/* Characterizes a link as a child pointer or a thread. */
enum tavl_tag
  {
    TAVL_CHILD,                     /* Child pointer. */
    TAVL_THREAD                     /* Thread. */
  };

/* An TAVL tree node. */
struct tavl_node
  {
    struct tavl_node *tavl_link[2]; /* Subtrees. */
    void *tavl_data;                /* Pointer to data. */
    unsigned char tavl_tag[2];      /* Tag fields. */
    signed char tavl_balance;       /* Balance factor. */
  };

/* TAVL traverser structure. */
struct tavl_traverser
  {
    struct tavl_table *tavl_table;        /* Tree being traversed. */
    struct tavl_node *tavl_node;          /* Current node in tree. */
  };

/* Table functions. */
struct tavl_table *marpa__tavl_create (tavl_comparison_func *, void *);
struct tavl_table *marpa__tavl_copy (const struct tavl_table *, tavl_copy_func *,
                            tavl_item_func *);
void marpa__tavl_destroy (struct tavl_table *, tavl_item_func *);
void **marpa__tavl_probe (struct tavl_table *, void *);
void *marpa__tavl_insert (struct tavl_table *, void *);
void *marpa__tavl_replace (struct tavl_table *, void *);
void *marpa__tavl_delete (struct tavl_table *, const void *);
void *marpa__tavl_find (const struct tavl_table *, const void *);
void marpa__tavl_assert_insert (struct tavl_table *, void *);
void *marpa__tavl_assert_delete (struct tavl_table *, void *);

#define tavl_count(table) ((size_t) (table)->tavl_count)

/* Table traverser functions. */
void marpa__tavl_t_init (struct tavl_traverser *, struct tavl_table *);
void *marpa__tavl_t_first (struct tavl_traverser *, struct tavl_table *);
void *marpa__tavl_t_last (struct tavl_traverser *, struct tavl_table *);
void *marpa__tavl_t_find (struct tavl_traverser *, struct tavl_table *, void *);
void *marpa__tavl_t_insert (struct tavl_traverser *, struct tavl_table *, void *);
void *marpa__tavl_t_copy (struct tavl_traverser *, const struct tavl_traverser *);
void *marpa__tavl_t_next (struct tavl_traverser *);
void *marpa__tavl_t_prev (struct tavl_traverser *);
void *marpa__tavl_t_cur (struct tavl_traverser *);
void *marpa__tavl_t_replace (struct tavl_traverser *, void *);

/* For testing, we don't include the Marpa utility macros, so make
 * sure we have this one
 */
#undef UNUSED
#if     __GNUC__ >  2 || (__GNUC__ == 2 && __GNUC_MINOR__ >  4)
#define UNUSED __attribute__((__unused__))
#else
#define UNUSED
#endif

#endif /* tavl.h */
