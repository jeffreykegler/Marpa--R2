/* Copyright 2022 Jeffrey Kegler */

/* This is a modification of avl.h, from Ben Pfaff's libavl,
   which was under the LGPL 3.  Here is the copyright notice
   from that file:

   libavl - library for manipulation of binary trees.
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

#ifndef _MARPA_AVL_H__
#define _MARPA_AVL_H__ 1

#include <stddef.h>

/* The linkage macros (MARPA_.*LINKAGE) are useful for specifying
   alternative linkage, usually 'static'.  The intended use case is
   including the Marpa source in a single file, and redefining
   the linkage macros on the command line:

-DMARPA_LINKAGE=static -DMARPA_AVL_LINKAGE=static -DMARPA_TAVL_LINKAGE=static -DMARPA_OBS_LINKAGE=static

   However, it is important to note that any redefinition of the linkaage
   macros is currently experimental, and therefore unsupported.
*/
#ifndef MARPA_AVL_LINKAGE
#  define MARPA_AVL_LINKAGE /* Default linkage */
#endif

/* Function types. */
typedef int marpa_avl_comparison_func (const void *avl_a, const void *avl_b,
                                 void *avl_param);
typedef void marpa_avl_item_func (void *avl_item, void *avl_param);
typedef void *marpa_avl_copy_func (void *avl_item, void *avl_param);

/* An AVL tree node. */
struct marpa_avl_node
  {
    struct marpa_avl_node *avl_link[2];  /* Subtrees. */
    void *avl_data;                /* Pointer to data. */
    signed char avl_balance;       /* Balance factor. */
  };

/* Tree data structure. */
struct marpa_avl_table
  {
    struct marpa_avl_node *avl_root;          /* Tree's root. */
    marpa_avl_comparison_func *avl_compare;   /* Comparison function. */
    void *avl_param;                    /* Extra argument to |avl_compare|. */
    struct marpa_obstack *avl_obstack;
    size_t avl_count;                   /* Number of items in tree. */
    unsigned long avl_generation;       /* Generation number. */
  };
typedef struct marpa_avl_table* MARPA_AVL_TREE;

/* Maximum AVL tree height. */
#ifndef MARPA_AVL_MAX_HEIGHT
#define MARPA_AVL_MAX_HEIGHT 92
#endif

/* AVL traverser structure. */
struct marpa_avl_traverser
  {
    MARPA_AVL_TREE avl_table;        /* Tree being traversed. */
    struct marpa_avl_node *avl_node;          /* Current node in tree. */
    struct marpa_avl_node *avl_stack[MARPA_AVL_MAX_HEIGHT];
                                        /* All the nodes above |avl_node|. */
    size_t avl_height;                  /* Number of nodes in |avl_parent|. */
    unsigned long avl_generation;       /* Generation number. */
  };
typedef struct marpa_avl_traverser* MARPA_AVL_TRAV;

#define MARPA_TREE_OF_AVL_TRAV(trav) ((trav)->avl_table)
#define MARPA_DATA_OF_AVL_TRAV(trav) ((trav)->avl_node ? (trav)->avl_node->avl_data : NULL)
#define MARPA_AVL_OBSTACK(table) ((table)->avl_obstack)

/* Table functions. */
MARPA_AVL_LINKAGE MARPA_AVL_TREE _marpa_avl_create (marpa_avl_comparison_func *, void *);
MARPA_AVL_LINKAGE MARPA_AVL_TREE _marpa_avl_copy (const MARPA_AVL_TREE , marpa_avl_copy_func *,
                            marpa_avl_item_func *, int alignment);
MARPA_AVL_LINKAGE void _marpa_avl_destroy (MARPA_AVL_TREE );
MARPA_AVL_LINKAGE void **_marpa_avl_probe (MARPA_AVL_TREE , void *);
MARPA_AVL_LINKAGE void *_marpa_avl_insert (MARPA_AVL_TREE , void *);
MARPA_AVL_LINKAGE void *_marpa_avl_replace (MARPA_AVL_TREE , void *);
MARPA_AVL_LINKAGE void *_marpa_avl_find (const MARPA_AVL_TREE , const void *);
MARPA_AVL_LINKAGE void *_marpa_avl_at_or_after (const MARPA_AVL_TREE , const void *);

#define marpa_avl_count(table) ((size_t) (table)->avl_count)

/* Table traverser functions. */
MARPA_AVL_LINKAGE MARPA_AVL_TRAV _marpa_avl_t_init (MARPA_AVL_TREE );
MARPA_AVL_LINKAGE MARPA_AVL_TRAV _marpa_avl_t_reset (MARPA_AVL_TRAV );
MARPA_AVL_LINKAGE void *_marpa_avl_t_first (MARPA_AVL_TRAV );
MARPA_AVL_LINKAGE void *_marpa_avl_t_last ( MARPA_AVL_TRAV );
MARPA_AVL_LINKAGE void *_marpa_avl_t_find ( MARPA_AVL_TRAV , void *);
MARPA_AVL_LINKAGE void *_marpa_avl_t_copy (struct marpa_avl_traverser *, const struct marpa_avl_traverser *);
MARPA_AVL_LINKAGE void *_marpa_avl_t_next (MARPA_AVL_TRAV);
MARPA_AVL_LINKAGE void *_marpa_avl_t_prev (MARPA_AVL_TRAV);
MARPA_AVL_LINKAGE void *_marpa_avl_t_cur (MARPA_AVL_TRAV);
MARPA_AVL_LINKAGE void *_marpa_avl_t_insert (MARPA_AVL_TRAV, void *);
MARPA_AVL_LINKAGE void *_marpa_avl_t_replace (MARPA_AVL_TRAV, void *);
MARPA_AVL_LINKAGE void *_marpa_avl_t_at_or_after (MARPA_AVL_TRAV, void*);

#endif /* marpa_avl.h */
