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

/*60:*/
#line 685 "./marpa_slif.w"


#include "config.h"

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#include "marpa_slif.h"
#include "marpa_ami.h"
#include "marpa_tavl.h"

/*5:*/
#line 152 "./marpa_slif.w"

#define PRIVATE_NOT_INLINE static
#define PRIVATE static inline

/*:5*/
#line 697 "./marpa_slif.w"

/*23:*/
#line 225 "./marpa_slif.w"

typedef Marpa_SLR SLR;

/*:23*/
#line 698 "./marpa_slif.w"

/*22:*/
#line 219 "./marpa_slif.w"

struct marpa_slr_s{
/*39:*/
#line 351 "./marpa_slif.w"

struct tavl_table*t_per_codepoint_tavl;

/*:39*//*46:*/
#line 605 "./marpa_slif.w"

MARPA_DSTACK_DECLARE(t_event_dstack);
MARPA_DSTACK_DECLARE(t_lexeme_dstack);

/*:46*/
#line 221 "./marpa_slif.w"

/*27:*/
#line 241 "./marpa_slif.w"
int t_ref_count;

/*:27*/
#line 222 "./marpa_slif.w"

int t_count_of_deleted_events;
};
/*:22*//*34:*/
#line 296 "./marpa_slif.w"

struct op_data_s{const char*name;Marpa_Op op;};

/*:34*//*37:*/
#line 335 "./marpa_slif.w"

struct per_codepoint_data_s{
Marpa_Codepoint t_codepoint;
Marpa_Op t_ops[1];
};

/*:37*/
#line 699 "./marpa_slif.w"


/*:60*/

#line 1 "./marpa_slif.c.p40"
static inline void
slr_unref (Marpa_SLR slr);
static inline SLR
slr_ref (SLR slr);
static inline void slr_free(SLR slr);
static inline int
cmp_per_codepoint_key( const void* a, const void* b, void* param UNUSED);
static inline void
per_codepoint_data_destroy(void *p, void* param UNUSED);

/*61:*/
#line 701 "./marpa_slif.w"


/*25:*/
#line 230 "./marpa_slif.w"

Marpa_SLR marpa__slr_new(void)
{
/*58:*/
#line 681 "./marpa_slif.w"
void*const failure_indicator UNUSED= NULL;

/*:58*/
#line 233 "./marpa_slif.w"

SLR slr;
slr= my_malloc(sizeof(*slr));
/*28:*/
#line 243 "./marpa_slif.w"

slr->t_ref_count= 1;

/*:28*//*40:*/
#line 354 "./marpa_slif.w"

{
slr->t_per_codepoint_tavl= marpa__tavl_create(cmp_per_codepoint_key,NULL);
}

/*:40*//*47:*/
#line 609 "./marpa_slif.w"

{
MARPA_DSTACK_INIT(slr->t_event_dstack,union marpa_slr_event_s,
MAX(1024/sizeof(union marpa_slr_event_s),16));
slr->t_count_of_deleted_events= 0;
MARPA_DSTACK_INIT(slr->t_lexeme_dstack,union marpa_slr_event_s,
MAX(1024/sizeof(union marpa_slr_event_s),16));
}

/*:47*/
#line 236 "./marpa_slif.w"

return slr;
}

/*:25*//*29:*/
#line 247 "./marpa_slif.w"

PRIVATE void
slr_unref(Marpa_SLR slr)
{
MARPA_ASSERT(slr->t_ref_count> 0)
slr->t_ref_count--;
if(slr->t_ref_count<=0)
{
slr_free(slr);
}
}
void
marpa__slr_unref(Marpa_SLR slr)
{
slr_unref(slr);
}

/*:29*//*30:*/
#line 265 "./marpa_slif.w"

PRIVATE SLR
slr_ref(SLR slr)
{
MARPA_ASSERT(slr->t_ref_count> 0)
slr->t_ref_count++;
return slr;
}

Marpa_SLR
marpa__slr_ref(Marpa_SLR slr)
{
return slr_ref(slr);
}

/*:30*//*31:*/
#line 280 "./marpa_slif.w"

PRIVATE void slr_free(SLR slr)
{
/*42:*/
#line 366 "./marpa_slif.w"

{
marpa__tavl_destroy(slr->t_per_codepoint_tavl,per_codepoint_data_destroy);
}

/*:42*//*48:*/
#line 618 "./marpa_slif.w"

{
MARPA_DSTACK_DESTROY(slr->t_event_dstack);
MARPA_DSTACK_DESTROY(slr->t_lexeme_dstack);
}

/*:48*/
#line 283 "./marpa_slif.w"

my_free(slr);
}

/*:31*//*35:*/
#line 301 "./marpa_slif.w"

const char*
marpa__slif_op_name(Marpa_Op op_id)
{
if(op_id>=(int)Dim(op_name_by_id_object))return"unknown";
return op_name_by_id_object[op_id];
}

Marpa_Op
marpa__slif_op_id(const char*name)
{
int lo= 0;
int hi= Dim(op_by_name_object)-1;
while(hi>=lo)
{
const int trial= lo+(hi-lo)/2;
const char*trial_name= op_by_name_object[trial].name;
int cmp= strcmp(name,trial_name);
if(!cmp)
return op_by_name_object[trial].op;
if(cmp<0)
{
hi= trial-1;
}
else
{
lo= trial+1;
}
}
return-1;
}

/*:35*//*38:*/
#line 341 "./marpa_slif.w"

PRIVATE int
cmp_per_codepoint_key(const void*a,const void*b,void*param UNUSED)
{
const Marpa_Codepoint codepoint_a= ((struct per_codepoint_data_s*)a)->t_codepoint;
const Marpa_Codepoint codepoint_b= ((struct per_codepoint_data_s*)b)->t_codepoint;
if(codepoint_a==codepoint_b)return 0;
return codepoint_a<codepoint_b?-1:1;
}

/*:38*//*41:*/
#line 359 "./marpa_slif.w"

PRIVATE void
per_codepoint_data_destroy(void*p,void*param UNUSED)
{
my_free(p);
}

/*:41*//*49:*/
#line 624 "./marpa_slif.w"

void marpa__slr_event_clear(Marpa_SLR slr)
{
MARPA_DSTACK_CLEAR(slr->t_event_dstack);
slr->t_count_of_deleted_events= 0;
}

/*:49*//*50:*/
#line 631 "./marpa_slif.w"

int marpa__slr_event_count(Marpa_SLR slr)
{
const int event_count= MARPA_DSTACK_LENGTH(slr->t_event_dstack);
return event_count-slr->t_count_of_deleted_events;
}

/*:50*//*51:*/
#line 638 "./marpa_slif.w"

int marpa__slr_event_max_index(Marpa_SLR slr)
{
return MARPA_DSTACK_LENGTH(slr->t_event_dstack)-1;
}

/*:51*//*52:*/
#line 644 "./marpa_slif.w"

union marpa_slr_event_s*marpa__slr_event_push(Marpa_SLR slr)
{
return MARPA_DSTACK_PUSH(slr->t_event_dstack,union marpa_slr_event_s);
}

/*:52*//*53:*/
#line 650 "./marpa_slif.w"

union marpa_slr_event_s*marpa__slr_event_entry(Marpa_SLR slr,int i)
{
return MARPA_DSTACK_INDEX(slr->t_event_dstack,union marpa_slr_event_s,i);
}

/*:53*//*54:*/
#line 656 "./marpa_slif.w"

void marpa__slr_lexeme_clear(Marpa_SLR slr)
{
MARPA_DSTACK_CLEAR(slr->t_lexeme_dstack);
}

/*:54*//*55:*/
#line 662 "./marpa_slif.w"

int marpa__slr_lexeme_count(Marpa_SLR slr)
{
return MARPA_DSTACK_LENGTH(slr->t_lexeme_dstack);
}

/*:55*//*56:*/
#line 668 "./marpa_slif.w"

union marpa_slr_event_s*marpa__slr_lexeme_push(Marpa_SLR slr)
{
return MARPA_DSTACK_PUSH(slr->t_lexeme_dstack,union marpa_slr_event_s);
}

/*:56*//*57:*/
#line 674 "./marpa_slif.w"

union marpa_slr_event_s*marpa__slr_lexeme_entry(Marpa_SLR slr,int i)
{
return MARPA_DSTACK_INDEX(slr->t_lexeme_dstack,union marpa_slr_event_s,i);
}

/*:57*/
#line 703 "./marpa_slif.w"


/*:61*/
