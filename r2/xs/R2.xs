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

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "config.h"
#include "marpa.h"

typedef SV* SVREF;

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
     G_Wrapper* base;
     unsigned int ruby_slippers:1;
} R_Wrapper;

typedef struct {
     R_Wrapper* r_wrapper;
     G_Wrapper* base;
     SV* r_sv;
     STRLEN character_ix; /* character position, taking into account Unicode */
     STRLEN input_offset; /* byte position, ignoring Unicode */
     SV* input;
     int input_debug; /* debug level for input */
     Marpa_Symbol_ID input_symbol_id;
     UV codepoint; /* For error returns */
     UV** oplists_by_byte;
     HV* per_codepoint_ops;
     IV ignore_rejection;

     /* The minimum number of tokens that must
       be accepted at an earleme */
     IV minimum_accepted;
     IV trace; /* trace level */
} Unicode_Stream;

typedef struct marpa_b Bocage;
typedef struct {
     Marpa_Bocage b;
     G_Wrapper* base;
} B_Wrapper;

typedef struct marpa_o Order;
typedef struct {
     Marpa_Order o;
     G_Wrapper* base;
} O_Wrapper;

typedef struct marpa_t Tree;
typedef struct {
     Marpa_Tree t;
     G_Wrapper* base;
} T_Wrapper;

typedef struct marpa_v Value;
typedef struct {
     Marpa_Value v;
     G_Wrapper* base;
} V_Wrapper;

static const char grammar_c_class_name[] = "Marpa::R2::Thin::G";
static const char recce_c_class_name[] = "Marpa::R2::Thin::R";
static const char bocage_c_class_name[] = "Marpa::R2::Thin::B";
static const char unicode_stream_class_name[] = "Marpa::R2::Thin::U";
static const char order_c_class_name[] = "Marpa::R2::Thin::O";
static const char tree_c_class_name[] = "Marpa::R2::Thin::T";
static const char value_c_class_name[] = "Marpa::R2::Thin::V";

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

enum marpa_recce_op {
   op_noop,
   op_ignore_rejection,
   op_report_rejection,
   op_alternative,
   op_earleme_complete,
   op_unregistered,
};

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

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Thin::G

void
new( ... )
PPCODE:
{
  Marpa_Grammar g;
  G_Wrapper *g_wrapper;
  int throw = 1;
  int interface = 0;
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
PREINIT:
    Marpa_Grammar grammar;
CODE:
    if (g_wrapper->message_buffer)
	Safefree(g_wrapper->message_buffer);
    grammar = g_wrapper->g;
    marpa_g_unref( grammar );
    Safefree( g_wrapper );


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
	        rhs[i] = SvIV(*elem);
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
	      int raw_min = SvIV (arg_value);
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
	      min = raw_min;
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
	      separator = SvIV (arg_value);
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
new( class, g_wrapper )
    char * class;
    G_Wrapper *g_wrapper;
PPCODE:
{
  int highest_symbol_id;
  Marpa_Grammar g = g_wrapper->g;
  SV *sv;
  R_Wrapper *r_wrapper;
  Marpa_Recce r;
  r = marpa_r_new (g);
  if (!r)
    {
      if (!g_wrapper->throw) { XSRETURN_UNDEF; }
      croak ("failure in marpa_r_new: %s", xs_g_error (g_wrapper));
    };
  highest_symbol_id = marpa_g_highest_symbol_id (g);
  if (highest_symbol_id < 0)
    {
      if (!g_wrapper->throw) { XSRETURN_UNDEF; }
      croak ("failure in marpa_g_highest_symbol_id: %s", xs_g_error (g_wrapper));
    };
  Newx (r_wrapper, 1, R_Wrapper);
  r_wrapper->r = r;
  Newx (r_wrapper->terminals_buffer, highest_symbol_id+1, Marpa_Symbol_ID);
  r_wrapper->ruby_slippers = 0;
  r_wrapper->base = g_wrapper;
  sv = sv_newmortal ();
  sv_setref_pv (sv, recce_c_class_name, (void *) r_wrapper);
  XPUSHs (sv);
}

void
DESTROY( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
    struct marpa_r *r = r_wrapper->r;
    Safefree(r_wrapper->terminals_buffer);
    marpa_r_unref( r );
    Safefree( r_wrapper );
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
new( class, r_sv )
    char * class;
    SV *r_sv;
PPCODE:
{
  if (!sv_isa (r_sv, "Marpa::R2::Thin::R"))
    {
      croak ("Problem in u->new(): arg is not of type Marpa::R2::Thin::R");
    }
  SvREFCNT_inc (r_sv);
  {
    IV tmp = SvIV ((SV *) SvRV (r_sv));
    R_Wrapper *r_wrapper = INT2PTR (R_Wrapper *, tmp);
    SV *u_sv = sv_newmortal ();
    Unicode_Stream *stream;
    Newx (stream, 1, Unicode_Stream);
    stream->trace = 0;
    stream->base = r_wrapper->base;
    stream->r_wrapper = r_wrapper;
    stream->r_sv = r_sv;
  stream->input = newSVpvn("", 0);
  stream->character_ix = 0;
  stream->input_offset = 0;
  stream->input_debug = 0;
  stream->input_symbol_id = -1;
  stream->per_codepoint_ops = newHV();
  {
    const int number_of_bytes = 0x100;
    int codepoint;
    UV **oplists;
    Newx(oplists, number_of_bytes, UV*);
    stream->oplists_by_byte = oplists;
    for (codepoint = 0; codepoint < number_of_bytes; codepoint++) {
        oplists[codepoint] = (UV*)NULL;
    }
  }
  stream->ignore_rejection = 1;
  stream->minimum_accepted = 1;
    sv_setref_pv (u_sv, unicode_stream_class_name, (void *) stream);
    XPUSHs (u_sv);
  }
}

void
recce_set( stream, new_r_sv )
    Unicode_Stream *stream;
    SV *new_r_sv;
PPCODE:
{
  if (!sv_isa (new_r_sv, "Marpa::R2::Thin::R"))
    {
      croak ("Problem in u->recce_set(): arg is not of type Marpa::R2::Thin::R");
    }
  SvREFCNT_inc (new_r_sv);
  {
    IV tmp = SvIV ((SV *) SvRV (new_r_sv));
    R_Wrapper *new_r_wrapper = INT2PTR (R_Wrapper *, tmp);
    stream->base = new_r_wrapper->base;
    stream->r_wrapper = new_r_wrapper;
    SvREFCNT_dec(stream->r_sv);
    stream->r_sv = new_r_sv;
  }
}


void
DESTROY( stream )
    Unicode_Stream *stream;
PPCODE:
{
    const SV* r_sv = stream->r_sv;
    UV **oplists = stream->oplists_by_byte;
    if (oplists) {
      const int number_of_bytes = 0x100;
      int codepoint;
      for (codepoint = 0; codepoint < number_of_bytes; codepoint++) {
	  Safefree(oplists[codepoint]);
      }
      Safefree(stream->oplists_by_byte);
    }
    SvREFCNT_dec(stream->input);
    SvREFCNT_dec(stream->per_codepoint_ops);
    SvREFCNT_dec(r_sv);
    Safefree( stream );
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
  XSRETURN_UNDEF;
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
     unsigned long codepoint;
PPCODE:
{
  /* OP Count is args less two, then plus two for codepoint and length fields */
  const STRLEN op_count = items;
  if (codepoint > 0xFF)
    {
      croak
	("Problem in r->char_register(0x%lx): More than 8bit codepoint not yet implemented",
	 codepoint);
    }
  {
    STRLEN op_ix;
    UV **const ops_by_byte = stream->oplists_by_byte;
    UV *ops = ops_by_byte[codepoint];
    Renew (ops, op_count, UV);
    stream->oplists_by_byte[codepoint] = ops;
    ops[0] = codepoint;
    ops[1] = op_count;
    for (op_ix = 2; op_ix < op_count; op_ix++)
      {
	/* By coincidence, offset of individual ops is 2 both in the
	 * method arguments and in the op_list, so that arg IX == op_ix
	 */
	ops[op_ix] = SvUV (ST (op_ix));
      }
  }
}

void
string_set( stream, string )
     Unicode_Stream *stream;
     SVREF string;
PPCODE:
{
  stream->character_ix = 0;
  stream->input_offset = 0;
  sv_setsv (stream->input, string);
  SvPV_nolen (stream->input);
}

void
pos( stream )
     Unicode_Stream *stream;
PPCODE:
{
  XSRETURN_IV(stream->character_ix);
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
  /* *SAFELY* change the position
   * This requires care in UTF8
   * Returns the position *BEFORE* the call
   */
  int input_is_utf8 = SvUTF8 (stream->input);
  STRLEN len;
  const STRLEN old_pos = stream->character_ix;
  char *input;
  if (input_is_utf8)
    {
      croak ("Problem in stream->pos_set(): UTF8 not yet implemented");
    }
  input = SvPV (stream->input, len);
  /* STRLEN is assumed to be unsigned so no check for less than zero */
  if (new_pos >= len)
    {
      croak ("Problem in stream->pos_set(): new pos = %ld, but length = %ld",
	     (long) new_pos, (long) len);
    }
  stream->input_offset = new_pos;
  stream->character_ix = new_pos;
  XSRETURN_IV (old_pos);
}

 # Return values:
 # 1 or greater: an event count, as returned by earleme complete.
 # 0: success: a full reading of the input, with nothing to report.
 # -1: a character was rejected, when rejection is not being ignored
 # -2: an unregistered character was found
 # -3: earleme_complete() reported an exhausted parse.
 #
void
read( stream )
     Unicode_Stream *stream;
PPCODE:
{
  const int trace_level = stream->trace;
  const R_Wrapper* r_wrapper = stream->r_wrapper;
  const Marpa_Recognizer r = r_wrapper->r;
  char *input;
  int input_is_utf8;
  int input_debug = stream->input_debug;
  STRLEN len;
  input_is_utf8 = SvUTF8 (stream->input);
  input = SvPV (stream->input, len);
  for (;;)
    {
      int return_value = 0;
      UV codepoint;
      STRLEN op_ix;
      STRLEN op_count;
      UV *ops;
      int ignore_rejection = stream->ignore_rejection;
      int minimum_accepted = stream->minimum_accepted;
      int tokens_accepted = 0;
      if (stream->input_offset >= len)
	break;
      if (input_is_utf8)
	{
	  croak ("Problem in r->read_string(): UTF8 not yet implemented");
	}
      else
	{
	  codepoint = (UV) input[stream->input_offset];
	  if (codepoint > 0xFF)
	    {
	      croak
		("Problem in r->string_read(0x%lx): More than 8bit codepoints not yet implemented",
		 codepoint);
	    }
	}
      if (trace_level >= 10) {
          warn("Thin::U::read() Reading codepoint 0x%04x at pos %d",
	    (int)codepoint, (int)stream->character_ix);
      }
      ops = stream->oplists_by_byte[codepoint];
      if (!ops)
	{
	  stream->codepoint = codepoint;
	  XSRETURN_IV (-2);
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
		result = marpa_r_alternative (r, symbol_id, value, length);
		switch (result)
		  {
		  case MARPA_ERR_UNEXPECTED_TOKEN_ID:
		    if (input_debug > 0) {
		       warn("input_read_string unexpected token: %d,%d,%d",
			 symbol_id, value, length);
		    }
		    # This guarantees that later, if we fall below
		    # the minimum number of tokens accepted,
		    # we have one of them as an example
		    stream->input_symbol_id = symbol_id;
		    if (trace_level >= 10) {
			warn("Thin::U::read() Rejected codepoint 0x%04x at pos %d as symbol %d",
			  (int)codepoint, (int)stream->character_ix, symbol_id);
		    }
		    if (!ignore_rejection)
		      {
			stream->codepoint = codepoint;
			XSRETURN_IV (-1);
		      }
		    break;
		  case MARPA_ERR_NONE:
		    if (trace_level >= 10) {
			warn("Thin::U::read() Accepted codepoint 0x%04x at pos %d as symbol %d",
			  (int)codepoint, (int)stream->character_ix, symbol_id);
		    }
		    tokens_accepted++;
		    break;
		  default:
		    stream->codepoint = codepoint;
		    stream->input_symbol_id = symbol_id;
		    croak
		      ("Problem alternative() failed at char ix %d; symbol id %d; codepoint 0x%lx\n"
		       "Problem in r->input_string_read(), alternative() failed: %s",
		       (int)stream->character_ix, symbol_id, codepoint,
		       xs_g_error (stream->base));
		  }
	      }
	      break;
	    case op_earleme_complete:
	      {
		int result;
		if (tokens_accepted < minimum_accepted) {
		    stream->codepoint = codepoint;
		    XSRETURN_IV (-1);
		}
		marpa_r_latest_earley_set_value_set (r, codepoint);
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
		      marpa_g_error (stream->base->g, NULL);
		    if (error == MARPA_ERR_PARSE_EXHAUSTED)
		      {
			XSRETURN_IV (-3);
		      }
		  }
		if (result < 0)
		  {
		    croak
		      ("Problem in r->input_string_read(), earleme_complete() failed: %s",
		       xs_g_error (stream->base));
		  }
	      }
	      break;
	    case op_unregistered:
	      croak ("Unregistered codepoint (0x%lx)",
		     (unsigned long) codepoint);
	    default:
	      croak ("Unknown op code (0x%lx); codepoint=0x%lx, op_ix=0x%lx",
		     (unsigned long) op_code, (unsigned long) codepoint,
		     (unsigned long) op_ix);
	    }
	}
    ADVANCE_ONE_CHAR:;
      if (input_is_utf8)
	{
	  croak ("Problem in r->read_string(): UTF8 not yet implemented");
	}
      else
	{
	  stream->input_offset++;
	}
      stream->character_ix++;
      /* This logic does not allow a return value of 0,
       * which is reserved for a indicating a full
       * read of the input string without event
       */
      if (return_value)
	{
	  XSRETURN_IV (return_value);
	}
    }
  XSRETURN_IV(0);
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
      if (!t_wrapper->base->throw) { XSRETURN_UNDEF; }
      croak ("Problem in v->new(): %s", xs_g_error(t_wrapper->base));
    }
  Newx (v_wrapper, 1, V_Wrapper);
  v_wrapper->base = t_wrapper->base;
  v_wrapper->v = v;
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
    marpa_v_unref(v);
    Safefree( v_wrapper );
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
  SV *sv;
  const Marpa_Step_Type status = marpa_v_step (v);

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
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_n (v))));
    }
  if (status == MARPA_STEP_NULLING_SYMBOL)
    {
      token_id = marpa_v_token (v);
      XPUSHs (sv_2mortal (newSViv (token_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_n (v))));
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

INCLUDE: general_pattern.xsh

BOOT:
    marpa_debug_handler_set(marpa_r2_warn);
