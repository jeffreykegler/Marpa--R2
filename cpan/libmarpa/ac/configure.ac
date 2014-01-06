# Copyright 2013 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.68])

dnl ***********************************
dnl *** include special marpa macros ***
dnl ***********************************

m4_define(marpa_configure_in)

m4_define([marpa_major_version], [5])
m4_define([marpa_minor_version], [179])
m4_define([marpa_micro_version], [106])
m4_define([marpa_version],
          [marpa_major_version.marpa_minor_version.marpa_micro_version])

AC_INIT([libmarpa],[marpa_version],[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marpa])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([])

# Specify a configuration file
AC_CONFIG_HEADERS([config.h])

LT_INIT([])

# Checks for programs.
AC_PROG_CC
AC_PROG_CPP
AC_PROG_LN_S

# Checks for header files.
AC_CHECK_HEADERS([inttypes.h stddef.h stdint.h stdlib.h string.h limits.h])
AC_CHECK_FUNCS([memset])

# Checks for typedefs, structures, and compiler characteristics.
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
AC_ARG_VAR(MARPA_DEBUG_FLAG,[Marpa debugging])

AC_CHECK_SIZEOF([int])
if test "$ac_cv_sizeof_int" -lt 4; then
    AC_MSG_ERROR(
        [Marpa requires that int be at least 32 bits -- on this system that is not the case])
fi

AC_TYPE_UNSIGNED_LONG_LONG_INT
if test x"$ac_cv_type_unsigned_long_long_int" != xyes; then
    AC_MSG_ERROR(
        [Marpa requires an unsigned long long type -- this compiler does not have one])
fi

AC_C_INLINE

AC_CONFIG_FILES( [Makefile])
AC_OUTPUT

# vim: expandtab shiftwidth=4:
