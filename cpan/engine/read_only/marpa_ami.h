/*
 * Copyright 2015 Jeffrey Kegler
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

/*
 * DO NOT EDIT DIRECTLY
 * This file is written by the Marpa build process
 * It is not intended to be modified directly
 */

/*27:*/
#line 490 "./marpa_ami.w"


#ifndef _MARPA_AMI_H__
#define _MARPA_AMI_H__ 1

#if defined(__GNUC__) && (__GNUC__ >   2) && defined(__OPTIMIZE__)
#define _MARPA_LIKELY(expr) (__builtin_expect ((expr), 1))
#define _MARPA_UNLIKELY(expr) (__builtin_expect ((expr), 0))
#else
#define _MARPA_LIKELY(expr) (expr)
#define _MARPA_UNLIKELY(expr) (expr)
#endif

/*19:*/
#line 352 "./marpa_ami.w"

#define MARPA_OFF_DEBUG1(a)
#define MARPA_OFF_DEBUG2(a, b)
#define MARPA_OFF_DEBUG3(a, b, c)
#define MARPA_OFF_DEBUG4(a, b, c, d)
#define MARPA_OFF_DEBUG5(a, b, c, d, e)
#define MARPA_OFF_ASSERT(expr)
/*:19*//*21:*/
#line 373 "./marpa_ami.w"


#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#if MARPA_DEBUG

#define MARPA_DEBUG1(a)  (marpa__debug_level && \
    (*marpa__debug_handler)(a)) 
#define MARPA_DEBUG2(a,b)  (marpa__debug_level && \
    (*marpa__debug_handler)((a),(b))) 
#define MARPA_DEBUG3(a,b,c)  (marpa__debug_level && \
    (*marpa__debug_handler)((a),(b),(c))) 
#define MARPA_DEBUG4(a,b,c,d)  (marpa__debug_level && \
    (*marpa__debug_handler)((a),(b),(c),(d))) 
#define MARPA_DEBUG5(a,b,c,d,e)  (marpa__debug_level && \
    (*marpa__debug_handler)((a),(b),(c),(d),(e))) 

#else

#define MARPA_DEBUG1(a)
#define MARPA_DEBUG2(a,b)
#define MARPA_DEBUG3(a,b,c)
#define MARPA_DEBUG4(a,b,c,d)
#define MARPA_DEBUG5(a,b,c,d,e)

#endif

#if MARPA_DEBUG
#undef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 1
#endif

#ifndef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 0
#endif

#if MARPA_ENABLE_ASSERT
#undef MARPA_ASSERT
#define MARPA_ASSERT(expr) do { if _MARPA_LIKELY (expr) ; else \
       (*marpa__debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
#else 
#define MARPA_ASSERT(exp) 
#endif

/*:21*/
#line 503 "./marpa_ami.w"

/*22:*/
#line 420 "./marpa_ami.w"


#if     __GNUC__ >  2 || (__GNUC__ == 2 && __GNUC_MINOR__ >  4)
#define UNUSED __attribute__((__unused__))
#else
#define UNUSED
#endif

#if defined (__GNUC__) && defined (__STRICT_ANSI__)
#  undef inline
#  define inline __inline__
#endif

#undef Dim
#define Dim(x) (sizeof(x)/sizeof(*x))

#undef      MAX
#define MAX(a, b)  (((a) >  (b)) ? (a) : (b))

#undef      CLAMP
#define CLAMP(x, low, high)  (((x) >  (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

#undef STRINGIFY_ARG
#define STRINGIFY_ARG(contents)       #contents
#undef STRINGIFY
#define STRINGIFY(macro_or_string)        STRINGIFY_ARG (macro_or_string)


#if defined(__GNUC__) && (__GNUC__ < 3) && !defined(__cplusplus)
#  define STRLOC        __FILE__ ":" STRINGIFY (__LINE__) ":" __PRETTY_FUNCTION__ "()"
#else
#  define STRLOC        __FILE__ ":" STRINGIFY (__LINE__)
#endif


#if defined (__GNUC__)
#  define STRFUNC     ((const char*) (__PRETTY_FUNCTION__))
#elif defined (__STDC_VERSION__) && __STDC_VERSION__ >= 19901L
#  define STRFUNC     ((const char*) (__func__))
#else
#  define STRFUNC     ((const char*) ("???"))
#endif

#if defined __GNUC__
# define alignof(type) (__alignof__(type))
#else
# define alignof(type) (offsetof (struct { char __slot1; type __slot2; }, __slot2))
#endif

/*:22*/
#line 504 "./marpa_ami.w"

/*23:*/
#line 470 "./marpa_ami.w"

typedef unsigned int BITFIELD;
/*22:*/
#line 420 "./marpa_ami.w"


#if     __GNUC__ >  2 || (__GNUC__ == 2 && __GNUC_MINOR__ >  4)
#define UNUSED __attribute__((__unused__))
#else
#define UNUSED
#endif

#if defined (__GNUC__) && defined (__STRICT_ANSI__)
#  undef inline
#  define inline __inline__
#endif

#undef Dim
#define Dim(x) (sizeof(x)/sizeof(*x))

#undef      MAX
#define MAX(a, b)  (((a) >  (b)) ? (a) : (b))

#undef      CLAMP
#define CLAMP(x, low, high)  (((x) >  (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

#undef STRINGIFY_ARG
#define STRINGIFY_ARG(contents)       #contents
#undef STRINGIFY
#define STRINGIFY(macro_or_string)        STRINGIFY_ARG (macro_or_string)


#if defined(__GNUC__) && (__GNUC__ < 3) && !defined(__cplusplus)
#  define STRLOC        __FILE__ ":" STRINGIFY (__LINE__) ":" __PRETTY_FUNCTION__ "()"
#else
#  define STRLOC        __FILE__ ":" STRINGIFY (__LINE__)
#endif


#if defined (__GNUC__)
#  define STRFUNC     ((const char*) (__PRETTY_FUNCTION__))
#elif defined (__STDC_VERSION__) && __STDC_VERSION__ >= 19901L
#  define STRFUNC     ((const char*) (__func__))
#else
#  define STRFUNC     ((const char*) ("???"))
#endif

#if defined __GNUC__
# define alignof(type) (__alignof__(type))
#else
# define alignof(type) (offsetof (struct { char __slot1; type __slot2; }, __slot2))
#endif

/*:22*/
#line 472 "./marpa_ami.w"

#define Boolean(value) ((value) ? 1 : 0)

/*:23*/
#line 505 "./marpa_ami.w"


#define marpa_new(type,count) ((type*) my_malloc((sizeof(type) *((size_t) (count) ) ) ) ) 
#define marpa_renew(type,p,count)  \
((type*) my_realloc((p) ,(sizeof(type) *((size_t) (count) ) ) ) )  \

#define MARPA_DSTACK_DECLARE(this) struct marpa_dstack_s this
#define MARPA_DSTACK_INIT(this,type,initial_size)  \
( \
((this) .t_count= 0) , \
((this) .t_base= marpa_new(type,((this) .t_capacity= (initial_size) ) ) )  \
) 
#define MARPA_DSTACK_INIT2(this,type)  \
MARPA_DSTACK_INIT((this) ,type,MAX(4,1024/sizeof(this) ) )  \

#define MARPA_DSTACK_IS_INITIALIZED(this) ((this) .t_base) 
#define MARPA_DSTACK_SAFE(this)  \
(((this) .t_count= (this) .t_capacity= 0) ,((this) .t_base= NULL) )  \

#define MARPA_DSTACK_COUNT_SET(this,n) ((this) .t_count= (n) )  \

#define MARPA_DSTACK_CLEAR(this) MARPA_DSTACK_COUNT_SET((this) ,0) 
#define MARPA_DSTACK_PUSH(this,type) ( \
(_MARPA_UNLIKELY((this) .t_count>=(this) .t_capacity)  \
?marpa_dstack_resize2(&(this) ,sizeof(type) )  \
:0) , \
((type*) (this) .t_base+(this) .t_count++)  \
) 
#define MARPA_DSTACK_POP(this,type) ((this) .t_count<=0?NULL: \
((type*) (this) .t_base+(--(this) .t_count) ) ) 
#define MARPA_DSTACK_INDEX(this,type,ix) (MARPA_DSTACK_BASE((this) ,type) +(ix) ) 
#define MARPA_DSTACK_TOP(this,type) (MARPA_DSTACK_LENGTH(this) <=0 \
?NULL \
:MARPA_DSTACK_INDEX((this) ,type,MARPA_DSTACK_LENGTH(this) -1) ) 
#define MARPA_DSTACK_BASE(this,type) ((type*) (this) .t_base) 
#define MARPA_DSTACK_LENGTH(this) ((this) .t_count) 
#define MARPA_DSTACK_CAPACITY(this) ((this) .t_capacity)  \

#define MARPA_STOLEN_DSTACK_DATA_FREE(data) (my_free(data) ) 
#define MARPA_DSTACK_DESTROY(this) MARPA_STOLEN_DSTACK_DATA_FREE(this.t_base) 
#define MARPA_DSTACK_RESIZE(this,type,new_size)  \
(marpa_dstack_resize((this) ,sizeof(type) ,(new_size) ) ) 

#line 507 "./marpa_ami.w"

/*14:*/
#line 316 "./marpa_ami.w"

struct marpa_dstack_s;
typedef struct marpa_dstack_s*MARPA_DSTACK;
/*:14*/
#line 508 "./marpa_ami.w"


/*:27*/
static inline void * marpa_dstack_resize2( struct marpa_dstack_s* this, int type_bytes);
static inline void * marpa_dstack_resize ( struct marpa_dstack_s *this, int type_bytes, int new_size);
/*28:*/
#line 511 "./marpa_ami.w"


/*15:*/
#line 319 "./marpa_ami.w"

struct marpa_dstack_s{int t_count;int t_capacity;void*t_base;};
/*:15*/
#line 513 "./marpa_ami.w"

/*7:*/
#line 196 "./marpa_ami.w"

static inline
void my_free(void*p)
{
free(p);
}

/*:7*//*8:*/
#line 203 "./marpa_ami.w"


static inline
void*my_malloc(size_t size)
{
void*newmem= malloc(size);
if(_MARPA_UNLIKELY(!newmem)){(*marpa__out_of_memory)();}
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
if(_MARPA_LIKELY(p!=NULL)){
void*newmem= realloc(p,size);
if(_MARPA_UNLIKELY(!newmem))(*marpa__out_of_memory)();
return newmem;
}
return my_malloc(size);
}

/*:8*//*16:*/
#line 321 "./marpa_ami.w"

static inline void*marpa_dstack_resize2(struct marpa_dstack_s*this,int type_bytes)
{
return marpa_dstack_resize(this,type_bytes,this->t_capacity*2);
}

/*:16*//*18:*/
#line 330 "./marpa_ami.w"

static inline void*
marpa_dstack_resize(struct marpa_dstack_s*this,int type_bytes,
int new_size)
{
if(new_size> this->t_capacity)
{

this->t_capacity= new_size;
this->t_base= my_realloc(this->t_base,(size_t)new_size*(size_t)type_bytes);
}
return this->t_base;
}

/*:18*/
#line 514 "./marpa_ami.w"


#endif 

/*:28*/
