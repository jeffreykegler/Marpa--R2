% Copyright 2010 Jeffrey Kegler
% This file is part of Marpa::XS.  Marpa::XS is free software: you can
% redistribute it and/or modify it under the terms of the GNU Lesser
% General Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later version.
%
% Marpa::XS is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser
% General Public License along with Marpa::XS.  If not, see
% http://www.gnu.org/licenses/.

% This code never used.  Saved in this file, just in case.

@** Hashing.
The code in this section is adopted from
|lookup3.c|.
It is by Bob Jenkins.
For extensive explanations, and much more,
see Mr. Jenkin's website: http://burtleburtle.net/bob/.

@d bjenkins_rot(x,k) (((x)<<(k)) | ((x)>>(32-(k))))

@d bjenkins_mix(a,b,c)
{ 
  a -= c;  a ^= bjenkins_rot(c, 4);  c += b; 
  b -= a;  b ^= bjenkins_rot(a, 6);  a += c; 
  c -= b;  c ^= bjenkins_rot(b, 8);  b += a; 
  a -= c;  a ^= bjenkins_rot(c,16);  c += b;
  b -= a;  b ^= bjenkins_rot(a,19);  a += c;
  c -= b;  c ^= bjenkins_rot(b, 4);  b += a;
}

@d bjenkins_final(a,b,c) 
{
  c ^= b; c -= bjenkins_rot(b,14);
  a ^= c; a -= bjenkins_rot(c,11);
  b ^= a; b -= bjenkins_rot(a,25);
  c ^= b; c -= bjenkins_rot(b,16);
  a ^= c; a -= bjenkins_rot(c,4);
  b ^= a; b -= bjenkins_rot(a,14);
  c ^= b; c -= bjenkins_rot(b,24);
}

@<Hash function body template@> =
  guint32 a,b,c;
  gsize length = TEMPLATE_KEY_LENGTH(p);
  TEMPLATE_KEY_TYPE k = TEMPLATE_KEY_INIT(p);

  /* Set up the internal state */
  a = b = c = 0xdeadbeef + (((guint32)length)<<2);

  while (length > 3)
  { /* Handle most of the key */
    a += TEMPLATE_KEY_VALUE(k, 0);
    b += TEMPLATE_KEY_VALUE(k, 1);
    c += TEMPLATE_KEY_VALUE(k, 2);
    bjenkins_mix(a,b,c);
    length -= 3;
    TEMPLATE_KEY_INC(k, 3);
  }

  switch(length)
  { 
  /* Handle the last 3 guint32's --
   all the case statements fall through */
  case 3 : c+= TEMPLATE_KEY_VALUE(k, 2);
  case 2 : b+= TEMPLATE_KEY_VALUE(k, 1);
  case 1 : a+= TEMPLATE_KEY_VALUE(k, 0);
    bjenkins_final(a,b,c);
  case 0:     /* case 0: nothing left to add */
    break;
  }
  return c; /* report the result */

@ @<Hash function template undefine@> =
#undef TEMPLATE_KEY_TYPE@/
#undef TEMPLATE_KEY_INIT@/
#undef TEMPLATE_KEY_VALUE@/
#undef TEMPLATE_KEY_LENGTH@/
#undef TEMPLATE_KEY_INC@/

