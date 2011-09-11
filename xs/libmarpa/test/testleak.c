/* Hello World program */

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <glib.h>
#include "marpa.h"

int main(void)
{
    Marpa_Symbol_ID S, A, a, E;
    struct marpa_g* g;
    struct marpa_r* r;
    void *result;
    /* Longest rule is 4 symbols */
    Marpa_Symbol_ID rhs[4];
    /* Try to move gslice area out of the
       tree of Marpa calls */
    void* dummy = g_slice_alloc(42);
    g_slice_free1(42, dummy);
    g = marpa_g_new();
    S = marpa_symbol_new(g);
    A = marpa_symbol_new(g);
    a = marpa_symbol_new(g);
    E = marpa_symbol_new(g);
    sleep(60);
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
    marpa_r_free(r);
    marpa_g_free(g);
    g = NULL;
    while(1) {
	putc('.', stderr);
	sleep(60);
    }
}

