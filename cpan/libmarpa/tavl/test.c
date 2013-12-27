/* Produced by texiweb from libavl.w.
   Adapted for Marpa by hand edits by Jeffrey Kegler. */

/* libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with this program; if not, write to the Free Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include <assert.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "test.h"

/* Insertion order. */
enum insert_order
  {
    INS_RANDOM,                        /* Random order. */
    INS_ASCENDING,                /* Ascending order. */
    INS_DESCENDING,                /* Descending order. */
    INS_BALANCED,                /* Balanced tree order. */
    INS_ZIGZAG,                        /* Zig-zag order. */
    INS_ASCENDING_SHIFTED,      /* Ascending from middle, then beginning. */
    INS_CUSTOM,                        /* Custom order. */

    INS_CNT                     /* Number of insertion orders. */
  };

/* Deletion order. */
enum delete_order
  {
    DEL_RANDOM,                        /* Random order. */
    DEL_REVERSE,                /* Reverse of insertion order. */
    DEL_SAME,                        /* Same as insertion order. */
    DEL_CUSTOM,                        /* Custom order. */

    DEL_CNT                     /* Number of deletion orders. */
  };

/* Memory tracking policy. */
enum mt_policy
  {
    MT_TRACK,                        /* Track allocation for leak detection. */
    MT_NO_TRACK,                /* No leak detection. */
    MT_FAIL_COUNT,        /* Fail allocations after a while. */
    MT_FAIL_PERCENT,                /* Fail allocations randomly. */
    MT_SUBALLOC                 /* Suballocate from larger blocks. */
  };

/* A single command-line option. */
struct option
  {
    const char *long_name;        /* Long name (|"--name"|). */
    int short_name;                /* Short name (|"-n"|); value returned. */
    int has_arg;                /* Has a required argument? */
  };

/* Test to perform. */
enum test
  {
    TST_CORRECTNESS,                /* Default tests. */
    TST_OVERFLOW,                /* Stack overflow test. */
    TST_NULL                    /* No test, just overhead. */
  };

/* Program options. */
struct test_options
  {
    enum test test;                     /* Test to perform. */
    enum insert_order insert_order;     /* Insertion order. */
    enum delete_order delete_order;     /* Deletion order. */

    enum mt_policy alloc_policy;        /* Allocation policy. */
    int alloc_arg[2];                   /* Policy arguments. */
    int alloc_incr; /* Amount to increment |alloc_arg| each iteration. */

    int node_cnt;                       /* Number of nodes in tree. */
    int iter_cnt;                       /* Number of runs. */

    int seed_given;                     /* Seed provided on command line? */
    unsigned seed;                      /* Random number seed. */

    int verbosity;                      /* Verbosity level, 0=default. */
    int nonstop;                        /* Don't stop after one error? */
  };

/* Program name. */
char *pgm_name;

/* Utility functions. */

/* Comparison function for pointers to |int|s.
   |param| is not used. */
int
compare_ints (const void *pa, const void *pb, void *param)
{
  const int *a = pa;
  const int *b = pb;

  if (*a < *b)
    return -1;
  else if (*a > *b)
    return +1;
  else
    return 0;
}

/* Prints |message| on |stderr|, which is formatted as for |printf()|,
   and terminates the program unsuccessfully. */
static void
fail (const char *message, ...)
{
  va_list args;

  fprintf (stderr, "%s: ", pgm_name);

  va_start (args, message);
  vfprintf (stderr, message, args);
  va_end (args);

  putchar ('\n');

  exit (EXIT_FAILURE);
}

/* Allocates and returns a pointer to |size| bytes of memory.
   Aborts if allocation fails. */
static void *
xmalloc (size_t size)
{
  void *block = malloc (size);
  if (block == NULL && size != 0)
    fail ("out of memory");
  return block;
}

/* Memory tracking allocator. */

/* A memory block. */
struct block
  {
    struct block *next;                 /* Next in linked list. */

    int idx;                            /* Allocation order index number. */
    size_t size;                        /* Size in bytes. */
    size_t used;                        /* MT_SUBALLOC: amount used so far. */
    void *content;                      /* Allocated region. */
  };

/* Indexes into |arg[]| within |struct mt_allocator|. */
enum mt_arg_index
  {
    MT_COUNT = 0,      /* |MT_FAIL_COUNT|: Remaining successful allocations. */
    MT_PERCENT = 0,    /* |MT_FAIL_PERCENT|: Failure percentage. */
    MT_BLOCK_SIZE = 0, /* |MT_SUBALLOC|: Size of block to suballocate. */
    MT_ALIGN = 1       /* |MT_SUBALLOC|: Alignment of suballocated blocks. */
  };

/* Memory tracking allocator. */
struct mt_allocator
  {
    struct libavl_allocator allocator;  /* Allocator.  Must be first member. */

    /* Settings. */
    enum mt_policy policy;              /* Allocation policy. */
    int arg[2];                         /* Policy arguments. */
    int verbosity;                      /* Message verbosity level. */

    /* Current state. */
    struct block *head, *tail;          /* Head and tail of block list. */
    int alloc_idx;                      /* Number of allocations so far. */
    int block_cnt;                      /* Number of still-allocated blocks. */
  };

static void *mt_allocate (struct libavl_allocator *, size_t);
static void mt_free (struct libavl_allocator *, void *);

/* Initializes the memory manager for use
   with allocation policy |policy| and policy arguments |arg[]|,
   at verbosity level |verbosity|, where 0 is a ``normal'' value. */
struct mt_allocator *
mt_create (enum mt_policy policy, int arg[2], int verbosity)
{
  struct mt_allocator *mt = xmalloc (sizeof *mt);

  mt->allocator.libavl_malloc = mt_allocate;
  mt->allocator.libavl_free = mt_free;

  mt->policy = policy;
  mt->arg[0] = arg[0];
  mt->arg[1] = arg[1];
  mt->verbosity = verbosity;

  mt->head = mt->tail = NULL;
  mt->alloc_idx = 0;
  mt->block_cnt = 0;

  return mt;
}

/* Frees and destroys memory tracker |mt|,
   reporting any memory leaks. */
void
mt_destroy (struct mt_allocator *mt)
{
  assert (mt != NULL);

  if (mt->block_cnt == 0)
    {
      if (mt->policy != MT_NO_TRACK && mt->verbosity >= 1)
        printf ("  No memory leaks.\n");
    }
  else
    {
      struct block *iter, *next;

      if (mt->policy != MT_SUBALLOC)
        printf ("  Memory leaks detected:\n");
      for (iter = mt->head; iter != NULL; iter = next)
        {
          if (mt->policy != MT_SUBALLOC)
            printf ("    block #%d: %lu bytes\n",
                    iter->idx, (unsigned long) iter->size);

          next = iter->next;
          free (iter->content);
          free (iter);
        }
    }

  free (mt);
}

/* Returns the |struct libavl_allocator| associated with |mt|. */
void *
mt_allocator (struct mt_allocator *mt)
{
  return &mt->allocator;
}

/* Creates a new |struct block| containing |size| bytes of content
   and returns a pointer to content. */
static void *
new_block (struct mt_allocator *mt, size_t size)
{
  struct block *new;

  /* Allocate and initialize new |struct block|. */
  new = xmalloc (sizeof *new);
  new->next = NULL;
  new->idx = mt->alloc_idx++;
  new->size = size;
  new->used = 0;
  new->content = xmalloc (size);

  /* Add block to linked list. */
  if (mt->head == NULL)
    mt->head = new;
  else
    mt->tail->next = new;
  mt->tail = new;

  /* Alert user. */
  if (mt->verbosity >= 3)
    printf ("    block #%d: allocated %lu bytes\n",
            new->idx, (unsigned long) size);

  /* Finish up and return. */
  mt->block_cnt++;
  return new->content;
}

/* Prints a message about a rejected allocation if appropriate. */
static void
reject_request (struct mt_allocator *mt, size_t size)
{
  if (mt->verbosity >= 2)
    printf ("    block #%d: rejected request for %lu bytes\n",
            mt->alloc_idx++, (unsigned long) size);
}

/* Allocates and returns a block of |size| bytes. */
static void *
mt_allocate (struct libavl_allocator *allocator, size_t size)
{
  struct mt_allocator *mt = (struct mt_allocator *) allocator;

  /* Special case. */
  if (size == 0)
    return NULL;

  switch (mt->policy)
    {
    case MT_TRACK:
      return new_block (mt, size);

    case MT_NO_TRACK:
      return xmalloc (size);

    case MT_FAIL_COUNT:
      if (mt->arg[MT_COUNT] == 0)
        {
          reject_request (mt, size);
          return NULL;
        }
      mt->arg[MT_COUNT]--;
      return new_block (mt, size);

    case MT_FAIL_PERCENT:
      if (rand () / (RAND_MAX / 100 + 1) < mt->arg[MT_PERCENT])
        {
          reject_request (mt, size);
          return NULL;
        }
      else
        return new_block (mt, size);

    case MT_SUBALLOC:
      if (mt->tail == NULL
          || mt->tail->used + size > (size_t) mt->arg[MT_BLOCK_SIZE])
        new_block (mt, mt->arg[MT_BLOCK_SIZE]);
      if (mt->tail->used + size <= (size_t) mt->arg[MT_BLOCK_SIZE])
        {
          void *p = (char *) mt->tail->content + mt->tail->used;
          size = ((size + mt->arg[MT_ALIGN] - 1)
                  / mt->arg[MT_ALIGN] * mt->arg[MT_ALIGN]);
          mt->tail->used += size;
          if (mt->verbosity >= 3)
            printf ("    block #%d: suballocated %lu bytes\n",
                    mt->tail->idx, (unsigned long) size);
          return p;
        }
      else
        fail ("blocksize %lu too small for %lu-byte allocation",
              (unsigned long) mt->tail->size, (unsigned long) size);

    default:
      assert (0);
    }
}

/* Releases |block| previously returned by |mt_allocate()|. */
static void
mt_free (struct libavl_allocator *allocator, void *block)
{
  struct mt_allocator *mt = (struct mt_allocator *) allocator;
  struct block *iter, *prev;

  /* Special cases. */
  if (block == NULL || mt->policy == MT_NO_TRACK)
    {
      free (block);
      return;
    }
  if (mt->policy == MT_SUBALLOC)
    return;

  /* Search for |block| within the list of allocated blocks. */
  for (prev = NULL, iter = mt->head; iter; prev = iter, iter = iter->next)
    {
      if (iter->content == block)
        {
          /* Block found.  Remove it from the list. */
          struct block *next = iter->next;

          if (prev == NULL)
            mt->head = next;
          else
            prev->next = next;
          if (next == NULL)
            mt->tail = prev;

          /* Alert user. */
          if (mt->verbosity >= 4)
            printf ("    block #%d: freed %lu bytes\n",
                    iter->idx, (unsigned long) iter->size);

          /* Free block. */
          free (iter->content);
          free (iter);

          /* Finish up and return. */
          mt->block_cnt--;
          return;
        }
    }

  /* Block not in list. */
  printf ("    attempt to free unknown block %p (already freed?)\n", block);
}

/* Option parsing state. */
struct option_state
  {
    const struct option *options; /* List of options. */
    char **arg_next;            /* Remaining arguments. */
    char *short_next;           /* When non-null, unparsed short options. */
  };

/* Creates and returns a command-line options parser.
   |args| is a null-terminated array of command-line arguments, not
   including program name. */
static struct option_state *
option_init (const struct option *options, char **args)
{
  struct option_state *state;

  assert (options != NULL && args != NULL);

  state = xmalloc (sizeof *state);
  state->options = options;
  state->arg_next = args;
  state->short_next = NULL;

  return state;
}

/* Parses a short option whose single-character name is pointed to by
   |state->short_next|.  Advances past the option so that the next one
   will be parsed in the next call to |option_get()|.  Sets |*argp| to
   the option's argument, if any.  Returns the option's short name. */
static int
handle_short_option (struct option_state *state, char **argp)
{
  const struct option *o;

  assert (state != NULL
          && state->short_next != NULL && *state->short_next != '\0'
          && state->options != NULL);

  /* Find option in |o|. */
  for (o = state->options; ; o++)
    if (o->long_name == NULL)
      fail ("unknown option `-%c'; use --help for help", *state->short_next);
    else if (o->short_name == *state->short_next)
      break;
  state->short_next++;

  /* Handle argument. */
  if (o->has_arg)
    {
      if (*state->arg_next == NULL || **state->arg_next == '-')
        fail ("`-%c' requires an argument; use --help for help");

      *argp = *state->arg_next++;
    }

  return o->short_name;
}

/* Parses a long option whose command-line argument is pointed to by
   |*state->arg_next|.  Advances past the option so that the next one
   will be parsed in the next call to |option_get()|.  Sets |*argp| to
   the option's argument, if any.  Returns the option's identifier. */
static int
handle_long_option (struct option_state *state, char **argp)
{
  const struct option *o;        /* Iterator on options. */
  char name[16];                /* Option name. */
  const char *arg;                /* Option argument. */

  assert (state != NULL
          && state->arg_next != NULL && *state->arg_next != NULL
          && state->options != NULL
          && argp != NULL);

  /* Copy the option name into |name|
     and put a pointer to its argument, or |NULL| if none, into |arg|. */
  {
    const char *p = *state->arg_next + 2;
    const char *q = p + strcspn (p, "=");
    size_t name_len = q - p;

    if (name_len > (sizeof name) - 1)
      name_len = (sizeof name) - 1;
    memcpy (name, p, name_len);
    name[name_len] = '\0';

    arg = (*q == '=') ? q + 1 : NULL;
  }

  /* Find option in |o|. */
  for (o = state->options; ; o++)
    if (o->long_name == NULL)
      fail ("unknown option --%s; use --help for help", name);
    else if (!strcmp (name, o->long_name))
      break;

  /* Make sure option has an argument if it should. */
  if ((arg != NULL) != (o->has_arg != 0))
    {
      if (arg != NULL)
        fail ("--%s can't take an argument; use --help for help", name);
      else
        fail ("--%s requires an argument; use --help for help", name);
    }

  /* Advance and return. */
  state->arg_next++;
  *argp = (char *) arg;
  return o->short_name;
}

/* Retrieves the next option in the state vector |state|.
   Returns the option's identifier, or -1 if out of options.
   Stores the option's argument, or |NULL| if none, into |*argp|. */
static int
option_get (struct option_state *state, char **argp)
{
  assert (state != NULL && argp != NULL);

  /* No argument by default. */
  *argp = NULL;

  /* Deal with left-over short options. */
  if (state->short_next != NULL)
    {
      if (*state->short_next != '\0')
        return handle_short_option (state, argp);
      else
        state->short_next = NULL;
    }

  /* Out of options? */
  if (*state->arg_next == NULL)
    {
      free (state);
      return -1;
    }

  /* Non-option arguments not supported. */
  if ((*state->arg_next)[0] != '-')
    fail ("non-option arguments encountered; use --help for help");
  if ((*state->arg_next)[1] == '\0')
    fail ("unknown option `-'; use --help for help");

  /* Handle the option. */
  if ((*state->arg_next)[1] == '-')
    return handle_long_option (state, argp);
  else
    {
      state->short_next = *state->arg_next + 1;
      state->arg_next++;
      return handle_short_option (state, argp);
    }
}

/* Command line parser. */

/* If |a| is a prefix for |b| or vice versa, returns the length of the
   match.
   Otherwise, returns 0. */
size_t
match_len (const char *a, const char *b)
{
  size_t cnt;

  for (cnt = 0; *a == *b && *a != '\0'; a++, b++)
    cnt++;

  return (*a != *b && *a != '\0' && *b != '\0') ? 0 : cnt;
}

/* |s| should point to a decimal representation of an integer.
   Returns the value of |s|, if successful, or 0 on failure. */
static int
stoi (const char *s)
{
  long x = strtol (s, NULL, 10);
  return x >= INT_MIN && x <= INT_MAX ? x : 0;
}

/* Print helpful syntax message and exit. */
static void
usage (void)
{
  static const char *help[] =
    {
      "bst-test, unit test for GNU libavl.\n\n",
      "Usage: %s [OPTION]...\n\n",
      "In the option descriptions below, CAPITAL denote arguments.\n",
      "If a long option shows an argument as mandatory, then it is\n",
      "mandatory for the equivalent short option also.  See the GNU\n",
      "libavl manual for more information.\n\n",
      "-t, --test=TEST     Sets test to perform.  TEST is one of:\n",
      "                      correctness insert/delete/... (default)\n",
      "                      overflow    stack overflow test\n",
      "                      benchmark   benchmark test\n",
      "                      null        no test\n",
      "-s, --size=TREE-SIZE  Sets tree size in nodes (default 16).\n",
      "-r, --repeat=COUNT  Repeats operation COUNT times (default 16).\n",
      "-i, --insert=ORDER  Sets the insertion order.  ORDER is one of:\n",
      "                      random      random permutation (default)\n",
      "                      ascending   ascending order 0...n-1\n",
      "                      descending  descending order n-1...0\n",
      "                      balanced    balanced tree order\n",
      "                      zigzag      zig-zag tree\n",
      "                      asc-shifted n/2...n-1, 0...n/2-1\n",
      "                      custom      custom, read from stdin\n",
      "-d, --delete=ORDER  Sets the deletion order.  ORDER is one of:\n",
      "                      random   random permutation (default)\n",
      "                      reverse  reverse order of insertion\n",
      "                      same     same as insertion order\n",
      "                      custom   custom, read from stdin\n",
      "-a, --alloc=POLICY  Sets allocation policy.  POLICY is one of:\n",
      "                      track     track memory leaks (default)\n",
      "                      no-track  turn off leak detection\n",
      "                      fail-CNT  fail after CNT allocations\n",
      "                      fail%%PCT  fail random PCT%% of allocations\n",
      "                      sub-B,A   divide B-byte blocks in A-byte units\n",
      "                    (Ignored for `benchmark' test.)\n",
      "-A, --incr=INC      Fail policies: arg increment per repetition.\n",
      "-S, --seed=SEED     Sets initial number seed to SEED.\n",
      "                    (default based on system time)\n",
      "-n, --nonstop       Don't stop after a single error.\n",
      "-q, --quiet         Turns down verbosity level.\n",
      "-v, --verbose       Turns up verbosity level.\n",
      "-h, --help          Displays this help screen.\n",
      "-V, --version       Reports version and copyright information.\n",
      NULL,
    };

  const char **p;
  for (p = help; *p != NULL; p++)
    printf (*p, pgm_name);

  exit (EXIT_SUCCESS);
}

/* Parses command-line arguments from null-terminated array |args|.
   Sets up |options| appropriately to correspond. */
static void
parse_command_line (char **args, struct test_options *options)
{
  static const struct option option_tab[] =
    {
      {"test", 't', 1},
      {"insert", 'i', 1},
      {"delete", 'd', 1},
      {"alloc", 'a', 1},
      {"incr", 'A', 1},
      {"size", 's', 1},
      {"repeat", 'r', 1},
      {"operation", 'o', 1},
      {"seed", 'S', 1},
      {"nonstop", 'n', 0},
      {"quiet", 'q', 0},
      {"verbose", 'v', 0},
      {"help", 'h', 0},
      {"version", 'V', 0},
      {NULL, 0, 0},
    };

  struct option_state *state;

  /* Default options. */
  options->test = TST_CORRECTNESS;
  options->insert_order = INS_RANDOM;
  options->delete_order = DEL_RANDOM;
  options->alloc_policy = MT_TRACK;
  options->alloc_arg[0] = 0;
  options->alloc_arg[1] = 0;
  options->alloc_incr = 0;
  options->node_cnt = 15;
  options->iter_cnt = 15;
  options->seed_given = 0;
  options->verbosity = 0;
  options->nonstop = 0;

  if (*args == NULL)
    return;

  state = option_init (option_tab, args + 1);
  for (;;)
    {
      char *arg;
      int id = option_get (state, &arg);
      if (id == -1)
        break;

      switch (id)
        {
        case 't':
          if (match_len (arg, "correctness") >= 3)
            options->test = TST_CORRECTNESS;
          else if (match_len (arg, "overflow") >= 3)
            options->test = TST_OVERFLOW;
          else if (match_len (arg, "null") >= 3)
            options->test = TST_NULL;
          else
            fail ("unknown test \"%s\"", arg);
          break;

        case 'i':
          {
            static const char *orders[INS_CNT] =
              {
                "random", "ascending", "descending",
                "balanced", "zigzag", "asc-shifted", "custom",
              };

            const char **iter;

            assert (sizeof orders / sizeof *orders == INS_CNT);
            for (iter = orders; ; iter++)
              if (iter >= orders + INS_CNT)
                fail ("unknown order \"%s\"", arg);
              else if (match_len (*iter, arg) >= 3)
                {
                  options->insert_order = iter - orders;
                  break;
                }
          }
          break;

        case 'd':
          {
            static const char *orders[DEL_CNT] =
              {
                "random", "reverse", "same", "custom",
              };

            const char **iter;

            assert (sizeof orders / sizeof *orders == DEL_CNT);
            for (iter = orders; ; iter++)
              if (iter >= orders + DEL_CNT)
                fail ("unknown order \"%s\"", arg);
              else if (match_len (*iter, arg) >= 3)
                {
                  options->delete_order = iter - orders;
                  break;
                }
          }
          break;

        case 'a':
          if (match_len (arg, "track") >= 3)
            options->alloc_policy = MT_TRACK;
          else if (match_len (arg, "no-track") >= 3)
            options->alloc_policy = MT_NO_TRACK;
          else if (!strncmp (arg, "fail", 3))
            {
              const char *p = arg + strcspn (arg, "-%");
              if (*p == '-')
                options->alloc_policy = MT_FAIL_COUNT;
              else if (*p == '%')
                options->alloc_policy = MT_FAIL_PERCENT;
              else
                fail ("invalid allocation policy \"%s\"", arg);

              options->alloc_arg[0] = stoi (p + 1);
            }
          else if (!strncmp (arg, "suballoc", 3))
            {
              const char *p = strchr (arg, '-');
              const char *q = strchr (arg, ',');
              if (p == NULL || q == NULL)
                fail ("invalid allocation policy \"%s\"", arg);

              options->alloc_policy = MT_SUBALLOC;
              options->alloc_arg[0] = stoi (p + 1);
              options->alloc_arg[1] = stoi (q + 1);
              if (options->alloc_arg[MT_BLOCK_SIZE] < 32)
                fail ("block size too small");
              else if (options->alloc_arg[MT_ALIGN]
                       > options->alloc_arg[MT_BLOCK_SIZE])
                fail ("alignment cannot be greater than block size");
              else if (options->alloc_arg[MT_ALIGN] < 1)
                fail ("alignment must be at least 1");
            }
          break;

        case 'A':
          options->alloc_incr = stoi (arg);
          break;

        case 's':
          options->node_cnt = stoi (arg);
          if (options->node_cnt < 1)
            fail ("bad tree size \"%s\"", arg);
          break;

        case 'r':
          options->iter_cnt = stoi (arg);
          if (options->iter_cnt < 1)
            fail ("bad repeat count \"%s\"", arg);
          break;

        case 'S':
          options->seed_given = 1;
          options->seed = strtoul (arg, NULL, 0);
          break;

        case 'n':
          options->nonstop = 1;
          break;

        case 'q':
          options->verbosity--;
          break;

        case 'v':
          options->verbosity++;
          break;

        case 'h':
          usage ();
          break;

        case 'V':
          fputs ("GNU libavl 2.0.3\n"
                 "Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 "
                 "Free Software Foundation, Inc.\n"
                 "This program comes with NO WARRANTY, not even for\n"
                 "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
                 "You may redistribute copies under the terms of the\n"
                 "GNU General Public License.  For more information on\n"
                 "these matters, see the file named COPYING.\n",
                 stdout);
          exit (EXIT_SUCCESS);

        default:
          assert (0);
        }
    }
}

/* Fills the |n| elements of |array[]| with a random permutation of the
   integers between |0| and |n - 1|. */
static void
permuted_integers (int array[], size_t n)
{
  size_t i;

  for (i = 0; i < n; i++)
    array[i] = i;

  for (i = 0; i < n; i++)
    {
      size_t j = i + (unsigned) rand () / (RAND_MAX / (n - i) + 1);
      int t = array[j];
      array[j] = array[i];
      array[i] = t;
    }
}

/* Generates a list of integers that produce a balanced tree when
   inserted in order into a binary tree in the usual way.
   |min| and |max| inclusively bound the values to be inserted.
   Output is deposited starting at |*array|. */
static void
gen_balanced_tree (int min, int max, int **array)
{
  int i;

  if (min > max)
    return;

  i = (min + max + 1) / 2;
  *(*array)++ = i;
  gen_balanced_tree (min, i - 1, array);
  gen_balanced_tree (i + 1, max, array);
}


/* Generates a permutation of the integers |0| to |n - 1| into
   |insert[]| according to |insert_order|. */
static void
gen_insertions (size_t n, enum insert_order insert_order, int insert[])
{
  size_t i;

  switch (insert_order)
    {
    case INS_RANDOM:
      permuted_integers (insert, n);
      break;

    case INS_ASCENDING:
      for (i = 0; i < n; i++)
        insert[i] = i;
      break;

    case INS_DESCENDING:
      for (i = 0; i < n; i++)
        insert[i] = n - i - 1;
      break;

    case INS_BALANCED:
      gen_balanced_tree (0, n - 1, &insert);
      break;

    case INS_ZIGZAG:
      for (i = 0; i < n; i++)
        if (i % 2 == 0)
          insert[i] = i / 2;
        else
          insert[i] = n - i / 2 - 1;
      break;

    case INS_ASCENDING_SHIFTED:
      for (i = 0; i < n; i++)
        {
           insert[i] = i + n / 2;
           if ((size_t) insert[i] >= n)
             insert[i] -= n;
        }
      break;

    case INS_CUSTOM:
      for (i = 0; i < n; i++)
        if (scanf ("%d", &insert[i]) == 0)
          fail ("error reading insertion order from stdin");
      break;

    default:
      assert (0);
    }
}

/* Generates a permutation of the integers |0| to |n - 1| into
   |delete[]| according to |delete_order| and |insert[]|. */
static void
gen_deletions (size_t n, enum delete_order delete_order,
               const int *insert, int *delete)
{
  size_t i;

  switch (delete_order)
    {
    case DEL_RANDOM:
      permuted_integers (delete, n);
      break;

    case DEL_REVERSE:
      for (i = 0; i < n; i++)
        delete[i] = insert[n - i - 1];
      break;

    case DEL_SAME:
      for (i = 0; i < n; i++)
        delete[i] = insert[i];
      break;

    case DEL_CUSTOM:
      for (i = 0; i < n; i++)
        if (scanf ("%d", &delete[i]) == 0)
          fail ("error reading deletion order from stdin");
      break;

    default:
      assert (0);
    }
}

/* Choose and return an initial random seed based on the current time.
   Based on code by Lawrence Kirby <fred@genesis.demon.co.uk>. */
unsigned
time_seed (void)
{
  time_t timeval;        /* Current time. */
  unsigned char *ptr;        /* Type punned pointed into timeval. */
  unsigned seed;        /* Generated seed. */
  size_t i;

  timeval = time (NULL);
  ptr = (unsigned char *) &timeval;

  seed = 0;
  for (i = 0; i < sizeof timeval; i++)
    seed = seed * (UCHAR_MAX + 2u) + ptr[i];

  return seed;
}

int
main (int argc, char *argv[])
{
  struct test_options opts;        /* Command-line options. */
  int *insert, *delete;                /* Insertion and deletion orders. */
  int success;                  /* Everything okay so far? */

  /* Initialize |pgm_name|, using |argv[0]| if sensible. */
  pgm_name = argv[0] != NULL && argv[0][0] != '\0' ? argv[0] : "bst-test";

  /* Parse command line into |options|. */
  parse_command_line (argv, &opts);

  if (opts.verbosity >= 0)
    fputs ("bst-test for GNU libavl 2.0.3; use --help to get help.\n", stdout);

  if (!opts.seed_given)
    opts.seed = time_seed () % 32768u;

  insert = xmalloc (sizeof *insert * opts.node_cnt);
  delete = xmalloc (sizeof *delete * opts.node_cnt);

  /* Run the tests. */
  success = 1;
  while (opts.iter_cnt--)
    {
      struct mt_allocator *alloc;

      if (opts.verbosity >= 0)
        {
          printf ("Testing seed=%u", opts.seed);
          if (opts.alloc_incr)
            printf (", alloc arg=%d", opts.alloc_arg[0]);
          printf ("...\n");
          fflush (stdout);
        }

      /* Generate insertion and deletion order.
         Seed them separately to ensure deletion order is
         independent of insertion order. */
      srand (opts.seed);
      gen_insertions (opts.node_cnt, opts.insert_order, insert);

      srand (++opts.seed);
      gen_deletions (opts.node_cnt, opts.delete_order, insert, delete);

      if (opts.verbosity >= 1)
        {
          int i;

          printf ("  Insertion order:");
          for (i = 0; i < opts.node_cnt; i++)
            printf (" %d", insert[i]);
          printf (".\n");

          if (opts.test == TST_CORRECTNESS)
            {
              printf ("Deletion order:");
              for (i = 0; i < opts.node_cnt; i++)
                printf (" %d", delete[i]);
              printf (".\n");
            }
        }

      alloc = mt_create (opts.alloc_policy, opts.alloc_arg, opts.verbosity);

      {
        int okay;
        struct libavl_allocator *a = mt_allocator (alloc);

        switch (opts.test)
          {
          case TST_CORRECTNESS:
            okay = test_correctness (a, insert, delete, opts.node_cnt,
                                     opts.verbosity);
            break;

          case TST_OVERFLOW:
            okay = test_overflow (a, insert, opts.node_cnt, opts.verbosity);
            break;

          case TST_NULL:
            okay = 1;
            break;

          default:
            assert (0);
          }

        if (okay)
          {
            if (opts.verbosity >= 1)
              printf ("  No errors.\n");
          }
        else
          {
            success = 0;
            printf ("  Error!\n");
          }
      }

      mt_destroy (alloc);
      opts.alloc_arg[0] += opts.alloc_incr;

      if (!success && !opts.nonstop)
        break;
    }

  free (delete);
  free (insert);

  return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
