#!/usr/bin/perl
# Copyright 2015 Jeffrey Kegler
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

use 5.010;
use strict;
use warnings;
use autodie;
use IPC::Cmd;
use File::Path;

my $libmarpa_repo = 'git@github.com:jeffreykegler/libmarpa.git';
my $stage = 'engine/stage';

my $deleted_count = File::Path::remove_tree($stage);
say "$deleted_count files deleted in $stage";

$deleted_count = File::Path::remove_tree('libmarpa_build');
say "$deleted_count files deleted in 'libmarpa_build'";

if (not IPC::Cmd::run(
        command => [ qw(git clone -b r2dev --depth 5), $libmarpa_repo, $stage ],
        verbose => 1
    )
    )
{
    die "Could not clone";
} ## end if ( not IPC::Cmd::run( command => [ qw(git clone -n --depth 1)...]))

# CHIDR into staging dir
chdir $stage || die "Could not chdir";

my $log_data;
if (not IPC::Cmd::run(
        command => [ qw(git log -n 5) ],
        verbose => 1,
	buffer => \$log_data
    )
    )
{
    die "Could not clone";
} ## end if ( not IPC::Cmd::run( command => [ qw(git clone -n --depth 1)...]))

{
   open my $fh, q{>}, '../LOG_DATA';
   print {$fh} $log_data;
   close $fh;
}

if (not IPC::Cmd::run(
        command => [ qw(make dist) ],
        verbose => 1
    )
    )
{
    die qq{Could not make dist};
} ## end if ( not IPC::Cmd::run( command => [ qw(git checkout)...]))

$deleted_count = File::Path::remove_tree('../read_only');
say "$deleted_count files deleted in ../read_only";

if (not IPC::Cmd::run(
        command => [ qw(sh etc/cp_libmarpa.sh ../read_only) ],
        verbose => 1
    )
    )
{
    die qq{Could not make dist};
} ## end if ( not IPC::Cmd::run( command => [ qw(git checkout)...]))

exit 0
