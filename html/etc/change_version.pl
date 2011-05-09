#!perl

use 5.010;
use strict;
use warnings;
use Fatal qw(:void open close unlink select rename);
use English qw( -no_match_vars );
use Carp;

our $FH;

Carp::croak("usage: $PROGRAM_NAME: old_version new_version")
    if scalar @ARGV != 2;

my ( $old, $new ) = @ARGV;

say STDERR "$old $new" or Carp::croak("Cannot print: $ERRNO");

sub check_version {
    my $version = shift;
    my ( $major, $minor1, $underscore, $minor2 ) =
        ( $version =~ m/^ ([0-9]+) [.] ([0-9.]{3}) ([_]?) ([0-9.]{3}) $/xms );
    if ( not defined $minor2 ) {
        Carp::croak("Bad format in version number: $version");
    }
    if ( $minor1 % 2 and $underscore ne '_' ) {
        Carp::croak("No underscore in developer's version number: $version");
    }
    if ( $minor1 % 2 == 0 and $underscore eq '_' ) {
        Carp::croak(
            "Underscore in official release version number: $version");
    }
} ## end sub check_version

check_version($old);
check_version($new);

## no critic (BuiltinFunctions::ProhibitStringyEval)
Carp::croak("$old >= $new") if eval $old >= eval $new;
## use critic

sub change {
    my ( $fix, @files ) = @_;
    for my $file (@files) {
        open my $fh, '<', $file;
        my $text = do { local ($RS) = undef; <$fh> };
        close $fh;
        open my $argvout, '>', $file;
        print {$argvout} ${ $fix->( \$text, $file ) }
            or Carp::croak("Could not print to argvout: $ERRNO");
        close $argvout;
    } ## end for my $file (@files)
    return 1;
} ## end sub change

sub fix_build_pl {
    my $text_ref  = shift;
    my $file_name = shift;

    if ( ${$text_ref}
        !~ s/(our\s+\$MARPA_HTML_VERSION\s*=\s*')$old';/$1$new';/xms )
    {
        say {*STDERR}
            "failed to change VERSION from $old to $new in $file_name"
            or Carp::croak("Could not print to STDERR: $ERRNO");
    } ## end if ( ${$text_ref} !~ ...)
    return $text_ref;
} ## end sub fix_build_pl

sub fix_marpa_html_pm {
    my $text_ref  = shift;
    my $file_name = shift;

    if ( ${$text_ref} !~ s/(our\s+\$VERSION\s*=\s*')$old';/$1$new';/xms ) {
        say {*STDERR}
            "failed to change VERSION from $old to $new in $file_name"
            or Carp::croak("Could not print to STDERR: $ERRNO");
    }
    return $text_ref;
} ## end sub fix_marpa_html_pm

sub update_changes {
    my $text_ref  = shift;
    my $file_name = shift;

    my $date_stamp = localtime;
    if ( ${$text_ref}
        !~ s/(\ARevision\s+history\s+[^\n]*\n\n)/$1$new $date_stamp\n/xms )
    {
        say {*STDERR} "failed to add $new to $file_name"
            or Carp::croak("Could not print to STDERR: $ERRNO");
    } ## end if ( ${$text_ref} !~ ...)
    return $text_ref;
} ## end sub update_changes

change( \&fix_build_pl,      'Build.PL' );
change( \&fix_marpa_html_pm, 'lib/Marpa/HTML.pm' );
change( \&update_changes,    'Changes' );

say {*STDERR} 'REMEMBER TO UPDATE Changes file'
    or Carp::croak("Could not print to STDERR: $ERRNO");
say {*STDERR} q{REMEMBER TO RUN "(cd etc;make update)"}
    or Carp::croak("Could not print to STDERR: $ERRNO");
