#!perl

use 5.010;
use strict;
use warnings;
use autodie;
use IPC::Cmd;
use Cwd;

my $commitish = 'master';
my $libmarpa_repo = 'git@github.com:jeffreykegler/libmarpa.git';
my $stage = 'core/stage';

die "core/stage already exists" if -r $stage;
die "libmarpa_build already exists" if -r 'libmarpa_build';

if (not IPC::Cmd::run(
        command => [ qw(git clone --depth 1), $libmarpa_repo, $stage ],
        verbose => 1
    )
    )
{
    die "Could not clone";
} ## end if ( not IPC::Cmd::run( command => [ qw(git clone -n --depth 1)...]))

if (not IPC::Cmd::run(
        command => [ qw(git checkout), $commitish ],
        verbose => 1
    )
    )
{
    die qq{Could not checkout "$commitish"};
} ## end if ( not IPC::Cmd::run( command => [ qw(git checkout)...]))

# CHIDR into staging dir
chdir $stage || die "Could not chdir";

if (not IPC::Cmd::run(
        command => [ qw(make dist) ],
        verbose => 1
    )
    )
{
    die qq{Could not make dist};
} ## end if ( not IPC::Cmd::run( command => [ qw(git checkout)...]))

if (not IPC::Cmd::run(
        command => [ qw(sh etc/cp_libmarpa.sh ../../libmarpa_build) ],
        verbose => 1
    )
    )
{
    die qq{Could not make dist};
} ## end if ( not IPC::Cmd::run( command => [ qw(git checkout)...]))

exit 0
