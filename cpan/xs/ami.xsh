/*
 * Copyright 2014 Jeffrey Kegler
 * This file is part of Libmarpa.  Libmarpa is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Libmarpa is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Libmarpa.  If not, see
 * http://www.gnu.org/licenses/.
 */

/* Dynamic stacks.  Copied from Libmarpa.  */

#define MARPA_DSTACK_DECLARE(this) struct marpa_dstack_s this
#define MARPA_DSTACK_INIT(this, type, initial_size) \
( \
    ((this).t_count = 0), \
    NewX(((this).t_base, ((this).t_capacity = (initial_size))), type) \
)
#define MARPA_DSTACK_INIT2(this, type) \
    MARPA_DSTACK_INIT((this), type, MAX(4, 1024/sizeof(this)))

#define MARPA_DSTACK_IS_INITIALIZED(this) ((this).t_base)
#define MARPA_DSTACK_SAFE(this) \
  (((this).t_count = (this).t_capacity = 0), ((this).t_base = NULL))

#define MARPA_DSTACK_COUNT_SET(this, n) ((this).t_count = (n))

#define MARPA_DSTACK_CLEAR(this) MARPA_DSTACK_COUNT_SET((this), 0)
#define MARPA_DSTACK_PUSH(this, type) ( \
      (_MARPA_UNLIKELY((this).t_count >= (this).t_capacity) \
      ? MARPA_DSTACK_RESIZE2(&(this), sizeof(type)) \
      : 0), \
     ((type *)(this).t_base+(this).t_count++) \
   )
#define MARPA_DSTACK_POP(this, type) ((this).t_count <= 0 ? NULL : \
    ( (type*)(this).t_base+(--(this).t_count)))
#define MARPA_DSTACK_INDEX(this, type, ix) (MARPA_DSTACK_BASE((this), type)+(ix))
#define MARPA_DSTACK_TOP(this, type) (MARPA_DSTACK_LENGTH(this) <= 0 \
   ? NULL \
   : MARPA_DSTACK_INDEX((this), type, MARPA_DSTACK_LENGTH(this)-1))
#define MARPA_DSTACK_BASE(this, type) ((type *)(this).t_base)
#define MARPA_DSTACK_LENGTH(this) ((this).t_count)
#define MARPA_DSTACK_CAPACITY(this) ((this).t_capacity)

#define MARPA_STOLEN_DSTACK_DATA_FREE(data) (my_free(data))
#define MARPA_DSTACK_DESTROY(this) MARPA_STOLEN_DSTACK_DATA_FREE(this.t_base)

#define MARPA_DSTACK_RESIZE(this, type, new_size) \
  (Renew((this), (new_size), sizeof(type)))
#define MARPA_DSTACK_RESIZE2(this, type) \
  (Renew((this), ((this)->t_capacity*2), sizeof(type)))

struct marpa_dstack_s;
typedef struct marpa_dstack_s* MARPA_DSTACK;
struct marpa_dstack_s { int t_count; int t_capacity; void * t_base; };


