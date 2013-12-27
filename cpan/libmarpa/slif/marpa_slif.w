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

\def\title{Marpa's ami tools}
\def\topofcontents{\null\vfill
  \centerline{\titlefont Marpa's Scanless interface (SLIF)}
  \vfill}
\def\botofcontents{\vfill
\noindent
@i copyright_page_license.w
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
@i copyright_page_license.w

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
@<Body of public header file@> =
struct s_marpa_error_description
{
  Marpa_Error_Code error_code;
  const char *name;
  const char *suggested;
};
extern const struct s_marpa_error_description marpa_error_description[];

@** Event description structure.
@ Keeps data for mapping back and forth between event code,
on one hand,
and its name and long form description,
on the other..
@<Body of public header file@> =
struct s_marpa_event_description
{
  Marpa_Event_Type event_code;
  const char *name;
  const char *suggested;
};
extern const struct s_marpa_event_description marpa_event_description[];

@** Step type description structure.
@ Keeps data for mapping back and forth between
evaluation step code,
on one hand,
and its name,
on the other.

@<Body of public header file@> =
struct s_marpa_step_type_description
{
  Marpa_Step_Type step_type;
  const char *name;
};
extern const struct s_marpa_step_type_description
  marpa_step_type_description[];

@** File layouts.  
@ The .c file has no contents at the moment, so just in
case, I include a dummy function.  Once there are other contents,
it should be deleted.
@*0 The main code file.
@(marpa_slif.c.p10@> =

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#include "marpa_slif.h"
#include "marpa_int.h"

@<Private macros@>@;

@ @(marpa_slif.c.p50@> =

int marpa__slif_dummy(void);
int marpa__slif_dummy(void) { return 1 ; }

@*0 The public header file.
@(marpa_slif.h.p50@> =

#ifndef _MARPA_SLIF_H__
#define _MARPA_SLIF_H__ 1

#include "marpa.h"

@<Body of public header file@>@;

#endif /* |_MARPA_SLIF_H__| */
@** Index.

% vim: expandtab shiftwidth=4:
