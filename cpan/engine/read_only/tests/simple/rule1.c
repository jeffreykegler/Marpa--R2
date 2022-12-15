/*
 * Copyright 2022 Jeffrey Kegler
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include "marpa.h"

#include "tap/basic.h"

static void
err (const char *s, Marpa_Grammar g)
{
    Marpa_Error_Code errcode = marpa_g_error (g, NULL);
    printf ("%s: Error %d\n\n", s, errcode);
    marpa_g_error_clear (g);
}

static void
code_fail (const char *s, Marpa_Grammar g)
{
    err (s, g);
    exit (1);
}

int
main (int argc UNUSED, char *argv[] UNUSED)
{

    Marpa_Config marpa_configuration;
    Marpa_Grammar g;

    Marpa_Symbol_ID S_lhs, S_rhs;
    Marpa_Symbol_ID rhs[1];

    Marpa_Rule_ID R_new;

    int rc;

    plan (4);

    marpa_c_init (&marpa_configuration);
    g = marpa_g_new (&marpa_configuration);
    if (!g) {
        Marpa_Error_Code errcode =
            marpa_c_error (&marpa_configuration, NULL);
        printf ("marpa_g_new: error %d", errcode);
        exit (1);
    }
    if (marpa_g_force_valued( g) < 0) {
        code_fail ("marpa_g_symbol_new", g);
    }

    /* Symbols */
    if ((S_lhs = marpa_g_symbol_new (g)) < 0) {
        code_fail ("marpa_g_symbol_new", g);
    }
    if ((S_rhs = marpa_g_symbol_new (g)) < 0) {
        code_fail ("marpa_g_symbol_new", g);
    }

    /* Rule */
    rhs[0] = S_rhs;
    if ((R_new = marpa_g_rule_new (g, S_lhs, rhs, 1)) < 0) {
        code_fail ("marpa_g_rule_new", g);
    }
    ok ((R_new == 0), "marpa_g_rule_new returns 0");

    /* Precompute */
    rc = marpa_g_start_symbol_set (g, S_lhs);
    if (rc < 0) {
        code_fail ("marpa_g_start_symbol_set", g);
    }

    rc = marpa_g_precompute (g);
    ok ((rc == 0), "marpa_g_precompute returned 0");
    if (rc < 0) {
        code_fail ("marpa_g_sequence_separator", g);
    }

    rc = marpa_g_is_precomputed (g);
    ok ((rc == 1), "marpa_g_is_precomputed returned 1");
    if (rc < 0) {
        code_fail ("marpa_g_is_precomputed", g);
    }

    /* Rule accessors */
    rc = marpa_g_rule_lhs (g, R_new);
    ok ((rc == 0), "marpa_g_rule_lhs(%d) returned 0", R_new);
    if (rc < 0) {
        code_fail ("marpa_g_rule_lhs", g);
    }

    marpa_g_unref(g);

    return 0;
}
