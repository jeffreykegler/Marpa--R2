/*
 * Copyright 2014 Jeffrey Kegler
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

#include "config.h"
#include "marpa_slif.h"

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "ppport.h"

/* This kind of pointer comparison is not portable per C89,
 * but the Perl source depends on it throughout,
 * and there seems to be no other way to do it.
 */
#undef IS_PERL_UNDEF
#define IS_PERL_UNDEF(x) ((x) == &PL_sv_undef)

#undef MAX
#define MAX(a, b) ((a) > (b) ? (a) : (b))

/* utf8_to_uvchr is deprecated in 5.16, but
 * utf8_to_uvchr_buf is not available before 5.16
 * If I need to get fancier, I should look at Dumper.xs
 * in Data::Dumper
 */
#if PERL_VERSION <= 15 && ! defined(utf8_to_uvchr_buf)
#define utf8_to_uvchr_buf(s, send, p_length) (utf8_to_uvchr(s, p_length))
#endif

typedef SV* SVREF;

#undef Dim
#define Dim(x) (sizeof(x)/sizeof(*x))

typedef struct marpa_g Grammar;
/* The error_code member should usually be ignored in favor of
 * getting a fresh error code from Libmarpa.  Essentially it
 * acts as an optional return value for marpa_g_error()
 */
typedef struct {
     Marpa_Grammar g;
     char *message_buffer;
     int libmarpa_error_code;
     const char *libmarpa_error_string;
     unsigned int throw:1;
     unsigned int message_is_marpa_thin_error:1;
} G_Wrapper;

typedef struct marpa_r Recce;
typedef struct {
     Marpa_Recce r;
     Marpa_Symbol_ID* terminals_buffer;
     SV* base_sv;
     AV* event_queue;
     G_Wrapper* base;
     unsigned int ruby_slippers:1;
} R_Wrapper;

typedef struct {
    int next_offset; /* Offset of *NEXT* codepoint */
    int linecol;
    /* Lines are 1-based, columns are zero-based and negated.
     * In the first column (column 0), linecol is the 1-based line number.
     * In subsequenct columns, linecol is -n, where n is the 0-based column
     * number.
     */
} Pos_Entry;

#undef POS_TO_OFFSET
#define POS_TO_OFFSET(slr, pos) \
  ((pos) > 0 ? (slr)->pos_db[(pos) - 1].next_offset : 0)
#undef OFFSET_IN_INPUT
#define OFFSET_IN_INPUT(slr) POS_TO_OFFSET((slr), (slr)->perl_pos)

struct symbol_g_properties {
     int priority;
     unsigned int latm:1;
     unsigned int pause_before:1;
     unsigned int pause_after:1;
};

struct symbol_r_properties {
     unsigned int pause_before_active:1;
     unsigned int pause_after_active:1;
};

 /* Lexers are not visible at the Perl level --
  * for object ownership purposes they are simply components
  * of an SLG.  Ownership of objects is by SLG.
  */
typedef struct
{
  SV *g_sv;
  Marpa_Symbol_ID *lexer_rule_to_g1_lexeme;
  Marpa_Assertion_ID *g1_lexeme_to_assertion;
  HV *per_codepoint_hash;
  IV *per_codepoint_array[128];
 G_Wrapper* g_wrapper;
 int index; /* Index in the lexers array, for convenience */
} Lexer;

typedef struct {
     Lexer **lexers;
     int lexer_count;
     int lexer_buffer_size;
     SV* g1_sv;
     G_Wrapper* g1_wrapper;
     Marpa_Grammar g1;
    int precomputed;
    struct symbol_g_properties * symbol_g_properties;
} Scanless_G;

typedef struct
{
  SV *slg_sv;
  SV *r1_sv;

  /* |next_lexer| is to allow |current_lexer| to reflect the lexer that processed
   * the current input.  The switch takes place just before reading new input.
   */
  Lexer *next_lexer;
  Lexer *current_lexer;

  Scanless_G *slg;
  R_Wrapper *r1_wrapper;
  Marpa_Recce r1;
  G_Wrapper *g1_wrapper;
  AV *token_values;
  IV trace_lexers;
  int trace_terminals;
  STRLEN start_of_lexeme;
  STRLEN end_of_lexeme;

  /* Input position at which to start the lexer.
     -1 means no restart.
   */
  int lexer_start_pos;
  int lexer_read_result;
  int r1_earleme_complete_result;

  /* Make sure that, when we allow fallback_lexer to be changed, we do NOT
   * allow that to happen while we are "hitting" the same perl_pos repeatedly --
   * this to avoid infinite loops.
   */
  Lexer* fallback_lexer;
  int perl_pos_hits;
  int last_perl_pos;
  int perl_pos;

  Marpa_Recce r0;
  /* character position, taking into account Unicode
     Equivalent to Perl pos()
     One past last actual position indicates past-end-of-string
   */
  /* Position of problem -- unspecifed if not returning a problem */
  int problem_pos;
  int throw;
  int start_of_pause_lexeme;
  int end_of_pause_lexeme;
  Marpa_Symbol_ID pause_lexeme;
  struct symbol_r_properties *symbol_r_properties;
  Pos_Entry *pos_db;
  int pos_db_logical_size;
  int pos_db_physical_size;

  Marpa_Symbol_ID input_symbol_id;
  UV codepoint;                 /* For error returns */
  int end_pos;
  SV* input;
  int too_many_earley_items;

  /* A "Gift" because it is something that is "wrapped". */
  Marpa_SLR gift;

} Scanless_R;
#define TOKEN_VALUE_IS_UNDEF (1)
#define TOKEN_VALUE_IS_LITERAL (2)

typedef struct marpa_b Bocage;
typedef struct {
     Marpa_Bocage b;
     SV* base_sv;
     G_Wrapper* base;
} B_Wrapper;

typedef struct marpa_o Order;
typedef struct {
     Marpa_Order o;
     SV* base_sv;
     G_Wrapper* base;
} O_Wrapper;

typedef struct marpa_t Tree;
typedef struct {
     Marpa_Tree t;
     SV* base_sv;
     G_Wrapper* base;
} T_Wrapper;

typedef struct marpa_v Value;
typedef struct
{
  Marpa_Value v;
  SV *base_sv;
  G_Wrapper *base;
  AV *event_queue;
  AV *token_values;
  AV *stack;
  IV trace_values;
  int mode;                     /* 'raw' or 'stack' */
  int result;                   /* stack location to which to write result */
  AV *constants;
  AV *rule_semantics;
  AV *token_semantics;
  AV *nulling_semantics;
  Scanless_R* slr;
} V_Wrapper;

#define MARPA_XS_V_MODE_IS_INITIAL 0
#define MARPA_XS_V_MODE_IS_RAW 1
#define MARPA_XS_V_MODE_IS_STACK 2

static const char grammar_c_class_name[] = "Marpa::R2::Thin::G";
static const char recce_c_class_name[] = "Marpa::R2::Thin::R";
static const char bocage_c_class_name[] = "Marpa::R2::Thin::B";
static const char order_c_class_name[] = "Marpa::R2::Thin::O";
static const char tree_c_class_name[] = "Marpa::R2::Thin::T";
static const char value_c_class_name[] = "Marpa::R2::Thin::V";
static const char scanless_g_class_name[] = "Marpa::R2::Thin::SLG";
static const char scanless_r_class_name[] = "Marpa::R2::Thin::SLR";

static const char *
event_type_to_string (Marpa_Event_Type event_code)
{
  const char *event_name = NULL;
  if (event_code >= 0 && event_code < MARPA_ERROR_COUNT) {
      event_name = marpa_event_description[event_code].name;
  }
  return event_name;
}

static const char *
step_type_to_string (const Marpa_Step_Type step_type)
{
  const char *step_type_name = NULL;
  if (step_type >= 0 && step_type < MARPA_STEP_COUNT) {
      step_type_name = marpa_step_type_description[step_type].name;
  }
  return step_type_name;
}

/* This routine is for the handling exceptions
   from libmarpa.  It is used when in the general
   cases, for those exception which are not singled
   out for special handling by the XS logic.
   It returns a buffer which must be Safefree()'d.
*/
static char *
error_description_generate (G_Wrapper *g_wrapper)
{
  dTHX;
  const int error_code = g_wrapper->libmarpa_error_code;
  const char *error_string = g_wrapper->libmarpa_error_string;
  const char *suggested_description = NULL;
  /*
   * error_name should always be set when suggested_description is,
   * so this initialization should never be used.
   */
  const char *error_name = "not libmarpa error";
  const char *output_string;
  switch (error_code)
    {
    case MARPA_ERR_DEVELOPMENT:
      output_string = form ("(development) %s",
                              (error_string ? error_string : "(null)"));
                            goto COPY_STRING;
    case MARPA_ERR_INTERNAL:
      output_string = form ("Internal error (%s)",
                              (error_string ? error_string : "(null)"));
                            goto COPY_STRING;
    }
  if (error_code >= 0 && error_code < MARPA_ERROR_COUNT) {
      suggested_description = marpa_error_description[error_code].suggested;
      error_name = marpa_error_description[error_code].name;
  }
  if (!suggested_description)
    {
      if (error_string)
        {
          output_string = form ("libmarpa error %d %s: %s",
          error_code, error_name, error_string);
          goto COPY_STRING;
        }
      output_string = form ("libmarpa error %d %s", error_code, error_name);
          goto COPY_STRING;
    }
  if (error_string)
    {
      output_string = form ("%s%s%s", suggested_description, "; ", error_string);
          goto COPY_STRING;
    }
  output_string = suggested_description;
  COPY_STRING:
  {
      char* buffer = g_wrapper->message_buffer;
      if (buffer) Safefree(buffer);
      return g_wrapper->message_buffer = savepv(output_string);
    }
}

/* Argument must be something that can be Safefree()'d */
static const char *
set_error_from_string (G_Wrapper * g_wrapper, char *string)
{
  dTHX;
  Marpa_Grammar g = g_wrapper->g;
  char *buffer = g_wrapper->message_buffer;
  if (buffer) Safefree(buffer);
  g_wrapper->message_buffer = string;
  g_wrapper->message_is_marpa_thin_error = 1;
  marpa_g_error_clear(g);
  g_wrapper->libmarpa_error_code = MARPA_ERR_NONE;
  g_wrapper->libmarpa_error_string = NULL;
  return buffer;
}

/* Return value must be Safefree()'d */
static const char *
xs_g_error (G_Wrapper * g_wrapper)
{
  Marpa_Grammar g = g_wrapper->g;
  g_wrapper->libmarpa_error_code =
    marpa_g_error (g, &g_wrapper->libmarpa_error_string);
  g_wrapper->message_is_marpa_thin_error = 0;
  return error_description_generate (g_wrapper);
}

/* Wrapper to use vwarn with libmarpa */
static int marpa_r2_warn(const char* format, ...)
{
  dTHX;
   va_list args;
   va_start (args, format);
   vwarn (format, &args);
   va_end (args);
   return 1;
}

/* Static grammar methods */

#define SET_G_WRAPPER_FROM_G_SV(g_wrapper, g_sv) { \
    IV tmp = SvIV ((SV *) SvRV (g_sv)); \
    (g_wrapper) = INT2PTR (G_Wrapper *, tmp); \
}

/* Static recognizer methods */

#define SET_R_WRAPPER_FROM_R_SV(r_wrapper, r_sv) { \
    IV tmp = SvIV ((SV *) SvRV (r_sv)); \
    (r_wrapper) = INT2PTR (R_Wrapper *, tmp); \
}

/* Maybe inline some of these */

/* Assumes caller has checked that g_sv is blessed into right type.
   Assumes caller holds a ref to the recce.
*/
static R_Wrapper*
r_wrap( Marpa_Recce r, SV* g_sv)
{
  dTHX;
  int highest_symbol_id;
  R_Wrapper *r_wrapper;
  G_Wrapper *g_wrapper;
  Marpa_Grammar g;

  SET_G_WRAPPER_FROM_G_SV(g_wrapper, g_sv);
  g = g_wrapper->g;

  highest_symbol_id = marpa_g_highest_symbol_id (g);
  if (highest_symbol_id < 0)
    {
      if (!g_wrapper->throw)
        {
          return 0;
        }
      croak ("failure in marpa_g_highest_symbol_id: %s",
             xs_g_error (g_wrapper));
    };
  Newx (r_wrapper, 1, R_Wrapper);
  r_wrapper->r = r;
  Newx (r_wrapper->terminals_buffer, highest_symbol_id + 1, Marpa_Symbol_ID);
  r_wrapper->ruby_slippers = 0;
  SvREFCNT_inc (g_sv);
  r_wrapper->base_sv = g_sv;
  r_wrapper->base = g_wrapper;
  r_wrapper->event_queue = newAV();
  return r_wrapper;
}

/* It is up to the caller to deal with the Libmarpa recce's
 * reference count
 */
static Marpa_Recce
r_unwrap (R_Wrapper * r_wrapper)
{
  dTHX;
  Marpa_Recce r = r_wrapper->r;
  /* The wrapper should always have had a ref to its base grammar's SV */
  SvREFCNT_dec (r_wrapper->base_sv);
  SvREFCNT_dec ((SV *) r_wrapper->event_queue);
  Safefree (r_wrapper->terminals_buffer);
  Safefree (r_wrapper);
  /* The wrapper should always have had a ref to the Libmarpa recce */
  return r;
}

/* Static Lexer methods */

/* The caller must ensure that g_sv is an SV of the correct type */
static Lexer* lexer_add(Scanless_G* slg, SV* g_sv)
{
  dTHX;
  Lexer *lexer;
  G_Wrapper *g_wrapper;
  unsigned i;
  int rule_ix;
  Marpa_Rule_ID lexer_rule_count;
  int lexer_count = slg->lexer_count;
  int lexer_buffer_size = slg->lexer_buffer_size;

  Newx (lexer, 1, Lexer);
  lexer->g_sv = g_sv;
  lexer->per_codepoint_hash = newHV ();
  lexer->index = slg->lexer_count++;
  for (i = 0; i < Dim (lexer->per_codepoint_array); i++)
    {
      lexer->per_codepoint_array[i] = NULL;
    }
  SET_G_WRAPPER_FROM_G_SV (g_wrapper, g_sv);
  lexer->g_wrapper = g_wrapper;
  lexer_rule_count = marpa_g_highest_rule_id (g_wrapper->g) + 1;
  Newx (lexer->lexer_rule_to_g1_lexeme, lexer_rule_count, Marpa_Symbol_ID);
  for (rule_ix = 0; rule_ix < lexer_rule_count; rule_ix++)
    {
      lexer->lexer_rule_to_g1_lexeme[rule_ix] = -1;
    }
  {
    int symbol_ix;
    int g1_symbol_count =
      marpa_g_highest_symbol_id ( slg->g1 ) + 1;
    Newx (lexer->g1_lexeme_to_assertion, g1_symbol_count,
	  Marpa_Assertion_ID);
    for (symbol_ix = 0; symbol_ix < g1_symbol_count;
	 symbol_ix++)
      {
	lexer->g1_lexeme_to_assertion[symbol_ix] = -1;
      }
  }
  SvREFCNT_inc (g_sv);
  if (lexer_count >= lexer_buffer_size)
    {
      lexer_buffer_size = slg->lexer_buffer_size *= 2;
      Renew (slg->lexers, lexer_buffer_size, Lexer *);
    }
  slg->lexers[lexer->index] = lexer;
  return lexer;
}

static void lexer_destroy(Lexer *lexer)
{
  dTHX;
  unsigned i;
  Safefree (lexer->lexer_rule_to_g1_lexeme);
  Safefree (lexer->g1_lexeme_to_assertion);
  SvREFCNT_dec (lexer->per_codepoint_hash);
  for (i = 0; i < Dim(lexer->per_codepoint_array); i++) {
    Safefree(lexer->per_codepoint_array[i]);
  }
  SvREFCNT_dec (lexer->g_sv);
  Safefree(lexer);
}

/* Static lexer methods */

static void
u_r0_clear (Scanless_R * slr)
{
  dTHX;
  Marpa_Recce r0 = slr->r0;
  if (!r0)
    return;
  marpa_r_unref (r0);
  slr->r0 = NULL;
}

static Marpa_Recce
u_r0_new (Scanless_R * slr)
{
  dTHX;
  Marpa_Recce r0 = slr->r0;
  const IV trace_lexers = slr->trace_lexers;
  Lexer *lexer = slr->current_lexer;
  G_Wrapper *lexer_wrapper = lexer->g_wrapper;
  const int too_many_earley_items = slr->too_many_earley_items;

  if (r0)
    {
      marpa_r_unref (r0);
    }
  slr->r0 = r0 = marpa_r_new (lexer_wrapper->g);
  if (!r0)
    {
      if (!lexer_wrapper->throw)
	return 0;
      croak ("failure in marpa_r_new(): %s", xs_g_error (lexer_wrapper));
    };
  if (too_many_earley_items >= 0)
    {
      marpa_r_earley_item_warning_threshold_set (r0, too_many_earley_items);
    }
  {
    int i;
    Marpa_Symbol_ID *terminals_buffer = slr->r1_wrapper->terminals_buffer;
    const int count = marpa_r_terminals_expected (slr->r1, terminals_buffer);
    if (count < 0)
      {
	croak ("Problem in u_read() with terminals_expected: %s",
	       xs_g_error (slr->g1_wrapper));
      }
    for (i = 0; i < count; i++)
      {
	const Marpa_Symbol_ID terminal = terminals_buffer[i];
	const Marpa_Assertion_ID assertion =
	  lexer->g1_lexeme_to_assertion[terminal];
	if (assertion >= 0 && marpa_r_zwa_default_set (r0, assertion, 1) < 0)
	  {
	    croak
	      ("Problem in u_read() with assertion ID %ld and lexeme ID %ld: %s",
	       (long) assertion, (long) terminal,
	       xs_g_error (slr->current_lexer->g_wrapper));
	  }
	if (trace_lexers >= 1)
	  {
	    union marpa_slr_event_s *event =
	      marpa__slr_event_push (slr->gift);
	    MARPA_SLREV_TYPE (event) = MARPA_SLRTR_LEXEME_EXPECTED;
	    event->t_trace_lexeme_expected.t_perl_pos = slr->perl_pos;
	    event->t_trace_lexeme_expected.t_current_lexer_ix =
	      slr->current_lexer->index;
	    event->t_trace_lexeme_expected.t_lexeme = terminal;
	    event->t_trace_lexeme_expected.t_assertion = assertion;
	  }

      }
  }
  {
    int gp_result = marpa_r_start_input (r0);
    if (gp_result == -1)
      return 0;
    if (gp_result < 0)
      {
	if (lexer_wrapper->throw)
	  {
	    croak ("Problem in r->start_input(): %s",
		   xs_g_error (lexer_wrapper));
	  }
	return 0;
      }
  }
  return r0;
}

/* Assumes it is called
 after a successful marpa_r_earleme_complete()
 */
static void
u_convert_events (Scanless_R * slr)
{
  dTHX;
  int event_ix;
  Marpa_Grammar g = slr->current_lexer->g_wrapper->g;
  const int event_count = marpa_g_event_count (g);
  for (event_ix = 0; event_ix < event_count; event_ix++)
    {
      Marpa_Event marpa_event;
      Marpa_Event_Type event_type =
        marpa_g_event (g, &marpa_event, event_ix);
      switch (event_type)
        {
          {
        case MARPA_EVENT_EXHAUSTED:
            /* Do nothing about exhaustion on success */
            break;
        case MARPA_EVENT_EARLEY_ITEM_THRESHOLD:
            /* All events are ignored on failure
             * On success, all except MARPA_EVENT_EARLEY_ITEM_THRESHOLD
             * are ignored.
             *
             * The warning raised for MARPA_EVENT_EARLEY_ITEM_THRESHOLD 
             * can be turned off by raising
             * the Earley item warning threshold.
             */
            {
              warn
                ("Marpa: lexer Earley item count (%ld) exceeds warning threshold",
                 (long) marpa_g_event_value (&marpa_event));
            }
            break;
        default:
            {
              const char *result_string = event_type_to_string (event_type);
              if (result_string)
                {
                  croak ("unexpected lexer grammar event: %s",
                         result_string);
                }
              croak ("lexer grammar event with unknown event code, %d",
                     event_type);
            }
            break;
          }
        }
    }
}

#define U_READ_OK 0
#define U_READ_REJECTED_CHAR -1
#define U_READ_UNREGISTERED_CHAR -2
#define U_READ_EXHAUSTED_ON_FAILURE -3
#define U_READ_TRACING -4
#define U_READ_EXHAUSTED_ON_SUCCESS -5
#define U_READ_INVALID_CHAR -6

/* Return values:
 * 1 or greater: reserved for an event count, to deal with multiple events
 *   when and if necessary
 * 0: success: a full reading of the input, with nothing to report.
 * -1: a character was rejected
 * -2: an unregistered character was found
 * -3: earleme_complete() reported an exhausted parse on failure
 * -4: we are tracing, character by character
 * -5: earleme_complete() reported an exhausted parse on success
 */
static int
u_read (Scanless_R * slr)
{
  dTHX;
  U8 *input;
  STRLEN len;
  int input_is_utf8;

  const IV trace_lexers = slr->trace_lexers;
  Lexer *lexer = slr->current_lexer;
  Marpa_Recognizer r = slr->r0;

  if (!r)
    {
      r = u_r0_new (slr);
      if (!r)
        croak ("Problem in u_read(): %s",
               xs_g_error (slr->current_lexer->g_wrapper));
    }
  input_is_utf8 = SvUTF8 (slr->input);
  input = (U8 *) SvPV (slr->input, len);
  for (;;)
    {
      UV codepoint;
      STRLEN codepoint_length = 1;
      STRLEN op_ix;
      STRLEN op_count;
      IV *ops;
      int tokens_accepted = 0;
      if (slr->perl_pos >= slr->end_pos)
        break;

      if (input_is_utf8)
        {

          codepoint =
            utf8_to_uvchr_buf (input + OFFSET_IN_INPUT (slr),
                               input + len, &codepoint_length);

          /* Perl API documents that return value is 0 and length is -1 on error,
           * "if possible".  length can be, and is, in fact unsigned.
           * I deal with this by noting that 0 is a valid UTF8 char but should
           * have a length of 1, when valid.
           */
          if (codepoint == 0 && codepoint_length != 1)
            {
              croak ("Problem in r->read_string(): invalid UTF8 character");
            }
        }
      else
        {
          codepoint = (UV) input[OFFSET_IN_INPUT (slr)];
          codepoint_length = 1;
        }

      if (codepoint < Dim (lexer->per_codepoint_array))
        {
          ops = lexer->per_codepoint_array[codepoint];
          if (!ops)
            {
              slr->codepoint = codepoint;
              return U_READ_UNREGISTERED_CHAR;
            }
        }
      else
        {
          STRLEN dummy;
          SV **p_ops_sv =
            hv_fetch (lexer->per_codepoint_hash, (char *) &codepoint,
                      (I32) sizeof (codepoint), 0);
          if (!p_ops_sv)
            {
              slr->codepoint = codepoint;
              return U_READ_UNREGISTERED_CHAR;
            }
          ops = (IV *) SvPV (*p_ops_sv, dummy);
        }

if (trace_lexers >= 1)
  {
    union marpa_slr_event_s *event = marpa__slr_event_push(slr->gift);
    MARPA_SLREV_TYPE(event) = MARPA_SLRTR_CODEPOINT_READ;
    event->t_trace_codepoint_read.t_codepoint = codepoint;
    event->t_trace_codepoint_read.t_perl_pos = slr->perl_pos;
    event->t_trace_codepoint_read.t_current_lexer_ix =
      slr->current_lexer->index;
  }

      /* ops[0] is codepoint */
      op_count = ops[1];
      for (op_ix = 2; op_ix < op_count; op_ix++)
        {
          IV op_code = ops[op_ix];
          switch (op_code)
            {
            case MARPA_OP_ALTERNATIVE:
              {
                int result;
                int symbol_id;
                int length;
                int value;

                op_ix++;
                if (op_ix >= op_count)
                  {
                    croak
                      ("Missing operand for op code (0x%lx); codepoint=0x%lx, op_ix=0x%lx",
                       (unsigned long) op_code, (unsigned long) codepoint,
                       (unsigned long) op_ix);
                  }
                symbol_id = (int) ops[op_ix];
                if (op_ix + 2 >= op_count)
                  {
                    croak
                      ("Missing operand for op code (0x%lx); codepoint=0x%lx, op_ix=0x%lx",
                       (unsigned long) op_code, (unsigned long) codepoint,
                       (unsigned long) op_ix);
                  }
                value = (int) ops[++op_ix];
                length = (int) ops[++op_ix];
                result = marpa_r_alternative (r, symbol_id, value, length);
                switch (result)
                  {
                  case MARPA_ERR_UNEXPECTED_TOKEN_ID:
                    /* This guarantees that later, if we fall below
                     * the minimum number of tokens accepted,
                     * we have one of them as an example
                     */
                    slr->input_symbol_id = symbol_id;
                    if (trace_lexers >= 1)
                      {
                        union marpa_slr_event_s *slr_event = marpa__slr_event_push(slr->gift);
                        MARPA_SLREV_TYPE(slr_event) = MARPA_SLRTR_CODEPOINT_REJECTED;
                        slr_event->t_trace_codepoint_rejected.t_codepoint = codepoint;
                        slr_event->t_trace_codepoint_rejected.t_perl_pos = slr->perl_pos;
                        slr_event->t_trace_codepoint_rejected.t_symbol_id = symbol_id;
                        slr_event->t_trace_codepoint_rejected.t_current_lexer_ix = slr->current_lexer->index;
                      }
                    break;
                  case MARPA_ERR_NONE:
                    if (trace_lexers >= 1)
                      {
                        union marpa_slr_event_s *slr_event = marpa__slr_event_push(slr->gift);
                        MARPA_SLREV_TYPE(slr_event) = MARPA_SLRTR_CODEPOINT_ACCEPTED;
                        slr_event->t_trace_codepoint_accepted.t_codepoint = codepoint;
                        slr_event->t_trace_codepoint_accepted.t_perl_pos = slr->perl_pos;
                        slr_event->t_trace_codepoint_accepted.t_symbol_id = symbol_id;
                        slr_event->t_trace_codepoint_accepted.t_current_lexer_ix = slr->current_lexer->index;
                      }
                    tokens_accepted++;
                    break;
                  default:
                    slr->codepoint = codepoint;
                    slr->input_symbol_id = symbol_id;
                    croak
                      ("Problem alternative() failed at char ix %ld; symbol id %ld; codepoint 0x%lx value %ld\n"
                       "Problem in u_read(), alternative() failed: %s",
                       (long) slr->perl_pos, (long) symbol_id,
                       (unsigned long) codepoint,
                       (long) value,
                       xs_g_error (slr->current_lexer->g_wrapper));
                  }
              }
              break;

            case MARPA_OP_INVALID_CHAR:
              slr->codepoint = codepoint;
              return U_READ_INVALID_CHAR;

            case MARPA_OP_EARLEME_COMPLETE:
              {
                int result;
                if (tokens_accepted < 1)
                  {
                    slr->codepoint = codepoint;
                    return U_READ_REJECTED_CHAR;
                  }
                result = marpa_r_earleme_complete (r);
                if (result > 0)
                  {
                    u_convert_events (slr);
                    /* Advance one character before returning */
                    if (marpa_r_is_exhausted (r))
                      {
                        return U_READ_EXHAUSTED_ON_SUCCESS;
                      }
                    goto ADVANCE_ONE_CHAR;
                  }
                if (result == -2)
                  {
                    const Marpa_Error_Code error =
                      marpa_g_error (slr->current_lexer->g_wrapper->g, NULL);
                    if (error == MARPA_ERR_PARSE_EXHAUSTED)
                      {
                        return U_READ_EXHAUSTED_ON_FAILURE;
                      }
                  }
                if (result < 0)
                  {
                    croak
                      ("Problem in r->u_read(), earleme_complete() failed: %s",
                       xs_g_error (slr->current_lexer->g_wrapper));
                  }
              }
              break;
            default:
              croak ("Unknown op code (0x%lx); codepoint=0x%lx, op_ix=0x%lx",
                     (unsigned long) op_code, (unsigned long) codepoint,
                     (unsigned long) op_ix);
            }
        }
    ADVANCE_ONE_CHAR:;
      slr->perl_pos++;
      if (trace_lexers)
        {
          return U_READ_TRACING;
        }
    }
  return U_READ_OK;
}

/* It is OK to set pos to last codepoint + 1 */
static STRLEN
u_pos_set (Scanless_R * slr, const char* name, int start_pos_arg, int length_arg)
{
  dTHX;
  const STRLEN old_perl_pos = slr->perl_pos;
  const STRLEN input_length = slr->pos_db_logical_size;
  int new_perl_pos;
  int new_end_pos;

  if (start_pos_arg < 0) {
      new_perl_pos = input_length + start_pos_arg;
  } else {
      new_perl_pos = start_pos_arg;
  }
  if (new_perl_pos < 0 || new_perl_pos > slr->pos_db_logical_size)
  {
      croak ("Bad start position in %s(): %ld", name, (long)start_pos_arg);
  }

  if (length_arg < 0) {
      new_end_pos = input_length + length_arg + 1;
  } else {
    new_end_pos = new_perl_pos + length_arg;
  }
  if (new_end_pos < 0 || new_end_pos > slr->pos_db_logical_size)
  {
      croak ("Bad length in %s(): %ld", name, (long)length_arg);
  }

  /* Application level intervention resets |perl_pos| */
  slr->last_perl_pos = -1;
  new_perl_pos = new_perl_pos;
  slr->perl_pos = new_perl_pos;
  new_end_pos = new_end_pos;
  slr->end_pos = new_end_pos;
  return old_perl_pos;
}

static SV *
u_pos_span_to_literal_sv (Scanless_R * slr,
                          int start_pos, int length_in_positions)
{
  dTHX;
  STRLEN dummy;
  char *input = SvPV (slr->input, dummy);
  SV* new_sv;
  int start_offset = POS_TO_OFFSET (slr, start_pos);
  int length_in_bytes =
    POS_TO_OFFSET (slr,
                   start_pos + length_in_positions) - start_offset;
  new_sv = newSVpvn (input + start_offset, length_in_bytes);
  if (SvUTF8(slr->input)) {
     SvUTF8_on(new_sv);
  }
  return new_sv;
}

static SV*
u_substring (Scanless_R * slr, const char *name, int start_pos_arg,
             int length_arg)
{
  dTHX;
  int start_pos;
  int end_pos;
  const int input_length = slr->pos_db_logical_size;
  int substring_length;

  start_pos =
    start_pos_arg < 0 ? input_length + start_pos_arg : start_pos_arg;
  if (start_pos < 0 || start_pos > input_length)
    {
      croak ("Bad start position in %s: %ld", name, (long) start_pos_arg);
    }

  end_pos =
    length_arg < 0 ? input_length + length_arg + 1 : start_pos + length_arg;
  if (end_pos < 0 || end_pos > input_length)
    {
      croak ("Bad length in %s: %ld", name, (long) length_arg);
    }
  substring_length = end_pos - start_pos;
  return u_pos_span_to_literal_sv (slr, start_pos, substring_length);
}

/* Static valuator methods */

/* Return -1 on failure due to wrong mode */
static IV
v_create_stack(V_Wrapper* v_wrapper)
{
  dTHX;
  if (v_wrapper->mode == MARPA_XS_V_MODE_IS_RAW)
    {
      return -1;
    }
  v_wrapper->stack = newAV ();
  av_extend (v_wrapper->stack, 1023);
  v_wrapper->mode = MARPA_XS_V_MODE_IS_STACK;
  return 0;
}

static void slr_es_to_span (Scanless_R * slr, Marpa_Earley_Set_ID earley_set,
                           int *p_start, int *p_length);
static void
slr_es_to_literal_span (Scanless_R * slr,
                        Marpa_Earley_Set_ID start_earley_set, int length,
                        int *p_start, int *p_length);
static SV*
slr_es_span_to_literal_sv (Scanless_R * slr,
                        Marpa_Earley_Set_ID start_earley_set, int length);

static int
v_do_stack_ops (V_Wrapper * v_wrapper, SV ** stack_results)
{
  dTHX;
  AV *stack = v_wrapper->stack;
  const Marpa_Value v = v_wrapper->v;
  const Marpa_Step_Type step_type = marpa_v_step_type (v);
  IV result_ix = marpa_v_result (v);
  IV *ops;
  int op_ix;
  UV blessing = 0;

  /* values_av is created when needed.
   * It is created mortal, so it automatically goes
   * away unless it is de-mortalized.
   */
  AV *values_av = NULL;

  v_wrapper->result = result_ix;

  switch (step_type)
    {
      STRLEN dummy;
    case MARPA_STEP_RULE:
      {
        SV **p_ops_sv =
          av_fetch (v_wrapper->rule_semantics, marpa_v_rule (v), 0);
        if (!p_ops_sv)
          {
            croak ("Problem in v->stack_step: rule %d is not registered",
                   marpa_v_rule (v));
          }
        ops = (IV *) SvPV (*p_ops_sv, dummy);
      }
      break;
    case MARPA_STEP_TOKEN:
      {
        SV **p_ops_sv =
          av_fetch (v_wrapper->token_semantics, marpa_v_token (v), 0);
        if (!p_ops_sv)
          {
            croak ("Problem in v->stack_step: token %d is not registered",
                   marpa_v_token (v));
          }
        ops = (IV *) SvPV (*p_ops_sv, dummy);
      }
      break;
    case MARPA_STEP_NULLING_SYMBOL:
      {
        SV **p_ops_sv =
          av_fetch (v_wrapper->nulling_semantics, marpa_v_token (v), 0);
        if (!p_ops_sv)
          {
            croak
              ("Problem in v->stack_step: nulling symbol %d is not registered",
               marpa_v_token (v));
          }
        ops = (IV *) SvPV (*p_ops_sv, dummy);
      }
      break;
    default:
      /* Never reached -- turns off warning about uninitialized ops */
      ops = NULL;
    }

  op_ix = 0;
  while (1)
    {
      IV op_code = ops[op_ix++];

      if (v_wrapper->trace_values >= 3)
        {
          AV *event;
          SV *event_data[3];
          const char *result_string = step_type_to_string (step_type);
          if (!result_string)
            result_string = "valuator unknown step";
          event_data[0] = newSVpvs ("starting op");
          event_data[1] = newSVpv (result_string, 0);
          event_data[2] = newSVpv (marpa__slif_op_name (op_code), 0);
          event = av_make (Dim (event_data), event_data);
          av_push (v_wrapper->event_queue, newRV_noinc ((SV *) event));
        }

      switch (op_code)
        {

        case 0:
          return -1;

        case MARPA_OP_RESULT_IS_UNDEF:
          {
            av_fill (stack, -1 + result_ix);
          }
          return -1;

        case MARPA_OP_RESULT_IS_CONSTANT:
          {
            IV constant_ix = ops[op_ix++];
            SV **p_constant_sv;

            p_constant_sv = av_fetch (v_wrapper->constants, constant_ix, 0);
            if (p_constant_sv)
              {
                SV *constant_sv = newSVsv (*p_constant_sv);
                SV **stored_sv = av_store (stack, result_ix, constant_sv);
                if (!stored_sv)
                  {
                    SvREFCNT_dec (constant_sv);
                  }
              }
            else
              {
                av_store (stack, result_ix, &PL_sv_undef);
              }

            if (v_wrapper->trace_values && step_type == MARPA_STEP_TOKEN)
              {
                AV *event;
                SV *event_data[3];
                const char *result_string = step_type_to_string (step_type);
                if (!result_string)
                  result_string = "valuator unknown step";
                event_data[0] = newSVpvn (result_string, 0);
                event_data[1] = newSViv (marpa_v_token (v));
                event_data[2] = newSViv (result_ix);
                event = av_make (Dim (event_data), event_data);
                av_push (v_wrapper->event_queue, newRV_noinc ((SV *) event));
              }
          }
          return -1;

        case MARPA_OP_RESULT_IS_RHS_N:
        case MARPA_OP_RESULT_IS_N_OF_SEQUENCE:
          {
            SV **stored_av;
            SV **p_sv;
            IV stack_offset = ops[op_ix++];
            IV fetch_ix;

            if (step_type != MARPA_STEP_RULE)
              {
                av_fill (stack, result_ix - 1);
                return -1;
              }
            if (stack_offset == 0)
              {
                /* Special-cased for 4 reasons --
                 * it's common, it's reference count handling is
                 * a special case and it can be easily and highly optimized.
                 */
                av_fill (stack, result_ix);
                return -1;
              }

            /* Determine index of SV to fetch */
            if (op_code == MARPA_OP_RESULT_IS_RHS_N)
              {
                if (stack_offset > 0)
                  {
                    fetch_ix = result_ix + stack_offset;
                  }
                else
                  {
                    fetch_ix = marpa_v_arg_n (v) + 1 - stack_offset;
                  }
              }
            else
              {                 /* sequence */
                int item_ix;
                if (stack_offset >= 0)
                  {
                    item_ix = stack_offset;
                  }
                else
                  {
                    int item_count =
                      (marpa_v_arg_n (v) - marpa_v_arg_0 (v)) / 2 + 1;
                    item_ix = (item_count + stack_offset);
                  }
                fetch_ix = result_ix + item_ix * 2;
              }

            /* Bounds check fetch ix */
            if (fetch_ix > marpa_v_arg_n (v) || fetch_ix < result_ix)
              {
                /* return an undef */
                av_fill (stack, result_ix - 1);
                return -1;
              }
            p_sv = av_fetch (stack, fetch_ix, 0);
            if (!p_sv)
              {
                av_fill (stack, result_ix - 1);
                return -1;
              }
            stored_av = av_store (stack, result_ix, SvREFCNT_inc_NN (*p_sv));
            if (!stored_av)
              {
                SvREFCNT_dec (*p_sv);
                av_fill (stack, result_ix - 1);
                return -1;
              }
            av_fill (stack, result_ix);
          }
          return -1;

        case MARPA_OP_RESULT_IS_ARRAY:
          {
            SV **stored_av;
            /* Increment ref count of values_av to de-mortalize it */
            SV *ref_to_values_av;

            if (!values_av)
              {
                values_av = (AV *) sv_2mortal ((SV *) newAV ());
              }
            ref_to_values_av = newRV_inc ((SV *) values_av);
            if (blessing)
              {
                SV **p_blessing_sv =
                  av_fetch (v_wrapper->constants, blessing, 0);
                if (p_blessing_sv && SvPOK (*p_blessing_sv))
                  {
                    STRLEN blessing_length;
                    char *classname = SvPV (*p_blessing_sv, blessing_length);
                    sv_bless (ref_to_values_av, gv_stashpv (classname, 1));
                  }
              }
            stored_av = av_store (stack, result_ix, ref_to_values_av);

            /* If the new RV did not get stored properly,
             * decrement its ref count
             */
            if (!stored_av)
              {
                SvREFCNT_dec (ref_to_values_av);
                av_fill (stack, result_ix - 1);
                return -1;
              }
            av_fill (stack, result_ix);
          }
          return -1;

        case MARPA_OP_PUSH_VALUES:
        case MARPA_OP_PUSH_SEQUENCE:
          {

            if (!values_av)
              {
                values_av = (AV *) sv_2mortal ((SV *) newAV ());
              }

            switch (step_type)
              {
              case MARPA_STEP_TOKEN:
                {
                  SV **p_token_value_sv;
                  int token_ix = marpa_v_token_value (v);
                  Scanless_R *slr = v_wrapper->slr;
                  if (slr && token_ix == TOKEN_VALUE_IS_LITERAL)
                    {
                      SV *sv;
                      Marpa_Earley_Set_ID start_earley_set =
                        marpa_v_token_start_es_id (v);
                      Marpa_Earley_Set_ID end_earley_set = marpa_v_es_id (v);
                      sv =
                        slr_es_span_to_literal_sv (slr, start_earley_set,
                                                   end_earley_set -
                                                   start_earley_set);
                      av_push (values_av, sv);
                      break;
                    }
                  /* If token value is NOT literal */
                  p_token_value_sv = av_fetch (v_wrapper->token_values, (I32) token_ix, 0);
                  if (p_token_value_sv)
                    {
                      av_push (values_av,
                               SvREFCNT_inc_NN (*p_token_value_sv));
                    }
                  else
                    {
                      av_push (values_av, &PL_sv_undef);
                    }
                }
                break;

              case MARPA_STEP_RULE:
                {
                  int stack_ix;
                  const int arg_n = marpa_v_arg_n (v);
                  int increment = op_code == MARPA_OP_PUSH_SEQUENCE ? 2 : 1;

                  for (stack_ix = result_ix; stack_ix <= arg_n;
                       stack_ix += increment)
                    {
                      SV **p_sv = av_fetch (stack, stack_ix, 0);
                      if (!p_sv)
                        {
                          av_push (values_av, &PL_sv_undef);
                        }
                      else
                        {
                          av_push (values_av, SvREFCNT_inc_simple_NN (*p_sv));
                        }
                    }
                }
                break;

              default:
              case MARPA_STEP_NULLING_SYMBOL:
                /* A no-op : push nothing */
                break;
              }
          }
          break;

        case MARPA_OP_PUSH_UNDEF:
          {
            if (!values_av)
              {
                values_av = (AV *) sv_2mortal ((SV *) newAV ());
              }
            av_push (values_av, &PL_sv_undef);
          }
          goto NEXT_OP_CODE;

        case MARPA_OP_PUSH_CONSTANT:
          {
            IV constant_ix = ops[op_ix++];
            SV **p_constant_sv;

            if (!values_av)
              {
                values_av = (AV *) sv_2mortal ((SV *) newAV ());
              }
            p_constant_sv = av_fetch (v_wrapper->constants, constant_ix, 0);
            if (p_constant_sv)
              {
                av_push (values_av, SvREFCNT_inc_simple_NN (*p_constant_sv));
              }
            else
              {
                av_push (values_av, &PL_sv_undef);
              }

          }
          goto NEXT_OP_CODE;

        case MARPA_OP_PUSH_ONE:
          {
            int offset;
            SV **p_sv;

            offset = ops[op_ix++];
            if (!values_av)
              {
                values_av = (AV *) sv_2mortal ((SV *) newAV ());
              }
            if (step_type != MARPA_STEP_RULE)
              {
                av_push (values_av, &PL_sv_undef);
                goto NEXT_OP_CODE;
              }
            p_sv = av_fetch (stack, result_ix + offset, 0);
            if (!p_sv)
              {
                av_push (values_av, &PL_sv_undef);
              }
            else
              {
                av_push (values_av, SvREFCNT_inc_simple_NN (*p_sv));
              }
          }
          goto NEXT_OP_CODE;

        case MARPA_OP_PUSH_START_LOCATION:
          {
            int start_location;
            Scanless_R *slr = v_wrapper->slr;
            Marpa_Earley_Set_ID start_earley_set;
            int dummy;

            if (!values_av)
              {
                values_av = (AV *) sv_2mortal ((SV *) newAV ());
              }
            if (!slr)
              {
                croak
                  ("Problem in v->stack_step: 'push_start_location' op attempted when no slr is set");
              }
            switch (step_type)
              {
              case MARPA_STEP_RULE:
                start_earley_set = marpa_v_rule_start_es_id (v);
                break;
              case MARPA_STEP_NULLING_SYMBOL:
              case MARPA_STEP_TOKEN:
                start_earley_set = marpa_v_token_start_es_id (v);
                break;
              default:
                croak
                  ("Problem in v->stack_step: Range requested for improper step type: %s",
                   step_type_to_string (step_type));
              }
            slr_es_to_literal_span (slr, start_earley_set, 0, &start_location,
                                    &dummy);
            av_push (values_av, newSViv ((IV) start_location));
          }
          goto NEXT_OP_CODE;

        case MARPA_OP_PUSH_LENGTH:
          {
            int length;
            Scanless_R *slr = v_wrapper->slr;

            if (!values_av)
              {
                values_av = (AV *) sv_2mortal ((SV *) newAV ());
              }
            if (!slr)
              {
                croak
                  ("Problem in v->stack_step: 'push_length' op attempted when no slr is set");
              }
            switch (step_type)
              {
              case MARPA_STEP_NULLING_SYMBOL:
                length = 0;
                break;
              case MARPA_STEP_RULE:
                {
                  int dummy;
                  Marpa_Earley_Set_ID start_earley_set =
                    marpa_v_rule_start_es_id (v);
                  Marpa_Earley_Set_ID end_earley_set = marpa_v_es_id (v);
                  slr_es_to_literal_span (slr, start_earley_set,
                                          end_earley_set - start_earley_set,
                                          &dummy, &length);
                }
                break;
              case MARPA_STEP_TOKEN:
                {
                  int dummy;
                  Marpa_Earley_Set_ID start_earley_set =
                    marpa_v_token_start_es_id (v);
                  Marpa_Earley_Set_ID end_earley_set = marpa_v_es_id (v);
                  slr_es_to_literal_span (slr, start_earley_set,
                                          end_earley_set - start_earley_set,
                                          &dummy, &length);
                }
                break;
              default:
                croak
                  ("Problem in v->stack_step: Range requested for improper step type: %s",
                   step_type_to_string (step_type));
              }
            av_push (values_av, newSViv ((IV) length));
          }
          goto NEXT_OP_CODE;

        case MARPA_OP_BLESS:
          {
            blessing = ops[op_ix++];
          }
          goto NEXT_OP_CODE;

        case MARPA_OP_CALLBACK:
          {
            const char *result_string = step_type_to_string (step_type);
            SV **p_stack_results = stack_results;

            switch (step_type)
              {
              case MARPA_STEP_RULE:
                /* For rules, create an array if we don't have one.
                 * It is expected to be mortal.
                 */
                if (!values_av)
                  {
                    values_av = (AV *) sv_2mortal ((SV *) newAV ());
                  }
                break;
              case MARPA_STEP_NULLING_SYMBOL:
                break;
              default:
                goto BAD_OP;
              }

            *p_stack_results++ = sv_2mortal (newSVpv (result_string, 0));
            *p_stack_results++ =
              sv_2mortal (newSViv
                          (step_type ==
                           MARPA_STEP_RULE ? marpa_v_rule (v) :
                           marpa_v_token (v)));

            if (values_av)
              {
                /* De-mortalize av_values */
                SV *ref_to_values_av =
                  sv_2mortal (newRV_inc ((SV *) values_av));
                if (blessing)
                  {
                    SV **p_blessing_sv =
                      av_fetch (v_wrapper->constants, blessing, 0);
                    if (p_blessing_sv && SvPOK (*p_blessing_sv))
                      {
                        STRLEN blessing_length;
                        char *classname =
                          SvPV (*p_blessing_sv, blessing_length);
                        sv_bless (ref_to_values_av,
                                  gv_stashpv (classname, 1));
                      }
                  }
                *p_stack_results++ = ref_to_values_av;
              }
            return p_stack_results - stack_results;
          }
          /* NOT REACHED */

        case MARPA_OP_RESULT_IS_TOKEN_VALUE:
          {
            SV **p_token_value_sv;
            Scanless_R *slr = v_wrapper->slr;
            int token_ix = marpa_v_token_value (v);

            if (step_type != MARPA_STEP_TOKEN)
              {
                av_fill (stack, result_ix - 1);
                return -1;
              }
            if (slr && token_ix == TOKEN_VALUE_IS_LITERAL)
              {
                SV **stored_sv;
                SV *token_literal_sv;
                Marpa_Earley_Set_ID start_earley_set =
                  marpa_v_token_start_es_id (v);
                Marpa_Earley_Set_ID end_earley_set = marpa_v_es_id (v);
                token_literal_sv =
                  slr_es_span_to_literal_sv (slr, start_earley_set,
                                             end_earley_set -
                                             start_earley_set);
                stored_sv = av_store (stack, result_ix, token_literal_sv);
                if (!stored_sv)
                  {
                    SvREFCNT_dec (token_literal_sv);
                  }
                return -1;
              }


            p_token_value_sv = av_fetch (v_wrapper->token_values, (I32) token_ix, 0);
            if (p_token_value_sv)
              {
                SV *token_value_sv = newSVsv (*p_token_value_sv);
                SV **stored_sv = av_store (stack, result_ix, token_value_sv);
                if (!stored_sv)
                  {
                    SvREFCNT_dec (token_value_sv);
                  }
              }
            else
              {
                av_fill (stack, result_ix - 1);
                return -1;
              }

            if (v_wrapper->trace_values)
              {
                AV *event;
                SV *event_data[4];
                const char *step_type_string =
                  step_type_to_string (step_type);
                if (!step_type_string)
                  step_type_string = "token value written to tos";
                event_data[0] = newSVpv (step_type_string, 0);
                event_data[1] = newSViv (marpa_v_token (v));
                event_data[2] = newSViv (marpa_v_token_value (v));
                event_data[3] = newSViv (v_wrapper->result);
                event = av_make (Dim (event_data), event_data);
                av_push (v_wrapper->event_queue, newRV_noinc ((SV *) event));
              }

          }
          return -1;

        default:
        BAD_OP:
          {
            const char *step_type_string = step_type_to_string (step_type);
            if (!step_type_string)
              step_type_string = "Unknown";
            croak
              ("Bad op code (%lu, '%s') in v->stack_step, step_type '%s'",
               (unsigned long) op_code, marpa__slif_op_name (op_code),
               step_type_string);
          }
        }

    NEXT_OP_CODE:;              /* continue while(1) loop */

    }

  return -1;
}

/* Static SLG methods */

#define SET_SLG_FROM_SLG_SV(slg, slg_sv) { \
    IV tmp = SvIV ((SV *) SvRV (slg_sv)); \
    (slg) = INT2PTR (Scanless_G *, tmp); \
}

/* Static SLR methods */


/*
 * Try to discard lexemes.
 * It is assumed this is because R1 is exhausted and we
 * are checking for unconsumed text.
 * Return values:
 * 0 OK.
 * -4: Exhausted, but lexemes remain.
 */
static IV
slr_discard (Scanless_R * slr)
{
  dTHX;
  int lexemes_discarded = 0;
  int lexemes_found = 0;
  Marpa_Recce r0;
  Marpa_Earley_Set_ID earley_set;

  r0 = slr->r0;
  if (!r0)
    {
      croak ("Problem in slr->read(): No R0 at %s %d", __FILE__, __LINE__);
    }
  earley_set = marpa_r_latest_earley_set (r0);
  /* Zero length lexemes are not of interest, so we do *not*
   * search the 0'th Earley set.
   */
  while (earley_set > 0)
    {
      int return_value;
      const int working_pos = slr->start_of_lexeme + earley_set;
      return_value = marpa_r_progress_report_start (r0, earley_set);
      if (return_value < 0)
        {
          croak ("Problem in marpa_r_progress_report_start(%p, %ld): %s",
                 (void *) r0, (unsigned long) earley_set,
                 xs_g_error (slr->current_lexer->g_wrapper));
        }
      while (1)
        {
          Marpa_Symbol_ID g1_lexeme;
          int dot_position;
          Marpa_Earley_Set_ID origin;
          Marpa_Rule_ID rule_id =
            marpa_r_progress_item (r0, &dot_position, &origin);
          if (rule_id <= -2)
            {
              croak ("Problem in marpa_r_progress_item(): %s",
                     xs_g_error (slr->current_lexer->g_wrapper));
            }
          if (rule_id == -1)
            goto NO_MORE_REPORT_ITEMS;
          if (origin != 0)
            goto NEXT_REPORT_ITEM;
          if (dot_position != -1)
            goto NEXT_REPORT_ITEM;
          g1_lexeme = slr->current_lexer->lexer_rule_to_g1_lexeme[rule_id];
          if (g1_lexeme == -1)
            goto NEXT_REPORT_ITEM;
          lexemes_found++;
          slr->end_of_lexeme = working_pos;

          /* -2 means a discarded item */
if (g1_lexeme <= -2)
  {
    lexemes_discarded++;
    if (slr->trace_terminals)
      {
                        union marpa_slr_event_s *slr_event = marpa__slr_event_push(slr->gift);
        MARPA_SLREV_TYPE(slr_event) = MARPA_SLRTR_LEXEME_DISCARDED;

        /* We do not have the lexeme, but we have the 
         * lexer rule.
         * The upper level will have to figure things out.
         */
        slr_event->t_trace_lexeme_discarded.t_rule_id = rule_id;
        slr_event->t_trace_lexeme_discarded.t_start_of_lexeme =
          slr->start_of_lexeme;
        slr_event->t_trace_lexeme_discarded.t_end_of_lexeme =
          slr->end_of_lexeme;
        slr_event->t_trace_lexeme_discarded.t_current_lexer_ix =
          slr->current_lexer->index;

      }
    /* If there is discarded item, we are fine,
     * and can return success.
     */
    slr->lexer_start_pos = slr->perl_pos = working_pos;
    return 0;
  }

          /*
           * Ignore everything else.
           * We don't try to read lexemes into an exhausted
           * R1 -- we only are looking for discardable tokens.
           */
          if (slr->trace_terminals)
            {
                        union marpa_slr_event_s *slr_event = marpa__slr_event_push(slr->gift);
MARPA_SLREV_TYPE(slr_event) = MARPA_SLRTR_LEXEME_IGNORED;

              slr_event->t_trace_lexeme_ignored.t_lexeme = g1_lexeme;
              slr_event->t_trace_lexeme_ignored.t_start_of_lexeme = slr->start_of_lexeme;
              slr_event->t_trace_lexeme_ignored.t_end_of_lexeme = slr->end_of_lexeme;
            }
        NEXT_REPORT_ITEM:;
        }
    NO_MORE_REPORT_ITEMS:;
      if (lexemes_found)
        {
          /* We found a lexeme at this location and we are not allowed
           * to discard this input.
           * Return failure.
           */
          slr->perl_pos = slr->problem_pos = slr->lexer_start_pos =
            slr->start_of_lexeme;
          return -4;
        }
      earley_set--;
    }

  /* If we are here we found no lexemes anywhere in the input,
   * and therefore none which can be discarded.
   * Return failure.
   */
  slr->perl_pos = slr->problem_pos = slr->lexer_start_pos =
    slr->start_of_lexeme;
  return -4;
}

/* Assumes it is called
 after a successful marpa_r_earleme_complete().
 At some point it may need optional SLR information,
 at which point I will add a parameter
 */
static void
slr_convert_events (Scanless_R * slr)
{
  dTHX;
  int event_ix;
  Marpa_Grammar g = slr->r1_wrapper->base->g;
  const int event_count = marpa_g_event_count (g);
  for (event_ix = 0; event_ix < event_count; event_ix++)
    {
      Marpa_Event marpa_event;
      Marpa_Event_Type event_type = marpa_g_event (g, &marpa_event, event_ix);
      switch (event_type)
        {
          {
        case MARPA_EVENT_EXHAUSTED:
            /* Do nothing about exhaustion on success */
            break;
        case MARPA_EVENT_SYMBOL_COMPLETED:
            {
              union marpa_slr_event_s *slr_event = marpa__slr_event_push(slr->gift);
                MARPA_SLREV_TYPE(slr_event) = MARPA_SLREV_SYMBOL_COMPLETED;
              slr_event->t_symbol_completed.t_symbol = marpa_g_event_value (&marpa_event);
            }
            break;
        case MARPA_EVENT_SYMBOL_NULLED:
            {
              union marpa_slr_event_s *slr_event = marpa__slr_event_push(slr->gift);
MARPA_SLREV_TYPE(slr_event) =MARPA_SLREV_SYMBOL_NULLED;
              slr_event->t_symbol_nulled.t_symbol = marpa_g_event_value (&marpa_event);
            }
            break;
        case MARPA_EVENT_SYMBOL_PREDICTED:
            {
              union marpa_slr_event_s *slr_event = marpa__slr_event_push(slr->gift);
MARPA_SLREV_TYPE(slr_event) = MARPA_SLREV_SYMBOL_PREDICTED;
              slr_event->t_symbol_predicted.t_symbol = marpa_g_event_value (&marpa_event);
            }
            break;
        case MARPA_EVENT_EARLEY_ITEM_THRESHOLD:
            /* All events are ignored on faiulre
             * On success, all except MARPA_EVENT_EARLEY_ITEM_THRESHOLD
             * are ignored.
             *
             * The warning raised for MARPA_EVENT_EARLEY_ITEM_THRESHOLD 
             * can be turned off by raising
             * the Earley item warning threshold.
             */
            {
              warn
                ("Marpa: Scanless G1 Earley item count (%ld) exceeds warning threshold",
                 (long) marpa_g_event_value (&marpa_event));
            }
            break;
        default:
            {
              union marpa_slr_event_s *slr_event = marpa__slr_event_push(slr->gift);
MARPA_SLREV_TYPE(slr_event) = MARPA_SLREV_MARPA_R_UNKNOWN;
              slr_event->t_marpa_r_unknown.t_event = event_type;
            }
            break;
          }
        }
    }
}

/* Called after start_input().
 I am not sure that all these events are needed.
 */
static void
r_convert_events (R_Wrapper * r_wrapper)
{
  dTHX;
  int event_ix;
  Marpa_Grammar g = r_wrapper->base->g;
  const int event_count = marpa_g_event_count (g);
  for (event_ix = 0; event_ix < event_count; event_ix++)
    {
      Marpa_Event marpa_event;
      Marpa_Event_Type event_type =
        marpa_g_event (g, &marpa_event, event_ix);
      switch (event_type)
        {
          {
        case MARPA_EVENT_EXHAUSTED:
            /* Do nothing about exhaustion on success */
            break;
        case MARPA_EVENT_SYMBOL_COMPLETED:
            {
              AV *event;
              SV *event_data[2];
              Marpa_Symbol_ID completed_symbol =
                marpa_g_event_value (&marpa_event);
              event_data[0] = newSVpvs ("symbol completed");
              event_data[1] = newSViv (completed_symbol);
              event = av_make (Dim (event_data), event_data);
              av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event));
            }
            break;
        case MARPA_EVENT_SYMBOL_NULLED:
            {
              AV *event;
              SV *event_data[2];
              Marpa_Symbol_ID nulled_symbol =
                marpa_g_event_value (&marpa_event);
              event_data[0] = newSVpvs ("symbol nulled");
              event_data[1] = newSViv (nulled_symbol);
              event = av_make (Dim (event_data), event_data);
              av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event));
            }
            break;
        case MARPA_EVENT_SYMBOL_PREDICTED:
            {
              AV *event;
              SV *event_data[2];
              Marpa_Symbol_ID predicted_symbol =
                marpa_g_event_value (&marpa_event);
              event_data[0] = newSVpvs ("symbol predicted");
              event_data[1] = newSViv (predicted_symbol);
              event = av_make (Dim (event_data), event_data);
              av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event));
            }
            break;
        case MARPA_EVENT_EARLEY_ITEM_THRESHOLD:
            /* All events are ignored on faiulre
             * On success, all except MARPA_EVENT_EARLEY_ITEM_THRESHOLD
             * are ignored.
             *
             * The warning raised for MARPA_EVENT_EARLEY_ITEM_THRESHOLD 
             * can be turned off by raising
             * the Earley item warning threshold.
             */
            {
              warn
                ("Marpa: Scanless G1 Earley item count (%ld) exceeds warning threshold",
                 (long) marpa_g_event_value (&marpa_event));
            }
            break;
        default:
            {
              AV *event;
              const char *result_string = event_type_to_string (event_type);
              SV *event_data[2];
              event_data[0] = newSVpvs ("unknown event");
              if (!result_string)
                {
                  result_string =
                    form ("event(%d): unknown event code, %d", event_ix,
                          event_type);
                }
              event_data[1] = newSVpv (result_string, 0);
              event = av_make (Dim (event_data), event_data);
              av_push (r_wrapper->event_queue, newRV_noinc ((SV *) event));
            }
            break;
          }
        }
    }
}

/*
 * Return values:
 * NULL OK.
 * Otherwise, a string containing the error.
 * The string must be a constant in static space.
 */
static const char *
slr_alternatives (Scanless_R * slr)
{
  dTHX;
  Marpa_Recce r0;
  Marpa_Recce r1 = slr->r1;
  Marpa_Earley_Set_ID earley_set;
  const Scanless_G *slg = slr->slg;

  /* |high_lexeme_priority| is not valid unless |is_priority_set| is set. */
  int is_priority_set = 0;
  int high_lexeme_priority = 0;

  int discarded = 0;
  int rejected = 0;
  int working_pos = slr->start_of_lexeme;

  r0 = slr->r0;
  if (!r0)
    {
      croak ("Problem in slr->read(): No R0 at %s %d", __FILE__, __LINE__);
    }

  marpa__slr_lexeme_clear (slr->gift);

  /* Zero length lexemes are not of interest, so we do *not*
   * search the 0'th Earley set.
   */
  for (earley_set = marpa_r_latest_earley_set (r0); earley_set > 0;
       earley_set--)
    {
      int return_value;
      int end_of_earley_items = 0;
      working_pos = slr->start_of_lexeme + earley_set;

      return_value = marpa_r_progress_report_start (r0, earley_set);
      if (return_value < 0)
	{
	  croak ("Problem in marpa_r_progress_report_start(%p, %ld): %s",
		 (void *) r0, (unsigned long) earley_set,
		 xs_g_error (slr->current_lexer->g_wrapper));
	}

      while (!end_of_earley_items)
	{
	  struct symbol_g_properties *symbol_g_properties;
	  Marpa_Symbol_ID g1_lexeme;
	  int this_lexeme_priority;
	  int is_expected;
	  int dot_position;
	  Marpa_Earley_Set_ID origin;
	  Marpa_Rule_ID rule_id =
	    marpa_r_progress_item (r0, &dot_position, &origin);
	  if (rule_id <= -2)
	    {
	      croak ("Problem in marpa_r_progress_item(): %s",
		     xs_g_error (slr->current_lexer->g_wrapper));
	    }
	  if (rule_id == -1)
	    {
	      end_of_earley_items = 1;
	      goto NEXT_PASS1_REPORT_ITEM;
	    }
	  if (origin != 0)
	    goto NEXT_PASS1_REPORT_ITEM;
	  if (dot_position != -1)
	    goto NEXT_PASS1_REPORT_ITEM;
	  g1_lexeme = slr->current_lexer->lexer_rule_to_g1_lexeme[rule_id];
	  if (g1_lexeme == -1)
	    goto NEXT_PASS1_REPORT_ITEM;
	  slr->end_of_lexeme = working_pos;
	  /* -2 means a discarded item */
	  if (g1_lexeme <= -2)
	    {
	      union marpa_slr_event_s *lexeme_entry =
		marpa__slr_lexeme_push (slr->gift);
	      MARPA_SLREV_TYPE (lexeme_entry) = MARPA_SLRTR_LEXEME_DISCARDED;
	      lexeme_entry->t_trace_lexeme_discarded.t_rule_id = rule_id;
	      lexeme_entry->t_trace_lexeme_discarded.t_start_of_lexeme =
		slr->start_of_lexeme;
	      lexeme_entry->t_trace_lexeme_discarded.t_end_of_lexeme =
		slr->end_of_lexeme;
	      lexeme_entry->t_trace_lexeme_discarded.t_current_lexer_ix =
		slr->current_lexer->index;
	      discarded++;

	      goto NEXT_PASS1_REPORT_ITEM;
	    }
	  symbol_g_properties = slg->symbol_g_properties + g1_lexeme;
	  is_expected = marpa_r_terminal_is_expected (r1, g1_lexeme);
	  if (!is_expected)
	    {
	      union marpa_slr_event_s *lexeme_entry =
		marpa__slr_lexeme_push (slr->gift);
	      if (symbol_g_properties->latm)
		{
		  croak
		    ("Internal error: Marpa recognized unexpected token @%ld-%ld: lexer=%ld, lexeme=%ld",
		     (long) slr->start_of_lexeme, (long) slr->end_of_lexeme,
                     (long) slr->current_lexer->index, (long) g1_lexeme);
		}
	      else
		{
		  MARPA_SLREV_TYPE (lexeme_entry) =
		    MARPA_SLRTR_LEXEME_REJECTED;
		  lexeme_entry->t_trace_lexeme_rejected.t_start_of_lexeme =
		    slr->start_of_lexeme;
		  lexeme_entry->t_trace_lexeme_rejected.t_end_of_lexeme =
		    slr->end_of_lexeme;
		  lexeme_entry->t_trace_lexeme_rejected.t_lexeme = g1_lexeme;
		  lexeme_entry->t_trace_lexeme_rejected.t_current_lexer_ix =
		    slr->current_lexer->index;
		  rejected++;
		}
	      goto NEXT_PASS1_REPORT_ITEM;
	    }

	  /* If we are here, the lexeme will be accepted  by the grammar,
	   * but we do not yet know about priority
	   */

	  this_lexeme_priority = symbol_g_properties->priority;
	  if (!is_priority_set || this_lexeme_priority > high_lexeme_priority)
	    {
	      high_lexeme_priority = this_lexeme_priority;
	      is_priority_set = 1;
	    }

	  {
	    union marpa_slr_event_s *lexeme_entry =
	      marpa__slr_lexeme_push (slr->gift);
	    MARPA_SLREV_TYPE (lexeme_entry) = MARPA_SLRTR_LEXEME_ACCEPTABLE;
	    lexeme_entry->t_lexeme_acceptable.t_start_of_lexeme =
	      slr->start_of_lexeme;
	    lexeme_entry->t_lexeme_acceptable.t_end_of_lexeme =
	      slr->end_of_lexeme;
	    lexeme_entry->t_lexeme_acceptable.t_lexeme = g1_lexeme;
	    lexeme_entry->t_lexeme_acceptable.t_current_lexer_ix =
	      slr->current_lexer->index;
	    lexeme_entry->t_lexeme_acceptable.t_priority =
	      this_lexeme_priority;
	    /* Default to this symbol's priority, since we don't
	       yet know what the required priority will be */
	    lexeme_entry->t_lexeme_acceptable.t_required_priority =
	      this_lexeme_priority;
	  }

	NEXT_PASS1_REPORT_ITEM:	/* Clearer, I think, using this label than long distance
					   break and continue */ ;
	}

      if (discarded || rejected || is_priority_set)
	break;

    }

  {
    int i;
    const int lexeme_dstack_length = marpa__slr_lexeme_count (slr->gift);
    for (i = 0; i < lexeme_dstack_length; i++)
      {
	union marpa_slr_event_s *const lexeme_stack_event =
	  marpa__slr_lexeme_entry (slr->gift, i);
	const int event_type = MARPA_SLREV_TYPE (lexeme_stack_event);
	switch (event_type)
	  {
	  case MARPA_SLRTR_LEXEME_ACCEPTABLE:
	    if (lexeme_stack_event->t_lexeme_acceptable.t_priority <
		high_lexeme_priority)
	      {
		MARPA_SLREV_TYPE (lexeme_stack_event) =
		  MARPA_SLRTR_LEXEME_OUTPRIORITIZED;
		lexeme_stack_event->t_lexeme_acceptable.t_required_priority =
		  high_lexeme_priority;
		if (slr->trace_terminals)
		  {
		    *(marpa__slr_event_push (slr->gift)) =
		      *lexeme_stack_event;
		  }
	      }
	    break;
	  case MARPA_SLRTR_LEXEME_REJECTED:
	    if (slr->trace_terminals || !is_priority_set)
	      {
		*(marpa__slr_event_push (slr->gift)) = *lexeme_stack_event;
	      }
	    break;
	  case MARPA_SLRTR_LEXEME_DISCARDED:
	    if (slr->trace_terminals)
	      {
		*(marpa__slr_event_push (slr->gift)) = *lexeme_stack_event;
	      }
	    break;
	  }
      }
  }

  if (!is_priority_set)
    {
      if (discarded)
	{
	  slr->perl_pos = slr->lexer_start_pos = working_pos;
	  return 0;
	}
      slr->perl_pos = slr->problem_pos = slr->lexer_start_pos =
	slr->start_of_lexeme;
      return "no lexeme";
    }

  /* If here, a lexeme has been accepted and priority is set
   */

  {				/* Check for a "pause before" lexeme */
    /* A legacy implement allowed only one pause-before lexeme, and used elements of
       the SLR structure to hold the data.  The new mechanism uses events and allows
       multiple pause-before lexemes, but the legacy mechanism must be supported. */
    Marpa_Symbol_ID g1_lexeme = -1;
    int i;
    const int lexeme_dstack_length = marpa__slr_lexeme_count (slr->gift);
    for (i = 0; i < lexeme_dstack_length; i++)
      {
	union marpa_slr_event_s *const lexeme_entry =
	  marpa__slr_lexeme_entry (slr->gift, i);
	const int event_type = MARPA_SLREV_TYPE (lexeme_entry);
	if (event_type == MARPA_SLRTR_LEXEME_ACCEPTABLE)
	  {
	    const Marpa_Symbol_ID lexeme_id =
	      lexeme_entry->t_lexeme_acceptable.t_lexeme;
	    const struct symbol_r_properties *symbol_r_properties =
	      slr->symbol_r_properties + lexeme_id;
	    if (symbol_r_properties->pause_before_active)
	      {
		g1_lexeme = lexeme_id;
		slr->start_of_pause_lexeme =
		  lexeme_entry->t_lexeme_acceptable.t_start_of_lexeme;
		slr->end_of_pause_lexeme =
		  lexeme_entry->t_lexeme_acceptable.t_end_of_lexeme;
		slr->pause_lexeme = g1_lexeme;
		if (slr->trace_terminals > 2)
		  {
		    union marpa_slr_event_s *slr_event =
		      marpa__slr_event_push (slr->gift);
		    MARPA_SLREV_TYPE (slr_event) = MARPA_SLRTR_BEFORE_LEXEME;
		    slr_event->t_trace_before_lexeme.t_start_of_pause_lexeme =
		      slr->start_of_pause_lexeme;
		    slr_event->t_trace_before_lexeme.t_end_of_pause_lexeme = slr->end_of_pause_lexeme;	/* end */
		    slr_event->t_trace_before_lexeme.t_pause_lexeme = slr->pause_lexeme;	/* lexeme */
		  }
		{
		  union marpa_slr_event_s *slr_event =
		    marpa__slr_event_push (slr->gift);
		  MARPA_SLREV_TYPE (slr_event) = MARPA_SLREV_BEFORE_LEXEME;
		  slr_event->t_before_lexeme.t_pause_lexeme =
		    slr->pause_lexeme;
		}
	      }
	  }
      }

    if (g1_lexeme >= 0)
      {
	slr->lexer_start_pos = slr->perl_pos = slr->start_of_lexeme;
	return 0;
      }
  }

  {
    int return_value;
    int i;
    const int lexeme_dstack_length = marpa__slr_lexeme_count (slr->gift);
    for (i = 0; i < lexeme_dstack_length; i++)
      {
	union marpa_slr_event_s *const event =
	  marpa__slr_lexeme_entry (slr->gift, i);
	const int event_type = MARPA_SLREV_TYPE (event);
	if (event_type == MARPA_SLRTR_LEXEME_ACCEPTABLE)
	  {
	    const Marpa_Symbol_ID g1_lexeme =
	      event->t_lexeme_acceptable.t_lexeme;
	    const struct symbol_r_properties *symbol_r_properties =
	      slr->symbol_r_properties + g1_lexeme;

	    if (slr->trace_terminals > 2)
	      {
		union marpa_slr_event_s *event =
		  marpa__slr_event_push (slr->gift);
		MARPA_SLREV_TYPE (event) = MARPA_SLRTR_G1_ATTEMPTING_LEXEME;
		event->t_trace_attempting_lexeme.t_start_of_lexeme = slr->start_of_lexeme;	/* start */
		event->t_trace_attempting_lexeme.t_end_of_lexeme = slr->end_of_lexeme;	/* end */
		event->t_trace_attempting_lexeme.t_lexeme = g1_lexeme;
	      }
	    return_value =
	      marpa_r_alternative (r1, g1_lexeme, TOKEN_VALUE_IS_LITERAL, 1);
	    switch (return_value)
	      {

	      case MARPA_ERR_UNEXPECTED_TOKEN_ID:
		croak ("Internal error: Marpa rejected expected token");
		break;

	      case MARPA_ERR_DUPLICATE_TOKEN:
		if (slr->trace_terminals)
		  {
		    union marpa_slr_event_s *event =
		      marpa__slr_event_push (slr->gift);
		    MARPA_SLREV_TYPE (event) =
		      MARPA_SLRTR_G1_DUPLICATE_LEXEME;
		    event->t_trace_duplicate_lexeme.t_start_of_lexeme = slr->start_of_lexeme;	/* start */
		    event->t_trace_duplicate_lexeme.t_end_of_lexeme = slr->end_of_lexeme;	/* end */
		    event->t_trace_duplicate_lexeme.t_lexeme = g1_lexeme;	/* lexeme */
		  }
		break;

	      case MARPA_ERR_NONE:
		if (slr->trace_terminals)
		  {
		    union marpa_slr_event_s *event =
		      marpa__slr_event_push (slr->gift);
		    MARPA_SLREV_TYPE (event) = MARPA_SLRTR_G1_ACCEPTED_LEXEME;
		    event->t_trace_accepted_lexeme.t_start_of_lexeme = slr->start_of_lexeme;	/* start */
		    event->t_trace_accepted_lexeme.t_end_of_lexeme = slr->end_of_lexeme;	/* end */
		    event->t_trace_accepted_lexeme.t_lexeme = g1_lexeme;	/* lexeme */
		    event->t_trace_accepted_lexeme.t_current_lexer_ix =
		      slr->current_lexer->index;
		  }
		if (symbol_r_properties->pause_after_active)
		  {
		    slr->start_of_pause_lexeme =
		      event->t_lexeme_acceptable.t_start_of_lexeme;
		    slr->end_of_pause_lexeme =
		      event->t_lexeme_acceptable.t_end_of_lexeme;
		    slr->pause_lexeme = g1_lexeme;
		    if (slr->trace_terminals > 2)
		      {
			union marpa_slr_event_s *event =
			  marpa__slr_event_push (slr->gift);
			MARPA_SLREV_TYPE (event) = MARPA_SLRTR_AFTER_LEXEME;
			event->t_trace_after_lexeme.t_start_of_lexeme =
			  slr->start_of_pause_lexeme;
			event->t_trace_after_lexeme.t_end_of_lexeme =
			  slr->end_of_pause_lexeme;
			event->t_trace_after_lexeme.t_lexeme = g1_lexeme;
		      }
		    {
		      union marpa_slr_event_s *event =
			marpa__slr_event_push (slr->gift);
		      MARPA_SLREV_TYPE (event) = MARPA_SLREV_AFTER_LEXEME;
		      event->t_after_lexeme.t_lexeme = slr->pause_lexeme;
		    }
		  }
		break;

	      default:
		croak
		  ("Problem SLR->read() failed on symbol id %d at position %d: %s",
		   g1_lexeme, (int) slr->perl_pos,
		   xs_g_error (slr->g1_wrapper));
		/* NOTREACHED */

	      }

	  }
      }


    return_value = slr->r1_earleme_complete_result =
      marpa_r_earleme_complete (r1);
    if (return_value < 0)
      {
	croak ("Problem in marpa_r_earleme_complete(): %s",
	       xs_g_error (slr->g1_wrapper));
      }
    slr->lexer_start_pos = slr->perl_pos = slr->end_of_lexeme;
    if (return_value > 0)
      {
	slr_convert_events (slr);
      }

    marpa_r_latest_earley_set_values_set (r1, slr->start_of_lexeme,
					  INT2PTR (void *,
						   (slr->end_of_lexeme -
						    slr->start_of_lexeme)));
  }

  return 0;

}

static void
slr_es_to_span (Scanless_R * slr, Marpa_Earley_Set_ID earley_set, int *p_start,
               int *p_length)
{
  dTHX;
  int result = 0;
  /* We fake the values for Earley set 0,
   */
  if (earley_set <= 0)
    {
      *p_start = 0;
      *p_length = 0;
    }
  else
    {
      void *length_as_ptr;
      result =
        marpa_r_earley_set_values (slr->r1, earley_set, p_start,
                                   &length_as_ptr);
      *p_length = (int) PTR2IV (length_as_ptr);
    }
  if (result < 0)
    {
      croak ("failure in slr->span(%d): %s", earley_set,
             xs_g_error (slr->g1_wrapper));
    }
}

static void
slr_es_to_literal_span (Scanless_R * slr,
                        Marpa_Earley_Set_ID start_earley_set, int length,
                        int *p_start, int *p_length)
{
  dTHX;
  const Marpa_Recce r1 = slr->r1;
  const Marpa_Earley_Set_ID latest_earley_set =
    marpa_r_latest_earley_set (r1);
  if (start_earley_set >= latest_earley_set)
    {
      /* Should only happen if length == 0 */
      *p_start = slr->pos_db_logical_size;
      *p_length = 0;
      return;
    }
  slr_es_to_span (slr, start_earley_set + 1, p_start, p_length);
  if (length == 0)
    *p_length = 0;
  if (length > 1)
    {
      int last_lexeme_start_position;
      int last_lexeme_length;
      slr_es_to_span (slr, start_earley_set + length,
        &last_lexeme_start_position, &last_lexeme_length);
      *p_length = last_lexeme_start_position + last_lexeme_length - *p_start;
    }
}

static SV*
slr_es_span_to_literal_sv (Scanless_R * slr,
                        Marpa_Earley_Set_ID start_earley_set, int length)
{
  dTHX;
  if (length > 0)
    {
      int length_in_positions;
      int start_position;
      slr_es_to_literal_span (slr,
                              start_earley_set, length,
                              &start_position, &length_in_positions);
      return u_pos_span_to_literal_sv(slr, start_position, length_in_positions);
    }
  return newSVpvn ("", 0);
}

#define EXPECTED_LIBMARPA_MAJOR 6
#define EXPECTED_LIBMARPA_MINOR 0
#define EXPECTED_LIBMARPA_MICRO 3

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin

PROTOTYPES: DISABLE

void
debug_level_set(new_level)
    int new_level;
PPCODE:
{
  const int old_level = marpa_debug_level_set (new_level);
  if (old_level || new_level)
    marpa_r2_warn ("libmarpa debug level set to %d, was %d", new_level,
		   old_level);
  XSRETURN_YES;
}

void
error_names()
PPCODE:
{
  int error_code;
  for (error_code = 0; error_code < MARPA_ERROR_COUNT; error_code++)
    {
      const char *error_name = marpa_error_description[error_code].name;
      XPUSHs (sv_2mortal (newSVpv (error_name, 0)));
    }
}

 # This search is not optimized.  This list is short
 # and the data is constant, so that
 # and lookup is expected to be done once by an application
 # and memoized.
void
op( op_name )
     char *op_name;
PPCODE:
{
  const int op_id = marpa__slif_op_id (op_name);
  if (op_id >= 0)
    {
      XSRETURN_IV ((IV) op_id);
    }
  croak ("Problem with Marpa::R2::Thin->op('%s'): No such op", op_name);
}

 # This search is not optimized.  This list is short
 # and the data is constant.  It is expected this lookup
 # will be done mainly for error messages.
void
op_name( op )
     IV op;
PPCODE:
{
  XSRETURN_PV (marpa__slif_op_name(op));
}

void
version()
PPCODE:
{
    int version[3];
    int result = marpa_version(version);
    if (result < 0) { XSRETURN_UNDEF; }
    XPUSHs (sv_2mortal (newSViv (version[0])));
    XPUSHs (sv_2mortal (newSViv (version[1])));
    XPUSHs (sv_2mortal (newSViv (version[2])));
}

void
tag()
PPCODE:
{
   const char* tag = _marpa_tag();
   XSRETURN_PV(tag);
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::G

void
new( ... )
PPCODE:
{
  Marpa_Grammar g;
  G_Wrapper *g_wrapper;
  int throw = 1;
  IV interface = 0;
  Marpa_Config marpa_configuration;
  Marpa_Error_Code error_code;

  switch (items)
    {
    case 1:
      {
	/* If we are using the (deprecated) interface 0,
	 * get the throw setting from a (deprecated) global variable
	 */
	SV *throw_sv = get_sv ("Marpa::R2::Thin::C::THROW", 0);
	throw = throw_sv && SvTRUE (throw_sv);
      }
      break;
      croak ("Usage: Marpa::R2::Thin:G::new(class, arg_hash)");
    case 2:
      {
	I32 retlen;
	char *key;
	SV *arg_value;
	SV *arg = ST (1);
	HV *named_args;
	if (!SvROK (arg) || SvTYPE (SvRV (arg)) != SVt_PVHV)
	  croak ("Problem in $g->new(): argument is not hash ref");
	named_args = (HV *) SvRV (arg);
	hv_iterinit (named_args);
	while ((arg_value = hv_iternextsv (named_args, &key, &retlen)))
	  {
	    if ((*key == 'i') && strnEQ (key, "if", (unsigned) retlen))
	      {
		interface = SvIV (arg_value);
		if (interface != 1)
		  {
		    croak ("Problem in $g->new(): interface value must be 1");
		  }
		continue;
	      }
	    croak ("Problem in $g->new(): unknown named argument: %s", key);
	  }
	if (interface != 1)
	  {
	    croak
	      ("Problem in $g->new(): 'interface' named argument is required");
	  }
      }
    }

  /* Make sure the header is from the version we want */
  if (MARPA_H_MAJOR_VERSION != EXPECTED_LIBMARPA_MAJOR
      || MARPA_H_MINOR_VERSION != EXPECTED_LIBMARPA_MINOR
      || MARPA_H_MICRO_VERSION != EXPECTED_LIBMARPA_MICRO)
    {
      croak
	("Problem in $g->new(): want Libmarpa %d.%d.%d, header was from Libmarpa %d.%d.%d",
	 EXPECTED_LIBMARPA_MAJOR, EXPECTED_LIBMARPA_MINOR,
	 EXPECTED_LIBMARPA_MICRO,
	 MARPA_H_MAJOR_VERSION, MARPA_H_MINOR_VERSION,
	 MARPA_H_MICRO_VERSION);
    }

  {
    /* Now make sure the library is from the version we want */
    int version[3];
    error_code = marpa_version (version);
    if (error_code != MARPA_ERR_NONE
	|| version[0] != EXPECTED_LIBMARPA_MAJOR
	|| version[1] != EXPECTED_LIBMARPA_MINOR
	|| version[2] != EXPECTED_LIBMARPA_MICRO)
      {
	croak
	  ("Problem in $g->new(): want Libmarpa %d.%d.%d, using Libmarpa %d.%d.%d",
	   EXPECTED_LIBMARPA_MAJOR, EXPECTED_LIBMARPA_MINOR,
	   EXPECTED_LIBMARPA_MICRO, version[0], version[1], version[2]);
      }
  }

  marpa_c_init (&marpa_configuration);
  g = marpa_g_new (&marpa_configuration);
  if (g)
    {
      SV *sv;
      Newx (g_wrapper, 1, G_Wrapper);
      g_wrapper->throw = throw;
      g_wrapper->g = g;
      g_wrapper->message_buffer = NULL;
      g_wrapper->libmarpa_error_code = MARPA_ERR_NONE;
      g_wrapper->libmarpa_error_string = NULL;
      g_wrapper->message_is_marpa_thin_error = 0;
      sv = sv_newmortal ();
      sv_setref_pv (sv, grammar_c_class_name, (void *) g_wrapper);
      XPUSHs (sv);
    }
  else
    {
      error_code = marpa_c_error (&marpa_configuration, NULL);
    }

  if (error_code != MARPA_ERR_NONE)
    {
      const char *error_description = "Error code out of bounds";
      if (error_code >= 0 && error_code < MARPA_ERROR_COUNT)
	{
	  error_description = marpa_error_description[error_code].name;
	}
      if (throw)
	croak ("Problem in Marpa::R2->new(): %s", error_description);
      if (GIMME != G_ARRAY)
	{
	  XSRETURN_UNDEF;
	}
      XPUSHs (&PL_sv_undef);
      XPUSHs (sv_2mortal (newSViv (error_code)));
    }
}

void
DESTROY( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
    Marpa_Grammar grammar;
    if (g_wrapper->message_buffer)
        Safefree(g_wrapper->message_buffer);
    grammar = g_wrapper->g;
    marpa_g_unref( grammar );
    Safefree( g_wrapper );
}


void
event( g_wrapper, ix )
    G_Wrapper *g_wrapper;
    int ix;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  Marpa_Event event;
  const char *result_string = NULL;
  Marpa_Event_Type result = marpa_g_event (g, &event, ix);
  if (result < 0)
    {
      if (!g_wrapper->throw)
        {
          XSRETURN_UNDEF;
        }
      croak ("Problem in g->event(): %s", xs_g_error (g_wrapper));
    }
  result_string = event_type_to_string (result);
  if (!result_string)
    {
      char *error_message =
        form ("event(%d): unknown event code, %d", ix, result);
      set_error_from_string (g_wrapper, savepv(error_message));
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
  XPUSHs (sv_2mortal (newSViv (marpa_g_event_value (&event))));
}

 # Actually returns Marpa_Rule_ID, void is here to eliminate RETVAL 
 # that remains unused with PPCODE. The same applies to all void's below 
 # when preceded with a return type commented out, e.g. 
 #    # int
 #    void
void
rule_new( g_wrapper, lhs, rhs_av )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID lhs;
    AV *rhs_av;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
    int length;
    Marpa_Symbol_ID* rhs;
    Marpa_Rule_ID new_rule_id;
    length = av_len(rhs_av)+1;
    if (length <= 0) {
        rhs = (Marpa_Symbol_ID*)NULL;
    } else {
        int i;
        Newx(rhs, length, Marpa_Symbol_ID);
        for (i = 0; i < length; i++) {
            SV** elem = av_fetch(rhs_av, i, 0);
            if (elem == NULL) {
                Safefree(rhs);
                XSRETURN_UNDEF;
            } else {
                rhs[i] = (Marpa_Symbol_ID)SvIV(*elem);
            }
        }
    }
    new_rule_id = marpa_g_rule_new(g, lhs, rhs, length);
    Safefree(rhs);
    if (new_rule_id < 0 && g_wrapper->throw ) {
      croak ("Problem in g->rule_new(%d, ...): %s", lhs, xs_g_error (g_wrapper));
    }
    XPUSHs( sv_2mortal( newSViv(new_rule_id) ) );
}

 # This function invalidates any current iteration on
 # the hash args.  This seems to be the way things are
 # done in Perl -- in particular there seems to be no
 # easy way to  prevent that.
# Marpa_Rule_ID
void
sequence_new( g_wrapper, lhs, rhs, args )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID lhs;
    Marpa_Symbol_ID rhs;
    HV *args;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  Marpa_Rule_ID new_rule_id;
  Marpa_Symbol_ID separator = -1;
  int min = 1;
  int flags = 0;
  if (args)
    {
      I32 retlen;
      char *key;
      SV *arg_value;
      hv_iterinit (args);
      while ((arg_value = hv_iternextsv (args, &key, &retlen)))
        {
          if ((*key == 'k') && strnEQ (key, "keep", (unsigned) retlen))
            {
              if (SvTRUE (arg_value))
                flags |= MARPA_KEEP_SEPARATION;
              continue;
            }
          if ((*key == 'm') && strnEQ (key, "min", (unsigned) retlen))
            {
              IV raw_min = SvIV (arg_value);
              if (raw_min < 0)
                {
                  char *error_message =
                    form ("sequence_new(): min cannot be less than 0");
                  set_error_from_string (g_wrapper, savepv (error_message));
                  if (g_wrapper->throw)
                    {
                      croak ("%s", error_message);
                    }
                  else
                    {
                      XSRETURN_UNDEF;
                    }
                }
              if (raw_min > INT_MAX)
                {
                  /* IV can be larger than int */
                  char *error_message =
                    form ("sequence_new(): min cannot be greater than %d",
                          INT_MAX);
                  set_error_from_string (g_wrapper, savepv (error_message));
                  if (g_wrapper->throw)
                    {
                      croak ("%s", error_message);
                    }
                  else
                    {
                      XSRETURN_UNDEF;
                    }
                }
              min = (int) raw_min;
              continue;
            }
          if ((*key == 'p') && strnEQ (key, "proper", (unsigned) retlen))
            {
              if (SvTRUE (arg_value))
                flags |= MARPA_PROPER_SEPARATION;
              continue;
            }
          if ((*key == 's') && strnEQ (key, "separator", (unsigned) retlen))
            {
              separator = (Marpa_Symbol_ID) SvIV (arg_value);
              continue;
            }
          {
            char *error_message =
              form ("unknown argument to sequence_new(): %.*s", (int) retlen,
                    key);
            set_error_from_string (g_wrapper, savepv (error_message));
            if (g_wrapper->throw)
              {
                croak ("%s", error_message);
              }
            else
              {
                XSRETURN_UNDEF;
              }
          }
        }
    }
  new_rule_id = marpa_g_sequence_new (g, lhs, rhs, separator, min, flags);
  if (new_rule_id < 0 && g_wrapper->throw)
    {
      switch (marpa_g_error (g, NULL))
        {
        case MARPA_ERR_SEQUENCE_LHS_NOT_UNIQUE:
          croak ("Problem in g->sequence_new(): %s", xs_g_error (g_wrapper));
        default:
          croak ("Problem in g->sequence_new(%d, %d, ...): %s", lhs, rhs,
                 xs_g_error (g_wrapper));
        }
    }
  XPUSHs (sv_2mortal (newSViv (new_rule_id)));
}

void
default_rank( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar self = g_wrapper->g;
  int gp_result = marpa_g_default_rank (self);
  if (gp_result == -2 && g_wrapper->throw)
    {
      const int libmarpa_error_code = marpa_g_error (self, NULL);
      if (libmarpa_error_code != MARPA_ERR_NONE)
        {
          croak ("Problem in g->default_rank(): %s", xs_g_error (g_wrapper));
        }
    }
  XSRETURN_IV (gp_result);
}

void
default_rank_set( g_wrapper, rank )
    G_Wrapper *g_wrapper;
    Marpa_Rank rank;
PPCODE:
{
  Marpa_Grammar self = g_wrapper->g;
  int gp_result = marpa_g_default_rank_set (self, rank);
  if (gp_result == -2 && g_wrapper->throw)
    {
      const int libmarpa_error_code = marpa_g_error (self, NULL);
      if (libmarpa_error_code != MARPA_ERR_NONE)
        croak ("Problem in g->default_rank_set(%d): %s",
               rank, xs_g_error (g_wrapper));
    }
  XSRETURN_IV (gp_result);
}

void
rule_rank( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar self = g_wrapper->g;
  int gp_result = marpa_g_rule_rank (self, rule_id);
  if (gp_result == -2 && g_wrapper->throw)
    {
      const int libmarpa_error_code = marpa_g_error (self, NULL);
      if (libmarpa_error_code != MARPA_ERR_NONE)
        {
          croak ("Problem in g->rule_rank(%d): %s",
                 rule_id, xs_g_error (g_wrapper));
        }
    }
  XSRETURN_IV (gp_result);
}

void
rule_rank_set( g_wrapper, rule_id, rank )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
    Marpa_Rank rank;
PPCODE:
{
  Marpa_Grammar self = g_wrapper->g;
  int gp_result = marpa_g_rule_rank_set(self, rule_id, rank);
  if (gp_result == -2 && g_wrapper->throw)
    {
      const int libmarpa_error_code = marpa_g_error (self, NULL);
      if (libmarpa_error_code != MARPA_ERR_NONE)
        croak ("Problem in g->rule_rank_set(%d, %d): %s",
               rule_id, rank, xs_g_error (g_wrapper));
    }
  XSRETURN_IV (gp_result);
}

void
symbol_rank( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar self = g_wrapper->g;
  int gp_result = marpa_g_symbol_rank (self, symbol_id);
  if (gp_result == -2 && g_wrapper->throw)
    {
      const int libmarpa_error_code = marpa_g_error (self, NULL);
      if (libmarpa_error_code != MARPA_ERR_NONE)
        {
          croak ("Problem in g->symbol_rank(%d): %s",
                 symbol_id, xs_g_error (g_wrapper));
        }
    }
  XSRETURN_IV (gp_result);
}

void
symbol_rank_set( g_wrapper, symbol_id, rank )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
    Marpa_Rank rank;
PPCODE:
{
  Marpa_Grammar self = g_wrapper->g;
  int gp_result = marpa_g_symbol_rank_set (self, symbol_id, rank);
  if (gp_result == -2 && g_wrapper->throw)
    {
      const int libmarpa_error_code = marpa_g_error (self, NULL);
      if (libmarpa_error_code != MARPA_ERR_NONE)
        croak ("Problem in g->symbol_rank_set(%d, %d): %s",
               symbol_id, rank, xs_g_error (g_wrapper));
    }
  XSRETURN_IV (gp_result);
}

void
throw_set( g_wrapper, boolean )
    G_Wrapper *g_wrapper;
    int boolean;
PPCODE:
{
  if (boolean < 0 || boolean > 1)
    {
      /* Always throws an exception if the arguments are bad */
      croak ("Problem in g->throw_set(%d): argument must be 0 or 1", boolean);
    }
  g_wrapper->throw = boolean;
  XPUSHs (sv_2mortal (newSViv (boolean)));
}

void
error( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  const char *error_message =
    "Problem in $g->error(): Nothing in message buffer";
  SV *error_code_sv = &PL_sv_undef;

  g_wrapper->libmarpa_error_code =
    marpa_g_error (g, &g_wrapper->libmarpa_error_string);
  /* A new Libmarpa error overrides any thin interface error */
  if (g_wrapper->libmarpa_error_code != MARPA_ERR_NONE)
    g_wrapper->message_is_marpa_thin_error = 0;
  if (g_wrapper->message_is_marpa_thin_error)
    {
      error_message = g_wrapper->message_buffer;
    }
  else
    {
      error_message = error_description_generate (g_wrapper);
      error_code_sv = sv_2mortal (newSViv (g_wrapper->libmarpa_error_code));
    }
  if (GIMME == G_ARRAY)
    {
      XPUSHs (error_code_sv);
    }
  XPUSHs (sv_2mortal (newSVpv (error_message, 0)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::R

void
new( class, g_sv )
    char * class;
    SV* g_sv;
PPCODE:
{
  SV *sv_to_return;
  G_Wrapper *g_wrapper;
  Marpa_Recce r;
  Marpa_Grammar g;
  PERL_UNUSED_ARG(class);

  if (!sv_isa (g_sv, "Marpa::R2::Thin::G"))
    {
      croak
        ("Problem in Marpa::R2->new(): arg is not of type Marpa::R2::Thin::G");
    }
  SET_G_WRAPPER_FROM_G_SV (g_wrapper, g_sv);
  g = g_wrapper->g;
  r = marpa_r_new (g);
  if (!r)
    {
      if (!g_wrapper->throw)
        {
          XSRETURN_UNDEF;
        }
      croak ("failure in marpa_r_new(): %s", xs_g_error (g_wrapper));
    };

  {
    R_Wrapper *r_wrapper = r_wrap (r, g_sv);
    sv_to_return = sv_newmortal ();
    sv_setref_pv (sv_to_return, recce_c_class_name, (void *) r_wrapper);
  }
  XPUSHs (sv_to_return);
}

void
DESTROY( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
    Marpa_Recce r = r_unwrap(r_wrapper);
    marpa_r_unref (r);
}

void
ruby_slippers_set( r_wrapper, boolean )
    R_Wrapper *r_wrapper;
    int boolean;
PPCODE:
{
  if (boolean < 0 || boolean > 1)
    {
      /* Always thrown */
      croak ("Problem in g->ruby_slippers_set(%d): argument must be 0 or 1", boolean);
    }
  r_wrapper->ruby_slippers = boolean;
  XPUSHs (sv_2mortal (newSViv (boolean)));
}

void
start_input( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  Marpa_Recognizer self = r_wrapper->r;
  int gp_result = marpa_r_start_input(self);
  if ( gp_result == -1 ) { XSRETURN_UNDEF; }
  if ( gp_result < 0 && r_wrapper->base->throw ) {
    croak( "Problem in r->start_input(): %s",
     xs_g_error( r_wrapper->base ));
  }
  r_convert_events(r_wrapper);
  XPUSHs (sv_2mortal (newSViv (gp_result)));
}

void
alternative( r_wrapper, symbol_id, value, length )
    R_Wrapper *r_wrapper;
    Marpa_Symbol_ID symbol_id;
    int value;
    int length;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  const G_Wrapper *base = r_wrapper->base;
  const int result = marpa_r_alternative (r, symbol_id, value, length);
  if (result == MARPA_ERR_NONE || r_wrapper->ruby_slippers || !base->throw)
    {
      XSRETURN_IV (result);
    }
  croak ("Problem in r->alternative(): %s", xs_g_error (r_wrapper->base));
}

void
terminals_expected( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  int i;
  struct marpa_r *r = r_wrapper->r;
  const int count =
    marpa_r_terminals_expected (r, r_wrapper->terminals_buffer);
  if (count < 0)
    {
      G_Wrapper* base = r_wrapper->base;
      if (!base->throw) { XSRETURN_UNDEF; }
      croak ("Problem in r->terminals_expected(): %s",
             xs_g_error (base));
    }
  EXTEND (SP, count);
  for (i = 0; i < count; i++)
    {
      PUSHs (sv_2mortal (newSViv (r_wrapper->terminals_buffer[i])));
    }
}

void
progress_item( r_wrapper )
     R_Wrapper *r_wrapper;
PPCODE:
{
  struct marpa_r *const r = r_wrapper->r;
  int position = -1;
  Marpa_Earley_Set_ID origin = -1;
  Marpa_Rule_ID rule_id = marpa_r_progress_item (r, &position, &origin);
  if (rule_id == -1)
    {
      XSRETURN_UNDEF;
    }
  if (rule_id < 0 && r_wrapper->base->throw)
    {
      croak ("Problem in r->progress_item(): %s",
             xs_g_error (r_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (rule_id)));
  XPUSHs (sv_2mortal (newSViv (position)));
  XPUSHs (sv_2mortal (newSViv (origin)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::B

void
new( class, r_wrapper, ordinal )
    char * class;
    R_Wrapper *r_wrapper;
    Marpa_Earley_Set_ID ordinal;
PPCODE:
{
  SV *sv;
  Marpa_Recognizer r = r_wrapper->r;
  B_Wrapper *b_wrapper;
  Marpa_Bocage b = marpa_b_new (r, ordinal);
  PERL_UNUSED_ARG(class);

  if (!b)
    {
      if (!r_wrapper->base->throw) { XSRETURN_UNDEF; }
      croak ("Problem in b->new(): %s", xs_g_error(r_wrapper->base));
    }
  Newx (b_wrapper, 1, B_Wrapper);
  {
    SV* base_sv = r_wrapper->base_sv;
    SvREFCNT_inc (base_sv);
    b_wrapper->base_sv = base_sv;
  }
  b_wrapper->base = r_wrapper->base;
  b_wrapper->b = b;
  sv = sv_newmortal ();
  sv_setref_pv (sv, bocage_c_class_name, (void *) b_wrapper);
  XPUSHs (sv);
}

void
DESTROY( b_wrapper )
    B_Wrapper *b_wrapper;
PPCODE:
{
    const Marpa_Bocage b = b_wrapper->b;
    SvREFCNT_dec (b_wrapper->base_sv);
    marpa_b_unref(b);
    Safefree( b_wrapper );
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::O

void
new( class, b_wrapper )
    char * class;
    B_Wrapper *b_wrapper;
PPCODE:
{
  SV *sv;
  Marpa_Bocage b = b_wrapper->b;
  O_Wrapper *o_wrapper;
  Marpa_Order o = marpa_o_new (b);
  PERL_UNUSED_ARG(class);

  if (!o)
    {
      if (!b_wrapper->base->throw) { XSRETURN_UNDEF; }
      croak ("Problem in o->new(): %s", xs_g_error(b_wrapper->base));
    }
  Newx (o_wrapper, 1, O_Wrapper);
  {
    SV* base_sv = b_wrapper->base_sv;
    SvREFCNT_inc (base_sv);
    o_wrapper->base_sv = base_sv;
  }
  o_wrapper->base = b_wrapper->base;
  o_wrapper->o = o;
  sv = sv_newmortal ();
  sv_setref_pv (sv, order_c_class_name, (void *) o_wrapper);
  XPUSHs (sv);
}

void
DESTROY( o_wrapper )
    O_Wrapper *o_wrapper;
PPCODE:
{
    const Marpa_Order o = o_wrapper->o;
    SvREFCNT_dec (o_wrapper->base_sv);
    marpa_o_unref(o);
    Safefree( o_wrapper );
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::T

void
new( class, o_wrapper )
    char * class;
    O_Wrapper *o_wrapper;
PPCODE:
{
  SV *sv;
  Marpa_Order o = o_wrapper->o;
  T_Wrapper *t_wrapper;
  Marpa_Tree t = marpa_t_new (o);
  PERL_UNUSED_ARG(class);

  if (!t)
    {
      if (!o_wrapper->base->throw) { XSRETURN_UNDEF; }
      croak ("Problem in t->new(): %s", xs_g_error(o_wrapper->base));
    }
  Newx (t_wrapper, 1, T_Wrapper);
  {
    SV* base_sv = o_wrapper->base_sv;
    SvREFCNT_inc (base_sv);
    t_wrapper->base_sv = base_sv;
  }
  t_wrapper->base = o_wrapper->base;
  t_wrapper->t = t;
  sv = sv_newmortal ();
  sv_setref_pv (sv, tree_c_class_name, (void *) t_wrapper);
  XPUSHs (sv);
}

void
DESTROY( t_wrapper )
    T_Wrapper *t_wrapper;
PPCODE:
{
    const Marpa_Tree t = t_wrapper->t;
    SvREFCNT_dec (t_wrapper->base_sv);
    marpa_t_unref(t);
    Safefree( t_wrapper );
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::V

void
new( class, t_wrapper )
    char * class;
    T_Wrapper *t_wrapper;
PPCODE:
{
  SV *sv;
  Marpa_Tree t = t_wrapper->t;
  V_Wrapper *v_wrapper;
  Marpa_Value v = marpa_v_new (t);
  PERL_UNUSED_ARG(class);

  if (!v)
    {
      if (!t_wrapper->base->throw)
        {
          XSRETURN_UNDEF;
        }
      croak ("Problem in v->new(): %s", xs_g_error (t_wrapper->base));
    }
  Newx (v_wrapper, 1, V_Wrapper);
  {
    SV *base_sv = t_wrapper->base_sv;
    SvREFCNT_inc (base_sv);
    v_wrapper->base_sv = base_sv;
  }
  v_wrapper->base = t_wrapper->base;
  v_wrapper->v = v;
  v_wrapper->event_queue = newAV ();
  v_wrapper->token_values = newAV ();
  av_fill(v_wrapper->token_values , TOKEN_VALUE_IS_LITERAL);
  v_wrapper->stack = NULL;
  v_wrapper->mode = MARPA_XS_V_MODE_IS_INITIAL;
  v_wrapper->result = 0;
  v_wrapper->trace_values = 0;

  v_wrapper->constants = newAV ();
  /* Reserve position 0 */
  av_push (v_wrapper->constants, &PL_sv_undef);

  v_wrapper->rule_semantics = newAV ();
  v_wrapper->token_semantics = newAV ();
  v_wrapper->nulling_semantics = newAV ();
  v_wrapper->slr = NULL;
  sv = sv_newmortal ();
  sv_setref_pv (sv, value_c_class_name, (void *) v_wrapper);
  XPUSHs (sv);
}

void
DESTROY( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
  const Marpa_Value v = v_wrapper->v;
  SvREFCNT_dec (v_wrapper->base_sv);
  SvREFCNT_dec (v_wrapper->event_queue);
  SvREFCNT_dec (v_wrapper->constants);
  SvREFCNT_dec (v_wrapper->rule_semantics);
  SvREFCNT_dec (v_wrapper->token_semantics);
  SvREFCNT_dec (v_wrapper->nulling_semantics);
  if (v_wrapper->slr) {
    SvREFCNT_dec (v_wrapper->slr);
  }
  if (v_wrapper->stack)
    {
      SvREFCNT_dec (v_wrapper->stack);
    }
  SvREFCNT_dec (v_wrapper->token_values);
  marpa_v_unref (v);
  Safefree (v_wrapper);
}

void
trace_values( v_wrapper, level )
    V_Wrapper *v_wrapper;
    IV level;
PPCODE:
{
  IV old_level = v_wrapper->trace_values;
  v_wrapper->trace_values = level;
  {
    AV *event;
    SV *event_data[3];
    event_data[0] = newSVpvs ("valuator trace level");
    event_data[1] = newSViv (old_level);
    event_data[2] = newSViv (level);
    event = av_make (Dim (event_data), event_data);
    av_push (v_wrapper->event_queue, newRV_noinc ((SV *) event));
  }
  XSRETURN_IV (old_level);
}

void
token_value_set( v_wrapper, token_ix, token_value )
    V_Wrapper *v_wrapper;
    int token_ix;
    SV* token_value;
PPCODE:
{
  if (token_ix <= TOKEN_VALUE_IS_LITERAL)
    {
      croak
        ("Problem in v->token_value_set(): token_value cannot be set for index %ld",
         (long) token_ix);
    }
  SvREFCNT_inc (token_value);
  if (!av_store (v_wrapper->token_values, (I32)token_ix, token_value))
  {
    SvREFCNT_dec (token_value);
  }
}

void
slr_set( v_wrapper, slr )
    V_Wrapper *v_wrapper;
    Scanless_R *slr;
PPCODE:
{
  if (v_wrapper->slr)
    {
      croak ("Problem in v->slr_set(): The SLR is already set");
    }
  SvREFCNT_inc (slr);
  v_wrapper->slr = slr;

  # Throw away the current token values hash
  SvREFCNT_dec (v_wrapper->token_values);

  # Take a reference to the one in the SLR
  v_wrapper->token_values = slr->token_values;
  SvREFCNT_inc (v_wrapper->token_values);
}

void
event( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
    SV* event = av_shift(v_wrapper->event_queue);
    XPUSHs (sv_2mortal (event));
}

void
step( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
  const Marpa_Value v = v_wrapper->v;
  Marpa_Symbol_ID token_id;
  Marpa_Rule_ID rule_id;
  const char *result_string;
  const Marpa_Step_Type step_type = marpa_v_step (v);

  if (v_wrapper->mode == MARPA_XS_V_MODE_IS_INITIAL) {
    v_wrapper->mode = MARPA_XS_V_MODE_IS_RAW;
  }
  if (v_wrapper->mode != MARPA_XS_V_MODE_IS_RAW) {
       if (v_wrapper->stack) {
          croak ("Problem in v->step(): Cannot call when valuator is in 'stack' mode");
       }
  }
  av_clear (v_wrapper->event_queue);
  if (step_type == MARPA_STEP_INACTIVE)
    {
      XSRETURN_EMPTY;
    }
  if (step_type < 0)
    {
      const char *error_message = xs_g_error (v_wrapper->base);
      if (v_wrapper->base->throw)
        {
          croak ("Problem in v->step(): %s", error_message);
        }
      XPUSHs (sv_2mortal
              (newSVpvf ("Problem in v->step(): %s", error_message)));
      XSRETURN (1);
    }
  result_string = step_type_to_string (step_type);
  if (!result_string)
    {
      char *error_message =
        form ("Problem in v->step(): unknown step type %d", step_type);
      set_error_from_string (v_wrapper->base, savepv(error_message));
      if (v_wrapper->base->throw)
        {
          croak ("%s", error_message);
        }
      XPUSHs (sv_2mortal (newSVpv (error_message, 0)));
      XSRETURN (1);
    }
  XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
  if (step_type == MARPA_STEP_TOKEN)
    {
      token_id = marpa_v_token (v);
      XPUSHs (sv_2mortal (newSViv (token_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_token_value (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_result (v))));
    }
  if (step_type == MARPA_STEP_NULLING_SYMBOL)
    {
      token_id = marpa_v_token (v);
      XPUSHs (sv_2mortal (newSViv (token_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_result (v))));
    }
  if (step_type == MARPA_STEP_RULE)
    {
      rule_id = marpa_v_rule (v);
      XPUSHs (sv_2mortal (newSViv (rule_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_0 (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_n (v))));
    }
}

void
stack_mode_set( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
  Marpa_Grammar g = v_wrapper->base->g;
  if (v_wrapper->mode != MARPA_XS_V_MODE_IS_INITIAL)
    {
      if (v_wrapper->stack)
        {
          croak ("Problem in v->stack_mode_set(): Cannot re-set stack mode");
        }
    }
  if (v_create_stack (v_wrapper) == -1)
    {
      croak ("Problem in v->stack_mode_set(): Could not create stack");
    }


  {
    int ix;
    IV ops[3];
    const int highest_rule_id = marpa_g_highest_rule_id (g);
    AV *av = v_wrapper->rule_semantics;
    av_extend (av, highest_rule_id);
    ops[0] = MARPA_OP_PUSH_VALUES;
    ops[1] = MARPA_OP_CALLBACK;
    ops[2] = 0;
    for (ix = 0; ix <= highest_rule_id; ix++)
      {
        SV **p_sv = av_fetch (av, ix, 1);
        if (!p_sv)
          {
            croak
              ("Internal error in v->stack_mode_set(): av_fetch(%p,%ld,1) failed",
               (void *) av, (long) ix);
          }
        sv_setpvn (*p_sv, (char *) ops, Dim(ops)*sizeof (ops[0]));
      }
  }

  { /* Set the default nulling symbol semantics */
    int ix;
    IV ops[2];
    const int highest_symbol_id = marpa_g_highest_symbol_id (g);
    AV *av = v_wrapper->nulling_semantics;
    av_extend (av, highest_symbol_id);
    ops[0] = MARPA_OP_RESULT_IS_UNDEF;
    ops[1] = 0;
    for (ix = 0; ix <= highest_symbol_id; ix++)
      {
        SV **p_sv = av_fetch (av, ix, 1);
        if (!p_sv)
          {
            croak
              ("Internal error in v->stack_mode_set(): av_fetch(%p,%ld,1) failed",
               (void *) av, (long) ix);
          }
        sv_setpvn (*p_sv, (char *) ops, Dim(ops) *sizeof (ops[0]));
      }
  }

  { /* Set the default token semantics */
    int ix;
    IV ops[2];
    const int highest_symbol_id = marpa_g_highest_symbol_id (g);
    AV *av = v_wrapper->token_semantics;
    av_extend (av, highest_symbol_id);
    ops[0] = MARPA_OP_RESULT_IS_TOKEN_VALUE;
    ops[1] = 0;
    for (ix = 0; ix <= highest_symbol_id; ix++)
      {
        SV **p_sv = av_fetch (av, ix, 1);
        if (!p_sv)
          {
            croak
              ("Internal error in v->stack_mode_set(): av_fetch(%p,%ld,1) failed",
               (void *) av, (long) ix);
          }
        sv_setpvn (*p_sv, (char *) ops, Dim(ops)*sizeof (ops[0]));
      }
  }

  XSRETURN_YES;
}

void
rule_register( v_wrapper, rule_id, ... )
     V_Wrapper *v_wrapper;
     Marpa_Rule_ID rule_id;
PPCODE:
{
  /* OP Count is args less two */
  const STRLEN op_count = items - 2;
  STRLEN op_ix;
  STRLEN dummy;
  IV *ops;
  SV *ops_sv;
  AV *rule_semantics = v_wrapper->rule_semantics;

  if (!rule_semantics)
    {
      croak ("Problem in v->rule_register(): valuator is not in stack mode");
    }

  /* Leave room for final 0 */
  ops_sv = newSV ((op_count+1) * sizeof (ops[0]));

  SvPOK_on (ops_sv);
  ops = (IV *) SvPV (ops_sv, dummy);
  for (op_ix = 0; op_ix < op_count; op_ix++)
    {
      ops[op_ix] = SvUV (ST (op_ix+2));
    }
  ops[op_ix] = 0;
  if (!av_store (rule_semantics, (I32) rule_id, ops_sv)) {
     SvREFCNT_dec(ops_sv);
  }
}

void
token_register( v_wrapper, token_id, ... )
     V_Wrapper *v_wrapper;
     Marpa_Symbol_ID token_id;
PPCODE:
{
  /* OP Count is args less two */
  const STRLEN op_count = items - 2;
  STRLEN op_ix;
  STRLEN dummy;
  IV *ops;
  SV *ops_sv;
  AV *token_semantics = v_wrapper->token_semantics;

  if (!token_semantics)
    {
      croak ("Problem in v->token_register(): valuator is not in stack mode");
    }

  /* Leave room for final 0 */
  ops_sv = newSV ((op_count+1) * sizeof (ops[0]));

  SvPOK_on (ops_sv);
  ops = (IV *) SvPV (ops_sv, dummy);
  for (op_ix = 0; op_ix < op_count; op_ix++)
    {
      ops[op_ix] = SvIV (ST (op_ix+2));
    }
  ops[op_ix] = 0;
  if (!av_store (token_semantics, (I32) token_id, ops_sv)) {
     SvREFCNT_dec(ops_sv);
  }
}

void
nulling_symbol_register( v_wrapper, symbol_id, ... )
     V_Wrapper *v_wrapper;
     Marpa_Symbol_ID symbol_id;
PPCODE:
{
  /* OP Count is args less two */
  const STRLEN op_count = items - 2;
  STRLEN op_ix;
  STRLEN dummy;
  IV *ops;
  SV *ops_sv;
  AV *nulling_semantics = v_wrapper->nulling_semantics;

  if (!nulling_semantics)
    {
      croak ("Problem in v->nulling_symbol_register(): valuator is not in stack mode");
    }

  /* Leave room for final 0 */
  ops_sv = newSV ((op_count+1) * sizeof (ops[0]));

  SvPOK_on (ops_sv);
  ops = (IV *) SvPV (ops_sv, dummy);
  for (op_ix = 0; op_ix < op_count; op_ix++)
    {
      ops[op_ix] = SvIV (ST (op_ix+2));
    }
  ops[op_ix] = 0;
  if (!av_store (nulling_semantics, (I32) symbol_id, ops_sv)) {
     SvREFCNT_dec(ops_sv);
  }
}

void
constant_register( v_wrapper, sv )
     V_Wrapper *v_wrapper;
     SV* sv;
PPCODE:
{
  AV *constants = v_wrapper->constants;

  if (!constants)
    {
      croak
        ("Problem in v->constant_register(): valuator is not in stack mode");
    }
  if (SvTAINTED(sv)) {
      croak
        ("Problem in v->constant_register(): Attempt to register a tainted constant with Marpa::R2\n"
        "Marpa::R2 is insecure for use with tainted data\n");
  }

  av_push (constants, SvREFCNT_inc_simple_NN (sv));
  XSRETURN_IV (av_len (constants));
}

void
highest_index( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
  AV* stack = v_wrapper->stack;
  IV length = stack ? av_len(stack) : -1;
  XSRETURN_IV(length);
}

void
absolute( v_wrapper, index )
    V_Wrapper *v_wrapper;
    IV index;
PPCODE:
{
  SV** p_sv;
  AV* stack = v_wrapper->stack;
  if (!stack) { XSRETURN_UNDEF; }
  p_sv = av_fetch(stack, index, 0);
  if (!p_sv) { XSRETURN_UNDEF; }
  XPUSHs (sv_mortalcopy(*p_sv));
}

void
relative( v_wrapper, index )
    V_Wrapper *v_wrapper;
    IV index;
PPCODE:
{
  SV** p_sv;
  AV* stack = v_wrapper->stack;
  if (!stack) { XSRETURN_UNDEF; }
  p_sv = av_fetch(stack, index+v_wrapper->result, 0);
  if (!p_sv) { XSRETURN_UNDEF; }
  XPUSHs (sv_mortalcopy(*p_sv));
}

void
result_set( v_wrapper, sv )
    V_Wrapper *v_wrapper;
    SV* sv;
PPCODE:
{
  IV result_ix;
  SV **p_stored_sv;
  AV *stack = v_wrapper->stack;
  if (!stack)
    {
      croak ("Problem in v->result_set(): valuator is not in stack mode");
    }
  result_ix = v_wrapper->result;
  av_fill(stack, result_ix);

  SvREFCNT_inc (sv);
  p_stored_sv = av_store (stack, result_ix, sv);
  if (!p_stored_sv)
    {
      SvREFCNT_dec (sv);
    }
}

void
stack_step( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{

  av_clear (v_wrapper->event_queue);

  if (v_wrapper->mode != MARPA_XS_V_MODE_IS_STACK)
    {
      if (v_wrapper->stack)
        {
          croak
            ("Problem in v->stack_step(): Cannot call unless valuator is in 'stack' mode");
        }
    }

  while (1)
    {
      Marpa_Step_Type step_type = marpa_v_step (v_wrapper->v);
      switch (step_type)
        {
        case MARPA_STEP_INACTIVE:
          XSRETURN_EMPTY;

          /* NOTREACHED */
        case MARPA_STEP_RULE:
        case MARPA_STEP_NULLING_SYMBOL:
        case MARPA_STEP_TOKEN:
          {
            int ix;
            SV *stack_results[3];
            int stack_offset = v_do_stack_ops (v_wrapper, stack_results);
            if (stack_offset < 0)
              {
                goto NEXT_STEP;
              }
            for (ix = 0; ix < stack_offset; ix++)
              {
                XPUSHs (stack_results[ix]);
              }
            XSRETURN (stack_offset);
          }
          /* NOTREACHED */

        default:
          /* Default is just return the step_type string and let the upper
           * layer deal with it.
           */
          {
            const char *step_type_string = step_type_to_string (step_type);
            if (!step_type_string)
              {
                step_type_string = "Unknown";
              }
            XPUSHs (sv_2mortal (newSVpv (step_type_string, 0)));
            XSRETURN (1);
          }
        }

    NEXT_STEP:;
      if (v_wrapper->trace_values)
        {
          XSRETURN_PV ("trace");
        }
    }
}

void
step_type( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
  const Marpa_Value v = v_wrapper->v;
  const Marpa_Step_Type status = marpa_v_step_type (v);
  const char *result_string;
  result_string = step_type_to_string (status);
  if (!result_string)
    {
      result_string =
        form ("Problem in v->step(): unknown step type %d", status);
      set_error_from_string (v_wrapper->base, savepv (result_string));
      if (v_wrapper->base->throw)
        {
          croak ("%s", result_string);
        }
    }
  XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
}

void
location( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
  const Marpa_Value v = v_wrapper->v;
  const Marpa_Step_Type status = marpa_v_step_type (v);
  if (status == MARPA_STEP_RULE)
    {
      XPUSHs (sv_2mortal (newSViv (marpa_v_rule_start_es_id (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_es_id (v))));
      XSRETURN (2);
    }
  if (status == MARPA_STEP_NULLING_SYMBOL)
    {
      XPUSHs (sv_2mortal (newSViv (marpa_v_token_start_es_id (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_es_id (v))));
      XSRETURN (2);
    }
  if (status == MARPA_STEP_TOKEN)
    {
      XPUSHs (sv_2mortal (newSViv (marpa_v_token_start_es_id (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_es_id (v))));
      XSRETURN (2);
    }
  XSRETURN_EMPTY;
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::G

void
_marpa_g_nsy_is_nulling( g_wrapper, nsy_id )
    G_Wrapper *g_wrapper;
    Marpa_NSY_ID nsy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_nsy_is_nulling (g, nsy_id);
  if (result < 0)
    {
      croak ("Problem in g->_marpa_g_nsy_is_nulling(%d): %s", nsy_id,
             xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
_marpa_g_nsy_is_start( g_wrapper, nsy_id )
    G_Wrapper *g_wrapper;
    Marpa_NSY_ID nsy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_nsy_is_start (g, nsy_id);
  if (result < 0)
    {
      croak ("Invalid nsy %d", nsy_id);
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

# Marpa_Symbol_ID
void
_marpa_g_source_xsy( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  Marpa_Symbol_ID source_xsy = _marpa_g_source_xsy (g, symbol_id);
  if (source_xsy < -1)
    {
      croak ("problem with g->_marpa_g_source_xsy: %s", xs_g_error (g_wrapper));
    }
  if (source_xsy < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (source_xsy)));
}

# Marpa_Rule_ID
void
_marpa_g_nsy_lhs_xrl( g_wrapper, nsy_id )
    G_Wrapper *g_wrapper;
    Marpa_NSY_ID nsy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  Marpa_Rule_ID rule_id = _marpa_g_nsy_lhs_xrl (g, nsy_id);
  if (rule_id < -1)
    {
      croak ("problem with g->_marpa_g_nsy_lhs_xrl: %s",
             xs_g_error (g_wrapper));
    }
  if (rule_id < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (rule_id)));
}

# Marpa_Rule_ID
void
_marpa_g_nsy_xrl_offset( g_wrapper, nsy_id )
    G_Wrapper *g_wrapper;
    Marpa_NSY_ID nsy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int offset = _marpa_g_nsy_xrl_offset (g, nsy_id);
  if (offset == -1)
    {
      XSRETURN_UNDEF;
    }
  if (offset < 0)
    {
      croak ("problem with g->_marpa_g_nsy_xrl_offset: %s",
             xs_g_error (g_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (offset)));
}

# int
void
_marpa_g_virtual_start( g_wrapper, irl_id )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_virtual_start (g, irl_id);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in g->_marpa_g_virtual_start(%d): %s", irl_id,
             xs_g_error (g_wrapper));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
}

# int
void
_marpa_g_virtual_end( g_wrapper, irl_id )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_virtual_end (g, irl_id);
  if (result <= -2)
    {
      croak ("Problem in g->_marpa_g_virtual_end(%d): %s", irl_id,
             xs_g_error (g_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_g_rule_is_used( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_rule_is_used (g, rule_id);
  if (result < 0)
    {
      croak ("Problem in g->_marpa_g_rule_is_used(%d): %s", rule_id,
             xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
_marpa_g_irl_is_virtual_lhs( g_wrapper, irl_id )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_irl_is_virtual_lhs (g, irl_id);
  if (result < 0)
    {
      croak ("Problem in g->_marpa_g_irl_is_virtual_lhs(%d): %s", irl_id,
             xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
_marpa_g_irl_is_virtual_rhs( g_wrapper, irl_id )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_irl_is_virtual_rhs (g, irl_id);
  if (result < 0)
    {
      croak ("Problem in g->_marpa_g_irl_is_virtual_rhs(%d): %s", irl_id,
             xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

# Marpa_Rule_ID
void
_marpa_g_real_symbol_count( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_real_symbol_count(g, rule_id);
  if (result <= -2)
    {
      croak ("Problem in g->_marpa_g_real_symbol_count(%d): %s", rule_id,
             xs_g_error (g_wrapper));
    }
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# Marpa_Rule_ID
void
_marpa_g_source_xrl ( g_wrapper, irl_id )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_source_xrl (g, irl_id);
  if (result <= -2)
    {
      croak ("Problem in g->_marpa_g_source_xrl (%d): %s", irl_id,
             xs_g_error (g_wrapper));
    }
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# Marpa_Rule_ID
void
_marpa_g_irl_semantic_equivalent( g_wrapper, irl_id )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_irl_semantic_equivalent (g, irl_id);
  if (result <= -2)
    {
      croak ("Problem in g->_marpa_g_irl_semantic_equivalent(%d): %s", irl_id,
             xs_g_error (g_wrapper));
    }
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_g_ahm_count( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_ahm_count (g);
  if (result <= -2)
    {
      croak ("Problem in g->_marpa_g_ahm_count(): %s", xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_g_irl_count( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_irl_count (g);
  if (result < -1)
    {
      croak ("Problem in g->_marpa_g_irl_count(): %s", xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_g_nsy_count( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_nsy_count (g);
  if (result < -1)
    {
      croak ("Problem in g->_marpa_g_nsy_count(): %s", xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# Marpa_IRL_ID
void
_marpa_g_ahm_irl( g_wrapper, item_id )
    G_Wrapper *g_wrapper;
    Marpa_AHM_ID item_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_ahm_irl(g, item_id);
    if (result < 0) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

 # -1 is a valid return value, so -2 indicates an error
# int
void
_marpa_g_ahm_position( g_wrapper, item_id )
    G_Wrapper *g_wrapper;
    Marpa_AHM_ID item_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_ahm_position(g, item_id);
    if (result <= -2) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

 # -1 is a valid return value, and -2 indicates an error
# Marpa_Symbol_ID
void
_marpa_g_ahm_postdot( g_wrapper, item_id )
    G_Wrapper *g_wrapper;
    Marpa_AHM_ID item_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_ahm_postdot(g, item_id);
    if (result <= -2) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::R

void
_marpa_r_is_use_leo_set( r_wrapper, boolean )
    R_Wrapper *r_wrapper;
    int boolean;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int result = _marpa_r_is_use_leo_set (r, (boolean ? TRUE : FALSE));
  if (result < 0)
    {
      croak ("Problem in _marpa_r_is_use_leo_set(): %s",
             xs_g_error(r_wrapper->base));
    }
  XSRETURN_YES;
}

void
_marpa_r_is_use_leo( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int boolean = _marpa_r_is_use_leo (r);
  if (boolean < 0)
    {
      croak ("Problem in _marpa_r_is_use_leo(): %s", xs_g_error(r_wrapper->base));
    }
  if (boolean)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
_marpa_r_earley_set_size( r_wrapper, set_ordinal )
    R_Wrapper *r_wrapper;
    Marpa_Earley_Set_ID set_ordinal;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int earley_set_size = _marpa_r_earley_set_size (r, set_ordinal);
      if (earley_set_size < 0) {
          croak ("Problem in r->_marpa_r_earley_set_size(): %s", xs_g_error(r_wrapper->base));
        }
      XPUSHs (sv_2mortal (newSViv (earley_set_size)));
    }

void
_marpa_r_earley_set_trace( r_wrapper, set_ordinal )
    R_Wrapper *r_wrapper;
    Marpa_Earley_Set_ID set_ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    Marpa_AHM_ID result = _marpa_r_earley_set_trace(
        r, set_ordinal );
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) { croak("problem with r->_marpa_r_earley_set_trace: %s", xs_g_error(r_wrapper->base)); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
_marpa_r_earley_item_trace( r_wrapper, item_ordinal )
    R_Wrapper *r_wrapper;
    Marpa_Earley_Item_ID item_ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    Marpa_AHM_ID result = _marpa_r_earley_item_trace(
        r, item_ordinal);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) { croak("problem with r->_marpa_r_earley_item_trace: %s", xs_g_error(r_wrapper->base)); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
_marpa_r_earley_item_origin( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int origin_earleme = _marpa_r_earley_item_origin (r);
      if (origin_earleme < 0)
        {
      croak ("Problem with r->_marpa_r_earley_item_origin(): %s",
                 xs_g_error(r_wrapper->base));
        }
      XPUSHs (sv_2mortal (newSViv (origin_earleme)));
    }

void
_marpa_r_first_token_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int token_id = _marpa_r_first_token_link_trace(r);
    if (token_id <= -2) { croak("Trace first token link problem: %s", xs_g_error(r_wrapper->base)); }
    if (token_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(token_id) ) );
    }

void
_marpa_r_next_token_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int token_id = _marpa_r_next_token_link_trace(r);
    if (token_id <= -2) { croak("Trace next token link problem: %s", xs_g_error(r_wrapper->base)); }
    if (token_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(token_id) ) );
    }

void
_marpa_r_first_completion_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int AHFA_state_id = _marpa_r_first_completion_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace first completion link problem: %s", xs_g_error(r_wrapper->base)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
_marpa_r_next_completion_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int AHFA_state_id = _marpa_r_next_completion_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace next completion link problem: %s", xs_g_error(r_wrapper->base)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
_marpa_r_first_leo_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int AHFA_state_id = _marpa_r_first_leo_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace first completion link problem: %s", xs_g_error(r_wrapper->base)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
_marpa_r_next_leo_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int AHFA_state_id = _marpa_r_next_leo_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace next completion link problem: %s", xs_g_error(r_wrapper->base)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
_marpa_r_source_predecessor_state( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int state_id = _marpa_r_source_predecessor_state(r);
    if (state_id <= -2) { croak("Problem finding trace source predecessor state: %s", xs_g_error(r_wrapper->base)); }
    if (state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(state_id) ) );
    }

void
_marpa_r_source_leo_transition_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int symbol_id = _marpa_r_source_leo_transition_symbol(r);
    if (symbol_id <= -2) { croak("Problem finding trace source leo transition symbol: %s", xs_g_error(r_wrapper->base)); }
    if (symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(symbol_id) ) );
    }

void
_marpa_r_source_token( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int value;
    int symbol_id = _marpa_r_source_token(r, &value);
    if (symbol_id == -1) { XSRETURN_UNDEF; }
    if (symbol_id < 0) { croak("Problem with r->source_token(): %s", xs_g_error(r_wrapper->base)); }
        XPUSHs( sv_2mortal( newSViv(symbol_id) ) );
        XPUSHs( sv_2mortal( newSViv(value) ) );
    }

void
_marpa_r_source_middle( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int middle = _marpa_r_source_middle(r);
    if (middle <= -2) { croak("Problem with r->source_middle(): %s", xs_g_error(r_wrapper->base)); }
    if (middle == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(middle) ) );
    }

void
_marpa_r_first_postdot_item_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int postdot_symbol_id = _marpa_r_first_postdot_item_trace(r);
    if (postdot_symbol_id <= -2) { croak("Trace first postdot item problem: %s", xs_g_error(r_wrapper->base)); }
    if (postdot_symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(postdot_symbol_id) ) );
    }

void
_marpa_r_next_postdot_item_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int postdot_symbol_id = _marpa_r_next_postdot_item_trace(r);
    if (postdot_symbol_id <= -2) { croak("Trace next postdot item problem: %s", xs_g_error(r_wrapper->base)); }
    if (postdot_symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(postdot_symbol_id) ) );
    }

void
_marpa_r_postdot_symbol_trace( r_wrapper, symid )
    R_Wrapper *r_wrapper;
    Marpa_Symbol_ID symid;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int postdot_symbol_id = _marpa_r_postdot_symbol_trace (r, symid);
  if (postdot_symbol_id == -1)
    {
      XSRETURN_UNDEF;
    }
  if (postdot_symbol_id <= 0)
    {
      croak ("Problem in r->postdot_symbol_trace: %s", xs_g_error(r_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (postdot_symbol_id)));
}

void
_marpa_r_leo_base_state( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int leo_base_state = _marpa_r_leo_base_state (r);
      if (leo_base_state == -1) { XSRETURN_UNDEF; }
      if (leo_base_state < 0) {
          croak ("Problem in r->leo_base_state(): %s", xs_g_error(r_wrapper->base));
        }
      XPUSHs (sv_2mortal (newSViv (leo_base_state)));
    }

void
_marpa_r_leo_base_origin( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int leo_base_origin = _marpa_r_leo_base_origin (r);
      if (leo_base_origin == -1) { XSRETURN_UNDEF; }
      if (leo_base_origin < 0) {
          croak ("Problem in r->leo_base_origin(): %s", xs_g_error(r_wrapper->base));
        }
      XPUSHs (sv_2mortal (newSViv (leo_base_origin)));
    }

void
_marpa_r_trace_earley_set( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int trace_earley_set = _marpa_r_trace_earley_set (r);
      if (trace_earley_set < 0) {
          croak ("Problem in r->trace_earley_set(): %s", xs_g_error(r_wrapper->base));
        }
      XPUSHs (sv_2mortal (newSViv (trace_earley_set)));
    }

void
_marpa_r_postdot_item_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int postdot_item_symbol = _marpa_r_postdot_item_symbol (r);
      if (postdot_item_symbol < 0) {
          croak ("Problem in r->postdot_item_symbol(): %s", xs_g_error(r_wrapper->base));
        }
      XPUSHs (sv_2mortal (newSViv (postdot_item_symbol)));
    }

void
_marpa_r_leo_predecessor_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int leo_predecessor_symbol = _marpa_r_leo_predecessor_symbol (r);
      if (leo_predecessor_symbol == -1) { XSRETURN_UNDEF; }
      if (leo_predecessor_symbol < 0) {
          croak ("Problem in r->leo_predecessor_symbol(): %s", xs_g_error(r_wrapper->base));
        }
      XPUSHs (sv_2mortal (newSViv (leo_predecessor_symbol)));
    }

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::B

 # Move of bocage modules to gp_generate.pl is now complete

void
_marpa_b_and_node_token( b_wrapper, and_node_id )
     B_Wrapper *b_wrapper;
     Marpa_And_Node_ID and_node_id;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int value = -1;
  int result = _marpa_b_and_node_token (b, and_node_id, &value);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_and_node_symbol(): %s",
             xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
  XPUSHs (sv_2mortal (newSViv (value)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::O

# int
void
_marpa_o_and_node_order_get( o_wrapper, or_node_id, and_ix )
    O_Wrapper *o_wrapper;
    Marpa_Or_Node_ID or_node_id;
    int and_ix;
PPCODE:
{
    Marpa_Order o = o_wrapper->o;
    int result;
    result = _marpa_o_and_order_get(o, or_node_id, and_ix);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in o->_marpa_o_and_node_order_get(): %s", xs_g_error(o_wrapper->base));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
}

void
_marpa_o_or_node_and_node_count( o_wrapper, or_node_id )
    O_Wrapper *o_wrapper;
    Marpa_Or_Node_ID or_node_id;
PPCODE:
{
    Marpa_Order o = o_wrapper->o;
    int count = _marpa_o_or_node_and_node_count(o, or_node_id);
    if (count < 0) { croak("Invalid or node ID %d", or_node_id); }
    XPUSHs( sv_2mortal( newSViv(count) ) );
}

void
_marpa_o_or_node_and_node_ids( o_wrapper, or_node_id )
    O_Wrapper *o_wrapper;
    Marpa_Or_Node_ID or_node_id;
PPCODE:
{
    Marpa_Order o = o_wrapper->o;
    int count = _marpa_o_or_node_and_node_count(o, or_node_id);
    if (count == -1) {
      if (GIMME != G_ARRAY) { XSRETURN_NO; }
      count = 0; /* will return an empty array */
    }
    if (count < 0) { croak("Invalid or node ID %d", or_node_id); }
    {
        int ix;
        EXTEND(SP, count);
        for (ix = 0; ix < count; ix++) {
            Marpa_And_Node_ID and_node_id
                = _marpa_o_or_node_and_node_id_by_ix(o, or_node_id, ix);
            PUSHs( sv_2mortal( newSViv(and_node_id) ) );
        }
    }
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::T

# int
void
_marpa_t_size( t_wrapper )
    T_Wrapper *t_wrapper;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = _marpa_t_size (t);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->_marpa_t_size(): %s", xs_g_error(t_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_t_nook_or_node( t_wrapper, nook_id )
    T_Wrapper *t_wrapper;
    Marpa_Nook_ID nook_id;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = _marpa_t_nook_or_node (t, nook_id);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->_marpa_t_nook_or_node(): %s", xs_g_error(t_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_t_nook_choice( t_wrapper, nook_id )
    T_Wrapper *t_wrapper;
    Marpa_Nook_ID nook_id;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = _marpa_t_nook_choice (t, nook_id);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->_marpa_t_nook_choice(): %s", xs_g_error(t_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_t_nook_parent( t_wrapper, nook_id )
    T_Wrapper *t_wrapper;
    Marpa_Nook_ID nook_id;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = _marpa_t_nook_parent (t, nook_id);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->_marpa_t_nook_parent(): %s", xs_g_error(t_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_t_nook_is_cause( t_wrapper, nook_id )
    T_Wrapper *t_wrapper;
    Marpa_Nook_ID nook_id;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = _marpa_t_nook_is_cause (t, nook_id);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->_marpa_t_nook_is_cause(): %s", xs_g_error(t_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_t_nook_cause_is_ready( t_wrapper, nook_id )
    T_Wrapper *t_wrapper;
    Marpa_Nook_ID nook_id;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = _marpa_t_nook_cause_is_ready (t, nook_id);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->_marpa_t_nook_cause_is_ready(): %s", xs_g_error(t_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}


# int
void
_marpa_t_nook_is_predecessor( t_wrapper, nook_id )
    T_Wrapper *t_wrapper;
    Marpa_Nook_ID nook_id;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = _marpa_t_nook_is_predecessor (t, nook_id);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->_marpa_t_nook_is_predecessor(): %s", xs_g_error(t_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

# int
void
_marpa_t_nook_predecessor_is_ready( t_wrapper, nook_id )
    T_Wrapper *t_wrapper;
    Marpa_Nook_ID nook_id;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = _marpa_t_nook_predecessor_is_ready (t, nook_id);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->_marpa_t_nook_predecessor_is_ready(): %s",
             xs_g_error(t_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::V

void
_marpa_v_trace( v_wrapper, flag )
    V_Wrapper *v_wrapper;
    int flag;
PPCODE:
{
  const Marpa_Value v = v_wrapper->v;
  int status;
  status = _marpa_v_trace (v, flag);
  if (status == -1)
    {
      XSRETURN_UNDEF;
    }
  if (status < 0)
    {
      croak ("Problem in v->trace(): %s", xs_g_error(v_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (status)));
}

void
_marpa_v_nook( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
  const Marpa_Value v = v_wrapper->v;
  int status;
  status = _marpa_v_nook (v);
  if (status == -1)
    {
      XSRETURN_UNDEF;
    }
  if (status < 0)
    {
      croak ("Problem in v->_marpa_v_nook(): %s", xs_g_error(v_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (status)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::SLG

void
new( class, l0_sv, g1_sv )
    char * class;
    SV *l0_sv;
    SV *g1_sv;
PPCODE:
{
  SV* new_sv;
  Scanless_G *slg;
  PERL_UNUSED_ARG(class);

  if (!sv_isa (l0_sv, "Marpa::R2::Thin::G"))
    {
      croak ("Problem in u->new(): L0 arg is not of type Marpa::R2::Thin::G");
    }
  if (!sv_isa (g1_sv, "Marpa::R2::Thin::G"))
    {
      croak ("Problem in u->new(): G1 arg is not of type Marpa::R2::Thin::G");
    }
  Newx (slg, 1, Scanless_G);

  slg->g1_sv = g1_sv;
  SvREFCNT_inc (g1_sv);

  # These do not need references, because parent objects
  # hold references to them
  SET_G_WRAPPER_FROM_G_SV(slg->g1_wrapper, g1_sv)
  slg->g1 = slg->g1_wrapper->g;
  slg->precomputed = 0;

  # Copy and take references to the parent objects
  Newx(slg->lexers, 1, Lexer*);
  # After testing, start with a larger buffer size, perhaps 8
  slg->lexer_buffer_size = 1;
  slg->lexer_count = 0;
  lexer_add(slg, l0_sv);

  {
    Marpa_Symbol_ID symbol_id;
    Marpa_Symbol_ID g1_symbol_count = marpa_g_highest_symbol_id (slg->g1) + 1;
    Newx (slg->symbol_g_properties, g1_symbol_count, struct symbol_g_properties);
    for (symbol_id = 0; symbol_id < g1_symbol_count; symbol_id++) {
        slg->symbol_g_properties[symbol_id].priority = 0;
        slg->symbol_g_properties[symbol_id].latm = 0;
        slg->symbol_g_properties[symbol_id].pause_before = 0;
        slg->symbol_g_properties[symbol_id].pause_after = 0;
    }
  }

  new_sv = sv_newmortal ();
  sv_setref_pv (new_sv, scanless_g_class_name, (void *) slg);
  XPUSHs (new_sv);
}

void
DESTROY( slg )
    Scanless_G *slg;
PPCODE:
{
  int i;
  for (i = 0; i < slg->lexer_count; i++)
    {
      Lexer *lexer = slg->lexers[i];
      if (lexer)
        {
          lexer_destroy (lexer);
        }
    }
  Safefree (slg->lexers);
  SvREFCNT_dec (slg->g1_sv);
  Safefree (slg->symbol_g_properties);
  Safefree (slg);
}

void
lexer_add( slg, lexer_sv )
  Scanless_G *slg;
    SV *lexer_sv;
PPCODE:
{
  Lexer *lexer;

  if (!sv_isa (lexer_sv, "Marpa::R2::Thin::G"))
    {
      croak ("Problem in u->new(): L0 arg is not of type Marpa::R2::Thin::G");
    }

  lexer = lexer_add (slg, lexer_sv);
  XSRETURN_IV ((IV) lexer->index);
}

 #  it does not create a new one
 # 
void
g1( slg )
    Scanless_G *slg;
PPCODE:
{
  /* Not mortalized because,
   * held for the length of the scanless object.
   */
  XPUSHs (sv_2mortal (SvREFCNT_inc_NN (slg->g1_sv)));
}

void
lexer_rule_to_g1_lexeme_set( slg, lexer_ix, lexer_rule, g1_lexeme, assertion_id )
    Scanless_G *slg;
    int lexer_ix;
    Marpa_Rule_ID lexer_rule;
    Marpa_Symbol_ID g1_lexeme;
    Marpa_Assertion_ID assertion_id;
PPCODE:
{
  Marpa_Rule_ID highest_lexer_rule_id;
  Marpa_Symbol_ID highest_g1_symbol_id;
  Marpa_Assertion_ID highest_assertion_id;
  Lexer *lexer;

  if (lexer_ix < 0 || lexer_ix >= slg->lexer_count)
    {
      croak
        ("slg->lexer_rule_to_g1_lexeme_set(%ld, %ld, %ld) called for invalid lexer(%ld)",
         (long) lexer_rule, (long) lexer_ix, (long) g1_lexeme, (long) lexer_ix);
    }
  lexer = slg->lexers[lexer_ix];
  highest_lexer_rule_id = marpa_g_highest_rule_id (lexer->g_wrapper->g);
  highest_g1_symbol_id = marpa_g_highest_symbol_id (slg->g1);
  highest_assertion_id = marpa_g_highest_zwa_id (lexer->g_wrapper->g);
  if (slg->precomputed)
    {
      croak
        ("slg->lexer_rule_to_g1_lexeme_set(%ld, %ld, %ld) called after SLG is precomputed",
         (long) lexer_rule, (long) lexer_ix, (long) g1_lexeme);
    }
  if (lexer_rule > highest_lexer_rule_id)
    {
      croak
        ("Problem in slg->lexer_rule_to_g1_lexeme_set(%ld, %ld, %ld): rule ID was %ld, but highest lexer rule ID = %ld",
         (long) lexer_rule, (long) lexer_ix,
         (long) g1_lexeme, (long) lexer_rule, (long) highest_lexer_rule_id);
    }
  if (g1_lexeme > highest_g1_symbol_id)
    {
      croak
        ("Problem in slg->lexer_rule_to_g1_lexeme_set(%ld, %ld, %ld): symbol ID was %ld, but highest G1 symbol ID = %ld",
         (long) lexer_rule, (long) lexer_ix,
         (long) g1_lexeme, (long) lexer_rule, (long) highest_g1_symbol_id);
    }
  if (assertion_id > highest_assertion_id)
    {
      croak
        ("Problem in slg->lexer_rule_to_g1_lexeme_set(%ld, %ld, %ld, %ld):"
        "assertion ID was %ld, but highest assertion ID = %ld",
         (long) lexer_rule, (long) lexer_ix,
         (long) g1_lexeme, (long) lexer_rule,
         (long) assertion_id,
         (long) highest_assertion_id);
    }
  if (lexer_rule < -2)
    {
      croak
        ("Problem in slg->lexer_rule_to_g1_lexeme_set(%ld, %ld, %ld): rule ID was %ld, a disallowed value",
         (long) lexer_rule, (long) lexer_ix, (long) g1_lexeme,
         (long) lexer_rule);
    }
  if (g1_lexeme < -2)
    {
      croak
        ("Problem in slg->lexer_rule_to_g1_lexeme_set(%ld, %ld, %ld): symbol ID was %ld, a disallowed value",
         (long) lexer_rule, (long) lexer_ix, (long) g1_lexeme,
         (long) g1_lexeme);
    }
  if (assertion_id < -2)
    {
      croak
        ("Problem in slg->lexer_rule_to_g1_lexeme_set(%ld, %ld, %ld, %ld): assertion ID was %ld, a disallowed value",
         (long) lexer_rule, (long) lexer_ix, (long) g1_lexeme,
         (long) g1_lexeme, (long)assertion_id);
    }
  if (lexer_rule >= 0) {
      lexer->lexer_rule_to_g1_lexeme[lexer_rule] = g1_lexeme;
  }
  if (g1_lexeme >= 0) {
      lexer->g1_lexeme_to_assertion[g1_lexeme] = assertion_id;
  }
  XSRETURN_YES;
}

void
g1_lexeme_priority_set( slg, g1_lexeme, priority )
    Scanless_G *slg;
    Marpa_Symbol_ID g1_lexeme;
    int priority;
PPCODE:
{
  Marpa_Symbol_ID highest_g1_symbol_id = marpa_g_highest_symbol_id (slg->g1);
    if (slg->precomputed)
      {
        croak
          ("slg->lexeme_priority_set(%ld, %ld) called after SLG is precomputed",
           (long) g1_lexeme, (long) priority);
      }
    if (g1_lexeme > highest_g1_symbol_id) 
    {
      croak
        ("Problem in slg->g1_lexeme_priority_set(%ld, %ld): symbol ID was %ld, but highest G1 symbol ID = %ld",
         (long) g1_lexeme,
         (long) priority,
         (long) g1_lexeme,
         (long) highest_g1_symbol_id
         );
    }
    if (g1_lexeme < 0) {
      croak
        ("Problem in slg->g1_lexeme_priority(%ld, %ld): symbol ID was %ld, a disallowed value",
         (long) g1_lexeme,
         (long) priority,
         (long) g1_lexeme);
    }
  slg->symbol_g_properties[g1_lexeme].priority = priority;
  XSRETURN_YES;
}

void
g1_lexeme_priority( slg, g1_lexeme )
    Scanless_G *slg;
    Marpa_Symbol_ID g1_lexeme;
PPCODE:
{
  Marpa_Symbol_ID highest_g1_symbol_id = marpa_g_highest_symbol_id (slg->g1);
    if (g1_lexeme > highest_g1_symbol_id) 
    {
      croak
        ("Problem in slg->g1_lexeme_priority(%ld): symbol ID was %ld, but highest G1 symbol ID = %ld",
         (long) g1_lexeme,
         (long) g1_lexeme,
         (long) highest_g1_symbol_id
         );
    }
    if (g1_lexeme < 0) {
      croak
        ("Problem in slg->g1_lexeme_priority(%ld): symbol ID was %ld, a disallowed value",
         (long) g1_lexeme,
         (long) g1_lexeme);
    }
  XSRETURN_IV( slg->symbol_g_properties[g1_lexeme].priority);
}

void
g1_lexeme_pause_set( slg, g1_lexeme, pause )
    Scanless_G *slg;
    Marpa_Symbol_ID g1_lexeme;
    int pause;
PPCODE:
{
  Marpa_Symbol_ID highest_g1_symbol_id = marpa_g_highest_symbol_id (slg->g1);
    struct symbol_g_properties * g_properties = slg->symbol_g_properties + g1_lexeme;
    if (slg->precomputed)
      {
        croak
          ("slg->lexeme_pause_set(%ld, %ld) called after SLG is precomputed",
           (long) g1_lexeme, (long) pause);
      }
    if (g1_lexeme > highest_g1_symbol_id) 
    {
      croak
        ("Problem in slg->g1_lexeme_pause_set(%ld, %ld): symbol ID was %ld, but highest G1 symbol ID = %ld",
         (long) g1_lexeme,
         (long) pause,
         (long) g1_lexeme,
         (long) highest_g1_symbol_id
         );
    }
    if (g1_lexeme < 0) {
      croak
        ("Problem in slg->lexeme_pause_set(%ld, %ld): symbol ID was %ld, a disallowed value",
         (long) g1_lexeme,
         (long) pause,
         (long) g1_lexeme);
    }
    switch (pause) {
    case 0: /* No pause */
        g_properties->pause_after = 0;
        g_properties->pause_before = 0;
        break;
    case 1: /* Pause after */
        g_properties->pause_after = 1;
        g_properties->pause_before = 0;
        break;
    case -1: /* Pause before */
        g_properties->pause_after = 0;
        g_properties->pause_before = 1;
        break;
    default:
      croak
        ("Problem in slg->lexeme_pause_set(%ld, %ld): value of pause must be -1,0 or 1",
         (long) g1_lexeme,
         (long) pause);
    }
  XSRETURN_YES;
}

void
g1_lexeme_latm_set( slg, g1_lexeme, latm )
    Scanless_G *slg;
    Marpa_Symbol_ID g1_lexeme;
    int latm;
PPCODE:
{
  Marpa_Symbol_ID highest_g1_symbol_id = marpa_g_highest_symbol_id (slg->g1);
    struct symbol_g_properties * g_properties = slg->symbol_g_properties + g1_lexeme;
    if (slg->precomputed)
      {
        croak
          ("slg->lexeme_latm_set(%ld, %ld) called after SLG is precomputed",
           (long) g1_lexeme, (long) latm);
      }
    if (g1_lexeme > highest_g1_symbol_id) 
    {
      croak
        ("Problem in slg->g1_lexeme_latm(%ld, %ld): symbol ID was %ld, but highest G1 symbol ID = %ld",
         (long) g1_lexeme,
         (long) latm,
         (long) g1_lexeme,
         (long) highest_g1_symbol_id
         );
    }
    if (g1_lexeme < 0) {
      croak
        ("Problem in slg->lexeme_latm(%ld, %ld): symbol ID was %ld, a disallowed value",
         (long) g1_lexeme,
         (long) latm,
         (long) g1_lexeme);
    }
    switch (latm) {
    case 0: case 1:
        g_properties->latm = latm;
        break;
    default:
      croak
        ("Problem in slg->lexeme_latm(%ld, %ld): value of latm must be 0 or 1",
         (long) g1_lexeme,
         (long) latm);
    }
  XSRETURN_YES;
}

void
precompute( slg )
    Scanless_G *slg;
PPCODE:
{
  /* Currently this routine does nothing except set a flag to
   * enforce the * separation of the precomputation phase
   * from the main processing.
   */
  if (!slg->precomputed)
    {
      /*
       * Ensure that I can call this multiple times safely, even
       * if I do some real processing here.
       */
      slg->precomputed = 1;
    }
  XSRETURN_IV (1);
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::SLR

void
new( class, slg_sv, r1_sv )
    char * class;
    SV *slg_sv;
    SV *r1_sv;
PPCODE:
{
  SV *new_sv;
  Scanless_R *slr;
  Scanless_G *slg;
  PERL_UNUSED_ARG(class);

  if (!sv_isa (slg_sv, "Marpa::R2::Thin::SLG"))
    {
      croak
        ("Problem in u->new(): slg arg is not of type Marpa::R2::Thin::SLG");
    }
  if (!sv_isa (r1_sv, "Marpa::R2::Thin::R"))
    {
      croak ("Problem in u->new(): r1 arg is not of type Marpa::R2::Thin::R");
    }
  Newx (slr, 1, Scanless_R);

  slr->throw = 1;
  slr->trace_lexers = 0;
  slr->trace_terminals = 0;
  slr->r0 = NULL;

# Copy and take references to the "parent objects",
# the ones responsible for holding references.
  slr->slg_sv = slg_sv;
  SvREFCNT_inc (slg_sv);
  slr->r1_sv = r1_sv;
  SvREFCNT_inc (r1_sv);

# These do not need references, because parent objects
# hold references to them
  SET_R_WRAPPER_FROM_R_SV (slr->r1_wrapper, r1_sv);
  SET_SLG_FROM_SLG_SV (slg, slg_sv);
  if (!slg->precomputed)
    {
      croak
        ("Problem in u->new(): Attempted to create SLIF recce from unprecomputed SLIF grammar");
    }
  slr->slg = slg;
  slr->r1 = slr->r1_wrapper->r;
  SET_G_WRAPPER_FROM_G_SV (slr->g1_wrapper, slr->r1_wrapper->base_sv);

  slr->start_of_lexeme = 0;
  slr->end_of_lexeme = 0;

  slr->perl_pos = 0;
  slr->perl_pos_hits = 0;
  slr->last_perl_pos = -1;
  slr->problem_pos = -1;

  slr->token_values = newAV ();
  av_fill (slr->token_values, TOKEN_VALUE_IS_LITERAL);

  {
    Marpa_Symbol_ID symbol_id;
    const Marpa_Symbol_ID g1_symbol_count =
      marpa_g_highest_symbol_id (slg->g1) + 1;
    Newx (slr->symbol_r_properties, g1_symbol_count,
          struct symbol_r_properties);
    for (symbol_id = 0; symbol_id < g1_symbol_count; symbol_id++)
      {
        const struct symbol_g_properties *g_properties =
          slg->symbol_g_properties + symbol_id;
        slr->symbol_r_properties[symbol_id].pause_before_active =
          g_properties->pause_before;
        slr->symbol_r_properties[symbol_id].pause_after_active =
          g_properties->pause_after;
      }
  }

  slr->lexer_start_pos = slr->perl_pos;
  slr->lexer_read_result = 0;
  slr->r1_earleme_complete_result = 0;
  slr->start_of_pause_lexeme = -1;
  slr->end_of_pause_lexeme = -1;
  slr->pause_lexeme = -1;

  slr->pos_db = 0;
  slr->pos_db_logical_size = -1;
  slr->pos_db_physical_size = -1;

  slr->input_symbol_id = -1;
  slr->input = newSVpvn ("", 0);
  slr->end_pos = 0;
  slr->too_many_earley_items = -1;
  slr->current_lexer = slg->lexers[0];
  slr->next_lexer = slr->current_lexer;
  slr->fallback_lexer = slr->current_lexer;

  slr->gift = marpa__slr_new();

  new_sv = sv_newmortal ();
  sv_setref_pv (new_sv, scanless_r_class_name, (void *) slr);
  XPUSHs (new_sv);
}

void
DESTROY( slr )
    Scanless_R *slr;
PPCODE:
{
  const Marpa_Recce r0 = slr->r0;
  if (r0)
    {
      marpa_r_unref (r0);
    }

   marpa__slr_unref(slr->gift);

  Safefree(slr->pos_db);
  SvREFCNT_dec (slr->slg_sv);
  SvREFCNT_dec (slr->r1_sv);
  Safefree(slr->symbol_r_properties);
  if (slr->token_values)
    {
      SvREFCNT_dec ((SV *) slr->token_values);
    }
  SvREFCNT_dec (slr->input);
  Safefree (slr);
}

void throw_set(slr, throw_setting)
    Scanless_R *slr;
    int throw_setting;
PPCODE:
{
  slr->throw = throw_setting;
}

void
trace_lexers( slr, new_level )
    Scanless_R *slr;
    int new_level;
PPCODE:
{
  IV old_level = slr->trace_lexers;
  slr->trace_lexers = new_level;
  if (new_level)
    {
      warn
	("Setting trace_lexers to %ld; was %ld",
	 (long) new_level, (long) old_level);
    }
  XSRETURN_IV (old_level);
}

void
trace_terminals( slr, new_level )
    Scanless_R *slr;
    int new_level;
PPCODE:
{
  IV old_level = slr->trace_terminals;
  slr->trace_terminals = new_level;
  XSRETURN_IV(old_level);
}

void
earley_item_warning_threshold( slr )
    Scanless_R *slr;
PPCODE:
{
  XSRETURN_IV(slr->too_many_earley_items);
}

void
earley_item_warning_threshold_set( slr, too_many_earley_items )
    Scanless_R *slr;
    int too_many_earley_items;
PPCODE:
{
  slr->too_many_earley_items = too_many_earley_items;
}

 #  Always returns the same SV for a given Scanless recce object -- 
 #  it does not create a new one
 # 
void
g1( slr )
    Scanless_R *slr;
PPCODE:
{
  XPUSHs (sv_2mortal (SvREFCNT_inc_NN ( slr->r1_wrapper->base_sv)));
}

void
pos( slr )
    Scanless_R *slr;
PPCODE:
{
  XSRETURN_IV(slr->perl_pos);
}

void
pos_set( slr, start_pos_sv, length_sv )
    Scanless_R *slr;
     SV* start_pos_sv;
     SV* length_sv;
PPCODE:
{
  int start_pos = SvIOK(start_pos_sv) ? SvIV(start_pos_sv) : slr->perl_pos;
  int length = SvIOK(length_sv) ? SvIV(length_sv) : -1;
  u_pos_set(slr, "slr->pos_set", start_pos, length);
  slr->lexer_start_pos = slr->perl_pos;
  XSRETURN_YES;
}

void
substring(slr, start_pos, length)
    Scanless_R *slr;
    int start_pos;
    int length;
PPCODE:
{
  SV* literal_sv = u_substring(slr, "slr->substring()", start_pos, length);
  XPUSHs (sv_2mortal (literal_sv));
}

 # An internal function for converting an Earley set span to
 # one in terms of the input locations.
 # This is only meaningful in the context of an SLR
void
_es_to_literal_span(slr, start_earley_set, length)
    Scanless_R *slr;
    Marpa_Earley_Set_ID start_earley_set;
    int length;
PPCODE:
{
  int literal_start;
  int literal_length;
  const Marpa_Recce r1 = slr->r1;
  const Marpa_Earley_Set_ID latest_earley_set =
    marpa_r_latest_earley_set (r1);
  if (start_earley_set < 0 || start_earley_set > latest_earley_set)
    {
      croak
        ("_es_to_literal_span: earley set is %d, must be between 0 and %d",
         start_earley_set, latest_earley_set);
    }
  if (length < 0)
    {
      croak ("_es_to_literal_span: length is %d, cannot be negative", length);
    }
  if (start_earley_set + length > latest_earley_set)
    {
      croak
        ("_es_to_literal_span: final earley set is %d, must be no greater than %d",
         start_earley_set + length, latest_earley_set);
    }
  slr_es_to_literal_span (slr,
                          start_earley_set, length,
                          &literal_start, &literal_length);
  XPUSHs (sv_2mortal (newSViv ((IV) literal_start)));
  XPUSHs (sv_2mortal (newSViv ((IV) literal_length)));
}

 #  Always returns the same SV for a given Scanless recce object -- 
void
lexer_set( slr, lexer_id )
    Scanless_R *slr;
    int lexer_id;
PPCODE:
{
  const int old_lexer_id = slr->current_lexer->index;
  const Scanless_G *slg = slr->slg;
  const int lexer_count = slg->lexer_count;
  if (lexer_id >= lexer_count || lexer_id < 0)
    {
      croak
        ("Problem in slr->lexer_set(%ld): lexer id must be between 0 and %ld",
         (long) lexer_id, (long) (lexer_count - 1));
    }
  slr->next_lexer = slg->lexers[lexer_id];
  XSRETURN_IV ((IV) old_lexer_id);
}

void
read(slr)
    Scanless_R *slr;
PPCODE:
{
  int lexer_read_result = 0;
  const int trace_lexers = slr->trace_lexers;

  slr->lexer_read_result = 0;
  slr->r1_earleme_complete_result = 0;
  slr->start_of_pause_lexeme = -1;
  slr->end_of_pause_lexeme = -1;
  slr->pause_lexeme = -1;

  /* Clear event queue */
  av_clear (slr->r1_wrapper->event_queue);
  marpa__slr_event_clear(slr->gift);

  /* Application intervention resets perl_pos */
  slr->last_perl_pos = -1;

  while (1)
    {
      /* Flag to indicate whether we should attempt to consume some of the input
       * after a u_read()
       */
      int consume_input = 0;
      if (slr->lexer_start_pos >= 0)
	{
	  if (slr->lexer_start_pos >= slr->end_pos)
	    {
	      XSRETURN_PV ("");
	    }

	  slr->start_of_lexeme = slr->perl_pos = slr->lexer_start_pos;
	  slr->lexer_start_pos = -1;
	  u_r0_clear (slr);
	  if (trace_lexers >= 1)
	    {
                        union marpa_slr_event_s *event = marpa__slr_event_push(slr->gift);
	      MARPA_SLREV_TYPE (event) = MARPA_SLREV_LEXER_RESTARTED_RECCE;
	      event->t_lexer_restarted_recce.t_perl_pos = slr->perl_pos;
	      event->t_lexer_restarted_recce.t_current_lexer_ix =
		slr->current_lexer->index;
	    }
	}

    if (trace_lexers >= 1 && slr->current_lexer->index != slr->next_lexer->index)
  {
                        union marpa_slr_event_s *event = marpa__slr_event_push(slr->gift);
    MARPA_SLREV_TYPE (event) = MARPA_SLRTR_CHANGE_LEXERS;
    event->t_trace_change_lexers.t_perl_pos = slr->perl_pos;
    event->t_trace_change_lexers.t_old_lexer_ix = slr->current_lexer->index;
    event->t_trace_change_lexers.t_new_lexer_ix = slr->next_lexer->index;
  }
      slr->current_lexer = slr->next_lexer;
      lexer_read_result = slr->lexer_read_result = u_read (slr);
      switch (lexer_read_result)
	{
	case U_READ_TRACING:
	  XSRETURN_PV ("trace");
	case U_READ_UNREGISTERED_CHAR:
	  XSRETURN_PV ("unregistered char");
	default:
	  if (lexer_read_result < 0)
	    {
	      croak
		("Internal Marpa SLIF error: u_read returned unknown code: %ld",
		 (long) lexer_read_result);
	    }
	  consume_input = 1;
	  break;
	case U_READ_OK:
	case U_READ_INVALID_CHAR:
	case U_READ_REJECTED_CHAR:
	case U_READ_EXHAUSTED_ON_FAILURE:
	case U_READ_EXHAUSTED_ON_SUCCESS:
	  consume_input = 1;
	  break;
	}


      if (consume_input)
	{
	  if (marpa_r_is_exhausted (slr->r1))
	    {
	      int discard_result = slr_discard (slr);
	      if (discard_result < 0)
		{
		  XSRETURN_PV ("R1 exhausted before end");
		}
	    }
	  else
	    {
	      int event_count;
	      const char *result_string = slr_alternatives (slr);
	      if (result_string)
		{
		  XSRETURN_PV (result_string);
		}
	      event_count = av_len (slr->r1_wrapper->event_queue) + 1;
	      event_count += marpa__slr_event_count(slr->gift);
	      if (event_count)
		{
		  XSRETURN_PV ("event");
		}
	    }

	  /* Deal with repeated failures at the same |perl_pos| */
	  if (slr->perl_pos == slr->last_perl_pos)
	    {
	      slr->perl_pos_hits++;
	    }
	  else
	    {
	      slr->last_perl_pos = slr->perl_pos;
	      slr->perl_pos_hits = 1;
	    }

	  if (slr->perl_pos_hits >= 2)
	    {
	      if (slr->current_lexer->index == slr->fallback_lexer->index)
		{
		  if (lexer_read_result == U_READ_INVALID_CHAR)
		    {
		      XSRETURN_PV ("invalid char");
		    }
		  XSRETURN_PV ("SLIF loop");
		}
	      slr->next_lexer = slr->fallback_lexer;
	      /* Start the hits count over again */
	      slr->perl_pos_hits = 0;
	      consume_input = 0;
	    }
	}

      if (slr->trace_terminals || slr->trace_lexers)
	{
	  XSRETURN_PV ("trace");
	}

    }

  /* Never reached */
  XSRETURN_PV ("");
}

void
lexer_read_result (slr)
     Scanless_R *slr;
PPCODE:
{
  XPUSHs (sv_2mortal (newSViv ((IV) slr->lexer_read_result)));
}

void
r1_earleme_complete_result (slr)
     Scanless_R *slr;
PPCODE:
{
  XPUSHs (sv_2mortal (newSViv ((IV) slr->r1_earleme_complete_result)));
}

void
pause_span (slr)
     Scanless_R *slr;
PPCODE:
{
  Marpa_Symbol_ID pause_lexeme = slr->pause_lexeme;
  if (pause_lexeme < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv ((IV) slr->start_of_pause_lexeme)));
  XPUSHs (sv_2mortal
          (newSViv
           ((IV) slr->end_of_pause_lexeme - slr->start_of_pause_lexeme)));
}

void
pause_lexeme (slr)
     Scanless_R *slr;
PPCODE:
{
  Marpa_Symbol_ID pause_lexeme = slr->pause_lexeme;
  if (pause_lexeme < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv ((IV) pause_lexeme)));
}

void
events(slr)
    Scanless_R *slr;
PPCODE:
{
  int i;
  int queue_length;
  const int event_max_index = marpa__slr_event_max_index(slr->gift);
  AV *const event_queue_av = slr->r1_wrapper->event_queue;

  for (i = 0; i <= event_max_index; i++)
    {
	union marpa_slr_event_s *const slr_event = marpa__slr_event_entry( slr->gift, i);

      const int event_type = MARPA_SLREV_TYPE (slr_event);
      switch (event_type)
        {
        case MARPA_SLREV_DELETED:
          break;

        case MARPA_SLRTR_CODEPOINT_READ:
          {
            AV *event_av = newAV ();

            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("lexer reading codepoint"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_read.t_codepoint));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_read.t_perl_pos));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_read.t_current_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_CODEPOINT_REJECTED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("lexer rejected codepoint"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_rejected.t_codepoint));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_rejected.t_perl_pos));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_rejected.t_symbol_id));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_rejected.t_current_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_CODEPOINT_ACCEPTED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("lexer accepted codepoint"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_accepted.t_codepoint));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_accepted.t_perl_pos));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_accepted.t_symbol_id));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_codepoint_accepted.t_current_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_LEXEME_DISCARDED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("discarded lexeme"));
            /* We do not have the lexeme, but we have the 
             * lexer rule.
             * The upper level will have to figure things out.
             */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_discarded.t_rule_id));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_discarded.t_start_of_lexeme));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_discarded.t_end_of_lexeme));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_discarded.t_current_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_LEXEME_IGNORED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("ignored lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_ignored.t_lexeme));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_ignored.t_start_of_lexeme));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_ignored.t_end_of_lexeme));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLREV_SYMBOL_COMPLETED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("symbol completed"));
            av_push (event_av, newSViv ((IV) slr_event->t_symbol_completed.t_symbol));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLREV_SYMBOL_NULLED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("symbol nulled"));
            av_push (event_av, newSViv ((IV) slr_event->t_symbol_nulled.t_symbol));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLREV_SYMBOL_PREDICTED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("symbol predicted"));
            av_push (event_av, newSViv ((IV) slr_event->t_symbol_predicted.t_symbol));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLREV_MARPA_R_UNKNOWN:
          {
            /* An unknown Marpa_Recce event */
            AV *event_av = newAV ();
            const int r_event_ix = slr_event->t_marpa_r_unknown.t_event;
            const char *result_string = event_type_to_string (r_event_ix);
            if (!result_string)
              {
                result_string =
                  form ("unknown marpa_r event code, %d", r_event_ix);
              }
            av_push (event_av, newSVpvs ("unknown marpa_r event"));
            av_push (event_av, newSVpv (result_string, 0));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_LEXEME_REJECTED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("rejected lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_rejected.t_start_of_lexeme));    /* start */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_rejected.t_end_of_lexeme));      /* end */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_rejected.t_lexeme));     /* lexeme */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_rejected.t_current_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_LEXEME_EXPECTED:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("expected lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_expected.t_perl_pos));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_expected.t_lexeme));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_expected.t_assertion));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_expected.t_current_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_LEXEME_OUTPRIORITIZED:
          {
            /* Uses same structure as "acceptable" lexeme */
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("outprioritized lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_acceptable.t_start_of_lexeme));  /* start */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_acceptable.t_end_of_lexeme));    /* end */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_acceptable.t_lexeme));   /* lexeme */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_acceptable.t_current_lexer_ix));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_acceptable.t_priority));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_lexeme_acceptable.t_required_priority));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_BEFORE_LEXEME:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("g1 before lexeme event"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_before_lexeme.t_start_of_pause_lexeme));        /* start */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_before_lexeme.t_end_of_pause_lexeme));  /* end */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_before_lexeme.t_pause_lexeme)); /* lexeme */
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLREV_BEFORE_LEXEME:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("before lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_before_lexeme.t_pause_lexeme));       /* lexeme */
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_G1_ATTEMPTING_LEXEME:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("g1 attempting lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_attempting_lexeme.t_start_of_lexeme));  /* start */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_attempting_lexeme.t_end_of_lexeme));    /* end */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_attempting_lexeme.t_lexeme));   /* lexeme */
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_G1_DUPLICATE_LEXEME:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("g1 duplicate lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_duplicate_lexeme.t_start_of_lexeme));   /* start */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_duplicate_lexeme.t_end_of_lexeme));     /* end */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_duplicate_lexeme.t_lexeme));    /* lexeme */
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_G1_ACCEPTED_LEXEME:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("g1 accepted lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_accepted_lexeme.t_start_of_lexeme));    /* start */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_accepted_lexeme.t_end_of_lexeme));      /* end */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_accepted_lexeme.t_lexeme));     /* lexeme */
            av_push (event_av,
                     newSViv ((IV) slr_event->t_trace_accepted_lexeme.
                              t_current_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_AFTER_LEXEME:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpvs ("g1 pausing after lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_trace_after_lexeme.t_start_of_lexeme));       /* start */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_after_lexeme.t_end_of_lexeme)); /* end */
            av_push (event_av, newSViv ((IV) slr_event->t_trace_after_lexeme.t_lexeme));        /* lexeme */
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLREV_AFTER_LEXEME:
          {
            AV *event_av = newAV ();;
            av_push (event_av, newSVpvs ("after lexeme"));
            av_push (event_av, newSViv ((IV) slr_event->t_after_lexeme.t_lexeme));        /* lexeme */
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLREV_LEXER_RESTARTED_RECCE:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpv ("lexer restarted recognizer", 0));
            av_push (event_av,
                     newSViv ((IV) slr_event->t_lexer_restarted_recce.
                              t_perl_pos));
            av_push (event_av,
                     newSViv ((IV) slr_event->t_lexer_restarted_recce.
                              t_current_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLRTR_CHANGE_LEXERS:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("'trace"));
            av_push (event_av, newSVpv ("changing lexers", 0));
            av_push (event_av,
                     newSViv ((IV) slr_event->t_trace_change_lexers.
                              t_perl_pos));
            av_push (event_av,
                     newSViv ((IV) slr_event->t_trace_change_lexers.
                              t_old_lexer_ix));
            av_push (event_av,
                     newSViv ((IV) slr_event->t_trace_change_lexers.
                              t_new_lexer_ix));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        case MARPA_SLREV_NO_ACCEPTABLE_INPUT:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("no acceptable input"));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }

        default:
          {
            AV *event_av = newAV ();
            av_push (event_av, newSVpvs ("unknown SLR event"));
            av_push (event_av, newSViv ((IV) event_type));
            XPUSHs (sv_2mortal (newRV_noinc ((SV *) event_av)));
            break;
          }
        }
    }

  queue_length = av_len (event_queue_av);
  for (i = 0; i <= queue_length; i++)
    {
      SV *event = av_shift (event_queue_av);
      XPUSHs (sv_2mortal (event));
    }
}

void
span(slr, earley_set)
    Scanless_R *slr;
    IV earley_set;
PPCODE:
{
  int start_position;
  int length;
  slr_es_to_span(slr, earley_set, &start_position, &length);
  XPUSHs (sv_2mortal (newSViv ((IV) start_position)));
  XPUSHs (sv_2mortal (newSViv ((IV) length)));
}

void
lexeme_span (slr)
     Scanless_R *slr;
PPCODE:
{
  STRLEN length = slr->end_of_lexeme - slr->start_of_lexeme;
  XPUSHs (sv_2mortal (newSViv ((IV) slr->start_of_lexeme)));
  XPUSHs (sv_2mortal (newSViv ((IV) length)));
}

 # Return values are 1-based, as is the tradition */
 # EOF is reported as the last line, last column plus one.
void
line_column(slr, pos)
     Scanless_R *slr;
     IV pos;
PPCODE:
{
  int line = 1;
  int column = 1;
  int linecol;
  int at_eof = 0;
  const int logical_size = slr->pos_db_logical_size;

  if (pos < 0)
    {
      pos = slr->perl_pos;
    }
  if (pos > logical_size)
    {
      if (logical_size < 0) {
          croak ("Problem in slr->line_column(%ld): line/column information not available",
                 (long) pos);
      }
      croak ("Problem in slr->line_column(%ld): position out of range",
             (long) pos);
    }

  /* At EOF, find data for position - 1 */
  if (pos == logical_size) { at_eof = 1; pos--; }
  linecol = slr->pos_db[pos].linecol;
  if (linecol >= 0)
    {                           /* Zero should not happen */
      line = linecol;
    }
  else
    {
      line = slr->pos_db[pos + linecol].linecol;
      column = -linecol + 1;
    }
  if (at_eof) { column++; }
  XPUSHs (sv_2mortal (newSViv ((IV) line)));
  XPUSHs (sv_2mortal (newSViv ((IV) column)));
}

 # Variable arg as opposed to a ref,
 # because there seems to be no
 # easy, forward-compatible way
 # to determine whether the de-referenced value will cause
 # a "bizarre copy" error.
 # 
 # All errors are returned, not thrown
void
g1_alternative (slr, symbol_id, ...)
    Scanless_R *slr;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  int result;
  int token_ix;
  switch (items)
    {
    case 2:
      token_ix = TOKEN_VALUE_IS_LITERAL;        /* default */
      break;
    case 3:
      {
        SV *token_value = ST (2);
        if (IS_PERL_UNDEF (token_value))
          {
            token_ix = TOKEN_VALUE_IS_UNDEF;    /* default */
            break;
          }
        /* Fail fast with a tainted input token value */
        if (SvTAINTED(token_value)) {
            croak
              ("Problem in Marpa::R2: Attempt to use a tainted token value\n"
              "Marpa::R2 is insecure for use with tainted data\n");
        }
        av_push (slr->token_values, newSVsv (token_value));
        token_ix = av_len (slr->token_values);
      }
      break;
    default:
      croak
        ("Usage: Marpa::R2::Thin::SLR::g1_alternative(slr, symbol_id, [value])");
    }

  result = marpa_r_alternative (slr->r1, symbol_id, token_ix, 1);
  XSRETURN_IV (result);
}

 # Returns current position on success, 0 on unthrown failure
void
g1_lexeme_complete (slr, start_pos_sv, length_sv)
    Scanless_R *slr;
     SV* start_pos_sv;
     SV* length_sv;
PPCODE:
{
  int result;
  const int input_length = slr->pos_db_logical_size;

  int start_pos = SvIOK (start_pos_sv) ? SvIV (start_pos_sv) : slr->perl_pos;

  int lexeme_length = SvIOK (length_sv) ? SvIV (length_sv)
    : slr->perl_pos ==
    slr->start_of_pause_lexeme ? (slr->end_of_pause_lexeme -
				  slr->start_of_pause_lexeme) : -1;

  /* User intervention resets last |perl_pos| */
  slr->last_perl_pos = -1;

  start_pos = start_pos < 0 ? input_length + start_pos : start_pos;
  if (start_pos < 0 || start_pos > input_length)
    {
      /* Undef start_pos_sv should not cause error */
      croak ("Bad start position in slr->g1_lexeme_complete(): %ld",
	     (long) (SvIOK (start_pos_sv) ? SvIV (start_pos_sv) : -1));
    }
  slr->perl_pos = start_pos;

  {
    const int end_pos =
      lexeme_length <
      0 ? input_length + lexeme_length + 1 : start_pos + lexeme_length;
    if (end_pos < 0 || end_pos > input_length)
      {
	/* Undef length_sv should not cause error */
	croak ("Bad length in slr->g1_lexeme_complete(): %ld",
	       (long) (SvIOK (length_sv) ? SvIV (length_sv) : -1));
      }
    lexeme_length = end_pos - start_pos;
  }

  av_clear (slr->r1_wrapper->event_queue);
  result = marpa_r_earleme_complete (slr->r1);
  if (result >= 0)
    {
      r_convert_events (slr->r1_wrapper);
      marpa_r_latest_earley_set_values_set (slr->r1, start_pos,
					    INT2PTR (void *, lexeme_length));
      slr->perl_pos = start_pos + lexeme_length;
      XSRETURN_IV (slr->perl_pos);
    }
  if (result == -2)
    {
      const Marpa_Error_Code error = marpa_g_error (slr->g1_wrapper->g, NULL);
      if (error == MARPA_ERR_PARSE_EXHAUSTED)
	{
	  union marpa_slr_event_s *event = marpa__slr_event_push(slr->gift);
	  MARPA_SLREV_TYPE (event) = MARPA_SLREV_NO_ACCEPTABLE_INPUT;
	}
      XSRETURN_IV (0);
    }
  if (slr->throw)
    {
      croak ("Problem in slr->g1_lexeme_complete(): %s",
	     xs_g_error (slr->g1_wrapper));
    }
  XSRETURN_IV (0);
}

void
lexeme_event_activate( slr, g1_lexeme_id, reactivate )
    Scanless_R *slr;
    Marpa_Symbol_ID g1_lexeme_id;
    int reactivate;
PPCODE:
{
  struct symbol_r_properties *symbol_r_properties;
  const Scanless_G *slg = slr->slg;
  const Marpa_Symbol_ID highest_g1_symbol_id = marpa_g_highest_symbol_id (slg->g1);
  if (g1_lexeme_id > highest_g1_symbol_id)
    {
      croak
        ("Problem in slr->lexeme_event_activate(..., %ld, %ld): symbol ID was %ld, but highest G1 symbol ID = %ld",
         (long) g1_lexeme_id, (long) reactivate,
         (long) g1_lexeme_id, (long) highest_g1_symbol_id);
    }
  if (g1_lexeme_id < 0)
    {
      croak
        ("Problem in slr->lexeme_event_activate(..., %ld, %ld): symbol ID was %ld, a disallowed value",
         (long) g1_lexeme_id, (long) reactivate, (long) g1_lexeme_id);
    }
  symbol_r_properties = slr->symbol_r_properties + g1_lexeme_id;
  switch (reactivate)
    {
    case 0:
      symbol_r_properties->pause_after_active = 0;
      symbol_r_properties->pause_before_active = 0;
      break;
    case 1:
      {
        const struct symbol_g_properties* g_properties = slg->symbol_g_properties + g1_lexeme_id;
        symbol_r_properties->pause_after_active = g_properties->pause_after;
        symbol_r_properties->pause_before_active = g_properties->pause_before;
      }
      break;
    default:
      croak
        ("Problem in slr->lexeme_event_activate(..., %ld, %ld): reactivate flag is %ld, a disallowed value",
         (long) g1_lexeme_id, (long) reactivate, (long) reactivate);
    }
  XPUSHs (sv_2mortal (newSViv (reactivate)));
}

void
problem_pos( slr )
     Scanless_R *slr;
PPCODE:
{
  if (slr->problem_pos < 0) {
     XSRETURN_UNDEF;
  }
  XSRETURN_IV(slr->problem_pos);
}

void
lexer_latest_earley_set( slr )
     Scanless_R *slr;
PPCODE:
{
  const Marpa_Recce r0 = slr->r0;
  if (!r0)
    {
      XSRETURN_UNDEF;
    }
  XSRETURN_IV (marpa_r_latest_earley_set (r0));
}

void
lexer_progress_report_start( slr, ordinal )
    Scanless_R *slr;
    Marpa_Earley_Set_ID ordinal;
PPCODE:
{
  int gp_result;
  G_Wrapper* lexer_wrapper;
  const Marpa_Recognizer recce = slr->r0;
  if (!recce)
    {
      croak ("Problem in r->progress_item(): No lexer recognizer");
    }
  lexer_wrapper = slr->current_lexer->g_wrapper;
  gp_result = marpa_r_progress_report_start(recce, ordinal);
  if ( gp_result == -1 ) { XSRETURN_UNDEF; }
  if ( gp_result < 0 && lexer_wrapper->throw ) {
    croak( "Problem in r->progress_report_start(%d): %s",
     ordinal, xs_g_error( lexer_wrapper ));
  }
  XPUSHs (sv_2mortal (newSViv (gp_result)));
}

void
lexer_progress_report_finish( slr )
    Scanless_R *slr;
PPCODE:
{
  int gp_result;
  G_Wrapper* lexer_wrapper;
  const Marpa_Recognizer recce = slr->r0;
  if (!recce)
    {
      croak ("Problem in r->progress_item(): No lexer recognizer");
    }
  lexer_wrapper = slr->current_lexer->g_wrapper;
  gp_result = marpa_r_progress_report_finish(recce);
  if ( gp_result == -1 ) { XSRETURN_UNDEF; }
  if ( gp_result < 0 && lexer_wrapper->throw ) {
    croak( "Problem in r->progress_report_finish(): %s",
     xs_g_error( lexer_wrapper ));
  }
  XPUSHs (sv_2mortal (newSViv (gp_result)));
}

void
lexer_progress_item( slr )
    Scanless_R *slr;
PPCODE:
{
  Marpa_Rule_ID rule_id;
  Marpa_Earley_Set_ID origin = -1;
  int position = -1;
  G_Wrapper* lexer_wrapper;
  const Marpa_Recognizer recce = slr->r0;
  if (!recce)
    {
      croak ("Problem in r->progress_item(): No lexer recognizer");
    }
  lexer_wrapper = slr->current_lexer->g_wrapper;
  rule_id = marpa_r_progress_item (recce, &position, &origin);
  if (rule_id == -1)
    {
      XSRETURN_UNDEF;
    }
  if (rule_id < 0 && lexer_wrapper->throw)
    {
      croak ("Problem in r->progress_item(): %s",
             xs_g_error (lexer_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (rule_id)));
  XPUSHs (sv_2mortal (newSViv (position)));
  XPUSHs (sv_2mortal (newSViv (origin)));
}

void
string_set( slr, string )
     Scanless_R *slr;
     SVREF string;
PPCODE:
{
  U8* p;
  U8* start_of_string;
  U8* end_of_string;
  int input_is_utf8;

  /* Initialized to a Unicode non-character.  In fact, anything
   * but a CR would work here.
   */
  UV previous_codepoint = 0xFDD0;
  int next_line = 1;
  int next_column = 0;

  STRLEN pv_length;

  /* Fail fast with a tainted input string */
  if (SvTAINTED(string)) {
      croak
        ("Problem in v->string_set(): Attempt to use a tainted input string with Marpa::R2\n"
        "Marpa::R2 is insecure for use with tainted data\n");
  }

  /* Get our own copy and coerce it to a PV.
   * Stealing is OK, magic is not.
   */
  SvSetSV (slr->input, string);
  start_of_string = (U8*)SvPV_force_nomg (slr->input, pv_length);
  end_of_string = start_of_string + pv_length;
  input_is_utf8 = SvUTF8 (slr->input);

  slr->pos_db_logical_size = 0;
  /* This original buffer size my be too small.
   */
  slr->pos_db_physical_size = 1024;
  Newx (slr->pos_db, slr->pos_db_physical_size, Pos_Entry);

  for (p = start_of_string; p < end_of_string; ) {
      STRLEN codepoint_length;
      UV codepoint;
      if (input_is_utf8)
        {
          codepoint = utf8_to_uvchr_buf (p, end_of_string, &codepoint_length);
          /* Perl API documents that return value is 0 and length is -1 on error,
           * "if possible".  length can be, and is, in fact unsigned.
           * I deal with this by noting that 0 is a valid UTF8 char but should
           * have a length of 1, when valid.
           */
          if (codepoint == 0 && codepoint_length != 1)
            {
              croak
                ("Problem in slr->string_set(): invalid UTF8 character");
            }
        }
      else
        {
          codepoint = (UV) * p;
          codepoint_length = 1;
        }
      /* Ensure that there is enough space */
      if (slr->pos_db_logical_size >= slr->pos_db_physical_size)
        {
          slr->pos_db_physical_size *= 2;
          Renew (slr->pos_db, slr->pos_db_physical_size, Pos_Entry);
        }
      p += codepoint_length;
      slr->pos_db[slr->pos_db_logical_size].next_offset =
        p - start_of_string;

        /* The definition of newline here follows the Unicode standard TR13 */
      if (codepoint == 0x0a && previous_codepoint == 0x0d) {
        slr->pos_db[slr->pos_db_logical_size].linecol =
          slr->pos_db[slr->pos_db_logical_size-1].linecol - 1;
      } else {
        slr->pos_db[slr->pos_db_logical_size].linecol = next_column ? next_column : next_line;
      }
      switch (codepoint) {
      case 0x0a: case 0x0b: case 0x0c: case 0x0d:
      case 0x85: case 0x2028: case 0x2029:
          next_line++;
          next_column = 0;
          break;
      default:
          next_column--;
      }
      slr->pos_db_logical_size++;
      previous_codepoint = codepoint;
    }
  XSRETURN_YES;
}

void
input_length( slr )
     Scanless_R *slr;
PPCODE:
{
  XSRETURN_IV(slr->pos_db_logical_size);
}

void
codepoint( slr )
     Scanless_R *slr;
PPCODE:
{
  XSRETURN_UV(slr->codepoint);
}

void
symbol_id( slr )
     Scanless_R *slr;
PPCODE:
{
  XSRETURN_IV(slr->input_symbol_id);
}

void
char_register( slr, codepoint, ... )
    Scanless_R *slr;
     UV codepoint;
PPCODE:
{
  /* OP Count is args less two, then plus two for codepoint and length fields */
  const STRLEN op_count = items;
  STRLEN op_ix;
  IV *ops;
  SV *ops_sv = NULL;
  Lexer *lexer = slr->current_lexer;
  const unsigned array_size = Dim (lexer->per_codepoint_array);
  const int use_array = codepoint < array_size;

  if (use_array)
    {
      ops = lexer->per_codepoint_array[codepoint];
      Renew (ops, op_count, IV);
      lexer->per_codepoint_array[codepoint] = ops;
    }
  else
    {
      STRLEN dummy;
      ops_sv = newSV (op_count * sizeof (ops[0]));
      SvPOK_on (ops_sv);
      ops = (IV *) SvPV (ops_sv, dummy);
    }
  ops[0] = codepoint;
  ops[1] = op_count;
  for (op_ix = 2; op_ix < op_count; op_ix++)
    {
      /* By coincidence, offset of individual ops is 2 both in the
       * method arguments and in the op_list, so that arg IX == op_ix
       */
      ops[op_ix] = SvUV (ST (op_ix));
    }
  if (ops_sv)
    {
      (void)hv_store (slr->current_lexer->per_codepoint_hash, (char *) &codepoint,
                sizeof (codepoint), ops_sv, 0);
    }
}

void
current_lexer( slr )
     Scanless_R *slr;
PPCODE:
{
  XSRETURN_IV(slr->current_lexer->index);
}

INCLUDE: general_pattern.xsh

BOOT:
    marpa_debug_handler_set(marpa_r2_warn);

    /* vim: set expandtab shiftwidth=2: */
