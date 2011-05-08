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

% This code not used, but kept in this file in case.

@** Pointer Arrays.
Pointer arrays can exist on their own,
or as part of a dynamic pointer array.
When considered on their own,
they are fixed in size.
@<ADT structures@> =
struct p_array { gint len; gpointer *data; };
@ @<Function definitions@> =
static inline void p_array_destroy(struct p_array* pa) {
    gpointer data = pa->data;
    if (data) g_free(data);
}
@ @<Private function prototypes@> =
static inline void p_array_destroy(struct p_array* pa);

@** Dynamic Pointer Arrays.
In this variation of dynamic arrays, only pointers are allowed
and sizes are expected to be large.
Adding to the array may cause it to move,
invalidating all addresses taken from it.
Once the array is "frozen",
addresses within it are stable
and addresses of items within it may be expected to
stay valid.
@<ADT structures@> =
struct dp_array { struct p_array pa; gint size; };
@ @<Function definitions@> =
static inline void dp_array_init(struct dp_array* dpa, gint size) {
dpa->pa.len = 0; dpa->size = size; dpa->pa.data = g_new(gpointer, size); }
@ @<Private function prototypes@> =
static inline void dp_array_init(struct dp_array* dpa, gint size);
@ @<Function definitions@> =
static inline void dp_array_destroy(struct dp_array* dpa) {
    p_array_destroy(&(dpa->pa));
}
@ @<Private function prototypes@> =
static inline void dp_array_destroy(struct dp_array* dpa);
@ @<Function definitions@> =
static inline void dp_array_resize(struct dp_array *dpa, gint new_size) {
   dpa->pa.data = g_renew(gpointer, dpa->pa.data, new_size);
   dpa->size = new_size;
}
@ @<Private function prototypes@> =
static inline void dp_array_resize(struct dp_array *dpa, gint new_size);
@ @<Function definitions@> =
static inline void dp_array_append(struct dp_array *dpa, gpointer p) {
     if (dpa->pa.len >= dpa->size) dp_array_resize(dpa, dpa->size*2);
     dpa->pa.data[dpa->pa.len++] = p;
}
@ @<Private function prototypes@> =
static inline void dp_array_append(struct dp_array *dpa, gpointer p);
@ Copies a dynamic pointer array to a pointer array, giving it a final
resizing.
@<Function definitions@> =
static inline void dp_array_freeze(struct dp_array *dpa, struct p_array* pa) {
    gint len = pa->len = dpa->pa.len;
    if (G_UNLIKELY(len >= dpa->size)) {
       pa->data = dpa->pa.data;
       return;
    }
   pa->data = g_renew(gpointer, dpa->pa.data, len);
}
@ @<Private function prototypes@> =
static inline void dp_array_freeze(struct dp_array *dpa, struct p_array* pa);

