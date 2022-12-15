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

/* Tests of Libmarpa methods on trivial grammar */

#include <stdio.h>
#include <string.h>
#include "marpa.h"

#include "marpa_m_test.h"

static void
warn (const char *s, Marpa_Grammar g)
{
    printf ("%s returned %d\n", s, marpa_g_error (g, NULL));
}

static void
fail (const char *s, Marpa_Grammar g)
{
    warn (s, g);
    exit (1);
}

Marpa_Symbol_ID S_top;
Marpa_Symbol_ID S_A1;
Marpa_Symbol_ID S_A2;
Marpa_Symbol_ID S_B1;
Marpa_Symbol_ID S_B2;
Marpa_Symbol_ID S_C1;
Marpa_Symbol_ID S_C2;

/* Longest rule is <= 4 symbols */
Marpa_Symbol_ID rhs[4];

Marpa_Rule_ID R_top_1;
Marpa_Rule_ID R_top_2;
Marpa_Rule_ID R_C2_3;           /* highest rule id */

/* For (error) messages */
char msgbuf[80];

UNUSED static char *
symbol_name (Marpa_Symbol_ID id)
{
    if (id == S_top)
        return (char *) "top";
    if (id == S_A1)
        return (char *) "A1";
    if (id == S_A2)
        return (char *) "A2";
    if (id == S_B1)
        return (char *) "B1";
    if (id == S_B2)
        return (char *) "B2";
    if (id == S_C1)
        return (char *) "C1";
    if (id == S_C2)
        return (char *) "C2";
    sprintf (msgbuf, "no such symbol: %d", id);
    return msgbuf;
}

UNUSED static int
is_nullable (Marpa_Symbol_ID id)
{
    if (id == S_top)
        return 1;
    if (id == S_A1)
        return 1;
    if (id == S_A2)
        return 1;
    if (id == S_B1)
        return 1;
    if (id == S_B2)
        return 1;
    if (id == S_C1)
        return 1;
    if (id == S_C2)
        return 1;
    return 0;
}

UNUSED static int
is_nulling (Marpa_Symbol_ID id)
{
    if (id == S_C1)
        return 1;
    if (id == S_C2)
        return 1;
    return 0;
}

static Marpa_Grammar
marpa_g_trivial_new (Marpa_Config * config)
{
    Marpa_Grammar g;
    g = marpa_g_new (config);
    if (!g) {
        Marpa_Error_Code errcode = marpa_c_error (config, NULL);
        printf ("marpa_g_new returned %d", errcode);
        exit (1);
    }

    if ((S_top = marpa_g_symbol_new (g)) < 0) {
        fail ("marpa_g_symbol_new", g);
    }
    if ((S_A1 = marpa_g_symbol_new (g)) < 0) {
        fail ("marpa_g_symbol_new", g);
    }
    if ((S_A2 = marpa_g_symbol_new (g)) < 0) {
        fail ("marpa_g_symbol_new", g);
    }
    if ((S_B1 = marpa_g_symbol_new (g)) < 0) {
        fail ("marpa_g_symbol_new", g);
    }
    if ((S_B2 = marpa_g_symbol_new (g)) < 0) {
        fail ("marpa_g_symbol_new", g);
    }
    if ((S_C1 = marpa_g_symbol_new (g)) < 0) {
        fail ("marpa_g_symbol_new", g);
    }
    if ((S_C2 = marpa_g_symbol_new (g)) < 0) {
        fail ("marpa_g_symbol_new", g);
    }

    rhs[0] = S_A1;
    if ((R_top_1 = marpa_g_rule_new (g, S_top, rhs, 1)) < 0) {
        fail ("marpa_g_rule_new", g);
    }
    rhs[0] = S_A2;
    if ((R_top_2 = marpa_g_rule_new (g, S_top, rhs, 1)) < 0) {
        fail ("marpa_g_rule_new", g);
    }
    rhs[0] = S_B1;
    if (marpa_g_rule_new (g, S_A1, rhs, 1) < 0) {
        fail ("marpa_g_rule_new", g);
    }
    rhs[0] = S_B2;
    if (marpa_g_rule_new (g, S_A2, rhs, 1) < 0) {
        fail ("marpa_g_rule_new", g);
    }
    rhs[0] = S_C1;
    if (marpa_g_rule_new (g, S_B1, rhs, 1) < 0) {
        fail ("marpa_g_rule_new", g);
    }
    rhs[0] = S_C2;
    if (marpa_g_rule_new (g, S_B2, rhs, 1) < 0) {
        fail ("marpa_g_rule_new", g);
    }
    if (marpa_g_rule_new (g, S_C1, rhs, 0) < 0) {
        fail ("marpa_g_rule_new", g);
    }

    if ((R_C2_3 = marpa_g_rule_new (g, S_C2, rhs, 0)) < 0) {
        fail ("marpa_g_rule_new", g);
    }

    return g;
}

static Marpa_Error_Code
marpa_g_trivial_precompute (Marpa_Grammar g, Marpa_Symbol_ID S_start)
{
    Marpa_Error_Code rc;

    if (marpa_g_start_symbol_set (g, S_start) < 0) {
        fail ("marpa_g_start_symbol_set", g);
    }

    rc = marpa_g_precompute (g);
    if (rc < 0)
        fail ("marpa_g_precompute", g);

    return rc;
}

static void
defaults_reset (API_test_data * defaults, Marpa_Grammar g)
{
    defaults->g = g;
    defaults->expected_errcode = MARPA_ERR_NONE;
    defaults->msg = (char *) "";
    defaults->rv_seen.long_rv = -86;
}

int
main (int argc UNUSED, char *argv[] UNUSED)
{
    int rc;

    Marpa_Config marpa_configuration;
    Marpa_Grammar g;
    Marpa_Recognizer r;
    Marpa_Bocage b;
    Marpa_Order o;
    Marpa_Tree t;
    Marpa_Value v;

    API_test_data defaults;
    API_test_data this_test;

    plan (34);

    marpa_c_init (&marpa_configuration);
    g = marpa_g_trivial_new (&marpa_configuration);
    defaults_reset (&defaults, g);
    this_test = defaults;

    /* precomputation */
    marpa_g_trivial_precompute (g, S_top);
    ok (1, "precomputation succeeded");

    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_g_force_valued, g);

    /* Recognizer Methods */
    r = marpa_r_new (g);
    if (!r)
        fail ("marpa_r_new", g);

    /* start the recce */
    rc = marpa_r_start_input (r);
    if (!rc)
        fail ("marpa_r_start_input", g);

    diag ("The below recce tests are at earleme 0");

    this_test = defaults;

    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_r_latest_earley_set,
        r);

    this_test.msg = (char *) "at earleme 0";
    API_STD_TEST0 (this_test, 1, MARPA_ERR_NONE, marpa_r_is_exhausted, r);

    /* Bocage */
    b = marpa_b_new (r, -1);
    if (!b)
        fail ("marpa_b_new", g);
    else
        ok (1, "marpa_b_new(): parse at current earleme of trivial parse");

    marpa_b_unref (b);

    b = marpa_b_new (r, 0);

    if (!b)
        fail ("marpa_b_new", g);
    else
        ok (1, "marpa_b_new(): null parse at earleme 0");

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE,
        marpa_b_ambiguity_metric, b);
    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_b_is_null, b);

    /* Order */
    o = marpa_o_new (b);

    if (!o)
        fail ("marpa_o_new", g);
    else
        ok (1, "marpa_o_new() at earleme 0");

    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE,
        marpa_o_high_rank_only_set, o, 1);
    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_o_high_rank_only, o);

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE,
        marpa_o_ambiguity_metric, o);
    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_o_is_null, o);

    API_STD_TEST1 (defaults, -2, MARPA_ERR_ORDER_FROZEN,
        marpa_o_high_rank_only_set, o, 1);
    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_o_high_rank_only, o);

    /* Tree */
    t = marpa_t_new (o);
    if (!t)
        fail ("marpa_t_new", g);
    else
        ok (1, "marpa_t_new() at earleme 0");

    this_test.msg = (char *) "before the first parse tree";
    API_STD_TEST0 (this_test, 0, MARPA_ERR_NONE, marpa_t_parse_count, t);
    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_t_next, t);

    /* Value */
    v = marpa_v_new (t);
    if (!t)
        fail ("marpa_v_new", g);
    else
        ok (1, "marpa_v_new() at earleme 0");

    {
        Marpa_Step_Type step_type = marpa_v_step (v);
        is_int (MARPA_STEP_NULLING_SYMBOL, step_type,
            "MARPA_STEP_NULLING_SYMBOL step.");

        is_int (0, marpa_v_result (v), "marpa_v_result(v)");
        is_int (MARPA_STEP_NULLING_SYMBOL, marpa_v_step_type (v),
            "marpa_v_step_type(v)");
        is_int (0, marpa_v_symbol (v), "marpa_v_symbol(v)");
        is_int (0, marpa_v_es_id (v), "marpa_v_es_id(v)");
        is_int (0, marpa_v_token_start_es_id (v),
            "marpa_v_token_start_es_id(v)");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_INACTIVE, step_type,
            "MARPA_STEP_INACTIVE step.");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_INACTIVE, step_type,
            "MARPA_STEP_INACTIVE step after retry of marpa_v_step().");
    }

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_t_parse_count, t);
    API_STD_TEST0 (defaults, -2, MARPA_ERR_TREE_PAUSED, marpa_t_next, t);

    marpa_v_unref (v);

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_t_parse_count, t);
    API_STD_TEST0 (defaults, -1, MARPA_ERR_TREE_EXHAUSTED, marpa_t_next,
        t);

    /* Needed for ASan test */
    marpa_t_unref (t);
    marpa_o_unref (o);
    marpa_b_unref (b);
    marpa_r_unref (r);
    marpa_g_unref (g);

    return 0;
}
