/*
 * Copyright 2012 Jeffrey Kegler
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
/*
 * DO NOT EDIT DIRECTLY
 * This file is written by texi2proto.pl
 * It is not intended to be modified directly
 */


Marpa_Error_Code marpa_check_version (unsigned int required_major, unsigned int required_minor, unsigned int required_micro );
int marpa_c_init ( Marpa_Config* config);
Marpa_Error_Code marpa_c_error ( Marpa_Config* config, const char** p_error_string );
Marpa_Grammar marpa_g_new ( Marpa_Config* configuration );
Marpa_Grammar marpa_g_ref (Marpa_Grammar g);
void marpa_g_unref (Marpa_Grammar g);
Marpa_Symbol_ID marpa_g_start_symbol (Marpa_Grammar g);
Marpa_Symbol_ID marpa_g_start_symbol_set ( Marpa_Grammar g, Marpa_Symbol_ID sym_id);
int marpa_g_highest_symbol_id (Marpa_Grammar g);
int marpa_g_symbol_is_accessible (Marpa_Grammar g, Marpa_Symbol_ID sym_id);
int marpa_g_symbol_is_nullable ( Marpa_Grammar g, Marpa_Symbol_ID sym_id);
int marpa_g_symbol_is_nulling (Marpa_Grammar g, Marpa_Symbol_ID sym_id);
int marpa_g_symbol_is_productive (Marpa_Grammar g, Marpa_Symbol_ID sym_id);
int marpa_g_symbol_is_start ( Marpa_Grammar g, Marpa_Symbol_ID sym_id);
int marpa_g_symbol_is_terminal ( Marpa_Grammar g, Marpa_Symbol_ID sym_id);
int marpa_g_symbol_is_terminal_set ( Marpa_Grammar g, Marpa_Symbol_ID sym_id, int value);
int marpa_g_symbol_is_valued ( Marpa_Grammar g, Marpa_Symbol_ID symbol_id);
int marpa_g_symbol_is_valued_set ( Marpa_Grammar g, Marpa_Symbol_ID symbol_id, int value);
Marpa_Symbol_ID marpa_g_symbol_new (Marpa_Grammar g);
int marpa_g_highest_rule_id (Marpa_Grammar g);
int marpa_g_rule_is_accessible (Marpa_Grammar g, Marpa_Rule_ID rule_id);
int marpa_g_rule_is_nullable ( Marpa_Grammar g, Marpa_Rule_ID ruleid);
int marpa_g_rule_is_nulling (Marpa_Grammar g, Marpa_Rule_ID ruleid);
int marpa_g_rule_is_loop (Marpa_Grammar g, Marpa_Rule_ID rule_id);
int marpa_g_rule_is_productive (Marpa_Grammar g, Marpa_Rule_ID rule_id);
int marpa_g_rule_length ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
Marpa_Symbol_ID marpa_g_rule_lhs ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
Marpa_Rule_ID marpa_g_rule_new (Marpa_Grammar g, Marpa_Symbol_ID lhs_id, Marpa_Symbol_ID *rhs_ids, int length);
Marpa_Symbol_ID marpa_g_rule_rhs ( Marpa_Grammar g, Marpa_Rule_ID rule_id, int ix);
int marpa_g_rule_is_proper_separation ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
int marpa_g_sequence_min ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
Marpa_Rule_ID marpa_g_sequence_new (Marpa_Grammar g, Marpa_Symbol_ID lhs_id, Marpa_Symbol_ID rhs_id, Marpa_Symbol_ID separator_id, int min, int flags );
int marpa_g_sequence_separator ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
int marpa_g_symbol_is_counted (Marpa_Grammar g, Marpa_Symbol_ID sym_id);
Marpa_Rank marpa_g_rule_rank ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
Marpa_Rank marpa_g_rule_rank_set ( Marpa_Grammar g, Marpa_Rule_ID rule_id, Marpa_Rank rank);
int marpa_g_rule_null_high ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
int marpa_g_rule_null_high_set ( Marpa_Grammar g, Marpa_Rule_ID rule_id, int flag);
int marpa_g_precompute (Marpa_Grammar g);
int marpa_g_is_precomputed (Marpa_Grammar g);
int marpa_g_has_cycle (Marpa_Grammar g);
Marpa_Recognizer marpa_r_new ( Marpa_Grammar g );
Marpa_Recognizer marpa_r_ref (Marpa_Recognizer r);
void marpa_r_unref (Marpa_Recognizer r);
int marpa_r_start_input (Marpa_Recognizer r);
int marpa_r_alternative (Marpa_Recognizer r, Marpa_Symbol_ID token_id, int value, int length);
Marpa_Earleme marpa_r_earleme_complete (Marpa_Recognizer r);
Marpa_Earleme marpa_r_earleme ( Marpa_Recognizer r, Marpa_Earley_Set_ID set_id);
unsigned int marpa_r_current_earleme (Marpa_Recognizer r);
Marpa_Earley_Set_ID marpa_r_latest_earley_set (Marpa_Recognizer r);
unsigned int marpa_r_furthest_earleme (Marpa_Recognizer r);
int marpa_r_earley_item_warning_threshold (Marpa_Recognizer r);
int marpa_r_earley_item_warning_threshold_set (Marpa_Recognizer r, int threshold);
int marpa_r_expected_symbol_event_set ( Marpa_Recognizer r, Marpa_Symbol_ID symbol_id, int value);
int marpa_r_terminals_expected ( Marpa_Recognizer r, Marpa_Symbol_ID* buffer);
int marpa_r_is_exhausted (Marpa_Recognizer r);
int marpa_r_progress_report_start ( Marpa_Recognizer r, Marpa_Earley_Set_ID set_id);
int marpa_r_progress_report_finish ( Marpa_Recognizer r );
Marpa_Rule_ID marpa_r_progress_item ( Marpa_Recognizer r, int* position, Marpa_Earley_Set_ID* origin );
Marpa_Bocage marpa_b_new (Marpa_Recognizer r, Marpa_Earley_Set_ID earley_set_ID);
Marpa_Bocage marpa_b_ref (Marpa_Bocage b);
void marpa_b_unref (Marpa_Bocage b);
Marpa_Order marpa_o_new ( Marpa_Bocage b);
Marpa_Order marpa_o_ref ( Marpa_Order o);
void marpa_o_unref ( Marpa_Order o);
int marpa_o_high_rank_only_set ( Marpa_Order o, int flag);
int marpa_o_high_rank_only ( Marpa_Order o);
int marpa_o_rank ( Marpa_Order o );
Marpa_Tree marpa_t_new (Marpa_Order o);
Marpa_Tree marpa_t_ref (Marpa_Tree t);
void marpa_t_unref (Marpa_Tree t);
int marpa_t_next ( Marpa_Tree t);
int marpa_t_parse_count ( Marpa_Tree t);
Marpa_Value marpa_v_new ( Marpa_Tree t );
Marpa_Value marpa_v_ref (Marpa_Value v);
void marpa_v_unref ( Marpa_Value v);
int marpa_v_symbol_is_valued ( Marpa_Value v, Marpa_Symbol_ID sym_id );
int marpa_v_symbol_is_valued_set ( Marpa_Value v, Marpa_Symbol_ID sym_id, int value );
int marpa_v_rule_is_valued ( Marpa_Value v, Marpa_Rule_ID rule_id );
int marpa_v_rule_is_valued_set ( Marpa_Value v, Marpa_Rule_ID rule_id, int value );
Marpa_Step_Type marpa_v_step ( Marpa_Value v);
Marpa_Event_Type marpa_g_event (Marpa_Grammar g, Marpa_Event* event, int ix);
int marpa_g_event_count ( Marpa_Grammar g );
Marpa_Error_Code marpa_g_error ( Marpa_Grammar g, const char** p_error_string);
Marpa_Error_Code marpa_g_error_clear ( Marpa_Grammar g );
Marpa_Rank marpa_g_default_rank ( Marpa_Grammar g);
Marpa_Rank marpa_g_default_rank_set ( Marpa_Grammar g, Marpa_Rank rank);
Marpa_Rank marpa_g_symbol_rank ( Marpa_Grammar g, Marpa_Symbol_ID sym_id);
Marpa_Rank marpa_g_symbol_rank_set ( Marpa_Grammar g, Marpa_Symbol_ID sym_id, Marpa_Rank rank);
int _marpa_g_rule_first_child_set ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
int _marpa_g_isy_is_start ( Marpa_Grammar g, Marpa_ISY_ID isy_id);
int _marpa_g_isy_is_nulling ( Marpa_Grammar g, Marpa_ISY_ID isy_id);
int _marpa_g_isy_is_lhs ( Marpa_Grammar g, Marpa_ISY_ID isy_id);
Marpa_ISY_ID _marpa_g_xsy_nulling_isy ( Marpa_Grammar g, Marpa_Symbol_ID symid);
Marpa_ISY_ID _marpa_g_xsy_isy ( Marpa_Grammar g, Marpa_Symbol_ID symid);
Marpa_Symbol_ID _marpa_g_symbol_proper_alias ( Marpa_Grammar g, Marpa_Symbol_ID symid);
Marpa_Symbol_ID _marpa_g_symbol_null_alias ( Marpa_Grammar g, Marpa_Symbol_ID symid);
int _marpa_g_symbol_is_semantic ( Marpa_Grammar g, Marpa_Symbol_ID symid);
Marpa_Rule_ID _marpa_g_source_xsy ( Marpa_Grammar g, Marpa_ISY_ID isy_id);
Marpa_Rule_ID _marpa_g_isy_lhs_xrl ( Marpa_Grammar g, Marpa_ISY_ID isy_id);
int _marpa_g_isy_xrl_offset ( Marpa_Grammar g, Marpa_ISY_ID isy_id );
int _marpa_g_rule_is_keep_separation ( Marpa_Grammar g, Marpa_Rule_ID rule_id);
int _marpa_g_isy_count ( Marpa_Grammar g);
int _marpa_g_irl_count ( Marpa_Grammar g);
Marpa_Symbol_ID _marpa_g_irl_lhs ( Marpa_Grammar g, Marpa_IRL_ID irl_id);
int _marpa_g_irl_length ( Marpa_Grammar g, Marpa_IRL_ID irl_id);
Marpa_Symbol_ID _marpa_g_irl_rhs ( Marpa_Grammar g, Marpa_IRL_ID irl_id, int ix);
int _marpa_g_rule_is_used (Marpa_Grammar g, Marpa_Rule_ID rule_id);
int _marpa_g_irl_is_virtual_lhs (Marpa_Grammar g, Marpa_IRL_ID irl_id);
int _marpa_g_irl_is_virtual_rhs (Marpa_Grammar g, Marpa_IRL_ID irl_id);
unsigned int _marpa_g_virtual_start (Marpa_Grammar g, Marpa_IRL_ID irl_id);
unsigned int _marpa_g_virtual_end (Marpa_Grammar g, Marpa_IRL_ID irl_id);
Marpa_Rule_ID _marpa_g_source_xrl (Marpa_Grammar g, Marpa_IRL_ID irl_id);
int _marpa_g_real_symbol_count (Marpa_Grammar g, Marpa_IRL_ID irl_id);
Marpa_Rule_ID _marpa_g_irl_semantic_equivalent (Marpa_Grammar g, Marpa_IRL_ID irl_id);
Marpa_Rank _marpa_g_irl_rank ( Marpa_Grammar g, Marpa_IRL_ID irl_id);
Marpa_Rank _marpa_g_isy_rank ( Marpa_Grammar g, Marpa_IRL_ID isy_id);
int _marpa_g_AHFA_item_count (Marpa_Grammar g);
Marpa_Rule_ID _marpa_g_AHFA_item_irl (Marpa_Grammar g, Marpa_AHFA_Item_ID item_id);
int _marpa_g_AHFA_item_position (Marpa_Grammar g, Marpa_AHFA_Item_ID item_id);
Marpa_Symbol_ID _marpa_g_AHFA_item_postdot (Marpa_Grammar g, Marpa_AHFA_Item_ID item_id);
int _marpa_g_AHFA_item_sort_key (Marpa_Grammar g, Marpa_AHFA_Item_ID item_id);
int _marpa_g_AHFA_state_count (Marpa_Grammar g);
int _marpa_g_AHFA_state_item_count (Marpa_Grammar g, Marpa_AHFA_State_ID AHFA_state_id);
Marpa_AHFA_Item_ID _marpa_g_AHFA_state_item (Marpa_Grammar g, Marpa_AHFA_State_ID AHFA_state_id, int item_ix);
int _marpa_g_AHFA_state_is_predict (Marpa_Grammar g, Marpa_AHFA_State_ID AHFA_state_id);
Marpa_Symbol_ID _marpa_g_AHFA_state_leo_lhs_symbol ( Marpa_Grammar g, Marpa_AHFA_State_ID AHFA_state_id);
int _marpa_g_AHFA_state_transitions ( Marpa_Grammar g, Marpa_AHFA_State_ID AHFA_state_id, int *buffer, int buffer_size );
Marpa_AHFA_State_ID _marpa_g_AHFA_state_empty_transition ( Marpa_Grammar g, Marpa_AHFA_Item_ID AHFA_item_id);
int _marpa_r_is_use_leo (Marpa_Recognizer r);
int _marpa_r_is_use_leo_set ( Marpa_Recognizer r, int value);
Marpa_Earley_Set_ID _marpa_r_trace_earley_set (Marpa_Recognizer r);
int _marpa_r_earley_set_size (Marpa_Recognizer r, Marpa_Earley_Set_ID set_id);
Marpa_Earleme _marpa_r_earley_set_trace (Marpa_Recognizer r, Marpa_Earley_Set_ID set_id);
Marpa_AHFA_State_ID _marpa_r_earley_item_trace (Marpa_Recognizer r, Marpa_Earley_Item_ID item_id);
Marpa_Earley_Set_ID _marpa_r_earley_item_origin (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_leo_predecessor_symbol (Marpa_Recognizer r);
Marpa_Earley_Set_ID _marpa_r_leo_base_origin (Marpa_Recognizer r);
Marpa_AHFA_State_ID _marpa_r_leo_base_state (Marpa_Recognizer r);
Marpa_AHFA_State_ID _marpa_r_leo_expansion_ahfa (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_postdot_symbol_trace (Marpa_Recognizer r, Marpa_Symbol_ID symid);
Marpa_Symbol_ID _marpa_r_first_postdot_item_trace (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_next_postdot_item_trace (Marpa_Recognizer r);
Marpa_AHFA_State_ID _marpa_r_postdot_item_symbol (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_first_token_link_trace (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_next_token_link_trace (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_first_completion_link_trace (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_next_completion_link_trace (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_first_leo_link_trace (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_next_leo_link_trace (Marpa_Recognizer r);
Marpa_AHFA_State_ID _marpa_r_source_predecessor_state (Marpa_Recognizer r);
Marpa_Symbol_ID _marpa_r_source_token (Marpa_Recognizer r, int *value_p);
Marpa_Symbol_ID _marpa_r_source_leo_transition_symbol (Marpa_Recognizer r);
Marpa_Earley_Set_ID _marpa_r_source_middle (Marpa_Recognizer r);
int _marpa_b_and_node_count ( Marpa_Bocage b);
int _marpa_b_and_node_parent ( Marpa_Bocage b, Marpa_And_Node_ID and_node_id);
int _marpa_b_and_node_predecessor ( Marpa_Bocage b, Marpa_And_Node_ID and_node_id);
int _marpa_b_and_node_cause ( Marpa_Bocage b, Marpa_And_Node_ID and_node_id);
int _marpa_b_and_node_symbol ( Marpa_Bocage b, Marpa_And_Node_ID and_node_id);
Marpa_Symbol_ID _marpa_b_and_node_token ( Marpa_Bocage b, Marpa_And_Node_ID and_node_id, int* value_p);
Marpa_Or_Node_ID _marpa_b_top_or_node ( Marpa_Bocage b);
int _marpa_b_or_node_set ( Marpa_Bocage b, Marpa_Or_Node_ID or_node_id);
int _marpa_b_or_node_origin ( Marpa_Bocage b, Marpa_Or_Node_ID or_node_id);
Marpa_IRL_ID _marpa_b_or_node_irl ( Marpa_Bocage b, Marpa_Or_Node_ID or_node_id);
int _marpa_b_or_node_position ( Marpa_Bocage b, Marpa_Or_Node_ID or_node_id);
int _marpa_b_or_node_first_and ( Marpa_Bocage b, Marpa_Or_Node_ID or_node_id);
int _marpa_b_or_node_last_and ( Marpa_Bocage b, Marpa_Or_Node_ID or_node_id);
int _marpa_b_or_node_and_count ( Marpa_Bocage b, Marpa_Or_Node_ID or_node_id);
Marpa_And_Node_ID _marpa_o_and_order_get ( Marpa_Order o, Marpa_Or_Node_ID or_node_id, int ix);
int _marpa_t_size ( Marpa_Tree t);
Marpa_Or_Node_ID _marpa_t_nook_or_node ( Marpa_Tree t, Marpa_Nook_ID nook_id);
int _marpa_t_nook_choice ( Marpa_Tree t, Marpa_Nook_ID nook_id );
int _marpa_t_nook_parent ( Marpa_Tree t, Marpa_Nook_ID nook_id );
int _marpa_t_nook_cause_is_ready ( Marpa_Tree t, Marpa_Nook_ID nook_id );
int _marpa_t_nook_predecessor_is_ready ( Marpa_Tree t, Marpa_Nook_ID nook_id );
int _marpa_t_nook_is_cause ( Marpa_Tree t, Marpa_Nook_ID nook_id );
int _marpa_t_nook_is_predecessor ( Marpa_Tree t, Marpa_Nook_ID nook_id );
int _marpa_v_trace ( Marpa_Value v, int flag);
Marpa_Nook_ID _marpa_v_nook ( Marpa_Value v);
#define MARPA_ERROR_COUNT 92
#define MARPA_ERR_NONE 0
#define MARPA_ERR_AHFA_IX_NEGATIVE 1
#define MARPA_ERR_AHFA_IX_OOB 2
#define MARPA_ERR_ANDID_NEGATIVE 3
#define MARPA_ERR_ANDID_NOT_IN_OR 4
#define MARPA_ERR_ANDIX_NEGATIVE 5
#define MARPA_ERR_BAD_SEPARATOR 6
#define MARPA_ERR_BOCAGE_ITERATION_EXHAUSTED 7
#define MARPA_ERR_COUNTED_NULLABLE 8
#define MARPA_ERR_DEVELOPMENT 9
#define MARPA_ERR_DUPLICATE_AND_NODE 10
#define MARPA_ERR_DUPLICATE_RULE 11
#define MARPA_ERR_DUPLICATE_TOKEN 12
#define MARPA_ERR_EIM_COUNT 13
#define MARPA_ERR_EIM_ID_INVALID 14
#define MARPA_ERR_EVENT_IX_NEGATIVE 15
#define MARPA_ERR_EVENT_IX_OOB 16
#define MARPA_ERR_GRAMMAR_HAS_CYCLE 17
#define MARPA_ERR_INACCESSIBLE_TOKEN 18
#define MARPA_ERR_INTERNAL 19
#define MARPA_ERR_INVALID_AHFA_ID 20
#define MARPA_ERR_INVALID_AIMID 21
#define MARPA_ERR_INVALID_BOOLEAN 22
#define MARPA_ERR_INVALID_IRLID 23
#define MARPA_ERR_INVALID_ISYID 24
#define MARPA_ERR_INVALID_LOCATION 25
#define MARPA_ERR_INVALID_RULE_ID 26
#define MARPA_ERR_INVALID_START_SYMBOL 27
#define MARPA_ERR_INVALID_SYMBOL_ID 28
#define MARPA_ERR_I_AM_NOT_OK 29
#define MARPA_ERR_MAJOR_VERSION_MISMATCH 30
#define MARPA_ERR_MICRO_VERSION_MISMATCH 31
#define MARPA_ERR_MINOR_VERSION_MISMATCH 32
#define MARPA_ERR_NOOKID_NEGATIVE 33
#define MARPA_ERR_NOT_PRECOMPUTED 34
#define MARPA_ERR_NOT_TRACING_COMPLETION_LINKS 35
#define MARPA_ERR_NOT_TRACING_LEO_LINKS 36
#define MARPA_ERR_NOT_TRACING_TOKEN_LINKS 37
#define MARPA_ERR_NO_AND_NODES 38
#define MARPA_ERR_NO_EARLEY_SET_AT_LOCATION 39
#define MARPA_ERR_NO_OR_NODES 40
#define MARPA_ERR_NO_PARSE 41
#define MARPA_ERR_NO_RULES 42
#define MARPA_ERR_NO_START_SYMBOL 43
#define MARPA_ERR_NO_TOKEN_EXPECTED_HERE 44
#define MARPA_ERR_NO_TRACE_EIM 45
#define MARPA_ERR_NO_TRACE_ES 46
#define MARPA_ERR_NO_TRACE_PIM 47
#define MARPA_ERR_NO_TRACE_SRCL 48
#define MARPA_ERR_NULLING_TERMINAL 49
#define MARPA_ERR_ORDER_FROZEN 50
#define MARPA_ERR_ORID_NEGATIVE 51
#define MARPA_ERR_OR_ALREADY_ORDERED 52
#define MARPA_ERR_PARSE_EXHAUSTED 53
#define MARPA_ERR_PARSE_TOO_LONG 54
#define MARPA_ERR_PIM_IS_NOT_LIM 55
#define MARPA_ERR_POINTER_ARG_NULL 56
#define MARPA_ERR_PRECOMPUTED 57
#define MARPA_ERR_PROGRESS_REPORT_EXHAUSTED 58
#define MARPA_ERR_PROGRESS_REPORT_NOT_STARTED 59
#define MARPA_ERR_RECCE_NOT_ACCEPTING_INPUT 60
#define MARPA_ERR_RECCE_NOT_STARTED 61
#define MARPA_ERR_RECCE_STARTED 62
#define MARPA_ERR_RHS_IX_NEGATIVE 63
#define MARPA_ERR_RHS_IX_OOB 64
#define MARPA_ERR_RHS_TOO_LONG 65
#define MARPA_ERR_SEQUENCE_LHS_NOT_UNIQUE 66
#define MARPA_ERR_SOURCE_TYPE_IS_AMBIGUOUS 67
#define MARPA_ERR_SOURCE_TYPE_IS_COMPLETION 68
#define MARPA_ERR_SOURCE_TYPE_IS_LEO 69
#define MARPA_ERR_SOURCE_TYPE_IS_NONE 70
#define MARPA_ERR_SOURCE_TYPE_IS_TOKEN 71
#define MARPA_ERR_SOURCE_TYPE_IS_UNKNOWN 72
#define MARPA_ERR_START_NOT_LHS 73
#define MARPA_ERR_SYMBOL_VALUED_CONFLICT 74
#define MARPA_ERR_TERMINAL_IS_LOCKED 75
#define MARPA_ERR_TOKEN_IS_NOT_TERMINAL 76
#define MARPA_ERR_TOKEN_LENGTH_LE_ZERO 77
#define MARPA_ERR_TOKEN_TOO_LONG 78
#define MARPA_ERR_TREE_EXHAUSTED 79
#define MARPA_ERR_TREE_PAUSED 80
#define MARPA_ERR_UNEXPECTED_TOKEN_ID 81
#define MARPA_ERR_UNPRODUCTIVE_START 82
#define MARPA_ERR_VALUATOR_INACTIVE 83
#define MARPA_ERR_VALUED_IS_LOCKED 84
#define MARPA_ERR_RANK_TOO_LOW 85
#define MARPA_ERR_RANK_TOO_HIGH 86
#define MARPA_ERR_SYMBOL_IS_NULLING 87
#define MARPA_ERR_SYMBOL_IS_UNUSED 88
#define MARPA_ERR_NO_SUCH_RULE_ID 89
#define MARPA_ERR_NO_SUCH_SYMBOL_ID 90
#define MARPA_ERR_BEFORE_FIRST_TREE 91
#define MARPA_EVENT_COUNT 7
#define MARPA_EVENT_NONE 0
#define MARPA_EVENT_COUNTED_NULLABLE 1
#define MARPA_EVENT_EARLEY_ITEM_THRESHOLD 2
#define MARPA_EVENT_EXHAUSTED 3
#define MARPA_EVENT_LOOP_RULES 4
#define MARPA_EVENT_NULLING_TERMINAL 5
#define MARPA_EVENT_SYMBOL_EXPECTED 6
#define MARPA_STEP_COUNT 8
#define MARPA_STEP_INTERNAL1 0
#define MARPA_STEP_RULE 1
#define MARPA_STEP_TOKEN 2
#define MARPA_STEP_NULLING_SYMBOL 3
#define MARPA_STEP_TRACE 4
#define MARPA_STEP_INACTIVE 5
#define MARPA_STEP_INTERNAL2 6
#define MARPA_STEP_INITIAL 7
