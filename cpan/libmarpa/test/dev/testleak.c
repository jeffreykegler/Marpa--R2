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
#include "marpa.h"

static void await_input(void) {
    fputs("Waiting for input: ", stdout);
    getchar();
    fflush(stdin);
}

static int
fail (const char *s, Marpa_Grammar g)
{
  const char *error_string;
  Marpa_Error_Code errcode = marpa_g_error (g, &error_string);
  printf ("%s returned %d: %s", s, errcode, error_string);
  exit (1);
}

int
main (int argc, char **argv)
{
  int i;
  const char *error_string;
  Marpa_Config marpa_configuration;
  Marpa_Symbol_ID S, A, a, E;
  Marpa_Grammar g;
  Marpa_Recognizer r;
  /* Longest rule is 4 symbols */
  Marpa_Symbol_ID rhs[4];
  int initial_sleep = 0;
  if (argc >= 2)
    {
      initial_sleep = atoi (argv[1]);
    }
  await_input ();

  marpa_c_init (&marpa_configuration);
  g = marpa_g_new (&marpa_configuration);
  if (!g) {
    Marpa_Error_Code errcode = marpa_c_error (&marpa_configuration, &error_string);
    printf ("marpa_g_new returned %d: %s", errcode, error_string);
    exit (1);
  }
  ((S = marpa_g_symbol_new (g)) >= 0) || fail ("marpa_g_symbol_new", g);
  ((A = marpa_g_symbol_new (g)) >= 0) || fail ("marpa_g_symbol_new", g);
  ((a = marpa_g_symbol_new (g)) >= 0) || fail ("marpa_g_symbol_new", g);
  ((E = marpa_g_symbol_new (g)) >= 0) || fail ("marpa_g_symbol_new", g);
  for (i = initial_sleep; i > 0; i--)
    {
      sleep (2);
      fputs ("-", stderr);
    }

  fputs ("\n", stderr);
  rhs[0] = A;
  rhs[1] = A;
  rhs[2] = A;
  rhs[3] = A;
  (marpa_g_rule_new (g, S, rhs, 4) >= 0) || fail ("marpa_g_rule_new", g);
  rhs[0] = a;
  (marpa_g_rule_new (g, A, rhs, 1) >= 0) || fail ("marpa_g_rule_new", g);
  rhs[0] = E;
  (marpa_g_rule_new (g, A, rhs, 1) >= 0) || fail ("marpa_g_rule_new", g);
  (marpa_g_rule_new (g, E, rhs, 0) >= 0) || fail ("marpa_g_rule_new", g);
  (marpa_g_symbol_is_terminal_set (g, a, 1) >= 0) ||
    fail ("marpa_g_rule_new", g);
  (marpa_g_start_symbol_set (g, S) >= 0) || fail ("marpa_g_rule_new", g);
  if (marpa_g_precompute (g) < 0)
    {
      marpa_g_error (g, &error_string);
      puts (error_string);
      exit (1);
    }
  r = marpa_r_new (g);
  if (!r)
    {
      marpa_g_error (g, &error_string);
      puts (error_string);
      exit (1);
    }
  if (!marpa_r_start_input (r))
    {
      marpa_g_error (g, &error_string);
      puts (error_string);
      exit (1);
    }
  for (i = 0; i < 4; i++)
    {
      int status = marpa_r_alternative (r, a, 42, 1);
      if (status != MARPA_ERR_NONE)
	{
	  marpa_g_error (g, &error_string);
	  printf ("marpa_alternative returned %d: %s", status, error_string);
	  exit (1);
	}
      status = marpa_r_earleme_complete (r);
      if (status < 0)
	{
	  marpa_g_error (g, &error_string);
	  printf ("marpa_earleme_complete returned %d: %s", status,
		  error_string);
	  exit (1);
	}
    }
  await_input ();
  for (i = 0; i <= 4; i++)
    {
      Marpa_Bocage bocage;
      Marpa_Order order;
      Marpa_Tree tree;
      int tree_ordinal = 0;
      bocage = marpa_b_new (r, i);
      if (!bocage)
	{
	  int errcode = marpa_g_error (g, &error_string);
	  printf ("marpa_bocage_new returned %d: %s", errcode, error_string);
	  exit (1);
	}
      order = marpa_o_new (bocage);
      if (!order)
	{
	  int errcode = marpa_g_error (g, &error_string);
	  printf ("marpa_order_new returned %d: %s", errcode, error_string);
	  exit (1);
	}
      tree = marpa_t_new (order);
      if (!tree)
	{
	  Marpa_Error_Code errcode = marpa_g_error (g, &error_string);
	  printf ("marpa_t_new returned %d: %s", errcode, error_string);
	  exit (1);
	}
      while (++tree_ordinal)
	{
	  Marpa_Value value = NULL;
	  int tree_status;
	  tree_status = marpa_t_next (tree);
	  if (tree_status < -1)
	    {
	      Marpa_Error_Code errcode = marpa_g_error (g, &error_string);
	      printf ("marpa_v_event returned %d: %s", errcode, error_string);
	      exit (1);
	    }
	  if (tree_status == -1)
	    break;
	  fprintf (stdout, "Tree #%d for length %d\n", tree_ordinal, i);
	  value = marpa_v_new (tree);
	  if (!value)
	    {
	      Marpa_Error_Code errcode = marpa_g_error (g, &error_string);
	      printf ("marpa_v_new returned %d: %s", errcode, error_string);
	      exit (1);
	    }
	  while (1)
	    {
	      Marpa_Step_Type step_type = marpa_v_step (value);
	      if (step_type < 0)
		{
		  Marpa_Error_Code errcode = marpa_g_error (g, &error_string);
		  printf ("marpa_v_event returned %d: %s", errcode,
			  error_string);
		  exit (1);
		}
	      if (step_type == MARPA_STEP_INACTIVE)
		{
		  printf ("No more events\n");
		  break;
		}
	      fprintf (stdout, "Step: %d %d %d %d %d\n",
		       marpa_v_token (value),
		       marpa_v_token_value (value),
		       marpa_v_rule (value),
		       marpa_v_arg_0 (value), marpa_v_arg_n (value));
	    }
	  if (value)
	    marpa_v_unref (value);
	}
      marpa_t_unref (tree);
      marpa_o_unref (order);
      marpa_b_unref (bocage);
    }
  marpa_r_unref (r);
  marpa_g_unref (g);
  g = NULL;
  while (1)
    {
      putc ('.', stderr);
      sleep (10);
    }
}
