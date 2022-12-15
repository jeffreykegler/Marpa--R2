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
    int errcode = marpa_g_error (g, NULL);
    printf ("%s returned error_code %d: %s\n", s, errcode,
        marpa_m_error_message (errcode));
}

static void
fail (const char *s, Marpa_Grammar g)
{
    warn (s, g);
    exit (1);
}

static void
err (const char *s, Marpa_Grammar g)
{
    Marpa_Error_Code errcode = marpa_g_error (g, NULL);
    printf ("%s: Error %d\n\n", s, errcode);
    marpa_g_error_clear (g);
}

Marpa_Rule_ID R_top;
Marpa_Rule_ID R_nulling;

Marpa_Symbol_ID S_top;
Marpa_Symbol_ID S_null;
Marpa_Symbol_ID S_tok;

/* For (error) messages */
char msgbuf[80];

UNUSED static char *
symbol_name (Marpa_Symbol_ID id)
{
    if (id == S_top)
        return (char *) "top";
    if (id == S_null)
        return (char *) "null";
    if (id == S_tok)
        return (char *) "tok";
    sprintf (msgbuf, "no such symbol: %d", id);
    return msgbuf;
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

    plan (62);

    marpa_c_init (&marpa_configuration);
    g = marpa_g_new (&marpa_configuration);
    if (!g) {
        Marpa_Error_Code errcode =
            marpa_c_error (&marpa_configuration, NULL);
        printf ("marpa_g_new: error %d", errcode);
        exit (1);
    }

    if ((S_top = marpa_g_symbol_new (g)) < 0) {
        err ("marpa_g_symbol_new", g);
    }
    if ((S_null = marpa_g_symbol_new (g)) < 0) {
        err ("marpa_g_symbol_new", g);
    }
    if ((S_tok = marpa_g_symbol_new (g)) < 0) {
        err ("marpa_g_symbol_new", g);
    }

    {
        /* Rule */
        Marpa_Symbol_ID rhs[5];
        rhs[0] = S_null;
        rhs[1] = S_tok;
        rhs[2] = S_null;
        rhs[3] = S_tok;
        rhs[4] = S_null;

        if ((R_top = marpa_g_rule_new (g, S_top, rhs, 5)) < 0) {
            err ("marpa_g_rule_new", g);
        }
        ok (1, "marpa_g_rule_new returns 0");

        if ((R_nulling = marpa_g_rule_new (g, S_null, rhs, 0)) < 0) {
            err ("marpa_g_rule_new", g);
        }
        ok (1, "marpa_g_rule_new returns 0");
    }

    /* Precompute */
    rc = marpa_g_start_symbol_set (g, S_top);
    if (rc < 0) {
        err ("marpa_g_start_symbol_set", g);
    }

    rc = marpa_g_precompute (g);
    ok ((rc == 0), "marpa_g_precompute returned 0");
    if (rc < 0) {
        err ("marpa_g_sequence_separator", g);
    }

    defaults_reset (&defaults, g);
    this_test = defaults;

    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_g_force_valued, g);

    /* Recognizer Methods */
    r = marpa_r_new (g);
    if (!r)
        fail ("marpa_r_new", g);

    /* start the recce */
    rc = marpa_r_start_input (r);
    if (!rc)
        fail ("marpa_r_start_input", g);
    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_r_latest_earley_set,
        r);

    this_test = defaults;

    API_STD_TEST3 (defaults, MARPA_ERR_NONE, MARPA_ERR_NONE,
        marpa_r_alternative, r, S_tok, 42, 1);
    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_r_earleme_complete,
        r);
    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_r_latest_earley_set,
        r);

    API_STD_TEST3 (defaults, MARPA_ERR_NONE, MARPA_ERR_NONE,
        marpa_r_alternative, r, S_tok, 43, 1);
    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_r_earleme_complete,
        r);
    API_STD_TEST0 (defaults, 2, MARPA_ERR_NONE, marpa_r_latest_earley_set,
        r);

    this_test.msg = (char *) "at earleme 0";
    API_STD_TEST0 (this_test, 1, MARPA_ERR_NONE, marpa_r_is_exhausted, r);

    /* Bocage */
    b = marpa_b_new (r, -1);

    if (!b) {
        fail ("marpa_b_new", g);
    } else
        ok (1, "marpa_b_new(): parse at current earleme");

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE,
        marpa_b_ambiguity_metric, b);
    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_b_is_null, b);

    /* Order */
    o = marpa_o_new (b);

    if (!o)
        fail ("marpa_o_new", g);
    else
        ok (1, "marpa_o_new()");

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE,
        marpa_o_ambiguity_metric, o);
    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_o_is_null, o);

    /* Tree */
    t = marpa_t_new (o);
    if (!t)
        fail ("marpa_t_new", g);
    else
        ok (1, "marpa_t_new()");

    this_test.msg = (char *) "before the first parse tree";
    API_STD_TEST0 (this_test, 0, MARPA_ERR_NONE, marpa_t_parse_count, t);

    rc = marpa_t_next (t);
    if (rc < 0)
        fail ("marpa_t_next", g);
    else
        ok (1, "marpa_t_next()");

    /* Value */
    v = marpa_v_new (t);
    if (!v)
        fail ("marpa_v_new", g);
    else
        ok (1, "marpa_v_new()");

    {
        Marpa_Step_Type step_type = marpa_v_step (v);
        is_int (MARPA_STEP_NULLING_SYMBOL, step_type,
            "0: MARPA_STEP_NULLING_SYMBOL step returned.");
        is_int (0, marpa_v_result (v), "0: marpa_v_result(v)");
        is_int (MARPA_STEP_NULLING_SYMBOL, marpa_v_step_type (v),
            "0: marpa_v_step_type(v)");
        is_int (S_null, marpa_v_symbol (v), "0: marpa_v_symbol(v)");
        is_int (0, marpa_v_es_id (v), "0: marpa_v_es_id(v)");
        is_int (0, marpa_v_token_start_es_id (v),
            "0: marpa_v_token_start_es_id(v)");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_TOKEN, step_type,
            "1: MARPA_STEP_TOKEN step returned.");
        is_int (1, marpa_v_result (v), "1: marpa_v_result(v)");
        is_int (MARPA_STEP_TOKEN, marpa_v_step_type (v),
            "1: marpa_v_step_type(v)");
        is_int (S_tok, marpa_v_symbol (v), "1: marpa_v_symbol(v)");
        is_int (0, marpa_v_token_start_es_id (v),
            "1: marpa_v_token_start_es_id(v)");
        is_int (1, marpa_v_es_id (v), "1: marpa_v_es_id(v)");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_NULLING_SYMBOL, step_type,
            "2: MARPA_STEP_NULLING_SYMBOL step returned.");
        is_int (2, marpa_v_result (v), "2: marpa_v_result(v)");
        is_int (MARPA_STEP_NULLING_SYMBOL, marpa_v_step_type (v),
            "2: marpa_v_step_type(v)");
        is_int (S_null, marpa_v_symbol (v), "2: marpa_v_symbol(v)");
        is_int (1, marpa_v_token_start_es_id (v),
            "2: marpa_v_token_start_es_id(v)");
        is_int (1, marpa_v_es_id (v), "2: marpa_v_es_id(v)");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_TOKEN, step_type,
            "3: MARPA_STEP_TOKEN step returned.");
        is_int (3, marpa_v_result (v), "3: marpa_v_result(v)");
        is_int (MARPA_STEP_TOKEN, marpa_v_step_type (v),
            "3: marpa_v_step_type(v)");
        is_int (S_tok, marpa_v_symbol (v), "3: marpa_v_symbol(v)");
        is_int (1, marpa_v_token_start_es_id (v),
            "3: marpa_v_token_start_es_id(v)");
        is_int (2, marpa_v_es_id (v), "3: marpa_v_es_id(v)");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_NULLING_SYMBOL, step_type,
            "4: MARPA_STEP_NULLING_SYMBOL step returned.");
        is_int (4, marpa_v_result (v), "4: marpa_v_result(v)");
        is_int (MARPA_STEP_NULLING_SYMBOL, marpa_v_step_type (v),
            "4: marpa_v_step_type(v)");
        is_int (S_null, marpa_v_symbol (v), "4: marpa_v_symbol(v)");
        is_int (2, marpa_v_token_start_es_id (v),
            "4: marpa_v_token_start_es_id(v)");
        is_int (2, marpa_v_es_id (v), "4: marpa_v_es_id(v)");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_RULE, step_type,
            "5: MARPA_STEP_RULE step returned.");
        is_int (0, marpa_v_result (v), "5: marpa_v_result(v)");
        is_int (0, marpa_v_arg_0 (v), "5: marpa_v_arg_0(v)");
        is_int (4, marpa_v_arg_n (v), "5: marpa_v_arg_n(v)");
        is_int (MARPA_STEP_RULE, marpa_v_step_type (v),
            "5: marpa_v_step_type(v)");
        is_int (R_top, marpa_v_rule (v), "5: marpa_v_rule(v)");
        is_int (0, marpa_v_rule_start_es_id (v),
            "5: marpa_v_rule_start_es_id(v)");
        is_int (2, marpa_v_es_id (v), "5: marpa_v_es_id(v)");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_INACTIVE, step_type,
            "6: MARPA_STEP_INACTIVE step.");

        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_INACTIVE, step_type,
            "7: MARPA_STEP_INACTIVE step after retry of marpa_v_step().");
    }

    /* Needed for ASan test */
    marpa_v_unref(v);
    marpa_t_unref(t);
    marpa_o_unref(o);
    marpa_b_unref(b);
    marpa_r_unref(r);
    marpa_g_unref(g);

    return 0;
}
