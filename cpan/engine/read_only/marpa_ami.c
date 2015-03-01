/*
 * Copyright 2015 Jeffrey Kegler
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


/*
 * DO NOT EDIT DIRECTLY
 * This file is written by the Marpa build process
 * It is not intended to be modified directly
 */

/*30:*/
#line 524 "./marpa_ami.w"


#include "config.h"

/*:30*//*31:*/
#line 537 "./marpa_ami.w"


#include <stdarg.h> 
#include <stdio.h> 

/*:31*//*32:*/
#line 542 "./marpa_ami.w"


#ifndef MARPA_DEBUG
#define MARPA_DEBUG 0
#endif

#include "marpa.h"
#include "marpa_ami.h"

/*5:*/
#line 184 "./marpa_ami.w"

#define PRIVATE_NOT_INLINE static
#define PRIVATE static inline

/*:5*/
#line 551 "./marpa_ami.w"


/*:32*/

#line 1 "./marpa_ami.c.p40"

/*33:*/
#line 556 "./marpa_ami.w"


/*20:*/
#line 365 "./marpa_ami.w"

int marpa__default_debug_handler(const char*format,...)
{
va_list args;
va_start(args,format);
vfprintf(stderr,format,args);
va_end(args);
putc('\n',stderr);
return 1;
}


/*:20*/
#line 558 "./marpa_ami.w"


/*:33*/
