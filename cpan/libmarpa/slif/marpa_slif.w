% Copyright 2013 Jeffrey Kegler
% This file is part of Marpa::R2.  Marpa::R2 is free software: you can
% redistribute it and/or modify it under the terms of the GNU Lesser
% General Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later version.
%
% Marpa::R2 is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser
% General Public License along with Marpa::R2.  If not, see
% http://www.gnu.org/licenses/.

\def\li{\item{$\bullet$}}

% Here is TeX material that gets inserted after \input cwebmac
\def\hang{\hangindent 3em\indent\ignorespaces}
\def\pb{$\.|\ldots\.|$} % C brackets (|...|)
\def\v{\char'174} % vertical (|) in typewriter font
\def\dleft{[\![} \def\dright{]\!]} % double brackets
\mathchardef\RA="3221 % right arrow
\mathchardef\BA="3224 % double arrow
\def\({} % ) kludge for alphabetizing certain section names
\def\TeXxstring{\\{\TEX/\_string}}
\def\skipxTeX{\\{skip\_\TEX/}}
\def\copyxTeX{\\{copy\_\TEX/}}

\let\K=\Longleftarrow

\secpagedepth=1

\def\title{Marpa's Scanless interface}
\def\topofcontents{\null\vfill
  \centerline{\titlefont Marpa's Scanless interface (SLIF)}
  \vfill}
\def\botofcontents{\vfill
\noindent
@i ../shared/copyright_page_license.w
\bigskip
\leftline{\sc\today\ at \hours} % timestamps the contents page
}
% \datecontentspage

\pageno=\contentspagenumber \advance\pageno by 1
\let\maybe=\iftrue

\def\marpa_sub#1{{\bf #1}: }
\def\libmarpa/{{\tt libmarpa}}
\def\QED/{{\bf QED}}
\def\Theorem/{{\bf Theorem}}
\def\Proof/{{\bf Theorem}}
\def\size#1{\v #1\v}
\def\gsize{\v g\v}
\def\wsize{\v w\v}
\def\comment{\vskip\baselineskip}

@q Unreserve the C++ keywords @>
@s asm normal
@s dynamic_cast normal
@s namespace normal
@s reinterpret_cast normal
@s try normal
@s bool normal
@s explicit normal
@s new normal
@s static_cast normal
@s typeid normal
@s catch normal
@s false normal
@s operator normal
@s template normal
@s typename normal
@s class normal
@s friend normal
@s private normal
@s this normal
@s using normal
@s const_cast normal
@s public normal
@s throw normal
@s virtual normal
@s delete normal
@s mutable normal
@s protected normal
@s true normal
@s wchar_t normal
@s and normal
@s bitand normal
@s compl normal
@s not_eq normal
@s or_eq normal
@s xor_eq normal
@s and_eq normal
@s bitor normal
@s not normal
@s or normal
@s xor normal

@s error normal
@s MARPA_AVL_TRAV int
@s MARPA_AVL_TREE int
@s Bit_Matrix int
@s DAND int
@s DSTACK int
@s LBV int
@s Marpa_Bocage int
@s Marpa_IRL_ID int
@s Marpa_Rule_ID int
@s Marpa_Symbol_ID int
@s NOOKID int
@s NOOK_Object int
@s OR int
@s PIM int
@s PRIVATE int
@s PRIVATE_NOT_INLINE int
@s PSAR int
@s PSAR_Object int
@s PSL int
@s RULE int
@s RULEID int
@s XRL int

@** License.
\bigskip\noindent
@i ../shared/copyright_page_license.w

@** Introduction.
@*0 About this library.
This is Marpa's scanless interface (SLIF) library.
It is an upper layer for Libmarpa.

@*0 About this document.
This document is very much under construction,
enough so that readers may question why I make it
available at all.  Two reasons:
\li Despite its problems, it is the best way to read the source code
at this point.
\li Since it is essential to changing the code, not making it available
could be seen to violate the spirit of the open source.

@*0 Inlining.
Most of this code in |libmarpa|
will be frequently executed.
Inlining is used a lot.
Enough so
that it is useful to define a macro to let me know when inlining is not
used in a private function.
@s PRIVATE_NOT_INLINE int
@s PRIVATE int
@<Private macros@> =
#define PRIVATE_NOT_INLINE static
#define PRIVATE static inline

@** Error description structure.
@ Keeps data for mapping back and forth between error code,
on one hand,
and its name and long form description,
on the other.
@<Public incomplete structures@> =
struct marpa_error_description_s;
@ @<Public structures@> =
struct marpa_error_description_s
{
  Marpa_Error_Code error_code;
  const char *name;
  const char *suggested;
};
@ @<Public constant declarations@> =
extern const struct marpa_error_description_s marpa_error_description[];

@** Event description structure.
@ Keeps data for mapping back and forth between event code,
on one hand,
and its name and long form description,
on the other..
@<Public incomplete structures@> =
struct marpa_event_description_s;
@ @<Public structures@> =
struct marpa_event_description_s
{
  Marpa_Event_Type event_code;
  const char *name;
  const char *suggested;
};
@ @<Public constant declarations@> =
extern const struct marpa_event_description_s marpa_event_description[];

@** Codepoints.

@ @<Public typedefs@> = 
typedef unsigned int Marpa_Codepoint;

@** Step type description structure.
@ Keeps data for mapping back and forth between
evaluation step code,
on one hand,
and its name,
on the other.
@<Public incomplete structures@> =
struct marpa_step_type_description_s;
@ @<Public structures@> =
struct marpa_step_type_description_s
{
  Marpa_Step_Type step_type;
  const char *name;
};
@ @<Public constant declarations@> =
extern const struct marpa_step_type_description_s
  marpa_step_type_description[];

@** The SLIF Recognizer (SLR).
@ Make this pubic for now, until I have write
a proper method-based interface.
@<Public incomplete structures@> =
struct marpa_slr_s;
typedef struct marpa_slr_s* Marpa_SLR;
@ @<Private structures@> =
struct marpa_slr_s {
  @<Widely aligned SLR elements@>@;
  @<Int aligned SLR elements@>@;
  int t_count_of_deleted_events;
};
@ @<Private typedefs@> =
typedef Marpa_SLR SLR;

@** SLR Constructor.

@ @<Function definitions@> =
Marpa_SLR marpa__slr_new(void)
{
    @<Return |NULL| on failure@>@;
    SLR slr;
    slr = my_malloc(sizeof(*slr));
    @<Initialize SLR elements@>@;
    return slr;
}

@** SLR Reference counting and destructors.
@ @<Int aligned SLR elements@>= int t_ref_count;

@ @<Initialize SLR elements@> =
slr->t_ref_count = 1;

@ Decrement the SLR reference count.
@<Function definitions@> =
PRIVATE void
slr_unref (Marpa_SLR slr)
{
  MARPA_ASSERT (slr->t_ref_count > 0)
  slr->t_ref_count--;
  if (slr->t_ref_count <= 0)
    {
      slr_free(slr);
    }
}
void
marpa__slr_unref (Marpa_SLR slr)
{
   slr_unref(slr);
}

@ Increment the SLR reference count.
@<Function definitions@> =
PRIVATE SLR
slr_ref (SLR slr)
{
  MARPA_ASSERT(slr->t_ref_count > 0)
  slr->t_ref_count++;
  return slr;
}

Marpa_SLR
marpa__slr_ref (Marpa_SLR slr)
{
   return slr_ref(slr);
}

@ @<Function definitions@> =
PRIVATE void slr_free(SLR slr)
{
    @<Destroy SLR elements@>@;
  my_free( slr);
}

@** Operations.
Small virtual machines are used in various places,
and their operations are kept in a single list.
This seems to make sense while they overlap heavily
and there are few of them.

@ @<Public typedefs@> = 
typedef int Marpa_Op;

@ @<Private structures@> =
struct op_data_s { const char *name; Marpa_Op op; };

@ For the moment these are internal, and the args are assumed to
be valid data.
@<Function definitions@> =
const char*
marpa__slif_op_name (Marpa_Op op_id)
{
  if (op_id >= (int)Dim(op_name_by_id_object)) return "unknown";
  return op_name_by_id_object[op_id];
}

Marpa_Op
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

@** Per-codepoint data.

@ @<Private structures@> =
struct per_codepoint_data_s {
    Marpa_Codepoint t_codepoint;
    Marpa_Op t_ops[1];
};

@ @<Function definitions@> =
PRIVATE int
cmp_per_codepoint_key( const void* a, const void* b, void* param UNUSED)
{
    const Marpa_Codepoint codepoint_a = ((struct per_codepoint_data_s*)a)->t_codepoint;
    const Marpa_Codepoint codepoint_b = ((struct per_codepoint_data_s*)b)->t_codepoint;
    if (codepoint_a == codepoint_b) return 0;
    return codepoint_a < codepoint_b ? -1 : 1;
}

@ @<Widely aligned SLR elements@> =
   struct tavl_table* t_per_codepoint_tavl;

@ @<Initialize SLR elements@> =
{
   slr->t_per_codepoint_tavl = marpa__tavl_create(cmp_per_codepoint_key, NULL);
}

@ @<Function definitions@> =
PRIVATE void
per_codepoint_data_destroy(void *p, void* param UNUSED)
{
    my_free(p);
}

@ @<Destroy SLR elements@> =
{
    marpa__tavl_destroy (slr->t_per_codepoint_tavl, per_codepoint_data_destroy);
}

@** Events.
@<Public incomplete structures@> =
union marpa_slr_event_s;

@
@d MARPA_SLREV_AFTER_LEXEME 1
@d MARPA_SLREV_BEFORE_LEXEME 2
@d MARPA_SLREV_LEXER_RESTARTED_RECCE 4
@d MARPA_SLREV_MARPA_R_UNKNOWN 5
@d MARPA_SLREV_NO_ACCEPTABLE_INPUT 6
@d MARPA_SLREV_SYMBOL_COMPLETED 7
@d MARPA_SLREV_SYMBOL_NULLED 8
@d MARPA_SLREV_SYMBOL_PREDICTED 9
@d MARPA_SLRTR_AFTER_LEXEME 10
@d MARPA_SLRTR_BEFORE_LEXEME 11
@d MARPA_SLRTR_CHANGE_LEXERS 12
@d MARPA_SLRTR_CODEPOINT_ACCEPTED 13
@d MARPA_SLRTR_CODEPOINT_READ 14
@d MARPA_SLRTR_CODEPOINT_REJECTED 15
@d MARPA_SLRTR_LEXEME_DISCARDED 16
@d MARPA_SLRTR_G1_ACCEPTED_LEXEME 17
@d MARPA_SLRTR_G1_ATTEMPTING_LEXEME 18
@d MARPA_SLRTR_G1_DUPLICATE_LEXEME 19
@d MARPA_SLRTR_LEXEME_REJECTED 20
@d MARPA_SLRTR_LEXEME_IGNORED 21
@d MARPA_SLREV_DELETED 22
@d MARPA_SLRTR_LEXEME_ACCEPTABLE 23
@d MARPA_SLRTR_LEXEME_OUTPRIORITIZED 24

@d MARPA_SLREV_TYPE(event) ((event)->t_header.t_event_type)

@ @<Public structures@> =
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
    int t_start_of_lexeme;      /* start */
    int t_end_of_lexeme;        /* end */
    int t_lexeme;               /* lexeme */
    int t_current_lexer_ix;
  }
  t_trace_lexeme_rejected;

  struct
  {
    int event_type;
    int t_start_of_lexeme;      /* start */
    int t_end_of_lexeme;        /* end */
    int t_lexeme;               /* lexeme */
    int t_current_lexer_ix;
    int t_priority;
    int t_required_priority;
  } t_trace_lexeme_acceptable;

  struct
  {
    int event_type;
    int t_start_of_pause_lexeme;        /* start */
    int t_end_of_pause_lexeme;  /* end */
    int t_pause_lexeme;         /* lexeme */
  } t_trace_before_lexeme;

  struct
  {
    int event_type;
    int t_pause_lexeme;         /* lexeme */
  } t_before_lexeme;

  struct
  {
    int event_type;
    int t_start_of_lexeme;      /* start */
    int t_end_of_lexeme;        /* end */
    int t_lexeme;               /* lexeme */
  } t_trace_after_lexeme;

  struct
  {
    int event_type;
    int t_lexeme;               /* lexeme */
  } t_after_lexeme;

  struct
  {
    int event_type;
    int t_start_of_lexeme;      /* start */
    int t_end_of_lexeme;        /* end */
    int t_lexeme;               /* lexeme */
  }
  t_trace_attempting_lexeme;

  struct
  {
    int event_type;
    int t_start_of_lexeme;      /* start */
    int t_end_of_lexeme;        /* end */
    int t_lexeme;               /* lexeme */
  }
  t_trace_duplicate_lexeme;

  struct
  {
    int event_type;
    int t_start_of_lexeme;      /* start */
    int t_end_of_lexeme;        /* end */
    int t_lexeme;               /* lexeme */
    int t_current_lexer_ix;
  }
  t_trace_accepted_lexeme;

  struct
  {
    int event_type;
    int t_start_of_lexeme;      /* start */
    int t_end_of_lexeme;        /* end */
    int t_lexeme;               /* lexeme */
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

};

@ @<Widely aligned SLR elements@> =
  MARPA_DSTACK_DECLARE(t_event_dstack);
  MARPA_DSTACK_DECLARE(t_lexeme_dstack);

@ @<Initialize SLR elements@> =
{
  MARPA_DSTACK_INIT (slr->t_event_dstack, union marpa_slr_event_s,
                     MAX (1024 / sizeof (union marpa_slr_event_s), 16));
  slr->t_count_of_deleted_events = 0;
  MARPA_DSTACK_INIT (slr->t_lexeme_dstack, union marpa_slr_event_s,
                     MAX (1024 / sizeof (union marpa_slr_event_s), 16));
}

@ @<Destroy SLR elements@> =
{
   MARPA_DSTACK_DESTROY(slr->t_event_dstack);
   MARPA_DSTACK_DESTROY(slr->t_lexeme_dstack);
}

@ @<Function definitions@> =
void marpa__slr_event_clear( Marpa_SLR slr )
{
  MARPA_DSTACK_CLEAR (slr->t_event_dstack);
  slr->t_count_of_deleted_events = 0;
}

@ @<Function definitions@> =
int marpa__slr_event_count( Marpa_SLR slr )
{
  const int event_count = MARPA_DSTACK_LENGTH (slr->t_event_dstack);
  return event_count - slr->t_count_of_deleted_events;
}

@ @<Function definitions@> =
int marpa__slr_event_max_index( Marpa_SLR slr )
{
  return  MARPA_DSTACK_LENGTH (slr->t_event_dstack) - 1;
}

@ @<Function definitions@> =
union marpa_slr_event_s * marpa__slr_event_push( Marpa_SLR slr )
{
    return MARPA_DSTACK_PUSH(slr->t_event_dstack, union marpa_slr_event_s);
}

@ @<Function definitions@> =
union marpa_slr_event_s * marpa__slr_event_entry( Marpa_SLR slr, int i )
{
    return MARPA_DSTACK_INDEX (slr->t_event_dstack, union marpa_slr_event_s, i);
}

@ @<Function definitions@> =
void marpa__slr_lexeme_clear( Marpa_SLR slr )
{
  MARPA_DSTACK_CLEAR (slr->t_lexeme_dstack);
}

@ @<Function definitions@> =
int marpa__slr_lexeme_count( Marpa_SLR slr )
{
  return MARPA_DSTACK_LENGTH (slr->t_lexeme_dstack);
}

@ @<Function definitions@> =
union marpa_slr_event_s * marpa__slr_lexeme_push( Marpa_SLR slr )
{
    return MARPA_DSTACK_PUSH(slr->t_lexeme_dstack, union marpa_slr_event_s);
}

@ @<Function definitions@> =
union marpa_slr_event_s * marpa__slr_lexeme_entry( Marpa_SLR slr, int i )
{
    return MARPA_DSTACK_INDEX (slr->t_lexeme_dstack, union marpa_slr_event_s, i);
}

@** Error handling.  
@<Return |NULL| on failure@> = void* const failure_indicator UNUSED = NULL;

@** File layouts.  
@*0 The main code file.
@(marpa_slif.c.p10@> =

#include "config.h"

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#include "marpa_slif.h"
#include "marpa_ami.h"
#include "marpa_tavl.h"

@<Private macros@>@;
@<Private typedefs@>@;
@<Private structures@>@;

@ @(marpa_slif.c.p50@> =

@<Function definitions@>@;

@*0 The public header file.
@(marpa_slif.h.p50@> =

#ifndef _MARPA_SLIF_H__
#define _MARPA_SLIF_H__ 1

#include "marpa.h"

@h
@<Public typedefs@>@;
@<Public incomplete structures@>@;
@<Public structures@>@;
@<Public constant declarations@>@;

#endif /* |_MARPA_SLIF_H__| */
@** Index.

% vim: expandtab shiftwidth=4:
