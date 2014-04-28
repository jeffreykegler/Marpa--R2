#!perl
# Copyright 2014 Jeffrey Kegler
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

# Copy things into stage/
# It makes more sense to do this in Perl than in the Makefile

use 5.010;
use File::Spec;
use File::Copy;
use Getopt::Long;
use autodie;    # Portability not essential in this script

my $verbose;
GetOptions( "verbose|v" => \$verbose )
    or die("Error in command line arguments\n");

FILE: while ( my $copy = <DATA> ) {
    chomp $copy;
    my ( $to, $from ) = $copy =~ m/\A (.*) [:] \s+ (.*) \z/xms;
    die "Bad copy spec: $copy" if not defined $to;
    next FILE if -e $to and ( -M $to <= -M $from );
    my ( undef, $to_dirs, $to_file ) = File::Spec->splitpath($to);
    my @to_dirs = File::Spec->splitdir($to_dirs);
    my @dir_found_so_far = ();
    # Make the directories we do not find
    DIR_PIECE: for my $dir_piece (@to_dirs) {
	push @dir_found_so_far, $dir_piece;
	my $dir_so_far = File::Spec->catdir(@dir_found_so_far);
        next DIR_PIECE if -e $dir_so_far;
	mkdir $dir_so_far;
    }
    File::Copy::copy($from, $to) or die "Cannot copy $from -> $to";
    say "Copied $from -> $to" if $verbose;
} ## end FILE: while ( my $copy = <DATA> )

# Note that order DOES matter here -- the configure.ac files
# MUST be FIRST

__DATA__
doc/configure.ac: ac_doc/configure.ac
stage/configure.ac: ac/configure.ac
doc/Makefile.am: ac_doc/Makefile.am
stage/Makefile.am: ac/Makefile.am
stage/Makefile.win32: win32/Makefile.win32
stage/win32/do_config_h.pl: win32/do_config_h.pl
stage/marpa.c: dev/marpa.c
stage/win32/marpa.def: dev/marpa.def
stage/marpa.h: public/marpa.h
stage/marpa_slif.h: public/marpa_slif.h
stage/marpa_obs.c: obs/marpa_obs.c
stage/marpa_obs.h: obs/marpa_obs.h
stage/marpa_ami.c: ami/marpa_ami.c
stage/marpa_codes.c: public/marpa_codes.c
stage/marpa_slif.c: slif/marpa_slif.c
stage/marpa_ami.h: ami/marpa_ami.h
stage/marpa_avl.c: avl/marpa_avl.c
stage/marpa_avl.h: avl/marpa_avl.h
stage/marpa_tavl.h: tavl/marpa_tavl.h
stage/marpa_tavl.c: tavl/marpa_tavl.c
stage/AUTHORS: ac/AUTHORS
stage/COPYING.LESSER: ac/COPYING.LESSER
stage/ChangeLog: ac/ChangeLog
stage/NEWS: ac/NEWS
stage/README: ac/README
stage/VERSION.in: public/VERSION.in
doc/README: ac_doc/README
doc/NEWS: ac_doc/NEWS
doc/AUTHORS: ac_doc/AUTHORS
doc/COPYING.LESSER: ac_doc/COPYING.LESSER
doc/ChangeLog: ac_doc/ChangeLog
doc/fdl-1.3.texi: ac_doc/fdl-1.3.texi
doc/lgpl-3.0.texi: ac_doc/lgpl-3.0.texi
doc/api.texi: dev/api.texi
doc/internal.texi: dev/internal.texi
stage/notes/shared_test.txt: notes/shared_test.txt
