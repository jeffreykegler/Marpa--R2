/*
 * Copyright 2011 Jeffrey Kegler
 * This file is part of Marpa::XS.  Marpa::XS is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Marpa::XS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Marpa::XS.  If not, see
 * http://www.gnu.org/licenses/.
 */

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <glib.h>
#include "marpa.h"

int main(int argc, char **argv)
{
    int i;
    Marpa_Symbol_ID S, A, a, E;
    struct marpa_g* g;
    struct marpa_r* r;
    void *result;
    /* Longest rule is 4 symbols */
    Marpa_Symbol_ID rhs[4];
    int initial_sleep = 0;
    /* Try to move gslice area out of the
       tree of Marpa calls */
    void* dummy = g_slice_alloc(42);
    if (argc >= 2) {
        initial_sleep = atoi(argv[1]);
    }
    g_slice_free1(42, dummy);
    g = marpa_g_new();
    S = marpa_symbol_new(g);
    A = marpa_symbol_new(g);
    a = marpa_symbol_new(g);
    E = marpa_symbol_new(g);
    for (i = initial_sleep; i > 0; i--) {
	sleep(2);
	fputs("-", stderr);
    }
    fputs("\n", stderr);
    rhs[0] = A;
    rhs[1] = A;
    rhs[2] = A;
    rhs[3] = A;
    marpa_rule_new(g, S, rhs, 4);
    rhs[0] = a;
    marpa_rule_new(g, A, rhs, 1);
    rhs[0] = E;
    marpa_rule_new(g, A, rhs, 1);
    marpa_rule_new(g, E, rhs, 0);
    marpa_symbol_is_terminal_set(g, a, 1);
    marpa_start_symbol_set(g, S);
    result = marpa_precompute(g);
    if (!result) {
        puts(marpa_g_error(g));
	exit(1);
    }
    r = marpa_r_new(g);
    if (!r) {
        puts(marpa_r_error(r));
	exit(1);
    }
    if (!marpa_start_input(r)) {
        puts(marpa_r_error(r));
	exit(1);
    }
    for (i = 0; i < 4; i++) {
	int status = marpa_alternative(r, a, GINT_TO_POINTER(42), 1);
	if (status < 0) {
	   printf("marpa_alternative returned %d: %s", status,
	    marpa_r_error(r));
	   exit(1);
	}
	status = marpa_earleme_complete(r);
	if (status < 0) {
	   printf("marpa_earleme_complete returned %d: %s", status,
	    marpa_r_error(r));
	   exit(1);
	}
    }
    for (i = 0; i <= 4; i++) {
	int tree_ordinal = 0;
	int status = marpa_bocage_new(r, -1, i);
	if (status < 0) {
	   printf("marpa_bocage_new returned %d: %s", status,
	    marpa_r_error(r));
	   exit(1);
	}
	while (++tree_ordinal) {
	    int value_ordinal = 0;
	    int val_status;
	    int tree_status = marpa_tree_new(r);
	    if (tree_status < -1) {
	       printf("marpa_tree_new returned %d: %s", status,
		marpa_r_error(r));
	       exit(1);
	    }
	    if (tree_status == -1) break;
	    fprintf(stdout, "Tree #%d for length %d\n", tree_ordinal, i);
	    val_status = marpa_val_new(r);
	    if (val_status < 0) {
	       printf("marpa_val_new returned %d: %s", status,
		marpa_r_error(r));
	       exit(1);
	    }
	    while (1) {
	       Marpa_Event event;
	       int event_status = marpa_val_event(r, &event);
	       if (event_status < -1) {
		   printf("marpa_val_event returned %d: %s", status,
		    marpa_r_error(r));
		   exit(1);
	       }
	       if (event_status == -1) break;
		fprintf(stdout, "Event: %d %d %d %d %d\n",
		    event.marpa_token_id,
		    GPOINTER_TO_INT(event.marpa_value),
		    event.marpa_rule_id,
		    event.marpa_arg_0,
		    event.marpa_arg_n);
	    }
	}
	marpa_bocage_free(r);
    }
    marpa_r_free(r);
    marpa_g_free(g);
    g = NULL;
    while(1) {
	putc('.', stderr);
	sleep(10);
    }
}

