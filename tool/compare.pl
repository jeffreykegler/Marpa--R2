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
        say STDERR "Different: $xs vs $pp";
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
File::Find::find(\&wanted, 'pp/tool');
say join "\n", @found;
