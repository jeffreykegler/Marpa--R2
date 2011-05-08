# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

dnl Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)

dnl ***********************************
dnl *** include special marpa macros ***
dnl ***********************************

m4_define(marpa_configure_in)

# Making releases:
#   marpa_micro_version += 1;
#   marpa_interface_age += 1;
#   marpa_binary_age += 1;
# if any functions have been added, set marpa_interface_age to 0.
# if backwards compatibility has been broken,
# set marpa_binary_age _and_ marpa_interface_age to 0.
#
m4_define([marpa_major_version], [0])
m4_define([marpa_minor_version], [1])
m4_define([marpa_micro_version], [0])
m4_define([marpa_interface_age], [100])
m4_define([marpa_binary_age],
          [m4_eval(100 * marpa_minor_version + marpa_micro_version)])
m4_define([marpa_version],
          [marpa_major_version.marpa_minor_version.marpa_micro_version])

# libtool version related macros
m4_define([marpa_lt_release], [marpa_major_version.marpa_minor_version])
m4_define([marpa_lt_current],
          [m4_eval(100 * marpa_minor_version + marpa_micro_version - marpa_interface_age)])
m4_define([marpa_lt_revision], [marpa_interface_age])
m4_define([marpa_lt_age], [m4_eval(marpa_binary_age - marpa_interface_age)])
m4_define([marpa_lt_current_minus_age],
          [m4_eval(marpa_lt_current - marpa_lt_age)])

# if the minor version number is odd, then we want debugging.  Otherwise
# we only want minimal debugging support.
m4_define([marpa_debug_default],
          [m4_if(m4_eval(marpa_minor_version % 2), [1], [yes], [minimum])])dnl

AC_INIT([marpa], [marpa_version],
    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marpa])

AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign])

# Specify a configuration file
AC_CONFIG_HEADERS([config.h])

MARPA_MAJOR_VERSION=marpa_major_version
MARPA_MINOR_VERSION=marpa_minor_version
MARPA_MICRO_VERSION=marpa_micro_version
MARPA_INTERFACE_AGE=marpa_interface_age
MARPA_BINARY_AGE=marpa_binary_age
MARPA_VERSION=marpa_version

AC_SUBST(MARPA_MAJOR_VERSION)
AC_SUBST(MARPA_MINOR_VERSION)
AC_SUBST(MARPA_MICRO_VERSION)
AC_SUBST(MARPA_VERSION)
AC_SUBST(MARPA_INTERFACE_AGE)
AC_SUBST(MARPA_BINARY_AGE)

AC_DEFINE(MARPA_MAJOR_VERSION, [marpa_major_version],
	  [Define to the MARPA major version])
AC_DEFINE(MARPA_MINOR_VERSION, [marpa_minor_version],
	  [Define to the MARPA minor version])
AC_DEFINE(MARPA_MICRO_VERSION, [marpa_micro_version],
	  [Define to the MARPA micro version])
AC_DEFINE(MARPA_INTERFACE_AGE, [marpa_interface_age],
	  [Define to the MARPA interface age])
AC_DEFINE(MARPA_BINARY_AGE, [marpa_binary_age],
	  [Define to the MARPA binary age])

# libtool versioning
LT_RELEASE=marpa_lt_release
LT_CURRENT=marpa_lt_current
LT_REVISION=marpa_lt_revision
LT_AGE=marpa_lt_age
LT_CURRENT_MINUS_AGE=marpa_lt_current_minus_age
AC_SUBST(LT_RELEASE)
AC_SUBST(LT_CURRENT)
AC_SUBST(LT_REVISION)
AC_SUBST(LT_AGE)
AC_SUBST(LT_CURRENT_MINUS_AGE)

dnl declare --enable-* args and collect ac_help strings
AC_ARG_ENABLE(debug,
              AS_HELP_STRING([--enable-debug=@<:@no/minimum/yes@:>@],
                             [turn on debugging @<:@default=marpa_debug_default@:>@]),,
              enable_debug=marpa_debug_default)

LT_INIT([pic-only])

# Checks for programs.
AC_PROG_CC
AC_PROG_CPP
AC_PROG_CXX
AC_PROG_LN_S

# Checks for header files.
AC_CHECK_HEADERS([inttypes.h stddef.h stdint.h stdlib.h string.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_SIZE_T

if test x"$GCC" = xyes; then
  WARNING_CFLAGS="-Wall \
    -Wextra \
    -Wpointer-arith \
    -Wstrict-prototypes \
    -Wwrite-strings \
    -Wdeclaration-after-statement \
    -Wshadow \
    -Winline \
    -Wmissing-declarations \
    -Wconversion \
    -ansi -pedantic"
fi

AC_SUBST(WARNING_CFLAGS)

# The following logic,
# for detailed checking of inline capabilities,
# is from the glib configuration file

dnl AC_C_INLINE is useless to us since it bails out too early, we need to
dnl truely know which ones of `inline', `__inline' and `__inline__' are
dnl actually supported.
AC_CACHE_CHECK([for __inline],marpa_cv_has__inline,[
        AC_COMPILE_IFELSE([
	__inline int foo () { return 0; }
	int main () { return foo (); }
       	],
	marpa_cv_has__inline=yes
        ,
	marpa_cv_has__inline=no
        ,)
])
case x$marpa_cv_has__inline in
xyes) AC_DEFINE(MARPA_HAVE___INLINE,1,[Have __inline keyword])
esac
AC_CACHE_CHECK([for __inline__],marpa_cv_has__inline__,[
        AC_COMPILE_IFELSE([
	__inline__ int foo () { return 0; }
	int main () { return foo (); }
       	],
	marpa_cv_has__inline__=yes
        ,
	marpa_cv_has__inline__=no
        ,)
])
case x$marpa_cv_has__inline__ in
xyes) AC_DEFINE(MARPA_HAVE___INLINE__,1,[Have __inline__ keyword])
esac
AC_CACHE_CHECK([for inline], marpa_cv_hasinline,[
        AC_COMPILE_IFELSE([
	#undef inline
	inline int foo () { return 0; }
	int main () { return foo (); }
       	],
	marpa_cv_hasinline=yes
        ,
	marpa_cv_hasinline=no
        ,)
])
case x$marpa_cv_hasinline in
xyes) AC_DEFINE(MARPA_HAVE_INLINE,1,[Have inline keyword])
esac

# if we can use inline functions in headers
AC_MSG_CHECKING(if inline functions in headers work)
AC_LINK_IFELSE([
#if defined (MARPA_HAVE_INLINE) && defined (__GNUC__) && defined (__STRICT_ANSI__)
#  undef inline
#  define inline __inline__
#elif !defined (MARPA_HAVE_INLINE)
#  undef inline
#  if defined (MARPA_HAVE___INLINE__)
#    define inline __inline__
#  elif defined (MARPA_HAVE___INLINE)
#    define inline __inline
#  endif
#endif

int marpa_test_func2 (int);

static inline int
marpa_test_func1 (void) {
  return marpa_test_func2 (1);
}

int
main (void) {
  int i = 1;
}],
        [marpa_cv_can_inline=1]
    ,
        [marpa_cv_can_inline=0]
    ,
)
AC_MSG_RESULT([MARPA_CAN_INLINE set to $marpa_cv_can_inline]);
AC_DEFINE_UNQUOTED( [MARPA_CAN_INLINE], $marpa_cv_can_inline, [Does header inlining actually take place?])

# This comment marks the end of the inline configuration logic
# taken from the glib configuration file

PKG_PROG_PKG_CONFIG([0.22])
PKG_CHECK_MODULES(GLIB, [glib-2.0 >= 2.6.0] )

AC_CONFIG_FILES([Makefile])
AC_OUTPUT

