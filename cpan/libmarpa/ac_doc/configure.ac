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
m4_define([marpa_micro_version], [110])
m4_define([marpa_version],
          [marpa_major_version.marpa_minor_version.marpa_micro_version])

AC_INIT([libmarpa-doc],[marpa_version],[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marpa])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([])

AC_CONFIG_FILES( [Makefile])
AC_OUTPUT

# vim: expandtab shiftwidth=4:
