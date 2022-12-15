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

/* Tests of Libmarpa methods on trivial grammar that is not merely nulling */

#include <stdio.h>
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
Marpa_Rule_ID R_C2_3;           /* Highest rule id */

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

static Marpa_Grammar
marpa_g_simple_new (Marpa_Config * config)
{
    Marpa_Grammar g;
    g = marpa_g_new (config);
    if (!g) {
        Marpa_Error_Code errcode = marpa_c_error (config, NULL);
        printf ("marpa_g_new returned %d", errcode);
        exit (1);
    }
    if ( marpa_g_force_valued( g) < 0) {
        fail ("marpa_g_force_valued", g);
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

    /*
     * top ::= A1
     * top ::= A2
     * A1  ::= B1
     * A2  ::= B2
     * B1  ::= C1
     * B2  ::= C2
     */
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

    return g;
}

static Marpa_Error_Code
marpa_g_simple_precompute (Marpa_Grammar g, Marpa_Symbol_ID S_start)
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

int
main (int argc UNUSED, char *argv[] UNUSED)
{
    int rc;
    int flag;

    Marpa_Config marpa_configuration;
    Marpa_Grammar g;
    Marpa_Recognizer r;
    Marpa_Bocage b;
    Marpa_Order o;

    Marpa_Symbol_ID S_token = S_A2;

    API_test_data defaults;
    API_test_data this_test;

    plan (20);

    marpa_c_init (&marpa_configuration);
    g = marpa_g_simple_new (&marpa_configuration);

    defaults.g = g;
    defaults.expected_errcode = MARPA_ERR_NONE;
    defaults.msg = (char *) "";
    defaults.rv_seen.long_rv = -86;

    this_test = defaults;

    marpa_g_simple_precompute (g, S_top);
    ok (1, "precomputation succeeded");

    r = marpa_r_new (g);
    if (!r)
        fail ("marpa_r_new", g);

    this_test.msg = (char *) "before marpa_r_start_input()";
    API_CODE_TEST3 (this_test, MARPA_ERR_RECCE_NOT_ACCEPTING_INPUT,
        marpa_r_alternative, r, S_token, 0, 0);

    rc = marpa_r_start_input (r);
    if (!rc)
        fail ("marpa_r_start_input", g);

    {
        Marpa_Symbol_ID S_expected = S_A2;
        int value = 1;
        API_STD_TEST2 (this_test, value, MARPA_ERR_NONE,
            marpa_r_expected_symbol_event_set, r, S_expected, value);
    }

    /* recognizer reading methods on invalid and missing symbols */

    this_test.msg =
        (char *) "invalid token symbol is checked before no-such";
    API_CODE_TEST3 (this_test, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_r_alternative, r, S_invalid, 0, 0);
    this_test.msg = (char *) "no such token symbol";
    API_CODE_TEST3 (this_test, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_r_alternative, r, S_no_such, 0, 0);
    this_test.msg =
        (char *) marpa_m_error_message (MARPA_ERR_TOKEN_LENGTH_LE_ZERO);
    API_CODE_TEST3 (this_test, MARPA_ERR_TOKEN_LENGTH_LE_ZERO,
        marpa_r_alternative, r, S_token, 0, 0);


    API_STD_TEST0 (defaults, -2, MARPA_ERR_PARSE_EXHAUSTED,
        marpa_r_earleme_complete, r);

    /* re-create the recce and try some input */
    marpa_r_unref(r);
    r = marpa_r_new (g);
    if (!r)
        fail ("marpa_r_new", g);

    rc = marpa_r_start_input (r);
    if (!rc)
        fail ("marpa_r_start_input", g);

    this_test = defaults;
    API_CODE_TEST3 (this_test, MARPA_ERR_NONE,
        marpa_r_alternative, r, S_C1, 1, 1);

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE,
        marpa_r_earleme_complete, r);

    /* marpa_o_high_rank_only_* */
    b = marpa_b_new (r, marpa_r_current_earleme (r));
    if (!b)
        fail ("marpa_b_new", g);

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE,
        marpa_b_ambiguity_metric, b);
    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_b_is_null, b);

    o = marpa_o_new (b);
    ok (o != NULL, "marpa_o_new(): ordering at earleme 0");

    flag = 1;
    API_STD_TEST1 (defaults, flag, MARPA_ERR_NONE,
        marpa_o_high_rank_only_set, o, flag);
    API_STD_TEST0 (defaults, flag, MARPA_ERR_NONE,
        marpa_o_high_rank_only, o);

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE,
        marpa_o_ambiguity_metric, o);
    API_STD_TEST0 (defaults, 0, MARPA_ERR_NONE, marpa_o_is_null, o);

    API_STD_TEST1 (defaults, -2, MARPA_ERR_ORDER_FROZEN,
        marpa_o_high_rank_only_set, o, flag);
    API_STD_TEST0 (defaults, flag, MARPA_ERR_NONE,
        marpa_o_high_rank_only, o);


    /* Needed for ASan test */
    marpa_o_unref(o);
    marpa_b_unref(b);
    marpa_r_unref(r);
    marpa_g_unref(g);

    return 0;
}
