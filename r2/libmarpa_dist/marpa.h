/*1288:*/
#line 14939 "./marpa.w"

/*1284:*/
#line 14911 "./marpa.w"

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
 * This file is written by ctangle
 * It is not intended to be modified directly
 */

/*:1284*/
#line 14940 "./marpa.w"


#ifndef __MARPA_H__
#define __MARPA_H__ 
#include "marpa_config.h"

/*36:*/
#line 553 "./marpa.w"

extern const unsigned int marpa_major_version;
extern const unsigned int marpa_minor_version;
extern const unsigned int marpa_micro_version;
extern const unsigned int marpa_interface_age;
extern const unsigned int marpa_binary_age;
#define MARPA_CHECK_VERSION(major,minor,micro)  \
     (MARPA_MAJOR_VERSION >  (major) \
         || (MARPA_MAJOR_VERSION == (major) && MARPA_MINOR_VERSION >  (minor)) \
         || (MARPA_MAJOR_VERSION == (major) && MARPA_MINOR_VERSION == (minor) \
          && MARPA_MICRO_VERSION >= (micro)))

/*102:*/
#line 953 "./marpa.w"

#define marpa_g_event_value(event) \
    ((event)->t_value)
/*:102*//*259:*/
#line 2329 "./marpa.w"

#define MARPA_KEEP_SEPARATION  0x1
/*:259*//*263:*/
#line 2369 "./marpa.w"

#define MARPA_PROPER_SEPARATION  0x2
/*:263*//*1095:*/
#line 12626 "./marpa.w"

#define marpa_v_step_type(v) ((v)->t_step_type)
#define marpa_v_token(v) \
    ((v)->t_token_id)
#define marpa_v_symbol(v) marpa_v_token(v)
#define marpa_v_token_value(v) \
    ((v)->t_token_value)
#define marpa_v_rule(v) \
    ((v)->t_rule_id)
#define marpa_v_arg_0(v) \
    ((v)->t_arg_0)
#define marpa_v_arg_n(v) \
    ((v)->t_arg_n)
#define marpa_v_result(v) marpa_v_arg_0(v)
#define marpa_v_rule_start_es_id(v) ((v)->t_rule_start_es_id)
#define marpa_v_token_start_es_id(v) ((v)->t_token_start_es_id)
#define marpa_v_es_id(v) ((v)->t_es_id)

/*:1095*/
#line 565 "./marpa.w"

/*41:*/
#line 601 "./marpa.w"

struct marpa_g;
struct marpa_avl_table;
typedef struct marpa_g*Marpa_Grammar;
/*:41*//*564:*/
#line 6148 "./marpa.w"

struct marpa_r;
typedef struct marpa_r*Marpa_Recognizer;
typedef Marpa_Recognizer Marpa_Recce;
/*:564*//*966:*/
#line 11129 "./marpa.w"

struct marpa_bocage;
typedef struct marpa_bocage*Marpa_Bocage;
/*:966*//*1008:*/
#line 11556 "./marpa.w"

struct marpa_order;
typedef struct marpa_order*Marpa_Order;
/*:1008*//*1009:*/
#line 11559 "./marpa.w"

typedef Marpa_Order ORDER;
/*:1009*//*1042:*/
#line 12004 "./marpa.w"

struct marpa_tree;
typedef struct marpa_tree*Marpa_Tree;
/*:1042*//*1090:*/
#line 12584 "./marpa.w"

struct marpa_value;
typedef struct marpa_value*Marpa_Value;
/*:1090*/
#line 566 "./marpa.w"

/*86:*/
#line 869 "./marpa.w"

typedef int Marpa_Rank;
/*:86*//*101:*/
#line 950 "./marpa.w"

struct marpa_event;
typedef int Marpa_Event_Type;
/*:101*//*122:*/
#line 1111 "./marpa.w"

typedef int Marpa_Error_Code;
/*:122*//*129:*/
#line 1166 "./marpa.w"

typedef int Marpa_Symbol_ID;
/*:129*//*185:*/
#line 1573 "./marpa.w"

typedef int Marpa_ISY_ID;
/*:185*//*217:*/
#line 1796 "./marpa.w"

typedef int Marpa_Rule_ID;
/*:217*//*289:*/
#line 2517 "./marpa.w"

typedef int Marpa_IRL_ID;
/*:289*//*411:*/
#line 4354 "./marpa.w"

typedef int Marpa_AHFA_Item_ID;
/*:411*//*451:*/
#line 4707 "./marpa.w"

typedef int Marpa_AHFA_State_ID;

/*:451*//*620:*/
#line 6554 "./marpa.w"
typedef int Marpa_Earleme;
/*:620*//*622:*/
#line 6558 "./marpa.w"
typedef int Marpa_Earley_Set_ID;
/*:622*//*646:*/
#line 6752 "./marpa.w"
typedef int Marpa_Earley_Item_ID;
/*:646*//*875:*/
#line 9822 "./marpa.w"

typedef int Marpa_Or_Node_ID;
/*:875*//*935:*/
#line 10696 "./marpa.w"

typedef int Marpa_And_Node_ID;
/*:935*//*1076:*/
#line 12445 "./marpa.w"

typedef int Marpa_Nook_ID;
/*:1076*//*1130:*/
#line 12963 "./marpa.w"

typedef int Marpa_Step_Type;
/*:1130*//*1259:*/
#line 14611 "./marpa.w"

typedef const char*Marpa_Message_ID;

/*:1259*/
#line 567 "./marpa.w"

/*38:*/
#line 572 "./marpa.w"

struct marpa_config{
int t_is_ok;
Marpa_Error_Code t_error;
const char*t_error_string;
};
typedef struct marpa_config Marpa_Config;

/*:38*//*103:*/
#line 956 "./marpa.w"

struct marpa_event{
Marpa_Event_Type t_type;
int t_value;
};
typedef struct marpa_event Marpa_Event;
/*:103*//*955:*/
#line 10897 "./marpa.w"

struct marpa_progress_item{
Marpa_Rule_ID t_rule_id;
int t_position;
int t_origin;
};

/*:955*//*1094:*/
#line 12614 "./marpa.w"

struct marpa_value{
Marpa_Step_Type t_step_type;
Marpa_Symbol_ID t_token_id;
int t_token_value;
Marpa_Rule_ID t_rule_id;
int t_arg_0;
int t_arg_n;
Marpa_Earley_Set_ID t_token_start_es_id;
Marpa_Earley_Set_ID t_rule_start_es_id;
Marpa_Earley_Set_ID t_es_id;
};
/*:1094*/
#line 568 "./marpa.w"

/*1265:*/
#line 14663 "./marpa.w"

void marpa_debug_handler_set(int(*debug_handler)(const char*,...));
/*:1265*//*1267:*/
#line 14671 "./marpa.w"

void marpa_debug_level_set(int level);
/*:1267*/
#line 569 "./marpa.w"


/*:36*/
#line 14946 "./marpa.w"


#include "marpa_api.h"
#endif 

/*:1288*/
