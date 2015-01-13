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

/* File called "ami" because the original factoring was with
 * the idea of a "friend" library for Libmarpa.  
 * The "friend" concept is rarely a good idea, and Libmarpa
 * did not prove to be an exception to that rule.
 */

/* Dynamic stacks.  Copied from Libmarpa.  */

#define MARPA_DSTACK_DECLARE(this) struct marpa_dstack_s this
#define MARPA_DSTACK_INIT(this, type, initial_size) \
( \
    ((this).t_count = 0), \
    Newx((this).t_base, ((this).t_capacity = (initial_size)), type) \
)
#define MARPA_DSTACK_INIT2(this, type) \
    MARPA_DSTACK_INIT((this), type, MAX(4, 1024/sizeof(this)))

#define MARPA_DSTACK_IS_INITIALIZED(this) ((this).t_base)
#define MARPA_DSTACK_SAFE(this) \
  (((this).t_count = (this).t_capacity = 0), ((this).t_base = NULL))

#define MARPA_DSTACK_COUNT_SET(this, n) ((this).t_count = (n))

#define MARPA_DSTACK_CLEAR(this) MARPA_DSTACK_COUNT_SET((this), 0)
#define MARPA_DSTACK_PUSH(this, type) ( \
      (_MARPA_UNLIKELY((this).t_count >= (this).t_capacity) \
      ? MARPA_DSTACK_RESIZE2(&(this), sizeof(type)) \
      : 0), \
     ((type *)(this).t_base+(this).t_count++) \
   )
#define MARPA_DSTACK_POP(this, type) ((this).t_count <= 0 ? NULL : \
    ( (type*)(this).t_base+(--(this).t_count)))
#define MARPA_DSTACK_INDEX(this, type, ix) (MARPA_DSTACK_BASE((this), type)+(ix))
#define MARPA_DSTACK_TOP(this, type) (MARPA_DSTACK_LENGTH(this) <= 0 \
   ? NULL \
   : MARPA_DSTACK_INDEX((this), type, MARPA_DSTACK_LENGTH(this)-1))
#define MARPA_DSTACK_BASE(this, type) ((type *)(this).t_base)
#define MARPA_DSTACK_LENGTH(this) ((this).t_count)
#define MARPA_DSTACK_CAPACITY(this) ((this).t_capacity)

#define MARPA_STOLEN_DSTACK_DATA_FREE(data) (Safefree(data))
#define MARPA_DSTACK_DESTROY(this) MARPA_STOLEN_DSTACK_DATA_FREE(this.t_base)

#define MARPA_DSTACK_RESIZE(this, type, new_size) \
  (Renew((this), (new_size), sizeof(type)))
#define MARPA_DSTACK_RESIZE2(this, type) \
  (Renew((this), ((this)->t_capacity*2), sizeof(type)))

struct marpa_dstack_s;
typedef struct marpa_dstack_s* MARPA_DSTACK;
struct marpa_dstack_s { int t_count; int t_capacity; void * t_base; };

struct marpa_error_description_s;
struct marpa_error_description_s
{
  int error_code;
  const char *name;
  const char *suggested;
};
extern const struct marpa_error_description_s marpa_error_description[];

struct marpa_event_description_s;
struct marpa_event_description_s
{
  Marpa_Event_Type event_code;
  const char *name;
  const char *suggested;
};
extern const struct marpa_event_description_s marpa_event_description[];

typedef unsigned int Marpa_Codepoint;

struct marpa_step_type_description_s;
struct marpa_step_type_description_s
{
  Marpa_Step_Type step_type;
  const char *name;
};

extern const struct marpa_step_type_description_s
  marpa_step_type_description[];

struct marpa_slr_s;
typedef struct marpa_slr_s* Marpa_SLR;
struct marpa_slr_s {
  MARPA_DSTACK_DECLARE(t_event_dstack);
  MARPA_DSTACK_DECLARE(t_lexeme_dstack);
  int t_ref_count;
  int t_count_of_deleted_events;
};
typedef Marpa_SLR SLR;

union marpa_slr_event_s;

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
#define MARPA_SLRTR_LEXEME_EXPECTED 26

#define MARPA_SLREV_TYPE(event) ((event)->t_header.t_event_type)

union marpa_slr_event_s
{
  struct
  {
    int t_event_type;
  } t_header;

  struct
  {
    int event_type;
    int t_codepoint;
    int t_perl_pos;
    int t_current_lexer_ix;
  } t_trace_codepoint_read;

  struct
  {
    int event_type;
    int t_codepoint;
    int t_perl_pos;
    int t_symbol_id;
    int t_current_lexer_ix;
  } t_trace_codepoint_rejected;

  struct
  {
    int event_type;
    int t_codepoint;
    int t_perl_pos;
    int t_symbol_id;
    int t_current_lexer_ix;
  } t_trace_codepoint_accepted;

  struct
  {
    int event_type;
    int t_event_type;
    int t_rule_id;
    int t_start_of_lexeme;
    int t_end_of_lexeme;
    int t_current_lexer_ix;
  } t_trace_codepoint_discarded;


  struct
  {
    int event_type;
    int t_event_type;
    int t_lexeme;
    int t_start_of_lexeme;
    int t_end_of_lexeme;
  } t_trace_lexeme_ignored;

  struct
  {
    int event_type;
    int t_rule_id;
    int t_start_of_lexeme;
    int t_end_of_lexeme;
    int t_current_lexer_ix;
  } t_trace_lexeme_discarded;

  struct
  {
    int event_type;
    int t_symbol;
  } t_symbol_completed;

  struct
  {
    int event_type;
    int t_symbol;
  } t_symbol_nulled;

  struct
  {
    int event_type;
    int t_symbol;
  } t_symbol_predicted;

  struct
  {
    int event_type;
    int t_event;
  } t_marpa_r_unknown;

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
  } t_trace_lexeme_acceptable;

  struct
  {
    int event_type;
    int t_start_of_pause_lexeme;
    int t_end_of_pause_lexeme;
    int t_pause_lexeme;
  } t_trace_before_lexeme;

  struct
  {
    int event_type;
    int t_pause_lexeme;
  } t_before_lexeme;

  struct
  {
    int event_type;
    int t_start_of_lexeme;
    int t_end_of_lexeme;
    int t_lexeme;
  } t_trace_after_lexeme;

  struct
  {
    int event_type;
    int t_lexeme;
  } t_after_lexeme;

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
  } t_lexeme_acceptable;
  struct
  {
    int event_type;
    int t_perl_pos;
    int t_old_lexer_ix;
    int t_new_lexer_ix;
  } t_trace_change_lexers;
  struct
  {
    int event_type;
  } t_no_acceptable_input;
  struct
  {
    int event_type;
    int t_perl_pos;
    int t_current_lexer_ix;
  } t_lexer_restarted_recce;
  struct
  {
    int event_type;
    int t_perl_pos;
    int t_current_lexer_ix;
    Marpa_Symbol_ID t_lexeme;
    Marpa_Assertion_ID t_assertion;
  } t_trace_lexeme_expected;

};

static Marpa_SLR marpa__slr_new(void)
{
    SLR slr;
    Newx(slr, 1, struct marpa_slr_s);
    slr->t_ref_count = 1;
  MARPA_DSTACK_INIT (slr->t_event_dstack, union marpa_slr_event_s,
                     MAX (1024 / sizeof (union marpa_slr_event_s), 16));
  slr->t_count_of_deleted_events = 0;
  MARPA_DSTACK_INIT (slr->t_lexeme_dstack, union marpa_slr_event_s,
                     MAX (1024 / sizeof (union marpa_slr_event_s), 16));
    return slr;
}

static void slr_free(SLR slr)
{
   MARPA_DSTACK_DESTROY(slr->t_event_dstack);
   MARPA_DSTACK_DESTROY(slr->t_lexeme_dstack);
  Safefree( slr);
}

static void
slr_unref (Marpa_SLR slr)
{
  /* MARPA_ASSERT (slr->t_ref_count > 0) */
  slr->t_ref_count--;
  if (slr->t_ref_count <= 0)
    {
      slr_free(slr);
    }
}

static void
marpa__slr_unref (Marpa_SLR slr)
{
   slr_unref(slr);
}

static SLR
slr_ref (SLR slr)
{
  /* MARPA_ASSERT(slr->t_ref_count > 0) */
  slr->t_ref_count++;
  return slr;
}

static Marpa_SLR
marpa__slr_ref (Marpa_SLR slr)
{
   return slr_ref(slr);
}

typedef int Marpa_Op;

struct op_data_s { const char *name; Marpa_Op op; };

static const char*
marpa__slif_op_name (Marpa_Op op_id)
{
  if (op_id >= (int)Dim(op_name_by_id_object)) return "unknown";
  return op_name_by_id_object[op_id];
}

static Marpa_Op
marpa__slif_op_id (const char *name)
{
  int lo = 0;
  int hi = Dim (op_by_name_object) - 1;
  while (hi >= lo)
    {
      const int trial = lo + (hi - lo) / 2;
      const char *trial_name = op_by_name_object[trial].name;
      int cmp = strcmp (name, trial_name);
      if (!cmp)
	return op_by_name_object[trial].op;
      if (cmp < 0)
	{
	  hi = trial - 1;
	}
      else
	{
	  lo = trial + 1;
	}
    }
  return -1;
}

struct per_codepoint_data_s {
    Marpa_Codepoint t_codepoint;
    Marpa_Op t_ops[1];
};

static int
cmp_per_codepoint_key( const void* a, const void* b, void* param )
{
    const Marpa_Codepoint codepoint_a = ((struct per_codepoint_data_s*)a)->t_codepoint;
    const Marpa_Codepoint codepoint_b = ((struct per_codepoint_data_s*)b)->t_codepoint;
    if (codepoint_a == codepoint_b) return 0;
    return codepoint_a < codepoint_b ? -1 : 1;
}

static void
per_codepoint_data_destroy(void *p, void* param )
{
    Safefree(p);
}

static void marpa__slr_event_clear( Marpa_SLR slr )
{
  MARPA_DSTACK_CLEAR (slr->t_event_dstack);
  slr->t_count_of_deleted_events = 0;
}

static int marpa__slr_event_count( Marpa_SLR slr )
{
  const int event_count = MARPA_DSTACK_LENGTH (slr->t_event_dstack);
  return event_count - slr->t_count_of_deleted_events;
}

static int marpa__slr_event_max_index( Marpa_SLR slr )
{
  return  MARPA_DSTACK_LENGTH (slr->t_event_dstack) - 1;
}

static union marpa_slr_event_s * marpa__slr_event_push( Marpa_SLR slr )
{
    return MARPA_DSTACK_PUSH(slr->t_event_dstack, union marpa_slr_event_s);
}

static union marpa_slr_event_s * marpa__slr_event_entry( Marpa_SLR slr, int i )
{
    return MARPA_DSTACK_INDEX (slr->t_event_dstack, union marpa_slr_event_s, i);
}

static void marpa__slr_lexeme_clear( Marpa_SLR slr )
{
  MARPA_DSTACK_CLEAR (slr->t_lexeme_dstack);
}

static int marpa__slr_lexeme_count( Marpa_SLR slr )
{
  return MARPA_DSTACK_LENGTH (slr->t_lexeme_dstack);
}

static union marpa_slr_event_s * marpa__slr_lexeme_push( Marpa_SLR slr )
{
    return MARPA_DSTACK_PUSH(slr->t_lexeme_dstack, union marpa_slr_event_s);
}

static union marpa_slr_event_s * marpa__slr_lexeme_entry( Marpa_SLR slr, int i )
{
    return MARPA_DSTACK_INDEX (slr->t_lexeme_dstack, union marpa_slr_event_s, i);
}

/* vim: expandtab shiftwidth=4:
*/
