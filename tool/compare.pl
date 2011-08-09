#!perl
use 5.010;
use strict;
use warnings;
use File::Spec;
use File::Compare;
use File::Find;

my @found= ();
sub t_wanted {
     / [.] t \z /xms and push @found, $File::Find::name;
}
File::Find::find(\&t_wanted, 'xs/t', 'pp/t');
my %t_names = ();
FILE: for my $t_file (@found) {
    my ($volume, $tdir, $filename) = File::Spec->splitpath($t_file);
    next FILE if $filename eq '00-load.t';
    next FILE if $filename =~ / _ (xs|pp) [.] t \z /xms;
    my @dirs = File::Spec->splitdir($tdir);
    shift @dirs;
    my $t_subdir = File::Spec->catdir( @dirs );
    $t_names{ File::Spec->catpath( $volume, $t_subdir, $filename ) } = 1;
}
sub normalize_t_line {
   my $xs_line = $_[1];
   $xs_line =~ s/ Marpa [:][:] XS /Marpa::PP/xmsg;
   $xs_line =~ s/ Marpa [-] XS /Marpa-PP/xmsg;
say STDERR $_[0], " vs. $xs_line" if $_[0] ne $xs_line;
   return $_[0] ne $xs_line;
}
POD_NAME: for my $t_name (keys %t_names) {
    my ($volume, $tdir, $filename) = File::Spec->splitpath($t_name);
    my @dirs = File::Spec->splitdir($tdir);
    my $pp_t_dir = File::Spec->catdir( 'pp', @dirs );
    my $pp = File::Spec->catpath( $volume, $pp_t_dir, $filename );
    if ( !-f $pp ) {
	say STDERR "Missing $pp";
	next POD_NAME;
    }
    my $xs_t_dir = File::Spec->catdir( 'xs', @dirs );
    my $xs = File::Spec->catpath( $volume, $xs_t_dir, $filename );
    if ( !-f $xs ) {
	say STDERR "Missing $xs";
	next POD_NAME;
    }
    if ( File::Compare::compare_text( $pp, $xs, \&normalize_t_line) ) {
        say STDERR "Different: $pp vs $xs";
    }
}

@found= ();
sub pod_wanted {
     / [.] pod \z /xms and push @found, $File::Find::name;
}
File::Find::find(\&pod_wanted, 'xs/pod', 'pp/pod');
my %pod_names = ();
FILE: for my $pod_file (@found) {
    my ($volume, $poddir, $filename) = File::Spec->splitpath($pod_file);
    next FILE if $filename =~ /\A Marpa_ (XS|PP) [.] pod \z /xms;
    my @dirs = File::Spec->splitdir($poddir);
    shift @dirs;
    my $pod_subdir = File::Spec->catdir( @dirs );
    $pod_names{ File::Spec->catpath( $volume, $pod_subdir, $filename ) } = 1;
}
sub normalize_pod_line {
   my $xs_line = $_[1];
   $xs_line =~ s/ Marpa [:][:] XS /Marpa::PP/xmsg;
   $xs_line =~ s/ Marpa [-] XS /Marpa-PP/xmsg;
say STDERR $_[0], " vs. $xs_line" if $_[0] ne $xs_line;
   return $_[0] ne $xs_line;
}
POD_NAME: for my $pod_name (keys %pod_names) {
    my ($volume, $poddir, $filename) = File::Spec->splitpath($pod_name);
    my @dirs = File::Spec->splitdir($poddir);
    my $pp_pod_dir = File::Spec->catdir( 'pp', @dirs );
    my $pp = File::Spec->catpath( $volume, $pp_pod_dir, $filename );
    if ( !-f $pp ) {
	say STDERR "Missing $pp";
	next POD_NAME;
    }
    my $xs_pod_dir = File::Spec->catdir( 'xs', @dirs );
    my $xs = File::Spec->catpath( $volume, $xs_pod_dir, $filename );
    if ( !-f $xs ) {
	say STDERR "Missing $xs";
	next POD_NAME;
    }
    if ( File::Compare::compare_text( $pp, $xs, \&normalize_pod_line) ) {
        say STDERR "Different: $pp vs $xs";
    }
}

