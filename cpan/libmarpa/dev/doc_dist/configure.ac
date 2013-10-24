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
m4_define([marpa_minor_version], [172])
m4_define([marpa_micro_version], [100])
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

# I am not using this system, at least not right now.
# So I've commented it out, while I decide
# whether to delete these lines permanently or adopt it.
#
# if the minor version number is odd, then we want debugging.  Otherwise
# we only want minimal debugging support.
# m4_define([marpa_debug_default],
#          [m4_if(m4_eval(marpa_minor_version % 2), [1], [yes], [minimum])])dnl

AC_INIT([libmarpa-doc],[marpa_version],[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marpa])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([])

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

# I am not using this enable-debug, so I've commented it out, while I decide
# whether to delete these lines or switch to this system.
#
# dnl declare --enable-* args and collect ac_help strings
# AC_ARG_ENABLE(debug,
#               AS_HELP_STRING([--enable-debug=@<:@no/minimum/yes@:>@],
#                              [turn on debugging @<:@default=marpa_debug_default@:>@]),,
#               enable_debug=marpa_debug_default)

dnl this section will only be run if config.status is invoked with no
dnl arguments, or with "marpa_config.h" as an argument.
AC_CONFIG_COMMANDS([marpa_config.h],
[
	outfile=marpa_config.h-tmp
	cat > $outfile <<_______EOF
/* marpa_config.h
 *
 * This is a generated file.  Please modify 'configure.ac'
 */

#ifndef __MARPA_CONFIG_H__
#define __MARPA_CONFIG_H__

$marpa_defines

#endif /* __MARPA_CONFIG_H__ */

_______EOF

	if cmp -s $outfile marpa_config.h; then
	  AC_MSG_NOTICE([marpa_config.h is unchanged])
	  rm -f $outfile
	else
	  mv $outfile marpa_config.h
	fi
],[

marpa_defines="
#define MARPA_MAJOR_VERSION $MARPA_MAJOR_VERSION
#define MARPA_MINOR_VERSION $MARPA_MINOR_VERSION
#define MARPA_MICRO_VERSION $MARPA_MICRO_VERSION
"

])

AC_CONFIG_FILES( [Makefile])
AC_OUTPUT

