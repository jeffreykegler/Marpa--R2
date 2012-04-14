/*1193:*/
#line 13593 "./marpa.w"

/*1188:*/
#line 13551 "./marpa.w"

/*
 * Copyright 2012 Jeffrey Kegler
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
/*
 * DO NOT EDIT DIRECTLY
 * This file is written by ctangle
 * It is not intended to be modified directly
 */

/*:1188*/
#line 13594 "./marpa.w"


#ifndef __MARPA_UTIL_H__
#define __MARPA_UTIL_H__

/*1127:*/
#line 12894 "./marpa.w"

extern void(*_marpa_out_of_memory)(void);

/*:1127*//*1136:*/
#line 12983 "./marpa.w"

static inline
void my_free(void*p)
{
free(p);
}

static inline
void*my_malloc(size_t size)
{
void*newmem= malloc(size);
if(UNLIKELY(!newmem))(*_marpa_out_of_memory)();
return newmem;
}

static inline
void*
my_malloc0(size_t size)
{
void*newmem= my_malloc(size);
memset(newmem,0,size);
return newmem;
}

static inline
void*
my_realloc(void*p,size_t size)
{
if(LIKELY(p!=NULL)){
void*newmem= realloc(p,size);
if(UNLIKELY(!newmem))(*_marpa_out_of_memory)();
return newmem;
}
return my_malloc(size);
}

/*:1136*//*1137:*/
#line 13021 "./marpa.w"

#define my_new(type, count) ((type *)my_malloc((sizeof(type)*(count))))
#define my_renew(type, p, count) \
    ((type *)my_realloc((p), (sizeof(type)*(count))))

/*:1137*/
#line 13599 "./marpa.w"


#endif __MARPA__UTIL_H__

/*:1193*/
