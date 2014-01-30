% Copyright 2014 Jeffrey Kegler
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

\def\title{Marpa: the program}
\def\topofcontents{\null\vfill
  \centerline{\titlefont Marpa: the program}
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
@s BITFIELD int
@s DAND int
@s MARPA_DSTACK int
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

@*0 About this document.
The document contains materials that do not describe the Marpa
algorithm in its latest form.
They are useful as background,
or for understanding why Marpa has changed in the way it has.

@*0 The Aycock-Horspool finite automata.

Most of the material in this document describes the behavior of
Marpa when it used the states of
the Aycock-Horspool finite automaton.
This material includes statistics, and some carefully worked
out math.
While not relevant to the current version of Marpa,
it may be useful for anyone else wanting to experiment with
the use of LR states in Earley items.

@*0 Some statistics on AHFA states.

@*1 Discovered states.

@ For Perl's grammar, the discovered states range in size from 1 to 20 items,
but the numbers are heavily skewed toward the low
end.  Here are the item counts that appear, with the percent of the total
discovered AHFA states with that item count in parentheses.
in parentheses:
\par
\vskip\baselineskip
\vbox{\offinterlineskip
\halign{&#&
  \strut\quad\hfil#\quad\cr
&\omit&&\omit&\cr
&Size\hfil&&Perl discovered&\cr\
&&&states (percent)\hfil&\cr\
&\omit&&\omit&\cr
&1&&67.05\%&\cr
&2&&25.67\%\cr
&3&&2.87\%\cr
&4&&2.68\%\cr
&5&&0.19\%\cr
&6&&0.38\%\cr
&7&&0.19\%\cr
&8&&0.57\%\cr
&9&&0.19\%\cr
&20&&0.19\%\cr
&\omit&&\omit&\cr}
}
\vskip\baselineskip
\par
As can be seen, well over 90\% of the total discovered states have
just one or two items.
The average size is 1.5235,
and the average of the $|size|^2$ is 3.9405.

@ For HTML, I looked at a parser which generates grammars on
the fly, aggregating the states in all of them.
For the the HTML grammars I used, the totals are even more lopsided:
80.96\% of all discovered states have only 1 item.
All the others (19.04\%) have 2 items.
The average size is 1.1904,
and the average of the $|size|^2$ is 1.5712.

@ For a compiler-quality C grammar,
the discovered states range in size from 1 to 15 items but again,
the numbers are heavily skewed toward the low
end.  Here are the item counts that appear, with the percent of the total
discovered AHFA states with that item count in parentheses.
in parentheses:
\par
\vskip\baselineskip
\vbox{\offinterlineskip
\halign{&#&
  \strut\quad\hfil#\quad\cr
&\omit&&\omit&\cr
&Size\hfil&&C discovered states&\cr\
&\omit&&\omit&\cr
&1&&695&\cr
&2&&188&\cr
&3&&40&\cr
&4&&17&\cr
&5&&6&\cr
&6&&8&\cr
&7&&6&\cr
&8&&4&\cr
&9&&1&\cr
&10&&2&\cr
&12&&2&\cr
&15&&1&\cr
&\omit&&\omit&\cr}
}
\vskip\baselineskip
\par
There were 970 discovered C states.
The average size was 1.52.
The average of the size squared was 3.98.

@*1 Predicted states.

@ The number of predicted states tends to be much more
evenly distributed.
It also tends to be much larger, and
the average for practical grammars may be $O(s)$,
where $s$ is the size of the grammar.
This is the same as the theoretical worst case.

@ Here are the number of items for predicted states for the Perl grammar.
Here in tabular form are the sizes most common sizes, in order of
decreasing frequency:
\par
\vskip\baselineskip
\vbox{\offinterlineskip
\halign{&#&
  \strut\quad\hfil#\quad\cr
&\omit&&\omit&\cr
&Size\hfil&&Frequency&\cr\
&\omit&&\omit&\cr
&2&&5&\cr
&3, 142&&4&\cr
&1, 4&&3&\cr
&6, 7, 143&&2&\cr
&\omit&&\omit&\cr}
}
\vskip\baselineskip
\par

In addition, the Perl grammar had exactly one predicted state of
the following sizes:
5,
64,
71,
77,
79,
81,
83,
85,
88,
90,
98,
100,
102,
104,
106,
108,
111,
116,
127,
129,
132,
135,
136,
137,
141,
144,
149,
151,
156,
157,
220,
224, and
225.

@ The number of predicted states in the Perl grammar was 58.
The average size was 83.59 AHFA items.
The average of the size squared was 11356.41.

@ And here is the same data for the collection of HTML grammars:
\par
\vskip\baselineskip
\vbox{\offinterlineskip
\halign{&#&
  \strut\quad\hfil#\quad\cr
&\omit&&\omit&\cr
&Size\hfil&&HTML predicted states&\cr\
&\omit&&\omit&\cr
&1&&95&\cr
&2&&95&\cr
&4&&95&\cr
&11&&181&\cr
&14&&181&\cr
&15&&294&\cr
&16&&112&\cr
&18&&349&\cr
&19&&120&\cr
&20&&190&\cr
&21&&63&\cr
&22&&22&\cr
&24&&8&\cr
&25&&16&\cr
&26&&16&\cr
&28&&2&\cr
&29&&16&\cr
&\omit&&\omit&\cr}
}
\vskip\baselineskip

@
The total number of predicted states in the HTML grammars was 1855.
Their average size was 14.60.
Their average size squared was 250.93.

@ The number of predicted states in the C grammar was 114.
The average size was 54.81.
The average size squared was 5361.28.
The sizes of the predicted states for the C grammar were spread from 1 
to 222.
\li The most frequent sizes were 2 and 3, tied at
six states each.
\li There were five states of size 8.
\li There were four states in each of the sizes 4 and 90.
\li There were three states in each of the following sizes:
      6, 11, 31, and 47
\li There were two states in each of the following sizes:
           5, 14, 42, 64, 68, 78, 91, 95, and 98.
\li There was a single state of each of the following sizes:
     1, 7, 9, 12, 15, 17, 18, 19, 21, 22, 25, 28, 29, 33, 34, 36,
    37, 40, 43, 44, 45, 46, 52, 53, 54, 57, 58, 61, 65, 66, 69, 72,
    74, 76, 80, 81, 86, 87, 89, 94, 96, 97, 99, 102, 105, 108,
   115, 117, 119, 123, 125, 127, 144, 149, 150, 154, 181, 219,
   and 222.


@*0 Statistics on completed LHS symbols per AHFA state.
An AHFA state may contain completions for more than one LHS,
but that is rare in practical use, and the number of completed
LHS symbols in the exceptions remains low.
The very complex Perl AHFA contains 271 states with completions.
Of these 268 have only one completed symbol.
The other three AHFA states complete only two different LHS symbols.
Two states have completions with both
a |term_hi| and a |indirob| on the LHS.
One state has completions for both a
|sideff| and an |mexpr|.
@ My HTML test grammars make the
same point more strongly.
My HTML parser generates grammars on the fly.
These HTML grammars can differ from each other.
because Marpa takes the HTML input into account when
generating the grammar.
In my HTML test suite,
every single one
of the 14,782 AHFA states
has only one completed LHS symbol.

@*0 CHAF duplicate and-nodes.
When AHFA's were in use,
there were three ways in which the same and-node can occur multiple
times as the descendant of a single or-node.
@ First, an or-node can have several different Earley items as
its source.  This is dealt with by noticing that in building the
or-node, we only use the source links of an Earley item, and
that these are always identical.  Therefore we can arbitrarily
select any one of the possible source Earley items to be
the or-node's ``unique" Earley item source.
@ The second source of duplication is duplicate source links
for the same Earley item.
I prevent token source links from duplicating,
and the Leo logic does not allow duplicate Leo source links.
@ Completion source links could be prevented from duplicating by
making the transition symbol part of its ``signature",
and making sure the source link transition symbol matches
the predot symbol of the or-node.
This would only impose a small overhead.
But given that I need to look for duplicates from other
sources, there does not seem to enough of a payoff to justify
even a small overhead.
@ A third source of duplication occurs
when different source links
have different AHFA states in their predecessors; but
share the the same AHFA item.
There will be
pairs of these source links which share the same middle earleme,
because if an AHFA item (dotted rule) in one is justified at a
location, the same AHFA item in the other must be, also.
This happens frequently enough to be an issue even for practical
grammars.

@*0 Sources of Leo path items.
A Leo path consists of a series of Earley items:
\li at the bottom, exactly one Leo base item;
\li at the top, exactly one Leo completion item;
\li in between, zero or more Leo path items.
@ Leo base items and Leo completion items can have a variety
of non-Leo sources.
Leo completion items can have multiple Leo sources,
though no other source can have the same middle earleme
as a Leo source.
@ When expanded, Leo path items can have multiple sources.
However, the sources of a single Leo path item
will result from the same Leo predecessor.
As consequences:
\li All the sources of an expanded Leo path item will have the same
Earley item predecessor,
the Leo base item of the Leo predecessor.
\li All these sources will also have the same middle
earleme, the Earley set of the Leo predecessor.
\li Every source of the Leo path item will have a cause
and the transition symbol of the Leo predecessor
will be on the LHS of at least one completion in all of those causes.
\li The Leo transition symbol will be the postdot symbol in exactly
one AHFA item in the AHFA state of the Earley item predecessor.

@*0 Relationship of Earley items to or-nodes.
Several Earley items may be the source of the same or-node,
but the or-node only keeps track of one.  This is sufficient,
because the Earley item is tracked by the or-node only for its
links and,
by the following theorem,
the links for every Earley item which is the source
of the same or-node must be the same.

@ {\bf Theorem}: If two Earley items are sources of the same or-node,
they have the same links.
{\bf Outline of Proof}:
No or-node results from a predicted Earley
item, so every Earley item which is the source of an or-node
is itself the result of a transition over a symbol from
another Earley item.  
So I can restrict my discussion to discovered Earley items.
For the same reason, I can assume all source links have
predecessors defined.

@ {\bf Shared Predot Lemma}: An AHFA state is either predicted,
or all its LR0 items share the same predot symbol.
{\bf Proof}:  Straightforward, based on the construction of
an AHFA.

@ {\bf YIM Lemma }: If two Earley items are sources of the same or-node,
they share the same origin YS, the same current YS and the same
predot symbol.
{\bf Proof of Lemma}:
Showing that the Earley items share the same origin and current
YS is straightforward, based on the or-node's construction.
They share at least one LR0 item in their AHFA states ---
the LR0 item which defines the or-node.
Because they share at least one LR0 item and because, by the
Shared Predot Lemma, every LR0
item in a discovered AHFA state has the same predot symbol,
the two Earley items also
share the same predot symbol.

@ {\bf Completion Source Lemma}:
A discovered Earley item has a completion source link if and only if
the origin YS of the link's predecessor,
the current YS of the link's cause
and the transition symbol match, respectively,
the origin YS, current YS and predot symbol of the discovered YIM.
{\bf Proof}: Based on the construction of YIMs.

@ {\bf Token Source Lemma}:
A discovered Earley item has a token source link if and only if
origin YS of the link's predecessor, the current YS of the link's cause
and the token symbol match, respectively,
the origin YS, current YS and predot symbol of the discovered YIM.
{\bf Proof}: Based on the construction of YIMs.

@ Source links are either completion source links or token source links.
The theorem for completion source links follows from the YIM Lemma and the
Completion Source Lemma.
The theorem for token source links follows from the YIM Lemma and the
Token Source Lemma.
{\bf QED}.

