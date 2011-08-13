/*
 * Copyright 2011 Jeffrey Kegler
 * This file is part of Marpa::XS.  Marpa::XS is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Marpa::XS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Marpa::XS.  If not, see
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

static const char grammar_c_class_name[] = "Marpa::XS::Internal::G_C";
static const char recce_c_class_name[] = "Marpa::XS::Internal::R_C";

static void
xs_g_message_callback(Grammar *g, Marpa_Message_ID id)
{
    SV* cb = marpa_g_message_callback_arg(g);
    if (!cb) return;
    if (!SvOK(cb)) return;
    {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv( marpa_grammar_id(g))));
    XPUSHs(sv_2mortal(newSVpv(id, 0)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    }
}

static void
xs_r_message_callback(struct marpa_r *r, Marpa_Message_ID id)
{
    SV* cb = marpa_r_message_callback_arg(r);
    if (!cb) return;
    if (!SvOK(cb)) return;
    {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv( marpa_r_id(r))));
    XPUSHs(sv_2mortal(newSVpv(id, 0)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    }
}

static void
xs_rule_callback(Grammar *g, Marpa_Rule_ID id)
{
    SV* cb = marpa_rule_callback_arg(g);
    if (!cb) return;
    if (!SvOK(cb)) return;
    {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv( marpa_grammar_id(g))));
    XPUSHs(sv_2mortal(newSViv(id)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    }
}

static void
xs_symbol_callback(Grammar *g, Marpa_Symbol_ID id)
{
    SV* cb = marpa_symbol_callback_arg(g);
    if (!cb) return;
    if (!SvOK(cb)) return;
    {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv( marpa_grammar_id(g))));
    XPUSHs(sv_2mortal(newSViv(id)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    }
}

MODULE = Marpa::XS        PACKAGE = Marpa::XS

PROTOTYPES: DISABLE

void
version()
PPCODE:
{
   int version[3];
   marpa_version(version);
   EXTEND(SP, 3);
   mPUSHi( version[0] );
   mPUSHi( version[1] );
   mPUSHi( version[2] );
}

MODULE = Marpa::XS        PACKAGE = Marpa::XS::Internal::G_C

G_Wrapper *
new( class, non_c_sv )
    char * class;
PREINIT:
    struct marpa_g *g;
    SV *sv;
    G_Wrapper *g_wrapper;
PPCODE:
    g = marpa_g_new();
    marpa_g_message_callback_set( g, &xs_g_message_callback );
    marpa_rule_callback_set( g, &xs_rule_callback );
    marpa_symbol_callback_set( g, &xs_symbol_callback );
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
    {
       SV *sv = marpa_g_message_callback_arg(grammar);
	marpa_g_message_callback_arg_set( grammar, NULL );
       if (sv) {
       SvREFCNT_dec(sv);
       }
    }
    {
       SV *sv = marpa_rule_callback_arg(grammar);
	marpa_rule_callback_arg_set( grammar, NULL );
       if (sv) { 
        SvREFCNT_dec(sv); }
    }
    {
       SV *sv = marpa_symbol_callback_arg(grammar);
	marpa_symbol_callback_arg_set( grammar, NULL );
       if (sv) {
       SvREFCNT_dec(sv); }
    }
    g_array_free(g_wrapper->gint_array, TRUE);
    marpa_g_free( grammar );
    Safefree( g_wrapper );

 # Note the Perl callback closure
 # is, in the libmarpa context, the *ARGUMENT* of the callback,
 # not the callback itself.
 # The libmarpa callback is a wrapper
 # that calls the Perl closure.
void
message_callback_set( g, sv )
    Grammar *g;
    SV *sv;
PPCODE:
    {
       SV *old_sv = marpa_g_message_callback_arg(g);
       if (old_sv) { SvREFCNT_dec(old_sv); }
    }
    marpa_g_message_callback_arg_set( g, sv );
    SvREFCNT_inc(sv);

void
rule_callback_set( g, sv )
    Grammar *g;
    SV *sv;
PPCODE:
    {
       SV *old_sv = marpa_rule_callback_arg(g);
       if (old_sv) {
       SvREFCNT_dec(old_sv); }
    }
    marpa_rule_callback_arg_set( g, sv );
    SvREFCNT_inc(sv);

void
symbol_callback_set( g, sv )
    Grammar *g;
    SV *sv;
PPCODE:
    {
       SV *old_sv = marpa_symbol_callback_arg(g);
       if (old_sv) {
       SvREFCNT_dec(old_sv); }
    }
    marpa_symbol_callback_arg_set( g, sv );
    SvREFCNT_inc(sv);

Marpa_Grammar_ID
id( g )
    Grammar *g;
CODE:
    RETVAL = marpa_grammar_id(g);
OUTPUT:
    RETVAL

void
start_symbol_set( g, id )
    Grammar *g;
    Marpa_Symbol_ID id;
PPCODE:
    { gboolean result = marpa_start_symbol_set(g, id);
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

void
start_symbol( g )
    Grammar *g;
PPCODE:
    { Marpa_Symbol_ID id = marpa_start_symbol( g );
    if (id < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(id) ) );
    }

void
is_precomputed( g )
    Grammar *g;
PPCODE:
    { gint boolean = marpa_is_precomputed( g );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
has_loop( g )
    Grammar *g;
PPCODE:
    { gint boolean = marpa_has_loop( g );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
is_lhs_terminal_ok_set( g, boolean )
    Grammar *g;
    int boolean;
PPCODE:
    { gboolean result = marpa_is_lhs_terminal_ok_set(
	g, (boolean ? TRUE : FALSE));
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

void
is_lhs_terminal_ok( g )
    Grammar *g;
PPCODE:
    { gboolean boolean = marpa_is_lhs_terminal_ok( g );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

Marpa_Symbol_ID
symbol_new( g )
    Grammar *g;
CODE:
    RETVAL = marpa_symbol_new(g);
OUTPUT:
    RETVAL

void
symbol_lhs_rule_ids( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { GArray *rule_id_array = marpa_symbol_lhs_peek( g, symbol_id );
    guint len = rule_id_array->len;
    Marpa_Rule_ID* rule_ids = (Marpa_Rule_ID*)rule_id_array->data;
    if (GIMME == G_ARRAY) {
        int i;
        EXTEND(SP, len);
        for (i = 0; i < len; i++) {
            PUSHs( sv_2mortal( newSViv(rule_ids[i]) ) );
        }
    } else {
        XPUSHs( sv_2mortal( newSViv(len) ) );
    }
    }

 # In scalar context, returns the RHS length
void
symbol_rhs_rule_ids( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { GArray *rule_id_array = marpa_symbol_rhs_peek( g, symbol_id );
    guint len = rule_id_array->len;
    Marpa_Rule_ID* rule_ids = (Marpa_Rule_ID*)rule_id_array->data;
    if (GIMME == G_ARRAY) {
        int i;
        EXTEND(SP, len);
        for (i = 0; i < len; i++) {
            PUSHs( sv_2mortal( newSViv(rule_ids[i]) ) );
        }
    } else {
        XPUSHs( sv_2mortal( newSViv(len) ) );
    }
    }

void
symbol_is_accessible_set( g, symbol_id, boolean )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
    int boolean;
PPCODE:
    marpa_symbol_is_accessible_set( g, symbol_id, (boolean ? TRUE : FALSE));

void
symbol_is_accessible( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gboolean boolean = marpa_symbol_is_accessible( g, symbol_id );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_counted( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gboolean boolean = marpa_symbol_is_counted( g, symbol_id );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_nullable_set( g, symbol_id, boolean )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
    int boolean;
PPCODE:
    marpa_symbol_is_nullable_set( g, symbol_id, (boolean ? TRUE : FALSE));

void
symbol_is_nullable( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gboolean boolean = marpa_symbol_is_nullable( g, symbol_id );
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_nulling_set( g, symbol_id, boolean )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
    int boolean;
PPCODE:
    marpa_symbol_is_nulling_set( g, symbol_id, (boolean ? TRUE : FALSE));

void
symbol_is_nulling( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gint result = marpa_symbol_is_nulling( g, symbol_id );
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
    marpa_symbol_is_terminal_set( g, symbol_id, (boolean ? TRUE : FALSE));

void
symbol_is_terminal( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gint result = marpa_symbol_is_terminal( g, symbol_id );
    if (result < 0) { croak("Invalid symbol %d", symbol_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_productive_set( g, symbol_id, boolean )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
    int boolean;
PPCODE:
    marpa_symbol_is_productive_set( g, symbol_id, (boolean ? TRUE : FALSE));

void
symbol_is_productive( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gint result = marpa_symbol_is_productive( g, symbol_id );
    if (result < 0) { croak("Invalid symbol %d", symbol_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
symbol_is_start( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
PPCODE:
    { gint result = marpa_symbol_is_start( g, symbol_id );
    if (result < 0) { croak("Invalid symbol %d", symbol_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

Marpa_Symbol_ID
symbol_null_alias( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
CODE:
    RETVAL = marpa_symbol_null_alias(g, symbol_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

Marpa_Symbol_ID
symbol_proper_alias( g, symbol_id )
    Grammar *g;
    Marpa_Symbol_ID symbol_id;
CODE:
    RETVAL = marpa_symbol_proper_alias(g, symbol_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

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
    new_rule_id = marpa_rule_new(g, lhs, rhs, length);
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
    guint min = 1;
    gint flags = 0;
PPCODE:
    if (args) {
	I32 retlen;
	char* key;
	SV* arg_value;
	hv_iterinit(args);
	while (arg_value = hv_iternextsv(args, &key, &retlen) ) {
	    if ((*key == 'k') && strnEQ(key, "keep", retlen)) {
		if (SvTRUE(arg_value)) flags |= MARPA_KEEP_SEPARATION;
		continue;
	    }
	    if ((*key == 'm') && strnEQ(key, "min", retlen)) {
		gint raw_min = SvIV(arg_value);
		if (raw_min < 0) {
		    croak("sequence_new(): min cannot be less than 0");
		}
		min = raw_min;
		continue;
	    }
	    if ((*key == 'p') && strnEQ(key, "proper", retlen)) {
		if (SvTRUE(arg_value)) flags |= MARPA_PROPER_SEPARATION;
		continue;
	    }
	    if ((*key == 's') && strnEQ(key, "separator", retlen)) {
		separator = SvIV(arg_value);
		continue;
	    }
	    croak("unknown argument to sequence_new(): %.*s", retlen, key);
	}
    }
    new_rule_id = marpa_sequence_new(g, lhs, rhs, separator, min, flags );
    if (new_rule_id < 0) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(new_rule_id) ) );

Marpa_Symbol_ID
rule_lhs( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_rule_lhs(g, rule_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

Marpa_Symbol_ID
rule_rhs( g, rule_id, ix )
    Grammar *g;
    Marpa_Rule_ID rule_id;
    unsigned int ix;
CODE:
    RETVAL = marpa_rule_rh_symbol(g, rule_id, ix);
    if (RETVAL < -1) { croak("Invalid call rule_rhs(%d, %u)", rule_id, ix); }
    if (RETVAL == -1) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

int
rule_length( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_rule_length(g, rule_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

void
rule_is_accessible( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_rule_is_accessible( g, rule_id );
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_productive( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_rule_is_productive( g, rule_id );
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_loop( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_rule_is_loop( g, rule_id );
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_virtual_loop( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_rule_is_virtual_loop( g, rule_id );
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

int
rule_virtual_start( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_virtual_start( g, rule_id );
    if (RETVAL <= -2) { croak("Invalid rule %d", rule_id); }
OUTPUT:
    RETVAL

int
rule_virtual_end( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_virtual_end( g, rule_id );
    if (RETVAL <= -2) { croak("Invalid rule %d", rule_id); }
OUTPUT:
    RETVAL

void
rule_is_used( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_rule_is_used( g, rule_id );
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_discard_separation( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_rule_is_discard_separation( g, rule_id );
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_virtual_lhs( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_rule_is_virtual_lhs( g, rule_id );
    if (result < 0) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
rule_is_virtual_rhs( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
PPCODE:
    { gint result = marpa_rule_is_virtual_rhs( g, rule_id );
    if (result == -1) { croak("Invalid rule %d", rule_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

Marpa_Rule_ID
real_symbol_count( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_real_symbol_count(g, rule_id);
OUTPUT:
    RETVAL

Marpa_Rule_ID
rule_original( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_rule_original(g, rule_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

Marpa_Rule_ID
semantic_equivalent( g, rule_id )
    Grammar *g;
    Marpa_Rule_ID rule_id;
CODE:
    RETVAL = marpa_rule_semantic_equivalent(g, rule_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

int
AHFA_item_count( g )
    Grammar *g;
CODE:
    RETVAL = marpa_AHFA_item_count(g );
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

Marpa_Rule_ID
AHFA_item_rule( g, item_id )
    Grammar *g;
    Marpa_AHFA_Item_ID item_id;
CODE:
    RETVAL = marpa_AHFA_item_rule(g, item_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

 # -1 is a valid return value, so -2 indicates an error
int
AHFA_item_position( g, item_id )
    Grammar *g;
    Marpa_AHFA_Item_ID item_id;
CODE:
    RETVAL = marpa_AHFA_item_position(g, item_id);
    if (RETVAL <= -2) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

int
AHFA_item_sort_key( g, item_id )
    Grammar *g;
    Marpa_AHFA_Item_ID item_id;
CODE:
    RETVAL = marpa_AHFA_item_sort_key(g, item_id);
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

 # -1 is a valid return value, and -2 indicates an error
Marpa_Symbol_ID
AHFA_item_postdot( g, item_id )
    Grammar *g;
    Marpa_AHFA_Item_ID item_id;
CODE:
    RETVAL = marpa_AHFA_item_postdot(g, item_id);
    if (RETVAL <= -2) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

int
AHFA_state_count( g )
    Grammar *g;
CODE:
    RETVAL = marpa_AHFA_state_count(g );
    if (RETVAL < 0) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

 # In scalar context, returns the count
void
AHFA_state_items( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    { gint count = marpa_AHFA_state_item_count(g, AHFA_state_id);
    if (count < 0) { croak("Invalid AHFA state %d", AHFA_state_id); }
    if (GIMME == G_ARRAY) {
        guint item_ix;
        EXTEND(SP, count);
        for (item_ix = 0; item_ix < count; item_ix++) {
	    Marpa_AHFA_Item_ID item_id
		= marpa_AHFA_state_item(g, AHFA_state_id, item_ix);
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
    const gint result = marpa_AHFA_state_transitions(g, AHFA_state_id, gint_array);
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
        XPUSHs( sv_2mortal( newSViv(gint_array->len) ) );
    }
    }

 # -1 is a valid return value, and -2 indicates an error
Marpa_AHFA_State_ID
AHFA_state_empty_transition( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
CODE:
    RETVAL = marpa_AHFA_state_empty_transition(g, AHFA_state_id);
    if (RETVAL <= -2) { XSRETURN_UNDEF; }
OUTPUT:
    RETVAL

void
AHFA_state_is_predict( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    { gint result = marpa_AHFA_state_is_predict( g, AHFA_state_id );
    if (result < 0) { croak("Invalid AHFA state %d", AHFA_state_id); }
    if (result) XSRETURN_YES;
    XSRETURN_NO;
    }

void
AHFA_state_leo_lhs_symbol( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    { gint result = marpa_AHFA_state_leo_lhs_symbol( g, AHFA_state_id );
    if (result < -1) { croak("Invalid AHFA state %d", AHFA_state_id); }
    if (result == -1) XSRETURN_UNDEF;
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

Marpa_Rule_ID
AHFA_completed_start_rule( g, AHFA_state_id )
    Grammar *g;
    Marpa_AHFA_State_ID AHFA_state_id;
PPCODE:
    { gint result = marpa_AHFA_completed_start_rule(g, AHFA_state_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < -1) { croak("Invalid AHFA state %d", AHFA_state_id); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
context( g, key )
    Grammar *g;
    char *key;
PREINIT:
    union marpa_context_value* value;
    const char *string;
PPCODE:
    value = marpa_g_context_value(g, key);
    if (!value) {
	XSRETURN_UNDEF;
    }
    string = MARPA_CONTEXT_STRING_VALUE(value);
    if (string) {
	XPUSHs( sv_2mortal( newSVpv( string, 0 ) ) );
	goto finished;
    }
    if (MARPA_IS_CONTEXT_INT(value)) {
	gint payload = MARPA_CONTEXT_INT_VALUE(value);
	XPUSHs( sv_2mortal( newSViv( payload ) ) );
    } else { XSRETURN_UNDEF; }
    finished: ;

char *error( g )
    Grammar *g;
CODE:
    RETVAL = (gchar*)marpa_g_error(g);
OUTPUT:
    RETVAL

void precompute( g )
    Grammar *g;
PPCODE:
    if  (marpa_precompute(g)) { XSRETURN_YES; }
    XSRETURN_NO;

MODULE = Marpa::XS        PACKAGE = Marpa::XS::Internal::R_C

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
    g_wrapper = INT2PTR(G_Wrapper *, tmp);
    g = g_wrapper->g;
    r = marpa_r_new(g);
    if (!r) { XSRETURN_UNDEF; }
    marpa_r_message_callback_set( r, &xs_r_message_callback );
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
    {
       SV *sv = marpa_r_message_callback_arg(r);
	marpa_r_message_callback_arg_set( r, NULL );
       if (sv) { SvREFCNT_dec(sv); }
    }
    g_array_free(r_wrapper->gint_array, TRUE);
    marpa_r_free( r );
    SvREFCNT_dec(g_sv);
    Safefree( r_wrapper );

 # Note the Perl callback closure
 # is, in the libmarpa context, the *ARGUMENT* of the callback,
 # not the callback itself.
 # The libmarpa callback is a wrapper
 # that calls the Perl closure.
void
message_callback_set( r_wrapper, sv )
    R_Wrapper *r_wrapper;
    SV *sv;
PPCODE:
    {
       struct marpa_r* r = r_wrapper->r;
       SV *old_sv = marpa_r_message_callback_arg(r);
       if (old_sv) {
       SvREFCNT_dec(old_sv); }
	marpa_r_message_callback_arg_set( r, sv );
	SvREFCNT_inc(sv);
    }

Marpa_Recognizer_ID
id( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = marpa_r_id(r_wrapper->r);
OUTPUT:
    RETVAL

 # Someday replace this with a function which translates the
 # error
char *error( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = (gchar*)marpa_r_error(r_wrapper->r);
OUTPUT:
    RETVAL

char *raw_error( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = (gchar*)marpa_r_error(r_wrapper->r);
OUTPUT:
    RETVAL

char *
phase( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    Marpa_Phase phase = marpa_phase(r_wrapper->r);
    RETVAL = "unknown";
    switch(phase) {
    case no_such_phase: RETVAL = "undefined"; break;
    case initial_phase: RETVAL = "initial"; break;
    case input_phase: RETVAL = "read"; break;
    case evaluation_phase: RETVAL = "evaluation"; break;
    case error_phase: RETVAL = "error"; break;
    }
OUTPUT:
    RETVAL

Marpa_Earleme
current_earleme( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = marpa_current_earleme(r_wrapper->r);
OUTPUT:
    RETVAL

Marpa_Earleme
furthest_earleme( r_wrapper )
    R_Wrapper *r_wrapper;
CODE:
    RETVAL = marpa_furthest_earleme(r_wrapper->r);
OUTPUT:
    RETVAL

void
is_use_leo_set( r_wrapper, boolean )
    R_Wrapper *r_wrapper;
    int boolean;
PPCODE:
{
  struct marpa_r *r = r_wrapper->r;
  gboolean result = marpa_is_use_leo_set (r, (boolean ? TRUE : FALSE));
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
     gint boolean = marpa_is_use_leo( r );
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
     gint boolean = marpa_is_exhausted( r );
     if (boolean < 0) { 
	 croak("Problem in is_exhausted(): %s", marpa_r_error(r)); }
    if (boolean) XSRETURN_YES;
    XSRETURN_NO;
    }

void
start_input( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { gboolean result = marpa_start_input(r_wrapper->r);
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

 # current earleme on success -- return that directly
 # -1 means rejected because unexpected -- return undef
 # -3 means rejected as duplicate -- return that directly
 #      because Perl can do better error message for this
 # -2 means some other failure -- call croak
void
alternative( r_wrapper, symbol_id, length )
    R_Wrapper *r_wrapper;
    Marpa_Symbol_ID symbol_id;
    int length;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint result =
	marpa_alternative (r, symbol_id, length);
      if (result == -1)
	{
	  XSRETURN_UNDEF;
	}
      if (result < 0 && result != -3)
	{
	  croak ("Invalid alternative: %s", marpa_r_error (r));
	}
      XPUSHs (sv_2mortal (newSViv (result)));
    }

void
earley_item_warning_threshold_set( r_wrapper, too_many_earley_items )
    R_Wrapper *r_wrapper;
    unsigned int too_many_earley_items;
PPCODE:
    { gboolean result = marpa_earley_item_warning_threshold_set(r_wrapper->r, too_many_earley_items);
    if (result) XSRETURN_YES;
    }
    XSRETURN_NO;

void
too_many_earley_items( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { guint too_many_earley_items = marpa_earley_item_warning_threshold( r_wrapper->r );
    XPUSHs( sv_2mortal( newSViv(too_many_earley_items) ) );
    }

void
latest_earley_set( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint latest_earley_set = marpa_latest_earley_set(r);
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
      gint earley_set_size = marpa_earley_set_size (r, set_ordinal);
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
    Marpa_AHFA_State_ID result = marpa_earley_set_trace(
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
    Marpa_AHFA_State_ID result = marpa_earley_item_trace(
	r, item_ordinal);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) { croak("problem with r->earley_item_trace: %s", marpa_r_error(r)); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
old_earley_item_trace( r_wrapper, origin, ahfa_id )
    R_Wrapper *r_wrapper;
    Marpa_Earleme origin;
    Marpa_AHFA_State_ID ahfa_id;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    Marpa_AHFA_State_ID result = marpa_old_earley_item_trace(r, origin, ahfa_id);
    if (result == -1) { XSRETURN_UNDEF; }
    if (result < 0) { croak("Trace earley item problem: %s", marpa_r_error(r)); }
    XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
earley_item_origin( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    {
      struct marpa_r *r = r_wrapper->r;
      gint origin_earleme = marpa_earley_item_origin (r);
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
    gint token_id = marpa_first_token_link_trace(r);
    if (token_id <= -2) { croak("Trace first token link problem: %s", marpa_r_error(r)); }
    if (token_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(token_id) ) );
    }

void
next_token_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint token_id = marpa_next_token_link_trace(r);
    if (token_id <= -2) { croak("Trace next token link problem: %s", marpa_r_error(r)); }
    if (token_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(token_id) ) );
    }

void
first_completion_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint AHFA_state_id = marpa_first_completion_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace first completion link problem: %s", marpa_r_error(r)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
next_completion_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint AHFA_state_id = marpa_next_completion_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace next completion link problem: %s", marpa_r_error(r)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
first_leo_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint AHFA_state_id = marpa_first_leo_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace first completion link problem: %s", marpa_r_error(r)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
next_leo_link_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint AHFA_state_id = marpa_next_leo_link_trace(r);
    if (AHFA_state_id <= -2) { croak("Trace next completion link problem: %s", marpa_r_error(r)); }
    if (AHFA_state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(AHFA_state_id) ) );
    }

void
source_predecessor_state( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint state_id = marpa_source_predecessor_state(r);
    if (state_id <= -2) { croak("Problem finding trace source predecessor state: %s", marpa_r_error(r)); }
    if (state_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(state_id) ) );
    }

void
source_leo_transition_symbol( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint symbol_id = marpa_source_leo_transition_symbol(r);
    if (symbol_id <= -2) { croak("Problem finding trace source leo transition symbol: %s", marpa_r_error(r)); }
    if (symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(symbol_id) ) );
    }

void
source_middle( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint middle = marpa_source_middle(r);
    if (middle <= -2) { croak("Problem with r->source_middle(): %s", marpa_r_error(r)); }
    if (middle == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(middle) ) );
    }

void
first_postdot_item_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint postdot_symbol_id = marpa_first_postdot_item_trace(r);
    if (postdot_symbol_id <= -2) { croak("Trace first postdot item problem: %s", marpa_r_error(r)); }
    if (postdot_symbol_id == -1) { XSRETURN_UNDEF; }
    XPUSHs( sv_2mortal( newSViv(postdot_symbol_id) ) );
    }

void
next_postdot_item_trace( r_wrapper )
    R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
    gint postdot_symbol_id = marpa_next_postdot_item_trace(r);
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
    gint postdot_symbol_id = marpa_postdot_symbol_trace(r, symid);
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
      gint leo_base_state = marpa_leo_base_state (r);
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
      gint leo_base_origin = marpa_leo_base_origin (r);
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
      gint leo_expansion_ahfa = marpa_leo_expansion_ahfa(r);
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
      gint trace_earley_set = marpa_trace_earley_set (r);
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
      gint postdot_item_symbol = marpa_postdot_item_symbol (r);
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
      gint leo_predecessor_symbol = marpa_leo_predecessor_symbol (r);
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
        gint count = marpa_terminals_expected(r, terminal_ids);
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
        Marpa_Earleme result = marpa_earleme_complete(r);
	if (result < 0) {
	  croak ("Problem in r->earleme_complete(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
earleme( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Earley_Set_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_earleme(r, ordinal);
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
	gint result = marpa_bocage_new(r, rule_id, ordinal);
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
	gint result = marpa_bocage_free(r);
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
	gint result = marpa_or_node_set(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_origin( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_or_node_origin(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_position( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_or_node_position(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_rule( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_or_node_rule(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_first_and( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_or_node_first_and(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_last_and( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_or_node_last_and(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
or_node_and_count( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_Or_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_or_node_and_count(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_count( r_wrapper )
     R_Wrapper *r_wrapper;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_and_node_count(r);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_parent( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_and_node_parent(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_predecessor( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_and_node_predecessor(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_cause( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_and_node_cause(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

void
and_node_symbol( r_wrapper, ordinal )
     R_Wrapper *r_wrapper;
     Marpa_And_Node_ID ordinal;
PPCODE:
    { struct marpa_r* r = r_wrapper->r;
	gint result = marpa_and_node_symbol(r, ordinal);
	if (result == -1) { XSRETURN_UNDEF; }
	if (result < 0) {
	  croak ("Problem in r->earleme(): %s", marpa_r_error (r));
	}
	XPUSHs( sv_2mortal( newSViv(result) ) );
    }

BOOT:
    gperl_handle_logs_for(G_LOG_DOMAIN);
