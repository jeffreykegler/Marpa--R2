/*
 * Copyright 2011 Jeffrey Kegler
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

#include <gperl.h>

#include "config.h"
#include "marpa.h"

#undef G_LOG_DOMAIN
#define G_LOG_DOMAIN "Marpa"

#define DEBUG 0
#if !DEBUG
#if defined(G_HAVE_GNUC_VARARGS)
#undef g_debug
#define g_debug(...)
#endif /* defined G_HAVE_GNUC_VARARGS */
#endif /* if !DEBUG */

typedef struct marpa_g Grammar;
typedef struct {
     Grammar *g;
     GArray* gint_array;
} G_Wrapper;

typedef struct marpa_r Recce;
typedef struct {
     Recce *r;
     SV *g_sv;
     GArray* gint_array;
} R_Wrapper;

static const char grammar_c_class_name[] = "Marpa::R2::Internal::G_C";
static const char recce_c_class_name[] = "Marpa::R2::Internal::R_C";

static const char *
event_type_to_string (Marpa_Event_Type type)
{
  switch (type)
    {
    case MARPA_G_EV_EXHAUSTED:
      return "exhausted";
    case MARPA_G_EV_EARLEY_ITEM_THRESHOLD:
      return "earley item count";
    case MARPA_G_EV_LOOP_RULES:
      return "loop rules";
    case MARPA_G_EV_NEW_SYMBOL:
      return "new symbol";
    case MARPA_G_EV_NEW_RULE:
      return "new rule";
    }
  return NULL;
}


MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal::G_C

PROTOTYPES: DISABLE

G_Wrapper *
new( class, non_c_sv )
    char * class;
PREINIT:
    struct marpa_g *g;
    SV *sv;
    G_Wrapper *g_wrapper;
    const char *version_error;
PPCODE:
    version_error =
	marpa_check_version(MARPA_MAJOR_VERSION, MARPA_MINOR_VERSION, MARPA_MICRO_VERSION);
    if (version_error) {
	  croak ("Problem in Marpa::R2->new(): %s", version_error);
    }
    g = marpa_g_new();
    Newx( g_wrapper, 1, G_Wrapper );
    g_wrapper->g = g;
    g_wrapper->gint_array = g_array_new( FALSE, FALSE, sizeof(gint));
    sv = sv_newmortal();
    sv_setref_pv(sv, grammar_c_class_name, (void*)g_wrapper);
    XPUSHs(sv);

void
DESTROY( g_wrapper )
    G_Wrapper *g_wrapper;
PREINIT:
    struct marpa_g * grammar;
CODE:
    grammar = g_wrapper->g;
    g_array_free(g_wrapper->gint_array, TRUE);
    marpa_g_free( grammar );
    Safefree( g_wrapper );

void
start_symbol_set( g, id )
    Grammar *g;
    Marpa_Symbol_ID id;
PPCODE:
    { gboolean result = marpa_g_start_symbol_set(g, id);
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

void
start_symbol( g )
    Grammar *g;
PPCODE:
    { Marpa_Symbol_ID id = marpa_g_start_symbol( g );
    if (id < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(id) ) );
    }

void
default_value_set( g, value )
    Grammar *g;
    int value;
PPCODE:
    { gboolean result = marpa_g_default_value_set(g, GINT_TO_POINTER(value));
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

void
default_value( g )
    Grammar *g;
PPCODE:
    { gpointer value = marpa_g_default_value( g );
    XPUSHs( sv_2mortal( newSViv(GPOINTER_TO_INT(value)) ) );
    }

void
is_precomputed( g )
    Grammar *g;
PPCODE:
    { gint boolean = marpa_g_is_precomputed( g );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
event( g, ix )
    Grammar *g;
    int ix;
PPCODE:
    {
      struct marpa_g_event event;
      const char *result_string = NULL;
      Marpa_Event_Type result = marpa_g_event (g, &event, ix);
      if (result < 0)
	{
	  croak ("Problem in g->event(): %s", marpa_g_error (g));
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
has_loop( g )
    Grammar *g;
PPCODE:
    { gint boolean = marpa_g_has_loop( g );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
is_lhs_terminal_ok_set( g, boolean )
    Grammar *g;
    int boolean;
PPCODE:
    { gboolean result = marpa_g_is_lhs_terminal_ok_set(
	g, (boolean ? TRUE : FALSE));
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

void
is_lhs_terminal_ok( g )
    Grammar *g;
PPCODE:
    { gboolean boolean = marpa_g_is_lhs_terminal_ok( g );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

Marpa_Symbol_ID
symbol_new( g )
    Grammar *g;
CODE:
    RETVAL = marpa_g_symbol_new(g);
OUTPUT:
    RETVAL

void
symbol_lhs_rule_ids( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    {
    int i;
    gint count = marpa_g_symbol_lhs_count( g, symbol_id );
    if (count < -1) { croak("Problem in g->symbol_lhs_rule_ids: %s", marpa_g_error(g)); }
    if (count == -1) { XSRETURN_UNDEF; }
    for (i = 0; i < count; i++) {
	Marpa_Rule_ID rule_id= marpa_g_symbol_lhs( g, symbol_id, i );
	if (rule_id < 0) { croak("Problem in g->symbol_lhs_rule_ids: %s", marpa_g_error(g)); }
	XPUSHs( sv_2mortal( newSViv(rule_id) ) );
    }
    }

void
symbol_rhs_rule_ids( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    {
    int i;
    gint count = marpa_g_symbol_rhs_count( g, symbol_id );
    if (count < -1) { croak("Problem in g->symbol_rhs_rule_ids: %s", marpa_g_error(g)); }
    if (count == -1) { XSRETURN_UNDEF; }
    for (i = 0; i < count; i++) {
	Marpa_Rule_ID rule_id= marpa_g_symbol_rhs( g, symbol_id, i );
	if (rule_id < 0) { croak("Problem in g->symbol_rhs_rule_ids: %s", marpa_g_error(g)); }
	XPUSHs( sv_2mortal( newSViv(rule_id) ) );
    }
    }

void
symbol_is_accessible( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gboolean boolean = marpa_g_symbol_is_accessible( g, symbol_id );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_counted( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gboolean boolean = marpa_g_symbol_is_counted( g, symbol_id );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_nullable( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gboolean boolean = marpa_g_symbol_is_nullable( g, symbol_id );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_nulling( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gint result = marpa_g_symbol_is_nulling( g, symbol_id );
    if (result < 0) { croak("Invalid symbol %d", symbol_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_terminal_set( g, symbol_id, boolean )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
    int boolean;
PPCODE:
    marpa_g_symbol_is_terminal_set( g, symbol_id, (boolean ? TRUE : FALSE));

void
symbol_is_terminal( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gint result = marpa_g_symbol_is_terminal( g, symbol_id );
    if (result < 0) { croak("Invalid symbol %d", symbol_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_productive( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gint result = marpa_g_symbol_is_productive( g, symbol_id );
    if (result < 0) { croak("Invalid symbol %d", symbol_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_start( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gint result = marpa_g_symbol_is_start( g, symbol_id );
    if (result < 0) { croak("Invalid symbol %d", symbol_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

Marpa_Symbol_ID
symbol_null_alias( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    {
    Marpa_Symbol_ID alias_id = marpa_g_symbol_null_alias(g, symbol_id);
      if (alias_id < -1)
	{
	  croak ("problem with g->symbol_null_alias: %s",
		 marpa_g_error (g));
	}
      if (alias_id < 0)
	{
	  XSRETURN_UNDEF;
	}
      XPUSHs (sv_2mortal (newSViv (alias_id)));
    }

Marpa_Symbol_ID
symbol_proper_alias( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    {
    Marpa_Symbol_ID alias_id = marpa_g_symbol_proper_alias(g, symbol_id);
      if (alias_id < -1)
	{
	  croak ("problem with g->symbol_proper_alias: %s",
		 marpa_g_error (g));
	}
      if (alias_id < 0)
	{
	  XSRETURN_UNDEF;
	}
      XPUSHs (sv_2mortal (newSViv (alias_id)));
    }

Marpa_Rule_ID
symbol_virtual_lhs_rule( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    {
      Marpa_Rule_ID rule_id = marpa_g_symbol_virtual_lhs_rule (g, symbol_id);
      if (rule_id < -1)
	{
	  croak ("problem with g->symbol_virtual_lhs_rule: %s",
		 marpa_g_error (g));
	}
      if (rule_id < 0)
	{
	  XSRETURN_UNDEF;
	}
      XPUSHs (sv_2mortal (newSViv (rule_id)));
    }

 # Rules

Marpa_Rule_ID
rule_new( g, lhs, rhs_av )
    Grammar *g;
    Marpa_Symbol_ID lhs;
    AV *rhs_av;
PREINIT:
    int length;
    Marpa_Symbol_ID* rhs;
    Marpa_Rule_ID new_rule_id;
PPCODE:
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

 # This function invalidates any current iteration on
 # the hash args.  This seesm to be the way things are
 # done in Perl -- in particular there seems to be no
 # easy way to  prevent that.
Marpa_Rule_ID
sequence_new( g, lhs, rhs, args )
    Grammar *g;
    Marpa_Symbol_ID lhs;
    Marpa_Symbol_ID rhs;
    HV *args;
PREINIT:
    Marpa_Rule_ID new_rule_id;
    Marpa_Symbol_ID separator = -1;
    gint min = 1;
    gint flags = 0;
PPCODE:
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
		gint raw_min = SvIV (arg_value);
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

Marpa_Symbol_ID
rule_lhs( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_g_rule_lhs(g, rule_id);
    if (RETVAL < -1) { 
      croak ("Problem in g->rule_lhs(%d): %s", rule_id, marpa_g_error (g));
      }
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

Marpa_Symbol_ID
rule_rhs( g, rule_id, ix )
    Grammar *g;
    Marpa_Rule_ID rule_id;
    int ix;
CODE:
    RETVAL = marpa_g_rule_rh_symbol(g, rule_id, ix);
    if (RETVAL < -1) { 
      croak ("Problem in g->rule_rhs(%d, %d): %s", rule_id, ix, marpa_g_error (g));
      }
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

int
rule_length( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_g_rule_length(g, rule_id);
    if (RETVAL < -1) { 
      croak ("Problem in g->rule_length(%d): %s", rule_id, marpa_g_error (g));
      }
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

void
rule_is_accessible( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_is_accessible( g, rule_id );
    if (result < -1) { 
      croak ("Problem in g->rule_is_accessible(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_productive( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_is_productive( g, rule_id );
    if (result < -1) { 
      croak ("Problem in g->rule_is_productive(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_loop( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_is_loop( g, rule_id );
    if (result < -1) { 
      croak ("Problem in g->rule_is_loop(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_virtual_loop( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_is_virtual_loop( g, rule_id );
    if (result < -1) { 
      croak ("Problem in g->rule_is_virtual_loop(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

int
rule_virtual_start( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_g_virtual_start( g, rule_id );
    if (RETVAL <= -2) { 
      croak ("Problem in g->rule_is_virtual_start(%d): %s", rule_id, marpa_g_error (g));
      }
OUTPUT:
    RETVAL

int
rule_virtual_end( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_g_virtual_end( g, rule_id );
    if (RETVAL <= -2) { 
      croak ("Problem in g->rule_is_virtual_end(%d): %s", rule_id, marpa_g_error (g));
      }
OUTPUT:
    RETVAL

void
rule_is_used( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_is_used( g, rule_id );
    if (result < 0) { 
      croak ("Problem in g->rule_is_used(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_discard_separation( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_is_discard_separation( g, rule_id );
    if (result < 0) { 
      croak ("Problem in g->rule_is_discard_separation(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_virtual_lhs( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_is_virtual_lhs( g, rule_id );
    if (result < 0) { 
      croak ("Problem in g->rule_is_virtual_lhs(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_virtual_rhs( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_is_virtual_rhs( g, rule_id );
    if (result < 0) { 
      croak ("Problem in g->rule_is_virtual_rhs(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

Marpa_Rule_ID
real_symbol_count( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_g_real_symbol_count(g, rule_id);
OUTPUT:
    RETVAL

Marpa_Rule_ID
rule_original( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_g_rule_original(g, rule_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

Marpa_Rule_ID
semantic_equivalent( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_g_rule_semantic_equivalent(g, rule_id);
    if (result <= -2) { 
      croak ("Problem in g->semantic_equivalent(%d): %s", rule_id, marpa_g_error (g));
      }
    if (result == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
AHFA_item_count( g )
    Grammar *g;
PPCODE:
    {
	gint result = marpa_g_AHFA_item_count(g );
	if (result <= -2) { 
	      croak ("Problem in g->AHFA_item_count(): %s", marpa_g_error (g));
	}
	if (result < 0) { XSRETURN_UNDEF; }
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
rule_count( g )
    Grammar *g;
PPCODE:
    {
	gint result = marpa_g_rule_count(g );
	if (result < -1) {
	  croak ("Problem in g->rule_count(): %s", marpa_g_error (g));
	}
	if (result < 0) { XSRETURN_UNDEF; }
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
symbol_count( g )
    Grammar *g;
PPCODE:
    {
	gint count = marpa_g_symbol_count(g );
	if (count < -1) {
	  croak ("Problem in g->symbol_count(): %s", marpa_g_error (g));
	}
	if (count < 0) { XSRETURN_UNDEF; }
	XPUSHs( sv_2mortal( newSViv(count) ) );
    }

Marpa_Rule_ID
AHFA_item_rule( g, item_id )
    Grammar *g;
    Marpa_AHFA_Item_ID item_id;
CODE:
    RETVAL = marpa_g_AHFA_item_rule(g, item_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

 # -1 is a valid return value, so -2 indicates an error
int
AHFA_item_position( g, item_id )
    Grammar *g;
    Marpa_AHFA_Item_ID item_id;
CODE:
    RETVAL = marpa_g_AHFA_item_position(g, item_id);
    if (RETVAL <= -2) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

int
AHFA_item_sort_key( g, item_id )
    Grammar *g;
    Marpa_AHFA_Item_ID item_id;
CODE:
    RETVAL = marpa_g_AHFA_item_sort_key(g, item_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

 # -1 is a valid return value, and -2 indicates an error
Marpa_Symbol_ID
AHFA_item_postdot( g, item_id )
    Grammar *g;
    Marpa_AHFA_Item_ID item_id;
CODE:
    RETVAL = marpa_g_AHFA_item_postdot(g, item_id);
    if (RETVAL <= -2) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

int
AHFA_state_count( g )
    Grammar *g;
CODE:
    RETVAL = marpa_g_AHFA_state_count(g );
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

 # In scalar context, returns the count
void
AHFA_state_items( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    { gint count = marpa_g_AHFA_state_item_count(g, AHFA_state_id);
    if (count < 0) { croak("Invalid AHFA state %d", AHFA_state_id); }
    if (GIMME == G_ARRAY) {
        gint item_ix;
        EXTEND(SP, count);
        for (item_ix = 0; item_ix < count; item_ix++) {
	    Marpa_AHFA_Item_ID item_id
		= marpa_g_AHFA_state_item(g, AHFA_state_id, item_ix);
            PUSHs( sv_2mortal( newSViv(item_id) ) );
        }
    } else {
        XPUSHs( sv_2mortal( newSViv(count) ) );
    }
    }

 # In scalar context, returns the count
void
AHFA_state_transitions( g_wrapper, AHFA_state_id )
    G_Wrapper *g_wrapper;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    {
    Grammar *g = g_wrapper->g;
    GArray* const gint_array = g_wrapper->gint_array;
    const gint result = marpa_g_AHFA_state_transitions(g, AHFA_state_id, gint_array);
    if (result < 0) {
	  croak ("Problem in AHFA_state_transitions(): %s", marpa_g_error (g));
    }
    if (GIMME == G_ARRAY) {
        const gint count = gint_array->len;
	gint ix;
        for (ix = 0; ix < count; ix++) {
	    XPUSHs (sv_2mortal (newSViv (g_array_index (gint_array, gint, ix))));
        }
    } else {
        XPUSHs( sv_2mortal( newSViv((gint)gint_array->len) ) );
    }
    }

 # -1 is a valid return value, and -2 indicates an error
Marpa_AHFA_State_ID
AHFA_state_empty_transition( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
CODE:
    RETVAL = marpa_g_AHFA_state_empty_transition(g, AHFA_state_id);
    if (RETVAL <= -2) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

void
AHFA_state_is_predict( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    { gint result = marpa_g_AHFA_state_is_predict( g, AHFA_state_id );
    if (result < 0) { croak("Invalid AHFA state %d", AHFA_state_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
AHFA_state_leo_lhs_symbol( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    { gint result = marpa_g_AHFA_state_leo_lhs_symbol( g, AHFA_state_id );
    if (result < -1) { croak("Invalid AHFA state %d", AHFA_state_id); }
    if (result == -1) XSRETURN_UNDEF;
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

Marpa_Rule_ID
AHFA_completed_start_rule( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    { gint result = marpa_g_AHFA_completed_start_rule(g, AHFA_state_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < -1) { croak("Invalid AHFA state %d", AHFA_state_id); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

char *error( g )
    Grammar *g;
CODE:
    RETVAL = (gchar*)marpa_g_error(g);
OUTPUT:
    RETVAL

void precompute( g )
    Grammar *g;
PPCODE:
    {
      gint result = marpa_g_precompute (g);
      if (result < 0) {
         XSRETURN_UNDEF;
      }
      XPUSHs (sv_2mortal (newSViv (result)));
    }

MODULE = Marpa::R2        PACKAGE = Marpa::R2::Internal::R_C

void
new( class, g_sv )
    char * class;
    SV *g_sv;
PREINIT:
    G_Wrapper *g_wrapper;
    struct marpa_g* g;
    IV tmp;
    SV *sv;
    R_Wrapper *r_wrapper;
    struct marpa_r* r;
PPCODE:
    if (! sv_isa(g_sv, grammar_c_class_name)) {
        g_debug("Marpa::Recognizer::new grammar arg is not in class %s",
            grammar_c_class_name);
    }
    tmp = SvIV((SV*)SvRV(g_sv));
    g_wrapper = GINT_TO_POINTER(tmp);
    g = g_wrapper->g;
    r = marpa_r_new(g);
    if (!r) { croak ("failure in marpa_r_new: %s", marpa_g_error (g)); };
    Newx( r_wrapper, 1, R_Wrapper );
    r_wrapper->r = r;
    r_wrapper->g_sv = g_sv;
    r_wrapper->gint_array = g_array_new( FALSE, FALSE, sizeof(gint));
    SvREFCNT_inc(g_sv);
    sv = sv_newmortal();
    sv_setref_pv(sv, recce_c_class_name, (void*)r_wrapper);
    XPUSHs(sv);

void
DESTROY( r_wrapper )
    R_Wrapper *r_wrapper;
PREINIT:
    SV *g_sv;
    struct marpa_r *r;
CODE:
    g_sv = r_wrapper->g_sv;
    r = r_wrapper->r;
    g_array_free(r_wrapper->gint_array, TRUE);
    marpa_r_free( r );
    SvREFCNT_dec(g_sv);
    Safefree( r_wrapper );

 # Someday replace this with a function which translates the
 # error
char *error( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = (gchar*)marpa_r_error(r_wrapper->r);
OUTPUT:
    RETVAL

const char *raw_error( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = marpa_r_error(r_wrapper->r);
OUTPUT:
    RETVAL

const char *
phase( r_wrapper )
    R_Wrapper *r_wrapper;
PREINIT:
    Marpa_Phase phase;
CODE:
    phase = marpa_r_phase(r_wrapper->r);
    RETVAL = "unknown";
    switch(phase) {
    case no_such_phase: RETVAL = "undefined"; break;
    case initial_phase: RETVAL = "initial"; break;
    case input_phase: RETVAL = "read"; break;
    case evaluation_phase: RETVAL = "evaluation"; break;
    }
OUTPUT:
    RETVAL

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
  gboolean result = marpa_r_is_use_leo_set (r, (boolean ? TRUE : FALSE));
  if (!result)
    {
      croak ("Problem in is_use_leo_set(): %s", marpa_r_error (r));
    }
}
XSRETURN_YES;

void
is_use_leo( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
     gint boolean = marpa_r_is_use_leo( r );
     if (boolean < 0) { 
	 croak("Problem in is_use_leo(): %s", marpa_r_error(r)); }
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
is_exhausted( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
     gint boolean = marpa_r_is_exhausted( r );
     if (boolean < 0) { 
	 croak("Problem in is_exhausted(): %s", marpa_r_error(r)); }
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
start_input( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { gboolean result = marpa_r_start_input(r_wrapper->r);
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

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
      gint result =
	marpa_r_alternative (r, symbol_id, GINT_TO_POINTER(value), length);
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
	  croak ("Invalid alternative: %s", marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (result)));
    }

void
earley_item_warning_threshold_set( r_wrapper, too_many_earley_items )
    R_Wrapper *r_wrapper;
    int too_many_earley_items;
PPCODE:
    { gboolean result = marpa_r_earley_item_warning_threshold_set(r_wrapper->r, too_many_earley_items);
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

void
too_many_earley_items( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { gint too_many_earley_items = marpa_r_earley_item_warning_threshold( r_wrapper->r );
    XPUSHs( sv_2mortal( newSViv(too_many_earley_items) ) );
    }

void
latest_earley_set( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint latest_earley_set = marpa_r_latest_earley_set(r);
      if (latest_earley_set < 0)
	{
      croak ("Problem with r->latest_earley_set(): %s",
		 marpa_r_error (r));
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
      gint earley_set_size = marpa_r_earley_set_size (r, set_ordinal);
      if (earley_set_size < 0) {
	  croak ("Problem in r->earley_set_size(): %s", marpa_r_error (r));
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
    if (result < 0) { croak("problem with r->earley_set_trace: %s", marpa_r_error(r)); }
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
    if (result < 0) { croak("problem with r->earley_item_trace: %s", marpa_r_error(r)); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
earley_item_origin( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint origin_earleme = marpa_r_earley_item_origin (r);
      if (origin_earleme < 0)
	{
      croak ("Problem with r->earley_item_origin(): %s",
		 marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (origin_earleme)));
    }

void
first_token_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint token_id = marpa_r_first_token_link_trace(r);
    if (token_id <= -2) { croak("Trace first token link problem: %s", marpa_r_error(r)); }
    if (token_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(token_id) ) );
    }

void
next_token_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint token_id = marpa_r_next_token_link_trace(r);
    if (token_id <= -2) { croak("Trace next token link problem: %s", marpa_r_error(r)); }
    if (token_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(token_id) ) );
    }

void
first_completion_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint AHFA_state_id = marpa_r_first_completion_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace first completion link problem: %s", marpa_r_error(r)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
next_completion_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint AHFA_state_id = marpa_r_next_completion_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace next completion link problem: %s", marpa_r_error(r)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
first_leo_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint AHFA_state_id = marpa_r_first_leo_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace first completion link problem: %s", marpa_r_error(r)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
next_leo_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint AHFA_state_id = marpa_r_next_leo_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace next completion link problem: %s", marpa_r_error(r)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
source_predecessor_state( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint state_id = marpa_r_source_predecessor_state(r);
    if (state_id <= -2) { croak("Problem finding trace source predecessor state: %s", marpa_r_error(r)); }
    if (state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(state_id) ) );
    }

void
source_leo_transition_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint symbol_id = marpa_r_source_leo_transition_symbol(r);
    if (symbol_id <= -2) { croak("Problem finding trace source leo transition symbol: %s", marpa_r_error(r)); }
    if (symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(symbol_id) ) );
    }

void
source_token( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gpointer value;
    gint symbol_id = marpa_r_source_token(r, &value);
    if (symbol_id == -1) { XSRETURN_UNDEF; }
    if (symbol_id < 0) { croak("Problem with r->source_token(): %s", marpa_r_error(r)); }
	XPUSHs( sv_2mortal( newSViv(symbol_id) ) );
	XPUSHs( sv_2mortal( newSViv(GPOINTER_TO_INT(value)) ) );
    }

void
source_middle( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint middle = marpa_r_source_middle(r);
    if (middle <= -2) { croak("Problem with r->source_middle(): %s", marpa_r_error(r)); }
    if (middle == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(middle) ) );
    }

void
first_postdot_item_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint postdot_symbol_id = marpa_r_first_postdot_item_trace(r);
    if (postdot_symbol_id <= -2) { croak("Trace first postdot item problem: %s", marpa_r_error(r)); }
    if (postdot_symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(postdot_symbol_id) ) );
    }

void
next_postdot_item_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint postdot_symbol_id = marpa_r_next_postdot_item_trace(r);
    if (postdot_symbol_id <= -2) { croak("Trace next postdot item problem: %s", marpa_r_error(r)); }
    if (postdot_symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(postdot_symbol_id) ) );
    }

void
postdot_symbol_trace( r, symid )
    Recce *r;
    Marpa_Symbol_ID symid;
PPCODE:
    { 
    gint postdot_symbol_id = marpa_r_postdot_symbol_trace(r, symid);
    if (postdot_symbol_id == -1) { XSRETURN_UNDEF; }
    if (postdot_symbol_id <= 0) { croak("Problem in r->postdot_symbol_trace: %s", marpa_r_error(r)); }
    XPUSHs( sv_2mortal( newSViv(postdot_symbol_id) ) );
    }

void
leo_base_state( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint leo_base_state = marpa_r_leo_base_state (r);
      if (leo_base_state == -1) { XSRETURN_UNDEF; }
      if (leo_base_state < 0) {
	  croak ("Problem in r->leo_base_state(): %s", marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (leo_base_state)));
    }

void
leo_base_origin( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint leo_base_origin = marpa_r_leo_base_origin (r);
      if (leo_base_origin == -1) { XSRETURN_UNDEF; }
      if (leo_base_origin < 0) {
	  croak ("Problem in r->leo_base_origin(): %s", marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (leo_base_origin)));
    }

void
leo_expansion_ahfa( r )
    Recce *r;
PPCODE:
    {
      gint leo_expansion_ahfa = marpa_r_leo_expansion_ahfa(r);
      if (leo_expansion_ahfa == -1) { XSRETURN_UNDEF; }
      if (leo_expansion_ahfa < 0) {
	  croak ("Problem in r->leo_expansion_ahfa(): %s", marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (leo_expansion_ahfa)));
    }

void
trace_earley_set( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint trace_earley_set = marpa_r_trace_earley_set (r);
      if (trace_earley_set < 0) {
	  croak ("Problem in r->trace_earley_set(): %s", marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (trace_earley_set)));
    }

void
postdot_item_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint postdot_item_symbol = marpa_r_postdot_item_symbol (r);
      if (postdot_item_symbol < 0) {
	  croak ("Problem in r->postdot_item_symbol(): %s", marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (postdot_item_symbol)));
    }

void
leo_predecessor_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint leo_predecessor_symbol = marpa_r_leo_predecessor_symbol (r);
      if (leo_predecessor_symbol == -1) { XSRETURN_UNDEF; }
      if (leo_predecessor_symbol < 0) {
	  croak ("Problem in r->leo_predecessor_symbol(): %s", marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (leo_predecessor_symbol)));
    }

void
terminals_expected( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
        GArray* terminal_ids = r_wrapper->gint_array;
        gint count = marpa_r_terminals_expected(r, terminal_ids);
	if (count < 0) {
	  croak ("Problem in r->terminals_expected(): %s", marpa_r_error (r));
	}
	if (GIMME == G_ARRAY) {
	    int i;
	    EXTEND(SP, count);
	    for (i = 0; i < count; i++) {
		PUSHs (sv_2mortal (newSViv (g_array_index (terminal_ids, gint, i))));
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
	  croak ("Problem in r->earleme_complete(): %s", marpa_r_error (r));
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
      struct marpa_g_event event;
      const char *result_string = NULL;
      Marpa_Event_Type result = marpa_r_event (r, &event, ix);
      if (result < 0)
	{
	  croak ("Problem in r->earleme_event(): %s", marpa_r_error (r));
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
	gint result = marpa_r_earleme(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
eval_setup( r_wrapper, rule_id, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Rule_ID rule_id;
     Marpa_Earley_Set_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_new(r, rule_id, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->eval_setup(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
eval_clear( r_wrapper )
     R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_free(r);
	if (result < 0) {
	  croak ("Problem in r->eval_clear(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_set( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_or_node_set(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->or_node_set(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_origin( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_or_node_origin(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->or_node_origin(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_position( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_or_node_position(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->or_node_position(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_rule( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_or_node_rule(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->or_node_rule(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_first_and( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_or_node_first_and(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->or_node_first_and(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_last_and( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_or_node_last_and(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->or_node_last_and(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_and_count( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_or_node_and_count(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->or_node_and_count(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_count( r_wrapper )
     R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_and_node_count(r);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->and_node_count(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_parent( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_and_node_parent(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->and_node_parent(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_predecessor( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_and_node_predecessor(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->and_node_predecessor(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_cause( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_and_node_cause(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->and_node_cause(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_symbol( r_wrapper, and_node_id )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID and_node_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_b_and_node_symbol(r, and_node_id);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->and_node_symbol(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_token( r_wrapper, and_node_id )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID and_node_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
        gpointer value = NULL;
	gint result = marpa_b_and_node_token(r, and_node_id, &value);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->and_node_symbol(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
	XPUSHs( sv_2mortal( newSViv(GPOINTER_TO_INT(value)) ) );
    }

int
and_node_order_set( r_wrapper, or_node_id, and_node_id_av )
    R_Wrapper *r_wrapper;
    Marpa_Or_Node_ID or_node_id;
    AV *and_node_id_av;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int length = av_len(and_node_id_av)+1;
    int result;
    Marpa_And_Node_ID* and_node_ids;
    int i;
    Newx(and_node_ids, length, Marpa_And_Node_ID);
    for (i = 0; i < length; i++) {
	SV** elem = av_fetch(and_node_id_av, i, 0);
	if (elem == NULL) {
	    Safefree(and_node_ids);
	    XSRETURN_UNDEF;
	} else {
	    and_node_ids[i] = SvIV(*elem);
	}
    }
    result = marpa_o_and_order_set(r, or_node_id, and_node_ids, length);
    Safefree(and_node_ids);
    if (result < 0) { XSRETURN_NO; }
    XSRETURN_YES;
    }

int
and_node_order_get( r_wrapper, or_node_id, and_ix )
    R_Wrapper *r_wrapper;
    Marpa_Or_Node_ID or_node_id;
    int and_ix;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_o_and_order_get(r, or_node_id, and_ix);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->and_node_order_get(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
tree_new( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int status;
    status = marpa_t_new(r);
    if (status == -1) { XSRETURN_UNDEF; }
    if (status < 0) {
      croak ("Problem in r->tree_new(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(status) ) );
    }

int
parse_count( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_parse_count(r);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->parse_count(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
tree_size( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_size(r);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->tree_size(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
fork_or_node( r_wrapper, fork_id )
    R_Wrapper *r_wrapper;
    Marpa_Fork_ID fork_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_fork_or_node(r, fork_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->fork_or_node(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
fork_choice( r_wrapper, fork_id )
    R_Wrapper *r_wrapper;
    Marpa_Fork_ID fork_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_fork_choice(r, fork_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->fork_choice(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
fork_parent( r_wrapper, fork_id )
    R_Wrapper *r_wrapper;
    Marpa_Fork_ID fork_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_fork_parent(r, fork_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->fork_parent(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
fork_is_cause( r_wrapper, fork_id )
    R_Wrapper *r_wrapper;
    Marpa_Fork_ID fork_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_fork_is_cause(r, fork_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->fork_is_cause(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
fork_cause_is_ready( r_wrapper, fork_id )
    R_Wrapper *r_wrapper;
    Marpa_Fork_ID fork_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_fork_cause_is_ready(r, fork_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->fork_cause_is_ready(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }


int
fork_is_predecessor( r_wrapper, fork_id )
    R_Wrapper *r_wrapper;
    Marpa_Fork_ID fork_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_fork_is_predecessor(r, fork_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->fork_is_predecessor(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

int
fork_predecessor_is_ready( r_wrapper, fork_id )
    R_Wrapper *r_wrapper;
    Marpa_Fork_ID fork_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int result;
    result = marpa_t_fork_predecessor_is_ready(r, fork_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) {
      croak ("Problem in r->fork_predecessor_is_ready(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
val_new( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int status;
    status = marpa_v_new(r);
    if (status == -1) { XSRETURN_UNDEF; }
    if (status < 0) {
      croak ("Problem in r->val_new(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(status) ) );
    }

void
val_event( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      int status;
      SV* sv;
      Marpa_Event event;
      status = marpa_v_event (r, &event);
      if (status == -1)
	{
	  XSRETURN_UNDEF;
	}
      if (status < 0)
	{
	  croak ("Problem in r->val_event(): %s", marpa_r_error (r));
	}
      if ( event.marpa_token_id < 0 ) {
	  XPUSHs (&PL_sv_undef);
	  XPUSHs (&PL_sv_undef);
      } else {
	  XPUSHs ( sv_2mortal (newSViv (event.marpa_token_id)) );
	  XPUSHs ( sv_2mortal (newSViv (GPOINTER_TO_INT(event.marpa_value))));
      }
      sv = event.marpa_rule_id < 0 ? &PL_sv_undef : sv_2mortal (newSViv (event.marpa_rule_id));
      XPUSHs (sv);
	XPUSHs( sv_2mortal( newSViv(event.marpa_arg_0) ) );
	XPUSHs( sv_2mortal( newSViv(event.marpa_arg_n) ) );
    }

void
val_trace( r_wrapper, flag )
    R_Wrapper *r_wrapper;
    int flag;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int status;
    status = marpa_v_trace(r, flag);
    if (status == -1) { XSRETURN_UNDEF; }
    if (status < 0) {
      croak ("Problem in r->val_trace(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(status) ) );
    }

void
val_fork( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    int status;
    status = marpa_v_fork(r);
    if (status == -1) { XSRETURN_UNDEF; }
    if (status < 0) {
      croak ("Problem in r->val_fork(): %s", marpa_r_error (r));
    }
    XPUSHs( sv_2mortal( newSViv(status) ) );
    }

BOOT:
    gperl_handle_logs_for(G_LOG_DOMAIN);
