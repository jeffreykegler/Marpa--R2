/*
 * Copyright 2013 Jeffrey Kegler
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

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "config.h"
#include "marpa.h"

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
     G_Wrapper* base;
     unsigned int ruby_slippers:1;
} R_Wrapper;

typedef struct {
     G_Wrapper* g0_wrapper;
     /* Need to keep a copy of the G0 SV in order to properly "wrap"
      * a recognizer.
      */
     SV* g0_sv;
     Marpa_Recce r0;
     SV* r0_sv;
     STRLEN perl_pos; /* character position, taking into account Unicode
         Equivalent to Perl pos()
     */
     STRLEN input_offset; /* byte position, ignoring Unicode */
     SV* input;
     int input_debug; /* debug level for input */
     Marpa_Symbol_ID input_symbol_id;
     UV codepoint; /* For error returns */
     HV* per_codepoint_ops;
     IV ignore_rejection;

     /* The minimum number of tokens that must
       be accepted at an earleme */
     IV minimum_accepted;
     IV trace; /* trace level */
} Unicode_Stream;

typedef struct {
     SV* g0_sv;
     SV* g1_sv;
     G_Wrapper* g0_wrapper;
     G_Wrapper* g1_wrapper;
     Marpa_Grammar g0;
     Marpa_Grammar g1;
    Marpa_Symbol_ID* g0_rule_to_g1_lexeme;
} Scanless_G;

typedef struct {
     SV* slg_sv;
     SV* r1_sv;
     SV* stream_sv;
     Scanless_G* slg;
     Unicode_Stream* stream;
     R_Wrapper* r1_wrapper;
     Marpa_Recce r1;
     G_Wrapper* g0_wrapper;
     G_Wrapper* g1_wrapper;
     AV* event_queue;
     int trace_level;
     int trace_terminals;
     STRLEN start_of_lexeme;
     STRLEN end_of_lexeme;
     int please_start_lex_recce;
     int stream_read_result;
     int r1_earleme_complete_result;
} Scanless_R;

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
  int mode;			/* 'raw' or 'stack' */
  int result;			/* stack location to which to write result */
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
static const char unicode_stream_class_name[] = "Marpa::R2::Thin::U";
static const char order_c_class_name[] = "Marpa::R2::Thin::O";
static const char tree_c_class_name[] = "Marpa::R2::Thin::T";
static const char value_c_class_name[] = "Marpa::R2::Thin::V";
static const char scanless_g_class_name[] = "Marpa::R2::Thin::SLG";
static const char scanless_r_class_name[] = "Marpa::R2::Thin::SLR";

#include "codes.h"
#include "codes.c"

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

enum marpa_op
{
  op_end_marker = 0,
  op_alternative,
  op_bless,
  op_callback,
  op_earleme_complete,
  op_ignore_rejection,
  op_noop,
  op_push_all,
  op_push_one,
  op_push_sequence,
  op_push_token_value,
  op_push_slr_range,
  op_report_rejection,
  op_result_is_array,
  op_result_is_constant,
  op_result_is_rhs_n,
  op_result_is_token_value,
  op_result_is_undef
};

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
  Safefree (r_wrapper->terminals_buffer);
  Safefree (r_wrapper);
  /* The wrapper should always have had a ref to the Libmarpa recce */
  return r;
}

/* Static Stream methods */

/* The caller must ensure that g_sv is an SV of the correct type */
static Unicode_Stream* u_new(SV* g_sv)
{
  dTHX;
  Unicode_Stream *stream;
  IV tmp = SvIV ((SV *) SvRV (g_sv));
  G_Wrapper *g_wrapper = INT2PTR (G_Wrapper *, tmp);
  Newx (stream, 1, Unicode_Stream);
  stream->trace = 0;
  stream->g0_wrapper = g_wrapper;
  stream->r0 = NULL;
  /* Hold a ref to the grammar SV we were called with --
   * it will have to exist for our lifetime
   */
  SvREFCNT_inc (g_sv);
  stream->g0_sv = g_sv;
  stream->r0_sv = NULL;
  stream->input = newSVpvn ("", 0);
  stream->perl_pos = 0;
  stream->input_offset = 0;
  stream->input_debug = 0;
  stream->input_symbol_id = -1;
  stream->per_codepoint_ops = newHV ();
  stream->ignore_rejection = 1;
  stream->minimum_accepted = 1;
  return stream;
}

static void u_destroy(Unicode_Stream *stream)
{
  dTHX;
  const Marpa_Recce r0 = stream->r0;
  if (r0)
    {
      marpa_r_unref (r0);
    }
  SvREFCNT_dec (stream->input);
  SvREFCNT_dec (stream->per_codepoint_ops);
  SvREFCNT_dec (stream->g0_sv);
  if (stream->r0_sv)
    {
      SvREFCNT_dec (stream->r0_sv);
    }
  Safefree (stream);
}

static void
u_r0_clear (Unicode_Stream * stream)
{
  dTHX;
  SV *r0_sv;
  Marpa_Recce r0 = stream->r0;
  if (!r0)
    return;
  r0_sv = stream->r0_sv;
  if (r0_sv)
    {
      SvREFCNT_dec (r0_sv);
      stream->r0_sv = NULL;
    }
  marpa_r_unref (r0);
  stream->r0 = NULL;
}

static Marpa_Recce
u_r0_new (Unicode_Stream * stream)
{
  dTHX;
  G_Wrapper *g0_wrapper = stream->g0_wrapper;
  Marpa_Recce r0 = marpa_r_new (g0_wrapper->g);
  if (!r0)
    {
      if (!g0_wrapper->throw)
	return 0;
      croak ("failure in marpa_r_new(): %s", xs_g_error (g0_wrapper));
    };
  {
    int gp_result = marpa_r_start_input (r0);
    if (gp_result == -1)
      return 0;
    if (gp_result < 0)
      {
	if (g0_wrapper->throw)
	  {
	    croak ("Problem in r->start_input(): %s", xs_g_error (g0_wrapper));
	  }
	return 0;
      }
  }
  stream->r0 = r0;
  return r0;
}

/* Return values:
 * 1 or greater: an event count, as returned by earleme complete.
 * 0: success: a full reading of the input, with nothing to report.
 * -1: a character was rejected, when rejection is not being ignored
 * -2: an unregistered character was found
 * -3: earleme_complete() reported an exhausted parse.
 */
static int
u_read(Unicode_Stream *stream)
{
  dTHX;
  U8* input;
  STRLEN len;
  int input_is_utf8;

  const IV trace_level = stream->trace;
  int input_debug = stream->input_debug;
  Marpa_Recognizer r = stream->r0;

  if (!r) {
      r = u_r0_new(stream);
      if (!r)
	croak ("Problem in u_read(): %s", xs_g_error (stream->g0_wrapper));
  }
  input_is_utf8 = SvUTF8 (stream->input);
  input = (U8*)SvPV (stream->input, len);
  for (;;)
    {
      int return_value = 0;
      UV codepoint;
      STRLEN codepoint_length = 1;
      STRLEN op_ix;
      STRLEN op_count;
      UV *ops;
      IV ignore_rejection = stream->ignore_rejection;
      IV minimum_accepted = stream->minimum_accepted;
      int tokens_accepted = 0;
      if (stream->input_offset >= len)
	break;
      if (input_is_utf8)
	{

  /* utf8_to_uvchr is deprecated in 5.16, but
   * utf8_to_uvchr_buf is not available before 5.16
   * If I need to get fancier, I should look at Dumper.xs
   * in Data::Dumper
   */
#if PERL_VERSION <= 15 && ! defined(utf8_to_uvchr_buf)
	  codepoint = utf8_to_uvchr(input+stream->input_offset, &codepoint_length);
#else
	  codepoint =
	  utf8_to_uvchr_buf (input + stream->input_offset, input + len,
			     &codepoint_length);
#endif

	  /* Perl API documents that return value is 0 and length is -1 on error,
	   * "if possible".  length can be, and is, in fact unsigned.
	   * I deal with this by noting that 0 is a valid UTF8 char but should
	   * have a length of 1, when valid.
	   */
	  if (codepoint == 0 && codepoint_length != 1) {
	    croak ("Problem in r->read_string(): invalid UTF8 character");
	  }
	}
      else
	{
	  codepoint = (UV) input[stream->input_offset];
	  codepoint_length = 1;
	}
      if (trace_level >= 1) {
          warn("Thin::U::read() Reading codepoint 0x%04x at pos %d",
	    (int)codepoint, (int)stream->perl_pos);
      }
      {
	STRLEN dummy;
	SV **p_ops_sv =
	  hv_fetch (stream->per_codepoint_ops, (char *) &codepoint,
		    (I32)sizeof (codepoint), 0);
	if (!p_ops_sv)
	  {
	    stream->codepoint = codepoint;
	    return -2;
	  }
	ops = (UV *)SvPV (*p_ops_sv, dummy);
      }
	
      /* ops[0] is codepoint */
      op_count = ops[1];
      for (op_ix = 2; op_ix < op_count; op_ix++)
	{
	  UV op_code = ops[op_ix];
	  switch (op_code)
	    {
	    case op_report_rejection:
	      {
		 ignore_rejection = 0;
	         break;
	      }
	    case op_ignore_rejection:
	      {
		 ignore_rejection = 1;
	         break;
	      }
	    case op_alternative:
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
		if (trace_level >= 1)
		  {
		    warn ("Thin::U::read() alternative(%p, %d, %d, %d)", r, symbol_id, value,
			  length);
		  }
		result = marpa_r_alternative (r, symbol_id, value, length);
		switch (result)
		  {
		  case MARPA_ERR_UNEXPECTED_TOKEN_ID:
		    if (input_debug > 0) {
		       warn("input_read_string unexpected token: %d,%d,%d",
			 symbol_id, value, length);
		    }
		    /* This guarantees that later, if we fall below
		     * the minimum number of tokens accepted,
		     * we have one of them as an example
		     */
		    stream->input_symbol_id = symbol_id;
		    if (trace_level >= 1) {
			warn("Thin::U::read() Rejected codepoint 0x%04lx at pos %d as symbol %d",
			  (unsigned long)codepoint, (int)stream->perl_pos, symbol_id);
		    }
		    if (!ignore_rejection)
		      {
			stream->codepoint = codepoint;
			return -1;
		      }
		    break;
		  case MARPA_ERR_NONE:
		    if (trace_level >= 1) {
			warn("Thin::U::read() Accepted codepoint 0x%04lx at pos %d as symbol %d",
			  (unsigned long)codepoint, (int)stream->perl_pos, symbol_id);
		    }
		    tokens_accepted++;
		    break;
		  default:
		    stream->codepoint = codepoint;
		    stream->input_symbol_id = symbol_id;
		    croak
		      ("Problem alternative() failed at char ix %d; symbol id %d; codepoint 0x%lx\n"
		       "Problem in r->input_string_read(), alternative() failed: %s",
		       (int)stream->perl_pos, symbol_id, (unsigned long)codepoint,
		       xs_g_error (stream->g0_wrapper));
		  }
	      }
	      break;
	    case op_earleme_complete:
	      {
		int result;
		if (tokens_accepted < minimum_accepted) {
		    stream->codepoint = codepoint;
		    return -1;
		}
		marpa_r_latest_earley_set_value_set (r, (int)codepoint);
		result = marpa_r_earleme_complete (r);
		if (result > 0)
		  {
		    return_value = result;
		    /* Advance one character before returning */
		    goto ADVANCE_ONE_CHAR;
		  }
		if (result == -2)
		  {
		    const Marpa_Error_Code error =
		      marpa_g_error (stream->g0_wrapper->g, NULL);
		    if (error == MARPA_ERR_PARSE_EXHAUSTED)
		      {
			return -3;
		      }
		  }
		if (result < 0)
		  {
		    croak
		      ("Problem in r->input_string_read(), earleme_complete() failed: %s",
		       xs_g_error (stream->g0_wrapper));
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
	stream->input_offset += codepoint_length;
      stream->perl_pos++;
      /* This logic does not allow a return value of 0,
       * which is reserved for a indicating a full
       * read of the input string without event
       */
      if (return_value)
	{
	  return return_value;
	}
    }
  return 0;
}

static STRLEN
u_pos_set(Unicode_Stream* stream, STRLEN new_pos)
{
  /* *SAFELY* change the position
   * This requires care in UTF8
   * Returns the position *BEFORE* the call
   */
  dTHX;
  U8 *input;
  int input_is_utf8;
  STRLEN len;
  const STRLEN old_pos = stream->perl_pos;

  /* Zero position is easy special case */
  if (new_pos == 0) {
      stream->input_offset = new_pos;
      stream->perl_pos = new_pos;
      return old_pos;
  }

  /* Same as current position is another easy special case */
  if (new_pos == old_pos) {
      return old_pos;
  }

  input_is_utf8 = SvUTF8 (stream->input);
  input = (U8 *) SvPV (stream->input, len);
  if (input_is_utf8)
    {
      /* I am required to *know* that the "hop" is inside the string,
       * which apparently can have Perl extensions -- it is *Perl* utf8, not
       * standard UTF8.  The only safe thing
       * to use the Perl API to hop one codepoint at a time,
       * which is basically how utf8_hop() does it anyway.
       */
      IV hop = new_pos - old_pos;
      U8 *p_current = input + stream->input_offset;
      U8 *end_of_input = input + len;
      while (hop > 0)
	{
	  if (p_current >= end_of_input)
	    {
	      croak
		("Problem in stream->pos_set(): Attempt to set position after end of utf8 string");
	    }
	  p_current = utf8_hop (p_current, 1);
	  hop--;
	}
      while (hop < 0)
	{
	  if (p_current <= input)
	    {
	      croak
		("Problem in stream->pos_set(): Attempt to set position before start of utf8 string");
	    }
	  p_current = utf8_hop (p_current, -1);
	  hop++;
	}
      stream->input_offset = p_current - input;
      stream->perl_pos = new_pos;
    }
  else
    {
      /* STRLEN is assumed to be unsigned so no check for less than zero */
      if (new_pos >= len)
	{
	  croak
	    ("Problem in stream->pos_set(): new pos = %ld, but length = %ld",
	     (long) new_pos, (long) len);
	}
      stream->input_offset = new_pos;
      stream->perl_pos = new_pos;
    }
  return old_pos;
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

/* Static SLG methods */

#define SET_SLG_FROM_SLG_SV(slg, slg_sv) { \
    IV tmp = SvIV ((SV *) SvRV (slg_sv)); \
    (slg) = INT2PTR (Scanless_G *, tmp); \
}

/* Static SLR methods */

/*
 * Return values:
 * 0 OK.
 * -4: Exhausted, but lexemes remain.
 */
static IV 
slr_stub_alternative(Scanless_R *slr, Marpa_Symbol_ID lexeme,
    IV attempted)
{
  dTHX;
  int result;
  Marpa_Recce r1 = slr->r1;
  Unicode_Stream *stream = slr->stream;
  int trace_level = slr->trace_level;
  int trace_terminals = slr->trace_terminals;
  Marpa_Earley_Set_ID latest_earley_set = marpa_r_latest_earley_set (r1);
  STRLEN start_pos = slr->start_of_lexeme;
  STRLEN end_pos = slr->end_of_lexeme;

  if (!attempted) {
       if (marpa_r_is_exhausted(r1)) { return -4; }
       /* Set values for Earley set n-1 to positions of lexeme --
        * that way we use set 0, and we can record position of a last,
	* rejected lexeme.
	*/
       marpa_r_latest_earley_set_values_set(r1, start_pos, INT2PTR(void*, end_pos));
  }
  result = marpa_r_alternative (r1, lexeme, latest_earley_set + 1, 1);
  switch (result)
    {

    case MARPA_ERR_UNEXPECTED_TOKEN_ID:
      if (trace_level >= 1)
	{
	  warn
	    ("slr->read() R1 Rejected unexpected symbol %d at pos %d",
	     lexeme, (int) slr->stream->perl_pos);
	}
	if (trace_terminals) {
	    AV* event;
	    SV* event_data[4];
	    event_data[0] = newSVpvs("unexpected");
	    event_data[1] = newSViv(start_pos); /* start */
	    event_data[2] = newSViv(end_pos); /* end */
	    event_data[3] = newSViv(lexeme); /* lexeme */
	    event = av_make(Dim(event_data), event_data);
	    av_push(slr->event_queue, newRV_noinc((SV*)event));
	}
      return 0;

    case MARPA_ERR_DUPLICATE_TOKEN:
      if (trace_level >= 1)
	{
	  warn
	    ("slr->read() R1 Rejected duplicate symbol %d at pos %d",
	     lexeme, (int) slr->stream->perl_pos);
	}
	if (trace_terminals) {
	    AV* event;
	    SV* event_data[4];
	    event_data[0] = newSVpvs("duplicate");
	    event_data[1] = newSViv(start_pos); /* start */
	    event_data[2] = newSViv(end_pos); /* end */
	    event_data[3] = newSViv(lexeme); /* lexeme */
	    event = av_make(Dim(event_data), event_data);
	    av_push(slr->event_queue, newRV_noinc((SV*)event));
	}
      return 0;

    case MARPA_ERR_NONE:
      if (trace_level >= 1)
	{
	  warn
	    ("slr->read() R1 Accepted symbol %d at pos %d",
	     lexeme, (int) slr->stream->perl_pos);
	}
	if (trace_terminals) {
	    AV* event;
	    SV* event_data[4];
	    event_data[0] = newSVpvs("accepted");
	    event_data[1] = newSViv(start_pos); /* start */
	    event_data[2] = newSViv(end_pos); /* end */
	    event_data[3] = newSViv(lexeme); /* lexeme */
	    event = av_make(Dim(event_data), event_data);
	    av_push(slr->event_queue, newRV_noinc((SV*)event));
	}
      return 0;

    }

  croak
    ("Problem SLR->read() failed on symbol id %d at position %d: %s",
     lexeme, (int) slr->stream->perl_pos, xs_g_error (slr->g1_wrapper));
  /* NOTREACHED */
  return 0;
}

/*
 * Return values:
 * 0 OK.
 * -4: Exhausted, but lexemes remain.
 */
static IV 
slr_stub_alternatives(Scanless_R *slr,
  IV*lexemes_found, IV*lexemes_attempted)
{
  dTHX;
  int return_value;
  Marpa_Recce r0;
  Marpa_Earley_Set_ID earley_set;

  r0 = slr->stream->r0;
  if (!r0)
    {
      croak ("Problem in slr->read(): No R0 at %s %d", __FILE__, __LINE__);
    }
  earley_set = marpa_r_latest_earley_set(r0);
  *lexemes_attempted = 0;
  *lexemes_found = 0;
  while (earley_set > 0) {
      return_value = marpa_r_progress_report_start(r0, earley_set);
      if (return_value < 0) {
	   croak ("Problem in marpa_r_progress_report_start(%p, %ld): %s",
	       (void*)r0, (unsigned long)earley_set, xs_g_error (slr->g0_wrapper));
      }
      while (1) {
	  Marpa_Symbol_ID g1_lexeme;
          int dot_position;
	  Marpa_Earley_Set_ID origin;
	  Marpa_Rule_ID rule_id = marpa_r_progress_item(r0, &dot_position, &origin);
	  if (rule_id <= -2) {
	   croak ("Problem in marpa_r_progress_item(): %s",
	        xs_g_error (slr->g0_wrapper));
	  }
	  if (rule_id == -1) goto NO_MORE_REPORT_ITEMS;
	  if (origin < 0) goto NEXT_REPORT_ITEM;
	  if (dot_position != -1) goto NEXT_REPORT_ITEM;
	  g1_lexeme = slr->slg->g0_rule_to_g1_lexeme[rule_id];
	  if (g1_lexeme == -1) goto NEXT_REPORT_ITEM;
	  (*lexemes_found)++;
	  slr->end_of_lexeme = slr->start_of_lexeme + earley_set;

	  /* -2 means a discarded item */
	  if (g1_lexeme <= -2) goto NEXT_REPORT_ITEM;
	  return_value = slr_stub_alternative(slr, g1_lexeme, *lexemes_attempted);
	  if (return_value == -4) { return return_value; }
	  (*lexemes_attempted)++;
	  NEXT_REPORT_ITEM: ;
      }
      NO_MORE_REPORT_ITEMS: ;
      if (*lexemes_found) goto LEXEMES_FOUND;
      earley_set--;
      /* Zero length lexemes are not of interest, so we do *not*
       * search the 0'th Earley set.
       */
  }
  LEXEMES_FOUND: ;
  return 0;
}

static void
slr_locations (Scanless_R * slr, Marpa_Earley_Set_ID earley_set, int *p_start,
	       int *p_end)
{
  dTHX;
  int result = 0;
  /* We need to fake the values for Earley set 0,
   *  since we are using it to store the values for Earley set 1.
   */
  if (earley_set <= 0)
    {
      *p_start = 0;
      *p_end = 0;
    }
  else
    {
      void *end_pos;
      result =
	marpa_r_earley_set_values (slr->r1, earley_set - 1, p_start,
				   &end_pos);
      *p_end = (int) PTR2IV (end_pos);
    }
  if (result < 0)
    {
      croak ("failure in slr->location(): %s", xs_g_error (slr->g1_wrapper));
    }
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin

PROTOTYPES: DISABLE

void
debug_level_set(level)
    int level;
PPCODE:
{
   marpa_debug_level_set(level);
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

void
op( op_name )
     char *op_name;
PPCODE:
{
  if (strEQ (op_name, "alternative"))
    {
      XSRETURN_IV (op_alternative);
    }
  if (strEQ (op_name, "ignore_rejection"))
    {
      XSRETURN_IV (op_ignore_rejection);
    }
  if (strEQ (op_name, "report_rejection"))
    {
      XSRETURN_IV (op_report_rejection);
    }
  if (strEQ (op_name, "earleme_complete"))
    {
      XSRETURN_IV (op_earleme_complete);
    }
  if (strEQ (op_name, "push_all"))
    {
      XSRETURN_IV (op_push_all);
    }
  if (strEQ (op_name, "push_sequence"))
    {
      XSRETURN_IV (op_push_sequence);
    }
  if (strEQ (op_name, "push_token_value"))
    {
      XSRETURN_IV (op_push_token_value);
    }
  if (strEQ (op_name, "push_one"))
    {
      XSRETURN_IV (op_push_one);
    }
  if (strEQ (op_name, "push_slr_range"))
    {
      XSRETURN_IV (op_push_slr_range);
    }
  if (strEQ (op_name, "bless"))
    {
      XSRETURN_IV (op_bless);
    }
  if (strEQ (op_name, "callback"))
    {
      XSRETURN_IV (op_callback);
    }
  if (strEQ (op_name, "result_is_array"))
    {
      XSRETURN_IV (op_result_is_array);
    }
  if (strEQ (op_name, "result_is_rhs_n"))
    {
      XSRETURN_IV (op_result_is_rhs_n);
    }
  if (strEQ (op_name, "result_is_constant"))
    {
      XSRETURN_IV (op_result_is_constant);
    }
  if (strEQ (op_name, "result_is_undef"))
    {
      XSRETURN_IV (op_result_is_undef);
    }
  if (strEQ (op_name, "end_marker"))
    {
      XSRETURN_IV (op_end_marker);
    }
  XSRETURN_UNDEF;
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
    case 1: {
      /* If we are using the (deprecated) interface 0,
       * get the throw setting from a (deprecated) global variable
       */
      SV *throw_sv = get_sv ("Marpa::R2::Thin::C::THROW", 0);
      throw = throw_sv && SvTRUE (throw_sv);
    }
    break;
    default: croak_xs_usage (cv, "class, arg_hash");
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

  error_code =
    marpa_check_version (MARPA_MAJOR_VERSION, MARPA_MINOR_VERSION,
			 MARPA_MICRO_VERSION);
  if (error_code == MARPA_ERR_NONE)
    {
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

Marpa_Rule_ID
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
Marpa_Rule_ID
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
		  set_error_from_string (g_wrapper, savepv(error_message));
		  if (g_wrapper->throw)
		    {
		      croak ("%s", error_message);
		    }
		  else
		    {
		      XSRETURN_UNDEF;
		    }
		}
		if (raw_min > INT_MAX) {
		  /* IV can be larger than int */
		  char *error_message =
		    form ("sequence_new(): min cannot be greater than %d", INT_MAX);
		  set_error_from_string (g_wrapper, savepv(error_message));
		  if (g_wrapper->throw)
		    {
		      croak ("%s", error_message);
		    }
		  else
		    {
		      XSRETURN_UNDEF;
		    }
		}
	      min = (int)raw_min;
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
	      separator = (Marpa_Symbol_ID)SvIV (arg_value);
	      continue;
	    }
	  {
	    char *error_message =
	      form ("unknown argument to sequence_new(): %.*s", (int) retlen,
		    key);
	    set_error_from_string (g_wrapper, savepv(error_message));
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
      croak ("Problem in g->sequence_new(%d, %d, ...): %s", lhs, rhs,
	     xs_g_error (g_wrapper));
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

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::U

void
new( class, g_sv )
    char * class;
    SV *g_sv;
PPCODE:
{
  SV* new_sv;
  Unicode_Stream *stream;
  if (!sv_isa (g_sv, "Marpa::R2::Thin::G"))
    {
      croak ("Problem in u->new(): arg is not of type Marpa::R2::Thin::G");
    }
  stream = u_new (g_sv);
  new_sv = sv_newmortal ();
  sv_setref_pv (new_sv, unicode_stream_class_name, (void *) stream);
  XPUSHs (new_sv);
}

void
DESTROY( stream )
    Unicode_Stream *stream;
PPCODE:
{
  u_destroy(stream);
}

 #  Always returns the same SV for a given stream -- 
 #  it does not create a new one
 # 
void
recce( stream )
    Unicode_Stream *stream;
PPCODE:
{
  SV *r0_sv = stream->r0_sv;
  if (!r0_sv)
    {
      R_Wrapper *r_wrapper = r_wrap (stream->r0, stream->g0_sv);
      marpa_r_ref (stream->r0);
      r0_sv = newSV (0);
      sv_setref_pv (r0_sv, recce_c_class_name, (void *) r_wrapper);
      stream->r0_sv = r0_sv;
    }
  XPUSHs (sv_2mortal (SvREFCNT_inc_simple_NN (r0_sv)));
}

void
trace( stream, level )
     Unicode_Stream *stream;
    int level;
PPCODE:
{
  if (level < 0)
    {
      /* Always thrown */
      croak ("Problem in u->trace(%d): argument must be greater than 0", level);
    }
  warn ("Setting Marpa scannerless stream trace level to %d", level);
  stream->trace = level;
  XPUSHs (sv_2mortal (newSViv (level)));
}


void
ignore_rejection( stream, boolean )
     Unicode_Stream *stream;
     IV boolean;
PPCODE:
{
     stream->ignore_rejection = boolean ? 1 : 0;
     XSRETURN_IV(stream->ignore_rejection);
}

void
_per_codepoint_ops( stream )
     Unicode_Stream *stream;
PPCODE:
{
  XPUSHs (sv_2mortal (newRV ((SV*)stream->per_codepoint_ops)));
}

void
char_register( stream, codepoint, ... )
     Unicode_Stream *stream;
     UV codepoint;
PPCODE:
{
  /* OP Count is args less two, then plus two for codepoint and length fields */
  const STRLEN op_count = items;
  STRLEN op_ix;
  STRLEN dummy;
  UV *ops;
  SV *ops_sv = newSV (op_count * sizeof (UV));
  SvPOK_on (ops_sv);
  ops = (UV *) SvPV (ops_sv, dummy);
  ops[0] = codepoint;
  ops[1] = op_count;
  for (op_ix = 2; op_ix < op_count; op_ix++)
    {
      /* By coincidence, offset of individual ops is 2 both in the
       * method arguments and in the op_list, so that arg IX == op_ix
       */
      ops[op_ix] = SvUV (ST (op_ix));
    }
  hv_store (stream->per_codepoint_ops, (char *) &codepoint,
	    sizeof (codepoint), ops_sv, 0);
}

void
string_set( stream, string )
     Unicode_Stream *stream;
     SVREF string;
PPCODE:
{
  STRLEN length; /* set, but not used */
  stream->perl_pos = 0;
  stream->input_offset = 0;
  /* Get our own copy and coerce it to a PV.
   * Stealing in OK, magic is not.
   */
  SvSetSV (stream->input, string);
  SvPV_force_nomg (stream->input, length);
}

void
pos( stream )
     Unicode_Stream *stream;
PPCODE:
{
  XSRETURN_IV(stream->perl_pos);
}

void
codepoint( stream )
     Unicode_Stream *stream;
PPCODE:
{
  XSRETURN_UV(stream->codepoint);
}

void
symbol_id( stream )
     Unicode_Stream *stream;
PPCODE:
{
  XSRETURN_IV(stream->input_symbol_id);
}

void
offset( stream )
     Unicode_Stream *stream;
PPCODE:
{
  XSRETURN_IV(stream->input_offset);
}

void
pos_set( stream, new_pos )
     Unicode_Stream *stream;
     STRLEN new_pos;
PPCODE:
{
  const STRLEN old_pos = u_pos_set(stream, new_pos);
  u_r0_clear(stream);
  XSRETURN_IV (old_pos);
}

void
read( stream )
     Unicode_Stream *stream;
PPCODE:
{
  const int return_value = u_read(stream);
  XSRETURN_IV(return_value);
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
  v_wrapper->token_values = NULL;
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
  if (v_wrapper->token_values)
    {
      SvREFCNT_dec (v_wrapper->token_values);
    }
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
    event_data[0] = newSVpvs ("trace level");
    event_data[1] = newSViv (old_level);
    event_data[2] = newSViv (level);
    event = av_make (Dim (event_data), event_data);
    av_push (v_wrapper->event_queue, newRV_noinc ((SV *) event));
  }
  XSRETURN_IV (old_level);
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
  const Marpa_Step_Type status = marpa_v_step (v);

  if (v_wrapper->mode == MARPA_XS_V_MODE_IS_INITIAL) {
    v_wrapper->mode = MARPA_XS_V_MODE_IS_RAW;
  }
  if (v_wrapper->mode != MARPA_XS_V_MODE_IS_RAW) {
       if (v_wrapper->stack) {
	  croak ("Problem in v->step(): Cannot call when valuator is in 'stack' mode");
       }
  }
  av_clear (v_wrapper->event_queue);
  if (status == MARPA_STEP_INACTIVE)
    {
      XSRETURN_EMPTY;
    }
  if (status < 0)
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
  result_string = step_type_to_string (status);
  if (!result_string)
    {
      char *error_message =
	form ("Problem in v->step(): unknown step type %d", status);
      set_error_from_string (v_wrapper->base, savepv(error_message));
      if (v_wrapper->base->throw)
	{
	  croak ("%s", error_message);
	}
      XPUSHs (sv_2mortal (newSVpv (error_message, 0)));
      XSRETURN (1);
    }
  XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
  if (status == MARPA_STEP_TOKEN)
    {
      token_id = marpa_v_token (v);
      XPUSHs (sv_2mortal (newSViv (token_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_token_value (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_result (v))));
    }
  if (status == MARPA_STEP_NULLING_SYMBOL)
    {
      token_id = marpa_v_token (v);
      XPUSHs (sv_2mortal (newSViv (token_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_result (v))));
    }
  if (status == MARPA_STEP_RULE)
    {
      rule_id = marpa_v_rule (v);
      XPUSHs (sv_2mortal (newSViv (rule_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_0 (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_n (v))));
    }
}

void
stack_mode_set( v_wrapper, token_values )
    V_Wrapper *v_wrapper;
    AV* token_values;
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

  v_wrapper->token_values = token_values;
  SvREFCNT_inc (token_values);

  {
    int ix;
    UV ops[3];
    const int highest_rule_id = marpa_g_highest_rule_id (g);
    AV *av = v_wrapper->rule_semantics;
    av_extend (av, highest_rule_id);
    ops[0] = op_push_all;
    ops[1] = op_callback;
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
	sv_setpvn (*p_sv, (char *) ops, sizeof (ops));
      }
  }

  { /* Set the default nulling symbol semantics */
    int ix;
    UV ops[2];
    const int highest_symbol_id = marpa_g_highest_symbol_id (g);
    AV *av = v_wrapper->nulling_semantics;
    av_extend (av, highest_symbol_id);
    ops[0] = op_result_is_undef;
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
	sv_setpvn (*p_sv, (char *) ops, sizeof (ops));
      }
  }

  { /* Set the default token semantics */
    int ix;
    UV ops[2];
    const int highest_symbol_id = marpa_g_highest_symbol_id (g);
    AV *av = v_wrapper->token_semantics;
    av_extend (av, highest_symbol_id);
    ops[0] = op_result_is_token_value;
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
	sv_setpvn (*p_sv, (char *) ops, sizeof (ops));
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
  UV *ops;
  SV *ops_sv;
  AV *rule_semantics = v_wrapper->rule_semantics;

  if (!rule_semantics)
    {
      croak ("Problem in v->rule_register(): valuator is not in stack mode");
    }

  /* Leave room for final 0 */
  ops_sv = newSV ((op_count+1) * sizeof (UV));

  SvPOK_on (ops_sv);
  ops = (UV *) SvPV (ops_sv, dummy);
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
  UV *ops;
  SV *ops_sv;
  AV *token_semantics = v_wrapper->token_semantics;

  if (!token_semantics)
    {
      croak ("Problem in v->token_register(): valuator is not in stack mode");
    }

  /* Leave room for final 0 */
  ops_sv = newSV ((op_count+1) * sizeof (UV));

  SvPOK_on (ops_sv);
  ops = (UV *) SvPV (ops_sv, dummy);
  for (op_ix = 0; op_ix < op_count; op_ix++)
    {
      ops[op_ix] = SvUV (ST (op_ix+2));
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
  UV *ops;
  SV *ops_sv;
  AV *nulling_semantics = v_wrapper->nulling_semantics;

  if (!nulling_semantics)
    {
      croak ("Problem in v->nulling_symbol_register(): valuator is not in stack mode");
    }

  /* Leave room for final 0 */
  ops_sv = newSV ((op_count+1) * sizeof (UV));

  SvPOK_on (ops_sv);
  ops = (UV *) SvPV (ops_sv, dummy);
  for (op_ix = 0; op_ix < op_count; op_ix++)
    {
      ops[op_ix] = SvUV (ST (op_ix+2));
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
  IV length;
  AV* stack = v_wrapper->stack;
  if (!stack) { XSRETURN_UNDEF; }
  length = stack ? av_len(stack) : -1;
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
  const Marpa_Value v = v_wrapper->v;
  const char *result_string;
  Marpa_Step_Type status;
  AV *stack = v_wrapper->stack;
  AV *token_values = v_wrapper->token_values;
  AV *values_av = NULL;

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
      status = marpa_v_step (v);
      if (status == MARPA_STEP_INACTIVE)
	{
	  XSRETURN_EMPTY;
	}
      if (status < 0)
	{
	  const char *error_message = xs_g_error (v_wrapper->base);
	  if (v_wrapper->base->throw)
	    {
	      croak ("Problem in v_>stack_step(): %s", error_message);
	    }
	  XPUSHs (sv_2mortal
		  (newSVpvf
		   ("Problem in v_>stack_step(): %s", error_message)));
	  XSRETURN (1);
	}
      result_string = step_type_to_string (status);
      if (!result_string)
	{
	  char *error_message =
	    form ("Problem in v->stack_step(): unknown step type %d", status);
	  set_error_from_string (v_wrapper->base, savepv (error_message));
	  if (v_wrapper->base->throw)
	    {
	      croak ("%s", error_message);
	    }
	  XPUSHs (sv_2mortal (newSVpv (error_message, 0)));
	  XSRETURN (1);
	}

      if (status == MARPA_STEP_TOKEN)
	{
	  IV token_id = marpa_v_token (v);
	  IV token_value_ix = marpa_v_token_value (v);
	  IV result_ix = v_wrapper->result = marpa_v_result (v);

	  UV *token_ops;
	  int op_ix;
	  UV blessing = 0;

	  {
	    STRLEN dummy;
	    SV **p_ops_sv =
	      av_fetch (v_wrapper->token_semantics, token_id, 0);
	    if (!p_ops_sv)
	      {
		croak
		  ("Problem in v->stack_step: token %ld is not registered",
		   (long) token_id);
	      }
	    token_ops = (UV *) SvPV (*p_ops_sv, dummy);
	  }

	  /* Create a values_av or, if there is one,
	   * clear the old values out.
	   * It's mortal, so it will go away unless we
	   * de-mortalize it.
	   */
	  if (!values_av)
	    {
	      values_av = (AV *) sv_2mortal ((SV *) newAV ());
	    }
	  av_clear (values_av);

	  op_ix = 0;
	  while (1)
	    {
	      UV op_code = token_ops[op_ix++];

	      switch (op_code)
		{

		case 0:
		  goto NEXT_STEP;

		case op_push_token_value:
		  {
		    SV **p_token_value_sv;

		    p_token_value_sv =
		      av_fetch (token_values, token_value_ix, 0);
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

		case op_bless:
		  {
		    blessing = token_ops[op_ix++];
		  }
		  break;

		case op_result_is_token_value:
		  {
		    SV **p_token_value_sv;

		    p_token_value_sv =
		      av_fetch (token_values, token_value_ix, 0);
		    if (p_token_value_sv)
		      {
			SV *token_value_sv = newSVsv (*p_token_value_sv);
			SV **stored_sv =
			  av_store (stack, result_ix, token_value_sv);
			if (!stored_sv)
			  {
			    SvREFCNT_dec (token_value_sv);
			  }
		      }
		    else
		      {
			av_store (stack, result_ix, &PL_sv_undef);
		      }

		    if (v_wrapper->trace_values)
		      {
			AV *event;
			SV *event_data[4];
			event_data[0] = newSVpv (result_string, 0);
			event_data[1] = newSViv (token_id);
			event_data[2] = newSViv (token_value_ix);
			event_data[3] = newSViv (v_wrapper->result);
			event = av_make (Dim (event_data), event_data);
			av_push (v_wrapper->event_queue,
				 newRV_noinc ((SV *) event));
		      }

		  }
		  goto NEXT_STEP;
		case op_result_is_array:
		  {
		    SV **stored_av;
		    /* Increment ref count of values_av to de-mortalize it */
		    SV *ref_to_values_av = newRV_inc ((SV *) values_av);
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
		    blessing = 0;
		    stored_av = av_store (stack, result_ix, ref_to_values_av);

		    /* Clear the way for a new values AV
		     * The mortal refcount held by this pointer will be
		     * decremented eventually
		     */
		    values_av = NULL;
		    /* If the new RV did not get stored properly,
		     * decrement its ref count
		     */
		    if (!stored_av)
		      {
			/* This should not happen */
			SvREFCNT_dec (ref_to_values_av);
			av_fill (stack, result_ix - 1);
			croak
			  ("Internal error: Could not write to stack at %s %d",
			   __FILE__, __LINE__);
			goto NEXT_STEP;
		      }
		    av_fill (stack, result_ix);

		  }
		  goto NEXT_STEP;
		default:
		  croak
		    ("Problem in v->stack_step: Unimplemented op code: %lu",
		     (unsigned long) op_code);
		}
	    }

	  goto NEXT_STEP;
	}
      if (status == MARPA_STEP_NULLING_SYMBOL)
	{
	  Marpa_Symbol_ID token_id = marpa_v_token (v);
	  int result_stack_ix = v_wrapper->result = marpa_v_result (v);
	  UV *nulling_ops;
	  int op_ix;

	  {
	    STRLEN dummy;
	    SV **p_ops_sv =
	      av_fetch (v_wrapper->nulling_semantics, token_id, 0);
	    if (!p_ops_sv)
	      {
		croak
		  ("Problem in v->stack_step: symbol %d is not registered",
		   token_id);
	      }
	    nulling_ops = (UV *) SvPV (*p_ops_sv, dummy);
	  }

	  op_ix = 0;
	  while (1)
	    {
	      UV op_code = nulling_ops[op_ix++];

	      switch (op_code)
		{

		case 0:
		  goto NEXT_STEP;

		case op_result_is_undef:
		  {
		    av_fill (stack, -1 + result_stack_ix);
		  }
		  goto NEXT_STEP;

		case op_result_is_constant:
		  {
		    IV constant_ix = nulling_ops[op_ix++];
		    SV **p_constant_sv;

		    p_constant_sv =
		      av_fetch (v_wrapper->constants, constant_ix, 0);
		    if (p_constant_sv)
		      {
			SV *constant_sv = newSVsv (*p_constant_sv);
			SV **stored_sv =
			  av_store (stack, result_stack_ix, constant_sv);
			if (!stored_sv)
			  {
			    SvREFCNT_dec (constant_sv);
			  }
		      }
		    else
		      {
			av_store (stack, result_stack_ix, &PL_sv_undef);
		      }

		    if (v_wrapper->trace_values)
		      {
			AV *event;
			SV *event_data[3];
			event_data[0] = newSVpv (result_string, 0);
			event_data[1] = newSViv (token_id);
			event_data[2] = newSViv (result_stack_ix);
			event = av_make (Dim (event_data), event_data);
			av_push (v_wrapper->event_queue,
				 newRV_noinc ((SV *) event));
		      }
		  }
		  goto NEXT_STEP;

		case op_callback:
		  {
		    XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
		    XPUSHs (sv_2mortal (newSViv (token_id)));
		    XPUSHs (sv_2mortal (newSViv (result_stack_ix)));
		    XSRETURN (3);
		  }
		  /* NOT REACHED */
		default:
		  croak
		    ("Problem in v->stack_step: Unimplemented op code: %lu",
		     (unsigned long) op_code);
		  /* NOT REACHED */
		}
	    }

	  /* NOT REACHED */
	  goto NEXT_STEP;
	}

      if (status == MARPA_STEP_RULE)
	{
	  Marpa_Rule_ID rule_id = marpa_v_rule (v);
	  IV arg_0 = marpa_v_arg_0 (v);
	  IV arg_n = marpa_v_arg_n (v);
	  UV *rule_ops;
	  int op_ix;
	  UV blessing = 0;

	  v_wrapper->result = arg_0;

	  {
	    STRLEN dummy;
	    SV **p_ops_sv = av_fetch (v_wrapper->rule_semantics, rule_id, 0);
	    if (!p_ops_sv)
	      {
		croak ("Problem in v->stack_step: rule %d is not registered",
		       rule_id);
	      }
	    rule_ops = (UV *) SvPV (*p_ops_sv, dummy);
	  }

	  /* Create a values_av or, if there is one,
	   * clear the old values out.
	   * It's mortal, so it will go away unless we
	   * de-mortalize it.
	   */
	  if (!values_av)
	    {
	      values_av = (AV *) sv_2mortal ((SV *) newAV ());
	    }
	  av_clear (values_av);

	  op_ix = 0;
	  while (1)
	    {
	      UV op_code = rule_ops[op_ix++];

	      switch (op_code)
		{

		case 0:
		  goto NEXT_STEP;

		case op_result_is_undef:
		  {
		    av_fill (stack, -1 + arg_0);
		  }
		  goto NEXT_STEP;

		case op_result_is_rhs_n:
		  {
		    SV **stored_av;
		    SV **p_sv;
		    UV stack_ix = rule_ops[op_ix++];

		    if (stack_ix == 0)
		      {
			/* Special-cased for two reasons --
			 * it's common and can be optimized.
			 */
			av_fill (stack, arg_0);
			goto NEXT_STEP;
		      }
		    p_sv = av_fetch (stack, arg_0 + stack_ix, 0);
		    if (!p_sv)
		      {
			av_fill (stack, arg_0 - 1);
			goto NEXT_STEP;
		      }
		    stored_av =
		      av_store (stack, arg_0, SvREFCNT_inc_NN (*p_sv));
		    if (!stored_av)
		      {
			SvREFCNT_dec (*p_sv);
			av_fill (stack, arg_0 - 1);
			goto NEXT_STEP;
		      }
		    av_fill (stack, arg_0);
		  }
		  goto NEXT_STEP;

		case op_result_is_array:
		  {
		    SV **stored_av;
		    /* Increment ref count of values_av to de-mortalize it */
		    SV *ref_to_values_av = newRV_inc ((SV *) values_av);
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
		    blessing = 0;
		    stored_av = av_store (stack, arg_0, ref_to_values_av);

		    /* Clear the way for a new values AV
		     * The mortal refcount held by this pointer will be
		     * decremented eventually
		     */
		    values_av = NULL;
		    /* If the new RV did not get stored properly,
		     * decrement its ref count
		     */
		    if (!stored_av)
		      {
			SvREFCNT_dec (ref_to_values_av);
			av_fill (stack, arg_0 - 1);
			goto NEXT_STEP;
		      }
		    av_fill (stack, arg_0);
		  }
		  goto NEXT_STEP;

		case op_push_all:
		case op_push_sequence:
		  {
		    int stack_ix;
		    int increment = op_code == op_push_sequence ? 2 : 1;
		    /* Create a mortalized array, so that it will go away
		     * by default.
		     */
		    for (stack_ix = arg_0; stack_ix <= arg_n;
			 stack_ix += increment)
		      {
			SV **p_sv = av_fetch (stack, stack_ix, 0);
			if (!p_sv)
			  {
			    av_push (values_av, &PL_sv_undef);
			  }
			else
			  {
			    av_push (values_av,
				     SvREFCNT_inc_simple_NN (*p_sv));
			  }
		      }
		  }
		  break;

		case op_push_one:
		  {
		    int offset = rule_ops[op_ix++];
		    SV **p_sv = av_fetch (stack, arg_0 + offset, 0);
		    if (!p_sv)
		      {
			av_push (values_av, &PL_sv_undef);
		      }
		    else
		      {
			av_push (values_av, SvREFCNT_inc_simple_NN (*p_sv));
		      }
		  }
		  break;

		case op_push_slr_range:
		  {
		    Marpa_Earley_Set_ID earley_set;
		    int start_location;
		    int end_location;
		    Scanless_R *slr = v_wrapper->slr;
		    if (!slr)
		      {
			croak
			  ("Problem in v->stack_step: Push SLR op attempted when no slr is set");
		      }
		    earley_set = marpa_v_rule_start_es_id (v);
		    slr_locations(slr, earley_set, &start_location, &end_location);
		    av_push (values_av, newSViv((IV)start_location));
		    earley_set = marpa_v_es_id (v);
		    slr_locations(slr, earley_set, &start_location, &end_location);
		    av_push (values_av, newSViv((IV)end_location));
		  }
		  break;
		
		case op_bless:
		  {
		    blessing = rule_ops[op_ix++];
		  }
		  break;

		case op_callback:
		  {
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
		    blessing = 0;
		    XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
		    XPUSHs (sv_2mortal (newSViv (rule_id)));
		    /* Must increment ref cnt of array to de-mortalize it,
		     * but the RV must be mortal.
		     */
		    XPUSHs (ref_to_values_av);
		    XSRETURN (3);
		  }
		  /* NOT REACHED */
		default:
		  croak
		    ("Problem in v->stack_step: Unimplemented op code: %lu",
		     (unsigned long) op_code);
		}
	    }

	  goto NEXT_STEP;
	}

      /* Default is just return the status string and let the upper
       * layer deal with it.
       */
      XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
      XSRETURN (1);

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
_marpa_g_symbol_is_semantic( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_symbol_is_semantic (g, symbol_id);
  if (result < 0)
    {
      croak ("Problem in g->_marpa_g_symbol_is_semantic(): %s", xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
_marpa_g_isy_is_nulling( g_wrapper, isy_id )
    G_Wrapper *g_wrapper;
    Marpa_ISY_ID isy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_isy_is_nulling (g, isy_id);
  if (result < 0)
    {
      croak ("Problem in g->_marpa_g_isy_is_nulling(%d): %s", isy_id,
	     xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
_marpa_g_isy_is_start( g_wrapper, isy_id )
    G_Wrapper *g_wrapper;
    Marpa_ISY_ID isy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_isy_is_start (g, isy_id);
  if (result < 0)
    {
      croak ("Invalid isy %d", isy_id);
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

Marpa_Symbol_ID
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

Marpa_Rule_ID
_marpa_g_isy_lhs_xrl( g_wrapper, isy_id )
    G_Wrapper *g_wrapper;
    Marpa_ISY_ID isy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  Marpa_Rule_ID rule_id = _marpa_g_isy_lhs_xrl (g, isy_id);
  if (rule_id < -1)
    {
      croak ("problem with g->_marpa_g_isy_lhs_xrl: %s",
	     xs_g_error (g_wrapper));
    }
  if (rule_id < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (rule_id)));
}

Marpa_Rule_ID
_marpa_g_isy_xrl_offset( g_wrapper, isy_id )
    G_Wrapper *g_wrapper;
    Marpa_ISY_ID isy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int offset = _marpa_g_isy_xrl_offset (g, isy_id);
  if (offset == -1)
    {
      XSRETURN_UNDEF;
    }
  if (offset < 0)
    {
      croak ("problem with g->_marpa_g_isy_xrl_offset: %s",
	     xs_g_error (g_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (offset)));
}

int
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

int
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

Marpa_Rule_ID
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

Marpa_Rule_ID
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

Marpa_Rule_ID
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

int
_marpa_g_AHFA_item_count( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_AHFA_item_count (g);
  if (result <= -2)
    {
      croak ("Problem in g->_marpa_g_AHFA_item_count(): %s", xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

int
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

int
_marpa_g_isy_count( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_isy_count (g);
  if (result < -1)
    {
      croak ("Problem in g->_marpa_g_isy_count(): %s", xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

Marpa_IRL_ID
_marpa_g_AHFA_item_irl( g_wrapper, item_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_Item_ID item_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_AHFA_item_irl(g, item_id);
    if (result < 0) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

 # -1 is a valid return value, so -2 indicates an error
int
_marpa_g_AHFA_item_position( g_wrapper, item_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_Item_ID item_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_AHFA_item_position(g, item_id);
    if (result <= -2) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

int
_marpa_g_AHFA_item_sort_key( g_wrapper, item_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_Item_ID item_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_AHFA_item_sort_key(g, item_id);
    if (result < 0) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

 # -1 is a valid return value, and -2 indicates an error
Marpa_Symbol_ID
_marpa_g_AHFA_item_postdot( g_wrapper, item_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_Item_ID item_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_AHFA_item_postdot(g, item_id);
    if (result <= -2) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

int
_marpa_g_AHFA_state_count( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_AHFA_state_count(g );
    if (result < 0) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

 # In scalar context, returns the count
void
_marpa_g_AHFA_state_items( g_wrapper, AHFA_state_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int count = _marpa_g_AHFA_state_item_count(g, AHFA_state_id);
    if (count < 0) { croak("Invalid AHFA state %d", AHFA_state_id); }
    if (GIMME == G_ARRAY) {
        int item_ix;
        EXTEND(SP, count);
        for (item_ix = 0; item_ix < count; item_ix++) {
	    Marpa_AHFA_Item_ID item_id
		= _marpa_g_AHFA_state_item(g, AHFA_state_id, item_ix);
            PUSHs( sv_2mortal( newSViv(item_id) ) );
        }
    } else {
        XPUSHs( sv_2mortal( newSViv(count) ) );
    }
}

 # In scalar context, returns the count
void
_marpa_g_AHFA_state_transitions( g_wrapper, AHFA_state_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
{
  int result_count;
  int *buffer;
  Marpa_Grammar g = g_wrapper->g;
  const int highest_symbol_id = marpa_g_highest_symbol_id(g);
  const int symbol_count = highest_symbol_id+1;
  if (highest_symbol_id < 0)
    {
      if (!g_wrapper->throw) { XSRETURN_UNDEF; }
      croak ("failure in marpa_g_highest_symbol_id: %s", xs_g_error (g_wrapper));
    };
  Newx( buffer, 2 * symbol_count, int);
  result_count =
    _marpa_g_AHFA_state_transitions (g, AHFA_state_id, buffer, 2*symbol_count*sizeof(int));
  if (result_count < 0)
    {
	Safefree(buffer);
      croak ("Problem in g->_marpa_g_AHFA_state_transitions(): %s", xs_g_error (g_wrapper));
    }
  if (GIMME == G_ARRAY)
    {
      int ix;
      for (ix = 0; ix < result_count*2; ix++)
	{
	  XPUSHs (sv_2mortal (newSViv (buffer[ix] )));
	}
    }
  else
    {
      XPUSHs (sv_2mortal (newSViv (result_count)));
    }
    Safefree(buffer);
}

 # -1 is a valid return value, and -2 indicates an error
Marpa_AHFA_State_ID
_marpa_g_AHFA_state_empty_transition( g_wrapper, AHFA_state_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_AHFA_state_empty_transition(g, AHFA_state_id);
    if (result <= -2) { XSRETURN_UNDEF; }
      XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_g_AHFA_state_is_predict( g_wrapper, AHFA_state_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_AHFA_state_is_predict (g, AHFA_state_id);
  if (result < 0)
    {
      croak ("Problem in AHFA_state_is_predict(%d): %s", AHFA_state_id,
	xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
_marpa_g_AHFA_state_leo_lhs_symbol( g_wrapper, AHFA_state_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_AHFA_state_leo_lhs_symbol (g, AHFA_state_id);
  if (result == -1)
    XSRETURN_UNDEF;
  if (result < 0)
    {
      croak ("Problem in AHFA_state_leo_lhs_symbol(%d): %s", AHFA_state_id,
	xs_g_error (g_wrapper));
    }
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
    Marpa_AHFA_State_ID result = _marpa_r_earley_set_trace(
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
    Marpa_AHFA_State_ID result = _marpa_r_earley_item_trace(
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
_marpa_r_leo_expansion_ahfa( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int leo_expansion_ahfa = _marpa_r_leo_expansion_ahfa (r);
  if (leo_expansion_ahfa == -1)
    {
      XSRETURN_UNDEF;
    }
  if (leo_expansion_ahfa < 0)
    {
      croak ("Problem in r->leo_expansion_ahfa(): %s", xs_g_error(r_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (leo_expansion_ahfa)));
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

void
_marpa_b_top_or_node( b_wrapper )
     B_Wrapper *b_wrapper;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_top_or_node (b);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_top_or_node(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_or_node_set( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_or_node_set (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_or_node_set(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_or_node_origin( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_or_node_origin (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_or_node_origin(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_or_node_position( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_or_node_position (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_or_node_position(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_or_node_irl( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_or_node_irl (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_or_node_irl(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_or_node_first_and( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_or_node_first_and (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_or_node_first_and(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_or_node_last_and( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_or_node_last_and (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_or_node_last_and(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_or_node_and_count( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_or_node_and_count (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_or_node_and_count(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_and_node_count( b_wrapper )
     B_Wrapper *b_wrapper;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_and_node_count (b);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_and_node_count(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_and_node_parent( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_and_node_parent (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_and_node_parent(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_and_node_predecessor( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_and_node_predecessor (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_and_node_predecessor(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_and_node_cause( b_wrapper, ordinal )
     B_Wrapper *b_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_and_node_cause (b, ordinal);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in b->_marpa_b_and_node_cause(): %s",
	     xs_g_error(b_wrapper->base));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
_marpa_b_and_node_symbol( b_wrapper, and_node_id )
     B_Wrapper *b_wrapper;
     Marpa_And_Node_ID and_node_id;
PPCODE:
{
  Marpa_Bocage b = b_wrapper->b;
  int result = _marpa_b_and_node_symbol (b, and_node_id);
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
}

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

int
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

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::T

int
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

int
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

int
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

int
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

int
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

int
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


int
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

int
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
new( class, g0_sv, g1_sv )
    char * class;
    SV *g0_sv;
    SV *g1_sv;
PPCODE:
{
  SV* new_sv;
  Scanless_G *slg;

  if (!sv_isa (g0_sv, "Marpa::R2::Thin::G"))
    {
      croak ("Problem in u->new(): g0 arg is not of type Marpa::R2::Thin::G");
    }
  if (!sv_isa (g1_sv, "Marpa::R2::Thin::G"))
    {
      croak ("Problem in u->new(): r1 arg is not of type Marpa::R2::Thin::G");
    }
  Newx (slg, 1, Scanless_G);

  # Copy and take references to the parent objects
  slg->g0_sv = g0_sv;
  SvREFCNT_inc (g0_sv);
  slg->g1_sv = g1_sv;
  SvREFCNT_inc (g1_sv);

  # These do not need references, because parent objects
  # hold references to them
  SET_G_WRAPPER_FROM_G_SV(slg->g0_wrapper, g0_sv)
  SET_G_WRAPPER_FROM_G_SV(slg->g1_wrapper, g1_sv)
  slg->g0 = slg->g0_wrapper->g;
  slg->g1 = slg->g1_wrapper->g;

  {
    Marpa_Rule_ID rule;
    Marpa_Rule_ID g0_rule_count = marpa_g_highest_rule_id (slg->g0) + 1;
    Newx (slg->g0_rule_to_g1_lexeme, g0_rule_count, Marpa_Symbol_ID);
    for (rule = 0; rule < g0_rule_count; rule++)
      {
	slg->g0_rule_to_g1_lexeme[rule] = -1;
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
  SvREFCNT_dec (slg->g0_sv);
  SvREFCNT_dec (slg->g1_sv);
  Safefree(slg->g0_rule_to_g1_lexeme);
  Safefree(slg);
}

 #  Always returns the same SV for a given Scanless recce object -- 
 #  it does not create a new one
 # 
void
g0( slg )
    Scanless_G *slg;
PPCODE:
{
  /* Not mortalized because,
   * held for the length of the scanless object.
   */
  XPUSHs (sv_2mortal (SvREFCNT_inc_NN (slg->g0_sv)));
}

 #  Always returns the same SV for a given Scanless recce object -- 
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
g0_rule_to_g1_lexeme_set( slg, g0_rule, g1_lexeme )
    Scanless_G *slg;
    Marpa_Rule_ID g0_rule;
    Marpa_Symbol_ID g1_lexeme;
PPCODE:
{
  Marpa_Rule_ID highest_g0_rule_id = marpa_g_highest_rule_id (slg->g0);
  Marpa_Symbol_ID highest_g1_symbol_id = marpa_g_highest_symbol_id (slg->g1);
    if (g0_rule > highest_g0_rule_id) 
    {
      croak
	("Problem in slg->g0_rule_to_g1_lexeme_set(%ld, %ld): rule ID was %ld, but highest G0 rule ID = %ld",
	 (unsigned long) g0_rule,
	 (unsigned long) g1_lexeme,
	 (unsigned long) g0_rule,
	 (unsigned long) g1_lexeme);
    }
    if (g1_lexeme > highest_g1_symbol_id) 
    {
      croak
	("Problem in slg->g0_rule_to_g1_lexeme_set(%ld, %ld): symbol ID was %ld, but highest G1 symbol ID = %ld",
	 (unsigned long) g0_rule,
	 (unsigned long) g1_lexeme,
	 (unsigned long) g0_rule,
	 (unsigned long) g1_lexeme);
    }
    if (g0_rule < -2) {
      croak
	("Problem in slg->g0_rule_to_g1_lexeme_set(%ld, %ld): rule ID was %ld, a disallowed value",
	 (unsigned long) g0_rule,
	 (unsigned long) g1_lexeme,
	 (unsigned long) g0_rule);
    }
    if (g1_lexeme < -2) {
      croak
	("Problem in slg->g0_rule_to_g1_lexeme_set(%ld, %ld): symbol ID was %ld, a disallowed value",
	 (unsigned long) g0_rule,
	 (unsigned long) g1_lexeme,
	 (unsigned long) g1_lexeme);
    }
  slg->g0_rule_to_g1_lexeme[g0_rule] = g1_lexeme;
  XSRETURN_YES;
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::SLR

void
new( class, slg_sv, r1_sv )
    char * class;
    SV *slg_sv;
    SV *r1_sv;
PPCODE:
{
  SV* new_sv;
  Scanless_R *slr;
  Scanless_G *slg;

  if (!sv_isa (slg_sv, "Marpa::R2::Thin::SLG"))
    {
      croak ("Problem in u->new(): g0 arg is not of type Marpa::R2::Thin::SLG");
    }
  if (!sv_isa (r1_sv, "Marpa::R2::Thin::R"))
    {
      croak ("Problem in u->new(): r1 arg is not of type Marpa::R2::Thin::R");
    }
  Newx (slr, 1, Scanless_R);

  slr->trace_level = 0;
  slr->trace_terminals = 0;

  # Copy and take references to the "parent objects",
  # the ones responsible for holding references.
  slr->slg_sv = slg_sv;
  SvREFCNT_inc (slg_sv);
  slr->r1_sv = r1_sv;
  SvREFCNT_inc (r1_sv);

  # These do not need references, because parent objects
  # hold references to them
  SET_R_WRAPPER_FROM_R_SV(slr->r1_wrapper, r1_sv);
  SET_SLG_FROM_SLG_SV(slg, slg_sv);
  slr->slg = slg;
  slr->r1 = slr->r1_wrapper->r;
  SET_G_WRAPPER_FROM_G_SV(slr->g1_wrapper, slr->r1_wrapper->base_sv);

  slr->start_of_lexeme = 0;
  slr->end_of_lexeme = 0;
  slr->event_queue = newAV();

  {
    SV* g0_sv = slg->g0_sv;
    Unicode_Stream* stream = u_new (g0_sv);
    SV* stream_sv = newSV (0);
    SET_G_WRAPPER_FROM_G_SV(slr->g0_wrapper, g0_sv);
    sv_setref_pv (stream_sv, unicode_stream_class_name, (void *) stream);
    slr->stream = stream;
    slr->stream_sv = stream_sv;
  }

  slr->please_start_lex_recce = 1;
  slr->stream_read_result = 0;
  slr->r1_earleme_complete_result = 0;

  new_sv = sv_newmortal ();
  sv_setref_pv (new_sv, scanless_r_class_name, (void *) slr);
  XPUSHs (new_sv);
}

void
DESTROY( slr )
    Scanless_R *slr;
PPCODE:
{
  SvREFCNT_dec (slr->stream_sv);
  SvREFCNT_dec (slr->slg_sv);
  SvREFCNT_dec (slr->r1_sv);
  SvREFCNT_dec ((SV*)slr->event_queue);
  Safefree(slr);
}

void
trace( slr, level )
    Scanless_R *slr;
    int level;
PPCODE:
{
  IV old_level = slr->trace_level;
  slr->trace_level = level;
  warn("Changing SLR trace level from %d to %d", (int)old_level, (int)level);
  XSRETURN_IV(old_level);
}

void
trace_terminals( slr, level )
    Scanless_R *slr;
    int level;
PPCODE:
{
  IV old_level = slr->trace_terminals;
  slr->trace_terminals = level;
  if (slr->trace_level) {
    /* Note that we use *trace_level*, not *trace_terminals* to control warning.
     * We never warn() for trace_terminals, just report events.
     */
    warn("Changing SLR trace terminals level from %d to %d", (int)old_level, (int)level);
  }
  XSRETURN_IV(old_level);
}

 #  Always returns the same SV for a given Scanless recce object -- 
 #  it does not create a new one
 # 
void
g0( slr )
    Scanless_R *slr;
PPCODE:
{
  XPUSHs (sv_2mortal (SvREFCNT_inc_NN ( slr->slg->g0_sv)));
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

 #  Always returns the same SV for a given Scanless recce object -- 
 #  it does not create a new one
 # 
void
stream( slr )
    Scanless_R *slr;
PPCODE:
{
  XPUSHs (sv_2mortal (SvREFCNT_inc_NN ( slr->stream_sv)));
}

void
read(slr)
    Scanless_R *slr;
PPCODE:
{
  int result = 0;		/* Hold various results */

  slr->stream_read_result = 0;
  slr->r1_earleme_complete_result = 0;
  while (1)
    {
      IV lexemes_found = 0;
      IV lexemes_attempted = 0;

      if (slr->please_start_lex_recce)
	{
	  Unicode_Stream *stream = slr->stream;
	  STRLEN input_length = SvCUR (stream->input);

	  slr->start_of_lexeme = slr->end_of_lexeme;
	  u_pos_set (stream, slr->start_of_lexeme);
	  if (stream->input_offset >= input_length)
	    {
	      XSRETURN_PV ("");
	    }

	  slr->please_start_lex_recce = 0;
	  u_r0_clear (stream);
	}

      av_clear (slr->event_queue);

      result = slr->stream_read_result = u_read (slr->stream);
      if (result == -2)
	{
	  XSRETURN_PV ("unregistered char");
	}
      if (result < -1)
	{
	  XSRETURN_PV ("R0 read() problem");
	}

      result =
	slr_stub_alternatives (slr, &lexemes_found, &lexemes_attempted);
      if (result == -4)
	{
	  XSRETURN_PV ("R0 exhausted before end");
	}
      if (!lexemes_found)
	{
	  XSRETURN_PV ("no lexeme");
	}
      slr->please_start_lex_recce = 1;	/* We found a lexeme, so must restart r0 */

      if (lexemes_attempted)
	{
	  G_Wrapper *g1_wrapper = slr->g1_wrapper;
	  slr->g1_wrapper->throw = 0;
	  result = slr->r1_earleme_complete_result =
	    marpa_r_earleme_complete (slr->r1);
	  slr->g1_wrapper->throw = 1;
	  if (result < 0)
	    {
	      XSRETURN_PV ("R1 earleme_complete() problem");
	    }
	}

      if (slr->trace_terminals)
	{
	  XSRETURN_PV ("trace");
	}

    }

  /* Never reached */
  XSRETURN_PV ("");
}

void
stream_read_result (slr)
     Scanless_R *slr;
PPCODE:
{
  XPUSHs (sv_2mortal (newSViv ((IV) slr->stream_read_result)));
}

void
r1_earleme_complete_result (slr)
     Scanless_R *slr;
PPCODE:
{
  XPUSHs (sv_2mortal (newSViv ((IV) slr->r1_earleme_complete_result)));
}

void
stub_alternative( slr, lexeme, attempted )
    Scanless_R *slr;
     Marpa_Symbol_ID lexeme;
     IV attempted;
PPCODE:
{
  IV return_value;
  return_value = slr_stub_alternative(slr, lexeme, attempted);
  XSRETURN_IV(return_value);
}

void
stub_alternatives( slr )
    Scanless_R *slr;
PPCODE:
{
  IV lexemes_found;
  IV lexemes_attempted;
  IV return_value = slr_stub_alternatives(slr, &lexemes_found, &lexemes_attempted);
  XPUSHs (sv_2mortal (newSViv ((IV) return_value)));
  XPUSHs (sv_2mortal (newSViv ((IV) lexemes_found)));
  XPUSHs (sv_2mortal (newSViv ((IV) lexemes_attempted)));
}

void
event(slr)
    Scanless_R *slr;
PPCODE:
{
    SV* event = av_shift(slr->event_queue);
    XPUSHs (sv_2mortal (event));
}

void
locations(slr, earley_set)
    Scanless_R *slr;
    IV earley_set;
PPCODE:
{
  int result = 0;
  int start_position;
  int end_position;
  slr_locations(slr, earley_set, &start_position, &end_position);
  XPUSHs (sv_2mortal (newSViv ((IV) start_position)));
  XPUSHs (sv_2mortal (newSViv ((IV) end_position)));
}

void
lexeme_locations (slr)
     Scanless_R *slr;
PPCODE:
{
  STRLEN end_of_lexeme = slr->end_of_lexeme;
  XPUSHs (sv_2mortal (newSViv ((IV) slr->start_of_lexeme)));
  XPUSHs (sv_2mortal (newSViv ((IV)end_of_lexeme)));
}

  # Eliminate after converstion?
void
lexeme_locations_set (slr, start, end)
     Scanless_R *slr;
     STRLEN start;
     STRLEN end;
PPCODE:
{
  Unicode_Stream *stream = slr->stream;
  STRLEN input_length = SvCUR (stream->input);
  if (end < start)
    {
      croak
	("Problem in slr->lexeme_locations_set(): start (%lu) is after the end (%lu)",
	 (unsigned long) start, (unsigned long) end);
    }
  if (start > input_length)
    {
      croak
	("Problem in slr->lexeme_locations_set(): new pos = %lu, but start = %lu",
	 (unsigned long) input_length, (unsigned long) start);
    }
  if (end > input_length)
    {
      croak
	("Problem in slr->lexeme_locations_set(): new pos = %lu, but end = %lu",
	 (unsigned long) input_length, (unsigned long) end);
    }
  slr->start_of_lexeme = start;
  slr->end_of_lexeme = end;
  XSRETURN_YES;
}

INCLUDE: general_pattern.xsh

BOOT:
    marpa_debug_handler_set(marpa_r2_warn);
