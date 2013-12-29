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
@ @<Public global data declarations@> =
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
@ @<Public global data declarations@> =
extern const struct marpa_event_description_s marpa_event_description[];

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
@ @<Public global data declarations@> =
extern const struct marpa_step_type_description_s
  marpa_step_type_description[];

@** SLIF Recognizer (SLR) code.
@ Make this pubic for now, until I have write
a proper method-based interface.
@<Public incomplete structures@> =
struct marpa_slr_s;
typedef struct marpa_slr_s* Marpa_SLR;
@ @<Private structures@> =
struct marpa_slr_s {
  MARPA_DSTACK_DECLARE(t_event_dstack);
  MARPA_DSTACK_DECLARE(t_lexeme_dstack);
  @<Int aligned SLR elements@>@;
  int t_count_of_deleted_events;
};
@ @<Private typedefs@> =
typedef Marpa_SLR SLR;

@**Events.
@<Public incomplete structures@> =
union marpa_slr_event_s;

@ @<Public macros@> =
#define MARPA_SLREV_TYPE(event) ((event)->t_header.t_event_type)

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

@ @<Function definitions@> =
Marpa_SLR marpa__slr_new(void)
{
    @<Return |NULL| on failure@>@;
    SLR slr;
    slr = marpa_malloc(sizeof(*slr));
    @<Initialize SLR elements@>@;
    return slr;
}

@ @<Initialize SLR elements@> =
{
  MARPA_DSTACK_INIT (slr->t_event_dstack, union marpa_slr_event_s,
                     MAX (1024 / sizeof (union marpa_slr_event_s), 16));
  slr->t_count_of_deleted_events = 0;
  MARPA_DSTACK_INIT (slr->t_lexeme_dstack, union marpa_slr_event_s,
                     MAX (1024 / sizeof (union marpa_slr_event_s), 16));
}

@*0 Reference counting and destructors.
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
   MARPA_DSTACK_DESTROY(slr->t_event_dstack);
   MARPA_DSTACK_DESTROY(slr->t_lexeme_dstack);
  marpa_free( slr);
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
@<Return |NULL| on failure@> = void* const failure_indicator = NULL;

@** File layouts.  
@ The .c file has no contents at the moment, so just in
case, I include a dummy function.  Once there are other contents,
it should be deleted.
@*0 The main code file.
@(marpa_slif.c.p10@> =

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#include "marpa.h"
#include "marpa_ami.h"
#include "marpa_slif.h"

@<Private macros@>@;
@<Private typedefs@>@;
@<Private structures@>@;

@ @(marpa_slif.c.p50@> =

@<Function definitions@>@;

@*0 The public header file.
@(marpa_slif.h.p50@> =

#ifndef _MARPA_SLIF_H__
#define _MARPA_SLIF_H__ 1

@<Public macros@>@;
@<Public incomplete structures@>@;
@<Public structures@>@;
@<Public global data declarations@>@;

#endif /* |_MARPA_SLIF_H__| */
@** Index.

% vim: expandtab shiftwidth=4:
