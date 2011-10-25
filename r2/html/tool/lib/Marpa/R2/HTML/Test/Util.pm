# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

package Marpa::HTML::Test::Util;

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
    # capture-stderr drops core on my Mac OS Tiger laptop
    # return
        # "$EXECUTABLE_NAME -Ilib ./lib/Marpa/HTML/Test/capture-stderr $catcherr_file @args";
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

    # Previous logic drops core on Darwin
    # open my $fh, '<', $catcherr_file;
    # my $stderr = do { local $RS = undef; <$fh> };
    # close $fh;
    # unlink $catcherr_file;

    return ( $stdout, q{}, $rc );
    # return ( $stdout, $stderr, $rc );
} ## end sub run_with_stderr

1;
