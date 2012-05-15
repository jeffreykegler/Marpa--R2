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

typedef struct marpa_g Grammar;
typedef struct {
     Marpa_Grammar g;
     char *message_buffer;
} G_Wrapper;

typedef struct marpa_r Recce;
typedef struct {
     Marpa_Recce r;
     char *message_buffer;
     Marpa_Symbol_ID* terminals_buffer;
} R_Wrapper;

typedef struct marpa_b Bocage;
typedef struct {
     Marpa_Bocage b;
     char *message_buffer;
} B_Wrapper;

typedef struct marpa_o Order;
typedef struct {
     Marpa_Order o;
     char *message_buffer;
} O_Wrapper;

typedef struct marpa_t Tree;
typedef struct {
     Marpa_Tree t;
     char *message_buffer;
} T_Wrapper;

typedef struct marpa_v Value;
typedef struct {
     Marpa_Value v;
     char *message_buffer;
} V_Wrapper;

static const char grammar_c_class_name[] = "Marpa::R2::Internal::G_C";
static const char recce_c_class_name[] = "Marpa::R2::Internal::R_C";
static const char bocage_c_class_name[] = "Marpa::R2::Internal::B_C";
static const char order_c_class_name[] = "Marpa::R2::Internal::O_C";
static const char tree_c_class_name[] = "Marpa::R2::Internal::T_C";
static const char value_c_class_name[] = "Marpa::R2::Internal::V_C";

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
value_type_to_string (Marpa_Value_Type value_type)
{
  const char *value_type_name = NULL;
  if (value_type >= 0 && value_type < MARPA_ERROR_COUNT) {
      value_type_name = marpa_value_type_description[value_type].name;
  }
  return value_type_name;
}

/* This routine is for the handling exceptions
   from libmarpa.  It is used when in the general
   cases, for those exception which are not singled
   out for special handling by the XS logic.
   It returns a buffer which must be Safefree()'d.
*/
static char *
libmarpa_exception (int error_code, const char *error_string)
{
  dTHX;
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
    case MARPA_ERR_UNKNOWN:
      output_string = form ("Unknown error (%s)",
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
      return savepv(output_string);
}

/* Return value must be Safefree()'d */
static const char *
xs_g_error (G_Wrapper * g_wrapper)
{
  const char *error_string;
  Marpa_Grammar g = g_wrapper->g;
  const int error_code = marpa_g_error (g, &error_string);
  char *buffer = g_wrapper->message_buffer;
  if (buffer) Safefree(buffer);
  g_wrapper->message_buffer = buffer =
    libmarpa_exception (error_code, error_string);
  return buffer;
}

/* Return value must be Safefree()'d */
static const char *
xs_r_error (R_Wrapper * r_wrapper)
{
  const char *error_string;
  struct marpa_r *r = r_wrapper->r;
  const int error_code = marpa_r_error (r, &error_string);
  char *buffer = r_wrapper->message_buffer;
  if (buffer) Safefree(buffer);
  r_wrapper->message_buffer = buffer =
    libmarpa_exception (error_code, error_string);
  return buffer;
}

/* Return value must be Safefree()'d */
static const char *
xs_b_error (B_Wrapper * b_wrapper)
{
  const char *error_string;
  Marpa_Bocage b = b_wrapper->b;
  Marpa_Grammar g = marpa_b_g(b);
  const int error_code = marpa_g_error (g, &error_string);
  char *buffer = b_wrapper->message_buffer;
  if (buffer) Safefree(buffer);
  b_wrapper->message_buffer = buffer =
    libmarpa_exception (error_code, error_string);
  return buffer;
}

/* Return value must be Safefree()'d */
static const char *
xs_o_error (O_Wrapper * o_wrapper)
{
  const char *error_string;
  Marpa_Order o = o_wrapper->o;
  Marpa_Grammar g = marpa_o_g(o);
  const int error_code = marpa_g_error (g, &error_string);
  char *buffer = o_wrapper->message_buffer;
  if (buffer) Safefree(buffer);
  o_wrapper->message_buffer = buffer =
    libmarpa_exception (error_code, error_string);
  return buffer;
}

/* Return value must be Safefree()'d */
static const char *
xs_t_error (T_Wrapper * t_wrapper)
{
  const char *error_string;
  Marpa_Tree t = t_wrapper->t;
  Marpa_Grammar g = marpa_t_g(t);
  const int error_code = marpa_g_error (g, &error_string);
  char *buffer = t_wrapper->message_buffer;
  if (buffer) Safefree(buffer);
  t_wrapper->message_buffer = buffer =
    libmarpa_exception (error_code, error_string);
  return buffer;
}

/* Return value must be Safefree()'d */
static const char *
xs_v_error (V_Wrapper * v_wrapper)
{
  const char *error_string;
  Marpa_Value v = v_wrapper->v;
  Marpa_Grammar g = marpa_v_g(v);
  const int error_code = marpa_g_error (g, &error_string);
  char *buffer = v_wrapper->message_buffer;
  if (buffer) Safefree(buffer);
  v_wrapper->message_buffer = buffer =
    libmarpa_exception (error_code, error_string);
  return buffer;
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

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal

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

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal::G_C

G_Wrapper *
new( class, non_c_sv )
    char * class;
PPCODE:
{
    Marpa_Grammar g;
    SV *sv;
    G_Wrapper *g_wrapper;
    Marpa_Error_Code version_error =
	marpa_check_version(MARPA_MAJOR_VERSION, MARPA_MINOR_VERSION, MARPA_MICRO_VERSION);
    if (version_error != MARPA_ERR_NONE)
      {
	const char *error_description = "Error code out of bounds";
	if (version_error >= 0 && version_error < MARPA_ERROR_COUNT)
	  {
	    error_description = marpa_error_description[version_error].name;
	  }
	croak ("Problem in Marpa::R2->new(): %s", error_description);
      }
    g = marpa_g_new( MARPA_MAJOR_VERSION, MARPA_MINOR_VERSION, MARPA_MICRO_VERSION);
    Newx( g_wrapper, 1, G_Wrapper );
    g_wrapper->g = g;
    g_wrapper->message_buffer = NULL;
    sv = sv_newmortal();
    sv_setref_pv(sv, grammar_c_class_name, (void*)g_wrapper);
    XPUSHs(sv);
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
start_symbol_set( g_wrapper, id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_start_symbol_set (g, id);
  if (result < 0)
    {
      croak ("Problem in g->start_symbol_set(): %s", xs_g_error (g_wrapper));
    }
  XSRETURN_YES;
}

void
start_symbol( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  Marpa_Symbol_ID id = marpa_g_start_symbol (g);
  if (id <= -2)
    {
      croak ("Problem in g->start_symbol(): %s", xs_g_error (g_wrapper));
    }
  if (id < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (id)));
}

void
is_precomputed( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_is_precomputed (g);
  if (result < 0)
    {
      croak ("Problem in g->is_precomputed(): %s",
	     xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
event( g_wrapper, ix )
    G_Wrapper *g_wrapper;
    int ix;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  struct marpa_event event;
  const char *result_string = NULL;
  Marpa_Event_Type result = marpa_g_event (g, &event, ix);
  if (result == -1)
  {
      XSRETURN_UNDEF;
  }
  if (result < 0)
    {
      croak ("Problem in g->event(): %s", xs_g_error (g_wrapper));
    }
  result_string = event_type_to_string (result);
  if (!result_string)
    {
      croak ("Problem in g->event(): unknown event %d", result);
    }
  XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
  XPUSHs (sv_2mortal (newSViv (event.t_value)));
}

void
has_cycle( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_has_cycle (g);
  if (result < 0)
    {
      croak ("Problem in g->has_cycle(): %s", xs_g_error (g_wrapper));
    }
  if (result) XSRETURN_YES;
  XSRETURN_NO;
}

Marpa_Symbol_ID
symbol_new( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_symbol_new (g);
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
symbol_is_accessible( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_symbol_is_accessible (g, symbol_id);
  if (result < 0)
    {
      croak ("Problem in g->symbol_is_accessible(): %s", xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

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
symbol_is_counted( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_symbol_is_counted (g, symbol_id);
  if (result < 0)
    {
      croak ("Problem in g->symbol_is_counted(): %s", xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
symbol_is_nulling( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_symbol_is_nulling (g, symbol_id);
  if (result < 0)
    {
      croak ("Problem in g->symbol_is_nulling(%d): %s", symbol_id,
	     xs_g_error (g_wrapper));
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
symbol_is_nullable( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_symbol_is_nullable (g, symbol_id);
  if (result < 0)
    {
      croak ("Problem in g->symbol_is_nullable(%d): %s", symbol_id,
	     xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
symbol_is_terminal_set( g_wrapper, symbol_id, boolean )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
    int boolean;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result =
    marpa_g_symbol_is_terminal_set (g, symbol_id, (boolean ? TRUE : FALSE));
  if (result < 0)
    {
      croak ("Problem in g->symbol_is_terminal_set(%d, %d): %s",
	     symbol_id, boolean, xs_g_error (g_wrapper));
    }
}

void
symbol_is_terminal( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_symbol_is_terminal (g, symbol_id);
  if (result < 0)
    {
      croak ("Problem in g->symbol_is_terminal(%d): %s",
	     symbol_id, xs_g_error (g_wrapper));
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
symbol_is_productive( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_symbol_is_productive (g, symbol_id);
  if (result < 0)
    {
      croak ("Invalid symbol %d", symbol_id);
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
marpa_g_symbol_is_start( g_wrapper, symbol_id )
    G_Wrapper *g_wrapper;
    Marpa_Symbol_ID symbol_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_symbol_is_start (g, symbol_id);
  if (result < 0)
    {
      croak ("Invalid symbol %d", symbol_id);
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

 # Rules

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
    if (new_rule_id < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(new_rule_id) ) );
}

 # This function invalidates any current iteration on
 # the hash args.  This seesm to be the way things are
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
    if (args) {
	I32 retlen;
	char* key;
	SV* arg_value;
	hv_iterinit(args);
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
		    croak ("sequence_new(): min cannot be less than 0");
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
    croak ("unknown argument to sequence_new(): %.*s", (int)retlen, key);
  }
    }
    new_rule_id = marpa_g_sequence_new(g, lhs, rhs, separator, min, flags );
    if (new_rule_id < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(new_rule_id) ) );
}

Marpa_Symbol_ID
rule_lhs( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = marpa_g_rule_lhs(g, rule_id);
    if (result < -1) { 
      croak ("Problem in g->rule_lhs(%d): %s", rule_id, xs_g_error (g_wrapper));
      }
    if (result < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(result) ) );
}

Marpa_Symbol_ID
rule_rhs( g_wrapper, rule_id, ix )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
    int ix;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = marpa_g_rule_rh_symbol(g, rule_id, ix);
    if (result < -1) { 
      croak ("Problem in g->rule_rhs(%d, %d): %s", rule_id, ix, xs_g_error (g_wrapper));
      }
    if (result < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(result) ) );
}

int
rule_length( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_rule_length (g, rule_id);
  if (result < -1)
    {
      croak ("Problem in g->rule_length(%d): %s", rule_id,
	     xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
rule_is_accessible( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_rule_is_accessible (g, rule_id);
  if (result < -1)
    {
      croak ("Problem in g->rule_is_accessible(%d): %s", rule_id,
	     xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      croak ("Invalid rule %d", rule_id);
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
rule_is_productive( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_rule_is_productive (g, rule_id);
  if (result < -1)
    {
      croak ("Problem in g->rule_is_productive(%d): %s", rule_id,
	     xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      croak ("Invalid rule %d", rule_id);
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
rule_is_loop( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_rule_is_loop (g, rule_id);
  if (result < -1)
    {
      croak ("Problem in g->rule_is_loop(%d): %s", rule_id,
	     xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      croak ("Invalid rule %d", rule_id);
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
rule_is_sequence( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_rule_is_sequence (g, rule_id);
  if (result < -1)
    {
      croak ("Problem in g->rule_is_sequence(%d): %s", rule_id,
	     xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      croak ("Invalid rule %d", rule_id);
    }
  if (result)
    XSRETURN_YES;
  XSRETURN_NO;
}

Marpa_Symbol_ID
_marpa_g_irl_lhs( g_wrapper, irl_id )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_irl_lhs(g, irl_id);
    if (result < -1) { 
      croak ("Problem in g->_marpa_g_irl_lhs(%d): %s", irl_id, xs_g_error (g_wrapper));
      }
    if (result < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(result) ) );
}

Marpa_Symbol_ID
_marpa_g_irl_rhs( g_wrapper, irl_id, ix )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
    int ix;
PPCODE:
{
    Marpa_Grammar g = g_wrapper->g;
    int result = _marpa_g_irl_rh_symbol(g, irl_id, ix);
    if (result < -1) { 
      croak ("Problem in g->_marpa_g_irl_rhs(%d, %d): %s", irl_id, ix, xs_g_error (g_wrapper));
      }
    if (result < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(result) ) );
}

int
_marpa_g_irl_length( g_wrapper, irl_id )
    G_Wrapper *g_wrapper;
    Marpa_IRL_ID irl_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_irl_length (g, irl_id);
  if (result < -1)
    {
      croak ("Problem in g->_marpa_g_irl_length(%d): %s", irl_id,
	     xs_g_error (g_wrapper));
    }
  if (result < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
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
rule_is_keep_separation( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_rule_is_keep_separation (g, rule_id);
  if (result < 0)
    {
      croak ("Problem in g->rule_is_keep_separation(%d): %s", rule_id,
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

void
rule_ask_me_set( g_wrapper, rule_id )
    G_Wrapper *g_wrapper;
    Marpa_Rule_ID rule_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_rule_ask_me_set (g, rule_id);
  if (result <= -2)
    {
      croak ("Problem in g->rule_ask_me_set(%d): %s", rule_id,
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

Marpa_Symbol_ID
_marpa_g_isy_buddy( g_wrapper, isy_id )
    G_Wrapper *g_wrapper;
    Marpa_ISY_ID isy_id;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = _marpa_g_isy_buddy (g, isy_id);
  if (result <= -2)
    {
      croak ("Problem in g->_marpa_g_isy_buddy(%d): %s", isy_id,
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
rule_count( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_rule_count (g);
  if (result < -1)
    {
      croak ("Problem in g->rule_count(): %s", xs_g_error (g_wrapper));
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

int
symbol_count( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  int count = marpa_g_symbol_count (g);
  if (count < -1)
    {
      croak ("Problem in g->symbol_count(): %s", xs_g_error (g_wrapper));
    }
  if (count < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (count)));
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
  const int symbol_count = marpa_g_symbol_count(g);
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

void
error( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  Marpa_Grammar g = g_wrapper->g;
  XPUSHs (sv_2mortal (newSVpv (xs_g_error (g_wrapper), 0)));
}

void
error_code( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  const Marpa_Grammar g = g_wrapper->g;
  const Marpa_Error_Code error_code = marpa_g_error (g, NULL);
  if (error_code < 0) {
	  XSRETURN_UNDEF;
  }
  XPUSHs (sv_2mortal (newSViv (error_code)));
}

void precompute( g_wrapper )
    G_Wrapper *g_wrapper;
PPCODE:
{
  const Marpa_Grammar g = g_wrapper->g;
  int result = marpa_g_precompute (g);
  if (result < 0)
    {
      XSRETURN_UNDEF;
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal::R_C

void
new( class, g_wrapper )
    char * class;
    G_Wrapper *g_wrapper;
PPCODE:
{
    int symbol_count;
    Marpa_Grammar g = g_wrapper->g;
    SV *sv;
    R_Wrapper *r_wrapper;
    Marpa_Recce r;
    r = marpa_r_new(g);
    if (!r) { croak ("failure in marpa_r_new: %s", xs_g_error (g_wrapper)); };
    symbol_count = marpa_g_symbol_count(g);
    Newx( r_wrapper, 1, R_Wrapper );
    r_wrapper->r = r;
    Newx( r_wrapper->terminals_buffer, symbol_count, Marpa_Symbol_ID );
    r_wrapper->message_buffer = NULL;
    sv = sv_newmortal();
    sv_setref_pv(sv, recce_c_class_name, (void*)r_wrapper);
    XPUSHs(sv);
}

void
DESTROY( r_wrapper )
    R_Wrapper *r_wrapper;
PREINIT:
    struct marpa_r *r;
CODE:
    r = r_wrapper->r;
    if (r_wrapper->message_buffer)
	Safefree(r_wrapper->message_buffer);
    Safefree(r_wrapper->terminals_buffer);
    marpa_r_unref( r );
    Safefree( r_wrapper );

void
error( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  XPUSHs (sv_2mortal (newSVpv (xs_r_error (r_wrapper), 0)));
}

void
error_code( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  const Marpa_Error_Code error_code = marpa_r_error (r, NULL);
  if (error_code < 0) {
	  XSRETURN_UNDEF;
  }
  XPUSHs (sv_2mortal (newSViv (error_code)));
}

Marpa_Earleme
current_earleme( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = marpa_r_current_earleme(r_wrapper->r);
OUTPUT:
    RETVAL

Marpa_Earleme
furthest_earleme( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = marpa_r_furthest_earleme(r_wrapper->r);
OUTPUT:
    RETVAL

void
is_use_leo_set( r_wrapper, boolean )
    R_Wrapper *r_wrapper;
    int boolean;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int result = marpa_r_is_use_leo_set (r, (boolean ? TRUE : FALSE));
  if (result < 0)
    {
      croak ("Problem in is_use_leo_set(): %s", xs_r_error (r_wrapper));
    }
  XSRETURN_YES;
}

void
is_use_leo( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int boolean = marpa_r_is_use_leo (r);
  if (boolean < 0)
    {
      croak ("Problem in is_use_leo(): %s", xs_r_error (r_wrapper));
    }
  if (boolean)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
is_exhausted( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int boolean = marpa_r_is_exhausted (r);
  if (boolean < 0)
    {
      croak ("Problem in is_exhausted(): %s", xs_r_error (r_wrapper));
    }
  if (boolean)
    XSRETURN_YES;
  XSRETURN_NO;
}

void
start_input( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
    int result = marpa_r_start_input(r_wrapper->r);
  if (result < 0)
    {
      croak ("Problem in r->start_input(): %s", xs_r_error (r_wrapper));
    }
    XSRETURN_YES;
}

 # current earleme on success -- return that directly
 # -1 means rejected because unexpected -- return undef
 # -3 means rejected as duplicate -- call croak
 # -2 means some other failure -- call croak
void
alternative( r_wrapper, symbol_id, value, length )
    R_Wrapper *r_wrapper;
    Marpa_Symbol_ID symbol_id;
    int value;
    int length;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int result;
      result =
	marpa_r_alternative (r, symbol_id, value, length);
      if (result == -1)
	{
	  XSRETURN_UNDEF;
	}
      if (result == -3)
	{
	  croak ("r->alternative(): Attempt to read same symbol twice at same location");
	  }
      if (result < 0)
	{
	  croak ("Invalid alternative: %s", xs_r_error (r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (result)));
    }

void
earley_item_warning_threshold_set( r_wrapper, too_many_earley_items )
    R_Wrapper *r_wrapper;
    int too_many_earley_items;
PPCODE:
{
  int result =
    marpa_r_earley_item_warning_threshold_set (r_wrapper->r,
					       too_many_earley_items);
      if (result < 0)
	{
	  croak ("Problem in r->earley_item_warning_threshold: %s", xs_r_error (r_wrapper));
	}
    XSRETURN_YES;
}

void
too_many_earley_items( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  int too_many_earley_items =
    marpa_r_earley_item_warning_threshold (r_wrapper->r);
  XPUSHs (sv_2mortal (newSViv (too_many_earley_items)));
}

void
latest_earley_set( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int latest_earley_set = marpa_r_latest_earley_set(r);
      if (latest_earley_set < 0)
	{
      croak ("Problem with r->latest_earley_set(): %s",
		 xs_r_error(r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (latest_earley_set)));
    }

void
earley_set_size( r_wrapper, set_ordinal )
    R_Wrapper *r_wrapper;
    Marpa_Earley_Set_ID set_ordinal;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int earley_set_size = marpa_r_earley_set_size (r, set_ordinal);
      if (earley_set_size < 0) {
	  croak ("Problem in r->earley_set_size(): %s", xs_r_error(r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (earley_set_size)));
    }

void
earley_set_trace( r_wrapper, set_ordinal )
    R_Wrapper *r_wrapper;
    Marpa_Earley_Set_ID set_ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    Marpa_AHFA_State_ID result = marpa_r_earley_set_trace(
	r, set_ordinal );
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) { croak("problem with r->earley_set_trace: %s", xs_r_error(r_wrapper)); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
earley_item_trace( r_wrapper, item_ordinal )
    R_Wrapper *r_wrapper;
    Marpa_Earley_Item_ID item_ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    Marpa_AHFA_State_ID result = marpa_r_earley_item_trace(
	r, item_ordinal);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) { croak("problem with r->earley_item_trace: %s", xs_r_error(r_wrapper)); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
earley_item_origin( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int origin_earleme = marpa_r_earley_item_origin (r);
      if (origin_earleme < 0)
	{
      croak ("Problem with r->earley_item_origin(): %s",
		 xs_r_error(r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (origin_earleme)));
    }

void
first_token_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int token_id = marpa_r_first_token_link_trace(r);
    if (token_id <= -2) { croak("Trace first token link problem: %s", xs_r_error(r_wrapper)); }
    if (token_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(token_id) ) );
    }

void
next_token_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int token_id = marpa_r_next_token_link_trace(r);
    if (token_id <= -2) { croak("Trace next token link problem: %s", xs_r_error(r_wrapper)); }
    if (token_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(token_id) ) );
    }

void
first_completion_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int AHFA_state_id = marpa_r_first_completion_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace first completion link problem: %s", xs_r_error(r_wrapper)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
next_completion_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int AHFA_state_id = marpa_r_next_completion_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace next completion link problem: %s", xs_r_error(r_wrapper)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
first_leo_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int AHFA_state_id = marpa_r_first_leo_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace first completion link problem: %s", xs_r_error(r_wrapper)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
next_leo_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int AHFA_state_id = marpa_r_next_leo_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace next completion link problem: %s", xs_r_error(r_wrapper)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
source_predecessor_state( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int state_id = marpa_r_source_predecessor_state(r);
    if (state_id <= -2) { croak("Problem finding trace source predecessor state: %s", xs_r_error(r_wrapper)); }
    if (state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(state_id) ) );
    }

void
source_leo_transition_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int symbol_id = marpa_r_source_leo_transition_symbol(r);
    if (symbol_id <= -2) { croak("Problem finding trace source leo transition symbol: %s", xs_r_error(r_wrapper)); }
    if (symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(symbol_id) ) );
    }

void
source_token( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int value;
    int symbol_id = marpa_r_source_token(r, &value);
    if (symbol_id == -1) { XSRETURN_UNDEF; }
    if (symbol_id < 0) { croak("Problem with r->source_token(): %s", xs_r_error(r_wrapper)); }
	XPUSHs( sv_2mortal( newSViv(symbol_id) ) );
	XPUSHs( sv_2mortal( newSViv(value) ) );
    }

void
source_middle( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int middle = marpa_r_source_middle(r);
    if (middle <= -2) { croak("Problem with r->source_middle(): %s", xs_r_error(r_wrapper)); }
    if (middle == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(middle) ) );
    }

void
first_postdot_item_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int postdot_symbol_id = marpa_r_first_postdot_item_trace(r);
    if (postdot_symbol_id <= -2) { croak("Trace first postdot item problem: %s", xs_r_error(r_wrapper)); }
    if (postdot_symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(postdot_symbol_id) ) );
    }

void
next_postdot_item_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int postdot_symbol_id = marpa_r_next_postdot_item_trace(r);
    if (postdot_symbol_id <= -2) { croak("Trace next postdot item problem: %s", xs_r_error(r_wrapper)); }
    if (postdot_symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(postdot_symbol_id) ) );
    }

void
postdot_symbol_trace( r_wrapper, symid )
    R_Wrapper *r_wrapper;
    Marpa_Symbol_ID symid;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int postdot_symbol_id = marpa_r_postdot_symbol_trace (r, symid);
  if (postdot_symbol_id == -1)
    {
      XSRETURN_UNDEF;
    }
  if (postdot_symbol_id <= 0)
    {
      croak ("Problem in r->postdot_symbol_trace: %s", xs_r_error (r_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (postdot_symbol_id)));
}

void
leo_base_state( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int leo_base_state = marpa_r_leo_base_state (r);
      if (leo_base_state == -1) { XSRETURN_UNDEF; }
      if (leo_base_state < 0) {
	  croak ("Problem in r->leo_base_state(): %s", xs_r_error(r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (leo_base_state)));
    }

void
leo_base_origin( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int leo_base_origin = marpa_r_leo_base_origin (r);
      if (leo_base_origin == -1) { XSRETURN_UNDEF; }
      if (leo_base_origin < 0) {
	  croak ("Problem in r->leo_base_origin(): %s", xs_r_error(r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (leo_base_origin)));
    }

void
leo_expansion_ahfa( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  int leo_expansion_ahfa = marpa_r_leo_expansion_ahfa (r);
  if (leo_expansion_ahfa == -1)
    {
      XSRETURN_UNDEF;
    }
  if (leo_expansion_ahfa < 0)
    {
      croak ("Problem in r->leo_expansion_ahfa(): %s", xs_r_error (r_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (leo_expansion_ahfa)));
}

void
trace_earley_set( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int trace_earley_set = marpa_r_trace_earley_set (r);
      if (trace_earley_set < 0) {
	  croak ("Problem in r->trace_earley_set(): %s", xs_r_error(r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (trace_earley_set)));
    }

void
postdot_item_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int postdot_item_symbol = marpa_r_postdot_item_symbol (r);
      if (postdot_item_symbol < 0) {
	  croak ("Problem in r->postdot_item_symbol(): %s", xs_r_error(r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (postdot_item_symbol)));
    }

void
leo_predecessor_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int leo_predecessor_symbol = marpa_r_leo_predecessor_symbol (r);
      if (leo_predecessor_symbol == -1) { XSRETURN_UNDEF; }
      if (leo_predecessor_symbol < 0) {
	  croak ("Problem in r->leo_predecessor_symbol(): %s", xs_r_error(r_wrapper));
	}
      XPUSHs (sv_2mortal (newSViv (leo_predecessor_symbol)));
    }

void
terminals_expected( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
        int count = marpa_r_terminals_expected(r, r_wrapper->terminals_buffer);
	if (count < 0) {
	  croak ("Problem in r->terminals_expected(): %s", xs_r_error(r_wrapper));
	}
	if (GIMME == G_ARRAY) {
	    int i;
	    EXTEND(SP, count);
	    for (i = 0; i < count; i++) {
		PUSHs (sv_2mortal (newSViv (r_wrapper->terminals_buffer[i])));
	    }
	} else {
	    XPUSHs( sv_2mortal( newSViv(count) ) );
	}
    }

void
earleme_complete( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
        Marpa_Earleme result = marpa_r_earleme_complete(r);
	if (result < 0) {
	  croak ("Problem in r->earleme_complete(): %s", xs_r_error(r_wrapper));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
event( r_wrapper, ix )
    R_Wrapper *r_wrapper;
    int ix;
PPCODE:
    {
      struct marpa_r * const r = r_wrapper->r;
      struct marpa_event event;
      const char *result_string = NULL;
      Marpa_Event_Type result = marpa_r_event (r, &event, ix);
      if (result < 0)
	{
	  croak ("Problem in r->earleme_event(): %s", xs_r_error(r_wrapper));
	}
	result_string = event_type_to_string(result);
      if (!result_string)
	{
	  croak ("Problem in r->earleme_event(): unknown event %d", result);
	}
      XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
      XPUSHs (sv_2mortal (newSViv (event.t_value)));
    }

void
earleme( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Earley_Set_ID ordinal;
PPCODE:
    { struct marpa_r* const r = r_wrapper->r;
	int result = marpa_r_earleme(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", xs_r_error(r_wrapper));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal::B_C

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
      croak ("Problem in b->new(): %s", xs_r_error (r_wrapper));
    }
  Newx (b_wrapper, 1, B_Wrapper);
  b_wrapper->message_buffer = NULL;
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
    if (b_wrapper->message_buffer)
	Safefree(b_wrapper->message_buffer);
    marpa_b_unref(b);
    Safefree( b_wrapper );
}

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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
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
	     xs_b_error (b_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
  XPUSHs (sv_2mortal (newSViv (value)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal::O_C

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
      croak ("Problem in o->new(): %s", xs_b_error (b_wrapper));
    }
  Newx (o_wrapper, 1, O_Wrapper);
  o_wrapper->message_buffer = NULL;
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
    if (o_wrapper->message_buffer)
	Safefree(o_wrapper->message_buffer);
    marpa_o_unref(o);
    Safefree( o_wrapper );
}

int
_marpa_o_and_node_order_set( o_wrapper, or_node_id, and_node_id_av )
    O_Wrapper *o_wrapper;
    Marpa_Or_Node_ID or_node_id;
    AV *and_node_id_av;
PPCODE:
{
  Marpa_Order o = o_wrapper->o;
  int length = av_len (and_node_id_av) + 1;
  int result;
  Marpa_And_Node_ID *and_node_ids;
  int i;
  Newx (and_node_ids, length, Marpa_And_Node_ID);
  for (i = 0; i < length; i++)
    {
      SV **elem = av_fetch (and_node_id_av, i, 0);
      if (elem == NULL)
	{
	  Safefree (and_node_ids);
	  XSRETURN_UNDEF;
	}
      else
	{
	  and_node_ids[i] = SvIV (*elem);
	}
    }
  result = _marpa_o_and_order_set (o, or_node_id, and_node_ids, length);
  Safefree (and_node_ids);
  if (result < -1) {
    croak ("Problem in o->_marpa_o_and_node_order_set(): %s", xs_o_error(o_wrapper));
  }
  if (result < 0)
    {
      XSRETURN_NO;
    }
  XSRETURN_YES;
}

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
      croak ("Problem in o->_marpa_o_and_node_order_get(): %s", xs_o_error(o_wrapper));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal::T_C

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
      croak ("Problem in t->new(): %s", xs_o_error (o_wrapper));
    }
  Newx (t_wrapper, 1, T_Wrapper);
  t_wrapper->message_buffer = NULL;
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
    if (t_wrapper->message_buffer)
	Safefree(t_wrapper->message_buffer);
    marpa_t_unref(t);
    Safefree( t_wrapper );
}

void
next( t_wrapper )
    T_Wrapper *t_wrapper;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = marpa_t_next (t);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->next(): %s", xs_t_error (t_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
parse_count( t_wrapper )
    T_Wrapper *t_wrapper;
PPCODE:
{
  Marpa_Tree t = t_wrapper->t;
  int result;
  result = marpa_t_parse_count (t);
  if (result == -1)
    {
      XSRETURN_UNDEF;
    }
  if (result < 0)
    {
      croak ("Problem in t->parse_count(): %s", xs_t_error (t_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

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
      croak ("Problem in t->_marpa_t_size(): %s", xs_t_error (t_wrapper));
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
      croak ("Problem in t->_marpa_t_nook_or_node(): %s", xs_t_error (t_wrapper));
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
      croak ("Problem in t->_marpa_t_nook_choice(): %s", xs_t_error (t_wrapper));
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
      croak ("Problem in t->_marpa_t_nook_parent(): %s", xs_t_error (t_wrapper));
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
      croak ("Problem in t->_marpa_t_nook_is_cause(): %s", xs_t_error (t_wrapper));
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
      croak ("Problem in t->_marpa_t_nook_cause_is_ready(): %s", xs_t_error (t_wrapper));
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
      croak ("Problem in t->_marpa_t_nook_is_predecessor(): %s", xs_t_error (t_wrapper));
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
	     xs_t_error (t_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal::V_C

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
      croak ("Problem in v->new(): %s", xs_t_error (t_wrapper));
    }
  Newx (v_wrapper, 1, V_Wrapper);
  v_wrapper->message_buffer = NULL;
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
    if (v_wrapper->message_buffer)
	Safefree(v_wrapper->message_buffer);
    marpa_v_unref(v);
    Safefree( v_wrapper );
}

void
symbol_ask_me_when_null_set( v_wrapper, symbol_id, value )
    V_Wrapper *v_wrapper;
    Marpa_Symbol_ID symbol_id;
    int value;
PPCODE:
{
  const Marpa_Value v = v_wrapper->v;
  int result = marpa_v_symbol_ask_me_when_null_set (v, symbol_id, value);
  if (result <= -1)
    {
      croak ("Problem in v->symbol_ask_me_when_null_set(%d, %d): %s",
	     symbol_id, value, xs_v_error (v_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (result)));
}

void
step( v_wrapper )
    V_Wrapper *v_wrapper;
PPCODE:
{
  const Marpa_Value v = v_wrapper->v;
  Marpa_Symbol_ID token_id;
  Marpa_Rule_ID rule_id;
  int status;
  const char *result_string;
  SV *sv;
  status = marpa_v_step (v);
  if (status == MARPA_VALUE_INACTIVE)
    {
      XSRETURN_UNDEF;
    }
  if (status < 0)
    {
      croak ("Problem in v->step(): %s", xs_v_error (v_wrapper));
    }
  result_string = value_type_to_string (status);
  if (!result_string)
    {
      croak ("Problem in r->v_step(): unknown action type %d", status);
    }
  XPUSHs (sv_2mortal (newSVpv (result_string, 0)));
  if (status == MARPA_VALUE_TOKEN)
    {
      token_id = marpa_v_semantic_token (v);
      XPUSHs (sv_2mortal (newSViv (token_id)));
      XPUSHs (sv_2mortal
	      (newSViv (marpa_v_token_value (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_n (v))));
    }
  if (status == MARPA_VALUE_NULLING_SYMBOL)
    {
      token_id = marpa_v_semantic_token (v);
      XPUSHs (sv_2mortal (newSViv (token_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_n (v))));
    }
  if (status == MARPA_VALUE_RULE)
    {
      rule_id = marpa_v_semantic_rule (v);
      XPUSHs (sv_2mortal (newSViv (rule_id)));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_0 (v))));
      XPUSHs (sv_2mortal (newSViv (marpa_v_arg_n (v))));
    }
}

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
      croak ("Problem in v->trace(): %s", xs_v_error (v_wrapper));
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
      croak ("Problem in v->_marpa_v_nook(): %s", xs_v_error (v_wrapper));
    }
  XPUSHs (sv_2mortal (newSViv (status)));
}

BOOT:
    marpa_debug_handler_set(marpa_r2_warn);
