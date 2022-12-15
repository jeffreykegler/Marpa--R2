/*
 * Utility routines for writing floating point tests.
 *
 * Currently provides only one function, which checks whether a double is
 * equal to an expected value within a given epsilon.  This is broken into a
 * separate source file from the rest of the basic C TAP library because it
 * may require linking with -lm on some platforms, and the package may not
 * otherwise care about floating point.
 *
 * This file is part of C TAP Harness.  The current version plus supporting
 * documentation is at <https://www.eyrie.org/~eagle/software/c-tap-harness/>.
 *
 * Copyright 2008, 2010, 2012-2019 Russ Allbery <eagle@eyrie.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * SPDX-License-Identifier: MIT
 */

/* Required for isnan() and isinf(). */
#if defined(__STRICT_ANSI__) || defined(PEDANTIC)
#    ifndef _XOPEN_SOURCE
#        define _XOPEN_SOURCE 600
#    endif
#endif

#include <math.h>
#include <stdarg.h>
#include <stdio.h>

#include <tests/tap/basic.h>
#include <tests/tap/float.h>

/*
 * Clang 4.0.1 gets very confused by this file and produces warnings about
 * floating point implicit conversion from the isnan() and isinf() macros.
 */
#if defined(__llvm__) || defined(__clang__)
#    pragma clang diagnostic ignored "-Wconversion"
#    pragma clang diagnostic ignored "-Wdouble-promotion"
#endif

/*
 * Returns true if the two doubles are equal infinities, false otherwise.
 * This requires a bit of machination since isinf is not required to return
 * different values for positive and negative infinity, and we're trying to
 * avoid direct comparisons between floating point numbers.
 */
static int
is_equal_infinity(double left, double right)
{
    if (!isinf(left) || !isinf(right))
        return 0;
    return !!(left < 0) == !!(right < 0);
}

/*
 * Takes two doubles and requires they be within epsilon of each other.
 */
int
is_double(double left, double right, double epsilon, const char *format, ...)
{
    va_list args;
    int success;

    va_start(args, format);
    fflush(stderr);
    if ((isnan(left) && isnan(right)) || is_equal_infinity(left, right)
        || fabs(left - right) <= epsilon) {
        success = 1;
        okv(1, format, args);
    } else {
        success = 0;
        diag(" left: %g", left);
        diag("right: %g", right);
        okv(0, format, args);
    }
    va_end(args);
    return success;
}
