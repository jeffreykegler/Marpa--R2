/*1289:*/
#line 14953 "./marpa.w"

/*1284:*/
#line 14911 "./marpa.w"

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

/*:1284*/
#line 14954 "./marpa.w"


#ifndef __MARPA_UTIL_H__
#define __MARPA_UTIL_H__

/*1235:*/
#line 14421 "./marpa.w"

#define my_new(type, count) ((type *)my_malloc((sizeof(type)*(count))))
#define my_renew(type, p, count) \
    ((type *)my_realloc((p), (sizeof(type)*(count))))

/*:1235*//*1260:*/
#line 14622 "./marpa.w"

#define MARPA_OFF_DEBUG1(a)
#define MARPA_OFF_DEBUG2(a, b)
#define MARPA_OFF_DEBUG3(a, b, c)
#define MARPA_OFF_DEBUG4(a, b, c, d)
#define MARPA_OFF_DEBUG5(a, b, c, d, e)
#define MARPA_OFF_ASSERT(expr)
/*:1260*//*1290:*/
#line 14970 "./marpa.w"


#if     __GNUC__ >  2 || (__GNUC__ == 2 && __GNUC_MINOR__ >  4)
#define UNUSED __attribute__((__unused__))
#else
#define UNUSED
#endif

#if defined (__GNUC__) && defined (__STRICT_ANSI__)
#  undef inline
#  define inline __inline__
#endif

#undef      MAX
#define MAX(a, b)  (((a) >  (b)) ? (a) : (b))

#undef      CLAMP
#define CLAMP(x, low, high)  (((x) >  (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

#undef STRINGIFY_ARG
#define STRINGIFY_ARG(contents)       #contents
#undef STRINGIFY
#define STRINGIFY(macro_or_string)        STRINGIFY_ARG (macro_or_string)


#if defined(__GNUC__) && (__GNUC__ < 3) && !defined(__cplusplus)
#  define STRLOC __FILE__ ":" STRINGIFY (__LINE__) ":" __PRETTY_FUNCTION__ "()"
#else
#  define STRLOC __FILE__ ":" STRINGIFY (__LINE__)
#endif


#if defined (__GNUC__)
#  define STRFUNC     ((const char*) (__PRETTY_FUNCTION__))
#elif defined (__STDC_VERSION__) && __STDC_VERSION__ >= 19901L
#  define STRFUNC     ((const char*) (__func__))
#else
#  define STRFUNC     ((const char*) ("???"))
#endif

#if defined(__GNUC__) && (__GNUC__ >  2) && defined(__OPTIMIZE__)
#define LIKELY(expr) (__builtin_expect ((expr), 1))
#define UNLIKELY(expr) (__builtin_expect ((expr), 0))
#else
#define LIKELY(expr) (expr)
#define UNLIKELY(expr) (expr)
#endif

#if defined __GNUC__
# define alignof(type) (__alignof__(type))
#else
# define alignof(type) (offsetof (struct { char __slot1; type __slot2; }, __slot2))
#endif

/*:1290*/
#line 14959 "./marpa.w"

/*1269:*/
#line 14679 "./marpa.w"


#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#if MARPA_DEBUG

#undef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 1

#define MARPA_DEBUG1(a)  (_marpa_debug_level && \
    (*_marpa_debug_handler)(a)) 
#define MARPA_DEBUG2(a,b)  (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b))) 
#define MARPA_DEBUG3(a,b,c)  (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c))) 
#define MARPA_DEBUG4(a,b,c,d)  (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c),(d))) 
#define MARPA_DEBUG5(a,b,c,d,e)  (_marpa_debug_level && \
    (*_marpa_debug_handler)((a),(b),(c),(d),(e))) 

#define MARPA_ASSERT(expr) do { if LIKELY (expr) ; else \
       (*_marpa_debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
#else 
#define MARPA_DEBUG1(a) 
#define MARPA_DEBUG2(a, b) 
#define MARPA_DEBUG3(a, b, c) 
#define MARPA_DEBUG4(a, b, c, d) 
#define MARPA_DEBUG5(a, b, c, d, e) 
#define MARPA_ASSERT(exp) 
#endif

#ifndef MARPA_ENABLE_ASSERT
#define MARPA_ENABLE_ASSERT 0
#endif

#if MARPA_ENABLE_ASSERT
#undef MARPA_ASSERT
#define MARPA_ASSERT(expr) do { if LIKELY (expr) ; else \
       (*_marpa_debug_handler) ("%s: assertion failed %s", STRLOC, #expr); } while (0);
#endif

/*:1269*/
#line 14960 "./marpa.w"

/*1225:*/
#line 14292 "./marpa.w"

extern void*(*_marpa_out_of_memory)(void);

/*:1225*//*1262:*/
#line 14643 "./marpa.w"

extern int(*_marpa_debug_handler)(const char*,...);
extern int _marpa_debug_level;
/*:1262*//*1263:*/
#line 14650 "./marpa.w"

#if MARPA_DEBUG >  0
extern int _marpa_default_debug_handler(const char*format,...);
#define MARPA_DEFAULT_DEBUG_HANDLER _marpa_default_debug_handler
#else
#define MARPA_DEFAULT_DEBUG_HANDLER NULL
#endif

/*:1263*/
#line 14961 "./marpa.w"

/*1233:*/
#line 14379 "./marpa.w"

static inline
void my_free(void*p)
{
free(p);
}

/*:1233*//*1234:*/
#line 14388 "./marpa.w"

#define MALLOC_VIA_TEMP(size, temp) \
  (UNLIKELY(!((temp) =  malloc(size))) ? (*_marpa_out_of_memory)() : (temp))
static inline
void*my_malloc(size_t size)
{
void*newmem;
return MALLOC_VIA_TEMP(size,newmem);
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

/*:1234*/
#line 14962 "./marpa.w"


#endif 

/*:1289*/
