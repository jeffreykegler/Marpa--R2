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

int
main (int argc, char **argv)
{
  int pass;
  int string_length = 1000;
  GArray *terminals_expected = g_array_new (FALSE, FALSE, sizeof (gint));
  /* This was to move gslice area out of the
     tree of Marpa calls during memory debugging */
  /* void* dummy = g_slice_alloc(42); */
  /* g_slice_free1(42, dummy); */
  if (argc >= 2)
    {
      string_length = atoi (argv[1]);
    }
  if (string_length < 10)
    {
      fprintf (stderr, "String length is %d, must be at least 10\n",
	       string_length);
      exit (1);
    }
  for (pass = 0; pass < 1; pass++)
    {
      int i;
      int end_of_parse = -1;
      Marpa_Symbol_ID s_top, s_prefix, s_first_balanced, s_endmark;
      Marpa_Symbol_ID s_prefix_char, s_balanced;
      Marpa_Symbol_ID s_lparen, s_rparen;
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
      s_endmark = marpa_symbol_new (g);
      s_prefix_char = marpa_symbol_new (g);
      s_balanced = marpa_symbol_new (g);
      s_lparen = marpa_symbol_new (g);
      s_rparen = marpa_symbol_new (g);
      s_balanced_sequence = marpa_symbol_new (g);
      rhs[0] = s_prefix;
      rhs[1] = s_first_balanced;
      rhs[2] = s_endmark;
      marpa_rule_new (g, s_top, rhs, 3);
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
      marpa_symbol_is_terminal_set (g, s_endmark, 1);
      marpa_start_symbol_set (g, s_top);
      result = marpa_precompute (g);
      if (!result)
	{
	  puts (marpa_g_error (g));
	  exit (1);
	}
      r = marpa_r_new (g);
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
      for (i = 0; i <= string_length; i++)
	{
	  int alternatives_accepted = 0;
	  int status;
	  Marpa_Symbol_ID paren_token = s_lparen;
	  {
	    int count = marpa_terminals_expected (r, terminals_expected);
	    if (count < 0)
	      {
		fprintf (stderr, "Problem in marpa_terminals_expected(): %s",
			 marpa_r_error (r));
	      }
	    while (count > 0)
	      {
		int expected_symbol_id =
		  g_array_index (terminals_expected, gint, count);
		if (expected_symbol_id == s_endmark) {
		    end_of_parse = i;
		}
		count--;
	      }
	  }
	  if (i >= string_length) break;
	  switch (i + 8 - string_length)
	    {
	    case 2:
	    case 4:
	      paren_token = s_rparen;
	    }
	  status = marpa_alternative (r, paren_token, 0, 1);
	  if (status < -1)
	    {
	      fprintf (stderr, "marpa_alternative returned %d: %s", status,
		      marpa_r_error (r));
	      exit (1);
	    }
	  if (status >= 0) alternatives_accepted++;
	  /* If we have not seen the end of a balanced set of parentheses,
	     we might be in a prefix */
if (end_of_parse < 0)
  {
    status = marpa_alternative (r, s_prefix_char, 0, 1);
    if (status < -1)
      {
	fprintf (stderr, "marpa_alternative returned %d: %s", status,
		 marpa_r_error (r));
	exit (1);
      }
    if (status >= 0)
      alternatives_accepted++;
  }
	  /* If none of the alternatives were accepted, we are done */
	  if (alternatives_accepted <= 0) break;
	  status = marpa_earleme_complete (r);
	  if (status < 0)
	    {
	      fprintf (stderr, "marpa_earleme_complete returned %d: %s", status,
		      marpa_r_error (r));
	      exit (1);
	    }
	}
      {
	int status = marpa_bocage_new (r, -1, end_of_parse);
	if (status < 0)
	  {
	    fprintf (stderr, "marpa_bocage_new returned %d: %s\n", status,
		     marpa_r_error (r));
	    exit (1);
	  }
	marpa_bocage_free (r);
      }
      marpa_r_free (r);
      marpa_g_free (g);
      g = NULL;
    }
  /* while(1) { putc('.', stderr); sleep(10); } */
  exit (0);
}
