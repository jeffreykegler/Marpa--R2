/*
 * Copyright 2011 Jeffrey Kegler
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
#include <unistd.h>
#include <stdio.h>
#include <glib.h>
#include "marpa.h"

#define Dim(x) (sizeof(x)/sizeof(*x))

Marpa_AHFA_State_ID first_balanced_completion;

Marpa_Symbol_ID s_lparen;
Marpa_Symbol_ID s_rparen;
Marpa_Symbol_ID s_endmark;

static inline Marpa_Symbol_ID
gen_token (int string_length, int location)
{
  switch (location + 8 - string_length)
    {
    case 2:
    case 4:
    case 5:
      return s_rparen;
    }
  return s_lparen;
}

static inline struct marpa_r *
create_recce (struct marpa_g *g)
{
  struct marpa_r *r = marpa_r_new (g);
  if (!r)
    {
      puts (marpa_r_error (r));
      exit (1);
    }
  if (!marpa_start_input (r))
    {
      puts (marpa_r_error (r));
      exit (1);
    }
  return r;
}

static void
fatal_r_error (const char *where, struct marpa_r *r, int status)
{
  fprintf (stderr, "%s returned %d: %s\n", where, status, marpa_r_error (r));
  exit (1);
}

static inline Marpa_Earley_Set_ID
at_first_balanced_completion (struct marpa_r *r, int earley_set )
{
  int eim = 0;
  int earleme = marpa_earley_set_trace(r, earley_set);
  /* printf("marpa_earley_set_trace: es=%d, earleme=%d\n", earley_set, earleme); */
  if (earleme < -1) {
      fatal_r_error("marpa_earley_set_trace", r, earleme);
  }
  while (1) {
      Marpa_AHFA_State_ID ahfa_id = marpa_earley_item_trace(r, eim);
      if (ahfa_id < -1) {
          fatal_r_error("marpa_earley_item_trace", r, ahfa_id);
      }
      if (ahfa_id == -1) break;
      /* printf("es=%d, eim=%d, ahfa_id=%d\n", earley_set, eim, ahfa_id); */
      if (ahfa_id == first_balanced_completion) {
          Marpa_Earley_Set_ID es = marpa_earley_item_origin(r);
	  if (es < 0) {
	      fatal_r_error("marpa_earley_item_origin", r, es);
	  }
	  return es;
      }
      eim++;
    }
  return -1;
}

static gint string_length = 1000;
static gint repeats = 1;

static GOptionEntry entries[] = {
  {"length", 'l', 0, G_OPTION_ARG_INT, &string_length,
   "Length of test string", "L"},
  {"repeats", 'r', 0, G_OPTION_ARG_INT, &repeats, "Test R times", "R"},
  {NULL, 0, 0, 0, NULL, NULL, NULL}
};

int
main (int argc, char **argv)
{
  int was_result_written = 0;
  int pass;
  /* This was to move gslice area out of the
     tree of Marpa calls during memory debugging */
  /* void* dummy = g_slice_alloc(42); */
  /* g_slice_free1(42, dummy); */
  GError *error = NULL;
  GOptionContext *context;

  context = g_option_context_new ("- test balanced parens");
  g_option_context_add_main_entries (context, entries, NULL);
  if (!g_option_context_parse (context, &argc, &argv, &error))
    {
      g_print ("option parsing failed: %s\n", error->message);
      exit (1);
    }

  if (string_length < 10)
    {
      fprintf (stderr, "String length is %d, must be at least 10\n",
	       string_length);
      exit (1);
    }
  for (pass = 0; pass < repeats; pass++)
    {
      int location;
      int start_of_match = -1;
      int end_of_match = -1;
      Marpa_Symbol_ID s_top, s_prefix, s_first_balanced;
      Marpa_Symbol_ID s_prefix_char, s_balanced;
      Marpa_Symbol_ID s_balanced_sequence;
      struct marpa_g *g;
      struct marpa_r *r;
      void *result;
      /* Longest rule is 4 symbols */
      Marpa_Symbol_ID rhs[4];
      g = marpa_g_new ();
      s_top = marpa_symbol_new (g);
      s_prefix = marpa_symbol_new (g);
      s_first_balanced = marpa_symbol_new (g);
      s_prefix_char = marpa_symbol_new (g);
      s_balanced = marpa_symbol_new (g);
      s_lparen = marpa_symbol_new (g);
      s_rparen = marpa_symbol_new (g);
      s_balanced_sequence = marpa_symbol_new (g);
      rhs[0] = s_prefix;
      rhs[1] = s_first_balanced;
      marpa_rule_new (g, s_top, rhs, 2);
      marpa_sequence_new (g, s_prefix, s_prefix_char, -1, 0, 0);
      rhs[0] = s_balanced;
      marpa_rule_new (g, s_first_balanced, rhs, 1);
      rhs[0] = s_lparen;
      rhs[1] = s_rparen;
      marpa_rule_new (g, s_balanced, rhs, 2);
      rhs[0] = s_lparen;
      rhs[1] = s_balanced_sequence;
      rhs[2] = s_rparen;
      marpa_rule_new (g, s_balanced, rhs, 3);
      marpa_sequence_new (g, s_balanced_sequence, s_balanced, -1, 1, 0);
      marpa_symbol_is_terminal_set (g, s_prefix_char, 1);
      marpa_symbol_is_terminal_set (g, s_lparen, 1);
      marpa_symbol_is_terminal_set (g, s_rparen, 1);
      marpa_start_symbol_set (g, s_top);
      result = marpa_precompute (g);
      if (!result)
	{
	  puts (marpa_g_error (g));
	  exit (1);
	}
{
  int AHFA_state_count = marpa_AHFA_state_count (g);
  int ahfa_id;
  first_balanced_completion = -1;
  for (ahfa_id = 0; ahfa_id < AHFA_state_count; ahfa_id++)
    {
      guint aim_ix;
      guint aim_count = marpa_AHFA_state_item_count (g, ahfa_id);
      for (aim_ix = 0; aim_ix < aim_count; aim_ix++)
	{
	  int aim_id = marpa_AHFA_state_item (g, ahfa_id, aim_ix);
	  int position = marpa_AHFA_item_position (g, aim_id);
	  if (position == -1)
	    {
	      Marpa_Rule_ID rule = marpa_AHFA_item_rule (g, aim_id);
	      Marpa_Symbol_ID lhs = marpa_rule_lhs (g, rule);
	      if (lhs == s_first_balanced)
		{
		  if (first_balanced_completion != -1) {
		      fprintf (stderr, "First balanced completion is not unique");
		      exit (1);
		  }
		  first_balanced_completion= ahfa_id;
		  break;
		}
	    }
	}
    }
}
      r = create_recce (g);
      for (location = 0; location <= string_length; location++)
	{
	  int origin, status;
	  Marpa_Symbol_ID paren_token = gen_token (string_length, location);
	  status = marpa_alternative (r, paren_token, 0, 1);
	  if (status < -1)
	    fatal_r_error ("marpa alternative", r, status);
	  status = marpa_alternative (r, s_prefix_char, 0, 1);
	  if (status < -1)
	    fatal_r_error ("marpa alternative", r, status);
	  status = marpa_earleme_complete (r);
	  if (status < -1)
	    fatal_r_error ("marpa_earleme_complete", r, status);
	  /* If none of the alternatives were accepted, we are done */
	  origin = at_first_balanced_completion (r, location+1 );
	  if (origin >= 0)
	    {
	      start_of_match = origin;
	      end_of_match = location + 1;
	      break;
	    }
	}
      if (start_of_match < 0)
	{
	  printf ("No balanced parens\n");
	}
      while (++location < string_length)
	{
	  int origin, status;
	  Marpa_Symbol_ID paren_token = gen_token (string_length, location);
	  status = marpa_alternative (r, paren_token, 0, 1);
	  if (status == -1) break;
	  if (status < -1)
	    fatal_r_error ("marpa alternative", r, status);
	  status = marpa_earleme_complete (r);
	  if (status < -1)
	    fatal_r_error ("marpa_earleme_complete", r, status);
	  origin = at_first_balanced_completion (r, location+1 );
	  if (origin >= 0 && origin < start_of_match)
	    {
	      start_of_match = origin;
	      end_of_match = location + 1;
	      break;
	    }
	}
	if (!was_result_written) {
	printf("Match at %d-%d\n", start_of_match, end_of_match);
	was_result_written++;
	}
      marpa_r_free (r);
      marpa_g_free (g);
      g = NULL;
    }
  /* while(1) { putc('.', stderr); sleep(10); } */
  exit (0);
}
