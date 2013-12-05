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
  \centerline{\titlefont Marpa's ami tools}
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

@** About this library.
This is Marpa's ``ami'' or ``friend'' library, for macros
and functions which are useful for Libmarpa and its
``close friends''.
The contents of this library are considered ``undocumented'',
in the sense that
they are not documented for general use.
Specifically, the interfaces of these functions is subject
to radical change without notice,
and it is assumed that the safety of such changes can
be ensured by checking only Marpa itself and its ``close friend''
libraries.

A ``close friend'' library is one which is allowed
to rely on undocumented Libmarpa interfaces.
At this writing,
the only example of a ``close friend'' library is the Perl XS code which
interfaces libmarpa to Perl.

The ami interface and an internal interface differ in that
\li The ami interface must be useable in a situation where the Libmarpa
implementor does not have complete control over the namespace.
It can only create names which begin in |marpa_|, |_marpa_| or
one of its capitalization variants.
The internal interface can assume that no library will be included
unless the Libmarpa implementor decided it should be, so that most
names are available for his use.
\li The ami interface cannot use Libmarpa's error handling -- although
it can be part of the implementation of that error handlind.
The ami interface must be useable in a situation where another
error handling regime is in effect.

@** About this document.
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
@d PRIVATE_NOT_INLINE static
@d PRIVATE static inline

@*0 Marpa global Setup.

Marpa has no globals as of this writing.
For thread-safety, among other reasons,
I'll try to keep it that way.

@** Lightweight boolean vectors (LBV).
These macros and functions assume that the 
caller remembers the boolean vector's length.
They also take no precautions about trailing bits
in the last word.
Most operations do not need to.
When and if there are such operations,
it will be up to the caller to make sure that
the trailing bits are correct.
@d lbv_wordbits (sizeof(LBW)*8u)
@d lbv_lsb (1u)
@d lbv_msb (1u << (lbv_wordbits-1u))
@s LBV int
@<Friend typedefs@> =
typedef unsigned int LBW;
typedef LBW* LBV;

@ Given a number of bits, compute the size.
@<Function definitions@> =
PRIVATE int lbv_bits_to_size(int bits)
{
    return (bits+(lbv_wordbits-1))/lbv_wordbits;
}

@*0 Create an unitialized LBV on an obstack.
@<Function definitions@> =
PRIVATE Bit_Vector
lbv_obs_new (struct marpa_obstack *obs, int bits)
{
  int size = lbv_bits_to_size (bits);
  LBV lbv = marpa_obs_new (obs, LBW, size);
  return lbv;
}

@*0 Zero an LBV.
@<Function definitions@> =
PRIVATE Bit_Vector
lbv_zero (Bit_Vector lbv, int bits)
{
  int size = lbv_bits_to_size (bits);
  if (size > 0) {
      LBW *addr = lbv;
      while (size--) *addr++ = 0u;
  }
  return lbv;
}

@*0 Create a zeroed LBV on an obstack.
@<Function definitions@> =
PRIVATE Bit_Vector
lbv_obs_new0 (struct marpa_obstack *obs, int bits)
{
  LBV lbv = lbv_obs_new(obs, bits);
  return lbv_zero(lbv, bits);
}

@*0 Basic LBV operations.
@d lbv_w(lbv, bit) ((lbv)+((bit)/lbv_wordbits))
@d lbv_b(bit) (lbv_lsb << ((bit)%bv_wordbits))
@d lbv_bit_set(lbv, bit)
  (*lbv_w ((lbv), (bit)) |= lbv_b (bit))
@d lbv_bit_clear(lbv, bit)
  (*lbv_w ((lbv), (bit)) &= ~lbv_b (bit))
@d lbv_bit_test(lbv, bit)
  ((*lbv_w ((lbv), (bit)) & lbv_b (bit)) != 0U)

@*0 Clone an LBV onto an obstack.
@<Function definitions@> =
PRIVATE LBV lbv_clone(
  struct marpa_obstack* obs, LBV old_lbv, int bits)
{
  int size = lbv_bits_to_size (bits);
  const LBV new_lbv = marpa_obs_new (obs, LBW, size);
  if (size > 0) {
      LBW *from_addr = old_lbv;
      LBW *to_addr = new_lbv;
      while (size--) *to_addr++ = *from_addr++;
  }
  return new_lbv;
}

@*0 Fill an LBV with ones.
No special provision is made for trailing bits.
@<Function definitions@> =
PRIVATE LBV lbv_fill(
  LBV lbv, int bits)
{
  int size = lbv_bits_to_size (bits);
  if (size > 0) {
      LBW *to_addr = lbv;
      while (size--) *to_addr++ = ~((LBW)0);
  }
  return lbv;
}

@** Boolean vectors.
Marpa's boolean vectors are adapted from
Steffen Beyer's Bit-Vector package on CPAN.
This is a combined Perl package and C library for handling
boolean vectors.
Someone seeking a general boolean vector package should
look at Steffen's instead.
|libmarpa|'s boolean vectors are tightly tied in
with its own needs and environment.
@<Private typedefs@> =
typedef LBW Bit_Vector_Word;
typedef Bit_Vector_Word* Bit_Vector;
@ Some defines and constants
@d BV_BITS(bv) *(bv-3)
@d BV_SIZE(bv) *(bv-2)
@d BV_MASK(bv) *(bv-1)
@<Global variables@> =
static const unsigned int bv_wordbits = lbv_wordbits;
static const unsigned int bv_modmask = lbv_wordbits - 1u;
static const unsigned int bv_hiddenwords = 3;
static const unsigned int bv_lsb = lbv_lsb;
static const unsigned int bv_msb = lbv_msb;

@ Given a number of bits, compute the size.
@<Function definitions@> =
PRIVATE unsigned int bv_bits_to_size(unsigned int bits)
{
    return (bits+bv_modmask)/bv_wordbits;
}
@ Given a number of bits, compute the unused-bit mask.
@<Function definitions@> =
PRIVATE unsigned int bv_bits_to_unused_mask(unsigned int bits)
{
    unsigned int mask = bits & bv_modmask;
    if (mask) mask = (unsigned int) ~(~0uL << mask); else mask = (unsigned int) ~0uL;
    return(mask);
}

@*0 Create a boolean vector.
@ Always start with an all-zero vector.
Note this code is a bit tricky ---
the pointer returned is to the data.
This is offset from the |malloc|'d space,
by |bv_hiddenwords|.
@<Function definitions@> =
PRIVATE Bit_Vector bv_create(unsigned int bits)
{
    unsigned int size = bv_bits_to_size(bits);
    unsigned int bytes = (size + bv_hiddenwords) * sizeof(Bit_Vector_Word);
    unsigned int* addr = (Bit_Vector) my_malloc0((size_t) bytes);
    *addr++ = bits;
    *addr++ = size;
    *addr++ = bv_bits_to_unused_mask(bits);
    return addr;
}

@*0 Create a boolean vector on an obstack.
@ Always start with an all-zero vector.
Note this code is a bit tricky ---
the pointer returned is to the data.
This is offset from the |malloc|'d space,
by |bv_hiddenwords|.
@<Function definitions@> =
PRIVATE Bit_Vector
bv_obs_create (struct marpa_obstack *obs, unsigned int bits)
{
  unsigned int size = bv_bits_to_size (bits);
  unsigned int bytes = (size + bv_hiddenwords) * sizeof (Bit_Vector_Word);
  unsigned int *addr = (Bit_Vector) marpa_obs_alloc (obs, (size_t) bytes);
  *addr++ = bits;
  *addr++ = size;
  *addr++ = bv_bits_to_unused_mask (bits);
  if (size > 0) {
      Bit_Vector bv = addr;
      while (size--) *bv++ = 0u;
  }
  return addr;
}


@*0 Shadow a boolean vector.
Create another vector the same size as the original, but with
all bits unset.
@<Function definitions@> =
PRIVATE Bit_Vector bv_shadow(Bit_Vector bv)
{
    return bv_create(BV_BITS(bv));
}
PRIVATE Bit_Vector bv_obs_shadow(struct marpa_obstack * obs, Bit_Vector bv)
{
    return bv_obs_create(obs, BV_BITS(bv));
}

@*0 Clone a boolean vector.
Given a boolean vector, creates a new vector which is
an exact duplicate.
This call allocates a new vector, which must be |free|'d.
@<Function definitions@> =
PRIVATE
Bit_Vector bv_copy(Bit_Vector bv_to, Bit_Vector bv_from)
{
    unsigned int *p_to = bv_to;
    const unsigned int bits = BV_BITS(bv_to);
    if (bits > 0)
    {
        int count = BV_SIZE(bv_to);
	while (count--) *p_to++ = *bv_from++;
    }
    return(bv_to);
}

@*0 Clone a boolean vector.
Given a boolean vector, creates a new vector which is
an exact duplicate.
This call allocates a new vector, which must be |free|'d.
@<Function definitions@> =
PRIVATE
Bit_Vector bv_clone(Bit_Vector bv)
{
    return bv_copy(bv_shadow(bv), bv);
}

PRIVATE
Bit_Vector bv_obs_clone(struct marpa_obstack *obs, Bit_Vector bv)
{
    return bv_copy(bv_obs_shadow(obs, bv), bv);
}

@*0 Free a boolean vector.
@<Function definitions@> =
PRIVATE void bv_free(Bit_Vector vector)
{
    if (LIKELY(vector != NULL))
    {
	vector -= bv_hiddenwords;
	my_free(vector);
    }
}

@*0 Fill a boolean vector.
@<Function definitions@> =
PRIVATE void bv_fill(Bit_Vector bv)
{
    unsigned int size = BV_SIZE(bv);
    if (size <= 0) return;
    while (size--) *bv++ = ~0u;
    --bv;
    *bv &= BV_MASK(bv);
}

@*0 Clear a boolean vector.
@<Function definitions@> =
PRIVATE void bv_clear(Bit_Vector bv)
{
    unsigned int size = BV_SIZE(bv);
    if (size <= 0) return;
    while (size--) *bv++ = 0u;
}

@ This function "overclears" ---
it clears "too many bits".
It clears a prefix of the boolean vector faster
than an interval clear, at the expense of often
clearing more bits than were requested.
In some situations clearing the extra bits is OK.
@ @<Function definitions@> =
PRIVATE void bv_over_clear(Bit_Vector bv, unsigned int bit)
{
    unsigned int length = bit/bv_wordbits+1;
    while (length--) *bv++ = 0u;
}

@*0 Set a boolean vector bit.
@ @<Function definitions@> =
PRIVATE void bv_bit_set(Bit_Vector vector, unsigned int bit)
{
    *(vector+(bit/bv_wordbits)) |= (bv_lsb << (bit%bv_wordbits));
}

@*0 Clear a boolean vector bit.
@<Function definitions@> =
PRIVATE void bv_bit_clear(Bit_Vector vector, unsigned int bit)
{
    *(vector+(bit/bv_wordbits)) &= ~ (bv_lsb << (bit%bv_wordbits));
}

@*0 Test a boolean vector bit.
@<Function definitions@> =
PRIVATE int bv_bit_test(Bit_Vector vector, unsigned int bit)
{
    return (*(vector+(bit/bv_wordbits)) & (bv_lsb << (bit%bv_wordbits))) != 0u;
}

@*0 Test and set a boolean vector bit.
Ensure that a bit is set.
Return its previous value to the call,
so that the return value is 1 if the call had no effect,
zero otherwise.
@<Function definitions@> =
PRIVATE int
bv_bit_test_then_set (Bit_Vector vector, unsigned int bit)
{
  Bit_Vector addr = vector + (bit / bv_wordbits);
  unsigned int mask = bv_lsb << (bit % bv_wordbits);
  if ((*addr & mask) != 0u)
    return 1;
  *addr |= mask;
  return 0;
}

@*0 Test a boolean vector for all zeroes.
@<Function definitions@> =
PRIVATE
int bv_is_empty(Bit_Vector addr)
{
    unsigned int  size = BV_SIZE(addr);
    int r = 1;
    if (size > 0) {
        *(addr+size-1) &= BV_MASK(addr);
        while (r && (size-- > 0)) r = ( *addr++ == 0 );
    }
    return(r);
}

@*0 Bitwise-negate a boolean vector.
@<Function definitions@>=
PRIVATE void bv_not(Bit_Vector X, Bit_Vector Y)
{
    unsigned int size = BV_SIZE(X);
    unsigned int mask = BV_MASK(X);
    while (size-- > 0) *X++ = ~*Y++;
    *(--X) &= mask;
}

@*0 Bitwise-and a boolean vector.
@<Function definitions@>=
PRIVATE void bv_and(Bit_Vector X, Bit_Vector Y, Bit_Vector Z)
{
    unsigned int size = BV_SIZE(X);
    unsigned int mask = BV_MASK(X);
    while (size-- > 0) *X++ = *Y++ & *Z++;
    *(--X) &= mask;
}

@*0 Bitwise-or a boolean vector.
@<Function definitions@>=
PRIVATE void bv_or(Bit_Vector X, Bit_Vector Y, Bit_Vector Z)
{
    unsigned int size = BV_SIZE(X);
    unsigned int mask = BV_MASK(X);
    while (size-- > 0) *X++ = *Y++ | *Z++;
    *(--X) &= mask;
}

@*0 Bitwise-or-assign a boolean vector.
@<Function definitions@>=
PRIVATE void bv_or_assign(Bit_Vector X, Bit_Vector Y)
{
    unsigned int size = BV_SIZE(X);
    unsigned int mask = BV_MASK(X);
    while (size-- > 0) *X++ |= *Y++;
    *(--X) &= mask;
}

@*0 Scan a boolean vector.
@<Function definitions@>=
PRIVATE_NOT_INLINE
int bv_scan(Bit_Vector bv, unsigned int start,
                                    unsigned int* min, unsigned int* max)
{
    unsigned int  size = BV_SIZE(bv);
    unsigned int  mask = BV_MASK(bv);
    unsigned int  offset;
    unsigned int  bitmask;
    unsigned int  value;
    int empty;

    if (size == 0) return 0;
    if (start >= BV_BITS(bv)) return 0;
    *min = start;
    *max = start;
    offset = start / bv_wordbits;
    *(bv+size-1) &= mask;
    bv += offset;
    size -= offset;
    bitmask = (unsigned int)1 << (start & bv_modmask);
    mask = ~ (bitmask | (bitmask - (unsigned int)1));
    value = *bv++;
    if ((value & bitmask) == 0)
    {
        value &= mask;
        if (value == 0)
        {
            offset++;
            empty = 1;
            while (empty && (--size > 0))
            {
                if ((value = *bv++)) empty = 0; else offset++;
            }
            if (empty) return 0;
        }
        start = offset * bv_wordbits;
        bitmask = bv_lsb;
        mask = value;
        while (!(mask & bv_lsb))
        {
            bitmask <<= 1;
            mask >>= 1;
            start++;
        }
        mask = ~ (bitmask | (bitmask - 1));
        *min = start;
        *max = start;
    }
    value = ~ value;
    value &= mask;
    if (value == 0)
    {
        offset++;
        empty = 1;
        while (empty && (--size > 0))
        {
            if ((value = ~ *bv++)) empty = 0; else offset++;
        }
        if (empty) value = bv_lsb;
    }
    start = offset * bv_wordbits;
    while (! (value & bv_lsb))
    {
        value >>= 1;
        start++;
    }
    *max = --start;
    return 1;
}

@*0 Count the bits in a boolean vector.
@<Function definitions@>=
PRIVATE unsigned int
bv_count (Bit_Vector v)
{
  unsigned int start, min, max;
  unsigned int count = 0;
  for (start = 0; bv_scan (v, start, &min, &max); start = max + 2)
    {
      count += max - min + 1;
    }
    return count;
}

@** Boolean matrixes.
Marpa's boolean matrixes are implemented differently
from the matrixes in
Steffen Beyer's Bit-Vector package on CPAN,
but like Beyer's matrixes are build on that package.
Beyer's matrixes are a single boolean vector
which special routines index by row and column.
Marpa's matrixes are arrays of vectors.

Since there are ``hidden words" before the data
in each vectors, Marpa must repeat these for each
row of a vector.  Consequences:
\li Marpa matrixes use a few extra bytes per row of space.
\li Marpa's matrix pointers cannot be used as vectors.
\li Marpa's rows {\bf can} be used as vectors.
\li Marpa's matrix pointers point to the beginning of
the allocated space.  |Bit_Vector| pointers use trickery
and include ``hidden words" before the pointer.
@ Note that |typedef|'s for |Bit_Matrix|
and |Bit_Vector| are identical.
@s Bit_Matrix int
@ @<Private structures@> =
struct s_bit_matrix {
    int t_row_count;
    Bit_Vector_Word t_row_data[1];
};
typedef struct s_bit_matrix* Bit_Matrix;

@*0 Create a boolean matrix.
@ Here the pointer returned is the actual start of the
|malloc|'d space.
This is {\bf not} the case with vectors, whose pointer is offset for
the ``hidden words".
@<Function definitions@> =
PRIVATE Bit_Matrix matrix_buffer_create(void *buffer, unsigned int rows, unsigned int columns)
{
    unsigned int row;
    const unsigned int bv_data_words = bv_bits_to_size(columns);
    const unsigned int bv_mask = bv_bits_to_unused_mask(columns);

    Bit_Matrix matrix_addr = buffer;
    matrix_addr->t_row_count = rows;
    for (row = 0; row < rows; row++) {
	const unsigned int row_start = row*(bv_data_words+bv_hiddenwords);
	Bit_Vector_Word* p_current_word = matrix_addr->t_row_data + row_start;
	int data_word_counter = bv_data_words;
	*p_current_word++ = columns;
	*p_current_word++ = bv_data_words;
	*p_current_word++ = bv_mask;
	while (data_word_counter--) *p_current_word++ = 0;
    }
    return matrix_addr;
}

@*0 Size a boolean matrix in bytes.
@ @<Function definitions@> =
PRIVATE size_t matrix_sizeof(unsigned int rows, unsigned int columns)
{
    const unsigned int bv_data_words = bv_bits_to_size(columns);
    const unsigned int row_bytes = (bv_data_words + bv_hiddenwords) * sizeof(Bit_Vector_Word);
    return offsetof (struct s_bit_matrix, t_row_data) + (rows) * row_bytes;
}

@*0 Create a boolean matrix on an obstack.
@ @<Function definitions@> =
PRIVATE Bit_Matrix matrix_obs_create(
  struct marpa_obstack *obs,
  unsigned int rows,
  unsigned int columns)
{
  Bit_Matrix matrix_addr =
    marpa_obs_alloc (obs, matrix_sizeof (rows, columns));
  return matrix_buffer_create (matrix_addr, rows, columns);
}

@*0 Clear a boolean matrix.
@<Function definitions@> =
PRIVATE void matrix_clear(Bit_Matrix matrix)
{
    Bit_Vector row;
    int row_ix;
    const int row_count = matrix->t_row_count;
    Bit_Vector row0 = matrix->t_row_data + bv_hiddenwords;
    unsigned int words_per_row = BV_SIZE(row0)+bv_hiddenwords;
    row_ix=0; row = row0;
    while (row_ix < row_count) {
	bv_clear(row);
        row_ix++;
	row += words_per_row;
    }
}

@*0 Find the number of columns in a boolean matrix.
The column count returned is for the first row.
It is assumed that 
all rows have the same number of columns.
Note that, in this implementation, the matrix has no
idea internally of how many rows it has.
@<Function definitions@> =
PRIVATE int matrix_columns(Bit_Matrix matrix)
{
    Bit_Vector row0 = matrix->t_row_data + bv_hiddenwords;
    return BV_BITS(row0);
}

@*0 Find a row of a boolean matrix.
Here's where the slight extra overhead of repeating
identical ``hidden word" data for each row of a matrix
pays off.
This simply returns a pointer into the matrix.
This is adequate if the data is not changed.
If it is changed, the vector should be cloned.
There is a bit of arithmetic, to deal with the
hidden words offset.
@<Function definitions@> =
PRIVATE Bit_Vector matrix_row(Bit_Matrix matrix, unsigned int row)
{
    Bit_Vector row0 = matrix->t_row_data + bv_hiddenwords;
    unsigned int words_per_row = BV_SIZE(row0)+bv_hiddenwords;
    return row0 + row*words_per_row;
}

@*0 Set a boolean matrix bit.
@ @<Function definitions@> =
PRIVATE void matrix_bit_set(Bit_Matrix matrix, unsigned int row, unsigned int column)
{
    Bit_Vector vector = matrix_row(matrix, row);
    bv_bit_set(vector, column);
}

@*0 Clear a boolean matrix bit.
@ @<Function definitions@> =
PRIVATE void matrix_bit_clear(Bit_Matrix matrix, unsigned int row, unsigned int column)
{
    Bit_Vector vector = matrix_row(matrix, row);
    bv_bit_clear(vector, column);
}

@*0 Test a boolean matrix bit.
@ @<Function definitions@> =
PRIVATE int matrix_bit_test(Bit_Matrix matrix, unsigned int row, unsigned int column)
{
    Bit_Vector vector = matrix_row(matrix, row);
    return bv_bit_test(vector, column);
}

@*0 Produce the transitive closure of a boolean matrix.
This routine takes a matrix representing a relation
and produces a matrix that represents the transitive closure
of the relation.
The matrix is assumed to be square.
The input matrix will be destroyed.

Its uses Warshall's algorithm,
which is
$O(n^3)$ where the matrix is $n$x$n$.
@<Function definitions@> =
PRIVATE_NOT_INLINE void transitive_closure(Bit_Matrix matrix)
{
  unsigned int size = matrix_columns (matrix);
  unsigned int outer_row;
  for (outer_row = 0; outer_row < size; outer_row++)
    {
      Bit_Vector outer_row_v = matrix_row (matrix, outer_row);
      unsigned int column;
      for (column = 0; column < size; column++)
	{
	  Bit_Vector inner_row_v = matrix_row (matrix, column);
	  if (bv_bit_test (inner_row_v, (unsigned int) outer_row))
	    {
	      bv_or_assign (inner_row_v, outer_row_v);
	    }
	}
    }
}

@** Efficient stacks and queues.
@ The interface for these macros is somewhat hackish,
in that the user often
must be aware of the implementation of the
macros.
Arguably, using these macros is not
all that easier than
hand-writing each instance.
But the most important goal was safety -- by
writing this stuff once I have a greater assurance
that it is tested and bug-free.
Another important goal was that there be
no compromise on efficiency,
when compared to hand-written code.

@*0 Fixed size stacks.
|libmarpa| uses stacks and worklists extensively.
Often a reasonable maximum size is known when they are
set up, in which case they can be made very fast.
@d FSTACK_DECLARE(stack, type) struct { int t_count; type* t_base; } stack;
@d FSTACK_CLEAR(stack) ((stack).t_count = 0)
@d FSTACK_INIT(stack, type, n) (FSTACK_CLEAR(stack), ((stack).t_base = my_new(type, n)))
@d FSTACK_SAFE(stack) ((stack).t_base = NULL)
@d FSTACK_BASE(stack, type) ((type *)(stack).t_base)
@d FSTACK_INDEX(this, type, ix) (FSTACK_BASE((this), type)+(ix))
@d FSTACK_TOP(this, type) (FSTACK_LENGTH(this) <= 0
   ? NULL
   : FSTACK_INDEX((this), type, FSTACK_LENGTH(this)-1))
@d FSTACK_LENGTH(stack) ((stack).t_count)
@d FSTACK_PUSH(stack) ((stack).t_base+stack.t_count++)
@d FSTACK_POP(stack) ((stack).t_count <= 0 ? NULL : (stack).t_base+(--(stack).t_count))
@d FSTACK_IS_INITIALIZED(stack) ((stack).t_base)
@d FSTACK_DESTROY(stack) (my_free((stack).t_base))

@*0 Dynamic stacks.
|libmarpa| uses stacks and worklists extensively.
This stack interface resizes itself dynamically.
There are two disadvantages.

\li There is more overhead ---
overflow must be checked for with each push,
and the resizings, while fast, do take time.

\li The stack may be moved after any |DSTACK_PUSH|
operation, making all pointers into it invalid.
Data must be retrieved from the stack before the
next |DSTACK_PUSH|.
In the special 2-argument form,
|DSTACK_INIT2|, the stack is initialized
to a size convenient for the memory allocator.
{\bf To Do}: @^To Do@>
Right now this is hard-wired to 1024, but I should
use the better calculation made by the obstack code.
@d DSTACK_DECLARE(this) struct s_dstack this
@d DSTACK_INIT(this, type, initial_size)
(
    ((this).t_count = 0),
    ((this).t_base = my_new(type, ((this).t_capacity = (initial_size))))
)
@d DSTACK_INIT2(this, type)
    DSTACK_INIT((this), type, MAX(4, 1024/sizeof(this)))

@ |DSTACK_SAFE| is for cases where the dstack is not
immediately initialized to a useful value,
and might never be.
All fields are zeroed so that when the containing object
is destroyed, the deallocation logic knows that no
memory has been allocated and therefore no attempt
to free memory should be made.
@d DSTACK_IS_INITIALIZED(this) ((this).t_base)
@d DSTACK_SAFE(this)
  (((this).t_count = (this).t_capacity = 0), ((this).t_base = NULL))

@ A stack reinitialized by
|DSTACK_CLEAR| contains 0 elements,
but has the same capacity as it had before the reinitialization.
This saves the cost of reallocating the dstack's buffer,
and leaves its capacity at what is hopefully
a stable, high-water mark, which will make future
resizings unnecessary.
@d DSTACK_CLEAR(this) ((this).t_count = 0)
@d DSTACK_PUSH(this, type) (
      (UNLIKELY((this).t_count >= (this).t_capacity)
      ? dstack_resize2(&(this), sizeof(type))
      : 0),
     ((type *)(this).t_base+(this).t_count++)
   )
@d DSTACK_POP(this, type) ((this).t_count <= 0 ? NULL :
    ( (type*)(this).t_base+(--(this).t_count)))
@d DSTACK_INDEX(this, type, ix) (DSTACK_BASE((this), type)+(ix))
@d DSTACK_TOP(this, type) (DSTACK_LENGTH(this) <= 0
   ? NULL
   : DSTACK_INDEX((this), type, DSTACK_LENGTH(this)-1))
@d DSTACK_BASE(this, type) ((type *)(this).t_base)
@d DSTACK_LENGTH(this) ((this).t_count)
@d DSTACK_CAPACITY(this) ((this).t_capacity)

@
|DSTACK|'s can have their data ``stolen", by other containers.
The |STOLEN_DSTACK_DATA_FREE| macro is intended
to help the ``thief" container
deallocate the data it now has ``stolen".
@d STOLEN_DSTACK_DATA_FREE(data) (my_free(data))
@d DSTACK_DESTROY(this) STOLEN_DSTACK_DATA_FREE(this.t_base)
@s DSTACK int
@<Private incomplete structures@> =
struct s_dstack;
typedef struct s_dstack* DSTACK;
@ @<Private utility structures@> =
struct s_dstack { int t_count; int t_capacity; void * t_base; };
@ Not inline because |DSTACK|'s should be initialized so that
resizings are uncommon or even exceptional events.
@<Function definitions@> =
PRIVATE_NOT_INLINE void * dstack_resize2(struct s_dstack* this, size_t type_bytes)
{
    return dstack_resize(this, type_bytes, this->t_capacity*2);
}

@ Not inline because |DSTACK|'s should be initialized so that
resizings are uncommon or even exceptional events.
@d DSTACK_RESIZE(this, type, new_size) (dstack_resize((this), sizeof(type), (new_size)))
@<Function definitions@> =
PRIVATE void * dstack_resize(struct s_dstack* this, size_t type_bytes, int new_size)
{
  if (new_size > this->t_capacity)
    {				/* We do not shrink the stack
				   in this method */
      this->t_capacity = new_size;
      this->t_base = my_realloc (this->t_base, new_size * type_bytes);
    }
  return this->t_base;
}

@*0 Dynamic queues.
This is simply a dynamic stack extended with a second
index.
These is no destructor at this point, because so far all uses
of this let another container ``steal" the data from this one.
When one exists, it will simply call the dynamic stack destructor.
Instead I define a destructor for the ``thief" container to use
when it needs to free the data.

@d DQUEUE_DECLARE(this) struct s_dqueue this
@d DQUEUE_INIT(this, type, initial_size)
    ((this.t_current=0), DSTACK_INIT(this.t_stack, type, initial_size))
@d DQUEUE_PUSH(this, type) DSTACK_PUSH(this.t_stack, type)
@d DQUEUE_POP(this, type) DSTACK_POP(this.t_stack, type)
@d DQUEUE_NEXT(this, type) (this.t_current >= DSTACK_LENGTH(this.t_stack)
    ? NULL
    : (DSTACK_BASE(this.t_stack, type))+this.t_current++)
@d DQUEUE_BASE(this, type) DSTACK_BASE(this.t_stack, type)
@d DQUEUE_END(this) DSTACK_LENGTH(this.t_stack)
@d STOLEN_DQUEUE_DATA_FREE(data) STOLEN_DSTACK_DATA_FREE(data)

@<Private incomplete structures@> =
struct s_dqueue;
typedef struct s_dqueue* DQUEUE;
@ @<Private structures@> =
struct s_dqueue { int t_current; struct s_dstack t_stack; };

@** Counted integer lists (CIL).
As a structure,
almost not worth bothering with,
if it were not for its use in CILAR's.
The first |int| is a count, and purists might insist
on a struct instead of an array.
A struct would reflect the logical structure more
accurately.
But would it make the actual code 
less readable, not more,
which I believe has to be the object.
@d Count_of_CIL(cil) (cil[0])
@d Item_of_CIL(cil, ix) (cil[1+(ix)])
@d Sizeof_CIL(ix) (sizeof(int) * (1+(ix)))
@ @s CIL int
@<Private typedefs@> =
typedef int* CIL;

@** Counted integer list arena (CILAR).
These implement an especially efficient memory allocation scheme.
Libmarpa needs many copies of integer lists,
where the integers are symbol ID's, rule ID's, etc.
The same ones are used again and again.
The CILAR allows them to be allocated once and reused.
\par
The CILAR is a software implementation
of memory which is both random-access
and content-addressable.
Content-addressability saves space -- when the
contents are identical they can be reused.
The content-addressability is implemented in software
(as an AVL).
While lookup is not slow
the intention is that the content-addressability will used
infrequently --
once created or found the CIL will be memoized
for random-access through a pointer.

@ An obstack for the actual data, and a tree
for the lookups.
@<Private utility structures@> =
struct s_cil_arena {
    struct marpa_obstack* t_obs;
    MARPA_AVL_TREE t_avl;
    DSTACK_DECLARE(t_buffer);
};
typedef struct s_cil_arena CILAR_Object;

@ @<Private incomplete structures@> =
struct s_cil_arena;
@ @s CILAR int
@<Private typedefs@> =
typedef struct s_cil_arena* CILAR;
@
{\bf To Do}: @^To Do@> The initial capacity of the CILAR dstack
is absurdly small, in order to test the logic during development.
Once things settle, |DSTACK_INIT| should be changed to
|DSTACK_INIT2|.
@d CAPACITY_OF_CILAR(cilar) (CAPACITY_OF_DSTACK(cilar->t_buffer)-1)
@<Function definitions@> =
PRIVATE void
cilar_init (const CILAR cilar)
{
  cilar->t_obs = marpa_obs_init;
  cilar->t_avl = _marpa_avl_create (cil_cmp, NULL, 0);
  DSTACK_INIT(cilar->t_buffer, int, 2);
  *DSTACK_INDEX(cilar->t_buffer, int, 0) = 0;
}
@
{\bf To Do}: @^To Do@> The initial capacity of the CILAR dstack
is absurdly small, in order to test the logic during development.
Once things settle, |DSTACK_INIT| should be changed to
|DSTACK_INIT2|.
@<Function definitions@> =
PRIVATE void
cilar_reinit (const CILAR cilar)
{
  DSTACK_DESTROY(cilar->t_buffer);
  DSTACK_INIT(cilar->t_buffer, int, 2);
  *DSTACK_INDEX(cilar->t_buffer, int, 0) = 0;
}

@ @<Function definitions@> =
PRIVATE void cilar_destroy(const CILAR cilar)
{
  _marpa_avl_destroy (cilar->t_avl );
  marpa_obs_free(cilar->t_obs);
  DSTACK_DESTROY((cilar->t_buffer));
}

@ Return the empty CIL from a CILAR.
@<Function definitions@> =
PRIVATE CIL cil_empty(CILAR cilar)
{
  CIL cil = DSTACK_BASE (cilar->t_buffer, int);	/* We assume there is enough room */
  Count_of_CIL(cil) = 0;
  return cil_buffer_add (cilar);
}

@ Return a singleton CIL from a CILAR.
@<Function definitions@> =
PRIVATE CIL cil_singleton(CILAR cilar, int element)
{
  CIL cil = DSTACK_BASE (cilar->t_buffer, int);
  Count_of_CIL(cil) = 1;
  Item_of_CIL(cil, 0) = element;
  /* We assume there is enough room in the CIL buffer for a singleton */
  return cil_buffer_add (cilar);
}

@ Add the CIL in the buffer to the
CILAR.
This method
is optimized for the case where the CIL
is alread in the CIL,
in which case this method finds the current entry.
@<Function definitions@> =
PRIVATE CIL cil_buffer_add(CILAR cilar)
{

  CIL cil_in_buffer = DSTACK_BASE (cilar->t_buffer, int);
  CIL found_cil = _marpa_avl_find (cilar->t_avl, cil_in_buffer);
  if (!found_cil)
    {
      int i;
      const int cil_size_in_ints = Count_of_CIL (cil_in_buffer) + 1;
      found_cil = marpa_obs_new (cilar->t_obs, int, cil_size_in_ints);
      for (i = 0; i < cil_size_in_ints; i++)
	{			/* Assumes that the CIL's are |int*| */
	  found_cil[i] = cil_in_buffer[i];
	}
      _marpa_avl_insert (cilar->t_avl, found_cil);
    }
  return found_cil;
}

@ Add a CIL taken from a bit vector
to the CILAR.
This method
is optimized for the case where the CIL
is already in the CIL,
in which case this method finds the current entry.
The CILAR buffer is used,
so its current contents will be destroyed.
@<Function definitions@> =
PRIVATE CIL cil_bv_add(CILAR cilar, Bit_Vector bv)
{
  unsigned int min, max, start = 0;
  cil_buffer_clear (cilar);
  for (start = 0; bv_scan (bv, start, &min, &max); start = max + 2)
    {
      int new_item;
      for (new_item = (int) min; new_item <= (int) max; new_item++)
	{
	  cil_buffer_push (cilar, new_item);
	}
    }
  return cil_buffer_add (cilar);
}

@ Clear the CILAR buffer.
@<Function definitions@> =
PRIVATE void cil_buffer_clear(CILAR cilar)
{
  const DSTACK dstack = &cilar->t_buffer;
  DSTACK_CLEAR(*dstack);
  /* \comment Has same effect as 
  |Count_of_CIL (cil_in_buffer) = 0|, except that it sets
  the DSTACK up properly */
  *DSTACK_PUSH(*dstack, int) = 0;
}

@ Push an |int| onto the end of the CILAR buffer.
It is up to the caller to ensure the buffer is sorted
when and if added to the CILAR.
@<Function definitions@> =
PRIVATE CIL cil_buffer_push(CILAR cilar, int new_item)
{
  CIL cil_in_buffer;
  DSTACK dstack = &cilar->t_buffer;
  *DSTACK_PUSH (*dstack, int) = new_item;
/* \comment Note that the buffer CIL might have been moved
		   by the |DSTACK_PUSH| */
  cil_in_buffer = DSTACK_BASE (*dstack, int);
  Count_of_CIL (cil_in_buffer)++;
  return cil_in_buffer;
}

@ Make sure that the CIL buffer is large enough
to hold |element_count| elements.
@<Function definitions@> =
PRIVATE CIL cil_buffer_reserve(CILAR cilar, int element_count)
{
  const int desired_dstack_capacity = element_count + 1;	/* One extra for the count word */
  const int old_dstack_capacity = DSTACK_CAPACITY (cilar->t_buffer);
  if (old_dstack_capacity < desired_dstack_capacity)
    {
      const int target_capacity =
	MAX (old_dstack_capacity * 2, desired_dstack_capacity);
      DSTACK_RESIZE (&(cilar->t_buffer), int, target_capacity);
    }
  return DSTACK_BASE (cilar->t_buffer, int);
}

@ Merge two CIL's into a new one.
Not used at this point.
This method trades unneeded obstack block
allocations for CPU speed.
@<Function definitions@> =
PRIVATE CIL cil_merge(CILAR cilar, CIL cil1, CIL cil2)
{
  const int cil1_count = Count_of_CIL (cil1);
  const int cil2_count = Count_of_CIL (cil2);
  CIL new_cil = cil_buffer_reserve (cilar, cil1_count+cil2_count);
  int new_cil_ix = 0;
  int cil1_ix = 0;
  int cil2_ix = 0;
  while (cil1_ix < cil1_count && cil2_ix < cil2_count)
    {
      const int item1 = Item_of_CIL (cil1, cil1_ix);
      const int item2 = Item_of_CIL (cil2, cil2_ix);
      if (item1 < item2)
	{
	  Item_of_CIL (new_cil, new_cil_ix) = item1;
	  cil1_ix++;
	  new_cil_ix++;
	  continue;
	}
      if (item2 < item1)
	{
	  Item_of_CIL (new_cil, new_cil_ix) = item2;
	  cil2_ix++;
	  new_cil_ix++;
	  continue;
	}
      Item_of_CIL (new_cil, new_cil_ix) = item1;
      cil1_ix++;
      cil2_ix++;
      new_cil_ix++;
    }
  while (cil1_ix < cil1_count ) {
      const int item1 = Item_of_CIL (cil1, cil1_ix);
      Item_of_CIL (new_cil, new_cil_ix) = item1;
      cil1_ix++;
      new_cil_ix++;
  }
  while (cil2_ix < cil2_count ) {
      const int item2 = Item_of_CIL (cil2, cil2_ix);
      Item_of_CIL (new_cil, new_cil_ix) = item2;
      cil2_ix++;
      new_cil_ix++;
  }
  Count_of_CIL(new_cil) = new_cil_ix;
  return cil_buffer_add (cilar);
}

@ Merge |int new_element| into an
a CIL already in the CILAR.
Optimized for the case where the CIL already includes
|new_element|,
in which case it returns |NULL|.
@<Function definitions@> =
PRIVATE CIL cil_merge_one(CILAR cilar, CIL cil, int new_element)
{
  const int cil_count = Count_of_CIL (cil);
  CIL new_cil = cil_buffer_reserve (cilar, cil_count + 1);
  int new_cil_ix = 0;
  int cil_ix = 0;
  while (cil_ix < cil_count)
    {
      const int cil_item = Item_of_CIL (cil, cil_ix);
      if (cil_item == new_element)
	{
	  /* |new_element| is already in |cil|, so we just return |cil|.
	     It is OK to abandon the CIL in progress */
	  return NULL;
	}
      if (cil_item > new_element)
	break;
      Item_of_CIL (new_cil, new_cil_ix) = cil_item;
      cil_ix++;
      new_cil_ix++;
    }
  Item_of_CIL (new_cil, new_cil_ix) = new_element;
  new_cil_ix++;
  while (cil_ix < cil_count)
    {
      const int cil_item = Item_of_CIL (cil, cil_ix);
      Item_of_CIL (new_cil, new_cil_ix) = cil_item;
      cil_ix++;
      new_cil_ix++;
    }
  Count_of_CIL (new_cil) = new_cil_ix;
  return cil_buffer_add (cilar);
}

@ @<Function definitions@> =
PRIVATE_NOT_INLINE int
cil_cmp (const void *ap, const void *bp, void *param @,@, UNUSED)
{
  int ix;
  CIL cil1 = (CIL) ap;
  CIL cil2 = (CIL) bp;
  int count1 = Count_of_CIL (cil1);
  int count2 = Count_of_CIL (cil2);
  if (count1 != count2)
    {
      return count1 > count2 ? 1 : -1;
    }
  for (ix = 0; ix < count1; ix++)
    {
      const int item1 = Item_of_CIL (cil1, ix);
      const int item2 = Item_of_CIL (cil2, ix);
      if (item1 == item2)
	continue;
      return item1 > item2 ? 1 : -1;
    }
  return 0;
}

@** Memory allocation.

@*0 Memory allocation failures.
@ By default,
a memory allocation failure
inside the Marpa library is a fatal error.
At some point I may allow this to be reset.
What else an application can do is not at all clear,
which is why the usual practice 
is to treatment memory allocation errors are
fatal, irrecoverable problems.
These functions all return |void*| in order
to avoid compiler warnings about void returns.
@<Function definitions@> =
PRIVATE_NOT_INLINE void*
_marpa_default_out_of_memory(void)
{
    abort();
}
void* (*_marpa_out_of_memory)(void) = _marpa_default_out_of_memory;

@ @<Utility variables@> =
extern void* (*_marpa_out_of_memory)(void);

@*0 Obstacks.
|libmarpa| uses the system malloc,
either directly or indirectly.
Indirect use comes via obstacks.
Obstacks are more efficient, but 
limit the ability to resize memory,
and to control the lifetime of the memory.
@ Obstacks are widely used inside |libmarpa|.
Much of the memory allocated in |libmarpa| is
\li In individual allocations less than 4K, often considerable less.
\li Once created, are kept for the entire life of the either the grammar or the recognizer.
\li Once created, is never resized.
For these, obstacks are perfect.
|libmarpa|'s grammar has an obstacks.
Small allocations needed for the lifetime of the grammar
are allocated on these as the grammar object is built.
All these allocations are are conveniently and quickly deallocated when
the grammar's obstack is destroyed along with its parent grammar.

@*0 Memory allocation.
libmarpa wrappers the standard memory functions
to provide more convenient behaviors.
\li The allocators do not return on failed memory allocations.
\li |my_realloc| is equivalent to |my_malloc| if called with
a |NULL| pointer.  (This is the GNU C library behavior.)
@ {\bf To Do}: @^To Do@>
For the moment, the memory allocators are hard-wired to
the C89 default |malloc| and |free|.
At some point I may allow the user to override
these choices.

@<Friend static inline functions@> =
static inline
void my_free (void *p)
{
  free (p);
}

@ The macro is defined because it is sometimes needed
to force inlining.
@<Friend static inline functions@> =
#define MALLOC_VIA_TEMP(size, temp) \
  (UNLIKELY(!((temp) = malloc(size))) ? (*_marpa_out_of_memory)() : (temp))
static inline
void* my_malloc(size_t size)
{
    void *newmem;
    return MALLOC_VIA_TEMP(size, newmem);
}

static inline
void*
my_malloc0(size_t size)
{
    void* newmem = my_malloc(size);
    memset (newmem, 0, size);
    return newmem;
}

static inline
void*
my_realloc(void *p, size_t size)
{
   if (LIKELY(p != NULL)) {
	void *newmem = realloc(p, size);
	if (UNLIKELY(!newmem)) (*_marpa_out_of_memory)();
	return newmem;
   }
   return my_malloc(size);
}

@ @<Utility macros@> =
#define my_new(type, count) ((type *)my_malloc((sizeof(type)*(count))))
#define my_renew(type, p, count) \
    ((type *)my_realloc((p), (sizeof(type)*(count))))

@** Debugging.
The |MARPA_DEBUG| flag enables intrusive debugging logic.
``Intrusive" debugging includes things which would
be annoying in production, such as detailed messages about
internal matters on |STDERR|.
|MARPA_DEBUG| is expected to be defined in the |CFLAGS|.
|MARPA_DEBUG| implies |MARPA_ENABLE_ASSERT|, but not
vice versa.
@<Utility macros@> =
#define MARPA_OFF_DEBUG1(a)
#define MARPA_OFF_DEBUG2(a, b)
#define MARPA_OFF_DEBUG3(a, b, c)
#define MARPA_OFF_DEBUG4(a, b, c, d)
#define MARPA_OFF_DEBUG5(a, b, c, d, e)
#define MARPA_OFF_ASSERT(expr)
@ Returns int so that it can be portably used
in a logically-anded expression.
@<Debug function definitions@> =
int _marpa_default_debug_handler (const char *format, ...)
{
   va_list args;
   va_start (args, format);
   vfprintf (stderr, format, args);
   va_end (args);
   putc('\n', stderr);
   return 1;
}

@ @<Utility variables@> =
extern int (*_marpa_debug_handler)(const char*, ...);
extern int _marpa_debug_level;
@ For thread-safety, these are for debugging only.
Even in debugging, while not actually initialized constants,
they are intended to be set very early
and left unchanged.
@<Utility variables@> =
#if MARPA_DEBUG > 0
extern int _marpa_default_debug_handler (const char *format, ...);
#define MARPA_DEFAULT_DEBUG_HANDLER _marpa_default_debug_handler
#else
#define MARPA_DEFAULT_DEBUG_HANDLER NULL
#endif

@ @<Global variables@> =
int (*_marpa_debug_handler)(const char*, ...) =
    MARPA_DEFAULT_DEBUG_HANDLER;
int _marpa_debug_level = 0;

@ @<Public function prototypes@> =
void marpa_debug_handler_set( int (*debug_handler)(const char*, ...) );
@ @<Function definitions@> =
void marpa_debug_handler_set( int (*debug_handler)(const char*, ...) )
{
    _marpa_debug_handler = debug_handler;
}

@ @<Public function prototypes@> =
void marpa_debug_level_set( int level );
@ @<Function definitions@> =
void marpa_debug_level_set( int level )
{
    _marpa_debug_level = level;
}

@ @<Debug macros@> =

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#if MARPA_DEBUG

#undef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 1

#define MARPA_DEBUG1(a) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)(a)) @]
#define MARPA_DEBUG2(a,b) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b))) @]
#define MARPA_DEBUG3(a,b,c) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c))) @]
#define MARPA_DEBUG4(a,b,c,d) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c),(d))) @]
#define MARPA_DEBUG5(a,b,c,d,e) @[ (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c),(d),(e))) @]

#define MARPA_ASSERT(expr) do { if LIKELY (expr) ; else \
       (*_marpa_debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
#else /* if not |MARPA_DEBUG| */
#define MARPA_DEBUG1(a) @[@]
#define MARPA_DEBUG2(a, b) @[@]
#define MARPA_DEBUG3(a, b, c) @[@]
#define MARPA_DEBUG4(a, b, c, d) @[@]
#define MARPA_DEBUG5(a, b, c, d, e) @[@]
#define MARPA_ASSERT(exp) @[@]
#endif

#ifndef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 0
#endif

#if MARPA_ENABLE_ASSERT
#undef MARPA_ASSERT
#define MARPA_ASSERT(expr) do { if LIKELY (expr) ; else \
       (*_marpa_debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
#endif

@** File layout.  
@ The output files are {\bf not} source files,
but I add the license to them anyway,
as close to the top as possible.
@ Also, it is helpful to someone first
trying to orient herself,
if built source files contain a comment
to that effect and a warning
not that they are
not intended to be edited directly.
So I add such a comment.

@ This is the license language for the header files.
\tenpoint
@<Header license language@> =
@=/*@>@/
@= * Copyright 2013 Jeffrey Kegler@>@/
@= * This file is part of Marpa::R2.  Marpa::R2 is free software: you can@>@/
@= * redistribute it and/or modify it under the terms of the GNU Lesser@>@/
@= * General Public License as published by the Free Software Foundation,@>@/
@= * either version 3 of the License, or (at your option) any later version.@>@/
@= *@>@/
@= * Marpa::R2 is distributed in the hope that it will be useful,@>@/
@= * but WITHOUT ANY WARRANTY; without even the implied warranty of@>@/
@= * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU@>@/
@= * Lesser General Public License for more details.@>@/
@= *@>@/
@= * You should have received a copy of the GNU Lesser@>@/
@= * General Public License along with Marpa::R2.  If not, see@>@/
@= * http://www.gnu.org/licenses/.@>@/
@= */@>@/
@=/*@>@/
@= * DO NOT EDIT DIRECTLY@>@/
@= * This file is written by ctangle@>@/
@= * It is not intended to be modified directly@>@/
@= */@>@/

@ \twelvepoint

@*0 |marpa_ami.h| layout.
\tenpoint
@(marpa_ami.h@> =
@<Header license language@>@;

#ifndef __MARPA_AMI_H__
#define __MARPA_AMI_H__

@<Utility macros@>@;
@<Debug macros@>@;
@<Utility variables@>@;
@<Friend typedefs@>@;
@<Friend static inline functions@>@;
@<Public function prototypes@>@;

#endif /* |__MARPA_AMI_H__| */

@*0 |marpa_ami.c| layout.
@q This is a hack to get the @>
@q license language nearer the top of the files. @>
@ The physical structure of the |marpa_ami.c| file
\tenpoint
@c
@=/*@>@/
@= * Copyright 2013 Jeffrey Kegler@>@/
@= * This file is part of Marpa::R2.  Marpa::R2 is free software: you can@>@/
@= * redistribute it and/or modify it under the terms of the GNU Lesser@>@/
@= * General Public License as published by the Free Software Foundation,@>@/
@= * either version 3 of the License, or (at your option) any later version.@>@/
@= *@>@/
@= * Marpa::R2 is distributed in the hope that it will be useful,@>@/
@= * but WITHOUT ANY WARRANTY; without even the implied warranty of@>@/
@= * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU@>@/
@= * Lesser General Public License for more details.@>@/
@= *@>@/
@= * You should have received a copy of the GNU Lesser@>@/
@= * General Public License along with Marpa::R2.  If not, see@>@/
@= * http://www.gnu.org/licenses/.@>@/
@= */@>@/
@=/*@>@/
@= * DO NOT EDIT DIRECTLY@>@/
@= * This file is written by ctangle@>@/
@= * It is not intended to be modified directly@>@/
@= */@>@/

@ \twelvepoint @c
#include "config.h"
#include "marpa.h"
#include <stddef.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>

#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#if MARPA_DEBUG
#include <stdarg.h>
#include <stdio.h>
#endif

#include "marpa_int.h"
#include "marpa_ami.h"

@h

@<Global variables@>@;
@<Private incomplete structures@>@;
@<Private structures@>@;
@<Private typedefs@>@;
@<Private utility structures@>@;

#if MARPA_DEBUG
@<Debug function definitions@>@;
#endif

#include "ami_private.h"

@<Function definitions@>@;

@** Index.

