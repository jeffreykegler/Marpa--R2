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

package Marpa::R2::HTML::Test::Util;

# The original of this code was copied from Andy Lester's Ack
# package

use 5.010;
use strict;
use warnings;

use Test::More;
use English qw( -no_match_vars );
use File::Spec;
use Fatal qw(unlink open close);
use Carp;
use CPAN::Version;

# capture stderr output into this file
my $catcherr_file = 'stderr.log';

sub is_win32 {
    return $OSNAME =~ /Win32/xms;
}

# capture-stderr is executing ack and storing the stderr output in
# $catcherr_file in a portable way.
#
# The quoting of command line arguments depends on the OS
sub build_command_line {
    my (@args) = @_;

    if ( is_win32() ) {
        for (@args) {
            s/(\\+)$/$1$1/xms;    # Double all trailing backslashes
            s/"/\\"/gxms;         # Backslash all quotes
            $_ = qq{"$_"};
        }
    } ## end if ( is_win32() )
    else {
        @args = map { quotemeta $_ } @args;
    }

    return "$EXECUTABLE_NAME -Ilib @args";

} ## end sub build_command_line

sub run_command {
    my ( $command, @args ) = @_;

    my ( $stdout, $stderr ) = run_with_stderr( $command, @args );

    Test::More::is( $stderr, q{},
        "Should have no output to stderr: $command @args" )
        or Test::More::diag("STDERR:\n$stderr");

    return $stdout;
} ## end sub run_command

sub run_with_stderr {
    my @args = @_;

    my $cmd = build_command_line(@args);

    ## no critic (InputOutput::ProhibitBacktickOperators)
    my $stdout = `$cmd`;
    ## use critic

    my ( $sig, $core, $rc ) = (
        ( $CHILD_ERROR & 127 ),
        ( $CHILD_ERROR & 128 ),
        ( $CHILD_ERROR >> 8 ),
    );

    return ( $stdout, q{}, $rc );

} ## end sub run_with_stderr

# This method must be called *BEFORE* any test plan is
# written -- it creates its own test plan
sub load_or_skip_all {
    my ($module_name) = @_;
## no critic(BuiltinFunctions::ProhibitStringyEval)
    my $eval_result = eval "require $module_name; '$module_name'->import; 1";
    if ( !$eval_result ) {
        my $eval_error = $EVAL_ERROR;
        $eval_error =~ s/^/# /gxms;
        print "1..0 # Skip Could not load $module_name\n", $eval_error
            or Carp::croak("say failed: $ERRNO");
        exit 0;
    } ## end if ( !$eval_result )
    use lib 'config';
    $eval_result = eval { require Marpa::R2::Config; 1 };
    if ( !$eval_result ) {
	Test::More::plan tests => 1;
	Test::More::diag($EVAL_ERROR);
	Test::More::fail("Could not load Marpa::R2::Config\n");
        exit 0;
    } ## end if ( !$eval_result )
    my $version_wanted = $Marpa::R2::VERSION_FOR_CONFIG{$module_name};
    if ( not defined $version_wanted ) {
	Test::More::plan tests => 1;
	Test::More::fail("$module_name is not known to Marpa::R2");
        exit 0;
    }
    my $module_version = eval q{$} . $module_name . '::VERSION';
    if ( CPAN::Version->vlt( $module_version, $version_wanted ) ) {
        say
            "1..0 # Skip $module_name version is $module_version; we wanted $version_wanted"
            or Carp::croak("say failed: $ERRNO");
        exit 0;
    } ## end if ( vlt( $module_version, $version_wanted ) )
} ## end sub load_or_skip_all

1;
