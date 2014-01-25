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

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include "marpa.h"

#define Dim(x) (sizeof(x)/sizeof(*x))

#if defined (__GNUC__) && defined (__STRICT_ANSI__)
#  undef inline
#  define inline __inline__
#endif

Marpa_AHFA_State_ID first_balanced_completion;

Marpa_Symbol_ID s_lparen;
Marpa_Symbol_ID s_rparen;
Marpa_Symbol_ID s_endmark;

struct leo_workitem
{
  Marpa_Earley_Set_ID es;
  Marpa_Symbol_ID transition_symbol;
};

static inline char *
gen_example_string (int length)
{
  char *result = malloc ((unsigned int) length + 1);
  int i;
  for (i = 0; i < length - 8; i++)
    {
      result[i] = '(';
    }
  strcpy (result + i, "(()())((");
  return result;
}

static inline struct marpa_r *
create_recce (struct marpa_g *g)
{
  struct marpa_r *r = marpa_r_new (g);
  if (!r)
    {
      puts (marpa_g_error (g));
      exit (1);
    }
  if (!marpa_start_input (r))
    {
      puts (marpa_g_error (g));
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

static Marpa_Earley_Set_ID
at_first_balanced_completion (struct marpa_r *r, int current_earley_set)
{
  int eim = 0;
  unsigned int work_item_ix;

  GArray *leo_worklist =
    g_array_new (TRUE, FALSE, sizeof (struct leo_workitem));
  int earleme = marpa_earley_set_trace (r, current_earley_set);
  /* printf("marpa_earley_set_trace: es=%d, earleme=%d\n", earley_set, earleme); */
  if (earleme < -1)
    {
      fatal_r_error ("marpa_earley_set_trace", r, earleme);
    }
  while (1)
    {
      Marpa_AHFA_State_ID ahfa_id;
      Marpa_AHFA_State_ID leo_cause_ahfa;
      ahfa_id = marpa_earley_item_trace (r, eim);
      if (ahfa_id < -1)
	{
	  fatal_r_error ("marpa_earley_item_trace", r, ahfa_id);
	}
      if (ahfa_id == -1)
	break;
      /* printf("es=%d, eim=%d, ahfa_id=%d\n", earley_set, eim, ahfa_id); */
      if (ahfa_id == first_balanced_completion)
	{
	  Marpa_Earley_Set_ID es = marpa_earley_item_origin (r);
	  if (es < 0)
	    {
	      fatal_r_error ("marpa_earley_item_origin", r, es);
	    }
	  return es;
	}
      for (leo_cause_ahfa = marpa_first_leo_link_trace (r);
	   leo_cause_ahfa >= 0;
	   leo_cause_ahfa = marpa_next_leo_link_trace (r))
	{
	  struct leo_workitem workitem;
	  Marpa_Earley_Set_ID leo_earley_set;
	  Marpa_Symbol_ID leo_transition_symbol =
	    marpa_source_leo_transition_symbol (r);
	  if (leo_transition_symbol < 0)
	    {
	      fatal_r_error ("marpa_source_leo_transition_symbol", r,
			     leo_transition_symbol);
	    }
	  leo_earley_set = marpa_source_middle (r);
	  if (leo_earley_set < 0)
	    {
	      fatal_r_error ("marpa_source_middle", r, leo_earley_set);
	    }
	  workitem.es = leo_earley_set;
	  workitem.transition_symbol = leo_transition_symbol;
	  g_array_append_vals (leo_worklist, &workitem, 1);
	}
      if (leo_cause_ahfa < -1)
	{
	  fatal_r_error ("marpa_{first,next}_leo_item_trace", r,
			 leo_cause_ahfa);
	}
      eim++;
    }
  for (work_item_ix = 0; work_item_ix < leo_worklist->len; work_item_ix++)
    {
      /* No relevant Leo items in this grammar, so this logic is not
       * really tested -- it was copied from Marpa::XS */
      struct leo_workitem *workitem =
	&g_array_index (leo_worklist, struct leo_workitem, work_item_ix);
      Marpa_Symbol_ID leo_transition_symbol = workitem->transition_symbol;
      Marpa_Earleme earley_set_of_leo_item = workitem->es;
      while (1)
	{
	  Marpa_Earley_Set_ID origin;
	  Marpa_AHFA_State_ID expansion_ahfa_id;
	  int result = marpa_earley_set_trace (r, earley_set_of_leo_item);
	  if (result < -1)
	    {
	      fatal_r_error ("marpa_earley_set_trace", r, result);
	    }
	  result = marpa_postdot_symbol_trace (r, leo_transition_symbol);
	  if (result < 0)
	    {
	      fatal_r_error ("marpa_postdot_symbol_trace", r, result);
	    }
	  expansion_ahfa_id = marpa_leo_expansion_ahfa (r);
	  if (expansion_ahfa_id < 0)
	    {
	      fatal_r_error ("marpa_leo_expansion_ahfa", r,
			     expansion_ahfa_id);
	    }
	  origin = marpa_leo_base_origin (r);
	  if (origin < 0)
	    {
	      fatal_r_error ("marpa_leo_base_origin", r, origin);
	    }
	  if (expansion_ahfa_id == first_balanced_completion)
	    {
	      return origin;
	    }
	  leo_transition_symbol = marpa_leo_predecessor_symbol (r);
	  if (leo_transition_symbol == -1)
	    break;
	  if (leo_transition_symbol < -1)
	    {
	      fatal_r_error ("marpa_leo_predecessor_symbol", r,
			     leo_transition_symbol);
	    }
	  earley_set_of_leo_item = origin;
	}
    }
  g_array_free (leo_worklist, TRUE);
  return -1;
}

static int string_length = 1000;
static int repeats = 1;
static char *string = NULL;

static GOptionEntry entries[] = {
  {"length", 'l', 0, G_OPTION_ARG_INT, &string_length,
   "Length of test string", "L"},
  {"repeats", 'r', 0, G_OPTION_ARG_INT, &repeats, "Test R times", "R"},
  {"string", 's', 0, G_OPTION_ARG_STRING, &string, "String to test", NULL},
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
  char *test_string;

  context = g_option_context_new ("- test balanced parens");
  g_option_context_add_main_entries (context, entries, NULL);
  if (!g_option_context_parse (context, &argc, &argv, &error))
    {
      g_print ("option parsing failed: %s\n", error->message);
      exit (1);
    }

  if (string)
    {
      /* Never freed */
      test_string = string;
      string_length = strlen (test_string);
      printf ("Target is \"%s\", length=%d\n", test_string, string_length);
    }
  else if (string_length < 10)
    {
      fprintf (stderr, "String length is %d, must be at least 10\n",
	       string_length);
      exit (1);
    }
  else
    {
      /* Never freed */
      test_string = gen_example_string (string_length);
      printf ("Target at end, length=%d\n", string_length);
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
	    unsigned int aim_ix;
	    unsigned int aim_count = marpa_AHFA_state_item_count (g, ahfa_id);
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
			if (first_balanced_completion != -1)
			  {
			    fprintf (stderr,
				     "First balanced completion is not unique");
			    exit (1);
			  }
			first_balanced_completion = ahfa_id;
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
	  Marpa_Symbol_ID paren_token =
	    test_string[location] == '(' ? s_lparen : s_rparen;
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
	  origin = at_first_balanced_completion (r, location + 1);
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
	  int origin, status, earleme_complete_status;
	  Marpa_Symbol_ID paren_token =
	    test_string[location] == '(' ? s_lparen : s_rparen;
	  status = marpa_alternative (r, paren_token, 0, 1);
	  if (status == -1)
	    break;
	  if (status < -1)
	    fatal_r_error ("marpa alternative", r, status);
	  earleme_complete_status = marpa_earleme_complete (r);
	  if (earleme_complete_status < -1)
	    fatal_r_error ("marpa_earleme_complete", r,
			   earleme_complete_status);
	  origin = at_first_balanced_completion (r, location + 1);
	  if (origin >= 0 && origin < start_of_match)
	    {
	      start_of_match = origin;
	      end_of_match = location + 1;
	      break;
	    }
	  if (earleme_complete_status == 0)
	    break;
	}
      if (!was_result_written)
	{
	  printf ("Match at %d-%d\n", start_of_match, end_of_match);
	  was_result_written++;
	}
      marpa_r_free (r);
      marpa_g_free (g);
      g = NULL;
    }
  exit (0);
}
