#!perl
use 5.010;
use strict;
use warnings;
use File::Spec;
use File::Compare;
use File::Find;

my @t_files = ();
push @t_files, glob "pp/t/shared/*.t";
push @t_files, glob "pp/t/shared/common/*.t";
push @t_files, glob "xs/t/shared/*.t";
push @t_files, glob "xs/t/shared/common/*.t";
my %t_file = ();
for my $t_file (@t_files) {
     my (undef, undef, $filename) = File::Spec->splitpath($t_file);
     $t_file{$filename}++;
}
my $eqx = 'xs/t/shared/equation.t';
my $eqp = 'pp/t/shared/equation.t';
for my $t_file ( keys %t_file ) {
    for my $file (
        map { $_ . $t_file }
        qw(
        pp/t/shared/ pp/t/shared/common/
        xs/t/shared/ xs/t/shared/common/ )
        )
    {
        if ( !-f $file ) {
            say STDERR "Missing $file";
        }
    } ## end for my $file ( map { $_ . $t_file } qw(...))
    my $pp = "pp/t/shared/common/$t_file";
    my $xs = "xs/t/shared/common/$t_file";
    if ( File::Compare::compare( $pp, $xs ) ) {
        say STDERR "Different: $pp vs $xs";
    }
    $pp = "pp/t/shared/$t_file";
    if ( File::Compare::compare( $pp, $eqp ) ) {
        say STDERR "Different: $eqp vs $pp";
    }
    $xs = "xs/t/shared/$t_file";
    if ( File::Compare::compare( $xs, $eqx ) ) {
        say STDERR "Different: $eqx vs $xs";
    }
} ## end for my $t_file ( keys %t_file )
my @found = ();
sub wanted {
     -d or push @found, $File::Find::name;
}
File::Find::find(\&wanted, 'xs/tool', 'xs/pperl');
FILE: for my $xs_tool_file (@found) {
     my ($volume, $xsdir, $filename) = File::Spec->splitpath($xs_tool_file);
     next FILE if $filename eq 'Version.pm';
     next FILE if $filename eq 'Installed.pm';
     my @dirs = File::Spec->splitdir($xsdir);
     my $ppdir = File::Spec->catdir('pp', @dirs[1 .. $#dirs]);
     my $pp_tool_file = File::Spec->catpath($volume, $ppdir, $filename);
    if ( File::Compare::compare( $pp_tool_file, $xs_tool_file ) ) {
        say STDERR "Different: $pp_tool_file vs. $xs_tool_file";
    }
}
@found = ();
File::Find::find(\&wanted, 'xs/lib/Marpa/XS/PP');
for my $xs_lib_file (@found) {
    my ( $volume, $xsdir, $filename ) = File::Spec->splitpath($xs_lib_file);
    my @dirs = File::Spec->splitdir($xsdir);
    my $ppdir =
        File::Spec->catdir( 'pp', 'lib', 'Marpa',
        @dirs[ 4 .. $#dirs ] );
    my $pp_lib_file = File::Spec->catpath( $volume, $ppdir, $filename );
    if ( File::Compare::compare( $pp_lib_file, $xs_lib_file ) ) {
        say STDERR "Different: $pp_lib_file vs. $xs_lib_file";
    }
} ## end for my $xs_lib_file (@found)

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
