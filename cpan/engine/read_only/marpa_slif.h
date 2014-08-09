/*
 * Copyright 2014 Jeffrey Kegler
 * This file is part of Libmarpa.  Libmarpa is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Libmarpa is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Libmarpa.  If not, see
 * http://www.gnu.org/licenses/.
 */

/*
 * DO NOT EDIT DIRECTLY
 * This file is written by the Marpa build process
 * It is not intended to be modified directly
 */

/*62:*/
#line 706 "./marpa_slif.w"


#ifndef _MARPA_SLIF_H__
#define _MARPA_SLIF_H__ 1

#include "marpa.h"

#define MARPA_SLREV_AFTER_LEXEME 1
#define MARPA_SLREV_BEFORE_LEXEME 2
#define MARPA_SLREV_LEXER_RESTARTED_RECCE 4
#define MARPA_SLREV_MARPA_R_UNKNOWN 5
#define MARPA_SLREV_NO_ACCEPTABLE_INPUT 6
#define MARPA_SLREV_SYMBOL_COMPLETED 7
#define MARPA_SLREV_SYMBOL_NULLED 8
#define MARPA_SLREV_SYMBOL_PREDICTED 9
#define MARPA_SLRTR_AFTER_LEXEME 10
#define MARPA_SLRTR_BEFORE_LEXEME 11
#define MARPA_SLRTR_CHANGE_LEXERS 12
#define MARPA_SLRTR_CODEPOINT_ACCEPTED 13
#define MARPA_SLRTR_CODEPOINT_READ 14
#define MARPA_SLRTR_CODEPOINT_REJECTED 15
#define MARPA_SLRTR_LEXEME_DISCARDED 16
#define MARPA_SLRTR_G1_ACCEPTED_LEXEME 17
#define MARPA_SLRTR_G1_ATTEMPTING_LEXEME 18
#define MARPA_SLRTR_G1_DUPLICATE_LEXEME 19
#define MARPA_SLRTR_LEXEME_REJECTED 20
#define MARPA_SLRTR_LEXEME_IGNORED 21
#define MARPA_SLREV_DELETED 22
#define MARPA_SLRTR_LEXEME_ACCEPTABLE 23
#define MARPA_SLRTR_LEXEME_OUTPRIORITIZED 24
#define MARPA_SLRTR_LEXEME_EXPECTED 26 \

#define MARPA_SLREV_TYPE(event) ((event) ->t_header.t_event_type)  \


#line 713 "./marpa_slif.w"

/*15:*/
#line 192 "./marpa_slif.w"

typedef unsigned int Marpa_Codepoint;

/*:15*//*33:*/
#line 293 "./marpa_slif.w"

typedef int Marpa_Op;

/*:33*/
#line 714 "./marpa_slif.w"

/*7:*/
#line 161 "./marpa_slif.w"

struct marpa_error_description_s;
/*:7*//*11:*/
#line 178 "./marpa_slif.w"

struct marpa_event_description_s;
/*:11*//*17:*/
#line 201 "./marpa_slif.w"

struct marpa_step_type_description_s;
/*:17*//*21:*/
#line 216 "./marpa_slif.w"

struct marpa_slr_s;
typedef struct marpa_slr_s*Marpa_SLR;
/*:21*//*43:*/
#line 372 "./marpa_slif.w"

union marpa_slr_event_s;

/*:43*/
#line 715 "./marpa_slif.w"

/*8:*/
#line 163 "./marpa_slif.w"

struct marpa_error_description_s
{
Marpa_Error_Code error_code;
const char*name;
const char*suggested;
};
/*:8*//*12:*/
#line 180 "./marpa_slif.w"

struct marpa_event_description_s
{
Marpa_Event_Type event_code;
const char*name;
const char*suggested;
};
/*:12*//*18:*/
#line 203 "./marpa_slif.w"

struct marpa_step_type_description_s
{
Marpa_Step_Type step_type;
const char*name;
};
/*:18*//*45:*/
#line 403 "./marpa_slif.w"

union marpa_slr_event_s
{
struct
{
int t_event_type;
}t_header;

struct
{
int event_type;
int t_codepoint;
int t_perl_pos;
int t_current_lexer_ix;
}t_trace_codepoint_read;

struct
{
int event_type;
int t_codepoint;
int t_perl_pos;
int t_symbol_id;
int t_current_lexer_ix;
}t_trace_codepoint_rejected;

struct
{
int event_type;
int t_codepoint;
int t_perl_pos;
int t_symbol_id;
int t_current_lexer_ix;
}t_trace_codepoint_accepted;

struct
{
int event_type;
int t_event_type;
int t_rule_id;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_current_lexer_ix;
}t_trace_codepoint_discarded;


struct
{
int event_type;
int t_event_type;
int t_lexeme;
int t_start_of_lexeme;
int t_end_of_lexeme;
}t_trace_lexeme_ignored;

struct
{
int event_type;
int t_rule_id;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_current_lexer_ix;
}t_trace_lexeme_discarded;

struct
{
int event_type;
int t_symbol;
}t_symbol_completed;

struct
{
int event_type;
int t_symbol;
}t_symbol_nulled;

struct
{
int event_type;
int t_symbol;
}t_symbol_predicted;

struct
{
int event_type;
int t_event;
}t_marpa_r_unknown;

struct
{
int event_type;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_lexeme;
int t_current_lexer_ix;
}
t_trace_lexeme_rejected;

struct
{
int event_type;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_lexeme;
int t_current_lexer_ix;
int t_priority;
int t_required_priority;
}t_trace_lexeme_acceptable;

struct
{
int event_type;
int t_start_of_pause_lexeme;
int t_end_of_pause_lexeme;
int t_pause_lexeme;
}t_trace_before_lexeme;

struct
{
int event_type;
int t_pause_lexeme;
}t_before_lexeme;

struct
{
int event_type;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_lexeme;
}t_trace_after_lexeme;

struct
{
int event_type;
int t_lexeme;
}t_after_lexeme;

struct
{
int event_type;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_lexeme;
}
t_trace_attempting_lexeme;

struct
{
int event_type;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_lexeme;
}
t_trace_duplicate_lexeme;

struct
{
int event_type;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_lexeme;
int t_current_lexer_ix;
}
t_trace_accepted_lexeme;

struct
{
int event_type;
int t_start_of_lexeme;
int t_end_of_lexeme;
int t_lexeme;
int t_current_lexer_ix;
int t_priority;
int t_required_priority;
}t_lexeme_acceptable;
struct
{
int event_type;
int t_perl_pos;
int t_old_lexer_ix;
int t_new_lexer_ix;
}t_trace_change_lexers;
struct
{
int event_type;
}t_no_acceptable_input;
struct
{
int event_type;
int t_perl_pos;
int t_current_lexer_ix;
}t_lexer_restarted_recce;
struct
{
int event_type;
int t_perl_pos;
int t_current_lexer_ix;
Marpa_Symbol_ID t_lexeme;
Marpa_Assertion_ID t_assertion;
}t_trace_lexeme_expected;

};

/*:45*/
#line 716 "./marpa_slif.w"

/*9:*/
#line 170 "./marpa_slif.w"

extern const struct marpa_error_description_s marpa_error_description[];

/*:9*//*13:*/
#line 187 "./marpa_slif.w"

extern const struct marpa_event_description_s marpa_event_description[];

/*:13*//*19:*/
#line 209 "./marpa_slif.w"

extern const struct marpa_step_type_description_s
marpa_step_type_description[];

/*:19*/
#line 717 "./marpa_slif.w"


#endif 
/*:62*/

#line 1 "./marpa_slif.h.p80"
Marpa_SLR marpa__slr_new (void);
Marpa_SLR marpa__slr_ref (Marpa_SLR slr);
void marpa__slr_unref (Marpa_SLR slr);
void marpa__slr_event_clear( Marpa_SLR slr );
union marpa_slr_event_s * marpa__slr_event_push( Marpa_SLR slr );
int marpa__slr_event_count( Marpa_SLR slr );
int marpa__slr_event_max_index( Marpa_SLR slr );
union marpa_slr_event_s * marpa__slr_event_entry( Marpa_SLR slr, int i );
void marpa__slr_lexeme_clear( Marpa_SLR slr );
union marpa_slr_event_s * marpa__slr_lexeme_push( Marpa_SLR slr );
int marpa__slr_lexeme_count( Marpa_SLR slr );
union marpa_slr_event_s * marpa__slr_lexeme_entry( Marpa_SLR slr, int i );
int marpa__slif_op_id (const char* op_name );
const char* marpa__slif_op_name (Marpa_Op op_id );


#line 1 "./marpa_slif.h-ops"
#define MARPA_OP_ALTERNATIVE 0
#define MARPA_OP_BLESS 1
#define MARPA_OP_CALLBACK 2
#define MARPA_OP_EARLEME_COMPLETE 3
#define MARPA_OP_END_MARKER 4
#define MARPA_OP_INVALID_CHAR 5
#define MARPA_OP_NOOP 6
#define MARPA_OP_PAUSE 7
#define MARPA_OP_PUSH_CONSTANT 8
#define MARPA_OP_PUSH_LENGTH 9
#define MARPA_OP_PUSH_ONE 10
#define MARPA_OP_PUSH_SEQUENCE 11
#define MARPA_OP_PUSH_START_LOCATION 12
#define MARPA_OP_PUSH_UNDEF 13
#define MARPA_OP_PUSH_VALUES 14
#define MARPA_OP_RESULT_IS_ARRAY 15
#define MARPA_OP_RESULT_IS_CONSTANT 16
#define MARPA_OP_RESULT_IS_N_OF_SEQUENCE 17
#define MARPA_OP_RESULT_IS_RHS_N 18
#define MARPA_OP_RESULT_IS_TOKEN_VALUE 19
#define MARPA_OP_RESULT_IS_UNDEF 20
#define MARPA_OP_RETRY_OR_SET_LEXER 21
#define MARPA_OP_SET_LEXER 22

