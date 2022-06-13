/*
 * Copyright 2018 Jeffrey Kegler
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

/*
 * DO NOT EDIT DIRECTLY
 * This file is written by the Marpa build process
 * It is not intended to be modified directly
 */


#line 1 "./marpa_codes.c.p10"
#include "config.h"

#include "marpa.h"
#include "marpa_codes.h"
#include "marpa_ami.h"


#line 1 "./marpa.c-err"
const struct marpa_error_description_s marpa_error_description[] = {
  { 0, "MARPA_ERR_NONE", "No error" },
  { 1, "MARPA_ERR_AHFA_IX_NEGATIVE", "MARPA_ERR_AHFA_IX_NEGATIVE" },
  { 2, "MARPA_ERR_AHFA_IX_OOB", "MARPA_ERR_AHFA_IX_OOB" },
  { 3, "MARPA_ERR_ANDID_NEGATIVE", "MARPA_ERR_ANDID_NEGATIVE" },
  { 4, "MARPA_ERR_ANDID_NOT_IN_OR", "MARPA_ERR_ANDID_NOT_IN_OR" },
  { 5, "MARPA_ERR_ANDIX_NEGATIVE", "MARPA_ERR_ANDIX_NEGATIVE" },
  { 6, "MARPA_ERR_BAD_SEPARATOR", "Separator has invalid symbol ID" },
  { 7, "MARPA_ERR_BOCAGE_ITERATION_EXHAUSTED", "MARPA_ERR_BOCAGE_ITERATION_EXHAUSTED" },
  { 8, "MARPA_ERR_COUNTED_NULLABLE", "Nullable symbol on RHS of a sequence rule" },
  { 9, "MARPA_ERR_DEVELOPMENT", "Development error, see string" },
  { 10, "MARPA_ERR_DUPLICATE_AND_NODE", "MARPA_ERR_DUPLICATE_AND_NODE" },
  { 11, "MARPA_ERR_DUPLICATE_RULE", "Duplicate rule" },
  { 12, "MARPA_ERR_DUPLICATE_TOKEN", "Duplicate token" },
  { 13, "MARPA_ERR_YIM_COUNT", "Maximum number of Earley items exceeded" },
  { 14, "MARPA_ERR_YIM_ID_INVALID", "MARPA_ERR_YIM_ID_INVALID" },
  { 15, "MARPA_ERR_EVENT_IX_NEGATIVE", "Negative event index" },
  { 16, "MARPA_ERR_EVENT_IX_OOB", "No event at that index" },
  { 17, "MARPA_ERR_GRAMMAR_HAS_CYCLE", "Grammar has cycle" },
  { 18, "MARPA_ERR_INACCESSIBLE_TOKEN", "Token symbol is inaccessible" },
  { 19, "MARPA_ERR_INTERNAL", "MARPA_ERR_INTERNAL" },
  { 20, "MARPA_ERR_INVALID_AHFA_ID", "MARPA_ERR_INVALID_AHFA_ID" },
  { 21, "MARPA_ERR_INVALID_AIMID", "MARPA_ERR_INVALID_AIMID" },
  { 22, "MARPA_ERR_INVALID_BOOLEAN", "Argument is not boolean" },
  { 23, "MARPA_ERR_INVALID_IRLID", "MARPA_ERR_INVALID_IRLID" },
  { 24, "MARPA_ERR_INVALID_NSYID", "MARPA_ERR_INVALID_NSYID" },
  { 25, "MARPA_ERR_INVALID_LOCATION", "Location is not valid" },
  { 26, "MARPA_ERR_INVALID_RULE_ID", "Rule ID is malformed" },
  { 27, "MARPA_ERR_INVALID_START_SYMBOL", "Specified start symbol is not valid" },
  { 28, "MARPA_ERR_INVALID_SYMBOL_ID", "Symbol ID is malformed" },
  { 29, "MARPA_ERR_I_AM_NOT_OK", "Marpa is in a not OK state" },
  { 30, "MARPA_ERR_MAJOR_VERSION_MISMATCH", "Libmarpa major version number is a mismatch" },
  { 31, "MARPA_ERR_MICRO_VERSION_MISMATCH", "Libmarpa micro version number is a mismatch" },
  { 32, "MARPA_ERR_MINOR_VERSION_MISMATCH", "Libmarpa minor version number is a mismatch" },
  { 33, "MARPA_ERR_NOOKID_NEGATIVE", "MARPA_ERR_NOOKID_NEGATIVE" },
  { 34, "MARPA_ERR_NOT_PRECOMPUTED", "This grammar is not precomputed" },
  { 35, "MARPA_ERR_NOT_TRACING_COMPLETION_LINKS", "MARPA_ERR_NOT_TRACING_COMPLETION_LINKS" },
  { 36, "MARPA_ERR_NOT_TRACING_LEO_LINKS", "MARPA_ERR_NOT_TRACING_LEO_LINKS" },
  { 37, "MARPA_ERR_NOT_TRACING_TOKEN_LINKS", "MARPA_ERR_NOT_TRACING_TOKEN_LINKS" },
  { 38, "MARPA_ERR_NO_AND_NODES", "MARPA_ERR_NO_AND_NODES" },
  { 39, "MARPA_ERR_NO_EARLEY_SET_AT_LOCATION", "Earley set ID is after latest Earley set" },
  { 40, "MARPA_ERR_NO_OR_NODES", "MARPA_ERR_NO_OR_NODES" },
  { 41, "MARPA_ERR_NO_PARSE", "No parse" },
  { 42, "MARPA_ERR_NO_RULES", "This grammar does not have any rules" },
  { 43, "MARPA_ERR_NO_START_SYMBOL", "This grammar has no start symbol" },
  { 44, "MARPA_ERR_NO_TOKEN_EXPECTED_HERE", "No token is expected at this earleme location" },
  { 45, "MARPA_ERR_NO_TRACE_YIM", "MARPA_ERR_NO_TRACE_YIM" },
  { 46, "MARPA_ERR_NO_TRACE_YS", "MARPA_ERR_NO_TRACE_YS" },
  { 47, "MARPA_ERR_NO_TRACE_PIM", "MARPA_ERR_NO_TRACE_PIM" },
  { 48, "MARPA_ERR_NO_TRACE_SRCL", "MARPA_ERR_NO_TRACE_SRCL" },
  { 49, "MARPA_ERR_NULLING_TERMINAL", "A symbol is both terminal and nulling" },
  { 50, "MARPA_ERR_ORDER_FROZEN", "The ordering is frozen" },
  { 51, "MARPA_ERR_ORID_NEGATIVE", "MARPA_ERR_ORID_NEGATIVE" },
  { 52, "MARPA_ERR_OR_ALREADY_ORDERED", "MARPA_ERR_OR_ALREADY_ORDERED" },
  { 53, "MARPA_ERR_PARSE_EXHAUSTED", "The parse is exhausted" },
  { 54, "MARPA_ERR_PARSE_TOO_LONG", "This input would make the parse too long" },
  { 55, "MARPA_ERR_PIM_IS_NOT_LIM", "MARPA_ERR_PIM_IS_NOT_LIM" },
  { 56, "MARPA_ERR_POINTER_ARG_NULL", "An argument is null when it should not be" },
  { 57, "MARPA_ERR_PRECOMPUTED", "This grammar is precomputed" },
  { 58, "MARPA_ERR_PROGRESS_REPORT_EXHAUSTED", "The progress report is exhausted" },
  { 59, "MARPA_ERR_PROGRESS_REPORT_NOT_STARTED", "No progress report has been started" },
  { 60, "MARPA_ERR_RECCE_NOT_ACCEPTING_INPUT", "The recognizer is not accepting input" },
  { 61, "MARPA_ERR_RECCE_NOT_STARTED", "The recognizer has not been started" },
  { 62, "MARPA_ERR_RECCE_STARTED", "The recognizer has been started" },
  { 63, "MARPA_ERR_RHS_IX_NEGATIVE", "RHS index cannot be negative" },
  { 64, "MARPA_ERR_RHS_IX_OOB", "RHS index must be less than rule length" },
  { 65, "MARPA_ERR_RHS_TOO_LONG", "The RHS is too long" },
  { 66, "MARPA_ERR_SEQUENCE_LHS_NOT_UNIQUE", "LHS of sequence rule would not be unique" },
  { 67, "MARPA_ERR_SOURCE_TYPE_IS_AMBIGUOUS", "MARPA_ERR_SOURCE_TYPE_IS_AMBIGUOUS" },
  { 68, "MARPA_ERR_SOURCE_TYPE_IS_COMPLETION", "MARPA_ERR_SOURCE_TYPE_IS_COMPLETION" },
  { 69, "MARPA_ERR_SOURCE_TYPE_IS_LEO", "MARPA_ERR_SOURCE_TYPE_IS_LEO" },
  { 70, "MARPA_ERR_SOURCE_TYPE_IS_NONE", "MARPA_ERR_SOURCE_TYPE_IS_NONE" },
  { 71, "MARPA_ERR_SOURCE_TYPE_IS_TOKEN", "MARPA_ERR_SOURCE_TYPE_IS_TOKEN" },
  { 72, "MARPA_ERR_SOURCE_TYPE_IS_UNKNOWN", "MARPA_ERR_SOURCE_TYPE_IS_UNKNOWN" },
  { 73, "MARPA_ERR_START_NOT_LHS", "Start symbol not on LHS of any rule" },
  { 74, "MARPA_ERR_SYMBOL_VALUED_CONFLICT", "Symbol is treated both as valued and unvalued" },
  { 75, "MARPA_ERR_TERMINAL_IS_LOCKED", "The terminal status of the symbol is locked" },
  { 76, "MARPA_ERR_TOKEN_IS_NOT_TERMINAL", "Token symbol must be a terminal" },
  { 77, "MARPA_ERR_TOKEN_LENGTH_LE_ZERO", "Token length must greater than zero" },
  { 78, "MARPA_ERR_TOKEN_TOO_LONG", "Token is too long" },
  { 79, "MARPA_ERR_TREE_EXHAUSTED", "Tree iterator is exhausted" },
  { 80, "MARPA_ERR_TREE_PAUSED", "Tree iterator is paused" },
  { 81, "MARPA_ERR_UNEXPECTED_TOKEN_ID", "Unexpected token" },
  { 82, "MARPA_ERR_UNPRODUCTIVE_START", "Unproductive start symbol" },
  { 83, "MARPA_ERR_VALUATOR_INACTIVE", "Valuator inactive" },
  { 84, "MARPA_ERR_VALUED_IS_LOCKED", "The valued status of the symbol is locked" },
  { 85, "MARPA_ERR_RANK_TOO_LOW", "Rule or symbol rank too low" },
  { 86, "MARPA_ERR_RANK_TOO_HIGH", "Rule or symbol rank too high" },
  { 87, "MARPA_ERR_SYMBOL_IS_NULLING", "Symbol is nulling" },
  { 88, "MARPA_ERR_SYMBOL_IS_UNUSED", "Symbol is not used" },
  { 89, "MARPA_ERR_NO_SUCH_RULE_ID", "No rule with this ID exists" },
  { 90, "MARPA_ERR_NO_SUCH_SYMBOL_ID", "No symbol with this ID exists" },
  { 91, "MARPA_ERR_BEFORE_FIRST_TREE", "Tree iterator is before first tree" },
  { 92, "MARPA_ERR_SYMBOL_IS_NOT_COMPLETION_EVENT", "Symbol is not set up for completion events" },
  { 93, "MARPA_ERR_SYMBOL_IS_NOT_NULLED_EVENT", "Symbol is not set up for nulled events" },
  { 94, "MARPA_ERR_SYMBOL_IS_NOT_PREDICTION_EVENT", "Symbol is not set up for prediction events" },
  { 95, "MARPA_ERR_RECCE_IS_INCONSISTENT", "MARPA_ERR_RECCE_IS_INCONSISTENT" },
  { 96, "MARPA_ERR_INVALID_ASSERTION_ID", "Assertion ID is malformed" },
  { 97, "MARPA_ERR_NO_SUCH_ASSERTION_ID", "No assertion with this ID exists" },
  { 98, "MARPA_ERR_HEADERS_DO_NOT_MATCH", "Internal error: Libmarpa was built incorrectly" },
  { 99, "MARPA_ERR_NOT_A_SEQUENCE", "Rule is not a sequence" },
};


#line 1 "./marpa.c-event"
const struct marpa_event_description_s marpa_event_description[] = {
  { 0, "MARPA_EVENT_NONE", "No event" },
  { 1, "MARPA_EVENT_COUNTED_NULLABLE", "This symbol is a counted nullable" },
  { 2, "MARPA_EVENT_EARLEY_ITEM_THRESHOLD", "Too many Earley items" },
  { 3, "MARPA_EVENT_EXHAUSTED", "Recognizer is exhausted" },
  { 4, "MARPA_EVENT_LOOP_RULES", "Grammar contains a infinite loop" },
  { 5, "MARPA_EVENT_NULLING_TERMINAL", "This symbol is a nulling terminal" },
  { 6, "MARPA_EVENT_SYMBOL_COMPLETED", "Completed symbol" },
  { 7, "MARPA_EVENT_SYMBOL_EXPECTED", "Expecting symbol" },
  { 8, "MARPA_EVENT_SYMBOL_NULLED", "Symbol was nulled" },
  { 9, "MARPA_EVENT_SYMBOL_PREDICTED", "Symbol was predicted" },
};


#line 1 "./marpa.c-step"
const struct marpa_step_type_description_s marpa_step_type_description[] = {
  { 0, "MARPA_STEP_INTERNAL1" },
  { 1, "MARPA_STEP_RULE" },
  { 2, "MARPA_STEP_TOKEN" },
  { 3, "MARPA_STEP_NULLING_SYMBOL" },
  { 4, "MARPA_STEP_TRACE" },
  { 5, "MARPA_STEP_INACTIVE" },
  { 6, "MARPA_STEP_INTERNAL2" },
  { 7, "MARPA_STEP_INITIAL" },
};

