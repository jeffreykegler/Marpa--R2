# Copyright 2018 Jeffrey Kegler
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.68])

dnl ***********************************
dnl *** include special marpa macros ***
dnl ***********************************

m4_define(marpa_configure_in)

m4_include(version.m4)
m4_define([marpa_version],
          [marpa_major_version.marpa_minor_version.marpa_micro_version])

AC_INIT([libmarpa],[marpa_version],[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marpa])
AM_MAINTAINER_MODE([enable])

# The safety check of the next line is as suggested by autoscan
AC_CONFIG_SRCDIR([marpa_ami.h])

AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([])

# Specify a configuration file
AC_CONFIG_HEADERS([config.h])

LT_INIT()

# Checks for programs.
# The following were suggested by autoscan
AC_PROG_AWK
AC_PROG_CC
AC_PROG_CPP
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET

# Checks for libraries.

# Checks for header files.
# The following were suggested by autoscan
AC_CHECK_HEADERS([stddef.h stdlib.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_INLINE
AC_TYPE_SIZE_T

if test x"$GCC" = xyes; then

marpa_save_CFLAGS="$CFLAGS"
CFLAGS="$marpa_save_CFLAGS -Wextra"
AC_CACHE_CHECK([whether GCC handles -Wextra],
    [marpa_cv_prog_gcc_wextra],
    [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[])],
                                       [marpa_cv_prog_gcc_wextra=-Wextra],
                                       [marpa_cv_prog_gcc_wextra=])])
CFLAGS="$marpa_save_CFLAGS -Wdeclaration-after-statement"
AC_CACHE_CHECK([whether GCC handles -Wdeclaration-after-statement],
    [marpa_cv_prog_gcc_wdas],
    [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[])],
                                       [marpa_cv_prog_gcc_wdas=-Wdeclaration-after-statement],
                                       [marpa_cv_prog_gcc_wdas=])])
CFLAGS="$marpa_save_CFLAGS"

dnl -Winline eliminated because it was too noisy
dnl One to a line to make these easy to edit
WARNING_CFLAGS="-Wall \
$marpa_cv_prog_gcc_wextra \
$marpa_cv_prog_gcc_wdas \
-Wpointer-arith \
-Wstrict-prototypes \
-Wwrite-strings \
-Wshadow \
-Wmissing-declarations \
-Wconversion \
-ansi -pedantic"

WARNING_CPPFLAGS=" \
-Wundef \
-Wendif-labels"

fi

if test x"$MARPA_DEBUG_FLAG" = x; then
    MARPA_DEBUG_FLAG=
fi

AC_SUBST(WARNING_CFLAGS)
AC_SUBST(WARNING_CPPFLAGS)

# There are two sets of version numbers, one that travels as
# a define with the public headers, and this one, which is compiled
# into the library.  Both *should* be the same.
# We use these duplicate headers to make sure applications match the
# right headers to the right library, and also for some sanity checking
# at build and development time.
AC_SUBST(MARPA_LIB_MAJOR_VERSION, [marpa_major_version])
AC_SUBST(MARPA_LIB_MINOR_VERSION, [marpa_minor_version])
AC_SUBST(MARPA_LIB_MICRO_VERSION, [marpa_micro_version])
AC_DEFINE([MARPA_LIB_MAJOR_VERSION], [marpa_major_version], [Marpa major version.])
AC_DEFINE([MARPA_LIB_MINOR_VERSION], [marpa_minor_version], [Marpa minor version.])
AC_DEFINE([MARPA_LIB_MICRO_VERSION], [marpa_micro_version], [Marpa micro version.])
AC_ARG_VAR(MARPA_DEBUG_FLAG,[Marpa debugging])

AC_CHECK_SIZEOF([int])
if test "$ac_cv_sizeof_int" -lt 4; then
    AC_MSG_ERROR(
        [Marpa requires that int be at least 32 bits -- on this system that is not the case])
fi

# This was to prepare for 64-bit pseudo-UTF8 characters (which full Perl-style
# Unicode support would require) in the SLIF.  This approach needs to be re-thought
# 
# AC_TYPE_UNSIGNED_LONG_LONG_INT
# if test x"$ac_cv_type_unsigned_long_long_int" != xyes; then
#      AC_MSG_ERROR(
#          [Marpa requires an unsigned long long type -- this compiler does not have one])
# fi

# Checks for library functions.
# The following were suggested by autoscan
AC_CHECK_FUNCS([memset])

AC_CONFIG_FILES( [Makefile libmarpa.pc])
AC_OUTPUT

# vim: expandtab shiftwidth=4:
