/* This is a modification of avl.c, from Ben Pfaff's libavl,
   which was under the LGPL 3.  Here is the copyright notice
   from that file:

   libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.
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

#include "config.h"

#include <assert.h>
#include <stdio.h>
#include "marpa.h"

#include "marpa_ami.h"
#include "marpa_obs.h"
#include "marpa_avl.h"

/* An AVL tree node. */
typedef struct marpa_avl_node* NODE;

/* Creates and returns a new table
   with comparison function |compare| using parameter |param|.
   */
MARPA_AVL_TREE 
_marpa_avl_create (marpa_avl_comparison_func *compare, void *param)
{
  MARPA_AVL_TREE tree;
  struct marpa_obstack *avl_obstack = marpa_obs_init;

  assert (compare != NULL);

  tree = marpa_obs_new( avl_obstack, struct marpa_avl_table, 1);
  tree->avl_obstack = avl_obstack;
  tree->avl_root = NULL;
  tree->avl_compare = compare;
  tree->avl_param = param;
  tree->avl_count = 0;
  tree->avl_generation = 0;

  return tree;
}

/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
void *
_marpa_avl_find (const MARPA_AVL_TREE tree, const void *item)
{
  NODE p;

  assert (tree != NULL && item != NULL);
  for (p = tree->avl_root; p != NULL; )
    {
      int cmp = tree->avl_compare (item, p->avl_data, tree->avl_param);

      if (cmp < 0)
        p = p->avl_link[0];
      else if (cmp > 0)
        p = p->avl_link[1];
      else /* |cmp == 0| */
        return p->avl_data;
    }

  return NULL;
}

/* Search |tree| for an item matching or after |item|, and return it if found.
   Otherwise return |NULL|. */
void *
_marpa_avl_at_or_after (const MARPA_AVL_TREE tree, const void *item)
{
  NODE p;
  NODE at_or_after = NULL;

  assert (tree != NULL && item != NULL);
  for (p = tree->avl_root; p != NULL; )
    {
      int cmp = tree->avl_compare (item, p->avl_data, tree->avl_param);

      if (cmp < 0)
        p = p->avl_link[0];
      else if (cmp > 0)
        at_or_after = p = p->avl_link[1];
      else /* |cmp == 0| */
        return p->avl_data;
    }

  return at_or_after ? at_or_after->avl_data : NULL;
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   */
void **
_marpa_avl_probe (MARPA_AVL_TREE tree, void *item)
{
  NODE y, z; /* Top node to update balance factor, and parent */
  NODE p, q; /* Iterator, and parent. */
  NODE n;     /* Newly inserted node. */
  NODE w;     /* New root of rebalanced subtree. */
  int dir;                /* Direction to descend. */

  unsigned char da[MARPA_AVL_MAX_HEIGHT]; /* Cached comparison results. */
  int k = 0;              /* Number of cached results. */

  assert (tree != NULL && item != NULL);

  z = (NODE) &tree->avl_root;
  y = tree->avl_root;
  dir = 0;
  for (q = z, p = y; p != NULL; q = p, p = p->avl_link[dir])
    {
      int cmp = tree->avl_compare (item, p->avl_data, tree->avl_param);
      if (cmp == 0)
        return &p->avl_data;

      if (p->avl_balance != 0)
        z = q, y = p, k = 0;
      dir = cmp > 0;
      da[k++] = (unsigned char)dir;
    }

  n = q->avl_link[dir] = marpa_obs_new (tree->avl_obstack, struct marpa_avl_node, 1);

  tree->avl_count++;
  n->avl_data = item;
  n->avl_link[0] = n->avl_link[1] = NULL;
  n->avl_balance = 0;
  if (y == NULL)
    return &n->avl_data;

  for (p = y, k = 0; p != n; p = p->avl_link[da[k]], k++)
    if (da[k] == 0)
      p->avl_balance--;
    else
      p->avl_balance++;

  if (y->avl_balance == -2)
    {
      NODE x = y->avl_link[0];
      if (x->avl_balance == -1)
        {
          w = x;
          y->avl_link[0] = x->avl_link[1];
          x->avl_link[1] = y;
          x->avl_balance = y->avl_balance = 0;
        }
      else
        {
          assert (x->avl_balance == +1);
          w = x->avl_link[1];
          x->avl_link[1] = w->avl_link[0];
          w->avl_link[0] = x;
          y->avl_link[0] = w->avl_link[1];
          w->avl_link[1] = y;
          if (w->avl_balance == -1)
            x->avl_balance = 0, y->avl_balance = +1;
          else if (w->avl_balance == 0)
            x->avl_balance = y->avl_balance = 0;
          else /* |w->avl_balance == +1| */
            x->avl_balance = -1, y->avl_balance = 0;
          w->avl_balance = 0;
        }
    }
  else if (y->avl_balance == +2)
    {
      NODE x = y->avl_link[1];
      if (x->avl_balance == +1)
        {
          w = x;
          y->avl_link[1] = x->avl_link[0];
          x->avl_link[0] = y;
          x->avl_balance = y->avl_balance = 0;
        }
      else
        {
          assert (x->avl_balance == -1);
          w = x->avl_link[0];
          x->avl_link[0] = w->avl_link[1];
          w->avl_link[1] = x;
          y->avl_link[1] = w->avl_link[0];
          w->avl_link[0] = y;
          if (w->avl_balance == +1)
            x->avl_balance = 0, y->avl_balance = -1;
          else if (w->avl_balance == 0)
            x->avl_balance = y->avl_balance = 0;
          else /* |w->avl_balance == -1| */
            x->avl_balance = +1, y->avl_balance = 0;
          w->avl_balance = 0;
        }
    }
  else
    return &n->avl_data;
  z->avl_link[y != z->avl_link[0]] = w;

  tree->avl_generation++;
  return &n->avl_data;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted.
   Otherwise, returns the duplicate item. */
void *
_marpa_avl_insert (MARPA_AVL_TREE table, void *item)
{
  void **p = _marpa_avl_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate.
   Otherwise, returns the item that was replaced. */
void *
_marpa_avl_replace (MARPA_AVL_TREE table, void *item)
{
  void **p = _marpa_avl_probe (table, item);
  if (p == NULL || *p == item)
    return NULL;
  else
    {
      void *r = *p;
      *p = item;
      return r;
    }
}

/* Refreshes the stack of parent pointers in |trav|
   and updates its generation number. */
static void
trav_refresh (struct marpa_avl_traverser *trav)
{
  assert (trav != NULL);

  trav->avl_generation = trav->avl_table->avl_generation;

  if (trav->avl_node != NULL)
    {
      marpa_avl_comparison_func *cmp = trav->avl_table->avl_compare;
      void *param = trav->avl_table->avl_param;
      NODE node = trav->avl_node;
      NODE i;

      trav->avl_height = 0;
      for (i = trav->avl_table->avl_root; i != node; )
        {
          assert (trav->avl_height < MARPA_AVL_MAX_HEIGHT);
          assert (i != NULL);

          trav->avl_stack[trav->avl_height++] = i;
          i = i->avl_link[cmp (node->avl_data, i->avl_data, param) > 0];
        }
    }
}

/* Assuming that the tree is already set,
  set the traverser to its initial values */
static inline void trav_reset(MARPA_AVL_TRAV trav)
{
  MARPA_AVL_TREE tree = MARPA_TREE_OF_AVL_TRAV(trav);
  trav->avl_node = NULL;
  trav->avl_height = 0;
  trav->avl_generation = tree->avl_generation;
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
MARPA_AVL_TRAV _marpa_avl_t_init (MARPA_AVL_TREE tree)
{
  const MARPA_AVL_TRAV trav
    = marpa_obs_new (MARPA_AVL_OBSTACK (tree), struct marpa_avl_traverser, 1);
  trav->avl_table = tree;
  trav_reset(trav);
  return trav;
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
MARPA_AVL_TRAV _marpa_avl_t_reset (MARPA_AVL_TRAV trav)
{
  trav_reset(trav);
  return trav;
}

/* Selects and returns a pointer to the least-valued item.
   Returns |NULL| if |tree| contains no nodes. */
void *
_marpa_avl_t_first (MARPA_AVL_TRAV trav)
{
  NODE x;
  MARPA_AVL_TREE tree = MARPA_TREE_OF_AVL_TRAV(trav);

  assert (trav != NULL);

  x = tree->avl_root;
  if (x != NULL)
    while (x->avl_link[0] != NULL)
      {
        assert (trav->avl_height < MARPA_AVL_MAX_HEIGHT);
        trav->avl_stack[trav->avl_height++] = x;
        x = x->avl_link[0];
      }
  trav->avl_node = x;

  return x != NULL ? x->avl_data : NULL;
}

/* Selects and returns a pointer to the greatest-valued item.
   Returns |NULL| if |tree| contains no nodes. */
void *
_marpa_avl_t_last (MARPA_AVL_TRAV trav)
{
  NODE x;
  MARPA_AVL_TREE tree = MARPA_TREE_OF_AVL_TRAV(trav);

  assert (trav != NULL);

  x = tree->avl_root;
  if (x != NULL)
    while (x->avl_link[1] != NULL)
      {
        assert (trav->avl_height < MARPA_AVL_MAX_HEIGHT);
        trav->avl_stack[trav->avl_height++] = x;
        x = x->avl_link[1];
      }
  trav->avl_node = x;

  return x != NULL ? x->avl_data : NULL;
}

/* Searches for |item| in |tree| of |trav|.
   If found, sets |trav| to the item found and returns the item
   as well.
   If there is no matching item, initializes |trav| to the null item
   and returns |NULL|. */
void *
_marpa_avl_t_find (MARPA_AVL_TRAV trav, void *item)
{
  NODE p, q;
  MARPA_AVL_TREE tree = MARPA_TREE_OF_AVL_TRAV(trav);

  assert (trav != NULL && item != NULL);
  for (p = tree->avl_root; p != NULL; p = q)
    {
      int cmp = tree->avl_compare (item, p->avl_data, tree->avl_param);

      if (cmp < 0)
        q = p->avl_link[0];
      else if (cmp > 0)
        q = p->avl_link[1];
      else /* |cmp == 0| */
        {
          trav->avl_node = p;
          return p->avl_data;
        }

      assert (trav->avl_height < MARPA_AVL_MAX_HEIGHT);
      trav->avl_stack[trav->avl_height++] = p;
    }

  trav->avl_height = 0;
  trav->avl_node = NULL;
  return NULL;
}

/* Attempts to insert |item| into tree of |trav|.
   If |item| is inserted successfully, it is returned and |trav| is
   initialized to its location.
   If a duplicate is found, it is returned and |trav| is initialized to
   its location.  No replacement of the item occurs.
   */
void *
_marpa_avl_t_insert ( MARPA_AVL_TRAV trav, void *item)
{
  void **p;
  MARPA_AVL_TREE tree = MARPA_TREE_OF_AVL_TRAV(trav);

  assert (trav != NULL && tree != NULL && item != NULL);

  p = _marpa_avl_probe (tree, item);
  if (p != NULL)
    {
      trav->avl_table = tree;
      trav->avl_node =
        ((NODE )
         ((char *) p - offsetof (struct marpa_avl_node, avl_data)));
      trav->avl_generation = tree->avl_generation - 1;
      return *p;
    }
  else
    {
      trav_reset (trav);
      return NULL;
    }
}

/* Initializes |trav| to have the same current node as |src|. */
void *
_marpa_avl_t_copy (struct marpa_avl_traverser *trav, const struct marpa_avl_traverser *src)
{
  assert (trav != NULL && src != NULL);

  if (trav != src)
    {
      trav->avl_table = src->avl_table;
      trav->avl_node = src->avl_node;
      trav->avl_generation = src->avl_generation;
      if (trav->avl_generation == trav->avl_table->avl_generation)
        {
          trav->avl_height = src->avl_height;
          memcpy (trav->avl_stack, (const void *) src->avl_stack,
                  sizeof *trav->avl_stack * trav->avl_height);
        }
    }

  return trav->avl_node != NULL ? trav->avl_node->avl_data : NULL;
}

/* Returns the next data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
_marpa_avl_t_next (MARPA_AVL_TRAV trav)
{
  NODE x;

  assert (trav != NULL);

  if (trav->avl_generation != trav->avl_table->avl_generation)
    trav_refresh (trav);

  x = trav->avl_node;
  if (x == NULL)
    {
      return _marpa_avl_t_first (trav);
    }
  else if (x->avl_link[1] != NULL)
    {
      assert (trav->avl_height < MARPA_AVL_MAX_HEIGHT);
      trav->avl_stack[trav->avl_height++] = x;
      x = x->avl_link[1];

      while (x->avl_link[0] != NULL)
        {
          assert (trav->avl_height < MARPA_AVL_MAX_HEIGHT);
          trav->avl_stack[trav->avl_height++] = x;
          x = x->avl_link[0];
        }
    }
  else
    {
      NODE y;

      do
        {
          if (trav->avl_height == 0)
            {
              trav->avl_node = NULL;
              return NULL;
            }

          y = x;
          x = trav->avl_stack[--trav->avl_height];
        }
      while (y == x->avl_link[1]);
    }
  trav->avl_node = x;

  return x->avl_data;
}

/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
_marpa_avl_t_prev (MARPA_AVL_TRAV trav)
{
  NODE x;

  assert (trav != NULL);

  if (trav->avl_generation != trav->avl_table->avl_generation)
    trav_refresh (trav);

  x = trav->avl_node;
  if (x == NULL)
    {
      return _marpa_avl_t_last (trav);
    }
  else if (x->avl_link[0] != NULL)
    {
      assert (trav->avl_height < MARPA_AVL_MAX_HEIGHT);
      trav->avl_stack[trav->avl_height++] = x;
      x = x->avl_link[0];

      while (x->avl_link[1] != NULL)
        {
          assert (trav->avl_height < MARPA_AVL_MAX_HEIGHT);
          trav->avl_stack[trav->avl_height++] = x;
          x = x->avl_link[1];
        }
    }
  else
    {
      NODE y;

      do
        {
          if (trav->avl_height == 0)
            {
              trav->avl_node = NULL;
              return NULL;
            }

          y = x;
          x = trav->avl_stack[--trav->avl_height];
        }
      while (y == x->avl_link[0]);
    }
  trav->avl_node = x;

  return x->avl_data;
}

/* Returns |trav|'s current item. */
void *
_marpa_avl_t_cur (MARPA_AVL_TRAV trav)
{
  assert (trav != NULL);

  return trav->avl_node != NULL ? trav->avl_node->avl_data : NULL;
}

/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
void *
_marpa_avl_t_replace (struct marpa_avl_traverser *trav, void *new)
{
  void *old;

  assert (trav != NULL && trav->avl_node != NULL && new != NULL);
  old = trav->avl_node->avl_data;
  trav->avl_node->avl_data = new;
  return old;
}

/* Frees storage allocated for |tree|.
  Everything is on the obstack.
*/
void
_marpa_avl_destroy (MARPA_AVL_TREE tree)
{
  if (tree == NULL)
    return;
  marpa_obs_free (tree->avl_obstack);
}

#undef NDEBUG
#include <assert.h>
