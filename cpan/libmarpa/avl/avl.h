/* This is a modification of avl.h, from Ben Pfaff's libavl,
   which was under the LGPL 3.  Here is the copyright notice
   from that file:

   libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.
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

#ifndef AVL_H
#define AVL_H 1

#include <stddef.h>

/* Function types. */
typedef int avl_comparison_func (const void *avl_a, const void *avl_b,
                                 void *avl_param);
typedef void avl_item_func (void *avl_item, void *avl_param);
typedef void *avl_copy_func (void *avl_item, void *avl_param);

/* Maximum AVL tree height. */
#ifndef AVL_MAX_HEIGHT
#define AVL_MAX_HEIGHT 92
#endif

/* Tree data structure. */
struct marpa_avl_table
  {
    struct avl_node *avl_root;          /* Tree's root. */
    avl_comparison_func *avl_compare;   /* Comparison function. */
    void *avl_param;                    /* Extra argument to |avl_compare|. */
    struct obstack *avl_obstack;
    size_t avl_count;                   /* Number of items in tree. */
    unsigned long avl_generation;       /* Generation number. */
  };
typedef struct marpa_avl_table* AVL_TREE;

/* An AVL tree node. */
struct avl_node
  {
    struct avl_node *avl_link[2];  /* Subtrees. */
    void *avl_data;                /* Pointer to data. */
    signed char avl_balance;       /* Balance factor. */
  };
typedef struct avl_node* NODE;

/* AVL traverser structure. */
struct avl_traverser
  {
    AVL_TREE avl_table;        /* Tree being traversed. */
    struct avl_node *avl_node;          /* Current node in tree. */
    struct avl_node *avl_stack[AVL_MAX_HEIGHT];
                                        /* All the nodes above |avl_node|. */
    size_t avl_height;                  /* Number of nodes in |avl_parent|. */
    unsigned long avl_generation;       /* Generation number. */
  };
typedef struct avl_traverser* AVL_TRAV;

#define TREE_of_AVL_TRAV(trav) ((trav)->avl_table)
#define DATA_of_AVL_TRAV(trav) ((trav)->avl_node ? (trav)->avl_node->avl_data : NULL)
#define AVL_OBSTACK(table) ((table)->avl_obstack)

/* Table functions. */
AVL_TREE _marpa_avl_create (avl_comparison_func *, void *,
                              int alignment);
AVL_TREE _marpa_avl_copy (const AVL_TREE , avl_copy_func *,
                            avl_item_func *, int alignment);
void _marpa_avl_destroy (AVL_TREE );
void **_marpa_avl_probe (AVL_TREE , void *);
void *_marpa_avl_insert (AVL_TREE , void *);
void *_marpa_avl_replace (AVL_TREE , void *);
void *_marpa_avl_find (const AVL_TREE , const void *);

#define marpa_avl_count(table) ((size_t) (table)->avl_count)

/* Table traverser functions. */
AVL_TRAV _marpa_avl_t_init (AVL_TREE );
AVL_TRAV _marpa_avl_t_reset (AVL_TRAV );
void *_marpa_avl_t_first (AVL_TRAV );
void *_marpa_avl_t_last ( AVL_TRAV );
void *_marpa_avl_t_find ( AVL_TRAV , void *);
void *_marpa_avl_t_copy (struct avl_traverser *, const struct avl_traverser *);
void *_marpa_avl_t_next (AVL_TRAV);
void *_marpa_avl_t_prev (AVL_TRAV);
void *_marpa_avl_t_cur (AVL_TRAV);
void *_marpa_avl_t_insert (AVL_TRAV, void *);
void *_marpa_avl_t_replace (AVL_TRAV, void *);

#endif /* avl.h */
