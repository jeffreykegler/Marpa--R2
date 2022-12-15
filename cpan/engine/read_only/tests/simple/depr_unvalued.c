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

/* Tests of Libmarpa methods with unvalued tokens in use.
   Note that use of unvalued tokens is DEPRECATED.
   These tests use a trivial grammar */

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
Marpa_Rule_ID R_C2_3;           /* Highest rule ID */

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
    int current_earleme;
    int furthest_earleme;
    int reactivate;
    int ix;
    int value;
    Marpa_Symbol_ID S_predicted, S_completed;

    /* For the test of marpa_r_earley_set_values() */
    const int orig_int_value = 1729;
    int int_value = orig_int_value;

    Marpa_Config marpa_configuration;
    Marpa_Grammar g;
    Marpa_Recognizer r;
    Marpa_Bocage b;
    Marpa_Order o;
    Marpa_Tree t;
    Marpa_Value v;

    Marpa_Rank negative_rank, positive_rank;
    int flag;

    int whatever = 42;

    char *value2_base = NULL;
    void *value2 = value2_base;

    API_test_data defaults;
    API_test_data this_test;

    plan (335);

    marpa_c_init (&marpa_configuration);
    g = marpa_g_trivial_new (&marpa_configuration);
    defaults_reset (&defaults, g);
    this_test = defaults;

    /* Grammar Methods per sections of api.texi: Symbols, Rules, Sequences, Ranks, Events ... */

    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_symbol_is_start, g, S_invalid);

    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_start, g, S_no_such);

    /* Returns 0 if sym_id is not the start symbol, either because the start symbol
       is different from sym_id, or because the start symbol has not been set yet. */
    API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE,
        marpa_g_symbol_is_start, g, S_top);

    API_STD_TEST0 (defaults, -1, MARPA_ERR_NO_START_SYMBOL,
        marpa_g_start_symbol, g);

    if (marpa_g_start_symbol_set (g, S_top) < 0) {
        fail ("marpa_g_start_symbol_set", g);
    }

    /* these must succeed after the start symbol is set */
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE,
        marpa_g_symbol_is_start, g, S_top);

    API_STD_TEST0 (defaults, S_top, MARPA_ERR_NONE, marpa_g_start_symbol,
        g);

    API_STD_TEST0 (this_test, S_C2, MARPA_ERR_NONE,
        marpa_g_highest_symbol_id, g);

    /* Symbols */

    /* Symbol classifier methods */
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_symbol_is_accessible, g, whatever);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_symbol_is_nullable, g, whatever);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_symbol_is_nulling, g, whatever);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_symbol_is_productive, g, whatever);

    API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE, marpa_g_symbol_is_terminal,
        g, S_top);

    /* Rules */

    /* Rule classifier methods */
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_rule_is_nullable, g, whatever);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_rule_is_nulling, g, whatever);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_rule_is_loop, g, whatever);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_rule_is_accessible, g, whatever);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_PRECOMPUTED,
        marpa_g_rule_is_productive, g, whatever);

    /* marpa_g_symbol_is_terminal_set() on invalid and non-existing symbol IDs
       on a non-precomputed grammar */
    API_STD_TEST2 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_symbol_is_terminal_set, g, S_invalid, 1);
    API_STD_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_terminal_set, g, S_no_such, 1);

    /* Rules */
    this_test.msg = (char *) "before precomputation";
    API_STD_TEST0 (this_test, R_C2_3, MARPA_ERR_NONE,
        marpa_g_highest_rule_id, g);
    API_STD_TEST1 (this_test, 1, MARPA_ERR_NONE, marpa_g_rule_length, g,
        R_top_1);
    API_STD_TEST1 (this_test, 0, MARPA_ERR_NONE, marpa_g_rule_length, g,
        R_C2_3);
    API_STD_TEST1 (this_test, S_top, MARPA_ERR_NONE, marpa_g_rule_lhs, g,
        R_top_1);
    API_STD_TEST2 (this_test, S_A1, MARPA_ERR_NONE, marpa_g_rule_rhs, g,
        R_top_1, 0);
    API_STD_TEST2 (this_test, S_A2, MARPA_ERR_NONE, marpa_g_rule_rhs, g,
        R_top_2, 0);

    /* marpa_g_symbol_is_terminal_set() on a nulling symbol */
    /* can't change terminal status after it's been set */
    API_STD_TEST2 (defaults, 1, MARPA_ERR_NONE,
        marpa_g_symbol_is_terminal_set, g, S_C1, 1);
    API_STD_TEST2 (defaults, -2, MARPA_ERR_TERMINAL_IS_LOCKED,
        marpa_g_symbol_is_terminal_set, g, S_C1, 0);

    API_STD_TEST0 (defaults, -2, MARPA_ERR_NULLING_TERMINAL,
        marpa_g_precompute, g);

    /* terminals are locked after setting, so we recreate the grammar */
    marpa_g_unref (g);
    g = marpa_g_trivial_new (&marpa_configuration);
    defaults_reset (&defaults, g);
    this_test = defaults;

    API_STD_TEST0 (defaults, -2, MARPA_ERR_NO_START_SYMBOL,
        marpa_g_precompute, g);

    marpa_g_trivial_precompute (g, S_top);
    ok (1, "precomputation succeeded");

    /* Symbols -- status accessors must succeed on precomputed grammar */
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE,
        marpa_g_symbol_is_accessible, g, S_C2);
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE, marpa_g_symbol_is_nullable,
        g, S_A1);
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE, marpa_g_symbol_is_nulling,
        g, S_A1);
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE,
        marpa_g_symbol_is_productive, g, S_top);

    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE,
        marpa_g_symbol_is_start, g, S_top);

    API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE, marpa_g_symbol_is_terminal,
        g, S_top);

    /* terminal and start symbols can't be set on precomputed grammar */
    API_STD_TEST2 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_symbol_is_terminal_set, g, S_top, 0);

    API_STD_TEST1 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_start_symbol_set, g, S_top);

    /* Rules */
    API_STD_TEST0 (this_test, R_C2_3, MARPA_ERR_NONE,
        marpa_g_highest_rule_id, g);

    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE, marpa_g_rule_is_accessible,
        g, R_top_1);
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE, marpa_g_rule_is_nullable,
        g, R_top_2);
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE, marpa_g_rule_is_nulling, g,
        R_top_2);
    API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE, marpa_g_rule_is_loop, g,
        R_C2_3);
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE, marpa_g_rule_is_productive,
        g, R_C2_3);
    API_STD_TEST1 (defaults, 1, MARPA_ERR_NONE, marpa_g_rule_length, g,
        R_top_1);
    API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE, marpa_g_rule_length, g,
        R_C2_3);
    API_STD_TEST1 (defaults, S_top, MARPA_ERR_NONE, marpa_g_rule_lhs, g,
        R_top_1);

    {
        API_STD_TEST2 (defaults, S_A1, MARPA_ERR_NONE, marpa_g_rule_rhs, g,
            R_top_1, 0);
        API_STD_TEST2 (defaults, S_A2, MARPA_ERR_NONE, marpa_g_rule_rhs, g,
            R_top_2, 0);

        API_STD_TEST2 (defaults, -2, MARPA_ERR_RHS_IX_OOB,
            marpa_g_rule_rhs, g, R_top_2, 25);

        API_STD_TEST2 (defaults, -2, MARPA_ERR_RHS_IX_NEGATIVE,
            marpa_g_rule_rhs, g, R_top_2, -1);
    }

    /* invalid/no such rule id error handling */
    /* Rule accessor methods */
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_is_accessible, g, R_invalid);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_is_loop, g, R_invalid);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_is_productive, g, R_invalid);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_is_nullable, g, R_invalid);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_is_nulling, g, R_invalid);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_length, g, R_invalid);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_lhs, g, R_invalid);

    /* Rule accessor methods */
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_is_accessible, g, R_no_such);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_is_loop, g, R_no_such);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_is_productive, g, R_no_such);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_is_nullable, g, R_no_such);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_is_nulling, g, R_no_such);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_length, g, R_no_such);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_lhs, g, R_no_such);

    /* Sequences */
    /* try to add a nulling sequence, and make sure that it fails with an appropriate
       error code -- http://irclog.perlgeek.de/marpa/2015-02-13#i_10111831  */

    /* recreate the grammar */
    marpa_g_unref (g);
    g = marpa_g_trivial_new (&marpa_configuration);
    defaults_reset (&defaults, g);
    this_test = defaults;

    /* try to add a nulling sequence */
    API_STD_TEST5 (defaults, -2, MARPA_ERR_SEQUENCE_LHS_NOT_UNIQUE,
        marpa_g_sequence_new, g, S_top, S_B1, S_B2, 0,
        MARPA_PROPER_SEPARATION);

    /* test error codes of other sequence methods */
    /* non-sequence rule id */
    API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE,
        marpa_g_rule_is_proper_separation, g, R_top_1);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NOT_A_SEQUENCE,
        marpa_g_sequence_min, g, R_top_1);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NOT_A_SEQUENCE,
        marpa_g_sequence_separator, g, R_top_1);
    API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE, marpa_g_symbol_is_counted,
        g, S_top);

    /* invalid/no such rule id error handling */

    /* Sequence mutator methods */
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_sequence_separator, g, R_invalid);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_sequence_min, g, R_invalid);

    /* Sequence mutator methods */
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_sequence_separator, g, R_no_such);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_sequence_min, g, R_no_such);

    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_is_proper_separation, g, R_invalid);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_is_proper_separation, g, R_no_such);

    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_symbol_is_counted, g, S_invalid);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_counted, g, S_no_such);

    /* Ranks */
    negative_rank = -2;
    API_HIDDEN_TEST2 (defaults, negative_rank, MARPA_ERR_NONE,
        marpa_g_rule_rank_set, g, R_top_1, negative_rank);
    API_HIDDEN_TEST1 (defaults, negative_rank, MARPA_ERR_NONE,
        marpa_g_rule_rank, g, R_top_1);

    positive_rank = 2;
    API_HIDDEN_TEST2 (defaults, positive_rank, MARPA_ERR_NONE,
        marpa_g_rule_rank_set, g, R_top_2, positive_rank);
    API_HIDDEN_TEST1 (defaults, positive_rank, MARPA_ERR_NONE,
        marpa_g_rule_rank, g, R_top_2);

    flag = 1;
    API_HIDDEN_TEST2 (defaults, flag, MARPA_ERR_NONE,
        marpa_g_rule_null_high_set, g, R_top_2, flag);
    API_HIDDEN_TEST1 (defaults, flag, MARPA_ERR_NONE,
        marpa_g_rule_null_high, g, R_top_2);

    /* invalid/no such rule id error handling */

    /* Rank setter methods */
    API_HIDDEN_TEST2 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_rank_set, g, R_invalid, negative_rank);

    API_HIDDEN_TEST2 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_null_high_set, g, R_invalid, whatever);

    API_HIDDEN_TEST2 (defaults, -2, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_rank_set, g, R_no_such, negative_rank);

    API_HIDDEN_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_null_high_set, g, R_no_such, whatever);

    /* Rank getter methods */
    API_HIDDEN_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_rank, g, R_invalid);

    API_HIDDEN_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_null_high, g, R_invalid);

    API_HIDDEN_TEST1 (defaults, -2, MARPA_ERR_INVALID_RULE_ID,
        marpa_g_rule_null_high, g, R_invalid);
    API_HIDDEN_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_RULE_ID,
        marpa_g_rule_null_high, g, R_no_such);

    marpa_g_trivial_precompute (g, S_top);
    ok (1, "precomputation succeeded");

    /* Ranks methods on precomputed grammar */
    /* setters fail */
    API_HIDDEN_TEST2 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_rule_rank_set, g, R_top_1, negative_rank);
    API_HIDDEN_TEST2 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_rule_rank_set, g, R_top_2, negative_rank);

    API_HIDDEN_TEST2 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_rule_null_high_set, g, R_top_2, flag);

    /* getters succeed */
    API_HIDDEN_TEST1 (defaults, negative_rank, MARPA_ERR_NONE,
        marpa_g_rule_rank, g, R_top_1);
    API_HIDDEN_TEST1 (defaults, positive_rank, MARPA_ERR_NONE,
        marpa_g_rule_rank, g, R_top_2);

    API_HIDDEN_TEST1 (defaults, flag, MARPA_ERR_NONE,
        marpa_g_rule_null_high, g, R_top_2);

    /* recreate the grammar to test event methods except nulled */
    marpa_g_unref (g);
    g = marpa_g_trivial_new (&marpa_configuration);
    defaults_reset (&defaults, g);
    this_test = defaults;

    /* Events */
    /* test that attempts to create events, other than nulled events,
       results in a reasonable error -- http://irclog.perlgeek.de/marpa/2015-02-13#i_10111838 */

    /* completion */
    S_completed = S_B1;

    value = 0;
    API_STD_TEST2 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_completion_event_set, g, S_completed, value);
    API_STD_TEST1 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_completion_event, g, S_completed);

    value = 1;
    API_STD_TEST2 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_completion_event_set, g, S_completed, value);
    API_STD_TEST1 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_completion_event, g, S_completed);

    reactivate = 0;
    API_STD_TEST2 (defaults, reactivate, MARPA_ERR_NONE,
        marpa_g_completion_symbol_activate, g, S_completed, reactivate);

    reactivate = 1;
    API_STD_TEST2 (defaults, reactivate, MARPA_ERR_NONE,
        marpa_g_completion_symbol_activate, g, S_completed, reactivate);

    /* prediction */
    S_predicted = S_A1;

    value = 0;
    API_STD_TEST2 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_prediction_event_set, g, S_predicted, value);
    API_STD_TEST1 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_prediction_event, g, S_predicted);

    value = 1;
    API_STD_TEST2 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_prediction_event_set, g, S_predicted, value);
    API_STD_TEST1 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_prediction_event, g, S_predicted);

    reactivate = 0;
    API_STD_TEST2 (defaults, reactivate, MARPA_ERR_NONE,
        marpa_g_prediction_symbol_activate, g, S_predicted, reactivate);

    reactivate = 1;
    API_STD_TEST2 (defaults, reactivate, MARPA_ERR_NONE,
        marpa_g_completion_symbol_activate, g, S_predicted, reactivate);

    /* completion on predicted symbol */
    value = 1;
    API_STD_TEST2 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_completion_event_set, g, S_predicted, value);
    API_STD_TEST1 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_completion_event, g, S_predicted);

    /* prediction on completed symbol */
    value = 1;
    API_STD_TEST2 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_prediction_event_set, g, S_completed, value);
    API_STD_TEST1 (defaults, value, MARPA_ERR_NONE,
        marpa_g_symbol_is_prediction_event, g, S_completed);

    /* invalid/no such symbol IDs */

    /* Event setter methods */
    API_STD_TEST2 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_symbol_is_completion_event_set, g, S_invalid, whatever);

    API_STD_TEST2 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_completion_symbol_activate, g, S_invalid, whatever);

    API_STD_TEST2 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_symbol_is_prediction_event_set, g, S_invalid, value);

    API_STD_TEST2 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_prediction_symbol_activate, g, S_invalid, whatever);

    /* Event setter methods */
    API_STD_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_completion_event_set, g, S_no_such, whatever);

    API_STD_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_completion_symbol_activate, g, S_no_such, whatever);

    API_STD_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_prediction_event_set, g, S_no_such, whatever);

    API_STD_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_prediction_symbol_activate, g, S_no_such, whatever);

    /* Event getter methods */
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_symbol_is_completion_event, g, S_invalid);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
        marpa_g_symbol_is_prediction_event, g, S_invalid);

    /* Event getter methods */
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_completion_event, g, S_no_such);
    API_STD_TEST1 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_prediction_event, g, S_no_such);

    /* precomputation */
    marpa_g_trivial_precompute (g, S_top);
    ok (1, "precomputation succeeded");

    /* event methods after precomputation */
    /* Event setter methods */
    API_STD_TEST2 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_symbol_is_completion_event_set, g, whatever, whatever);

    API_STD_TEST2 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_completion_symbol_activate, g, S_no_such, whatever);

    API_STD_TEST2 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_symbol_is_prediction_event_set, g, S_predicted, whatever);

    API_STD_TEST2 (defaults, -2, MARPA_ERR_PRECOMPUTED,
        marpa_g_prediction_symbol_activate, g, S_no_such, whatever);

    API_STD_TEST1 (defaults, value, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_prediction_event, g, S_predicted);
    API_STD_TEST1 (defaults, value, MARPA_ERR_NO_SUCH_SYMBOL_ID,
        marpa_g_symbol_is_completion_event, g, S_completed);

    /* Recognizer Methods */
    r = marpa_r_new (g);
    if (!r)
        fail ("marpa_r_new", g);

    /* the recce hasn't been started yet */

    API_STD_TEST0 (defaults, -1, MARPA_ERR_RECCE_NOT_STARTED,
        marpa_r_current_earleme, r);
    API_STD_TEST0 (defaults, -2, MARPA_ERR_RECCE_NOT_STARTED,
        marpa_r_progress_report_reset, r);
    API_STD_TEST1 (defaults, -2, MARPA_ERR_RECCE_NOT_STARTED,
        marpa_r_progress_report_start, r, whatever);
    API_STD_TEST0 (defaults, -2, MARPA_ERR_RECCE_NOT_STARTED,
        marpa_r_progress_report_finish, r);

    {
        int set_id;
        Marpa_Earley_Set_ID origin;
        API_STD_TEST2 (defaults, -2, MARPA_ERR_RECCE_NOT_STARTED,
            marpa_r_progress_item, r, &set_id, &origin);
    }

    /* start the recce */
    rc = marpa_r_start_input (r);
    if (!rc)
        fail ("marpa_r_start_input", g);

    diag ("The below recce tests are at earleme 0");

    {                           /* event loop -- just count events so far -- there must be no event except exhausted */
        Marpa_Event event;
        int exhausted_event_triggered = 0;
        int spurious_events = 0;
        int prediction_events = 0;
        int completion_events = 0;
        int event_ix;
        const int event_count = marpa_g_event_count (g);

        is_int (1, event_count, "event count at earleme 0 is %ld",
            (long) event_count);

        for (event_ix = 0; event_ix < event_count; event_ix++) {
            int event_type = marpa_g_event (g, &event, event_ix);
            if (event_type == MARPA_EVENT_SYMBOL_COMPLETED)
                completion_events++;
            else if (event_type == MARPA_EVENT_SYMBOL_PREDICTED)
                prediction_events++;
            else if (event_type == MARPA_EVENT_EXHAUSTED)
                exhausted_event_triggered++;
            else {
                printf ("spurious event type is %ld\n", (long) event_type);
                spurious_events++;
            }
        }

        is_int (0, spurious_events, "spurious events triggered: %ld",
            (long) spurious_events);
        is_int (0, completion_events,
            "completion events triggered: %ld", (long) completion_events);
        is_int (0, prediction_events,
            "completion events triggered: %ld", (long) prediction_events);
        ok (exhausted_event_triggered, "exhausted event triggered");

    }                           /* event loop */

    /* recognizer reading methods */
    this_test.msg = (char *)
        "not accepting input is checked before invalid symbol";
    API_CODE_TEST3 (this_test, MARPA_ERR_RECCE_NOT_ACCEPTING_INPUT,
        marpa_r_alternative, r, S_invalid, 0, 0);

    this_test.msg = (char *)
        "not accepting input is checked before no such symbol";
    API_CODE_TEST3 (this_test, MARPA_ERR_RECCE_NOT_ACCEPTING_INPUT,
        marpa_r_alternative, r, S_no_such, 0, 0);

    this_test.msg = (char *) "not accepting input";
    API_CODE_TEST3 (this_test, MARPA_ERR_RECCE_NOT_ACCEPTING_INPUT,
        marpa_r_alternative, r, S_A2, 0, 0);

    this_test = defaults;

    API_STD_TEST0 (defaults, -2, MARPA_ERR_RECCE_NOT_ACCEPTING_INPUT,
        marpa_r_earleme_complete, r);

    this_test.msg = (char *) "at earleme 0";
    API_STD_TEST0 (this_test, 1, MARPA_ERR_NONE, marpa_r_is_exhausted, r);

    /* Location accessors */
    /* the below 2 always succeed */
    current_earleme = furthest_earleme = 0;
    API_STD_TEST0 (defaults, current_earleme, MARPA_ERR_NONE,
        marpa_r_current_earleme, r);

    API_STD_TEST0U (defaults, furthest_earleme, MARPA_ERR_NONE,
        marpa_r_furthest_earleme, r);

    API_STD_TEST0 (defaults, furthest_earleme, MARPA_ERR_NONE,
        marpa_r_latest_earley_set, r);

    API_STD_TEST1 (defaults, current_earleme, MARPA_ERR_NONE,
        marpa_r_earleme, r, current_earleme);

    API_STD_TEST1 (defaults, -1, MARPA_ERR_NONE,
        marpa_r_earley_set_value, r, current_earleme);

    {
        /* marpa_r_earley_set_value_*() methods */
        const int taxicab = 1729;

        struct marpa_r_earley_set_value_test
        {
            int earley_set;

            int rv_marpa_r_earleme;
            int rv_marpa_r_latest_earley_set_value_set;
            int rv_marpa_r_earley_set_value;
            int rv_marpa_r_latest_earley_set_values_set;

            int rv_marpa_r_earley_set_values;
            int int_p_value_rv_marpa_r_earley_set_values;
            void *void_p_value_rv_marpa_r_earley_set_values;
            Marpa_Error_Code errcode;
        };
        typedef struct marpa_r_earley_set_value_test
            Marpa_R_Earley_Set_Value_Test;

        Marpa_R_Earley_Set_Value_Test tests[4] = {
            {-1, -2, taxicab, -2, 1, -2, taxicab, NULL,
                MARPA_ERR_INVALID_LOCATION},
            {0, 0, taxicab, taxicab, 1, 1, 42, NULL,
                MARPA_ERR_INVALID_LOCATION},
            {1, -2, 42, -2, 1, -2, 42, NULL,
                MARPA_ERR_NO_EARLEY_SET_AT_LOCATION},
            {2, -2, 42, -2, 1, -2, 42, NULL,
                MARPA_ERR_NO_EARLEY_SET_AT_LOCATION},
        };
        /* We change these at runtime to silence a "not computable at load time" warning */
        tests[0].void_p_value_rv_marpa_r_earley_set_values =
            (void *) value2;
        tests[1].void_p_value_rv_marpa_r_earley_set_values =
            (void *) value2;
        tests[2].void_p_value_rv_marpa_r_earley_set_values =
            (void *) value2;
        tests[3].void_p_value_rv_marpa_r_earley_set_values =
            (void *) value2;

        for (ix = 0;
            ix <
            (int)(sizeof (tests) / sizeof (Marpa_R_Earley_Set_Value_Test));
            ix++) {
            const Marpa_R_Earley_Set_Value_Test test = tests[ix];
            diag ("marpa_r_earley_set_value_*() methods, earley_set: %d",
                test.earley_set);

            if (test.earley_set == -1 || test.earley_set == 1
                || test.earley_set == 2) {
                API_STD_TEST1 (defaults, test.rv_marpa_r_earleme,
                    test.errcode, marpa_r_earleme, r, test.earley_set);
            } else {
                API_STD_TEST1 (defaults, test.rv_marpa_r_earleme,
                    MARPA_ERR_NONE, marpa_r_earleme, r, test.earley_set);
            }

            API_STD_TEST1 (defaults,
                test.rv_marpa_r_latest_earley_set_value_set,
                MARPA_ERR_NONE, marpa_r_latest_earley_set_value_set, r,
                test.rv_marpa_r_latest_earley_set_value_set);

            if (test.earley_set == -1 || test.earley_set == 1
                || test.earley_set == 2) {
                API_STD_TEST1 (defaults, test.rv_marpa_r_earley_set_value,
                    test.errcode, marpa_r_earley_set_value, r,
                    test.earley_set);
            } else {
                API_STD_TEST1 (defaults, test.rv_marpa_r_earley_set_value,
                    MARPA_ERR_NONE, marpa_r_earley_set_value, r,
                    test.earley_set);
            }

            {
                API_STD_TEST2 (defaults,
                    test.rv_marpa_r_latest_earley_set_values_set,
                    MARPA_ERR_NONE,
                    marpa_r_latest_earley_set_values_set, r, 42, value2);
            }

            {
                /* There is no c89 portable way to test arbitrary pointers.
                 * With ifdef's we could cover 99.999% of cases, but for now
                 * we do not bother.
                 */
                void *orig_value3 = NULL;
                void *value3 = orig_value3;

                API_STD_TEST3 (defaults,
                    test.rv_marpa_r_earley_set_values,
                    test.errcode,
                    marpa_r_earley_set_values,
                    r, test.earley_set, (&int_value), &value3);
                is_int (test.int_p_value_rv_marpa_r_earley_set_values,
                    int_value, "marpa_r_earley_set_values() int* value");

            }

        }
    }                           /* Location Accessors */

    /* Other parse status methods */
    {
        int boolean = 0;
        API_STD_TEST2 (defaults, boolean, MARPA_ERR_NONE,
            marpa_r_prediction_symbol_activate, r, S_predicted, boolean);
        API_STD_TEST2 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
            marpa_r_prediction_symbol_activate, r, S_invalid, boolean);
        API_STD_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
            marpa_r_prediction_symbol_activate, r, S_no_such, boolean);

        reactivate = 1;
        API_STD_TEST2 (defaults, reactivate, MARPA_ERR_NONE,
            marpa_r_completion_symbol_activate, r, S_completed,
            reactivate);
        API_STD_TEST2 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
            marpa_r_completion_symbol_activate, r, S_invalid, reactivate);
        API_STD_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
            marpa_r_completion_symbol_activate, r, S_no_such, reactivate);

        {
            Marpa_Symbol_ID S_nulled = S_C1;
            boolean = 1;
            API_STD_TEST2 (defaults, boolean, MARPA_ERR_NONE,
                marpa_r_nulled_symbol_activate, r, S_nulled, boolean);
            API_STD_TEST2 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
                marpa_r_nulled_symbol_activate, r, S_invalid, boolean);
            API_STD_TEST2 (defaults, -1, MARPA_ERR_NO_SUCH_SYMBOL_ID,
                marpa_r_nulled_symbol_activate, r, S_no_such, boolean);
        }

        {
            int threshold = 1;
            API_STD_TEST1 (defaults, threshold, MARPA_ERR_NONE,
                marpa_r_earley_item_warning_threshold_set, r, threshold);

            API_STD_TEST0 (defaults, threshold, MARPA_ERR_NONE,
                marpa_r_earley_item_warning_threshold, r);
        }

        value = 1;
        API_STD_TEST2 (defaults, -2, MARPA_ERR_SYMBOL_IS_NULLING,
            marpa_r_expected_symbol_event_set, r, S_B1, value);

        {
            Marpa_Symbol_ID buffer[42];
            API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE,
                marpa_r_terminals_expected, r, buffer);
        }

        API_STD_TEST1 (defaults, 0, MARPA_ERR_NONE,
            marpa_r_terminal_is_expected, r, S_C1);
        API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_SYMBOL_ID,
            marpa_r_terminal_is_expected, r, S_invalid);
        API_STD_TEST1 (defaults, -2, MARPA_ERR_NO_SUCH_SYMBOL_ID,
            marpa_r_terminal_is_expected, r, S_no_such);

    }                           /* Other parse status methods */

    /* Progress reports */
    {
        API_STD_TEST0 (defaults, -2,
            MARPA_ERR_PROGRESS_REPORT_NOT_STARTED,
            marpa_r_progress_report_reset, r);

        API_STD_TEST0 (defaults, -2,
            MARPA_ERR_PROGRESS_REPORT_NOT_STARTED,
            marpa_r_progress_report_finish, r);

        {
            int set_id;
            Marpa_Earley_Set_ID origin;
            API_STD_TEST2 (defaults, -2,
                MARPA_ERR_PROGRESS_REPORT_NOT_STARTED,
                marpa_r_progress_item, r, &set_id, &origin);
        }


        /* start report at bad locations */
        {
            Marpa_Earley_Set_ID ys_id_negative = -1;
            API_STD_TEST1 (defaults, -2, MARPA_ERR_INVALID_LOCATION,
                marpa_r_progress_report_start, r, ys_id_negative);
        }

        {
            Marpa_Earley_Set_ID ys_id_not_existing = 1;
            API_STD_TEST1 (defaults, -2,
                MARPA_ERR_NO_EARLEY_SET_AT_LOCATION,
                marpa_r_progress_report_start, r, ys_id_not_existing);
        }

        /* start report at earleme 0 */
        {
            Marpa_Earley_Set_ID earleme_0 = 0;
            this_test.msg = (char *) "no items at earleme 0";
            API_STD_TEST1 (this_test, 0, MARPA_ERR_NONE,
                marpa_r_progress_report_start, r, earleme_0);
        }

        {
            int set_id;
            Marpa_Earley_Set_ID origin;
            API_STD_TEST2 (defaults, -1,
                MARPA_ERR_PROGRESS_REPORT_EXHAUSTED,
                marpa_r_progress_item, r, &set_id, &origin);
        }


        {
            int non_negative_value = 1;
            API_STD_TEST0 (this_test, non_negative_value, MARPA_ERR_NONE,
                marpa_r_progress_report_reset, r);

            this_test.msg = (char *) "at earleme 0";
            API_STD_TEST0 (this_test, non_negative_value, MARPA_ERR_NONE,
                marpa_r_progress_report_finish, r);
        }
    }

    /* Bocage */
    {
        Marpa_Earley_Set_ID ys_invalid = -2;
        API_PTR_TEST1 (defaults, MARPA_ERR_INVALID_LOCATION,
            marpa_b_new, r, ys_invalid);
    }

    {
        Marpa_Earley_Set_ID ys_non_existing = 1;
        API_PTR_TEST1 (defaults, MARPA_ERR_NO_PARSE,
            marpa_b_new, r, ys_non_existing);
    }

    {
        Marpa_Earley_Set_ID ys_at_current_earleme = -1;
        b = marpa_b_new (r, ys_at_current_earleme);
        if (!b)
            fail ("marpa_b_new", g);
        else
            ok (1,
                "marpa_b_new(): parse at current earleme of trivial parse");
    }

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

    flag = 1;
    API_STD_TEST1 (defaults, flag, MARPA_ERR_NONE,
        marpa_o_high_rank_only_set, o, flag);
    API_STD_TEST0 (defaults, flag, MARPA_ERR_NONE,
        marpa_o_high_rank_only, o);

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE,
        marpa_o_ambiguity_metric, o);
    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_o_is_null, o);

    API_STD_TEST1 (defaults, -2, MARPA_ERR_ORDER_FROZEN,
        marpa_o_high_rank_only_set, o, flag);
    API_STD_TEST0 (defaults, flag, MARPA_ERR_NONE,
        marpa_o_high_rank_only, o);

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
        is_int (MARPA_STEP_INACTIVE, step_type,
            "MARPA_STEP_INACTIVE step.");
        step_type = marpa_v_step (v);
        is_int (MARPA_STEP_INACTIVE, step_type,
            "MARPA_STEP_INACTIVE step on retry of marpa_v_step().");
    }

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_t_parse_count, t);
    API_STD_TEST0 (defaults, -2, MARPA_ERR_TREE_PAUSED, marpa_t_next, t);

    marpa_v_unref (v);

    API_STD_TEST0 (defaults, 1, MARPA_ERR_NONE, marpa_t_parse_count, t);
    API_STD_TEST0 (defaults, -1, MARPA_ERR_TREE_EXHAUSTED,
        marpa_t_next, t);

    /* Needed for ASan test */
    marpa_t_unref(t);
    marpa_o_unref(o);
    marpa_b_unref(b);
    marpa_r_unref(r);
    marpa_g_unref(g);

    return 0;
}
